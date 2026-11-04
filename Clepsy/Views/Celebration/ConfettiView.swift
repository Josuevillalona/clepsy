import SwiftUI

/// Bursts of confetti drawn on a Canvas. Each change of `trigger` fires a
/// new burst from `origin`. Seeded, so a given trigger always looks the same.
struct ConfettiView: View {
    let trigger: Int
    var origin = UnitPoint(x: 0.5, y: 0.38)
    var pieces = 90
    var palette: [Color] = [.clepsyGold, .clepsyTeal, .clepsyTextPrimary, .clepsyOrange, Color(hex: "FFD88A")]

    @State private var bursts: [Burst] = []

    private struct Burst: Identifiable {
        let id: Int
        let start: Date
    }

    private static let lifetime: TimeInterval = 2.2
    private static let gravity: Double = 1500
    private static let drag: Double = 2.2

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: bursts.isEmpty)) { timeline in
            Canvas { context, size in
                for burst in bursts {
                    draw(burst, at: timeline.date, in: &context, size: size)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { newValue in
            let burst = Burst(id: newValue, start: Date())
            bursts.append(burst)
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.lifetime) {
                bursts.removeAll { $0.id == burst.id }
            }
        }
    }

    private func draw(_ burst: Burst, at date: Date, in context: inout GraphicsContext, size: CGSize) {
        let t = date.timeIntervalSince(burst.start)
        guard t >= 0, t < Self.lifetime else { return }

        var rng = SeededRandom(seed: UInt64(truncatingIfNeeded: burst.id) &+ 0x9E37_79B9)
        let originPoint = CGPoint(x: origin.x * size.width, y: origin.y * size.height)
        // Velocity decays with drag: distance = v * (1 - e^(-kt)) / k
        let travel = (1 - exp(-Self.drag * t)) / Self.drag

        for _ in 0..<pieces {
            // Mostly upward fan, wider than tall
            let angle = -Double.pi / 2 + rng.next(in: -1.25...1.25)
            let speed = rng.next(in: 520...1150)
            let spin = rng.next(in: -9...9)
            let flutter = rng.next(in: 4...9)
            let width = rng.next(in: 6...11)
            let height = width * rng.next(in: 0.45...1.1)
            let color = palette[Int(rng.next(in: 0...Double(palette.count) - 0.001))]
            let isCircle = rng.next(in: 0...1) < 0.25

            let x = originPoint.x + cos(angle) * speed * travel + sin(t * flutter) * 8
            let y = originPoint.y + sin(angle) * speed * travel + 0.5 * Self.gravity * t * t * 0.55
            guard y < size.height + 20 else { continue }

            let fadeStart = Self.lifetime - 0.6
            let opacity = t < fadeStart ? 1 : max(0, 1 - (t - fadeStart) / 0.6)

            var piece = context
            piece.opacity = opacity
            piece.translateBy(x: x, y: y)
            piece.rotate(by: .radians(spin * t))
            // Squash on one axis to fake the tumble of a flat piece
            piece.scaleBy(x: 1, y: abs(cos(t * flutter)) * 0.8 + 0.2)

            let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
            let path = isCircle ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 1.5)
            piece.fill(path, with: .color(color))
        }
    }
}

/// SplitMix64: small, fast and deterministic
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func nextUInt() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        let unit = Double(nextUInt() >> 11) / Double(1 << 53)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
}
