# Трос у місті: перехожі, заголовок ROPE CLIMB, справжній ввід і геймпад у гардах — журнал виконання

**Дата:** 2026-10-15 · **Роль:** T2 Гефест (T2-П) · **Статус:** зроблено в дереві без коміту (§ «Де зупинився»):
`make check` і `make gates` — rc 0; підмножини батареї 218 / 0; дуель біт у біт. Мерж — Santos.
**Задача:** ТЗ 1–7 сторінки приймання T8 [[2026-10-15-T8-Rope-Climb-Input-Acceptance]] (вердикт YELLOW, RED немає).
Продовження кроку 5 (15а) плану [[2026-10-15-Rope-Climb-Perch-Release]]; попередні журнали — [[2026-10-15-Rope-Climb-City-Fix]]
(T2-И, T2-Л) і [[2026-10-15-Rope-Perch-Entry-Fix]] (T2-М). 0 кредитів.

Дерево — scratchpad `t2p-tree`: `93ba633` + індексоване зведення хвилі 15а (T2-К, T2-И, T2-Л, T2-О, T2-М, документи T4,
T6, T8). Індекс не чіпаю, не комічу, не пушу. Godot `4.7.stable.official.5b4e0cb0f` (`$GODOT_BIN --version`). Сирі логи —
scratchpad `t2p/` (далі `П/`). «До» — знімок `П/base-tree/` (`cp -a game tools Makefile` до першої правки); кеш імпорту
скопійовано з `t15-tree` (`diff -rq --exclude=.godot t15-tree/game/assets t2p-tree/game/assets` → порожньо, rc 0).
Стан індексу на старті: `git status --short | wc -l` → 72, усі рядки `A ` / `M ` (`П/git_status_start.txt`).

## 0. Звірка ТЗ із кодом дерева

| твердження ТЗ T8 | де | що в коді дерева |
|---|---|---|
| ТЗ 1: `CityEventDirector.can_talk_to` (`:225`) не дивиться на трос | `grep -n "func can_talk_to" game/scripts/world/CityEventDirector.gd` → `225` | ✓ лише висота, відстань, лінія (`:225–231`) |
| розмову з перехожим відкривають три випадки через `can_talk_to` | `grep -rn "can_talk_to" game/scripts` | ✓ `CityAlleyEvent.gd:174`, `CityLeavesEvent.gd:113`, `CityVendorEvent.gd:116`; G відкриває меню лише при `prompt.visible` (`:176–178`, `:117–120`, `:120–123`) |
| `events.spawn_passerby` є | `CityEventDirector.gd:234` | ✓ |
| ТЗ 2: `ComfortPanel.ROPE_CLIMB_TITLE` (`:52`) = `"ROPE CLIMB"` | `grep -n ROPE_CLIMB_TITLE game/scripts/ui/ComfortPanel.gd` → `52`, `175` | ✓; заголовок у гардах ніхто не читає (`grep -rn "ROPE_CLIMB_TITLE\|\"ROPE CLIMB\"" tools` → порожньо) |
| ТЗ 3: `_comfort_row` шле `item_selected.emit` (T8: `:601–619`) | `rope_climb_check.gd:945–964` | ✓ `row.item_selected.emit(1)` `:957`, `(0)` `:960` — дрейф рядків |
| ТЗ 3: негатив як `drugs_row` | `tools/fx/blood_content_check.gd:271–273` | ✓ від'єднує всі `item_selected` рядка; `blood-content-negative-drugs_row` — у списку без родини (`playable_unfamilied_negatives.txt:19`), мій новий негатив туди не йде |
| ТЗ 4: P3 (Y + X) уже додав T2-М | `rope_climb_check.gd:862–885` | ✓ Y + X 20 тиків — L не змінилась, DASH немає; контроль X 20 тиків — спуск > 0,5 м. Родина `pad`. Не дублюю |
| ТЗ 4: інших подій геймпада в гарді немає | `grep -n "JOY_" tools/grapple/rope_climb_check.gd` | ✓ лише `X`, `Y` у P3 (`:868–882`) |
| ТЗ 5: канарки N2 немає | `grep -n "rope_buffer" tools` → порожньо | ✓; P7 — `rope_climb_check.gd:838–861`, родина `dodge` |
| такт троса забирає буфер `dodge` і `dash` | `CityFighter.gd:120–123` | ✓ `InputRouter.buffered(…, "dodge")`, `(…, "dash")` — у рядку коду, без методу, який мутант міг би перекрити |
| ТЗ 6: `_tick_perch` буфер `dash` не забирає | `CityFighter.gd:232–265` | ✓ |
| ТЗ 7: P5 у `traversal_check` без `denied` | `traversal_check.gd:421`; `HarpoonAim.REASONS` `:22`; `GrappleHook.denied` `:11`, `_deny` `:549–552`, `retarget` → `_deny` `:366` | ✓ рядок «a target shown 3 ticks ago» перевіряє лише, що висить |
| нові імена мутацій вільні | `grep -n "rope_buffer\|pad_dash\|passerby\|rope_row" tools/grapple/*.gd tools/gates/playable_check.sh` → порожньо | ✓ |
| зонди T8 | scratchpad `t8r/probe/t8_rope_probe.gd` (500 рядків), `t8_rope_probe2.gd` | ✓ беру з них подачу подій геймпада і F1–F4 |

Звірка пройдена, розбіжностей, що повертали б ТЗ Дедалу, немає (лише дрейф номерів рядків).

## 1. Що змінено в продукті (`game/`)

| ТЗ | файл | правка |
|---|---|---|
| 1 | `game/scripts/world/CityEventDirector.gd` | `can_talk_to` = `not talk_blocked() and in_talk_reach(p)`; `talk_blocked()` → `player.grapple.busy()` (на тросі, на звисі, під час змотування — те саме правило, що в `CityNpcDirector.can_talk` для мешканців); `in_talk_reach()` — старе тіло `can_talk_to` дослівно. Одна правка закриває провулок, «П'ять листків» і ятку: їхній G відкриває меню лише при `prompt.visible`, а підказка йде через `can_talk_to` |
| 1 (обв'язка негативу) | `game/scripts/world/CityWorld.gd` | `var events_script: Script = CityEventDirector`, `events = events_script.new()` — шов для фікстури, як наявний `fighter_script`; у грі завжди `CityEventDirector` |
| 2 | `game/scripts/ui/ComfortPanel.gd` | `ROPE_CLIMB_TITLE := "ROPE CLIMB · CITY ONLY"` (С2 T8) |
| 5, 6 | `game/scripts/world/CityFighter.gd` | рядки, якими такт троса забирав буфери `dodge` / `dash`, винесено в `_take_rope_presses(on_arm)` (поведінка троса та сама); `_tick_perch` першим рядком кличе `_take_rope_presses(true)` — на звисі забирається лише `dash` (ухилення зі звису лишається) |

Дуель цих місць не торкається: `CityEventDirector`, `CityWorld`, `CityFighter` — лише місто; у `ComfortPanel` змінено текст однієї мітки.

## 2. Гарди і негативи (`tools/`)

Предмет: для всіх натисків, що на тросі чи звисі нічого не означають (`dodge` на тросі, `dash` на тросі й звисі): після
відпускання вони не спрацьовують, а свіжий натиск після відпускання — спрацьовує.
Предмет: для всіх перехожих випадків у межах розмови: розмова недоступна, поки гак зайнятий, і доступна на землі з вільним гаком.
Предмет: для рядка ROPE CLIMB: справжні клавіші й геймпад змінюють режим і `settings.cfg`, заголовок — літерал T8.

`tools/grapple/rope_climb_check.gd` (`--part=rules`):
- **P3 (T2-М) розширено, не продубльовано:** перед ним — A утримано 10 тиків → L спадає > 0,3 м; під час X 20 тиків —
  DASH немає (родина `pad`). Сам P3 (Y + X) без змін.
- **`_pad_rows` (ТЗ 4):** на тросі L3, Y + LT (порожній запас, `aim.ticks_since_target() ≥ 15` як передумова) і B —
  відпускає (`phase 0`, `JUMP`); на звисі B і D-pad ↓ — падіння, X — ухилення (DASH), A + стік — стрибок 6,8 / 7,4 —
  родина `pad`; LShift на звисі — ухилення, родина `grip`.
- **`_perch_dash` (ТЗ 6, лише Skea):** LAlt і Y + X на звисі, за 2 тики B — DASH 8 тиків немає; контроль — свіжий LAlt після
  падіння дає flash. Родина `perch_dash`.
- **`_passerby` — P10b (ТЗ 1):** перехожий (`events.spawn_passerby`) поруч із героєм, що висить, — передумова
  `in_talk_reach` = true, `can_talk_to` = false; випадок «П'ять листків» (фікстура стартує його `events.start`) з
  перехожим у фазі `offer` поруч — підказка прихована, справжній G меню не відкриває; під час змотування — `can_talk_to` =
  false; після змотування той самий перехожий поруч — true (контроль). Родина `talk`. Стоїть перед P10, бо P10 зводить
  мешканців до якоря 3 (передумова `npc_director.find_nearest() < 0`).
- **`_comfort_row` (ТЗ 2–3):** пауза → фокус на COMFORT → Enter → панель, фокус на MASTER; мітка перед `RopeClimb` =
  `ROPE CLIMB · CITY ONLY`; 7 × ↓ → фокус на `RopeClimb`; Enter, ↓, Enter → `rope_climb == "toggle"`, `selected 1`,
  `[input] rope_climb = toggle` у `user://settings.cfg`; на геймпаді A, D-pad ↑, A → `hold`. Байти `settings.cfg` зберігаються
  до першого натиску і повертаються (або файл видаляється, якщо його не було) — перевірка `count`.
- **P13 з гліфами геймпада:** другий прохід — лазіння до звису з утриманим A і спуск X до підлоги; кожен рядок
  `ROPE`/`ANCHOR`/`CLIMBING`/`Reel in` ≤ 1552 px, і показано рядки з `A / Cross` (трос, звис) та
  `Y / Triangle + D-pad Down` (змотування).
- `_key` ставить `KEY_LOCATION_LEFT` і для `KEY_ALT` (так його чекає профіль SOLO).

`tools/grapple/traversal_check.gd` — **P5 (ТЗ 7):** у рядках «a target shown 3 / 14 ticks ago» натиск, що лишає героя
на тросі, дає рівно один `GrappleHook.denied` з кодом із `HarpoonAim.REASONS`. Родина `denied`.

Мутанти (`--break=`):

| мутація | де | що ламає | родина |
|---|---|---|---|
| `rope_buffer` (N2) | `rope_climb_fighter.gd` `_take_rope_presses` | такт троса не забирає буфер `dodge` | `dodge` (P7) |
| `perch_flash` | там само | звис не забирає буфер `dash` (код до правки) | `perch_dash` |
| `pad_dash` | `rope_climb_fighter.gd` `_climb_input` | спуск читає і `held("dash")` | `pad` (P3) |
| `passerby` | новий `rope_climb_events.gd` через `CityWorld.events_script` | `talk_blocked()` → false: `can_talk_to` = старе тіло | `talk` |
| `rope_row` | `rope_climb_check._comfort_row` | обробник `item_selected` рядка від'єднано (як `drugs_row`) | `comfort` |
| `mute_deny` | `rope_climb_mutants.gd` `_deny` | гак не надсилає `denied` | `denied` (P5) |

`tools/gates/playable_check.sh` — лише додано 6 негативів, кожен із `red=…\b<родина>\b…`; список винятків не чіпав.

## 3. Перші прогони (прямі запуски, той самий командний рядок, що в раннері, власний `XDG_DATA_HOME`)

Синтаксис: `bash tools/hooks/gd_check.sh <файл>` для 9 змінених / нових `.gd` → 9 × `rc="0"`.

**Позитиви** (`П/r1/`, `--quit-after 40000`, щоб побачити кадри; раннер дає 12000 і 180 с):

| прогін | вихід | кадри / с |
|---|---|---|
| база `П/base-tree`, rules Skea | `checks=92 failures=0 … red=none`, rc 0 | 5342 / 20 |
| нове дерево, rules Skea | `checks=138 failures=0 … red=none`, rc 0 | 7060 / 25 |
| нове дерево, rules Choko | `checks=135 failures=0 … red=none`, rc 0 | 6765 / 30 |
| нове дерево, `traversal_check` | `TRAVERSAL_FAMILIES failures=0 mutation=none red=none`, `checks=85 failures=0`, rc 0 | — |

Запас до межі раннера: 7060 з 12000 кадрів, 30 з 180 с. P5: обидва рядки вікна дають `denied ["none"]` (HUD: `NO ANCHOR IN REACH`).
P13 з гліфами (`grep "pad width" П/r1/new-rules-skea.log`): найширший — 989 px,
`ANCHOR · Grip 2.8s · A / Cross + move: leap · Y / Triangle + LT / L2 / L3: next anchor · B / Circle (while hanging): drop`
(те саме число, що в зонді T8); рядок троса 777 px, змотування 443 px — усі ≤ 1552.

**Нові гарди на продукті ДО правки** (`П/mixed-tree` = `game` бази + `tools` нового дерева, rules Skea):
`checks=129 failures=3 … red=comfort,perch_dash`, rc 1:
- `[perch_dash] LAlt on the grip, B 2 ticks later: … dashed true` і те саме для `Y + X` — дефект B5 зонда T8 відтворено гардом;
- `[comfort] the row's title is «ROPE CLIMB · CITY ONLY» («ROPE CLIMB»)`;
- P10b на базі не виконується (`Nonexistent function 'in_talk_reach'` — метод нового продукту); старе тіло `can_talk_to`
  перевіряє мутант `passerby`.

**Негативи** (`П/neg_run.sh`, `П/neg1/`):

| мутація | вихід | червоні рядки |
|---|---|---|
| `rope_buffer` | `failures=1 … red=dodge`, rc 1 | P7: `dashed true, still in the air true` |
| `perch_flash` | `failures=2 … red=perch_dash`, rc 1 | LAlt і Y + X: `dashed true` |
| `pad_dash` | `failures=1 … red=pad`, rc 1 | P3: `L 4.8167 → 5.3833, phase 0` |
| `passerby` | `failures=3 … red=talk`, rc 1 | висить; підказка листків `true` і G відкрив меню `true`; змотування |
| `rope_row` | `failures=2 … red=comfort`, rc 1 | Enter · ↓ · Enter: `InputRouter hold, the row 1, settings.cfg File not found`; геймпад так само |
| `mute_deny` | `TRAVERSAL_FAMILIES failures=2 mutation=mute_deny red=denied`, rc 1 | обидва рядки вікна: `denied []` |

Кожен негатив червоніє рівно своєю родиною; жоден не зачепив чужу.

**Помилка, яку я впіймав сам:** перша версія P5 називала `HarpoonAim.REASONS` прямо в `traversal_check.gd`. Хук
`gd_check.sh` дав «OK» (він фільтрує `Identifier not found: <автолоад>`), але при запуску `--script` клас компілюється до
автолоадів: `SCRIPT ERROR: Compile Error: Identifier not found: InputRouter (HarpoonAim.gd:57)`, і **весь** `traversal_check`
не завантажився — rc 0 без жодного рядка-сентинела (`П/neg1/mute_deny.log`, перший запуск). Тепер `REASONS` читаються під час
виконання (`load(…HarpoonAim.gd).get_script_constant_map()`); позитив і `mute_deny` переміряні (таблиці вище).

## 4. Батарея-підмножина (тіло раннера дослівно)

`run_subset.py` (scratchpad `battery-w14s/`), `SHARD=i/3`, логи `П/sub1/playable/`, запуск `П/sub_run.sh`.

**Підмножина 1** — змінені й нові кейси та все, що відкриває COMFORT або говорить із перехожими:
`ONLY='(rope-climb.*|traversal.*|blood-content.*|comfort-ui.*|city-controls.*|city-alley.*|city-leaves.*|city-event-.*|city-substances.*|city-thirst.*|item-icons.*|conversation-camera|colour-switch|comfort-settings|graphics-ui)'`
(`П/sub1/only.txt`), 19:46–20:03 UTC → `PLAYABLE CHECK: 42 / 42 / 41 scenarios, 0 failures`, rc 0 / 0 / 0 — **125 / 0**.
Правило раннера нових негативів не відмовило: `PLAYABLE FAMILIES: 342 negatives in the battery, 156 of them without a family
and listed (ceiling 156); canary 12/12 forms as expected` — стеля та сама, 156.

| кейс | сентинел |
|---|---|
| `rope-climb-rules-choko` / `-skea` | `checks=135` / `138 failures=0 … red=none` |
| `rope-climb-1…5` | `anchors=10/10 perched=10 blocked=0 red=none` кожна |
| `rope-climb-duel` | `checks=7 failures=0 … red=none` |
| `comfort-ui` (MASTER на місці) | `COMFORT_UI PASS (0 failures; mutation=)` |
| `blood-content` (кільце фокусу) | `checks=75 failures=0` |
| `city-controls` | `checks=48 failures=0` |
| `traversal` | `checks=85 failures=0` |
| `city-leaves` / `city-alley` / `city-event-menus` / `city-substances` / `city-thirst` / `item-icons` | `35` / `45` / `28` / `115` / `103` / `63`, усі `failures=0` |
| 6 нових негативів | ті самі родини, що в § 3 (`dodge`, `perch_dash`, `pad`, `talk`, `comfort`, `denied`) |

**Скан логів** (`python3 П/scan.py П/sub1`): 125 кейсів — 24 з rc 0, 101 негатив. У позитивах `SCRIPT ERROR` 0, `ERROR:` 0,
`warning` (без регістру) 0, `leaked` 0, `still in use` 0. У негативах `SCRIPT ERROR` 0, `warning` 0, витоків 0; `ERROR:` 479
у 101 лозі — навмисні, раннер звіряє їхні префікси (усі PASS).

**Підмножина 2** — решта кейсів, де ходить міський трос `CityFighter` (виніс рядків у `_take_rope_presses`), COMFORT і
місто: `ONLY='(rope-pull.*|rope-choice.*|rope-transfer.*|weighted-swing.*|rope-contact|rope-recovery|rope-visual|display-auto.*|colour-switch.*|auto-hook.*|lethal-fight|city-tidy|city-perch|parkour-.*|harpoon.*|city-runtime|city-camera|npc-close|district-life)'`
(`П/sub2_only.txt`), 20:05–20:11 UTC → `PLAYABLE CHECK: 31 / 31 / 31 scenarios, 0 failures`, rc 0 / 0 / 0 — **93 / 0**.
Скан (`python3 П/scan.py П/sub2`): 39 позитивів, 54 негативи; `SCRIPT ERROR` 0, `leaked` 0, `still in use` 0 скрізь;
`warning` — 1, у позитиві `parkour-moves`: `WARNING: Jolt Physics job system exceeded the maximum number of jobs` (клас 15,
під навантаженням 3 шардів). Той самий кейс сам-один двічі (`П/solo/parkour{1,2}.out`) → `1 scenarios, 0 failures`, `warning`
0 / 0. `parkour-moves` звису й троса не торкається.

Разом **218 / 0** (125 + 93). Повну батарею не ганяв — її запускає T1.

## 5. Дуель біт у біт

`П/duel_run.sh` = скрипт T2-М (`t2m/duel_run.sh`, лише тека логів інша): smoke, зонд T3 `t2i/probe/duel_rope_probe.gd` ×
(Choko, Skea) × (SOLO, SHARED), 38 дуельних кейсів батареї. База — `П/base-tree`, «після» — `П/after-tree` = `game` мого
дерева (`diff -rq --exclude=.godot t2p-tree/game П/after-tree/game` → порожньо, rc 0) + `tools` і `Makefile` бази.

| що | вихід (`П/duel/base`, `П/duel/after`) |
|---|---|
| усі прогони | `rc=0` (`rc.txt` обох, 6 / 6) |
| smoke | `[smoke] ALL OK (165 checks) in 19847 frames` обидва, `cmp` → однакові |
| 38 логів батареї | `PLAYABLE CHECK: 38 scenarios, 0 failures` обидва; `cmp` після заміни шляху дерева → 38 / 38 однакові |
| зонд × 4 | `cmp` → 3 однакові; `duel_skea_solo`: рядки 1–20 (усі виміри) однакові, у **бази** на виході `4 ObjectDB instances were leaked` / `2 resources still in use` |

Витік на виході зонда — не від правки: повтор Skea SOLO по 3 рази на кожному дереві (`П/duel/rerun/`) — рядки 1–20 однакові в
усіх шести прогонах і з першим прогоном бази; витік на виході — база 1 з 3, «після» 2 з 3 (разом з першими прогонами — 2 з 4
кожне). Зонд T3 — не гейт; в усіх 38 кейсах батареї витоків 0.

## 6. `make check`, `make gates`

Після останньої правки коду (`find game tools Makefile -newer П/sub1/started.txt -type f -not -path "game/.godot/*"` →
порожньо), на дереві без інших процесів Godot (`pgrep -af Godot_v4.7` → 0):
- `GODOT_BIN=… make check` → rc 0: `перевірено: 144 · не парсяться: 0 · не виміряно: 0 · канарка: FAIL як треба`,
  `[smoke] ALL OK (165 checks) in 19847 frames`, `SMOKE ЗЕЛЕНИЙ` (`П/make_check_final.log`);
- `GODOT_BIN=… make gates` → rc 0, `БАТАРЕЯ ЗЕЛЕНА`: wikilinks 560 сторінок / 9413 лінків / 0 зламаних, реєстр 187 / 187,
  ролі 8 / 0, стеля негативів без родини 156 / `UNFAMILIED_CEILING 156`, GDS 144 / 0 (`П/make_gates_final.log`).
- після останніх правок цього журналу (лише документ) — `bash tools/gates/run_gates.sh --docs-only` → rc 0, 560 сторінок /
  9413 лінків / 0 зламаних, `ДОКИ ЗЕЛЕНІ; КОД НЕ ВИМІРЯНО` (`П/gates_docs_final.log`); код після `make gates` не мінявся.

## Відкрите

Для T8:
1. [[06-UI-UX]] `:166–167` каже «доки T2 не змінить константу, у коді стоїть `ROPE CLIMB`» — після цієї правки рядок застарів
   (сторінка T8, я її не правлю).
2. Справжній G при підказці перевірено на випадку «П'ять листків». Провулок і ятка йдуть через той самий `can_talk_to`
   (`CityAlleyEvent.gd:174`, `CityVendorEvent.gd:116`); окремого гарда справжнім G для них немає.
3. P5 перевіряє сигнал `denied` і код причини; що HUD показав рядок `HOOK_REASONS`, `traversal_check` (без HUD) не бачить —
   ТЗ 7 цього й не просило.
4. `settings.cfg`, що не читається, і далі без статусу помилки в COMFORT (кандидат T8 «наступний захід»), не робив.

Для T1 / T4:
5. `CityWorld.events_script` — новий шов для фікстур (за зразком `fighter_script`); у грі завжди `CityEventDirector`.
6. Гард «звис забирає `dash`» — лише Skea: у Choko dash у повітрі є тільки зі «Spring» (`Fighter.gd:717`), тож для нього
   перевірка нічого б не розрізняла.
7. `state.md` не правлю (паралельні дерева); рядок пропоную T1 у звіті.

## Де зупинився

Готово до приймання T1 / T8, не закомічено, індекс не чіпав. `git status --short` у `t2p-tree`, фінальний
(`П/git_status_final.txt`, 75 рядків; 72 рядки індексу `A ` / `M ` — ті самі, що на старті, згорнуто):

```
A  / M  … (72 рядки індексу хвилі 15а, без змін)
MM game/scripts/ui/ComfortPanel.gd
 M game/scripts/world/CityEventDirector.gd
MM game/scripts/world/CityFighter.gd
MM game/scripts/world/CityWorld.gd
MM tools/gates/playable_check.sh
AM tools/grapple/rope_climb_check.gd
AM tools/grapple/rope_climb_fighter.gd
AM tools/grapple/rope_climb_mutants.gd
MM tools/grapple/traversal_check.gd
?? docs/Fix/2026-10-15-Rope-Input-Acceptance-Fix.md
?? tools/grapple/rope_climb_events.gd
```

Друга літера (`M` у другому стовпці, `??`) — мої зміни поверх індексу; `git diff --stat` → 9 файлів, +474 / −24. Нові файли
для `git add -N`: цей журнал і `tools/grapple/rope_climb_events.gd`.

## Related
- [[2026-10-15-T8-Rope-Climb-Input-Acceptance]] · [[2026-10-15-Rope-Climb-Input]] · [[2026-10-15-Rope-Climb-City-Fix]]
- [[2026-10-15-Rope-Perch-Entry-Fix]] · [[2026-10-15-Rope-Climb-Perch-Release]] · [[ADR-028-Rope-Climb-Perch-And-Retrieval]]
- [[06-UI-UX]] · [[recurring_class_register]] · [[state]] · [[constitution]]
