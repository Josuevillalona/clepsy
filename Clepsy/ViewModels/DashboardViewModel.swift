import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentBalance: TimeBalance
    @Published var todayEarned: Int = 0
    @Published var todaySpent: Int = 0
    @Published var dailyGoalSeconds: Int = 1800
    @Published var viceApps: [TrackedApp] = []
    @Published var productiveApps: [TrackedApp] = []
    @Published var currentStreak: Int = 0
    @Published var showStreakBanner: Bool = false

    private let persistenceService: PersistenceService

    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
        self.currentBalance = persistenceService.loadTimeBalance()
        let settings = persistenceService.loadUserSettings()
        self.dailyGoalSeconds = settings.dailyGoalMinutes * 60
        self.viceApps = settings.viceApps.isEmpty ? AppCategory.defaultViceApps : settings.viceApps
        self.productiveApps = settings.productiveApps.isEmpty ? AppCategory.defaultProductiveApps : settings.productiveApps
        loadStreak()
    }

    func addTime(seconds: Int) {
        currentBalance.add(seconds: seconds)
        todayEarned += seconds
        persistenceService.saveTimeBalance(currentBalance)

        // Check if goal was just met
        if goalProgressPercentage >= 1.0 {
            incrementStreak()
        }
    }

    func subtractTime(seconds: Int) {
        guard currentBalance.currentSeconds > 0 else { return }
        let actualSubtracted = min(seconds, currentBalance.currentSeconds)
        currentBalance.subtract(seconds: actualSubtracted)
        todaySpent += actualSubtracted
        persistenceService.saveTimeBalance(currentBalance)
    }

    var canSpend: Bool {
        currentBalance.currentSeconds > 0
    }

    // Full balance display: "47 minutes" or "1h 23m"
    var formattedBalance: String {
        let totalMinutes = currentBalance.currentSeconds / 60
        if totalMinutes == 0 {
            return "0 minutes"
        } else if totalMinutes == 1 {
            return "1 minute"
        } else if totalMinutes < 60 {
            return "\(totalMinutes) minutes"
        } else {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours) hour\(hours > 1 ? "s" : "")"
        }
    }

    // Short format for inline stats
    var formattedEarned: String {
        "\(todayEarned / 60) min"
    }

    var formattedSpent: String {
        "\(todaySpent / 60) min"
    }

    var balancePercentage: Double {
        guard dailyGoalSeconds > 0 else { return 0 }
        return Double(currentBalance.currentSeconds) / Double(dailyGoalSeconds)
    }

    var goalProgressPercentage: Double {
        guard dailyGoalSeconds > 0 else { return 0 }
        return min(Double(todayEarned) / Double(dailyGoalSeconds), 1.0)
    }

    var dailyGoalMinutes: Int {
        dailyGoalSeconds / 60
    }

    var todayEarnedMinutes: Int {
        todayEarned / 60
    }

    var streakMessage: String {
        switch currentStreak {
        case 1...6: return "Keep it going!"
        case 7...13: return "You're building a real habit here"
        case 14...29: return "Two weeks strong!"
        case 30...59: return "A whole month! Incredible"
        case 60...: return "You're unstoppable!"
        default: return "Start your streak today"
        }
    }

    func refreshGoal() {
        let settings = persistenceService.loadUserSettings()
        dailyGoalSeconds = settings.dailyGoalMinutes * 60
        viceApps = settings.viceApps.isEmpty ? AppCategory.defaultViceApps : settings.viceApps
        productiveApps = settings.productiveApps.isEmpty ? AppCategory.defaultProductiveApps : settings.productiveApps
    }

    func dismissStreak() {
        showStreakBanner = false
    }

    func checkAndPerformDailyReset() {
        let calendar = Calendar.current
        let now = Date()

        if let lastReset = persistenceService.loadLastResetDate() {
            if !calendar.isDate(lastReset, inSameDayAs: now) {
                performReset()
            }
        } else {
            persistenceService.performDailyReset()
        }
    }

    // MARK: - Streak

    private static let streakKey = "clepsy_streak_count"
    private static let streakDateKey = "clepsy_streak_last_date"
    private static let streakGoalMetKey = "clepsy_streak_goal_met_today"

    private func loadStreak() {
        let defaults = UserDefaults.standard
        currentStreak = defaults.integer(forKey: Self.streakKey)
        showStreakBanner = currentStreak > 0
    }

    private func incrementStreak() {
        let defaults = UserDefaults.standard
        let alreadyMetToday = defaults.bool(forKey: Self.streakGoalMetKey)
        guard !alreadyMetToday else { return }

        defaults.set(true, forKey: Self.streakGoalMetKey)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = defaults.object(forKey: Self.streakDateKey) as? Date {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysBetween == 1 {
                currentStreak += 1
            } else if daysBetween > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        defaults.set(currentStreak, forKey: Self.streakKey)
        defaults.set(today, forKey: Self.streakDateKey)
        showStreakBanner = true
    }

    private func performReset() {
        persistenceService.performDailyReset()
        currentBalance = TimeBalance()
        todayEarned = 0
        todaySpent = 0
        UserDefaults.standard.set(false, forKey: Self.streakGoalMetKey)
    }
}
