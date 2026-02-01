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

    // MARK: - TimeBalance Tests

    func testSaveAndLoadTimeBalance() {
        var balance = TimeBalance(currentSeconds: 1800)
        balance.add(seconds: 300)

        sut.saveTimeBalance(balance)
        let loaded = sut.loadTimeBalance()

        XCTAssertEqual(loaded.currentSeconds, 2100)
    }

    func testLoadTimeBalanceWhenNoneExists() {
        let loaded = sut.loadTimeBalance()
        XCTAssertEqual(loaded.currentSeconds, 0)
    }

    func testTimeBalancePersistsAcrossInstances() {
        let balance = TimeBalance(currentSeconds: 500)
        sut.saveTimeBalance(balance)

        // Create new service instance
        let newService = PersistenceService(userDefaults: testDefaults)
        let loaded = newService.loadTimeBalance()

        XCTAssertEqual(loaded.currentSeconds, 500)
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

    // MARK: - Daily Reset Tests

    func testPerformDailyReset() {
        var balance = TimeBalance(currentSeconds: 1000)
        balance.add(seconds: 500)
        sut.saveTimeBalance(balance)

        sut.performDailyReset()

        let loaded = sut.loadTimeBalance()
        XCTAssertEqual(loaded.currentSeconds, 0)
    }

    func testLastResetDate() {
        let now = Date()
        sut.saveLastResetDate(now)

        let loaded = sut.loadLastResetDate()
        XCTAssertNotNil(loaded)

        // Compare timestamps (allowing 1 second tolerance)
        if let loaded = loaded {
            XCTAssertEqual(loaded.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1.0)
        }
    }

    func testLastResetDateWhenNoneExists() {
        let loaded = sut.loadLastResetDate()
        XCTAssertNil(loaded)
    }

    // MARK: - Clear All Data

    func testClearAllData() {
        // Set up some data
        var settings = UserSettings()
        settings.hasCompletedOnboarding = true
        sut.saveUserSettings(settings)

        let balance = TimeBalance(currentSeconds: 1000)
        sut.saveTimeBalance(balance)

        // Clear everything
        sut.clearAll()

        // Verify everything is reset
        let loadedSettings = sut.loadUserSettings()
        let loadedBalance = sut.loadTimeBalance()

        XCTAssertFalse(loadedSettings.hasCompletedOnboarding)
        XCTAssertEqual(loadedBalance.currentSeconds, 0)
        XCTAssertNil(sut.loadLastResetDate())
    }
}
