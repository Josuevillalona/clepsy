import Foundation
import FamilyControls
import ManagedSettings

class AppBlockingService {
    private let persistenceService: PersistenceService

    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
    }

    // MARK: - Block / Unblock

    /// Shields vice apps unless today's unlock has been claimed
    func applyViceAppBlocks() {
        let today = DayKey.string(for: Date())
        guard ViceShieldPolicy.shouldShield(today: today, unlockedDay: SharedStorageService().unlockedDay) else { return }
        ViceShield.apply(persistenceService.loadViceSelection(), closingForegroundApp: false)
    }

    func removeAllBlocks() {
        ViceShield.remove()
    }

    // MARK: - State

    var hasViceSelection: Bool {
        let selection = persistenceService.loadViceSelection()
        return !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }
}
