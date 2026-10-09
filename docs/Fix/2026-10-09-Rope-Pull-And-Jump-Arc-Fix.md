# Трос тягне героя (V4) і стрибок однією дугою (С2) — реалізація

**Дата:** 2026-10-09 · **Роль:** T2 Гефест · **Статус:** крок 1 виконано, зелений; крок 2 виконано на числах T5, але
гард G4 і чинна `living_body_check` червоні на числах С4 посадок — **повернуто T1 / T5 на рішення** (§ 2.4).
**Зведення 2026-10-09:** T1 обрав варіант B, обидва кейси зелені; власний стовп якоря більше не рве мотузку — § «Зведення
2026-10-09».
Кроки 1–2 плану [[2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum]], числа T5 [[2026-10-09-Rope-Pull-And-Jump-Arc-Numbers]],
діагностика [[2026-10-08-Rope-Swing-And-Jump-Fix]]. Ізольований worktree; не комічу й не пушу, diff забирає T1; кредитів
не витрачаю. Godot `4.7.stable.official.5b4e0cb0f` (`godot --version`).

Слова Santos (M3, клавіатура й миша): «Гак чіпляється, але не тягне», про стрибок — «Смикається», «Поза дивна».

## 0. Звірка

- Worktree стояв на `d3bfcd4`, а не на `97675c7` із завдання (`git rev-parse HEAD`). `git log d3bfcd4..97675c7` — 3 коміти,
  `git diff --stat d3bfcd4 97675c7` — лише `docs/` (16 файлів, `game/` не зачеплено). Зробив `git merge --ff-only 97675c7`.
- Сторінку T5 скопіював з основного дерева: `sha256sum` обох копій — `f1c62a8c…` однаковий.
- Рядки плану звірив: `GrappleHook.gd:62-63` (`reel_distance` 1.2, `minimum_rope` 2.0), `:199-203` (`reel_remaining`),
  `:519-523` (довжина на контакті), `AuthoredHookMotion.gd:98-101` (цикл перебирання), `CityHud.gd:1191`,
  `LivingBodyMotion.gd:65` (`MODE_BLEND`), `:317-322` (апекс за `APEX_SPEED`). Розбіжностей із планом немає.

## 1. Трос V4

**Що зроблено** (`game/scripts/grapple/GrappleHook.gd`):
- `_swing_length(contact)` — Т3/Т4: `min(L0, max(minimum_rope, y_якоря − y_опори − HAND.y − 0.5))`, де `y_опори` —
  вища з двох: промінь униз від якоря і промінь униз від ніг героя в мить зачепу (шар 1, без тіла й hurtbox). Немає
  опори під жодним — тяги немає. Порядок `min`/`max` замість `clampf` прототипу: за `L0 < 2` ціль = `L0`, не 2.
- Лише `_responsive_traversal()` (місто, `grapple_parkour`, не ворог). Ціль пишеться в `_hang_start_length`, тож
  `reel_remaining()` без змін формули рахує Space від довжини після тяги (Т5), а дуель має там `L0`, як раніше.
- `drive()` — Т7: `rope_length -= max(тяга, Space)`, тяга 8 м/с до цілі, Space 3.6 м/с до `max(2, ціль − 1.2)`.
  Числа `parkour_pull_speed` 8.0 і `parkour_swing_clearance` 0.5 — `@export`, PLACEHOLDER T5.
- `pulling` (лише читання): `AuthoredHookMotion` не крутить цикл перебирання від тяги і малює звис
  (`source_phase` `pull`); перебирання лише від Space понад тягу.
- HUD `CityHud.gd:1191`: `ROPE · Pulling you up` / `ROPE · Steer to swing` + `Hold <jump> to reel higher`; `REEL LIMIT`
  без змін. Контракт — [[04-Grapple-System]] § «Трос V4».

**Відкрите питання T5 — якір `(−24; 6,8; 10,6)`, ціль 7,39 замість 5,05.** Промінь тут ні до чого: униз від якоря він
влучає в `CityDistrict/Ground` на y 0,00, ціль 5,05 правильна (`pull_trace.gd`, `PULL_TRACE … settled=5.050
under_anchor=/root/CityWorld/CityDistrict/Ground@(-24.00,0.00,10.60)`). 7,39 = 7,52 − 8/60: тяга відпрацювала один тик, і
гак відпустило, бо лінія рука → якір торкнулась `CityInteriors/ShopAwning` у точці `(−26,74; 3,76; 11,09)` (`T 000 ph=0
… los1=…/ShopAwning@(-26.74,3.76,11.09)`). На HEAD той самий натиск теж закінчується без звису (`still_HEAD_choko.log`:
`still_hang=false`, `L_end=7.52`): лінія вибору пролягає впритул до тенту.

**Числа до / після** (Choko; Skea — ті самі, капсула однакова):

| сценарій | до (`97675c7`) | після (V4) | команда |
|---|---|---|---|
| з місця `(0;0;9,5)`, тап E, якір `(8;6,5;8)`: зсув / підйом / тиків у повітрі зі 127 | 0,05 м / 0,00 м / 0 | 8,80 м / 0,99 м / 126 | `impl/trace_pair.sh` → `trace_{H97675c7,V4}_choko.log` |
| те саме + W | 5,80 / 0,00 / 0 | 10,69 / 1,20 / 126 | там само, `kb_tap_fwd` |
| те саме + Space | 2,48 / 0,10 / 14 | 8,98 / 1,79 / 126 | там само, `kb_tap_reel` |
| маршрут P11, у повітрі ≥ 20 тиків із 90 | 2/18 · 3/19 (T2, 2026-10-08) | 17/18 · 18/19 | `impl/still_pair.sh v4` → `ROUTE_SUMMARY` |
| маршрут P11, мотузка дійшла до `L_ціль` і в повітрі ≥ пів періоду | — | 12/18 · 14/19, решта 6 · 5 обірвані геометрією | `rope_pull_check` → `ROPE_PULL route` |

Найбільший крок тіла за тик — 0,251 м (Choko) / 0,311 м (Skea) при порозі 0,3167; найбільше скорочення за тик —
0,1333 м = 8/60 (`grep -o 'max_step=…\|max_shorten=…' rope_pull_*.log`).

**Предмет:** для кожного паркурного HANG у справжньому `CityWorld` (E, W, Space; обидва герої; з місця й маршрут P11)
мотузка доходить до `L_ціль` не швидше за 8/60 м за тик, ніколи не довшає, Space додає ≤ 1,2 м (max, не сума), крок тіла
≤ 0,3167 м, і тіло ≥ пів періоду `π·√(L/g)` у повітрі, якщо тверда геометрія не перерізала лінію рука → якір.

| обіцянка | гард | негатив (форма) | результат |
|---|---|---|---|
| тягне до `L_ціль`, з місця й на маршруті | `rope_pull_check` [target], [air], [count] | `nopull` (тяга 0 = контракт HEAD) | позитив 0 провалів; `nopull` → rc=1 `red=air,target` |
| не подовжується | [lengthen] | `lengthen` (ін'єкція: мотузку відпущено на 0,3 м раз на звис) | rc=1 `red=lengthen` |
| max(тяга, Space), не сума | [rate] | `sum` (ін'єкція: Space поверх тяги) | rc=1 `red=rate` |
| без ривка (Т8) | [step] | `snap` (тяга 10⁶ м/с = V3) | rc=1 `red=rate,step` |
| звис ≠ успіх (клас 5) | `auto_hook_check` P11: тіло після HANG — мотузка дійшла до цілі, тіло відірвалось або лінію перерізано | `auto_hook --break=nopull` | позитив 233/0, `lifted` 16/18 · 18/19; `nopull` → rc=1 (63 провали) |
| продукт HEAD | обидва гарди на знімку `97675c7` | — | `rope_pull` choko / skea → rc=1 `red=air,target`; `auto_hook` → rc=1, 63 провали, усі «тіло після HANG» |
| дуель без змін | `living_body_check -- --dump` до / після | — | sha256 `68a5bd8d…` на HEAD, після кроку 1 і після кроків 1–2; `cmp` 8/8 файлів однакові |

Логи: `scratchpad/rope-jump/impl/` — `rope_pull_{choko,skea}.log`, `rope_v4_neg_*.log`, `rope_pull_HEAD_*.log`,
`auto_hook_v4.log`, `auto_hook_v4_neg_nopull.log`, `auto_hook_HEAD.log`, `duel_{HEAD,step1,step12}/`.

**Відкрите (крок 1):**
- **Власний стовп ріже мотузку.** Тепер герой справді гойдається, і дуга ліхтаря `(8;6,5;8)` / `(−8;6,5;8)` заводить
  лінію рука → якір за його ж стовп (`AnchorPost3`, `AnchorPost2`): гак відпускає через 34–71 тик. Так само карниз
  `ArchitectureSolid622` біля `(16;6,7;10,6)` і тенти `ShopAwning` / намет ринку. Це чинне правило «укриття рве мотузку»,
  не тяга; на маршруті — 6/18 (Choko) і 5/19 (Skea). Рішення T1: чи виключати опору самого якоря з перевірки лінії.
- **Намет ринку під якорем `(8,6; 6,7; 24,6)`** — тверда опора на 2,8 м, тож ціль 2,15 (Т4/Т5 «опора тверда — ціль
  правильна»). Choko тягне в край тенту і гак обривається на 47-му тику; Skea проходить (68 тиків у повітрі).
- Довідка паузи `ComfortPanel.gd:194` («Get closer beneath an anchor for lift») і `CityHud.exploration_help` — не мої
  файли, текст варто оновити T8.

## 2. Стрибок С2

**Що зроблено** (`game/scripts/fighter/LivingBodyMotion.gd`):
- С1–С3: стан `_tuck` (PENDING → ON → DONE). Після відриву з землі в кінці take-off (тик 12) рахується час до опори
  `time_to_ground()` (вгору `GRAVITY`, униз `GRAVITY × fall_gravity_mult`, промінь `floor_y` лише на читання); групування
  вмикається, якщо воно триватиме ≥ 0,28 с, і закінчується, коли до опори ≤ 0,31 с. Після відриву `rise` немає. Без
  відриву (зрив із мотузки, крок із краю) групування немає: `rise` / `fall`.
- `_fall_target` бере той самий `time_to_ground` (для падіння формула тотожна старій).
- С4: `MODE_BLEND` takeoff 0,18 · apex 0,18 · fall 0,18 · rise 0,12 · land_* 0,12. **Takeoff 0,18 — запасний варіант
  T5:** за 0,15 G3 червоний на бігу (Choko 18,9° > 17,1, Skea 22,2° > 22,1); за 0,18 — 16,0 / 18,7.
- С5: легка посадка `Jump_Land` ×6 (`LIGHT_LAND_RATE`), звичайна ×2,5.
- `mode_blend`, `light_land_rate`, `tuck_min_seconds` — змінні з тих самих констант, лише щоб гард міг повернути
  значення 2026-10-08 як негатив.
- `AuthoredLocomotion.gd` не змінював.

**Гард** `tools/animation/jump_arc_check.gd` (справжній `CityWorld`, Space і D, обидва герої, з місця, з бігу, падіння
3,5 м і 6,5 м). Значення «до» — заміри `aa51881` тим самим зондом (`impl/jump_capture2.gd`, `impl/jump_g.py`).

| гард | до `aa51881` | HEAD `97675c7` | після (С2) |
|---|---|---|---|
| G1 режими в повітрі | — | takeoff→rise→apex→fall | takeoff→apex→fall (4/4); падіння без відриву — лише fall |
| G2 тиків ≥ 15° у повітрі після відриву | 0 (макс 0,7°) | 6–10 (макс 25,3°) | **0** (макс 11,4°) |
| G3 макс на відриві, Choko біг / місце, Skea біг / місце | 17,1 / 33,4 / 22,1 / 17,2 | 41,3 / 59,9 / 49,2 / 35,1 | 16,0 / 21,1 / 18,7 / 10,0 |
| G4 ноги ≥ 15° на легкій посадці, Choko / Skea | 0 / 0 | 3 / 2 | **1 / 1** (16,1° / 16,8°, тик +2 після землі) |
| G4 найнижчий таз легкої, м | 0,717 / 0,700 | 0,474 / 0,463 | 0,791 / 0,774 |
| G4 таз легка > звичайна > важка, м | — | Choko 0,474 > 0,247 > 0,199 | **0,791 > 0,327, важка 0,409** (Skea 0,774 / 0,314 / 0,392) |
| ривок ≥ 90° на посадці | 140,3° (передпліччя Choko) | 92,1° (стегно, важка) | макс 61,3° |

Команди: `python3 -I impl/jump_g.py impl/jump_aa51881 impl/jump_HEAD impl/jump_after`; гард —
`impl/fixture.sh … jump_arc_check.gd` → `JUMP_ARC_COMPLETE checks=40 failures=4 mutation=none red=G4legs,G4order`.

Негативи: `blend` (змішування 2026-10-08) → `red=G2,G3,G4depth,G4legs,flip`; `tuck` (групування вимкнене) →
`red=G1,G4legs,G4order`; `land` (легка ×2,5) → `red=G4depth,G4legs,G4order`; продукт HEAD → rc=1
`red=G1,G2,G3,G4depth,G4legs,flip`.

**Предмет:** для стрибка з землі в справжньому `CityWorld` (обидва герої, з місця й з бігу) повітря після відриву —
рівно takeoff → apex → fall без жодного тику ≥ 15°, відрив не різкіший, ніж до `bf38d3e`, легка посадка без ривка ніг ≥ 15°
і не глибша, ніж до, а глибина росте від легкої до звичайної й важкої без перевороту кістки ≥ 90°.

### 2.4 Що червоне і чому — рішення T1 / T5

1. **G4 «ноги легкої посадки 0 тиків ≥ 15°»** — 1 тик (16,1° / 16,8°): ціль `Jump_Land` ×6 на тику +2 уже в найглибшому
   присіді, а вага змішування 0,12 с саме росте найшвидше. ×5 і ×7 не лікують (17,2 / 17,9 і 15,2 / 15,8,
   `impl/jump_exp_t18_l{5,7}`).
2. **G4 «звичайна глибша за легку, важка — за звичайну»** — важка мілкіша за звичайну: `NinjaJump_Land` ×3,8 проходить
   найглибшу точку (кліп 0,19 с) на 3-му тику, коли вага змішування 0,12 с ще ≈ 0,4. Оцінка T5 «≈ 78 % глибини» не
   справдилась.
3. **Чинна `living_body_check` (J3 / P8 «рука на землі при звичайній і важкій посадці», ≤ 0,10 м)** — тепер Choko 0,098 /
   0,198, Skea 0,116 / 0,215 (HEAD 0,053 / 0,040 і 0,076 / 0,040) → `LIVING_BODY_COMPLETE checks=61 failures=2`.

Сітка на копії дерева (`impl/exp_grid.sh`; worktree не чіпав; takeoff 0,18 скрізь), land_light / land_normal / land_heavy:

| варіант | `living_body_check` | `jump_arc_check` |
|---|---|---|
| 0,12 / 0,12 / 0,12 (T5) | 2 провали (рука) | RED G4legs, G4order |
| A 0,15 / 0,12 / 0,08 | 1 (рука Skea 0,116) | 0 |
| **B 0,15 / 0,08 / 0,06** | **0** | **0** (таз 0,847 > 0,257 > 0,235; ноги 0 тиків; макс 66,6°) |
| C 0,15 / 0,04 / 0,03 | 0 | RED flip (92,1°) |
| D 0,15 / 0,06 / 0,04 | 0 | RED flip (94,0° / 90,5°) |

Єдиний зелений із перевірених — B, але звичайна й важка коротші за «змішування ≥ 0,12 с» із плану. Числа не мої: код
лишається на С4 T5 (+ запасний takeoff 0,18); питання надіслане T1 двома повідомленнями.

## 3. Кадри

Стрибок. До: `scratchpad/rope-jump/jump_aa51881shots/`, `jump_HEADshots/` (2026-10-08). Після:
`scratchpad/rope-jump/jump_after/` (xvfb, 1280×720, `gl_compatibility`, кожен другий тик, 346 JPG, обидва герої × з місця,
з бігу, падіння 3,5 і 6,5 м). Аркуші в три ряди «до / HEAD / після» — `scratchpad/rope-jump/jump_sheets_after/`
(`impl/jump_sheet3.py`). На аркушах після: з бігу групування тримається від +14 до +26 без розгинання на +16; легка посадка
з місця — короткий присід, герой стоїть на +58 (HEAD — глибокий присід із рукою вниз на +52…+58).

Трос. `scratchpad/rope-jump/rope_after/choko_pull_t000…t064.jpg` і аркуш `choko_pull_sheet.jpg` (тап E з `(0;0;9,5)`):
герой відривається від бруківки на першому ж тику тяги (`t=23 … floor=false`), руки на мотузці (звис `Climb_Idle`), цикл перебирання 0,000 весь час тяги;
трасу кадрів — `choko_pull.txt`. Зі Space (`impl/pull_head/choko_pull_space.txt`): тяга 9,55 → 4,75 м без перебирання,
потім Space 4,75 → 3,55 м, цикл 1,849 = 1,2 / 0,65.

## 4. Батарея (на остаточному коді: С4 T5 + takeoff 0,18)

| команда | вихід |
|---|---|
| `GODOT_BIN=<godot 4.7> make check-playable` (лог `impl/check-playable1.log`, кейси `impl/playable1/`) | GDS 141 / 0, канарка FAIL як треба; `[smoke] ALL OK (165 checks) in 19847 frames`, `SMOKE ЗЕЛЕНИЙ`; **`PLAYABLE CHECK: 236 scenarios, 2 failures`** — `living-body` (рука на звичайній і важкій посадці, § 2.4 п. 3) і `jump-arc` (`red=G4legs,G4order`); make rc=2 |
| `grep -lE '^\s*(SCRIPT ERROR\|ERROR):' impl/playable1/*.log` | поза `*-negative-*` — лише `jump-arc.log` і `living-body.log` (ті самі два провали); 135 / 135 негативів |
| `grep -l 'leaked\|still in use at exit'` у позитивних логах | 0 |
| нові кейси | `rope-pull` PASS (`checks=12952 failures=0`), `auto-hook` PASS (233 / 0), негативи `rope-pull-*` 4 / 4, `auto-hook-negative-nopull`, `jump-arc-negative-*` 3 / 3 — PASS (rc=1 у своїй родині) |
| `GODOT_BIN=<godot 4.7> make gates` (лог `impl/gates1.log`) | wikilinks 8293 / 0 зламаних, реєстр 183 / 183, ролі 8 / 0, GDS 141 / 0, **`БАТАРЕЯ ЗЕЛЕНА`**, rc=0 |

**Крок 1 — готово. Крок 2 — не готово:** два кейси червоні на числах С4 посадок; варіант B із § 2.4 (одна правка
`MODE_BLEND`) на копії дерева дає обидва зелені, але це нові числа — рішення T1 / T5.

## Зведення 2026-10-09

T2 на зведеному дереві T1 (гілка `claude/t1-orchestration-2026-10-07`, три гілки T2 застейджені, не закомічені), за
розділом «Рішення T1 після кроків 1–4» плану [[2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum]]. Не комічу й не
пушу; кредитів не витрачав. Godot `4.7.stable.official.5b4e0cb0f`. Логи — scratchpad `merge-t2/` (`base_*` — зведене
дерево до моїх правок, `s*_*` — проміжні, `final_*` — остаточний код). Кожен кейс запускав тим самим кодом, що й
`playable_check.sh`: `merge-t2/run.sh` вирізає з нього список кейсів і фільтрує за іменем.

### Змішування посадки — варіант B (§ 2.4 закрито)

`LivingBodyMotion.MODE_BLEND`: land_light 0,15, land_normal 0,08, land_heavy 0,06; takeoff 0,18, режими в повітрі як
були. `jump_arc_check` → `JUMP_ARC_COMPLETE checks=40 failures=0 mutation=none red=none`. Таз легка > звичайна > важка:
Choko 0,847 > 0,257 > 0,235, Skea 0,832 > 0,246 > 0,222; ноги на легкій посадці 0 тиків ≥ 15°; найбільший поворот на
посадці 66,6° (< 90°). `living_body_check` → `LIVING_BODY_COMPLETE checks=61 failures=0`. Негативи `jump-arc-negative-*`
3/3 і `living-body-negative-*` 10/10 — `PASS rc=1`. Сітка T2 справдилась на зведеному дереві: 40/0 і 61/0.

### Опора самого якоря не рве мотузку

Як якір знає свою опору: ні `anchor_supports()`, ні `MatchRopes` про тіла опори не знають, тож `CityDistrict` тепер
кладе на маркер якоря мету `support` — масив тіл, які збудував `_anchor_support` (колайдер має лише стовп `post`,
шар 9; кронштейн, плита, підкіс і кераміка — без колайдера). `GrappleHook._support_of(точка)` на зачепі (`_flight`) і на
перезачепі (`_attach_existing`) знаходить маркер і бере RID цих тіл; `drive()` передає їх у `line_clear(…, skip)`
**лише** для перевірки рука → якір під час звису. Вибір цілі й політ гака стовп і далі бачать: інакше гак летів би в
стовп і відскакував. Якорі дуелі мети не мають — `skip` порожній.

**Предмет:** для кожного паркурного HANG у справжньому `CityWorld` (обидва герої, з місця й маршрут P11) — гак ніколи не
відпускає через стовп свого якоря, а будь-яка інша тверда геометрія на лінії рука → якір рве мотузку не пізніше
наступного тику.

Гард `rope_pull_check`: стовп фікстура знаходить сама з `CityLayout.anchor_supports()` (тіло `post` з центром на `mount`),
мету продукту не читає. Родини `own` (обрив, коли на лінії лише власний стовп; і не-порожнеча: хоча б один тик мотузка
тримала крізь свій стовп) і `cover` (два тики поспіль мотузка висить крізь інше тверде тіло).

| маршрут P11, `rope_pull_check` | до (зведене дерево, `base_rope`) | після п. 2 (`s2_rope`) | після п. 2 + п. 3 (`final_pos`) |
|---|---|---|---|
| Choko: зачепів / дійшли до `L_ціль` / обірвано | 18 / 12 / 6 | 18 / 14 / 4 | 18 / **15** / **3** |
| Skea | 19 / 14 / 5 | 19 / 16 / 3 | 19 / **16** / **3** |
| обриви через власний стовп (`AnchorPost2`, `AnchorPost3`) | Choko 2, Skea 2 | 0 / 0 | 0 / 0 |
| тиків, що мотузка тримала крізь свій стовп | — | Choko 14, Skea 8 | Choko 14, Skea 8 |

Що лишилось обірваним — укриття, як вирішив T1: карниз `ArchitectureSolid622` біля `(16; 6,7; 10,6)` (Choko), тенти
`ShopAwning` біля `(−24; 6,8; 10,6)` (обидва, двічі; один із них — уже на першому тику, бо лінія вибору впритул до
тенту, див. § 1) і тент крамниці `(−13,27; 3,76; 10,91)` (Skea). `auto_hook_check` → 234/0, `lifted` 17/18 · 18/19.

Команди: `merge-t2/run.sh <dir> 'rope-pull'`; рядки `ROPE_PULL route` і `ROPE_PULL own` у `rope-pull.log`.

### Тент над якорем `(8,6; 6,7; 24,6)` згорнутий (стан Н6 «rolled»)

`CityMarket.STALL_STATES` → `["full", "trestle", "half", "rolled"]`: ятка схід z 25 (під якорем 5). Ті самі вісім смуг
скручені в рулон Ø 0,24 м на задній жердині (лежить на ній, вище верхів стійок 3,28), три зав'язки, один колайдер
`RolledCanopy`; товар — як у повної ятки. Рамка, прилавок і стійки без змін. Промінь униз від якоря тепер іде на
бруківку: `L_ціль` 2,148 → 4,950.

| якір 5 з маршруту `(0; 0; 17,25)` | до | після |
|---|---|---|
| Choko | `target=2.148`, обрив на 47-му тику об край тенту `@StaticBody3D@1979@(7.26,2.63,25.33)`, у повітрі 46 | `target=4.950`, дійшла на 46-му тику, у повітрі 86/86, обриву немає |
| Skea | `target=2.148`, у повітрі 68/57 | `target=4.950`, у повітрі 86/86 |

### Довідки

`CityHud.exploration_help`: рядки «Move … · Jump: Space / A», «Hook (finite): tap E / L3 (or Y + LT), marked anchor only ·
it pulls you up to swing height», «On the rope: move to swing · hold jump to reel 1.2 m higher · tap hook to transfer».
Рядків так само 11: пауза на 1600×900 мала 6 px запасу (`merge-t2/probe/pause_probe.gd`: `lines=11`, найширший рядок
910 px проти 917 до правки, низ кнопки виходу 894). Тому «Reuse rope within 0.70m of hand» перейшло в COMFORT &
CONTROLS: «A rope cue means grab the deployed rope within 0.70 m of your hand». `ComfortPanel.gd:194`: «In the city
the parkour hook pulls you up to swing height by itself; in a duel it does not, so hook from beneath an anchor for
lift. / Hold jump to reel in up to 1.2 m further; move to steer the swing.» Рядок «Hold jump to reel in», який читає
smoke, лишився. Нові символи — лише ASCII і «·», `glyph_coverage_check` зелений. Слова — T8 перевірить.

Гард `rope_pull_check`, родина `help`: пауза і COMFORT, як їх бачить гравець (мітки в дереві), кажуть «pulls you up» і
«1.2 m» (Т5), і жодна не тримає старого «Get closer beneath an anchor» / «distant ropes pull toward it».

| правка | гард | негатив (форма) | результат |
|---|---|---|---|
| `MODE_BLEND` варіант B | `jump_arc_check` G1–G4; `living_body_check` | `jump-arc-negative-blend/tuck/land`; 10 негативів `living-body` | 40/0, 61/0; негативи 13/13 `PASS rc=1` |
| власний стовп поза перевіркою звису (`GrappleHook`, `CityDistrict`) | `rope_pull_check` `own`, `cover` | `own` (мети немає = код до п. 2), `wrong` (мета показує стовп сусіднього ліхтаря), `wide` (мета розширена до всіх тіл у 6 м) | позитив 17086/0; `own`, `wrong` → `red` з `own`; `wide` → `red` з `cover`; усі `PASS rc=1` |
| тент якоря 5 згорнутий (`CityMarket`) | `rope_pull_check` (якір 5 без обриву); `city_tidy_check` K anchor 5 | `city-tidy-negative-anchor` (бочка під якорем 2), решта 25 негативів `city-tidy` | 171/0; 26/26 `PASS rc=1` |
| довідки (`CityHud`, `ComfortPanel`) | `rope_pull_check` `help`; `city_onboarding_check`, `city_controls_check`, `comfort_ui_check`, smoke | `help_nopull` (тяги немає в паузі), `help_reel` («2 m»), `help_lift` (стара обіцянка) | 72/0, 48/0, `COMFORT_UI PASS`; негативи 3/3 `PASS rc=1` |

### Перевірка (остаточний код зведеного дерева)

| команда | вихід |
|---|---|
| `living_body_check -- --dump` (`merge-t2/dump_duel.sh final`) проти `rope-jump/impl/duel_HEAD/` | `identical=8 different=0`; sha256 `a3b963487086876f…` (choko_skea on/off), `84b63712d0ed7740…` (skea_choko on/off) — дуель і VERSUS біт у біт |
| позитиви 32 кейси (`merge-t2/final_pos`) | `PLAYABLE CHECK: 32 scenarios, 0 failures`; `ERROR:` у позитивних логах — 0, `leaked` — 0 |
| негативи 97 кейсів (`final_neg`, `final_neg2`, `final_neg3`) | 37 + 33 + 27 `PASS rc=1`, `FAIL` — 0; у кожному негативному лозі є рядок `ERROR:` свого префікса |
| `GODOT_BIN=<godot 4.7> make check` | rc=0: імпорт rc0; GDS `перевірено: 143 · не парсяться: 0 · канарка: FAIL як треба`; `[smoke] ALL OK (165 checks) in 19847 frames`, `SMOKE ЗЕЛЕНИЙ` |
| `GODOT_BIN=<godot 4.7> make gates` | rc=0: wikilinks 515 сторінок / 8417 лінків / 0 зламаних, реєстр 183 / 183, ролі 0 проблем, R8 44 плани, GDS 143 / 0, `БАТАРЕЯ ЗЕЛЕНА` |

Повну `make check-playable` не запускав — її запускає T1 після мене.

**Відкрите після зведення:**
- кадри згорнутого тенту й нових рядків довідки — T6 / T8 (не знімав);
- дві обірвані лінії біля `(−24; 6,8; 10,6)` лишаються: тент `ShopAwning` на першому тику (лінія вибору впритул) — правило
  укриття, як вирішив T1; чи прибирати цей тент — питання T1 / T6;
- ятка під якорем 5 без розгорнутого тенту: як гойдання виглядає поруч зі стійками й прилавком — на очі T6 (числа
  лише кажуть, що мотузка не обривається і герой 86/86 тиків у повітрі).

## Related
- [[2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum]] · [[2026-10-09-Rope-Pull-And-Jump-Arc-Numbers]] · [[2026-10-08-Rope-Swing-And-Jump-Fix]]
- [[04-Grapple-System]] · [[2026-10-07-Living-Body]] · [[2026-10-07-Living-Body-Fix]] · [[recurring_class_register]] · [[state]]
