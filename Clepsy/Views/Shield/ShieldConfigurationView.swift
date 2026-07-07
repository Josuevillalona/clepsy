import SwiftUI

/// Shield view shown when user attempts to open a blocked app
struct ShieldConfigurationView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let appName: String
    let onUnlock: () -> Void
    let onEarnTime: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.clepsyMidnight.ignoresSafeArea()

            VStack(spacing: ClepsySpacing.md) {
                Spacer()

                // Clepsy character
                ClepsyCharacterView(
                    balancePercentage: min(viewModel.balancePercentage, 1.0),
                    expression: .patient
                )
                .scaleEffect(0.55)
                .frame(height: 160)

                // Lock message
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.clepsyOrange)

                    Text("\(appName) is locked")
                        .font(.clepsyTitle)
                        .foregroundColor(.clepsyTextPrimary)

                    Text("Earn time with productive apps to unlock")
                        .font(.clepsySubheadline)
                        .foregroundColor(.clepsyTextSecondary)
                }

                // Balance info card
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Balance")
                                .font(.clepsyCaption)
                                .foregroundColor(.clepsyTextSecondary)
                            Text(viewModel.formattedBalance)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.clepsyGold)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Earned Today")
                                .font(.clepsyCaption)
                                .foregroundColor(.clepsyTextSecondary)
                            Text("\(viewModel.todayEarned / 60)m")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.clepsyTeal)
                        }
                    }
                }
                .padding()
                .background(Color.clepsySurface)
                .cornerRadius(16)
                .padding(.horizontal, ClepsySpacing.md)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    if viewModel.currentBalance.currentSeconds > 0 {
                        let unlockMinutes = min(5, viewModel.currentBalance.currentSeconds / 60)

                        Button(action: {
                            viewModel.unlockViceApps(seconds: unlockMinutes * 60)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "lock.open.fill")
                                Text("Unlock for \(unlockMinutes)m")
                            }
                        }
                        .buttonStyle(.clepsyPrimary)

                        Text("This will deduct \(unlockMinutes)m from your balance")
                            .font(.clepsyCaption)
                            .foregroundColor(.clepsyTextSecondary)
                    } else {
                        Button(action: {
                            onEarnTime()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "clock.badge.checkmark")
                                Text("Earn Time Now")
                            }
                        }
                        .buttonStyle(.clepsyPrimary)

                        Text("Use productive apps to earn unlock time")
                            .font(.clepsyCaption)
                            .foregroundColor(.clepsyTextSecondary)
                    }

                    Button(action: { dismiss() }) {
                        Text("Go Back")
                            .font(.clepsySubheadline)
                            .foregroundColor(.clepsyTextSecondary)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.bottom, ClepsySpacing.lg)
            }
        }
    }
}

#Preview("With Balance") {
    ShieldConfigurationView(
        viewModel: {
            let vm = DashboardViewModel()
            vm.addTime(seconds: 600)
            return vm
        }(),
        appName: "Instagram",
        onUnlock: {},
        onEarnTime: {}
    )
}

#Preview("No Balance") {
    ShieldConfigurationView(
        viewModel: DashboardViewModel(),
        appName: "TikTok",
        onUnlock: {},
        onEarnTime: {}
    )
}
