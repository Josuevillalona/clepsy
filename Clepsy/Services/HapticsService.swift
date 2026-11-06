import CoreHaptics
import UIKit

/// Every haptic in Clepsy, each with one meaning (Apple HIG: consistent,
/// short, optional):
/// - `selection`: a value snapped to a new step or band
/// - `soft` / `light`: something arrived on screen
/// - `heavyPop`: the goal-hit moment
/// - `success`: an unlock or an accepted step up
/// - `rampSandPour`: the hourglass filling on the claim screen
/// All are silent when the Haptics setting is off.
@MainActor
final class HapticsService {
    static let shared = HapticsService()

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private var engine: CHHapticEngine?
    private var rampPlayer: CHHapticAdvancedPatternPlayer?

    private let shared = SharedStorageService()
    private var enabled: Bool { shared.hapticsEnabled }
    private var supportsCustom: Bool { CHHapticEngine.capabilitiesForHardware().supportsHaptics }

    func selection() {
        guard enabled else { return }
        selectionGenerator.selectionChanged()
    }

    func soft() { impact(.soft) }

    func light() { impact(.light) }

    func heavyPop() {
        guard enabled else { return }
        // A sharp transient reads as a "pop" better than a heavy impact
        if !playTransient(intensity: 1.0, sharpness: 0.8) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }

    func success() {
        guard enabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }

    /// A continuous rumble that swells with the sand, matched to the pour's
    /// duration so the feel tracks what you see
    func rampSandPour(duration: TimeInterval) {
        guard enabled, supportsCustom, let engine = startEngine() else { return }
        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
                ],
                relativeTime: 0,
                duration: duration
            )
            let swell = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0, value: 0.25),
                    .init(relativeTime: duration * 0.7, value: 0.8),
                    .init(relativeTime: duration, value: 1.0)
                ],
                relativeTime: 0
            )
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [swell])
            rampPlayer = try engine.makeAdvancedPlayer(with: pattern)
            try rampPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Haptics: sand pour failed: \(error)")
        }
    }

    func stop() {
        try? rampPlayer?.stop(atTime: CHHapticTimeImmediate)
        rampPlayer = nil
    }

    // MARK: - Private

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func playTransient(intensity: Float, sharpness: Float) -> Bool {
        guard supportsCustom, let engine = startEngine() else { return false }
        do {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            try engine.makePlayer(with: CHHapticPattern(events: [event], parameters: [])).start(atTime: 0)
            return true
        } catch {
            return false
        }
    }

    private func startEngine() -> CHHapticEngine? {
        if let engine { return engine }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            // The system stops the engine when the app backgrounds; drop it so
            // the next haptic builds a fresh one
            engine.stoppedHandler = { [weak self] _ in
                Task { @MainActor in self?.engine = nil }
            }
            try engine.start()
            self.engine = engine
            return engine
        } catch {
            return nil
        }
    }
}
