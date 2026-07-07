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
                // balance ("Unlock for X min"). If so, defer — that makes the
                // system re-query the configuration, redrawing the shield with
                // the real zero-balance screen. Recording false first means a
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

            Self.log.info("Primary tap: unlocking for \(min(5, availableMinutes), privacy: .public) min (balance \(availableMinutes, privacy: .public) min)")
            unlock(app: application, minutes: min(5, availableMinutes), storage: storage)
            // Shield is gone, so .none lets the user proceed into the app
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
        // Legacy path for category-based selections: iOS only tells us the
        // category, so the unlock has to be all-or-nothing.
        switch action {
        case .primaryButtonPressed:
            let storage = SharedStorageService()
            let availableMinutes = storage.currentBalanceSeconds() / 60

            guard availableMinutes > 0 else {
                completionHandler(.close)
                return
            }

            unlockAll(minutes: min(5, availableMinutes), storage: storage)
            completionHandler(.none)

        case .secondaryButtonPressed:
            completionHandler(.close)

        @unknown default:
            completionHandler(.defer)
        }
    }

    // MARK: - Per-App Unlock

    private func unlock(app token: ApplicationToken, minutes: Int, storage: SharedStorageService) {
        let seconds = minutes * 60
        let expiry = Date().addingTimeInterval(TimeInterval(seconds))

        // Spend the time — the main app reconciles this event on next open
        storage.appendEvent(TimeEvent(seconds: seconds, timestamp: Date(), type: .spent))

        // Lift the shield for just this app; the rest stay blocked
        let store = ManagedSettingsStore()
        var shielded = store.shield.applications ?? []
        shielded.remove(token)
        store.shield.applications = shielded.isEmpty ? nil : shielded

        // Register the unlock so foregrounding Clepsy doesn't re-shield this
        // app early, and schedule its own re-lock activity
        let activityName = "unlock_\(UUID().uuidString)"
        if let tokenData = try? JSONEncoder().encode(token) {
            storage.registerUnlock(tokenData: tokenData, expiry: expiry, activityName: activityName)
        }
        scheduleRelock(named: activityName, at: expiry)
    }

    // MARK: - Whole-Selection Unlock (categories)

    private func unlockAll(minutes: Int, storage: SharedStorageService) {
        let seconds = minutes * 60
        let expiry = Date().addingTimeInterval(TimeInterval(seconds))

        storage.appendEvent(TimeEvent(seconds: seconds, timestamp: Date(), type: .spent))
        storage.saveUnlockExpiry(expiry)

        let store = ManagedSettingsStore()
        store.shield.applications = nil
        store.shield.applicationCategories = nil

        let center = DeviceActivityCenter()
        center.stopMonitoring([DeviceActivityName("unlockWindow")])
        scheduleRelock(named: "unlockWindow", at: expiry)
    }

    // MARK: - Re-lock Scheduling

    private func scheduleRelock(named name: String, at expiry: Date) {
        // DeviceActivity requires >= 15 min intervals, so backdate the start;
        // only the end (re-lock moment) matters.
        let calendar = Calendar.current
        var start = expiry.addingTimeInterval(-16 * 60)
        if !calendar.isDate(start, inSameDayAs: expiry) {
            start = calendar.startOfDay(for: expiry)
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents([.hour, .minute, .second], from: start),
            intervalEnd: calendar.dateComponents([.hour, .minute, .second], from: expiry),
            repeats: false
        )

        do {
            try DeviceActivityCenter().startMonitoring(DeviceActivityName(name), during: schedule)
        } catch {
            print("ClepsyShieldAction: Failed to schedule re-lock: \(error)")
        }
    }
}
