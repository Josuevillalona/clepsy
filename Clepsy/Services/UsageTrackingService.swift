import Foundation
import DeviceActivity
import FamilyControls

@MainActor
class UsageTrackingService: ObservableObject {
    private let center = DeviceActivityCenter()
    private let sharedStorage = SharedStorageService()
    private let earningManager = EarningSessionManager()

    @Published var isMonitoringActive = false

    // MARK: - Monitoring Control

    func startMonitoringProductiveApps(_ apps: [TrackedApp]) {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(
                .productiveApps,
                during: schedule
            )
            isMonitoringActive = true
            print("Started monitoring productive apps")
        } catch {
            print("Failed to start productive monitoring: \(error)")
        }
    }

    func startMonitoringViceApps(_ apps: [TrackedApp]) {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(
                .viceApps,
                during: schedule
            )
            print("Started monitoring vice apps")
        } catch {
            print("Failed to start vice monitoring: \(error)")
        }
    }

    func stopAllMonitoring() {
        center.stopMonitoring([.productiveApps, .viceApps])
        isMonitoringActive = false
        print("Stopped all monitoring")
    }

    // MARK: - Event Sync

    /// Sync pending time events from shared storage to the view model
    func syncPendingTime(to viewModel: DashboardViewModel) {
        let events = sharedStorage.getEvents()

        guard !events.isEmpty else { return }

        // Process each event in chronological order
        for event in events.sorted(by: { $0.timestamp < $1.timestamp }) {
            switch event.type {
            case .earned:
                viewModel.addTime(seconds: event.seconds)
            case .spent:
                viewModel.subtractTime(seconds: event.seconds)
            }
        }

        // Clear queue after processing
        sharedStorage.clearEvents()
        print("Synced \(events.count) time events")
    }

    // MARK: - Earning Session (for direct app tracking)

    func startEarningSession(for app: TrackedApp) {
        earningManager.startSession(for: app.bundleIdentifier)
    }

    func pauseEarningSession() {
        earningManager.pauseSession()
    }

    func resumeEarningSession() {
        earningManager.resumeSession()
    }

    func endEarningSession() -> Int {
        let earnings = earningManager.currentSessionEarnings
        earningManager.endSession()
        return earnings
    }

    func setEarningUpdateCallback(_ callback: @escaping (Int) -> Void) {
        earningManager.onBalanceUpdate = callback
    }
}

// MARK: - DeviceActivityName Extensions

extension DeviceActivityName {
    static let productiveApps = DeviceActivityName("productiveApps")
    static let viceApps = DeviceActivityName("viceApps")
}
