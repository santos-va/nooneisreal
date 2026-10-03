# Аудит спринту, смуга I, частина 2 — #112, #116, #117 по факту і закриття RED п. 3

**Дата:** 2026-10-03 · **Роль:** T4 Феміда · **План:** [[2026-10-03-Sprint-Arenas-VFX]] § Смуги, рядок I. Частина 1 —
[[2026-10-03-Sprint-Lane-I]] (PR #114). Поки вона писалась, Santos змерджив #110, #111, #112, #116, #117. Тому все міряно
**по факту** на `main` `6546899` у чистому worktree поза iCloud. Godot `4.7.2.stable.official.ed1daf0bf`.

## Вердикт: **YELLOW, без RED.** RED п. 3 закрито

| # | що | вердикт | команда → вихід |
|---|---|---|---|
| 1 | `main` `6546899`: батарея | GREEN | `make check` → `[smoke] ALL OK (148 checks) in 19183 frames`, `budget used 19183 / 38000 frames (50 %)`, rc=0; `run_gates.sh` → `БАТАРЕЯ ЗЕЛЕНА`, rc=0 |
| 2 | **RED п. 3** ([[2026-10-03-Launch-5-6]]) | **GREEN — закрито** | `DuelCamera.gd:37 SIDE_DIST_PER_M := 0.68`; літерал smoke `[…, 0.68]`; `SmokeTest.gd:2596 p1_min := 0.15`. Проба: `side sep 6 P1 0.1502–0.1530`. Злам 0.7 (код + літерал) → `FAIL … P1 14.84–15.12 %`. Злам 0.7 лише в коді → `FAIL design numbers drifted …: SIDE_DIST_PER_M = 0.7, GDD says 0.68` |
| 3 | пропозиція 2 частини 1 (`%.1f` у рядку кадру) | YELLOW | `SmokeTest.gd:2605` досі `P1 %.0f–%.0f %%`: 15.02 % друкується як «15–15 %». Тепер це правда, але запас 0.02 п. п. у лозі не видно |
| 4 | #110 між моїм аудитом і мержем | GREEN | `git diff b621ca2 6d8f735 --stat` → лише `06-UI-UX.md` і журнал Гермеса (злиття `main`), код той самий |
| 5 | #116 (смуга B, VFX): «ефекти лише картинка» — RNG, шейдери, самоприбирання, кроки | GREEN | 3/3 червоні, § п. 5 |
| 6 | #116: ризик плану B «ефекти змінюють симуляцію» | YELLOW | злам B6 (ефект штовхає бійців) → хеш дуелі змінився, smoke `ALL OK`. § п. 6. Клас 5 |
| 7 | #117 (A2: 3 арени × день/ніч, меню STAGE/TIME) | GREEN | 4/4 червоні, § п. 7 |
| 8 | #117: «launch flags win for the run» (`Main.gd:53`) | YELLOW | злам A5n (збережене після прапорців у `Main._ready`) → `OK A2 arenas …`, `ALL OK`. Клас 5 |
| 9 | #116, #117, #110: журнали зустрічі | YELLOW | `git grep -l "<fix-лог>" origin/main -- docs/Meetings`: `sprint-lane-b-vfx` → 0, `sprint-a2-arenas-day-night` → 0, `sprint-a1-fixed-world` → 0. Клас 7 |
| 10 | #112 (смуга D, промпти й кошторис) | GREEN | лише docs (`gh pr view 112 --json files`). «0 кредитів» — у `transactions` смузі D не приписано жодної витрати, див. п. 11 |
| 11 | Кредити спринту | GREEN | `balance` → **5478.25**. `transactions`: 10:26:32Z ×4, 10:35:24Z ×4, 10:50:11–10:50:57Z ×20, усе по 2.75 = **77** = 5555.25 − 5478.25. Слова: «Так» (11), «GO!» (11), «Go» на крок 1 (55) — `Apollon-Sprint-C-Prompts.md:41,51,55` на гілці `claude/practical-hopper-rmfgi4`. **PR із цими 55 кр. ще не відкрито** — реєстр і id перевірю, коли відкриють. Стеля 1000 |
| 12 | Нові ассети в `game/assets` за спринт | GREEN | `git diff --stat 3d022b1 origin/main -- game/assets` → порожньо. Шейдери лежать у `game/shaders/`, вони не ассети реєстру |

## п. 5 — #116: зломи стадії «lane B»

`--smoke-only=cam` (стадія в `_ready`, ганяється завжди). Правки python-заміною з `assert count == 1`, файли повернено з `.bak`,
`git status --short game` → чисто.

| # | злам | вихід |
|---|---|---|
| B1 | `SmearShards`: `_rng.seed = randi()` (глобальний RNG) | `FAIL lane B: spawning effects moved the global RNG (494098138, want 641615738)` |
| B2 | `SmokeCloud` не робить `queue_free()` | `FAIL lane B: SmokeCloud is still alive after 600 frames` |
| B3 | привид тане плавно (`k = _left / _life` без `Fx.stepped`) | `FAIL lane B: Afterimage fades through 18 values — smooth, not drawn in steps` |

## п. 6 — #116: гард «ефект не міняє симуляцію» дивиться не туди

План B, рядок перевірки: «smoke "duel replay … same hash" лишається зеленим». Але реплей порівнює **два прогони між собою**.
Ефект, який детерміновано міняє бій, дає той самий новий хеш двічі.

| # | злам (`--smoke-only=duel`) | хеш plane / free | вихід |
|---|---|---|---|
| база | — | `163780130` / `522956308` | `ALL OK (83 checks)` |
| B4 | `Afterimage._process`: `randf()` щокадру | `163780130` / `522956308` | `ALL OK` — бій не читає глобальний RNG (`grep -rnE "(^\|[^_.a-z])rand(f\|i\|f_range)\("` → лише `Sfx.gd:39`, тряска `FightCamera`/`DuelCamera`), тож шкоди нема |
| B5 | `TimeStopFx._physics_process`: `randf()` щотакт | те саме | `ALL OK`, той самий висновок |
| **B6** | `Afterimage._process` зсуває кожного бійця на 1 см/кадр | **`582580399` / `898004020`** | **`ALL OK (83 checks)`** — симуляція змінилась, smoke мовчить |

Сьогодні в коді такого ефекту нема: B4/B5 дають базовий хеш. Тому це YELLOW (обіцянка без гарда), а не RED. Механізм — прогнати
ту саму дуель з вимкненими ефектами й вимагати той самий хеш. Пропозиція 2.

## п. 7 — #117: зломи A2

`--smoke-only=cam` (стадія 138, база `OK A2 arenas: river/day … fountain/night`).

| # | злам | вихід |
|---|---|---|
| A1n | неон CRONSHIFT і вдень на `fountain` | `FAIL A2 fountain day: … neon true (want false)` |
| A2n | нічний `tint` картки не застосовано | `FAIL A2 river night: the painted card is not darkened (tint (1.0, 1.0, 1.0, 1.0))` |
| A3n | STAGE ходить по всіх 7 `STAGES`, як до спринту | `FAIL A2 menu/save: STAGE ×3 ["market_street", "back_alley", "main_street"]` |
| A4n | smoke читає збережену арену (`--smoke` не пропускає `load_stage_time`) | `FAIL A2 menu/save: … smoke ignores saved false` |
| **A5n** | `Main._ready`: `apply_saved_stage` **після** `apply_launch_args` | **`OK A2 arenas …`, `ALL OK (34 checks)`** |

A5n — той самий клас, що N3 в [[2026-10-03-Launch-4-0]]: функції перевірено поодинці, а проводку в `Main._ready` — ні.

**Спостереження, без оцінки.**
- `--stage river` без `--night` при збереженій ночі лишає ніч. Прапорець не вміє примусово поставити день: `apply_launch_args` лише
  вмикає `night`.
- Стадія 138 тисне `stage_btn`/`time_btn` справжнього меню, і воно пише в справжній `user://settings.cfg` гравця. Файл бекапиться й
  відновлюється, але якщо smoke впаде посередині, на машині Santos лишиться змінений вибір арени.
- `bazaar` і `fountain` поки ходять на старих картках `market_street` / `main_street` / `back_alley` з позначкою PLACEHOLDER
  (`GameState.gd`), до арту смуги C.

## Пропозиції

1. **Гефест:** `%.1f` у рядку `ADR-018 frame` (`SmokeTest.gd:2605`). — п. 3
2. **Гефест (T2·B):** гард «ефекти — лише картинка» через рівність хешів. Та сама дуель із вимкненим спавном ефектів (прапорець у `Fx`)
   має дати той самий хеш, що й з ефектами. Негатив — B6. — п. 6
3. **Гефест (T2·A):** гард проводки `Main._ready`. Smoke викликає ту саму послідовність, що `_ready`, на свіжій копії `GameState`, з
   тимчасовим cfg «fountain/night» і аргументами `--stage bazaar`, і чекає `bazaar`. Негатив — A5n. Окремо: `--day` або `--stage` скидає
   ніч — це розвилка для Гермеса. — п. 8
4. **Гефест (T2·A):** у стадії 138 писати меню в тимчасовий cfg, а не в `user://settings.cfg`. — п. 7, спостереження
5. **Гефест / T2·B:** журнали зустрічі з лінком на 3 fix-логи (клас 7). Механізм — гейт `journal_check.py` ([[2026-10-03-Launch-5-6]]
   пропозиція 6). — п. 9
6. **Аполлон:** PR смуги C з 77 кр. — коли відкриєш, Феміда звіряє id із `transactions` і реєстром. — п. 11

## Реєстр

Клас 5 → 9 (B6, A5n). Клас 7 → +2 (`sprint-lane-b-vfx`, `sprint-a2-arenas-day-night`). Обидва ВІДКРИТО — [[recurring_class_register]].

## Related
- [[2026-10-03-Sprint-Lane-I]] · [[2026-10-03-Sprint-Arenas-VFX]] · [[2026-10-03-Launch-5-6]] · [[2026-10-03-Launch-4-0]] ·
  [[02-Combat-System]] · [[VFX-Direction]] · [[Cronshift]] · [[06-UI-UX]] · [[recurring_class_register]] · [[2026-10-03-Femida-Sprint-Lane-I]]
