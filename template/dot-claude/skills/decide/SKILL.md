---
name: decide
description: Records a decision as an ADR under .claude/decisions/. Use when a technology, architecture, scope, naming or process decision is made (the user stated it or approved my proposal) and when an earlier decision changes.
argument-hint: <decision>
---

# /decide

Decision: $ARGUMENTS (if empty, extract the latest decision from the conversation).

1. **Threshold** — Is it a small, easily reversible implementation detail? Then don't write an ADR; add a journal note if useful. Any decision whose rationale may be asked about later is an ADR.
2. **Conflict** — Read `.claude/decisions/INDEX.md`. If an `accepted` ADR exists on the same topic, the new decision supersedes it:
   - In the old ADR change only `status: superseded` and `superseded_by: <new no>` (don't touch the body).
   - In the new ADR fill in `supersedes: <old no>` and explain in Context why it changed.
3. **Write** — Create `NNNN-<kebab-slug>.md` from `TEMPLATE.md` with the next number. Take alternatives and rationale from the conversation; don't invent what isn't known, write "not stated". Fill in `decided_by` correctly.
4. **Index** — Add a row to the `INDEX.md` table; update the status of the superseded one.
5. **Link** — If the decision affects a memory/knowledge record or a task, update it (e.g. a knowledge page that mentions the old technology).
6. `python3 .claude/hooks/memory_lint.py`, then one line: `📝 decision: NNNN <title>`.
