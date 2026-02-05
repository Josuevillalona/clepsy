import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.clepsyMidnight.ignoresSafeArea()

            VStack(spacing: ClepsySpacing.sm) {
                // Clepsy mascot
                Image("clepsy_mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .padding(.top, ClepsySpacing.md)

                (Text("Meet ") + Text("Clepsy").foregroundColor(.clepsyGold))
                    .font(.clepsyLargeTitle)
                    .foregroundColor(.clepsyTextPrimary)

                Text("Your guide to healthier scrolling habits")
                    .font(.clepsySubheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.clepsyTextSecondary)
                    .padding(.horizontal, ClepsySpacing.md)

                // How it works
                VStack(alignment: .leading, spacing: 14) {
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
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.top, ClepsySpacing.sm)

                Spacer()

                Button(action: onContinue) {
                    Text("Get Started")
                }
                .buttonStyle(.clepsyPrimary)
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.bottom, ClepsySpacing.lg)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: ClepsySpacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.clepsyGold)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.clepsyHeadline)
                    .foregroundColor(.clepsyTextPrimary)
                Text(description)
                    .font(.clepsyCaption)
                    .foregroundColor(.clepsyTextSecondary)
            }
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
