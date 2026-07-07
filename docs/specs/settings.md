## **Settings Screen \- Complete Specification**

### **Screen Structure**

```
┌─────────────────────────────────────┐
│  ← Settings                         │ ← Nav bar with back button
├─────────────────────────────────────┤
│           ↓ Scroll Area ↓           │
│                                     │
│  Daily Goal                         │ ← Section 1 (P0)
│  ┌───────────────────────────────┐ │
│  │ 🎯 30 minutes              › │ │
│  └───────────────────────────────┘ │
│                                     │
│  Vice Apps                          │ ← Section 2 (P0)
│  ┌───────────────────────────────┐ │
│  │ 📱 Manage vice apps        › │ │
│  │    3 apps selected            │ │
│  └───────────────────────────────┘ │
│                                     │
│  Productive Apps                    │ ← Section 3 (P0)
│  ┌───────────────────────────────┐ │
│  │ ✅ Manage productive apps   › │ │
│  │    3 apps selected            │ │
│  └───────────────────────────────┘ │
│                                     │
│  Notifications                      │ ← Section 4 (P0)
│  ┌───────────────────────────────┐ │
│  │ 🔔 Milestone notifications    │ │
│  │    [Toggle: ON]               │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ ⏰ Milestone interval       › │ │
│  │    Every 15 minutes           │ │
│  └───────────────────────────────┘ │
│                                     │
│  Account & Data                     │ ← Section 5 (P0)
│  ┌───────────────────────────────┐ │
│  │ 📊 Reset all data          › │ │
│  └───────────────────────────────┘ │
│                                     │
│  About                              │ ← Section 6 (P0)
│  ┌───────────────────────────────┐ │
│  │ ℹ️ How Clepsy works         › │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ 📄 Privacy Policy          › │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ 📜 Terms of Service        › │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ 💬 Send Feedback           › │ │
│  └───────────────────────────────┘ │
│                                     │
│  Version 1.0.0 (Build 1)            │ ← Footer
│                                     │
└─────────────────────────────────────┘
```

---

## **Section 1: Daily Goal (P0)**

### **Goal Adjustment Row**

**Layout:**

```
┌───────────────────────────────────┐
│ 🎯 30 minutes              ›     │
└───────────────────────────────────┘
```

**Interaction:**

* **Tap:** Opens goal picker sheet (modal)

**Goal Picker Sheet:**

```
┌───────────────────────────────────┐
│     Set Your Daily Goal           │
│                                   │
│ How much time do you want to      │
│ spend on productive apps?         │
│                                   │
│   ( ) 15 minutes                  │
│   ( ) 30 minutes      ← Selected  │
│   ( ) 1 hour                      │
│   ( ) 2 hours                     │
│   ( ) Custom                      │
│                                   │
│  [Cancel]         [Save]          │
└───────────────────────────────────┘
```

**Custom option:**

* Opens number picker (15 min to 4 hours in 15-min increments)  
* Format: Scrolling wheel picker (iOS native)

**Behavior:**

* Changes take effect immediately  
* Dashboard goal progress updates on return  
* Clepsy sand level reflects new goal ratio

**Specs:**

* Background: `#2A3B4D` (Surface)  
* Border: 1px solid rgba(244, 162, 89, 0.2)  
* Border radius: 16pt  
* Padding: 16pt  
* Height: 64pt  
* Icon: 24pt emoji  
* Text: 17pt Semibold  
* Chevron: SF Symbol "chevron.right", 16pt, `#D4CFC4`

---

## **Section 2: Vice Apps (P0)**

### **Manage Vice Apps Row**

**Layout:**

```
┌───────────────────────────────────┐
│ 📱 Manage vice apps        ›     │
│    3 apps selected                │
└───────────────────────────────────┘
```

**Interaction:**

* **Tap:** Opens vice apps management screen

**Vice Apps Management Screen:**

```
┌─────────────────────────────────────┐
│  ← Vice Apps                        │
├─────────────────────────────────────┤
│ Select apps you want to block       │
│                                     │
│ [×] TikTok              [icon]      │
│ [×] Instagram           [icon]      │
│ [ ] Twitter/X           [icon]      │
│ [×] YouTube             [icon]      │
│ [ ] Facebook            [icon]      │
│ [ ] Reddit              [icon]      │
│ [ ] Snapchat            [icon]      │
│                                     │
│ [+ Add Custom App]                  │
│                                     │
│          [Done]                     │
└─────────────────────────────────────┘
```

**Features:**

* Checkbox list (multi-select)  
* Shows installed apps first, then common apps  
* "Add Custom App" → iOS app picker sheet  
* Minimum: 1 app required (can't uncheck all)  
* Changes save immediately, no "Save" button needed  
* "Done" button returns to settings

**Validation:**

* If user tries to uncheck last app: Alert

```
  "Need at least one vice app
  
  Clepsy needs to block at least one app.
  Add another vice app first."
  
  [OK]
```

**Specs:**

* Same card style as other settings rows  
* Subtitle shows count: "{X} apps selected"  
* Color: `#D4CFC4` (Text Secondary)

---

## **Section 3: Productive Apps (P0)**

### **Manage Productive Apps Row**

**Layout:**

```
┌───────────────────────────────────┐
│ ✅ Manage productive apps   ›    │
│    3 apps selected                │
└───────────────────────────────────┘
```

**Interaction:**

* **Tap:** Opens productive apps management screen

**Productive Apps Management Screen:**

```
┌─────────────────────────────────────┐
│  ← Productive Apps                  │
├─────────────────────────────────────┤
│ Select apps that help you learn,    │
│ read, or grow                       │
│                                     │
│ [×] Kindle              [icon]      │
│ [×] Duolingo            [icon]      │
│ [ ] Headspace           [icon]      │
│ [×] Notion              [icon]      │
│ [ ] Coursera            [icon]      │
│ [ ] Apple Books         [icon]      │
│ [ ] Khan Academy        [icon]      │
│                                     │
│ [+ Add Custom App]                  │
│                                     │
│          [Done]                     │
└─────────────────────────────────────┘
```

**Features:**

* Same mechanics as Vice Apps management  
* Minimum: 1 app required  
* Changes save immediately

**Validation:**

* Same as Vice Apps (need at least 1\)

---

## **Section 4: Notifications (P0)**

### **Milestone Notifications Toggle**

**Layout:**

```
┌───────────────────────────────────┐
│ 🔔 Milestone notifications        │
│    [Toggle: ON]                   │
└───────────────────────────────────┘
```

**Behavior:**

* iOS-style toggle switch (right side)  
* Default: ON  
* When OFF: Hides interval setting below  
* Changes save immediately

**Specs:**

* Toggle color (ON): `#4ECDC4` (Teal)  
* Toggle color (OFF): `#D4CFC4` (Muted)

---

### **Milestone Interval Row (conditional)**

**Layout:**

```
┌───────────────────────────────────┐
│ ⏰ Milestone interval       ›    │
│    Every 15 minutes               │
└───────────────────────────────────┘
```

**Visibility:**

* Only shows when milestone notifications toggle is ON  
* Hides when toggle is OFF

**Interaction:**

* **Tap:** Opens interval picker sheet

**Interval Picker Sheet:**

```
┌───────────────────────────────────┐
│    Milestone Interval             │
│                                   │
│ How often should we notify you?   │
│                                   │
│   (●) Every 15 minutes            │
│   ( ) Every 30 minutes            │
│   ( ) Every 1 hour                │
│                                   │
│  [Cancel]         [Save]          │
└───────────────────────────────────┘
```

**Options:**

* 15 minutes (default)  
* 30 minutes  
* 1 hour

**Note:** "Off" option removed here because toggle handles that

---

## **Section 5: Account & Data (P0)**

### **Reset All Data Row**

**Layout:**

```
┌───────────────────────────────────┐
│ 📊 Reset all data          ›     │
└───────────────────────────────────┘
```

**Interaction:**

* **Tap:** Shows confirmation alert (destructive action)

**Confirmation Alert:**

```
┌───────────────────────────────────┐
│     Reset All Data?               │
│                                   │
│ This will permanently delete:     │
│ • Your earning history            │
│ • Your streak progress            │
│ • Your app selections             │
│ • All settings                    │
│                                   │
│ Your goal will reset to 30 min.   │
│                                   │
│ This cannot be undone.            │
│                                   │
│  [Cancel]      [Reset Data]       │
└───────────────────────────────────┘
```

**Button styling:**

* "Reset Data" button: Red text (destructive)  
* "Cancel" button: Blue text (safe action)

**After reset:**

* Returns to onboarding (as if fresh install)  
* All data cleared from local storage  
* DeviceActivity history cleared

**Purpose:**

* Fresh start for users  
* Testing during development  
* Troubleshooting corrupted data

---

## **Section 6: About (P0)**

### **How Clepsy Works Row**

**Layout:**

```
┌───────────────────────────────────┐
│ ℹ️ How Clepsy works         ›    │
└───────────────────────────────────┘
```

**Interaction:**

* **Tap:** Opens informational screen

**How It Works Screen:**

```
┌─────────────────────────────────────┐
│  ← How Clepsy Works                 │
├─────────────────────────────────────┤
│                                     │
│ [Clepsy character illustration]     │
│                                     │
│ THE BASICS                          │
│                                     │
│ 1. Vice apps are blocked by default │
│    You can't open TikTok, Instagram,│
│    etc. without earned time.        │
│                                     │
│ 2. Earn time with productive apps   │
│    Use Kindle, Duolingo, etc. to    │
│    earn unlock time 1:1.            │
│                                     │
│ 3. Spend earned time guilt-free     │
│    Unlock vice apps for as long as  │
│    you've earned. Enjoy scrolling!  │
│                                     │
│ 4. Reset at midnight daily          │
│    Unused time expires. Fresh start │
│    every morning.                   │
│                                     │
│ EARNING DETAILS                     │
│                                     │
│ • 60-second warmup before tracking  │
│ • Screen must be unlocked           │
│ • Notifications every 15 min (opt.) │
│ • Balance updates every 5 min       │
│                                     │
└─────────────────────────────────────┘
```

**Purpose:**

* User education  
* Reference for mechanics  
* Onboarding refresher

---

### **Privacy Policy Row**

**Layout:**

```
┌───────────────────────────────────┐
│ 📄 Privacy Policy          ›     │
└───────────────────────────────────┘
```

**Interaction:**

* **Tap:** Opens in-app web view OR Safari  
* URL: `https://clepsy.app/privacy` (placeholder)

**Required by App Store:**

* Must have privacy policy for Screen Time API  
* Must disclose data collection (even if minimal)

**Content (example for MVP):**

```
PRIVACY POLICY

Clepsy does not collect, store, or share your data.

All data stays on your device:
- App selections
- Earning history  
- Settings preferences

We use Screen Time permission to:
- Block vice apps
- Track productive app usage

This data never leaves your device.

Contact: privacy@clepsy.app
Last updated: [Date]
```

---

### **Terms of Service Row**

**Layout:**

```
┌───────────────────────────────────┐
│ 📜 Terms of Service        ›     │
└───────────────────────────────────┘
```

**Interaction:**

* **Tap:** Opens in-app web view OR Safari  
* URL: `https://clepsy.app/terms` (placeholder)

**Required by App Store:**

* Standard ToS (AI-generated template is fine for MVP)

---

### **Send Feedback Row**

**Layout:**

```
┌───────────────────────────────────┐
│ 💬 Send Feedback           ›     │
└───────────────────────────────────┘
```

**Interaction:**

* **Tap:** Opens email composer

**Email Template:**

```
To: feedback@clepsy.app
Subject: Clepsy Feedback (iOS v1.0.0)

Device: [iPhone model]
iOS: [version]
App: v1.0.0 (Build 1)

---
[User writes feedback here]
```

**Alternative (simpler for MVP):**

* Just open mailto: link  
* User's default email app handles it

---

### **Version Footer**

**Layout:**

```
Version 1.0.0 (Build 1)
```

**Specs:**

* Font: SF Pro Text, 13pt, Regular  
* Color: `#D4CFC4` (Text Secondary)  
* Alignment: Center  
* Margin top: 40pt (spacer from last row)  
* Margin bottom: 20pt

**Format:**

* Version: Semantic versioning (1.0.0)  
* Build: Internal build number (increments each TestFlight/release)

---

## **Typography & Styling**

### **Section Headers**

```
Daily Goal
```

**Specs:**

* Font: SF Pro Text, 13pt, Semibold  
* Color: `#D4CFC4` (Text Secondary)  
* Transform: Uppercase  
* Letter spacing: 0.5pt  
* Margin top: 24pt (from previous section)  
* Margin bottom: 8pt

---

### **Settings Rows (Standard)**

```
┌───────────────────────────────────┐
│ [Icon] Title               [›]    │
│        Subtitle (optional)        │
└───────────────────────────────────┘
```

**Specs:**

* Background: `#2A3B4D` (Surface)  
* Border: 1px solid rgba(244, 162, 89, 0.2)  
* Border radius: 16pt  
* Padding: 16pt  
* Height: 64pt (without subtitle) or 80pt (with subtitle)  
* Gap between rows: 12pt

**Icon:**

* Size: 24pt emoji or SF Symbol  
* Color: `#F4A259` (if SF Symbol)  
* Position: Left, vertically centered

**Title:**

* Font: SF Pro Text, 17pt, Semibold  
* Color: `#F9F6F0` (Text Primary)

**Subtitle (optional):**

* Font: SF Pro Text, 15pt, Regular  
* Color: `#D4CFC4` (Text Secondary)  
* Margin top: 4pt

**Chevron:**

* SF Symbol: "chevron.right"  
* Size: 16pt  
* Color: `#D4CFC4` (Text Secondary)  
* Position: Right, vertically centered

---

### **Settings Rows (Toggle)**

```
┌───────────────────────────────────┐
│ [Icon] Title               [⚪]   │
└───────────────────────────────────┘
```

**Toggle specs:**

* iOS UISwitch component  
* ON color: `#4ECDC4` (Teal)  
* OFF color: `#D4CFC4` (Muted)  
* Position: Right, vertically centered

---

## **Navigation**

### **Entry Points**

**From Dashboard:**

* Tap gear icon (⚙️) in top-right nav bar

**From Other Screens:**

* Not directly accessible (must go through dashboard)

---

### **Exit Points**

**Back to Dashboard:**

* Tap "\< Settings" back button in nav bar  
* iOS swipe-from-left gesture

**Sub-screens (e.g., Manage Vice Apps):**

* Tap "\< Vice Apps" back button  
* Swipe-from-left gesture  
* "Done" button (explicit exit)

---

## **State Management**

### **What Persists**

Settings are saved to local storage immediately on change:

javascript

````javascript
{
  "dailyGoal": 30, // minutes
  "viceApps": ["com.zhiliaoapp.musically", "com.burbn.instagram", ...],
  "productiveApps": ["com.amazon.Lassen", "com.duolingo.DuolingoMobile", ...],
  "notificationsEnabled": true,
  "milestoneInterval": 15, // minutes (0 = off)
  "appVersion": "1.0.0",
  "buildNumber": 1
}
```

**No "Save" buttons needed** - changes apply immediately

---

## Error States

### **App Selection Conflicts**

**Scenario:** User adds same app to both vice and productive lists

**Prevention:**
- When selecting app in Vice Apps, remove from Productive Apps (if present)
- When selecting app in Productive Apps, remove from Vice Apps (if present)
- Show toast: "Moved {AppName} from {PreviousList}"

---

### **Minimum App Requirements**

**Scenario:** User tries to uncheck last vice/productive app

**Alert:**
```
┌───────────────────────────────────┐
│   Need at least one app           │
│                                   │
│ You need at least one vice app    │
│ to block. Add another app first.  │
│                                   │
│             [OK]                  │
└───────────────────────────────────┘
```

---

### **Permission Issues**

**Scenario:** User revoked Screen Time permission

**Show banner in settings:**
```
┌───────────────────────────────────┐
│ ⚠️ Permission Required            │
│                                   │
│ Clepsy can't work without Screen  │
│ Time permission. Enable it in     │
│ iOS Settings.                     │
│                                   │
│ [Open Settings]                   │
└───────────────────────────────────┘
````

**Banner placement:** Top of settings screen, above all sections

---

## **PRD Section: Settings**

Add this as **Journey 8: Settings Management** in your PRD:

markdown

````
### JOURNEY 8: Settings Management

**PRD Goal:** User can customize app behavior and manage preferences (P0)

**Entry Point:** Tap gear icon (⚙️) in dashboard nav bar

---

#### SETTINGS SECTIONS (P0 - Must Have)

**1. Daily Goal**
- Row: "🎯 {X} minutes ›"
- Tap: Opens goal picker sheet (15 min, 30 min, 1hr, 2hr, Custom)
- Changes apply immediately
- Dashboard goal progress updates on return

**2. Vice Apps Management**
- Row: "📱 Manage vice apps ›" + subtitle "{X} apps selected"
- Tap: Opens vice apps selection screen
- Checkbox list with common apps + "Add Custom"
- Minimum: 1 app required
- Changes save immediately

**3. Productive Apps Management**
- Row: "✅ Manage productive apps ›" + subtitle "{X} apps selected"
- Same mechanics as Vice Apps
- Minimum: 1 app required

**4. Notifications**
- Row: "🔔 Milestone notifications" + toggle switch
- Default: ON
- When enabled: Shows interval row below
- Row: "⏰ Milestone interval ›" (conditional)
- Tap: Opens picker (15 min, 30 min, 1 hour)
- Default: 15 minutes

**5. Account & Data**
- Row: "📊 Reset all data ›"
- Tap: Shows destructive confirmation alert
- Action: Clears all data, returns to onboarding
- Purpose: Fresh start, troubleshooting

**6. About**
- Row: "ℹ️ How Clepsy works ›"
  - Opens educational screen with app mechanics
- Row: "📄 Privacy Policy ›"
  - Opens web view to privacy policy URL
- Row: "📜 Terms of Service ›"
  - Opens web view to ToS URL
- Row: "💬 Send Feedback ›"
  - Opens email composer (feedback@clepsy.app)

**Footer:**
- "Version 1.0.0 (Build 1)" text
- Center-aligned, muted color

---

#### INTERACTION PATTERNS

**Immediate Save:**
- All settings changes save immediately (no "Save" button)
- No confirmation needed for non-destructive changes
- Only destructive action (Reset Data) requires confirmation

**Navigation:**
- Entry: Dashboard gear icon
- Exit: Back button or swipe gesture
- Sub-screens: Standard iOS navigation stack

**Validation:**
- Prevent < 1 vice app selected (show alert)
- Prevent < 1 productive app selected (show alert)
- Prevent same app in both lists (auto-move with toast)

---

#### DATA PERSISTENCE

Settings stored in local storage:
```json
{
  "dailyGoal": 30,
  "viceApps": ["app.id.1", "app.id.2"],
  "productiveApps": ["app.id.3", "app.id.4"],
  "notificationsEnabled": true,
  "milestoneInterval": 15
}
```

---

#### ERROR HANDLING

**Permission Revoked:**
- Show banner at top: "⚠️ Permission Required"
- Button: "Open Settings" (deep link to iOS Settings)

**App Selection Conflict:**
- Auto-resolve: Move app from old list to new list
- Show toast: "Moved {AppName} from {List}"

**Reset Data Failed:**
- Show alert: "Reset failed. Try again or reinstall app."

---

#### SUCCESS METRICS

- Settings completion rate: >90% (users don't abandon mid-flow)
- Goal adjustment frequency: Track to validate default (30 min)
- Notification disable rate: <20% (most users keep enabled)
- Reset data usage: <5% (should be rare)

---

#### NON-GOALS (MVP)

- Export/import settings
- Multiple user profiles
- App categories (Reading, Learning, etc.)
- Backup to cloud
- Sync across devices
````

