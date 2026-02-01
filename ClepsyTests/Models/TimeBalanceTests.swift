import XCTest
@testable import Clepsy

final class TimeBalanceTests: XCTestCase {
    func testInitialBalanceIsZero() {
        let balance = TimeBalance()
        XCTAssertEqual(balance.currentSeconds, 0)
    }

    func testAddingTime() {
        var balance = TimeBalance()
        balance.add(seconds: 120)
        XCTAssertEqual(balance.currentSeconds, 120)
    }

    func testSubtractingTime() {
        var balance = TimeBalance(currentSeconds: 120)
        balance.subtract(seconds: 60)
        XCTAssertEqual(balance.currentSeconds, 60)
    }

    func testCannotSubtractBelowZero() {
        var balance = TimeBalance(currentSeconds: 30)
        balance.subtract(seconds: 60)
        XCTAssertEqual(balance.currentSeconds, 0)
    }

    func testFormattedTimeDisplay() {
        let balance = TimeBalance(currentSeconds: 3665) // 1h 1m 5s
        XCTAssertEqual(balance.formattedTime, "1h 1m")
    }

    func testFormattedTimeMinutesOnly() {
        let balance = TimeBalance(currentSeconds: 180) // 3 minutes
        XCTAssertEqual(balance.formattedTime, "3m")
    }

    func testFormattedTimeZero() {
        let balance = TimeBalance(currentSeconds: 0)
        XCTAssertEqual(balance.formattedTime, "0m")
    }

    func testCodableEncoding() throws {
        let balance = TimeBalance(currentSeconds: 1800)
        let encoded = try JSONEncoder().encode(balance)
        XCTAssertNotNil(encoded)
    }

    func testCodableDecoding() throws {
        let balance = TimeBalance(currentSeconds: 1800)
        let encoded = try JSONEncoder().encode(balance)
        let decoded = try JSONDecoder().decode(TimeBalance.self, from: encoded)
        XCTAssertEqual(decoded.currentSeconds, 1800)
    }

    func testEquality() {
        let balance1 = TimeBalance(currentSeconds: 100)
        let balance2 = TimeBalance(currentSeconds: 100)
        let balance3 = TimeBalance(currentSeconds: 200)

        XCTAssertEqual(balance1, balance2)
        XCTAssertNotEqual(balance1, balance3)
    }
}
