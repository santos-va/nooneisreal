# План — читабельність міської камери біля тісних опор

**Дата:** 2026-10-07 · **Роль:** T1 Дедал · **Статус:** `draft` — фаза діагностики; вибір корекції після чисел T2 і брифу T3 ·
**Виріс з:** [[2026-10-07-T1-Orchestration-Session]], [[2026-10-05-Parkour-Tricks-And-Quality]] (розділ «Наступний обмежений напрям»), [[2026-10-05-Tricks-And-Quality-Review]] (YELLOW), [[2026-10-05-Traversal-And-Surface-Review]].

## Що хоче Santos (його словами)

> «Спочатку робиш аудит по крайнім оновленням, перевіряєш чого не вистачає або де зупинилися й просто починаєш надавати відповідні завдання ролям»

Попередня хвиля зупинилась на явній межі: камера біля тісної станції `(4,0,31.4)`. Цей план її закриває.

## Аудит і погляди

| що | місце / команда | вихід |
|---|---|---|
| Хвиля трюків/якості змерджена | `git log --oneline -1` | `f27fd67 Merge pull request #183` |
| CI на `f27fd67` | GitHub MCP `actions_list` | `ci` run 37317106289 success · `macOS main app` run 37317106267 success |
| state.md застарів | `docs/system/state.md:3`, блок T2 | ще пише «draft review», «ще не змерджені» |
| Відкритий кут | [[2026-10-05-Tricks-And-Quality-Review]] | YELLOW: на `(4,0,31.4)` spring arm стискається, proximity dither майже ховає героя; причинність не встановлена |
| Камерний код | `wc -l game/scripts/world/CityCamera.gd game/scripts/world/CityCameraProximity.gd game/shaders/camera_proximity.gdshaderinc` | 188 · 235 · 11 рядків |
| Станція в тестах | `grep -rn "31.4" tools` | `city_parkour_check.gd:167`, `trick_capture.gd:99`, `trick_production_capture.gd:91`, `parkour_capture.gd:132` |
| Godot у контейнері | `which godot` | нема; T2 ставить офіційний 4.7 зі звіркою SHA512 |
| Гейти без Godot | `make gates` | rc0, «БАТАРЕЯ ЗЕЛЕНА», але GDS «ПРОПУЩЕНО» — не вимір |
| Числа hang / drop / kick | T2 → `docs/Fix/2026-10-07-Tight-Station-Camera-Baseline.md` | **очікується** |
| Техніки й API Godot 4.7 | T3 → `docs/Research/2026-10-07-Tight-Support-Camera-Research.md` | **очікується** |
| Художні мірила | T6 → `docs/Art/2026-10-07-Tight-Station-Readability-Criteria.md` | **очікується** |

**Вже вирішено:** [[ADR-018-Camera-Frames-Fight-With-Air]], [[ADR-020-Camera-Continuity-And-Impact]], [[ADR-023-City-First-Exploration]]. Поточний план змінює лише міську камеру, не дуельну.

**Сусіди:** відкритих PR нема; гілки remote — `main`, `textures/santos-pack` (GitHub MCP, 2026-10-07).

Варіанти, погляди й вибір мірилами гри дописуються після трьох звітів вище; до того план — `draft`, і Гефест його не виконує.

## Кроки

| # | хто | що (файли) | ризик | перевірка (команда → очікуваний вихід) |
|---|---|---|---|---|
| 1 | T2 | Godot 4.7 + базова батарея на `f27fd67`; зонд `tools/camera/tight_station_probe.gd`; `docs/Fix/` | Довгий check-playable на llvmpipe | `make check` → `SMOKE ЗЕЛЕНИЙ`; `make gates` → rc0 з GDS, не «ПРОПУЩЕНО» |
| 2 | T3 | Бриф технік і API з джерелами | Невідповідність версії документації | Кожне число з URL + версією або `PLACEHOLDER` |
| 3 | T6 | Художні мірила тісного кадру | Мірило без джерела | Пороги позначені `PLACEHOLDER` |
| 4 | T1 | Варіанти ≥ 3, погляди ≥ 5, вибір | — | Розділ «Аудит і погляди» повний; `make gates` → rc0 |

## Хендофи

Після вибору: «T2 — виконай кроки корекції з [[2026-10-07-Tight-Support-Camera]]».

## Related
- [[state]] · [[constitution]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]] · [[ADR-018-Camera-Frames-Fight-With-Air]] · [[ADR-020-Camera-Continuity-And-Impact]] · [[2026-10-05-Parkour-Tricks-And-Quality]] · [[2026-10-07-City-Encounter-Options]] · [[2026-10-07-T1-Orchestration-Session]]
