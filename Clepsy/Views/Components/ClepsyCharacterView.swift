import SwiftUI

struct ClepsyCharacterView: View {
    let balancePercentage: Double // 0.0 to 1.0
    let expression: ClepsyExpression

    @State private var animationOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Hourglass body with sand level
            HourglassBody(fillPercentage: balancePercentage)

            // Face expression overlay
            FaceExpression(expression: expression)
                .offset(y: -60)
        }
        .frame(width: 240, height: 320)
        .offset(y: animationOffset)
        .onAppear {
            startFloatingAnimation()
        }
    }

    private func startFloatingAnimation() {
        withAnimation(
            .easeInOut(duration: 3.5)
            .repeatForever(autoreverses: true)
        ) {
            animationOffset = 10
        }
    }
}

struct HourglassBody: View {
    let fillPercentage: Double

    var body: some View {
        ZStack(alignment: .bottom) {
            // Hourglass outline
            Image(systemName: "hourglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.purple.opacity(0.3))

            // Sand fill (simplified - actual implementation would use assets)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 320 * fillPercentage)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 60)
        }
    }
}

struct FaceExpression: View {
    let expression: ClepsyExpression

    var body: some View {
        HStack(spacing: 20) {
            // Eyes
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)

            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)
        }
        .overlay(alignment: .bottom) {
            // Mouth based on expression
            mouthShape
                .stroke(Color.black, lineWidth: 2)
                .frame(width: 40, height: 20)
                .offset(y: 30)
        }
    }

    @ViewBuilder
    private var mouthShape: some Shape {
        switch expression {
        case .patient:
            Capsule()
        case .encouraging:
            Arc(startAngle: .degrees(0), endAngle: .degrees(180))
        case .celebrating:
            Arc(startAngle: .degrees(0), endAngle: .degrees(180))
        }
    }
}

enum ClepsyExpression {
    case patient
    case encouraging
    case celebrating
}

struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

#Preview {
    VStack(spacing: 40) {
        ClepsyCharacterView(balancePercentage: 0.0, expression: .patient)
        ClepsyCharacterView(balancePercentage: 0.5, expression: .encouraging)
        ClepsyCharacterView(balancePercentage: 1.0, expression: .celebrating)
    }
}
