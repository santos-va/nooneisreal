#!/usr/bin/env python3
"""Гейт РЕЄ — кожен ассет зареєстрований, кожен зареєстрований ассет існує.

Диск: усі файли під game/assets/ з розширенням png/webp/jpg/jpeg/svg/ogg/wav/mp3/glb/gltf.
Реєстр: docs/Art/Textures-Registry.md; шлях у ньому приймається у формах
`game/assets/...`, `res://assets/...` або `assets/...` (нормалізується до `assets/...`).

rc: 0 ok · 1 є незареєстровані або неіснуючі · 2 не змогли виміряти
(є ассети, а реєстру немає). game/assets/ відсутній → 0 з приміткою.
Тільки stdlib, без мережі.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / "game"
ASSETS = GAME / "assets"
REGISTRY = ROOT / "docs" / "Art" / "Textures-Registry.md"
EXTS = ("png", "webp", "jpg", "jpeg", "svg", "ogg", "wav", "mp3", "glb", "gltf")
PATH_RE = re.compile(
    r"(?:res://|game/)?assets/[A-Za-z0-9_./\-]+?\.(?:" + "|".join(EXTS) + r")\b"
)


def normalize(s: str) -> str:
    if s.startswith("res://"):
        s = s[len("res://"):]
    if s.startswith("game/"):
        s = s[len("game/"):]
    return s


def main() -> int:
    if not ASSETS.is_dir():
        print("   game/assets/ відсутній — нічого реєструвати")
        return 0

    on_disk = {
        p.relative_to(GAME).as_posix(): p
        for p in ASSETS.rglob("*")
        if p.is_file() and p.suffix.lower().lstrip(".") in EXTS
    }

    if not REGISTRY.is_file():
        if not on_disk:
            print("   ассетів на диску немає, реєстру ще немає — нічого реєструвати")
            return 0
        print(
            f"ВІДМОВА виміряти: на диску {len(on_disk)} ассетів, "
            f"а {REGISTRY.relative_to(ROOT).as_posix()} відсутній"
        )
        for path in sorted(on_disk):
            print(f"   не зареєстровано: game/{path}")
        return 2

    try:
        text = REGISTRY.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        print(f"ВІДМОВА виміряти: реєстр не читається ({exc})")
        return 2

    listed = {normalize(m.group(0)) for m in PATH_RE.finditer(text)}
    unregistered = sorted(set(on_disk) - listed)
    missing = sorted(listed - set(on_disk))

    for path in unregistered:
        print(f"   не зареєстровано: game/{path} → додай рядок у docs/Art/Textures-Registry.md")
    for path in missing:
        print(f"   у реєстрі, але не на диску: game/{path}")

    print(
        f"   на диску: {len(on_disk)} · у реєстрі: {len(listed)} · "
        f"незареєстрованих: {len(unregistered)} · неіснуючих: {len(missing)}"
    )
    return 1 if (unregistered or missing) else 0


if __name__ == "__main__":
    sys.exit(main())
