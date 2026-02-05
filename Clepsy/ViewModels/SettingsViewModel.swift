import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var dailyGoalMinutes: Int = 30 {
        didSet { saveSettings() }
    }

    @Published var notificationsEnabled: Bool = true {
        didSet { saveSettings() }
    }

    @Published var milestoneInterval: Int = 15 {
        didSet { saveSettings() }
    }

    @Published var viceApps: [SelectableApp] = []
    @Published var productiveApps: [SelectableApp] = []

    // MARK: - UI State

    @Published var showGoalPicker = false
    @Published var showIntervalPicker = false
    @Published var showResetConfirmation = false

    // MARK: - Services

    private let persistenceService: PersistenceService

    // MARK: - Computed Properties

    var formattedDailyGoal: String {
        if dailyGoalMinutes < 60 {
            return "\(dailyGoalMinutes) min"
        } else if dailyGoalMinutes == 60 {
            return "1 hour"
        } else {
            return "\(dailyGoalMinutes / 60) hours"
        }
    }

    var formattedMilestoneInterval: String {
        switch milestoneInterval {
        case 0: return "Off"
        case 15: return "Every 15 min"
        case 30: return "Every 30 min"
        case 60: return "Every hour"
        default: return "\(milestoneInterval) min"
        }
    }

    var selectedViceAppsCount: Int {
        viceApps.filter { $0.isSelected }.count
    }

    var selectedProductiveAppsCount: Int {
        productiveApps.filter { $0.isSelected }.count
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (Build \(build))"
    }

    // MARK: - Initialization

    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
        loadSettings()
    }

    // MARK: - Settings Management

    private func loadSettings() {
        let settings = persistenceService.loadUserSettings()
        dailyGoalMinutes = settings.dailyGoalMinutes
        notificationsEnabled = settings.notificationsEnabled

        // Load default apps with selection state
        let savedViceIds = Set(settings.viceApps.map { $0.bundleIdentifier })
        let savedProductiveIds = Set(settings.productiveApps.map { $0.bundleIdentifier })

        viceApps = AppCategory.defaultViceApps.map { app in
            SelectableApp(
                trackedApp: app,
                isSelected: savedViceIds.isEmpty ? true : savedViceIds.contains(app.bundleIdentifier)
            )
        }

        productiveApps = AppCategory.defaultProductiveApps.map { app in
            SelectableApp(
                trackedApp: app,
                isSelected: savedProductiveIds.isEmpty ? true : savedProductiveIds.contains(app.bundleIdentifier)
            )
        }
    }

    private func saveSettings() {
        var settings = persistenceService.loadUserSettings()
        settings.dailyGoalMinutes = dailyGoalMinutes
        settings.notificationsEnabled = notificationsEnabled
        settings.viceApps = viceApps.filter { $0.isSelected }.map { $0.trackedApp }
        settings.productiveApps = productiveApps.filter { $0.isSelected }.map { $0.trackedApp }
        persistenceService.saveUserSettings(settings)
    }

    func resetAllData() {
        persistenceService.clearAll()
        loadSettings()

        // Reset to defaults
        dailyGoalMinutes = 30
        notificationsEnabled = true
        milestoneInterval = 15
    }
}

// MARK: - Selectable App Model

struct SelectableApp: Identifiable {
    let id: UUID
    let trackedApp: TrackedApp
    var isSelected: Bool

    init(trackedApp: TrackedApp, isSelected: Bool = false) {
        self.id = trackedApp.id
        self.trackedApp = trackedApp
        self.isSelected = isSelected
    }

    var name: String { trackedApp.name }
    var bundleIdentifier: String { trackedApp.bundleIdentifier }
}
