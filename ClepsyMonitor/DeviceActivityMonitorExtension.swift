import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// DeviceActivityMonitor extension that runs in a separate process
/// to track app usage even when Clepsy is not running
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let sharedStorage = SharedStorageService()

    // MARK: - Interval Events

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Called when monitoring interval starts (e.g., start of day)
        print("ClepsyMonitor: Interval started for \(activity.rawValue)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        if activity == .unlockWindow {
            reapplyViceShields()
        } else if activity.rawValue.hasPrefix("unlock_") {
            relockApp(activityName: activity.rawValue)
        }
    }

    /// Re-shields a single app whose per-app unlock window just ended.
    private func relockApp(activityName: String) {
        defer { sharedStorage.removeUnlock(activityName: activityName) }

        guard let tokenData = sharedStorage.unlockTokenData(for: activityName),
              let token = try? JSONDecoder().decode(ApplicationToken.self, from: tokenData) else {
            // Registry entry missing — fall back to a full re-shield, which
            // still skips apps inside their own unlock windows
            reapplyViceShields()
            return
        }

        // Skip if the user removed this app from their vice selection mid-window
        if let selection = sharedStorage.loadViceSelection(),
           !selection.applicationTokens.contains(token) {
            return
        }

        let store = ManagedSettingsStore()
        var shielded = store.shield.applications ?? []
        shielded.insert(token)
        store.shield.applications = shielded
    }

    private func reapplyViceShields() {
        sharedStorage.saveUnlockExpiry(nil)
        guard let selection = sharedStorage.loadViceSelection() else { return }

        // Don't cut short apps still inside their own per-app unlock window
        var tokens = selection.applicationTokens
        for data in sharedStorage.activeUnlockTokenDatas() {
            if let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                tokens.remove(token)
            }
        }

        let store = ManagedSettingsStore()
        store.shield.applications = tokens.isEmpty ? nil : tokens
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
    }

    // MARK: - Threshold Events

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // Called when a usage threshold is reached
        // This is where we track time earned or spent
        print("ClepsyMonitor: Event \(event.rawValue) reached threshold for \(activity.rawValue)")

        handleThresholdEvent(event, activity: activity)
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)

        print("ClepsyMonitor: Interval will start warning for \(activity.rawValue)")
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)

        print("ClepsyMonitor: Interval will end warning for \(activity.rawValue)")
    }

    // MARK: - Event Handling

    private func handleThresholdEvent(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        // Determine if this is a productive app (earning) or vice app (spending)
        if activity == .productiveApps {
            handleProductiveAppEvent(event)
        } else if activity == .viceApps {
            handleViceAppEvent(event)
        }
    }

    private func handleProductiveAppEvent(_ event: DeviceActivityEvent.Name) {
        // Thresholds are spaced 1 minute apart, so each firing = 1 minute earned
        let earnedSeconds = 60
        let timeEvent = TimeEvent(
            seconds: earnedSeconds,
            timestamp: Date(),
            type: .earned,
            appBundleId: extractBundleId(from: event)
        )

        sharedStorage.appendEvent(timeEvent)
        print("ClepsyMonitor: Earned \(earnedSeconds) seconds")
    }

    private func handleViceAppEvent(_ event: DeviceActivityEvent.Name) {
        // User spent time in a vice app - deduct from balance
        let spentSeconds = 60 // 1-minute tracking for vice apps
        let timeEvent = TimeEvent(
            seconds: spentSeconds,
            timestamp: Date(),
            type: .spent,
            appBundleId: extractBundleId(from: event)
        )

        sharedStorage.appendEvent(timeEvent)
        print("ClepsyMonitor: Spent \(spentSeconds) seconds")
    }

    private func extractBundleId(from event: DeviceActivityEvent.Name) -> String? {
        // Event names may be formatted to include app identifier
        // This is a placeholder - actual implementation depends on how events are configured
        let rawValue = event.rawValue
        if rawValue.contains(".") {
            return rawValue
        }
        return nil
    }
}

// MARK: - DeviceActivityName Extensions

extension DeviceActivityName {
    static let productiveApps = DeviceActivityName("productiveApps")
    static let viceApps       = DeviceActivityName("viceApps")
    static let unlockWindow   = DeviceActivityName("unlockWindow")
}
