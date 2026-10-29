#!/usr/bin/env bash
# PreCompact: leaves a marker in today's journal before compaction, so the
# SessionStart summary after compaction shows where context was compacted.
set -u
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
J="$ROOT/.claude/journal/$(date +%F).md"
[ -f "$J" ] || printf '# %s\n' "$(date +%F)" > "$J"
printf '\n<!-- %s: context compacted; details before this point were summarized. Fill gaps with /recap. -->\n' "$(date +%H:%M)" >> "$J"
exit 0
