import XCTest
import FamilyControls
@testable import Clepsy

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var sut: DashboardViewModel!
    var persistence: PersistenceService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceService(suiteName: "test.dashboard")!
        persistence.clearAll()
        sut = DashboardViewModel(persistenceService: persistence)
    }

    override func tearDown() {
        persistence.clearAll()
        super.tearDown()
    }

    func testStartsWithEmptySelections() {
        XCTAssertTrue(sut.viceSelection.applicationTokens.isEmpty)
        XCTAssertTrue(sut.productiveSelection.applicationTokens.isEmpty)
    }

    func testRefreshReloadsSelections() {
        sut.refreshSelections()
        XCTAssertTrue(sut.viceSelection.applicationTokens.isEmpty)
    }
}
