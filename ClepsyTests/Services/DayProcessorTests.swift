import XCTest
@testable import Clepsy

final class DayProcessorTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
    }

    /// Consecutive day keys starting 2026-11-01
    private func days(_ count: Int, from start: String = "2026-11-01") -> [String] {
        let first = DayKey.date(from: start, calendar: calendar)!
        return (0..<count).map {
            DayKey.string(for: calendar.date(byAdding: .day, value: $0, to: first)!, calendar: calendar)
        }
    }

    private func run(_ days: [String], reached: Set<String>,
                     streak: StreakState = StreakState(),
                     plan: GoalPlan = .default,
                     earned: Set<BadgeID> = []) -> DayResult {
        DayProcessor.process(days: days, reached: reached, streak: streak, plan: plan,
                             earned: earned, calendar: calendar)
    }

    func testReachedDaysBuildStreak() {
        let d = days(3)
        let result = run(d, reached: Set(d))
        XCTAssertEqual(result.streak.count, 3)
        XCTAssertEqual(result.streak.lastProcessedDay, "2026-11-03")
        XCTAssertEqual(result.plan.consecutiveReached, 3)
    }

    func testSeventhDayEarnsFreezeCappedAtTwo() {
        XCTAssertEqual(run(days(7), reached: Set(days(7))).streak.freezes, 1)
        XCTAssertEqual(run(days(21), reached: Set(days(21))).streak.freezes, 2)
    }

    func testMissedDayUsesFreeze() {
        let d = days(2)
        let result = run(d, reached: [d[0]], streak: StreakState(count: 9, freezes: 1))
        XCTAssertEqual(result.streak.count, 10)
        XCTAssertEqual(result.streak.freezes, 0)
        XCTAssertEqual(result.streak.frozenDays, [d[1]])
        XCTAssertEqual(result.plan.consecutiveReached, 0)
    }

    func testMissedDayWithoutFreezeResets() {
        let d = days(1)
        let result = run(d, reached: [], streak: StreakState(count: 9, freezes: 0))
        XCTAssertEqual(result.streak.count, 0)
        XCTAssertEqual(result.streak.lastResetDay, d[0])
    }

    func testGapOfFourDaysUsesFreezesThenResets() {
        let result = run(days(4), reached: [], streak: StreakState(count: 20, freezes: 2))
        XCTAssertEqual(result.streak.freezes, 0)
        XCTAssertEqual(result.streak.count, 0)
        XCTAssertEqual(result.streak.frozenDays.count, 2)
    }

    func testPendingGoalAppliesNextDay() {
        var plan = GoalPlan(mode: .buildUp(target: 45), currentGoal: 20, consecutiveReached: 0, pendingGoal: 25)
        plan = run(days(1), reached: [], plan: plan).plan
        XCTAssertEqual(plan.currentGoal, 25)
        XCTAssertNil(plan.pendingGoal)
    }

    func testReachingBuildUpTargetSwitchesToFixedAndAwardsBadge() {
        let plan = GoalPlan(mode: .buildUp(target: 30), currentGoal: 25, consecutiveReached: 0, pendingGoal: 30)
        let result = run(days(1), reached: Set(days(1)), plan: plan)
        XCTAssertEqual(result.plan.mode, .fixed)
        XCTAssertEqual(result.plan.currentGoal, 30)
        XCTAssertTrue(result.newBadges.contains(.builtUp))
    }

    func testStreakBadgesAwardedOnce() {
        let d = days(7)
        let result = run(d, reached: Set(d))
        XCTAssertEqual(Set(result.newBadges), [.firstGoal, .streak3, .streak7, .firstFreeze])

        let again = run(days(1, from: "2026-11-08"), reached: ["2026-11-08"], streak: result.streak,
                        earned: Set(result.newBadges))
        XCTAssertTrue(again.newBadges.isEmpty)
    }

    func testComebackBadge() {
        let d = days(2)
        let result = run(d, reached: [d[1]], streak: StreakState(count: 4, freezes: 0), earned: [.firstGoal])
        XCTAssertEqual(result.newBadges, [.comeback])
    }

    func testIntenseBadgeAtEighty() {
        let plan = GoalPlan(mode: .fixed, currentGoal: 80, consecutiveReached: 0, pendingGoal: nil)
        XCTAssertTrue(run(days(1), reached: Set(days(1)), plan: plan, earned: [.firstGoal]).newBadges.contains(.intense))

        let lower = GoalPlan(mode: .fixed, currentGoal: 75, consecutiveReached: 0, pendingGoal: nil)
        XCTAssertFalse(run(days(1), reached: Set(days(1)), plan: lower).newBadges.contains(.intense))
    }

    func testDaysToProcessSpansGap() {
        XCTAssertEqual(
            DayProcessor.daysToProcess(after: "2026-11-01", through: "2026-11-04", calendar: calendar),
            ["2026-11-02", "2026-11-03", "2026-11-04"]
        )
        XCTAssertEqual(DayProcessor.daysToProcess(after: "2026-11-04", through: "2026-11-04", calendar: calendar), [])
        XCTAssertEqual(DayProcessor.daysToProcess(after: nil, through: "2026-11-04", calendar: calendar), [])
    }

    func testDaysToProcessCrossesMonthEnd() {
        XCTAssertEqual(
            DayProcessor.daysToProcess(after: "2026-10-30", through: "2026-11-01", calendar: calendar),
            ["2026-10-31", "2026-11-01"]
        )
    }
}
