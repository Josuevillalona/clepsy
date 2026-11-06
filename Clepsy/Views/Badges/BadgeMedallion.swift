import SwiftUI

/// Placeholder badge art until the badges are designed: a medallion with
/// the badge's symbol, gold when earned, a quiet silhouette when not.
struct BadgeMedallion: View {
    let badge: BadgeID
    let earned: Bool
    var size: CGFloat = 72
    /// A light sweep across the face, for detail views and fresh unlocks
    var shines = false

    @State private var shineOffset: CGFloat = -1.2

    var body: some View {
        ZStack {
            Circle()
                .fill(earned ? AnyShapeStyle(earnedFill) : AnyShapeStyle(Color.clepsySurface))
            Circle()
                .strokeBorder(
                    earned ? Color(hex: "FFE2A8").opacity(0.9) : Color.clepsyTextSecondary.opacity(0.18),
                    lineWidth: size * 0.05
                )
            Circle()
                .strokeBorder(Color.black.opacity(earned ? 0.12 : 0), lineWidth: 1)
                .padding(size * 0.1)

            Image(systemName: badge.symbol)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(earned ? .white : .clepsyTextSecondary.opacity(0.35))
                .shadow(color: .black.opacity(earned ? 0.2 : 0), radius: 2, y: 1)

            if !earned {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.16, weight: .bold))
                    .foregroundColor(.clepsyTextSecondary.opacity(0.6))
                    .padding(size * 0.06)
                    .background(Circle().fill(Color.clepsyMidnight))
                    .offset(x: size * 0.32, y: size * 0.32)
            }

            if earned && shines {
                LinearGradient(colors: [.clear, .white.opacity(0.55), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: size * 0.45)
                    .rotationEffect(.degrees(20))
                    .offset(x: shineOffset * size)
                    .mask(Circle())
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.4).delay(0.3).repeatForever(autoreverses: false)) {
                            shineOffset = 1.2
                        }
                    }
            }
        }
        .frame(width: size, height: size)
        .shadow(color: earned ? Color.clepsyGold.opacity(0.35) : .clear, radius: size * 0.12, y: size * 0.04)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(badge.title), \(earned ? "earned" : "locked")")
    }

    private var earnedFill: LinearGradient {
        LinearGradient(colors: [Color(hex: "FFC56E"), .clepsyGold, .clepsyOrange],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
