import Foundation
import FamilyControls

class SharedStorageService {
    static let defaultAppGroup = "group.com.clepsy.shared"

    private let appGroup: String
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.clepsy.shared", qos: .userInitiated)

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    private lazy var containerURL: URL = {
        // Falls back to a per-group temp folder, so a test suite name that
        // isn't a real App Group gets its own isolated event file
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? fileManager.temporaryDirectory.appendingPathComponent(appGroup)
    }()

    private lazy var eventsFileURL: URL = {
        containerURL.appendingPathComponent("pendingTimeEvents.json")
    }()

    /// Pass a non-App-Group suite name in tests to keep them off real data
    init(appGroup: String = SharedStorageService.defaultAppGroup) {
        self.appGroup = appGroup
        // Ensure container directory exists
        try? fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
    }

    // MARK: - Thread-Safe Event Queue (FileCoordination)

    /// Append a time event (called from extension)
    /// Uses FileCoordination for atomic writes
    func appendEvent(_ event: TimeEvent) {
        queue.sync {
            let coordinator = NSFileCoordinator(filePresenter: nil)
            var error: NSError?

            coordinator.coordinate(
                writingItemAt: eventsFileURL,
                options: .forMerging,
                error: &error
            ) { url in
                do {
                    let data = try? Data(contentsOf: url)
                    var events = (try? JSONDecoder().decode([TimeEvent].self, from: data ?? Data())) ?? []
                    events.append(event)
                    let encoded = try JSONEncoder().encode(events)
                    try encoded.write(to: url, options: .atomic)
                    self.setPendingDelta(events: events)
                } catch {
                    print("Error appending event: \(error)")
                }
            }

            if let error = error {
                print("FileCoordination error: \(error)")
            }
        }
    }

    /// Get all pending events (called from main app)
    func getEvents() -> [TimeEvent] {
        return queue.sync {
            let coordinator = NSFileCoordinator(filePresenter: nil)
            var events = [TimeEvent]()
            var error: NSError?

            coordinator.coordinate(
                readingItemAt: eventsFileURL,
                options: [],
                error: &error
            ) { url in
                do {
                    let data = try Data(contentsOf: url)
                    events = try JSONDecoder().decode([TimeEvent].self, from: data)
                } catch {
                    // No events file yet or JSON error - return empty array
                }
            }

            return events
        }
    }

    /// Clear all events after processing (called from main app)
    func clearEvents() {
        queue.sync {
            let coordinator = NSFileCoordinator(filePresenter: nil)
            var error: NSError?

            coordinator.coordinate(
                writingItemAt: eventsFileURL,
                options: .forDeleting,
                error: &error
            ) { url in
                do {
                    let emptyArray = try JSONEncoder().encode([TimeEvent]())
                    try emptyArray.write(to: url, options: .atomic)
                    self.setPendingDelta(events: [])
                } catch {
                    print("Error clearing events: \(error)")
                }
            }
        }
    }

    /// Remove specific events by their IDs
    func removeEvents(withIds ids: Set<UUID>) {
        queue.sync {
            let coordinator = NSFileCoordinator(filePresenter: nil)
            var error: NSError?

            coordinator.coordinate(
                writingItemAt: eventsFileURL,
                options: .forMerging,
                error: &error
            ) { url in
                do {
                    let data = try? Data(contentsOf: url)
                    var events = (try? JSONDecoder().decode([TimeEvent].self, from: data ?? Data())) ?? []
                    events.removeAll { ids.contains($0.id) }
                    let encoded = try JSONEncoder().encode(events)
                    try encoded.write(to: url, options: .atomic)
                    self.setPendingDelta(events: events)
                } catch {
                    print("Error removing events: \(error)")
                }
            }
        }
    }

    // MARK: - Vice Selection (App Group UserDefaults, readable by extension)

    func saveViceSelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try JSONEncoder().encode(selection)
            sharedDefaults?.set(data, forKey: "viceSelection")
        } catch {
            print("❌ Error encoding FamilyActivitySelection for shared storage: \(error)")
        }
    }

    func loadViceSelection() -> FamilyActivitySelection? {
        guard let data = sharedDefaults?.data(forKey: "viceSelection") else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    // MARK: - Balance Mirror (readable by shield extensions)

    /// Mirrors the main app's saved balance. Does not include pending events.
    func saveBalanceSeconds(_ seconds: Int) {
        sharedDefaults?.set(seconds, forKey: "balanceSeconds")
    }

    /// Effective balance right now: last saved balance plus events the main
    /// app hasn't consumed yet.
    func currentBalanceSeconds() -> Int {
        let saved = sharedDefaults?.integer(forKey: "balanceSeconds") ?? 0
        let pending = getEvents().reduce(0) { total, event in
            switch event.type {
            case .earned: return total + event.seconds
            case .spent:  return total - event.seconds
            }
        }
        return max(0, saved + pending)
    }

    /// Same as `currentBalanceSeconds` but reads only UserDefaults — no file
    /// coordination. Use from the shield configuration extension, which gets
    /// killed by the system if it doesn't respond almost instantly.
    func fastBalanceSeconds() -> Int {
        let saved = sharedDefaults?.integer(forKey: "balanceSeconds") ?? 0
        let pending = sharedDefaults?.integer(forKey: "pendingDeltaSeconds") ?? 0
        return max(0, saved + pending)
    }

    /// Keeps a UserDefaults mirror of the net pending-event total so shield
    /// extensions can compute the balance without touching the events file.
    private func setPendingDelta(events: [TimeEvent]) {
        let delta = events.reduce(0) { total, event in
            switch event.type {
            case .earned: return total + event.seconds
            case .spent:  return total - event.seconds
            }
        }
        sharedDefaults?.set(delta, forKey: "pendingDeltaSeconds")
    }

    // MARK: - Spending Session State

    /// A session starts when the user chooses to use their earned time from a
    /// shield: all vice apps unshield, and the balance drains only while a
    /// vice app is actually in use (1-minute usage thresholds). The session
    /// ends when the balance is exhausted.
    func saveSessionActive(_ active: Bool) {
        sharedDefaults?.set(active, forKey: "sessionActive")
    }

    var isSessionActive: Bool {
        sharedDefaults?.bool(forKey: "sessionActive") ?? false
    }

    /// When the current session's metering interval is scheduled to end.
    /// Restarting monitoring also fires intervalDidEnd for the old interval,
    /// so the monitor compares against this to tell a real lapse from that.
    func saveSessionMeteringEnd(_ date: Date) {
        sharedDefaults?.set(date, forKey: "sessionMeteringEnd")
    }

    var sessionMeteringEnd: Date? {
        sharedDefaults?.object(forKey: "sessionMeteringEnd") as? Date
    }

    // MARK: - Notifications Toggle Mirror

    /// Mirror of the user's notifications setting so extensions can honor it
    func saveNotificationsEnabled(_ enabled: Bool) {
        sharedDefaults?.set(enabled, forKey: "notificationsEnabled")
    }

    var notificationsEnabled: Bool {
        // Default to enabled when the mirror hasn't been written yet
        (sharedDefaults?.object(forKey: "notificationsEnabled") as? Bool) ?? true
    }

    // MARK: - Daily Goal State (fast path: UserDefaults only)

    /// Today's goal, written by the app at rollover and whenever it changes
    func saveGoalToday(minutes: Int, day: String) {
        sharedDefaults?.set(minutes, forKey: "goalMinutesToday")
        sharedDefaults?.set(day, forKey: "goalDay")
    }

    /// The plan's current goal, for days the app hasn't rolled over yet
    func saveGoalBase(_ minutes: Int) {
        sharedDefaults?.set(minutes, forKey: "goalMinutesBase")
    }

    func goalMinutes(for day: String) -> Int {
        if sharedDefaults?.string(forKey: "goalDay") == day,
           let today = sharedDefaults?.object(forKey: "goalMinutesToday") as? Int {
            return today
        }
        return (sharedDefaults?.object(forKey: "goalMinutesBase") as? Int) ?? GoalPlan.default.currentGoal
    }

    /// Written by the monitor as earn thresholds fire
    var earnState: EarnState? {
        guard let day = sharedDefaults?.string(forKey: "earnDay") else { return nil }
        return EarnState(
            day: day,
            minutes: sharedDefaults?.integer(forKey: "earnMinutes") ?? 0,
            reached: sharedDefaults?.bool(forKey: "earnReached") ?? false
        )
    }

    func saveEarnState(_ state: EarnState) {
        sharedDefaults?.set(state.day, forKey: "earnDay")
        sharedDefaults?.set(state.minutes, forKey: "earnMinutes")
        sharedDefaults?.set(state.reached, forKey: "earnReached")
    }

    private static let reachedDaysLimit = 60

    /// Days the goal was reached, so the app can roll streaks forward over
    /// days it never ran on. Keeps the most recent 60.
    var reachedDays: Set<String> {
        Set(sharedDefaults?.stringArray(forKey: "reachedDays") ?? [])
    }

    func addReachedDay(_ day: String) {
        var days = reachedDays
        days.insert(day)
        // Day keys sort chronologically as strings
        let kept = days.sorted().suffix(Self.reachedDaysLimit)
        sharedDefaults?.set(Array(kept), forKey: "reachedDays")
    }

    /// The day the user claimed their unlock; shields stay off until it changes
    var unlockedDay: String? {
        sharedDefaults?.string(forKey: "unlockedDay")
    }

    func saveUnlockedDay(_ day: String?) {
        sharedDefaults?.set(day, forKey: "unlockedDay")
    }

    // MARK: - Haptics Toggle Mirror

    func saveHapticsEnabled(_ enabled: Bool) {
        sharedDefaults?.set(enabled, forKey: "hapticsEnabled")
    }

    var hapticsEnabled: Bool {
        (sharedDefaults?.object(forKey: "hapticsEnabled") as? Bool) ?? true
    }

    // MARK: - Last Shield Screen Record

    private let shieldStateKey = "shieldShowedBalanceByToken"

    /// The configuration extension records whether the screen it returned for
    /// an app offered an unlock. iOS caches shield appearances, so the action
    /// extension uses this to detect taps on a stale screen. Keyed by
    /// base64-encoded token data.
    func setShieldShowedBalance(_ showedBalance: Bool, tokenKey: String) {
        var states = (sharedDefaults?.dictionary(forKey: shieldStateKey) as? [String: Bool]) ?? [:]
        states[tokenKey] = showedBalance
        sharedDefaults?.set(states, forKey: shieldStateKey)
    }

    func shieldShowedBalance(tokenKey: String) -> Bool? {
        ((sharedDefaults?.dictionary(forKey: shieldStateKey) as? [String: Bool]) ?? [:])[tokenKey]
    }

}
