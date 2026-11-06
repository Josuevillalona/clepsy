import Foundation

// The decisions the extensions make, kept free of DeviceActivity and
// ManagedSettings types so the unit tests can exercise them directly.
// Compiled into the app and the monitor, shield action and shield
// configuration extensions.

// MARK: - Spending Sessions

enum SessionRules {

    /// DeviceActivity rejects schedules shorter than 15 minutes
    static let minimumIntervalSeconds: TimeInterval = 15 * 60

    /// Metering window for a session started at `now`. Anchored at now, not
    /// midnight: thresholds count usage inside the interval, so a midnight
    /// anchor would instantly re-fire for every vice minute used earlier
    /// today. Runs to 23:59, or now+16 min when that's too close to midnight.
    static func meteringWindow(startingAt now: Date, calendar: Calendar = .current) -> DateInterval {
        var end = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now)
            ?? now.addingTimeInterval(16 * 60)
        if end.timeIntervalSince(now) < minimumIntervalSeconds {
            end = now.addingTimeInterval(16 * 60)
        }
        return DateInterval(start: now, end: end)
    }

    /// Starting a session restarts monitoring, and stopping the previous
    /// interval also fires intervalDidEnd — after the new session is already
    /// marked active. Only an end at (or within a minute of) the scheduled
    /// end is a real lapse.
    static func isRealIntervalEnd(now: Date, scheduledEnd: Date?) -> Bool {
        guard let scheduledEnd else { return true }
        return now >= scheduledEnd.addingTimeInterval(-60)
    }

    enum ViceMinuteOutcome: Equatable {
        /// No session: retroactive usage from before blocking began
        case ignore
        case spend
        /// Spend, and the balance is now exhausted
        case spendAndEndSession
    }

    enum EndReason: Equatable {
        case balanceExhausted
        /// The metering interval lapsed at 23:59 with time left
        case dayEnded
    }

    /// Title and body for the notification posted when a session ends
    static func endNotification(for reason: EndReason) -> (title: String, body: String) {
        switch reason {
        case .balanceExhausted:
            return ("Time's up ⏳",
                    "You've used all your earned time — apps are locked again. Tap to earn more in Clepsy.")
        case .dayEnded:
            return ("That's a wrap for today 🌙",
                    "Apps are locked again — your time resets at midnight. Earn fresh minutes in Clepsy tomorrow.")
        }
    }

    /// A vice-app usage minute ticked over; each one spends 60 seconds
    static func viceMinuteOutcome(sessionActive: Bool, balanceSeconds: Int) -> ViceMinuteOutcome {
        guard sessionActive else { return .ignore }
        return balanceSeconds - 60 <= 0 ? .spendAndEndSession : .spend
    }
}

// MARK: - Shield

enum ShieldRules {

    struct Content: Equatable {
        let title: String
        let subtitle: String
        let primaryButton: String
        /// nil when the primary button already just closes the shield
        let secondaryButton: String?
    }

    static func content(appName: String?, availableMinutes: Int) -> Content {
        let title = appName.map { "\($0) is blocked" } ?? "This app is blocked"

        if availableMinutes > 0 {
            return Content(
                title: title,
                subtitle: "You have \(availableMinutes) min. It only counts down while you're in blocked apps.",
                primaryButton: "Use My Time",
                secondaryButton: "Go Back"
            )
        }

        // Shield extensions can't launch apps, so a lone "Go Back" is the only
        // honest zero-balance action
        return Content(
            title: title,
            subtitle: "No time available yet. Earn minutes in your productive apps, then come back.",
            primaryButton: "Go Back",
            secondaryButton: nil
        )
    }

    enum PrimaryTap: Equatable {
        case startSession
        /// Zero balance, but the screen tapped was a cached one that still
        /// offered an unlock — ask iOS to redraw it
        case redrawStaleScreen
        case close
    }

    /// `screenShowedBalance` is what the configuration extension last recorded
    /// for this app's screen (nil if never recorded)
    static func primaryTap(availableMinutes: Int, screenShowedBalance: Bool?) -> PrimaryTap {
        if availableMinutes > 0 { return .startSession }
        return screenShowedBalance == true ? .redrawStaleScreen : .close
    }
}
