import XCTest
import DeviceActivity
import SwiftUI
import FamilyControls
@testable import Clepsy

@MainActor
final class UsageTrackingServiceTests: XCTestCase {
    var sut: UsageTrackingService!
    var sharedStorage: SharedStorageService!
    var persistence: PersistenceService!

    static let testSuite = "test.clepsy.usagetracking"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: Self.testSuite)?.removePersistentDomain(forName: Self.testSuite)
        sharedStorage = SharedStorageService(appGroup: Self.testSuite)
        sharedStorage.clearEvents()
        sut = UsageTrackingService(sharedStorage: sharedStorage)
        persistence = PersistenceService(suiteName: "test.usagetracking")!
        persistence.clearAll()
    }

    override func tearDown() {
        sharedStorage.clearEvents()
        UserDefaults(suiteName: Self.testSuite)?.removePersistentDomain(forName: Self.testSuite)
        persistence.clearAll()
        super.tearDown()
    }

    // MARK: - Monitoring guards

    func testDailyMonitoringWithNoProductiveAppsDoesNothing() {
        sut.startDailyMonitoring(productiveSelection: FamilyActivitySelection())
        XCTAssertFalse(sut.isMonitoringActive)
    }


    // MARK: - Event sync




    // MARK: - Report

    func testReportContextMatchesExtension() {
        XCTAssertEqual(DeviceActivityReport.Context.productiveTime.rawValue, "productiveTime")
    }

    func testReportDurationFormatting() {
        XCTAssertEqual(ReportFormatting.duration(seconds: 0), "0s")
        XCTAssertEqual(ReportFormatting.duration(seconds: 40), "40s")
        XCTAssertEqual(ReportFormatting.duration(seconds: 160), "2m 40s")
        XCTAssertEqual(ReportFormatting.duration(seconds: 3600), "1h 0m")
        XCTAssertEqual(ReportFormatting.duration(seconds: 5712), "1h 35m")
        XCTAssertEqual(ReportFormatting.duration(seconds: -5), "0s")
    }
}
