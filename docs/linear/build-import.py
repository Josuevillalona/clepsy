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
    # =========================================================== device spikes
    ("Earning engine", "SPIKE (needs a physical iPhone): verify re-arming threshold ladders", HIGH, "spike", 3,
     "CD-037. Screen Time APIs do not work in the Simulator, so this can only be done on a real device.\n\n"
     "BACKGROUND: iOS cannot say 'notify me every minute forever'. You register a fixed list of "
     "threshold alarms up front. Today both ladders stop at 180, which is why earning silently caps at "
     "3h (CD-012) and a session stops metering after 180 min (R-02). Neither number is a product "
     "decision (CD-036) - there is no intended cap.\n\n"
     "PROPOSED FIX: register a SHORT ladder and restart the schedule when the top threshold fires, so "
     "tracking continues indefinitely with a constant number of events. Size the spending ladder to the "
     "balance the user actually has instead of always registering 180.\n\n"
     "VERIFY, in this order:\n"
     "1. Does re-arming work at all? Temporarily set the ladder to 3 instead of 60 so you do not have to "
     "wait an hour. Use a productive app ~5 min. Does earning continue past minute 3?\n"
     "2. How much usage leaks per re-arm? Check Console for the gap between the last threshold firing "
     "and the new schedule taking effect. Seconds per re-arm is fine; minutes is not.\n"
     "3. Is there a hard event limit? Call startMonitoring with 200 / 400 / 800 events and find where it "
     "throws. This decides whether small ladders are merely nicer or actually required.\n\n"
     "Precedent: ShieldActionExtension.restartViceMonitoring already restarts monitoring from inside an "
     "extension, so the pattern is proven here.\n\n"
     "Source: docs/decisions/decision-log.md#cd-037"),

    ("Spending & shield", "SPIKE (needs a physical iPhone): measure the 1-second sleep at time's-up", MED, "spike", 2,
     "R-01. DeviceActivityMonitorExtension.endSession sets blockedApplications (which terminates the "
     "foreground app), sleeps 1 second, then clears it and applies the normal shield.\n\n"
     "RISK: extensions have tight execution budgets. If iOS kills the extension mid-sleep, "
     "blockedApplications stays set - which does not just shield the vice apps, it HIDES THEIR ICONS "
     "from the home screen. The user's apps look deleted with no explanation. AppBlockingService clears "
     "it as a safety net, but only when the user next opens Clepsy.\n\n"
     "MEASURE: how often does the extension survive the full second? If it is unreliable, consider a "
     "shorter sleep or a different teardown order. The sleep is defensible (an async dispatch might not "
     "run at all before teardown), so this is a measurement task, not an obvious bug.\n\n"
     "File: ClepsyMonitor/DeviceActivityMonitorExtension.swift (endSession)"),

    # ======================================================= earning / spending
    ("Earning engine", "Remove BOTH 180 ceilings together (earning + spending)", HIGH, "bug", 5,
     "CD-012 + R-02. MUST BE ONE COMMIT - do not do either alone.\n\n"
     "Earning stops crediting after 180 min/day. Spending stops metering after 180 min in a session, "
     "after which the balance never drains and the apps stay unshielded until 23:59 - free access.\n\n"
     "WHY THEY ARE COUPLED: the spending hole is currently unreachable ONLY because earning also caps at "
     "180, so a balance can never outgrow the meter. Removing the earning cap alone opens the exploit.\n\n"
     "INTERIM: leave the earning cap in place until this ships.\n\n"
     "Blocked on the CD-037 spike.\n\n"
     "Files: Clepsy/Services/UsageTrackingService.swift (earn ladder), "
     "ClepsyShieldAction/ShieldActionExtension.swift (spend ladder)"),

    # ============================================================ known bugs
    ("Settings hardening", "Persist milestoneInterval", HIGH, "bug", 1,
     "C2. SettingsViewModel.milestoneInterval has a didSet calling saveSettings(), but saveSettings() "
     "never writes it and UserSettings has no such field. The value silently resets to 15 every launch. "
     "The notifications toggle beside it now controls something real, which makes the dead picker more "
     "misleading than before.\n\n"
     "File: Clepsy/ViewModels/SettingsViewModel.swift:16"),

    ("Daily expiration", "Check the daily reset on foreground, not only onAppear", HIGH, "bug", 2,
     "C4. checkAndPerformDailyReset runs only in DashboardView.onAppear. The scenePhase handler calls "
     "syncPendingEvents but not the reset check, so an app left in the background across midnight keeps "
     "yesterday's balance until a full relaunch. data-architecture.md calls launch-only checking a "
     "'CRITICAL FIX' problem and specifies multiple triggers.\n\n"
     "Files: Clepsy/ViewModels/DashboardViewModel.swift, Clepsy/Views/Dashboard/DashboardView.swift"),

    ("Settings hardening", "Enforce at least one vice and one productive app in Settings", HIGH, "bug", 2,
     "C5. Onboarding requires >=1 app in each list; Settings does not. A user can clear both lists after "
     "setup and silently disable the entire product.\n\n"
     "File: Clepsy/ViewModels/SettingsViewModel.swift"),

    ("Settings hardening", "Prevent the same app being both vice and productive", MED, "bug", 3,
     "C6. PRD J6 P0 requires conflict resolution with a confirmation toast. No detection exists. An app "
     "in both lists would be shielded AND earning at the same time - undefined behavior."),

    ("Settings hardening", "Reset all data should clear the streak", MED, "bug", 1,
     "C8. The clepsy_streak_* keys live in standard UserDefaults, outside PersistenceService.clearAll(), "
     "so 'Reset all data' preserves the streak.\n\n"
     "File: Clepsy/ViewModels/SettingsViewModel.swift"),

    # ============================================================== cleanup
    ("Cleanup", "Remove the unreachable category-handling code", MED, "tech-debt", 3,
     "CD-001, decided 2026-08-04: apps-only is permanent. Both pickers already reject categories, so the "
     "category paths can never be entered by a new user.\n\n"
     "Do this carefully and on its own - it touches three targets and a mistake here silently breaks the "
     "shield. The genuinely dead code is ShieldActionExtension.handle(for category:). The rest are "
     "harmless pass-throughs (categories: selection.categoryTokens on an always-empty set) that can go "
     "at the same time.\n\n"
     "~14 references across: AppBlockingService, UsageTrackingService, DeviceActivityMonitorExtension, "
     "ShieldActionExtension, DashboardView."),

    ("Cleanup", "Remove the unobserved AppDidBecomeActive notification", LOW, "tech-debt", 1,
     "CD-026. Posted on every foreground in ClepsyApp; nothing listens. Left over from the pre-scenePhase "
     "wiring."),

    ("Cleanup", "Remove or wire up the clepsy:// URL scheme", LOW, "tech-debt", 1,
     "CD-027. Registered in project.yml for a 'launch productive app' feature that was later removed. "
     "Nothing opens a URL anywhere now."),

    ("Cleanup", "Remove hardcoded app lists and AppIconView", LOW, "tech-debt", 1,
     "CD-029. AppCategory.defaultViceApps/.defaultProductiveApps and AppIconView predate "
     "FamilyActivitySelection. The dashboard renders system Label(token) views instead. "
     "DashboardViewModel still loads the hardcoded lists into published properties nothing reads."),

    ("Cleanup", "Remove the unused UserSettings.exchangeRate", LOW, "tech-debt", 1,
     "CD-030. Added as '1:1 for MVP, configurable for future'; nothing consumes it. The 1:1 rate is "
     "implicit in 'one threshold = 60 seconds'."),

    ("Cleanup", "Add tests for UsageTrackingService and the extensions", MED, "tests", 3,
     "No tests exist for UsageTrackingService or any of the three extensions - which is where the "
     "product's actual mechanics live. The largest test file covers EarningSessionManager, which the app "
     "never runs (CD-024)."),

    # ======================================================= unbuilt features
    ("Notifications", "Build milestone notifications", HIGH, "feature", 5,
     "PRD J2 P0. The 'Time's up' notification now exists (CD-035), so the permission flow and App Group "
     "toggle mirror are already in place. Milestone notifications ('15 minutes earned!') are still "
     "unbuilt. Depends on persisting milestoneInterval."),

    ("Notifications", "Low-balance, weekly summary, and fresh-start notifications", LOW, "feature", 5,
     "PRD J5/J6 P1s, fully specified in the notification chapter of the specs, none implemented."),

    ("History & analytics", "Persist the TimeEvent ledger so history is possible", HIGH, "feature", 5,
     "D4. PRD J5 P0 calls for lists of recent earning and spending sessions. TimeEvent already carries "
     "app, duration and timestamp, but syncPendingEvents calls clearEvents() straight after applying "
     "them, so nothing is retained. Needs a persistence layer before any history UI can exist."),

    ("History & analytics", "Earning and spending history UI", MED, "feature", 3,
     "PRD J5 P0. Blocked on ledger persistence."),

    ("Daily expiration", "Balance expiration indicator and midnight countdown", MED, "feature", 2,
     "PRD J5 P0: show the balance with an expiration indicator plus a visual countdown to the midnight "
     "reset. Neither exists."),

    ("Daily expiration", "Re-shield vice apps at midnight mid-session", MED, "feature", 3,
     "PRD J4 P0: 'if user is mid-session in a vice app at 11:59 PM, app locks at 12:00 AM'. Nothing "
     "re-shields at midnight, and a session straddling midnight is unaffected by the reset."),

    ("Spending & shield", "Shield: expiration indicator and last-updated timestamp", MED, "feature", 2,
     "PRD J3 P0s, unbuilt. Note the config extension must stay fast (CD-003), so both values need to be "
     "readable from UserDefaults."),

    ("Spending & shield", "Shield: distinguish Fresh Start from spent-it-all at zero balance", MED, "feature", 2,
     "PRD J3 P0. Post-midnight should read 'Fresh Start: yesterday's balance expired'; mid-day should "
     "read 'You have used all your earned time today'. One generic message covers both today."),

    ("Error states", "Handle permission denied during onboarding", HIGH, "feature", 3,
     "PRD J1 P0, onboarding spec Screen 2B. PermissionView advances regardless of the authorization "
     "result, so a user who denies Screen Time lands on a dashboard that can never work.\n\n"
     "File: Clepsy/Views/Onboarding/PermissionView.swift"),

    ("Error states", "Detect revoked Family Controls permission and show a banner", HIGH, "feature", 3,
     "PRD J6 P0, dashboard spec 3.1B. No detection, no banner. Needs an authorization check on "
     "foreground plus a banner with an Open Settings deep link."),

    ("Error states", "Triage the rest of the error-state spec", LOW, "docs", 2,
     "docs/specs/error-states.md is ~1,065 lines and roughly 0% implemented. Turn the P1/P2 entries into "
     "real issues or drop them."),

    # ============================================================ documentation
    ("Docs & hygiene", "Rewrite PRD J4 + earning spec: spending is built, earning is threshold-based", HIGH, "docs", 3,
     "CD-011 / CD-014 / CD-031. Two corrections in one pass.\n\n"
     "J4: the audit originally claimed real-time deduction was not implementable. Wrong - per-SECOND "
     "metering is unavailable to a background extension, but per-MINUTE metering works and you SHIPPED "
     "it in 959da5f. Amend to 1-minute granularity; do not strike it.\n\n"
     "J2 + docs/specs/earning.md: the documented 60s warmup and 2-min pause/resume session model was "
     "never built and cannot be from a background extension. Replace with threshold accrual."),

    ("Docs & hygiene", "Write the shield & session spec (new document)", HIGH, "docs", 3,
     "The largest engineering surface in the repo has no spec. Cover: the two shield extensions (CD-004), "
     "the UserDefaults-only fast path and why (CD-003), the session model (CD-031), metering anchored at "
     "session start (CD-032 - the subtlest thing in the codebase), hard-block-to-terminate at exhaustion "
     "(CD-033), one-session-unshields-everything (CD-034), the 15-min minimum interval (CD-006), and "
     "FB14237883 (CD-007)."),

    ("Docs & hygiene", "Amend PRD J5: the streak is a goal-completion streak", MED, "docs", 1,
     "CD-020, decided. Goal-met days is the rule; the code stands. PRD J5 currently says 'consecutive "
     "days with earning activity' and calls it a 'Fresh Start Streak'.\n\n"
     "State the accepted consequence: partial-credit days count for nothing (20 of a 30-min goal daily "
     "for a month = streak of 0)."),

    ("Docs & hygiene", "Amend PRD J3 + MVB: hourglass shows spendable balance", MED, "docs", 1,
     "CD-018, decided. The sand level is spendable balance, not goal progress. PRD J3 P0 and the MVB's "
     "'Why Hourglass Body?' rationale are both written around the goal-progress reading.\n\n"
     "Also note CD-019: the body tracks balance while the face tracks goal progress. Decide whether "
     "that is intended."),

    ("Docs & hygiene", "Amend PRD J3: 'Earn Time Now' is not implementable", MED, "docs", 1,
     "CD-005. A shield extension cannot launch another app - no API exists. Replace the requirement "
     "rather than tracking it as a gap."),

    ("Docs & hygiene", "Strike PRD J1 P2: category blocking", MED, "docs", 1,
     "CD-001, decided. Document apps-only as a permanent platform constraint."),

    ("Docs & hygiene", "Rewrite the data-architecture storage section", MED, "docs", 2,
     "C12 / CD-013. The doc describes pendingTimeEvents as an App Group UserDefaults key; the code uses "
     "a FILE (pendingTimeEvents.json) with NSFileCoordinator. The key table omits everything actually in "
     "use: viceSelection, productiveSelection, balanceSeconds, pendingDeltaSeconds, sessionActive, "
     "notificationsEnabled, shieldShowedBalanceByToken, todayEarnedSeconds, todaySpentSeconds, "
     "clepsy_streak_*."),

    ("Docs & hygiene", "Fix 14 broken doc cross-references", MED, "docs", 1,
     "H1. Docs point at flat paths that no longer exist (earning_specs.md, dashboard_specs.md, "
     "docs/clepsy_prd.md, clepsy_app_images/, docs/testing/mvp-test-checklist.md...). Real locations are "
     "docs/specs/, docs/plans/, design/assets/. Every 'see X' pointer in the plan and CHANGELOG is dead."),

    ("Docs & hygiene", "Update README: entitlements, extensions, structure", MED, "docs", 1,
     "H3 / CD-025. README says to uncomment the entitlements and the ClepsyMonitor dependency - both "
     "active since 14984df. Project structure omits ClepsyShieldAction and ClepsyShieldConfiguration. "
     "Missing: the App Group requirement, docs/, design/."),

    ("Docs & hygiene", "Update onboarding + dashboard specs to what shipped", MED, "docs", 1,
     "CD-016: onboarding is 5 screens, not 6 (Welcome+HowItWorks merged, Ready replaced by a 2.5s "
     "celebration overlay, no Screen 2B). The spec's own header already contradicts its contents. "
     "CD-017: the dashboard's two standalone stat cards were folded into the balance hero card."),

    ("Docs & hygiene", "Cut PRD v1.0; keep v2.1 as the single PRD", MED, "docs", 1,
     "H7. Doc 2 and docs/plans/prd.md contain both v1.0 (Jan 24) and v2.1 (Jan 30) in full, with no "
     "marker that v1 is superseded. Reading top-down gives you the obsolete version first."),

    ("Docs & hygiene", "Replace the CHANGELOG and close out the MVP plan", LOW, "docs", 1,
     "H2/H4. docs/CHANGELOG.md is a pre-implementation proposal ending with 'Ready to Begin Task 0?'. "
     "docs/plans/clepsy_mvp.md is a 30-task plan, mostly executed, with no completion state and no task "
     "covering the shield extensions."),

    ("Docs & hygiene", "Archive stale Google Docs after migration", LOW, "docs", 1,
     "H5. Doc 3 ('Copy of Productivity app notes') has no unique content - archive it. Freeze Docs 1 and "
     "2 read-only with a pointer to Linear once migration completes."),
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
