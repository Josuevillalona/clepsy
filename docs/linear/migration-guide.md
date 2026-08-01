# Migrating Clepsy Documentation to Linear

**Status:** ready to execute. The backlog is generated; the docs need one decision from you first (see
§2).

---

## 0. Blocker: the Linear connector isn't authorized

Linear appears in this workspace's connector list but has **not been authorized**, and this session is
non-interactive so the OAuth flow can't run here. Until it's connected I can't create issues or
documents in Linear directly.

**To fix:** authorize Linear in your **claude.ai connector settings**. Once it's connected, a new
session can create projects, issues, and documents directly from these files — no CSV needed.

Everything below works *without* that, so you're not blocked on it.

---

## 1. What should actually go to Linear

Worth being deliberate here, because the drift this audit found has a cause: **the specs live apart
from the code that keeps invalidating them.** Moving them from one place-apart-from-code (Google Docs)
to another (Linear) doesn't fix that on its own.

Recommended split:

| Content | Where | Why |
|---|---|---|
| **PRD** (v2.1 only) | Linear document, project-level | Product intent, changes on product cadence, non-engineers read it |
| **Product Principles** | Linear document | Stable, strategic, referenced in decisions |
| **MVB / brand guide** | Linear document | Design reference, rarely changes with code |
| **Decision log** | **Repo** (`docs/decisions/`) | Changes *with* the code; PR review is what keeps it honest |
| **Architecture** | **Repo** (`docs/data-architecture.md`) | Same — it went stale precisely because it was elsewhere |
| **UI specs** (onboarding, dashboard, settings, shield, earning) | **Repo** (`docs/specs/`) | These are what drifted. Keep them next to the views they describe |
| **Error-state spec, notification spec** | Linear **issues**, not docs | ~0% implemented — that's a backlog, not a specification |
| **`clepsy_mvp.md` plan** | Linear issues (the unbuilt tasks only) | Mostly executed; the rest is history |
| **"FEATURES for PRD" backlog, V1.5/V2 lists, scratch notes** | Linear project "Ideas" | Idea capture, not spec |

The one rule that would have prevented most of this audit: **if a doc describes how the code behaves,
it lives in the repo and changes in the same PR.** If it describes what we want, it lives in Linear.

---

## 2. Documents: three ways in

Linear has no bulk markdown importer for documents, so pick one:

**A. Manual paste (fastest for 3 docs).** Create the project, then New document → paste the markdown.
Linear's editor accepts pasted markdown and converts it. For the PRD, paste only v2.1 — cut v1.0 first.

**B. Via the connector** (after §0). I can create the documents directly with the right project
association and formatting.

**C. Via the API.** `documentCreate` in Linear's GraphQL API takes markdown in `content`. Worth it only
if you want this repeatable.

⚠️ **Do the PRD amendments before or during migration, not after.** Copying the PRD as-is imports four
requirements that are known-unimplementable (CD-001 categories, CD-005 "Earn Time Now", CD-011 warmup/
sessions, CD-014 real-time deduction). Migrating them unchanged means someone files them as bugs later.

---

## 3. Issues: import the generated CSV

`docs/linear/issues.csv` — **45 issues**, generated from the audit and decision log by
`docs/linear/build-import.py` (edit the Python, re-run, don't hand-edit the CSV).

### Contents

| Project | Issues | Notes |
|---|---|---|
| Release readiness | 1 | The `#if DEBUG` gate — genuinely urgent, ships free balance today |
| Decisions | 5 | The open calls from the decision log, as issues so they don't get lost |
| Earning engine | 3 | Includes removing the 180-min ceiling (decided) |
| Spending & shield | 6 | Includes writing the missing shield spec |
| Daily expiration | 3 | |
| Notifications | 4 | P0 in the PRD, 0% built |
| History & analytics | 2 | P0 in the PRD, 0% built |
| Error states | 3 | |
| Settings hardening | 3 | |
| Docs & hygiene | 9 | |
| Cleanup | 6 | Dead code and loose ends |

Priorities use Linear's scale: **1 Urgent, 2 High, 3 Medium, 4 Low**. One Urgent (the debug gate),
14 High, 20 Medium, 10 Low. Estimates are rough points, mostly 1–5.

### Steps

1. Create the team (or use an existing one).
2. **Settings → Workspace → Import / Export → Import issues → CSV.**
3. Upload `issues.csv` and use the column-mapping step to confirm each column.
4. Import into the backlog, review, then bulk-assign to projects.

**Two caveats, so nothing surprises you:**

- **Verify the mapping screen rather than trusting my headers.** `Title` and `Description` are
  reliable; `Priority`, `Labels`, `Estimate`, and `Status` map cleanly in my experience. I'm **not
  confident Linear's CSV importer honors a `Project` column** — if it doesn't appear in the mapping
  step, import without it and group afterward by sorting on that column, or drop the column and
  bulk-select by batch.
- **Import into a scratch team first if you want a dry run.** Linear has no one-click undo for a bulk
  import; cleanup means selecting and deleting.

### If you'd rather use the API

A personal API key plus `issueCreate` gives you what CSV can't: real project association, sub-issues,
and labels created on the fly. `build-import.py` already holds the data as structured Python — it's a
small change to emit GraphQL mutations instead of CSV rows. Say the word and I'll write it.

---

## 4. Suggested Linear structure

```
Team: Clepsy
├─ Project: MVP Release Readiness     ← the debug gate + P0 gaps blocking any external build
├─ Project: Earning & Spending Engine ← CD-011/012/014/021; the core loop
├─ Project: Notifications             ← 0% built, fully specified
├─ Project: History & Analytics       ← 0% built, PRD P0
├─ Project: Error States              ← 0% built
├─ Project: Documentation             ← PRD amendments + doc debt
└─ Project: Ideas                     ← V1.5/V2, FEATURES backlog, scratch notes
```

Labels used in the CSV: `decision`, `bug`, `feature`, `docs`, `tech-debt`, `tests`, `scaffolding`.

The `decision` label is the one to watch — five issues are blocked on your call, and four of those
block real work (the unlock cap gates the constant-unification issue; the streak definition gates a
PRD amendment; the `EarningSessionManager` call gates the earning spec rewrite; the category call
gates removing unreachable code).

---

## 5. After migration

1. **Freeze the Google Docs.** Set Docs 1 and 2 to read-only with a header pointing at Linear. Don't
   delete — they're the provenance for the decision log.
2. **Archive Doc 3** entirely ("Copy of Productivity app notes"). No unique content.
3. **Keep `docs/` in the repo authoritative** for architecture, decisions, and UI specs. Add a line to
   the README pointing at Linear for product intent and the repo for behavior.
4. **Wire the loop:** put "does this change a doc in `docs/`?" in the PR checklist. That's the piece
   that was missing — every divergence in the audit came from a commit that changed behavior without
   touching the doc describing it.

---

## Regenerating the backlog

```bash
python3 docs/linear/build-import.py   # rewrites docs/linear/issues.csv
```

Edit `ISSUES` in the script — title, priority, labels, estimate, project, description. Descriptions
carry `CD-xxx` / `C-xx` / `H-x` / `D-x` references back to the decision log and audit, so traceability
survives the import.
