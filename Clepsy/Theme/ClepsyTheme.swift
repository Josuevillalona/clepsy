import SwiftUI

// MARK: - Clepsy Brand Colors

extension Color {
    // Primary Colors
    static let clepsyMidnight = Color(hex: "1E2A3A")   // Primary background
    static let clepsySurface = Color(hex: "2A3B4D")    // Cards, elevated elements
    static let clepsyGold = Color(hex: "F4A259")       // Primary accent, CTAs, sand
    static let clepsyBrown = Color(hex: "8B6F47")      // Character frame, warm accents

    // Functional Colors
    static let clepsyTeal = Color(hex: "4ECDC4")       // Success, earning indicators
    static let clepsyOrange = Color(hex: "FF8C42")     // Spending, low balance, alerts

    // Text Colors
    static let clepsyTextPrimary = Color(hex: "F9F6F0")
    static let clepsyTextSecondary = Color(hex: "D4CFC4")

    // Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Clepsy Typography

extension Font {
    static let clepsyLargeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
    static let clepsyTitle = Font.system(.title, design: .default, weight: .bold)
    static let clepsyTitle2 = Font.system(.title2, design: .default, weight: .semibold)
    static let clepsyHeadline = Font.system(.headline, design: .default, weight: .semibold)
    static let clepsyBody = Font.system(.body, design: .default)
    static let clepsyCTA = Font.system(.body, design: .rounded, weight: .semibold)
    static let clepsySubheadline = Font.system(.subheadline, design: .default)
    static let clepsyCaption = Font.system(.caption, design: .default)
}

// MARK: - Clepsy Spacing

enum ClepsySpacing {
    static let xs: CGFloat = 8    // Tight spacing
    static let sm: CGFloat = 16   // Standard spacing
    static let md: CGFloat = 24   // Section spacing, card padding
    static let lg: CGFloat = 32   // Large spacing, screen margins
    static let xl: CGFloat = 40   // Extra large spacing
    static let xxl: CGFloat = 48  // Maximum spacing
}

// MARK: - Clepsy Card Style

struct ClepsyCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(ClepsySpacing.md)
            .background(Color.clepsySurface)
            .cornerRadius(16)
    }
}

extension View {
    func clepsyCard() -> some View {
        modifier(ClepsyCardStyle())
    }
}

// MARK: - Clepsy Button Styles

struct ClepsyPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.clepsyCTA)
            .foregroundColor(.clepsyMidnight)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.clepsyGold)
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ClepsySecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.clepsyCTA)
            .foregroundColor(.clepsyGold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.clepsySurface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.clepsyGold.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ClepsyPrimaryButtonStyle {
    static var clepsyPrimary: ClepsyPrimaryButtonStyle { ClepsyPrimaryButtonStyle() }
}

extension ButtonStyle where Self == ClepsySecondaryButtonStyle {
    static var clepsySecondary: ClepsySecondaryButtonStyle { ClepsySecondaryButtonStyle() }
}
