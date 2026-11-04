# Goal-based unlock — design

Status: approved in conversation 2026-11-03. The user delegated the build overnight; calls marked **(builder's call)** were made without them and are listed at the end for review.
Linear: CLE-48 (model), CLE-49 (challenges). Supersedes the earn/spend balance model.

## Intent

Clepsy stops being a meter ("earn a minute, spend a minute") and becomes a daily commitment: **do your productive time first, then your socials are yours for the day.** It frames Clepsy as making time for the apps you've been meaning to use, not as a blocker, and it should feel like a game you're winning.

Why now: on-device testing showed the balance model fights iOS:
- DeviceActivity usage reports arrive late (a 2-minute balance took ~4 minutes to lock).
- Re-locking a foreground app shows a stale shield (Apple FB14237883, CLE-2). No workaround worked.

A goal model only re-locks once a day (midnight), and a late report just means the unlock lands about a minute after the goal. Nobody notices that.

## Goals

- Vice apps stay shielded each day until today's goal of productive-app time is reached.
- Reaching the goal is a **celebration you claim in Clepsy**. Nothing unlocks automatically, ever.
- Two goal modes: **Same goal every day**, or **Build up to it** (start low, Clepsy offers +5 min steps until the target).
- Streaks with **freezes**, and a **badge collection**.
- The claim moment is the best-feeling screen in the app: animation, haptics, particles, mascot.

## Non-goals (this version)

- Any limit after unlock (no "you've scrolled an hour" nudge, no second daily goal). Recorded in CLE-48 as a later idea.
- Final badge artwork. The user designs badges later; ship a system with placeholder art.
- Planned sessions / per-app unlock (CLE-37, 45, 46, 47). Superseded.
- Reading report data in the app. It's display-only by Apple's design; we won't work around that.

## Anti-goals (failure even if it works)

- Shame or guilt copy ("You failed"). Voice stays encouraging, direct, specific (brand guide §5).
- Celebration fatigue: big motion everywhere. The daily screens stay calm; the claim moment is the one big beat, and the contrast is what makes it land.
- Unlocking without the user's tap, or unlocking before the goal.
- Haptics with no clear meaning, or haptics you can't turn off (Apple HIG: haptics must be optional and consistently mapped).

## Constraints (iOS)

- Clepsy can't run a timer in the background. Progress comes from DeviceActivity threshold events: one per minute of productive-app use, cumulative over a midnight-to-midnight repeating schedule. Event `earn_N` firing means N minutes so far today.
- Events land about a minute late. The `DeviceActivityReport` view is accurate to the second but **display-only**.
- Shields can't open Clepsy or render custom UI. The only one-tap path from a shield into Clepsy is a notification.
- Deployment target is iOS 16: no `phaseAnimator`, `keyframeAnimator` or `sensoryFeedback`. Use `withAnimation` + async sequencing, `TimelineView` + `Canvas`, UIKit feedback generators and Core Haptics.
- Goals max out at 2 hours (the threshold ladder is 1…180, so 120 stays well under it).

## Approaches considered

1. **Replace everything at once (picked by the user for the overnight build).** Remove the balance and spending model and build the goal model end to end in one pass. The cost: nothing usable midway. That's acceptable because the user is away overnight.
2. In phases (engine → goal setup → rewards), each testable on the phone. Recommended for day-time work. The build still follows this order internally so each layer is tested before the next.
3. Both models behind a switch. Rejected: the user decided on goals, so it adds complexity for no benefit.

## Product rules

### Goal setup (onboarding last step, and Settings)

Step 1, choose a mode (two large cards):

```
How do you want to start?

[ Same goal every day ]
  The same daily goal unlocks your socials.

[ Build up to it ]
  Start small. Clepsy suggests going up as you get stronger.
```

Step 2, pick minutes:
- **Same goal:** one slider, 5–120 min in 5-min steps. A difficulty label updates as it slides:
  - Easy: 5–20 min
  - Medium: 25–45 min
  - Hard: 50–75 min
  - Intense: 80–120 min
- **Build up:** two sliders.
  - **Start at**, 5–115 min.
  - **Build up to**, from start + 5 up to 120.
  - Each step is +5 min. A line shows the estimate: "About N days to reach X" (steps × 3 days).
- Default: Same goal, 30 min.
- Settings has the same picker. Changing it takes effect **tomorrow** if today's goal is already reached. Otherwise it takes effect immediately.

**(builder's call)** Lowering the goal mid-day applies immediately, but the change is only accepted from Settings with a confirmation ("Lower today's goal to 15 min?"). It's the user's own tool, and a hard lock would read as distrust. This is simple to tighten later.

### Build-up offers

- Track consecutive days the current goal was reached.
- After **3 in a row** while below target, the next claim screen ends with an offer: "Ready for 15 min?" with **Let's go** and **Not yet**.
  - **Accept:** the new goal applies from tomorrow, and the count resets.
  - **Decline:** the count resets, and Clepsy asks again after 3 more.
- Reaching the target switches the plan to Same goal at the target and awards the "Built up" badge.
- A missed day resets the consecutive count. **The goal never goes down on its own.**

### Daily cycle

1. **Midnight.** The monitor's `intervalDidStart` for the daily earning schedule re-shields all vice apps (CLE-18). If a vice app is in the foreground, it uses the existing close-app swap: hard block, then shield. No notification at midnight. The app's foreground check is the fallback: if today isn't unlocked, it applies shields.
2. **Earning.** `earn_N` → the monitor records today's earned minutes as max(stored, N), stamped with today's date.
3. **Almost there.** Clepsy's count is at least goal − 1 and the goal isn't reached.
4. **Goal reached.** When N ≥ today's goal, the monitor marks today as reached and posts one notification: "You hit your goal 🎉 · Tap to claim your unlock." It respects the notifications toggle.
5. **Claim.** Opening Clepsy with the goal reached but unclaimed presents the claim experience. Tapping **Unlock my apps** removes all shields until midnight.
6. **Shield copy** (fast path; reads only UserDefaults):
   - Before the goal: title "Instagram is locked", subtitle "12 of 30 min today. Your productive apps unlock it.", button **Go Back**.
   - Goal reached, unclaimed: title "You did it 🎉", subtitle "Open Clepsy to claim your unlock.", primary **Claim in Clepsy**. Tapping it posts the claim notification so one more tap opens Clepsy, then closes the shield.

### Edge cases (from the builder check)

- **Goal lowered below today's earned minutes:** no new earn event will fire, so the **app** also evaluates "reached" whenever it computes today's state (foreground, after a goal change). It marks the day reached, then presents the claim.
- **Re-applying shields never undoes a claim:** every shield-applying path checks `unlockedDay`. That covers app foreground, vice-app changes in Settings, onboarding completion and the monitor's `intervalDidStart`. If today is unlocked, shields stay off.
- **`intervalDidStart` also fires when monitoring starts mid-interval** (first launch, a forced restart). The `unlockedDay` check makes that harmless.
- **Onboarding completion** applies shields immediately: you start locked on day one.
- **The goal's day stamp is stale** (the app hasn't run today): the monitor and shield fall back to the plan's goal mirrored as `goalMinutesBase`, so the first day after a gap still works without the app.

### Streaks and freezes

- A day **counts** if the goal was reached that day. Claiming isn't required.
- The streak is consecutive counted days. A missed day uses a freeze if one is available (the streak survives, marked frozen); otherwise the streak resets to 0.
- Freezes: earn 1 for each 7 consecutive counted days, holding at most 2.
- Days are processed at the app's daily rollover. Any days since the last processed day are evaluated in order, so a week of not opening the app is handled correctly. The monitor records reached days in a shared set (last 60 days).

### Badges (system now, art later)

The initial set, all with placeholder art (an SF Symbol in a medallion, tinted):
- First goal (first reached day)
- 3-day, 7-day, 14-day, 30-day, 100-day streaks
- Built up (reached the build-up target)
- First freeze earned
- Intense (reached a goal of 80 min or more)
- Comeback (reached the goal the day after a streak reset)

Badges are earned during day processing or at claim, and newly earned ones appear on the claim screen. The collection lives in a **Badges** screen from the dashboard: a 3-column grid, earned in color with the date, unearned as a silhouette with its rule ("Reach a 7-day streak").

## Screens

### Dashboard (calm)

```
 Clepsy                                  ⚙︎
 ┌──────────────────────────────────────┐
 │        (hourglass mascot, floats)    │
 │   sand = goal progress, top → bottom │
 │                                      │
 │        18 of 30 min                  │
 │   Productive apps today: 18m 40s     │  ← report view, accurate
 │   ● Locked · 12 min to go            │  ← status chip
 └──────────────────────────────────────┘
 🔥 6-day streak   ❄︎ 1 freeze      Badges ›
 Build up: today 20 · target 45
 Vice apps / Productive apps lists (as today)
```

Status chip states:
- Locked · N min to go
- Almost there…
- Goal hit · Claim (tappable, opens the claim screen)
- Unlocked until midnight

The hourglass sand tracks goal progress and is full all day once the goal is reached. Expression:
- **patient**: under 50%
- **encouraging**: 50% and up
- **celebrating**: reached

### Claim screen (the big beat)

A full-screen cover over the dashboard. Sequence (≈3s to the button; the user can tap to skip ahead to the button):

| t | Visual | Haptic |
|---|---|---|
| 0.0 | Background dims to midnight, radial gold glow fades in (0.4s) | — |
| 0.2 | Hourglass springs in from scale 0.6 (spring 0.5 / 0.7) | soft impact |
| 0.5–1.7 | Sand pours to full (1.2s easeInOut) | continuous haptic ramping 0.15 → 0.6 intensity (Core Haptics) |
| 1.7 | "Pop": mascot to celebrating, scale 1 → 1.12 → 1 spring; confetti burst (gold, teal, cream, Canvas particles with gravity, ~1.5s) | heavy transient (sharpness 0.8) |
| 1.9 | "Goal hit!" title + "30 min of productive time" fade-up | — |
| 2.2 | Streak counter rolls N-1 → N (numeric content transition), flame scales 1.2 → 1 | light impact |
| 2.5+ | Each newly earned badge slides up, staggered 0.15s, spring overshoot | selection tick each |
| 2.8 | **Unlock my apps** button rises in, gentle shimmer sweep | — |
| tap | Lock icon opens (shackle lifts and rotates), second confetti burst, "Enjoy your socials, you've earned it." | success notification |
| +1.2 | Build-up offer card if eligible; otherwise dismiss to the dashboard | — |

- **Reduce Motion:** cross-fades only, no confetti, no scale pops, sand set to full without the pour. Haptics still play if enabled.
- **Haptics toggle:** Settings → Haptics (default on). It mirrors to the App Group like notifications do.

### Build-up offer card

Appears after unlocking, on the same cover:

```
  You've hit 20 min three days running.
  Ready for 25?
  [ Let's go ]   Not yet
```

- **Let's go:** success haptic, the number rolls 20 → 25, small confetti.
- **Not yet:** quiet dismiss.

### Badges screen

- Grid as described above. Tapping a badge opens a detail sheet with the large medallion, its name, rule and date earned.
- The detail medallion has a subtle 3D tilt that follows device motion **(builder's call: skipped for v1, static shine sweep instead)**.

### Onboarding

- Replace `DailyGoalView` with the two-step goal setup.
- Welcome copy changes from earn/spend to: "Hit your daily goal in productive apps → your socials unlock for the rest of the day."

## Research that shaped this

- **Duolingo:** a mascot reaction first, then staggered spring-in stat cards with overshoot, counting numbers and particles. The celebration shows instantly to mask background work. A lower daily bar raised 7-day streak retention by 40%+, and Streak Freeze is based on research that slack motivates more than rigid rules. ([60fps.design](https://60fps.design/apps/duolingo), [Mobbin](https://mobbin.com/blog/streaks-are-about-losing-a-study-of-859-streak-designs), [Duolingo](https://blog.duolingo.com/how-duolingo-streak-builds-habit))
- **Apple Fitness:** ring-closing fireworks plus collectible awards, including limited ones; users look forward to the moment. Apple Watch *suggests* goal increases that apply only on accept, which is why build-up offers here need consent.
- **Apple HIG (haptics):** short haptics tied to discrete events; a consistent meaning per pattern; intensity matched to the animation; use system patterns per their meaning; always optional. ([HIG](https://developer.apple.com/design/human-interface-guidelines/playing-haptics))
- **Finch:** layered loops (task → reward → collection) and collection-motivated users. The critique that the reward loop can become the point is why there's one big beat per day, not constant rewards.
- **Habit research (Lally):** missing one day doesn't materially affect habit formation. Hence freezes, and goals that never drop on their own.
- **Category gap:** Opal uses gems and streaks as rewards and Clearspace earns time with pushups, but nobody gates socials behind a ramping goal. This is Clepsy's differentiator.

Brand guide note: §2 says "subtle animation only, no bouncing". The user said not to be rigid, so this design keeps calm motion everywhere **except** the claim moment.

## Architecture

**Shared state** (App Group UserDefaults, all fast-path reads):
- `goalMinutesToday` + `goalDay`: written by the app at rollover and on change. The monitor and shield read it.
- `goalMinutesBase`: the plan's current goal, used when `goalDay` is stale.
- `earnedMinutesToday` + `earnedDay`: written by the monitor.
- `reachedDays`: [yyyy-MM-dd], written by the monitor.
- `unlockedDay`: written by the app on claim.
- `hapticsEnabled`: mirror.

**App-only state** (`PersistenceService`):
- `GoalPlan`: mode, current goal, target, consecutive hits, pending goal for tomorrow
- `StreakState`: count, freezes, last processed day, last reset day
- `BadgeCollection`: id → date

**Pure logic** (framework-free, unit-tested; shared to extensions where needed):
- `GoalRules`: difficulty bands, picker ranges, build-up days estimate, offer eligibility, accept/decline
- `DayProcessor`: rolls streak/freezes/plan forward over missed days and returns newly earned badges
- `EarnRules`: given an earn event N and stored state, returns the new earned count and whether the goal was just reached
- `ShieldRules`: copy and button per state, and the primary-tap decision
- `BadgeRules`: which badges a day or claim earns

**Removed:** the time balance and its persistence, spending sessions, vice monitoring (`ViceMonitoring`, spend thresholds, `SessionRules` session parts), "Use My Time", the time's-up flow (`endSession` at balance exhaustion), and the pending-event sync that fed the balance. `TimeEvent` and the coordinated event file stay as infrastructure for the ledger (CLE-14), but nothing writes to them in this version.

**Services:**
- `HapticsService`: wraps the UIKit generators and one Core Haptics continuous ramp; no-ops when disabled or on unsupported hardware.
- `ConfettiView`: `TimelineView` + `Canvas`, deterministic seeds.

## Left to the builder

- Exact copy beyond what's quoted (follow brand voice §5)
- File layout
- Particle physics constants
- Badge symbols and colors
- Test structure

## Builder's calls made overnight (for the user to review)

1. Lowering the goal mid-day applies immediately, behind a confirmation.
2. Streak counts reaching the goal; claiming isn't required.
3. No notification at the midnight re-lock.
4. Shield "Claim in Clepsy" posts a notification as the path into the app.
5. Badge set and placeholder art as listed.
6. No device-motion tilt on badges in v1.
7. A goal change in Settings after today's goal is reached applies tomorrow.
8. The build-up estimate assumes 3 days per step.
