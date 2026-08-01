# Clepsy Documentation Audit — Docs vs. Built Code

**Date:** 2026-08-01
**Auditor:** Claude (code + doc read-through)
**Repo state:** `main` @ `14984df` ("feat: shield extensions, per-app unlock, and apps-only selection")
**Purpose:** Establish ground truth on what is actually built, catalogue where the written documentation
disagrees with it, and produce a clean basis for migrating documentation from Google Docs into Linear.

> **Companion document:** [`docs/decisions/decision-log.md`](../decisions/decision-log.md) records the
> *implementation decisions* behind these divergences — reconstructed from source comments and commit
> history. Where this audit says "the docs and the code disagree," the decision log says *why the code
> does what it does*, and flags which choices still need the owner's call. Read the decision log first;
> most of what looks like drift here is an undocumented decision there.
>
> **Careful with "5 minutes" and "2 minutes"** — there are three unrelated pairs in this codebase:
> the dashboard's +5/−2 test buttons (scaffolding, CD-023), the shield's 5-minute unlock cap
> (production, CD-021), and `EarningSessionManager`'s 2-minute pause / 5-minute credit interval (the
> spec's values, in code that never runs, CD-024).

---

## 1. Scope & Method

### Sources reviewed

| Source | Title | Last modified | Repo mirror |
|---|---|---|---|
| [Doc 1](https://docs.google.com/document/d/192FcQyHHJP4nJR-qNwbHTbdHo0ZvObw-QS-j4A-RpFU/edit) | *Productivity app MVB* | 2026-08-01 | `docs/plans/mvb-brand-guide.md`, `docs/specs/*.md` |
| [Doc 2](https://docs.google.com/document/d/1Nz1CP88mcSxuU0wye9r8fOJbnqVt9uoNukAAsB74sss/edit) | *Productivity app notes:* | 2026-08-01 | `docs/plans/prd.md` |
| [Doc 3](https://docs.google.com/document/d/1BO8-84u8Psky4uBhDkb1sfCsdVOCEK4JEmBdNXbFwYw/edit) | *Copy of Productivity app notes: – January 25* | 2026-08-01 | — (not mirrored) |

Doc 1 is a multi-tab omnibus: MVB brand doc + onboarding specs + dashboard specs + earning specs +
settings specs + error-state specs + notification specs + mascot asset guide + a "FEATURES for PRD"
backlog. Doc 2 holds Product Principles, PRD v1.0, scratch notes, a "Dropped from MVP" list, and
**PRD v2.1 (Jan 30, 2025)** — v2.1 is the operative PRD. Doc 3 is a stale partial copy of Doc 2
(notes + dropped-from-MVP only) with no unique content.

The repo already carries markdown mirrors of most of this under `docs/`. Content matches the Google
Docs closely, so the divergences below apply equally to both copies.

### Code reviewed

All 29 Swift sources across 4 targets (`Clepsy`, `ClepsyMonitor`, `ClepsyShieldConfiguration`,
`ClepsyShieldAction`), 11 test files, `project.yml`, and the asset catalog.

### Limitation

This is a static read. The project could not be built or run — it needs macOS + Xcode + XcodeGen, and
Screen Time behavior needs a physical device with a paid developer account. Nothing below is a
runtime observation; "not implemented" means "no code path exists," not "tested and broken."

---

## 2. Executive Summary

**The app is materially further along than the docs suggest in some places, and materially behind
them in others — and the two lists barely overlap.**

The single most important finding: **the core earning and spending mechanics that shipped are not the
mechanics the docs specify.** This is not drift in copy or layout; it is a different economic model.

1. **Earning** is documented as a session engine (60s warmup → session → 2-min pause timeout →
   credit every 5 min). What shipped is DeviceActivity threshold-based accrual: 180 fixed thresholds
   at 1-minute intervals, crediting 60 seconds each. `EarningSessionManager.swift` — the class that
   implements the documented behavior — exists, is fully unit-tested, and **is referenced by nothing
   in the app.** It is dead code.
2. **Spending** is documented as real-time metered deduction while the user scrolls, with automatic
   re-shielding at zero balance. What shipped is a **prepaid unlock**: tap the shield, get charged up
   to 5 minutes up front, app unshields for exactly that window, then re-shields on a scheduled
   DeviceActivity event. Usage is never metered.
3. **Notifications** — a P0 in the PRD, with a full spec chapter and a working-looking Settings UI —
   have **no implementation at all**. `UNUserNotificationCenter` does not appear anywhere in the
   codebase. The Settings toggle and interval picker are inert, and the interval value isn't even
   persisted.
4. Conversely, **three app extensions, a per-app unlock registry, shield-cache staleness handling,
   and an apps-only selection rule** were built and are entirely undocumented. The shield extensions
   are the largest single engineering surface in the repo and appear in no spec.

Net: the docs describe an app that would behave noticeably differently from the one in the repo. A
new engineer or PM reading `docs/` today would be misled about the product's central loop.

### Rough completeness against PRD v2.1 P0s

| Journey | P0 items | Built | Partial | Missing |
|---|---|---|---|---|
| J1 First-time setup | 9 | 5 | 2 | 2 |
| J2 Earning time | 6 | 2 | 2 | 2 |
| J3 The block (shield) | 9 | 4 | 1 | 4 |
| J4 Unlock & spend | 12 | 4 | 3 | 5 |
| J5 Dashboard & history | 8 | 3 | 1 | 4 |
| J6 Settings & errors | 12 | 5 | 2 | 5 |
| **Total** | **56** | **23 (41%)** | **11 (20%)** | **22 (39%)** |

Detail in §5.

---

## 3. What Is Actually Built (ground truth)

Written as the docs should describe it.

### Architecture

- SwiftUI + MVVM, iOS 16.0 deployment target, XcodeGen-generated project.
- **Four targets**, not two: the app, `ClepsyMonitor` (DeviceActivityMonitor),
  `ClepsyShieldConfiguration` (custom shield UI), `ClepsyShieldAction` (shield button handling).
- App Group `group.com.clepsy.shared` carries all app↔extension state.
- `SharedStorageService` is compiled into all four targets and is the sole cross-process contract.

### Earning loop (as built)

1. On launch/foreground, `UsageTrackingService.startDailyMonitoring` registers one DeviceActivity
   schedule (`productiveApps`, 00:00–23:59, repeating) with **180 threshold events**
   (`earn_1` … `earn_180`), one per minute of cumulative daily productive-app usage.
2. Each threshold fires `DeviceActivityMonitorExtension.eventDidReachThreshold`, which appends a
   `TimeEvent(seconds: 60, type: .earned)` to a JSON file in the App Group container via
   `NSFileCoordinator`, and updates a `pendingDeltaSeconds` mirror in shared `UserDefaults`.
3. On next foreground, `DashboardViewModel.syncPendingEvents` drains the file, applies the deltas to
   the balance, persists, then **discards the events**.

Consequences worth documenting: there is no warmup, no session concept, granularity is 1 minute, the
credit is delayed until the user next opens Clepsy (the shield reads a separate live mirror), and
there is a hard, undocumented **180-minute/day earning ceiling**.

### Spending loop (as built)

1. Vice apps are shielded by `ManagedSettingsStore.shield.applications`.
2. `ShieldConfigurationExtension` renders the shield: reads `fastBalanceSeconds()` (UserDefaults-only,
   for speed), shows "Unlock for N min" where **N = min(5, balance minutes)**, or a zero-balance
   "Go Back" screen. It records which variant it showed, keyed by token, because iOS caches shields.
3. `ShieldActionExtension` on primary tap: charges the full N minutes up front as a `.spent`
   `TimeEvent`, removes that one app's token from the shield set, registers the unlock in an
   `activeUnlocks` registry with an expiry, and schedules a one-shot `unlock_<uuid>` DeviceActivity
   whose interval end triggers the re-lock. If balance is zero but the shield showed a stale
   "unlock" screen, it returns `.defer` to force a redraw.
4. `DeviceActivityMonitorExtension.intervalDidEnd` re-shields the single app (or the whole selection
   for the legacy category path), skipping apps still inside their own unlock windows.
5. `ClepsyApp.reapplyBlocksIfNeeded` re-applies shields on foreground **unless** an unlock window is
   live, so opening Clepsy doesn't cut an unlock short.

### Selection model (as built)

Onboarding and Settings both **reject `FamilyActivitySelection` category tokens** and require
individual app tokens, because a category token cannot be unshielded per-app. Users get an inline
warning and the Continue button stays disabled. Vestigial category-handling code remains in
`AppBlockingService`, `ShieldActionExtension.handle(for category:)`, and the monitor extension.

### Screens (as built)

- **Onboarding, 5 steps:** Welcome (mascot + 4 feature rows) → Permission → Vice app picker →
  Productive app picker → Daily goal. Then a 2.5s celebration overlay on the dashboard.
- **Dashboard:** header, balance hero card (animated mascot + pulsing glow, balance, inline
  Earned/Spent), conditional streak banner, goal progress card, blocked-apps list, productive-apps
  list, and a **"Test Actions" +5min/−2min section** — a Simulator test harness for the
  earning/spending UI that is currently not behind `#if DEBUG` (CD-023).
- **Settings:** 6 sections matching the spec's structure — Daily Goal, Vice Apps, Productive Apps,
  Notifications, Account & Data, About (with How Clepsy Works, Privacy, Terms, Feedback, version).

### Mascot

Decoupled ZStack: body asset by fill level (0/25/50/75/100 at 12.5% boundaries) + face. Patient and
Encouraging use programmatic eyes (`ClepsyEyesView`) plus a mouth image; Celebrating uses a full face
image plus 6 animated sparkles. Float amplitude/duration, body rock, breathing scale, and face nod
are all **expression-driven** (patient 5pt/4.0s → celebrating 10pt/1.8s).

---

## 4. Mechanic-Level Divergences (the ones that matter)

### D1 — Earning engine: documented session model vs. shipped threshold model 🔴

| | Docs (`docs/specs/earning.md`, PRD J2, plan Task 21B) | Code |
|---|---|---|
| Warmup | 60 consecutive seconds before tracking starts | None — first credit at 1 min of cumulative daily usage |
| Sessions | Start/pause/resume/end with 2-min pause timeout | No session concept |
| Screen lock | Pauses tracking immediately | Handled implicitly by iOS (usage doesn't accrue), not by app logic |
| Credit cadence | Balance updated every 5 minutes and at session end | Every 1 minute, via threshold events |
| Credit visibility | On session end | Deferred to next app foreground for the in-app balance; shield reads a live mirror |
| Daily ceiling | None specified | **180 min/day hard cap** (thresholds only go to `earn_180`) |
| Implementation | `EarningSessionManager` | `EarningSessionManager` exists, is tested, **and is never called** |

The 180-minute cap is especially notable: Doc 2's "Dropped from MVP" section explicitly *removed* a
daily earning cap from scope, yet the implementation has one as an artifact of how the thresholds
were enumerated.

**Decision needed:** is the session model still the target (wire up `EarningSessionManager`), or is
threshold accrual the accepted design (rewrite `earning.md`, delete the class)? Everything in the
earning spec, PRD J2, plan Task 21B, and the CHANGELOG's headline item depends on the answer.

### D2 — Spending: real-time deduction vs. prepaid window 🔴

PRD J4 P0s: *"System tracks vice app usage in real-time (1-second increments)"*, *"deducts time from
bank as user scrolls"*, *"automatically re-shields app when balance hits zero mid-session — app locks
immediately, no grace period."*

Built: charge up-front, unshield for a fixed window, re-shield on schedule. A user who unlocks 5
minutes and uses 40 seconds still pays 5 minutes; a user with 60 minutes banked still only gets 5
minutes per tap. `DeviceActivityName.viceApps` monitoring is **never started** — the handler exists in
the extension but nothing registers the schedule.

This is defensible (real-time metering on iOS is genuinely hard, and prepaid windows are far more
reliable), but it is a different product promise and the PRD's Painkiller value prop —
*"you see exactly what it costs"* — is weakened by the flat 5-minute cap. Nothing in any doc mentions
5 minutes.

### D3 — Notifications: fully specified, zero implementation 🔴

PRD J2 P0 (milestone notifications), J6 P0 (change threshold / disable all), plus a full notification
chapter in Doc 1 with copy, timing rules, `UNUserNotificationCenter` code, tap handling, and a
delivery matrix. Doc 1 also specifies low-balance, time-expired, weekly-summary, and fresh-start
notifications.

Code: **no notification framework import anywhere.** `UserSettings.notificationsEnabled` is
persisted but never read by anything that sends a notification. Worse, `SettingsView` presents a
working-looking toggle and an interval picker whose value **`milestoneInterval` is never persisted** —
`SettingsViewModel.saveSettings()` only writes `dailyGoalMinutes` and `notificationsEnabled`, and
`UserSettings` has no field for it. The setting silently resets to 15 on every launch.

### D4 — Balance history: specified as P0, not stored at all 🟠

PRD J5 P0s call for lists of recent earning and spending sessions with app name, duration, and
timestamp. `TimeEvent` carries exactly those fields — but `syncPendingEvents` calls `clearEvents()`
immediately after applying them. **No history is retained.** There is no history UI, and no
persistence layer that could back one.

Related: `todayEarned` / `todaySpent` are in-memory `@Published` ints, never persisted. Force-quit
and relaunch mid-day and both show 0, which also zeroes the goal-progress bar and the mascot's
expression logic while the balance itself survives.

### D5 — Daily expiration: single trigger, not "multiple triggers" 🟠

`data-architecture.md` calls launch-only reset checking a "CRITICAL FIX" problem and specifies checks
on multiple triggers. Code checks in exactly one place: `DashboardView.onAppear`. The `scenePhase`
handler calls `syncPendingEvents()` but not `checkAndPerformDailyReset()`. An app resident in the
background across midnight keeps yesterday's balance until it's fully relaunched.

Also: PRD P0 *"if user is mid-session in a vice app at 11:59 PM, app locks at 12:00 AM"* has no
implementation — nothing re-shields at midnight, and an unlock window straddling midnight is
unaffected by the reset.

### D6 — Shield content 🟠

| PRD J3 P0 | Built |
|---|---|
| Shows current available balance | ✅ "You have N min available." |
| Shows expiration indicator ("Expires at midnight (5 hours remaining)") | ❌ |
| Shows last-updated timestamp ("Updated 30 seconds ago") | ❌ |
| Button "Unlock [App] for [X] minutes" with exact available time | ⚠️ Capped at 5 min |
| Prominently features Clepsy in Patient state | ❌ Static `shield_icon` image; no such asset in the catalog |
| Sand level reflects goal progress | ❌ |
| Zero-balance distinguishes "Fresh Start" (post-midnight) vs. "spent it all" | ❌ Single generic message |
| "Earn Time Now" button opens the main app | ❌ Shield extensions can't launch apps; zero-balance shows "Go Back" |

The "Earn Time Now" requirement is worth flagging as a **platform constraint the PRD doesn't know
about** — a ShieldAction extension cannot open the containing app. The code comments this correctly.
The PRD should be amended rather than the code.

Note also that `Clepsy/Views/Shield/ShieldConfigurationView.swift` — the in-app SwiftUI shield from
plan Task 23, which *does* show the mascot, balance, earned-today, and an "Earn Time Now" button — is
**dead code**. It is never presented. The real shield is the extension. Two different shields are
documented as one.

### D7 — Categories: P2 feature actively forbidden 🟡

PRD J1 P2: *"User can select app categories (Social Media, News, Gaming) to block entire groups."*
Code deliberately blocks this in both pickers with a warning, because per-app unlock is impossible
for category tokens. That's a sound engineering decision that reverses a documented requirement, and
it's recorded nowhere but in source comments. Meanwhile partial category support still exists in
`AppBlockingService.applyViceAppBlocks`, the monitor's `reapplyViceShields`, and
`ShieldActionExtension.handle(for category:)` — so the codebase is internally inconsistent about
whether categories are supported.

### D8 — Exchange rate 🟡

`UserSettings.exchangeRate` exists, defaults to 1.0, is asserted in tests, and is **read by no
production code**. Matches the PRD's 1:1 non-goal in effect, but it's a field that implies
configurability that doesn't exist.

---

## 5. PRD v2.1 P0 Traceability

Legend: ✅ built · ⚠️ partial · ❌ missing

### Journey 1 — First-Time User Setup

| P0 requirement | Status | Notes |
|---|---|---|
| Explanation of how time-trading works | ✅ | `WelcomeView` — 4 feature rows incl. midnight reset |
| Grant Family Controls permission with rationale first | ✅ | `PermissionView` |
| Error message if permission denied, with retry | ❌ | `PermissionView` advances regardless of outcome; Screen 2B / Error 1A unimplemented |
| See list of common vice apps | ⚠️ | System `familyActivityPicker` only; `AppCategory.defaultViceApps` is unused |
| Select vice apps (min 1 required) | ✅ | Continue disabled until ≥1 app token |
| Search for apps not in suggested list | ✅ | Provided by the system picker |
| See list of common productive apps | ⚠️ | Same as above |
| Select productive apps (min 1) | ✅ | |
| Set milestone notification preference (default 15 min) | ❌ | No onboarding step; setting exists in Settings but is inert |

### Journey 2 — Earning Time

| P0 requirement | Status | Notes |
|---|---|---|
| 60-second warmup | ❌ | See D1 |
| Session pause/resume, 2-min timeout | ❌ | See D1 |
| Screen lock pauses tracking | ⚠️ | Satisfied by iOS not accruing usage, not by app logic |
| Background monitoring via DeviceActivityMonitor | ✅ | `ClepsyMonitor` |
| Milestone notification on earning threshold | ❌ | See D3 |
| Tap notification → open app to balance | ❌ | See D3 |

### Journey 3 — The Block

| P0 requirement | Status | Notes |
|---|---|---|
| Custom shield on blocked app | ✅ | `ShieldConfigurationExtension` |
| Shield shows available balance | ✅ | |
| Shield shows expiration indicator | ❌ | |
| Shield shows last-updated timestamp | ❌ | |
| Unlock button showing exact available time | ⚠️ | Capped at 5 min |
| Clepsy character in Patient state on shield | ❌ | Missing `shield_icon` asset |
| Sand level reflects goal progress on shield | ❌ | |
| Zero-balance shield state | ✅ | Generic copy |
| Zero-balance reason (Fresh Start vs. spent) | ❌ | |

### Journey 4 — Unlock & Spend

| P0 requirement | Status | Notes |
|---|---|---|
| Tap unlock button on shield | ✅ | |
| System records claimed amount + timestamp | ✅ | `.spent` `TimeEvent` |
| Removes shield for exact duration | ✅ | Per-app, scheduled re-lock |
| Vice app opens immediately | ✅ | `.none` response |
| Real-time usage tracking (1s increments) | ❌ | See D2 |
| Deduct as user scrolls | ❌ | Charged up front |
| Auto re-shield when balance hits zero mid-session | ❌ | N/A in prepaid model |
| Switch between vice apps on shared bank | ⚠️ | Bank is shared, but each app needs its own unlock + charge |
| Deduct from same bank regardless of app | ✅ | |
| Reset bank to zero at midnight (local) | ⚠️ | Only on full relaunch — see D5 |
| Fresh Start explanation next morning | ❌ | |
| Midnight reset with no grace period (locks mid-session) | ❌ | Nothing re-shields at midnight |
| Handle timezone changes | ⚠️ | Uses `Calendar.current`; MVP simplification is documented and matches |

### Journey 5 — Dashboard

| P0 requirement | Status | Notes |
|---|---|---|
| Current balance prominently displayed | ✅ | Hero card |
| …with expiration indicator | ❌ | |
| Visual countdown to midnight reset | ❌ | |
| Today's earned time | ⚠️ | Shown, but not persisted across relaunch (D4) |
| Today's spent time | ⚠️ | Same |
| List of recent earning sessions | ❌ | No history stored (D4) |
| List of recent spending sessions | ❌ | Same |
| Streak counter (P1, but built) | ✅ | Built ahead of spec — see §6 |

### Journey 6 — Settings, Errors, Edge Cases

| P0 requirement | Status | Notes |
|---|---|---|
| Add vice apps | ✅ | |
| Add productive apps | ✅ | Re-registers the earning schedule |
| Prevent same app in both lists (with toast) | ❌ | No conflict detection at all |
| Enforce ≥1 app in each list | ⚠️ | Enforced in onboarding, **not** in Settings — a user can clear both lists post-setup |
| Change milestone notification threshold | ❌ | UI exists, value not persisted, no notifications (D3) |
| Disable all notifications | ⚠️ | Toggle persists, but controls nothing |
| See app version / iOS compatibility | ⚠️ | Version yes; iOS compatibility no |
| Error if Family Controls permission revoked | ❌ | No detection, no banner (dashboard §3.1B unbuilt) |
| Error if DeviceActivityReport fails, with manual refresh | ❌ | `DeviceActivityReport` is not used anywhere; no pull-to-refresh |
| Handle phone restart gracefully | ✅ | Shields persist (iOS); balance in UserDefaults |
| Handle timezone changes | ⚠️ | Per MVP simplification |
| Reset all data (P2, but built) | ✅ | With confirmation alert |

---

## 6. Built But Undocumented

These need to be **written into** the docs, not fixed in code.

| # | Feature | Where |
|---|---|---|
| U1 | **`ClepsyShieldConfiguration` extension** — custom shield UI, brand colors, dual balance/zero-balance states | No spec mentions it |
| U2 | **`ClepsyShieldAction` extension** — unlock handling, category legacy path | No spec |
| U3 | **Per-app unlock registry** — `activeUnlocks` keyed by DeviceActivity name, expiry pruning, per-app re-lock | No spec |
| U4 | **Shield-cache staleness handling** — `shieldShowedBalanceByToken` + `.defer` to force redraw when iOS serves a cached shield | No spec; genuinely subtle, must be documented |
| U5 | **`fastBalanceSeconds()` / `pendingDeltaSeconds`** — UserDefaults-only fast path because the config extension gets killed if slow | No spec |
| U6 | **Apps-only selection rule** — categories rejected in both pickers | Contradicts PRD J1 P2 (D7) |
| U7 | **5-minute unlock cap** | No doc mentions any cap |
| U8 | **180-min/day earning ceiling** | No doc; contradicts "Dropped from MVP" |
| U9 | **Streak system** — count, banner, tiered messages, dismiss | PRD lists streak as P1; built. But it counts *goal-met* days, while PRD J5 defines it as *earning-activity* days |
| U10 | **Onboarding celebration overlay** | Replaces spec Screen 6; different pattern (2.5s auto-dismissing overlay, not a screen) |
| U11 | **Expression-driven mascot animation** | Asset guide specifies one float: 10pt / 3.5s. Code varies amplitude 5–10pt and duration 1.8–4.0s by expression, plus breathing, body rock, face nod, sparkles |
| U12 | **Programmatic eyes + mouth assets** | `ClepsyEyesView`, `patience_mouth`, `encouraging_mouth` — not in the asset guide's 27-file inventory |
| U13 | **`reapplyBlocksIfNeeded`** — foregrounding Clepsy must not cut an active unlock short | No spec |
| U14 | **Unlock windows backdated 16 min** to satisfy DeviceActivity's 15-minute minimum interval | No spec; important platform constraint |
| U15 | **URL scheme `clepsy://`** registered in `project.yml` | Unused, undocumented |

---

## 7. Documentation Hygiene

### H1 — Broken internal references (14)

Docs reference paths that don't exist. These break every "see X" pointer in the plan and CHANGELOG:

```
clepsy_app_images/                       docs/dashboard_specs.md
clepsy_app_images/clepsy_mascot_asset_guide.md   docs/earning_specs.md
dashboard_specs.md                       docs/onboarding_specs.md
earning_specs.md                         docs/settings_specs.md
error_state_specs.md                     docs/clepsy_mvb.md
onboarding_specs.md                      docs/clepsy_prd.md
settings_specs.md                        docs/testing/mvp-test-checklist.md
```

Actual locations are `docs/specs/*.md`, `docs/plans/*.md`, `design/assets/`. The old flat names
were never updated after the `docs/` reorganization.

### H2 — `docs/CHANGELOG.md` is a pre-implementation artifact

Dated 2026-02-01, written as a *proposal* awaiting approval — it ends with "Questions Before
Starting?" and "Ready to Begin Task 0?" It has never been updated, so the file that should be the
project's history instead reads as though no code exists. Every commit since is unrecorded.

### H3 — `README.md` is stale

- Says Screen Time features require *"uncomment the entitlements in `project.yml`"* and *"uncomment
  the ClepsyMonitor dependency."* Both are **already active and uncommented** in `project.yml`.
- Project structure lists `ClepsyMonitor/` only. `ClepsyShieldAction/` and
  `ClepsyShieldConfiguration/` are missing entirely.
- Doesn't mention `docs/`, `design/`, or the App Group requirement.
- The design-system table is accurate; `clepsyBrown` (`#8B6F47`) is in the theme but absent from the
  README table.

### H4 — `docs/plans/clepsy_mvp.md` has no completion state

3,560 lines, 30 tasks, no task marked done. Tasks 8–13 describe an onboarding flow that doesn't match
what shipped (Task 9's separate "How It Works" screen was folded into Welcome; Task 12's "Ready"
screen became an overlay). Task 23 describes the in-app shield view that ended up dead code. There's
no task covering the shield extensions, which is where most post-plan work went.

### H5 — Doc 3 is a redundant stale copy

*"Copy of Productivity app notes: - January 25, 5:30 PM"* contains only Notes and Dropped-from-MVP,
both present and more current in Doc 2. No unique content. Recommend archiving rather than migrating.

### H6 — Doc 1 mixes four document types in one file

Brand strategy, six UI specs, a mascot asset guide, and a feature backlog live in one Google Doc.
This is the main reason the specs are hard to keep current — there's no natural unit to update or
review. The repo mirror already splits them correctly; the Google Doc doesn't.

### H7 — Two PRDs in one document

Doc 2 contains PRD v1.0 (Jan 24) and PRD v2.1 (Jan 30) in full, sequentially, with no marker that v1
is superseded. `docs/plans/prd.md` mirrors this. Anyone reading top-down gets the obsolete version
first.

### H8 — Internal inconsistencies within the specs themselves

- Onboarding spec header says *"Target: 5 screens total"* but then specifies **six** screens (1, 2,
  2B, 3, 4, 5, 6).
- Daily-goal options differ across three places: onboarding spec (15/30/60/120/Custom), settings
  spec (15 min–4 hr in 15-min increments), onboarding code (15/30/45/60/90/120), settings code
  (15/30/60/120/180/240). Four different sets.
- CHANGELOG says the plan has 30 tasks (0–30 with 21B); the plan's last task is 29.

---

## 8. Code Issues Surfaced During the Audit

Not documentation problems, but they change what the docs should say. Listed by severity.

| # | Issue | Location |
|---|---|---|
| C1 | **Development scaffolding is not gated.** The "Test Actions" +5min/−2min buttons are a deliberate Simulator test harness for the earning/spending UI (confirmed by the owner — the 5 and 2 are arbitrary test amounts, not product values), but they carry no `#if DEBUG` guard, so they ship to TestFlight/App Store as a user-facing section that grants free balance. See CD-023. | `DashboardView.swift:332` |
| C2 | **`milestoneInterval` is never persisted.** `didSet` calls `saveSettings()`, which doesn't write it; `UserSettings` has no such field. Silently resets to 15. | `SettingsViewModel.swift:16` |
| C3 | **`todayEarned`/`todaySpent` are in-memory only.** Lost on relaunch, taking goal progress and mascot expression with them. | `DashboardViewModel.swift:8` |
| C4 | **Daily reset checked only in `onAppear`.** Backgrounded app misses midnight. | `DashboardViewModel.swift:136`, `DashboardView.swift:59` |
| C5 | **Settings can leave the user with zero vice or productive apps**, unlike onboarding. Silently disables the product. | `SettingsViewModel.swift:20` |
| C6 | **No vice/productive conflict detection** (PRD P0). An app can be in both lists; behavior then is undefined. | — |
| C7 | **Streak semantics differ from PRD** (goal-met days vs. earning days), and `clepsy_streak_goal_met_today` is cleared only in `performReset()` — which the nil-`lastResetDate` branch of `checkAndPerformDailyReset` bypasses. | `DashboardViewModel.swift:161` |
| C8 | **`resetAllData()` doesn't clear streak keys** — they live in standard `UserDefaults` under `clepsy_streak_*`, outside `PersistenceService.clearAll()`. "Start fresh" keeps the streak. | `SettingsViewModel.swift:122` |
| C9 | **Missing asset `shield_icon`** referenced by the shield extension; not in `Assets.xcassets`. Shield renders with no icon. | `ShieldConfigurationExtension.swift:52` |
| C10 | **Dead code:** `EarningSessionManager`, `ShieldConfigurationView`, `AppIconView` (its comment claims DashboardView uses it — it doesn't), `AppCategory.defaultViceApps`/`defaultProductiveApps` (loaded into `DashboardViewModel` but never rendered), `TimeBalance.formattedTime`, `UserSettings.exchangeRate`. Roughly 400 lines. | various |
| C11 | **`saveTimeBalance` constructs a `SharedStorageService()` on every call**, each one hitting `createDirectory` and a `containerURL` lookup. Same pattern in `AppBlockingService.applyViceAppBlocks`. | `PersistenceService.swift:33` |
| C12 | **Data-architecture doc's storage description is wrong.** It documents `pendingTimeEvents` as an App Group *UserDefaults key*; the implementation uses a **file** (`pendingTimeEvents.json`) with `NSFileCoordinator`. The doc's key table also omits every key actually in use: `viceSelection`, `productiveSelection`, `balanceSeconds`, `pendingDeltaSeconds`, `activeUnlocks`, `shieldShowedBalanceByToken`, `unlockExpiresAt`, `clepsy_streak_*`. | `docs/data-architecture.md:293` |

---

## 9. Recommended Target Doc Set (for Linear migration)

The current structure doesn't map cleanly onto Linear because one Google Doc holds four document
types and the specs mix "what we want" with "what we built." Proposed shape:

### Keep as living documents (Linear docs, or repo `docs/`)

| Document | Source | Action |
|---|---|---|
| **PRD** | Doc 2 → PRD v2.1 only | Cut v1.0. Amend J2/J4 to match the shipped mechanics (D1, D2) or explicitly re-scope them as future work. Amend J3 "Earn Time Now" for the platform constraint. Reconcile the J1 P2 category requirement with the apps-only rule. |
| **Product Principles** | Doc 2, Tab 4 | Migrate as-is — no code conflict |
| **Brand / MVB** | Doc 1, MVB tab | Migrate as-is. Add the expression-driven animation table (U11) and the programmatic-face assets (U12) |
| **Architecture** | `docs/data-architecture.md` | Rewrite storage section (C12). Add the four-target layout, App Group contract, and the full key inventory |
| **Shield & Unlock Spec** | **new** | The biggest gap — covers U1–U5, U7, U13, U14. Nothing exists |
| **Earning Spec** | `docs/specs/earning.md` | Rewrite once D1 is decided |
| **Onboarding / Dashboard / Settings specs** | Doc 1 | Update to shipped screens; mark unbuilt sections as backlog rather than spec |
| **Error States** | Doc 1 | Currently ~0% implemented. Convert wholesale into Linear issues |
| **Notification Spec** | Doc 1 | Currently 0% implemented. Convert into a Linear project |

### Convert into Linear issues, don't migrate as docs

- `docs/plans/clepsy_mvp.md` — a 30-task implementation plan that's mostly executed. Its residual
  value is the unbuilt tasks; the rest is history. Close it out, don't port it.
- Doc 1's "FEATURES for PRD" backlog (accounts, leaderboards, stats sharing, social proof,
  multiplayer) — that's a backlog, not a spec.
- Doc 2's V1.5/V2 Future Considerations — same.
- Doc 2's Notes section — raw idea capture; port to a Linear "Ideas" project.

### Archive

- **Doc 3** entirely (H5).
- **PRD v1.0** within Doc 2 (H7).
- `docs/CHANGELOG.md` in its current form (H2) — replace with a real changelog going forward.

### Suggested Linear structure

```
Project: Clepsy MVP
├─ Epic: Earning engine          → D1 (decide + reconcile), U8, C3
├─ Epic: Spending & shield       → D2, D6, U1–U5, U7, C9
├─ Epic: Notifications           → D3, C2   (0% built, fully specified)
├─ Epic: History & analytics     → D4       (P0 in PRD, 0% built)
├─ Epic: Daily expiration        → D5, C4, C7
├─ Epic: Error states            → J6 error P0s, dashboard §3.1B, onboarding 2B
├─ Epic: Settings hardening      → C5, C6, C8
└─ Epic: Docs & hygiene          → H1–H8, C1, C10
```

---

## 10. Open Questions for the Product Owner

These block a clean doc rewrite — each changes what the updated PRD says.

1. **Earning model (D1):** is threshold-based accrual the accepted design, or should
   `EarningSessionManager` be wired up? The warmup/session rules exist only on paper today.
2. **Spending model (D2):** is the prepaid 5-minute unlock the MVP model? If yes, the PRD's
   real-time-deduction P0s need rewriting and the 5-minute cap needs a rationale in the docs.
3. **Unlock cap:** why 5 minutes, and should it scale with balance or be user-configurable?
4. **180-minute earning ceiling (U8):** intentional, or an artifact to remove?
5. **Notifications (D3):** still P0 for launch? If yes it's a full epic. If not, the Settings UI
   should be hidden until it works — it currently promises something that doesn't exist.
6. **History (D4):** PRD marks earning/spending history P0. Nothing is stored. Keep as P0 (needs a
   persistence layer) or defer to V1.1?
7. **Categories (D7):** accept apps-only permanently and strike the P2 requirement, or keep category
   blocking as a future goal with all-or-nothing unlock?
8. **Streak definition (U9):** goal-met days (as built) or earning-activity days (as specified)?
9. **Google Docs after migration:** freeze read-only with a pointer to Linear, or delete? Recommend
   freezing Doc 1/Doc 2 and archiving Doc 3.

---

## Appendix A — File Inventory

**Production Swift (29 files, ~2,400 lines)**

```
Clepsy/
  ClepsyApp.swift                          entry, scenePhase, block reapplication
  Models/         AppCategory, TimeBalance, TimeEvent, UserSettings
  Services/       AppBlockingService, EarningSessionManager (dead), PersistenceService,
                  ScreenTimeService, SharedStorageService, UsageTrackingService
  ViewModels/     DashboardViewModel, OnboardingViewModel, SettingsViewModel
  Views/
    Onboarding/   Welcome, Permission, AppSelection (vice + productive), DailyGoal, Container
    Dashboard/    DashboardView
    Settings/     SettingsView (+ GoalPicker, IntervalPicker, About), SettingsAppSelectionView
    Shield/       ShieldConfigurationView (dead)
    Components/   ClepsyCharacterView, ClepsyEyesView
  Theme/          ClepsyTheme
ClepsyMonitor/              DeviceActivityMonitorExtension
ClepsyShieldAction/         ShieldActionExtension
ClepsyShieldConfiguration/  ShieldConfigurationExtension
```

**Tests (11 files):** models ×4, services ×5, view models ×2. No tests for
`UsageTrackingService`, the three extensions, or any view. `EarningSessionManagerTests` (167 lines)
is the largest test file and covers code the app never runs.

**Docs (12 files, ~7,500 lines):** `README.md`, `docs/{CHANGELOG,data-architecture,mac-setup-guide,
simulator-testing-guide}.md`, `docs/plans/{clepsy_mvp,mvb-brand-guide,prd}.md`,
`docs/specs/{dashboard,earning,error-states,onboarding,settings}.md`,
`design/assets/clepsy_mascot_asset_guide.md`.

## Appendix B — Assets

27 mascot PNGs in `design/assets/` at @1x/@2x/@3x (5 body levels × 3 + 3 faces × 3), matching the
asset guide. `Clepsy/Assets.xcassets` additionally carries `clepsy_mascot`, `patience_mouth`,
`encouraging_mouth`, and `AppIcon`. **`shield_icon` is referenced by the shield extension and does
not exist** (C9).
