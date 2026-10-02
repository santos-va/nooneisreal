#!/usr/bin/env bash
# Швидка перевірка щойно записаного .gd: godot --headless --check-only.
# rc: 0 нічого (не .gd або нечитабельний) · 10 є текст (результат або «пропущено»).
# Без бінаря Godot хук fail-open, але ГОЛОСНО: «не дивився» ≠ «ок».
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 0
F="${1:-}"
[[ -n "$F" && "$F" == *.gd && -r "$F" ]] || exit 0

GODOT="${GODOT_BIN:-}"
[[ -n "$GODOT" ]] || GODOT="$(command -v godot 2>/dev/null || true)"
if [[ -z "$GODOT" || ! -f "$GODOT" || ! -x "$GODOT" ]]; then
  echo "<gd-check file=\"$F\" skipped=\"true\">godot не знайдено (PATH: ні; GODOT_BIN='${GODOT_BIN:-}' не є виконуваним файлом) — синтаксис НЕ перевірено (ніхто не дивився, це не «ок»); перед «готово» прогнати make check там, де Godot є.</gd-check>"
  exit 10
fi

GAME="$ROOT/game"
ABS="$(cd "$(dirname "$F")" 2>/dev/null && pwd)/$(basename "$F")"
if [[ "$ABS" == "$GAME"/* ]]; then RES="res://${ABS#"$GAME"/}"; else RES="$ABS"; fi

AUTOLOADS="$(sed -n '/^\[autoload\]/,/^\[/p' "$GAME/project.godot" | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' | paste -sd'|' -)"
FILTER='Failed to compile depended scripts|Compilation failed|Failed to load script'
[[ -n "$AUTOLOADS" ]] && FILTER="$FILTER|Identifier not found: ($AUTOLOADS)\b|Identifier \"($AUTOLOADS)\" not declared"
OUT="$("$GODOT" --headless --path "$GAME" --check-only --script "$RES" 2>&1)"; RC=$?
REAL="$(printf '%s\n' "$OUT" | grep -E 'SCRIPT ERROR|Parse Error' | grep -vE "$FILTER" || true)"
if [[ $RC -eq 0 || -z "$REAL" ]]; then
  echo "<gd-check file=\"$F\" rc=\"0\">godot --check-only: OK ($RES)</gd-check>"
else
  echo "<gd-check file=\"$F\" rc=\"$RC\">"
  printf '%s\n' "$REAL" | head -n 20
  echo "Файл щойно записано і він НЕ парситься. Полагодь зараз, не відкладай на батарею."
  echo "</gd-check>"
fi
exit 10
