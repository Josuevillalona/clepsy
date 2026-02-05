import SwiftUI

struct ClepsyCharacterView: View {
    let balancePercentage: Double // 0.0 to 1.0
    let expression: ClepsyExpression

    @State private var animationOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            // Layer 1: The Body (Sand Level) - based on balance percentage
            Image(bodyImageName)
                .resizable()
                .scaledToFit()

            // Layer 2: The Face (Expression) - positioned in upper bulb
            Image(faceImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 145, height: 120)
                .offset(y: 40) // Position in upper bulb of hourglass
        }
        .frame(width: 240, height: 320)
        .offset(y: animationOffset)
        .onAppear {
            startFloatingAnimation()
        }
    }

    // MARK: - Asset Selection

    /// Select body image based on balance percentage
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

    /// Select face image based on expression
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

    // MARK: - Animation

    private func startFloatingAnimation() {
        withAnimation(
            .easeInOut(duration: 3.5)
            .repeatForever(autoreverses: true)
        ) {
            animationOffset = 10
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

#Preview("Empty (0%)") {
    ClepsyCharacterView(balancePercentage: 0.0, expression: .patient)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Quarter (25%)") {
    ClepsyCharacterView(balancePercentage: 0.25, expression: .patient)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Half (50%)") {
    ClepsyCharacterView(balancePercentage: 0.5, expression: .encouraging)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Three Quarters (75%)") {
    ClepsyCharacterView(balancePercentage: 0.75, expression: .encouraging)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Full (100%)") {
    ClepsyCharacterView(balancePercentage: 1.0, expression: .celebrating)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("All Expressions") {
    HStack(spacing: 20) {
        VStack {
            ClepsyCharacterView(balancePercentage: 0.5, expression: .patient)
                .scaleEffect(0.5)
            Text("Patient")
                .font(.caption)
        }
        VStack {
            ClepsyCharacterView(balancePercentage: 0.5, expression: .encouraging)
                .scaleEffect(0.5)
            Text("Encouraging")
                .font(.caption)
        }
        VStack {
            ClepsyCharacterView(balancePercentage: 0.5, expression: .celebrating)
                .scaleEffect(0.5)
            Text("Celebrating")
                .font(.caption)
        }
    }
    .padding()
}
