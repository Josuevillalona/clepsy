import XCTest
@testable import Clepsy

final class TimeEventTests: XCTestCase {
    func testTimeEventCreation() {
        let event = TimeEvent(
            seconds: 300,
            timestamp: Date(),
            type: .earned,
            appBundleId: "com.amazon.Lassen"
        )

        XCTAssertEqual(event.seconds, 300)
        XCTAssertEqual(event.type, .earned)
        XCTAssertEqual(event.appBundleId, "com.amazon.Lassen")
        XCTAssertNotNil(event.id)
    }

    func testEventTypeEncoding() throws {
        let event = TimeEvent(
            seconds: 120,
            timestamp: Date(),
            type: .spent,
            appBundleId: "com.zhiliaoapp.musically"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimeEvent.self, from: data)

        XCTAssertEqual(decoded.seconds, 120)
        XCTAssertEqual(decoded.type, .spent)
    }

    func testMultipleEventsArray() throws {
        let events = [
            TimeEvent(seconds: 300, timestamp: Date(), type: .earned),
            TimeEvent(seconds: 120, timestamp: Date(), type: .spent)
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(events)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([TimeEvent].self, from: data)

        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].type, .earned)
        XCTAssertEqual(decoded[1].type, .spent)
    }

    func testEventEquality() {
        let id = UUID()
        let timestamp = Date()

        let event1 = TimeEvent(id: id, seconds: 100, timestamp: timestamp, type: .earned)
        let event2 = TimeEvent(id: id, seconds: 100, timestamp: timestamp, type: .earned)

        XCTAssertEqual(event1, event2)
    }

    func testEventWithoutAppBundleId() {
        let event = TimeEvent(
            seconds: 60,
            timestamp: Date(),
            type: .earned
        )

        XCTAssertNil(event.appBundleId)
        XCTAssertEqual(event.seconds, 60)
    }
}
