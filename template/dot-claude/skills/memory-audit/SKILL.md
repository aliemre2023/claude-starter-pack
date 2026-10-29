---
name: memory-audit
description: Audits and fixes all memory layers (memory, decisions, knowledge, tasks) for content and structure — conflicts, duplicates, stale records, broken links, index sync. Use when SessionStart suggests it (30 days without an audit) or reports consistency issues, or when the user says memory is wrong.
---

# /memory-audit

1. **Structural check** — `python3 .claude/hooks/memory_lint.py`. Fix every issue it reports (missing frontmatter, file not in index, broken link, duplicate T-ID…).
2. **Content check** — Read every file in `.claude/memory/`, `decisions/` and `knowledge/` and look for:
   - **Conflicts**: two records say different things on the same topic → the most recent user statement wins; fix/delete the other. If it's a decision, supersede the ADR.
   - **Duplicates**: the same fact in several files → merge, update the index.
   - **Staleness**: if a record names a file/function/command/version/URL, check it still holds (file exists, grep, `--version`). If not, fix or delete it. Question `project` records whose `updated` date is older than 90 days in particular.
   - **Wrong layer**: a decision in memory, a user preference in knowledge, etc. → move it to the right layer.
   - **Relative dates**: "yesterday", "last week" → convert to an absolute date (remove if unknown).
   - **Secrets**: delete any token/password, write where it is stored instead.
   - **Private matters**: health, family, contact details or other personal data about anyone → delete (`.claude/` is usually committed).
3. **Tasks** — Any Active task idle for more than 14 days? Does Done exceed 20? Tidy up.
4. **Verify** — Run the lint again; it must be clean.
5. **Report** — List what changed per file (deleted, merged, fixed). Don't delete anything you're unsure about; mark it "could not verify" in the list.
6. Add a `## HH:MM — memory audit` entry to the journal (exactly this heading: SessionStart uses it to time the next reminder).
