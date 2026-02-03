import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case 0:
                WelcomeView(onContinue: viewModel.nextStep)
            case 1:
                HowItWorksView(
                    onContinue: viewModel.nextStep,
                    onBack: viewModel.previousStep
                )
            case 2:
                PermissionView(
                    viewModel: viewModel,
                    onContinue: viewModel.nextStep,
                    onBack: viewModel.previousStep
                )
            case 3:
                AppSelectionView(
                    onContinue: viewModel.nextStep,
                    onBack: viewModel.previousStep
                )
            case 4:
                ReadyView(onComplete: {
                    viewModel.completeOnboarding()
                    hasCompletedOnboarding = true
                })
            default:
                WelcomeView(onContinue: viewModel.nextStep)
            }
        }
        .animation(.easeInOut, value: viewModel.currentStep)
    }
}

#Preview {
    OnboardingContainerView(hasCompletedOnboarding: .constant(false))
}
