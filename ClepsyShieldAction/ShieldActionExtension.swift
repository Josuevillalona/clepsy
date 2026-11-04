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
            let tokenKey = (try? JSONEncoder().encode(application))?.base64EncodedString()

            switch ShieldRules.primaryTap(
                availableMinutes: availableMinutes,
                screenShowedBalance: tokenKey.flatMap { storage.shieldShowedBalance(tokenKey: $0) }
            ) {
            case .startSession:
                Self.log.info("Primary tap: starting spending session (balance \(availableMinutes, privacy: .public) min)")
                startSession(storage: storage)
                // Shields are gone, so .none lets the user proceed into the app
                completionHandler(.none)

            case .redrawStaleScreen:
                // iOS showed a cached screen from when there WAS balance.
                // Defer asks the system to re-query the configuration for a
                // redraw. Recording false first means a second tap (or a fresh
                // "Go Back" screen) always closes.
                if let tokenKey {
                    storage.setShieldShowedBalance(false, tokenKey: tokenKey)
                }
                Self.log.info("Primary tap: zero balance on stale screen — deferring for redraw")
                completionHandler(.defer)

            case .close:
                Self.log.info("Primary tap: zero balance on fresh screen — closing")
                completionHandler(.close)
            }

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

        guard let selection = storage.loadViceSelection() else { return }
        do {
            try ViceMonitoring.restart(for: selection, storage: storage)
        } catch {
            Self.log.error("Failed to restart vice monitoring: \(error.localizedDescription, privacy: .public)")
        }
    }
}
