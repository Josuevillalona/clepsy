import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// DeviceActivityMonitor extension that runs in a separate process
/// to track app usage even when Clepsy is not running
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let sharedStorage = SharedStorageService()

    // MARK: - Interval Events

    /// The daily earning schedule restarts at midnight: a new day, so vice
    /// apps lock again. Also fires when monitoring starts mid-day, which is
    /// why the unlock check matters.
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("ClepsyMonitor: Interval started for \(activity.rawValue)")

        guard activity == .productiveApps else { return }
        let today = DayKey.string(for: Date())
        guard ViceShieldPolicy.shouldShield(today: today, unlockedDay: sharedStorage.unlockedDay),
              let selection = sharedStorage.loadViceSelection() else { return }

        ViceShield.apply(selection, closingForegroundApp: true)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("ClepsyMonitor: Interval ended for \(activity.rawValue)")
    }

    // MARK: - Earning

    /// Earn thresholds fire once per minute of productive-app use, counted
    /// since midnight, so "earn_N" means N minutes so far today
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        print("ClepsyMonitor: Event \(event.rawValue) reached threshold for \(activity.rawValue)")

        guard activity == .productiveApps,
              let minute = EarnRules.minute(fromEventName: event.rawValue) else { return }

        let today = DayKey.string(for: Date())
        let result = EarnRules.apply(
            eventMinute: minute,
            today: today,
            stored: sharedStorage.earnState,
            goal: sharedStorage.goalMinutes(for: today),
            baseline: sharedStorage.earnBaseline(for: today)
        )
        sharedStorage.saveEarnState(result.state)

        if result.justReached {
            sharedStorage.addReachedDay(today)
            GoalNotifications.postClaimReady(storage: sharedStorage)
        }
    }
}

// MARK: - DeviceActivityName Extensions

extension DeviceActivityName {
    static let productiveApps = DeviceActivityName("productiveApps")
}
