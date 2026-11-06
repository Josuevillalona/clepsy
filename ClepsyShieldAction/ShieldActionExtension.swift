import Foundation
import ManagedSettings
import os.log

class ShieldActionExtension: ShieldActionDelegate {

    private static let log = Logger(subsystem: "com.clepsy.app.shieldaction", category: "action")

    override func handle(action: ShieldAction,
                         for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action))
    }

    // Apps shielded through a category route here instead
    override func handle(action: ShieldAction,
                         for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action))
    }

    private func respond(to action: ShieldAction) -> ShieldActionResponse {
        guard action == .primaryButtonPressed else { return .close }

        let storage = SharedStorageService()
        let today = DayKey.string(for: Date())
        let reached = storage.earnState.map { $0.day == today && $0.reached } ?? false

        switch ShieldRules.primaryTap(reached: reached) {
        case .claimViaNotification:
            // A shield can't open Clepsy; the notification puts it one tap away
            Self.log.info("Primary tap: goal reached — posting claim notification")
            GoalNotifications.postClaimReady(storage: storage)
            return .close
        case .close:
            return .close
        }
    }
}
