# 2026-10-04 — Головне крісло T1 і план співпраці Codex/Claude

**Хто:** Santos · T1 Дедал (Codex)
**Контекст:** handoff інтеграції та прохання «Віднови роботу»; підготувати послідовність окремих сесій.

## Що обговорили

- Santos визначив цей чат місцем важливих рішень і планування на кілька сесій агентів/субагентів зі стислим поверненням контексту.
- Прочитано state повністю, constitution, root AGENTS, roles.map, T1, Plan-Template, ADR-019, Wave-2-Kickoff, Arena-Depth-Life, Living-Combat, Comfort і реєстр рецидивів.
- Свіжа база `1440344b6efe4eb581e84a1905cc4a9eebcbecbf`; відкритих PR на момент огляду немає. Історичні статуси чужих ролей не переписувалися.
- Виявлено CLI `0.159.0-alpha.3` і Godot `4.6.3`; CLI-events, trust, installed skills, Mac і доступ до Claude-машини не перевірені.
- GitHub читання успішне. Higgsfield list_workspaces/balance: обраний private owner workspace `bf32c161-1feb-43c3-9d97-cd7bbc83357e`, Ultra, 4568.75 кр., unlimited недоступний. Витрат 0.
- CI `37204095786`: jobs success; connector logs підтвердили skip GDS у docs job та smoke ALL OK 164 у godot job. Порожній результат `gh run view --log` не використано як доказ.

## Що вирішили

- Доручення Santos про головне крісло застосоване: поточна роль T1, продукт — [[2026-10-04-Codex-Coworker]].
- Технічна рекомендація B + A записана як **пропозиція**, [[ADR-021-Codex-Coworker-Adapter]]. Спільний закон не дублюється.
- Пакет виконавцю містить мету, роль, SHA, owned files, залежності, перевірки й межі; назад — до 12 рядків із посиланнями на докази. Повний контекст лишається у репо.

## Що відклали / відкриті питання

- Встановлення, hook wiring, role parity, strict Godot/CI — окрема T2-сесія; поточний T1 код не виконує.
- Незалежне runtime-приймання — T4, на конкретному SHA; інтеграція не готова.
- Слухове приймання/керування/FPS на Mac лишаються у попередньому треку комфорту.

## Дії

- [x] T1 · план, запропонований ADR, цей Meeting і свій розділ state.
- [ ] T2 · C1 inventory → C2–C3 adapter/parity → окрема C4 strict gates/CI.
- [ ] T4 · C5 незалежне приймання кожного реалізаційного PR.
- [ ] T1 · C6 зіставити докази; Santos мерджить.

## Перевірки цієї документаційної зміни

Ігровий код, адаптери й hooks не змінювалися. Перевірено 2026-10-04:

- `git diff --check` → rc=0.
- `make hooks-check` → «хуки і гейти виконувані», rc=0; це не доказ runtime wiring.
- `GODOT_BIN=/workspace/scratch/nir-godot-unavailable bash tools/gates/run_gates.sh` → rc=0: wikilinks 0 зламаних; реєстр 171/171; поточна Claude parity 8 ролей/0 проблем; state anchors і R8 sections OK. GDS **навмисно не виміряно** через неіснуючий шлях: команда відтворила дефект skip→зелена батарея. Це не повна валідація коду і не Codex parity.
- Є попередження про неоднозначне старе ім'я `2026-10-04-Camera-Foot-Contact` (Plan/Audit); нові посилання розв'язуються.
- `make check` не запускався: ця зміна лише документаційна, на PATH Godot 4.6.3 замість цільового 4.7. Нова ігрова readiness не заявляється.
- Остаточний SHA документаційної зміни — head PR; результати реалізаційних acceptance criteria ще відсутні.

## Related
- [[state]] · [[constitution]] · [[2026-10-04-Codex-Coworker]] · [[ADR-021-Codex-Coworker-Adapter]] · [[Plans/2026-10-04-Comfort]]
