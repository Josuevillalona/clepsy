import SwiftUI
import UserNotifications

@main
struct ClepsyApp: App {
    @StateObject private var persistenceService = PersistenceService()
    @State private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) var scenePhase

    private let blockingService = AppBlockingService()
    @StateObject private var usageTrackingService = UsageTrackingService()

    var body: some Scene {
        WindowGroup {
            ContentView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .onAppear {
                    let settings = persistenceService.loadUserSettings()
                    hasCompletedOnboarding = settings.hasCompletedOnboarding
                    if hasCompletedOnboarding {
                        reapplyBlocksIfNeeded()
                        startDailyMonitoring()
                        Self.requestNotificationPermission()
                    }
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        if hasCompletedOnboarding {
                            reapplyBlocksIfNeeded()
                            startDailyMonitoring()
                        }
                        NotificationCenter.default.post(
                            name: NSNotification.Name("AppDidBecomeActive"),
                            object: nil
                        )
                    }
                }
        }
    }

    private func startDailyMonitoring() {
        let productive = persistenceService.loadProductiveSelection()
        usageTrackingService.startDailyMonitoring(productiveSelection: productive)
    }

    /// Locks vice apps unless today's unlock was claimed. The monitor locks
    /// them at midnight; this catches anything it missed.
    private func reapplyBlocksIfNeeded() {
        blockingService.applyViceAppBlocks()
    }

    /// Needed for the "You hit your goal" notification from the monitor
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}

struct ContentView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var showCelebration = false

    var body: some View {
        if hasCompletedOnboarding {
            DashboardView(showCelebration: $showCelebration)
        } else {
            OnboardingContainerView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .onChange(of: hasCompletedOnboarding) { completed in
                    if completed {
                        showCelebration = true
                        ClepsyApp.requestNotificationPermission()
                    }
                }
        }
    }
}
