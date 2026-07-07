# **GAP 5: ERROR STATES (Complete Specification)**

## **Error Categories**

1. **Critical Blockers** (P0 \- App unusable)  
2. **Feature Degradation** (P1 \- App works but limited)  
3. **Recoverable Errors** (P1 \- Temporary issues)  
4. **Edge Cases** (P2 \- Rare scenarios)

---

## **1\. CRITICAL BLOCKERS (P0)**

### **Error 1A: Permission Denied During Onboarding**

**When:** User denies Screen Time permission on Screen 2 of onboarding

**Screen:**

```
┌─────────────────────────────────────┐
│  [Grey shield icon with X]          │
│                                     │
│      Permission Required            │
│                                     │
│ Clepsy can't block apps without     │
│ Screen Time permission.             │
│                                     │
│ To continue:                        │
│ 1. Open Settings app                │
│ 2. Go to Screen Time                │
│ 3. Enable permission for Clepsy     │
│                                     │
│ [Open Settings →]                   │
│                                     │
│ [I'll Do This Later]                │
└─────────────────────────────────────┘
```

**Buttons:**

* **Open Settings:** Deep links to iOS Settings \> Screen Time \> Clepsy  
  * iOS URL: `App-prefs:root=SCREEN_TIME`  
  * If deep link unavailable: Opens main Settings app  
* **I'll Do This Later:** Exits onboarding, saves state, user can restart

**State Management:**

* Save onboarding progress: `{ "onboardingIncomplete": true, "stoppedAt": "permission" }`  
* Next app open: Resume from permission screen (don't restart)

**Recovery:**

* User enables permission in Settings  
* Returns to app  
* App detects permission granted  
* Continues to Screen 3 (Select Vice Apps)

---

### **Error 1B: Permission Revoked After Setup**

**When:** User had permission, then revoked it in iOS Settings

**Detection:** On app launch, check permission status

**Banner (Top of Dashboard):**

```
┌─────────────────────────────────────┐
│ ⚠️ Permission Required              │
│                                     │
│ Clepsy can't work without Screen    │
│ Time permission. Vice apps are      │
│ currently unblocked.                │
│                                     │
│ [Open Settings →]                   │
└─────────────────────────────────────┘
```

**Banner specs:**

* Background: `#FF8C42` (Warning Orange) with 20% opacity  
* Border: 2px solid `#FF8C42`  
* Border radius: 16pt  
* Padding: 16pt  
* Position: Fixed at top of dashboard (above balance card)  
* Dismissible: NO (persists until permission granted)

**Behavior:**

* Dashboard still loads (shows data)  
* Vice apps are unblocked (can't enforce without permission)  
* Productive app tracking still works (doesn't require permission)  
* Balance doesn't increase from productive apps (no point, can't spend it)

**Recovery:**

* User taps "Open Settings"  
* Grants permission  
* Returns to app  
* Banner disappears  
* Vice apps block immediately

---

### **Error 1C: iOS Version Too Old**

**When:** User has iOS \< 16.0 (Screen Time API unavailable)

**Screen (On Launch):**

```
┌─────────────────────────────────────┐
│  [Clepsy sad face]                  │
│                                     │
│    iOS 16 Required                  │
│                                     │
│ Clepsy needs iOS 16 or later to     │
│ work. Your device is running        │
│ iOS [detected version].             │
│                                     │
│ Please update iOS in Settings to    │
│ use Clepsy.                         │
│                                     │
│ [Close App]                         │
└─────────────────────────────────────┘
```

**Prevention:** App Store listing should specify "Requires iOS 16.0 or later" (prevents installs)

**If somehow installed:**

* Show this error on launch  
* "Close App" exits gracefully  
* No other functionality available

---

## **2\. FEATURE DEGRADATION (P1)**

### **Error 2A: DeviceActivityReport Unavailable**

**When:** iOS framework fails to provide usage data (rare iOS bug/glitch)

**Detection:** API call returns error or times out (\>10 seconds)

**Banner (Dashboard):**

```
┌─────────────────────────────────────┐
│ ⚠️ Can't Update Balance             │
│                                     │
│ Having trouble checking your usage. │
│ Pull down to refresh.               │
│                                     │
│ [×] Dismiss                         │
└─────────────────────────────────────┘
```

**Banner specs:**

* Background: rgba(255, 140, 66, 0.2) (Warning Orange)  
* Border: 1px solid `#FF8C42`  
* Dismissible: YES (user can close)  
* Position: Below nav bar, above balance card

**Fallback behavior:**

* Show last known balance (from cache)  
* Add "(Last updated: 5 min ago)" subtitle  
* Disable pull-to-refresh temporarily (prevents spam)  
* Retry automatically after 60 seconds

**Balance card shows:**

```
YOUR BALANCE
47 minutes
Available to spend

Last updated: 5 min ago
Having trouble refreshing...
```

**Recovery:**

* Wait 60 seconds, retry automatically  
* If successful: Banner disappears, balance updates  
* If still failing after 3 attempts: Show "Try restarting app" message

---

### **Error 2B: Tracking Failed (Background Process Crashed)**

**When:** DeviceActivityMonitor stops reporting (process crash, iOS killed it)

**Detection:** No updates received for 10+ minutes during active session

**User experience:**

* User is in Kindle earning time  
* After 10 minutes, no milestone notification  
* User opens dashboard: Balance hasn't updated

**Dashboard shows:**

```
YOUR BALANCE
22 minutes
Available to spend

⚠️ Tracking may have stopped
Try closing and reopening productive apps
```

**Notification (if user was earning):**

```
Title: "Tracking Issue"
Body: "We lost track of your session. Reopen your app to continue earning."
Tap action: Opens dashboard
```

**Recovery:**

* User closes productive app  
* Reopens it  
* DeviceActivityMonitor restarts  
* New session begins (with warmup)

**Logging:**

* Record this event for analytics (helps detect iOS bugs)  
* Show report in Settings \> About \> Debug Info (hidden dev tool)

---

### **Error 2C: Midnight Reset Failed**

**When:** Scheduled midnight reset didn't fire (iOS background tasks issue)

**Detection:** App launches, checks last reset timestamp, sees it's \>24 hours old

**Automatic recovery:**

javascript

````javascript
onAppLaunch() {
  const lastReset = getLastResetTime()
  const now = Date.now()
  const hoursSinceReset = (now - lastReset) / (1000 * 60 * 60)
  
  if (hoursSinceReset >= 24) {
    // Missed midnight reset, do it now
    performMidnightReset()
    logMissedReset() // Analytics
  }
}
```

**User sees:**
- Balance is 0 (reset happened)
- No error message (silent recovery)
- Fresh start as expected

**Edge case:** User opens app at 11:59 PM, reset was supposed to happen at 12:00 AM
- App launch at 11:59:30 PM detects missed reset
- Performs reset immediately
- User sees 0 balance (correct)

---

## 3. RECOVERABLE ERRORS (P1)

### **Error 3A: Network Timeout (If App Needs API)**

**Note:** MVP is fully offline, but future versions might need network

**When:** API call fails (server down, no internet)

**Toast notification:**
```
⚠️ Connection issue. Using cached data.
```

**Specs:**
- Duration: 3 seconds
- Position: Bottom of screen
- Background: rgba(255, 140, 66, 0.9)
- Text color: #FFFFFF

**Behavior:**
- App continues working with cached data
- Retry in background every 30 seconds
- When connection restored: Silent sync, no notification

---

### **Error 3B: App Unlock Failed**

**When:** User tries to unlock vice app but DeviceActivity API fails

**Modal alert:**
```
┌─────────────────────────────────────┐
│    Couldn't Unlock App              │
│                                     │
│ Something went wrong. Your balance  │
│ wasn't deducted.                    │
│                                     │
│ Try again in a moment.              │
│                                     │
│           [OK]                      │
└─────────────────────────────────────┘
```

**Behavior:**
- Balance is NOT deducted (user didn't get access)
- User can retry immediately
- If fails 3 times: Show "Restart app" suggestion

**Recovery:**
- User force-quits app
- Relaunches
- DeviceActivity framework resets
- Unlock works

---

### **Error 3C: Balance Deduction Mismatch**

**When:** User unlocks app for 15 min, but balance only deducts 10 min (calculation bug)

**Detection:** Periodic audit (compare expected vs actual balance)

**Alert (in dashboard):**
```
┌─────────────────────────────────────┐
│ Balance Corrected                   │
│                                     │
│ We detected a calculation error and │
│ fixed your balance. No action needed.│
│                                     │
│           [Got It]                  │
└─────────────────────────────────────┘
````

**Logging:**

* Send bug report to analytics (includes state snapshot)  
* Help identify and fix calculation bugs

---

## **4\. EDGE CASES (P2)**

### **Error 4A: Clock Changed (Time Travel)**

**When:** User manually changes device time (or travels across timezones)

**Detection:**

javascript

````javascript
const lastKnownTime = localStorage.get('lastAppTime')
const currentTime = Date.now()
const timeDifference = currentTime - lastKnownTime

if (Math.abs(timeDifference) > 2 * 60 * 60 * 1000) { // > 2 hours
  // Possible time manipulation or timezone change
  handleTimeChange()
}
```

**Scenario A: User sets clock forward (to skip midnight reset)**
```
Current time: 11:00 PM
User changes to: 2:00 AM next day
Expected: Midnight reset should have happened
```

**Behavior:**
- Detect time jump forward
- If > 24 hours: Perform midnight reset immediately
- If < 24 hours but crossed midnight: Perform reset
- User sees 0 balance (can't cheat the system)

**Scenario B: User sets clock backward (to "undo" spending)**
```
Current time: 6:00 PM, balance: 0 min (all spent)
User changes to: 12:00 PM (earlier today)
Expected: Balance should still be 0
```

**Behavior:**
- Detect time jump backward
- Ignore it (don't restore balance)
- Balance remains as it was before time change
- Log event (potential abuse attempt)

---

### **Error 4B: Device Storage Full**

**When:** No space to save settings/data

**Detection:** Write operation fails with storage error

**Alert:**
```
┌─────────────────────────────────────┐
│    Storage Full                     │
│                                     │
│ Your device is out of storage.      │
│ Clepsy can't save your changes.     │
│                                     │
│ Free up space in Settings > General │
│ > iPhone Storage.                   │
│                                     │
│           [OK]                      │
└─────────────────────────────────────┘
````

**Behavior:**

* Changes are not saved (revert to last saved state)  
* App continues working with existing data  
* User must free space to make changes

---

### **Error 4C: App Deleted Mid-Session**

**When:** User is earning time, then deletes productive app from device

**Detection:** DeviceActivityMonitor reports app no longer installed

**Behavior:**

* Session ends immediately  
* Accumulated time is credited  
* App removed from productive apps list  
* Dashboard updates (shows one fewer app)

**No error shown** (expected behavior, not an error)

---

### **Error 4D: Multiple Rapid Unlocks**

**When:** User unlocks same vice app 3+ times in 60 seconds (rapid open/close)

**Detection:**

javascript

````javascript
const unlockHistory = [] // [{app, time}, ...]

function onUnlockAttempt(app) {
  const now = Date.now()
  const recentUnlocks = unlockHistory.filter(u => 
    u.app === app && now - u.time < 60000
  )
  
  if (recentUnlocks.length >= 3) {
    showCooldownAlert()
    return false // Block unlock
  }
  
  unlockHistory.push({app, time: now})
  return true // Allow unlock
}
```

**Alert:**
```
┌─────────────────────────────────────┐
│    Slow Down                        │
│                                     │
│ You've unlocked this app 3 times    │
│ in one minute. Take a breath!       │
│                                     │
│ Try again in 30 seconds.            │
│                                     │
│           [OK]                      │
└─────────────────────────────────────┘
```

**Purpose:** Prevent abuse, encourage mindful use

---

## Error Handling Philosophy

### **Design Principles:**

1. **Silent Recovery When Possible**
   - Don't show errors if we can fix them automatically
   - Example: Missed midnight reset → Just do it, don't tell user

2. **Clear Communication When Required**
   - If user action needed, explain exactly what to do
   - Example: Permission denied → "Open Settings > Screen Time"

3. **Never Block Without Explanation**
   - If something doesn't work, tell user why
   - Example: Can't unlock app → "Something went wrong" + retry option

4. **Preserve User Data**
   - Never lose balance or streak without user consent
   - Example: Calculation error → Correct it, don't reset everything

5. **Log Everything for Debugging**
   - Track all errors silently
   - Helps fix bugs in future versions
   - Privacy-safe (no personal data)

---

## Error Logging (for Development)

**Hidden Debug Screen** (Settings > About > Tap version 7 times)
```
┌─────────────────────────────────────┐
│  ← Debug Info                       │
├─────────────────────────────────────┤
│ Last 10 Errors:                     │
│                                     │
│ [2024-01-31 14:23]                  │
│ DeviceActivityReport timeout        │
│ Resolved: Retry successful          │
│                                     │
│ [2024-01-31 10:05]                  │
│ Missed midnight reset               │
│ Resolved: Performed on app launch   │
│                                     │
│ [2024-01-30 16:42]                  │
│ Unlock failed: API error            │
│ Resolved: User restarted app        │
│                                     │
│ [Copy All Logs]                     │
│ [Clear Logs]                        │
└─────────────────────────────────────┘
```

**Purpose:**
- TestFlight beta testers can share logs
- Developers can diagnose issues
- Not visible to regular users (hidden)

---

# GAP 6: NOTIFICATION CONTENT (Complete Specification)

## Notification Types

1. **Milestone Notifications** (P0 - Earning progress)
2. **Low Balance Warnings** (P1 - About to run out)
3. **Time Expired Mid-Session** (P1 - Ran out while using)
4. **Daily Reset Reminder** (P2 - Optional evening summary)

---

## 1. MILESTONE NOTIFICATIONS (P0)

### **Purpose:** Positive reinforcement during earning sessions

**Trigger:** User earns X minutes (configurable: 15, 30, 60)

---

### **First Milestone (15 min)**
```
Title: Nice! ⭐
Body: You just earned 15 minutes.
Tap action: Opens dashboard
Sound: Default (subtle)
Badge: Update to current balance
```

**Timing:** Exactly when user reaches 15 min earned (during session)

**Why this copy:**
- "Nice!" = Encouraging, not over-the-top
- "⭐" emoji = Visual reward
- "You just earned" = Present tense, immediate gratification
- No "Keep going!" = Don't interrupt their flow

---

### **Second Milestone (30 min)**
```
Title: Awesome! 🎉
Body: You earned 30 minutes total today.
Tap action: Opens dashboard
Sound: Default
Badge: Update to current balance
```

**Why this copy:**
- "Awesome!" = Escalates enthusiasm
- "🎉" emoji = Celebration
- "total today" = Context (not just this session)

---

### **Third+ Milestones (45, 60, 75...)**
```
Title: On fire! 🔥
Body: You earned 45 minutes total today.
Tap action: Opens dashboard
Sound: Default
Badge: Update to current balance
````

**Variations (cycle through):**

* 45 min: "On fire\! 🔥"  
* 60 min: "Incredible\! 💪"  
* 75 min: "Unstoppable\! ⚡"  
* 90 min: "Amazing\! 🌟"

**Why variations:**

* Prevents notification fatigue  
* Keeps it fresh and engaging  
* Still positive, not preachy

---

### **Notification Specs**

**iOS Implementation:**

swift

````
let content = UNMutableNotificationContent()
content.title = "Nice! ⭐"
content.body = "You just earned 15 minutes."
content.sound = .default
content.badge = NSNumber(value: currentBalance)
content.categoryIdentifier = "MILESTONE"
content.userInfo = ["type": "milestone", "amount": 15]

let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
let request = UNNotificationRequest(identifier: UUID().uuidString, 
                                   content: content, 
                                   trigger: trigger)
UNUserNotificationCenter.current().add(request)
```

**Tap Action:**
- Opens app to dashboard
- Does NOT dismiss notification automatically
- User can dismiss or tap

**Badge Behavior:**
- Shows current balance number
- Updates with each notification
- Clears when app is opened

---

## 2. LOW BALANCE WARNINGS (P1)

### **Purpose:** Alert user before balance runs out

**Trigger:** Balance drops to 5 minutes (during vice app use)
```
Title: Heads up ⏰
Body: 5 minutes left. Earn more to keep scrolling.
Tap action: Opens dashboard
Sound: Default
Badge: 5
```

**When NOT to send:**
- User is not currently in a vice app (no point)
- User already saw this warning today (don't spam)
- Balance is decreasing slowly (<1 min per 5 min) (not urgent)

**Why this copy:**
- "Heads up" = Gentle warning, not alarming
- "⏰" emoji = Time-related
- "5 minutes left" = Concrete info
- "Earn more to keep scrolling" = Actionable, positive framing (not "or you'll be blocked")

---

### **Alternative (if balance is 0)**

**Trigger:** User's balance hits exactly 0 min while using vice app
```
Title: Time's up ⏰
Body: Earn time to unlock TikTok again.
Tap action: Opens dashboard
Sound: Default
Badge: 0
```

**User experience:**
- Notification appears
- Vice app locks immediately (shield screen shows)
- User sees both notification and shield

---

## 3. TIME EXPIRED MID-SESSION (P1)

### **Purpose:** Explain why vice app suddenly locked

**Trigger:** User is using TikTok, balance hits 0, app locks
```
Title: Session ended ⏰
Body: You spent all your earned time. Open Clepsy to earn more.
Tap action: Opens dashboard
Sound: Default
Badge: 0
```

**Why this copy:**
- "Session ended" = Clear cause (not "app locked" which sounds punitive)
- "You spent all your earned time" = Factual, not judgmental
- "Open Clepsy to earn more" = Clear next step

**User journey:**
1. User scrolling TikTok
2. Balance hits 0
3. TikTok locks → Shield screen appears
4. Notification appears ~1 second later
5. User sees shield screen first, then notification

**Notification is secondary** (shield screen is primary feedback)

---

## 4. DAILY RESET REMINDER (P2 - Optional)

### **Purpose:** Evening summary + reminder about midnight reset

**Trigger:** 9:00 PM every day (configurable in settings, default: OFF for MVP)
```
Title: Today's summary 📊
Body: You earned 45 min and spent 32 min. Balance resets at midnight.
Tap action: Opens dashboard
Sound: None (silent)
Badge: Current balance
```

**Why OFF by default:**
- Can feel naggy
- Not everyone wants daily summaries
- User can enable if they want

**Settings option:**
```
Settings > Notifications
┌─────────────────────────────────────┐
│ [ ] Daily summary (9 PM)            │
└─────────────────────────────────────┘
```

**Defer to V1.5** - Not critical for MVP

---

## 5. STREAK MILESTONES (P2 - Optional)

### **Purpose:** Celebrate consecutive days of earning

**Trigger:** User earns at least 1 minute for 7 consecutive days
```
Title: 7 day streak! 🔥
Body: You've earned time every day this week. Keep it up!
Tap action: Opens dashboard
Sound: Default
Badge: Current balance
```

**Milestones:**
- 7 days: "7 day streak! 🔥"
- 14 days: "2 week streak! 🎉"
- 30 days: "30 day streak! ⭐"
- 60 days: "2 month streak! 💪"
- 90 days: "90 day streak! 🌟"

**Timing:** Sent at 8:00 PM on milestone day

**Defer to V1.5** - Focus on core loop first

---

## Notification Settings (User Control)

### **Settings > Notifications**
```
┌─────────────────────────────────────┐
│ Milestone Notifications             │
│ [×] Enabled                         │
│                                     │
│ Milestone interval                  │
│ (●) Every 15 minutes                │
│ ( ) Every 30 minutes                │
│ ( ) Every 1 hour                    │
│ ( ) Off                             │
├─────────────────────────────────────┤
│ Other Notifications                 │
│ [×] Low balance warnings            │
│ [×] Time expired alerts             │
│ [ ] Daily summary (9 PM)            │
└─────────────────────────────────────┘
```

**Defaults:**
- Milestone: ON, 15 min
- Low balance: ON
- Time expired: ON
- Daily summary: OFF

---

## Notification Permissions (iOS)

### **When to Request Permission**

**Option A: During onboarding (Screen 6 - Success)**
```
┌─────────────────────────────────────┐
│ 🎉 You're All Set!                  │
│                                     │
│ [... onboarding success content...] │
│                                     │
│ [Enable Notifications]              │
│ [Skip for Now]                      │
└─────────────────────────────────────┘
````

**Option B: On first milestone (better UX)**

* User earns 15 minutes  
* System tries to send notification  
* iOS prompts: "Clepsy wants to send you notifications"  
* User decides in context

**My recommendation: Option B**

* More contextual (user sees value first)  
* Higher opt-in rate  
* Doesn't add friction to onboarding

---

## **Notification Best Practices**

### **Timing Rules:**

1. **Never send notifications between 11 PM \- 7 AM**  
   * Exception: Time expired (user is actively using app)  
   * Respect sleep hours  
2. **Batch notifications if multiple trigger at once**  
   * Example: User earns 30 min, which is also a milestone for "low balance cleared"  
   * Send only: "You earned 30 minutes total today"  
   * Don't send: Two separate notifications  
3. **Rate limiting: Max 5 notifications per day**  
   * Prevents spam if user earns/spends repeatedly  
   * Milestone notifications count toward limit  
   * Critical notifications (time expired) exempt

---

## **Notification Delivery (Technical)**

### **iOS UNUserNotificationCenter**

swift

```
// Request permission
UNUserNotificationCenter.current().requestAuthorization(
  options: [.alert, .badge, .sound]
) { granted, error in
  if granted {
    print("Notifications enabled")
  }
}

// Schedule notification
let content = UNMutableNotificationContent()
content.title = "Nice! ⭐"
content.body = "You just earned 15 minutes."
content.badge = NSNumber(value: currentBalance)

let request = UNNotificationRequest(
  identifier: UUID().uuidString,
  content: content,
  trigger: nil // Immediate
)

UNUserNotificationCenter.current().add(request)
```

### **Handling Tap Actions**

swift

```
// AppDelegate
func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  didReceive response: UNNotificationResponse,
  withCompletionHandler completionHandler: @escaping () -> Void
) {
  let userInfo = response.notification.request.content.userInfo
  
  if let type = userInfo["type"] as? String {
    switch type {
    case "milestone":
      // Open dashboard
      navigateToDashboard()
    case "lowBalance":
      // Open dashboard with "Earn Time" focused
      navigateToDashboard(highlightEarning: true)
    case "timeExpired":
      // Open dashboard (user will see shield if they tap vice app)
      navigateToDashboard()
    default:
      break
    }
  }
  
  completionHandler()
}
```

---

## **Complete Notification Matrix**

| Type | Trigger | Title | Body | Tap Action | Sound | Badge | Priority |
| ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| **Milestone (1st)** | 15 min earned | Nice\! ⭐ | You just earned 15 minutes. | Dashboard | Default | Balance | P0 |
| **Milestone (2nd)** | 30 min earned | Awesome\! 🎉 | You earned 30 minutes total today. | Dashboard | Default | Balance | P0 |
| **Milestone (3rd+)** | 45+ min earned | On fire\! 🔥 | You earned {X} minutes total today. | Dashboard | Default | Balance | P0 |
| **Low Balance** | 5 min left | Heads up ⏰ | 5 minutes left. Earn more to keep scrolling. | Dashboard | Default | 5 | P1 |
| **Balance Zero** | 0 min while using | Time's up ⏰ | Earn time to unlock TikTok again. | Dashboard | Default | 0 | P1 |
| **Expired Mid-Use** | App locked at 0 | Session ended ⏰ | You spent all your earned time. Open Clepsy to earn more. | Dashboard | Default | 0 | P1 |
| **Daily Summary** | 9 PM | Today's summary 📊 | You earned {X} min and spent {Y} min. Resets at midnight. | Dashboard | Silent | Balance | P2 |
| **Streak** | Milestone days | 7 day streak\! 🔥 | You've earned time every day this week. Keep it up\! | Dashboard | Default | Balance | P2 |

---

## **PRD Sections (Add These)**

### **Add to Journey 4 (Earning Time):**

markdown

```
#### MILESTONE NOTIFICATIONS

**Trigger:** User earns milestone amount (default: 15 min intervals)

**First Milestone (15 min):**
- Title: "Nice! ⭐"
- Body: "You just earned 15 minutes."
- Tap: Opens dashboard
- Sound: Default

**Subsequent Milestones:**
- Title varies: "Awesome! 🎉", "On fire! 🔥", "Incredible! 💪", "Unstoppable! ⚡"
- Body: "You earned {total} minutes total today."
- Format: Shows total earned today, not session amount

**Settings Control:**
- User can disable in Settings > Notifications
- User can adjust interval: 15 min, 30 min, 1 hour, or Off
- Default: Enabled, 15 minutes

**Rate Limiting:**
- Max 5 milestone notifications per day
- Quiet hours: No notifications 11 PM - 7 AM
```

### **Add to Journey 5 (Spending Time):**

markdown

```
#### LOW BALANCE & EXPIRATION NOTIFICATIONS

**Low Balance Warning (P1):**
- Trigger: Balance drops to 5 minutes while using vice app
- Title: "Heads up ⏰"
- Body: "5 minutes left. Earn more to keep scrolling."
- Sent once per session (not repeated)

**Time Expired Mid-Session (P1):**
- Trigger: Balance hits 0 while using vice app
- Title: "Session ended ⏰"
- Body: "You spent all your earned time. Open Clepsy to earn more."
- Appears simultaneously with shield screen
- Notification is secondary feedback (shield is primary)

**Non-Goals (MVP):**
- Proactive warnings before midnight reset
- "You're about to lose X minutes" alerts
- Spending rate warnings ("You're using time faster than earning")
```

### **Add to Journey 9 (NEW): Notification Management**

markdown

```
### JOURNEY 9: Notification Management

**PRD Goal:** User can control notification frequency and types (P0)

**Settings Screen Location:** Settings > Notifications

**Options (P0):**

1. **Milestone Notifications**
   - Toggle: ON/OFF
   - Interval selector: 15 min / 30 min / 1 hour
   - Default: ON, 15 minutes

2. **Low Balance Warnings**
   - Toggle: ON/OFF
   - Triggers at 5 minutes remaining
   - Default: ON

3. **Time Expired Alerts**
   - Toggle: ON/OFF
   - Triggers when balance hits 0 during use
   - Default: ON

**Options (P2 - Defer to V1.5):**

4. **Daily Summary**
   - Toggle: ON/OFF
   - Time selector: 8 PM / 9 PM / 10 PM
   - Default: OFF

5. **Streak Milestones**
   - Toggle: ON/OFF
   - Celebrates consecutive earning days
   - Default: OFF

**iOS Permission:**
- Requested on first milestone event (contextual)
- If denied: Settings shows banner with "Enable Notifications" button
- Deep links to iOS Settings > Clepsy > Notifications

**Badge Updates:**
- App icon badge shows current balance
- Updates with each notification
- Clears when app is opened
```

