import Foundation

struct UserSettings: Codable {
    var hasCompletedOnboarding: Bool
    var notificationsEnabled: Bool
    var exchangeRate: Double
    var dailyGoalMinutes: Int
    var viceApps: [TrackedApp]
    var productiveApps: [TrackedApp]

    init(
        hasCompletedOnboarding: Bool = false,
        notificationsEnabled: Bool = true,
        exchangeRate: Double = 1.0,
        dailyGoalMinutes: Int = 30,
        viceApps: [TrackedApp] = [],
        productiveApps: [TrackedApp] = []
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.notificationsEnabled = notificationsEnabled
        self.exchangeRate = exchangeRate
        self.dailyGoalMinutes = dailyGoalMinutes
        self.viceApps = viceApps
        self.productiveApps = productiveApps
    }
}
