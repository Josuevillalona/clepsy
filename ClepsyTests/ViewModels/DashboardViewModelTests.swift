import XCTest
@testable import Clepsy

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var sut: DashboardViewModel!
    var mockPersistence: PersistenceService!

    override func setUp() {
        super.setUp()
        mockPersistence = PersistenceService(suiteName: "test.dashboard")!
        mockPersistence.clearAll()
        sut = DashboardViewModel(persistenceService: mockPersistence)
    }

    override func tearDown() {
        mockPersistence.clearAll()
        super.tearDown()
    }

    func testInitialBalance() {
        XCTAssertEqual(sut.currentBalance.currentSeconds, 0)
    }

    func testAddTime() {
        sut.addTime(seconds: 120)
        XCTAssertEqual(sut.currentBalance.currentSeconds, 120)
    }

    func testSubtractTime() {
        sut.addTime(seconds: 300)
        sut.subtractTime(seconds: 100)
        XCTAssertEqual(sut.currentBalance.currentSeconds, 200)
    }

    func testFormattedBalance() {
        sut.addTime(seconds: 3600) // 1 hour
        XCTAssertEqual(sut.formattedBalance, "1 hour")
    }

    func testFormattedBalanceWithMinutes() {
        sut.addTime(seconds: 5400) // 1 hour 30 minutes
        XCTAssertEqual(sut.formattedBalance, "1h 30m")
    }

    func testBalancePercentage() {
        // Default dailyGoalSeconds is 1800 (30 min)
        sut.addTime(seconds: 900) // 15 minutes = 50% of 30 min goal
        let expected = Double(900) / Double(1800)
        XCTAssertEqual(sut.balancePercentage, expected, accuracy: 0.01)
    }

    func testBalancePercentageAtGoal() {
        // Adding exactly the goal amount should be 100%
        sut.addTime(seconds: 1800) // 30 minutes = 100% of default goal
        XCTAssertEqual(sut.balancePercentage, 1.0, accuracy: 0.01)
    }
}
