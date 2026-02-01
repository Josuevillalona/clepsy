## **Earning Mechanics (Technical Spec)**

### **Rule 1: 60-Second Warmup**

**Behavior:**

```
User opens productive app (e.g., Kindle)
0:00 - 0:59 → Warmup period (not counting)
1:00        → Tracking starts ✓
1:01        → User has earned 1 minute
5:00        → User has earned 5 minutes
```

**Implementation:**

javascript

````javascript
// Pseudocode
onAppEnterForeground(app) {
  if (isProductiveApp(app)) {
    startWarmupTimer(60 seconds)
  }
}

onWarmupComplete() {
  startEarningSession()
  sessionStartTime = currentTime
}
```

**User visibility:**
- Silent (no notification)
- User doesn't know about warmup unless they check documentation
- Prevents confusion about "why didn't I earn 1 minute?"

---

### **Rule 2: Session Pause/Resume (2-Minute Timeout)**

**Scenario A: Brief interruption (< 2 min)**
```
User in Duolingo
0:00 - 5:00 → Earning (5 min accumulated)
5:01        → Phone call, Duolingo → background
5:01 - 5:30 → Paused (30 seconds away)
5:31        → Returns to Duolingo
5:31        → Session resumes (no new warmup)
10:00       → Total earned: 10 min (5 + 5)
```

**Scenario B: Long interruption (> 2 min)**
```
User in Duolingo
0:00 - 5:00 → Earning (5 min accumulated)
5:01        → Leaves Duolingo
5:01 - 7:30 → Away for 2.5 minutes (> timeout)
7:30        → Session ends, credits 5 min to balance
10:00       → User returns to Duolingo
10:00 - 10:59 → NEW session, warmup starts
11:00       → Tracking resumes
````

**Implementation:**

javascript

````javascript
onAppEnterBackground(app) {
  pauseSession()
  startTimeoutTimer(2 minutes)
}

onTimeoutExpired() {
  endSession()
  creditBalance(accumulatedMinutes)
  accumulatedMinutes = 0
}

onAppEnterForeground(app) {
  if (sessionActive && timeAway < 2 minutes) {
    resumeSession() // No new warmup
  } else {
    startNewSession() // New warmup required
  }
}
```

---

### **Rule 3: Balance Updates (Every 5 Min OR Session End)**

**During active session:**
```
User in Kindle for 12 minutes:
0:00 - 0:59 → Warmup
1:00 - 5:00 → Earning (4 min accumulated)
5:00        → ✓ Balance update: +4 min
5:01 - 10:00 → Earning (5 min accumulated)
10:00       → ✓ Balance update: +5 min (total: 9 min)
10:01 - 12:00 → Earning (2 min accumulated)
12:00       → User exits
            → ✓ Balance update: +2 min (total: 11 min)
````

**Why every 5 minutes:**

* iOS DeviceActivityReport may not update in real-time  
* Reduces API calls and battery drain  
* Still feels responsive (user sees progress)

**Implementation:**

javascript

````javascript
let minutesEarnedSinceLastUpdate = 0

onMinuteEarned() {
  minutesEarnedSinceLastUpdate++
  
  if (minutesEarnedSinceLastUpdate >= 5) {
    updateBalance(minutesEarnedSinceLastUpdate)
    minutesEarnedSinceLastUpdate = 0
  }
}

onSessionEnd() {
  if (minutesEarnedSinceLastUpdate > 0) {
    updateBalance(minutesEarnedSinceLastUpdate)
    minutesEarnedSinceLastUpdate = 0
  }
}
```

---

### **Rule 4: Milestone Notifications (15 Min, Optional)**

**Default behavior:**
```
User earning in Duolingo:
1:00 - 15:00 → First 15 minutes earned
15:00        → 🔔 Notification: "Nice! ⭐ You just earned 15 minutes."
15:01 - 30:00 → Next 15 minutes
30:00        → 🔔 Notification: "Awesome! You earned 30 minutes total today."
```

**Notification specs:**
- **Title:** "Nice! ⭐" (first milestone) OR "Awesome! 🎉" (subsequent)
- **Body:** "You just earned {X} minutes." OR "You earned {total} minutes total today."
- **Tap action:** Opens Clepsy dashboard
- **Sound:** System default (subtle)
- **Badge:** Update app badge to current balance

**User concern addressed:**
> "Don't want them to be like 'oh I just got this let me go scroll' and interrupt their productivity"

**Solution - Settings option:**
```
Settings > Notifications
┌─────────────────────────────────────┐
│ Milestone Notifications             │
│                                     │
│ [×] Notify when I earn milestones   │
│                                     │
│ Milestone interval                  │
│ ( ) 15 minutes                      │
│ ( ) 30 minutes                      │
│ ( ) 1 hour                          │
│ (×) Off                             │
└─────────────────────────────────────┘
````

**Default:** ON, 15 minutes **User can:** Disable completely OR adjust interval

**Implementation:**

javascript

````javascript
const milestoneInterval = getUserSetting('milestoneInterval') // 15, 30, 60, or 0 (off)

if (milestoneInterval > 0 && totalEarned % milestoneInterval === 0) {
  sendMilestoneNotification(totalEarned)
}
```

---

### **Rule 5: Screen Lock Pauses Tracking**

**Scenario:**
```
User in Kindle reading:
0:00 - 5:00 → Earning (screen on)
5:00        → User locks phone (screen off)
5:00 - 10:00 → Paused (not earning)
10:00       → User unlocks, returns to Kindle
10:00       → Session resumes
15:00       → Total earned: 10 min (not 15)
````

**Why pause on lock:**

* Enforces active, engaged use  
* Prevents overnight farming (leaving app open)  
* Aligns with productivity intent

**Exception:** None for MVP

* Audiobooks, podcasts don't earn time while screen is locked  
* This is a tradeoff for simplicity  
* Can revisit in V1.5 if users request it

**Implementation:**

javascript

```javascript
onScreenLock() {
  if (sessionActive) {
    pauseSession()
  }
}

onScreenUnlock() {
  if (sessionPaused && userReturnsToProductiveApp) {
    resumeSession()
  }
}
```

---

## **Complete User Flows**

### **Flow 1: First Earning Experience**

**Context:** User just completed onboarding, balance is 0 min

**Step-by-step:**

1. **User on dashboard**  
   * Balance: 0 minutes  
   * Goal: 0 of 30 min (0%)  
   * User taps Duolingo card  
2. **Duolingo launches**  
   * Clepsy exits to background  
   * DeviceActivityMonitor detects Duolingo is active  
   * Warmup timer starts (60 seconds)  
3. **User does Duolingo lesson**  
   * 0:00 \- 0:59 → Warmup (no feedback)  
   * 1:00 → Tracking starts silently  
   * 1:00 \- 15:00 → User earns minutes (no interruption)  
4. **15-minute milestone**  
   * 15:00 → 🔔 Notification: "Nice\! ⭐ You just earned 15 minutes."  
   * User sees notification, continues (or dismisses)  
5. **User finishes lesson**  
   * 22:00 → User exits Duolingo  
   * Session ends  
   * Balance update: \+22 min  
6. **User opens dashboard**  
   * Balance card: "22 minutes" (was 0\)  
   * Goal progress: "22 of 30 min" (73%)  
   * Duolingo card: "22 min earned"  
   * Clepsy character: 73% sand level

---

### **Flow 2: Interrupted Session**

**Context:** User earning, then gets interrupted

1. **User in Kindle reading**  
   * 0:00 \- 5:00 → Earned 5 min  
   * Balance hasn't updated yet (next update at 6:00)  
2. **Phone call comes in**  
   * 5:01 → Kindle → background  
   * Session pauses  
   * Timeout timer starts (2 minutes)  
3. **User on call briefly**  
   * 5:01 \- 5:30 → Paused (30 seconds)  
   * 5:31 → Call ends, user returns to Kindle  
   * Session resumes (no new warmup)  
4. **User continues reading**  
   * 5:31 \- 6:00 → Earns 1 more minute (total: 6 min)  
   * 6:00 → Balance update: \+6 min

**Result:** Seamless experience, brief interruption didn't kill session

---

### **Flow 3: Long Break (Session Timeout)**

**Context:** User takes break \> 2 minutes

1. **User in Notion writing**  
   * 0:00 \- 8:00 → Earned 8 min  
   * 5:00 → Balance updated: \+5 min  
2. **User gets distracted**  
   * 8:01 → Leaves Notion for Instagram (blocked)  
   * Session pauses  
   * Timeout timer starts  
3. **User forgets about Notion**  
   * 8:01 \- 11:00 → Away for 3 minutes (\> 2 min timeout)  
   * 10:01 → Session times out  
   * Balance update: \+3 min (remaining from session)  
   * Total earned: 8 min  
4. **User returns to Notion later**  
   * 15:00 → Opens Notion again  
   * NEW session starts  
   * 15:00 \- 15:59 → Warmup  
   * 16:00 → Tracking resumes

**Result:** Two separate sessions (8 min \+ new session)

---

### **Flow 4: Screen Lock Interruption**

**Context:** User locks phone mid-session

1. **User reading in Kindle**  
   * 0:00 \- 10:00 → Earned 10 min  
   * 5:00 → Balance updated: \+5 min  
   * 10:00 → Balance updated: \+5 min (total: 10\)  
2. **User locks phone**  
   * 10:01 → Screen locks  
   * Session pauses immediately  
3. **Phone stays locked**  
   * 10:01 \- 10:30 → Paused (not earning)  
   * 10:31 → User unlocks phone, returns to Kindle  
   * Session resumes (no timeout yet, \<2 min)  
4. **User continues reading**  
   * 10:31 \- 15:00 → Earns 5 more min  
   * 15:00 → Balance update: \+5 min (total: 15\)

**Result:** Screen lock pauses but doesn't end session if \<2 min

---

## **PRD Section: Earning Flow**

Add this as **Journey 4: Earning Time** in your PRD:

markdown

````
### JOURNEY 4: Earning Time Through Productive Apps

**PRD Goal:** User earns unlock time by using productive apps (P0)

**Trigger:** User opens a productive app (from dashboard, home screen, or anywhere)

---

#### EARNING MECHANICS

**1. Session Warmup (60 seconds)**
- User must use productive app for 60 consecutive seconds before tracking starts
- Purpose: Prevents gaming (rapid open/close), ensures genuine intent
- User experience: Silent (no notification)
- Example: Opens Duolingo at 12:00:00, tracking starts at 12:01:00

**2. Active Tracking**
- System tracks time in 1-second increments while app is in foreground
- Requirement: Screen must be unlocked and app must be active
- Tracked via iOS DeviceActivityMonitor API
- Runs in background even when Clepsy is closed

**3. Session Pause/Resume**
- **Brief interruption (< 2 min):**
  - User switches apps or takes call
  - Session pauses (not earning)
  - User returns within 2 minutes
  - Session resumes without new warmup
  
- **Long interruption (> 2 min):**
  - User away for > 2 minutes
  - Session ends, time is credited
  - User returns later → new session starts with new warmup

**4. Balance Updates**
- Balance updates every 5 minutes during active session
- Balance updates at session end for remaining minutes
- Updates trigger pull-to-refresh on dashboard if app is open
- Example: 12-minute session = update at 5 min, update at 10 min, update at session end (2 min)

**5. Screen Lock Behavior**
- Locking phone pauses tracking immediately
- Unlocking + returning to app resumes session (if < 2 min timeout)
- Purpose: Enforces active, engaged use; prevents overnight farming

---

#### MILESTONE NOTIFICATIONS (P0)

**Default Settings:**
- Trigger: Every 15 minutes earned
- Can be disabled in Settings
- Can be adjusted: 15 min, 30 min, 1 hour, or Off

**Notification Content:**
- **First milestone (15 min):**
  - Title: "Nice! ⭐"
  - Body: "You just earned 15 minutes."
  
- **Subsequent milestones:**
  - Title: "Awesome! 🎉"
  - Body: "You earned {total} minutes total today."

**Notification Behavior:**
- Tap action: Opens Clepsy dashboard
- Sound: System default (subtle)
- App badge: Updates to current balance
- Dismissible (does not block productive app use)

**Settings Control:**
```
Settings > Notifications
- [×] Milestone notifications enabled
- Interval: ( ) 15 min (●) 30 min ( ) 1 hour ( ) Off
```

---

#### USER FLOWS

**Happy Path:**
1. User taps productive app card on dashboard
2. App launches natively
3. 60-second warmup (silent)
4. Tracking starts, user earns 1:1 time
5. At 15 min: Milestone notification appears
6. User continues or finishes session
7. Session ends: Remaining time credited
8. Dashboard updates with new balance

**Edge Cases:**
- Phone call interruption → Session pauses, resumes after call
- Long break (> 2 min) → Session ends, new session on return
- Screen lock → Pauses tracking, resumes on unlock
- Rapid app switching (< 60 sec) → No time earned

---

#### TECHNICAL REQUIREMENTS

**DeviceActivityMonitor must:**
- Track foreground time for productive apps
- Detect app transitions (foreground/background)
- Detect screen lock/unlock events
- Start warmup timer (60 sec) on app open
- Start earning session after warmup
- Pause session on background/lock
- End session after 2-minute timeout
- Update balance every 5 min or at session end
- Trigger milestone notifications at intervals

**Data to Track:**
- Current session start time
- Total minutes earned in current session
- Minutes earned since last balance update
- Total minutes earned today (all apps)
- Per-app earned minutes (for dashboard breakdown)

**Success Metrics:**
- Tracking accuracy: 95%+ (compare DeviceActivity to expected)
- Balance update latency: <5 seconds after session end
- Milestone notification delivery: 100% (no missed notifications)
- False earning prevention: <1% of sessions (gaming attempts)

---

#### NON-GOALS (MVP)

- Manual session start/stop (automatic only)
- Custom earning ratios (1:1 only, no 2:1 or 3:1)
- Earning caps per day (unlimited earning)
- Earning during screen-locked audio apps (pause on lock, no exceptions)
- Session history/analytics (just today's totals)
````

---

## **Quick Reference Card**

| Mechanic | Behavior | Example |
| ----- | ----- | ----- |
| **Warmup** | 60 sec before tracking | Opens app at 12:00, earns starting 12:01 |
| **Pause timeout** | 2 min before session ends | Away 1:59 \= resume, 2:01 \= new session |
| **Balance update** | Every 5 min OR session end | 12-min session \= 3 updates (5, 10, 12\) |
| **Milestones** | Every 15 min (default) | Notification at 15, 30, 45 min... |
| **Screen lock** | Pauses immediately | Lock at 10 min earned, unlock resumes |

