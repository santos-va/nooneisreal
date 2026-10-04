#!/usr/bin/env bash
# Шапка docs/system/state.md для інжекту в контекст + вік файла в годинах.
# rc: 0 файла немає (нічого сказати) · 10 є текст у stdout.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 0
STATE_REL="docs/system/state.md"
STATE="$ROOT/$STATE_REL"
HEAD_LINES="${NIR_STATE_HEAD:-25}"
[[ -r "$STATE" ]] || exit 0

# Вік файла: GNU stat (-c %Y) або BSD stat (-f %m). Валідуємо ЗНАЧЕННЯ, не rc:
# GNU stat на `-f %m` віддає rc=1, але все одно щось пише в stdout.
NOW="$(date +%s 2>/dev/null || echo 0)"
MTIME=""
for probe in "-c %Y" "-f %m"; do
  # shellcheck disable=SC2086
  cand="$(stat $probe "$STATE" 2>/dev/null | head -n1 | tr -d '[:space:]')"
  if [[ "$cand" =~ ^[0-9]+$ ]]; then MTIME="$cand"; break; fi
done
[[ -z "$MTIME" ]] && MTIME="$NOW"
AGE_H=$(( (NOW - MTIME) / 3600 ))

STALE=""
[[ "$AGE_H" -ge 24 ]] && STALE=" СТАН НЕ ОНОВЛЮВАВСЯ ${AGE_H} год — вважай кожен факт нижче простроченим, поки не переміряв."

echo "<honesty-rule>R0 (головне правило Santos): перед відповіддю перевір кожен факт у джерелі в ЦІЙ сесії — файл, команда, інструмент (Higgsfield balance/get_cost/models_explore, git, make check). Не перевірено — так і скажи. Нічого не вигадуй. Свою помилку визнай першим рядком.</honesty-rule>"
echo "<decision-rule>R8 (ADR-019): рішення, що міняє гру, процес або витрачає кредити, — спершу аудит, ≥ 3 варіанти, ≥ 5 поглядів, вибір мірилами гри; у плані — розділ «Аудит і погляди» (docs/Plans/Plan-Template.md).</decision-rule>"
echo "<project-state source=\"${STATE_REL}\" age_hours=\"${AGE_H}\">"
echo "Перші ${HEAD_LINES} рядків поточної правди проєкту. Це ЗАЯВИ, а не факти:"
echo "будь-яке число чи шлях звідси переводиться командою, перш ніж на нього спертися.${STALE}"
echo "---"
head -n "$HEAD_LINES" "$STATE"
echo "---"
echo "Повний файл — ${STATE_REL}. Якщо твоє твердження суперечить цьому блоку —"
echo "не обирай зручнішу версію: переміряй командою і виправ те, що збрехало."
echo "</project-state>"
exit 10
