import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

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

        print("ClepsyMonitor: Interval ended for \(activity.rawValue)")

        // The session metering interval runs to end of day; if a session is
        // still open when it lapses, usage would stop counting — end it.
        if activity == .viceApps && sharedStorage.isSessionActive {
            endSession()
        }
    }

    // MARK: - Threshold Events

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        print("ClepsyMonitor: Event \(event.rawValue) reached threshold for \(activity.rawValue)")

        if activity == .productiveApps {
            handleProductiveAppEvent(event)
        } else if activity == .viceApps {
            handleViceAppEvent(event)
        }
    }

    // MARK: - Earning

    private func handleProductiveAppEvent(_ event: DeviceActivityEvent.Name) {
        // Thresholds are spaced 1 minute apart, so each firing = 1 minute earned
        let timeEvent = TimeEvent(
            seconds: 60,
            timestamp: Date(),
            type: .earned
        )

        sharedStorage.appendEvent(timeEvent)
        print("ClepsyMonitor: Earned 60 seconds")
    }

    // MARK: - Spending (session model)

    /// A vice-app usage minute ticked over. Only drains the balance during an
    /// active spending session: outside a session vice apps are shielded, so
    /// any firing is retroactive usage from before blocking began (thresholds
    /// count cumulative whole-day usage) and must be ignored.
    private func handleViceAppEvent(_ event: DeviceActivityEvent.Name) {
        guard sharedStorage.isSessionActive else {
            print("ClepsyMonitor: Ignoring \(event.rawValue) — no active session")
            return
        }

        sharedStorage.appendEvent(TimeEvent(seconds: 60, timestamp: Date(), type: .spent))
        print("ClepsyMonitor: Spent 60 seconds")

        if sharedStorage.currentBalanceSeconds() <= 0 {
            endSession()
        }
    }

    /// Balance exhausted: kick the user out of the vice app, then re-shield.
    /// Applying a shield over a foreground app renders a stale cached screen
    /// (Apple bug FB14237883), so instead we hard-block momentarily — which
    /// terminates the running app — and land the user on the home screen with
    /// the notification explaining why. Their next launch is a fresh shield
    /// presentation, which always shows the correct zero-balance screen.
    private func endSession() {
        sharedStorage.saveSessionActive(false)
        postTimesUpNotification()

        guard let selection = sharedStorage.loadViceSelection() else { return }
        let store = ManagedSettingsStore()

        let apps = Set(selection.applicationTokens.map { Application(token: $0) })
        if !apps.isEmpty {
            store.application.blockedApplications = apps
            // Give the system a beat to terminate the app before swapping the
            // hard block (which hides home-screen icons) for the normal shield
            Thread.sleep(forTimeInterval: 1.0)
            store.application.blockedApplications = nil
        }

        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
        }
    }

    private func postTimesUpNotification() {
        guard sharedStorage.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time's up ⏳"
        content.body = "You've used all your earned time — apps are locked again. Tap to earn more in Clepsy."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "timesup_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - DeviceActivityName Extensions

extension DeviceActivityName {
    static let productiveApps = DeviceActivityName("productiveApps")
    static let viceApps       = DeviceActivityName("viceApps")
}
