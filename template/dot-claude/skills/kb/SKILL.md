---
name: kb
description: Builds and maintains the project knowledge base (.claude/knowledge/) — adds domain knowledge, architecture, glossary, how-tos and research findings, updates existing pages, or searches the knowledge base. Use when durable information is learned, after research, or when the user says "take a note / document this".
argument-hint: <topic> | search <query>
---

# /kb

Input: $ARGUMENTS

**Search (`search <query>`)** — `grep -ril` inside `.claude/knowledge/`; summarize the relevant part of matching pages and show the source file. If nothing is found, say so; don't make things up.

**Add / update**
1. Read `INDEX.md`; if the topic belongs to an existing page, update that page (don't open a new one). If a page grows past 300 lines, split it into subtopics.
2. New page: `<kebab-topic>.md` from `TEMPLATE.md`. Summary at the top, details below.
3. Put the source of the information in `sources` (URL, file path, "user YYYY-MM-DD"). If unverified, set `confidence: low` and add it to "Open questions".
4. If it conflicts with older information: fix the old content and refresh `updated`; if this is a change of decision, write an ADR with `/decide`.
5. Add/update `- [Title](file.md) — one-line summary` in `INDEX.md`; keep it under category headings.
6. Link related ADR/memory records with `[[...]]`. Run `python3 .claude/hooks/memory_lint.py`.
7. One line: `📝 knowledge: <topic> → knowledge/<file>`.

I build the knowledge base myself: when I meet a new subsystem, concept or external dependency in the project, I open a page even if the user didn't ask.
