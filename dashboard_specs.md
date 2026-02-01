# **CLEPSY DASHBOARD SPECIFICATIONS**

**Complete Dashboard Design & Requirements for MVP**  
 **Version 1.0 • January 2026**

---

## **TABLE OF CONTENTS**

1. Dashboard Purpose & Scope  
2. Complete Layout Specification  
3. Component Details  
4. Interaction Patterns  
5. Typography & Spacing  
6. Color Usage  
7. State Management  
8. PRD Requirements Section

---

## **1\. DASHBOARD PURPOSE & SCOPE**

### **What is the Dashboard?**

The dashboard is the **main hub** of the Clepsy app where users:

* Check their current balance (available time to spend)  
* Monitor daily goal progress (motivational)  
* View today's activity (earned/spent breakdown)  
* Access vice apps to unlock  
* Access productive apps to launch  
* Navigate to settings

### **When Users See Dashboard**

**Primary access point:**

* User opens Clepsy app directly (home screen icon)  
* After completing onboarding  
* After dismissing a shield screen  
* From "Earn Time Now" button on shield

**NOT the first thing users see when:**

* Opening a blocked vice app (Shield screen appears instead)

---

## **2\. COMPLETE LAYOUT SPECIFICATION**

### **Screen Structure (iPhone 14 Pro \- 393×852pt)**

```
┌─────────────────────────────────────┐
│  Clepsy              [⚙️]           │ ← Nav bar (44pt height)
├─────────────────────────────────────┤
│           ↓ Scroll Area ↓           │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  [Clepsy Character]           │ │ ← Balance Hero Card
│  │       75% sand level          │ │   (320pt height)
│  │                               │ │
│  │     YOUR BALANCE              │ │
│  │    47 minutes                 │ │
│  │  Available to spend           │ │
│  │                               │ │
│  │ Today: 52 min earned, 5 spent │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ Daily Goal: 30 min      75%   │ │ ← Goal Progress Card
│  │ ████████████░░░░░░░░░░        │ │   (120pt height)
│  │ 23 of 30 min earned           │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🔥 7 Day Streak!         [×]  │ │ ← Streak Banner
│  │ You're building a real habit  │ │   (80pt height)
│  └───────────────────────────────┘ │   (conditional)
│                                     │
│  Today's Stats                      │ ← Section header
│  ┌──────────────┐ ┌──────────────┐ │
│  │ ↗ Time Earned│ │ ⏱ Time Spent │ │ ← Stat Cards
│  │    52 min    │ │    5 min     │ │   (100pt height each)
│  │  From 3 apps │ │  On TikTok   │ │
│  └──────────────┘ └──────────────┘ │
│                                     │
│  Vice Apps                          │ ← Section header
│  ┌───────────────────────────────┐ │
│  │ [📷] Instagram        [Vice]  │ │ ← App Card
│  │      15 min spent today       │ │   (64pt height)
│  │      Tap to unlock            │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ [▶️] YouTube          [Vice]  │ │
│  │      7 min spent today        │ │
│  │      Tap to unlock            │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ [🐦] Twitter          [Vice]  │ │
│  │      0 min today              │ │
│  │      Tap to unlock            │ │
│  └───────────────────────────────┘ │
│                                     │
│  Productive Apps                    │ ← Section header
│  ┌───────────────────────────────┐ │
│  │ [🦉] Duolingo    [Productive] │ │ ← App Card
│  │      23 min earned            │ │   (64pt height)
│  │      Tap to open              │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ [📖] Kindle       [Productive]│ │
│  │      12 min earned            │ │
│  │      Tap to open              │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ [💪] Nike Training [Productive]│ │
│  │      3 min earned             │ │
│  │      Tap to open              │ │
│  └───────────────────────────────┘ │
│                                     │
│        ↑ Scroll Area ↑              │
└─────────────────────────────────────┘
```

### **Screen Dimensions Summary**

| Element | Height | Notes |
| ----- | ----- | ----- |
| Nav bar | 44pt | Fixed at top |
| Balance hero card | 320pt | Includes Clepsy \+ balance |
| Goal progress card | 120pt | Shows daily goal |
| Streak banner | 80pt | Conditional (milestone only) |
| Stat card | 100pt | Side-by-side, 2 cards |
| Section header | 32pt | "Vice Apps", "Productive Apps" |
| App card | 64pt | Tap target minimum met |
| Card gaps | 16pt | Between all cards |
| Screen padding | 24pt | Left/right margins |

**Total scrollable height:** \~1200pt (varies based on \# of apps)

---

## **3\. COMPONENT DETAILS**

### **3.1 Navigation Bar**

**Layout:**

```
┌─────────────────────────────────────┐
│  Clepsy              [⚙️ Settings]  │
└─────────────────────────────────────┘
```

**Specifications:**

* Height: 44pt (iOS standard)  
* Background: \#1E2A3A (Midnight Blue)  
* Padding: 16pt left/right  
* No border (blends with background)

**Left side \- App name:**

* Text: "Clepsy"  
* Font: SF Pro Display, 20pt, Semibold  
* Color: \#F9F6F0 (Text Primary)

**Right side \- Settings button:**

* Icon: SF Symbol "gearshape.fill"  
* Size: 24pt  
* Color: \#F4A259 (Sand Gold)  
* Tap target: 44×44pt  
* Action: Opens settings screen

---

### **3.2 Balance Hero Card**

**Purpose:** Show current spendable balance and Clepsy character

**Layout:**

```
┌───────────────────────────────────┐
│                                   │
│     [Clepsy Character]            │
│      240×320pt, 75% sand          │
│                                   │
│         YOUR BALANCE              │
│        47 minutes                 │
│     Available to spend            │
│                                   │
│  Today: 52 min earned, 5 min spent│
│                                   │
└───────────────────────────────────┘
```

**Card Specifications:**

* Background: \#2A3B4D (Surface)  
* Border: 2px solid \#F4A259 (Sand Gold)  
* Border radius: 24pt  
* Padding: 32pt all sides  
* Total height: 320pt  
* Shadow: 0px 4px 20px rgba(0, 0, 0, 0.25)

**Clepsy Character:**

* Size: 180×240pt (medium, not large like shield)  
* Position: Centered horizontally, top of card  
* Sand level: Based on goal progress (not balance)  
* State: Patient (😊) for dashboard  
* Margin bottom: 16pt

**"YOUR BALANCE" Label:**

* Font: SF Pro Text, 13pt, Regular  
* Color: \#D4CFC4 (Text Secondary)  
* Letter spacing: 1pt (uppercase tracking)  
* Transform: Uppercase  
* Margin bottom: 4pt

**Balance Number (47 minutes):**

* Font: SF Pro Display, 48pt, Bold  
* Color: \#F4A259 (Sand Gold)  
* "47" \= Number  
* "minutes" \= Unit (20pt, Regular, same color)  
* Line height: 1.1  
* Margin bottom: 4pt

**"Available to spend" Subtext:**

* Font: SF Pro Text, 15pt, Regular  
* Color: \#D4CFC4 (Text Secondary)  
* Margin bottom: 16pt

**Today's Summary Line:**

* Font: SF Pro Text, 15pt, Regular  
* Color: \#F9F6F0 (Text Primary)  
* Format: "Today: {earned} min earned, {spent} spent"  
* "earned" number in \#4ECDC4 (Teal)  
* "spent" number in \#FF8C42 (Orange)

---

### **3.3 Goal Progress Card**

**Purpose:** Show daily productivity goal progress

**Layout:**

```
┌───────────────────────────────────┐
│ 🎯 Daily Goal: 30 min       75%   │
│ ████████████░░░░░░░░░░░░░░        │
│ 23 of 30 min earned today         │
└───────────────────────────────────┘
```

**Card Specifications:**

* Background: \#2A3B4D (Surface)  
* Border: 1px solid rgba(244, 162, 89, 0.3) (subtle gold)  
* Border radius: 20pt  
* Padding: 20pt all sides  
* Total height: 120pt  
* Margin top: 16pt (from balance card)

**Header Row:**

* Icon: 🎯 or SF Symbol "target"  
* Text: "Daily Goal: {amount} min"  
* Font: SF Pro Text, 17pt, Semibold  
* Color: \#F9F6F0 (Text Primary)  
* Percentage: Same line, right-aligned  
* Percentage color: \#4ECDC4 (Teal) if \>50%, \#F4A259 if \<50%

**Progress Bar:**

* Height: 8pt  
* Background: \#1E2A3A (darker, recessed)  
* Fill: Gradient from \#4ECDC4 to \#F4A259 (Teal → Gold)  
* Border radius: 4pt  
* Margin: 12pt top/bottom

**Progress Text:**

* Font: SF Pro Text, 15pt, Regular  
* Color: \#D4CFC4 (Text Secondary)  
* Format: "{current} of {goal} min earned today"

---

### **3.4 Streak Banner (Conditional)**

**Purpose:** Celebrate achievement milestones

**Layout:**

```
┌───────────────────────────────────┐
│ 🔥 7 Day Streak!             [×]  │
│ You're building a real habit here │
└───────────────────────────────────┘
```

**When to Show:**

* User hits milestone: 7, 14, 21, 30, 60, 90 days  
* Shows once per milestone  
* User can dismiss with \[×\] button  
* Once dismissed, doesn't reappear for that milestone  
* Next milestone triggers new banner

**Card Specifications:**

* Background: Gradient from \#F4A259 to \#FF8C42 (Gold → Orange)  
* No border  
* Border radius: 20pt  
* Padding: 20pt  
* Total height: 80pt  
* Margin: 16pt top

**Content:**

* Icon: 🔥 emoji, 28pt  
* Title: "{X} Day Streak\!"  
* Font: SF Pro Display, 20pt, Bold  
* Color: \#FFFFFF (White for contrast on gradient)  
* Subtitle: Encouraging message  
* Font: SF Pro Text, 15pt, Regular  
* Color: rgba(255, 255, 255, 0.9)

**Close Button \[×\]:**

* SF Symbol: "xmark"  
* Size: 16pt  
* Color: rgba(255, 255, 255, 0.8)  
* Position: Top-right corner (12pt from edges)  
* Tap target: 32×32pt  
* Action: Dismisses banner, saves to local storage

**State Management:**

```javascript
// Pseudocode
milestones = [7, 14, 21, 30, 60, 90, 180, 365]
dismissedMilestones = localStorage.get('dismissedStreaks') || []

if (currentStreak >= milestone && !dismissedMilestones.includes(milestone)) {
  showBanner(milestone)
}

onDismiss(milestone) {
  dismissedMilestones.push(milestone)
  localStorage.set('dismissedStreaks', dismissedMilestones)
}
```

---

### **3.5 Today's Stats Cards**

**Purpose:** Quick view of earned vs spent

**Layout:**

```
Today's Stats

┌──────────────┐ ┌──────────────┐
│ ↗ Time Earned│ │ ⏱ Time Spent │
│    52 min    │ │    5 min     │
│  From 3 apps │ │  On TikTok   │
└──────────────┘ └──────────────┘
```

**Section Header:**

* Text: "Today's Stats"  
* Font: SF Pro Display, 22pt, Semibold  
* Color: \#F9F6F0 (Text Primary)  
* Margin: 24pt top, 12pt bottom

**Stat Card (Earned) \- Left:**

* Background: \#2A3B4D (Surface)  
* Border: 2px solid \#4ECDC4 (Teal \- earning color)  
* Border radius: 16pt  
* Padding: 16pt  
* Width: calc(50% \- 8pt)  
* Height: 100pt

**Stat Card (Spent) \- Right:**

* Same as earned but border: 2px solid \#FF8C42 (Orange)

**Card Content:**

* Icon: SF Symbol, 20pt, color matches border  
  * Earned: "arrow.up.right" (\#4ECDC4)  
  * Spent: "clock.fill" (\#FF8C42)  
* Label: "Time Earned" / "Time Spent"  
  * Font: SF Pro Text, 13pt, Regular  
  * Color: \#D4CFC4 (Text Secondary)  
* Number: "52 min"  
  * Font: SF Pro Display, 28pt, Bold  
  * Color: \#F9F6F0 (Text Primary)  
* Context: "From 3 apps" / "On TikTok"  
  * Font: SF Pro Text, 13pt, Regular  
  * Color: \#D4CFC4 (Text Secondary)

**Gap between cards:** 16pt

---

### **3.6 App Cards (Vice & Productive)**

**Purpose:** Show app usage and provide tap-to-action

**Section Header:**

* Text: "Vice Apps" / "Productive Apps"  
* Font: SF Pro Display, 22pt, Semibold  
* Color: \#F9F6F0 (Text Primary)  
* Margin: 24pt top, 12pt bottom

**Card Layout:**

```
┌───────────────────────────────────┐
│ [Icon] App Name        [Badge]    │
│        Subtitle                   │
│        Action hint                │
└───────────────────────────────────┘
```

**Card Specifications:**

* Background: \#2A3B4D (Surface)  
* Border: 1px solid rgba(244, 162, 89, 0.2) (subtle gold)  
* Border radius: 16pt  
* Padding: 16pt all sides  
* Height: 64pt (meets 44pt tap target minimum)  
* Gap between cards: 12pt  
* Tap target: Entire card is tappable

**App Icon:**

* Size: 40×40pt  
* Position: Left, vertically centered  
* Border radius: 10pt (rounded square)  
* If no custom icon: Use colored circle with first letter

**App Name:**

* Font: SF Pro Text, 17pt, Semibold  
* Color: \#F9F6F0 (Text Primary)  
* Position: Next to icon, top-aligned

**Badge (Vice/Productive):**

* Background: rgba(244, 162, 89, 0.2) for Vice (Orange tint)  
* Background: rgba(78, 205, 196, 0.2) for Productive (Teal tint)  
* Border: 1px solid color (Orange or Teal)  
* Border radius: 8pt  
* Padding: 4pt 8pt  
* Font: SF Pro Text, 11pt, Semibold  
* Text color: Matches border  
* Position: Top-right corner

**Subtitle (time info):**

* Font: SF Pro Text, 15pt, Regular  
* Color: \#D4CFC4 (Text Secondary)  
* Format:  
  * Vice: "{X} min spent today" or "0 min today"  
  * Productive: "{X} min earned"

**Action Hint:**

* Font: SF Pro Text, 13pt, Regular  
* Color: \#F4A259 (Sand Gold \- draws attention)  
* Format:  
  * Vice: "Tap to unlock"  
  * Productive: "Tap to open"  
* Position: Below subtitle

**Sorting:**

* Vice apps: Most used today (top)  
* Productive apps: Most earned today (top)  
* Apps with 0 usage: Bottom (alphabetical)

---

## **4\. INTERACTION PATTERNS**

### **4.1 Pull to Refresh**

**Trigger:** User pulls down from top of scroll area

**Behavior:**

* Shows iOS spinner at top  
* Queries DeviceActivityReport for latest data  
* Updates balance, goal progress, app stats  
* Completes in 1-2 seconds  
* Spinner disappears

**When to use:**

* User suspects balance is stale  
* After earning session, checking if time accumulated

---

### **4.2 Tap Vice App Card (Unlock)**

**User taps:** Instagram card

**Step 1 \- Show confirmation sheet:**

```
┌───────────────────────────────────┐
│         Unlock Instagram?         │
│                                   │
│  You have 47 min available        │
│  How long do you want?            │
│                                   │
│  [ 15 min ] [ 30 min ] [ 1 hour ] │
│  [        All (47 min)          ] │
│                                   │
│  [Cancel]        [Unlock →]       │
└───────────────────────────────────┘
```

**Sheet specifications:**

* Modal sheet, slides up from bottom  
* Background: \#2A3B4D (Surface)  
* Border radius: 24pt top corners  
* Padding: 24pt

**Duration buttons:**

* Preset options: 15 min, 30 min, 1 hour  
* "All" option shows current balance  
* Radio button selection (single select)  
* Selected: Gold border, filled background

**Action buttons:**

* Cancel: Ghost button, closes sheet  
* Unlock: Primary CTA (gold background)

**Step 2 \- User confirms:**

* DeviceActivity unlocks Instagram  
* Balance deducts by selected amount  
* Instagram app launches  
* Sheet dismisses

**Step 3 \- Dashboard updates:**

* Balance number decreases  
* Spent stat increases  
* Instagram card shows updated time

---

### **4.3 Tap Productive App Card (Launch)**

**User taps:** Duolingo card

**Behavior:**

* Immediately launches Duolingo app natively  
* No confirmation needed (they want to earn)  
* DeviceActivityMonitor starts tracking  
* Dashboard exits to background

**When user returns to dashboard:**

* Pull to refresh shows updated earned time  
* Or auto-refreshes on app open

---

### **4.4 Tap Settings Icon**

**User taps:** Gear icon in nav bar

**Behavior:**

* Navigates to Settings screen  
* Slides in from right (iOS standard)  
* Back button returns to dashboard

---

### **4.5 Dismiss Streak Banner**

**User taps:** \[×\] button on streak banner

**Behavior:**

* Banner animates out (fade \+ slide up)  
* Preference saved to local storage  
* Dashboard reflows (cards move up)  
* Banner does not reappear for this milestone

---

## **5\. TYPOGRAPHY & SPACING**

### **Typography System**

| Element | Font | Size | Weight | Color |
| ----- | ----- | ----- | ----- | ----- |
| Nav bar title | SF Pro Display | 20pt | Semibold | \#F9F6F0 |
| Hero balance label | SF Pro Text | 13pt | Regular | \#D4CFC4 |
| Hero balance number | SF Pro Display | 48pt | Bold | \#F4A259 |
| Hero subtext | SF Pro Text | 15pt | Regular | \#D4CFC4 |
| Section header | SF Pro Display | 22pt | Semibold | \#F9F6F0 |
| Card title | SF Pro Text | 17pt | Semibold | \#F9F6F0 |
| Card body | SF Pro Text | 15pt | Regular | \#D4CFC4 |
| Badge | SF Pro Text | 11pt | Semibold | Contextual |
| Action hint | SF Pro Text | 13pt | Regular | \#F4A259 |

### **Spacing Scale (8pt Grid)**

| Usage | Size |
| ----- | ----- |
| Card internal padding | 16-24pt |
| Gap between cards | 12-16pt |
| Section spacing | 24pt |
| Screen margins | 24pt left/right |
| Element gaps (small) | 4-8pt |
| Element gaps (medium) | 12-16pt |

---

## **6\. COLOR USAGE**

### **Dashboard-Specific Color Mapping**

| Element | Color | Hex | Purpose |
| ----- | ----- | ----- | ----- |
| Screen background | Midnight Blue | \#1E2A3A | Primary BG |
| Card background | Surface | \#2A3B4D | Elevated elements |
| Primary accent | Sand Gold | \#F4A259 | Balance, CTAs, badges |
| Earning indicator | Accent Teal | \#4ECDC4 | Goal progress, earned stats |
| Spending indicator | Warning Orange | \#FF8C42 | Spent stats, caution |
| Text primary | Light Cream | \#F9F6F0 | Main content |
| Text secondary | Muted Cream | \#D4CFC4 | Labels, metadata |
| Borders (cards) | Gold 20% | rgba(244,162,89,0.2) | Subtle separation |
| Borders (emphasis) | Gold 100% | \#F4A259 | Hero card, important elements |

---

## **7\. STATE MANAGEMENT**

### **Dashboard Data Requirements**

**What data needs to be fetched:**

1. Current balance (from DeviceActivityReport)  
2. Today's earned minutes (total across all productive apps)  
3. Today's spent minutes (total across all vice apps)  
4. Daily goal amount (from user settings)  
5. Daily goal progress % (earned / goal \* 100\)  
6. Per-app usage (earned and spent breakdown)  
7. Current streak count (consecutive days with earning activity)

**Data refresh triggers:**

* App opens (fresh data)  
* Pull to refresh (manual)  
* Background to foreground (if \>5 min elapsed)  
* After unlocking vice app (balance changes)  
* After milestone notification (streak updated)

**Loading states:**

**Initial load (first open):**

```
[Skeleton screens showing placeholders]
Balance: "-- min"
Goal: Loading bar animation
App cards: Grey placeholders
```

**Pull to refresh:**

```
[Spinner at top]
Data updates smoothly (no flicker)
```

**Stale data warning:**

```
If DeviceActivityReport fails:
Show banner: "⚠️ Can't update balance. Pull to refresh."
```

---

## **8\. PRD REQUIREMENTS SECTION**

Add this to your PRD as **Journey 7: Dashboard View**

```
### JOURNEY 7: Dashboard View

**PRD Goal:** Central hub for status checking and taking action (P0)

**When User Sees Dashboard:**
- Opens Clepsy app directly (not from blocked app)
- After completing onboarding
- After dismissing shield screen
- From "Earn Time Now" button on shield

**Screen Elements (P0 - Must Have):**

1. **Navigation Bar**
   - App name: "Clepsy"
   - Settings icon (gear, top-right)
   - Height: 44pt

2. **Balance Hero Card**
   - Clepsy character (goal-based sand level)
   - Current balance (large, 48pt)
   - "Available to spend" label
   - Today's earned/spent summary
   - Card height: 320pt

3. **Goal Progress Card**
   - Daily goal amount display
   - Progress percentage
   - Visual progress bar (gradient: Teal → Gold)
   - "X of Y min earned today" text
   - Card height: 120pt

4. **Today's Stats Cards** (side-by-side)
   - Time Earned card (Teal border)
   - Time Spent card (Orange border)
   - Shows source context ("From 3 apps", "On TikTok")
   - Card height: 100pt each

5. **Vice Apps List**
   - App icon, name, badge
   - Minutes spent today
   - "Tap to unlock" hint
   - Sorted by usage (most used first)
   - Card height: 64pt each

6. **Productive Apps List**
   - App icon, name, badge
   - Minutes earned
   - "Tap to open" hint
   - Sorted by earned time (most earned first)
   - Card height: 64pt each

**Optional Elements (P1 - Conditional):**

7. **Streak Banner** (milestone achievements only)
   - Shows at 7, 14, 21, 30, 60, 90 day milestones
   - Dismissible with [×] button
   - Gradient background (Gold → Orange)
   - Height: 80pt

**Interactions (P0):**

1. **Pull to Refresh**
   - Gesture: Pull down from top
   - Action: Queries DeviceActivityReport
   - Updates: Balance, goal progress, app stats
   - Duration: 1-2 seconds

2. **Tap Vice App Card**
   - Shows confirmation sheet
   - Options: 15 min, 30 min, 1 hour, All
   - User selects duration
   - Unlocks app, deducts balance
   - Launches app natively

3. **Tap Productive App Card**
   - Immediately launches app natively
   - No confirmation needed
   - DeviceActivityMonitor starts tracking
   - Background: Dashboard exits

4. **Tap Settings Icon**
   - Navigates to Settings screen
   - Slides in from right (iOS pattern)

5. **Dismiss Streak Banner**
   - Tap [×] button
   - Banner fades out
   - Saves dismissed state
   - Does not reappear for this milestone

**Data Requirements (P0):**

- Current balance (real-time from DeviceActivityReport)
- Today's earned minutes (aggregate)
- Today's spent minutes (aggregate)
- Daily goal amount (from settings)
- Goal progress percentage (calculated)
- Per-app breakdown (earned and spent)
- Current streak count (days)

**Refresh Triggers:**
- App opens (initial load)
- Pull to refresh (manual)
- Background → foreground (if >5 min elapsed)
- After unlock action (balance changed)

**Loading States:**
- Initial: Skeleton screens
- Refresh: Spinner at top
- Error: Warning banner with retry

**Success Metrics:**
- Time to first data load: <2 seconds
- Pull to refresh completion: <2 seconds
- Tap to unlock → app opens: <1 second
- Tap to open productive app: <500ms

**Non-Goals (Defer to V1.5):**
- Weekly goal progress
- Historical stats (past days)
- Achievement badges
- Social features
- Custom app categories
```

---

## **APPENDIX: Quick Reference**

### **Card Heights**

```
Nav bar: 44pt
Balance hero: 320pt
Goal progress: 120pt
Streak banner: 80pt (conditional)
Stat card: 100pt
App card: 64pt
Section header: 32pt
```

### **Spacing**

```
Screen margins: 24pt
Card gaps: 16pt
Internal padding: 16-24pt
Section spacing: 24pt
```

### **Colors**

```
Background: #1E2A3A
Surface: #2A3B4D
Gold: #F4A259
Teal: #4ECDC4
Orange: #FF8C42
Text Primary: #F9F6F0
Text Secondary: #D4CFC4
```

---

