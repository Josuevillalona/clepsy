import SwiftUI
import FamilyControls

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @Binding var showCelebration: Bool
    @State private var celebrationOpacity: Double = 0
    @State private var celebrationScale: CGFloat = 0.5
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            Color.clepsyMidnight
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Text("Clepsy")
                        .font(.clepsyHeadline)
                        .foregroundColor(.clepsyTextPrimary)

                    Spacer()

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.body)
                            .foregroundColor(.clepsyGold)
                    }
                }
                .padding(.horizontal, ClepsySpacing.md)
                .padding(.vertical, ClepsySpacing.sm)

                ScrollView {
                    VStack(spacing: ClepsySpacing.md) {
                        balanceHeroCard
                        if viewModel.showStreakBanner {
                            streakBanner
                        }
                        goalProgressCard
                        viceAppsSection
                        productiveAppsSection
                    }
                    .padding(.horizontal, ClepsySpacing.md)
                    .padding(.bottom, ClepsySpacing.lg)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            viewModel.checkAndPerformDailyReset()
            viewModel.refreshGoal()
            viewModel.syncPendingEvents()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                viewModel.syncPendingEvents()
            }
        }
        .overlay {
            if showCelebration {
                celebrationOverlay
            }
        }
    }

    // MARK: - Balance Hero Card

    private var balanceHeroCard: some View {
        VStack(spacing: 16) {
            // Character with pulsing glow
            ZStack {
                // Pulsing radial glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.clepsyGold.opacity(glowPulse ? 0.2 : 0.1),
                                Color.clepsyGold.opacity(glowPulse ? 0.08 : 0.03),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(glowPulse ? 1.08 : 1.0)

                ClepsyCharacterView(
                    balancePercentage: min(viewModel.balancePercentage, 1.0),
                    expression: expressionForBalance
                )
                .scaleEffect(0.525)
                .frame(height: 150)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true)
                ) {
                    glowPulse = true
                }
            }

            // Balance
            VStack(spacing: 6) {
                Text("YOUR BALANCE")
                    .font(.clepsyCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(.clepsyTextSecondary)
                    .tracking(1.5)

                Text(viewModel.formattedBalance)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.clepsyTextPrimary)
            }

            // Earned / Spent inline
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(viewModel.formattedEarned)
                        .font(.clepsyHeadline)
                        .foregroundColor(.clepsyTeal)
                    Text("EARNED")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.clepsyTextSecondary)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.clepsyTextSecondary.opacity(0.3))
                    .frame(width: 1, height: 30)

                VStack(spacing: 2) {
                    Text(viewModel.formattedSpent)
                        .font(.clepsyHeadline)
                        .foregroundColor(.clepsyOrange)
                    Text("SPENT")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.clepsyTextSecondary)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ClepsySpacing.md)
        .padding(.horizontal, ClepsySpacing.sm)
        .background(Color.clepsySurface)
        .cornerRadius(24)
    }

    // MARK: - Streak Banner

    private var streakBanner: some View {
        HStack {
            Text("🔥")
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.currentStreak) Day Streak!")
                    .font(.clepsyHeadline)
                    .foregroundColor(.clepsyTextPrimary)
                Text(viewModel.streakMessage)
                    .font(.clepsyCaption)
                    .foregroundColor(.clepsyTextPrimary.opacity(0.85))
            }

            Spacer()

            Button {
                withAnimation { viewModel.dismissStreak() }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.clepsyTextPrimary.opacity(0.7))
                    .frame(width: 32, height: 32)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.clepsyGold, .clepsyOrange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Goal Progress

    private var goalProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundColor(.clepsyTeal)
                    Text("Daily Goal")
                        .font(.clepsyHeadline)
                        .foregroundColor(.clepsyTextPrimary)
                }
                Spacer()
                Text("\(Int(viewModel.goalProgressPercentage * 100))%")
                    .font(.clepsyHeadline)
                    .foregroundColor(.clepsyGold)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.clepsyMidnight)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [.clepsyTeal, .clepsyGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(0, geometry.size.width * viewModel.goalProgressPercentage),
                            height: 10
                        )
                        .animation(.easeInOut(duration: 0.3), value: viewModel.goalProgressPercentage)
                }
            }
            .frame(height: 10)

            Text("\(viewModel.todayEarnedMinutes) of \(viewModel.dailyGoalMinutes) minutes earned today")
                .font(.clepsyCaption)
                .foregroundColor(.clepsyTextSecondary)
        }
        .padding()
        .background(Color.clepsySurface)
        .cornerRadius(20)
    }

    // MARK: - Vice Apps

    private var viceAppsSection: some View {
        selectionSection(
            title: "Blocked Apps",
            selection: viewModel.viceSelection,
            badge: "Vice",
            badgeColor: .clepsyOrange,
            emptyMessage: "No blocked apps yet — choose them in Settings"
        )
    }

    // MARK: - Productive Apps

    private var productiveAppsSection: some View {
        selectionSection(
            title: "Productive Apps",
            selection: viewModel.productiveSelection,
            badge: "Productive",
            badgeColor: .clepsyTeal,
            emptyMessage: "No productive apps yet — choose them in Settings"
        )
    }

    private func selectionSection(
        title: String,
        selection: FamilyActivitySelection,
        badge: String,
        badgeColor: Color,
        emptyMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: ClepsySpacing.sm) {
            Text(title)
                .font(.clepsyHeadline)
                .foregroundColor(.clepsyTextPrimary)

            if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
                Text(emptyMessage)
                    .font(.clepsyCaption)
                    .foregroundColor(.clepsyTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.clepsySurface)
                    .cornerRadius(16)
            } else {
                ForEach(Array(selection.categoryTokens), id: \.self) { token in
                    selectionRow(Label(token), badge: badge, badgeColor: badgeColor)
                }
                ForEach(Array(selection.applicationTokens), id: \.self) { token in
                    selectionRow(Label(token), badge: badge, badgeColor: badgeColor)
                }
            }
        }
    }

    private func selectionRow<L: View>(_ label: L, badge: String, badgeColor: Color) -> some View {
        HStack(spacing: 12) {
            label
                .font(.clepsyBody)
                .foregroundColor(.clepsyTextPrimary)

            Spacer()

            Text(badge)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(badgeColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(badgeColor.opacity(0.15))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.clepsySurface)
        .cornerRadius(16)
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
        if viewModel.goalProgressPercentage >= 1.0 {
            return .celebrating
        } else if viewModel.goalProgressPercentage > 0.3 {
            return .encouraging
        } else {
            return .patient
        }
    }
}

#Preview {
    DashboardView(showCelebration: .constant(false))
}
