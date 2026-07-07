import Foundation
import SwiftUI
import FamilyControls

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var hasCompletedOnboarding: Bool = false
    @Published var viceSelection = FamilyActivitySelection()
    @Published var productiveSelection = FamilyActivitySelection()

    private let persistenceService: PersistenceService
    private let screenTimeService: ScreenTimeService
    private let blockingService: AppBlockingService

    let totalSteps = 5

    init(
        persistenceService: PersistenceService = PersistenceService(),
        screenTimeService: ScreenTimeService = ScreenTimeService()
    ) {
        self.persistenceService = persistenceService
        self.screenTimeService = screenTimeService
        self.blockingService = AppBlockingService(persistenceService: persistenceService)

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
        persistenceService.saveViceSelection(viceSelection)
        persistenceService.saveProductiveSelection(productiveSelection)
        blockingService.applyViceAppBlocks()

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
