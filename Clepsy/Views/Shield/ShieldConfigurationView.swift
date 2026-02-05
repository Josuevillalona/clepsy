import SwiftUI

/// Shield view shown when user attempts to open a blocked app
/// Note: In production, this would be shown via ManagedSettings ShieldConfiguration extension
/// This view serves as a preview and for app-based shield presentation
struct ShieldConfigurationView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let appName: String
    let appBundleId: String
    let onUnlock: () -> Void
    let onEarnTime: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Clepsy character showing current balance
            ClepsyCharacterView(
                balancePercentage: min(viewModel.balancePercentage, 1.0),
                expression: .patient
            )
            .scaleEffect(0.7)

            // Lock message
            VStack(spacing: 8) {
                Text("\(appName) is locked")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Earn time with productive apps to unlock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Balance info card
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Balance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.formattedBalance)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Exchange Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("1:1")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }

                Divider()

                HStack {
                    Text("Earned today:")
                    Spacer()
                    Text("\(viewModel.todayEarned / 60) min")
                        .foregroundColor(.green)
                }
                .font(.subheadline)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 24)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                if viewModel.currentBalance.currentSeconds > 0 {
                    Button(action: {
                        onUnlock()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                            Text("Unlock \(appName)")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(14)
                    }
                } else {
                    Button(action: {
                        onEarnTime()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "clock.badge.checkmark")
                            Text("Earn Time Now")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(14)
                    }

                    Text("Use productive apps to earn unlock time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("Go Back")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview("With Balance") {
    ShieldConfigurationView(
        viewModel: {
            let vm = DashboardViewModel()
            vm.addTime(seconds: 600) // 10 minutes
            return vm
        }(),
        appName: "Instagram",
        appBundleId: "com.burbn.instagram",
        onUnlock: {},
        onEarnTime: {}
    )
}

#Preview("No Balance") {
    ShieldConfigurationView(
        viewModel: DashboardViewModel(),
        appName: "TikTok",
        appBundleId: "com.zhiliaoapp.musically",
        onUnlock: {},
        onEarnTime: {}
    )
}
