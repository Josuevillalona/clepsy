import Foundation
import FamilyControls
import ManagedSettings

class AppBlockingService {
    private let store = ManagedSettingsStore()

    func blockApps(_ apps: [TrackedApp]) throws {
        // Note: In production, we need ApplicationTokens from FamilyActivityPicker
        // For MVP/Simulator testing, this prepares the shield configuration
        // Actual blocking happens with real tokens on device

        // Clear existing blocks first
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    func unblockApps(_ apps: [TrackedApp]) throws {
        // Remove shields for specific apps
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    func blockAllViceApps() throws {
        let viceApps = AppCategory.defaultViceApps
        try blockApps(viceApps)
    }

    func unblockAllViceApps() throws {
        let viceApps = AppCategory.defaultViceApps
        try unblockApps(viceApps)
    }
}
