import SwiftUI

/// Two steps: pick a mode, then pick the minutes. Used as the last step of
/// onboarding and from Settings.
struct GoalSetupView: View {
    enum Choice { case fixed, buildUp }

    let onBack: (() -> Void)?
    let doneTitle: String
    let onDone: (GoalMode, Int) -> Void

    @State private var step = 0
    @State private var choice: Choice
    @State private var fixedGoal: Int
    @State private var start: Int
    @State private var target: Int

    init(plan: GoalPlan = .default, doneTitle: String = "Continue",
         onBack: (() -> Void)? = nil, onDone: @escaping (GoalMode, Int) -> Void) {
        self.onBack = onBack
        self.doneTitle = doneTitle
        self.onDone = onDone
        switch plan.mode {
        case .fixed:
            _choice = State(initialValue: .fixed)
            _fixedGoal = State(initialValue: plan.currentGoal)
            _start = State(initialValue: 10)
            _target = State(initialValue: max(plan.currentGoal, 30))
        case .buildUp(let target):
            _choice = State(initialValue: .buildUp)
            _fixedGoal = State(initialValue: target)
            _start = State(initialValue: plan.currentGoal)
            _target = State(initialValue: target)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if step == 1 || onBack != nil {
                    Button {
                        if step == 1 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { step = 0 }
                        } else {
                            onBack?()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.clepsyGold)
                            .frame(width: 44, height: 44, alignment: .leading)
                    }
                    .accessibilityLabel("Back")
                }
                Spacer()
            }
            .padding(.horizontal, ClepsySpacing.md)
            .padding(.top, ClepsySpacing.xs)

            ZStack {
                if step == 0 {
                    modeStep
                        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    minutesStep
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .trailing).combined(with: .opacity)))
                }
            }
            .frame(maxHeight: .infinity)

            Button {
                if step == 0 {
                    HapticsService.shared.light()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { step = 1 }
                } else {
                    HapticsService.shared.success()
                    switch choice {
                    case .fixed: onDone(.fixed, fixedGoal)
                    case .buildUp: onDone(.buildUp(target: target), start)
                    }
                }
            } label: {
                Text(step == 0 ? "Continue" : doneTitle)
            }
            .buttonStyle(.clepsyPrimary)
            .padding(.horizontal, ClepsySpacing.md)
            .padding(.bottom, ClepsySpacing.lg)
        }
        .background(Color.clepsyMidnight.ignoresSafeArea())
    }

    // MARK: - Step 1: Mode

    private var modeStep: some View {
        VStack(spacing: ClepsySpacing.sm) {
            Text("How do you want to start?")
                .font(.clepsyTitle)
                .foregroundColor(.clepsyTextPrimary)
                .multilineTextAlignment(.center)
            Text("Hit your goal in productive apps and your socials unlock for the rest of the day.")
                .font(.clepsySubheadline)
                .foregroundColor(.clepsyTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, ClepsySpacing.xs)

            ModeCard(
                symbol: "target",
                title: "Same goal every day",
                detail: "Pick your daily goal and keep it steady.",
                isSelected: choice == .fixed
            ) { select(.fixed) }

            ModeCard(
                symbol: "chart.line.uptrend.xyaxis",
                title: "Build up to it",
                detail: "Start small. Clepsy suggests going up as you get stronger.",
                isSelected: choice == .buildUp
            ) { select(.buildUp) }
        }
        .padding(.horizontal, ClepsySpacing.md)
    }

    private func select(_ newChoice: Choice) {
        guard newChoice != choice else { return }
        HapticsService.shared.selection()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { choice = newChoice }
    }

    // MARK: - Step 2: Minutes

    @ViewBuilder
    private var minutesStep: some View {
        VStack(spacing: ClepsySpacing.md) {
            switch choice {
            case .fixed:
                Text("Your daily goal")
                    .font(.clepsyTitle2)
                    .foregroundColor(.clepsyTextPrimary)
                GoalMinutesPicker(minutes: $fixedGoal, range: GoalRules.minutesRange)

            case .buildUp:
                Text("Build up to your goal")
                    .font(.clepsyTitle2)
                    .foregroundColor(.clepsyTextPrimary)
                VStack(spacing: ClepsySpacing.sm) {
                    labeled("Start at") {
                        GoalMinutesPicker(minutes: $start, range: GoalRules.startRange(), compact: true)
                    }
                    labeled("Build up to") {
                        GoalMinutesPicker(minutes: $target, range: GoalRules.targetRange(start: start), compact: true)
                    }
                }
                Text(estimateText)
                    .font(.clepsySubheadline)
                    .foregroundColor(.clepsyTextSecondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: estimateText)
            }
        }
        .padding(.horizontal, ClepsySpacing.md)
        .onChange(of: start) { newStart in
            // The target always stays at least one step above the start
            let range = GoalRules.targetRange(start: newStart)
            if target < range.lowerBound { target = range.lowerBound }
        }
    }

    private var estimateText: String {
        let days = GoalRules.estimatedDays(start: start, target: target)
        return "Starting at \(start) min, Clepsy will suggest +5 min when you're ready. About \(days) days to reach \(target)."
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(.clepsyTextSecondary)
            content()
        }
        .padding()
        .background(Color.clepsySurface)
        .cornerRadius(20)
    }
}

// MARK: - Mode Card

private struct ModeCard: View {
    let symbol: String
    let title: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ClepsySpacing.sm) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundColor(isSelected ? .clepsyMidnight : .clepsyGold)
                    .frame(width: 48, height: 48)
                    .background(isSelected ? Color.clepsyGold : Color.clepsyGold.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.clepsyHeadline)
                        .foregroundColor(.clepsyTextPrimary)
                    Text(detail)
                        .font(.clepsySubheadline)
                        .foregroundColor(.clepsyTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .clepsyGold : .clepsyTextSecondary.opacity(0.4))
            }
            .padding()
            .background(Color.clepsySurface)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clepsyGold : Color.clear, lineWidth: 2)
            )
            .cornerRadius(20)
            .scaleEffect(isSelected ? 1.0 : 0.98)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Minutes Picker

/// A 5-min-step slider with the number and its difficulty band. The band
/// label recolors and ticks a haptic as you cross into it.
struct GoalMinutesPicker: View {
    @Binding var minutes: Int
    let range: ClosedRange<Int>
    var compact = false

    var body: some View {
        let difficulty = GoalDifficulty.forMinutes(minutes)
        VStack(spacing: compact ? 8 : 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(GoalFormatting.minutes(minutes))
                    .font(.system(size: compact ? 34 : 64, weight: .bold, design: .rounded))
                    .foregroundColor(.clepsyTextPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: minutes)
                Spacer(minLength: 0).frame(maxWidth: compact ? .infinity : 0)
                DifficultyPill(difficulty: difficulty)
            }
            .frame(maxWidth: .infinity, alignment: compact ? .leading : .center)

            Slider(
                value: Binding(
                    get: { Double(minutes) },
                    set: {
                        let snapped = GoalRules.clamped(Int($0.rounded()))
                        // Tick only for the user's own drag, not for clamps
                        if snapped != minutes { HapticsService.shared.selection() }
                        minutes = snapped
                    }
                ),
                in: Double(range.lowerBound)...Double(max(range.upperBound, range.lowerBound + 1)),
                step: Double(GoalRules.step)
            )
            .tint(difficulty.color)
            .accessibilityValue("\(minutes) minutes, \(difficulty.title)")

            if !compact {
                Text(difficulty.blurb)
                    .font(.clepsySubheadline)
                    .foregroundColor(.clepsyTextSecondary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: difficulty)
            }
        }
        .onChange(of: range) { newRange in
            if !newRange.contains(minutes) { minutes = min(max(minutes, newRange.lowerBound), newRange.upperBound) }
        }
    }
}

struct DifficultyPill: View {
    let difficulty: GoalDifficulty

    var body: some View {
        Text(difficulty.title)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(difficulty.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(difficulty.color.opacity(0.16))
            .clipShape(Capsule())
            .id(difficulty)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: difficulty)
    }
}

extension GoalDifficulty {
    var color: Color {
        switch self {
        case .easy: return .clepsyTeal
        case .medium: return .clepsyGold
        case .hard: return .clepsyOrange
        case .intense: return Color(hex: "E85D75")
        }
    }

    var blurb: String {
        switch self {
        case .easy: return "A gentle start. Easy to keep every day."
        case .medium: return "A solid daily habit."
        case .hard: return "A real commitment. You'll feel it."
        case .intense: return "Serious dedication. Make sure it's what you want."
        }
    }
}

enum GoalFormatting {
    /// "45 min", "1h", "1h 30m"
    static func minutes(_ minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes) min" }
        let hours = minutes / 60, rest = minutes % 60
        return rest == 0 ? "\(hours)h" : "\(hours)h \(rest)m"
    }

    static func plan(_ plan: GoalPlan) -> String {
        switch plan.mode {
        case .fixed: return "Same goal · \(minutes(plan.currentGoal))"
        case .buildUp(let target): return "Build up · \(minutes(plan.currentGoal)) → \(minutes(target))"
        }
    }
}

#Preview {
    GoalSetupView { _, _ in }
}
