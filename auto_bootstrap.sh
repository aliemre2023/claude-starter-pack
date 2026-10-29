#!/usr/bin/env bash
# Global SessionStart hook (~/.claude/settings.json) for projects without the starter pack.
#   - Inside one of the roots in CLAUDE_STARTER_PACK_ROOTS (colon-separated): installs it with
#     install.sh and prints the protocol into context for the first session.
#   - Elsewhere, only in git repos: asks Claude to offer the install to the user, once per
#     project (remembered in $STATE). Nothing in the project is changed.
# To disable: a .claude/.no-starter-pack file in the project, or CLAUDE_STARTER_PACK=off.
set -u
PACK="$(cd "$(dirname "$0")" && pwd)"
DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
DIR="$(cd "$DIR" 2>/dev/null && pwd)" || exit 0
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/claude-starter-pack/offered"

[ "${CLAUDE_STARTER_PACK:-on}" = "off" ] && exit 0
[ -f "$DIR/.claude/.no-starter-pack" ] && exit 0
[ -f "$DIR/.claude/memory/MEMORY.md" ] && exit 0   # already installed

# Non-project directories: root, home, direct children of home, the pack itself, temp dirs
case "$DIR" in
  /|"$HOME"|"$HOME"/.claude*|"$PACK"|"$PACK"/*|"$(dirname "$PACK")"|/tmp*|/private/*|/var/*) exit 0 ;;
esac
[ "$(dirname "$DIR")" = "$HOME" ] && exit 0

in_roots() {
  local IFS=: root
  for root in ${CLAUDE_STARTER_PACK_ROOTS:-}; do
    root="$(cd "${root/#\~/$HOME}" 2>/dev/null && pwd)" || continue
    case "$DIR/" in "$root"/*) return 0 ;; esac
  done
  return 1
}

if ! in_roots; then
  [ -e "$DIR/.git" ] || exit 0
  grep -qxF "$DIR" "$STATE" 2>/dev/null && exit 0
  mkdir -p "$(dirname "$STATE")" && echo "$DIR" >> "$STATE"
  echo "## claude-starter-pack is not installed in this project"
  echo "Once, at a natural point (not in the middle of the user's task), ask the user whether to install it"
  echo "(project-local memory, ADRs, knowledge base, task board and journal under .claude/)."
  echo "- Yes: bash \"$PACK/install.sh\" \"$DIR\" (never overwrites files; takes effect next session)"
  echo "- No: touch \"$DIR/.claude/.no-starter-pack\" (create .claude/ if needed)"
  echo "This is offered only once for this project."
  exit 0
fi

if ! out=$(bash "$PACK/install.sh" "$DIR" 2>&1); then
  echo "## claude-starter-pack install failed in $DIR"
  echo "Tell the user briefly; output:"
  echo "$out" | tail -10
  exit 0
fi

echo "## Starter pack was just installed in this project ($DIR)"
echo "Follow the protocol below from this session on (CLAUDE.md was not loaded in this session yet)."
echo "Memory goes under .claude/memory/ in this session too; don't write global memory for this project."
echo
if grep -qE "Agent Working Protocol|Ajan Çalışma Protokolü" "$DIR/CLAUDE.md" 2>/dev/null && [ ! -f "$DIR/.claude/PROTOCOL.md" ]; then
  cat "$DIR/CLAUDE.md"
else
  cat "$DIR/.claude/PROTOCOL.md"
fi
exit 0
