import Foundation
import DeviceActivity
import FamilyControls

@MainActor
class UsageTrackingService: ObservableObject {
    private let center = DeviceActivityCenter()
    private let sharedStorage: SharedStorageService

    @Published var isMonitoringActive = false

    init(sharedStorage: SharedStorageService = SharedStorageService()) {
        self.sharedStorage = sharedStorage
    }

    // MARK: - Daily Earning Monitoring

    /// Sets up a daily midnight-to-midnight schedule with a threshold for each
    /// minute of productive-app use, up to the largest goal. The monitor turns
    /// "earn_N" into today's minutes, and the schedule's start each midnight
    /// is when vice apps lock again. Restarting an active schedule resets the
    /// day's accumulated usage, so this is a no-op while it's running.
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

        // 1 minute is the finest granularity DeviceActivity allows
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for minutes in 1...GoalRules.minutesRange.upperBound {
            events[DeviceActivityEvent.Name("\(EarnRules.eventPrefix)\(minutes)")] = DeviceActivityEvent(
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

    func stopAllMonitoring() {
        center.stopMonitoring([.productiveApps])
        isMonitoringActive = false
    }
}

// MARK: - DeviceActivityName Constants

extension DeviceActivityName {
    static let productiveApps = DeviceActivityName("productiveApps")
}
