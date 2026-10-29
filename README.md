# claude-starter-pack

An agent setup in which Claude keeps its own memory, decisions, knowledge base, tasks and journal
inside each project, under `.claude/`. Protocol: [template/PROTOCOL.md](template/PROTOCOL.md).

The pack is written in English; the agent replies in whatever language the user writes in.

## Quick start

Register the `claude-starter-pack` command once:

```bash
bash <path-to>/claude-starter-pack/setup.sh
```

Then, in a new terminal, from any project:

```bash
claude-starter-pack             # installs into the current directory
claude-starter-pack <dir>       # installs into <dir>
claude-starter-pack --private   # also git-ignores .claude/memory/ and .claude/journal/
```

If the pack is already installed there, it says so and never overwrites your work: only pack files
you haven't changed (hooks, skills, templates, the protocol) are brought up to date, and any you did
change are kept and listed. Otherwise it installs it. Use `--private` (or
`CLAUDE_STARTER_PACK_PRIVATE=1`) in team or public repos, so personal notes stay on your machine. `setup.sh` adds a marked block to `~/.zshrc` / `~/.bashrc`; run it
again after moving the pack, or `bash setup.sh --remove` to take the command away.

## Layout

| Pack | Installed as | |
|---|---|---|
| `template/PROTOCOL.md` | `CLAUDE.md` (or `.claude/PROTOCOL.md` + `@import`) | the protocol |
| `template/dot-claude/` | `.claude/` | layers, skills, agent template, hooks, `settings.json` |
| `setup.sh` | — | registers the `claude-starter-pack` command |
| `install.sh` | — | installs into a project |
| `auto_bootstrap.sh` | — | optional global `SessionStart` hook |

The template folders are deliberately not named `CLAUDE.md` / `.claude/`, so working on the pack
itself doesn't load the protocol, skills and hooks, and nothing a session writes ends up in new installs.

## Automatic install

Add `auto_bootstrap.sh` as a global `SessionStart` hook in `~/.claude/settings.json`.
List the folders where your own projects live in `CLAUDE_STARTER_PACK_ROOTS` (colon-separated):

```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "*", "hooks": [{ "type": "command", "command": "CLAUDE_STARTER_PACK_ROOTS=\"$HOME/projects:$HOME/work\" bash \"<path-to>/claude-starter-pack/auto_bootstrap.sh\"", "timeout": 20 }] }
    ]
  }
}
```

When a project without `.claude/memory/MEMORY.md` is opened:
- **inside a root** → the pack is installed and the protocol is printed into that session's context;
- **any other git repo** → nothing is changed; Claude offers the install once
  (remembered in `~/.local/state/claude-starter-pack/offered`);
- **anything else** → nothing happens.

Never touched: `/`, `$HOME`, direct children of `$HOME` (Desktop, Documents…), `~/.claude`,
this pack and its parent folder, `/tmp`, `/private`, `/var`.
If the install fails, the error is shown in the session instead of being swallowed.

Disable for one project: `touch .claude/.no-starter-pack` · for a whole session: `CLAUDE_STARTER_PACK=off`.

## Manual install

```bash
bash <path-to>/claude-starter-pack/install.sh [project_dir]   # default: current directory
```

Never overwrites existing files. If the project already has a `CLAUDE.md`, the protocol goes to
`.claude/PROTOCOL.md` and `@.claude/PROTOCOL.md` is appended to `CLAUDE.md`;
an existing `.claude/settings.json` gets the hooks and permissions merged in, and the pack's own
hook entries from an older install are replaced with the current ones.

**After cloning a project on another machine**, run `install.sh` on it again:
`autoMemoryDirectory` is an absolute path in the git-ignored `settings.local.json`, and the
re-run rewrites it (nothing else is overwritten).

## Template notes

- `{{DATE}}` is replaced with the install date.
- Only the skeleton is copied: `settings.local.json`, journal entries and memory records other
  than `MEMORY.md` in `template/dot-claude/` are skipped even if they exist.
- `prompt_capture.py` matches English and Turkish phrases; add patterns for other languages there.
- Hook commands skip a missing script instead of failing: a `UserPromptSubmit` hook that exits with code 2
  (what `python3` does for a missing file) blocks every prompt.
- `config_guard.py` (`PreToolUse`) lets Claude add hook scripts and settings entries but asks the user
  before an existing hook file or settings value is changed or removed. Bash edits bypass it.
- `agents/TEMPLATE.md.example` is a subagent skeleton; the `.example` suffix keeps it from loading.
- Re-running `install.sh` updates the pack's hook entries in `settings.json` and every pack file
  (hooks, skills, agent/ADR/knowledge templates, the protocol) the project hasn't changed, using the
  hashes in `.claude/.starter-pack.json` (commit it). Layer contents are never touched.
- `session_start.sh` keeps context small: active/blocked tasks, the last few ADRs, the knowledge index,
  only the latest journal entry, lint issues, and a `/memory-audit` nudge after 30 days without one.
