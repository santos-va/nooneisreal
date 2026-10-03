# Fix-журнал — Запуск 6: 3D-керування й камера («нормальний файт»)

**Роль:** T2 Гефест, 2026-10-03. **План:** [[2026-10-03-Path-to-First-Fight]] § Запуски, рядок 6; [[ADR-014-Free-Movement-Layout]],
[[ADR-015-Solo-Camera-Behind-Fighter]], [[06-UI-UX]] § Кнопка «РЕЖИМ 2.5D / 3D», числа — [[02-Combat-System]] § Камера за спиною і плавність.
**Слово Santos:** «запуск 5, потім кристальна ульта, потім запуск 6»; 6 — тією ж гілкою в PR santos-va/nooneisreal#95 (відповідь у чаті).
**Статус:** зроблено, на ревʼю разом із 5 у #95.

## Звірка

- Усі файли плану на місці: `InputRouter.gd` (`TODO #26`, `FREE_MOVE_UP_KEYS`), `DuelCamera.gd` (кламп 3°/такт, без межі прискорення,
  поворот кроками фізики), `MainMenu.gd` (рядок `KEYBOARD`), `GameState.free_move`. У `project.godot` дій `p*_up/down` немає
  (python по `project.godot`), `p*_crouch` має axis 1 +1 і кнопку 12 — як каже ADR-014.
- **Розбіжність, дрібна:** [[06-UI-UX]] пише дефолт `[gameplay] free_move = false`, «доки Santos не скаже „3D за замовчуванням“ — запуск 6».
  Santos це вже сказав (запуск 2, `GameState.free_move = true`, smoke «free_move defaults to true»). Беру дефолт `true`. Рядок у 06 —
  Гермесу (не мій файл).
- Ввід у 3D іде через `DuelFrame` (симуляція), а не через камеру. Тому режим `behind` змінює лише рамку **P1**: у соло W — до суперника,
  A/D — обхід (ADR-015 п. 6). P2/CPU лишаються в бічній рамці, тож поведінка CPU не змінилась.

## Що зроблено

- **Розкладка (ADR-014):** у 3D W/↑ → `up`, S/↓ → `down`, стрибок — лише Space і `/`, присід — **X** (P1) і **M** (P2, SHARED).
  Геймпад: лівий стік ↑/↓ → `p*_up/down`, з `p*_crouch` стік знято, присід — D-pad ↓. У 2.5D — розкладка `project.godot` без змін.
  Підказка HUD: соло проти CPU — «W/S to·from foe · A/D circle», VERSUS — «A/D to·from foe · W/S circle». `TODO #26` прибрано.
- **Кнопка MODE** у меню, одразу під `KEYBOARD`: `MODE: ◂ 3D (free move) ▸` / `◂ 2.5D (plane) ▸`. Перемикають Enter, клік і ←/→.
  `GameState.save_free_move()` пише `user://settings.cfg` → `[gameplay] free_move` (спершу `load()`, тож `[input]` лишається).
  `Main` бере збережений вибір при старті. Прапорці `--plane` / `--free-move` діють лише на цей запуск і нічого не пишуть, а smoke файл не читає.
- **Камера (ADR-015):** `GameState.camera_behind()` = 3D і P2 — CPU (FIGHT, TRAINING) → `DuelFrame.behind` → `DuelCamera.behind`.
  - `behind`: точка за P1 на лінії P2 → P1, 3.4 м (+0.25 м/м після `sep` 4, стеля 6), висота 3.2 → 2.5 м (`sep` 1 → 4), плече 1.2 м праворуч;
    погляд — на 60 % від P1 до P2 на висоті 1.2 м. Числа — константи `DuelCamera.BEHIND_*` з GDD 02, гард «числа ↔ GDD» їх звіряє.
  - Обидва режими: кутова швидкість ≤ 3°/такт, **зміна швидкості ≤ 0.25°/такт²**, з гальмуванням (швидкість ≤ √(2·a·залишок)), тому без перельоту.
  - Рендер: yaw інтерполюється між двома останніми тактами (`Engine.get_physics_interpolation_fraction()`), а не стрибає з частотою 60 Гц.

**Предмет:** для всіх тактів обходу 360° в обох режимах |ω| ≤ 3°/такт, |Δω| ≤ 0.25°/такт², обидва бійці в кадрі; у `behind` голова P2
на екрані не нижча за голову P1, а W веде P1 до суперника.

## Перевірка

| команда | результат |
|---|---|
| `make check` | `[smoke] ALL OK (122 checks) in 16705 frames`, `SMOKE ЗЕЛЕНИЙ` (було 114) |
| `make gates` | `БАТАРЕЯ ЗЕЛЕНА` |
| `godot … -- --smoke --smoke-only=cam` | `camera behind P1: … 360° in 180 frames; |ω| ≤ 2.00°/tick, |Δω| ≤ 0.250°/tick², … worst -174 px`; `camera side-on in VERSUS: … |Δω| ≤ 0.250` |
| `xvfb-run … -- --skeletal-rig --screenshot=<scratchpad>` | кадри 230, 420: камера за спиною Choko, Skea над плечем, підказка «W/S to·from foe» (не в git) |

Старі перевірки бічної камери (обхід 360°, зміна сторін, стрибок лінії на 90°) лишились зеленими з новою межею прискорення.

**Негативні контролі** (`--smoke-only=cam`, тимчасова правка, повернення з копії) — 7/7 червоні:

| форма зламу | що каже smoke |
|---|---|
| без межі прискорення | `|Δω| max 0.495 (≤ 0.25)` |
| ввід P1 ігнорує `behind` | `W (up) … from 4.00 to 4.00 m` |
| `camera_behind()` завжди `false` | `vs CPU in 3D want behind (camera false …)` |
| камера низько (0.9 м) | `P2 head 173.4 px below P1's` |
| присід без X | `X on crouch false` |
| стік лишився на присіді | `pad d1 axis1 +1 on both p2_crouch and p2_down` |
| MODE не зберігає | `saved <null>` |

## Відомо / не перевірено

- Інтерполяцію рендера headless-smoke **не міряє**: у ньому один такт на кадр. Плавність на 120 Гц — лише очима Santos на Mac.
- Нижня підказка в меню показує розкладку VERSUS (`hint_text(false)`, як і раніше).
- Rollover клавіатури на Mac у SHARED (ADR-014 § Чим платимо) — не перевірено.
- Тряска на удар (ADR-015 п. 5) не змінювалась.

## Запуск 6 — що перевірити (Santos)

`make update BRANCH=claude/friendly-ritchie-3ti2sm && make run`:
1. Меню: рядок **MODE** під KEYBOARD. ←/→ або Enter перемикає 2.5D ↔ 3D, нижня підказка змінюється. Закрий гру й запусти знову — вибір той самий.
2. FIGHT у 3D: камера **за спиною** Choko, Skea видно над плечем. W — до суперника, S — від нього, A/D — обхід. Space — стрибок, X — присід.
   Обійди Skea по колу: камера має повертатись плавно, без ривків на старті й зупинці.
3. VERSUS у 3D: спільна камера **збоку**, теж плавна. P2: стрілки, `/` — стрибок, M — присід.
4. Геймпад, якщо є: стік ↑/↓ — обхід, D-pad ↓ — присід.

## Related
- [[2026-10-03-Path-to-First-Fight]] · [[ADR-014-Free-Movement-Layout]] · [[ADR-015-Solo-Camera-Behind-Fighter]] · [[06-UI-UX]] ·
  [[05-Platforms-Input]] · [[02-Combat-System]] · [[2026-10-03-launch-5-heroes]] · [[2026-10-03-crystal-ult-look]] · [[state]]
