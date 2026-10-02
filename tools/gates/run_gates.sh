#!/usr/bin/env bash
#
# Батарея гейтів nooneisreal.
#
# Гейт, якого не викликає батарея, — це файл, а не забезпечення. Кожен новий гейт
# дописується сюди В ТОМУ Ж КОМІТІ, що й народжується.
#
#   bash tools/gates/run_gates.sh      # rc = кількість гейтів, що впали. 0 = зелено.
#
# ТРИ СТАНИ, НЕ ДВА: 0 ok · 1 порушення · 2 «не змогли виміряти». rc=2 рахується разом
# із порушеннями і так само блокує: гейт, який не зміг подивитися, не каже «все гаразд» —
# він каже «ніхто не дивився», а це різні речі.
#
# Батарея не потребує мережі і нічого поза python3 stdlib + bash.

set -u
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
  if [ "$total" -eq 0 ]; then
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
run "GDS godot --check-only на .gd"   bash  tools/gates/gd_check_all.sh
# BATTERY_DISPATCH_END

finish
exit $?
