import XCTest
@testable import Clepsy

final class GoalRulesTests: XCTestCase {

    // MARK: - Difficulty and ranges

    func testDifficultyBands() {
        XCTAssertEqual(GoalDifficulty.forMinutes(5), .easy)
        XCTAssertEqual(GoalDifficulty.forMinutes(20), .easy)
        XCTAssertEqual(GoalDifficulty.forMinutes(25), .medium)
        XCTAssertEqual(GoalDifficulty.forMinutes(45), .medium)
        XCTAssertEqual(GoalDifficulty.forMinutes(50), .hard)
        XCTAssertEqual(GoalDifficulty.forMinutes(75), .hard)
        XCTAssertEqual(GoalDifficulty.forMinutes(80), .intense)
        XCTAssertEqual(GoalDifficulty.forMinutes(120), .intense)
    }

    func testTargetRangeStartsFiveAboveStart() {
        XCTAssertEqual(GoalRules.targetRange(start: 60), 65...120)
        XCTAssertEqual(GoalRules.startRange(), 5...115)
    }

    func testEstimatedDays() {
        XCTAssertEqual(GoalRules.estimatedDays(start: 10, target: 45), 21)
        XCTAssertEqual(GoalRules.estimatedDays(start: 60, target: 120), 36)
    }

    func testClampedRoundsToStepsWithinRange() {
        XCTAssertEqual(GoalRules.clamped(240), 120)
        XCTAssertEqual(GoalRules.clamped(37), 35)
        XCTAssertEqual(GoalRules.clamped(0), 5)
    }

    // MARK: - Build-up offers

    private func buildUp(goal: Int, target: Int, count: Int) -> GoalPlan {
        GoalPlan(mode: .buildUp(target: target), currentGoal: goal, consecutiveReached: count, pendingGoal: nil)
    }

    func testOfferDueAfterThreeDaysBelowTarget() {
        XCTAssertTrue(GoalRules.isOfferDue(buildUp(goal: 20, target: 30, count: 3)))
        XCTAssertFalse(GoalRules.isOfferDue(buildUp(goal: 20, target: 30, count: 2)))
        XCTAssertEqual(GoalRules.nextOfferGoal(buildUp(goal: 20, target: 30, count: 3)), 25)
    }

    func testNoOfferInFixedModeOrAtTarget() {
        let fixed = GoalPlan(mode: .fixed, currentGoal: 20, consecutiveReached: 9, pendingGoal: nil)
        XCTAssertFalse(GoalRules.isOfferDue(fixed))
        XCTAssertFalse(GoalRules.isOfferDue(buildUp(goal: 30, target: 30, count: 5)))
        XCTAssertNil(GoalRules.nextOfferGoal(fixed))
    }

    func testNoOfferWhileARaiseIsAlreadyPending() {
        var plan = buildUp(goal: 20, target: 30, count: 3)
        plan.pendingGoal = 25
        XCTAssertFalse(GoalRules.isOfferDue(plan))
    }

    func testAcceptSetsPendingGoalAndResetsCount() {
        let accepted = GoalRules.accept(buildUp(goal: 20, target: 30, count: 3))
        XCTAssertEqual(accepted.pendingGoal, 25)
        XCTAssertEqual(accepted.currentGoal, 20)
        XCTAssertEqual(accepted.consecutiveReached, 0)
    }

    func testDeclineResetsCountOnly() {
        let declined = GoalRules.decline(buildUp(goal: 20, target: 30, count: 3))
        XCTAssertNil(declined.pendingGoal)
        XCTAssertEqual(declined.currentGoal, 20)
        XCTAssertEqual(declined.consecutiveReached, 0)
    }

    // MARK: - Earning

    func testEarnFirstEventOfDay() {
        let result = EarnRules.apply(eventMinute: 1, today: "2026-11-04", stored: nil, goal: 30)
        XCTAssertEqual(result.state, EarnState(day: "2026-11-04", minutes: 1, reached: false))
        XCTAssertFalse(result.justReached)
    }

    func testEarnReachesGoalOnce() {
        let first = EarnRules.apply(eventMinute: 30, today: "2026-11-04",
                                    stored: EarnState(day: "2026-11-04", minutes: 29, reached: false), goal: 30)
        XCTAssertTrue(first.justReached)
        XCTAssertTrue(first.state.reached)

        let next = EarnRules.apply(eventMinute: 31, today: "2026-11-04", stored: first.state, goal: 30)
        XCTAssertTrue(next.state.reached)
        XCTAssertFalse(next.justReached)
    }

    func testRepeatedAndOutOfOrderEventsAreIdempotent() {
        let stored = EarnState(day: "2026-11-04", minutes: 12, reached: false)
        let result = EarnRules.apply(eventMinute: 9, today: "2026-11-04", stored: stored, goal: 30)
        XCTAssertEqual(result.state.minutes, 12)
        XCTAssertFalse(result.justReached)
    }

    func testNewDayResetsEarnState() {
        let stored = EarnState(day: "2026-11-03", minutes: 50, reached: true)
        let result = EarnRules.apply(eventMinute: 1, today: "2026-11-04", stored: stored, goal: 30)
        XCTAssertEqual(result.state, EarnState(day: "2026-11-04", minutes: 1, reached: false))
    }

    func testParseEventName() {
        XCTAssertEqual(EarnRules.minute(fromEventName: "earn_12"), 12)
        XCTAssertNil(EarnRules.minute(fromEventName: "spend_3"))
        XCTAssertNil(EarnRules.minute(fromEventName: "earn_x"))
    }

    // MARK: - Formatting

    func testGoalFormatting() {
        XCTAssertEqual(GoalFormatting.minutes(45), "45 min")
        XCTAssertEqual(GoalFormatting.minutes(60), "1h")
        XCTAssertEqual(GoalFormatting.minutes(90), "1h 30m")
        XCTAssertEqual(GoalFormatting.plan(.default), "Same goal · 30 min")
        let buildUp = GoalPlan(mode: .buildUp(target: 45), currentGoal: 20, consecutiveReached: 0, pendingGoal: nil)
        XCTAssertEqual(GoalFormatting.plan(buildUp), "Build up · 20 min → 45 min")
    }

    // MARK: - Day keys

    func testDayKeyFormat() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 23, minute: 30))!
        XCTAssertEqual(DayKey.string(for: date, calendar: calendar), "2026-03-07")
    }
}

final class SharedGoalStateTests: XCTestCase {
    static let suite = "test.clepsy.goalstate"
    var sut: SharedStorageService!

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: Self.suite)?.removePersistentDomain(forName: Self.suite)
        sut = SharedStorageService(appGroup: Self.suite)
    }

    override func tearDown() {
        UserDefaults(suiteName: Self.suite)?.removePersistentDomain(forName: Self.suite)
        super.tearDown()
    }

    func testStaleGoalDayFallsBackToBase() {
        sut.saveGoalToday(minutes: 15, day: "2026-11-03")
        sut.saveGoalBase(30)
        XCTAssertEqual(sut.goalMinutes(for: "2026-11-04"), 30)
        XCTAssertEqual(sut.goalMinutes(for: "2026-11-03"), 15)
    }

    func testGoalDefaultsToThirty() {
        XCTAssertEqual(sut.goalMinutes(for: "2026-11-04"), 30)
    }

    func testEarnStateRoundTrip() {
        XCTAssertNil(sut.earnState)
        let state = EarnState(day: "2026-11-04", minutes: 12, reached: false)
        sut.saveEarnState(state)
        XCTAssertEqual(sut.earnState, state)
    }

    func testReachedDaysKeepsLatestSixty() {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        for offset in 0..<70 {
            sut.addReachedDay(DayKey.string(for: calendar.date(byAdding: .day, value: offset, to: start)!, calendar: calendar))
        }
        XCTAssertEqual(sut.reachedDays.count, 60)
        XCTAssertFalse(sut.reachedDays.contains("2026-01-01"))
        XCTAssertTrue(sut.reachedDays.contains("2026-03-11"))
    }

    func testUnlockedDayAndHapticsMirror() {
        XCTAssertNil(sut.unlockedDay)
        sut.saveUnlockedDay("2026-11-04")
        XCTAssertEqual(sut.unlockedDay, "2026-11-04")
        XCTAssertTrue(sut.hapticsEnabled)
        sut.saveHapticsEnabled(false)
        XCTAssertFalse(sut.hapticsEnabled)
    }
}

final class GoalShieldRulesTests: XCTestCase {

    func testShieldBeforeGoalShowsProgress() {
        let content = ShieldRules.content(appName: "Instagram", earnedMinutes: 12, goalMinutes: 30, reached: false)
        XCTAssertEqual(content.title, "Instagram is locked")
        XCTAssertTrue(content.subtitle.contains("12 of 30 min today"))
        XCTAssertEqual(content.primaryButton, "Go Back")
        XCTAssertNil(content.secondaryButton)
    }

    func testShieldReachedOffersClaim() {
        let content = ShieldRules.content(appName: "Instagram", earnedMinutes: 30, goalMinutes: 30, reached: true)
        XCTAssertEqual(content.title, "You did it 🎉")
        XCTAssertEqual(content.primaryButton, "Claim in Clepsy")
        XCTAssertEqual(content.secondaryButton, "Go Back")
    }

    func testShieldWithoutAppNameUsesGenericTitle() {
        XCTAssertEqual(ShieldRules.content(appName: nil, earnedMinutes: 0, goalMinutes: 30, reached: false).title,
                       "This app is locked")
    }

    func testPrimaryTapClaimsOnlyWhenReached() {
        XCTAssertEqual(ShieldRules.primaryTap(reached: true), .claimViaNotification)
        XCTAssertEqual(ShieldRules.primaryTap(reached: false), .close)
    }
}
