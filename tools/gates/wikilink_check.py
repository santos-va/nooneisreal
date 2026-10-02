#!/usr/bin/env python3
"""Гейт ВІК — wikilinks резолвляться.

Кожен [[name]], [[name|alias]], [[name#heading]] у docs/**/*.md і roles/*.md має
відповідати файлу docs/**/<name>.md (регістрозалежно по імені). [[path/name]] резолвиться
відносно docs/. Вкладення не-md файлів ([[img.png]]) шукаються за іменем під docs/.
Лінки всередині ``` fenced ``` блоків і `inline code` ігноруються.

rc: 0 ok · 1 є зламані лінки · 2 не змогли виміряти (docs/ відсутній).
Тільки stdlib, без мережі.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
ROLES = ROOT / "roles"

LINK = re.compile(r"\[\[([^\[\]]+?)\]\]")
INLINE_CODE = re.compile(r"`[^`]*`")
FENCE = re.compile(r"^\s*(```|~~~)")


def rel(p: Path) -> str:
    return p.relative_to(ROOT).as_posix()


def main() -> int:
    if not DOCS.is_dir():
        print("ВІДМОВА виміряти: docs/ відсутній — вікі нема де перевіряти")
        return 2

    pages: dict[str, list[Path]] = {}
    for p in DOCS.rglob("*.md"):
        pages.setdefault(p.stem, []).append(p)
    rel_pages = {
        p.relative_to(DOCS).with_suffix("").as_posix() for ps in pages.values() for p in ps
    }
    other_files = {p.name for p in DOCS.rglob("*") if p.is_file() and p.suffix != ".md"}
    other_rel = {p.relative_to(DOCS).as_posix() for p in DOCS.rglob("*") if p.is_file()}

    sources = sorted(DOCS.rglob("*.md"))
    if ROLES.is_dir():
        sources += sorted(ROLES.glob("*.md"))

    broken = 0
    total = 0
    for src in sources:
        in_fence = False
        try:
            lines = src.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeDecodeError) as exc:
            print(f"{rel(src)}: не читається ({exc})")
            broken += 1
            continue
        for n, line in enumerate(lines, start=1):
            if FENCE.match(line):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            for m in LINK.finditer(INLINE_CODE.sub("", line)):
                raw = m.group(1)
                target = raw.split("|", 1)[0].split("#", 1)[0].split("^", 1)[0].strip()
                if not target:
                    continue  # [[#heading]] — та сама сторінка
                total += 1
                if target.endswith(".md"):
                    target = target[:-3]
                name = target.rsplit("/", 1)[-1]
                ok = (
                    target in pages
                    or target in rel_pages
                    or name in other_files
                    or target in other_rel
                )
                if not ok:
                    broken += 1
                    print(f"{rel(src)}:{n}: [[{raw}]] → docs/**/{target}.md не існує")

    for stem, paths in sorted(pages.items()):
        if len(paths) > 1:
            print(f"   увага: ім'я `{stem}` неоднозначне: " + ", ".join(rel(p) for p in paths))

    npages = sum(len(v) for v in pages.values())
    print(f"   сторінок: {npages} · джерел: {len(sources)} · лінків: {total} · зламаних: {broken}")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
