import XCTest
@testable import Clepsy

@MainActor
final class GoalStoreTests: XCTestCase {
    static let sharedSuite = "test.clepsy.goalstore.shared"
    static let persistenceSuite = "test.clepsy.goalstore"

    var persistence: PersistenceService!
    var shared: SharedStorageService!
    var calendar: Calendar!
    var now: Date!
    var unlockCalls = 0

    override func setUp() {
        super.setUp()
        for suite in [Self.sharedSuite, Self.persistenceSuite] {
            UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        }
        persistence = PersistenceService(suiteName: Self.persistenceSuite)!
        shared = SharedStorageService(appGroup: Self.sharedSuite)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 4, hour: 15))!
        unlockCalls = 0
    }

    override func tearDown() {
        for suite in [Self.sharedSuite, Self.persistenceSuite] {
            UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        }
        super.tearDown()
    }

    private let today = "2026-11-04"

    private func makeStore() -> GoalStore {
        GoalStore(persistence: persistence, shared: shared, now: { self.now }, calendar: calendar,
                  unlockApps: { self.unlockCalls += 1 })
    }

    private func setPlan(_ plan: GoalPlan) {
        persistence.saveGoalPlan(plan)
    }

    private func earned(_ minutes: Int, reached: Bool = false) {
        shared.saveEarnState(EarnState(day: today, minutes: minutes, reached: reached))
    }

    func testMigratesFromDailyGoalMinutes() {
        var settings = UserSettings()
        settings.dailyGoalMinutes = 240
        persistence.saveUserSettings(settings)
        XCTAssertEqual(makeStore().plan, GoalPlan(mode: .fixed, currentGoal: 120, consecutiveReached: 0, pendingGoal: nil))

        UserDefaults(suiteName: Self.persistenceSuite)?.removePersistentDomain(forName: Self.persistenceSuite)
        settings.dailyGoalMinutes = 37
        persistence.saveUserSettings(settings)
        XCTAssertEqual(makeStore().plan.currentGoal, 35)
    }

    func testRefreshMirrorsTodaysGoal() {
        setPlan(GoalPlan(mode: .fixed, currentGoal: 45, consecutiveReached: 0, pendingGoal: nil))
        makeStore().refresh()
        XCTAssertEqual(shared.goalMinutes(for: today), 45)
    }

    func testStatusLockedShowsMinutesToGo() {
        earned(18)
        let store = makeStore()
        store.refresh()
        XCTAssertEqual(store.status, .locked(minutesToGo: 12))
        XCTAssertNil(store.pendingCelebration)
    }

    func testAlmostThereAtGoalMinusOne() {
        earned(29)
        let store = makeStore()
        store.refresh()
        XCTAssertEqual(store.status, .almostThere)
    }

    func testReachedButUnclaimedIsReadyToClaimWithCelebration() {
        earned(30, reached: true)
        let store = makeStore()
        store.refresh()
        XCTAssertEqual(store.status, .readyToClaim)
        XCTAssertEqual(store.pendingCelebration?.goal, 30)
        XCTAssertEqual(store.pendingCelebration?.streakAfter, 1)
        XCTAssertEqual(store.pendingCelebration?.newBadges, [.firstGoal])
    }

    func testClaimUnlocksAndMarksDay() {
        earned(30, reached: true)
        let store = makeStore()
        store.refresh()
        store.claim()
        XCTAssertEqual(unlockCalls, 1)
        XCTAssertEqual(store.status, .unlocked)
        XCTAssertEqual(shared.unlockedDay, today)
        XCTAssertNotNil(store.badges[.firstGoal])
    }

    func testClaimBeforeGoalDoesNothing() {
        earned(10)
        let store = makeStore()
        store.refresh()
        store.claim()
        XCTAssertEqual(unlockCalls, 0)
        XCTAssertNil(shared.unlockedDay)
    }

    func testLoweringGoalBelowEarnedMarksReached() {
        earned(18)
        let store = makeStore()
        store.refresh()
        store.setPlan(mode: .fixed, goal: 15)
        XCTAssertEqual(store.status, .readyToClaim)
        XCTAssertTrue(shared.reachedDays.contains(today))
        XCTAssertEqual(shared.earnState?.reached, true)
    }

    func testGoalChangeAfterReachedAppliesTomorrow() {
        earned(30, reached: true)
        let store = makeStore()
        store.refresh()
        store.setPlan(mode: .fixed, goal: 45)
        XCTAssertEqual(store.todayGoal, 30)
        XCTAssertEqual(store.plan.pendingGoal, 45)
        XCTAssertEqual(shared.goalMinutes(for: "2026-11-05"), 45)
    }

    func testCelebrationIncludesOfferWhenDue() {
        // Two earlier days in a row; today is the third
        setPlan(GoalPlan(mode: .buildUp(target: 45), currentGoal: 20, consecutiveReached: 2, pendingGoal: nil))
        earned(20, reached: true)
        let store = makeStore()
        store.refresh()
        XCTAssertEqual(store.pendingCelebration?.offerGoal, 25)
    }

    func testAcceptOfferRaisesFromTomorrowAndRestartsCount() {
        setPlan(GoalPlan(mode: .buildUp(target: 45), currentGoal: 20, consecutiveReached: 2, pendingGoal: nil))
        persistence.saveStreak(StreakState(count: 2, lastProcessedDay: "2026-11-03"))
        earned(20, reached: true)
        shared.addReachedDay(today)
        let store = makeStore()
        store.refresh()
        store.acceptOffer()
        XCTAssertEqual(store.todayGoal, 20)
        XCTAssertEqual(store.plan.pendingGoal, 25)

        // Tomorrow: the raise applies and the count toward the next offer starts at 0
        now = calendar.date(byAdding: .day, value: 1, to: now)
        let tomorrow = makeStore()
        tomorrow.refresh()
        XCTAssertEqual(tomorrow.todayGoal, 25)
        XCTAssertEqual(tomorrow.plan.consecutiveReached, 0)
    }

    func testDeclineOfferAsksAgainAfterThreeMoreDays() {
        setPlan(GoalPlan(mode: .buildUp(target: 45), currentGoal: 20, consecutiveReached: 2, pendingGoal: nil))
        persistence.saveStreak(StreakState(count: 2, lastProcessedDay: "2026-11-03"))
        earned(20, reached: true)
        shared.addReachedDay(today)
        let store = makeStore()
        store.refresh()
        store.declineOffer()

        now = calendar.date(byAdding: .day, value: 1, to: now)
        let tomorrow = makeStore()
        tomorrow.refresh()
        XCTAssertEqual(tomorrow.plan.consecutiveReached, 0)
        XCTAssertEqual(tomorrow.todayGoal, 20)
    }

    func testRolloverProcessesYesterday() {
        persistence.saveStreak(StreakState(count: 4, lastProcessedDay: "2026-11-02"))
        shared.addReachedDay("2026-11-03")
        let store = makeStore()
        store.refresh()
        XCTAssertEqual(store.streak.count, 5)
        XCTAssertEqual(store.streak.lastProcessedDay, "2026-11-03")
    }

    func testFirstRunStartsHistoryAtYesterday() {
        let store = makeStore()
        store.refresh()
        XCTAssertEqual(store.streak.lastProcessedDay, "2026-11-03")
        XCTAssertEqual(store.streak.count, 0)
    }

    func testRolloverBadgesShowInNextCelebration() {
        // Yesterday completed a 3-day streak; today's claim should show the badge
        persistence.saveStreak(StreakState(count: 2, lastProcessedDay: "2026-11-02"))
        persistence.saveBadges([.firstGoal: now])
        shared.addReachedDay("2026-11-03")
        earned(30, reached: true)
        let store = makeStore()
        store.refresh()
        XCTAssertEqual(store.pendingCelebration?.newBadges, [.streak3])
    }

    func testDisplayStreakIncludesToday() {
        persistence.saveStreak(StreakState(count: 4, lastProcessedDay: "2026-11-03"))
        earned(30, reached: true)
        let store = makeStore()
        store.refresh()
        XCTAssertEqual(store.displayStreak, 5)
    }

    func testDismissedCelebrationStaysAwayUntilAskedFor() {
        earned(30, reached: true)
        let store = makeStore()
        store.refresh()
        store.dismissCelebration()
        store.refresh()
        XCTAssertNil(store.pendingCelebration)
        XCTAssertEqual(store.status, .readyToClaim)

        store.presentCelebration()
        XCTAssertEqual(store.pendingCelebration?.id, today)
    }

    func testCelebrationStaysOpenAfterClaimUntilFinished() {
        earned(30, reached: true)
        let store = makeStore()
        store.refresh()
        store.claim()
        store.refresh()
        XCTAssertNotNil(store.pendingCelebration)
        store.finishCelebration()
        store.refresh()
        XCTAssertNil(store.pendingCelebration)
    }

    func testSavingTheSamePlanKeepsOfferProgress() {
        let plan = GoalPlan(mode: .buildUp(target: 45), currentGoal: 20, consecutiveReached: 2, pendingGoal: nil)
        setPlan(plan)
        earned(5)
        let store = makeStore()
        store.refresh()
        store.setPlan(mode: .buildUp(target: 45), goal: 20)
        XCTAssertEqual(store.plan.consecutiveReached, 2)
    }
}
