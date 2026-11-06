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

    func testViceMonitoringWithNoViceAppsDoesNotRecordASession() {
        sut.startViceSpendingMonitoring(viceSelection: FamilyActivitySelection())
        XCTAssertNil(sharedStorage.sessionMeteringEnd)
    }

    // MARK: - Event sync

    func testSyncAppliesEarnedAndSpentEventsToBalance() {
        let viewModel = DashboardViewModel(persistenceService: persistence)
        sharedStorage.appendEvent(TimeEvent(seconds: 180, timestamp: Date(), type: .earned))
        sharedStorage.appendEvent(TimeEvent(seconds: 60, timestamp: Date().addingTimeInterval(1), type: .spent))

        sut.syncPendingEvents(to: viewModel)

        XCTAssertEqual(viewModel.currentBalance.currentSeconds, 120)
    }

    func testSyncDrainsTheEventQueue() {
        let viewModel = DashboardViewModel(persistenceService: persistence)
        sharedStorage.appendEvent(TimeEvent(seconds: 60, timestamp: Date(), type: .earned))

        sut.syncPendingEvents(to: viewModel)

        XCTAssertTrue(sharedStorage.getEvents().isEmpty)
    }

    func testSyncAppliesEventsInTimestampOrder() {
        // Spending before earning would be clamped at zero and lost
        let viewModel = DashboardViewModel(persistenceService: persistence)
        let now = Date()
        sharedStorage.appendEvent(TimeEvent(seconds: 60, timestamp: now.addingTimeInterval(5), type: .spent))
        sharedStorage.appendEvent(TimeEvent(seconds: 120, timestamp: now, type: .earned))

        sut.syncPendingEvents(to: viewModel)

        XCTAssertEqual(viewModel.currentBalance.currentSeconds, 60)
    }

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
