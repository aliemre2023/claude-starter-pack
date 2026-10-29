---
name: remember
description: Saves the user's behavior, preference, correction or project context under .claude/memory/. Use when the user says "remember", "from now on", "always/never", "don't do that" (or the equivalent in their language), approves or corrects an approach, or asks for the same thing a second time.
argument-hint: <what to save>
---

# /remember

To save: $ARGUMENTS (if empty, extract what is durable from the recent conversation).

1. **Classify** — `user` (who they are, expertise, preferences), `feedback` (how I should work: a correction or an approved approach), `project` (goal, constraint, date), `reference` (pointer to an external resource). A decision goes to `/decide`, domain knowledge to `/kb`.
2. **Search** — Check `.claude/memory/MEMORY.md` and `grep -ril` for a record covering the same topic.
   - If found: update that file (refresh `updated`). On conflict the new statement wins; delete the old content, optionally leave a "was X, became Y on YYYY-MM-DD" note.
   - If not: create `.claude/memory/<type>_<slug>.md` (format in CLAUDE.md).
3. **Body** — One fact. `**Why:**` and `**How to apply:**` are required for feedback/project. Add the concrete event and an absolute date. Link related records with `[[name]]`.
4. **Index** — Add/update a `- [Title](file.md) — short hook` line in `MEMORY.md`. Content never goes into the index.
5. **Verify** — Run `python3 .claude/hooks/memory_lint.py` and fix any issues.
6. One line to the user: `📝 memory: <summary> → <file>`.
