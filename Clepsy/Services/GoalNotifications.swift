import Foundation
import UserNotifications

/// The one notification the goal model sends: "you hit your goal, come
/// claim it". Posted by the monitor when the goal is reached, and by the
/// shield's "Claim in Clepsy" button, since a shield can't open the app.
enum GoalNotifications {

    static func postClaimReady(storage: SharedStorageService) {
        guard storage.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "You hit your goal 🎉"
        content.body = "Tap to claim your unlock."
        content.sound = .default

        // A fixed identifier replaces an unread one instead of stacking
        let request = UNNotificationRequest(identifier: "claim_ready", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
