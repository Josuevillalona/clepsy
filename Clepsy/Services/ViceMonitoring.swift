import DeviceActivity
import FamilyControls
import Foundation

/// Starts usage metering for a spending session. Shared by the app (sessions
/// started from the dashboard) and the shield action extension (sessions
/// started from "Use My Time"), so both meter identically.
enum ViceMonitoring {

    static let activity = DeviceActivityName("viceApps")

    /// Thresholds every minute; each firing spends 60 seconds
    static let thresholdMinutes = 1...180

    /// Records the session's scheduled end, then restarts monitoring with the
    /// interval anchored at now (see SessionRules.meteringWindow). The end is
    /// saved first: stopping the old interval fires intervalDidEnd, and the
    /// monitor checks it against this to ignore the restart.
    static func restart(for selection: FamilyActivitySelection,
                        storage: SharedStorageService,
                        calendar: Calendar = .current) throws {
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else { return }

        let window = SessionRules.meteringWindow(startingAt: Date(), calendar: calendar)
        storage.saveSessionMeteringEnd(window.end)

        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(components, from: window.start),
            intervalEnd: calendar.dateComponents(components, from: window.end),
            repeats: false
        )

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for minutes in thresholdMinutes {
            events[DeviceActivityEvent.Name("spend_\(minutes)")] = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                threshold: DateComponents(minute: minutes)
            )
        }

        let center = DeviceActivityCenter()
        center.stopMonitoring([activity])
        try center.startMonitoring(activity, during: schedule, events: events)
    }
}
