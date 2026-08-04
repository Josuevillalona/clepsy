import Foundation
import FamilyControls

class SharedStorageService {
    private let appGroup = "group.com.clepsy.shared"
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.clepsy.shared", qos: .userInitiated)

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    private lazy var containerURL: URL = {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? FileManager.default.temporaryDirectory
    }()

    private lazy var eventsFileURL: URL = {
        containerURL.appendingPathComponent("pendingTimeEvents.json")
    }()

    init() {
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

    // MARK: - Notifications Toggle Mirror

    /// Mirror of the user's notifications setting so extensions can honor it
    func saveNotificationsEnabled(_ enabled: Bool) {
        sharedDefaults?.set(enabled, forKey: "notificationsEnabled")
    }

    var notificationsEnabled: Bool {
        // Default to enabled when the mirror hasn't been written yet
        (sharedDefaults?.object(forKey: "notificationsEnabled") as? Bool) ?? true
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
