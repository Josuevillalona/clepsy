import SwiftUI

struct PermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                Spacer()
            }
            .padding(.horizontal)

            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)

            Text("Screen Time Permission")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Clepsy needs permission to monitor app usage and manage screen time. This data stays private on your device.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

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
                            .tint(.white)
                    }
                    Text(isRequesting ? "Requesting..." : "Grant Permission")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(12)
            }
            .disabled(isRequesting)
            .padding(.horizontal)
            .padding(.bottom, 32)
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
