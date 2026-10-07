#!/usr/bin/env bash
#
# Батарея гейтів nooneisreal.
#
# Гейт, якого не викликає батарея, — це файл, а не забезпечення. Кожен новий гейт
# дописується сюди В ТОМУ Ж КОМІТІ, що й народжується.
#
#   bash tools/gates/run_gates.sh              # make gates: повна батарея, з GDS. rc = кількість
#                                              # гейтів, що впали. 0 = «БАТАРЕЯ ЗЕЛЕНА».
#   bash tools/gates/run_gates.sh --docs-only  # make gates-docs: усе, крім GDS. Ніколи не каже
#                                              # «БАТАРЕЯ ЗЕЛЕНА»; останній рядок — «… КОД НЕ ВИМІРЯНО».
#
# ТРИ СТАНИ, НЕ ДВА: 0 ok · 1 порушення · 2 «не змогли виміряти». rc=2 рахується разом
# із порушеннями і так само блокує: гейт, який не зміг подивитися, не каже «все гаразд» —
# він каже «ніхто не дивився», а це різні речі. Тому без Godot повна батарея червона (GDS → rc=2),
# а перевірка лише документів — окремий режим із власним написом, не прапорець «пропусти GDS».
#
# Батарея не потребує мережі і нічого поза python3 stdlib + bash (GDS — ще й Godot).

set -u
MODE=full
case "${1:-}" in
  "") ;;
  --docs-only) MODE=docs ;;
  *) echo "ВІДМОВА: невідомий аргумент '$1' (відомий лише --docs-only)"; exit 2 ;;
esac
[ "$#" -le 1 ] || { echo "ВІДМОВА: зайві аргументи: $*"; exit 2; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 2

PY="$(command -v python3 2>/dev/null)"
if [ -z "$PY" ]; then
  echo "ВІДМОВА виміряти: python3 відсутній на PATH"
  exit 2
fi
echo "── інтерпретатор ──────────────────────────────────"
echo "   $PY $("$PY" -c 'import sys; print(sys.version.split()[0])')"
echo ""
if [ "$MODE" = docs ]; then
  echo "── режим --docs-only ──────────────────────────────"
  echo "   GDS (godot --check-only на .gd) у цьому прогоні НЕ запускається: код не вимірюється."
  echo "   Повна батарея: GODOT_BIN=/шлях/до/godot make gates"
  echo ""
fi

FAILED=0
REFUSED=0

run() {
  local name="$1"; shift
  echo "── $name ──────────────────────────────────────────"
  "$@"
  local rc=$?
  case "$rc" in
    0) : ;;
    2) REFUSED=$((REFUSED + 1)); echo "   ↳ rc=2 ВІДМОВА виміряти (це теж блокує)" ;;
    *) FAILED=$((FAILED + 1)); echo "   ↳ rc=$rc ПОРУШЕННЯ" ;;
  esac
  echo ""
  return "$rc"
}

finish() {
  local total=$((FAILED + REFUSED))
  echo "═══════════════════════════════════════════════════"
  if [ "$MODE" = docs ]; then
    if [ "$total" -eq 0 ]; then
      echo "ДОКИ ЗЕЛЕНІ; КОД НЕ ВИМІРЯНО"
    else
      echo "ДОКИ ЧЕРВОНІ: $FAILED порушень, $REFUSED відмов виміряти; КОД НЕ ВИМІРЯНО"
    fi
  elif [ "$total" -eq 0 ]; then
    echo "БАТАРЕЯ ЗЕЛЕНА"
  else
    echo "БАТАРЕЯ ЧЕРВОНА: $FAILED порушень, $REFUSED відмов виміряти"
  fi
  return "$total"
}

# BATTERY_DISPATCH_START
run "ВІК wikilinks у docs/ і roles/"   "$PY" tools/gates/wikilink_check.py
run "РЕЄ реєстр текстур і ассетів"    "$PY" tools/gates/texture_registry_check.py
run "ПАР парність ролей"              "$PY" tools/gates/role_parity_check.py
run "ЯКІ якорі шапки state.md"       "$PY" tools/gates/state_anchor_check.py
run "ПЛА розділ R8 у планах"         "$PY" tools/gates/plan_sections_check.py
if [ "$MODE" = full ]; then
  run "GDS godot --check-only на .gd"   bash  tools/gates/gd_check_all.sh
else
  echo "── GDS godot --check-only на .gd ──────────────────"
  echo "   НЕ ЗАПУСКАВСЯ (--docs-only): .gd НЕ перевірено. Це не «ок», а «код не виміряно»."
  echo ""
fi
# BATTERY_DISPATCH_END

finish
exit $?
