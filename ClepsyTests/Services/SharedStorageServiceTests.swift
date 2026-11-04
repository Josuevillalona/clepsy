import XCTest
@testable import Clepsy

final class SharedStorageServiceTests: XCTestCase {
    var sut: SharedStorageService!

    // Not a real App Group: its own UserDefaults suite and temp event file
    static let testSuite = "test.clepsy.sharedstorage"

    override func setUp() {
        super.setUp()
        Self.reset()
        sut = SharedStorageService(appGroup: Self.testSuite)
    }

    override func tearDown() {
        sut.clearEvents()
        Self.reset()
        super.tearDown()
    }

    static func reset() {
        UserDefaults(suiteName: testSuite)?.removePersistentDomain(forName: testSuite)
        SharedStorageService(appGroup: testSuite).clearEvents()
    }

    func testAppendAndGetEvents() {
        let event = TimeEvent(
            seconds: 300,
            timestamp: Date(),
            type: .earned,
            appBundleId: "com.amazon.Lassen"
        )

        sut.appendEvent(event)
        let retrieved = sut.getEvents()

        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.seconds, 300)
    }

    func testMultipleEventsInOrder() {
        let event1 = TimeEvent(seconds: 100, timestamp: Date(), type: .earned)
        let event2 = TimeEvent(seconds: 200, timestamp: Date().addingTimeInterval(1), type: .earned)

        sut.appendEvent(event1)
        sut.appendEvent(event2)

        let retrieved = sut.getEvents()
        XCTAssertEqual(retrieved.count, 2)
        XCTAssertEqual(retrieved[0].seconds, 100)
        XCTAssertEqual(retrieved[1].seconds, 200)
    }

    func testClearEvents() {
        let event = TimeEvent(seconds: 300, timestamp: Date(), type: .earned)
        sut.appendEvent(event)

        sut.clearEvents()
        XCTAssertTrue(sut.getEvents().isEmpty)
    }

    func testMixedEventTypes() {
        let earnedEvent = TimeEvent(seconds: 300, timestamp: Date(), type: .earned)
        let spentEvent = TimeEvent(seconds: 60, timestamp: Date(), type: .spent)

        sut.appendEvent(earnedEvent)
        sut.appendEvent(spentEvent)

        let retrieved = sut.getEvents()
        XCTAssertEqual(retrieved.count, 2)
        XCTAssertEqual(retrieved[0].type, .earned)
        XCTAssertEqual(retrieved[1].type, .spent)
    }

    func testRemoveSpecificEvents() {
        let event1 = TimeEvent(seconds: 100, timestamp: Date(), type: .earned)
        let event2 = TimeEvent(seconds: 200, timestamp: Date(), type: .earned)
        let event3 = TimeEvent(seconds: 300, timestamp: Date(), type: .earned)

        sut.appendEvent(event1)
        sut.appendEvent(event2)
        sut.appendEvent(event3)

        // Remove event2
        sut.removeEvents(withIds: [event2.id])

        let retrieved = sut.getEvents()
        XCTAssertEqual(retrieved.count, 2)
        XCTAssertEqual(retrieved[0].seconds, 100)
        XCTAssertEqual(retrieved[1].seconds, 300)
    }

    func testGetEventsWhenEmpty() {
        sut.clearEvents()
        let retrieved = sut.getEvents()
        XCTAssertTrue(retrieved.isEmpty)
    }

    // MARK: - State the extensions share

    func testCurrentBalanceIncludesPendingEvents() {
        sut.saveBalanceSeconds(120)
        sut.appendEvent(TimeEvent(seconds: 60, timestamp: Date(), type: .earned))
        sut.appendEvent(TimeEvent(seconds: 60, timestamp: Date(), type: .spent))
        sut.appendEvent(TimeEvent(seconds: 60, timestamp: Date(), type: .spent))

        XCTAssertEqual(sut.currentBalanceSeconds(), 60)
    }

    func testFastBalanceMatchesCurrentBalance() {
        // The shield configuration extension reads the fast path; it must
        // agree with the file-backed balance the action extension reads
        sut.saveBalanceSeconds(300)
        sut.appendEvent(TimeEvent(seconds: 120, timestamp: Date(), type: .spent))

        XCTAssertEqual(sut.fastBalanceSeconds(), sut.currentBalanceSeconds())
    }

    func testBalanceNeverGoesNegative() {
        sut.saveBalanceSeconds(0)
        sut.appendEvent(TimeEvent(seconds: 60, timestamp: Date(), type: .spent))

        XCTAssertEqual(sut.currentBalanceSeconds(), 0)
        XCTAssertEqual(sut.fastBalanceSeconds(), 0)
    }

    func testSessionActiveRoundTrip() {
        XCTAssertFalse(sut.isSessionActive)
        sut.saveSessionActive(true)
        XCTAssertTrue(sut.isSessionActive)
        sut.saveSessionActive(false)
        XCTAssertFalse(sut.isSessionActive)
    }

    func testSessionMeteringEndRoundTrip() {
        XCTAssertNil(sut.sessionMeteringEnd)
        let end = Date(timeIntervalSince1970: 1_793_779_140)
        sut.saveSessionMeteringEnd(end)
        XCTAssertEqual(sut.sessionMeteringEnd, end)
    }

    func testTestSuiteDoesNotTouchRealAppGroup() {
        let real = SharedStorageService()
        let realBalance = real.currentBalanceSeconds()
        sut.saveBalanceSeconds(9_999)
        XCTAssertEqual(real.currentBalanceSeconds(), realBalance)
    }

    func testShieldScreenRecordIsPerApp() {
        sut.setShieldShowedBalance(true, tokenKey: "test-app-a")
        sut.setShieldShowedBalance(false, tokenKey: "test-app-b")

        XCTAssertEqual(sut.shieldShowedBalance(tokenKey: "test-app-a"), true)
        XCTAssertEqual(sut.shieldShowedBalance(tokenKey: "test-app-b"), false)
        XCTAssertNil(sut.shieldShowedBalance(tokenKey: "test-app-never-shown"))
    }
}
