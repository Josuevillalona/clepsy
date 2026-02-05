import SwiftUI

struct PermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isRequesting = false

    var body: some View {
        ZStack {
            Color.clepsyMidnight.ignoresSafeArea()

            VStack(spacing: ClepsySpacing.md) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.clepsyGold)
                    }
                    Spacer()
                }
                .padding(.horizontal, ClepsySpacing.md)

                Spacer()

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.clepsyGold)

                Text("Screen Time Permission")
                    .font(.clepsyTitle)
                    .foregroundColor(.clepsyTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Clepsy needs permission to monitor app usage and manage screen time. This data stays private on your device.")
                    .font(.clepsyBody)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.clepsyTextSecondary)
                    .padding(.horizontal, ClepsySpacing.md)

                Spacer()

                Button(action: {
                    Task {
                        isRequesting = true
                        await viewModel.requestScreenTimePermission()
                        isRequesting = false
                        onContinue()
                    }
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.clepsyMidnight)
                        }
                        Text(isRequesting ? "Requesting..." : "Grant Permission")
                    }
                }
                .buttonStyle(.clepsyPrimary)
                .disabled(isRequesting)
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.bottom, ClepsySpacing.lg)
            }
        }
    }
}

#Preview {
    PermissionView(
        viewModel: OnboardingViewModel(),
        onContinue: {},
        onBack: {}
    )
}
