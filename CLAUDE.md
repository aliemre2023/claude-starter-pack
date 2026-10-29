# claude-starter-pack — working on the pack

This repo is the **source** of the starter pack, not a project that uses it.

- `template/PROTOCOL.md` and `template/dot-claude/` are the product that `install.sh` copies into
  projects (as `CLAUDE.md` and `.claude/`). Their instructions are for installed projects, not for
  this repo: don't write memory, ADRs, tasks or journal entries into `template/`.
- Don't rename them back to `CLAUDE.md` / `.claude/`: Claude Code would then load the protocol,
  skills and hooks while working on the pack.
- Test changes by installing into a throwaway directory (`bash install.sh <tmp_dir>`), then run
  its hooks there (`session_start.sh`, `memory_lint.py`, `prompt_capture.py` with a JSON prompt on stdin).
- Files, code and commits are in English; reply in the user's language.
