import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentBalance: TimeBalance
    @Published var todayEarned: Int = 0
    @Published var todaySpent: Int = 0
    @Published var dailyGoalSeconds: Int = 1800 // default 30 min

    private let persistenceService: PersistenceService

    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
        self.currentBalance = persistenceService.loadTimeBalance()
        let settings = persistenceService.loadUserSettings()
        self.dailyGoalSeconds = settings.dailyGoalMinutes * 60
    }

    func addTime(seconds: Int) {
        currentBalance.add(seconds: seconds)
        todayEarned += seconds
        persistenceService.saveTimeBalance(currentBalance)
    }

    func subtractTime(seconds: Int) {
        let actualSubtracted = min(seconds, currentBalance.currentSeconds)
        currentBalance.subtract(seconds: seconds)
        todaySpent += actualSubtracted
        persistenceService.saveTimeBalance(currentBalance)
    }

    var formattedBalance: String {
        currentBalance.formattedTime
    }

    var balancePercentage: Double {
        guard dailyGoalSeconds > 0 else { return 0 }
        return Double(currentBalance.currentSeconds) / Double(dailyGoalSeconds)
    }

    func refreshGoal() {
        let settings = persistenceService.loadUserSettings()
        dailyGoalSeconds = settings.dailyGoalMinutes * 60
    }

    func checkAndPerformDailyReset() {
        let calendar = Calendar.current
        let now = Date()

        if let lastReset = persistenceService.loadLastResetDate() {
            if !calendar.isDate(lastReset, inSameDayAs: now) {
                performReset()
            }
        } else {
            // First launch, set initial date
            persistenceService.performDailyReset()
        }
    }

    private func performReset() {
        persistenceService.performDailyReset()
        currentBalance = TimeBalance()
        todayEarned = 0
        todaySpent = 0
    }
}
