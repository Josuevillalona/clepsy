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

    // MARK: - Per-App Unlock Registry

    private let activeUnlocksKey = "activeUnlocks"

    /// Records an active per-app unlock, keyed by the DeviceActivity name of
    /// its re-lock schedule. Token is stored as encoded Data so this file
    /// doesn't need ManagedSettings types.
    func registerUnlock(tokenData: Data, expiry: Date, activityName: String) {
        var unlocks = unlockRegistry()
        unlocks[activityName] = ["token": tokenData, "expiry": expiry.timeIntervalSince1970]
        sharedDefaults?.set(unlocks, forKey: activeUnlocksKey)
    }

    func unlockTokenData(for activityName: String) -> Data? {
        unlockRegistry()[activityName]?["token"] as? Data
    }

    func removeUnlock(activityName: String) {
        var unlocks = unlockRegistry()
        unlocks.removeValue(forKey: activityName)
        sharedDefaults?.set(unlocks, forKey: activeUnlocksKey)
    }

    /// Token data for unlocks still inside their window; prunes expired entries.
    func activeUnlockTokenDatas() -> [Data] {
        var unlocks = unlockRegistry()
        let now = Date().timeIntervalSince1970
        let expired = unlocks.filter { (($0.value["expiry"] as? TimeInterval) ?? 0) <= now }
        if !expired.isEmpty {
            expired.keys.forEach { unlocks.removeValue(forKey: $0) }
            sharedDefaults?.set(unlocks, forKey: activeUnlocksKey)
        }
        return unlocks.compactMap { $0.value["token"] as? Data }
    }

    private func unlockRegistry() -> [String: [String: Any]] {
        (sharedDefaults?.dictionary(forKey: activeUnlocksKey) as? [String: [String: Any]]) ?? [:]
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

    // MARK: - Unlock Window State

    func saveUnlockExpiry(_ date: Date?) {
        if let date {
            sharedDefaults?.set(date.timeIntervalSince1970, forKey: "unlockExpiresAt")
        } else {
            sharedDefaults?.removeObject(forKey: "unlockExpiresAt")
        }
    }

    func loadUnlockExpiry() -> Date? {
        guard let interval = sharedDefaults?.object(forKey: "unlockExpiresAt") as? TimeInterval else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    /// True while a paid unlock window is still running
    var isUnlockActive: Bool {
        guard let expiry = loadUnlockExpiry() else { return false }
        return expiry > Date()
    }
}
