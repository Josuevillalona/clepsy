import Foundation
import FamilyControls

/// The dashboard's app lists. Goal progress, streak and the claim live in
/// `GoalStore`.
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var viceSelection = FamilyActivitySelection()
    @Published var productiveSelection = FamilyActivitySelection()

    private let persistenceService: PersistenceService

    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
        refreshSelections()
    }

    /// Settings can change either list, so this runs on every appear
    func refreshSelections() {
        viceSelection = persistenceService.loadViceSelection()
        productiveSelection = persistenceService.loadProductiveSelection()
    }
}
