#!/usr/bin/env python3
"""Гейт СТЕ — список негативів без родини і UNFAMILIED_CEILING не ростуть проти origin/main (клас 18 реєстру).

Клас 18: негатив зараховувався за будь-яку причину. Правило раннера `tools/gates/playable_check.sh` відмовляє негативу
без конкретної родини (`red=`), якщо його немає в `tools/gates/playable_unfamilied_negatives.txt`, а список тримає рівно
`UNFAMILIED_CEILING` рядків. Обхід, якого раннер не бачить (аудит T4 2026-10-15, канарка «grow»): додати рядок у список
і підняти стелю в одному діфі. Що список ріс, видно лише в історії, тому цей гейт звіряє робоче дерево з базою:

  база — `git merge-base HEAD origin/main`;
    є список у базі          → рядки й стеля бази (звичайний стан, коли правило вже в main);
    немає, але є в коміті гілки (між базою і HEAD) → рядки й стеля найранішого такого коміту;
    немає ніде в історії     → негативи без `red=` у раннері HEAD (рядок «ім'я|скрипт|аргументи»), стеля — їхнє число:
                               заморожений список може взяти лише те, що вже було без родини в останньому коміті.
  дерево — кожен рядок списку є в базі (те саме ім'я, той самий скрипт і аргументи; рядок бази без прив'язки — лише
           ім'я), без дублів, `UNFAMILIED_CEILING` не більша, ніж у базі, і дорівнює числу рядків; список і стеля
           на місці. (Рядків більше, ніж у базі, без нових імен — лише з дублем.)

rc: 0 — не росте;
    2 — ВІДМОВА (список або стеля виросли, рядок перев'язано, список чи стелю прибрано) або НЕ ВИМІРЯНО: немає git,
        немає `origin/main`, немає merge-base (неглибока історія: у CI — `actions/checkout` з `fetch-depth: 0`),
        не читається блоб. «Не зміг виміряти» блокує так само (R3, клас 12).
Перед звіркою щоразу — вбудована канарка: на синтетичних парах «база → дерево» ріст, перев'язка, підміна, ріст стелі й
зниклий список мусять дати відмову, а рівність і скорочення — ні; інакше rc 2.
Тільки stdlib і git, без мережі. Журнал — docs/Fix/2026-10-15-Runner-Rule-Bypass-Fix.md.
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIST = "tools/gates/playable_unfamilied_negatives.txt"
RUNNER = "tools/gates/playable_check.sh"
BASE = "origin/main"
CEILING_RE = re.compile(r"^UNFAMILIED_CEILING = (\d+)$", re.MULTILINE)


class NotMeasured(Exception):
    pass


def entries_of(text: str) -> list[tuple[str, str | None]]:
    """Рядки списку: (ім'я, «скрипт|аргументи»); None — рядок без прив'язки (старий формат «лише ім'я»)."""
    entries = []
    for line in text.splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            name, _, binding = line.partition("|")
            entries.append((name, binding or None))
    return entries


def ceiling_of(runner_text: str | None) -> int | None:
    found = CEILING_RE.findall(runner_text or "")
    return int(found[0]) if len(found) == 1 else None


def compare(ref: list[tuple[str, str | None]], ref_ceiling: int, tree: list[tuple[str, str | None]] | None,
            tree_ceiling: int | None) -> list[str]:
    """Відмови дерева проти бази; порожньо — не росте."""
    if tree is None:
        return [f"{LIST} прибрано, хоча база його тримає"]
    problems = []
    if tree_ceiling is None:
        problems.append(f"у {RUNNER} немає рівно одного рядка «UNFAMILIED_CEILING = N»")
    elif tree_ceiling > ref_ceiling:
        problems.append(f"UNFAMILIED_CEILING {ref_ceiling} → {tree_ceiling}: стеля лише знижується")
    bound = dict(ref)
    new = sorted({name for name, _binding in tree if name not in bound})
    if new:
        problems.append(f"рядків, яких база не тримає ({len(new)}): {', '.join(new[:12])}"
                        + (" …" if len(new) > 12 else "") + " — новий негатив називає родину (red=), а не стає в список")
    rebound = sorted({f"{name}: {bound[name]} → {binding}" for name, binding in tree
                      if name in bound and bound[name] is not None and binding != bound[name]})
    if rebound:
        problems.append(f"рядок перев'язано на інший кейс ({len(rebound)}): {'; '.join(rebound[:6])}"
                        + (" …" if len(rebound) > 6 else ""))
    names = [name for name, _binding in tree]
    if tree_ceiling is not None and tree_ceiling != len(names):
        problems.append(f"UNFAMILIED_CEILING {tree_ceiling}, а рядків у списку {len(names)}: стеля — це число рядків")
    if len(names) != len(set(names)):
        problems.append(f"у списку {len(names)} рядків, різних імен {len(set(names))}: дубль")
    return problems  # більше рядків, ніж у базі, без нових імен буває лише з дублем — його ловить рядок вище


def canary() -> list[str]:
    """Синтетичні пари база → дерево: (форма, дерево, стеля дерева, чи має бути відмова)."""
    ref = [(f"n{k}-negative-x", f"tools/x/n{k}.gd|-- --break=x") for k in range(4)]
    new = ("new-negative-x", "tools/x/new.gd|-- --break=x")
    forms = [
        ("same", list(ref), 4, False),
        ("shrink", ref[1:], 3, False),
        ("grow", ref + [new], 5, True),
        ("grow_list_only", ref + [new], 4, True),
        ("ceiling_only", list(ref), 5, True),
        ("swap", ref[1:] + [new], 4, True),
        ("rebind", [(ref[0][0], "tools/x/other.gd|-- --break=x")] + ref[1:], 4, True),
        ("duplicate", ref[1:] + [ref[1]], 4, True),
        ("gone", None, 4, True),
        ("ceiling_gone", list(ref), None, True),
    ]
    broken = []
    forms.append(("ceiling_below_lines", list(ref), 3, True))
    for form, tree, tree_ceiling, refuse in forms:
        if bool(compare(ref, 4, tree, tree_ceiling)) != refuse:
            broken.append(f"{form}: {'не відмовила' if refuse else 'відмовила'}")
    if not compare(ref, 3, list(ref), 4):  # база з рядками понад стелю: дерево не піднімає стелю до числа рядків
        broken.append("ceiling_up_to_lines: не відмовила")
    if compare([(ref[0][0], None)], 1, [(ref[0][0], "tools/x/any.gd|")], 1):  # рядок бази без прив'язки — лише ім'я
        broken.append("unbound_ref: відмовила")
    return broken


def git(*args: str) -> str:
    try:
        result = subprocess.run(["git", *args], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    except OSError as exc:
        raise NotMeasured(f"git недоступний ({exc})")
    if result.returncode != 0:
        raise NotMeasured(f"`git {' '.join(args)}` → rc {result.returncode}: {result.stderr.strip()[:200]}")
    return result.stdout


def blob(rev: str, path: str) -> str | None:
    """Вміст шляху в коміті; None — шляху там немає."""
    if subprocess.run(["git", "cat-file", "-e", f"{rev}:{path}"], cwd=ROOT,
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
        return None
    return git("show", f"{rev}:{path}")


def ceiling_or_count(runner_text: str | None, entries: list) -> int:
    ceiling = ceiling_of(runner_text)
    return len(entries) if ceiling is None else ceiling


def unfamilied_at(rev: str) -> list[tuple[str, str | None]]:
    """Негативи без «red=» у раннері коміту rev — частина `cases` його heredoc, виконана дослівно."""
    text = blob(rev, RUNNER)
    if text is None:
        raise NotMeasured(f"у {rev[:7]} немає {RUNNER}")
    try:
        body = text.split("python3 - <<'PY'\n", 1)[1].rsplit("\nPY", 1)[0]
        start = re.search(r"^cases = ", body, re.MULTILINE).start()
        end = body.index("@contextmanager\ndef isolated_profile():")
        scope: dict = {"re": re, "os": os, "Path": Path}
        exec(compile(body[start:end], f"{RUNNER}@{rev[:7]}", "exec"), scope)
        cases = scope["cases"]
    except Exception as exc:  # розклад раннера змінився — не вгадуємо
        raise NotMeasured(f"не вдалося прочитати `cases` раннера {rev[:7]} ({type(exc).__name__}: {exc})")
    return [(name, f"{script}|{' '.join(args)}") for name, script, sentinel, args, rc in cases
            if rc == 1 and re.search(r"\bred=", sentinel) is None]


def reference() -> tuple[str, list[tuple[str, str | None]], int]:
    git("rev-parse", "--is-inside-work-tree")
    try:
        git("rev-parse", "--verify", "--quiet", f"{BASE}^{{commit}}")
    except NotMeasured:
        raise NotMeasured(f"немає {BASE} (у CI — actions/checkout з fetch-depth: 0; локально — git fetch origin main)")
    try:
        base = git("merge-base", "HEAD", BASE).strip()
    except NotMeasured:
        raise NotMeasured(f"немає спільного предка HEAD і {BASE}: неглибока історія (fetch-depth: 0 / git fetch --unshallow)")
    text = blob(base, LIST)
    if text is not None:
        runner = blob(base, RUNNER)
        entries = entries_of(text)
        return f"{BASE} {base[:7]} (merge-base, список у main)", entries, ceiling_or_count(runner, entries)
    added = git("log", "--reverse", "--diff-filter=A", "--format=%H", f"{base}..HEAD", "--", LIST).split()
    if added:
        intro = added[0]
        entries = entries_of(blob(intro, LIST) or "")
        return (f"{BASE} {base[:7]} (merge-base) без списку → коміт гілки {intro[:7]}, що його додав",
                entries, ceiling_or_count(blob(intro, RUNNER), entries))
    head = git("rev-parse", "HEAD").strip()
    entries = unfamilied_at(head)
    return (f"{BASE} {base[:7]} (merge-base) без списку, у комітах гілки теж → негативи без red= у раннері HEAD "
            f"{head[:7]}", entries, len(entries))


def main(argv: list[str]) -> int:
    if argv:
        print(f"   ВІДМОВА: невідомі аргументи {argv}")
        return 2
    broken = canary()
    if broken:
        print("   КАНАРКА ЗЛАМАНА — гейт мовчки пропускав би ріст: " + "; ".join(broken))
        return 2
    try:
        label, ref, ref_ceiling = reference()
    except NotMeasured as exc:
        print(f"   НЕ ВИМІРЯНО: {exc}")
        return 2
    list_path = ROOT / LIST
    tree = entries_of(list_path.read_text()) if list_path.is_file() else None
    runner_path = ROOT / RUNNER
    tree_ceiling = ceiling_of(runner_path.read_text() if runner_path.is_file() else None)
    print(f"   база: {label}: {len(ref)} рядків, стеля {ref_ceiling}")
    print(f"   дерево: {'—' if tree is None else len(tree)} рядків, UNFAMILIED_CEILING {tree_ceiling}")
    problems = compare(ref, ref_ceiling, tree, tree_ceiling)
    if problems:
        for problem in problems:
            print(f"   ВІДМОВА: {problem}")
        return 2
    print("   список і стеля не ростуть; канарка: ріст, перев'язка, підміна, стеля, зниклий список — відмова")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
