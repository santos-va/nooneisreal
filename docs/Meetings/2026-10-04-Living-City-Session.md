# 2026-10-04 — Мотузники, музика, ухилення й живі мешканці

**Хто:** Santos · T1 · шість виконавчих смуг.
**Контекст:** продовження прямим дорученням Santos; спершу push попереднього фікса, потім агенти.

## Рішення

Попередній пакет запушено як `f1c147d` у `codex/rope-combat-identity`. [[2026-10-04-Living-City-Traversal]] фіксує R8, власників файлів, tap-latched parkour та межі прототипу NPC. Нові сюжетні ідеї записані як пропозиція, чинний [[Lore]] збережено.

## Реалізований локальний зріз

T2-звіти: [[2026-10-04-Rope-Traversal]], [[2026-10-04-Dodge-Stamina]], [[2026-10-04-Santos-Soundtracks]], [[2026-10-04-Living-Npc-Slice]]. Керування/HUD: [[2026-10-04-Controls-Stamina-HUD]]. Зовнішність: [[2026-10-04-NPC-Appearance]]. Незалежний огляд: [[2026-10-04-Living-City-Review]].

- Камерний приціл, tap-latched підвіс, retarget і рання готовність до захвату старого span; рух/стрибок дозволені під час готовності. Native прицілювання спочатку перекривав герой, додано collision-aware shoulder offset; ліхтар у фінальному кадрі відкритий.
- Ухилення окремо від signature dash, stamina з відновленням, окремі профілі. У native кадрах виявлено занадто повільне згладжування: прискорено саме dodge pose response; повторні кадри показують гард/зігнуті ноги.
- SOLO Shift — dodge, Alt — dash, E — parkour/наступна опора, Z — detach, Space — jump/reel; SHARED detach лівий/правий Ctrl. Pad X — dodge, Y+X — dash, L3 — parkour, B — block/контекстне detach. Усі фізичні map-гейти збережено суворими; B має лише block binding, Fighter трактує його як відчеплення лише у підвісі.
- Компактна міська картка, ресурси й target prompt; бойова stamina та critical health. Стандартні HP bars не замінено фінальним художнім HUD — варіанти описані в дослідженні.
- 12 постійних жителів, bounded schedule/memory, збереження, streaming, розмови й соціальна підтримка від фактичних зустрічей. Три оригінальні SVG й seed-based статура/одяг/обличчя. Локальна LLM лише через підготовлений gateway контракт; моделі не встановлено.
- Music autoload і two-pass loudness importer готові, реальні біти не підключені: файлів немає в доступному середовищі.

## Перевірка

Початкові інтеграційні failures не приховано: рання готовність захвату блокувала jump; B відкривав паузу; strict smoke відхилив дублікати клавіш X і pad B та старий текст hold-help. Виправлено механіку/мапінг/застарілий текст, не послаблено гейти. T1 прочитав фінальні raw logs: `/tmp/nir-living-complete.log` — smoke **164 перевірки/19847 кадрів** зелений. Перша повна батарея після цього мала єдиний music teardown failure (Ogg decoder на виході, не assertion); після виправлення тільки тестового завершення `/tmp/nir-living-pass.log` — **50 сценаріїв/0 помилок**. `/tmp/nir-living-gates.log` — **БАТАРЕЯ ЗЕЛЕНА, 80 GDS/0 помилок парсингу**, registry **174/174**. Після фінальних записів wikilinks — 0 зламаних, diff-check чистий. Фінальні scoped логи підтверджують traversal **29/0**, dodge **198/0**, input **227/0**, NPC **19/0**, runtime **43/0** (native **44/0**). Випадкові metadata правки імпортера 4.6.3 прибрані, source-параметри 4.7 збережено.

Native `/tmp/nir-traversal-shoulder.log`, `/tmp/nir-living-combat-final.log`, `/tmp/nir-npc-capture.log` завершилися без ERROR, лише непідтримуваний VSync llvmpipe. T1 переглянув фактичні ліхтар/cue, low HP/stamina/CD, dodge Choko/Skea, NPC у районі. Кадри `/workspace/scratch/nir-living-review/`; це не FPS-приймання.

## Інтеграція зі свіжим main

Після push `f17cba3` відкрито [PR #172](https://github.com/santos-va/nooneisreal/pull/172). Main просунувся до `32d7d32` (cleanup #171), що спричинило чотири текстові конфлікти. Збережено короткий state/історію cleanup, актуальну назву Cronshift, draw/reform та reel-пояснення; нові latch/відчеплення/stamina/компактний HUD збережено. README й чинні довідки узгоджено з новою гілкою, а не повернуто старі інструкції.

Фінальні `/tmp/nir-merged-check.log` — **make check-playable: smoke164/19847, 50/0**; `/tmp/nir-merged-gates.log` — **БАТАРЕЯ ЗЕЛЕНА, 80GDS/0**. Незалежний T4 звірив source з обома батьками: gameplay не втрачено, `_key_clash`/`_pad_clash` не послаблено. Це merge main у робочу гілку, не merge PR у main.

## Відкрито

Santos Soundtracks не в доступному дереві, у користувача запитано повний шлях. Всі числа нової рухової презентації — PLACEHOLDER до приймання. Фізичного геймпада і цільового Mac у цьому середовищі немає. Результати виконання додаються після фактичних перевірок.

## Related
- [[state]] · [[2026-10-04-Living-City-Traversal]] · [[Lore]]
