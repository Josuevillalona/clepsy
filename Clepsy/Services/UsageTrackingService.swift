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
    //
    // Spending sessions are started from the shield, not from the app — see
    // ShieldActionExtension.restartViceMonitoring. There is deliberately no
    // in-app copy of that logic: a second implementation of the
    // anchored-at-session-start schedule (CD-032) would silently drift from
    // the live one.

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
