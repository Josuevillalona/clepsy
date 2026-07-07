import SwiftUI

struct ClepsyCharacterView: View {
    let balancePercentage: Double // 0.0 to 1.0
    let expression: ClepsyExpression

    // Idle floating
    @State private var isFloating = false
    // Breathing pulse
    @State private var isBreathing = false
    // Expression-specific animation trigger
    @State private var expressionActive = false
    // Face micro-movement
    @State private var faceNod = false
    // Sparkle particles (celebrating)
    @State private var showSparkles = false

    var body: some View {
        ZStack(alignment: .top) {
            // Layer 1: The Body (Sand Level)
            Image(bodyImageName)
                .resizable()
                .scaledToFit()
                .scaleEffect(breathingScale)

            // Layer 2: The Face (Expression)
            if expression == .celebrating {
                // Celebrating uses full face image
                Image(faceImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 145, height: 120)
                    .offset(y: 40 + faceYOffset)
                    .scaleEffect(faceScale)
            } else {
                // Patient/Encouraging use programmatic eyes + mouth image
                programmaticFace
                    .scaleEffect(1.8)
                    .frame(width: 145, height: 120)
                    .offset(y: 50 + faceYOffset)
                    .scaleEffect(faceScale)
            }

            // Layer 3: Sparkle particles (celebrating only)
            if expression == .celebrating {
                sparkleParticles
            }
        }
        .frame(width: 240, height: 320)
        .offset(y: isFloating ? floatAmplitude : -floatAmplitude)
        .rotationEffect(.degrees(bodyRockDegrees))
        .onAppear {
            startAllAnimations()
        }
        .onChange(of: expression) { _ in
            restartExpressionAnimations()
        }
    }

    // MARK: - Expression-Driven Values

    /// Float amplitude varies by expression
    private var floatAmplitude: CGFloat {
        switch expression {
        case .patient: return 5
        case .encouraging: return 7
        case .celebrating: return 10
        }
    }

    /// Float duration varies by expression
    private var floatDuration: Double {
        switch expression {
        case .patient: return 4.0
        case .encouraging: return 3.0
        case .celebrating: return 1.8
        }
    }

    /// Body rock rotation
    private var bodyRockDegrees: Double {
        guard expressionActive else { return 0 }
        switch expression {
        case .patient: return 1.0
        case .encouraging: return 2.0
        case .celebrating: return 4.0
        }
    }

    /// Breathing scale
    private var breathingScale: CGFloat {
        guard isBreathing else { return 1.0 }
        switch expression {
        case .patient: return 1.015
        case .encouraging: return 1.02
        case .celebrating: return 1.03
        }
    }

    /// Face Y offset for nod/bounce
    private var faceYOffset: CGFloat {
        guard faceNod else { return 0 }
        switch expression {
        case .patient: return 1.5
        case .encouraging: return 3.0
        case .celebrating: return 5.0
        }
    }

    /// Face scale for bounce
    private var faceScale: CGFloat {
        guard expressionActive else { return 1.0 }
        switch expression {
        case .patient: return 1.0
        case .encouraging: return 1.0
        case .celebrating: return 1.05
        }
    }

    // MARK: - Animations

    private func startAllAnimations() {
        startFloating()
        startBreathing()
        startExpressionAnimation()
        startFaceNod()
        if expression == .celebrating {
            showSparkles = true
        }
    }

    private func startFloating() {
        withAnimation(
            .easeInOut(duration: floatDuration)
            .repeatForever(autoreverses: true)
        ) {
            isFloating = true
        }
    }

    private func startBreathing() {
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            isBreathing = true
        }
    }

    private func startExpressionAnimation() {
        let duration: Double = expression == .celebrating ? 0.8 : 2.5
        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
        ) {
            expressionActive = true
        }
    }

    private func startFaceNod() {
        let duration: Double
        switch expression {
        case .patient: duration = 3.5
        case .encouraging: duration = 2.0
        case .celebrating: duration = 0.6
        }
        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
        ) {
            faceNod = true
        }
    }

    private func restartExpressionAnimations() {
        // Reset states
        isFloating = false
        isBreathing = false
        expressionActive = false
        faceNod = false
        showSparkles = false

        // Restart after brief delay so reset takes effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            startAllAnimations()
        }
    }

    // MARK: - Sparkle Particles

    private var sparkleParticles: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                SparkleView(index: index, isAnimating: showSparkles)
            }
        }
        .frame(width: 240, height: 320)
    }

    // MARK: - Programmatic Face

    private var programmaticFace: some View {
        ZStack {
            // Eyes
            ClepsyEyesView()
                .offset(y: -5)

            // Mouth image
            Image(mouthImageName)
                .resizable()
                .scaledToFit()
                .frame(width: mouthWidth, height: mouthHeight)
                .offset(y: 0)
        }
        .frame(width: 100, height: 80)
    }

    private var mouthImageName: String {
        switch expression {
        case .patient:
            return "patience_mouth"
        case .encouraging, .celebrating:
            return "encouraging_mouth"
        }
    }

    private var mouthWidth: CGFloat {
        switch expression {
        case .patient:
            return 20
        case .encouraging, .celebrating:
            return 28
        }
    }

    private var mouthHeight: CGFloat {
        switch expression {
        case .patient:
            return 14
        case .encouraging, .celebrating:
            return 20
        }
    }

    // MARK: - Asset Selection

    private var bodyImageName: String {
        switch balancePercentage {
        case 0..<0.125:
            return "body_level_0"
        case 0.125..<0.375:
            return "body_level_25"
        case 0.375..<0.625:
            return "body_level_50"
        case 0.625..<0.875:
            return "body_level_75"
        default:
            return "body_level_100"
        }
    }

    private var faceImageName: String {
        switch expression {
        case .patient:
            return "patience_face"
        case .encouraging:
            return "encouraging_face"
        case .celebrating:
            return "celebrating_face"
        }
    }
}

// MARK: - Sparkle Particle

private struct SparkleView: View {
    let index: Int
    let isAnimating: Bool

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.3
    @State private var offset: CGSize = .zero

    private var baseAngle: Double {
        Double(index) * (360.0 / 6.0)
    }

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12))
            .foregroundColor(.clepsyGold)
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(offset)
            .onAppear {
                guard isAnimating else { return }
                let angle = baseAngle * .pi / 180
                let radius: CGFloat = 90 + CGFloat(index % 3) * 20
                let targetOffset = CGSize(
                    width: cos(angle) * radius,
                    height: sin(angle) * radius - 40
                )

                // Staggered start
                let delay = Double(index) * 0.2

                withAnimation(
                    .easeOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    opacity = 0.9
                    scale = 1.0
                    offset = targetOffset
                }
            }
    }
}

// MARK: - Expression Enum

enum ClepsyExpression {
    case patient      // Default, waiting, blocked states
    case encouraging  // Earning time, milestones
    case celebrating  // Goal met, streaks, achievements
}

// MARK: - Previews

#Preview("Patient - Empty") {
    ZStack {
        Color.clepsyMidnight.ignoresSafeArea()
        ClepsyCharacterView(balancePercentage: 0.0, expression: .patient)
            .scaleEffect(0.7)
    }
}

#Preview("Encouraging - Half") {
    ZStack {
        Color.clepsyMidnight.ignoresSafeArea()
        ClepsyCharacterView(balancePercentage: 0.5, expression: .encouraging)
            .scaleEffect(0.7)
    }
}

#Preview("Celebrating - Full") {
    ZStack {
        Color.clepsyMidnight.ignoresSafeArea()
        ClepsyCharacterView(balancePercentage: 1.0, expression: .celebrating)
            .scaleEffect(0.7)
    }
}

#Preview("All Expressions") {
    HStack(spacing: 20) {
        VStack {
            ClepsyCharacterView(balancePercentage: 0.2, expression: .patient)
                .scaleEffect(0.4)
            Text("Patient")
                .font(.caption)
                .foregroundColor(.clepsyTextPrimary)
        }
        VStack {
            ClepsyCharacterView(balancePercentage: 0.5, expression: .encouraging)
                .scaleEffect(0.4)
            Text("Encouraging")
                .font(.caption)
                .foregroundColor(.clepsyTextPrimary)
        }
        VStack {
            ClepsyCharacterView(balancePercentage: 1.0, expression: .celebrating)
                .scaleEffect(0.4)
            Text("Celebrating")
                .font(.caption)
                .foregroundColor(.clepsyTextPrimary)
        }
    }
    .padding()
    .background(Color.clepsyMidnight)
}
