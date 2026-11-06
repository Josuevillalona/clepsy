import Foundation
import DeviceActivity
import FamilyControls

@MainActor
class UsageTrackingService: ObservableObject {
    private let sharedStorage: SharedStorageService

    /// DeviceActivityCenter calls are synchronous requests to the Screen Time
    /// service and can hang for seconds. On the main thread that froze Clepsy
    /// until iOS killed it mid-restart, leaving nothing monitored. They run
    /// here instead, one at a time.
    private static let queue = DispatchQueue(label: "com.clepsy.monitoring", qos: .userInitiated)

    @Published var isMonitoringActive = false

    init(sharedStorage: SharedStorageService = SharedStorageService()) {
        self.sharedStorage = sharedStorage
    }

    // MARK: - Daily Earning Monitoring

    /// Sets up a daily midnight-to-midnight schedule with a threshold for each
    /// minute of productive-app use, up to the largest goal. The monitor turns
    /// "earn_N" into today's minutes, and the schedule's start each midnight
    /// is when vice apps lock again. A restart makes iOS count from zero again,
    /// so today's minutes are carried over first (see EarnRules), and it only
    /// restarts when needed (see MonitoringRules).
    func startDailyMonitoring(productiveSelection: FamilyActivitySelection, force: Bool = false) {
        guard !productiveSelection.applicationTokens.isEmpty ||
              !productiveSelection.categoryTokens.isEmpty else { return }

        let storage = sharedStorage
        Self.queue.async { [weak self] in
            let center = DeviceActivityCenter()
            let today = DayKey.string(for: Date())
            let restart = force || MonitoringRules.shouldRestart(
                isActive: center.activities.contains(.productiveApps),
                startedDay: storage.monitoringStartedAt.map { DayKey.string(for: $0) },
                lastEventDay: storage.lastEarnEventAt.map { DayKey.string(for: $0) },
                today: today
            )
            guard restart else {
                DispatchQueue.main.async { self?.isMonitoringActive = true }
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

            // Starting an activity that's already monitored replaces it, so
            // there's no stop first and never a moment with nothing tracking
            do {
                storage.prepareForMonitoringRestart(today: today)
                try center.startMonitoring(.productiveApps, during: schedule, events: events)
                storage.recordMonitoringStarted(at: Date())
                DispatchQueue.main.async { self?.isMonitoringActive = true }
            } catch {
                print("❌ Failed to start daily monitoring: \(error)")
            }
        }
    }

    func stopAllMonitoring() {
        Self.queue.async { DeviceActivityCenter().stopMonitoring([.productiveApps]) }
        isMonitoringActive = false
    }
}

// MARK: - DeviceActivityName Constants

extension DeviceActivityName {
    static let productiveApps = DeviceActivityName("productiveApps")
}
