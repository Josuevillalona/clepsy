import FamilyControls
import Foundation
import ManagedSettings

/// Whether vice apps should be shielded right now. Every path that applies
/// shields (app foreground, Settings changes, onboarding, the monitor at
/// midnight) checks this first, so nothing ever undoes a claimed unlock.
enum ViceShieldPolicy {
    static func shouldShield(today: String, unlockedDay: String?) -> Bool {
        unlockedDay != today
    }
}

/// Applies and removes vice-app shields. Shared by the app and the monitor
/// extension, which re-locks at midnight.
enum ViceShield {

    static func apply(_ selection: FamilyActivitySelection, closingForegroundApp: Bool) {
        let store = ManagedSettingsStore()

        if closingForegroundApp {
            // Shielding a foreground app shows a stale cached screen (Apple bug
            // FB14237883). A momentary hard block terminates the app instead,
            // so the next launch gets a fresh, correct shield.
            let apps = Set(selection.applicationTokens.map { Application(token: $0) })
            if !apps.isEmpty {
                store.application.blockedApplications = apps
                // Give the system a beat to terminate the app before swapping
                // the hard block (which hides home-screen icons) for the shield
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
        // Also clears a hard block left behind if an extension died mid-swap
        store.application.blockedApplications = nil

        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
    }

    static func remove() {
        let store = ManagedSettingsStore()
        store.application.blockedApplications = nil
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
}
