---
name: recap
description: Session wrap-up and interim summary — writes a journal entry, updates the task board, and scans the conversation for decisions/preferences/knowledge that weren't saved yet and saves them. Use when a meaningful block of work ends, before the user leaves, or when context compaction is near.
---

# /recap

1. **Scan for misses** — Go through this session's conversation from the start and list:
   - User preferences/corrections/approvals → save with the `/remember` steps
   - Decisions made → ADR with the `/decide` steps
   - Durable knowledge learned → knowledge base with the `/kb` steps
   - Tasks defined / finished / blocked → board with the `/task` steps
   Don't rewrite what's already saved (search first).
2. **Journal** — Append to `.claude/journal/YYYY-MM-DD.md` (create it with a `# YYYY-MM-DD` heading if missing):
   ```
   ## HH:MM — <session topic>
   **Done**
   - ...
   **Decisions**
   - [[NNNN-slug]] (or "—")
   **Open**
   - ... (starting point for the next session; SessionStart shows this)
   ```
   Append only; never change earlier entries.
3. **Check** — `python3 .claude/hooks/memory_lint.py`; fix any issues.
4. Give the user a 3-5 line summary: what was saved (with file paths) and what is still open.
