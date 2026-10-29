#!/usr/bin/env bash
# Registers the `claude-starter-pack` shell command: setup.sh [--remove]
# Adds a function to ~/.zshrc and ~/.bashrc (the one for $SHELL is created if missing), between
# marker lines, so running it again (e.g. after moving the pack) replaces the old block.
#   claude-starter-pack          installs the pack into the current directory
#   claude-starter-pack <dir>    installs it into <dir>
set -eu
PACK="$(cd "$(dirname "$0")" && pwd)"
BEGIN="# >>> claude-starter-pack >>>"
END="# <<< claude-starter-pack <<<"

rcs=()
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$rc" ] && rcs+=("$rc")
done
case "${SHELL:-}" in
  */zsh) [ -f "$HOME/.zshrc" ] || rcs+=("$HOME/.zshrc") ;;
  */bash) [ -f "$HOME/.bashrc" ] || rcs+=("$HOME/.bashrc") ;;
esac

for rc in "${rcs[@]}"; do
  # Drop an existing block; write back in place so a symlinked rc file stays a symlink
  if [ -f "$rc" ]; then
    kept="$(awk -v b="$BEGIN" -v e="$END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$rc")"
    printf '%s\n' "$kept" > "$rc"
  fi
  if [ "${1:-}" = "--remove" ]; then
    echo "removed from $rc"
  else
    printf '%s\nclaude-starter-pack() { bash "%s/install.sh" "$@"; }\n%s\n' "$BEGIN" "$PACK" "$END" >> "$rc"
    echo "added to $rc"
  fi
done

if [ "${1:-}" = "--remove" ]; then
  echo "claude-starter-pack command removed; open a new terminal."
else
  echo "Open a new terminal (or source your rc file), then run claude-starter-pack in any project."
fi
