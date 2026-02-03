import XCTest
@testable import Clepsy

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    var sut: OnboardingViewModel!
    var mockPersistence: PersistenceService!
    var mockScreenTime: ScreenTimeService!

    override func setUp() {
        super.setUp()
        mockPersistence = PersistenceService(suiteName: "test.onboarding")!
        mockScreenTime = ScreenTimeService()
        sut = OnboardingViewModel(
            persistenceService: mockPersistence,
            screenTimeService: mockScreenTime
        )
    }

    override func tearDown() {
        mockPersistence.clearAll()
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(sut.currentStep, 0)
        XCTAssertFalse(sut.hasCompletedOnboarding)
    }

    func testNextStep() {
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, 1)
    }

    func testPreviousStep() {
        sut.nextStep()
        sut.nextStep()
        XCTAssertEqual(sut.currentStep, 2)

        sut.previousStep()
        XCTAssertEqual(sut.currentStep, 1)
    }

    func testCannotGoBeforeFirstStep() {
        sut.previousStep()
        XCTAssertEqual(sut.currentStep, 0)
    }

    func testCompleteOnboarding() {
        sut.completeOnboarding()
        XCTAssertTrue(sut.hasCompletedOnboarding)

        let settings = mockPersistence.loadUserSettings()
        XCTAssertTrue(settings.hasCompletedOnboarding)
    }
}
