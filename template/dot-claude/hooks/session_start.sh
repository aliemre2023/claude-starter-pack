#!/usr/bin/env bash
# SessionStart: adds a summary of the memory layers to context (stdout -> context).
# Runs on startup, resume, clear and after compact; memory/MEMORY.md is already loaded by auto-memory.
set -u
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
C="$ROOT/.claude"
TODAY=$(date +%F)
NAME=$(basename "$ROOT")

section() { printf '\n### %s\n' "$1"; }

# Prints the lines of the section starting with "## <heading>" (up to the next ## heading).
md_section() {
  awk -v h="$2" '
    /^## / { inside = (index($0, h) > 0); next }
    inside && NF { print }
  ' "$1"
}

echo "## $NAME memory summary ($TODAY)"
echo "Protocol: CLAUDE.md. Proactively keep memory, decisions, knowledge and tasks under .claude/ up to date."

if [ -f "$C/tasks/TASKS.md" ]; then
  section "Active tasks"
  out=$(md_section "$C/tasks/TASKS.md" "Active" | head -15); echo "${out:-(none)}"
  section "Blocked"
  out=$(md_section "$C/tasks/TASKS.md" "Blocked" | head -8); echo "${out:-(none)}"
  backlog=$(md_section "$C/tasks/TASKS.md" "Backlog" | grep -c '^- \[ \]')
  echo "(Backlog: $backlog tasks — full list: .claude/tasks/TASKS.md)"
fi

if [ -f "$C/decisions/INDEX.md" ]; then
  section "Recent decisions (decisions/INDEX.md)"
  out=$(grep -E '^\| *[0-9]{4}' "$C/decisions/INDEX.md" | tail -8); echo "${out:-(no decisions yet)}"
fi

if [ -f "$C/knowledge/INDEX.md" ]; then
  section "Knowledge base (knowledge/INDEX.md)"
  out=$(grep -E '^- ' "$C/knowledge/INDEX.md" | head -20); echo "${out:-(empty so far)}"
fi

journals=$(ls "$C/journal"/*.md 2>/dev/null | sort)
last=$(echo "$journals" | tail -1)
if [ -n "$last" ]; then
  section "Latest journal entry: $(basename "$last")"
  # Only the last entry: its "Open" part is the starting point for the next session.
  awk '/^## /{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' "$last" | grep -v '^$' | head -15
fi

# Audit reminder: /memory-audit leaves a "— memory audit" journal entry; nudge after 30 days without one
# (counted from the first journal day if there was never an audit).
cutoff=$(date -v-30d +%F 2>/dev/null || date -d '30 days ago' +%F 2>/dev/null)
audited=$(grep -l -- "— memory audit" $journals /dev/null 2>/dev/null | sort | tail -1)
since=$(basename "${audited:-$(echo "$journals" | head -1)}" .md)
if [ -n "$journals" ] && [ -n "$cutoff" ] && [[ "$since" < "$cutoff" ]]; then
  section "Housekeeping"
  echo "No memory audit since $since: suggest /memory-audit to the user at a natural point."
fi

lint=$(python3 -I "$C/hooks/memory_lint.py" --quiet 2>/dev/null)
if [ -n "$lint" ]; then
  section "⚠️ Memory consistency issues — fix these first"
  echo "$lint" | head -15
fi
exit 0
