## **Clepsy Onboarding Flow \- Complete Specification**

**Target: 5 screens total** (optimal range per your research)  
 **Estimated completion time: 3-4 minutes**

---

### **SCREEN 1: Welcome \+ Value Proposition**

**Purpose:** Explain what Clepsy does and why it's different

**Layout:**

```
[Clepsy Character - Patient state, 50% sand]

Welcome to Clepsy

Break your doomscrolling habit by 
earning your screen time.

- Block distracting apps by default
- Earn time by being productive
- Spend earned time guilt-free

[Get Started →]
```

**Copy notes:**

* Focus on benefit ("break habit") not feature ("time-trading")  
* Use bullets for scannability (3 max)  
* CTA is action-oriented: "Get Started" not "Next"

**Typography:**

* Title: 34pt Bold  
* Body: 17pt Regular  
* Bullets: 17pt with • icons

**Time to read:** 15-20 seconds

---

### **SCREEN 2: Permission Request (with Rationale)**

**Purpose:** Get Family Controls permission with clear explanation

**Layout:**

```
[Icon: Shield with checkmark - iOS style]

We Need Screen Time Permission

To block apps like TikTok and Instagram,
iOS requires Screen Time access.

This lets Clepsy:
✓ Block vice apps until you earn time
✓ Track your productive app usage
✓ Enforce time limits you've earned

Your data stays on your device.
We can't see what apps you use.

[Grant Permission →]

───────────────────────
Why we're asking early: We need this
to make everything work. Better to
know now than after setup!
```

**Copy notes:**

* Lead with "We Need" (direct, honest)  
* Explain "Why" before "What" (per research: 12% higher grant rate)  
* Bullet list shows specific benefits  
* Privacy reassurance (common concern)  
* Footer explains why we're asking now (builds trust)

**Technical:**

* CTA triggers iOS Family Controls permission sheet  
* If granted → Advance to Screen 3  
* If denied → Show error state (see below)

**Time to read:** 30-40 seconds

---

### **SCREEN 2B: Permission Denied (Error State)**

**Purpose:** Handle rejection gracefully

**Layout:**

```
[Icon: Grey shield with X]

Permission Required

Clepsy can't block apps without 
Screen Time permission.

To continue:
1. Open Settings app
2. Go to Screen Time
3. Enable permission for Clepsy

[Open Settings →]

[I'll Do This Later]
```

**Behavior:**

* "Open Settings" → Deep links to iOS Settings (if possible)  
* "I'll Do This Later" → Exits onboarding, saves state, user can restart later

---

### **SCREEN 3: Select Vice Apps to Block**

**Purpose:** Let user choose which apps to block

**Layout:**

```
[Clepsy - Encouraging state]

Which apps steal your time?

Select the apps you want to block.
You'll need to earn time to unlock them.

┌─────────────────────────────┐
│ [×] TikTok         [icon]   │
│ [×] Instagram      [icon]   │
│ [ ] Twitter/X      [icon]   │
│ [×] YouTube        [icon]   │
│ [ ] Facebook       [icon]   │
│ [ ] Reddit         [icon]   │
│ + Add Custom App            │
└─────────────────────────────┘

Selected: 3 apps

[Continue →]
```

**Behavior:**

* Checkbox list, multi-select  
* Pre-select top 3 most common (TikTok, Instagram, YouTube)  
* User can toggle on/off  
* Minimum: 1 app required to continue  
* "Add Custom App" → Opens app picker (iOS sheet)

**Copy notes:**

* "Steal your time" \= empathetic, non-judgmental  
* Explain what blocking means  
* Show count of selected apps

**Time to complete:** 30-60 seconds

---

### **SCREEN 4: Select Productive Apps to Track**

**Purpose:** Let user choose which apps earn time

**Layout:**

```
[Clepsy - Patient state]

Which apps make you productive?

Select apps that help you learn, read,
or grow. You'll earn time when you use them.

┌─────────────────────────────┐
│ [×] Kindle         [icon]   │
│ [×] Duolingo       [icon]   │
│ [ ] Headspace      [icon]   │
│ [×] Notion         [icon]   │
│ [ ] Coursera       [icon]   │
│ [ ] Fitness+       [icon]   │
│ + Add Custom App            │
└─────────────────────────────┘

Selected: 3 apps

[Continue →]
```

**Behavior:**

* Same mechanics as Screen 3  
* Pre-select top 3 common productivity apps  
* Minimum: 1 app required  
* Apps are dynamically pulled from device (show installed apps first)

**Copy notes:**

* "Make you productive" (positive framing)  
* Examples: learn, read, grow (concrete actions)  
* Explain earning mechanic

**Time to complete:** 30-60 seconds

---

### **SCREEN 5: Set Daily Goal**

**Purpose:** Let user choose productivity goal (with smart default)

**Layout:**

```
[Clepsy - 0% sand level]

Set Your Daily Productivity Goal

How much time do you want to spend
on productive apps each day?

┌─────────────────────────────┐
│   [  15 min  ]              │
│   [ ●30 min  ] ← Selected   │
│   [  1 hour  ]              │
│   [  2 hours ]              │
│   [  Custom  ]              │
└─────────────────────────────┘

This goal helps track your progress.
You can change it anytime in Settings.

[Start Using Clepsy →]
```

**Behavior:**

* Radio buttons (single select)  
* 30 min pre-selected (default)  
* "Custom" → Opens number picker (15 min to 4 hours)  
* Goal is separate from balance (sand level \= goal progress)

**Copy notes:**

* "Want to spend" (positive, not "must" or "should")  
* Reassurance: Can change later (reduces decision anxiety)  
* CTA: "Start Using" (clear next step)

**Time to complete:** 15-30 seconds

---

### **SCREEN 6: You're All Set (Success State)**

**Purpose:** Confirm setup complete, explain next steps

**Layout:**

```
[Clepsy - Celebrating state, 0% sand]

🎉 You're All Set!

Your vice apps are now blocked.
Here's what happens next:

1️⃣ Use productive apps to earn time
2️⃣ Get notified when you hit milestones
3️⃣ Spend earned time guilt-free

Your balance resets at midnight each day.
Start fresh every morning!

[Go to Dashboard →]
```

**Behavior:**

* CTA takes user to main dashboard  
* Vice apps are now blocked (can test immediately)  
* Dashboard shows 0 min balance, 0% goal progress

**Copy notes:**

* Celebration tone (you did it\!)  
* Numbered steps (clear sequence)  
* Reinforce midnight reset (key mechanic)

**Time to read:** 20-30 seconds

---

## **Complete Flow Summary**

| Screen | Purpose | Time | Can Skip? |
| ----- | ----- | ----- | ----- |
| 1\. Welcome | Explain value | 20s | No |
| 2\. Permission | Get Family Controls | 40s | No (blocker) |
| 3\. Vice Apps | Select apps to block | 60s | No |
| 4\. Productive Apps | Select apps to track | 60s | No |
| 5\. Goal | Set daily target | 30s | No (use default) |
| 6\. Success | Confirm & educate | 30s | No |

