# Goal-based Unlock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Clepsy's earn/spend balance with a daily goal that, once reached and claimed in a celebration, unlocks vice apps until midnight. Adds two goal modes, streak freezes and badges.

**Architecture:** Framework-free rules (`GoalRules`, `EarnRules`, `DayProcessor`, `BadgeRules`, `ShieldRules`) hold every decision and are unit-tested. A `GoalStore` in the app owns plan, streak and badge persistence and mirrors today's goal and unlock state into the App Group. The monitor writes earned minutes and the goal-reached flag there, and the shield reads it on the fast path. UI is SwiftUI on iOS 16, with Core Haptics and Canvas particles.

**Tech Stack:** Swift 5.9, SwiftUI (iOS 16), FamilyControls, DeviceActivity, ManagedSettings, CoreHaptics, XCTest, xcodegen.

**Spec:** `docs/superpowers/specs/2026-11-03-goal-based-unlock-design.md`

## Global Constraints

- iOS 16.0 deployment target: no `phaseAnimator`, `keyframeAnimator` or `sensoryFeedback`.
- Goals are 5–120 min in 5-min steps. Difficulty bands:
  - Easy: 5–20
  - Medium: 25–45
  - Hard: 50–75
  - Intense: 80–120
- Build-up: +5 per step; an offer comes after 3 consecutive reached days; the estimate assumes 3 days per step.
- Freezes: +1 per 7 consecutive counted days, at most 2.
- Day key: `yyyy-MM-dd` in `Calendar.current`.
- The shield configuration extension reads only UserDefaults (no file coordination).
- Every shield-applying path checks `unlockedDay == today` first.
- Haptics and notifications are optional, mirrored to the App Group.
- Copy follows brand voice §5: encouraging, specific, no shame.
- New shared source files must be added to `project.yml` per target, then run `xcodegen generate`.
- Test: `xcodebuild test -project Clepsy.xcodeproj -scheme Clepsy -destination "id=9CB1AFEF-C590-44D3-937D-8A3E30108E03"` with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

## Review Focus

1. **Goal lowered below earned minutes mid-day.** The app marks the day reached and presents the claim (Task 3 test `testLoweringGoalBelowEarnedMarksReached`).
2. **App not opened for several days.** The streak and freezes roll forward correctly over the gap (Task 2 test `testGapOfFourDaysUsesFreezesThenResets`).
3. **Earn events arriving out of order or repeated** (iOS redelivery). The count never goes down, and the goal notification fires once (Task 1 test `testRepeatedAndOutOfOrderEventsAreIdempotent`).
4. **Stale goal day stamp** (the monitor runs before the app has rolled over today). Fall back to `goalMinutesBase` (Task 1 test `testStaleGoalDayFallsBackToBase`).
5. **Changing vice apps in Settings after claiming.** Must not re-lock (Task 4 test `testApplyBlocksSkipsWhenUnlockedToday` on `ViceShieldPolicy.shouldShield`).

---

### Task 1: Goal rules, earn rules, shared goal state

**Files:**
- Create: `Clepsy/Services/GoalRules.swift` (Foundation only; shared to app, monitor, shield config, shield action)
- Modify: `Clepsy/Services/SharedStorageService.swift` (add goal state; remove balance, session and metering APIs in Task 4)
- Modify: `Clepsy/Services/ScreenTimeRules.swift`: replace `ShieldRules` per the spec. `SessionRules` goes in Task 4.
- Test: `ClepsyTests/Services/GoalRulesTests.swift`, `ClepsyTests/Services/ScreenTimeRulesTests.swift`

**Interfaces (produces):**
- `enum DayKey { static func string(for: Date, calendar: Calendar = .current) -> String }`
- `enum GoalDifficulty: String { case easy, medium, hard, intense; static func forMinutes(_:) -> GoalDifficulty; var title: String }`
- `enum GoalMode: Codable, Equatable { case fixed; case buildUp(target: Int) }`
- `struct GoalPlan: Codable, Equatable { var mode: GoalMode; var currentGoal: Int; var consecutiveReached: Int; var pendingGoal: Int? }`
- `enum GoalRules`:
  - `minutesRange = 5...120`, `step = 5`, `offerAfterDays = 3`, `daysPerStep = 3`
  - `startRange(): ClosedRange<Int>` = 5...115
  - `targetRange(start:) -> ClosedRange<Int>` = start+5...120
  - `estimatedDays(start:target:) -> Int`
  - `isOfferDue(_ plan: GoalPlan) -> Bool`
  - `accept(_ plan:) -> GoalPlan` (sets `pendingGoal = currentGoal+5`, resets count)
  - `decline(_ plan:) -> GoalPlan`
  - `nextOfferGoal(_:) -> Int?`
- `struct EarnState: Equatable { var day: String; var minutes: Int; var reached: Bool }`
- `enum EarnRules { static func apply(eventMinute: Int, today: String, stored: EarnState?, goal: Int) -> (state: EarnState, justReached: Bool) }`. Parse the event name with `static func minute(fromEventName: String) -> Int?` (`"earn_12"` → 12).
- `SharedStorageService`:
  - `earnState: EarnState?`, `saveEarnState(_:)`
  - `saveGoalToday(minutes:day:)`, `saveGoalBase(_:)`
  - `goalMinutes(for day: String) -> Int` (today's goal if the stamp matches, otherwise base, otherwise 30)
  - `reachedDays: Set<String>`, `addReachedDay(_:)` (keeps the latest 60)
  - `unlockedDay: String?`, `saveUnlockedDay(_:)`
  - `hapticsEnabled` + `saveHapticsEnabled(_:)` (default true)
- `ShieldRules`:
  - `content(appName: String?, earnedMinutes: Int, goalMinutes: Int, reached: Bool) -> Content`
  - `enum PrimaryTap { case close, claimViaNotification }`
  - `primaryTap(reached: Bool) -> PrimaryTap`

- [ ] **Step 1: Write failing tests**
  - `testDifficultyBands`: 5→easy, 20→easy, 25→medium, 45→medium, 50→hard, 75→hard, 80→intense, 120→intense
  - `testTargetRangeStartsFiveAboveStart`: targetRange(start: 60) == 65...120
  - `testEstimatedDays`: (10, 45) → 21; (60, 120) → 36
  - `testOfferDueAfterThreeDaysBelowTarget`: a buildUp(target: 30) plan with goal 20 and count 3 → true; count 2 → false
  - `testNoOfferInFixedModeOrAtTarget`
  - `testAcceptSetsPendingGoalAndResetsCount`
  - `testDeclineResetsCountOnly`
  - `testEarnFirstEventOfDay`: stored nil, event 1, goal 30 → minutes 1, not reached
  - `testEarnReachesGoalOnce`: event 30 → `justReached` true; event 31 next → reached, `justReached` false
  - `testRepeatedAndOutOfOrderEventsAreIdempotent`: stored 12; event 9 → still 12, `justReached` false
  - `testNewDayResetsEarnState`: stored day yesterday with 50 minutes; event 1 today → 1
  - `testParseEventName`: "earn_12" → 12, "spend_3" → nil, "earn_x" → nil
  - `testStaleGoalDayFallsBackToBase` (SharedStorage on a test suite): today stamp yesterday=15, base 30 → `goalMinutes(for: today)` == 30
  - `testReachedDaysKeepsLatestSixty`
  - Shield:
    - `testShieldBeforeGoalShowsProgress`: subtitle contains "12 of 30 min today"; primary "Go Back"; no secondary
    - `testShieldReachedOffersClaim`: title "You did it 🎉", primary "Claim in Clepsy", secondary "Go Back"
    - `testPrimaryTapClaimsOnlyWhenReached`
- [ ] **Step 2: Run tests; expect compile failures**
- [ ] **Step 3: Implement the above.** Store `EarnState` as three keys (`earnDay`, `earnMinutes`, `earnReached`) for fast-path reads.
- [ ] **Step 4: Run tests; expect PASS**
- [ ] **Step 5: Commit** `feat: goal, earn and shield rules with shared goal state`

### Task 2: Day processing, streaks, freezes, badges

**Files:**
- Create: `Clepsy/Models/Progress.swift` (`StreakState`, `Badge`, `BadgeID`)
- Create: `Clepsy/Services/DayProcessor.swift`
- Test: `ClepsyTests/Services/DayProcessorTests.swift`

**Interfaces (produces):**
- `struct StreakState: Codable, Equatable { var count: Int; var freezes: Int; var lastProcessedDay: String?; var lastResetDay: String?; var frozenDays: [String] }`
- `enum BadgeID: String, Codable, CaseIterable { case firstGoal, streak3, streak7, streak14, streak30, streak100, builtUp, firstFreeze, intense, comeback }`, each with `title`, `rule` (unearned copy) and `symbol` (SF Symbol)
- `struct DayResult { var streak: StreakState; var plan: GoalPlan; var newBadges: [BadgeID] }`
- `enum DayProcessor { static func process(days: [String], reached: Set<String>, goalForDay: (String) -> Int, streak: StreakState, plan: GoalPlan, earned: Set<BadgeID>) -> DayResult }`
  - Walks the given days in order. For a reached day:
    - count += 1
    - plan.consecutiveReached += 1
    - every 7th count → freezes = min(2, +1)
  - For a missed day:
    - If freezes > 0: freezes -= 1 and the day is recorded as frozen.
    - Otherwise: count = 0 and lastResetDay = day.
    - In both cases plan.consecutiveReached = 0.
  - At the start of each day, if `pendingGoal` is set, it becomes `currentGoal`. If it equals the build-up target, mode becomes `.fixed` and `builtUp` is awarded.
  - Badges, unless already earned:
    - firstGoal: the first reached day
    - streak thresholds: 3, 7, 14, 30, 100
    - firstFreeze: when freezes first goes above 0
    - intense: a goal of 80 or more reached
    - comeback: a reached day whose previous day was a reset
- `static func daysToProcess(from lastProcessed: String?, through yesterday: String, calendar:) -> [String]` (empty when lastProcessed is nil, so the first run doesn't create days)

- [ ] **Step 1: Write failing tests:**
  - `testReachedDaysBuildStreak`
  - `testSeventhDayEarnsFreezeCappedAtTwo` (21 days → 2)
  - `testMissedDayUsesFreeze`
  - `testMissedDayWithoutFreezeResets`
  - `testGapOfFourDaysUsesFreezesThenResets`: freezes 2, 4 missed → freezes 0, count 0
  - `testPendingGoalAppliesNextDay`
  - `testReachingBuildUpTargetSwitchesToFixedAndAwardsBadge`
  - `testBadgesAwardedOnce`
  - `testComebackBadge`
  - `testIntenseBadgeAtEighty`
  - `testDaysToProcessSpansGap`: last "2026-11-01", yesterday "2026-11-04" → ["2026-11-02", "2026-11-03", "2026-11-04"]
- [ ] **Step 2: Run; expect FAIL**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run; expect PASS**
- [ ] **Step 5: Commit** `feat: streaks, freezes and badges day processor`

### Task 3: GoalStore (app-side state owner)

**Files:**
- Create: `Clepsy/Services/GoalStore.swift`
- Modify: `Clepsy/Services/PersistenceService.swift`: add `saveGoalPlan`/`loadGoalPlan`, `saveStreak`/`loadStreak` and `saveBadges`/`loadBadges` (`[BadgeID: Date]`). Remove the time-balance and today-stats APIs in Task 4.
- Modify: `Clepsy/Models/UserSettings.swift`: keep `dailyGoalMinutes` as the migration source only
- Test: `ClepsyTests/Services/GoalStoreTests.swift`

**Interfaces (produces):**
- `@MainActor final class GoalStore: ObservableObject`, `init(persistence: PersistenceService, shared: SharedStorageService, now: @escaping () -> Date = Date.init, calendar: Calendar = .current)`
  - Published:
    - `plan: GoalPlan`
    - `streak: StreakState`
    - `badges: [BadgeID: Date]`
    - `todayGoal: Int`
    - `earnedMinutes: Int`
    - `status: TodayStatus`
    - `pendingCelebration: Celebration?`
  - `enum TodayStatus: Equatable { case locked(minutesToGo: Int), almostThere, readyToClaim, unlocked }`
  - `struct Celebration: Equatable, Identifiable { let id: String /* day */; let goal: Int; let streakBefore: Int; let streakAfter: Int; let newBadges: [BadgeID]; let offerGoal: Int? }`
  - `func refresh()`:
    1. Roll over the days that need processing.
    2. Mirror the goal to shared storage.
    3. Read earned and reached.
    4. If earned ≥ goal and not reached, mark reached, add the reached day, and save the earn state.
    5. Compute status.
    6. Build `pendingCelebration` when status is `.readyToClaim`.
  - `func claim()`:
    - Saves `unlockedDay` = today.
    - Calls the injected `unlockApps: () -> Void`.
    - Awards claim-time badges (firstGoal/intense for today, if not yet earned).
    - Today's streak display = processed count + 1.
  - `func acceptOffer()`, `func declineOffer()`
  - `func setPlan(mode: GoalMode, goal: Int)`: applies immediately unless today is reached (then sets `pendingGoal`).
  - Migration: no saved plan → `.fixed` with `dailyGoalMinutes` clamped and rounded to 5...120.
- The `unlockApps` closure is injected (default: `AppBlockingService().removeAllBlocks()`), keeping it testable.

- [ ] **Step 1: Write failing tests** (test suites for persistence and shared; fixed `now`)
  - `testMigratesFromDailyGoalMinutes`: 240 → 120, 37 → 35
  - `testStatusLockedShowsMinutesToGo`: earned 18, goal 30 → `.locked(12)`
  - `testAlmostThereAtGoalMinusOne`
  - `testReachedButUnclaimedIsReadyToClaimWithCelebration`
  - `testClaimUnlocksAndMarksDay`: closure called; status `.unlocked`; `unlockedDay` == today
  - `testLoweringGoalBelowEarnedMarksReached`
  - `testGoalChangeAfterReachedAppliesTomorrow`
  - `testCelebrationIncludesOfferWhenDue`
  - `testRolloverProcessesYesterday`
- [ ] **Step 2: Run; expect FAIL**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run; expect PASS**
- [ ] **Step 5: Commit** `feat: GoalStore owns daily goal state, claim and offers`

### Task 4: Engine wiring and balance-model removal

**Files:**
- Create: `Clepsy/Services/ViceShield.swift` (ManagedSettings; shared to app + monitor)
  - `enum ViceShieldPolicy { static func shouldShield(today: String, unlockedDay: String?) -> Bool }`
  - `enum ViceShield { static func apply(_ selection: FamilyActivitySelection, closingForegroundApp: Bool); static func remove() }` (moves the hard-block-then-shield swap here)
- Modify: `ClepsyMonitor/DeviceActivityMonitorExtension.swift`
  - Earn events → `EarnRules.apply` → save; on `justReached`, add the reached day and post "You hit your goal 🎉" / "Tap to claim your unlock."
  - `intervalDidStart(.productiveApps)` → if `shouldShield`, `ViceShield.apply(closingForegroundApp: true)`
  - Delete the vice/spend handling and `endSession`
- Modify: `ClepsyShieldConfiguration/ShieldConfigurationExtension.swift`: new `ShieldRules.content`, fed from the shared fast path
- Modify: `ClepsyShieldAction/ShieldActionExtension.swift`: primary → `.claimViaNotification` posts the claim notification then `.close`; otherwise `.close`. Delete `startSession`.
- Modify:
  - `Clepsy/Services/AppBlockingService.swift`: `applyViceAppBlocks()` returns early when `!shouldShield`
  - `Clepsy/ClepsyApp.swift`: drop session logic; foreground → `applyViceAppBlocks`, `startDailyMonitoring`
  - `Clepsy/ViewModels/DashboardViewModel.swift`: remove balance and spending
  - `Clepsy/Services/UsageTrackingService.swift`: remove vice spending and event sync
  - `Clepsy/Services/PersistenceService.swift`
  - `Clepsy/Services/SharedStorageService.swift`
  - `Clepsy/Services/ScreenTimeRules.swift`
  - `project.yml`
- Delete:
  - `Clepsy/Models/TimeBalance.swift`
  - `Clepsy/Services/ViceMonitoring.swift`
  - `Clepsy/Services/EarningSessionManager.swift` (never ran; CD-024)
  - `Clepsy/Views/Shield/ShieldConfigurationView.swift` if it's balance-only
  - their tests
- Test: `ClepsyTests/Services/ViceShieldPolicyTests.swift`; update the remaining tests

- [ ] **Step 1: Write failing tests:** `testApplyBlocksSkipsWhenUnlockedToday`, `testShieldsWhenUnlockedYesterday`, `testShieldsWhenNeverUnlocked`
- [ ] **Step 2: Implement the wiring and deletions; regenerate the project; build all targets**
  - Expect: the app plus 4 extensions build, and `grep -rE "TimeBalance|startSpendingSession|SessionRules|ViceMonitoring"` finds nothing in sources
- [ ] **Step 3: Run the full suite; expect PASS**
- [ ] **Step 4: Commit** `feat!: goal-based engine replaces the earn/spend balance`

### Task 5: Goal setup UI (onboarding + Settings)

**Files:**
- Create: `Clepsy/Views/Goal/GoalSetupView.swift`: a mode-choice step, then picker step(s), with `onDone: (GoalMode, Int) -> Void`
  - Slider: 5-min steps
  - Difficulty pill: animated color and label change, plus a selection haptic on band change
  - Build-up: two sliders, with the estimate line "About N days to reach X min"
- Modify:
  - `Clepsy/Views/Onboarding/OnboardingContainerView.swift`: step 4 uses `GoalSetupView`, which calls `GoalStore.setPlan`, completes onboarding and applies shields
  - `Clepsy/Views/Onboarding/WelcomeView.swift`: new copy
  - `Clepsy/Views/Settings/SettingsView.swift` + `Clepsy/ViewModels/SettingsViewModel.swift`:
    - The goal row opens `GoalSetupView` as a sheet, with a confirmation when lowering today's goal.
    - Add a Haptics toggle (mirrored).
    - Update the About copy.
- Delete: `Clepsy/Views/Onboarding/DailyGoalView.swift`
- Test: extend `OnboardingViewModelTests` only if logic moves there; the UI is verified by build and on-device

- [ ] **Step 1: Build the views; build the app** (expect success)
- [ ] **Step 2: Commit** `feat: two-mode goal setup with difficulty slider`

### Task 6: Dashboard for the goal model

**Files:**
- Modify:
  - `Clepsy/Views/Dashboard/DashboardView.swift`:
    - The hero hourglass shows goal progress (`earnedMinutes/todayGoal`); expression patient < 0.5 ≤ encouraging < reached = celebrating.
    - Show "18 of 30 min", the report line and a status chip with the four states. Claim is tappable and presents the claim screen.
    - Streak row: flame, count, freezes and a Badges link.
    - Build-up row.
    - Remove the goal-progress card and the balance UI.
  - `Clepsy/ViewModels/DashboardViewModel.swift`: owns the `GoalStore`; `refresh()` on appear/foreground
  - `Clepsy/Views/Components/ClepsyCharacterView.swift`: rename the `balancePercentage` parameter to `fillPercentage`
- [ ] **Step 1: Implement; build**
- [ ] **Step 2: Commit** `feat: dashboard shows goal progress, status and streak`

### Task 7: Reward layer (claim, haptics, confetti, badges)

**Files:**
- Create:
  - `Clepsy/Services/HapticsService.swift`: `static let shared`
    - `soft()`, `light()`, `heavyPop()`, `selection()`, `success()`
    - `rampSandPour(duration: TimeInterval)`: a Core Haptics continuous event, intensity curve 0.15 → 0.6
    - `stop()`
    - All are no-ops when `hapticsEnabled` is false or the hardware doesn't support haptics
  - `Clepsy/Views/Celebration/ConfettiView.swift`: `ConfettiView(trigger: Int, palette:)`, `TimelineView(.animation)` + `Canvas`, ~80 particles, gravity, ~1.6s life, seeded
  - `Clepsy/Views/Celebration/ClaimView.swift`: full-screen cover with the spec's timeline table (tap to skip to the button); Reduce Motion path; offer card after unlock
  - `Clepsy/Views/Badges/BadgesView.swift`: 3-column grid and a detail sheet with a shine sweep
  - `Clepsy/Views/Badges/BadgeMedallion.swift`
- Modify: `DashboardView.swift`: `.fullScreenCover(item: $store.pendingCelebration)`; also auto-present on appear when `.readyToClaim`
- [ ] **Step 1: Implement; build; run the full suite**
- [ ] **Step 2: Commit** `feat: claim celebration with haptics, confetti, streak and badges`

### Task 8: Ship

- [ ] Build for the device with the API key; install on the iPhone
- [ ] Push the branch; open the PR against `josuevillalona/device-testing-fixes` (stacked); run `code-review` (memory rule); fix the findings
- [ ] Linear:
  - CLE-48 / CLE-49: comment with the PR and builder's calls
  - Comment on the tickets this supersedes (CLE-37, 45, 46, 47, 16, 17, 19, 20, 4)
  - CLE-18: done by the midnight re-lock
