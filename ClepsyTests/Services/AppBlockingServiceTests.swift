import XCTest
import FamilyControls
import ManagedSettings
@testable import Clepsy

final class AppBlockingServiceTests: XCTestCase {
    var sut: AppBlockingService!

    override func setUp() {
        super.setUp()
        sut = AppBlockingService()
    }

    func testBlockAppsInterface() {
        let apps = AppCategory.defaultViceApps
        // This will not actually block apps in test environment
        // but verifies the interface is correct
        do {
            try sut.blockApps(apps)
            XCTAssertTrue(true)
        } catch {
            XCTFail("blockApps should not throw: \(error)")
        }
    }

    func testUnblockAppsInterface() {
        let apps = AppCategory.defaultViceApps
        do {
            try sut.unblockApps(apps)
            XCTAssertTrue(true)
        } catch {
            XCTFail("unblockApps should not throw: \(error)")
        }
    }

    func testBlockAllViceApps() {
        do {
            try sut.blockAllViceApps()
            XCTAssertTrue(true)
        } catch {
            XCTFail("blockAllViceApps should not throw: \(error)")
        }
    }

    func testUnblockAllViceApps() {
        do {
            try sut.unblockAllViceApps()
            XCTAssertTrue(true)
        } catch {
            XCTFail("unblockAllViceApps should not throw: \(error)")
        }
    }
}
