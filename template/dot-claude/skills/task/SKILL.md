---
name: task
description: Manages the .claude/tasks/TASKS.md task board — add, start, finish, block, list and prioritize tasks. Use when the user defines new work, says "we'll look at it later", when work starts, or when it's finished.
argument-hint: add|start|done|block|list|prio [T-NNN] [description]
---

# /task

Command: $ARGUMENTS (`list` if empty).

Board: `.claude/tasks/TASKS.md`. IDs come from the `Next ID` counter at the top of the file; increment it after every add.

- **add <title> [P0-P3]** — Default P2, `## Backlog`. If it's to be done right away, `## Active`. If the same task already exists, don't add it; update the existing line.
- **start T-NNN** — Move to `## Active`, set the marker to `[>]`. At most 3 `[>]` tasks at once; if there are more, tell the user which one is waiting.
- **done T-NNN** — Set `[x]`, append `✓ YYYY-MM-DD` to the line, move it to the top of `## Done`. If Done exceeds 20, move the oldest to `tasks/archive.md`. If the task produced durable knowledge or a decision, suggest or run `/kb` or `/decide`.
- **block T-NNN <reason>** — Set `[!]`, move to `## Blocked`, write the reason and what it is waiting on.
- **prio T-NNN P0-P3** — Change the priority; Active and Backlog stay sorted by priority.
- **list** — Briefly show Active + Blocked + the first 5 of Backlog; give a one-sentence suggestion on what to work on.

Rules: the board is the single source of truth. If I finished work in the conversation, I update the board even if the user didn't ask. After any change run `python3 .claude/hooks/memory_lint.py`.
