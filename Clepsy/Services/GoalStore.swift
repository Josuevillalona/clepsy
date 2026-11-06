import Foundation

/// Owns the daily-goal state on the app side: the plan, streak and badges,
/// today's status, and the claim. Mirrors what the extensions need (today's
/// goal, the unlock) into the App Group; reads what they write (earned
/// minutes, reached days).
@MainActor
final class GoalStore: ObservableObject {

    enum TodayStatus: Equatable {
        case locked(minutesToGo: Int)
        /// Within a minute of the goal by Clepsy's count. True either way:
        /// you're in your last minute, or iOS's report is about to land.
        case almostThere
        case readyToClaim
        case unlocked
    }

    struct Celebration: Equatable, Identifiable {
        /// The day being celebrated
        let id: String
        let goal: Int
        let streakBefore: Int
        let streakAfter: Int
        let newBadges: [BadgeID]
        /// The next build-up step to offer after unlocking, if one is due
        let offerGoal: Int?
    }

    @Published private(set) var plan: GoalPlan
    @Published private(set) var streak: StreakState
    @Published private(set) var badges: [BadgeID: Date]
    @Published private(set) var todayGoal: Int
    @Published private(set) var earnedMinutes = 0
    @Published private(set) var status: TodayStatus = .locked(minutesToGo: 0)
    @Published var pendingCelebration: Celebration?

    private let persistence: PersistenceService
    private let shared: SharedStorageService
    private let now: () -> Date
    private let calendar: Calendar
    private let unlockApps: () -> Void
    /// Set when the claim screen is closed with "Not now", so the dashboard's
    /// periodic refresh doesn't bring it straight back
    private var dismissedCelebrationDay: String?

    init(persistence: PersistenceService = PersistenceService(),
         shared: SharedStorageService = SharedStorageService(),
         now: @escaping () -> Date = Date.init,
         calendar: Calendar = .current,
         unlockApps: @escaping () -> Void = { AppBlockingService().removeAllBlocks() }) {
        self.persistence = persistence
        self.shared = shared
        self.now = now
        self.calendar = calendar
        self.unlockApps = unlockApps

        let plan = persistence.loadGoalPlan() ?? GoalPlan(
            mode: .fixed,
            currentGoal: GoalRules.clamped(persistence.loadUserSettings().dailyGoalMinutes),
            consecutiveReached: 0,
            pendingGoal: nil
        )
        self.plan = plan
        self.todayGoal = plan.currentGoal
        self.streak = persistence.loadStreak()
        self.badges = persistence.loadBadges()
    }

    private var today: String { DayKey.string(for: now(), calendar: calendar) }

    private var yesterday: String {
        let date = calendar.date(byAdding: .day, value: -1, to: now()) ?? now()
        return DayKey.string(for: date, calendar: calendar)
    }

    var reachedToday: Bool {
        status == .readyToClaim || status == .unlocked
    }

    /// The streak including today once today's goal is reached
    var displayStreak: Int {
        streak.count + (reachedToday ? 1 : 0)
    }

    // MARK: - Refresh

    func refresh() {
        rollOver()

        todayGoal = plan.currentGoal
        shared.saveGoalToday(minutes: todayGoal, day: today)
        shared.saveGoalBase(plan.pendingGoal ?? plan.currentGoal)

        var earn = shared.earnState.flatMap { $0.day == today ? $0 : nil }
            ?? EarnState(day: today, minutes: 0, reached: false)
        // The monitor only flags "reached" when an earn event fires, so a goal
        // lowered below today's minutes has to be caught here
        if !earn.reached && earn.minutes >= todayGoal {
            earn.reached = true
            shared.saveEarnState(earn)
            shared.addReachedDay(today)
        }
        earnedMinutes = earn.minutes

        if shared.unlockedDay == today {
            status = .unlocked
        } else if earn.reached {
            status = .readyToClaim
        } else if todayGoal - earn.minutes <= 1 {
            status = .almostThere
        } else {
            status = .locked(minutesToGo: todayGoal - earn.minutes)
        }

        if status == .readyToClaim, pendingCelebration?.id != today, dismissedCelebrationDay != today {
            pendingCelebration = makeCelebration()
        } else if status != .readyToClaim && status != .unlocked {
            pendingCelebration = nil
        }
    }

    /// Folds every completed day since the last run into streak, plan, badges
    private func rollOver() {
        guard let lastProcessed = streak.lastProcessedDay else {
            // First run: history starts now, nothing to catch up on
            streak.lastProcessedDay = yesterday
            persistence.saveStreak(streak)
            return
        }

        let days = DayProcessor.daysToProcess(after: lastProcessed, through: yesterday, calendar: calendar)
        guard !days.isEmpty else { return }

        let result = DayProcessor.process(days: days, reached: shared.reachedDays, streak: streak,
                                          plan: plan, earned: Set(badges.keys), calendar: calendar)
        streak = result.streak
        plan = result.plan
        for badge in result.newBadges { badges[badge] = now() }

        persistence.saveStreak(streak)
        persistence.saveGoalPlan(plan)
        persistence.saveBadges(badges)
        persistence.saveUnseenBadges(persistence.loadUnseenBadges() + result.newBadges)
    }

    // MARK: - Claim

    private func makeCelebration() -> Celebration {
        let streakAfter = streak.count + 1
        // Badges today's claim will earn, shown on the claim screen
        var preview: [BadgeID] = []
        func add(_ badge: BadgeID) {
            if badges[badge] == nil && !preview.contains(badge) { preview.append(badge) }
        }
        add(.firstGoal)
        for (threshold, badge) in BadgeID.streakThresholds where streakAfter >= threshold {
            add(badge)
        }
        if todayGoal >= BadgeID.intenseMinutes { add(.intense) }

        return Celebration(
            id: today,
            goal: todayGoal,
            streakBefore: streak.count,
            streakAfter: streakAfter,
            newBadges: persistence.loadUnseenBadges() + preview,
            offerGoal: GoalRules.isOfferDue(planCountingToday) ? GoalRules.nextOfferGoal(plan) : nil
        )
    }

    /// Today's reached day is only folded in at tomorrow's rollover, so
    /// offers and their answers count it explicitly
    private var planCountingToday: GoalPlan {
        var plan = plan
        plan.consecutiveReached += 1
        return plan
    }

    func claim() {
        guard status == .readyToClaim else { return }
        shared.saveUnlockedDay(today)
        unlockApps()

        for badge in pendingCelebration?.newBadges ?? [] where badges[badge] == nil {
            badges[badge] = now()
        }
        persistence.saveBadges(badges)
        persistence.saveUnseenBadges([])
        status = .unlocked
    }

    func finishCelebration() {
        pendingCelebration = nil
    }

    /// "Not now": close the claim screen without unlocking
    func dismissCelebration() {
        dismissedCelebrationDay = today
        pendingCelebration = nil
    }

    /// Bring the claim screen back, from the dashboard's claim button
    func presentCelebration() {
        dismissedCelebrationDay = nil
        refresh()
    }

    // MARK: - Reset

    /// Testing aid and part of "Reset all data": today's goal starts over
    /// from 0 and apps lock again. The streak and badges are left alone.
    func resetToday(clearHistory: Bool = false) {
        shared.resetProgress(today: today, clearHistory: clearHistory)
        dismissedCelebrationDay = nil
        pendingCelebration = nil
        refresh()
    }

    /// "Reset all data": also forgets the plan, streak and badges
    func resetAll() {
        plan = .default
        streak = StreakState()
        badges = [:]
        persistence.saveGoalPlan(plan)
        persistence.saveStreak(streak)
        persistence.saveBadges(badges)
        persistence.saveUnseenBadges([])
        resetToday(clearHistory: true)
    }

    // MARK: - Build-up Offers

    func acceptOffer() {
        answerOffer(GoalRules.accept)
    }

    func declineOffer() {
        answerOffer(GoalRules.decline)
    }

    /// Answers count today, then step back one: tomorrow's rollover adds
    /// today's reached day again, landing the count at 0
    private func answerOffer(_ answer: (GoalPlan) -> GoalPlan) {
        var answered = answer(planCountingToday)
        answered.consecutiveReached -= 1
        plan = answered
        persistence.saveGoalPlan(plan)
        shared.saveGoalBase(plan.pendingGoal ?? plan.currentGoal)
    }

    // MARK: - Changing the Plan

    /// Applies now, unless today's goal is already reached; then it starts
    /// tomorrow, so a claimed (or claimable) day is never moved
    func setPlan(mode: GoalMode, goal: Int) {
        let goal = GoalRules.clamped(goal)
        let changed = mode != plan.mode || goal != (plan.pendingGoal ?? plan.currentGoal)
        plan.mode = mode
        if reachedToday {
            plan.pendingGoal = goal == plan.currentGoal ? nil : goal
        } else {
            plan.currentGoal = goal
            plan.pendingGoal = nil
            // Re-saving the same plan keeps progress toward the next offer
            if changed { plan.consecutiveReached = 0 }
        }
        persistence.saveGoalPlan(plan)
        refresh()
    }
}
