#!/usr/bin/env bash
# Нагад про рольову поставу. Аргументи: $1 — текст промпту, $2 — client (claude|codex|kimi).
# rc: 0 нічого · 10 є текст у stdout (знайдено роль або видима помилка мапи).
# Спрощене ядро: bash + python3 stdlib, без git-root валідації. Fail-open, але голосно.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 0
MAP="$ROOT/tools/hooks/roles.map"
[[ -n "${1:-}" ]] || exit 0
command -v python3 >/dev/null 2>&1 || {
  echo '<role-posture-error>python3 відсутній — рольову поставу не виміряно; roles.map читай руками</role-posture-error>'
  exit 10
}

ROOT="$ROOT" MAP="$MAP" PROMPT="$1" CLIENT="${2:-claude}" python3 - <<'PY'
import os
import re
import sys
from pathlib import Path

GREET = {
    "привіт", "прив", "вітаю", "хай", "ку", "йо", "хей", "слухай", "слух", "о", "оо",
    "добрий", "доброго", "день", "дня", "ранок", "ранку", "вечір", "вечора",
    "hi", "hello", "hey", "yo", "ok", "ок", "окей", "так",
}
ROOT = Path(os.environ["ROOT"])
client = os.environ.get("CLIENT", "claude")
if client not in {"claude", "codex", "kimi"}:
    client = "claude"


def loud(message: str) -> None:
    print("<role-posture-error>")
    print(f"roles.map: {message}")
    print("Поставу не виміряно — візьми її руками за tools/hooks/roles.map.")
    print("</role-posture-error>")
    raise SystemExit(10)


try:
    lines = Path(os.environ["MAP"]).read_text(encoding="utf-8").splitlines()
except OSError as exc:
    loud(f"не читається: {exc}")

table = {}
for number, raw in enumerate(lines, start=1):
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    fields = tuple(f.strip() for f in line.split("|"))
    if len(fields) != 6 or not all(fields):
        loud(f"рядок {number}: очікується 6 непорожніх полів")
    alias = fields[0].lower()
    if alias in table:
        loud(f"рядок {number}: дубль alias `{alias}`")
    table[alias] = fields[1:]

first = None
for token in re.split(r"[\s,.!?:;—–\-\"'()\[\]@«»]+", os.environ.get("PROMPT", "")):
    token = token.strip().lower()
    if not token or token in GREET:
        continue
    first = token
    break

hit = table.get(first) if first else None
if not hit:
    raise SystemExit(0)

body, claude_skill, codex_skill, kimi_skill, label = hit
skill = {"claude": claude_skill, "codex": codex_skill, "kimi": kimi_skill}[client]
body_path = ROOT / "roles" / f"{body}.md"
print("<role-posture>")
print(f"Santos звернувся до ролі {label}. ПЕРШИМ ділом візьми поставу `{skill}` — тіло ролі")
print(f"лежить у roles/{body}.md; прочитай його зараз. Без нього ти працюєш не в тій поставі:")
print("чужа лінза на правила, чужі артефакти, чужі повноваження на state.md.")
if not body_path.is_file():
    print(f"УВАГА: roles/{body}.md ВІДСУТНЄ — тіло ролі не знайдено, скажи це Santos перед роботою.")
print("Одна сесія = одна роль на весь її час. Сусідню роль не виконуємо і не запускаємо.")
print("</role-posture>")
raise SystemExit(10)
PY
STATUS=$?
if [[ "$STATUS" -ne 0 && "$STATUS" -ne 10 ]]; then
  printf '<role-posture-error>ядро role_posture завершилось неочікувано (rc=%s); поставу не виміряно</role-posture-error>\n' "$STATUS"
  exit 10
fi
exit "$STATUS"
