#!/usr/bin/env bash
#
# АДАПТЕР. Логіки тут немає — вона в tools/hooks/ (спільне, клієнт-нейтральне ядро).
# Цей файл робить рівно дві речі: guard на cwd/подію і обгортку у wire свого клієнта.
# Правка ПОВЕДІНКИ йде в ядро. Якщо здається, що зручніше поправити тут, — це момент,
# коли дві клієнтські площини починають розходитись.
set -uo pipefail
#
# Claude Code додає stdout хука UserPromptSubmit у контекст сам — обгортка не потрібна.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 0
command -v jq >/dev/null 2>&1 || exit 0
CWD="$(cat 2>/dev/null | jq -r '.cwd // ""' 2>/dev/null)"
[[ "$CWD" == "$ROOT" || "$CWD" == "$ROOT"/* ]] || exit 0
OUT="$("$ROOT/tools/hooks/state_header.sh")"; [[ $? -eq 10 ]] || exit 0
printf '%s\n' "$OUT"
exit 0
