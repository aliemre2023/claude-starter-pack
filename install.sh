#!/usr/bin/env bash
# Installs the starter pack into a project: install.sh [--private] [project_dir] (default: current directory)
# Never overwrites the project's own work; safe to run again.
#   - template/dot-claude/ is copied to .claude/ where missing ({{DATE}} -> today)
#   - pack files (hooks, skills, agent/ADR/knowledge templates, the protocol) are updated on a re-run
#     only if the project hasn't changed them since install (hashes in .claude/.starter-pack.json);
#     changed ones are kept and listed. Layer contents (memory, ADRs, tasks, indexes) are never touched.
#   - if there is no CLAUDE.md, template/PROTOCOL.md is written as CLAUDE.md; otherwise it
#     goes to .claude/PROTOCOL.md and an @import line is appended to the existing CLAUDE.md
#   - an existing .claude/settings.json gets the hooks and permissions merged in; the pack's own
#     hook entries (matched by script path) are replaced, so fixes reach older installs
#   - autoMemoryDirectory (absolute path) is written to .claude/settings.local.json
#   - --private (or CLAUDE_STARTER_PACK_PRIVATE=1): memory/ and journal/ are git-ignored
# Re-run after cloning a project on another machine: it fixes autoMemoryDirectory.
set -eu
PACK="$(cd "$(dirname "$0")" && pwd)"
PRIVATE="${CLAUDE_STARTER_PACK_PRIVATE:-0}"
DIR=.
for arg in "$@"; do
  case "$arg" in
    --private) PRIVATE=1 ;;
    -*) echo "usage: install.sh [--private] [project_dir]" >&2; exit 1 ;;
    *) DIR="$arg" ;;
  esac
done
TARGET="$(cd "$DIR" && pwd)"
TODAY=$(date +%F)
case "$TARGET/" in
  "$PACK"/*) echo "the starter pack cannot be installed into itself" >&2; exit 1 ;;
esac
case "$TARGET" in
  /|"$HOME") echo "not a project directory: $TARGET" >&2; exit 1 ;;
esac

python3 -I - "$PACK/template" "$TARGET" "$TODAY" "$PRIVATE" <<'EOF'
import hashlib, json, re, sys
from pathlib import Path

tpl, target, today, private = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3], sys.argv[4] == "1"
src_root = tpl / "dot-claude"
already = (target / ".claude/memory/MEMORY.md").exists()
manifest_path = target / ".claude/.starter-pack.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
hashes = manifest.get("files", {})
created, updated, kept = [], [], []


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def is_template_file(rel: Path) -> bool:
    """Only the pack's skeleton is copied; anything a session produced in the template is not."""
    if rel.name == ".DS_Store" or "__pycache__" in rel.parts:
        return False
    if rel.name in ("settings.json", "settings.local.json") and len(rel.parts) == 1:
        return False  # settings.json is merged below; settings.local.json is machine-specific
    if rel.parts[0] == "journal":
        return rel.name == ".gitkeep"
    if rel.parts[0] == "memory":
        return rel.name == "MEMORY.md"
    return True


def is_managed(rel: Path) -> bool:
    """Pack code and templates, as opposed to layer contents the project fills in."""
    return rel.parts[0] in ("hooks", "skills", "agents") or rel.name == "TEMPLATE.md"


def place(dst: Path, data: bytes, managed: bool, mode=None) -> None:
    """Creates dst; replaces it only if managed and unchanged since the pack last wrote it."""
    key = dst.relative_to(target).as_posix()
    new = sha(data)
    if dst.exists():
        cur = sha(dst.read_bytes())
        if cur == new:
            hashes[key] = new
            return
        if not managed:
            return
        if hashes.get(key) != cur:
            kept.append(key)  # changed in the project (or installed before hashes were kept)
            return
        updated.append(key)
    else:
        created.append(key)
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(data)
    if mode is not None:
        dst.chmod(mode)
    hashes[key] = new


# 1. template/dot-claude/ -> .claude/
for src in sorted(src_root.rglob("*")):
    rel = src.relative_to(src_root)
    if src.is_dir() or not is_template_file(rel):
        continue
    data = src.read_bytes()
    if src.suffix in {".md", ".sh", ".py"}:
        data = data.decode("utf-8").replace("{{DATE}}", today).encode("utf-8")
    place(target / ".claude" / rel, data, is_managed(rel), src.stat().st_mode)

# 2. CLAUDE.md
protocol = (tpl / "PROTOCOL.md").read_bytes()
claude_md, protocol_md = target / "CLAUDE.md", target / ".claude/PROTOCOL.md"
is_protocol = claude_md.exists() and any(
    m in claude_md.read_text(encoding="utf-8") for m in ("Agent Working Protocol", "Ajan Çalışma Protokolü"))
if not claude_md.exists() or (is_protocol and not protocol_md.exists()):
    place(claude_md, protocol, managed=True)
else:
    place(protocol_md, protocol, managed=True)
    if "@.claude/PROTOCOL.md" not in claude_md.read_text(encoding="utf-8"):
        with claude_md.open("a", encoding="utf-8") as f:
            f.write("\n\n<!-- claude-starter-pack -->\n@.claude/PROTOCOL.md\n")

# 3. settings.json: merge permissions and hooks
pack_settings = json.loads((src_root / "settings.json").read_text(encoding="utf-8"))
sp = target / ".claude/settings.json"
settings = json.loads(sp.read_text(encoding="utf-8")) if sp.exists() else {}
settings.setdefault("$schema", pack_settings["$schema"])
allow = settings.setdefault("permissions", {}).setdefault("allow", [])
allow += [p for p in pack_settings["permissions"]["allow"] if p not in allow]
hooks = settings.setdefault("hooks", {})


def script(cmd) -> str:
    m = re.search(r"\.claude/hooks/[\w.-]+", cmd or "")
    return m.group(0) if m else str(cmd)


for event, entries in pack_settings["hooks"].items():
    current = hooks.setdefault(event, [])
    for e in entries:
        mine = {script(h["command"]) for h in e["hooks"]}
        for c in current:
            c["hooks"] = [h for h in c.get("hooks", []) if script(h.get("command")) not in mine]
        current[:] = [c for c in current if c["hooks"]]
        current.append(e)
sp.write_text(json.dumps(settings, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

# 4. settings.local.json: auto-memory inside the project. The directory is always set to this
#    project's path, so a stale value (another machine, a copied file) is corrected.
lp = target / ".claude/settings.local.json"
local = json.loads(lp.read_text(encoding="utf-8")) if lp.exists() else {}
local.setdefault("autoMemoryEnabled", True)
local["autoMemoryDirectory"] = str(target / ".claude/memory")
local.setdefault("autoDreamEnabled", True)
lp.write_text(json.dumps(local, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

# 5. .gitignore
gi = target / ".gitignore"
lines = gi.read_text(encoding="utf-8").splitlines() if gi.exists() else []
wanted = [".claude/settings.local.json", "__pycache__/", ".DS_Store"]
if private:
    wanted += [".claude/memory/", ".claude/journal/"]
missing = [l for l in wanted if l not in lines]
if missing:
    with gi.open("a", encoding="utf-8") as f:
        if lines and lines[-1].strip():
            f.write("\n")
        f.write("\n".join(missing) + "\n")

# 6. Install journal entry
if not already:
    j = target / f".claude/journal/{today}.md"
    if not j.exists():
        j.write_text(f"# {today}\n", encoding="utf-8")
    with j.open("a", encoding="utf-8") as f:
        f.write(
            "\n## Starter pack installed\n**Done**\n- Installed the claude-starter-pack structure "
            f"({len(created)} files).\n**Decisions**\n- [[0001-project-local-agent-memory]]\n"
            "**Open**\n- T-001: write the project's purpose to knowledge/overview.md.\n"
            "- autoMemoryDirectory takes effect from the next session.\n"
        )

manifest_path.write_text(json.dumps({"files": dict(sorted(hashes.items()))}, indent=2) + "\n", encoding="utf-8")

if not already:
    print(f"starter pack -> {target}: {len(created)} new files")
else:
    print(f"starter pack is already installed in {target}; your files were not overwritten")
    if updated:
        print(f"  updated {len(updated)} pack files you hadn't changed: " + ", ".join(updated))
    if created:
        print(f"  added {len(created)} missing files: " + ", ".join(created))
    if kept:
        print(f"  kept your version (differs from the pack): " + ", ".join(kept))
EOF
