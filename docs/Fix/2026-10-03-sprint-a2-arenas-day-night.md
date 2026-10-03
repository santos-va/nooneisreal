# Fix-журнал — спринт, смуга A, A2: три арени × день/ніч, рядки STAGE/TIME у меню

**Роль:** T2 Гефест (T2·A), 2026-10-03. **План:** [[2026-10-03-Sprint-Arenas-VFX]] § Смуги A, крок A2. **ТЗ меню:** [[06-UI-UX]] § Арена й час
доби в меню (Гермес, смуга G). **Канон:** [[Cronshift]] § Нові арени. **Від `main`** `f8c01e4` (після #110, #111).

## Звірка

- `GameState.STAGES` — 5 старих записів; `bazaar`, `fountain` немає (як і каже 06). Smoke прив'язаний до **індексів** (`stage_index = 2` —
  `back_alley`), тож старі записи лишаються на місцях, нові — в кінці; «вийти з ротації» = не показувати в меню.
- Арту `bazaar`/`fountain` у Sketch-Cel ще немає (смуга C). Плейсхолдери — старі картки (`market_street` → bazaar день, `back_alley` →
  bazaar ніч, `main_street` → fountain), кольори сонця/світла/неба — мої PLACEHOLDER на основі наявних записів, T6 переналаштує.
- **Арес закрив RED п. 3 Феміди варіантом (а)** (PR #111): нахил `side` **0.68** — ставлю в `DuelCamera` і в гард «числа ↔ GDD»; межа P1 у smoke
  знову строга 15 % (мій тимчасовий 0.148 прибрано).

## Що зроблено

- `GameState`: записи `bazaar`, `fountain` з `label`, `night`-словником (sun, ambient, небо, `tint`, `neon`); `ROTATION = [river, bazaar,
  fountain]`; `RIVER_NIGHT`; `night: bool`; `stage()` зливає нічні значення; `stage_id()`, `set_stage(id)` (не ротаційний/невідомий → `river`),
  `cycle_stage()` — лише ротація; `save_stage_time()` / `load_stage_time()` → `[gameplay] stage` (id), `time_of_day`.
- `Main`: `apply_saved_stage(args, state, path)` — чиста, smoke не читає налаштувань; прапорці `-- --stage <id>` і `-- --night` — лише на запуск.
- `MainMenu`: `STAGE: ◂ River ▸` (тільки ротація, коротка назва) і новий рядок `TIME: ◂ DAY / NIGHT ▸` одразу під ним; ←/→, Enter, клік — як у
  KEYBOARD/MODE; вибір зберігається.
- `Backdrop`: нічний `tint` на картці (шейдер `backdrop.gdshader` уже мав `tint`, його ніхто не задавав); **неон CRONSHIFT** (`Label3D`,
  без світла, рожевий з обвідкою) перед першою карткою — лише якщо в записі є `neon` (= `fountain` уночі). Хмари, що ховають неон, — ні.
- `Screenshot.gd`: не скидає арену на 0, коли є `--stage` (знімок кожного варіанта — вимога плану A2).
- Smoke, стадія `_stage_a2_arenas()` (138): 6 варіантів завантажуються, кожна отримує своє сонце, ніч ≠ день, картка вночі затемнена,
  неон лише на `fountain`/ніч; меню STAGE ×3 → bazaar, fountain, river (жодного старого), TIME ×2 → ніч, день; збережено id;
  тимчасовий файл → назад; `--smoke` ігнорує збережене; `--stage bazaar --night`; `back_alley` → `river`.

**Предмет:** для всіх 6 комбінацій (арена × час): світло арени = записові, ніч ≠ день, неон ⇔ fountain ∧ ніч; меню показує лише ротацію.

## Перевірка

| команда | результат |
|---|---|
| `make check` | `[smoke] ALL OK (147 checks) in 19183 frames`; `budget used 19183 / 38000 frames (50 %)` |
| `make gates` | `БАТАРЕЯ ЗЕЛЕНА` |
| `xvfb-run … -- --stage <id> [--night] --screenshot=<scratchpad>` | 6 знімків; ніч на річці — темне холодне місто; неон у кадрі не потрапив (камера дивиться на іншу картку) |

**Негатив** (`--smoke-only=cam`) — 4/4 червоні: меню гортає всі `STAGES` (`market_street, back_alley, main_street`); ніч ігнорується
(`card is not darkened`); неон завжди (`river day … neon true`); без нічного `tint` (`tint (1, 1, 1, 1)`).

## Відомо / не перевірено

- Арт і кольори — PLACEHOLDER (смуга C). Старі вуличні картки в кільці виглядають «перспективою вулиці», підлога пласка — текстури від C.
- Вода річки вночі лишається сутінковою (шейдер води колір часу доби не бере).
- Ліхтарі зі світлом уночі — A3.
- Контраст HUD (варіант 2, подвійний контур — рішення Santos у 06) — окремий PR T2·A після A2.

## Що перевірити (Santos)

`cd ~/dev/nir-play && make update BRANCH=claude/friendly-ritchie-3ti2sm && make run`:
1. Меню: `STAGE` гортає лише River → Bazaar → Fountain Square; під ним `TIME: DAY / NIGHT`. Вийди й зайди — вибір той самий.
2. Кожна арена вдень і вночі: уночі місто темне й холодне; на Fountain Square вночі в небі рожевий неон CRONSHIFT (покрутись — він з одного боку).

## Related
- [[2026-10-03-Sprint-Arenas-VFX]] · [[06-UI-UX]] · [[Cronshift]] · [[2026-10-03-sprint-a1-fixed-world]] · [[02-Combat-System]] · [[Backgrounds]] · [[state]]
