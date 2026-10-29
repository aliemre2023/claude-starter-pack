"""Checks the structural consistency of the memory layers.

Checks:
  - memory/: missing frontmatter (name, description, metadata.type), valid type,
    duplicate names, files missing from MEMORY.md / listed in MEMORY.md but not on disk
  - decisions/: files in sync with INDEX.md, valid status, superseded ADRs name a successor
  - knowledge/: files in sync with INDEX.md
  - broken [[links]] in all layers (matching no memory name / file stem)
  - tasks/TASKS.md: duplicate T-IDs

Usage: python3 .claude/hooks/memory_lint.py [--quiet]
--quiet: prints nothing when there are no issues (for SessionStart).
Exit code: 1 if there are issues.
"""
import re
import sys
from pathlib import Path

C = Path(__file__).resolve().parent.parent
MEMORY_TYPES = {"user", "feedback", "project", "reference"}
ADR_STATUSES = {"proposed", "accepted", "superseded", "deprecated"}
SKIP = {"MEMORY.md", "INDEX.md", "TEMPLATE.md", "README.md"}


def frontmatter(path: Path) -> dict:
    """Minimal YAML frontmatter reader: top-level keys and one nested level (metadata.*)."""
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}
    data, parent = {}, None
    for line in m.group(1).splitlines():
        if not line.strip():
            continue
        key, _, val = line.strip().partition(":")
        val = val.strip().strip("'\"")
        if line.startswith((" ", "\t")) and parent:
            data[f"{parent}.{key}"] = val
        else:
            data[key] = val
            parent = key if not val else None
    return data


def index_targets(index: Path) -> set[str]:
    """Target file names of the markdown links in an INDEX/MEMORY file."""
    if not index.exists():
        return set()
    # Example links inside code blocks, inline code and HTML comments don't count
    text = re.sub(r"```.*?```|`[^`\n]*`|<!--.*?-->", "", index.read_text(encoding="utf-8"), flags=re.S)
    return {Path(t).name for t in re.findall(r"\]\(([^)#]+\.md)\)", text)}


def layer_files(d: Path) -> list[Path]:
    return sorted(p for p in d.glob("*.md") if p.name not in SKIP) if d.exists() else []


def main() -> int:
    quiet = "--quiet" in sys.argv
    issues: list[str] = []
    rel = lambda p: str(p.relative_to(C.parent))  # noqa: E731

    # memory/
    mem_dir = C / "memory"
    names: dict[str, Path] = {}
    for p in layer_files(mem_dir):
        fm = frontmatter(p)
        for key in ("name", "description", "metadata.type"):
            if not fm.get(key):
                issues.append(f"{rel(p)}: missing frontmatter '{key}'")
        t = fm.get("metadata.type")
        if t and t not in MEMORY_TYPES:
            issues.append(f"{rel(p)}: invalid type '{t}'")
        n = fm.get("name")
        if n:
            if n in names:
                issues.append(f"{rel(p)}: duplicate name '{n}' (also in {rel(names[n])})")
            names[n] = p

    # Index sync
    for d, index in ((mem_dir, mem_dir / "MEMORY.md"),
                     (C / "decisions", C / "decisions" / "INDEX.md"),
                     (C / "knowledge", C / "knowledge" / "INDEX.md")):
        on_disk = {p.name for p in layer_files(d)}
        listed = index_targets(index)
        for f in sorted(on_disk - listed):
            issues.append(f"{rel(d / f)}: not listed in {index.name}")
        for f in sorted(listed - on_disk):
            issues.append(f"{rel(index)}: '{f}' is listed but the file doesn't exist")

    # decisions/
    adr_ids = set()
    for p in layer_files(C / "decisions"):
        fm = frontmatter(p)
        adr_ids.add(p.name[:4])
        s = fm.get("status")
        if s not in ADR_STATUSES:
            issues.append(f"{rel(p)}: invalid status '{s}' ({'/'.join(sorted(ADR_STATUSES))})")
        if s == "superseded" and not fm.get("superseded_by"):
            issues.append(f"{rel(p)}: superseded but 'superseded_by' is empty")

    # Broken [[links]]: must be a memory name, a file stem in any layer, or an ADR number
    stems = {p.stem for d in ("memory", "decisions", "knowledge") for p in layer_files(C / d)}
    valid = set(names) | stems | adr_ids
    for d in ("memory", "decisions", "knowledge"):
        for p in layer_files(C / d):
            for link in re.findall(r"\[\[([^\]|]+)", p.read_text(encoding="utf-8")):
                if link.strip() not in valid:
                    issues.append(f"{rel(p)}: broken link [[{link.strip()}]]")

    # tasks/
    tasks = C / "tasks" / "TASKS.md"
    if tasks.exists():
        ids = re.findall(r"^- \[[ x>!]\] (T-\d+)", tasks.read_text(encoding="utf-8"), re.M)
        for tid in sorted({i for i in ids if ids.count(i) > 1}):
            issues.append(f"{rel(tasks)}: {tid} appears more than once")

    if issues:
        print("\n".join(f"- {i}" for i in issues))
        return 1
    if not quiet:
        print("✓ memory is consistent")
    return 0


if __name__ == "__main__":
    sys.exit(main())
