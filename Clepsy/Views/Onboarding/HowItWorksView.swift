import SwiftUI

struct HowItWorksView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

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

            Text("How It Works")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "lock.fill",
                    title: "Vice apps are blocked",
                    description: "TikTok, Instagram, etc. start locked"
                )

                FeatureRow(
                    icon: "book.fill",
                    title: "Earn time being productive",
                    description: "Use Kindle, Duolingo to earn minutes"
                )

                FeatureRow(
                    icon: "clock.fill",
                    title: "Spend time on vice apps",
                    description: "Unlock social media with earned time"
                )

                FeatureRow(
                    icon: "arrow.clockwise",
                    title: "Daily reset at midnight",
                    description: "Fresh start every day, no rollover"
                )
            }
            .padding(.horizontal)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    HowItWorksView(onContinue: {}, onBack: {})
}
