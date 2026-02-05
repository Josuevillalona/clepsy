import Foundation

class EarningSessionManager {
    private var currentSessionId: UUID?
    private var currentSessionStartTime: Date?
    private var currentSessionPausedTime: TimeInterval = 0
    private var currentAppBundleId: String?
    private var lastEarningsReported: Int = 0
    private var warmupExpired = false
    private var pauseStartTime: Date?
    private var lastBalanceUpdateTime: Date?

    // Callback for balance updates (every 5 minutes or session end)
    var onBalanceUpdate: ((Int) -> Void)?

    // Configuration
    private let warmupDuration: TimeInterval = 60      // 60 seconds
    private let pauseTimeoutDuration: TimeInterval = 120  // 2 minutes
    private let balanceUpdateInterval: Int = 300       // 5 minutes in seconds

    // MARK: - Public Read-Only State

    var isSessionActive: Bool {
        currentSessionId != nil
    }

    var isPaused: Bool {
        pauseStartTime != nil
    }

    var currentAppId: String? {
        currentAppBundleId
    }

    // MARK: - Public Interface

    func startSession(for appBundleId: String) {
        currentSessionId = UUID()
        currentAppBundleId = appBundleId
        currentSessionStartTime = Date()
        currentSessionPausedTime = 0
        warmupExpired = false
        lastEarningsReported = 0
        lastBalanceUpdateTime = Date()
        pauseStartTime = nil
        print("Earning session started for \(appBundleId)")
    }

    func pauseSession() {
        guard currentSessionId != nil, pauseStartTime == nil else { return }
        pauseStartTime = Date()
        print("Session paused")
    }

    func resumeSession() {
        guard let pauseStart = pauseStartTime else { return }

        let pausedDuration = Date().timeIntervalSince(pauseStart)

        if pausedDuration > pauseTimeoutDuration {
            // Pause was too long, session ends
            print("Pause exceeded 2 minutes, session will end")
            _ = endSession()
        } else {
            // Brief pause, add to total paused time
            currentSessionPausedTime += pausedDuration
            pauseStartTime = nil
            print("Session resumed (paused for \(Int(pausedDuration))s)")
        }
    }

    @discardableResult
    func endSession() -> Bool {
        guard currentSessionId != nil else { return false }

        // Credit any remaining earnings
        let finalEarnings = calculateEarnings()
        if finalEarnings > lastEarningsReported {
            onBalanceUpdate?(finalEarnings)
        }

        print("Session ended with \(finalEarnings) seconds earned")

        // Reset state
        currentSessionId = nil
        currentAppBundleId = nil
        currentSessionStartTime = nil
        currentSessionPausedTime = 0
        warmupExpired = false
        lastEarningsReported = 0
        pauseStartTime = nil

        return true
    }

    /// Current session earnings in seconds (triggers balance updates at 5-min intervals)
    var currentSessionEarnings: Int {
        guard currentSessionId != nil else { return 0 }

        let totalEarnings = calculateEarnings()

        // Check if we should send balance update (every 5 minutes)
        let minutesEarned = totalEarnings / 60
        let lastMinutesReported = lastEarningsReported / 60
        let minutesSinceLastUpdate = minutesEarned - lastMinutesReported

        if minutesSinceLastUpdate >= 5 {
            let updateAmount = (minutesSinceLastUpdate / 5) * 5 * 60  // Round to 5-min chunks
            lastEarningsReported += updateAmount
            lastBalanceUpdateTime = Date()
            onBalanceUpdate?(lastEarningsReported)
        }

        return totalEarnings
    }

    // MARK: - Private Helpers

    private func calculateEarnings() -> Int {
        guard let startTime = currentSessionStartTime else { return 0 }

        // If currently paused, don't count current pause time
        var totalPausedTime = currentSessionPausedTime
        if let pauseStart = pauseStartTime {
            totalPausedTime += Date().timeIntervalSince(pauseStart)
        }

        let elapsed = Date().timeIntervalSince(startTime) - totalPausedTime

        // Warmup: first 60 seconds don't count
        guard elapsed > warmupDuration else { return 0 }

        if !warmupExpired {
            warmupExpired = true
            print("Warmup complete, tracking started")
        }

        // Earning time = (elapsed - warmup) in seconds
        let earnedSeconds = Int(elapsed - warmupDuration)
        return max(0, earnedSeconds)
    }

    // MARK: - Testing Support

    #if DEBUG
    /// For testing: simulate time passing by adjusting the start time
    func simulateElapsedTime(seconds: TimeInterval) {
        if let startTime = currentSessionStartTime {
            currentSessionStartTime = startTime.addingTimeInterval(-seconds)
        }
        if let pauseStart = pauseStartTime {
            pauseStartTime = pauseStart.addingTimeInterval(-seconds)
        }
    }

    /// For testing: reset all state
    func reset() {
        currentSessionId = nil
        currentAppBundleId = nil
        currentSessionStartTime = nil
        currentSessionPausedTime = 0
        warmupExpired = false
        lastEarningsReported = 0
        pauseStartTime = nil
        lastBalanceUpdateTime = nil
        onBalanceUpdate = nil
    }
    #endif
}
