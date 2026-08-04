import Foundation
import DeviceActivity
import FamilyControls

@MainActor
class UsageTrackingService: ObservableObject {
    private let center = DeviceActivityCenter()
    private let sharedStorage = SharedStorageService()

    @Published var isMonitoringActive = false

    // MARK: - Daily Earning Monitoring

    /// Sets up a daily midnight-to-midnight schedule that fires every 5 minutes
    /// of productive app usage. Each firing credits 5 minutes to the balance.
    /// Restarting an active schedule resets the day's accumulated usage,
    /// so this is a no-op while monitoring is already running.
    func startDailyMonitoring(productiveSelection: FamilyActivitySelection, force: Bool = false) {
        guard !productiveSelection.applicationTokens.isEmpty ||
              !productiveSelection.categoryTokens.isEmpty else { return }

        if !force && center.activities.contains(.productiveApps) {
            isMonitoringActive = true
            return
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // Thresholds every minute up to 3 hours of daily productive time.
        // 1 minute is the finest granularity DeviceActivity allows.
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for minutes in 1...180 {
            events[DeviceActivityEvent.Name("earn_\(minutes)")] = DeviceActivityEvent(
                applications: productiveSelection.applicationTokens,
                categories: productiveSelection.categoryTokens,
                threshold: DateComponents(minute: minutes)
            )
        }

        do {
            center.stopMonitoring([.productiveApps])
            try center.startMonitoring(.productiveApps, during: schedule, events: events)
            isMonitoringActive = true
        } catch {
            print("❌ Failed to start daily monitoring: \(error)")
        }
    }

    // MARK: - Vice Spending Monitoring

    /// Starts usage metering for a spending session. The schedule interval is
    /// anchored at NOW: thresholds only count usage inside the interval, so a
    /// midnight-anchored schedule would instantly re-fire for every vice
    /// minute already used today the moment a session starts. Runs to end of
    /// day (or now+16 min near midnight — DeviceActivity's 15-min minimum).
    func startViceSpendingMonitoring(viceSelection: FamilyActivitySelection) {
        guard !viceSelection.applicationTokens.isEmpty ||
              !viceSelection.categoryTokens.isEmpty else { return }

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
                applications: viceSelection.applicationTokens,
                categories: viceSelection.categoryTokens,
                threshold: DateComponents(minute: minutes)
            )
        }

        do {
            center.stopMonitoring([.viceApps])
            try center.startMonitoring(.viceApps, during: schedule, events: events)
        } catch {
            print("❌ Failed to start vice spending monitoring: \(error)")
        }
    }

    func stopAllMonitoring() {
        center.stopMonitoring([.productiveApps, .viceApps])
        isMonitoringActive = false
    }

    // MARK: - Event Sync

    /// Drains pending time events written by the extension into the view model.
    func syncPendingEvents(to viewModel: DashboardViewModel) {
        let events = sharedStorage.getEvents()
        guard !events.isEmpty else { return }

        for event in events.sorted(by: { $0.timestamp < $1.timestamp }) {
            switch event.type {
            case .earned:  viewModel.addTime(seconds: event.seconds)
            case .spent:   viewModel.subtractTime(seconds: event.seconds)
            }
        }

        sharedStorage.clearEvents()
    }
}

// MARK: - DeviceActivityName Constants

extension DeviceActivityName {
    static let productiveApps = DeviceActivityName("productiveApps")
    static let viceApps       = DeviceActivityName("viceApps")
}
