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

        // Safety net: the monitor extension hard-blocks momentarily to kick
        // the user out at time's-up; if it died mid-swap, apps would stay
        // hidden from the home screen until this clears it
        store.application.blockedApplications = nil

        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
    }

    func removeAllBlocks() {
        store.application.blockedApplications = nil
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    // MARK: - State

    var hasViceSelection: Bool {
        let selection = persistenceService.loadViceSelection()
        return !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }
}
