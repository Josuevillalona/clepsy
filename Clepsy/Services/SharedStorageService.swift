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

    /// The day the earning schedule was last (re)started (see MonitoringRules)
    var monitoringStartDay: String? {
        sharedDefaults?.string(forKey: "monitoringStartDay")
    }

    func saveMonitoringStartDay(_ day: String) {
        sharedDefaults?.set(day, forKey: "monitoringStartDay")
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


}
