import Foundation
import SwiftUI
import FamilyControls

@MainActor
class SettingsViewModel: ObservableObject {

    @Published var dailyGoalMinutes: Int = 30 {
        didSet { saveSettings() }
    }

    @Published var notificationsEnabled: Bool = true {
        didSet { saveSettings() }
    }

    @Published var milestoneInterval: Int = 15 {
        didSet { saveSettings() }
    }

    @Published var viceSelection = FamilyActivitySelection() {
        didSet {
            guard !isLoading else { return }
            // Apps-only rule: category selections can't be unlocked per-app,
            // so don't persist them — warn and let the user re-pick
            guard viceSelection.categoryTokens.isEmpty else {
                showCategoryWarning = true
                return
            }
            persistenceService.saveViceSelection(viceSelection)
        }
    }

    @Published var productiveSelection = FamilyActivitySelection() {
        didSet {
            guard !isLoading else { return }
            guard productiveSelection.categoryTokens.isEmpty else {
                showCategoryWarning = true
                return
            }
            persistenceService.saveProductiveSelection(productiveSelection)
            // Rebuild the earning schedule with the new app tokens
            usageTrackingService.startDailyMonitoring(productiveSelection: productiveSelection, force: true)
        }
    }

    private var isLoading = false

    // MARK: - UI State

    @Published var showGoalPicker = false
    @Published var showIntervalPicker = false
    @Published var showResetConfirmation = false
    @Published var showCategoryWarning = false

    // MARK: - Services

    private let persistenceService: PersistenceService
    private let usageTrackingService = UsageTrackingService()

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

    var viceAppCount: Int {
        viceSelection.applicationTokens.count + viceSelection.categoryTokens.count
    }

    var productiveAppCount: Int {
        productiveSelection.applicationTokens.count + productiveSelection.categoryTokens.count
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
        isLoading = true
        defer { isLoading = false }
        let settings = persistenceService.loadUserSettings()
        dailyGoalMinutes = settings.dailyGoalMinutes
        notificationsEnabled = settings.notificationsEnabled
        viceSelection = persistenceService.loadViceSelection()
        productiveSelection = persistenceService.loadProductiveSelection()
    }

    private func saveSettings() {
        var settings = persistenceService.loadUserSettings()
        settings.dailyGoalMinutes = dailyGoalMinutes
        settings.notificationsEnabled = notificationsEnabled
        persistenceService.saveUserSettings(settings)
    }

    func resetAllData() {
        persistenceService.clearAll()
        dailyGoalMinutes = 30
        notificationsEnabled = true
        milestoneInterval = 15
        viceSelection = FamilyActivitySelection()
        productiveSelection = FamilyActivitySelection()
    }
}
