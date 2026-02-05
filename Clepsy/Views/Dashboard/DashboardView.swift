import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showSettings = false
    @State private var showBlockScreen = false
    @State private var blockAppName = "Instagram"
    @Binding var showCelebration: Bool
    @State private var celebrationOpacity: Double = 0
    @State private var celebrationScale: CGFloat = 0.5

    var body: some View {
        NavigationView {
            ZStack {
                Color.clepsyMidnight
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ClepsySpacing.md) {
                        balanceHeroCard
                        if viewModel.showStreakBanner {
                            streakBanner
                        }
                        todayStatsSection
                        goalProgressCard
                        viceAppsSection
                        productiveAppsSection
                        testActionsSection
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
            .sheet(isPresented: $showBlockScreen) {
                ShieldConfigurationView(
                    viewModel: viewModel,
                    appName: blockAppName,
                    onUnlock: {
                        viewModel.subtractTime(seconds: 300)
                    },
                    onEarnTime: {
                        viewModel.addTime(seconds: 300)
                    }
                )
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
        VStack(spacing: 16) {
            // Character with circular glow
            ZStack {
                // Radial glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.clepsyGold.opacity(0.15),
                                Color.clepsyGold.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)

                ClepsyCharacterView(
                    balancePercentage: min(viewModel.goalProgressPercentage, 1.0),
                    expression: expressionForBalance
                )
                .scaleEffect(0.7)
                .frame(height: 200)
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
                    .foregroundColor(.white)
                Text(viewModel.streakMessage)
                    .font(.clepsyCaption)
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            Button {
                withAnimation { viewModel.dismissStreak() }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
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

    // MARK: - Today's Stats

    private var todayStatsSection: some View {
        VStack(alignment: .leading, spacing: ClepsySpacing.sm) {
            Text("Today's Stats")
                .font(.clepsyHeadline)
                .foregroundColor(.clepsyTextPrimary)

            HStack(spacing: ClepsySpacing.sm) {
                // Earned
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.clepsyTeal)
                        Text("Time Earned")
                            .font(.clepsyCaption)
                            .foregroundColor(.clepsyTextSecondary)
                    }
                    Text(viewModel.formattedEarned)
                        .font(.clepsyTitle2)
                        .foregroundColor(.clepsyTextPrimary)
                    Text("From \(viewModel.productiveApps.count) apps")
                        .font(.system(size: 11))
                        .foregroundColor(.clepsyTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.clepsySurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.clepsyTeal.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(16)

                // Spent
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.clepsyOrange)
                        Text("Time Spent")
                            .font(.clepsyCaption)
                            .foregroundColor(.clepsyTextSecondary)
                    }
                    Text(viewModel.formattedSpent)
                        .font(.clepsyTitle2)
                        .foregroundColor(.clepsyTextPrimary)
                    Text(viewModel.viceApps.first.map { "On \($0.name)" } ?? "No apps")
                        .font(.system(size: 11))
                        .foregroundColor(.clepsyTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.clepsySurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.clepsyOrange.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(16)
            }
        }
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
        VStack(alignment: .leading, spacing: ClepsySpacing.sm) {
            Text("Vice Apps")
                .font(.clepsyHeadline)
                .foregroundColor(.clepsyTextPrimary)

            ForEach(viewModel.viceApps) { app in
                Button {
                    blockAppName = app.name
                    showBlockScreen = true
                } label: {
                    HStack(spacing: 12) {
                        AppIconView(bundleIdentifier: app.bundleIdentifier)
                            .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .font(.clepsyBody)
                                .foregroundColor(.clepsyTextPrimary)
                            Text("0 min today")
                                .font(.clepsyCaption)
                                .foregroundColor(.clepsyTextSecondary)
                        }

                        Spacer()

                        Text("Vice")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.clepsyOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.clepsyOrange.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.clepsySurface)
                    .cornerRadius(16)
                }
            }
        }
    }

    // MARK: - Productive Apps

    private var productiveAppsSection: some View {
        VStack(alignment: .leading, spacing: ClepsySpacing.sm) {
            Text("Productive Apps")
                .font(.clepsyHeadline)
                .foregroundColor(.clepsyTextPrimary)

            ForEach(viewModel.productiveApps) { app in
                Button {
                    launchApp(bundleId: app.bundleIdentifier)
                } label: {
                    HStack(spacing: 12) {
                        AppIconView(bundleIdentifier: app.bundleIdentifier)
                            .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .font(.clepsyBody)
                                .foregroundColor(.clepsyTextPrimary)
                            Text("0 min earned")
                                .font(.clepsyCaption)
                                .foregroundColor(.clepsyTextSecondary)
                        }

                        Spacer()

                        Text("Productive")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.clepsyTeal)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.clepsyTeal.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.clepsySurface)
                    .cornerRadius(16)
                }
            }
        }
    }

    // MARK: - Test Actions

    private var testActionsSection: some View {
        VStack(alignment: .leading, spacing: ClepsySpacing.sm) {
            Text("Test Actions")
                .font(.clepsyCaption)
                .foregroundColor(.clepsyTextSecondary)

            HStack(spacing: ClepsySpacing.sm) {
                Button {
                    viewModel.addTime(seconds: 300)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.clepsyTeal)
                        Text("+5 min")
                            .font(.clepsyCaption)
                            .foregroundColor(.clepsyTextPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.clepsySurface)
                    .cornerRadius(10)
                }

                Button {
                    viewModel.subtractTime(seconds: 120)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(viewModel.canSpend ? .clepsyOrange : .clepsyTextSecondary)
                        Text("-2 min")
                            .font(.clepsyCaption)
                            .foregroundColor(viewModel.canSpend ? .clepsyTextPrimary : .clepsyTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.clepsySurface)
                    .cornerRadius(10)
                }
                .disabled(!viewModel.canSpend)
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

    private func launchApp(bundleId: String) {
        if let url = URL(string: "app://\(bundleId)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

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
