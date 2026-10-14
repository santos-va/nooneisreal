#!/usr/bin/env python3
"""Гейт ЧИС — числа підсумку в docs/system/state.md проти логів фінальної батареї (клас 16 реєстру рецидивів).

Клас 16: підсумок у state.md розходився з виміряним артефактом («91 892 → 98 364» проти `CITY_TIDY_INFO triangles
district=99048` у власному лозі батареї T1; «7 іконок» проти 5 + 2). Пропозиція T4 (аудит 2026-10-09, «Реєстр
рецидивів»): кожне число підсумку береться з рядка логу фінальної батареї, гейт звіряє відомі сентинели.

Що читає: ОСТАННІЙ пункт нумерованого списку розділу `## ▶ Хвиля` у state.md — увесь, з підпунктами (аудит T4
2026-10-14 п. 8, рішення T1 «варіант А»: другий випадок класу, «91 892 → 98 364», стояв у підпункті). Відомі форми
звіряються в усьому пункті; у реченні «T1 переміряв: …» (від цих слів до кінця речення) ще й будь-яка інша цифра —
«число без звірки». Поза цим реченням інші цифри — дизайн-числа пункту (тики, метри, градуси), гейт їх не чіпає.
Розпізнає:
  `make check-playable` N/F          → `PLAYABLE CHECK: N scenarios, F failures` (check-playable.log)
  (K негативів `PASS rc=1`)          → кількість рядків `PLAYABLE <case>: PASS rc=1` (check-playable.log)
  smoke A/B                          → `[smoke] ALL OK (A checks) in B frames` (check-playable.log)
  GDS N/F                            → `перевірено: N · не парсяться: F` (кожне входження в check-playable.log і gates.log)
  реєстр R/D                         → `на диску: D · у реєстрі: R` (gates.log)
  `<case>` n/f                       → `<SENTINEL>_COMPLETE checks=n failures=f` в логу фікстури <case>.log
  `CITY_TIDY_INFO triangles k=v …`   → той самий рядок у city-tidy.log, кожен названий ключ
  трикутників [кварталу] A → B       → `CITY_TIDY_INFO triangles district=B` (city-tidy.log); A — база, не ця батарея
  трикутників [кварталу] N           → `district=N` (N з пробілами-тисячами або ≥ 4 цифри)
  `MeshInstance3D` a → b             → `mesh_instances=b` у тому самому рядку
  0 ERROR / 0 WARNING / 0 витоків    → рядки `ERROR:`/`SCRIPT ERROR:`, `WARNING:`, «leaked / still in use at exit»
                                       у логах позитивних кейсів (`PASS rc=0`)
  `make gates` зелено / gates зелено → рядок `БАТАРЕЯ ЗЕЛЕНА` у gates.log
Будь-яка інша цифра в реченні — «число без звірки»: гейт не знає, з яким логом його порівняти, тож не мовчить.

`--log-dir DIR` — тека батареї: DIR (або її батьківська тека, якщо DIR — це сам PLAYABLE_LOG_DIR) містить
check-playable.log і gates.log; логи кейсів — у DIR/playable/ або в DIR.

rc: 0 — усе звірено й збігається;
    2 — розбіжність, число, якого немає в логах, немає чого читати, або `--log-dir` не задано («НЕ ВИМІРЯНО»: R3
        конституції, клас 12 реєстру — «не зміг виміряти» блокує так само, як порушення; аудит T4 2026-10-14 п. 8).
`--state PATH` — інший state.md (для негативних контролів). `--canary` — самоперевірка: на згенерованій фікстурі
чисте зведення мусить дати rc=0, а кожна навмисна розбіжність — rc=2; інакше rc=2 (гейт мовчки пропускав би). Серед
форм — повтор інциденту `cd8f5dd` (п. 10 дослівно проти рядка `CITY_TIDY_INFO` з логу батареї T1 `t1-battery-1009`)
з контролем: той самий пункт із виправленим числом дає rc=0.
`make gates` запускає лише канарку; звірку з логами — `make summary-check PLAYABLE_LOG_DIR=…`.
Тільки stdlib, без мережі.
"""
from __future__ import annotations

import io
import re
import sys
import tempfile
from contextlib import redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STATE = ROOT / "docs" / "system" / "state.md"
WAVE = "## ▶ Хвиля"
OPENER = "T1 переміряв:"

# --- розбір state.md -------------------------------------------------------------------------------------------------

ITEM_RE = re.compile(r"^(\d+)\.\s")


def last_item(text: str) -> tuple[str | None, str]:
    """Повертає (номер, текст) останнього пункту верхнього рівня розділу «▶ Хвиля»; (None, причина), якщо немає."""
    lines = text.splitlines()
    start = next((i for i, l in enumerate(lines) if l.startswith(WAVE)), None)
    if start is None:
        return None, f"немає розділу `{WAVE}`"
    section: list[str] = []
    for line in lines[start + 1:]:
        if line.startswith("## "):
            break
        section.append(line)
    items: list[tuple[str, list[str]]] = []
    current: list[str] | None = None
    for line in section:
        m = ITEM_RE.match(line)
        if m:
            current = [line]
            items.append((m.group(1), current))
        elif current is not None and (not line.strip() or line[:1].isspace()):
            current.append(line)
        else:
            current = None  # абзац без відступу закриває пункт
    if not items:
        return None, f"у розділі `{WAVE}` немає нумерованих пунктів"
    number, body = items[-1]
    return number, "\n".join(body)


def summary_sentence(item: str) -> str | None:
    """Речення «T1 переміряв: …» без самих цих слів — до кінця речення (крапка перед великою літерою або кінець абзацу)."""
    at = item.rfind(OPENER)
    if at < 0:
        return None
    paragraph = item[at + len(OPENER):].split("\n\n", 1)[0]
    flat = " ".join(part.strip() for part in paragraph.splitlines())
    end = re.search(r"\.\s+(?=[A-ZА-ЯІЇЄҐ])", flat)
    return flat[: end.start() + 1] if end else flat


# --- розпізнавачі чисел у реченні -----------------------------------------------------------------------------------

NUM = r"\d{1,3}(?:[ \u00a0\u202f]\d{3})+|\d+"  # 99 048, 99 048 (нерозривні пробіли) або 99048

PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("playable", re.compile(r"`?make check-playable`?\s+(\d+)/(\d+)")),
    ("negatives", re.compile(r"(\d+)\s+негатив\w*\s+`?PASS rc=1`?")),
    ("smoke", re.compile(r"\bsmoke\s+(\d+)/(\d+)")),
    ("gds", re.compile(r"\bGDS\s+(\d+)/(\d+)")),
    ("registry", re.compile(r"реєстр\s+(\d+)/(\d+)")),
    ("triangles", re.compile(r"`?CITY_TIDY_INFO triangles((?:\s+[a-z_]+=\d+)+)`?")),
    ("district", re.compile(r"трикутник\w*(?:\s+кварталу)?\s+(?:" + NUM + r")\s*→\s*(" + NUM + r")")),
    ("district", re.compile(r"трикутник\w*(?:\s+кварталу)?\s+(\d{1,3}(?:[ \u00a0\u202f]\d{3})+|\d{4,})(?![\d/])")),
    ("meshes", re.compile(r"`MeshInstance3D`\s+(?:\d+)\s*→\s*(\d+)")),
    ("clean", re.compile(r"\b(\d+)\s+(ERROR|WARNING|витік\w*|витоків|витоку)")),
    ("gates", re.compile(r"(?:`make gates`|\bgates)\s+зелен\w*")),
    ("fixture", re.compile(r"`([a-z0-9][a-z0-9_-]*)`\s+(\d+)/(\d+)")),
]


def flat(text: str) -> str:
    """Рядки пункту в один рядок (як summary_sentence склеює абзац): число, розірване переносом, лишається числом."""
    return " ".join(part.strip() for part in text.splitlines())


def claims(sentence: str) -> tuple[list[tuple[str, tuple[str, ...]]], list[str]]:
    """Розпізнані твердження і залишок — фрагменти з цифрами, які гейт не вміє звірити."""
    found: list[tuple[int, str, tuple[str, ...]]] = []
    masked = sentence
    for kind, pattern in PATTERNS:
        for m in pattern.finditer(masked):
            found.append((m.start(), kind, m.groups()))
        masked = pattern.sub(lambda m: " " * len(m.group(0)), masked)
    found.sort()
    leftovers = []
    for m in re.finditer(r"\S*\d\S*", masked):
        leftovers.append(sentence[max(0, m.start() - 20): m.end() + 20].strip())
    return [(kind, groups) for _, kind, groups in found], leftovers


# --- логи батареї ----------------------------------------------------------------------------------------------------

CASE_RE = re.compile(r"^PLAYABLE (\S+): (PASS|FAIL) rc=(-?\d+) log=(.*)$", re.M)
SENTINEL_RE = re.compile(r"^[A-Z0-9_]+_COMPLETE checks=(\d+) failures=(\d+)", re.M)
ERROR_RE = re.compile(r"^\s*(?:SCRIPT ERROR|ERROR):", re.M)
WARNING_RE = re.compile(r"^\s*WARNING:", re.M)
LEAK_RE = re.compile(r"leaked at exit|still in use at exit", re.I)


class Battery:
    def __init__(self, log_dir: Path) -> None:
        self.dir = log_dir
        roots = [log_dir, log_dir.parent]
        self.root = next((r for r in roots if (r / "check-playable.log").is_file()), None)
        self.playable = self._read(self.root / "check-playable.log") if self.root else None
        gates_root = next((r for r in roots if (r / "gates.log").is_file()), None)
        self.gates = self._read(gates_root / "gates.log") if gates_root else None
        self.cases: dict[str, tuple[str, int]] = {}
        if self.playable:
            for m in CASE_RE.finditer(self.playable):
                self.cases[m.group(1)] = (m.group(2), int(m.group(3)))

    @staticmethod
    def _read(path: Path) -> str | None:
        try:
            return path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            return None

    def case_log(self, name: str) -> str | None:
        bases = [self.dir / "playable", self.dir]
        if self.root is not None:
            bases += [self.root / "playable", self.root]
        for base in bases:
            path = base / f"{name}.log"
            if path.is_file():
                return self._read(path)
        return None


def verify(kind: str, groups: tuple[str, ...], bat: Battery) -> list[str]:
    """Порожній список — твердження збігається з логом; інакше перелік розбіжностей / відсутніх джерел."""
    need_playable = kind in ("playable", "negatives", "smoke", "clean", "fixture", "triangles", "district", "meshes")
    if need_playable and bat.playable is None:
        return [f"{kind}: немає check-playable.log у {bat.dir} (ні в батьківській теці)"]
    if kind == "playable":
        found = re.findall(r"^PLAYABLE CHECK: (\d+) scenarios, (\d+) failures", bat.playable, re.M)
        if not found:
            return ["`make check-playable`: у check-playable.log немає рядка `PLAYABLE CHECK: N scenarios, F failures`"]
        if found[-1] != groups:
            return [f"`make check-playable` {groups[0]}/{groups[1]} ≠ лог `PLAYABLE CHECK: {found[-1][0]} scenarios, {found[-1][1]} failures`"]
        return []
    if kind == "negatives":
        count = len(re.findall(r"^PLAYABLE \S+: PASS rc=1 ", bat.playable, re.M))
        return [] if count == int(groups[0]) else [f"{groups[0]} негативів `PASS rc=1` ≠ у check-playable.log {count}"]
    if kind == "smoke":
        found = re.findall(r"^\[smoke\] ALL OK \((\d+) checks\) in (\d+) frames", bat.playable, re.M)
        if not found:
            return ["smoke: у check-playable.log немає рядка `[smoke] ALL OK (A checks) in B frames`"]
        bad = [f"{a}/{b}" for a, b in found if (a, b) != groups]
        return [f"smoke {groups[0]}/{groups[1]} ≠ лог {', '.join(bad)}"] if bad else []
    if kind == "gds":
        texts = [t for t in (bat.playable, bat.gates) if t]
        found = [f for t in texts for f in re.findall(r"перевірено: (\d+) · не парсяться: (\d+)", t)]
        if not found:
            return ["GDS: ні в check-playable.log, ні в gates.log немає рядка `перевірено: N · не парсяться: F`"]
        bad = [f"{a}/{b}" for a, b in found if (a, b) != groups]
        return [f"GDS {groups[0]}/{groups[1]} ≠ лог {', '.join(bad)}"] if bad else []
    if kind == "registry":
        if bat.gates is None:
            return [f"реєстр: немає gates.log у {bat.dir} (ні в батьківській теці)"]
        found = re.findall(r"на диску: (\d+) · у реєстрі: (\d+)", bat.gates)
        if not found:
            return ["реєстр: у gates.log немає рядка `на диску: D · у реєстрі: R`"]
        disk, registered = found[-1]
        return [] if (registered, disk) == groups else [f"реєстр {groups[0]}/{groups[1]} ≠ gates.log у реєстрі {registered} / на диску {disk}"]
    if kind == "gates":
        if bat.gates is None:
            return [f"«gates зелено»: немає gates.log у {bat.dir} (ні в батьківській теці)"]
        lines = [l.strip() for l in bat.gates.splitlines()]
        if "БАТАРЕЯ ЗЕЛЕНА" in lines and not any(l.startswith("БАТАРЕЯ ЧЕРВОНА") for l in lines):
            return []
        return ["«gates зелено» ≠ gates.log без рядка `БАТАРЕЯ ЗЕЛЕНА` (або з `БАТАРЕЯ ЧЕРВОНА`)"]
    if kind == "fixture":
        name, n, f = groups
        log = bat.case_log(name)
        if log is None:
            return [f"`{name}` {n}/{f}: немає логу фікстури {name}.log"]
        found = SENTINEL_RE.findall(log)
        if not found:
            return [f"`{name}` {n}/{f}: у {name}.log немає рядка `…_COMPLETE checks=N failures=F`"]
        return [] if found[-1] == (n, f) else [f"`{name}` {n}/{f} ≠ {name}.log checks={found[-1][0]} failures={found[-1][1]}"]
    if kind == "triangles":
        log = bat.case_log("city-tidy")
        if log is None:
            return ["`CITY_TIDY_INFO triangles`: немає логу city-tidy.log"]
        found = re.findall(r"^CITY_TIDY_INFO triangles((?:\s+[a-z_]+=\d+)+)", log, re.M)
        if not found:
            return ["`CITY_TIDY_INFO triangles`: у city-tidy.log немає такого рядка"]
        logged = dict(re.findall(r"([a-z_]+)=(\d+)", found[-1]))
        out = []
        for key, value in re.findall(r"([a-z_]+)=(\d+)", groups[0]):
            if logged.get(key) != value:
                out.append(f"`CITY_TIDY_INFO triangles {key}={value}` ≠ city-tidy.log {key}={logged.get(key, 'немає')}")
        return out
    if kind in ("district", "meshes"):
        key = "district" if kind == "district" else "mesh_instances"
        value = re.sub(r"\D", "", groups[0])
        log = bat.case_log("city-tidy")
        if log is None:
            return [f"{describe(kind, groups)}: немає логу city-tidy.log"]
        found = re.findall(r"^CITY_TIDY_INFO triangles((?:\s+[a-z_]+=\d+)+)", log, re.M)
        if not found:
            return [f"{describe(kind, groups)}: у city-tidy.log немає рядка `CITY_TIDY_INFO triangles`"]
        logged = dict(re.findall(r"([a-z_]+)=(\d+)", found[-1]))
        return [] if logged.get(key) == value else [f"{describe(kind, groups)} ≠ city-tidy.log {key}={logged.get(key, 'немає')}"]
    if kind == "clean":
        number, what = int(groups[0]), groups[1]
        pattern = ERROR_RE if what == "ERROR" else WARNING_RE if what == "WARNING" else LEAK_RE
        positives = [name for name, (verdict, rc) in bat.cases.items() if verdict == "PASS" and rc == 0]
        if not positives:
            return [f"{number} {what}: у check-playable.log немає жодного позитивного кейсу `PASS rc=0`"]
        missing = [name for name in positives if bat.case_log(name) is None]
        if missing:
            return [f"{number} {what}: немає логів {len(missing)} позитивних кейсів ({', '.join(missing[:5])}…)"]
        total = sum(len(pattern.findall(bat.case_log(name) or "")) for name in positives)
        return [] if total == number else [f"{number} {what} у позитивних логах ≠ {total} рядків у {len(positives)} логах"]
    return [f"невідомий вид твердження {kind}"]


def describe(kind: str, groups: tuple[str, ...]) -> str:
    """Звірене твердження так, як його написано в підсумку (для рядка «ок»)."""
    if kind == "playable":
        return f"check-playable {groups[0]}/{groups[1]}"
    if kind == "negatives":
        return f"{groups[0]} негативів PASS rc=1"
    if kind in ("smoke", "gds"):
        return f"{'smoke' if kind == 'smoke' else 'GDS'} {groups[0]}/{groups[1]}"
    if kind == "registry":
        return f"реєстр {groups[0]}/{groups[1]}"
    if kind == "triangles":
        return f"CITY_TIDY_INFO triangles {groups[0].strip()}"
    if kind == "clean":
        return f"{groups[0]} {groups[1]}"
    if kind == "gates":
        return "gates зелено"
    if kind == "district":
        return f"трикутників {groups[0]} (district)"
    if kind == "meshes":
        return f"`MeshInstance3D` → {groups[0]} (mesh_instances)"
    return f"`{groups[0]}` {groups[1]}/{groups[2]}"


def check(state_text: str, log_dir: Path) -> tuple[list[str], list[str]]:
    """(проблеми, звірені твердження) для state.md проти теки батареї."""
    number, item = last_item(state_text)
    if number is None:
        return [item], []
    sentence = summary_sentence(item)
    if sentence is None:
        return [f"останній пункт «▶ Хвиля» (п. {number}) не має речення «{OPENER} …»"], []
    found, leftovers = claims(sentence)
    problems = [f"п. {number}: число без звірки — «…{piece}…»" for piece in leftovers]
    if not found:
        problems.append(f"п. {number}: у реченні «{OPENER}» немає жодного числа, яке гейт уміє звірити")
    # Решта пункту (підпункти, інші абзаци): лише відомі форми; інші цифри там — дизайн-числа, не числа батареї.
    whole = flat(item)
    at = whole.find(sentence)
    rest = whole[:at] + " " * len(sentence) + whole[at + len(sentence):] if at >= 0 else whole
    rest_found, _ = claims(rest)
    found += rest_found
    bat = Battery(log_dir)
    verified = []
    for kind, groups in found:
        issues = verify(kind, groups, bat)
        problems += [f"п. {number}: {issue}" for issue in issues]
        if not issues:
            verified.append(describe(kind, groups))
    return problems, verified


def run(argv: list[str]) -> int:
    if argv == ["--canary"]:
        return canary()
    state = STATE
    log_dir: Path | None = None
    args = list(argv)
    while args:
        flag = args.pop(0)
        if flag in ("--state", "--log-dir") and args:
            value = Path(args.pop(0))
            if flag == "--state":
                state = value
            else:
                log_dir = value
            continue
        print(f"   ВІДМОВА: невідомий аргумент `{flag}` (відомі: --state PATH, --log-dir DIR, --canary)")
        return 2
    if log_dir is None:
        print("   НЕ ВИМІРЯНО: немає логів батареї (--log-dir); числа state.md не перевірено — це блокує (rc=2, R3)."
              " Звірка: make summary-check PLAYABLE_LOG_DIR=/тека/батареї")
        return 2
    try:
        text = state.read_text(encoding="utf-8")
    except OSError as e:
        print(f"   ВІДМОВА: не читається {state}: {e}")
        return 2
    if not log_dir.is_dir():
        print(f"   ВІДМОВА: немає теки логів {log_dir}")
        return 2
    problems, verified = check(text, log_dir)
    for p in problems:
        print(f"   ✗ {p}")
    if problems:
        print(f"   ЧИСЛА НЕ ЗБІГАЮТЬСЯ або не мають джерела: {len(problems)}; звірено {len(verified)}")
        return 2
    print(f"   ок: звірено {len(verified)} чисел останнього пункту «▶ Хвиля» з логами {log_dir}: {'; '.join(verified)}")
    return 0


# --- канарка -----------------------------------------------------------------------------------------------------------

FIXTURE_STATE = """# state

## ▶ Хвиля — фікстура канарки

1. **Старий пункт.** T1 переміряв: `make check-playable` 999/0.
2. **Пункт канарки.**
   - щось змінено.

   Фізика та сама: `identical=8`. T1 переміряв: `make check-playable` 5/0 (2 негативи `PASS rc=1`), smoke 165/19847, GDS 144/0, 0 ERROR / 0 WARNING / 0 витоків у позитивних логах, реєстр 185/185, `make gates` зелено; `alpha` 12/0, трикутників `CITY_TIDY_INFO triangles district=108024 mesh_instances=264` (лог батареї).

   Відкрите: кадри.

Після цього — приймання.

## Ще не завершено
"""

FIXTURE_LOGS = {
    "check-playable.log": (
        "   перевірено: 144 · не парсяться: 0 · не виміряно: 0 · канарка: FAIL як треба\n"
        "[smoke] ALL OK (165 checks) in 19847 frames\nSMOKE ЗЕЛЕНИЙ\n"
        "PLAYABLE alpha: PASS rc=0 log=/elsewhere/alpha.log\n"
        "PLAYABLE city-tidy: PASS rc=0 log=/elsewhere/city-tidy.log\n"
        "PLAYABLE beta: PASS rc=0 log=/elsewhere/beta.log\n"
        "PLAYABLE alpha-negative-x: PASS rc=1 log=/elsewhere/alpha-negative-x.log\n"
        "PLAYABLE beta-negative-y: PASS rc=1 log=/elsewhere/beta-negative-y.log\n"
        "PLAYABLE CHECK: 5 scenarios, 0 failures\n"
    ),
    "gates.log": (
        "   на диску: 185 · у реєстрі: 185 · незареєстрованих: 0 · неіснуючих: 0\n"
        "   перевірено: 144 · не парсяться: 0 · не виміряно: 0 · канарка: FAIL як треба\n"
        "БАТАРЕЯ ЗЕЛЕНА\n"
    ),
    "playable/alpha.log": "ALPHA_INFO 3\nALPHA_COMPLETE checks=12 failures=0 mutation=none\n",
    "playable/city-tidy.log": "CITY_TIDY_INFO triangles district=108024 mesh_instances=264 {\"A\":1}\nCITY_TIDY_COMPLETE checks=9 failures=0 mutation=none\n",
    "playable/beta.log": "BETA_COMPLETE checks=4 failures=0\n",
    "playable/alpha-negative-x.log": "ERROR: ALPHA: x\nALPHA_COMPLETE checks=12 failures=1 mutation=x\n",
    "playable/beta-negative-y.log": "ERROR: BETA: y\nBETA_COMPLETE checks=4 failures=1\n",
}

# Кожна форма — одна навмисна розбіжність між підсумком і логами (або підсумок, якого не звірити). Кожна → rc=2.
CANARY_FORMS: list[tuple[str, str, str, str]] = [
    # (назва, файл, що замінити, на що)
    ("сценаріїв у підсумку 6, у лозі 5", "state.md", "`make check-playable` 5/0", "`make check-playable` 6/0"),
    ("негативів 3, у лозі 2", "state.md", "(2 негативи", "(3 негативи"),
    ("smoke: кадрів у лозі інше", "check-playable.log", "in 19847 frames", "in 19848 frames"),
    ("GDS у gates.log інше, ніж у check-playable.log", "gates.log", "перевірено: 144", "перевірено: 143"),
    ("реєстр у gates.log 184", "gates.log", "у реєстрі: 185", "у реєстрі: 184"),
    ("фікстура: checks у лозі 13", "playable/alpha.log", "checks=12 failures=0", "checks=13 failures=0"),
    ("фікстура без логу", "state.md", "`alpha` 12/0", "`gamma` 12/0"),
    ("трикутники: district у лозі інше", "playable/city-tidy.log", "district=108024", "district=99048"),
    ("WARNING у позитивному лозі при «0 WARNING»", "playable/beta.log", "BETA_COMPLETE", "WARNING: ObjectDB instances leaked at exit\nBETA_COMPLETE"),
    ("gates.log червоний при «gates зелено»", "gates.log", "БАТАРЕЯ ЗЕЛЕНА", "БАТАРЕЯ ЧЕРВОНА: 1 порушень, 0 відмов виміряти"),
    ("число, якого гейт не вміє звірити", "state.md", "(лог батареї).", "(лог батареї), 18 тиків."),
    ("останній пункт без речення «T1 переміряв»", "state.md", "T1 переміряв: `make check-playable` 5/0", "T1 мовчить: `make check-playable` 5/0"),
    ("немає check-playable.log", "check-playable.log", None, None),
]


# Повтор інциденту класу 16 (аудит T4 2026-10-14 п. 8, рішення T1): п. 10 з `git show cd8f5dd:docs/system/state.md`
# дослівно, проти логів батареї T1 `t1-battery-1009` у тій частині, яку цей пункт називає (282/0, 180 негативів, smoke
# 165/19847, GDS 143/0, реєстр 183/183, gates зелено; рядок city-tidy.log `CITY_TIDY_INFO triangles district=99048
# mesh_instances=259`). Підсумок писав «трикутників 91 892 → 98 364» у підпункті, лог мав 99048. Гейт мусить дати rc=2 саме
# через трикутники, а той самий пункт із числом логу — rc=0 (контроль: rc=2 не від фікстури).
INCIDENT_CD8F5DD_ITEM = """10. **Трос тягне, стрибок однією дугою, «Хміль» без вигоди, порядок у місті — у гілці PR #190** ([[2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum]], [[2026-10-09-City-Tidy-And-Modern-Props]], [[ADR-027-City-Modern-Props-Style-And-Path]]):
   - трос V4: після зачепу в місті мотузка сама тягне 8 м/с до довжини гойдання (ступні на 0,5 м над вищою з двох опор), Space — ще 1,2 м. З місця: зсув 0,05 → 8,80 м, у повітрі 0 → 126 зі 127 тиків. Власний стовп якоря мотузку не рве. Дуель без змін;
   - стрибок С2: одне групування, змішування в повітрі 0,15–0,18 с, посадки 0,15 / 0,08 / 0,06 (варіант B, рішення T1). Найбільший поворот кістки в повітрі 11,4° (HEAD 25,3°);
   - «Хміль» і «Заплутаність» A: понад швидкість ходи — повне гальмування. Серія ривків без стіка +27,3 % → +4,5 %. Гард на наслідок, негативи U1–U4;
   - дрібне з аудитів: важіль і ковш колонки, teardown меню без ERROR, одна підказка на клавішу, заборона гліфів, зібраних у рантаймі;
   - місто, фаза 0: 207 дефектів на базі → 0 (`city_tidy_check`); бочки трьох видів, 4 перешкоди для перескоку, труби й випуски пари, урни; трикутників 91 892 → 98 364.

   T1 переміряв: `make check-playable` 282/0 (180 негативів `PASS rc=1`), smoke 165/19847, GDS 143/0, у позитивних логах 0 ERROR / 0 WARNING / 0 витоків, `make gates` зелено, реєстр 183/183, код незмінний за прогін (`cmp`).

   Відкрите:
   - паромобіль і легковик під брезентом з Blender (0 кр.) готові окремо, ще не в місті — [[ADR-027-City-Modern-Props-Style-And-Path]];
   - 3 концепт-аркуші — генерацію блокує фільтр дозволів сесії;
   - аудит T4 цієї хвилі, кадри й слова довідок T6/T8, рушій множить альбедо вдруге (T6);
   - тент `ShopAwning` біля якоря (−24; 6,8; 10,6) рве мотузку на першому тику."""
INCIDENT_WRONG = "трикутників 91 892 → 98 364"
INCIDENT_FIXED = "трикутників 91 892 → 99 048"


def _incident_files() -> dict[str, str]:
    """Фікстура повтору: state.md з п. 10 `cd8f5dd` і логи `t1-battery-1009` у тій частині, яку він називає."""
    positives = [f"case-{index:03d}" for index in range(1, 102)] + ["city-tidy"]
    negatives = [f"case-negative-{index:03d}" for index in range(1, 181)]
    lines = ["   перевірено: 143 · не парсяться: 0 · не виміряно: 0 · канарка: FAIL як треба",
             "[smoke] ALL OK (165 checks) in 19847 frames", "SMOKE ЗЕЛЕНИЙ"]
    lines += [f"PLAYABLE {name}: PASS rc=0 log=/elsewhere/{name}.log" for name in positives]
    lines += [f"PLAYABLE {name}: PASS rc=1 log=/elsewhere/{name}.log" for name in negatives]
    lines.append(f"PLAYABLE CHECK: {len(positives) + len(negatives)} scenarios, 0 failures")
    files = {
        "state.md": "# state\n\n## ▶ Хвиля — повтор інциденту cd8f5dd\n\n" + INCIDENT_CD8F5DD_ITEM + "\n\n## Ще не завершено\n",
        "check-playable.log": "\n".join(lines) + "\n",
        "gates.log": ("   на диску: 183 · у реєстрі: 183 · незареєстрованих: 0 · неіснуючих: 0\n"
                      "   перевірено: 143 · не парсяться: 0 · не виміряно: 0 · канарка: FAIL як треба\nБАТАРЕЯ ЗЕЛЕНА\n"),
    }
    for name in positives:
        files[f"playable/{name}.log"] = "CASE_COMPLETE checks=1 failures=0 mutation=none\n"
    files["playable/city-tidy.log"] = ("CITY_TIDY_INFO triangles district=99048 mesh_instances=259 {\"CityInteriors\":19920}\n"
                                       "CITY_TIDY_COMPLETE checks=1 failures=0 mutation=none\n")
    for name in negatives:
        files[f"playable/{name}.log"] = "ERROR: CASE: x\nCASE_COMPLETE checks=1 failures=1 mutation=x\n"
    return files


def _materialise(base: Path, files: dict[str, str]) -> None:
    for rel, body in files.items():
        path = base / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")


def _gate(base: Path) -> tuple[int, str]:
    """The same entry point and rc as `make summary-check`, on a fixture; the printed lines are kept, not shown."""
    out = io.StringIO()
    with redirect_stdout(out):
        rc = run(["--state", str(base / "state.md"), "--log-dir", str(base)])
    return rc, out.getvalue()


def canary() -> int:
    files = {"state.md": FIXTURE_STATE, **FIXTURE_LOGS}
    failures: list[str] = []
    with tempfile.TemporaryDirectory(prefix="nir-summary-canary-") as tmp:
        clean = Path(tmp) / "clean"
        _materialise(clean, files)
        rc, text = _gate(clean)
        count = re.search(r"ок: звірено (\d+) чисел", text)
        verified = int(count.group(1)) if count else 0
        if rc != 0 or verified < 11:
            failures.append(f"чиста фікстура мала дати rc=0 і 11 звірених чисел, а дала rc={rc}, {verified}: {text.strip()[:300]}")
        for index, (name, target, old, new) in enumerate(CANARY_FORMS):
            case = Path(tmp) / f"form{index}"
            mutated = dict(files)
            if old is None:
                mutated.pop(target)
            else:
                if old not in mutated[target]:
                    failures.append(f"форма «{name}»: у {target} немає «{old}» — канарка застаріла")
                    continue
                mutated[target] = mutated[target].replace(old, new, 1)
            _materialise(case, mutated)
            rc, text = _gate(case)
            if rc != 2:
                failures.append(f"форма «{name}» дала rc={rc}, а не 2: {text.strip()[:200]}")
        # Без --log-dir — «не виміряно», rc=2 (клас 12, R3), а не «зелено».
        out = io.StringIO()
        with redirect_stdout(out):
            rc = run(["--state", str(clean / "state.md")])
        if rc != 2:
            failures.append(f"без --log-dir гейт мав дати rc=2 («НЕ ВИМІРЯНО»), а дав rc={rc}: {out.getvalue().strip()[:200]}")
        # Повтор інциденту cd8f5dd п. 10 і його контроль (див. INCIDENT_CD8F5DD_ITEM).
        incident = _incident_files()
        if INCIDENT_WRONG not in incident["state.md"]:
            failures.append(f"повтор cd8f5dd: у пункті немає «{INCIDENT_WRONG}» — канарка застаріла")
        else:
            replay = Path(tmp) / "incident-cd8f5dd"
            _materialise(replay, incident)
            rc, text = _gate(replay)
            if rc != 2 or "district=99048" not in text or "98 364" not in text:
                failures.append(f"повтор інциденту cd8f5dd п. 10 мав дати rc=2 через «98 364» ≠ district=99048, а дав rc={rc}: {text.strip()[:300]}")
            control = Path(tmp) / "incident-cd8f5dd-fixed"
            fixed = dict(incident)
            fixed["state.md"] = fixed["state.md"].replace(INCIDENT_WRONG, INCIDENT_FIXED, 1)
            _materialise(control, fixed)
            rc, text = _gate(control)
            if rc != 0 or "99 048 (district)" not in text:
                failures.append(f"контроль повтору cd8f5dd (число логу 99 048) мав дати rc=0 і звірити трикутники, а дав rc={rc}: {text.strip()[:300]}")
    if failures:
        for f in failures:
            print(f"   ✗ канарка: {f}")
        print("   ВІДМОВА виміряти: гейт підсумкових чисел не розрізняє збіг і розбіжність (rc=2)")
        return 2
    print(f"   канарка: чиста фікстура — 0 розбіжностей; {len(CANARY_FORMS)} форм розбіжності — кожна rc=2, як треба;"
          " без --log-dir — rc=2; повтор інциденту cd8f5dd п. 10 — rc=2 (98 364 ≠ district=99048), з числом логу — rc=0."
          " Звірка справжньої батареї: make summary-check PLAYABLE_LOG_DIR=…")
    return 0


def main(argv: list[str]) -> int:
    return run(argv)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
