import Foundation

struct DayResult: Equatable {
    var streak: StreakState
    var plan: GoalPlan
    var newBadges: [BadgeID]
}

/// Folds completed days into the streak, freezes, goal plan and badges.
/// Runs at the app's daily rollover over every day since it last ran, so a
/// week without opening Clepsy still lands correctly.
enum DayProcessor {

    /// Completed days after `lastProcessed`, up to and including `yesterday`.
    /// With no history there's nothing to catch up on.
    static func daysToProcess(after lastProcessed: String?, through yesterday: String,
                              calendar: Calendar = .current) -> [String] {
        guard let lastProcessed,
              var day = DayKey.date(from: lastProcessed, calendar: calendar),
              let end = DayKey.date(from: yesterday, calendar: calendar) else { return [] }

        var keys: [String] = []
        while let next = calendar.date(byAdding: .day, value: 1, to: day), next <= end {
            keys.append(DayKey.string(for: next, calendar: calendar))
            day = next
        }
        return keys
    }

    static func process(days: [String], reached: Set<String>, streak: StreakState, plan: GoalPlan,
                        earned: Set<BadgeID>, calendar: Calendar = .current) -> DayResult {
        var streak = streak
        var plan = plan
        var earned = earned
        var newBadges: [BadgeID] = []

        func award(_ badge: BadgeID) {
            guard !earned.contains(badge) else { return }
            earned.insert(badge)
            newBadges.append(badge)
        }

        for day in days {
            if reached.contains(day) {
                if streak.lastResetDay == previousDay(of: day, calendar: calendar) {
                    award(.comeback)
                }
                streak.count += 1
                plan.consecutiveReached += 1

                if streak.count % StreakState.daysPerFreeze == 0 {
                    streak.freezes = min(StreakState.maxFreezes, streak.freezes + 1)
                    award(.firstFreeze)
                }
                award(.firstGoal)
                for (threshold, badge) in BadgeID.streakThresholds where streak.count >= threshold {
                    award(badge)
                }
                if plan.currentGoal >= BadgeID.intenseMinutes {
                    award(.intense)
                }
            } else {
                if streak.freezes > 0 {
                    streak.freezes -= 1
                    streak.frozenDays.append(day)
                } else {
                    streak.count = 0
                    streak.lastResetDay = day
                }
                plan.consecutiveReached = 0
            }
            streak.lastProcessedDay = day

            // An accepted raise starts the day after it was accepted
            if let pending = plan.pendingGoal {
                plan.currentGoal = pending
                plan.pendingGoal = nil
                if case .buildUp(let target) = plan.mode, pending >= target {
                    plan.mode = .fixed
                    award(.builtUp)
                }
            }
        }

        return DayResult(streak: streak, plan: plan, newBadges: newBadges)
    }

    private static func previousDay(of key: String, calendar: Calendar) -> String? {
        guard let date = DayKey.date(from: key, calendar: calendar),
              let previous = calendar.date(byAdding: .day, value: -1, to: date) else { return nil }
        return DayKey.string(for: previous, calendar: calendar)
    }
}
