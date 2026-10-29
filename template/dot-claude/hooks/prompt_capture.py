"""UserPromptSubmit: reminds Claude to save durable information when the user's message signals it.

stdout is added to context. Prints nothing when there is no signal (keeps context clean).
Only explicit phrases count; /recap catches the rest at the end of a session.
Patterns are English plus Turkish; add your own language's phrases to each list.
"""
import json
import re
import sys

# Blocks the IDE/harness wraps around the user's text (<ide_opened_file>, <browser_instruction>,
# <system-reminder>…). Their wording ("ALWAYS", "Never", "task") would otherwise match every prompt.
INJECTED = re.compile(r"<([a-z][\w-]*)\b[^>]*>.*?</\1>", re.S)

# "her zaman / asla" are everyday words in Turkish; they only count before an instruction
# (imperative, optionally negated / polite plural: kullan, kullanma, kullanın, eklemeyin).
TR_IMPERATIVE = r"\b(kullan|yap|yaz|sor|ekle|koy|ver|sil|cevapla|yanıtla)(ma|me)?(y?[ıiuü]n)?\b"

SIGNALS = {
    "memory (feedback/user)": [
        r"from now on", r"remember (this|that)", r"keep in mind", r"\bi prefer\b",
        r"\balways (use|do|write|reply|ask)\b", r"\bnever (use|do|write|reply|ask)\b",
        r"don'?t ever", r"stop (doing|using)",
        # tr
        r"bundan (sonra|böyle)", r"\bhatırla(yın)?\b", r"\bunutma(yın)?\b", r"aklında (tut|olsun)",
        r"\b(her zaman|asla|hiçbir zaman)\b[^.?!\n]{0,40}" + TR_IMPERATIVE,
        r"tercih(im|ediyorum)", r"böyle yapma",
    ],
    "decisions (ADR)": [
        r"we decided", r"let'?s go with", r"\bdecision:",
        # tr
        r"karar (verdik|verdim|aldık)", r"(onu|bunu|şunu) seçtik", r"(onunla|bununla|şununla) gidelim",
    ],
    "tasks (TASKS.md)": [
        r"\btodo\b", r"to the backlog", r"look at it later",
        # tr
        r"sonra bak(arız|alım)", r"backlog'?a", r"(listeye|panoya) ekle", r"yapılacaklar",
    ],
    "knowledge": [
        r"take a note", r"document (this|that|it)\b",
        # tr
        r"\bnot al\b", r"dokümante et",
    ],
}


def main() -> None:
    try:
        prompt = json.load(sys.stdin).get("prompt", "")
    except (json.JSONDecodeError, ValueError):
        return
    text = INJECTED.sub(" ", prompt).lower()
    hits = [layer for layer, pats in SIGNALS.items() if any(re.search(p, text) for p in pats)]
    if not hits:
        return
    print(
        "[memory signal] This message may contain durable information → possible layer: "
        + ", ".join(hits)
        + ". If it really is durable, save it per the CLAUDE.md protocol (search for an existing record "
        "first, then update/add) and report it in one line. If it's transient, ignore this."
    )


if __name__ == "__main__":
    main()
