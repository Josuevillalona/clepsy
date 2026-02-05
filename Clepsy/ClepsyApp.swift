import SwiftUI

@main
struct ClepsyApp: App {
    @StateObject private var persistenceService = PersistenceService()
    @State private var hasCompletedOnboarding = false

    // ⚠️ Scene phase observer for daily reset
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .onAppear {
                    let settings = persistenceService.loadUserSettings()
                    hasCompletedOnboarding = settings.hasCompletedOnboarding
                }
                // ⚠️ Check daily reset when app enters foreground
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        // Dashboard will handle actual reset check via its ViewModel
                        // This establishes the pattern for foreground monitoring
                        NotificationCenter.default.post(
                            name: NSNotification.Name("AppDidBecomeActive"),
                            object: nil
                        )
                    }
                }
        }
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
