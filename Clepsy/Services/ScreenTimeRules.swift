import Foundation

// Shield decisions, kept free of ManagedSettings types so the unit tests can
// exercise them directly. Compiled into the app and the shield configuration
// and shield action extensions.

enum ShieldRules {

    struct Content: Equatable {
        let title: String
        let subtitle: String
        let primaryButton: String
        /// nil when the primary button already just closes the shield
        let secondaryButton: String?
    }

    // MARK: Goal model

    static func content(appName: String?, earnedMinutes: Int, goalMinutes: Int, reached: Bool) -> Content {
        if reached {
            return Content(
                title: "You did it 🎉",
                subtitle: "Today's goal is done. Open Clepsy to claim your unlock.",
                primaryButton: "Claim in Clepsy",
                secondaryButton: "Go Back"
            )
        }
        let title = appName.map { "\($0) is locked" } ?? "This app is locked"
        return Content(
            title: title,
            subtitle: "\(min(earnedMinutes, goalMinutes)) of \(goalMinutes) min today. Your productive apps unlock it.",
            primaryButton: "Go Back",
            secondaryButton: nil
        )
    }

    enum GoalTap: Equatable {
        case close
        /// Shields can't open Clepsy; a notification is the one-tap path
        case claimViaNotification
    }

    static func primaryTap(reached: Bool) -> GoalTap {
        reached ? .claimViaNotification : .close
    }
}
