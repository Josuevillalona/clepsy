#!/usr/bin/env python3
"""Generate a Linear-importable CSV backlog from the audit and decision log.

Regenerate with:  python3 docs/linear/build-import.py
Output:           docs/linear/issues.csv

Priority column uses Linear's scale: 1 Urgent, 2 High, 3 Medium, 4 Low, 0 None.
"""

import csv
import pathlib

URGENT, HIGH, MED, LOW = 1, 2, 3, 4

# (Project, Title, Priority, Labels, Estimate, Description)
ISSUES = [
    # ---------------------------------------------------------------- decisions
    ("Decisions", "Decide: streak counts goal-met days or earning-activity days", HIGH, "decision", 1,
     "CD-020. Code fires the streak only when goalProgressPercentage >= 1.0, so a user earning 20 of a "
     "30-min goal daily never builds a streak. PRD J5 defines it as 'consecutive days with earning "
     "activity'. Pick one: keep the code and amend the PRD, or change the code and keep the PRD.\n\n"
     "Source: docs/decisions/decision-log.md#cd-020"),

    ("Decisions", "Decide: is the 5-minute unlock cap intentional?", HIGH, "decision", 1,
     "CD-021. Traces to commit 9db7dd7 ('wire vice app unlock to deduct 5 min') — a dashboard prototype "
     "value later mirrored into the shield as maxUnlockMinutes. PRD J4 promises 'Button displays exact "
     "available time'. A cap forces a re-decision every 5 min (aligns with Intentional Friction) but "
     "hides the true cost of banked time (weakens the Painkiller value prop).\n\n"
     "Source: docs/decisions/decision-log.md#cd-021"),

    ("Decisions", "Decide: which daily-goal option set is canonical", MED, "decision", 1,
     "CD-022. Onboarding offers [15,30,45,60,90,120]; Settings offers [15,30,60,120,180,240]. A user who "
     "picks 45 or 90 during onboarding cannot re-select it in Settings. Neither set matches either spec.\n\n"
     "Source: docs/decisions/decision-log.md#cd-022"),

    ("Decisions", "Decide: keep or delete EarningSessionManager", MED, "decision", 1,
     "CD-024. 169 lines + 167 lines of tests implementing the documented session model (60s warmup, 2-min "
     "pause timeout, 5-min credit). Referenced by nothing. Its existence is the main reason "
     "docs/specs/earning.md reads as though the session model is live. Keep as a reference for a future "
     "device-side implementation (with a header comment pointing at CD-011), or delete.\n\n"
     "Source: docs/decisions/decision-log.md#cd-024"),

    ("Decisions", "Decide: drop category blocking from the PRD permanently", MED, "decision", 1,
     "CD-001. PRD J1 P2 wants category selection; per-app unlock makes it impossible (a category token "
     "cannot be unshielded for one app inside it). Code already enforces apps-only. Confirm the "
     "requirement is dropped, then remove the unreachable category paths in AppBlockingService, "
     "ShieldActionExtension.handle(for category:), and the monitor's reapplyViceShields.\n\n"
     "Source: docs/decisions/decision-log.md#cd-001"),

    # ------------------------------------------------------------ release blockers
    ("Release readiness", "Gate the Test Actions section behind #if DEBUG", URGENT, "bug,scaffolding", 1,
     "CD-023 / C1. The dashboard's +5min/-2min buttons are a deliberate Simulator test harness, but they "
     "carry no #if DEBUG guard — they ship to TestFlight and the App Store as a user-facing section that "
     "grants free balance, which defeats the product and is an App Review risk.\n\n"
     "File: Clepsy/Views/Dashboard/DashboardView.swift:332"),

    # -------------------------------------------------------------------- earning
    ("Earning engine", "Remove the 180 min/day earning ceiling", HIGH, "bug", 3,
     "CD-012, decided. UsageTrackingService registers thresholds `for minutes in 1...180`, so earning "
     "silently stops after 3h of daily productive use. This is the exact daily earning cap that "
     "'Dropped from MVP' removed from scope, reintroduced by implementation accident.\n\n"
     "Not a one-line fix: event count grows linearly with the bound, so 1...1440 is likely unacceptable. "
     "Spike what DeviceActivity will accept, then either cap at a defensible waking-hours figure or use a "
     "small re-arming threshold set.\n\n"
     "File: Clepsy/Services/UsageTrackingService.swift:36"),

    ("Earning engine", "Persist todayEarned and todaySpent", HIGH, "bug", 2,
     "C3. Both are in-memory @Published ints, never persisted. Force-quit and relaunch mid-day and both "
     "show 0 — which also zeroes the goal progress bar and the mascot's expression logic, while the "
     "balance itself survives. Needs day-scoped persistence that clears on daily reset.\n\n"
     "File: Clepsy/ViewModels/DashboardViewModel.swift:8"),

    ("Earning engine", "Amend PRD J2: replace the session model with threshold accrual", HIGH, "docs", 2,
     "CD-011. PRD J2 P0s specify a 60s warmup and 2-min pause/resume timeout. Neither is implementable "
     "from a background extension — DeviceActivity reports threshold crossings, not app lifecycle. "
     "Rewrite J2 to describe threshold accrual, and rewrite docs/specs/earning.md to match.\n\n"
     "Source: docs/decisions/decision-log.md#cd-011"),

    # ------------------------------------------------------------- spending/shield
    ("Spending & shield", "Write the shield & unlock spec", HIGH, "docs", 3,
     "The largest engineering surface in the repo has no spec. Should cover: the two shield extensions "
     "(CD-004), the UserDefaults-only fast path and why (CD-003), the per-app unlock registry (CD-010), "
     "the 16-min backdating for DeviceActivity's minimum interval (CD-006), stale-shield mitigation for "
     "Apple bug FB14237883 (CD-007), and unlock-aware foreground re-shielding (CD-009)."),

    ("Spending & shield", "Amend PRD J4: prepaid window replaces real-time deduction", HIGH, "docs", 2,
     "CD-014. J4 P0s specify per-second metering, deduction as the user scrolls, and auto re-shield at "
     "zero mid-session. None are implementable — per-second foreground metering is not available to a "
     "background extension. Document the prepaid model and its user-visible consequence: unlock 5 "
     "minutes, use 40 seconds, you still paid 5."),

    ("Spending & shield", "Amend PRD J3: 'Earn Time Now' is not implementable", MED, "docs", 1,
     "CD-005. A shield extension cannot launch another app — no API exists. The zero-balance state shows "
     "a single honest 'Go Back'. Replace the requirement rather than tracking it as a gap."),

    ("Spending & shield", "Unify the 5-minute unlock constant across targets", MED, "tech-debt", 1,
     "maxUnlockMinutes is defined in ClepsyShieldConfiguration but ShieldActionExtension hardcodes "
     "min(5, ...) as a literal in two places. They will drift. Blocked on the CD-021 decision.\n\n"
     "Files: ClepsyShieldConfiguration/ShieldConfigurationExtension.swift:15, "
     "ClepsyShieldAction/ShieldActionExtension.swift:37,64"),

    ("Spending & shield", "Shield: add expiration indicator and last-updated timestamp", MED, "feature", 2,
     "PRD J3 P0s, unbuilt. 'Expires at midnight (5 hours remaining)' and 'Updated 30 seconds ago'. Note "
     "the config extension must stay fast (CD-003) — both values need to be readable from UserDefaults."),

    ("Spending & shield", "Shield: distinguish Fresh Start from spent-it-all at zero balance", MED, "feature", 2,
     "PRD J3 P0. Post-midnight should read 'Fresh Start: yesterday's balance expired'; mid-day should read "
     "\"You've spent all your earned time today\". Currently one generic message covers both."),

    # ------------------------------------------------------------- daily expiration
    ("Daily expiration", "Check the daily reset on foreground, not only onAppear", HIGH, "bug", 2,
     "C4 / D5. checkAndPerformDailyReset runs only in DashboardView.onAppear. The scenePhase handler calls "
     "syncPendingEvents but not the reset check, so an app resident in the background across midnight "
     "keeps yesterday's balance until a full relaunch. data-architecture.md calls launch-only checking a "
     "'CRITICAL FIX' problem and specifies multiple triggers.\n\n"
     "Files: Clepsy/ViewModels/DashboardViewModel.swift:136, Clepsy/Views/Dashboard/DashboardView.swift:59"),

    ("Daily expiration", "Re-shield vice apps at midnight mid-session", MED, "feature", 3,
     "PRD J4 P0: 'if user is mid-session in a vice app at 11:59 PM, app locks at 12:00 AM'. Nothing "
     "re-shields at midnight today, and an unlock window straddling midnight is unaffected by the reset."),

    ("Daily expiration", "Balance expiration indicator and midnight countdown on dashboard", MED, "feature", 2,
     "PRD J5 P0s: balance shown with an expiration indicator, plus a visual countdown to the midnight "
     "reset. Neither exists."),

    # -------------------------------------------------------------- notifications
    ("Notifications", "Build milestone notifications", HIGH, "feature", 5,
     "D3. PRD J2 P0. UNUserNotificationCenter appears nowhere in the codebase. Needs permission request, "
     "scheduling against earning thresholds, notification content, and tap-to-open handling. Full copy "
     "and timing rules already exist in the notification chapter of the specs."),

    ("Notifications", "Persist milestoneInterval", HIGH, "bug", 1,
     "C2 / CD-023 adjacent. SettingsViewModel.milestoneInterval has a didSet calling saveSettings(), but "
     "saveSettings() never writes it and UserSettings has no such field. The value silently resets to 15 "
     "on every launch.\n\n"
     "File: Clepsy/ViewModels/SettingsViewModel.swift:16"),

    ("Notifications", "Hide or disable the inert notification settings UI until it works", MED, "bug", 1,
     "The Settings toggle and interval picker look functional but control nothing — the app promises a "
     "feature that does not exist. Either ship the feature or hide the controls."),

    ("Notifications", "Low-balance, time-expired, and weekly summary notifications", LOW, "feature", 5,
     "PRD J5/J6 P1s, fully specified in the notification chapter, none implemented. Depends on the "
     "milestone notification foundation."),

    # ------------------------------------------------------------------- history
    ("History & analytics", "Persist the TimeEvent ledger for earning/spending history", HIGH, "feature", 5,
     "D4. PRD J5 P0s call for lists of recent earning and spending sessions (app name, duration, "
     "timestamp). TimeEvent already carries those fields, but syncPendingEvents calls clearEvents() "
     "immediately after applying them, so nothing is retained. Needs a persistence layer before any "
     "history UI is possible.\n\n"
     "File: Clepsy/Services/UsageTrackingService.swift (syncPendingEvents)"),

    ("History & analytics", "Earning and spending history UI", MED, "feature", 3,
     "PRD J5 P0. Blocked on the ledger persistence issue."),

    # --------------------------------------------------------------- error states
    ("Error states", "Handle permission denied during onboarding", HIGH, "feature", 3,
     "PRD J1 P0, onboarding spec Screen 2B, error spec 1A. PermissionView advances to the next step "
     "regardless of the authorization result, so a user who denies Screen Time lands on a dashboard that "
     "can never work. Needs the denied state plus a retry path.\n\n"
     "File: Clepsy/Views/Onboarding/PermissionView.swift"),

    ("Error states", "Detect revoked Family Controls permission and show the dashboard banner", HIGH, "feature", 3,
     "PRD J6 P0, dashboard spec 3.1B, error spec 1B. No detection and no banner exist. Needs an "
     "authorization-status check on foreground and a banner with an Open Settings deep link."),

    ("Error states", "Convert the remaining error-state spec into issues", LOW, "docs", 2,
     "docs/specs/error-states.md is ~1,065 lines and roughly 0% implemented. Triage the P1/P2 entries "
     "(tracking failure, midnight reset failure, clock change, app deleted mid-session, rapid unlocks) "
     "into real issues or drop them."),

    # ------------------------------------------------------------------- settings
    ("Settings hardening", "Enforce at least one vice and one productive app in Settings", HIGH, "bug", 2,
     "C5. Onboarding requires >=1 app in each list; Settings does not. A user can clear both lists "
     "post-setup and silently disable the entire product.\n\n"
     "File: Clepsy/ViewModels/SettingsViewModel.swift:20"),

    ("Settings hardening", "Prevent the same app in both vice and productive lists", MED, "bug", 3,
     "C6. PRD J6 P0 requires conflict resolution with a confirmation toast. No detection exists; behavior "
     "with an app in both lists is undefined (it would be both shielded and earning)."),

    ("Settings hardening", "Reset all data should clear streak keys", MED, "bug", 1,
     "C8. The clepsy_streak_* keys live in standard UserDefaults outside PersistenceService.clearAll(), so "
     "'Reset all data' preserves the streak.\n\n"
     "File: Clepsy/ViewModels/SettingsViewModel.swift:122"),

    # ------------------------------------------------------------------ doc debt
    ("Docs & hygiene", "Fix 14 broken doc cross-references", MED, "docs", 1,
     "H1. Docs point at flat paths that no longer exist (earning_specs.md, dashboard_specs.md, "
     "docs/clepsy_prd.md, clepsy_app_images/, docs/testing/mvp-test-checklist.md, ...). Actual locations "
     "are docs/specs/, docs/plans/, design/assets/. Every 'see X' pointer in the plan and CHANGELOG is "
     "currently dead."),

    ("Docs & hygiene", "Update README: entitlements, extensions, structure", MED, "docs", 1,
     "H3 / CD-025. README says to uncomment the entitlements and the ClepsyMonitor dependency — both have "
     "been active since 14984df. Project structure omits ClepsyShieldAction and ClepsyShieldConfiguration "
     "entirely. Also missing: the App Group requirement, docs/, design/."),

    ("Docs & hygiene", "Rewrite the data-architecture storage section", MED, "docs", 2,
     "C12 / CD-013. The doc describes pendingTimeEvents as an App Group UserDefaults key; the "
     "implementation uses a file (pendingTimeEvents.json) with NSFileCoordinator. The key table omits "
     "every key actually in use: viceSelection, productiveSelection, balanceSeconds, pendingDeltaSeconds, "
     "activeUnlocks, shieldShowedBalanceByToken, unlockExpiresAt, clepsy_streak_*."),

    ("Docs & hygiene", "Amend the MVB hourglass rationale for spendable balance", MED, "docs", 1,
     "CD-018, decided. The sand level represents spendable balance, not goal progress. The MVB's 'Why "
     "Hourglass Body?' section is written around the goal-progress reading and needs rewriting, as does "
     "PRD J3 P0. Consider whether the face should also key off balance (CD-019) — today the body tracks "
     "balance and the face tracks goal progress."),

    ("Docs & hygiene", "Update onboarding spec to the shipped 5-screen flow", MED, "docs", 1,
     "CD-016. Spec describes 6 screens while its own header says 'Target: 5 screens total'. Shipped: "
     "Welcome+HowItWorks merged, Ready screen replaced by a 2.5s celebration overlay, no Screen 2B."),

    ("Docs & hygiene", "Update dashboard spec: stats folded into the hero card", LOW, "docs", 1,
     "CD-017. Spec 3.5 specifies two standalone stat cards; commit 157be49 folded earned/spent inline "
     "into the balance hero card as redundant."),

    ("Docs & hygiene", "Cut PRD v1.0; keep v2.1 as the single PRD", MED, "docs", 1,
     "H7. Doc 2 and docs/plans/prd.md contain both PRD v1.0 (Jan 24) and v2.1 (Jan 30) in full, "
     "sequentially, with no marker that v1 is superseded. Anyone reading top-down gets the obsolete "
     "version first."),

    ("Docs & hygiene", "Replace the CHANGELOG with a real one", LOW, "docs", 1,
     "H2. docs/CHANGELOG.md is a pre-implementation proposal dated 2026-02-01 that ends with 'Ready to "
     "Begin Task 0?'. Every commit since is unrecorded."),

    ("Docs & hygiene", "Close out clepsy_mvp.md and archive stale Google Docs", LOW, "docs", 1,
     "H4/H5. The 30-task plan is mostly executed and has no completion state; its residual value is the "
     "unbuilt tasks. Doc 3 ('Copy of Productivity app notes') has no unique content — archive it. Freeze "
     "Docs 1 and 2 read-only with a pointer to Linear once migration completes."),

    # ----------------------------------------------------------------- cleanup
    ("Cleanup", "Remove the unobserved AppDidBecomeActive notification", LOW, "tech-debt", 1,
     "CD-026. Posted on every foreground in ClepsyApp.swift:30; nothing listens. Left over from the "
     "pre-scenePhase wiring in 65f849c."),

    ("Cleanup", "Remove or wire up the clepsy:// URL scheme", LOW, "tech-debt", 1,
     "CD-027. Registered in project.yml. Added for 'launch productive app via URL scheme' in 9db7dd7; the "
     "tappable app cards were later removed. Nothing opens a URL anywhere now."),

    ("Cleanup", "Delete the superseded in-app ShieldConfigurationView", LOW, "tech-debt", 1,
     "CD-028. Plan Task 23's SwiftUI shield, never presented. It implements things the real shield "
     "cannot (mascot, earned-today, 'Earn Time Now'), which is part of why the specs read as though "
     "those exist.\n\nFile: Clepsy/Views/Shield/ShieldConfigurationView.swift"),

    ("Cleanup", "Remove hardcoded app lists and AppIconView", LOW, "tech-debt", 1,
     "CD-029. AppCategory.defaultViceApps/.defaultProductiveApps and AppIconView predate "
     "FamilyActivitySelection. The dashboard renders system Label(token) views instead. DashboardViewModel "
     "still loads the hardcoded lists into published properties nothing reads. AppIconView's comment "
     "claims 'Used by DashboardView' — it isn't."),

    ("Cleanup", "Remove the unused UserSettings.exchangeRate", LOW, "tech-debt", 1,
     "CD-030. Added as '1:1 for MVP, configurable for future'; nothing consumes it. The 1:1 rate is "
     "implicit in 'one threshold = 60 seconds'. It implies configurability that doesn't exist."),

    ("Cleanup", "Add test coverage for UsageTrackingService and the extensions", MED, "tests", 3,
     "No tests exist for UsageTrackingService or any of the three extensions — which is where the "
     "product's actual mechanics live. Meanwhile the largest test file (EarningSessionManagerTests, 167 "
     "lines) covers code the app never runs."),
]


def main() -> None:
    out = pathlib.Path(__file__).parent / "issues.csv"
    with out.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["Title", "Description", "Priority", "Labels", "Estimate", "Project", "Status"])
        for project, title, priority, labels, estimate, description in ISSUES:
            w.writerow([title, description, priority, labels, estimate, project, "Backlog"])
    print(f"wrote {len(ISSUES)} issues to {out}")


if __name__ == "__main__":
    main()
