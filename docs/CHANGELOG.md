# Documentation Updates - 2026-02-01

> **Summary**: Critical architecture improvements, modern API standards, and Simulator testing strategy added before implementation begins.

---

## **What Changed**

### **1. Core Architecture: Modern APIs** 🔄

**File**: `docs/data-architecture.md`

**Change**: Replaced deprecated `.synchronize()` with **FileCoordination** (iOS 16+ standard)

**Why**:
- `.synchronize()` is deprecated since iOS 12
- FileCoordination is the modern standard for app + extension communication
- Atomic writes prevent partial data corruption
- More reliable than UserDefaults alone

**Code Impact**:
- `SharedStorageService` now uses `NSFileCoordinator`
- Maintains thread safety with serial `DispatchQueue`
- Works with App Group containers
- No external dependencies

**Details**: See `data-architecture.md` → "Syncing from Monitor Extension"

---

### **2. Timezone Handling: Simplified** 🌍

**File**: `docs/data-architecture.md` + `docs/plans/clepsy_mvp.md` (Task 17)

**Change**: Use device's current timezone only (removed complex timezone offset logic)

**Why MVP Decision**:
- Users don't travel 5 timezones in a single day
- Simplifies implementation by ~40 lines
- Uses native `Calendar.startOfDay()` API
- Easier to test and maintain

**Implementation**:
```swift
let calendar = Calendar.current
let todayStartOfDay = calendar.startOfDay(for: Date())
let lastResetStartOfDay = calendar.startOfDay(for: lastResetDate)

if todayStartOfDay > lastResetStartOfDay {
    performDailyReset()
}
```

**Details**: See `data-architecture.md` → "Daily Reset (Midnight)"

---

### **3. New Task: Earning Session Manager** ⭐

**File**: `docs/plans/clepsy_mvp.md` → **Task 21B** (new, inserted between Task 21 & 22)

**Purpose**: Implements earning mechanics that were missing from original plan

**Implements** (from `earning_specs.md`):
- ✅ 60-second warmup before tracking starts
- ✅ 2-minute timeout to pause/resume sessions
- ✅ 5-minute balance update frequency
- ✅ Session end → credit balance
- ✅ Comprehensive test coverage

**Impact**:
- MVP now has full earning mechanics specified
- Includes TDD tests
- Fills gap between original plan and earning_specs

**Details**: See `docs/plans/clepsy_mvp.md` → **Task 21B**

---

### **4. Task 16 Update: Error Banner** 🔴

**File**: `docs/plans/clepsy_mvp.md` → Task 16 + `dashboard_specs.md`

**Change**: Dashboard now includes error banner for permission denied scenario

**Scope**:
- Detects when FamilyControls authorization is revoked
- Shows warning banner at top of dashboard
- Includes "Open Settings" deep link
- Banner dismisses when permission granted

**Visual Specs**: See `dashboard_specs.md` → "Section 3.1B: Error Banner"

**Implementation Reference**: See `error_state_specs.md` → "Error 1B: Permission Revoked"

---

### **5. Task 20 Update: FileCoordination** 📁

**File**: `docs/plans/clepsy_mvp.md` → Task 20

**Change**: `SharedStorageService` now uses modern FileCoordination API

**Benefits**:
- Atomic file writes (no partial data corruption)
- Thread-safe between app + extension
- Handles concurrent access safely
- iOS 16+ standard practice

**Code**: See `docs/plans/clepsy_mvp.md` → Task 20 → Step 3

---

### **6. New Document: Simulator Testing Guide** 🧪

**File**: `docs/simulator-testing-guide.md` (new)

**Purpose**: Maximize test coverage before physical device arrives

**Includes**:
- ✅ What can/can't test on Simulator
- ✅ Mock strategies for DeviceActivity
- ✅ Test buttons for Dashboard
- ✅ Step-by-step test checklist
- ✅ Daily reset testing (by changing device time)
- ✅ Permission error scenario testing
- ✅ Debugging tips

**Key Strategy**:
- Phase 1-4 (Tasks 0-17): Full Simulator testing ✅
- Phase 5 (Tasks 18-21): Mock-based testing with test buttons 🎯
- Device arrives: Remove mocks, test real DeviceActivityMonitor 📱

**Details**: See `docs/simulator-testing-guide.md`

---

### **7. Earning Specs Reference** 🔗

**File**: `earning_specs.md`

**Change**: Added reference to Task 21B at top of document

**Purpose**: Link specifications to implementation task

---

## **Total Changes Summary**

| Document | Type | Changes | Status |
|----------|------|---------|--------|
| `data-architecture.md` | Updated | FileCoordination, simplified timezone handling | ✅ Complete |
| `docs/plans/clepsy_mvp.md` | Updated | Task 17, 20 clarifications; Task 21B added | ✅ Complete |
| `dashboard_specs.md` | Updated | Error banner section (3.1B) added | ✅ Complete |
| `docs/simulator-testing-guide.md` | NEW | Complete Simulator testing strategy | ✅ Complete |
| `earning_specs.md` | Updated | Reference to Task 21B added | ✅ Complete |

---

## **Task Count**

**Before**: 29 tasks (0-29)
**After**: 30 tasks (0-30, with Task 21B inserted between 21 & 22)

**Phases**:
- Phase 1: Tasks 0-6 (Setup + Core Models)
- Phase 2: Tasks 7-13 (Onboarding)
- Phase 3: Tasks 14-17 (Dashboard + App Entry)
- Phase 4: Tasks 18-21B (Device Activity Monitoring)
- Phase 5: Tasks 22-30 (Settings, Assets, Testing)

---

### **7. Tasks 26-27 Update: Asset Alignment** 🎨

**File**: `docs/plans/clepsy_mvp.md` → Tasks 26 & 27

**Change**: Fixed asset naming to match actual files in `clepsy_app_images/`

**Problem Found**:
- Original plan used wrong names: `clepsy_face_patient`, `clepsy_body_20`
- Wrong intervals: 20% (should be 25%)
- Wrong count: 6 body levels (actually 5)

**Fixed To Match Your Assets**:

**Faces** (3 expressions):
- ✅ `patience_face` (not `clepsy_face_patient`)
- ✅ `encouraging_face` (not `clepsy_face_encouraging`)
- ✅ `celebrating_face` (not `clepsy_face_celebrating`)

**Bodies** (5 sand levels, 25% intervals):
- ✅ `body_level_0`, `body_level_25`, `body_level_50`, `body_level_75`, `body_level_100`
- ❌ Not: `clepsy_body_0`, `clepsy_body_20`, `clepsy_body_40`...

**Implementation Details**:
```swift
// Correct asset mapping (Task 27)
switch fillPercentage {
case 0..<0.125: return "body_level_0"      // 0-12.5%
case 0.125..<0.375: return "body_level_25" // 12.5-37.5%
case 0.375..<0.625: return "body_level_50" // 37.5-62.5%
case 0.625..<0.875: return "body_level_75" // 62.5-87.5%
default: return "body_level_100"           // 87.5-100%
}
```

**Decoupled Layering** (from asset guide):
```swift
ZStack {
    Image("body_level_50")     // Layer 1: Body (changes with balance)
    Image("patience_face")     // Layer 2: Face (changes with context)
}
.frame(width: 240, height: 320) // Canvas size from guide
```

**Animation Specs**:
- Amplitude: 10pt (8-10pt range)
- Duration: 3.5 seconds
- Type: Vertical float (Y-axis offset)
- Applied to entire ZStack (face + body move together)

**Total Assets**: 27 PNG files (3 faces × 3 scales + 5 bodies × 3 scales)

**Reference**: All specs from `clepsy_app_images/clepsy_mascot_asset_guide.md`

---

## **What This Means for Implementation**

### **Ready to Start** ✅
- Architecture is modernized (no deprecated APIs)
- All tasks documented with TDD approach
- Simulator testing strategy clear
- Gap filled (Earning Session Manager)

### **Before Task 0**
- Review this document
- Familiarize with FileCoordination pattern
- Understand Simulator testing approach

### **During Implementation**
- Follow test-driven development (red → green → refactor)
- Use test buttons on Simulator until physical device arrives
- Refer to `simulator-testing-guide.md` for Simulator limits

### **Before Device Testing**
- Remove all `#if DEBUG` test code
- Implement real DeviceActivityMonitor (Tasks 18-21)
- Run full E2E checklist from `docs/testing/mvp-test-checklist.md`

---

## **Questions Before Starting?**

1. **FileCoordination complexity**: Is the NSFileCoordinator pattern clear?
2. **Simulator testing strategy**: Does mock-based approach work for your workflow?
3. **New Task 21B**: Does Earning Session Manager feel like the right scope?
4. **Task count**: Are 30 tasks the right breakdown?

---

## **Ready to Begin Task 0?**

Once you approve these changes, we can start:
1. **Task 0**: Project setup with Xcode
2. **Tasks 1-3**: Core models (TDD style)
3. Continue through phases...

Let me know if you want me to adjust anything before we dive into implementation!
