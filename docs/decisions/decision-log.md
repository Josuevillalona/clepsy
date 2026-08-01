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

### CD-001 · Selections must be individual apps, never categories 🔒 ⤴️
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

### CD-010 · Each unlock gets its own registry entry and re-lock schedule ✅
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

### CD-020 · Streak counts goal-met days, not earning days ❓ ⤴️ *(answered ambiguously 2026-08-01 — needs one word)*

> **Owner replied "correct"** — which is ambiguous here, because affirming the *code* and affirming the
> *recommendation* point in opposite directions. Either read is plausible; resolve before acting:
> **(a)** goal-met days is right → keep the code, amend PRD J5's "consecutive days with earning
> activity" definition. **(b)** the analysis is right → change the code to count any day with earning
> activity, keep the PRD. Everything else below is unaffected either way.

**Code:** `DashboardViewModel.incrementStreak` — fires from `addTime` when `goalProgressPercentage >= 1.0`

**Conflicts with:** PRD J5, which defines the streak as *"consecutive days with earning activity"* and
frames it as "Fresh Start Streak" celebrating users who earn *anything* daily.

**Needs a call:** goal-met is a much harder bar. A user who earns 20 of a 30-minute goal every day
for a month has a streak of zero. Given the PRD's stated goal is *"complete at least 1 productive
session every day,"* the earning-activity definition matches the strategy better.

**Also:** the `clepsy_streak_*` keys live in standard `UserDefaults` outside
`PersistenceService.clearAll()`, so "Reset all data" preserves the streak.

### CD-021 · Unlocks are capped at 5 minutes ❓
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

### CD-022 · Daily goal options differ between onboarding and Settings ❓
Onboarding: `[15, 30, 45, 60, 90, 120]` · Settings: `[15, 30, 60, 120, 180, 240]`

A user who picks 45 or 90 in onboarding cannot see or re-select that value in Settings' wheel picker.
Neither set matches either spec. Almost certainly unintentional.

---

## D. Development Scaffolding

Built to make progress without a physical device — the whole Screen Time surface is untestable in the
Simulator. These are **not** product behavior, but they currently ship as if they were.

### CD-023 · Dashboard "+5 min / −2 min" test buttons 🧪
**Code:** `DashboardView.testActionsSection` (`DashboardView.swift:332`)

Manual balance controls added to exercise the earning/spending UI without DeviceActivity. The 5 and 2
are arbitrary test amounts, not product values.

**Risk:** they are **not** behind `#if DEBUG`, so they ship to TestFlight and the App Store as a
user-facing "Test Actions" section that grants free balance. Gate or remove before any external
build. (Guarding them is a 2-line change.)

### CD-024 · `EarningSessionManager` is a spec-faithful reference implementation, unused 🧪
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

### Resolved 2026-08-01

| ID | Decision |
|---|---|
| CD-012 | **Remove the 180 min/day ceiling.** Needs a spike on how to do it without registering 1,440 events. |
| CD-018 | **Hourglass = spendable balance.** Code stands; amend PRD J3 and the MVB hourglass rationale. |

### Still open

| ID | Question | Why it matters |
|---|---|---|
| CD-020 | Streak = goal-met days or earning days? | Reply was ambiguous — one word settles it |
| CD-021 | Is the 5-minute unlock cap intentional? | Looks like a prototype value; changes the core promise |
| CD-022 | Which daily goal options are canonical? | Two sets; users can strand themselves on 45/90 |
| CD-024 | Keep or delete `EarningSessionManager`? | Its existence is why the earning spec looks live |
| CD-001 | Drop category blocking from the PRD permanently? | Incompatible with per-app unlock |

And three that are documentation-only follow-ups, no decision needed: amend PRD J3 for CD-005,
amend PRD J4 for CD-014, amend PRD J2 for CD-011.
