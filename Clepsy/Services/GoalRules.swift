import Foundation

// The daily-goal model's decisions, kept free of Screen Time frameworks so
// unit tests can exercise them directly. Compiled into the app and the
// monitor, shield configuration and shield action extensions.

// MARK: - Day Keys

/// "yyyy-MM-dd" in the user's calendar. Every per-day record (earned
/// minutes, reached days, unlocks) is keyed by this, so the app and the
/// extensions agree on what "today" is.
enum DayKey {
    static func string(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func date(from key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}

// MARK: - Goals

enum GoalDifficulty: String, CaseIterable {
    case easy, medium, hard, intense

    static func forMinutes(_ minutes: Int) -> GoalDifficulty {
        switch minutes {
        case ...20: return .easy
        case ...45: return .medium
        case ...75: return .hard
        default: return .intense
        }
    }

    var title: String { rawValue.capitalized }
}

enum GoalMode: Codable, Equatable {
    case fixed
    /// Start low; Clepsy offers +5 min steps until the target
    case buildUp(target: Int)
}

struct GoalPlan: Codable, Equatable {
    var mode: GoalMode
    var currentGoal: Int
    /// Days in a row the current goal was reached, toward the next offer
    var consecutiveReached: Int
    /// An accepted raise; becomes `currentGoal` at the next day's start
    var pendingGoal: Int?

    static let `default` = GoalPlan(mode: .fixed, currentGoal: 30, consecutiveReached: 0, pendingGoal: nil)
}

enum GoalRules {
    static let minutesRange = 5...120
    static let step = 5
    static let offerAfterDays = 3
    /// Used only for the "About N days" estimate in build-up setup
    static let daysPerStep = 3

    static func startRange() -> ClosedRange<Int> {
        minutesRange.lowerBound...(minutesRange.upperBound - step)
    }

    static func targetRange(start: Int) -> ClosedRange<Int> {
        min(start + step, minutesRange.upperBound)...minutesRange.upperBound
    }

    static func estimatedDays(start: Int, target: Int) -> Int {
        max(0, (target - start) / step) * daysPerStep
    }

    /// Snaps any stored or migrated value onto the 5-min grid within range
    static func clamped(_ minutes: Int) -> Int {
        let rounded = Int((Double(minutes) / Double(step)).rounded(.down)) * step
        return min(max(rounded, minutesRange.lowerBound), minutesRange.upperBound)
    }

    static func nextOfferGoal(_ plan: GoalPlan) -> Int? {
        guard case .buildUp(let target) = plan.mode, plan.currentGoal < target else { return nil }
        return min(plan.currentGoal + step, target)
    }

    static func isOfferDue(_ plan: GoalPlan) -> Bool {
        plan.pendingGoal == nil
            && nextOfferGoal(plan) != nil
            && plan.consecutiveReached >= offerAfterDays
    }

    /// The raise applies from tomorrow, so today's unlock is never moved
    static func accept(_ plan: GoalPlan) -> GoalPlan {
        var plan = plan
        plan.pendingGoal = nextOfferGoal(plan)
        plan.consecutiveReached = 0
        return plan
    }

    /// Asks again after another `offerAfterDays` reached days
    static func decline(_ plan: GoalPlan) -> GoalPlan {
        var plan = plan
        plan.consecutiveReached = 0
        return plan
    }
}

// MARK: - Earning

struct EarnState: Equatable {
    var day: String
    var minutes: Int
    var reached: Bool
}

enum EarnRules {
    static let eventPrefix = "earn_"

    /// "earn_12" → 12. Earn events are cumulative minutes since midnight.
    static func minute(fromEventName name: String) -> Int? {
        guard name.hasPrefix(eventPrefix) else { return nil }
        return Int(name.dropFirst(eventPrefix.count))
    }

    /// Thresholds can be redelivered or arrive out of order (and a monitoring
    /// restart re-sends every minute already used today), so the count only
    /// ever moves up and the goal is reported reached exactly once.
    /// `baseline` is how many of today's minutes a reset set aside: iOS keeps
    /// counting from midnight, so they're subtracted from every later event.
    static func apply(eventMinute: Int, today: String, stored: EarnState?, goal: Int, baseline: Int = 0)
        -> (state: EarnState, justReached: Bool) {
        var state = (stored?.day == today ? stored : nil)
            ?? EarnState(day: today, minutes: 0, reached: false)
        state.minutes = max(state.minutes, eventMinute - baseline)

        let justReached = !state.reached && state.minutes >= goal
        if justReached { state.reached = true }
        return (state, justReached)
    }
}

// MARK: - Monitoring

enum MonitoringRules {
    /// Seen on device: iOS can stop delivering a schedule's thresholds while
    /// still reporting it as registered. Restarting makes iOS re-send the
    /// minutes already used today (EarnRules dedupes them), so opening Clepsy
    /// restarts it, at most this often.
    static let restartInterval: TimeInterval = 5 * 60

    static func shouldRestart(isActive: Bool, lastStartedAt: Date?, now: Date) -> Bool {
        guard isActive, let lastStartedAt else { return true }
        return now.timeIntervalSince(lastStartedAt) > restartInterval
    }
}
