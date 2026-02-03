import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentBalance: TimeBalance
    @Published var todayEarned: Int = 0
    @Published var todaySpent: Int = 0

    private let persistenceService: PersistenceService
    private let maxDisplaySeconds = 3600 // 1 hour for percentage calculation

    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
        self.currentBalance = persistenceService.loadTimeBalance()
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
        return Double(currentBalance.currentSeconds) / Double(maxDisplaySeconds)
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
