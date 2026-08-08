# Documentation in Linear

**Status: migrated 2026-08-04.** Google Docs are no longer the source of truth.

---

## Where things live now

| Content | Home | Why |
|---|---|---|
| **PRD** | [Linear document](https://linear.app/pursuitjosue/document/clepsy-prd-v3-source-of-truth-04fc2dcdc3ec) | Product intent. Changes on product cadence; non-engineers read it. |
| **Decision Log** | [Linear document](https://linear.app/pursuitjosue/document/clepsy-decision-log-740f5dc501c9) + `docs/decisions/decision-log.md` | Linear holds the decisions and reasons; the repo copy carries file/line detail and changes with the code. |
| **Architecture** | `docs/data-architecture.md` | Describes code behavior — belongs next to the code. |
| **UI specs** | `docs/specs/` | Same. These are exactly what drifted. |
| **Brand / MVB** | `docs/plans/mvb-brand-guide.md` | Design reference; move to Linear if non-engineers start editing it. |
| **Work** | Linear issues, team `CLE` | — |

### The rule that keeps this from rotting again

Every divergence the audit found came from one cause: **a commit changed behavior without touching
the doc describing it.** Moving docs between tools doesn't fix that.

> **Describes what we want** → Linear. **Describes how the code behaves** → the repo, changed in the
> same PR as the code.

Tracked as CLE-32.

---

## Linear structure

**Team:** `clepsy` (`CLE`)

| Project | Contents |
|---|---|
| **Core Loop — Earning and Spending** | The central mechanic, both 180 ceilings, the two device spikes |
| **Notifications** | Milestone and status notifications; foundation exists, most types unbuilt |
| **History and Analytics** | Event ledger retention — blocks every success metric |
| **Error States and Hardening** | Permission failures, Settings states that can disable the product |
| **Documentation** | Bringing specs in line with the code |
| **Cleanup and Tech Debt** | Dead wiring from three architectural pivots, missing test coverage |
| **UI & Branding** | Pre-existing |

**Issues:** CLE-3 … CLE-34 created from the audit, plus pre-existing CLE-1 and CLE-2.

Priorities use Linear's scale (1 Urgent … 4 Low). Labels reuse the team's existing `Bug` / `Feature` /
`Improvement`. Descriptions carry `CD-xxx` / `R-xx` references back to the Decision Log, so
traceability survives the move.

---

## Two things to action in Linear

1. **CLE-2** (stale shield, FB14237883) — commented as likely resolved by `959da5f`. That commit's
   approach matches the "local notification at re-lock" mitigation CLE-2 itself recommended. Verify on
   device, then close.
2. **CLE-3 and CLE-5** are both blocked on physical-device access. Everything else can proceed
   without hardware.

---

## The CSV is legacy

`issues.csv` and `build-import.py` were built for a CSV import that turned out to be unnecessary —
the connector created the issues directly. They're kept only as a record of what was imported. **Don't
re-run the generator**; Linear is the source of truth for work now, and re-importing would duplicate.
