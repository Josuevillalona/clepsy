# Where Clepsy's documentation lives

**Linear is the source of truth.** Google Docs are retired.

---

## Four documents

| Document | Covers |
|---|---|
| [**Clepsy PRD v3**](https://linear.app/pursuitjosue/document/clepsy-prd-v3-source-of-truth-04fc2dcdc3ec) | Product intent. Every requirement carries a build status. |
| [**Clepsy Decision Log**](https://linear.app/pursuitjosue/document/clepsy-decision-log-740f5dc501c9) | Why the implementation works the way it does. `CD-xxx` |
| [**Clepsy Architecture**](https://linear.app/pursuitjosue/document/clepsy-architecture-ba0e4cc5e0f3) | Targets, storage, data flow, platform constraints. |
| [**Clepsy Brand (MVB)**](https://linear.app/pursuitjosue/document/clepsy-brand-mvb-65abb79c1d11) | Character, design system, tone of voice. |

## Nine projects — organised by surface

Each project's **description holds the decisions governing that surface**, so opening it tells you what
the surface is, why it works that way, and what's left. The tickets are the work; the description is
the documentation.

| Project | What it owns | Issues |
|---|---|---|
| 🚪 [**Onboarding**](https://linear.app/pursuitjosue/project/onboarding-29cd7bf584d9) | The five setup screens, permission flow, app pickers | CLE-11, 29 |
| 📊 [**Dashboard**](https://linear.app/pursuitjosue/project/dashboard-0a421da4edef) | Balance hero, streak, goal progress, history | CLE-12, 15, 19, 35 |
| 🛡️ [**Shield and Blocking**](https://linear.app/pursuitjosue/project/shield-and-blocking-8b107d362ec7) | The block screen and its two extensions | CLE-1, 2, 16, 17, 23 |
| ⚙️ [**Settings**](https://linear.app/pursuitjosue/project/settings-0926b2805a01) | Goal, app lists, notifications, data | CLE-6, 8, 9, 10 |
| 🌱 [**Earning Engine**](https://linear.app/pursuitjosue/project/earning-engine-12146d81bb77) | How productive time becomes balance | CLE-3, 4, 24 |
| ⏱️ [**Spending Sessions**](https://linear.app/pursuitjosue/project/spending-sessions-1b086054f371) | Usage-metered spending, re-lock at zero | CLE-5, 18 |
| 🔔 [**Notifications**](https://linear.app/pursuitjosue/project/notifications-6e94c15cb961) | Milestone and status notifications | CLE-13, 20 |
| 💾 [**Data and Platform**](https://linear.app/pursuitjosue/project/data-and-platform-e67412c04cdf) | Storage, App Group, daily reset, Apple constraints | CLE-7, 14, 25 |
| 🎨 [**Brand and Character**](https://linear.app/pursuitjosue/project/brand-and-character-348ffdbfbb5e) | Clepsy, design system, voice | CLE-26 |
| 📚 [**Docs and Process**](https://linear.app/pursuitjosue/project/docs-and-process-9d8f0a9228d6) | Keeping docs true | CLE-27, 28, 30, 31, 32, 34 |
| 🧹 [**Tech Debt**](https://linear.app/pursuitjosue/project/tech-debt-063ea9d9ecfd) | Dead wiring, test coverage | CLE-21, 22, 33 |

*"Error States and Hardening" was retired — its issues moved to the surface each one actually belongs
to.*

---

## What's still in the repo

| File | Status |
|---|---|
| `specs/earning.md` | **Stale** — describes `EarningSessionManager`, which nothing calls. Fix (CLE-24) then move. |
| `specs/onboarding.md` | **Stale** — six screens vs the five that shipped. CLE-29. |
| `specs/dashboard.md` | **Stale** — stat cards that were folded into the hero. CLE-35. |
| `specs/error-states.md` | **Backlog, not a spec** — ~0% implemented. CLE-34. |
| `specs/settings.md` | Largely accurate; moves with the others. |
| `data-architecture.md` | **Superseded** by the Linear Architecture doc — delete. |
| `plans/mvb-brand-guide.md` | **Superseded** by the Linear Brand doc — delete. |
| `plans/clepsy_mvp.md`, `CHANGELOG.md` | **Obsolete** — close out, don't migrate. CLE-30. |
| `mac-setup-guide.md`, `simulator-testing-guide.md` | **Stay.** Build-time runbooks belong next to the code. |
| `decisions/decision-log.md` | **Stays as a mirror** — Linear holds the decisions, this holds file/line detail and changes with the code. |
| `audit/` | Historical record of how this was found. Not a living doc. |

**Sequence:** fix a spec → move it to Linear → delete the repo copy. Migrating known-wrong docs into the
source of truth is worse than leaving them where they are.

---

## The rule

Every divergence the audit found came from one cause: **a commit changed behavior without touching the
doc describing it.** Moving docs between tools doesn't fix that.

> **What we want** → Linear. **How the code behaves** → the repo, changed in the same PR.

Tracked as CLE-32.

---

## Two things to action

1. **CLE-2** — likely resolved by `959da5f`, which implements the "local notification at re-lock"
   mitigation CLE-2 itself recommended. Verify on device, then close.
2. **CLE-3 and CLE-5** need a physical iPhone. Everything else can proceed without hardware.

---

*`issues.csv` and `build-import.py` are legacy — the connector created the issues directly. Kept as a
record only. **Don't re-run the generator**; it would duplicate.*
