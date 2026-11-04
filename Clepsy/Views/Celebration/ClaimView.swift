import SwiftUI

/// The day's one big moment: the goal is hit, and you claim your unlock.
/// Everything else in Clepsy stays calm so this lands. Timeline (spec):
/// glow → hourglass springs in → sand pours (haptic swell) → pop + confetti
/// → title → streak rolls up → badges → Unlock button. Tap to skip ahead.
struct ClaimView: View {
    let celebration: GoalStore.Celebration
    @ObservedObject var store: GoalStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Phase: Int, Comparable {
        case intro, pouring, popped, titled, streak, badges, ready, unlocked, offer, offerAccepted
        static func < (a: Phase, b: Phase) -> Bool { a.rawValue < b.rawValue }
    }

    @State private var phase: Phase = .intro
    @State private var fill = 0.55
    @State private var glow = false
    @State private var raysAngle = 0.0
    @State private var characterScale: CGFloat = 0.6
    @State private var popScale: CGFloat = 1
    @State private var shownStreak: Int
    @State private var visibleBadges = 0
    @State private var confetti = 0
    @State private var lockOpen = false
    @State private var shownOfferGoal: Int
    @State private var shimmer: CGFloat = -1
    @State private var sequence: Task<Void, Never>?

    init(celebration: GoalStore.Celebration, store: GoalStore) {
        self.celebration = celebration
        self.store = store
        _shownStreak = State(initialValue: celebration.streakBefore)
        _shownOfferGoal = State(initialValue: celebration.goal)
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                hero
                Spacer(minLength: ClepsySpacing.md)
                // A fixed-height slot, so the hero never shifts as the
                // button, lock and offer card come and go
                ZStack(alignment: .top) { bottom }
                    .frame(height: 210, alignment: .top)
                    .padding(.horizontal, ClepsySpacing.md)
                    .padding(.bottom, ClepsySpacing.md)
            }

            if !reduceMotion {
                ConfettiView(trigger: confetti)
                    .ignoresSafeArea()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if phase < .ready { skipToReady() }
        }
        .onAppear(perform: start)
        .onDisappear {
            sequence?.cancel()
            HapticsService.shared.stop()
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }

    // MARK: - Layers

    private var background: some View {
        Color.clepsyMidnight.ignoresSafeArea()
    }

    /// Glow and slowly turning rays, centered on the hourglass
    private var halo: some View {
        ZStack {
            AngularGradient(
                gradient: Gradient(colors: (0..<24).map { $0.isMultiple(of: 2) ? Color.clepsyGold.opacity(0.11) : .clear }),
                center: .center
            )
            .rotationEffect(.degrees(raysAngle))
            .mask(RadialGradient(colors: [.white, .clear], center: .center, startRadius: 30, endRadius: 300))
            .opacity(phase >= .popped ? 1 : 0)

            RadialGradient(
                colors: [Color.clepsyGold.opacity(glow ? 0.34 : 0), .clear],
                center: .center, startRadius: 10, endRadius: 260
            )
        }
        .frame(width: 700, height: 700)
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        HStack {
            Spacer()
            if phase < .unlocked {
                Button {
                    store.dismissCelebration()
                } label: {
                    Text("Not now")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.clepsyTextSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, ClepsySpacing.sm)
        .padding(.top, ClepsySpacing.sm)
        .frame(height: 52)
    }

    private var hero: some View {
        VStack(spacing: ClepsySpacing.sm) {
            ClepsyCharacterView(
                fillPercentage: fill,
                expression: phase >= .popped ? .celebrating : .encouraging
            )
            .scaleEffect(0.62 * characterScale * popScale)
            .frame(height: 200)
            // A background so the oversized halo never widens the layout
            .background(halo)

            VStack(spacing: 6) {
                Text(phase >= .unlocked ? "Unlocked!" : "Goal hit!")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "FFD88A"), .clepsyGold], startPoint: .top, endPoint: .bottom)
                    )
                    .contentTransition(.opacity)
                Text(phase >= .unlocked
                     ? "Enjoy your socials. You've earned it."
                     : "\(celebration.goal) min of productive time today")
                    .font(.clepsySubheadline)
                    .foregroundColor(.clepsyTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(phase >= .titled ? 1 : 0)
            .offset(y: phase >= .titled ? 0 : 12)

            streakRow
                .opacity(phase >= .streak ? 1 : 0)
                .scaleEffect(phase >= .streak ? 1 : 0.85)

            if !celebration.newBadges.isEmpty {
                badgeRow
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, ClepsySpacing.md)
    }

    private var streakRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [.clepsyGold, .clepsyOrange], startPoint: .top, endPoint: .bottom))
                .scaleEffect(shownStreak > celebration.streakBefore ? 1 : 1.25)
            Text("\(shownStreak)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.clepsyTextPrimary)
                .contentTransition(.numericText())
            Text("day streak")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.clepsyTextSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.clepsySurface.opacity(0.8))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }

    private var badgeRow: some View {
        HStack(spacing: ClepsySpacing.sm) {
            ForEach(Array(celebration.newBadges.enumerated()), id: \.element) { index, badge in
                VStack(spacing: 6) {
                    BadgeMedallion(badge: badge, earned: true, size: 54, shines: index < visibleBadges)
                    Text(badge.title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.clepsyTextPrimary)
                        .lineLimit(1)
                }
                .opacity(index < visibleBadges ? 1 : 0)
                .offset(y: index < visibleBadges ? 0 : 24)
                .scaleEffect(index < visibleBadges ? 1 : 0.6)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("New badges: " + celebration.newBadges.map(\.title).joined(separator: ", "))
    }

    @ViewBuilder
    private var bottom: some View {
        switch phase {
        case .offer, .offerAccepted:
            if let offer = celebration.offerGoal { offerCard(offer) }
        case .unlocked:
            Image(systemName: lockOpen ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.clepsyTeal)
                .rotationEffect(.degrees(lockOpen ? -12 : 0))
                .scaleEffect(lockOpen ? 1.1 : 1)
                .transition(.scale.combined(with: .opacity))
        default:
            if phase >= .ready { unlockButton.transition(.move(edge: .bottom).combined(with: .opacity)) }
        }
    }

    private var unlockButton: some View {
        Button(action: unlock) {
            HStack(spacing: 8) {
                Image(systemName: "lock.open.fill")
                Text("Unlock my apps")
            }
            .font(.system(size: 19, weight: .bold, design: .rounded))
            .foregroundColor(.clepsyMidnight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: [Color(hex: "FFD88A"), .clepsyGold, .clepsyOrange],
                               startPoint: .leading, endPoint: .trailing)
            )
            .overlay(
                // A light sweep that invites the tap
                LinearGradient(colors: [.clear, .white.opacity(0.45), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 90)
                    .offset(x: shimmer * 220)
                    .allowsHitTesting(false)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .clepsyGold.opacity(0.45), radius: 18, y: 6)
        }
        .buttonStyle(PressScaleStyle())
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false).delay(0.4)) {
                shimmer = 1
            }
        }
    }

    private func offerCard(_ offer: Int) -> some View {
        VStack(spacing: ClepsySpacing.sm) {
            Text("You've hit \(celebration.goal) min three days running.")
                .font(.clepsySubheadline)
                .foregroundColor(.clepsyTextSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                Text(phase == .offerAccepted ? "New goal:" : "Ready for")
                Text("\(shownOfferGoal) min")
                    .contentTransition(.numericText())
                    .foregroundColor(.clepsyGold)
                if phase != .offerAccepted { Text("?") }
            }
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundColor(.clepsyTextPrimary)

            if phase == .offer {
                Button("Let's go") { acceptOffer(offer) }
                    .buttonStyle(.clepsyPrimary)
                Button("Not yet") { declineOffer() }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.clepsyTextSecondary)
                    .padding(.vertical, 6)
            } else {
                Text("Starting tomorrow.")
                    .font(.clepsySubheadline)
                    .foregroundColor(.clepsyTextSecondary)
            }
        }
        .padding(ClepsySpacing.md)
        .background(Color.clepsySurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Sequence

    private func start() {
        if reduceMotion {
            fill = 1
            characterScale = 1
            shownStreak = celebration.streakAfter
            visibleBadges = celebration.newBadges.count
            withAnimation(.easeInOut(duration: 0.4)) {
                glow = true
                phase = .ready
            }
            HapticsService.shared.heavyPop()
            return
        }

        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) { raysAngle = 360 }

        sequence = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.4)) { glow = true }
            guard await pause(0.2) else { return }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { characterScale = 1 }
            HapticsService.shared.soft()
            guard await pause(0.3) else { return }

            phase = .pouring
            HapticsService.shared.rampSandPour(duration: 1.2)
            for level in [0.7, 0.85, 1.0] {
                withAnimation(.easeInOut(duration: 0.35)) { fill = level }
                guard await pause(0.4) else { return }
            }

            pop()
            guard await pause(0.2) else { return }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { phase = .titled }
            guard await pause(0.3) else { return }

            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { phase = .streak }
            guard await pause(0.15) else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { shownStreak = celebration.streakAfter }
            HapticsService.shared.light()
            guard await pause(0.3) else { return }

            phase = .badges
            for index in celebration.newBadges.indices {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) { visibleBadges = index + 1 }
                HapticsService.shared.selection()
                guard await pause(0.15) else { return }
            }
            guard await pause(0.2) else { return }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { phase = .ready }
        }
    }

    private func pop() {
        HapticsService.shared.stop()
        HapticsService.shared.heavyPop()
        confetti += 1
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            phase = .popped
            popScale = 1.12
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15)) { popScale = 1 }
    }

    private func skipToReady() {
        sequence?.cancel()
        HapticsService.shared.stop()
        if phase < .popped { confetti += 1 }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            glow = true
            characterScale = 1
            popScale = 1
            fill = 1
            shownStreak = celebration.streakAfter
            visibleBadges = celebration.newBadges.count
            phase = .ready
        }
    }

    private func unlock() {
        store.claim()
        HapticsService.shared.success()
        if !reduceMotion { confetti += 1 }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { phase = .unlocked }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.2)) { lockOpen = true }

        sequence = Task { @MainActor in
            guard await pause(1.5) else { return }
            if celebration.offerGoal != nil {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { phase = .offer }
            } else {
                store.finishCelebration()
            }
        }
    }

    private func acceptOffer(_ offer: Int) {
        store.acceptOffer()
        HapticsService.shared.success()
        if !reduceMotion { confetti += 1 }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            phase = .offerAccepted
            shownOfferGoal = offer
        }
        sequence = Task { @MainActor in
            guard await pause(1.4) else { return }
            store.finishCelebration()
        }
    }

    private func declineOffer() {
        store.declineOffer()
        store.finishCelebration()
    }

    /// Sleeps; false when the sequence was cancelled (skip, dismiss)
    private func pause(_ seconds: Double) async -> Bool {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        return !Task.isCancelled
    }
}

/// Buttons that sink slightly under the finger
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
