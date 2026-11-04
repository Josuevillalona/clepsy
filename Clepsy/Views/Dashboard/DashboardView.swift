import SwiftUI
import FamilyControls
import DeviceActivity

struct DashboardView: View {
    @StateObject private var store = GoalStore()
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @Binding var showCelebration: Bool
    @State private var celebrationOpacity: Double = 0
    @State private var celebrationScale: CGFloat = 0.5
    @State private var glowPulse = false
    @State private var reportRefreshDate = Date()

    /// The monitor updates today's minutes in the background; while the
    /// dashboard is open, pick them up every so often
    private let liveRefresh = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

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
                        goalHeroCard
                        streakCard
                        viceAppsSection
                        productiveAppsSection
                    }
                    .padding(.horizontal, ClepsySpacing.md)
                    .padding(.bottom, ClepsySpacing.lg)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings, onDismiss: refreshAll) {
            SettingsView(store: store)
        }
        .onAppear(perform: refreshAll)
        .onReceive(liveRefresh) { _ in store.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            // Open across midnight: a new day's goal, and the report's new day
            refreshAll()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { refreshAll() }
        }
        .overlay {
            if showCelebration {
                celebrationOverlay
            }
        }
    }

    private func refreshAll() {
        viewModel.refreshSelections()
        store.refresh()
        // The report view only renders once; recreating it makes iOS hand
        // the extension fresh usage data
        reportRefreshDate = Date()
    }

    // MARK: - Goal Hero Card

    private var fillPercentage: Double {
        guard !store.reachedToday else { return 1 }
        guard store.todayGoal > 0 else { return 0 }
        return min(Double(store.earnedMinutes) / Double(store.todayGoal), 1)
    }

    private var expression: ClepsyExpression {
        if store.reachedToday { return .celebrating }
        return fillPercentage >= 0.5 ? .encouraging : .patient
    }

    private var goalHeroCard: some View {
        VStack(spacing: 14) {
            // Character with pulsing glow; the sand is today's goal progress
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.clepsyGold.opacity(glowPulse ? 0.22 : 0.1),
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

                ClepsyCharacterView(fillPercentage: fillPercentage, expression: expression)
                    .scaleEffect(0.525)
                    .frame(height: 150)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(min(store.earnedMinutes, store.todayGoal))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.clepsyTextPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.earnedMinutes)
                    Text("of \(store.todayGoal) min")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.clepsyTextSecondary)
                }

                // Accurate to the second, drawn by the ClepsyReport extension
                // (display-only: the app can't read it)
                DeviceActivityReport(.productiveTime, filter: productiveTodayFilter)
                    .frame(height: 20)
                    .id(reportRefreshDate)
            }

            StatusChip(status: store.status) {
                // The claim screen arrives with the reward layer
                store.claim()
            }

            if case .buildUp(let target) = store.plan.mode {
                buildUpRow(target: target)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ClepsySpacing.md)
        .padding(.horizontal, ClepsySpacing.sm)
        .background(Color.clepsySurface)
        .cornerRadius(24)
    }

    private func buildUpRow(target: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.caption)
                .foregroundColor(.clepsyTeal)
            Text("Building up · today \(store.todayGoal) · target \(target) min")
                .font(.clepsyCaption)
                .foregroundColor(.clepsyTextSecondary)
        }
    }

    // MARK: - Streak

    private var streakCard: some View {
        HStack(spacing: ClepsySpacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(colors: [.clepsyGold, .clepsyOrange], startPoint: .top, endPoint: .bottom)
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(store.displayStreak)-day streak")
                        .font(.clepsyHeadline)
                        .foregroundColor(.clepsyTextPrimary)
                        .contentTransition(.numericText())
                    Text(streakMessage)
                        .font(.clepsyCaption)
                        .foregroundColor(.clepsyTextSecondary)
                }
            }

            Spacer()

            if store.streak.freezes > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "snowflake")
                    Text("\(store.streak.freezes)")
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.clepsyTeal)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.clepsyTeal.opacity(0.15))
                .clipShape(Capsule())
                .accessibilityLabel("\(store.streak.freezes) streak freeze\(store.streak.freezes == 1 ? "" : "s")")
            }
        }
        .padding()
        .background(Color.clepsySurface)
        .cornerRadius(20)
    }

    private var streakMessage: String {
        switch store.displayStreak {
        case 0: return "Hit today's goal to start one"
        case 1...6: return "Keep it going!"
        case 7...13: return "You're building a real habit here"
        case 14...29: return "Two weeks strong!"
        case 30...59: return "A whole month! Incredible"
        default: return "You're unstoppable!"
        }
    }

    private var productiveTodayFilter: DeviceActivityFilter {
        let today = Calendar.current.dateInterval(of: .day, for: reportRefreshDate)
            ?? DateInterval(start: reportRefreshDate, duration: 0)
        // Earning is per device, so count only this one
        let device: DeviceActivityData.Device.Model = UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
        return DeviceActivityFilter(
            segment: .daily(during: today),
            users: .all,
            devices: .init([device]),
            applications: viewModel.productiveSelection.applicationTokens,
            categories: viewModel.productiveSelection.categoryTokens
        )
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
}

#Preview {
    DashboardView(showCelebration: .constant(false))
}
