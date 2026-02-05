import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showSettings = false
    @Binding var showCelebration: Bool
    @State private var celebrationOpacity: Double = 0
    @State private var celebrationScale: CGFloat = 0.5

    var body: some View {
        NavigationView {
            ZStack {
                // Brand background
                Color.clepsyMidnight
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ClepsySpacing.md) {
                        // Balance Hero Card
                        balanceHeroCard

                        // Today's Stats
                        todayStatsSection

                        // Quick Actions (test buttons for MVP)
                        quickActionsSection
                    }
                    .padding(.horizontal, ClepsySpacing.md)
                    .padding(.bottom, ClepsySpacing.lg)
                }
            }
            .navigationTitle("Clepsy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.clepsyMidnight, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.clepsyGold)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.checkAndPerformDailyReset()
            viewModel.refreshGoal()
        }
        .overlay {
            if showCelebration {
                celebrationOverlay
            }
        }
    }

    // MARK: - Balance Hero Card

    private var balanceHeroCard: some View {
        VStack(spacing: ClepsySpacing.sm) {
            // Clepsy Character
            ClepsyCharacterView(
                balancePercentage: min(viewModel.balancePercentage, 1.0),
                expression: expressionForBalance
            )
            .scaleEffect(0.65)
            .frame(height: 180)

            // Balance Display
            VStack(spacing: ClepsySpacing.xs) {
                Text("YOUR BALANCE")
                    .font(.clepsyCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(.clepsyTextSecondary)
                    .tracking(1.5)

                Text(viewModel.formattedBalance)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.clepsyGold)

                Text("Available to spend")
                    .font(.clepsySubheadline)
                    .foregroundColor(.clepsyTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ClepsySpacing.md)
        .padding(.horizontal, ClepsySpacing.sm)
        .background(Color.clepsySurface)
        .cornerRadius(20)
    }

    // MARK: - Today's Stats

    private var todayStatsSection: some View {
        VStack(alignment: .leading, spacing: ClepsySpacing.sm) {
            Text("Today's Stats")
                .font(.clepsyHeadline)
                .foregroundColor(.clepsyTextPrimary)

            HStack(spacing: ClepsySpacing.sm) {
                // Earned Card
                StatCard(
                    title: "Time Earned",
                    value: formatSeconds(viewModel.todayEarned),
                    icon: "arrow.up.circle.fill",
                    color: .clepsyTeal
                )

                // Spent Card
                StatCard(
                    title: "Time Spent",
                    value: formatSeconds(viewModel.todaySpent),
                    icon: "arrow.down.circle.fill",
                    color: .clepsyOrange
                )
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: ClepsySpacing.sm) {
            Text("Quick Actions")
                .font(.clepsyHeadline)
                .foregroundColor(.clepsyTextPrimary)

            Button {
                viewModel.addTime(seconds: 300)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.clepsyTeal)
                    Text("Add 5 minutes (test)")
                        .foregroundColor(.clepsyTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.clepsyTextSecondary)
                }
                .padding()
                .background(Color.clepsySurface)
                .cornerRadius(12)
            }

            Button {
                viewModel.subtractTime(seconds: 120)
            } label: {
                HStack {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.clepsyOrange)
                    Text("Subtract 2 minutes (test)")
                        .foregroundColor(.clepsyTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.clepsyTextSecondary)
                }
                .padding()
                .background(Color.clepsySurface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Celebration Overlay

    private var celebrationOverlay: some View {
        ZStack {
            Color.clepsyMidnight.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: ClepsySpacing.md) {
                Image("clepsy_mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)

                Text("You're All Set!")
                    .font(.clepsyLargeTitle)
                    .foregroundColor(.clepsyGold)

                Text("Clepsy is ready to help you build healthier habits")
                    .font(.clepsySubheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.clepsyTextSecondary)
                    .padding(.horizontal, ClepsySpacing.md)
            }
            .scaleEffect(celebrationScale)
            .opacity(celebrationOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                celebrationOpacity = 1
                celebrationScale = 1
            }
            // Auto-dismiss after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    celebrationOpacity = 0
                    celebrationScale = 0.8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCelebration = false
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.3)) {
                celebrationOpacity = 0
                celebrationScale = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showCelebration = false
            }
        }
    }

    // MARK: - Helpers

    private var expressionForBalance: ClepsyExpression {
        if viewModel.balancePercentage > 0.6 {
            return .celebrating
        } else if viewModel.balancePercentage > 0.2 {
            return .encouraging
        } else {
            return .patient
        }
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes == 0 {
            return "0m"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMins = minutes % 60
            return remainingMins > 0 ? "\(hours)h \(remainingMins)m" : "\(hours)h"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: ClepsySpacing.xs) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.clepsyCaption)
                    .foregroundColor(.clepsyTextSecondary)
            }

            Text(value)
                .font(.clepsyTitle2)
                .foregroundColor(.clepsyTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.clepsySurface)
        .cornerRadius(16)
    }
}

#Preview {
    DashboardView(showCelebration: .constant(false))
}
