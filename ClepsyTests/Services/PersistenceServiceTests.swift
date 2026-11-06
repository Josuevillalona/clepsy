import XCTest
@testable import Clepsy

final class PersistenceServiceTests: XCTestCase {
    var sut: PersistenceService!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Use a test suite to avoid affecting real user data
        testDefaults = UserDefaults(suiteName: "com.clepsy.tests")!
        testDefaults.removePersistentDomain(forName: "com.clepsy.tests")
        sut = PersistenceService(userDefaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.clepsy.tests")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - UserSettings Tests

    func testSaveAndLoadUserSettings() {
        var settings = UserSettings()
        settings.hasCompletedOnboarding = true
        settings.notificationsEnabled = false
        settings.viceApps = AppCategory.defaultViceApps

        sut.saveUserSettings(settings)
        let loaded = sut.loadUserSettings()

        XCTAssertEqual(loaded.hasCompletedOnboarding, true)
        XCTAssertEqual(loaded.notificationsEnabled, false)
        XCTAssertEqual(loaded.viceApps.count, settings.viceApps.count)
    }

    func testLoadUserSettingsWhenNoneExists() {
        let loaded = sut.loadUserSettings()

        XCTAssertFalse(loaded.hasCompletedOnboarding)
        XCTAssertTrue(loaded.notificationsEnabled)
        XCTAssertTrue(loaded.viceApps.isEmpty)
    }

    func testUserSettingsPersistsAcrossInstances() {
        var settings = UserSettings()
        settings.hasCompletedOnboarding = true
        sut.saveUserSettings(settings)

        let newService = PersistenceService(userDefaults: testDefaults)
        let loaded = newService.loadUserSettings()

        XCTAssertTrue(loaded.hasCompletedOnboarding)
    }

    // MARK: - Goal Plan, Streak, Badges

    func testGoalPlanRoundTrip() {
        XCTAssertNil(sut.loadGoalPlan())
        let plan = GoalPlan(mode: .buildUp(target: 45), currentGoal: 20, consecutiveReached: 2, pendingGoal: 25)
        sut.saveGoalPlan(plan)
        XCTAssertEqual(sut.loadGoalPlan(), plan)
    }

    func testStreakAndBadgesRoundTrip() {
        let streak = StreakState(count: 6, freezes: 1, lastProcessedDay: "2026-11-03")
        sut.saveStreak(streak)
        let date = Date(timeIntervalSince1970: 1_793_779_140)
        sut.saveBadges([.firstGoal: date])
        sut.saveUnseenBadges([.streak3])
        XCTAssertEqual(sut.loadStreak(), streak)
        XCTAssertEqual(sut.loadBadges(), [.firstGoal: date])
        XCTAssertEqual(sut.loadUnseenBadges(), [.streak3])
    }

    func testClearAllRemovesGoalState() {
        sut.saveGoalPlan(.default)
        sut.saveStreak(StreakState(count: 3))
        sut.saveBadges([.firstGoal: Date()])
        sut.clearAll()
        XCTAssertNil(sut.loadGoalPlan())
        XCTAssertEqual(sut.loadStreak(), StreakState())
        XCTAssertTrue(sut.loadBadges().isEmpty)
    }
}
