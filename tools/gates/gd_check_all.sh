#!/usr/bin/env bash
# Гейт GDS — godot --headless --check-only на кожен game/**/*.gd (addons/ і .godot/ пропускаються).
# rc: 0 ok або пропущено без бінаря (голосно) · 1 є файли, що не парсяться · 2 відмова.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 2
GAME="$ROOT/game"
[ -d "$GAME" ] || { echo "   game/ відсутній — нічого перевіряти"; exit 0; }

GODOT="${GODOT_BIN:-}"
[ -n "$GODOT" ] || GODOT="$(command -v godot 2>/dev/null || true)"
if [ -z "$GODOT" ] || [ ! -f "$GODOT" ] || [ ! -x "$GODOT" ]; then
  echo "   ПРОПУЩЕНО: godot не знайдено (PATH: ні; GODOT_BIN='${GODOT_BIN:-}' не є виконуваним файлом) — .gd НЕ перевірено."
  echo "   Це не «ок», це «ніхто не дивився». Прогнати там, де Godot є: make check"
  exit 0
fi

FILES="$(cd "$ROOT" && find game -name '*.gd' -not -path '*/.godot/*' -not -path '*/addons/*' | sort)"
[ -n "$FILES" ] || { echo "   .gd файлів немає"; exit 0; }

# --check-only не реєструє autoload-синглтони (GameState, Sfx, ...) — їхні «Identifier not found»
# і каскадні «Failed to compile depended scripts» відфільтровуються; справжній парс-еррор лишається.
AUTOLOADS="$(sed -n '/^\[autoload\]/,/^\[/p' "$GAME/project.godot" | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' | paste -sd'|' -)"
FILTER='Failed to compile depended scripts|Compilation failed|Failed to load script'
[ -n "$AUTOLOADS" ] && FILTER="$FILTER|Identifier not found: ($AUTOLOADS)\b|Identifier \"($AUTOLOADS)\" not declared"

BAD=0; N=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  N=$((N + 1))
  RES="res://${f#game/}"
  OUT="$("$GODOT" --headless --path "$GAME" --check-only --script "$RES" 2>&1)"; RC=$?
  REAL="$(printf '%s\n' "$OUT" | grep -E 'SCRIPT ERROR|Parse Error' | grep -vE "$FILTER" || true)"
  if [ "$RC" -ne 0 ] && [ -n "$REAL" ]; then
    BAD=$((BAD + 1))
    echo "   FAIL $f (rc=$RC)"
    printf '%s\n' "$REAL" | head -n 10 | sed 's/^/      /'
  fi
done <<EOF_FILES
$FILES
EOF_FILES

echo "   перевірено: $N · не парсяться: $BAD · бінар: $GODOT (autoload-ідентифікатори відфільтровано: ${AUTOLOADS:-немає})"
[ "$BAD" -eq 0 ] && exit 0 || exit 1
