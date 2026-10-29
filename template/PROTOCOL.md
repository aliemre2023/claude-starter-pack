# Agent Working Protocol

In this project Claude works as a persistent agent that manages its own memory and knowledge base.
**Everything lives inside this project, under `.claude/`.** Nothing about this project is written to global memory (`~/.claude/...`).

## Memory layers

| Layer | Location | What it holds | Rule |
|---|---|---|---|
| Memory | `.claude/memory/` | User (who they are, expertise, preferences), feedback (corrections + approved approaches), project context, references | One fact per file; `MEMORY.md` is the index |
| Decisions | `.claude/decisions/` | Decisions made (ADRs): what, why, alternatives, consequences | Numbered; an accepted ADR is **never edited**, a new one is written with `supersedes` |
| Knowledge | `.claude/knowledge/` | Domain knowledge, architecture, glossary, how-tos, research findings | Living documents; kept up to date with an `updated` date |
| Tasks | `.claude/tasks/TASKS.md` | Single board for all work (Active / Blocked / Backlog / Done) | Single source of truth; IDs are `T-NNN` |
| Journal | `.claude/journal/YYYY-MM-DD.md` | What was done in a session, what is left | Append-only |

`memory/` is Claude Code's built-in auto-memory directory (`.claude/settings.local.json` → `autoMemoryDirectory`), so `MEMORY.md` is loaded automatically every session. A summary of the other layers is added to context at session start by the `SessionStart` hook.

## When I write — proactively, without being asked

- **When I see a user behavior / preference** → `memory/` (type `user` or `feedback`). Triggers: "from now on", "always", "never", "don't do that", "make it like this", a correction, approval of an approach, a recurring habit (asking for the same thing a second time) — or the equivalent in the user's language.
- **When a decision is made** (technology, architecture, scope, naming, process; by the user, or proposed by me and approved) → new ADR in `decisions/`. Small, easily reversible implementation details are not ADRs.
- **When I learn or research something durable** (external source, domain rule, how the system works) → `knowledge/`.
- **When work is defined, started, finished or blocked** → `tasks/TASKS.md`. "Let's also do X", "we'll look at it later" → Backlog.
- **When a meaningful block of work ends, and at session end** → `journal/` entry (`/recap`).

**One home per fact:** how the user wants me to work → `memory/`; why the project is built this way →
`decisions/`; how something works → `knowledge/`; what is left to do → `tasks/`; what happened → `journal/`.
The journal links to records (`[[name]]`) instead of repeating them; `project` memory is only for context that
fits none of the other layers (deadlines, stakeholders, constraints).

After writing I tell the user in one line: `📝 memory: <what was saved> → <file>`.

## Accuracy rules (keeping memory correct)

1. **Search before writing.** If a file already covers the topic, update it; don't create a duplicate.
2. **Conflict = the most recent user statement wins.** Update or delete the old record; never keep both. For decisions, write a new ADR and mark the old one `superseded`.
3. **Fix or delete a wrong record immediately.** Stale information is worse than none.
4. **Don't trust memory blindly.** If a record names a file, function, command or version, verify it still holds before recommending it; if not, fix the record.
5. **Use absolute dates** (`2026-10-25`), not "yesterday / last week".
6. **Record source and rationale.** `**Why:**` and `**How to apply:**` in feedback/project records; `sources` in knowledge.
7. **Indexes stay in sync.** When adding/removing a file, update the matching `INDEX.md` / `MEMORY.md` line. Check with `python3 .claude/hooks/memory_lint.py`.
8. **Don't record what the repo already records** (code structure, git history). Only write what can't be derived from the code.
9. **Never write secrets** (tokens, passwords, API keys) — only where they are stored.
10. **Only work-relevant facts about people.** `.claude/` is usually committed: no health, family, contact
    details or other private matters, even if mentioned. Keep `user` records to how they want to work.

## File formats

**memory/** (`<type>_<slug>.md`):
```markdown
---
name: <kebab-slug>
description: <one line; used to judge relevance during recall>
metadata:
  type: user | feedback | project | reference
  updated: 2026-10-25
---
<the fact>. For feedback/project:
**Why:** ...
**How to apply:** ...
Related: [[other-record]]
```

**decisions/** (`NNNN-<slug>.md`) → template: `.claude/decisions/TEMPLATE.md`
**knowledge/** (`<topic>.md`) → template: `.claude/knowledge/TEMPLATE.md`
**tasks/TASKS.md** line: `- [ ] T-007 · <title> · P1 · 2026-10-25 · <note / link>`
**journal/** entry: `## HH:MM — <topic>` + Done / Decisions / Open items.

## Skills

- `/remember <what>` — save a behavior / preference / feedback
- `/decide <decision>` — write an ADR
- `/task <add|start|done|block|list> ...` — manage the task board
- `/kb <topic>` — add to / update / search the knowledge base
- `/recap` — session wrap-up: journal, tasks, missed memory records
- `/memory-audit` — audit all memory: conflicts, duplicates, stale records, broken links

## Agents and hooks

- **Subagents** live in `.claude/agents/<name>.md`. To make one, copy `.claude/agents/TEMPLATE.md.example`
  (the `.example` file itself is not loaded). When a self-contained job keeps recurring (the same review,
  research or check), propose a subagent for it. Subagents report; the main agent writes the memory layers.
- **Hooks and settings:** adding is free — a new script under `.claude/hooks/`, new entries in
  `.claude/settings.json`. **Changing or removing** an existing hook file or settings entry needs the user's
  OK: say what changes and why, then ask. `config_guard.py` enforces this for Edit/Write; follow the same rule
  for changes made through Bash.
- Register hook commands with a missing-file guard, as the existing ones do
  (`f=...; [ ! -f "$f" ] || python3 -I "$f"`): a hook whose file is missing must not block the session.

## Working style

- Reply in the language the user writes in. Files under `.claude/`, code, commits and file names are in English.
- Ask for confirmation before destructive or irreversible actions.
