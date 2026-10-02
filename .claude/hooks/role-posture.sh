#!/usr/bin/env bash
#
# АДАПТЕР. Логіки тут немає — вона в tools/hooks/ (спільне, клієнт-нейтральне ядро).
# Цей файл робить рівно дві речі: guard на cwd/подію і обгортку у wire свого клієнта.
# Правка ПОВЕДІНКИ йде в ядро. Якщо здається, що зручніше поправити тут, — це момент,
# коли дві клієнтські площини починають розходитись.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 0
command -v jq >/dev/null 2>&1 || exit 0
IN="$(cat 2>/dev/null)"
CWD="$(printf '%s' "$IN" | jq -r '.cwd // ""' 2>/dev/null)"
[[ "$CWD" == "$ROOT" || "$CWD" == "$ROOT"/* ]] || exit 0
PROMPT="$(printf '%s' "$IN" | jq -r '.prompt // ""' 2>/dev/null)"
OUT="$("$ROOT/tools/hooks/role_posture.sh" "$PROMPT" claude)"; [[ $? -eq 10 ]] || exit 0
printf '%s\n' "$OUT"
exit 0
