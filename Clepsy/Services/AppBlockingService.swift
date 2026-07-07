import Foundation
import FamilyControls
import ManagedSettings

class AppBlockingService {
    private let store = ManagedSettingsStore()
    private let persistenceService: PersistenceService

    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
    }

    // MARK: - Block / Unblock

    func applyViceAppBlocks() {
        let selection = persistenceService.loadViceSelection()

        // Apps the user paid to unlock stay unshielded until their window ends
        var tokens = selection.applicationTokens
        for data in SharedStorageService().activeUnlockTokenDatas() {
            if let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                tokens.remove(token)
            }
        }
        store.shield.applications = tokens.isEmpty ? nil : tokens

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
    }

    func removeAllBlocks() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    // MARK: - State

    var hasViceSelection: Bool {
        let selection = persistenceService.loadViceSelection()
        return !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }
}
