# Documentation in Linear

**Status: migrated.** Google Docs are no longer the source of truth.

---

## Linear documents

| Document | Covers |
|---|---|
| [**Clepsy PRD v3**](https://linear.app/pursuitjosue/document/clepsy-prd-v3-source-of-truth-04fc2dcdc3ec) | Product intent, every requirement with a build status |
| [**Clepsy Decision Log**](https://linear.app/pursuitjosue/document/clepsy-decision-log-740f5dc501c9) | Why the implementation works the way it does |
| [**Clepsy Architecture**](https://linear.app/pursuitjosue/document/clepsy-architecture-ba0e4cc5e0f3) | Targets, storage, data flow, platform constraints |
| [**Clepsy Brand (MVB)**](https://linear.app/pursuitjosue/document/clepsy-brand-mvb-65abb79c1d11) | Character, colors, typography, tone of voice |

Team `clepsy` (`CLE`) · issues CLE-1 … CLE-34 across six projects.

---

## Still in the repo, and why

**Not a recommendation to keep them there — a sequencing decision.** Each is either stale or genuinely
build-time material.

| File | Why it hasn't moved |
|---|---|
| `docs/specs/earning.md` | Describes `EarningSessionManager`, which nothing calls. Moving it verbatim would enshrine a fiction. Rewrite first — **CLE-24**. |
| `docs/specs/onboarding.md`, `dashboard.md` | Stale: six screens vs the five that shipped; stat cards that were folded into the hero card. **CLE-29**. |
| `docs/specs/error-states.md` | 1,065 lines, ~0% implemented. That's a backlog, not a spec. **CLE-34**. |
| `docs/specs/settings.md` | Largely accurate; moves with the other specs. |
| `docs/data-architecture.md` | **Superseded** by the Linear Architecture doc. Delete or stub it — **CLE-25** is closed. |
| `docs/plans/mvb-brand-guide.md` | **Superseded** by the Linear Brand doc. |
| `docs/plans/clepsy_mvp.md` | Obsolete 30-task plan, mostly executed. Close out, don't migrate — **CLE-30**. |
| `docs/CHANGELOG.md` | Pre-implementation proposal ending "Ready to Begin Task 0?" — **CLE-30**. |
| `docs/mac-setup-guide.md`, `simulator-testing-guide.md` | Build-time runbooks. These belong next to the code. |
| `docs/decisions/decision-log.md` | Mirrors the Linear doc, plus file/line detail. Changes in the same PR as the code. |
| `docs/audit/` | Historical record of how all this was found. Not a living doc. |

**Order of operations:** fix a spec (CLE-24, CLE-29, CLE-34), then move it to Linear and delete the
repo copy. Migrating known-wrong docs into the source of truth is worse than leaving them where they
are.

---

## The rule that keeps this from rotting again

Every divergence the audit found came from one cause: **a commit changed behavior without touching the
doc describing it.** Moving docs between tools doesn't fix that.

Tracked as CLE-32.

---

## Two things to action

1. **CLE-2** (stale shield, FB14237883) — commented as likely resolved by `959da5f`, which implements
   the "local notification at re-lock" mitigation CLE-2 itself recommended. Verify on device, close.
2. **CLE-3 and CLE-5** need a physical iPhone. Everything else can proceed without hardware.

---

## The CSV is legacy

`issues.csv` and `build-import.py` were built for a CSV import that turned out to be unnecessary — the
connector created the issues directly. Kept only as a record of what was imported. **Don't re-run the
generator**; it would duplicate.
