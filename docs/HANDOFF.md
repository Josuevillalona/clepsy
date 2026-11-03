# Clepsy — Dev Handoff

Last updated: 2026-08-04 (commit `959da5f`)

## What Clepsy is

A time-trading iOS app: the user earns screen time by using "productive" apps and
spends it to unlock blocked "vice" apps. Built on Apple's Family Controls /
Screen Time APIs. The app has received Apple's Family Controls entitlement for
`com.clepsy.app` (Development scope — Distribution scope not yet requested, see
Open Items).

Bundle ID: `com.clepsy.app`. Team ID: `98PT3PWGFU`. App Group:
`group.com.clepsy.shared`. Deployment target: iOS 16.0.

## Architecture

Four build targets, generated from `project.yml` via XcodeGen (`xcodegen generate`
— run this after any `project.yml` edit, and whenever `.xcodeproj` seems out of
sync with sources; `.xcodeproj` itself is gitignored):

- **Clepsy** (main app) — SwiftUI, onboarding → dashboard, settings.
- **ClepsyMonitor** (`com.clepsy.app.monitor`) — `DeviceActivityMonitor`
  extension. Runs in the background even when Clepsy isn't open. Credits
  earned minutes, debits spent minutes, re-shields apps, posts notifications.
- **ClepsyShieldConfiguration** (`com.clepsy.app.shieldconfiguration`) —
  `ShieldConfigurationDataSource` extension. Draws the custom lock screen
  shown over a blocked app.
- **ClepsyShieldAction** (`com.clepsy.app.shieldaction`) — `ShieldActionDelegate`
  extension. Handles taps on the shield's buttons.

All four share code via files listed directly in multiple targets in
`project.yml` (not a separate framework): `Clepsy/Models/TimeEvent.swift` and
`Clepsy/Services/SharedStorageService.swift` are compiled into each extension
target as well as the main app.

**Cross-process communication** happens entirely through the App Group
(`group.com.clepsy.shared`), via `SharedStorageService.swift`:
- `UserDefaults(suiteName:)` for small values (balance mirror, session-active
  flag, unlock state, notifications-enabled mirror, per-token shield-screen
  record).
- A coordinated JSON file (`pendingTimeEvents.json`, via `NSFileCoordinator`)
  for the event queue — extensions append `TimeEvent`s, the main app drains
  them into the view model on foreground.
- `FamilyActivitySelection` (vice/productive app picks) is also mirrored into
  the App Group so extensions can read it, since it's `Codable`, not
  `NSCoding` (see Hard-Won Lessons).

## Current feature state (what works today)

1. **Onboarding**: user picks productive apps and vice apps via
   `FamilyActivityPicker`. Selections must be individual apps, not whole
   categories (enforced after the fact — see Hard-Won Lessons #6) — the
   Continue button stays disabled and a warning card explains why if a
   category is selected. Same enforcement in Settings.
2. **Earning**: `UsageTrackingService.startDailyMonitoring` sets a
   midnight-to-midnight `DeviceActivitySchedule` with 1-minute-apart
   thresholds (1...180 min) over the productive-app selection. Each threshold
   firing credits 60 seconds via a `TimeEvent` queued in the App Group.
   Earning is intentionally **not** session-gated — all-day accumulation is
   correct for earning (a minute of Duolingo at breakfast should count).
3. **Blocking**: `AppBlockingService.applyViceAppBlocks()` sets
   `ManagedSettingsStore.shield.applications` / `.applicationCategories` from
   the saved vice selection. Called on app launch, foreground, and after
   onboarding completes.
4. **Spending — usage-based sessions** (current model, replaced wall-clock
   unlock windows in the last redesign):
   - Tapping **"Use My Time"** (on the shield, or in the in-app unlock sheet)
     unshields **all** vice apps and marks a session active
     (`SharedStorageService.saveSessionActive(true)`). Nothing is deducted
     upfront.
   - `UsageTrackingService.startViceSpendingMonitoring` starts a
     `DeviceActivitySchedule` **anchored at the moment the session starts**
     (not midnight — this is the critical fix, see Hard-Won Lessons #8),
     running to end of day, with 1-minute thresholds over the vice
     selection.
   - The monitor extension's `handleViceAppEvent` only deducts when
     `sharedStorage.isSessionActive` is true (ignores stray firings outside a
     session). Each firing costs 60 seconds.
   - When the balance hits zero, `endSession()` runs: marks the session
     inactive, **hard-blocks the vice apps for ~1 second**
     (`store.application.blockedApplications`, which terminates the running
     app — normally a parental-controls primitive) then swaps back to the
     normal shield, and posts a local "Time's up ⏳" notification. This
     avoids ever re-presenting a shield over a foreground app, which is where
     Apple's stale-shield bug lives (see Known Apple Bug below).
   - `AppBlockingService.applyViceAppBlocks()` clears any lingering hard
     block as a safety net, in case the extension died mid-swap.
5. **Shield UI**: `ShieldConfigurationExtension` shows a navy/gold screen with
   the Clepsy mascot icon (bundled at reduced size directly in the extension's
   own asset catalog — `UIImage(named:)` can't reach the main app's catalog).
   Copy depends on balance: `"You have N min. It only counts down while
   you're in blocked apps." / "Use My Time"` vs. `"No time available yet. Earn
   minutes in your productive apps, then come back." / "Go Back"`. Overrides
   both the plain and the `in category:` variants of
   `configuration(shielding:)` — apps blocked via a category token route
   through the category variant exclusively (see Hard-Won Lessons #5).
6. **Notifications**: a "Time's up" local notification fires whenever a
   session ends (now only from `endSession()`). Respects the Settings
   notifications toggle, mirrored into the App Group
   (`SharedStorageService.notificationsEnabled`) so the extension can read it.
   Main app requests notification permission on first launch post-onboarding
   and when onboarding completes.
7. **Dashboard**: shows real selected apps (via `Label(token)`, which renders
   the actual icon/name from an opaque `ApplicationToken`/`ActivityCategoryToken`
   — not hardcoded apps). Goal progress bar is driven by `todayEarned`
   (persisted — see Hard-Won Lessons #9), **independent of spendable
   balance**; the character's fill level is driven by balance. Streak
   tracking lives in `UserDefaults.standard` (not the App Group — it's
   main-app-only state).
8. Test-only UI (+5 min / -2 min buttons) has been removed from the
   dashboard — the only ways to move the balance now are the real earn/spend
   paths.

## Known Apple framework bug — read before touching the shield

**FB14237883** (filed with Apple, unresolved as of iOS 18/19): when
`ManagedSettingsStore.shield.applications` is set while the target app is in
the **foreground**, iOS re-displays the shield it last rendered for that app
instead of querying `ShieldConfigurationDataSource` again. If the shield
content is dynamic (ours is — it shows balance), the screen can be stale and
contradict what the (always-fresh) `ShieldActionDelegate` does when tapped.
Only a fresh app launch reliably re-queries the data source.

Workarounds tried and their results — don't repeat these:
- Nil-then-reapply bounce on the shield value at re-lock: **no effect**.
- `.defer` from the action handler to try to force a redraw when a stale
  screen is tapped with zero balance: **no effect observed on device** (code
  for this is still in `ShieldActionExtension.swift` as a defensive no-op; it
  can't make things worse — worst case is the same as `.close`).
- **What actually sidesteps it**: never re-apply the shield over a foreground
  app. The time's-up hard-block-then-shield swap (see feature #4 above) kicks
  the user to the home screen instead, so the next shield presentation is
  always a fresh launch. This is the shipped mitigation.
- A "Time's up" local notification was also added as a second, independent
  mitigation — it delivers the true state through a channel the cache can't
  affect, regardless of what the shield shows.

Linear ticket `CLE-2` has the full writeup, repro steps, and forum links (filed
in Linear team **Clepsy** — see Where Things Are Tracked below). If Linear
access is available to you, read it before re-investigating this; if not, this
section plus the git history for `ClepsyMonitor/DeviceActivityMonitorExtension.swift`
and `ClepsyShieldAction/ShieldActionExtension.swift` has the same information.

## Hard-won lessons (do not redo this debugging)

1. **`FamilyActivitySelection` is `Codable`, not `NSCoding`.** Using
   `NSKeyedArchiver` on it compiles fine but **crashes at runtime** with
   `-[__SwiftValue encodeWithCoder:]: unrecognized selector`. Always use
   `JSONEncoder`/`JSONDecoder` (see `PersistenceService.swift`,
   `SharedStorageService.swift`).
2. **`NSExtensionPointIdentifier` values must be exact.** The correct values
   (already set in `project.yml`, don't change without re-verifying via
   `PlistBuddy` on the built `.appex`):
   - Monitor: `com.apple.deviceactivity.monitor-extension`
   - Shield config: `com.apple.ManagedSettingsUI.shield-configuration-service`
   - Shield action: `com.apple.ManagedSettings.shield-action-service`
   Wrong values cause iOS to silently never launch the extension — no
   earning, default shield, no re-lock — with no error anywhere.
3. **DeviceActivity schedules have a 15-minute minimum interval.** A schedule
   shorter than that throws `intervalTooShort`. Historically worked around by
   backdating `intervalStart`; the current session-anchored vice monitoring
   schedule (`startViceSpendingMonitoring`) handles this by extending `end` to
   `now + 16min` whenever less than 15 minutes remain until midnight.
4. **DeviceActivity thresholds count cumulative usage within the schedule's
   interval, not "since you started caring."** This caused two real bugs:
   - Earlier: restarting monitoring on every foreground reset the day's
     accumulated usage, silently losing earned minutes. Fixed by making
     `startDailyMonitoring` a no-op while already monitoring (`force`
     parameter to override when the app selection actually changes).
   - Later (the big one): the original per-session vice monitoring was
     anchored at **midnight**, so starting a new session with leftover
     partial-minute usage from earlier sessions caused the next threshold to
     fire within seconds, instantly draining the whole session's balance.
     **Fixed by anchoring the schedule's `intervalStart` at the moment the
     session begins** (`startViceSpendingMonitoring`,
     `restartViceMonitoring` in the shield action extension) — usage before
     that moment is outside the interval and cannot fire thresholds. If you
     ever touch vice monitoring again: never go back to a midnight anchor
     without re-deriving why it breaks.
5. **`ShieldConfigurationDataSource` has exactly 4 overridable methods**:
   `configuration(shielding: Application)`, `configuration(shielding:
   Application, in: ActivityCategory)`, `configuration(shielding: WebDomain)`,
   `configuration(shielding: WebDomain, in: ActivityCategory)`. Apps blocked
   via a **category token** route through the `in category:` variant, not the
   plain one — omitting it was the root cause of "the custom shield never
   appears for category-blocked apps" (iOS silently falls back to its default
   "Restricted" shield). All four are now overridden.
6. **The system `FamilyActivityPicker` cannot be customized** — you cannot
   hide or disable its category checkboxes (iOS renders it out-of-process for
   privacy). "Apps only, no categories" is enforced by validating the
   selection after picking (Continue disabled + warning in onboarding; alert +
   discard in Settings), not by modifying the picker itself.
7. **Shield extensions (configuration especially) have a very tight
   memory/response budget.** If `ShieldConfigurationDataSource` is slow (e.g.,
   doing `NSFileCoordinator` file I/O), iOS kills it and silently falls back
   to the default shield — no crash log, no error. `SharedStorageService`
   has a `fastBalanceSeconds()` that reads only `UserDefaults` (no file
   coordination) specifically for the shield config extension to stay inside
   budget. Don't make the shield config path do file I/O again.
8. **iOS caches compiled extension binaries.** After changing
   `ShieldConfigurationExtension` / `ShieldActionExtension` /
   `DeviceActivityMonitorExtension` code, a plain Cmd+R reinstall sometimes
   isn't enough to pick up the new code — **reboot the device** before
   concluding a fix didn't work. This cost significant debugging time twice.
9. **Today's earned/spent totals must be persisted, not just held in
   `@Published` memory.** They used to live only in `DashboardViewModel`'s
   in-memory properties, so if iOS killed the app in the background mid-day,
   the goal progress bar and streak detection would silently reset to zero.
   Now persisted via `PersistenceService.saveTodayStats` /
   `loadTodayStats`, restored on `DashboardViewModel.init`, cleared by
   `performDailyReset` and `clearAll`.
10. **`UIApplication.shared` and app-launching are unavailable in app
    extensions.** Shield buttons can only respond with `.none` (dismiss, let
    the user through), `.close` (quit the shielded app), or `.defer`. There is
    **no way to deep-link from a shield extension into the main app** — this
    is why the shield's zero-balance state is a single "Go Back" button
    rather than an "Open Clepsy" button that could never actually open
    anything.
11. **`store.application.blockedApplications` terminates a running app and
    hides its home-screen icon** while set — it's the parental-controls
    "fully blocked" primitive, distinct from `store.shield.applications`
    (which only overlays a shield, doesn't kill the app). Used deliberately
    now for the time's-up kick-out; must always be cleared quickly (it's
    swapped back to `nil` within ~1 second in `endSession`, and
    `applyViceAppBlocks` also clears it defensively) or app icons stay
    hidden.
12. **Threshold event delivery has a delay** (observed up to ~30-60 seconds)
    and can arrive batched. Don't assume a credit/debit lands the instant the
    real-world minute ticks over — this explains apparent "lumpiness" in
    earned minutes within a single sitting (correct over a full day, can look
    off by ±1 minute within one sitting) and why a session's final seconds
    can run slightly past zero before the re-lock actually executes.
13. **Git identity on this machine is auto-generated**
    (`Josue <josuevillalonagmail.com@Josues-MacBook-Air.local>`), not the
    real email. Commits pushed so far won't link to the GitHub account until
    `git config --global user.email "josuevillalona@gmail.com"` and
    `user.name` are set. Not yet done as of this handoff — ask the user
    before amending already-pushed commits' authorship.

## Where things are tracked

- **Linear**: workspace `pursuitjosue`, team **Clepsy** (key `CLE`). As of
  this handoff there are 35 issues (CLE-1 through CLE-35) organized into
  projects: Shield and Blocking, Spending Sessions, Earning Engine,
  Dashboard, Onboarding, Settings, Data and Platform, Notifications, Brand
  and Character, Tech Debt, Docs and Process. This backlog is the result of
  a thorough code-level audit (referenced internally as CD-/R-/J- numbered
  findings against the PRD) done after commit `959da5f` — it is detailed and
  cites exact files/functions, so **trust it over assumptions, but verify
  against current code before acting**, since code keeps moving. Notable
  tickets to read before touching related areas:
  - **CLE-2** — the Apple shield-cache bug (FB14237883) writeup; read before
    touching shield presentation again.
  - **CLE-4 + CLE-3** — coupled: both earning and spending threshold ladders
    silently cap at 180 minutes (`UsageTrackingService.swift`,
    `ShieldActionExtension.swift`, both still `for minutes in 1...180`,
    confirmed present as of this handoff). Removing the earning cap alone
    without also fixing spending opens a free-unlimited-access hole — CLE-3
    is a device-only spike to verify a re-arming-ladder fix before CLE-4 can
    ship. **Do not remove one 180 ceiling without the other.**
  - **CLE-21** — the category-handling code (`ShieldActionExtension.handle(for
    category:)` and related pass-throughs) is confirmed dead — apps-only
    selection is a permanent product decision, not a workaround — but hasn't
    been removed yet. Touches three targets; do carefully and in isolation.
  - **CLE-33** — dead wiring confirmed still present: `AppDidBecomeActive`
    notification (posted, nothing listens), `clepsy://` URL scheme in
    `project.yml` (nothing opens a URL), `AppCategory.defaultViceApps` /
    `.defaultProductiveApps` hardcoded lists (dashboard actually renders via
    `Label(token)`), `UserSettings.exchangeRate` (unused, implies
    configurability that doesn't exist).
  - **CLE-18** — claims nothing re-shields vice apps at midnight mid-session.
    Possibly already mitigated as a side effect of the session-anchored
    metering fix in this handoff (`DeviceActivityMonitorExtension.intervalDidEnd`
    calls `endSession()` when the `.viceApps` interval ends, and that
    interval's end is anchored near end-of-day) — flagged with a comment on
    the ticket, **not verified on-device**, don't close without testing.
  - A Linear Document mirroring this file lives in the "Docs and Process"
    project — update both together when either drifts (see CLE-32, which
    tracks adopting a doc-sync habit for exactly this reason).
- **GitHub**: `https://github.com/Josuevillalona/clepsy`, branch `main`. Last
  pushed commit as of this handoff: `959da5f`.
- **Design**: `design-kit/` at the repo root is a separate Node/React project
  (a web demo of the Clepsy character component) — intentionally left
  **untracked** in git (it has its own `node_modules/`). Don't add it to a
  commit without first adding `design-kit/node_modules/` and
  `design-kit/dist/` to `.gitignore`, or asking the user whether it belongs in
  this repo at all.

## Open items / suggested next steps

1. **Device-verify the current build.** The most recent redesign (session
   model + time's-up kick-out) was build-verified and unit-tested, but the
   full on-device loop (earn → spend → exhaust → kick-out → notification →
   reopen → correct shield) should be re-run end to end after a fresh
   install + reboot, since several of the mechanisms here rely on
   undocumented iOS behavior that only on-device testing can confirm.
2. **CLE-1 (shield branding polish)** — still open. Apple's
   `ShieldConfiguration` API only allows background color/blur, one icon,
   title/subtitle text+color, and button label text+colors — no custom
   layout or fonts. Worth a copy/visual pass once the current functionality
   is confirmed stable.
3. **Family Controls (Distribution) entitlement** not yet requested. Current
   entitlement is Development-scope, which works for direct Xcode installs
   but not TestFlight. Needed per extension bundle ID before any TestFlight
   distribution: `com.clepsy.app`, `com.clepsy.app.monitor`,
   `com.clepsy.app.shieldconfiguration`, `com.clepsy.app.shieldaction`.
4. **Per-app (as opposed to all-vice-apps-at-once) session unlock** was
   explored and fully implemented earlier, then **deliberately removed**
   when the user clarified they wanted a shared pool where all vice apps
   unlock together and the balance drains only on actual usage (the current
   session model). If a future request wants "unlock just this one app,"
   note that this was built once already — check git history around commit
   `14984df` for the per-app registry approach (`registerUnlock` /
   `activeUnlockTokenDatas` in `SharedStorageService`) before rebuilding it
   from scratch, though it will need to be adapted to sit on top of the
   session model rather than wall-clock windows.
5. **No automated UI/end-to-end tests** — `ClepsyTests` covers models and
   services (29 tests, passing as of `959da5f`) but nothing exercises the
   extensions or the shield flow, since XCTest can't drive Screen Time UI.
   All extension behavior verification has been manual, on-device.
6. **`design-kit/`** — clarify with the user whether this should be tracked
   in this repo (as source-only, gitignoring `node_modules`/`dist`) or lives
   elsewhere / is a one-off demo that can stay untracked.
7. Consider setting `git config --global user.email/user.name` (see Hard-Won
   Lessons #13) so future commits attribute correctly on GitHub.

## Useful commands

```bash
# Regenerate Xcode project after editing project.yml
xcodegen generate

# Verify the full app + all extensions build for device (no signing needed for this check)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Clepsy.xcodeproj -scheme Clepsy \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build

# Run the unit test suite (simulator name may need adjusting to what's installed)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Clepsy.xcodeproj -scheme Clepsy \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# Check a built extension's Info.plist values (e.g. NSExtensionPointIdentifier)
/usr/libexec/PlistBuddy -c "Print" \
  ~/Library/Developer/Xcode/DerivedData/Clepsy-*/Build/Products/Debug-iphoneos/ClepsyShieldConfiguration.appex/Info.plist
```

Device testing requires: Cmd+R install from Xcode with the phone connected,
**and a device reboot after any extension code change** (see Hard-Won Lessons
#8) before concluding a fix didn't work. Console.app (Mac, phone connected,
filter on `clepsy`) surfaces `os.log` breadcrumbs from the shield extensions —
subsystems `com.clepsy.app.shieldconfiguration` and `com.clepsy.app.shieldaction`.
