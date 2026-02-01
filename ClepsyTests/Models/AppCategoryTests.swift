import XCTest
import FamilyControls
@testable import Clepsy

final class AppCategoryTests: XCTestCase {
    func testViceAppCategory() {
        let category = AppCategory.vice
        XCTAssertEqual(category.displayName, "Vice Apps")
        XCTAssertTrue(category.isBlocked)
    }

    func testProductiveAppCategory() {
        let category = AppCategory.productive
        XCTAssertEqual(category.displayName, "Productive Apps")
        XCTAssertFalse(category.isBlocked)
    }

    func testDefaultViceApps() {
        let defaults = AppCategory.defaultViceApps
        XCTAssertTrue(defaults.contains { $0.name == "TikTok" })
        XCTAssertTrue(defaults.contains { $0.name == "Instagram" })
        XCTAssertTrue(defaults.contains { $0.name == "Twitter/X" })
    }

    func testDefaultProductiveApps() {
        let defaults = AppCategory.defaultProductiveApps
        XCTAssertTrue(defaults.contains { $0.name == "Kindle" })
        XCTAssertTrue(defaults.contains { $0.name == "Duolingo" })
    }

    func testTrackedAppCreation() {
        let app = TrackedApp(
            name: "TestApp",
            bundleIdentifier: "com.test.app",
            category: .vice
        )

        XCTAssertEqual(app.name, "TestApp")
        XCTAssertEqual(app.bundleIdentifier, "com.test.app")
        XCTAssertEqual(app.category, .vice)
        XCTAssertNotNil(app.id)
    }

    func testTrackedAppCodable() throws {
        let app = TrackedApp(
            name: "TestApp",
            bundleIdentifier: "com.test.app",
            category: .productive
        )

        let encoded = try JSONEncoder().encode(app)
        let decoded = try JSONDecoder().decode(TrackedApp.self, from: encoded)

        XCTAssertEqual(decoded.name, app.name)
        XCTAssertEqual(decoded.bundleIdentifier, app.bundleIdentifier)
        XCTAssertEqual(decoded.category, app.category)
    }

    func testTrackedAppEquality() {
        let app1 = TrackedApp(
            id: UUID(),
            name: "TestApp",
            bundleIdentifier: "com.test.app",
            category: .vice
        )

        let app2 = TrackedApp(
            id: app1.id,
            name: "TestApp",
            bundleIdentifier: "com.test.app",
            category: .vice
        )

        let app3 = TrackedApp(
            id: UUID(),
            name: "Different",
            bundleIdentifier: "com.different.app",
            category: .productive
        )

        XCTAssertEqual(app1, app2)
        XCTAssertNotEqual(app1, app3)
    }
}
