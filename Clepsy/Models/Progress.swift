import Foundation

/// Consecutive days the daily goal was reached. A missed day spends a
/// freeze if one is banked; otherwise the streak resets.
struct StreakState: Codable, Equatable {
    var count: Int = 0
    var freezes: Int = 0
    /// The last completed day folded into this state
    var lastProcessedDay: String?
    var lastResetDay: String?
    /// Missed days a freeze covered, for showing them on a calendar later
    var frozenDays: [String] = []

    static let maxFreezes = 2
    static let daysPerFreeze = 7
}

enum BadgeID: String, Codable, CaseIterable, Identifiable {
    case firstGoal, streak3, streak7, streak14, streak30, streak100
    case builtUp, firstFreeze, intense, comeback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstGoal: return "First Goal"
        case .streak3: return "On a Roll"
        case .streak7: return "One Week"
        case .streak14: return "Two Weeks"
        case .streak30: return "A Whole Month"
        case .streak100: return "Unstoppable"
        case .builtUp: return "Built Up"
        case .firstFreeze: return "Ice Cold"
        case .intense: return "Intense"
        case .comeback: return "Comeback"
        }
    }

    /// How to earn it, shown on unearned badges
    var rule: String {
        switch self {
        case .firstGoal: return "Hit your daily goal for the first time"
        case .streak3: return "Reach a 3-day streak"
        case .streak7: return "Reach a 7-day streak"
        case .streak14: return "Reach a 14-day streak"
        case .streak30: return "Reach a 30-day streak"
        case .streak100: return "Reach a 100-day streak"
        case .builtUp: return "Build up all the way to your target"
        case .firstFreeze: return "Earn your first streak freeze"
        case .intense: return "Hit a goal of 80 minutes or more"
        case .comeback: return "Hit your goal the day after a streak ends"
        }
    }

    /// Placeholder art until the badges are designed
    var symbol: String {
        switch self {
        case .firstGoal: return "flag.checkered"
        case .streak3: return "flame"
        case .streak7: return "flame.fill"
        case .streak14: return "bolt.fill"
        case .streak30: return "star.fill"
        case .streak100: return "crown.fill"
        case .builtUp: return "chart.line.uptrend.xyaxis"
        case .firstFreeze: return "snowflake"
        case .intense: return "mountain.2.fill"
        case .comeback: return "arrow.uturn.up"
        }
    }

    static let streakThresholds: [(Int, BadgeID)] = [
        (3, .streak3), (7, .streak7), (14, .streak14), (30, .streak30), (100, .streak100)
    ]

    static let intenseMinutes = 80
}
