import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots at top
            OnboardingProgressDots(
                currentStep: viewModel.currentStep,
                totalSteps: viewModel.totalSteps
            )
            .padding(.top, 8)

            // Step content
            Group {
                switch viewModel.currentStep {
                case 0:
                    WelcomeView(onContinue: viewModel.nextStep)
                case 1:
                    PermissionView(
                        viewModel: viewModel,
                        onContinue: viewModel.nextStep,
                        onBack: viewModel.previousStep
                    )
                case 2:
                    ViceAppSelectionView(
                        onContinue: viewModel.nextStep,
                        onBack: viewModel.previousStep
                    )
                case 3:
                    ProductiveAppSelectionView(
                        onContinue: viewModel.nextStep,
                        onBack: viewModel.previousStep
                    )
                case 4:
                    DailyGoalView(
                        onContinue: {
                            viewModel.completeOnboarding()
                            hasCompletedOnboarding = true
                        },
                        onBack: viewModel.previousStep
                    )
                default:
                    WelcomeView(onContinue: viewModel.nextStep)
                }
            }
            .animation(.easeInOut, value: viewModel.currentStep)
        }
        .background(Color.clepsyMidnight.ignoresSafeArea())
    }
}

struct OnboardingProgressDots: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.clepsyGold : Color.clepsyTextSecondary.opacity(0.3))
                    .frame(width: index == currentStep ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: currentStep)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    OnboardingContainerView(hasCompletedOnboarding: .constant(false))
}
