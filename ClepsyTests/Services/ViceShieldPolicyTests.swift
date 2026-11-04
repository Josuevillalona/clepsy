import XCTest
@testable import Clepsy

final class ViceShieldPolicyTests: XCTestCase {

    func testApplyBlocksSkipsWhenUnlockedToday() {
        XCTAssertFalse(ViceShieldPolicy.shouldShield(today: "2026-11-04", unlockedDay: "2026-11-04"))
    }

    func testShieldsWhenUnlockedYesterday() {
        XCTAssertTrue(ViceShieldPolicy.shouldShield(today: "2026-11-04", unlockedDay: "2026-11-03"))
    }

    func testShieldsWhenNeverUnlocked() {
        XCTAssertTrue(ViceShieldPolicy.shouldShield(today: "2026-11-04", unlockedDay: nil))
    }
}
