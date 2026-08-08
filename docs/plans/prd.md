# Clepsy PRD

**Project:** Clepsy — time-trading iOS app
**Owner:** Josue
**Version:** v3.0 · 2026-08-04
**Status:** Current. Reconciled against the shipped implementation at `959da5f`.

> **This is the single source of truth for product intent.** Every requirement below carries a build
> status. Where the code and the old PRD disagreed, this version follows the code and records why.
>
> **Companion documents**
> - **Decision Log** — why the implementation works the way it does. Referenced below as `CD-xxx`.
> - **Architecture** — storage, App Group contract, the four targets.
>
> **Status legend:** ✅ Built · 🟡 Partial · ⬜ Not built · ❌ Struck (not achievable on iOS)

---

## Problem

Gen Z and Millennial social media users struggle to disengage from negative content loops
("doomscrolling") on platforms like TikTok and Reddit, often entering a state of "problematic use"
where they feel unable to stop despite recognizing the negative impact on their mood and schedule.

### Impact

- **Mental & physical health:** increased anxiety, depression, and sleep disturbance from prolonged
  exposure to distressing content.
- **Loss of function:** doomscrollers are 4× more likely to miss deadlines or opportunities.
- **Loss of time:** the average user loses 3.5 hours per week during workdays alone.

### Evidence

- 64% of Americans describe themselves as doomscrollers; 81% for Gen Z.
- 43% doomscroll daily; 26% multiple times a day (Morning Consult).
- A 2024 WHO report found over 10% of adolescents struggle to control usage — closer to addiction
  than habit.

---

## Opportunity

Enable Gen Z and Millennial doomscrollers to interrupt passive consumption loops and convert that
time into micro-progress toward personal goals, reclaiming ~3.5 hours per week through daily
intentional practice.

**Expected outcomes**

- **User:** reduce passive screen time 20% within 30 days; complete at least one productive session
  daily.
- **Product:** 25% Day-30 retention, proving daily expiration works where willpower-based apps fail.
- **Strategic:** position as a *daily intentionality coach*, not just a blocker — differentiating from
  Apple Screen Time and accumulation-based competitors.

**Why now:** algorithms have optimized passive consumption into problematic use for 10% of
adolescents; 42% of users identify "brain rot" content as a trigger; 51% cite politics — a cultural
moment primed for counter-tools.

---

## Users & Needs

**Primary — "The Powerless Scroller"** (18–35). Recognizes they lack self-control with social media.
Has tried built-in Screen Time limits but always taps "Ignore." Wants a system that enforces
boundaries *for* them and makes productive time feel rewarding rather than restrictive.

**Secondary — "The Aspiring Optimizer"** (22–35). Doesn't identify as addicted but wants to structure
time intentionally. Treats leisure as something earned and budgeted. Drawn to the quantified-self
angle and guilt-free scrolling within daily boundaries.

### Must have

1. **Vice apps blocked by default**, so they can't be opened unconsciously. ✅
2. **Verified proof of productive time via iOS Screen Time** before unlocking, so the system feels
   fair and ungameable. ✅
3. **Earned minutes as a shared bank across all vice apps**, not locked per app. ✅
4. **Automatic tracking in native apps** (Kindle, Duolingo) with no user action. ✅
5. **Deduction from the bank as vice apps are used**, so the cost of scrolling is felt immediately.
   ✅ *at 1-minute granularity — see J4 and CD-031*

### Should have

6. **Milestone notifications** ("15 minutes earned!") to sustain motivation. ⬜
7. **Earned time expires at midnight**, forcing a fresh start each day. ✅

### Nice to have

8. Adjustable productive-to-vice ratio (2:1 etc.) for increasing difficulty. ⬜ *V2*

---

## Solution

A time-trading iOS app with a supportive accountability character (Clepsy) that blocks distracting
apps by default. Vice apps unlock only when the user has earned time through productive apps, tracked
via Apple's Screen Time APIs. Clepsy's hourglass body visualizes the balance, making enforcement feel
collaborative rather than punitive.

### Top 3 MVP value props

1. **The Vitamin — verified blocking that can't be bypassed.** Vice apps are locked by iOS itself.
   There is no "Ignore Limit" button.
2. **The Painkiller — force conscious decisions, not autopilot.** Every attempt to open a vice app
   shows exactly what's available and what it costs, breaking the unconscious habit loop.
3. **The Steroid — every day is a fresh start.** The bank resets at midnight. You can't bank hours on
   Sunday to coast on Monday.

---

## Goals & Non-Goals

**Goals**

1. Break the autopilot habit — reduce unintentional vice usage 50% within 30 days.
2. Drive daily productive behavior — at least one productive session per day, 7-day streak within 30
   days.
3. Reach 25% Day-30 retention among Powerless Scrollers.
4. Validate the core mechanic before monetizing. Launch free.

**Non-goals**

1. No buddy/social features in MVP (V1.5).
2. No Android (V2 — requires a different technical approach entirely).
3. No custom exchange rates. MVP is strict 1:1.
4. No in-app productivity tools. Users use their own native apps.
5. No rollover or banking across days. Daily expiration is the mechanic.
6. No monetization at launch.
7. **No caps on earning.** The daily goal is a *floor* that sets the streak bar, never a ceiling — a
   user who wants to earn six hours should be able to. See CD-036.

---

## Success Metrics

| Goal | Metric | Target |
|---|---|---|
| Break autopilot habit | **Earning activation rate** — % completing one full earn→unlock→spend cycle in 14 days | >50% |
| Daily productive behavior | **Daily earning consistency** — % with a 7-day streak within 30 days | >40% |
| Sustained engagement | **Daily earned minutes** per active user | >20 min/day |
| Retention | **Day-30 retention** | >25% (vs. ~10–15% for typical blockers) |
| Trust | **Support tickets** about miscredited time or unfair blocking | <3% of actives |
| Organic discovery | % encountering the morning fresh-start shield within 7 days | >80% |
| Responsiveness | Tap-to-unlock app opening latency | <1s |
| Fluidity | Time to first dashboard data load | <2s |
| Accuracy | Tracking accuracy vs. actual usage | 95%+ |

> ⚠️ **Most of these are not yet measurable.** There is no analytics instrumentation, and no earning
> or spending history is retained (see J5). Instrumentation is a prerequisite for validating any of
> this.

---

## Requirements

Organized by user journey. **[P0]** = must-have to launch · **[P1]** = should-have · **[P2]** =
nice-to-have.

---

### Journey 1 — First-Time Setup

**Context:** The make-or-break moment. Users must grasp time-trading and grant permissions. Target:
<2 minutes to first blocked-app encounter.

**As built:** five screens — Welcome (concept + 4 feature rows) → Permission → Vice app picker →
Productive app picker → Daily goal. Then a 2.5-second celebration overlay on first dashboard load.
Originally specced as seven screens; compressed to hit the <2min target (CD-016).

| # | Requirement | Status |
|---|---|---|
| P0 | Explanation of how time-trading works, including midnight expiry | ✅ |
| P0 | Grant Family Controls permission, with rationale shown first | ✅ |
| P0 | Error state if permission is denied, with retry | ⬜ **Gap — the flow currently advances regardless, stranding the user on a dashboard that can't work** |
| P0 | Select vice apps to block (minimum 1) | ✅ |
| P0 | Select productive apps to track (minimum 1) | ✅ |
| P0 | Search for apps not in a suggested list | ✅ *provided by Apple's picker* |
| P0 | Set milestone notification preference | ⬜ *no onboarding step; see J6* |
| P1 | See current weekly usage per app to prioritize | ⬜ |
| ~~P2~~ | ~~Select whole app categories (Social Media, News, Gaming)~~ | ❌ **Struck** |

> **❌ Why category blocking is struck (CD-001).** A category token cannot be unshielded for a single
> app inside it, which breaks the entire spending model. Apple's picker offers no way to hide the
> category checkboxes, so both pickers validate after selection and require individual apps. This is
> permanent, not a workaround.

---

### Journey 2 — Earning Time

**Context:** Where the bank is built. Tracking must be accurate and require nothing from the user.

**As built:** one repeating daily DeviceActivity schedule over the productive apps, with a threshold
event every minute of cumulative usage. Each firing credits 60 seconds to a shared event ledger. The
app drains that ledger into the balance when next foregrounded; the shield reads a live mirror, so it
is always current.

| # | Requirement | Status |
|---|---|---|
| P0 | Background tracking that works when Clepsy is closed | ✅ |
| P0 | 1:1 rate — one minute of productive use earns one minute | ✅ |
| P0 | No cap on daily earning | 🟡 **Currently capped at 180 min/day — unintended, see below** |
| P0 | Milestone notification on hitting an earning threshold | ⬜ |
| P0 | Tapping that notification opens the app | ⬜ |
| ~~P0~~ | ~~60-second warmup before tracking begins~~ | ❌ **Struck** |
| ~~P0~~ | ~~Session pause/resume with a 2-minute timeout~~ | ❌ **Struck** |
| P0 | Locking the phone stops tracking | ✅ *handled by iOS — usage doesn't accrue* |

> **❌ Why warmup and session pause/resume are struck (CD-011).** Both require observing app
> foreground/background transitions. A DeviceActivity extension only receives threshold crossings — it
> is never told when an app opens or closes. `EarningSessionManager` in the codebase implements this
> model faithfully and is deliberately **not wired up** (CD-024); don't mistake it for live behavior.

> **🟡 The 180-minute cap is a bug, not a decision (CD-012, CD-036).** iOS requires pre-registering a
> fixed list of threshold alarms; the implementation registers 180 and then goes silent. There is no
> intended ceiling. The fix (CD-037, unverified) is a re-arming ladder — register a short list and
> restart the schedule when it's exhausted. **This must ship together with the spending-side fix in
> J4**, since removing the earning cap alone opens an exploit.

---

### Journey 3 — The Block

**Context:** The critical intervention. The user is opening TikTok on autopilot; the shield must break
that pattern without causing rage-quit.

**As built:** a custom shield rendered by a dedicated extension. With balance: *"You have N min. It
only counts down while you're in blocked apps."* with a **"Use My Time"** primary button and a
**"Go Back"** secondary. Without balance: a single "Go Back."

| # | Requirement | Status |
|---|---|---|
| P0 | Custom shield when opening a blocked app | ✅ |
| P0 | Shows current available balance | ✅ |
| P0 | Primary action to spend earned time | ✅ |
| P0 | Zero-balance state | 🟡 *exists, but doesn't distinguish morning fresh-start from spent-it-all* |
| P0 | Shows expiration indicator ("expires at midnight, 5 hours left") | ⬜ |
| P0 | Shows last-updated timestamp | ⬜ |
| P0 | Features the Clepsy character | 🟡 *a static mascot icon; not the animated character, no expression states* |
| P0 | Sand level reflects the user's standing | ✅ *shows spendable balance — see below* |
| ~~P0~~ | ~~"Earn Time Now" button that opens the main app~~ | ❌ **Struck** |

> **❌ Why "Earn Time Now" is struck (CD-005).** A ShieldAction extension has no API to launch another
> app. A button that silently does nothing is worse than no button, so the zero-balance state offers
> one honest action.

> **📐 The hourglass shows spendable balance, not goal progress (CD-018).** Sand drains as time is
> spent, which is what an hourglass should do. This reverses the original spec. Note the character's
> *face* still keys off goal progress while the *body* keys off balance (CD-019) — deliberate for now,
> worth revisiting.

> **⚡ Shield extensions are killed if slow (CD-003).** The shield reads the balance from a
> UserDefaults mirror rather than the event ledger, because file coordination was too slow and the
> failure mode is silent — you get Apple's generic "Restricted" screen with no error. Any new field
> shown on the shield must be readable from that fast path.

---

### Journey 4 — Spending Time

**Context:** The user earned this. It should feel like a fair transaction — guilt-free, accurately
metered.

**As built (CD-031):** tapping "Use My Time" starts a **spending session**. All vice apps unshield at
once. Nothing is charged up front. The balance drains **one minute per minute of actual vice-app
usage** — wall-clock time doesn't count. When it hits zero, the session ends: the app is terminated,
the shield returns, and a "Time's up" notification explains why.

| # | Requirement | Status |
|---|---|---|
| P0 | Spend earned time from the shield | ✅ |
| P0 | Vice app opens immediately after unlocking | ✅ |
| P0 | Time is deducted as the user actually uses vice apps | ✅ *1-minute granularity* |
| P0 | Wall-clock time does not consume balance | ✅ |
| P0 | Apps re-shield automatically when the balance hits zero | ✅ |
| P0 | Shared bank — switch freely between vice apps | ✅ |
| P0 | Bank resets to zero at local midnight | 🟡 *only checked when the app is opened; a backgrounded app misses it (CD-004 gap)* |
| P0 | No spending cap within a session | 🟡 **Capped at 180 min — same root cause as J2** |
| P0 | Mid-session midnight cutoff — locks at 12:00 AM | ⬜ |
| P0 | Fresh-start explanation the next morning | ⬜ |
| P1 | Confirmation when a session starts | ⬜ |
| ~~P0~~ | ~~Per-second (1-second increment) tracking~~ | ❌ **Struck — 1 minute is the finest granularity iOS offers** |

> **📌 The old PRD said this was "real-time deduction as you scroll." That intent survived; only the
> resolution changed.** An earlier version of this audit claimed metered deduction was impossible on
> iOS. That was wrong. Per-second isn't available to a background extension, but per-minute is, using
> the same threshold mechanism as earning.

> **🔑 Metering is anchored at session start, not midnight (CD-032).** Thresholds count usage *inside
> the schedule interval*. A midnight-anchored interval would see all of today's earlier vice usage
> already banked and fire every threshold at once, draining a full balance in seconds. This is the
> subtlest thing in the codebase — do not "simplify" it.

> **⚠️ One session unshields everything (CD-034).** Opening Instagram also unlocks TikTok. Consistent
> with the shared-bank model, but it means the friction moment happens once per session rather than
> once per app. Worth watching in user testing.

> **🛑 Exhaustion terminates the app deliberately (CD-033).** Applying a shield over a *foreground* app
> renders a stale cached screen (Apple bug FB14237883). Instead the app is hard-blocked for a moment,
> which terminates it, then the normal shield is restored. The user lands on the home screen with a
> notification. This sidesteps the Apple bug entirely rather than working around it.

---

### Journey 5 — Dashboard

**Context:** Builds awareness and reinforces time-as-currency.

**As built:** balance hero card with the animated mascot and a pulsing glow, inline earned/spent
stats, a conditional streak banner, a goal progress bar, and lists of blocked and productive apps.

| # | Requirement | Status |
|---|---|---|
| P0 | Current balance prominently displayed | ✅ |
| P0 | Today's earned time | ✅ *persisted; survives relaunch* |
| P0 | Today's spent time | ✅ |
| P0 | Daily goal progress | ✅ |
| P0 | Balance shown with an expiration indicator | ⬜ |
| P0 | Visual countdown to the midnight reset | ⬜ |
| P0 | List of recent earning sessions (app, duration, time) | ⬜ **No history is retained at all — see below** |
| P0 | List of recent spending sessions | ⬜ |
| P1 | Streak counter | ✅ |
| P1 | Net positive/negative for the day | ⬜ |
| P1 | Weekly summary | ⬜ |

> **🔥 The streak counts goal-completion days, not participation days (CD-020).** It increments only
> when the daily goal is fully met. **Accepted consequence:** a user earning 20 minutes against a
> 30-minute goal every day for a month has a streak of zero. If this proves demotivating, the lever is
> the goal default, not the streak rule.

> **📉 No history exists (D4).** `TimeEvent` already carries app, duration and timestamp — but events
> are discarded immediately after being applied to the balance. Retaining them is a prerequisite for
> the history requirements above *and* for most of the success metrics in this document.

---

### Journey 6 — Settings & Errors

| # | Requirement | Status |
|---|---|---|
| P0 | Add/change vice apps | ✅ |
| P0 | Add/change productive apps | ✅ *re-registers the earning schedule* |
| P0 | Change the daily goal | ✅ *15/30/45/60/90/120 min, matching onboarding (CD-022)* |
| P0 | Enforce at least one app in each list | 🟡 *enforced in onboarding, **not** in Settings — a user can clear both and silently disable the product* |
| P0 | Prevent the same app being both vice and productive | ⬜ |
| P0 | Disable all notifications | ✅ |
| P0 | Change milestone notification threshold | 🟡 *the picker exists but the value is never persisted — resets to 15 every launch* |
| P0 | See app version | ✅ |
| P0 | Error if Family Controls permission is revoked | ⬜ |
| P0 | Handle device restart gracefully | ✅ *shields persist via iOS; balance in UserDefaults* |
| P1 | Privacy policy and terms | ✅ |
| P1 | "How Clepsy works" explainer | ✅ |
| P2 | Reset all data | 🟡 *works, but doesn't clear the streak* |

**Notifications as built (CD-035):** permission is requested, the toggle is honored via an App Group
mirror, and the "Time's up" notification fires at exhaustion. Milestone, low-balance, weekly-summary
and fresh-start notifications are all still unbuilt.

---

## Technical Dependencies

**Frameworks:** FamilyControls (permission) · ManagedSettings (shielding) · DeviceActivity (usage
thresholds) · UserNotifications.

**Not used:** `DeviceActivityReport`. It renders usage inside a sandboxed view whose data the host app
cannot read, so it cannot back a balance. Clepsy maintains its own event ledger instead (CD-013).

**Targets:** the app plus three extensions — `ClepsyMonitor` (usage thresholds),
`ClepsyShieldConfiguration` (shield UI), `ClepsyShieldAction` (shield buttons). They communicate
solely through the `group.com.clepsy.shared` App Group.

**Minimum:** iOS 16.0, iPhone. Paid Apple Developer account required — Family Controls entitlements
can't be provisioned otherwise, and **none of this works in the Simulator**.

**Platform constraints that shape the product:**

- Thresholds must be pre-registered; there is no "notify me every minute forever" (CD-037).
- DeviceActivity intervals must be ≥15 minutes (CD-006).
- Restarting a schedule resets its accumulated usage (CD-008).
- Shield configuration extensions are killed if slow, silently (CD-003).
- App tokens are opaque — Apple never reveals which app a token refers to.

---

## Future Considerations

**V1.5 — Social accountability:** buddy system for emergency unlocks, shared progress, friend
challenges. Deferred until the core loop is validated solo.

**V1.5 — Potential premium:** advanced analytics, custom notification timing, weekly reports.

**V2 — Platform expansion:** Android (different technical approach entirely), custom exchange rates,
web dashboard, family/parent monitoring.

---

## Open Questions

1. **Does the re-arming ladder work on device?** (CD-037) Gates removing both caps. Needs a physical
   iPhone.
2. **Is one-session-unshields-everything the right friction model?** (CD-034) Or should each app
   require its own decision?
3. **Should the character's face and body track the same quantity?** (CD-019) Body shows balance, face
   shows goal progress.
4. **When does analytics instrumentation land?** None of the success metrics are measurable today.

---

## Document History

- **v3.0** — 2026-08-04 — Reconciled against the shipped implementation. Struck four requirements that
  iOS cannot support (categories, "Earn Time Now", earning warmup/sessions, per-second deduction);
  rewrote J4 around the session model as built; corrected the hourglass and streak definitions to
  match the code; added build status to every requirement; recorded the two unintended 180-minute caps
  as bugs rather than decisions.
- v2.1 — 2025-01-30 — Removed proactive expiration warnings, clarified free launch, streamlined
  notifications for organic discovery of the reset.
- v2.0 — 2025-01-30 — Daily expiration as core mechanic; revised value props and journeys.
- v1.0 — 2025-01-24 — Initial draft. *Superseded; do not reference.*
