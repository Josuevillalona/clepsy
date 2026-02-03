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
        XCTAssertEqual(sut.formattedBalance, "1h 0m")
    }

    func testBalancePercentage() {
        sut.addTime(seconds: 1800) // 30 minutes
        // Assuming max display is 60 minutes (3600 seconds)
        let expected = Double(1800) / Double(3600)
        XCTAssertEqual(sut.balancePercentage, expected, accuracy: 0.01)
    }
}
