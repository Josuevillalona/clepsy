import XCTest
@testable import Clepsy

final class SharedStorageServiceTests: XCTestCase {
    var sut: SharedStorageService!

    override func setUp() {
        super.setUp()
        sut = SharedStorageService()
        sut.clearEvents()
    }

    override func tearDown() {
        sut.clearEvents()
        super.tearDown()
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
}
