import SwiftUI

/// Where today stands, under the hero number. Ready-to-claim is the one
/// state that asks for a tap, so it's the only one drawn as a button.
struct StatusChip: View {
    let status: GoalStore.TodayStatus
    let onClaim: () -> Void

    @State private var pulse = false

    var body: some View {
        Group {
            switch status {
            case .locked(let minutesToGo):
                label("lock.fill", "Locked · \(minutesToGo) min to go", color: .clepsyTextSecondary)
            case .almostThere:
                label("hourglass", "Almost there…", color: .clepsyGold)
                    .opacity(pulse ? 1 : 0.6)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
                    }
            case .readyToClaim:
                Button(action: onClaim) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Goal hit · Claim your unlock")
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.clepsyMidnight)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(colors: [.clepsyGold, .clepsyOrange], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .clepsyGold.opacity(0.45), radius: pulse ? 14 : 6)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true }
                }
            case .unlocked:
                label("lock.open.fill", "Unlocked until midnight", color: .clepsyTeal)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: status)
    }

    private func label(_ symbol: String, _ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(text)
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundColor(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }
}
