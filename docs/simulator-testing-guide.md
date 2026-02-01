# Clepsy Simulator Testing Guide

> **Updated**: 2026-02-01
> **Purpose**: Maximize test coverage before physical device arrives

---

## **Overview**

Most of Clepsy can be tested on the iOS Simulator **except** Device Activity Monitoring (Phase 5). This guide explains what works, what doesn't, and testing strategies for MVP.

### **Can Test on Simulator ✅**
- Phases 1-4: Models, Services, Onboarding, Dashboard, App Entry
- Local persistence (UserDefaults)
- Navigation flows
- UI layouts
- Permissions rejection scenarios
- Daily reset logic (by changing Simulator time)

### **Cannot Test on Simulator ❌**
- Phase 5: DeviceActivityMonitor extension
- FamilyControls authorization (always denied on Simulator)
- Real app blocking/shielding
- Real DeviceActivityReport data
- Extension ↔ App communication (FileCoordination)

---

## **Testing Strategy**

### **Phase 1-4: Full Simulator Testing** ✅

All tasks 0-17 can run entirely on Simulator with high confidence. Use standard iOS testing:

```bash
# Run all unit tests
xcodebuild test -scheme Clepsy \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run with coverage
xcodebuild test -scheme Clepsy \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

**What to test manually on Simulator:**
1. App launches → Onboarding flow
2. Complete all 5 onboarding screens
3. Navigate to Dashboard
4. Settings screen loads
5. Toggle notifications
6. Add/remove apps (with mock data)
7. Persist data across app restarts

**Test daily reset by changing Simulator time:**

```bash
# In Simulator: Debug menu → Device → Clock → Set date/time
# Set to 11:50 PM
# Verify reset happens when clock hits midnight
# Or use Settings app to toggle date
```

### **Phase 5: Mock-Based Testing** 🎯

Device Activity Monitoring cannot run on Simulator. Instead, use **mocks + test buttons** on Dashboard:

#### **Step 1: Create Mock UsageTrackingService**

Add to `Clepsy/Services/UsageTrackingService.swift`:

```swift
#if DEBUG
extension UsageTrackingService {
    /// Test only: Simulate earning time without real DeviceActivity
    func simulateEarning(seconds: Int) {
        let event = TimeEvent(
            id: UUID(),
            seconds: seconds,
            timestamp: Date(),
            type: .earned,
            appBundleId: "com.amazon.Kindle" // Mock app
        )

        // Append to shared storage as if extension wrote it
        let sharedStorage = SharedStorageService()
        sharedStorage.appendEvent(event)
        print("✅ Simulated \(seconds)s earning")
    }

    /// Test only: Simulate spending time without real DeviceActivity
    func simulateSpending(seconds: Int) {
        let event = TimeEvent(
            id: UUID(),
            seconds: seconds,
            timestamp: Date(),
            type: .spent,
            appBundleId: "com.zhiliaoapp.musically" // Mock TikTok
        )

        let sharedStorage = SharedStorageService()
        sharedStorage.appendEvent(event)
        print("✅ Simulated \(seconds)s spending")
    }
}
#endif
```

#### **Step 2: Add Test Buttons to Dashboard**

In `Clepsy/Views/Dashboard/DashboardView.swift`, add test section:

```swift
#if DEBUG
VStack(alignment: .leading, spacing: 12) {
    Text("🧪 TEST CONTROLS (Simulator)")
        .font(.headline)
        .foregroundColor(.orange)
        .padding(.horizontal)

    Button(action: {
        // Simulate 15 min earning
        UsageTrackingService().simulateEarning(seconds: 900)
        viewModel.refreshBalance()
    }) {
        HStack {
            Image(systemName: "plus.circle.fill")
            Text("Earn 15 min (test)")
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.2))
        .cornerRadius(12)
    }
    .padding(.horizontal)

    Button(action: {
        // Simulate 5 min spending
        UsageTrackingService().simulateSpending(seconds: 300)
        viewModel.refreshBalance()
    }) {
        HStack {
            Image(systemName: "minus.circle.fill")
            Text("Spend 5 min (test)")
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.2))
        .cornerRadius(12)
    }
    .padding(.horizontal)

    Button(action: {
        // Force daily reset
        viewModel.checkAndPerformDailyReset()
    }) {
        HStack {
            Image(systemName: "arrow.clockwise.circle.fill")
            Text("Force Daily Reset (test)")
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.2))
        .cornerRadius(12)
    }
    .padding(.horizontal)
}
#endif
```

#### **Step 3: Test Earning/Spending Flow**

On Simulator:

1. Launch app
2. Complete onboarding
3. Tap "Earn 15 min" button
4. Verify balance increases (15 min)
5. Verify character sand level updates
6. Tap "Spend 5 min" button
7. Verify balance decreases (now 10 min)
8. Test "Force Daily Reset"
9. Verify balance → 0

### **Phase 5: Physical Device Testing** 📱

When device arrives, remove all `#if DEBUG` test code and test real phases:

1. **Real earning**: Open Kindle app → verify balance increases every 5 minutes
2. **Real spending**: Open TikTok (unlocked) → verify balance decreases
3. **Re-shielding**: Run out of balance → app should shield/lock
4. **Midnight reset**: Change device time to midnight → verify balance resets

---

## **Test Checklist for MVP (Simulator)**

### **Onboarding Flow** ✅

- [ ] App launches → Welcome screen
- [ ] Tap "Get Started" → How It Works screen
- [ ] Tap "Continue" → Permission Request screen
- [ ] Tap "Grant Permission" → shows iOS system dialog
- [ ] Deny permission → shows error state, "Retry" button works
- [ ] Grant permission → advances to App Selection screen
- [ ] Can search for apps
- [ ] Can toggle apps as vice/productive
- [ ] Minimum 1 vice + 1 productive required
- [ ] Tap "Ready" → completes onboarding, shows dashboard

### **Dashboard** ✅

- [ ] Displays current balance (starts at 0)
- [ ] Shows today's earned/spent (starts at 0)
- [ ] Clepsy character visible with sand level
- [ ] Settings button navigates to Settings view
- [ ] Test buttons visible (Simulator only)
- [ ] "Earn 15 min" increases balance
- [ ] "Spend 5 min" decreases balance
- [ ] Balance cannot go below 0
- [ ] Formatted time correct (e.g., "1h 30m")

### **Settings** ✅

- [ ] Displays vice/productive apps selected
- [ ] Can toggle notifications on/off
- [ ] Can tap "Reset Daily Stats"
- [ ] Can tap "Reset All Data" (clears everything)
- [ ] Version number displayed
- [ ] Back button returns to Dashboard

### **Persistence** ✅

- [ ] Close app (swipe up to kill)
- [ ] Relaunch app
- [ ] Balance persists
- [ ] Settings persist
- [ ] Onboarding completion persists

### **Daily Reset** ✅

- [ ] Tap "Force Daily Reset" button
- [ ] Balance → 0
- [ ] Tap "Earn 15 min"
- [ ] Balance = 15 min
- [ ] **Simulate next day**:
  - Open Settings → Date & Time
  - Toggle "Set Automatically" off
  - Change date to tomorrow
  - Close settings
  - Return to Clepsy
  - Tap "Force Daily Reset"
  - Balance should be 0 (reset occurred)

### **Error States** ✅

- [ ] **Permission Denied on Onboarding**:
  - Deny permission → shows error screen
  - Tap "Retry" → shows permission dialog again
  - Tap "I'll Do This Later" → completes onboarding but banner shows on dashboard

- [ ] **Permission Revoked After Setup**:
  - Complete onboarding with permission
  - Go to Settings app → Screen Time → Clepsy → toggle off
  - Return to Clepsy
  - Error banner appears on dashboard
  - Tap "Open Settings" → deep link works
  - Grant permission again
  - Banner disappears

### **UI/Layout** ✅

- [ ] Test on iPhone SE (small screen) - min size
- [ ] Test on iPhone 15 Pro Max (large screen)
- [ ] All text readable
- [ ] Tap targets ≥44×44pt
- [ ] Scrolling works smoothly
- [ ] No layout warnings (Debug → View Debugging)

---

## **Debugging on Simulator**

### **View Hierarchy**

```bash
# In Xcode Debug Navigator, use:
# Debug → View Debugging → Show View Hierarchy
# Helps identify layout/constraint issues
```

### **Console Logging**

Add to services:

```swift
print("✅ Event recorded: \(event.type) \(event.seconds)s")
print("🔄 Daily reset performed")
print("❌ Permission denied")
```

Then filter Console by search:

```
Filter: "✅" (for successful operations)
Filter: "❌" (for errors)
```

### **UserDefaults Inspection**

```bash
# Print all UserDefaults to console
defaults read com.clepsy.app

# Print just time balance
defaults read com.clepsy.app timeBalance
```

---

## **Known Simulator Limitations**

| Feature | Simulator | Device | Workaround |
|---------|-----------|--------|-----------|
| FamilyControls permission | ❌ Always denied | ✅ Works | Test error handling |
| DeviceActivityMonitor | ❌ Can't run | ✅ Works | Use mock buttons |
| App blocking/shielding | ❌ Can't test | ✅ Works | Verify logic in tests |
| Notifications | ⚠️ Local only | ✅ All types | Use local notifications |
| Background modes | ⚠️ Limited | ✅ Full | Foreground testing sufficient |
| Screen Time data | ❌ Unavailable | ✅ Real data | Mock via test buttons |

---

## **Transition to Physical Device**

When physical iPhone arrives:

1. **Remove test code**:
   ```bash
   git grep "#if DEBUG" -- '*.swift'  # Find all test code
   ```

2. **Update Task 18-21**:
   - Remove simulator workarounds
   - Implement real DeviceActivityMonitor
   - Remove test buttons from Dashboard

3. **Full E2E testing** (see `docs/testing/mvp-test-checklist.md`)

---

## **Questions?**

For Simulator-specific issues, check:
- Xcode Help → Simulator Documentation
- [Apple Developer Docs: Testing on Simulator](https://developer.apple.com/documentation/xcode/testing-your-app-with-xcode)
- [Screen Time API Limitations](https://developer.apple.com/documentation/familycontrols)
