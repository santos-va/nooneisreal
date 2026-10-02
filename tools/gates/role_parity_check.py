#!/usr/bin/env python3
"""Гейт ПАР — парність ролей між roles.map, roles/, .claude/skills/ і .claude/agents/.

Для кожної ролі з tools/hooks/roles.map:
  - roles/<body>.md існує;
  - .claude/skills/<claude_skill>/SKILL.md існує, це ШИМ (< 40 рядків), має
    frontmatter `name: <claude_skill>` і вказує на roles/<body>.md;
  - .claude/agents/<body>.md існує і має frontmatter `name: <body>`.
Кожен roles/*.md має бодай один аляс у мапі (сирітське тіло — порушення).

rc: 0 ok · 1 порушення · 2 не змогли виміряти (мапа відсутня/зламана).
Тільки stdlib, без мережі.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAP = ROOT / "tools" / "hooks" / "roles.map"
ROLES = ROOT / "roles"
SKILLS = ROOT / ".claude" / "skills"
AGENTS = ROOT / ".claude" / "agents"
SHIM_MAX_LINES = 40


def frontmatter_name(path: Path) -> str | None:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for line in lines[1:]:
        if line.strip() == "---":
            break
        if line.startswith("name:"):
            return line.split(":", 1)[1].strip()
    return None


def main() -> int:
    if not MAP.is_file():
        print("ВІДМОВА виміряти: tools/hooks/roles.map відсутній")
        return 2

    roles: dict[str, tuple[str, str]] = {}  # body -> (claude_skill, label)
    problems = 0
    for number, raw in enumerate(MAP.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        fields = [f.strip() for f in line.split("|")]
        if len(fields) != 6 or not all(fields):
            print(f"ВІДМОВА виміряти: roles.map:{number}: очікується 6 непорожніх полів")
            return 2
        _alias, body, claude_skill, codex_skill, kimi_skill, label = fields
        if not codex_skill.startswith("nir-") or not kimi_skill.startswith("kimi-"):
            print(f"   roles.map:{number}: префікси мають бути `nir-` (Codex) і `kimi-` (Kimi)")
            problems += 1
        prev = roles.get(body)
        if prev and prev != (claude_skill, label):
            print(f"   roles.map:{number}: тіло `{body}` мапиться на різні скіли/мітки")
            problems += 1
        roles[body] = (claude_skill, label)

    if not roles:
        print("ВІДМОВА виміряти: roles.map не містить жодної ролі")
        return 2

    for body, (skill, _label) in sorted(roles.items()):
        body_md = ROLES / f"{body}.md"
        if not body_md.is_file():
            print(f"   {body}: відсутнє тіло roles/{body}.md")
            problems += 1

        shim = SKILLS / skill / "SKILL.md"
        if not shim.is_file():
            print(f"   {body}: відсутній шим .claude/skills/{skill}/SKILL.md")
            problems += 1
        else:
            text = shim.read_text(encoding="utf-8")
            nlines = len(text.splitlines())
            if nlines >= SHIM_MAX_LINES:
                print(
                    f"   {body}: .claude/skills/{skill}/SKILL.md має {nlines} рядків "
                    f"(≥ {SHIM_MAX_LINES}) — схоже на скопійоване тіло, а не шим"
                )
                problems += 1
            if f"roles/{body}.md" not in text:
                print(f"   {body}: шим не вказує на roles/{body}.md")
                problems += 1
            if frontmatter_name(shim) != skill:
                print(f"   {body}: у шимі frontmatter `name:` ≠ `{skill}`")
                problems += 1

        agent = AGENTS / f"{body}.md"
        if not agent.is_file():
            print(f"   {body}: відсутній агент .claude/agents/{body}.md")
            problems += 1
        elif frontmatter_name(agent) != body:
            print(f"   {body}: в агенті frontmatter `name:` ≠ `{body}`")
            problems += 1

    if ROLES.is_dir():
        for body_md in sorted(ROLES.glob("*.md")):
            if body_md.stem not in roles:
                print(f"   сирітське тіло roles/{body_md.name}: жодного аляса в roles.map")
                problems += 1

    print(f"   ролей у мапі: {len(roles)} · проблем: {problems}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
