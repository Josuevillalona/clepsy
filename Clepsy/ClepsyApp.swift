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
        // Vice spending monitoring is NOT started here — it's anchored to the
        // start of each spending session so earlier usage today can't count
    }

    /// Re-applies shields unless a spending session with remaining balance is
    /// running — otherwise foregrounding Clepsy would cut the session short.
    private func reapplyBlocksIfNeeded() {
        let shared = SharedStorageService()
        if shared.isSessionActive && shared.currentBalanceSeconds() > 0 { return }
        // Session over (or balance gone while the monitor missed it) — clean up
        shared.saveSessionActive(false)
        blockingService.applyViceAppBlocks()
    }

    /// Needed for the monitor extension's "time's up" notification at re-lock
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
