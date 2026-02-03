import Foundation

class PersistenceService {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let timeBalance = "timeBalance"
        static let userSettings = "userSettings"
        static let lastResetDate = "lastResetDate"
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

    // MARK: - Testing Helper

    func clearAll() {
        userDefaults.removeObject(forKey: Keys.timeBalance)
        userDefaults.removeObject(forKey: Keys.userSettings)
        userDefaults.removeObject(forKey: Keys.lastResetDate)
    }
}
