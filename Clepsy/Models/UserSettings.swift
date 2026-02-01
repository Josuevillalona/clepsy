import Foundation

struct UserSettings: Codable {
    var hasCompletedOnboarding: Bool
    var notificationsEnabled: Bool
    var exchangeRate: Double
    var viceApps: [TrackedApp]
    var productiveApps: [TrackedApp]

    init(
        hasCompletedOnboarding: Bool = false,
        notificationsEnabled: Bool = true,
        exchangeRate: Double = 1.0,
        viceApps: [TrackedApp] = [],
        productiveApps: [TrackedApp] = []
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.notificationsEnabled = notificationsEnabled
        self.exchangeRate = exchangeRate
        self.viceApps = viceApps
        self.productiveApps = productiveApps
    }
}
