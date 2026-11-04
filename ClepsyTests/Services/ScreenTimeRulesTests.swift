import XCTest
@testable import Clepsy

final class SessionRulesTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
    }

    private func date(_ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 3, hour: hour, minute: minute))!
    }

    // MARK: - Metering window

    func testWindowStartsNowNotMidnight() {
        let now = date(14, 30)
        XCTAssertEqual(SessionRules.meteringWindow(startingAt: now, calendar: calendar).start, now)
    }

    func testWindowRunsToEndOfDay() {
        let window = SessionRules.meteringWindow(startingAt: date(14, 30), calendar: calendar)
        XCTAssertEqual(window.end, date(23, 59))
    }

    func testWindowNearMidnightStretchesPastFifteenMinutes() {
        // 23:50 → 23:59 would be a 9-minute schedule, which DeviceActivity rejects
        let now = date(23, 50)
        let window = SessionRules.meteringWindow(startingAt: now, calendar: calendar)
        XCTAssertEqual(window.end, now.addingTimeInterval(16 * 60))
        XCTAssertGreaterThanOrEqual(window.duration, SessionRules.minimumIntervalSeconds)
    }

    // MARK: - Interval end

    func testIntervalEndFromRestartIsIgnored() {
        // Stopping the previous session's monitoring lands hours before the
        // new session's scheduled end — the bug that ended sessions instantly
        let scheduledEnd = date(23, 59)
        XCTAssertFalse(SessionRules.isRealIntervalEnd(now: date(14, 30), scheduledEnd: scheduledEnd))
    }

    func testIntervalEndAtScheduledEndIsReal() {
        let scheduledEnd = date(23, 59)
        XCTAssertTrue(SessionRules.isRealIntervalEnd(now: scheduledEnd, scheduledEnd: scheduledEnd))
    }

    func testIntervalEndWithinAMinuteOfScheduledEndIsReal() {
        let scheduledEnd = date(23, 59)
        XCTAssertTrue(SessionRules.isRealIntervalEnd(now: scheduledEnd.addingTimeInterval(-30), scheduledEnd: scheduledEnd))
    }

    func testIntervalEndWithNoRecordedEndIsReal() {
        XCTAssertTrue(SessionRules.isRealIntervalEnd(now: date(14, 30), scheduledEnd: nil))
    }

    // MARK: - Vice minutes

    func testViceMinuteOutsideSessionIsIgnored() {
        XCTAssertEqual(SessionRules.viceMinuteOutcome(sessionActive: false, balanceSeconds: 600), .ignore)
    }

    func testViceMinuteWithBalanceLeftSpends() {
        XCTAssertEqual(SessionRules.viceMinuteOutcome(sessionActive: true, balanceSeconds: 180), .spend)
    }

    func testLastViceMinuteEndsSession() {
        XCTAssertEqual(SessionRules.viceMinuteOutcome(sessionActive: true, balanceSeconds: 60), .spendAndEndSession)
    }

    func testViceMinuteAtZeroBalanceEndsSession() {
        XCTAssertEqual(SessionRules.viceMinuteOutcome(sessionActive: true, balanceSeconds: 0), .spendAndEndSession)
    }
}

final class ShieldRulesTests: XCTestCase {

    // MARK: - Content

    func testContentWithBalanceOffersUnlock() {
        let content = ShieldRules.content(appName: "Instagram", availableMinutes: 4)
        XCTAssertEqual(content.title, "Instagram is blocked")
        XCTAssertTrue(content.subtitle.contains("4 min"))
        XCTAssertEqual(content.primaryButton, "Use My Time")
        XCTAssertEqual(content.secondaryButton, "Go Back")
    }

    func testContentAtZeroOffersOnlyGoBack() {
        let content = ShieldRules.content(appName: "Instagram", availableMinutes: 0)
        XCTAssertEqual(content.primaryButton, "Go Back")
        XCTAssertNil(content.secondaryButton)
        XCTAssertFalse(content.subtitle.contains("min."))
    }

    func testContentWithoutAppNameUsesGenericTitle() {
        XCTAssertEqual(ShieldRules.content(appName: nil, availableMinutes: 0).title, "This app is blocked")
    }

    // MARK: - Primary tap

    func testTapWithBalanceStartsSession() {
        XCTAssertEqual(ShieldRules.primaryTap(availableMinutes: 3, screenShowedBalance: true), .startSession)
    }

    func testTapAtZeroOnStaleUnlockScreenAsksForRedraw() {
        XCTAssertEqual(ShieldRules.primaryTap(availableMinutes: 0, screenShowedBalance: true), .redrawStaleScreen)
    }

    func testTapAtZeroOnFreshScreenCloses() {
        XCTAssertEqual(ShieldRules.primaryTap(availableMinutes: 0, screenShowedBalance: false), .close)
    }

    func testTapAtZeroWithNoRecordCloses() {
        XCTAssertEqual(ShieldRules.primaryTap(availableMinutes: 0, screenShowedBalance: nil), .close)
    }
}
