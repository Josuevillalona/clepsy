import XCTest
import FamilyControls
import ManagedSettings
@testable import Clepsy

final class AppBlockingServiceTests: XCTestCase {
    var sut: AppBlockingService!
    var persistenceService: PersistenceService!

    override func setUp() {
        super.setUp()
        persistenceService = PersistenceService()
        sut = AppBlockingService(persistenceService: persistenceService)
    }

    func testHasViceSelectionFalseWhenEmpty() {
        persistenceService.saveViceSelection(FamilyActivitySelection())
        XCTAssertFalse(sut.hasViceSelection)
    }

    func testApplyViceAppBlocksDoesNotCrashWithEmptySelection() {
        // Shields can't actually be applied in the test environment, but the
        // call should be safe with nothing selected
        persistenceService.saveViceSelection(FamilyActivitySelection())
        sut.applyViceAppBlocks()
    }

    func testRemoveAllBlocksDoesNotCrash() {
        sut.removeAllBlocks()
    }
}
