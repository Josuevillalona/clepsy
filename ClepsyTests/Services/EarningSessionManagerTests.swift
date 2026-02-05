import XCTest
@testable import Clepsy

final class EarningSessionManagerTests: XCTestCase {
    var manager: EarningSessionManager!

    override func setUp() {
        super.setUp()
        manager = EarningSessionManager()
    }

    override func tearDown() {
        manager.reset()
        super.tearDown()
    }

    func testSessionStartsInactive() {
        XCTAssertFalse(manager.isSessionActive)
        XCTAssertNil(manager.currentAppId)
    }

    func testStartSessionActivatesSession() {
        manager.startSession(for: "com.amazon.Kindle")

        XCTAssertTrue(manager.isSessionActive)
        XCTAssertEqual(manager.currentAppId, "com.amazon.Kindle")
    }

    func testWarmupRequiredBeforeEarning() {
        // User opens productive app
        manager.startSession(for: "com.amazon.Kindle")

        // At 30 seconds: should not have earned time yet (still in warmup)
        manager.simulateElapsedTime(seconds: 30)
        XCTAssertEqual(manager.currentSessionEarnings, 0)

        // At 60 seconds: warmup just complete, 0 seconds of actual earning
        manager.simulateElapsedTime(seconds: 30)
        XCTAssertEqual(manager.currentSessionEarnings, 0)

        // At 70 seconds: 10 seconds of actual usage after warmup
        manager.simulateElapsedTime(seconds: 10)
        XCTAssertEqual(manager.currentSessionEarnings, 10)

        // At 120 seconds: 60 seconds of actual usage = 1 min earned
        manager.simulateElapsedTime(seconds: 50)
        XCTAssertEqual(manager.currentSessionEarnings, 60)
    }

    func testBriefInterruptionResumesSession() {
        // User in Kindle for 2 minutes after warmup
        manager.startSession(for: "com.amazon.Kindle")
        manager.simulateElapsedTime(seconds: 60) // Warmup
        manager.simulateElapsedTime(seconds: 120) // 2 min earning

        let earningsBeforePause = manager.currentSessionEarnings
        XCTAssertEqual(earningsBeforePause, 120) // 2 minutes

        // Brief interruption (30 seconds < 2 min timeout)
        manager.pauseSession()
        XCTAssertTrue(manager.isPaused)

        manager.simulateElapsedTime(seconds: 30)

        // Resume: session resumes without new warmup
        manager.resumeSession()
        XCTAssertFalse(manager.isPaused)
        XCTAssertTrue(manager.isSessionActive)

        // Continue earning
        manager.simulateElapsedTime(seconds: 60)
        XCTAssertEqual(manager.currentSessionEarnings, 180) // 3 minutes total
    }

    func testLongInterruptionEndsSession() {
        // User in Kindle for 2 minutes
        manager.startSession(for: "com.amazon.Kindle")
        manager.simulateElapsedTime(seconds: 60)  // Warmup
        manager.simulateElapsedTime(seconds: 120) // 2 min earning

        let earningsBeforePause = manager.currentSessionEarnings
        XCTAssertGreaterThan(earningsBeforePause, 0)

        // Long interruption (2.5 minutes > 2 min timeout)
        manager.pauseSession()
        manager.simulateElapsedTime(seconds: 150) // 2.5 minutes

        // Resume should end session due to timeout
        manager.resumeSession()

        // Session should have ended
        XCTAssertFalse(manager.isSessionActive)
    }

    func testEndSessionCreditsRemainingTime() {
        var receivedUpdate: Int?
        manager.onBalanceUpdate = { seconds in
            receivedUpdate = seconds
        }

        manager.startSession(for: "com.amazon.Kindle")
        manager.simulateElapsedTime(seconds: 60)  // Warmup
        manager.simulateElapsedTime(seconds: 120) // 2 min earning

        // End session
        let ended = manager.endSession()

        XCTAssertTrue(ended)
        XCTAssertFalse(manager.isSessionActive)
        XCTAssertNotNil(receivedUpdate)
        XCTAssertEqual(receivedUpdate, 120) // 2 minutes
    }

    func testBalanceUpdateEvery5Minutes() {
        var updatesReceived = [Int]()
        manager.onBalanceUpdate = { seconds in
            updatesReceived.append(seconds)
        }

        manager.startSession(for: "com.amazon.Kindle")
        manager.simulateElapsedTime(seconds: 60) // Warmup

        // Earn for 5 minutes - should trigger update
        manager.simulateElapsedTime(seconds: 300)
        _ = manager.currentSessionEarnings // Trigger check

        XCTAssertEqual(updatesReceived.count, 1)
        XCTAssertEqual(updatesReceived[0], 300) // 5 minutes

        // Earn for another 5 minutes - should trigger second update
        manager.simulateElapsedTime(seconds: 300)
        _ = manager.currentSessionEarnings

        XCTAssertEqual(updatesReceived.count, 2)
        XCTAssertEqual(updatesReceived[1], 600) // 10 minutes total

        // Earn 2 more minutes, then end session - should get final update
        manager.simulateElapsedTime(seconds: 120)
        manager.endSession()

        XCTAssertEqual(updatesReceived.count, 3)
        XCTAssertEqual(updatesReceived[2], 720) // 12 minutes total
    }

    func testNoEarningsWithoutSession() {
        XCTAssertEqual(manager.currentSessionEarnings, 0)
    }

    func testEndSessionWithoutActiveSessionReturnsFalse() {
        let ended = manager.endSession()
        XCTAssertFalse(ended)
    }

    func testNewSessionAfterEndRequiresWarmup() {
        // First session
        manager.startSession(for: "com.amazon.Kindle")
        manager.simulateElapsedTime(seconds: 120)
        manager.endSession()

        // New session
        manager.startSession(for: "com.amazon.Kindle")

        // Still in warmup
        manager.simulateElapsedTime(seconds: 30)
        XCTAssertEqual(manager.currentSessionEarnings, 0)
    }
}
