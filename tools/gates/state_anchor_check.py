#!/usr/bin/env python3
"""Гейт ЯКІ — якорі шапки docs/system/state.md (план Arena-Depth-Life, Ф0.3).

Шапку state.md уже раз затерли мержем у браузері (`c3a094e`): зник розділ «▶ Хвиля 2», а рядок
«Оновлено» розрісся історією. Гейт тримає три якорі:
  - рівно один рядок `**Фаза:**`;
  - бодай один заголовок `## ▶ Хвиля`;
  - рівно один рядок `**Оновлено:**` — один запис, без «раніше», ≤ MAX_UPDATED символів
    (історія — `git log -p -- docs/system/state.md` і docs/Meetings/).

rc: 0 ok · 1 порушення · 2 не змогли виміряти (файла немає / не читається).
Тільки stdlib, без мережі. `--state <шлях>` — інший файл (для негативних контролів).
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STATE = ROOT / "docs" / "system" / "state.md"
MAX_UPDATED = 600


def check(text: str) -> list[str]:
    lines = text.splitlines()
    bad: list[str] = []
    phase = [l for l in lines if l.startswith("**Фаза:**")]
    if len(phase) != 1:
        bad.append(f"рядків `**Фаза:**` — {len(phase)} (треба 1)")
    if not any(l.startswith("## ▶ Хвиля") for l in lines):
        bad.append("немає заголовка `## ▶ Хвиля` (розділ «хто що робить зараз»)")
    upd = [l for l in lines if l.startswith("**Оновлено:**")]
    if len(upd) != 1:
        bad.append(f"рядків `**Оновлено:**` — {len(upd)} (треба 1)")
    for l in upd:
        n = len(l.rstrip())
        if n > MAX_UPDATED:
            bad.append(f"`**Оновлено:**` — {n} символів (межа {MAX_UPDATED}): лише останнє оновлення, історія — git log")
        if "раніше" in l:
            bad.append("`**Оновлено:**` містить «раніше» — історія не в шапці, а в git log і docs/Meetings/")
    return bad


def main(argv: list[str]) -> int:
    path = STATE
    if len(argv) == 2 and argv[0] == "--state":
        path = Path(argv[1])
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        print(f"   ВІДМОВА: не читається {path}: {e}")
        return 2
    bad = check(text)
    for b in bad:
        print(f"   ✗ {b}")
    if bad:
        return 1
    print(f"   ок: Фаза 1, «▶ Хвиля» є, Оновлено 1 (≤ {MAX_UPDATED}, без «раніше»)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
