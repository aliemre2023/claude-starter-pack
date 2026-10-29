"""PreToolUse (Edit|Write|MultiEdit): Claude may add hooks and settings; changing existing ones asks the user.

  - .claude/hooks/**: creating a new file passes; changing an existing file asks.
  - .claude/settings.json, settings.local.json: purely additive changes (new keys, new list items)
    pass; changing or removing an existing value asks.
Prints a decision only when asking; otherwise the normal permission rules apply.
Changes made through Bash (sed -i, >) are not seen here; the protocol covers those.
"""
import json
import os
import sys
from pathlib import Path


def contains(old, new) -> bool:
    """True if new keeps everything in old (dict keys and values, list items) and only adds to it."""
    if isinstance(old, dict):
        return isinstance(new, dict) and all(k in new and contains(v, new[k]) for k, v in old.items())
    if isinstance(old, list):
        return isinstance(new, list) and all(any(contains(o, n) for n in new) for o in old)
    return old == new


def after_change(tool: str, inp: dict, path: Path) -> str:
    """The file's content as it would be after the tool call."""
    if tool == "Write":
        return inp.get("content", "")
    text = path.read_text(encoding="utf-8")
    for e in inp.get("edits", []) if tool == "MultiEdit" else [inp]:
        old, new = e.get("old_string", ""), e.get("new_string", "")
        text = text.replace(old, new) if e.get("replace_all") else text.replace(old, new, 1)
    return text


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return
    tool, inp = data.get("tool_name", ""), data.get("tool_input") or {}
    if not inp.get("file_path"):
        return
    path = (Path(data.get("cwd", ".")) / inp["file_path"]).resolve()
    root = (Path(os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd", ".")) / ".claude").resolve()
    if not path.exists():
        return  # a new file: adding is allowed

    if path.is_relative_to(root / "hooks"):
        reason = f"changes the existing hook file {path.name}"
    elif path.parent == root and path.name in ("settings.json", "settings.local.json"):
        try:
            old = json.loads(path.read_text(encoding="utf-8"))
            if contains(old, json.loads(after_change(tool, inp, path))):
                return
        except ValueError:
            pass
        reason = f"changes or removes existing entries in {path.name}"
    else:
        return

    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": f"Starter pack: this {reason}. Adding is free; updating needs your OK.",
    }}))


if __name__ == "__main__":
    main()
