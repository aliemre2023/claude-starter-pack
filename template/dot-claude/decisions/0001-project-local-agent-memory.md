---
id: 0001
title: Agent memory lives inside the project, in a layered file structure
status: accepted
date: {{DATE}}
decided_by: user
supersedes:
superseded_by:
tags: [meta, memory, tooling]
---

# 0001 — Agent memory lives inside the project, in a layered file structure

## Context
The project needs an agent that builds its own knowledge base, records decisions and user preferences, manages tasks and keeps its memory accurate — with everything kept local to the project. The structure was installed from `claude-starter-pack`.

## Decision
Five layers under `.claude/`: `memory/` (Claude Code's auto-memory directory, redirected via `autoMemoryDirectory`), `decisions/` (ADRs), `knowledge/`, `tasks/TASKS.md`, `journal/`. The protocol is in `CLAUDE.md`; the `SessionStart` hook adds a summary to context, the `UserPromptSubmit` hook flags durable-information signals, and `memory_lint.py` checks structural consistency.

## Alternatives considered
- **Global auto-memory (`~/.claude/projects/...`)** — lives outside the project and breaks the "local" requirement.
- **MCP memory server / vector DB** — extra dependency; plain markdown is readable, diffable and versioned with git.
- **One big NOTES.md** — conflicts and duplicates pile up as it grows; one fact per file + an index can be audited.

## Consequences
- Gained: memory is versioned in git, portable, and readable/editable by humans.
- Cost: for security reasons `autoMemoryDirectory` only works in `settings.local.json` and holds an absolute path; it must be set again when the repo is cloned on another machine.
- Revisit when: memory grows to hundreds of records and the index bloats context (a search/summary layer may be needed).

## Related
CLAUDE.md → "Memory layers"
