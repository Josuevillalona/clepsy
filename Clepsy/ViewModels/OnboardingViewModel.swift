import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var hasCompletedOnboarding: Bool = false

    private let persistenceService: PersistenceService
    private let screenTimeService: ScreenTimeService

    let totalSteps = 5 // Per onboarding_specs.md

    init(
        persistenceService: PersistenceService = PersistenceService(),
        screenTimeService: ScreenTimeService = ScreenTimeService()
    ) {
        self.persistenceService = persistenceService
        self.screenTimeService = screenTimeService

        let settings = persistenceService.loadUserSettings()
        self.hasCompletedOnboarding = settings.hasCompletedOnboarding
    }

    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func completeOnboarding() {
        var settings = persistenceService.loadUserSettings()
        settings.hasCompletedOnboarding = true
        persistenceService.saveUserSettings(settings)
        hasCompletedOnboarding = true
    }

    func requestScreenTimePermission() async {
        do {
            _ = try await screenTimeService.requestAuthorization()
        } catch {
            print("❌ Screen Time authorization failed: \(error)")
        }
    }
}
