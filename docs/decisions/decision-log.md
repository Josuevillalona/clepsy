# Clepsy Decision Log

**Purpose:** Capture the implementation decisions that were made while building Clepsy but never
written down. Most of these live only in source comments and commit messages today. This is the
missing layer between the PRD ("what we want") and the code ("what it does").

**How this was built:** reverse-engineered from the code, its comments, and the full commit history
(`32507f5` → `14984df`), then classified. Entries marked ❓ are places where the code contains a
decision that may not have been made deliberately — those need your call.

**Status legend**

| | Meaning |
|---|---|
| ✅ **Locked in** | Deliberate and correct. Just needs to exist in the docs. |
| 🔒 **Platform-forced** | iOS/Apple constraint left no real choice. Document so nobody "fixes" it. |
| ❓ **Needs your call** | A behavior is embedded in code; confirm it's intended or change it. |
| 🧪 **Scaffolding** | Built for development. Needs gating or removal before release. |
| ⤴️ **Supersedes docs** | Reverses something a written spec or the PRD says. |
| 🧹 **Loose end** | Dead wiring left behind by a change of direction. |

---

## A. Platform-Forced Decisions

These are the ones most at risk of being "corrected" by someone who doesn't know why they exist.
Every one of them cost debugging time to discover.

### CD-001 · Selections must be individual apps, never categories 🔒 ⤴️ ✅ *(confirmed 2026-08-04)*

> **Decision:** apps-only is permanent and intended, not just a workaround. The UI must keep preventing
> category selection. PRD J1 P2 (category blocking) is **struck**, and the unreachable category paths
> in `AppBlockingService`, `ShieldActionExtension.handle(for category:)` and the monitor extension
> should be removed so only one selection model exists.

**Code:** `AppSelectionView.swift:15`, `SettingsViewModel.swift:23`

Both pickers reject `FamilyActivitySelection.categoryTokens`. Continue stays disabled; Settings
shows a "Pick specific apps" alert and discards the change.

**Why:** a category token cannot be unshielded for one app inside it. Per-app unlock — the whole
spending model — is impossible with categories. Apple's `familyActivityPicker` has no API to hide
the category checkboxes, so it has to be validated after the fact.

**Conflicts with:** PRD J1 P2 *"User can select app categories (Social Media, News, Gaming) to block
entire groups."* That requirement is not achievable alongside per-app unlock. One has to go.

**Note:** the all-or-nothing category path still exists in `ShieldActionExtension.handle(for
category:)`, `AppBlockingService.applyViceAppBlocks`, and the monitor's `reapplyViceShields`. It's
unreachable for new users but would fire for anyone with a category selection saved before the rule
landed.

### CD-002 · `FamilyActivitySelection` persists via `JSONEncoder`, not `NSKeyedArchiver` 🔒
**Code:** `PersistenceService.swift:88`

**Why:** `NSKeyedArchiver` crashes at runtime on `FamilyActivitySelection` despite it appearing
archivable. It's a `Codable` struct; JSON round-trips fine. Most Screen Time tutorials online show
the archiver approach — this is a trap worth documenting.

### CD-003 · Shield configuration reads balance from UserDefaults only 🔒
**Code:** `SharedStorageService.fastBalanceSeconds()`, `ShieldConfigurationExtension.swift:21`

`fastBalanceSeconds()` sums two `UserDefaults` integers (`balanceSeconds` + `pendingDeltaSeconds`)
instead of coordinating a read of the events file like `currentBalanceSeconds()` does.

**Why:** iOS kills the shield configuration extension if it doesn't return almost instantly, and the
failure mode is silent — you get Apple's generic "Restricted" shield with no error. File
coordination was too slow. `pendingDeltaSeconds` exists purely as a UserDefaults mirror of the
event ledger's net total to make this path possible.

### CD-004 · The category variant of `ShieldConfigurationDataSource` must be overridden 🔒
**Code:** `ShieldConfigurationExtension.swift` — `configuration(shielding:in:)`

**Why:** apps blocked via a category token route through `configuration(shielding:in:)`, *not* the
plain `configuration(shielding:)` overload. Without the override, iOS silently shows the default
shield. This was the root cause of "the custom shield never appears."

### CD-005 · Zero balance shows one "Go Back" button, not "Earn Time Now" 🔒 ⤴️
**Code:** `ShieldConfigurationExtension.swift:33`

**Why:** a shield extension cannot launch another app — there is no API. The PRD's *"User sees
button: 'Earn Time Now' which opens main app"* (J3 P0) is not implementable as written. A button
that does nothing is worse than no button, so the zero-balance state offers a single honest action.

**Action:** amend PRD J3. This is a platform limit, not a gap.

### CD-006 · Unlock windows are backdated 16 minutes 🔒
**Code:** `UsageTrackingService.swift:62`, `ShieldActionExtension.swift:120`

A 5-minute unlock schedules a `DeviceActivitySchedule` starting 16 minutes *before* it ends.

**Why:** DeviceActivity rejects intervals shorter than 15 minutes. Only the interval *end* matters —
that's the re-lock moment — so the start is backdated to satisfy the framework. If backdating would
cross midnight, it clamps to `startOfDay` instead.

### CD-007 · Stale-shield mitigation via `.defer` + per-token screen record 🔒
**Code:** `SharedStorageService.setShieldShowedBalance`, `ShieldActionExtension.swift:19`

The configuration extension records, per app token, whether the screen it returned offered an unlock.
The action extension reads that record: on a zero-balance tap against a screen that *had* offered an
unlock, it returns `.defer` (forcing iOS to re-query and redraw) instead of `.close`.

**Why:** Apple bug **FB14237883** — iOS caches shield appearances, so a user can tap "Unlock for 5
min" on a screen rendered when they had balance, after spending it. Recording `false` before
deferring guarantees a second tap always closes, so the user can never get stuck.

**History:** a nil-bounce approach was tried first and reverted. Don't re-attempt it.

### CD-008 · Restarting daily monitoring is a no-op while it's already running ✅
**Code:** `UsageTrackingService.startDailyMonitoring(force:)`

**Why:** `startMonitoring` on an active schedule **resets that day's accumulated usage to zero** —
the user would silently lose their earning progress every time they foregrounded Clepsy. The guard
skips the restart unless `force: true`, which only Settings uses after the productive app list
actually changes.

### CD-009 · Foregrounding Clepsy must not re-shield an app inside its unlock window ✅
**Code:** `ClepsyApp.reapplyBlocksIfNeeded`, `AppBlockingService.applyViceAppBlocks`

Shields are re-applied on every foreground (defensive — shields can be lost), but the token set
excludes apps with a live unlock, and the whole pass is skipped during a category-style unlock window.

**Why:** without it, switching to Clepsy to check your balance would kill the unlock you just paid
for.

### CD-010 · Each unlock gets its own registry entry and re-lock schedule 🗑️ *(removed in `959da5f`)*

> **Superseded by the session model (CD-031).** The `activeUnlocks` registry, `unlockExpiresAt`, and
> the per-app `unlock_<uuid>` re-lock schedules are all gone. Retained here as the record of what the
> prepaid design required — useful if per-app granularity ever comes back.

**Code:** `SharedStorageService` — `activeUnlocks`; `ShieldActionExtension.scheduleRelock`

An unlock registers `{token, expiry}` under a unique `unlock_<uuid>` DeviceActivity name. Its
interval end re-shields that one app. Expired entries are pruned lazily on read.

**Why:** supports several apps unlocked concurrently on independent timers, and lets every
re-shield path ask "is this app still inside a paid window?"

---

## B. Architecture Decisions

### CD-011 · Earning is threshold accrual, not a session engine ✅ ⤴️
**Code:** `UsageTrackingService.startDailyMonitoring`, `DeviceActivityMonitorExtension.handleProductiveAppEvent`

One repeating daily schedule registers 180 threshold events (`earn_1` … `earn_180`) at 1-minute
intervals of cumulative productive-app usage. Each firing appends a 60-second `.earned` event.

**Why (inferred):** DeviceActivity only reports threshold crossings — it doesn't stream foreground/
background transitions to a killed app. Warmup and pause/resume require observing app lifecycle,
which a background extension cannot do. Threshold accrual is what the framework actually supports.

**Conflicts with:** `docs/specs/earning.md` in its entirety, PRD J2 P0s (60s warmup, 2-min pause
timeout), plan Task 21B. Practical differences: no warmup, no sessions, 1-minute granularity, and
in-app balance updates only on foreground (the shield reads a live mirror, so *it* is current).

**Related:** `EarningSessionManager` — see CD-024.

### CD-012 · 180-minute/day earning ceiling ✅ *(decided 2026-08-01: remove it)*

> **Decision:** the ceiling is not intended. Remove it — there should be no daily earning cap, matching
> the "Dropped from MVP" scope call. Implementation note: raising the loop bound linearly grows the
> registered event count, so the fix is probably *not* `1...1440`. Options to weigh: cap at a
> defensible waking-hours figure, or switch to a small repeating threshold set that re-arms. Needs a
> spike to confirm what DeviceActivity will accept before picking.

**Code:** `UsageTrackingService.swift:36` — `for minutes in 1...180`

Thresholds stop at 180, so **a user earns nothing after 3 hours of productive app use per day.**
Silent — no message, the balance simply stops growing.

**Why (inferred):** 180 events is already a large registration; there's presumably a practical limit.
But nothing documents this, and Doc 2's "Dropped from MVP" explicitly *removed* a daily earning cap
from scope — so the app has the very cap the PRD dropped, by accident of implementation.

**Needs a call:** is 3h/day acceptable for MVP? If yes it belongs in the PRD as a stated limit. If
no, the ceiling needs raising (and the registration cost measuring).

### CD-013 · Balance is derived from an internal event ledger, not `DeviceActivityReport` ✅ ⤴️
**Code:** `SharedStorageService` (events file), `DashboardViewModel.syncPendingEvents`

`DeviceActivityReport` — listed as a required framework in PRD Technical Dependencies — is not used
anywhere. Clepsy maintains its own `TimeEvent` ledger in the App Group container, written by
extensions and drained by the app.

**Why:** the report framework renders usage in a sandboxed SwiftUI view whose data can't be read out
by the host app; it can't back a balance. The ledger also gives cross-process atomicity via
`NSFileCoordinator`.

**Note:** the doc's stated key `pendingTimeEvents` (an App Group *UserDefaults* key) does not exist —
the implementation uses a **file**, `pendingTimeEvents.json`.

### CD-014 · Spending is a prepaid window, not real-time metering ✅ ⤴️
**Code:** `ShieldActionExtension.unlock`

Tapping unlock charges the full amount immediately as a `.spent` event, unshields the app, and
schedules the re-lock. Actual usage is never measured. Unused time inside a window is not refunded;
`DeviceActivityName.viceApps` monitoring is never started.

**Why:** the same framework limit as CD-011 — per-second usage metering of a foreground app is not
available to a background extension. Prepaid windows are deterministic and survive app termination.

**Conflicts with:** PRD J4 P0s — *"real-time (1-second increments)"*, *"deducts as user scrolls"*,
*"auto re-shields when balance hits zero mid-session."* None are implementable as written.

**User-visible consequence to document:** unlock 5 minutes, use 40 seconds, you still paid 5.

### CD-015 · `SharedStorageService` is compiled into all four targets ✅
**Code:** `project.yml` — listed in the sources of every extension

It plus `TimeEvent` are the entire app↔extension contract. There is no shared framework target; the
files are compiled into each.

**Why:** simplest thing that works for two small files. Worth knowing before adding a fifth
dependency to it — every extension pays the compile and every extension gets the API surface.

---

## C. Product & UX Decisions

### CD-016 · Onboarding went 7 screens → 5 ✅ ⤴️
**Commit:** `45a7318` — *"Optimize onboarding: 7 screens → 5 (merge Welcome+HowItWorks, remove Ready)"*

Welcome and "How It Works" merged into one screen with four feature rows; the "You're All Set" screen
became a 2.5s auto-dismissing celebration overlay on the dashboard.

**Why:** PRD Open Question 2 sets a `<2 minutes to first blocked app` target and calls for "3 screens
max." This was the compression toward that goal.

**Conflicts with:** `docs/specs/onboarding.md`, which specifies 6 screens (and whose own header
says "Target: 5 screens total" — the spec contradicts itself). Screens 2B and 6 as written no
longer exist.

### CD-017 · "Today's Stats" cards folded into the balance hero card ✅ ⤴️
**Commit:** `157be49` — *"Remove redundant Today's Stats section (earned/spent shown in hero card)"*

**Conflicts with:** `docs/specs/dashboard.md` §3.5, which specifies two standalone stat cards with
teal/orange borders and "From X apps" context.

### CD-018 · The hourglass shows spendable balance, not goal progress ✅ ⤴️ *(confirmed 2026-08-01)*

> **Decision:** current behavior stands. The sand level represents **spendable balance** — it drains as
> you spend, which is what an hourglass should do. The docs are what's wrong here, not the code.
> Follow-ups: amend PRD J3 P0 (*"sand level must reflect progress toward their daily productivity
> goal"*) and the MVB's "Why Hourglass Body?" rationale, which is currently written around the
> goal-progress reading. Also worth revisiting CD-019 — the face still keys off goal progress while the
> body keys off balance.

**Code:** `DashboardView` passes `viewModel.balancePercentage` (= balance ÷ daily goal)
**Commits:** `9db7dd7` set it to goal progress → `157be49` *"Fix hourglass to use balance (spendable)
not goal progress"* reversed it.

This was decided twice in opposite directions, and the second one won.

**Conflicts with:** PRD J3 P0 *"the sand level in Clepsy's hourglass body must reflect the user's
current progress toward their daily productivity goal"* and the MVB brand doc, which both say goal
progress.

**Needs a call:** the current behavior means the sand *drains as you spend*, which reads naturally as
an hourglass but no longer tracks the goal. Both readings are defensible — but the brand doc's
rationale for the hourglass body is built on the goal-progress reading, so whichever you pick, the
MVB needs updating to match.

### CD-019 · Expression thresholds: patient <30%, encouraging 30–99%, celebrating 100% ✅
**Code:** `DashboardView.expressionForBalance`

Note these keys off `goalProgressPercentage` (earned ÷ goal), while the *body* keys off
`balancePercentage` (CD-018) — so face and body track different quantities. Probably fine, possibly
surprising. Body fill buckets at 12.5% boundaries: 0 / 25 / 50 / 75 / 100.

### CD-020 · Streak counts goal-met days, not earning days ✅ ⤴️ *(confirmed 2026-08-01)*

> **Decision:** goal-met days is correct. The code stands; the docs change.
>
> The streak is a **goal completion** streak, not a participation streak — it only increments on days
> the user actually hits their daily goal. Follow-up: amend PRD J5, which currently defines it as
> "consecutive days with earning activity" and labels it a "Fresh Start Streak."
>
> **Accepted consequence:** partial-credit days count for nothing. A user earning 20 minutes against a
> 30-minute goal every day for a month has a streak of zero. If that turns out to be demotivating in
> testing, the lever is the daily goal default (30 min), not the streak rule.

**Code:** `DashboardViewModel.incrementStreak` — fires from `addTime` when `goalProgressPercentage >= 1.0`

**Conflicts with:** PRD J5, which defines the streak as *"consecutive days with earning activity"* and
frames it as "Fresh Start Streak" celebrating users who earn *anything* daily.

**Needs a call:** goal-met is a much harder bar. A user who earns 20 of a 30-minute goal every day
for a month has a streak of zero. Given the PRD's stated goal is *"complete at least 1 productive
session every day,"* the earning-activity definition matches the strategy better.

**Also:** the `clepsy_streak_*` keys live in standard `UserDefaults` outside
`PersistenceService.clearAll()`, so "Reset all data" preserves the streak.

### CD-021 · Unlocks are capped at 5 minutes 🗑️ *(rejected 2026-08-01, removed in `959da5f`)*

> **Decision:** the 5-minute cap is **not** the intended model. It was a prototype value that hardened.
> The target model is: **unlock the full accumulated balance, and consume it only while the user is
> actually in the app.** Specified as CD-031 below. The rest of this entry is retained as the record of
> what is currently built.

**Code:** `ShieldConfigurationExtension.maxUnlockMinutes = 5`; `ShieldActionExtension.swift:37,64`
(hardcoded literal `min(5, …)`, twice, not referencing the constant)

**Provenance:** traces back to `9db7dd7` — *"Wire vice app unlock to deduct 5 min from balance"* — a
value in the dashboard prototype, which was then mirrored into the shield extension as
`maxUnlockMinutes` with the comment *"matches the in-app unlock flow."*

**This one is worth a decision.** It looks like a prototype value that hardened into production
rather than a deliberate product choice. It's the difference between "unlock for what you've earned"
(what the PRD promises: *"Button displays exact available time"*) and "unlock in 5-minute
increments." The latter weakens the Painkiller value prop — the user never sees the full cost of
what they banked — but it does force a re-decision every 5 minutes, which is arguably *more* aligned
with the Intentional Friction principle.

**Cleanup regardless:** the constant lives in one target and the literal in another. They will drift.

### CD-031 · Spending model: full-balance session, metered by actual usage ✅ **BUILT** *(`959da5f`, 2026-08-04)*
**Status:** decided 2026-08-01, **shipped 2026-08-04.** Supersedes CD-021 and rewrites CD-014.

**The model:** tapping unlock grants access to the app using the user's *entire* accumulated balance.
Time is consumed **only while the user is actually in a vice app** — not by wall clock. When the
balance is exhausted, the app re-shields. Balance ticks down in 1-minute increments as they use it.

**Why this reverses my earlier analysis.** The audit claimed the PRD's real-time deduction was "not
implementable as written." That was **too strong and it shaped several conclusions**. Per-*second*
metering genuinely isn't available to a background extension — but per-*minute* metered consumption is,
using exactly the mechanism the earning path already uses: a DeviceActivity schedule over the vice apps
with 1-minute threshold events, each firing burning a minute off the ledger. DeviceActivity thresholds
measure **actual usage**, not elapsed time, which is precisely the required semantics.

**The plumbing is already half-built**, which suggests this was the original intent before the prepaid
window went in as a stopgap:

- `DeviceActivityName.viceApps` is defined (`UsageTrackingService.swift:114`)
- `DeviceActivityMonitorExtension.handleViceAppEvent` already writes a 60-second `.spent` event
- `UsageTrackingService.stopAllMonitoring` already tears `.viceApps` down
- **Nothing ever calls `startMonitoring(.viceApps, …)`** — that's the whole gap

**How the four spike questions were answered by the implementation:**

1. **Re-registration on balance change — sidestepped.** The schedule registers a fixed
   `spend_1 … spend_180` ladder once per session and never re-registers. Instead, *every* threshold
   firing appends a 60-second `.spent` event and then re-reads `currentBalanceSeconds()`; the session
   ends the moment that hits zero. The balance is evaluated dynamically rather than encoded in the
   thresholds — which avoids the CD-008 reset trap entirely.
2. **15-minute minimum — handled.** The interval runs from *now* to 23:59, falling back to
   `now + 16 min` when less than 15 minutes of the day remain.
3. **Concurrent event limits — still unverified.** Now 180 earning + 180 spending events across two
   activities. Nothing has confirmed iOS tolerates this, and CD-012 will push the earning side higher.
   **Remains an open risk — see R-02.**
4. **Re-shield latency — solved differently.** Rather than accept overrun, `endSession` momentarily
   sets `store.application.blockedApplications`, which *terminates* the foreground app, then clears it
   and applies the normal shield. The user lands on the home screen with a "Time's up" notification.
   This also sidesteps FB14237883 (CD-007): a shield is never re-presented over a running app, so the
   stale-cache bug has no opportunity to fire. **Carries its own risk — see R-01.**

**As built:** the shield's primary button is now **"Use My Time"**, subtitled *"You have N min. It only
counts down while you're in blocked apps."* Tapping it unshields **all** vice apps at once and flags
`sessionActive` in the App Group. No per-app granularity; nothing charged up front.

**Doc follow-ups:** PRD J4's real-time-deduction P0s are now *implemented* at 1-minute granularity —
amend the wording, don't strike it. CD-014's "not implementable" framing and the audit's D2 entry are
both corrected.

### CD-022 · Daily goal options differ between onboarding and Settings ✅ *(decided 2026-08-04)*

> **Decision:** **15 / 30 / 45 / 60 / 90 / 120** minutes is canonical — onboarding's set wins.
> `SettingsView.GoalPickerSheet` changes from `[15,30,60,120,180,240]` to match. Gentler ladder, and
> nobody can strand themselves on a 45 or 90 they can't re-pick later.

Onboarding: `[15, 30, 45, 60, 90, 120]` · Settings: `[15, 30, 60, 120, 180, 240]`

A user who picks 45 or 90 in onboarding cannot see or re-select that value in Settings' wheel picker.
Neither set matches either spec. Almost certainly unintentional.

---

## D. Development Scaffolding

Built to make progress without a physical device — the whole Screen Time surface is untestable in the
Simulator. These are **not** product behavior, but they currently ship as if they were.

### CD-023 · Dashboard "+5 min / −2 min" test buttons 🗑️ *(removed in `959da5f`)*

> Deleted outright rather than gated. The release-blocker risk is closed.

**Code:** `DashboardView.testActionsSection` (`DashboardView.swift:332`)

Manual balance controls added to exercise the earning/spending UI without DeviceActivity. The 5 and 2
are arbitrary test amounts, not product values.

**Risk:** they are **not** behind `#if DEBUG`, so they ship to TestFlight and the App Store as a
user-facing "Test Actions" section that grants free balance. Gate or remove before any external
build. (Guarding them is a 2-line change.)

### CD-024 · `EarningSessionManager` is a spec-faithful reference implementation, unused ✅ *(decided 2026-08-04: keep, clearly marked)*

> **Decision:** keep the file, but mark it unmistakably as not live. A header comment stating it is
> never called, with a pointer to CD-011 for what actually runs. It stays compiled (so its tests keep
> passing) purely as a reference if session-based earning is ever revisited on-device.

**Code:** `Clepsy/Services/EarningSessionManager.swift` (169 lines) + 167 lines of tests

Implements the documented model exactly — 60s warmup, 2-minute pause timeout, 5-minute credit
interval, `simulateElapsedTime` test hook. It is referenced by nothing outside its own tests.

Its `pauseTimeoutDuration = 120` and `balanceUpdateInterval = 300` are the **spec's** 2 and 5
minutes, not the dashboard buttons' — three unrelated pairs of "5 and 2" in this codebase, which is
worth untangling in one place. It's also the reason `docs/specs/earning.md` reads as though the
session model is live.

**Needs a call:** keep as a documented reference for a future device-side implementation, or delete
so the codebase stops implying a mechanic that isn't wired up? If kept, a header comment saying
"not wired up — see CD-011" would prevent the next reader making the same inference I did.

### CD-025 · Entitlements were toggled for Simulator work 🧪
**Commit:** `45a7318` — *"Disable FamilyControls entitlements for simulator testing"*, re-enabled by
`14984df`. A separate `Clepsy/ClepsyDebug.entitlements` exists for this.

**Consequence:** `README.md` still tells you to *uncomment* the entitlements and the ClepsyMonitor
dependency. That was accurate at `b42ac9d` and wrong since `14984df` — both are active in
`project.yml` now.

---

## D2. Session Model Decisions (`959da5f`, 2026-08-04)

Decisions embedded in the spending-session commit. Logged at the time rather than reconstructed.

### CD-032 · Metering interval is anchored at session start, not midnight ✅ 🔒
**Code:** `ShieldActionExtension.restartViceMonitoring`, `UsageTrackingService.startViceSpendingMonitoring`

The vice schedule runs from *now* to 23:59, re-registered on every session start.

**Why:** DeviceActivity thresholds count usage accumulated **inside the schedule interval**. A
midnight-anchored interval would see all of today's earlier vice-app usage already banked, and every
`spend_N` threshold below that total would fire the instant a session started — draining a full
balance in seconds. Anchoring at session start makes "minutes used" mean "minutes used *this
session*." This is the subtlest thing in the spending path and the easiest to accidentally undo.

### CD-033 · Exhaustion hard-blocks momentarily to terminate the app ✅ 🔒
**Code:** `DeviceActivityMonitorExtension.endSession`

At zero balance: set `store.application.blockedApplications` (which terminates the running app and
hides its icon) → `Thread.sleep(1.0)` → clear it → apply the normal shield → post "Time's up".

**Why:** two problems solved at once. Applying a shield over a *foreground* app renders the stale
cached screen from Apple bug FB14237883 (CD-007). Terminating the app first means the next launch is a
fresh shield presentation, which always renders correctly. It also gives a decisive end to the session
instead of a soft overrun.

**Trade-off accepted:** a blocking sleep inside an extension with a tight execution budget. See R-01.

### CD-034 · One session unshields everything, with no per-app granularity ✅ ⤴️
**Code:** `ShieldActionExtension.startSession` — `store.shield.applications = nil`

Tapping "Use My Time" on *any* blocked app unshields *all* vice apps until the balance runs out.

**Why:** the balance is a shared bank (PRD J4 P0, "switch between vice apps using same bank"), and with
usage metering there's no reason to gate each app separately — time only burns where it's spent. It
also removes the per-app registry (CD-010) entirely.

**Worth noting for the docs:** this is a real UX shift from the prepaid design. Opening Instagram now
also unlocks TikTok. Defensible under the shared-bank model, but it means the friction moment happens
once per session rather than once per app.

### CD-035 · Notifications now exist — but only the "Time's up" one ✅
**Code:** `ClepsyApp.requestNotificationPermission`, `DeviceActivityMonitorExtension.postTimesUpNotification`,
`SharedStorageService.notificationsEnabled`

`UNUserNotificationCenter` is now used. Permission is requested on first dashboard appearance and at
onboarding completion. The monitor extension posts "Time's up ⏳" at exhaustion, gated on a
`notificationsEnabled` mirror in the App Group (defaulting to true when unwritten).

**Still missing:** milestone notifications (PRD J2 P0), low-balance and weekly-summary (P1). And
`milestoneInterval` is *still* not persisted — the Settings interval picker remains inert even though
the toggle above it now controls something real.

---

### CD-036 · The daily goal is a floor, not a ceiling ✅ *(clarified 2026-08-04)*

The daily goal exists **only** to set the bar for the streak (CD-020). It is not a cap, a budget, or a
stopping point. A user who wants to earn 6 hours against a 30-minute goal should be able to, and should
keep earning at the same 1:1 rate the whole way.

**Why this needs saying:** two numbers in the code look like limits and aren't product decisions at
all — the `1...180` earning ladder (CD-012) and the `1...180` spending ladder (R-02). Both are
artifacts of how many DeviceActivity alarms got registered, not expressions of intent. Anyone reading
the code could reasonably mistake them for a deliberate 3-hour cap. They aren't. **There is no cap.**

**Consequence:** CD-012 isn't "raise the ceiling," it's "there should be no ceiling," and the same
applies to spending. See CD-037 for how.

### CD-037 · Unlimited earning and spending via re-arming threshold ladders 🔬 *(proposed 2026-08-04 — needs device verification)*
**Status:** design direction, **not built, not verified.**

**The constraint:** DeviceActivity can't do "notify me every minute, forever." You register a fixed
list of alarms up front — alarm at 1 minute of use, at 2 minutes, and so on. When the last one fires,
you stop hearing anything. That's why both ladders stop at 180: somebody had to pick a number.

**The fix — one mechanism for both sides:**

*Earning.* Register a short ladder (say `earn_1 … earn_60`) instead of 180. When the **top** threshold
fires, the monitor extension restarts the `productiveApps` schedule anchored at *now* with a fresh
ladder. Repeat indefinitely. Truly unlimited, with a constant 60 events instead of a growing list.

*Spending.* Size the ladder to the balance the user actually has at session start rather than always
registering 180. Balance of 12 minutes → 12 alarms. Users can't earn while spending (productive and
vice apps are different apps), so the balance is effectively fixed for the session. If a balance ever
exceeds the ladder length, re-arm exactly as earning does.

This is strictly better than today even ignoring the cap: a user with 10 minutes banked currently gets
180 alarms registered, 170 of them pointless.

**Precedent:** `ShieldActionExtension.restartViceMonitoring` already restarts monitoring from inside an
extension, so the pattern is proven in this codebase.

**Deliberate use of CD-008:** restarting a schedule *resets* accumulated usage. Everywhere else that's
a hazard; here it's the point — those minutes are already banked, so the counter should start over.

**What must be verified on a device before committing:**

1. **Is there a hard limit on events per activity, or on total events across activities?** 180 + 180
   apparently works today, but nothing has confirmed the ceiling. If a small ladder is required, this
   design is mandatory rather than merely better.
2. **How much usage leaks at each re-arm?** There's a gap between the final threshold firing and the
   new schedule taking effect. Seconds per hour is fine; minutes per hour is not.
3. **Can the monitor extension reliably restart its own schedule** from inside `eventDidReachThreshold`,
   given its execution budget (cf. R-01)?

**Direction of error:** on earning, a leak means the user earns slightly *less* than they used. On
spending, it means they spend slightly *less* than they used. Both err in the user's favour, which is
the right way round for a trust-critical app.

---

## F. Open Risks

Introduced or left open by the current implementation. Not decisions — things to watch.

### R-01 · `Thread.sleep(1.0)` inside the monitor extension 🟠
**Code:** `DeviceActivityMonitorExtension.endSession`

A one-second blocking sleep runs inside a `DeviceActivityMonitor` callback, between setting
`blockedApplications` and clearing it. These extensions have tight execution budgets.

**Failure mode if the extension is killed mid-sleep:** `blockedApplications` stays set, which doesn't
just shield the vice apps — it **hides their icons from the home screen entirely**. The user's apps
appear to have been deleted, with no explanation.

**Existing mitigation:** `AppBlockingService.applyViceAppBlocks` clears `blockedApplications` as a
safety net — but only when the user next opens Clepsy. A user who doesn't connect "my apps vanished"
with "open Clepsy" stays stuck.

The sleep is a defensible choice (an async dispatch might not run at all before teardown), so this is
a risk to measure on device, not an obvious bug. Worth testing: how often does the extension survive
the full second?

### R-02 · Spend thresholds are capped at 180, coupling them to the earning ceiling 🟠
**Code:** `restartViceMonitoring` / `startViceSpendingMonitoring` — `for minutes in 1...180`

Only 180 `spend_N` thresholds are registered, so **a session meters at most 180 minutes of vice usage.**
Past that, no further thresholds fire, the balance stops draining, and the apps stay unshielded until
`intervalDidEnd` at 23:59.

**Currently harmless** — the earning ceiling (CD-012) caps a day's balance at 180 minutes too, so a
session can't outlive its thresholds. **But CD-012 says remove the earning ceiling**, and the moment
earning exceeds 180/day this becomes free unlimited vice access after 180 metered minutes.

**These two ceilings must move together.** Whoever picks up CD-012 has to fix the spend ladder in the
same change.

**Resolution direction:** CD-036 confirms neither number is a product decision — there is no intended
cap on either side. CD-037 proposes one mechanism (re-arming ladders) that removes both. Until that
lands, the safe interim state is the current one: *leave the earning cap in place*, because it's the
only thing keeping the spending exploit unreachable.

### R-03 · The vice-schedule builder is duplicated, and the in-app copy is unreachable 🟡
`ShieldActionExtension.restartViceMonitoring` (live) and `UsageTrackingService.startViceSpendingMonitoring`
(unreachable) are near-identical ~35-line implementations of the same schedule.

The in-app copy is reached only via `DashboardViewModel.startSpendingSession`, which is called only by
`ShieldConfigurationView` — which is itself dead code presented nowhere but its own `#Preview` (CD-028).
So the entire in-app spending path is dead, and it duplicates the live logic including the CD-032
anchoring subtlety. Fix one and the other silently rots. Same class of hazard as the old duplicated
`min(5, …)` constant.

---

## E. Loose Ends

Small, but each one costs the next reader time.

### CD-026 · `AppDidBecomeActive` notification has no observers 🧹
`ClepsyApp.swift:30` posts it on every foreground. Nothing listens. Left from the pre-`scenePhase`
wiring in `65f849c`.

### CD-027 · `clepsy://` URL scheme is registered but unused 🧹
Declared in `project.yml`. `9db7dd7` added *"wire productive app tap to launch via URL scheme"*; the
tappable app cards were later removed. Nothing opens a URL anywhere in the codebase now.

### CD-028 · In-app `ShieldConfigurationView` is superseded by the extension 🧹
`Clepsy/Views/Shield/ShieldConfigurationView.swift` — plan Task 23's SwiftUI shield, never presented.
Notably it *does* implement several things the real shield can't (mascot, earned-today, "Earn Time
Now"), which is why the specs read as though those exist.

### CD-029 · Hardcoded app lists are superseded by picker tokens 🧹
`AppCategory.defaultViceApps` / `.defaultProductiveApps` and `AppIconView` (whose comment claims
"Used by DashboardView" — it isn't) predate `FamilyActivitySelection`. The dashboard renders system
`Label(token)` views instead. `DashboardViewModel` still loads the hardcoded lists into published
properties nothing reads.

### CD-030 · `UserSettings.exchangeRate` is never read 🧹
Added in `1b18e09` as *"1:1 for MVP, configurable for future."* Nothing consumes it — the 1:1 rate is
implicit in "one threshold = 60 seconds." Harmless, but it implies configurability that doesn't exist.

---

## Summary: what needs a decision from you

### Resolved

| ID | Decision | Status |
|---|---|---|
| CD-012 | **Remove the 180 min/day earning ceiling.** | Decided 08-01 — **not yet done**, and now coupled to R-02 |
| CD-018 | **Hourglass = spendable balance.** Code stands; amend PRD J3 + MVB. | Decided 08-01 — docs pending |
| CD-020 | **Streak = goal-completion days.** Code stands; amend PRD J5. | Confirmed 08-01 — docs pending |
| CD-021 | **5-minute unlock cap rejected.** | Removed in `959da5f` ✅ |
| CD-031 | **Full-balance session, metered by actual usage.** | Shipped in `959da5f` ✅ |
| CD-023 | **Test buttons removed** (deleted, not gated). | Removed in `959da5f` ✅ |

### Resolved 2026-08-04

| ID | Decision |
|---|---|
| CD-024 | **Keep `EarningSessionManager`**, marked unmistakably as not live. |
| CD-022 | **15 / 30 / 45 / 60 / 90 / 120** is canonical; Settings changes to match onboarding. |
| CD-001 | **Apps-only is permanent.** Strike PRD J1 P2; remove the unreachable category paths. |
| CD-036 | **The daily goal is a floor, not a ceiling.** Neither `180` is a product decision. |

### Still open

| ID | Question | Why it matters |
|---|---|---|
| CD-037 | Do re-arming ladders actually work on-device? | Three things to verify; gates CD-012 and R-02 |

### Risks to watch

| ID | Risk | Severity |
|---|---|---|
| R-01 | `Thread.sleep(1.0)` in the monitor extension; if killed mid-sleep, vice app icons stay hidden | 🟠 |
| R-02 | Spend ladder capped at 180 — must be raised in lockstep with CD-012 or it becomes free access | 🟠 |
| R-03 | Vice-schedule builder duplicated; the in-app copy is unreachable dead code | 🟡 |

And three that are documentation-only follow-ups, no decision needed: amend PRD J3 for CD-005,
amend PRD J4 for CD-014, amend PRD J2 for CD-011.
