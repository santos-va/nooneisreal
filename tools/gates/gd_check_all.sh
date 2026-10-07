#!/usr/bin/env bash
# Гейт GDS — godot --headless --check-only на кожен game/**/*.gd (addons/ і .godot/ пропускаються).
# rc: 0 кожен файл виміряно, парс-помилок немає · 1 є файли, що не парсяться ·
#     2 ВІДМОВА виміряти: бінаря немає, бінар не відповідає версією Godot, або на якомусь файлі
#       Godot упав, не сказавши нічого розпізнаного. rc=2 блокує так само, як 1 (R3):
#       «ніхто не дивився» — не «ок». Лише доки без Godot — `make gates-docs`, і він так і каже.
# Файл зараховано як виміряний, коли у виводі є банер «Godot Engine v…» і Godot завершився
# rc=0, або rc=1 і кожен рядок SCRIPT ERROR|Parse Error — відомий autoload-шум нижче.
# Проєкт має бути імпортований (game/.godot/ з реєстром class_name); `make check` імпортує першим.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 2
GAME="$ROOT/game"
[ -d "$GAME" ] || { echo "   game/ відсутній — нічого перевіряти"; exit 0; }

GODOT="${GODOT_BIN:-}"
[ -n "$GODOT" ] || GODOT="$(command -v godot 2>/dev/null || true)"
if [ -z "$GODOT" ] || [ ! -f "$GODOT" ] || [ ! -x "$GODOT" ]; then
  if [ -n "${GODOT_BIN:-}" ]; then WHY="GODOT_BIN='$GODOT_BIN' не є виконуваним файлом"
  else WHY="GODOT_BIN не задано, godot на PATH немає"; fi
  echo "   ВІДМОВА виміряти: godot не знайдено ($WHY) — .gd НЕ перевірено."
  echo "   Це «ніхто не дивився», а не «ок», тому rc=2 блокує. Повна батарея: GODOT_BIN=/шлях/до/godot make gates"
  echo "   Лише доки без Godot: make gates-docs (останній рядок — «КОД НЕ ВИМІРЯНО»)."
  exit 2
fi

# Бінар, що виходить без слова (/bin/true) або падає (/bin/false), не має права «перевірити» жоден файл.
VER="$("$GODOT" --headless --version </dev/null 2>&1 | grep -m1 -E '^[0-9]+\.[0-9]+\.' || true)"
if [ -z "$VER" ]; then
  echo "   ВІДМОВА виміряти: '$GODOT' не відповів версією на --version — це не Godot або він не запускається; .gd НЕ перевірено."
  exit 2
fi

FILES="$(cd "$ROOT" && find game -name '*.gd' -not -path '*/.godot/*' -not -path '*/addons/*' | sort)"
[ -n "$FILES" ] || { echo "   .gd файлів немає"; exit 0; }

# --check-only не реєструє autoload-синглтони (GameState, Sfx, ...) — їхні «Identifier not found»
# і каскадні «Failed to compile depended scripts» відфільтровуються; справжній парс-еррор лишається.
AUTOLOADS="$(sed -n '/^\[autoload\]/,/^\[/p' "$GAME/project.godot" | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' | paste -sd'|' -)"
FILTER='Failed to compile depended scripts|Compilation failed|Failed to load script'
[ -n "$AUTOLOADS" ] && FILTER="$FILTER|Identifier not found: ($AUTOLOADS)\b|Identifier \"($AUTOLOADS)\" not declared"

show_tail() {
  if [ -n "$1" ]; then printf '%s\n' "$1" | tail -n 5 | sed 's/^/      /'; else echo "      (вивід порожній)"; fi
}

BAD=0; UNMEASURED=0; N=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  N=$((N + 1))
  RES="res://${f#game/}"
  OUT="$("$GODOT" --headless --path "$GAME" --check-only --script "$RES" 2>&1)"; RC=$?
  MARK="$(printf '%s\n' "$OUT" | grep -E 'SCRIPT ERROR|Parse Error' || true)"
  REAL=""
  [ -z "$MARK" ] || REAL="$(printf '%s\n' "$MARK" | grep -vE "$FILTER" || true)"
  if ! printf '%s\n' "$OUT" | grep -q '^Godot Engine v'; then
    UNMEASURED=$((UNMEASURED + 1))
    echo "   НЕ ВИМІРЯНО $f (rc=$RC): у виводі немає банера «Godot Engine v…» — Godot на цьому файлі не відпрацював"
    show_tail "$OUT"
  elif [ "$RC" -eq 0 ]; then
    :
  elif [ -n "$REAL" ]; then
    BAD=$((BAD + 1))
    echo "   FAIL $f (rc=$RC)"
    printf '%s\n' "$REAL" | head -n 10 | sed 's/^/      /'
  elif [ -z "$MARK" ]; then
    UNMEASURED=$((UNMEASURED + 1))
    echo "   НЕ ВИМІРЯНО $f (rc=$RC): Godot завершився з помилкою без жодного SCRIPT ERROR/Parse Error — збій бінаря, не перевірка"
    show_tail "$OUT"
  elif [ "$RC" -ne 1 ]; then
    UNMEASURED=$((UNMEASURED + 1))
    echo "   НЕ ВИМІРЯНО $f (rc=$RC): лише autoload-шум, але код виходу не 1 — Godot упав (сигнал/abort), файл не дочитано"
    show_tail "$OUT"
  fi
done <<EOF_FILES
$FILES
EOF_FILES

echo "   перевірено: $((N - UNMEASURED)) · не парсяться: $BAD · не виміряно: $UNMEASURED · бінар: $GODOT ($VER; autoload-ідентифікатори відфільтровано: ${AUTOLOADS:-немає})"
[ "$BAD" -eq 0 ] || exit 1
[ "$UNMEASURED" -eq 0 ] || exit 2
exit 0
