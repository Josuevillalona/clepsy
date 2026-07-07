import Foundation
import FamilyControls

class PersistenceService: ObservableObject {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let timeBalance = "timeBalance"
        static let userSettings = "userSettings"
        static let lastResetDate = "lastResetDate"
        static let viceSelection = "viceSelection"
        static let productiveSelection = "productiveSelection"
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

    // MARK: - Time Balance

    func saveTimeBalance(_ balance: TimeBalance) {
        do {
            let encoded = try JSONEncoder().encode(balance)
            userDefaults.set(encoded, forKey: Keys.timeBalance)
            // Mirror to App Group so shield extensions can show/spend the balance
            SharedStorageService().saveBalanceSeconds(balance.currentSeconds)
        } catch {
            print("❌ Error encoding TimeBalance: \(error)")
        }
    }

    func loadTimeBalance() -> TimeBalance {
        guard let data = userDefaults.data(forKey: Keys.timeBalance),
              let balance = try? JSONDecoder().decode(TimeBalance.self, from: data) else {
            return TimeBalance()
        }
        return balance
    }

    // MARK: - User Settings

    func saveUserSettings(_ settings: UserSettings) {
        do {
            let encoded = try JSONEncoder().encode(settings)
            userDefaults.set(encoded, forKey: Keys.userSettings)
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

    // MARK: - Last Reset Date

    func saveLastResetDate(_ date: Date) {
        userDefaults.set(date, forKey: Keys.lastResetDate)
    }

    func loadLastResetDate() -> Date? {
        return userDefaults.object(forKey: Keys.lastResetDate) as? Date
    }

    // MARK: - Daily Reset

    func performDailyReset() {
        let balance = TimeBalance(currentSeconds: 0)
        saveTimeBalance(balance)
        saveLastResetDate(Date())
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
        userDefaults.removeObject(forKey: Keys.timeBalance)
        userDefaults.removeObject(forKey: Keys.userSettings)
        userDefaults.removeObject(forKey: Keys.lastResetDate)
        userDefaults.removeObject(forKey: Keys.viceSelection)
        userDefaults.removeObject(forKey: Keys.productiveSelection)
    }
}
