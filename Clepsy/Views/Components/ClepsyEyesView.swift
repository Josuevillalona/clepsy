import SwiftUI

/// Programmatic animated eyes for Clepsy (open eyes only)
struct ClepsyEyesView: View {
    @State private var isBlinking = false
    @State private var blinkTimer: Timer?
    @State private var lookOffset: CGSize = .zero

    var body: some View {
        HStack(spacing: 16) {
            singleEye
            singleEye
        }
        .onAppear {
            startBlinkTimer()
            startLookAnimation()
        }
        .onDisappear {
            blinkTimer?.invalidate()
        }
    }

    // MARK: - Single Eye

    private var singleEye: some View {
        ZStack {
            // Eye white
            Circle()
                .fill(Color.clepsyTextPrimary)
                .frame(width: 16, height: 16)
                .shadow(color: Color.clepsyMidnight.opacity(0.15), radius: 1, x: 0, y: 1)

            // Pupil
            Circle()
                .fill(Color.clepsyMidnight)
                .frame(width: 11, height: 11)
                .offset(x: lookOffset.width, y: lookOffset.height)

            // Reflection
            Circle()
                .fill(Color.clepsyTextPrimary)
                .frame(width: 3, height: 3)
                .offset(x: -1.5 + lookOffset.width * 0.3, y: -1.5 + lookOffset.height * 0.3)
        }
        .scaleEffect(y: isBlinking ? 0.1 : 1.0)
    }

    // MARK: - Blink Animation

    private func startBlinkTimer() {
        scheduleNextBlink()
    }

    private func scheduleNextBlink() {
        let delay = Double.random(in: 2.5...4.5)
        blinkTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            performBlink()
        }
    }

    private func performBlink() {
        withAnimation(.easeIn(duration: 0.07)) {
            isBlinking = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.07)) {
                isBlinking = false
            }
            scheduleNextBlink()
        }
    }

    // MARK: - Look Animation

    private func startLookAnimation() {
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                lookOffset = CGSize(
                    width: CGFloat.random(in: -1.5...1.5),
                    height: CGFloat.random(in: -1...1)
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    lookOffset = .zero
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Open Eyes") {
    ZStack {
        Color.clepsyGold.opacity(0.5)
        ClepsyEyesView()
            .scaleEffect(2)
    }
    .frame(width: 150, height: 100)
}
