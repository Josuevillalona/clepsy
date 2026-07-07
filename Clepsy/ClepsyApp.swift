import SwiftUI

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

    /// Re-applies shields unless a paid unlock window is still running —
    /// otherwise foregrounding Clepsy would cut the unlock short.
    private func reapplyBlocksIfNeeded() {
        guard !SharedStorageService().isUnlockActive else { return }
        blockingService.applyViceAppBlocks()
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
                    }
                }
        }
    }
}
