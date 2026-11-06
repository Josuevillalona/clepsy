import Foundation
import FamilyControls

class PersistenceService: ObservableObject {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let userSettings = "userSettings"
        static let viceSelection = "viceSelection"
        static let productiveSelection = "productiveSelection"
        static let goalPlan = "goalPlan"
        static let streak = "streakState"
        static let badges = "badges"
        static let unseenBadges = "unseenBadges"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    convenience init?(suiteName: String) {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return nil
        }
        self.init(userDefaults: userDefaults)
    }

    // MARK: - User Settings

    func saveUserSettings(_ settings: UserSettings) {
        do {
            let encoded = try JSONEncoder().encode(settings)
            userDefaults.set(encoded, forKey: Keys.userSettings)
            // Mirror to App Group so the monitor extension can honor the toggle
            SharedStorageService().saveNotificationsEnabled(settings.notificationsEnabled)
        } catch {
            print("❌ Error encoding UserSettings: \(error)")
        }
    }

    func loadUserSettings() -> UserSettings {
        guard let data = userDefaults.data(forKey: Keys.userSettings),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return UserSettings()
        }
        return settings
    }

    // MARK: - Goal Plan, Streak, Badges

    func saveGoalPlan(_ plan: GoalPlan) { save(plan, key: Keys.goalPlan) }

    func loadGoalPlan() -> GoalPlan? { load(GoalPlan.self, key: Keys.goalPlan) }

    func saveStreak(_ streak: StreakState) { save(streak, key: Keys.streak) }

    func loadStreak() -> StreakState { load(StreakState.self, key: Keys.streak) ?? StreakState() }

    func saveBadges(_ badges: [BadgeID: Date]) { save(badges, key: Keys.badges) }

    func loadBadges() -> [BadgeID: Date] { load([BadgeID: Date].self, key: Keys.badges) ?? [:] }

    /// Earned at rollover but not yet shown on a claim screen
    func saveUnseenBadges(_ badges: [BadgeID]) { save(badges, key: Keys.unseenBadges) }

    func loadUnseenBadges() -> [BadgeID] { load([BadgeID].self, key: Keys.unseenBadges) ?? [] }

    private func save<T: Encodable>(_ value: T, key: String) {
        do {
            userDefaults.set(try JSONEncoder().encode(value), forKey: key)
        } catch {
            print("❌ Error encoding \(key): \(error)")
        }
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        userDefaults.data(forKey: key).flatMap { try? JSONDecoder().decode(type, from: $0) }
    }

    // MARK: - FamilyActivitySelection

    func saveFamilyActivitySelection(_ selection: FamilyActivitySelection, key: String) {
        do {
            // FamilyActivitySelection is a Codable struct — NSKeyedArchiver crashes on it at runtime
            let data = try JSONEncoder().encode(selection)
            userDefaults.set(data, forKey: key)
        } catch {
            print("❌ Error encoding FamilyActivitySelection: \(error)")
        }
    }

    func loadFamilyActivitySelection(key: String) -> FamilyActivitySelection? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    func saveViceSelection(_ selection: FamilyActivitySelection) {
        saveFamilyActivitySelection(selection, key: Keys.viceSelection)
        // Mirror to App Group so the DeviceActivityMonitor extension can read it
        SharedStorageService().saveViceSelection(selection)
    }

    func loadViceSelection() -> FamilyActivitySelection {
        loadFamilyActivitySelection(key: Keys.viceSelection) ?? FamilyActivitySelection()
    }

    func saveProductiveSelection(_ selection: FamilyActivitySelection) {
        saveFamilyActivitySelection(selection, key: Keys.productiveSelection)
    }

    func loadProductiveSelection() -> FamilyActivitySelection {
        loadFamilyActivitySelection(key: Keys.productiveSelection) ?? FamilyActivitySelection()
    }

    // MARK: - Testing Helper

    func clearAll() {
        userDefaults.removeObject(forKey: Keys.userSettings)
        userDefaults.removeObject(forKey: Keys.viceSelection)
        userDefaults.removeObject(forKey: Keys.productiveSelection)
        userDefaults.removeObject(forKey: Keys.goalPlan)
        userDefaults.removeObject(forKey: Keys.streak)
        userDefaults.removeObject(forKey: Keys.badges)
        userDefaults.removeObject(forKey: Keys.unseenBadges)
    }
}
