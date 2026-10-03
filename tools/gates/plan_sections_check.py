#!/usr/bin/env python3
"""Гейт ПЛА — кожен новий план у docs/Plans/ має розділ `## Аудит і погляди` (R8, ADR-019, Ф0.3).

Плани, написані до R8, перелічені в LEGACY поіменно: їх не переписуємо. Новий план поза LEGACY
без розділу — порушення. Шаблон (Plan-Template.md) розділ має і теж перевіряється.

rc: 0 ok · 1 порушення · 2 не змогли виміряти (немає docs/Plans/).
Тільки stdlib, без мережі. `--plans <тека>` — інша тека (для негативних контролів).
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PLANS = ROOT / "docs" / "Plans"
SECTION = "## Аудит і погляди"

# Плани до R8 (2026-10-03). Новий план сюди НЕ дописується — він пише розділ.
LEGACY = {
    "2026-10-02-Prototype-0.1.md",
    "2026-10-03-Behaviour-Cloth-VFX-Shaders.md",
    "2026-10-03-Character-Select.md",
    "2026-10-03-Choko-Outfit-v5.md",
    "2026-10-03-Crystal-Ult-Arena-Fatigue.md",
    "2026-10-03-Fight-Craft-Research.md",
    "2026-10-03-Generation-Waves.md",
    "2026-10-03-Living-Combat.md",
    "2026-10-03-Main-Menu-Skyline.md",
    "2026-10-03-Online-Play.md",
    "2026-10-03-Path-to-First-Fight.md",
    "2026-10-03-Picks-to-Game-and-Animation.md",
    "2026-10-03-Production-Plan.md",
    "2026-10-03-Prototype-0.3-Free-Movement.md",
    "2026-10-03-Santos-Packs-Arenas.md",
    "2026-10-03-Skea-Redesign.md",
    "2026-10-03-Skea-Ult-Bass.md",
    "2026-10-03-Sprint-Arenas-VFX.md",
    "2026-10-03-Wave-2-Kickoff.md",
}


def main(argv: list[str]) -> int:
    plans = PLANS
    if len(argv) == 2 and argv[0] == "--plans":
        plans = Path(argv[1])
    if not plans.is_dir():
        print(f"   ВІДМОВА: немає теки {plans}")
        return 2
    checked = 0
    bad: list[str] = []
    for p in sorted(plans.glob("*.md")):
        if p.name in LEGACY:
            continue
        checked += 1
        try:
            lines = p.read_text(encoding="utf-8").splitlines()
        except OSError as e:
            print(f"   ВІДМОВА: не читається {p}: {e}")
            return 2
        if not any(l.strip() == SECTION for l in lines):
            bad.append(p.name)
    for b in bad:
        print(f"   ✗ {b}: немає `{SECTION}` (R8, docs/Plans/Plan-Template.md)")
    if bad:
        return 1
    print(f"   ок: {checked} планів поза LEGACY мають `{SECTION}`; LEGACY {len(LEGACY)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
