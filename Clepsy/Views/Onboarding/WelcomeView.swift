import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Clepsy character (placeholder for now)
            Image(systemName: "hourglass")
                .font(.system(size: 120))
                .foregroundColor(.purple)

            Text("Meet Clepsy")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your friendly guide to healthier scrolling habits")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
