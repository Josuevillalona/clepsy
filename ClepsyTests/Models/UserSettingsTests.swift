import XCTest
@testable import Clepsy

final class UserSettingsTests: XCTestCase {
    func testDefaultInitialization() {
        let settings = UserSettings()

        XCTAssertFalse(settings.hasCompletedOnboarding)
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertEqual(settings.exchangeRate, 1.0)
        XCTAssertTrue(settings.viceApps.isEmpty)
        XCTAssertTrue(settings.productiveApps.isEmpty)
    }

    func testOnboardingCompletion() {
        var settings = UserSettings()
        settings.hasCompletedOnboarding = true

        XCTAssertTrue(settings.hasCompletedOnboarding)
    }

    func testNotificationSettings() {
        var settings = UserSettings()
        settings.notificationsEnabled = false

        XCTAssertFalse(settings.notificationsEnabled)
    }

    func testViceAppsManagement() {
        var settings = UserSettings()
        let tiktok = TrackedApp(
            name: "TikTok",
            bundleIdentifier: "com.zhiliaoapp.musically",
            category: .vice
        )

        settings.viceApps = [tiktok]
        XCTAssertEqual(settings.viceApps.count, 1)
        XCTAssertEqual(settings.viceApps.first?.name, "TikTok")
    }

    func testProductiveAppsManagement() {
        var settings = UserSettings()
        let kindle = TrackedApp(
            name: "Kindle",
            bundleIdentifier: "com.amazon.Lassen",
            category: .productive
        )

        settings.productiveApps = [kindle]
        XCTAssertEqual(settings.productiveApps.count, 1)
        XCTAssertEqual(settings.productiveApps.first?.name, "Kindle")
    }

    func testCodableEncoding() throws {
        var settings = UserSettings()
        settings.hasCompletedOnboarding = true
        settings.viceApps = AppCategory.defaultViceApps
        settings.productiveApps = AppCategory.defaultProductiveApps

        let encoded = try JSONEncoder().encode(settings)
        XCTAssertNotNil(encoded)
    }

    func testCodableDecoding() throws {
        var settings = UserSettings()
        settings.hasCompletedOnboarding = true
        settings.notificationsEnabled = false
        settings.viceApps = AppCategory.defaultViceApps
        settings.productiveApps = AppCategory.defaultProductiveApps

        let encoded = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(UserSettings.self, from: encoded)

        XCTAssertEqual(decoded.hasCompletedOnboarding, true)
        XCTAssertEqual(decoded.notificationsEnabled, false)
        XCTAssertEqual(decoded.viceApps.count, settings.viceApps.count)
        XCTAssertEqual(decoded.productiveApps.count, settings.productiveApps.count)
    }

    func testExchangeRateDefault() {
        let settings = UserSettings()
        XCTAssertEqual(settings.exchangeRate, 1.0)
    }
}
