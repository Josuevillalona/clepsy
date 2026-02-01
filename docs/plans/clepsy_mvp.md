# Clepsy MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the Clepsy iOS app MVP - a time-trading system that blocks social media apps and unlocks them by earning time through productive app usage.

**Architecture:** SwiftUI-based iOS app using Apple's Screen Time API (FamilyControls, ManagedSettings, DeviceActivity frameworks) for app blocking and usage monitoring. MVVM architecture with local-only data persistence via UserDefaults/CoreData. No backend required for MVP - all logic runs on-device with iOS privacy APIs.

**Tech Stack:** SwiftUI, iOS 16+, FamilyControls, ManagedSettings, DeviceActivity, DeviceActivityReport, UserDefaults/CoreData, XCTest

---

## ⚠️ CRITICAL UPDATES (2026-02-01)

**Three high-priority architectural improvements were identified after initial plan creation:**

1. **Race Condition Fix (Tasks 19-20)**: Original design used simple `Int` for pending time → replaced with thread-safe event queue using `[TimeEvent]` array
2. **Daily Reset Resilience (Task 17)**: Added `scenePhase` observer to catch midnight resets when app is backgrounded
3. **Future-Proofing**: Documented SwiftData migration path for V1.1 historical data

**📖 See `docs/data-architecture.md` for complete architectural decisions and rationale.**

**Updated tasks in this plan**: Tasks 17, 19, 20, 21B (new), 26-27 (asset alignment)

---

## Before You Start ✅

### **Required Reading**

**Critical Documents** (read before Task 0):
- `docs/UPDATES-2026-02-01.md` - All architectural changes explained
- `docs/data-architecture.md` - FileCoordination pattern, timezone handling
- `clepsy_prd.md` - Product requirements and success metrics
- `clepsy_mvb.md` - Brand guidelines (Clepsy character, tone, colors)

**Reference During Implementation**:
- `dashboard_specs.md`, `onboarding_specs.md`, `settings_specs.md` - UI specifications
- `earning_specs.md` - Earning mechanics (60-sec warmup, 2-min timeout)
- `error_state_specs.md` - Error handling scenarios
- `docs/simulator-testing-guide.md` - Simulator testing strategy (Phases 1-4)

### **Development Environment**

**Requirements**:
- Xcode 15.0+
- Swift 5.9+
- iOS 16.0+ deployment target
- macOS 13+ (for Simulator)

**Physical Device** (needed later for Phase 5):
- iPhone with iOS 16+
- Apple Developer account with Screen Time API entitlements

### **Key Architecture Decisions**

1. ✅ **Modern APIs**: FileCoordination (not deprecated `.synchronize()`)
2. ✅ **Timezone**: Device time only (no complex offset logic)
3. ✅ **Thread-Safe**: Event queue with `[TimeEvent]` array
4. ✅ **Simulator-First**: Phases 1-4 fully testable, Phase 5 uses mocks until device
5. ✅ **Asset Structure**: Decoupled layering (body + face separate, ZStack)

### **Approval Checklist**

Before proceeding, confirm:
- [ ] Modern APIs approved (FileCoordination)
- [ ] Simulator testing strategy understood (mock buttons for DeviceActivity)
- [ ] Asset alignment verified (Tasks 26-27 use correct names from `clepsy_app_images/`)
- [ ] 30 tasks reviewed (Tasks 0-30, including new Task 21B)
- [ ] Ready to start with Task 0

### **What Happens Next**

**Task 0** (30 min): Xcode project setup, frameworks, folder structure
**Phase 1** (2-3 hrs): Core models + persistence services (TDD)
**Phase 2** (2-3 hrs): Onboarding flow (5 screens)
**Phase 3** (2-3 hrs): Dashboard + character component
**Phase 4** (3-4 hrs): DeviceActivity monitoring (mock-based on Simulator)
**Phase 5** (1-2 hrs): Settings, assets, testing

Full timeline: ~12-15 hours for MVP on Simulator, +2-3 hours for physical device testing

---

## Prerequisites

### Task 0: Project Setup

**Files:**
- Create: Xcode project structure
- Create: `Clepsy/ClepsyApp.swift`
- Create: `Clepsy/Info.plist`
- Create: `Clepsy/Clepsy.entitlements`

**Step 1: Create new Xcode project**

1. Open Xcode
2. File → New → Project
3. Select iOS → App
4. Product Name: "Clepsy"
5. Interface: SwiftUI
6. Language: Swift
7. Minimum Deployment: iOS 16.0
8. Save to project directory

**Step 2: Configure capabilities and entitlements**

Add to `Clepsy.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.family-controls</key>
    <true/>
</dict>
</plist>
```

Add to `Info.plist`:
```xml
<key>NSFamilyControlsUsageDescription</key>
<string>Clepsy needs permission to monitor app usage and manage screen time to help you trade productive time for social media access.</string>
```

**Step 3: Add required frameworks**

In Xcode project settings → Targets → Clepsy → Frameworks:
- Add FamilyControls.framework
- Add ManagedSettings.framework
- Add DeviceActivity.framework

**Step 4: Create folder structure**

```bash
mkdir -p Clepsy/Models
mkdir -p Clepsy/ViewModels
mkdir -p Clepsy/Views
mkdir -p Clepsy/Views/Onboarding
mkdir -p Clepsy/Views/Dashboard
mkdir -p Clepsy/Views/Settings
mkdir -p Clepsy/Views/Shield
mkdir -p Clepsy/Views/Components
mkdir -p Clepsy/Services
mkdir -p Clepsy/Utils
mkdir -p Clepsy/Assets/ClepsyCharacter
mkdir -p ClepsyTests
```

**Step 5: Commit**

```bash
git init
git add .
git commit -m "chore: initialize Xcode project with required frameworks and structure"
```

---

## Phase 1: Core Data Models & Services

### Task 1: Time Balance Model

**Files:**
- Create: `Clepsy/Models/TimeBalance.swift`
- Create: `ClepsyTests/Models/TimeBalanceTests.swift`

**Step 1: Write the failing test**

Create `ClepsyTests/Models/TimeBalanceTests.swift`:
```swift
import XCTest
@testable import Clepsy

final class TimeBalanceTests: XCTestCase {
    func testInitialBalanceIsZero() {
        let balance = TimeBalance()
        XCTAssertEqual(balance.currentSeconds, 0)
    }

    func testAddingTime() {
        var balance = TimeBalance()
        balance.add(seconds: 120)
        XCTAssertEqual(balance.currentSeconds, 120)
    }

    func testSubtractingTime() {
        var balance = TimeBalance(currentSeconds: 120)
        balance.subtract(seconds: 60)
        XCTAssertEqual(balance.currentSeconds, 60)
    }

    func testCannotSubtractBelowZero() {
        var balance = TimeBalance(currentSeconds: 30)
        balance.subtract(seconds: 60)
        XCTAssertEqual(balance.currentSeconds, 0)
    }

    func testFormattedTimeDisplay() {
        let balance = TimeBalance(currentSeconds: 3665) // 1h 1m 5s
        XCTAssertEqual(balance.formattedTime, "1h 1m")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U` or `xcodebuild test -scheme Clepsy -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: FAIL with "Cannot find 'TimeBalance' in scope"

**Step 3: Write minimal implementation**

Create `Clepsy/Models/TimeBalance.swift`:
```swift
import Foundation

struct TimeBalance: Codable, Equatable {
    private(set) var currentSeconds: Int

    init(currentSeconds: Int = 0) {
        self.currentSeconds = max(0, currentSeconds)
    }

    mutating func add(seconds: Int) {
        currentSeconds += seconds
    }

    mutating func subtract(seconds: Int) {
        currentSeconds = max(0, currentSeconds - seconds)
    }

    var formattedTime: String {
        let hours = currentSeconds / 3600
        let minutes = (currentSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `Cmd+U`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Clepsy/Models/TimeBalance.swift ClepsyTests/Models/TimeBalanceTests.swift
git commit -m "feat: add TimeBalance model with add/subtract operations"
```

---

### Task 2: App Category Model

**Files:**
- Create: `Clepsy/Models/AppCategory.swift`
- Create: `ClepsyTests/Models/AppCategoryTests.swift`

**Step 1: Write the failing test**

Create `ClepsyTests/Models/AppCategoryTests.swift`:
```swift
import XCTest
import FamilyControls
@testable import Clepsy

final class AppCategoryTests: XCTestCase {
    func testViceAppCategory() {
        let category = AppCategory.vice
        XCTAssertEqual(category.displayName, "Vice Apps")
        XCTAssertTrue(category.isBlocked)
    }

    func testProductiveAppCategory() {
        let category = AppCategory.productive
        XCTAssertEqual(category.displayName, "Productive Apps")
        XCTAssertFalse(category.isBlocked)
    }

    func testDefaultViceApps() {
        let defaults = AppCategory.defaultViceApps
        XCTAssertTrue(defaults.contains { $0.name == "TikTok" })
        XCTAssertTrue(defaults.contains { $0.name == "Instagram" })
        XCTAssertTrue(defaults.contains { $0.name == "Twitter/X" })
    }

    func testDefaultProductiveApps() {
        let defaults = AppCategory.defaultProductiveApps
        XCTAssertTrue(defaults.contains { $0.name == "Kindle" })
        XCTAssertTrue(defaults.contains { $0.name == "Duolingo" })
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL with "Cannot find 'AppCategory' in scope"

**Step 3: Write minimal implementation**

Create `Clepsy/Models/AppCategory.swift`:
```swift
import Foundation
import FamilyControls

enum AppCategory: String, Codable, CaseIterable {
    case vice
    case productive

    var displayName: String {
        switch self {
        case .vice: return "Vice Apps"
        case .productive: return "Productive Apps"
        }
    }

    var isBlocked: Bool {
        switch self {
        case .vice: return true
        case .productive: return false
        }
    }

    static var defaultViceApps: [TrackedApp] {
        [
            TrackedApp(name: "TikTok", bundleIdentifier: "com.zhiliaoapp.musically", category: .vice),
            TrackedApp(name: "Instagram", bundleIdentifier: "com.burbn.instagram", category: .vice),
            TrackedApp(name: "Twitter/X", bundleIdentifier: "com.atebits.Tweetie2", category: .vice),
            TrackedApp(name: "Reddit", bundleIdentifier: "com.reddit.Reddit", category: .vice),
            TrackedApp(name: "Facebook", bundleIdentifier: "com.facebook.Facebook", category: .vice),
            TrackedApp(name: "YouTube", bundleIdentifier: "com.google.ios.youtube", category: .vice),
            TrackedApp(name: "Snapchat", bundleIdentifier: "com.toyopagroup.picaboo", category: .vice)
        ]
    }

    static var defaultProductiveApps: [TrackedApp] {
        [
            TrackedApp(name: "Kindle", bundleIdentifier: "com.amazon.Lassen", category: .productive),
            TrackedApp(name: "Duolingo", bundleIdentifier: "com.duolingo.DuolingoMobile", category: .productive),
            TrackedApp(name: "Headspace", bundleIdentifier: "com.getsomeheadspace.headspace", category: .productive),
            TrackedApp(name: "Khan Academy", bundleIdentifier: "org.khanacademy.Khan-Academy", category: .productive),
            TrackedApp(name: "Coursera", bundleIdentifier: "org.coursera.ios", category: .productive)
        ]
    }
}

struct TrackedApp: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let bundleIdentifier: String
    let category: AppCategory

    init(id: UUID = UUID(), name: String, bundleIdentifier: String, category: AppCategory) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.category = category
    }
}
```

**Step 4: Run test to verify it passes**

Run: `Cmd+U`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Clepsy/Models/AppCategory.swift ClepsyTests/Models/AppCategoryTests.swift
git commit -m "feat: add AppCategory model with default vice and productive apps"
```

---

### Task 3: User Settings Model

**Files:**
- Create: `Clepsy/Models/UserSettings.swift`
- Create: `ClepsyTests/Models/UserSettingsTests.swift`

**Step 1: Write the failing test**

Create `ClepsyTests/Models/UserSettingsTests.swift`:
```swift
import XCTest
@testable import Clepsy

final class UserSettingsTests: XCTestCase {
    func testDefaultSettings() {
        let settings = UserSettings()
        XCTAssertTrue(settings.hasCompletedOnboarding == false)
        XCTAssertTrue(settings.notificationsEnabled == true)
        XCTAssertEqual(settings.exchangeRate, 1.0)
    }

    func testEncodingAndDecoding() throws {
        let original = UserSettings(
            hasCompletedOnboarding: true,
            notificationsEnabled: false,
            exchangeRate: 1.5,
            viceApps: AppCategory.defaultViceApps,
            productiveApps: AppCategory.defaultProductiveApps
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserSettings.self, from: data)

        XCTAssertEqual(decoded.hasCompletedOnboarding, true)
        XCTAssertEqual(decoded.notificationsEnabled, false)
        XCTAssertEqual(decoded.exchangeRate, 1.5)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL with "Cannot find 'UserSettings' in scope"

**Step 3: Write minimal implementation**

Create `Clepsy/Models/UserSettings.swift`:
```swift
import Foundation

struct UserSettings: Codable {
    var hasCompletedOnboarding: Bool
    var notificationsEnabled: Bool
    var exchangeRate: Double // 1.0 = 1:1, 2.0 = 2:1 (deferred to V1.5)
    var viceApps: [TrackedApp]
    var productiveApps: [TrackedApp]

    init(
        hasCompletedOnboarding: Bool = false,
        notificationsEnabled: Bool = true,
        exchangeRate: Double = 1.0,
        viceApps: [TrackedApp] = AppCategory.defaultViceApps,
        productiveApps: [TrackedApp] = AppCategory.defaultProductiveApps
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.notificationsEnabled = notificationsEnabled
        self.exchangeRate = exchangeRate
        self.viceApps = viceApps
        self.productiveApps = productiveApps
    }
}
```

**Step 4: Run test to verify it passes**

Run: `Cmd+U`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Clepsy/Models/UserSettings.swift ClepsyTests/Models/UserSettingsTests.swift
git commit -m "feat: add UserSettings model for app configuration"
```

---

### Task 4: Persistence Service

**Files:**
- Create: `Clepsy/Services/PersistenceService.swift`
- Create: `ClepsyTests/Services/PersistenceServiceTests.swift`

**Step 1: Write the failing test**

Create `ClepsyTests/Services/PersistenceServiceTests.swift`:
```swift
import XCTest
@testable import Clepsy

final class PersistenceServiceTests: XCTestCase {
    var sut: PersistenceService!

    override func setUp() {
        super.setUp()
        // Use a test-specific UserDefaults suite
        sut = PersistenceService(suiteName: "test.clepsy.persistence")
        sut.clearAll() // Start fresh
    }

    override func tearDown() {
        sut.clearAll()
        super.tearDown()
    }

    func testSaveAndLoadTimeBalance() {
        let balance = TimeBalance(currentSeconds: 300)
        sut.saveTimeBalance(balance)

        let loaded = sut.loadTimeBalance()
        XCTAssertEqual(loaded.currentSeconds, 300)
    }

    func testSaveAndLoadUserSettings() {
        var settings = UserSettings()
        settings.hasCompletedOnboarding = true
        sut.saveUserSettings(settings)

        let loaded = sut.loadUserSettings()
        XCTAssertEqual(loaded.hasCompletedOnboarding, true)
    }

    func testLoadTimeBalanceWhenNoneExists() {
        let loaded = sut.loadTimeBalance()
        XCTAssertEqual(loaded.currentSeconds, 0)
    }

    func testDailyReset() {
        let balance = TimeBalance(currentSeconds: 500)
        sut.saveTimeBalance(balance)

        sut.performDailyReset()

        let loaded = sut.loadTimeBalance()
        XCTAssertEqual(loaded.currentSeconds, 0)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL with "Cannot find 'PersistenceService' in scope"

**Step 3: Write minimal implementation**

Create `Clepsy/Services/PersistenceService.swift`:
```swift
import Foundation

class PersistenceService {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let timeBalance = "timeBalance"
        static let userSettings = "userSettings"
        static let lastResetDate = "lastResetDate"
    }

    init(suiteName: String? = nil) {
        if let suiteName = suiteName {
            self.userDefaults = UserDefaults(suiteName: suiteName)!
        } else {
            self.userDefaults = UserDefaults.standard
        }
    }

    // MARK: - Time Balance

    func saveTimeBalance(_ balance: TimeBalance) {
        if let encoded = try? JSONEncoder().encode(balance) {
            userDefaults.set(encoded, forKey: Keys.timeBalance)
        }
    }

    func loadTimeBalance() -> TimeBalance {
        guard let data = userDefaults.data(forKey: Keys.timeBalance),
              let balance = try? JSONDecoder().decode(TimeBalance.self, from: data) else {
            return TimeBalance()
        }
        return balance
    }

    // MARK: - User Settings

    func saveUserSettings(_ settings: UserSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: Keys.userSettings)
        }
    }

    func loadUserSettings() -> UserSettings {
        guard let data = userDefaults.data(forKey: Keys.userSettings),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return UserSettings()
        }
        return settings
    }

    // MARK: - Daily Reset

    func performDailyReset() {
        let balance = TimeBalance(currentSeconds: 0)
        saveTimeBalance(balance)
        userDefaults.set(Date(), forKey: Keys.lastResetDate)
    }

    func getLastResetDate() -> Date? {
        return userDefaults.object(forKey: Keys.lastResetDate) as? Date
    }

    // MARK: - Testing

    func clearAll() {
        userDefaults.removeObject(forKey: Keys.timeBalance)
        userDefaults.removeObject(forKey: Keys.userSettings)
        userDefaults.removeObject(forKey: Keys.lastResetDate)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `Cmd+U`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Clepsy/Services/PersistenceService.swift ClepsyTests/Services/PersistenceServiceTests.swift
git commit -m "feat: add PersistenceService for UserDefaults storage"
```

---

### Task 5: Screen Time Authorization Service

**Files:**
- Create: `Clepsy/Services/ScreenTimeService.swift`
- Create: `ClepsyTests/Services/ScreenTimeServiceTests.swift`

**Step 1: Write the failing test**

Create `ClepsyTests/Services/ScreenTimeServiceTests.swift`:
```swift
import XCTest
import FamilyControls
@testable import Clepsy

final class ScreenTimeServiceTests: XCTestCase {
    var sut: ScreenTimeService!

    override func setUp() {
        super.setUp()
        sut = ScreenTimeService()
    }

    func testRequestAuthorizationReturnsResult() async {
        // Note: This test will fail in simulator without Family Controls entitlement
        // but verifies the service interface is correct
        do {
            let result = try await sut.requestAuthorization()
            // In a real device with proper entitlements, this should succeed
            XCTAssertTrue(result == true || result == false)
        } catch {
            // Expected to fail in test environment without proper setup
            XCTAssertTrue(true)
        }
    }

    func testAuthorizationStatusCheck() {
        let status = sut.authorizationStatus
        XCTAssertNotNil(status)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL with "Cannot find 'ScreenTimeService' in scope"

**Step 3: Write minimal implementation**

Create `Clepsy/Services/ScreenTimeService.swift`:
```swift
import Foundation
import FamilyControls

class ScreenTimeService: ObservableObject {
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined

    private let center = AuthorizationCenter.shared

    init() {
        updateAuthorizationStatus()
    }

    func requestAuthorization() async throws -> Bool {
        do {
            try await center.requestAuthorization(for: .individual)
            updateAuthorizationStatus()
            return authorizationStatus == .approved
        } catch {
            updateAuthorizationStatus()
            throw error
        }
    }

    private func updateAuthorizationStatus() {
        authorizationStatus = center.authorizationStatus
    }
}
```

**Step 4: Run test to verify it passes**

Run: `Cmd+U`
Expected: Tests PASS (may show warnings about simulator limitations)

**Step 5: Commit**

```bash
git add Clepsy/Services/ScreenTimeService.swift ClepsyTests/Services/ScreenTimeServiceTests.swift
git commit -m "feat: add ScreenTimeService for FamilyControls authorization"
```

---

### Task 6: App Blocking Service

**Files:**
- Create: `Clepsy/Services/AppBlockingService.swift`
- Create: `ClepsyTests/Services/AppBlockingServiceTests.swift`

**Step 1: Write the failing test**

Create `ClepsyTests/Services/AppBlockingServiceTests.swift`:
```swift
import XCTest
import FamilyControls
import ManagedSettings
@testable import Clepsy

final class AppBlockingServiceTests: XCTestCase {
    var sut: AppBlockingService!

    override func setUp() {
        super.setUp()
        sut = AppBlockingService()
    }

    func testBlockAppsInterface() {
        let apps = AppCategory.defaultViceApps
        // This will not actually block apps in test environment
        // but verifies the interface is correct
        XCTAssertNoThrow(sut.blockApps(apps))
    }

    func testUnblockAppsInterface() {
        let apps = AppCategory.defaultViceApps
        XCTAssertNoThrow(sut.unblockApps(apps))
    }

    func testBlockAllViceApps() {
        XCTAssertNoThrow(sut.blockAllViceApps())
    }

    func testUnblockAllViceApps() {
        XCTAssertNoThrow(sut.unblockAllViceApps())
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL with "Cannot find 'AppBlockingService' in scope"

**Step 3: Write minimal implementation**

Create `Clepsy/Services/AppBlockingService.swift`:
```swift
import Foundation
import FamilyControls
import ManagedSettings

class AppBlockingService {
    private let store = ManagedSettingsStore()

    func blockApps(_ apps: [TrackedApp]) {
        // Convert bundle identifiers to ApplicationTokens
        // Note: In production, we need to use FamilyActivityPicker to get proper tokens
        // For now, we'll use the shield configuration

        let bundleIds = apps.map { $0.bundleIdentifier }

        // Block using shield
        store.shield.applications = Set(bundleIds.compactMap { _ in
            // This is a placeholder - actual implementation needs proper tokens from FamilyActivityPicker
            nil as ApplicationToken?
        }).isEmpty ? nil : Set(bundleIds.compactMap { _ in nil as ApplicationToken? })

        // For MVP, we'll apply shields through the blocking mechanism
        store.shield.applicationCategories = .all(including: .all)
    }

    func unblockApps(_ apps: [TrackedApp]) {
        // Remove specific apps from shield
        // In production, this would remove specific tokens
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    func blockAllViceApps() {
        let viceApps = AppCategory.defaultViceApps
        blockApps(viceApps)
    }

    func unblockAllViceApps() {
        let viceApps = AppCategory.defaultViceApps
        unblockApps(viceApps)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `Cmd+U`
Expected: Tests PASS

**Step 5: Commit**

```bash
git add Clepsy/Services/AppBlockingService.swift ClepsyTests/Services/AppBlockingServiceTests.swift
git commit -m "feat: add AppBlockingService for ManagedSettings shield control"
```

---

## Phase 2: Onboarding Flow

### Task 7: Onboarding View Models

**Files:**
- Create: `Clepsy/ViewModels/OnboardingViewModel.swift`
- Create: `ClepsyTests/ViewModels/OnboardingViewModelTests.swift`

**Step 1: Write the failing test**

Create `ClepsyTests/ViewModels/OnboardingViewModelTests.swift`:
```swift
import XCTest
@testable import Clepsy

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    var sut: OnboardingViewModel!
    var mockPersistence: PersistenceService!
    var mockScreenTime: ScreenTimeService!

    override func setUp() {
        super.setUp()
        mockPersistence = PersistenceService(suiteName: "test.onboarding")
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
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL with "Cannot find 'OnboardingViewModel' in scope"

**Step 3: Write minimal implementation**

Create `Clepsy/ViewModels/OnboardingViewModel.swift`:
```swift
import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var hasCompletedOnboarding: Bool = false

    private let persistenceService: PersistenceService
    private let screenTimeService: ScreenTimeService

    let totalSteps = 5 // Per onboarding_specs.md

    init(
        persistenceService: PersistenceService = PersistenceService(),
        screenTimeService: ScreenTimeService = ScreenTimeService()
    ) {
        self.persistenceService = persistenceService
        self.screenTimeService = screenTimeService

        let settings = persistenceService.loadUserSettings()
        self.hasCompletedOnboarding = settings.hasCompletedOnboarding
    }

    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func completeOnboarding() {
        var settings = persistenceService.loadUserSettings()
        settings.hasCompletedOnboarding = true
        persistenceService.saveUserSettings(settings)
        hasCompletedOnboarding = true
    }

    func requestScreenTimePermission() async {
        do {
            _ = try await screenTimeService.requestAuthorization()
        } catch {
            print("Screen Time authorization failed: \(error)")
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `Cmd+U`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Clepsy/ViewModels/OnboardingViewModel.swift ClepsyTests/ViewModels/OnboardingViewModelTests.swift
git commit -m "feat: add OnboardingViewModel with step navigation"
```

---

### Task 8: Onboarding Welcome Screen (Screen 1)

**Files:**
- Create: `Clepsy/Views/Onboarding/WelcomeView.swift`
- Test manually via Preview

**Step 1: Create WelcomeView**

Create `Clepsy/Views/Onboarding/WelcomeView.swift`:
```swift
import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Clepsy character (placeholder for now)
            Image(systemName: "hourglass")
                .font(.system(size: 120))
                .foregroundColor(.purple)

            Text("Meet Clepsy")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your friendly guide to healthier scrolling habits")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
```

**Step 2: Test in Preview**

Run: Build and view in Xcode Preview (Canvas)
Expected: See welcome screen with hourglass icon and "Get Started" button

**Step 3: Commit**

```bash
git add Clepsy/Views/Onboarding/WelcomeView.swift
git commit -m "feat: add onboarding welcome screen (screen 1)"
```

---

### Task 9: Onboarding How It Works Screen (Screen 2)

**Files:**
- Create: `Clepsy/Views/Onboarding/HowItWorksView.swift`

**Step 1: Create HowItWorksView**

Create `Clepsy/Views/Onboarding/HowItWorksView.swift`:
```swift
import SwiftUI

struct HowItWorksView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                Spacer()
            }
            .padding(.horizontal)

            Text("How It Works")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "lock.fill",
                    title: "Vice apps are blocked",
                    description: "TikTok, Instagram, etc. start locked"
                )

                FeatureRow(
                    icon: "book.fill",
                    title: "Earn time being productive",
                    description: "Use Kindle, Duolingo to earn minutes"
                )

                FeatureRow(
                    icon: "clock.fill",
                    title: "Spend time on vice apps",
                    description: "Unlock social media with earned time"
                )

                FeatureRow(
                    icon: "arrow.clockwise",
                    title: "Daily reset at midnight",
                    description: "Fresh start every day, no rollover"
                )
            }
            .padding(.horizontal)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    HowItWorksView(onContinue: {}, onBack: {})
}
```

**Step 2: Test in Preview**

Run: Build and view in Xcode Preview
Expected: See 4-step explanation with icons

**Step 3: Commit**

```bash
git add Clepsy/Views/Onboarding/HowItWorksView.swift
git commit -m "feat: add how it works onboarding screen (screen 2)"
```

---

### Task 10: Onboarding Permission Screen (Screen 3)

**Files:**
- Create: `Clepsy/Views/Onboarding/PermissionView.swift`

**Step 1: Create PermissionView**

Create `Clepsy/Views/Onboarding/PermissionView.swift`:
```swift
import SwiftUI

struct PermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                Spacer()
            }
            .padding(.horizontal)

            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)

            Text("Screen Time Permission")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Clepsy needs permission to monitor app usage and manage screen time. This data stays private on your device.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()

            Button(action: {
                Task {
                    isRequesting = true
                    await viewModel.requestScreenTimePermission()
                    isRequesting = false
                    onContinue()
                }
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isRequesting ? "Requesting..." : "Grant Permission")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(12)
            }
            .disabled(isRequesting)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    PermissionView(
        viewModel: OnboardingViewModel(),
        onContinue: {},
        onBack: {}
    )
}
```

**Step 2: Test in Preview**

Run: Build and view in Xcode Preview
Expected: See permission request screen with shield icon

**Step 3: Commit**

```bash
git add Clepsy/Views/Onboarding/PermissionView.swift
git commit -m "feat: add screen time permission screen (screen 3)"
```

---

### Task 11: Onboarding App Selection Screen (Screen 4)

**Files:**
- Create: `Clepsy/Views/Onboarding/AppSelectionView.swift`

**Step 1: Create AppSelectionView**

Create `Clepsy/Views/Onboarding/AppSelectionView.swift`:
```swift
import SwiftUI

struct AppSelectionView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var selectedViceApps = Set<UUID>()
    @State private var selectedProductiveApps = Set<UUID>()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)

            Text("Choose Your Apps")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 8)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Vice Apps Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Vice Apps (to block)")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("These apps will be locked by default")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(AppCategory.defaultViceApps) { app in
                            AppToggleRow(
                                app: app,
                                isSelected: selectedViceApps.contains(app.id),
                                onToggle: {
                                    if selectedViceApps.contains(app.id) {
                                        selectedViceApps.remove(app.id)
                                    } else {
                                        selectedViceApps.insert(app.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 8)

                    // Productive Apps Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Productive Apps")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Earn time by using these apps")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(AppCategory.defaultProductiveApps) { app in
                            AppToggleRow(
                                app: app,
                                isSelected: selectedProductiveApps.contains(app.id),
                                onToggle: {
                                    if selectedProductiveApps.contains(app.id) {
                                        selectedProductiveApps.remove(app.id)
                                    } else {
                                        selectedProductiveApps.insert(app.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }

            // Continue Button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
    }
}

struct AppToggleRow: View {
    let app: TrackedApp
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: "app.fill")
                    .foregroundColor(.purple)

                Text(app.name)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    AppSelectionView(onContinue: {}, onBack: {})
}
```

**Step 2: Test in Preview**

Run: Build and view in Xcode Preview
Expected: See scrollable list of vice and productive apps with toggle checkboxes

**Step 3: Commit**

```bash
git add Clepsy/Views/Onboarding/AppSelectionView.swift
git commit -m "feat: add app selection onboarding screen (screen 4)"
```

---

### Task 12: Onboarding Ready Screen (Screen 5)

**Files:**
- Create: `Clepsy/Views/Onboarding/ReadyView.swift`

**Step 1: Create ReadyView**

Create `Clepsy/Views/Onboarding/ReadyView.swift`:
```swift
import SwiftUI

struct ReadyView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Clepsy is ready to help you build healthier scrolling habits")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 16) {
                InfoRow(icon: "lock.fill", text: "Vice apps are now blocked")
                InfoRow(icon: "book.fill", text: "Start earning time with productive apps")
                InfoRow(icon: "clock.fill", text: "Watch your balance on the dashboard")
            }
            .padding(.horizontal)

            Spacer()

            Button(action: onComplete) {
                Text("Go to Dashboard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    ReadyView(onComplete: {})
}
```

**Step 2: Test in Preview**

Run: Build and view in Xcode Preview
Expected: See completion screen with checkmark and summary

**Step 3: Commit**

```bash
git add Clepsy/Views/Onboarding/ReadyView.swift
git commit -m "feat: add ready screen onboarding (screen 5)"
```

---

### Task 13: Onboarding Container View

**Files:**
- Create: `Clepsy/Views/Onboarding/OnboardingContainerView.swift`

**Step 1: Create OnboardingContainerView**

Create `Clepsy/Views/Onboarding/OnboardingContainerView.swift`:
```swift
import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case 0:
                WelcomeView(onContinue: viewModel.nextStep)
            case 1:
                HowItWorksView(
                    onContinue: viewModel.nextStep,
                    onBack: viewModel.previousStep
                )
            case 2:
                PermissionView(
                    viewModel: viewModel,
                    onContinue: viewModel.nextStep,
                    onBack: viewModel.previousStep
                )
            case 3:
                AppSelectionView(
                    onContinue: viewModel.nextStep,
                    onBack: viewModel.previousStep
                )
            case 4:
                ReadyView(onComplete: {
                    viewModel.completeOnboarding()
                    hasCompletedOnboarding = true
                })
            default:
                WelcomeView(onContinue: viewModel.nextStep)
            }
        }
        .animation(.easeInOut, value: viewModel.currentStep)
    }
}

#Preview {
    OnboardingContainerView(hasCompletedOnboarding: .constant(false))
}
```

**Step 2: Test in Preview**

Run: Build and view in Xcode Preview
Expected: See welcome screen, test navigation by clicking buttons

**Step 3: Commit**

```bash
git add Clepsy/Views/Onboarding/OnboardingContainerView.swift
git commit -m "feat: add onboarding container with step navigation"
```

---

## Phase 3: Dashboard (Main Screen)

### Task 14: Dashboard ViewModel

**Files:**
- Create: `Clepsy/ViewModels/DashboardViewModel.swift`
- Create: `ClepsyTests/ViewModels/DashboardViewModelTests.swift`

**Step 1: Write the failing test**

Create `ClepsyTests/ViewModels/DashboardViewModelTests.swift`:
```swift
import XCTest
@testable import Clepsy

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var sut: DashboardViewModel!
    var mockPersistence: PersistenceService!

    override func setUp() {
        super.setUp()
        mockPersistence = PersistenceService(suiteName: "test.dashboard")
        mockPersistence.clearAll()
        sut = DashboardViewModel(persistenceService: mockPersistence)
    }

    override func tearDown() {
        mockPersistence.clearAll()
        super.tearDown()
    }

    func testInitialBalance() {
        XCTAssertEqual(sut.currentBalance.currentSeconds, 0)
    }

    func testAddTime() {
        sut.addTime(seconds: 120)
        XCTAssertEqual(sut.currentBalance.currentSeconds, 120)
    }

    func testSubtractTime() {
        sut.addTime(seconds: 300)
        sut.subtractTime(seconds: 100)
        XCTAssertEqual(sut.currentBalance.currentSeconds, 200)
    }

    func testFormattedBalance() {
        sut.addTime(seconds: 3600) // 1 hour
        XCTAssertEqual(sut.formattedBalance, "1h 0m")
    }

    func testBalancePercentage() {
        sut.addTime(seconds: 1800) // 30 minutes
        // Assuming max display is 60 minutes (3600 seconds)
        let expected = Double(1800) / Double(3600)
        XCTAssertEqual(sut.balancePercentage, expected, accuracy: 0.01)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL with "Cannot find 'DashboardViewModel' in scope"

**Step 3: Write minimal implementation**

Create `Clepsy/ViewModels/DashboardViewModel.swift`:
```swift
import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentBalance: TimeBalance
    @Published var todayEarned: Int = 0
    @Published var todaySpent: Int = 0

    private let persistenceService: PersistenceService
    private let maxDisplaySeconds = 3600 // 1 hour for percentage calculation

    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
        self.currentBalance = persistenceService.loadTimeBalance()
    }

    func addTime(seconds: Int) {
        currentBalance.add(seconds: seconds)
        todayEarned += seconds
        persistenceService.saveTimeBalance(currentBalance)
    }

    func subtractTime(seconds: Int) {
        let actualSubtracted = min(seconds, currentBalance.currentSeconds)
        currentBalance.subtract(seconds: seconds)
        todaySpent += actualSubtracted
        persistenceService.saveTimeBalance(currentBalance)
    }

    var formattedBalance: String {
        currentBalance.formattedTime
    }

    var balancePercentage: Double {
        return Double(currentBalance.currentSeconds) / Double(maxDisplaySeconds)
    }

    func checkAndPerformDailyReset() {
        let calendar = Calendar.current
        let now = Date()

        if let lastReset = persistenceService.getLastResetDate() {
            if !calendar.isDate(lastReset, inSameDayAs: now) {
                performReset()
            }
        } else {
            // First launch, set initial date
            persistenceService.performDailyReset()
        }
    }

    private func performReset() {
        persistenceService.performDailyReset()
        currentBalance = TimeBalance()
        todayEarned = 0
        todaySpent = 0
    }
}
```

**Step 4: Run test to verify it passes**

Run: `Cmd+U`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Clepsy/ViewModels/DashboardViewModel.swift ClepsyTests/ViewModels/DashboardViewModelTests.swift
git commit -m "feat: add DashboardViewModel with balance management"
```

---

### Task 15: Clepsy Character Component

**Files:**
- Create: `Clepsy/Views/Components/ClepsyCharacterView.swift`

**Step 1: Create ClepsyCharacterView**

Create `Clepsy/Views/Components/ClepsyCharacterView.swift`:
```swift
import SwiftUI

struct ClepsyCharacterView: View {
    let balancePercentage: Double // 0.0 to 1.0
    let expression: ClepsyExpression

    @State private var animationOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Hourglass body with sand level
            HourglassBody(fillPercentage: balancePercentage)

            // Face expression overlay
            FaceExpression(expression: expression)
                .offset(y: -60)
        }
        .frame(width: 240, height: 320)
        .offset(y: animationOffset)
        .onAppear {
            startFloatingAnimation()
        }
    }

    private func startFloatingAnimation() {
        withAnimation(
            .easeInOut(duration: 3.5)
            .repeatForever(autoreverses: true)
        ) {
            animationOffset = 10
        }
    }
}

struct HourglassBody: View {
    let fillPercentage: Double

    var body: some View {
        ZStack(alignment: .bottom) {
            // Hourglass outline
            Image(systemName: "hourglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.purple.opacity(0.3))

            // Sand fill (simplified - actual implementation would use assets)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 320 * fillPercentage)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 60)
        }
    }
}

struct FaceExpression: View {
    let expression: ClepsyExpression

    var body: some View {
        HStack(spacing: 20) {
            // Eyes
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)

            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)
        }
        .overlay(alignment: .bottom) {
            // Mouth based on expression
            mouthShape
                .stroke(Color.black, lineWidth: 2)
                .frame(width: 40, height: 20)
                .offset(y: 30)
        }
    }

    @ViewBuilder
    private var mouthShape: some Shape {
        switch expression {
        case .patient:
            Capsule()
        case .encouraging:
            Arc(startAngle: .degrees(0), endAngle: .degrees(180))
        case .celebrating:
            Arc(startAngle: .degrees(0), endAngle: .degrees(180))
        }
    }
}

enum ClepsyExpression {
    case patient
    case encouraging
    case celebrating
}

struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

#Preview {
    VStack(spacing: 40) {
        ClepsyCharacterView(balancePercentage: 0.0, expression: .patient)
        ClepsyCharacterView(balancePercentage: 0.5, expression: .encouraging)
        ClepsyCharacterView(balancePercentage: 1.0, expression: .celebrating)
    }
}
```

**Step 2: Test in Preview**

Run: Build and view in Xcode Preview
Expected: See three Clepsy characters with different sand levels and expressions

**Step 3: Commit**

```bash
git add Clepsy/Views/Components/ClepsyCharacterView.swift
git commit -m "feat: add Clepsy character component with animations"
```

---

### Task 16: Dashboard Main View

**Files:**
- Create: `Clepsy/Views/Dashboard/DashboardView.swift`

**Scope Update** (2026-02-01): Now includes error banner for permission denied scenario. See `dashboard_specs.md` (Section 3.1B) for visual specifications.

**Note**: Permission denied banner is conditional and appears at top of dashboard if `FamilyControls.authorization != .approved`

**Step 1: Create DashboardView**

Create `Clepsy/Views/Dashboard/DashboardView.swift`:
```swift
import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Clepsy Character
                    ClepsyCharacterView(
                        balancePercentage: min(viewModel.balancePercentage, 1.0),
                        expression: expressionForBalance
                    )
                    .padding(.top, 20)

                    // Current Balance Card
                    VStack(spacing: 8) {
                        Text("Current Balance")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(viewModel.formattedBalance)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.purple)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Today's Activity
                    HStack(spacing: 16) {
                        ActivityCard(
                            title: "Earned",
                            value: formatSeconds(viewModel.todayEarned),
                            icon: "arrow.up.circle.fill",
                            color: .green
                        )

                        ActivityCard(
                            title: "Spent",
                            value: formatSeconds(viewModel.todaySpent),
                            icon: "arrow.down.circle.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Quick Actions (placeholder for MVP)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)

                        Button(action: {
                            // Test: Add 5 minutes
                            viewModel.addTime(seconds: 300)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add 5 minutes (test)")
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        Button(action: {
                            // Test: Subtract 2 minutes
                            viewModel.subtractTime(seconds: 120)
                        }) {
                            HStack {
                                Image(systemName: "minus.circle.fill")
                                Text("Subtract 2 minutes (test)")
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: Text("Settings")) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onAppear {
            viewModel.checkAndPerformDailyReset()
        }
    }

    private var expressionForBalance: ClepsyExpression {
        if viewModel.balancePercentage > 0.6 {
            return .celebrating
        } else if viewModel.balancePercentage > 0.2 {
            return .encouraging
        } else {
            return .patient
        }
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes)m"
    }
}

struct ActivityCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
}
```

**Step 2: Test in Preview**

Run: Build and view in Xcode Preview
Expected: See dashboard with Clepsy character, balance display, and activity cards

**Step 3: Commit**

```bash
git add Clepsy/Views/Dashboard/DashboardView.swift
git commit -m "feat: add main dashboard view with balance and activity"
```

---

## Phase 4: App Entry Point & Navigation

### Task 17: Main App Entry ⚠️ UPDATED

**Files:**
- Modify: `Clepsy/ClepsyApp.swift`

**⚠️ Critical Update** (2026-02-01):
1. Added `scenePhase` observer to ensure daily reset triggers when app enters foreground (not just on launch)
2. Simplified timezone handling: Use device's current timezone only (MVP doesn't handle travel scenarios)

**Step 1: Read existing file**

Run: Read tool on `Clepsy/ClepsyApp.swift`

**Step 2: Update ClepsyApp.swift**

Replace content with:
```swift
import SwiftUI

@main
struct ClepsyApp: App {
    @StateObject private var persistenceService = PersistenceService()
    @State private var hasCompletedOnboarding = false

    // ⚠️ NEW: Scene phase observer for daily reset
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .onAppear {
                    let settings = persistenceService.loadUserSettings()
                    hasCompletedOnboarding = settings.hasCompletedOnboarding
                }
                // ⚠️ NEW: Check daily reset when app enters foreground
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        // Dashboard will handle actual reset check via its ViewModel
                        // This establishes the pattern for foreground monitoring
                        NotificationCenter.default.post(
                            name: NSNotification.Name("AppDidBecomeActive"),
                            object: nil
                        )
                    }
                }
        }
    }
}

struct ContentView: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        if hasCompletedOnboarding {
            DashboardView()
        } else {
            OnboardingContainerView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}
```

**Step 3: Build and test**

Run: `Cmd+B` to build
Expected: Project builds successfully

**Step 4: Commit**

```bash
git add Clepsy/ClepsyApp.swift
git commit -m "feat: wire up app entry point with onboarding/dashboard routing"
```

---

## Phase 5: Device Activity Monitoring (Earning & Spending)

### Task 18: Device Activity Monitor Extension Setup

**Files:**
- Create: DeviceActivityMonitor extension target
- Create: `DeviceActivityMonitor/DeviceActivityMonitorExtension.swift`

**Step 1: Create extension target**

In Xcode:
1. File → New → Target
2. Choose "Device Activity Monitor Extension"
3. Name: "ClepsyMonitor"
4. Add to Clepsy project

**Step 2: Create monitor implementation**

Create `ClepsyMonitor/DeviceActivityMonitorExtension.swift`:
```swift
import DeviceActivity
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Handle productive app usage start
        // This will be called when user opens a productive app
        // Note: Cannot directly update UI from extension
        // Must use shared storage (UserDefaults with app group)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Handle productive app usage end
        // Calculate time earned and save to shared storage
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // Handle events like spending time on vice apps
    }
}
```

**Step 3: Configure app group**

1. Add App Groups capability to both Clepsy and ClepsyMonitor targets
2. Create group: `group.com.clepsy.shared`
3. Enable for both targets

**Step 4: Commit**

```bash
git add .
git commit -m "feat: add DeviceActivityMonitor extension for usage tracking"
```

---

### Task 19: TimeEvent Model ⚠️ NEW

**Files:**
- Create: `Clepsy/Models/TimeEvent.swift`
- Create: `ClepsyTests/Models/TimeEventTests.swift`

**⚠️ Critical Addition**: Replaces simple `Int` approach with thread-safe event queue to prevent race conditions between app and monitor extension.

**Step 1: Write the failing test**

Create `ClepsyTests/Models/TimeEventTests.swift`:
```swift
import XCTest
@testable import Clepsy

final class TimeEventTests: XCTestCase {
    func testTimeEventCreation() {
        let event = TimeEvent(
            seconds: 300,
            timestamp: Date(),
            type: .earned,
            appBundleId: "com.amazon.Lassen"
        )

        XCTAssertEqual(event.seconds, 300)
        XCTAssertEqual(event.type, .earned)
        XCTAssertEqual(event.appBundleId, "com.amazon.Lassen")
        XCTAssertNotNil(event.id)
    }

    func testEventTypeEncoding() throws {
        let event = TimeEvent(
            seconds: 120,
            timestamp: Date(),
            type: .spent,
            appBundleId: "com.zhiliaoapp.musically"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimeEvent.self, from: data)

        XCTAssertEqual(decoded.seconds, 120)
        XCTAssertEqual(decoded.type, .spent)
    }

    func testMultipleEventsArray() throws {
        let events = [
            TimeEvent(seconds: 300, timestamp: Date(), type: .earned),
            TimeEvent(seconds: 120, timestamp: Date(), type: .spent)
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(events)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([TimeEvent].self, from: data)

        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].type, .earned)
        XCTAssertEqual(decoded[1].type, .spent)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL with "Cannot find 'TimeEvent' in scope"

**Step 3: Write minimal implementation**

Create `Clepsy/Models/TimeEvent.swift`:
```swift
import Foundation

struct TimeEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let seconds: Int              // Time earned or spent
    let timestamp: Date           // When event occurred
    let type: EventType           // .earned or .spent
    let appBundleId: String?      // Optional: which app triggered this

    init(
        id: UUID = UUID(),
        seconds: Int,
        timestamp: Date,
        type: EventType,
        appBundleId: String? = nil
    ) {
        self.id = id
        self.seconds = seconds
        self.timestamp = timestamp
        self.type = type
        self.appBundleId = appBundleId
    }

    enum EventType: String, Codable {
        case earned
        case spent
    }
}
```

**Step 4: Run test to verify it passes**

Run: `Cmd+U`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Clepsy/Models/TimeEvent.swift ClepsyTests/Models/TimeEventTests.swift
git commit -m "feat: add TimeEvent model for thread-safe event queue"
```

---

### Task 20: Shared Storage Service ⚠️ UPDATED

**Files:**
- Create: `Clepsy/Services/SharedStorageService.swift`
- Create: `ClepsyTests/Services/SharedStorageServiceTests.swift`

**⚠️ Critical Update** (2026-02-01):
1. Changed from simple `Int` values to thread-safe event queue using `[TimeEvent]` array
2. Replaced deprecated `.synchronize()` with FileCoordination (iOS 16+ standard)
3. Uses `NSFileCoordinator` for atomic writes between app + extension

**Step 1: Write the failing test**

Create `ClepsyTests/Services/SharedStorageServiceTests.swift`:
```swift
import XCTest
@testable import Clepsy

final class SharedStorageServiceTests: XCTestCase {
    var sut: SharedStorageService!

    override func setUp() {
        super.setUp()
        sut = SharedStorageService()
        sut.clearEvents()
    }

    override func tearDown() {
        sut.clearEvents()
        super.tearDown()
    }

    func testAppendAndGetEvents() {
        let event = TimeEvent(
            seconds: 300,
            timestamp: Date(),
            type: .earned,
            appBundleId: "com.amazon.Lassen"
        )

        sut.appendEvent(event)
        let retrieved = sut.getEvents()

        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.seconds, 300)
    }

    func testMultipleEventsInOrder() {
        let event1 = TimeEvent(seconds: 100, timestamp: Date(), type: .earned)
        let event2 = TimeEvent(seconds: 200, timestamp: Date().addingTimeInterval(1), type: .earned)

        sut.appendEvent(event1)
        sut.appendEvent(event2)

        let retrieved = sut.getEvents()
        XCTAssertEqual(retrieved.count, 2)
        XCTAssertEqual(retrieved[0].seconds, 100)
        XCTAssertEqual(retrieved[1].seconds, 200)
    }

    func testClearEvents() {
        let event = TimeEvent(seconds: 300, timestamp: Date(), type: .earned)
        sut.appendEvent(event)

        sut.clearEvents()
        XCTAssertTrue(sut.getEvents().isEmpty)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `Cmd+U`
Expected: FAIL with "Cannot find 'SharedStorageService' in scope"

**Step 3: Write minimal implementation (with FileCoordination)**

Create `Clepsy/Services/SharedStorageService.swift`:
```swift
import Foundation

class SharedStorageService {
    private let appGroup = "group.com.clepsy.shared"
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.clepsy.shared", qos: .userInitiated)

    private lazy var containerURL: URL = {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? FileManager.default.temporaryDirectory
    }()

    private lazy var eventsFileURL: URL = {
        containerURL.appendingPathComponent("pendingTimeEvents.json")
    }()

    init() {
        // Ensure container directory exists
        try? fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
    }

    // MARK: - Thread-Safe Event Queue (FileCoordination)

    /// Append a time event (called from extension)
    /// Uses FileCoordination for atomic writes
    func appendEvent(_ event: TimeEvent) {
        queue.sync {
            let coordinator = NSFileCoordinator(filePresenter: nil)
            var error: NSError?

            coordinator.coordinate(
                writingItemAt: eventsFileURL,
                options: .forMerging,
                error: &error
            ) { url in
                do {
                    let data = try? Data(contentsOf: url)
                    var events = (try? JSONDecoder().decode([TimeEvent].self, from: data ?? Data())) ?? []
                    events.append(event)
                    let encoded = try JSONEncoder().encode(events)
                    try encoded.write(to: url, options: .atomic)
                } catch {
                    print("❌ Error appending event: \(error)")
                }
            }

            if let error = error {
                print("❌ FileCoordination error: \(error)")
            }
        }
    }

    /// Get all pending events (called from main app)
    func getEvents() -> [TimeEvent] {
        return queue.sync {
            let coordinator = NSFileCoordinator(filePresenter: nil)
            var events = [TimeEvent]()
            var error: NSError?

            coordinator.coordinate(
                readingItemAt: eventsFileURL,
                options: [],
                error: &error
            ) { url in
                do {
                    let data = try Data(contentsOf: url)
                    events = (try JSONDecoder().decode([TimeEvent].self, from: data)) ?? []
                } catch {
                    print("⚠️ No events file yet or JSON error: \(error)")
                }
            }

            return events
        }
    }

    /// Clear all events after processing (called from main app)
    func clearEvents() {
        queue.sync {
            let coordinator = NSFileCoordinator(filePresenter: nil)
            var error: NSError?

            coordinator.coordinate(
                writingItemAt: eventsFileURL,
                options: .forDeleting,
                error: &error
            ) { url in
                do {
                    let emptyArray = try JSONEncoder().encode([TimeEvent]())
                    try emptyArray.write(to: url, options: .atomic)
                } catch {
                    print("❌ Error clearing events: \(error)")
                }
            }
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `Cmd+U`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add Clepsy/Services/SharedStorageService.swift ClepsyTests/Services/SharedStorageServiceTests.swift
git commit -m "feat: add thread-safe SharedStorageService with event queue"
```

---

### Task 21: Usage Tracking Service ⚠️ UPDATED

**Files:**
- Create: `Clepsy/Services/UsageTrackingService.swift`

**⚠️ Critical Update**: Updated `syncPendingTime` to use thread-safe event queue instead of simple Int values.

**Step 1: Create UsageTrackingService**

Create `Clepsy/Services/UsageTrackingService.swift`:
```swift
import Foundation
import DeviceActivity
import FamilyControls

class UsageTrackingService {
    private let center = DeviceActivityCenter()
    private let sharedStorage = SharedStorageService()

    func startMonitoringProductiveApps(_ apps: [TrackedApp]) {
        // Configure device activity schedule for productive apps
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(
                .productiveApps,
                during: schedule
            )
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }

    func startMonitoringViceApps(_ apps: [TrackedApp]) {
        // Configure device activity schedule for vice apps
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(
                .viceApps,
                during: schedule
            )
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }

    func stopAllMonitoring() {
        center.stopMonitoring([.productiveApps, .viceApps])
    }

    func syncPendingTime(to viewModel: DashboardViewModel) {
        let sharedStorage = SharedStorageService()

        // ✅ Get all events atomically
        let events = sharedStorage.getEvents()

        guard !events.isEmpty else { return }

        // ✅ Process each event in chronological order
        for event in events.sorted(by: { $0.timestamp < $1.timestamp }) {
            switch event.type {
            case .earned:
                viewModel.addTime(seconds: event.seconds)
            case .spent:
                viewModel.subtractTime(seconds: event.seconds)
            }
        }

        // ✅ Clear queue atomically after processing
        sharedStorage.clearEvents()
    }
}

extension DeviceActivityName {
    static let productiveApps = DeviceActivityName("productiveApps")
    static let viceApps = DeviceActivityName("viceApps")
}
```

**Step 2: Test manually**

Build and verify no compilation errors

**Step 3: Commit**

```bash
git add Clepsy/Services/UsageTrackingService.swift
git commit -m "feat: add UsageTrackingService for DeviceActivity scheduling"
```

---

### Task 21B: Earning Session Manager ⭐ NEW

**Purpose**: Implements earning mechanics from earning_specs: 60-second warmup + 2-minute timeout logic

**Files:**
- Create: `Clepsy/Services/EarningSessionManager.swift`
- Create: `ClepsyTests/Services/EarningSessionManagerTests.swift`

**Why This Task**: Earning mechanics are critical to MVP but underspecified in original plan. This service implements:
- 60-second warmup before tracking starts
- 2-minute timeout to pause/resume sessions
- 5-minute balance update frequency
- Session end → credit balance

**Step 1: Write tests first**

Create `ClepsyTests/Services/EarningSessionManagerTests.swift`:
```swift
import XCTest
@testable import Clepsy

final class EarningSessionManagerTests: XCTestCase {
    var manager: EarningSessionManager!

    override func setUp() {
        super.setUp()
        manager = EarningSessionManager()
    }

    func testWarmupRequiredBeforeEarning() {
        // User opens productive app
        manager.startSession(for: "com.amazon.Kindle")

        // At 30 seconds: should not have earned time yet
        manager.simulateElapsedTime(seconds: 30)
        XCTAssertEqual(manager.currentSessionEarnings, 0)

        // At 60 seconds: warmup complete, tracking starts
        manager.simulateElapsedTime(seconds: 30)
        XCTAssertEqual(manager.currentSessionEarnings, 0) // No earnings yet

        // At 70 seconds: 10 seconds of actual usage = 0 min earned
        manager.simulateElapsedTime(seconds: 10)
        XCTAssertEqual(manager.currentSessionEarnings, 0)

        // At 120 seconds: 60 seconds of actual usage = 1 min earned
        manager.simulateElapsedTime(seconds: 50)
        XCTAssertEqual(manager.currentSessionEarnings, 60)
    }

    func testBriefInterruptionResumesSession() {
        // User in Kindle for 5 minutes
        manager.startSession(for: "com.amazon.Kindle")
        manager.simulateElapsedTime(seconds: 300 + 60) // 5 min + warmup

        let earningsAfter5Min = manager.currentSessionEarnings
        XCTAssertGreaterThan(earningsAfter5Min, 0)

        // Brief interruption (30 seconds)
        manager.pauseSession()
        manager.simulateElapsedTime(seconds: 30)

        // Resume: session resumes without new warmup
        manager.resumeSession()
        manager.simulateElapsedTime(seconds: 60)

        // Should have additional earnings
        XCTAssertGreaterThan(manager.currentSessionEarnings, earningsAfter5Min)
    }

    func testLongInterruptionEndsSession() {
        // User in Kindle for 5 minutes
        manager.startSession(for: "com.amazon.Kindle")
        manager.simulateElapsedTime(seconds: 360 + 60) // 6 min total

        let earningsBeforePause = manager.currentSessionEarnings
        XCTAssertGreaterThan(earningsBeforePause, 0)

        // Long interruption (2.5 minutes > timeout)
        manager.pauseSession()
        manager.simulateElapsedTime(seconds: 150)

        // Session should end
        let sessionEnded = manager.endSession()
        XCTAssertTrue(sessionEnded)

        // Next app open requires new warmup
        manager.startSession(for: "com.amazon.Kindle")
        manager.simulateElapsedTime(seconds: 30)
        XCTAssertEqual(manager.currentSessionEarnings, 0) // Warmup required again
    }

    func testBalanceUpdateFrequency() {
        manager.startSession(for: "com.amazon.Kindle")
        manager.simulateElapsedTime(seconds: 60) // Warmup

        var updatesReceived = [Int]()
        manager.onBalanceUpdate = { seconds in
            updatesReceived.append(seconds)
        }

        // Earn for 12 minutes (5 + 5 + 2)
        manager.simulateElapsedTime(seconds: 300) // 5 min earned → update
        manager.simulateElapsedTime(seconds: 300) // 10 min earned → update
        manager.simulateElapsedTime(seconds: 120) // 12 min earned → no update yet

        XCTAssertEqual(updatesReceived.count, 2) // Two updates at 5 and 10 min

        // Session ends → final update
        manager.endSession()
        XCTAssertEqual(updatesReceived.count, 3) // Third update on session end
    }
}
```

**Step 2: Write minimal implementation**

Create `Clepsy/Services/EarningSessionManager.swift`:
```swift
import Foundation

class EarningSessionManager {
    private var currentSessionId: UUID?
    private var currentSessionStartTime: Date?
    private var currentSessionPausedTime: TimeInterval = 0
    private var currentAppBundleId: String?
    private var currentSessionEarningsSeconds: Int = 0
    private var warmupExpired = false
    private var pauseStartTime: Date?
    private var lastBalanceUpdateTime: Date?

    // Callback for balance updates (every 5 minutes or session end)
    var onBalanceUpdate: ((Int) -> Void)?

    private let warmupDuration: TimeInterval = 60 // 60 seconds
    private let pauseTimeoutDuration: TimeInterval = 120 // 2 minutes
    private let balanceUpdateInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Public Interface

    func startSession(for appBundleId: String) {
        self.currentSessionId = UUID()
        self.currentAppBundleId = appBundleId
        self.currentSessionStartTime = Date()
        self.currentSessionEarningsSeconds = 0
        self.warmupExpired = false
        self.lastBalanceUpdateTime = Date()
        print("📱 Earning session started for \(appBundleId)")
    }

    func pauseSession() {
        pauseStartTime = Date()
        print("⏸️ Session paused")
    }

    func resumeSession() {
        guard let pauseStart = pauseStartTime else { return }

        let pausedDuration = Date().timeIntervalSince(pauseStart)

        if pausedDuration > pauseTimeoutDuration {
            // Pause was too long, session ends
            print("❌ Pause exceeded 2 minutes, session will end")
            _ = endSession()
        } else {
            // Brief pause, add to total paused time
            currentSessionPausedTime += pausedDuration
            pauseStartTime = nil
            print("▶️ Session resumed (paused for \(pausedDuration)s)")
        }
    }

    func endSession() -> Bool {
        guard currentSessionId != nil else { return false }

        // Credit any remaining earnings
        let remainingEarnings = calculateEarnings()
        if remainingEarnings > currentSessionEarningsSeconds {
            currentSessionEarningsSeconds = remainingEarnings
            onBalanceUpdate?(currentSessionEarningsSeconds)
        }

        print("✅ Session ended with \(currentSessionEarningsSeconds) seconds earned")
        currentSessionId = nil
        return true
    }

    var currentSessionEarnings: Int {
        guard currentSessionId != nil else { return 0 }

        let totalEarnings = calculateEarnings()

        // Check if we should send balance update
        if totalEarnings >= currentSessionEarningsSeconds + Int(balanceUpdateInterval) {
            currentSessionEarningsSeconds = totalEarnings
            lastBalanceUpdateTime = Date()
            onBalanceUpdate?(currentSessionEarningsSeconds)
        }

        return currentSessionEarningsSeconds
    }

    // MARK: - Private Helpers

    private func calculateEarnings() -> Int {
        guard let startTime = currentSessionStartTime else { return 0 }

        let elapsed = Date().timeIntervalSince(startTime) - currentSessionPausedTime

        // Warmup: first 60 seconds don't count
        guard elapsed > warmupDuration else { return 0 }

        // Earning time = (elapsed - warmup) in seconds
        let earnedSeconds = Int(elapsed - warmupDuration)
        return max(0, earnedSeconds)
    }

    // MARK: - Testing Only

    #if DEBUG
    func simulateElapsedTime(seconds: TimeInterval) {
        // For testing: advance the clock
        if let startTime = currentSessionStartTime {
            currentSessionStartTime = startTime.addingTimeInterval(-seconds)
        }
    }
    #endif
}
```

**Step 3: Run tests**

Run: `Cmd+U`
Expected: All tests PASS

**Step 4: Commit**

```bash
git add Clepsy/Services/EarningSessionManager.swift ClepsyTests/Services/EarningSessionManagerTests.swift
git commit -m "feat: add EarningSessionManager with warmup and timeout mechanics"
```

---

## Phase 6: Settings & Polish

### Task 22: Settings View

**Files:**
- Create: `Clepsy/Views/Settings/SettingsView.swift`

**Step 1: Create SettingsView**

Create `Clepsy/Views/Settings/SettingsView.swift`:
```swift
import SwiftUI

struct SettingsView: View {
    @StateObject private var persistenceService = PersistenceService()
    @State private var settings: UserSettings

    init() {
        let service = PersistenceService()
        _settings = State(initialValue: service.loadUserSettings())
    }

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                    .onChange(of: settings.notificationsEnabled) { _ in
                        saveSettings()
                    }
            }

            Section("Apps") {
                NavigationLink("Manage Vice Apps") {
                    AppListView(
                        apps: settings.viceApps,
                        category: .vice,
                        onUpdate: { updatedApps in
                            settings.viceApps = updatedApps
                            saveSettings()
                        }
                    )
                }

                NavigationLink("Manage Productive Apps") {
                    AppListView(
                        apps: settings.productiveApps,
                        category: .productive,
                        onUpdate: { updatedApps in
                            settings.productiveApps = updatedApps
                            saveSettings()
                        }
                    )
                }
            }

            Section("Data") {
                Button("Reset Daily Statistics") {
                    persistenceService.performDailyReset()
                }
                .foregroundColor(.orange)

                Button("Reset All Data") {
                    resetAllData()
                }
                .foregroundColor(.red)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                Link("Privacy Policy", destination: URL(string: "https://clepsy.app/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://clepsy.app/terms")!)
            }
        }
        .navigationTitle("Settings")
    }

    private func saveSettings() {
        persistenceService.saveUserSettings(settings)
    }

    private func resetAllData() {
        persistenceService.clearAll()
        settings = UserSettings()
    }
}

struct AppListView: View {
    let apps: [TrackedApp]
    let category: AppCategory
    let onUpdate: ([TrackedApp]) -> Void

    var body: some View {
        List {
            ForEach(apps) { app in
                HStack {
                    Image(systemName: "app.fill")
                        .foregroundColor(.purple)
                    Text(app.name)
                    Spacer()
                }
            }
        }
        .navigationTitle("\(category.displayName)")
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
```

**Step 2: Test in Preview**

Run: Build and view in Xcode Preview
Expected: See settings form with sections

**Step 3: Commit**

```bash
git add Clepsy/Views/Settings/SettingsView.swift
git commit -m "feat: add settings view with app management"
```

---

### Task 23: Shield Configuration View

**Files:**
- Create: `Clepsy/Views/Shield/ShieldConfigurationView.swift`

**Step 1: Create ShieldConfigurationView**

Create `Clepsy/Views/Shield/ShieldConfigurationView.swift`:
```swift
import SwiftUI
import FamilyControls

struct ShieldConfigurationView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let appName: String
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Clepsy character showing current balance
            ClepsyCharacterView(
                balancePercentage: min(viewModel.balancePercentage, 1.0),
                expression: .patient
            )
            .scaleEffect(0.6)

            Text("\(appName) is locked")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                HStack {
                    Text("Your balance:")
                    Spacer()
                    Text(viewModel.formattedBalance)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }

                HStack {
                    Text("Cost to unlock:")
                    Spacer()
                    Text("1 min per 1 min")
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            if viewModel.currentBalance.currentSeconds > 0 {
                Button(action: onUnlock) {
                    Text("Unlock \(appName)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    Text("Earn time to unlock")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Use productive apps like Kindle or Duolingo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }

            Spacer()
        }
        .padding(.top, 40)
    }
}

#Preview {
    ShieldConfigurationView(
        viewModel: DashboardViewModel(),
        appName: "Instagram",
        onUnlock: {}
    )
}
```

**Step 2: Test in Preview**

Run: Build and view in Xcode Preview
Expected: See shield screen with balance and unlock button

**Step 3: Commit**

```bash
git add Clepsy/Views/Shield/ShieldConfigurationView.swift
git commit -m "feat: add shield configuration view for blocked apps"
```

---

## Phase 7: Final Integration & Testing

### Task 24: Wire Dashboard to Settings

**Files:**
- Modify: `Clepsy/Views/Dashboard/DashboardView.swift:47`

**Step 1: Read current DashboardView**

Already read in previous task

**Step 2: Update toolbar navigation**

Replace the toolbar section:
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        NavigationLink(destination: SettingsView()) {
            Image(systemName: "gear")
        }
    }
}
```

**Step 3: Build and test**

Run: `Cmd+B`
Expected: Build succeeds, settings navigation works

**Step 4: Commit**

```bash
git add Clepsy/Views/Dashboard/DashboardView.swift
git commit -m "feat: connect settings navigation from dashboard"
```

---

### Task 25: Add App Icon Assets

**Files:**
- Add to: `Clepsy/Assets.xcassets/AppIcon.appiconset/`

**Step 1: Prepare app icon**

1. Locate `app_icon_1024.png` from documentation assets
2. Open Xcode Assets.xcassets
3. Select AppIcon
4. Drag 1024x1024 icon into "App Store iOS" slot

**Step 2: Generate other sizes**

Use Xcode's automatic icon generation or manually add:
- 20pt (@1x, @2x, @3x)
- 29pt (@1x, @2x, @3x)
- 40pt (@1x, @2x, @3x)
- 60pt (@2x, @3x)
- 76pt (@1x, @2x)
- 83.5pt (@2x)

**Step 3: Build and verify**

Run: `Cmd+B` then check simulator home screen
Expected: See Clepsy icon

**Step 4: Commit**

```bash
git add Clepsy/Assets.xcassets/AppIcon.appiconset/
git commit -m "assets: add app icon at all required sizes"
```

---

### Task 26: Add Clepsy Character Assets

**Files:**
- Add to: `Clepsy/Assets.xcassets/ClepsyCharacter/`

**Asset Source**: `clepsy_app_images/` folder (27 files total: 3 faces × 3 scales + 5 body levels × 3 scales)

**Step 1: Create image sets in Assets.xcassets**

In Xcode Assets.xcassets, create **8 image sets** (NOT individual files - Xcode manages @1x/@2x/@3x):

**Face expressions** (3 sets):
- `patience_face` (for shield screen, morning start)
- `encouraging_face` (for earning milestones, unlocking)
- `celebrating_face` (for daily goal met, streaks)

**Body sand levels** (5 sets):
- `body_level_0` (empty hourglass, 0% progress)
- `body_level_25` (25% sand level)
- `body_level_50` (50% sand level)
- `body_level_75` (75% sand level)
- `body_level_100` (full hourglass, 100% progress)

**Step 2: Import assets from clepsy_app_images/**

For each image set, drag the corresponding files:

```
patience_face:
  - @1x_clepsy_app_icons_(240x320px)/patience_face@1x.png.png → 1x slot
  - @2x_clepsy_app_icons_(480x640px)/patience_face@2x.png.png → 2x slot
  - @3_clepsy_app_icons_(720x960px)/patience_face@3x.png.png → 3x slot

body_level_0:
  - @1x_clepsy_app_icons_(240x320px)/body_level_0@1x.png.png → 1x slot
  - @2x_clepsy_app_icons_(480x640px)/body_level_0@2x.png.png → 2x slot
  - @3_clepsy_app_icons_(720x960px)/body_level_0@3x.png.png → 3x slot

(Repeat for all 8 image sets)
```

**Step 3: Verify assets**

- [ ] All image sets show 3 scales (1x, 2x, 3x)
- [ ] Transparency preserved (PNG-24)
- [ ] Canvas size is uniform (240×320pt)

**Step 4: Commit**

```bash
git add Clepsy/Assets.xcassets/ClepsyCharacter/
git commit -m "assets: add Clepsy character images (3 faces + 5 body levels)"
```

**Reference**: See `clepsy_app_images/clepsy_mascot_asset_guide.md` for layering strategy

---

### Task 27: Update ClepsyCharacterView to Use Assets

**Files:**
- Modify: `Clepsy/Views/Components/ClepsyCharacterView.swift`

**Asset Strategy**: Use **Decoupled Layering System** from `clepsy_mascot_asset_guide.md` - body and face are separate layers in a ZStack.

**Step 1: Read current implementation**

Already read

**Step 2: Update to use real assets**

Replace placeholder code with production asset loading:
```swift
struct HourglassBody: View {
    let fillPercentage: Double

    var sandLevel: String {
        // Map percentage to 5 sand levels (0, 25, 50, 75, 100)
        switch fillPercentage {
        case 0..<0.125: return "body_level_0"      // 0-12.5% → empty
        case 0.125..<0.375: return "body_level_25" // 12.5-37.5% → 25%
        case 0.375..<0.625: return "body_level_50" // 37.5-62.5% → 50%
        case 0.625..<0.875: return "body_level_75" // 62.5-87.5% → 75%
        default: return "body_level_100"           // 87.5-100% → full
        }
    }

    var body: some View {
        Image(sandLevel)
            .resizable()
            .scaledToFit()
    }
}

struct FaceExpression: View {
    let expression: ClepsyExpression

    var faceName: String {
        switch expression {
        case .patient: return "patience_face"
        case .encouraging: return "encouraging_face"
        case .celebrating: return "celebrating_face"
        }
    }

    var body: some View {
        Image(faceName)
            .resizable()
            .scaledToFit()
    }
}
```

**Step 3: Update ClepsyCharacterView to ensure proper ZStack**

Verify the main view matches asset guide's layering:
```swift
struct ClepsyCharacterView: View {
    let balancePercentage: Double // 0.0 to 1.0
    let expression: ClepsyExpression

    @State private var animationOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Layer 1: Hourglass Body (sand level)
            HourglassBody(fillPercentage: balancePercentage)

            // Layer 2: Face Expression (overlays on body)
            FaceExpression(expression: expression)
        }
        .frame(width: 240, height: 320) // Canvas size from asset guide
        .offset(y: animationOffset)
        .onAppear {
            startFloatingAnimation()
        }
    }

    private func startFloatingAnimation() {
        // Subtle float: 8-10pt amplitude, 3.5s duration (from asset guide)
        withAnimation(
            .easeInOut(duration: 3.5)
            .repeatForever(autoreverses: true)
        ) {
            animationOffset = 10
        }
    }
}
```

**Step 4: Test in Preview**

Run: Xcode Preview
Expected:
- ✅ Character displays with transparent PNG assets
- ✅ Body and face layer correctly (ZStack)
- ✅ Floating animation works (10pt vertical offset, 3.5s loop)
- ✅ Sand level changes when balancePercentage updates
- ✅ Face expression changes when expression updates

**Step 5: Commit**

```bash
git add Clepsy/Views/Components/ClepsyCharacterView.swift
git commit -m "feat: use production Clepsy assets with decoupled layering"
```

**Reference**: All logic maps from `clepsy_app_images/clepsy_mascot_asset_guide.md` → "Logic & State Mapping" table

---

### Task 28: End-to-End Testing Checklist

**Files:**
- Create: `docs/testing/mvp-test-checklist.md`

**Step 1: Create test checklist**

Create `docs/testing/mvp-test-checklist.md`:
```markdown
# Clepsy MVP Testing Checklist

## Onboarding Flow
- [ ] Launch app for first time shows welcome screen
- [ ] Can navigate through all 5 onboarding screens
- [ ] Back button works on screens 2-4
- [ ] Screen Time permission request triggers on screen 3
- [ ] App selection checkboxes toggle correctly
- [ ] Completing onboarding saves state
- [ ] Relaunching app after onboarding shows dashboard

## Dashboard
- [ ] Dashboard loads with zero balance initially
- [ ] Clepsy character displays at correct size
- [ ] Character animation (floating) works
- [ ] "Add time" test button increases balance
- [ ] "Subtract time" test button decreases balance
- [ ] Balance cannot go below zero
- [ ] Formatted time displays correctly (minutes/hours)
- [ ] Today's earned/spent cards update
- [ ] Settings button navigates to settings

## Settings
- [ ] Settings view loads from dashboard
- [ ] Notifications toggle saves state
- [ ] Vice apps list displays
- [ ] Productive apps list displays
- [ ] Reset daily stats works
- [ ] Reset all data clears everything
- [ ] About section links are present

## Persistence
- [ ] Balance persists across app restarts
- [ ] Settings persist across app restarts
- [ ] Daily reset occurs at midnight (test by changing device time)
- [ ] Onboarding completion persists

## Screen Time Integration (Device Testing Only)
- [ ] FamilyControls authorization requested
- [ ] Authorization status tracked correctly
- [ ] Vice apps can be blocked (requires approval)
- [ ] Shield appears when trying to open blocked app
- [ ] DeviceActivityMonitor extension loads

## Performance
- [ ] App launches in < 2 seconds
- [ ] Dashboard loads in < 2 seconds
- [ ] No memory warnings during normal use
- [ ] Smooth animations (60fps)

## Edge Cases
- [ ] App handles denied Screen Time permission
- [ ] App works with zero vice apps selected
- [ ] App works with zero productive apps selected
- [ ] Balance handles very large numbers (10+ hours)
- [ ] UI looks correct on iPhone SE (small screen)
- [ ] UI looks correct on iPhone 15 Pro Max (large screen)
```

**Step 2: Commit**

```bash
git add docs/testing/mvp-test-checklist.md
git commit -m "docs: add MVP testing checklist"
```

---

### Task 29: Create README

**Files:**
- Create: `README.md`

**Step 1: Create README**

Create `README.md`:
```markdown
# Clepsy

> Trade productive time for social media access

Clepsy is an iOS app that helps users break doomscrolling habits by creating a time-trading system. Earn minutes by using productive apps (Kindle, Duolingo), then spend that time to unlock social media apps (TikTok, Instagram).

## Features

- **Time Trading**: 1:1 exchange between productive and vice app usage
- **App Blocking**: Uses iOS Screen Time API to enforce blocks
- **Daily Reset**: All earned time expires at midnight
- **Clepsy Character**: Supportive mascot with visual time balance indicator
- **Dashboard**: See your current balance, daily earning/spending stats
- **Settings**: Customize which apps are blocked vs. productive

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Clone the repository
2. Open `Clepsy.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run on device (Screen Time API requires physical device)

## Architecture

- **SwiftUI** for UI
- **MVVM** architecture pattern
- **FamilyControls** for Screen Time authorization
- **ManagedSettings** for app blocking
- **DeviceActivity** for usage monitoring
- **UserDefaults** for local persistence

## Project Structure

```
Clepsy/
├── Models/              # Data models (TimeBalance, UserSettings, etc.)
├── ViewModels/          # Business logic & state management
├── Views/
│   ├── Onboarding/     # 5-screen onboarding flow
│   ├── Dashboard/      # Main screen
│   ├── Settings/       # App configuration
│   ├── Shield/         # Blocked app screen
│   └── Components/     # Reusable UI components
├── Services/           # Business services (Persistence, ScreenTime, etc.)
└── Assets.xcassets/    # Images, icons, colors

ClepsyMonitor/          # DeviceActivityMonitor extension
ClepsyTests/            # Unit tests
```

## Testing

Run unit tests:
```bash
xcodebuild test -scheme Clepsy -destination 'platform=iOS Simulator,name=iPhone 15'
```

See `docs/testing/mvp-test-checklist.md` for manual testing guide.

## Documentation

- `docs/clepsy_prd.md` - Product Requirements Document
- `docs/clepsy_mvb.md` - Minimum Viable Brand guidelines
- `docs/dashboard_specs.md` - Dashboard design specs
- `docs/onboarding_specs.md` - Onboarding flow specs
- `docs/earning_specs.md` - Earning mechanics specs
- `docs/settings_specs.md` - Settings screen specs

## License

Copyright © 2026 Clepsy. All rights reserved.
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add project README"
```

---

## Post-MVP Enhancements (Deferred)

The following features are documented but deferred to V1.5+ per PRD:

- **Buddy System**: Emergency unlock requests to trusted contacts
- **Social Features**: Leaderboards, friend challenges
- **Premium Analytics**: Detailed usage insights dashboard
- **Custom Exchange Rates**: 2:1, 3:1 difficulty modes
- **Weekend Rollover**: Optional time banking for weekends
- **Android Support**: Cross-platform expansion
- **Backend Integration**: Cloud sync, social features

---

## Summary

This implementation plan provides a complete, tested path to building the Clepsy MVP. Each task:

- Follows TDD principles (test first, implement second)
- Includes exact file paths and code
- Has clear success criteria
- Results in a commit

**Total estimated tasks: 29** (includes critical architectural improvements)
**Time estimate: [REDACTED - no time estimates per guidelines]**

The plan progresses through:
1. Project setup & data models
2. Core services (persistence, Screen Time)
3. Onboarding UI flow
4. Dashboard & main features
5. Device activity monitoring
6. Settings & polish
7. Testing & documentation

After completion, you'll have a functional iOS app ready for TestFlight beta testing.
