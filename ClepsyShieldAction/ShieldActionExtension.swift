import DeviceActivity
import Foundation
import ManagedSettings
import os.log

class ShieldActionExtension: ShieldActionDelegate {

    private static let log = Logger(subsystem: "com.clepsy.app.shieldaction", category: "action")

    override func handle(action: ShieldAction,
                         for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            let storage = SharedStorageService()
            let availableMinutes = storage.currentBalanceSeconds() / 60

            guard availableMinutes > 0 else {
                // iOS may have shown a cached screen from when there WAS
                // balance ("Use my time"). If so, defer — that asks the
                // system to re-query the configuration for a redraw with the
                // real zero-balance screen. Recording false first means a
                // second tap (or a fresh "Go Back" screen) always closes.
                if let tokenData = try? JSONEncoder().encode(application),
                   storage.shieldShowedBalance(tokenKey: tokenData.base64EncodedString()) == true {
                    storage.setShieldShowedBalance(false, tokenKey: tokenData.base64EncodedString())
                    Self.log.info("Primary tap: zero balance on stale screen — deferring for redraw")
                    completionHandler(.defer)
                } else {
                    Self.log.info("Primary tap: zero balance on fresh screen — closing")
                    completionHandler(.close)
                }
                return
            }

            Self.log.info("Primary tap: starting spending session (balance \(availableMinutes, privacy: .public) min)")
            startSession(storage: storage)
            // Shields are gone, so .none lets the user proceed into the app
            completionHandler(.none)

        case .secondaryButtonPressed:
            completionHandler(.close)

        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(action: ShieldAction,
                         for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            let storage = SharedStorageService()

            guard storage.currentBalanceSeconds() / 60 > 0 else {
                completionHandler(.close)
                return
            }

            startSession(storage: storage)
            completionHandler(.none)

        case .secondaryButtonPressed:
            completionHandler(.close)

        @unknown default:
            completionHandler(.defer)
        }
    }

    // MARK: - Spending Session

    /// Unshields all vice apps and marks a session active. Nothing is spent
    /// up front — the monitor extension drains the balance one minute per
    /// minute of actual vice-app usage and re-shields when it hits zero.
    private func startSession(storage: SharedStorageService) {
        storage.saveSessionActive(true)

        let store = ManagedSettingsStore()
        store.shield.applications = nil
        store.shield.applicationCategories = nil

        restartViceMonitoring(storage: storage)
    }

    /// Starts usage metering with the schedule interval anchored at NOW.
    /// Thresholds only count usage inside the interval, so a midnight-anchored
    /// schedule would instantly re-fire for every vice minute already used
    /// today the moment the session starts, draining the balance in seconds.
    private func restartViceMonitoring(storage: SharedStorageService) {
        guard let selection = storage.loadViceSelection() else { return }

        let calendar = Calendar.current
        let now = Date()
        var end = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now)
            ?? now.addingTimeInterval(16 * 60)
        if end.timeIntervalSince(now) < 15 * 60 {
            end = now.addingTimeInterval(16 * 60)
        }

        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(components, from: now),
            intervalEnd: calendar.dateComponents(components, from: end),
            repeats: false
        )

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for minutes in 1...180 {
            events[DeviceActivityEvent.Name("spend_\(minutes)")] = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                threshold: DateComponents(minute: minutes)
            )
        }

        let center = DeviceActivityCenter()
        let activity = DeviceActivityName("viceApps")
        center.stopMonitoring([activity])
        do {
            try center.startMonitoring(activity, during: schedule, events: events)
        } catch {
            Self.log.error("Failed to restart vice monitoring: \(error.localizedDescription, privacy: .public)")
        }
    }
}
