# Повторний аудит хвилі 15а — трос у місті після T2-Л … T2-Р

**Дата:** 2026-10-15 · **Роль:** T4 Феміда (вердикт подано текстом; інструменти лише для читання) ·
**Попередній вердикт:** [[2026-10-15-Rope-Climb-15a-Review]] — RED.
**Предмет:** дерево scratchpad `t4d-tree`: detached `93ba633` + індекс. `git status --short` → 84 рядки (52 `A`, 32 `M`), лише
індексовані зміни. Джерела = дерево фінальної батареї T1: `sha256sum` по `git ls-files -co --exclude-standard -z game tools
Makefile` → 951 рядок, `diff` з `battery-w15b/src.before` порожній — і на старті, і після всіх моїх прогонів;
`cmp src.before src.after` → однакові. Логи, мутанти, скрипти — scratchpad `t4-w15b/` (далі `Ф/`). Мутанти — лише в копіях
`Ф/mut-tree`, `Ф/mut-tree2`, `Ф/mut-tree3`; `t4d-tree` не змінювала. Кейси ганяла командним рядком батареї (`Ф/bin/mrun.sh`,
аргументи — з `cases` раннера, `Ф/bin/casecmd.py`). Повну батарею не запускала — її логи T1 (`battery-w15b/`).

**Вердикт: YELLOW, RED немає.** RED-1 і RED-2 першого аудиту закриті: мої мутанти тепер червоні у своїх родинах.
Нові YELLOW:
- гард не судить «dash, натиснутий на тросі, не спрацьовує після відпускання» — продукт правий, мутант зелений;
- підказки провулка й ятки на тросі не мають гарда справжнім G;
- нижня межа швидкості лазіння й спуску досі не судиться (Y2 першого аудиту);
- гейт СТЕ має люфт до першого коміту списку;
- кілька документів застаріли.

| # | пункт | вердикт | доказ (команда цієї сесії → вихід) |
|---|---|---|---|
| 0 | базові команди | GREEN | `make check` → rc 0: GDS 144/0, `канарка: FAIL як треба`, `[smoke] ALL OK (165 checks) in 19847 frames` (`Ф/make_check.log`). `bash tools/gates/run_gates.sh` → rc 0: 561 стор. / 9437 лінків / 0 зламаних, реєстр 187/187, ролі 8/0, СТЕ rc 0, GDS 144/0 (`Ф/gates_full.log`). `git diff --cached --stat HEAD -- game/assets docs/Art/Textures-Registry.md game/project.godot game/data` → порожньо |
| 1 | батарея T1 | GREEN | `PLAYABLE CHECK: 161 scenarios, 0 failures` × 3, `shard*.rc` → `rc=0` × 3. Мій скан 483 логів (§ 0) |
| 2 | RED-1 `blood-content` | GREEN | лог T1 і мій прогін → `checks=75 failures=0`; кільце = літерал T8; мутант → 4 провали (§ 1) |
| 3 | RED-2 (а) 14 м, (б) швидкість на E | GREEN | `reel_20m`, `reel_16m` → `red=reel_refuse`; `e_letgo_zero_v` → `red=letgo_v` (§ 2) |
| 4 | YELLOW 15а: липкість, HOLD, переходи, коментар, P3 | GREEN | вікно рівно 15; `climb_default` до першого `set_rope_climb`; `transfer_denied`; `:45`; родина `pad` (§ 3). Y2 — п. 10 |
| 5 | правило раннера після T2-О | GREEN | 5 моїх обходів → rc 2; 10 нових форм → rc 2; контроль → rc 0 (§ 4) |
| 6 | гейт СТЕ, `ci.yml` | YELLOW | ріст у станах «гілка» і «main» → rc 2; без git / без `origin/main` / неглибока історія → rc 2. Люфт 8 рядків у стані «список ще ні в якому коміті». `ci.yml` +2/−0 (§ 4) |
| 7 | гарди T2-Р на поверхні | GREEN | 4 родини судять; продуктові мутанти червоні; відсікання точне на 4 прогонах (§ 5) |
| 8 | `KNOWN_LEAP_SURFACE` (клас 17) | GREEN, залишок | 9 ключів = замір дослівно, допуск 0,003 м; погіршення на 5 мм → червоне. Група тіла не закріплена (§ 5) |
| 9 | дуель біт у біт | GREEN | smoke, зонд × 4, 12 кейсів — однакові (§ 6) |
| 10 | продукт T2-М / T2-П / T2-Р | YELLOW | 30 тиків і 3,6 м/с ті самі; `talk_blocked` судиться, провулок і ятка — ні; `_take_rope_presses`: `dash` на тросі не судиться; Y2 відкритий (§ 7) |
| 11 | документи | YELLOW | застаріли [[06-UI-UX]] § ROPE CLIMB, коментар фікстури, шапка Fix T2-И; стовпець «коміт» у [[Screenshots]] (§ 8) |
| 12 | рецидиви | — | клас 5 +1, клас 10 +1 (механізм є), клас 18 — механізм у гілці, клас 17 без нового (§ 9) |

## 0. Батарея T1 — мій скан

`python3` по `battery-w15b/shard*.out` і 483 логах, кейси — з `cases` раннера `t4d-tree` (`Ф/cases_tree.json`):
- результатів 483, `PASS` 483; 137 позитивів / 346 негативів / 156 негативів без `red=`;
- у позитивах `ERROR` 0, `WARNING` 0, `leaked` / `still in use` 0; у негативах `SCRIPT ERROR` 0;
- sentinel кожного кейсу знайдено в його лозі;
- у кожному шарді: `PLAYABLE FAMILIES: 346 negatives in the battery, 156 of them without a family and listed (ceiling 156);
  canary 12/12 forms as expected`.

Від дерева 15а (`t4-w15/cases_after.json`) додано 25 кейсів, усі негативи; видалено 0; sentinel наявних не змінено.
Розбір `required_families` раннера: кожен новий негатив вимагає свою родину. Ось вони:
`flag` → `perch_tilt`; `head` → `perch_head`; `snap`, `elbow` → `perch_turn`; `cadence`; `stroke` → `hand_stroke`;
`antiphase` → `feet_phase`; `reel_right` → `reel_hands`; `tail_stays` → `retrieve_tail`; `instant` → `retrieve_hud`;
`two_hands` → `perch_throw`; `leap_along` → `leap_clear`; `reel_range` → `reel_refuse`; `zero_v` → `letgo_v`;
`short_window` → `flicker`; `rope_buffer` → `dodge`; `perch_flash` → `perch_dash`; `pad_dash` → `pad`;
`passerby` → `talk`; `rope_row` → `comfort`; `body_near` → `perch_head_mesh`; `pull_first` → `pull_ceramic`;
`strut_far` → `sleeve_strut`; `body_near_leap` → `leap_mesh`; `mute_deny` → `denied`.

Фікстури від дерева 15а (`diff` з `t4-w15/mut-tree`, її `sha256sum -c` проти `t4-w15/src.t4c` → rc 0) не послаблені.
Прибрані рядки `_check` перенесені:
- П-1 — у тому самому місці з відступом;
- стрибок — `_leap_expected` за правилом T1;
- рядок COMFORT — справжнім вводом.

`FEET_BELOW` став `{"choko": 1.28, "skea": 1.32}` за рішенням T1, допуск той самий (± 0,01).

## 1. RED-1 закрито — `blood-content`

- `battery-w15b/playable/blood-content.log` → `BLOOD_CONTENT_COMPLETE checks=75 failures=0`; мій прогін у копії `Ф/mut-tree2` — те
  саме (`Ф/mut/base/blood-content.log`).
- Кільце: `_ring()` (`blood_content_check.gd:105–113`) = літерал [[06-UI-UX]] `:1348–1349`: `… → DRUGS → ROPE CLIMB → RESTORE SOUND &
  SHAKE DEFAULTS → CONTROLS (довідка) → BACK → DISPLAY`, телефон — без DISPLAY. `ring.has(null)` → провал, тож відсутній рядок
  не проходить.
- Мутант `ring_no_rope` (продукт: прибрано `_focus_order.append(rope_climb_choice)`) → `checks=75 failures=4`:
  - кільце на десктопі;
  - `Down from DRUGS reaches ROPE CLIMB`;
  - `Down from ROPE CLIMB reaches RESTORE`;
  - кільце на телефоні.

## 2. RED-2 закрито — 14 м і швидкість на E

Мій набір мутантів 15а перенесено на це дерево (`Ф/bin/mut2.py`; `check` → кожен рядок мутанта знайдено рівно раз). Кейси —
командний рядок батареї; база в `Ф/mut-tree` — `rope-climb-rules-choko` `checks=152 failures=0`, `traversal` `checks=85
failures=0`.

| мутант (продукт) | було в 15а | тепер |
|---|---|---|
| змотування з 20 м | усе зелене | `rules-choko` rc 1, `red=reel_refuse` («П-4 far: the reel is refused … offered true») |
| змотування з 16 м | усе зелене | `rules-choko` rc 1, `red=reel_refuse` |
| E-відпускання обнуляє швидкість | усе зелене | `traversal` rc 1, `failures=3`, `red=letgo_v` |
| вікно липкості 5 тиків | усе зелене | `traversal` rc 1, `red=denied,flicker` |

- П-4 far стоїть на вільній лінії за 14,5 м (`rope_climb_check.gd:1514`, передумова `:1546`); контроль — 13,5 м, змотування
  пропонується й забирає мотузку (`:1484–1498`).
- Міські рядки `traversal` стартують зі швидкістю `SWING = (3; 0; 1)` (`traversal_check.gd:437`). Рівність точна й
  ненульова, родина `letgo_v` (`:490`).
- Негатив `reel_range` у батареї червоніє лише рядком предмета (`:1549`), передумова тримається.

## 3. YELLOW 15а — що закрито

| пункт 15а | мутант / перевірка | вихід |
|---|---|---|
| Y1 липкість 14 / 15 | рядки `:427–428` (14 тиків висить, 15 відпускає); `sticky_14` | `red=denied,flicker` |
| | `sticky_16` | `red=empty,letgo_v` |
| Y3 HOLD першим | `climb_default` читається в `_run` (`:364`), перший `set_rope_climb` — `:407`; `climb_toggle_default` | `rules-choko` `red=comfort` |
| Y4 `rewinds=0 denied=0` | `rope_choice_check.gd:227–228`; `transfer_deny_far` (дальність `retarget` × 0,5) | `rope-transfer-choko-3` rc 1, `denied=5`, `red=count,open,transfer_denied` |
| Y9 коментар `:45` | `sed -n 45p` | «(4: 22 → 19 and 14 → 22 for each hero)» |
| Y8 геймпад P3 | `:1046–1055` (Y + X 20 тиків — L та сама, без DASH), контроль X; негатив `pad_dash` | у батареї `red=pad` |

Y2 (нижня межа швидкості) не входив у ТЗ — § 7.

## 4. Правило раннера і гейт СТЕ (T2-О)

**Правило** — канарка на тілі раннера до першого кейсу (`Ф/bin/rule_canary2.py`, вихід `Ф/canary_rule.out`):

| форма | rc |
|---|---|
| без змін | 0, `346 … 156 … (ceiling 156); canary 12/12` |
| 15а: `red=[a-z_,]*` | **2** «has red= but requires no concrete family» |
| 15а: `red=(none\|[a-z,]+)` | **2** |
| 15а: «привид» (кейс видалено, ім'я в списку) | **2** «listed … but no case has that name» |
| 15а: те саме ім'я → новий негатив | **2** «… for tools/world/city_rim_exit_check.gd\|-- --break=old but the case runs tools/other/new_check.gd\|» |
| 15а: голе ім'я + стеля 157 | **2** (формат рядка, без родини, стеля ≠ рядкам) |
| контроль: новий негатив без `red=` | **2** |
| нові: `(\bx\b)?`, `(\bx\b\|…)`, `(?=.*\bx\b)`, `(?!none)`, `n\x6fne`, верхня `\|`, `\bx*\b`, `(?:\bx\b){0}`, умовна група, `xred=\bx\b` | **2** кожна |
| позитивний контроль: `red=[a-z_,]*\bx\b[a-z_,]*` | 0 |
| прив'язаний рядок + стеля 157 | 0 — за задумом це справа гейта СТЕ |

**Гейт СТЕ** (`tools/gates/unfamilied_ceiling_check.py`). Перевіряла в `Ф/gate/`:
- `git clone --shared --no-checkout` репозиторію, sparse `tools/gates`, detached `93ba633`;
- `origin/main` := `d34cf67`, як у справжньому репозиторії (`git merge-base HEAD origin/main` у `t4d-tree` → `d34cf67`);
- файли раннера, списку й гейта — з `t4d-tree`.

| стан бази | форма | rc |
|---|---|---|
| список ще ні в якому коміті (база — негативи без `red=` у раннері HEAD `93ba633`, 164) | без змін | 0 |
| | прив'язаний рядок + стеля 157 | **2** «рядків, яких база не тримає (1)» |
| | повернути `city-bounds-negative-gap\|tools/world/city_bounds_check.gd\|-- --break=gap` + стеля 157 | **0** — люфт |
| коміт гілки додав список (156) | без змін | 0 |
| | ріст / повернення `gap` | **2** «UNFAMILIED_CEILING 156 → 157 …» |
| список у main (156) | без змін / ріст | 0 / **2** |
| без git | — | **2** «НЕ ВИМІРЯНО: … not a git repository» |
| без `origin/main` | — | **2** |
| `git clone --depth 1 --no-single-branch` | — | **2** «немає спільного предка …» |

- Люфт стану «ще ні в якому коміті» — рівно 8 імен `city-bounds` / `city-perch`, що мали родину лише з цього заходу
  (`unfamilied_at('93ba633')` → 164, з них не в списку 8: `Ф/gate/slack.txt`). Повернути одне з них, знявши йому родину,
  можна. T2-О це назвав. Люфт закриває перший коміт, що додає список: з нього база тримає 156.
- `git diff --cached HEAD -- .github/` → лише `with:` + `fetch-depth: 0` у задачі `gates` (`--numstat` → `2 0`). Задача
  `godot` не змінена. `run_gates.sh` +4/−1: рядок `СТЕ` і шапка.

## 5. Гарди T2-Р на поверхні моделі і `KNOWN_LEAP_SURFACE`

**Чи судять.** Мої продуктові мутанти (константи продукту, а не перемикачі фікстури) → підбатареї:

| мутант | кейси | вихід |
|---|---|---|
| `PULL_UP_DUCK` 0,30 → 0 (шлях 15а) | `rope-climb-1`, `-2`, `-5` | `red=pull_ceramic`; `pull_ceramic,sleeve_strut`; `pull_ceramic,sleeve_strut` |
| `PULL_UP_DUCK` → 0,10 | `rope-climb-1…5` | `pull_ceramic` у кожній, у 5/5 ще `sleeve_strut` |
| `PERCH_BODY_BACK_MORE` → `{}` (Skea на 0,14) | `rope-climb-1`, `rules-skea` | `perch_head_mesh,pull_ceramic,sleeve_strut`; `leap_mesh` (15 провалів) |
| `perch_head_back` 25° → 15° | `rope-climb-1` | `perch_head_mesh,pull_ceramic` |
| `perch_strut_far` 0,56 → 0,66 | `rope-climb-2` | `sleeve_strut` |
| `PERCH_LEAP_ACROSS` 0,5 → 0,2 | `rules-choko` | `leap,leap_clear,leap_mesh` |

**Точність відсікання** `rope_mesh_clearance.gd`. Мутант `nocull` вимикає відсікання (`if false and bool(bucket.exact):` —
скінуються всі вершини). Рядки `ROPE_CLIMB_MESH` / `ROPE_CLIMB_LEAP` (без поля `v=`) побайтно однакові (`md5`) у 4 парах:
- продукт `rope-climb-1`;
- продукт `rules-skea` (8 ненульових стрибків);
- Skea на 0,14 `rope-climb-1` (5 ненульових);
- Skea на 0,14 `rules-skea` (15 ненульових).

Вартість: 19,8 мс / тик без відсікання проти 9,6 з ним.

**`KNOWN_LEAP_SURFACE`** (`rope_climb_check.gd:162–173`):
- 9 ключів `герой|якір|стік` = рядки `ROPE_CLIMB_LEAP` логів T1 `rope-climb-rules-*` дослівно (тики й глибина до мм:
  `choko|16|along+` 1 / 0,012 … `skea|16|along-` 3 / 0,064);
- решта 21 стрибок — `surface=0`;
- перевірка (`:312–317`): тиків ≤ пришпилених, глибина ≤ пришпиленої + `LEAP_PIN_SLACK` 0,003; «більше не стається» — червоне;
  непришпилений — строго 0.

Мутанти:
- Skea на 0,14 → усі 8 пришпилених стрибків Skea «pinned at …»;
- Skea на 0,185 (на 5 мм ближче, `skea_back_045`) → `red=leap_mesh`, 7 провалів: 3 пришпилені погіршились
  (`22|along-` 3 тики / 0,037 проти 2 / 0,036; `16|along+` 3 / 0,046 проти 2 / 0,044; `16|along-` 0,068 проти 0,064),
  а `22|away`, `22|toward`, `16|away`, `16|toward` — нові.

Ширше за дефект — ні: ключ вузький, пороги — замір. **Залишок (кандидат класу 17):** група тіла й коробка не закріплені.
Голова замість плеча в тій самій точці з тими самими тиками й глибиною пройде.

## 6. Дуель біт у біт (GREEN)

- База — `t4-w15/base-tree`. Звірено з комітом: `git archive 93ba633 game tools Makefile` → 944 файли, `sha256sum -c` → rc 0.
- «Після» — та сама база з `game/scripts` із `t4d-tree`; `diff -rq --exclude=.godot t4d-tree/game after-tree/game` → rc 0,
  `tools` = бази.
- Скрипт `Ф/bin/duel_cmp.sh`:
  - `smoke.log` — однакові (171 рядок, `ALL OK (165 checks) in 19847 frames`);
  - зонд T3 `duel_rope_probe.gd`: `choko_shared`, `skea_solo`, `skea_shared` — однакові;
  - `choko_solo`: усі 20 рядків даних однакові, у «після» на виході `6 ObjectDB instances were leaked`. Повтор 2 + 2
    (`Ф/duel/rerun/`): 20 рядків, `md5` `32834fd1` у всіх чотирьох і в базі, витоків 0 / 4. Це гонка виходу зонда; у 15а
    вона була в базі;
  - 12 дуельних кейсів батареї (раннер бази) — `12 scenarios, 0 failures` обидва; `cmp` після заміни шляху → 12 / 12.

## 7. Продукт T2-М / T2-П / T2-Р

**Шлях підтягування з трьох ніг** (`GrappleHook._climb_path`, `_climb_point`, `_drive_climb_top`).
- `total = roundi(climb_top_seconds / delta)` = 0,5 · 60 = 30. Позначки 0 / 0,5 / 0,8 / 1,0 → 15 / 9 / 6 тиків.
  `climb_speed` = 3,6 (`:102`), як у 15а.
- Логи T1 `rope-climb-[1-5]`: `pull_up=30` × 50, `way=4` × 50.
- Мутанти: `climb_top_seconds` 0,6 → `rope-climb-1` `red=perch` (Л-б: тиків ≠ 30); `climb_speed` 4,2 → `red=climb_rate`.
- Запасний шлях 15а, коли «під ковпаком» перекрито, лишає героя не застряглим — це презентаційне рішення T2.

**Вхід у звис (T2-М).**
- `PERCH_UPRIGHT_RATE` 8° → 2° — `perch_tilt`; → 40° — `perch_tilt`.
- Миттєвий розворот (`clampf` знято) → `perch_tilt,perch_turn`.

**`can_talk_to` / `talk_blocked`.**
- `talk_blocked()` → `false` — `rules-choko` `red=talk`; виклик «П'ять листків» через `in_talk_reach` — `red=talk`.
- **Виклик провулка (`CityAlleyEvent.gd:174`) і ятки (`CityVendorEvent.gd:116`) через `in_talk_reach` — усе зелене.** Гард
  справжнім G бачить лише листки. T2-П сам це назвав (Fix «Відкрите» п. 2). YELLOW.
- Шов `CityWorld.events_script` — у грі завжди `CityEventDirector`, за зразком `fighter_script`. Прийнятно.

**`_take_rope_presses`.**
- `dodge` на тросі не забирається → `red=dodge`.
- `dash` не забирається ніде → Skea `red=perch_dash` (звис), Choko зелене (у нього немає dash у повітрі без «Spring»).
- **`dash` не забирається лише на тросі (`hang_dash_kept`) → `rules-skea` і `rules-choko` зелені.** Мій зонд
  `Ф/mut-tree/tools/grapple/t4_hang_dash_probe.gd` — копія `_perch_dash`, лише хват на тросі замість звису (`_hang_on`,
  `phase == HANG`): продукт → `failures=0`; мутант → `red=perch_dash`, «LAlt … dashed true» і «Y + X … dashed true».
  - Отже, після відпускання троса flash Skea спрацює, і гард цього не побачить.
  - T2-П § 2: «Предмет: … (`dash` на тросі й звисі): після відпускання вони не спрацьовують».
  - YELLOW, клас 5.

**Y2 15а — досі відкритий.** Мутанти: лазіння 3,6 → 3,0 м/с — `rope-climb-1`, `rules-choko`, `rope-pull` зелені;
спуск 2,0 → 1,6 м/с — `rules-choko`, `traversal`, `rope-pull` зелені. Верхню межу (4,2) судить `climb_rate`.

## 8. Документи (YELLOW)

- `run_gates.sh` → 561 стор. / 9437 лінків / 0 зламаних. 36 нових кадрів, кожен рядком у [[Screenshots]] рівно раз,
  79 282…275 911 байт (`stat -c %s`).
- Застаріло:
  - [[06-UI-UX]] § ROPE CLIMB:
    - `:166` — «Заголовок `ROPE CLIMB` … доки T2 не змінить константу». У коді `ROPE_CLIMB_TITLE := "ROPE CLIMB · CITY ONLY"`
      (`ComfortPanel.gd:53`);
    - `:204` — «через `item_selected.emit`, не справжнім вводом». T2-П перевів `_comfort_row` на клавіші й геймпад;
    - посилання `:52`, `:175–181`, `:178` (і `:1343` «`ComfortPanel.gd:178`») → тепер 53, 176–179, 179;
  - `blood_content_check.gd:110` — «(the place awaits T8)». T8 місце підтвердила (`06-UI-UX` `:1342–1349`);
  - шапка [[2026-10-15-Rope-Climb-City-Fix]] `:3` — «Статус: у роботі» (Y9 15а виконано лише для коментаря);
  - у [[Screenshots]] 36 рядків «не закомічено» (`grep -c`). Після коміту застаріють (клас 13);
  - журналу `docs/Meetings/2026-10-15-*` про 15а ще немає (`ls docs/Meetings | grep 2026-10-15` → лише хвиля 14). `state.md`
    без 15а — це закриття T1.

## 9. Рецидиви — текст для реєстру

Спершу — текст 15а з [[2026-10-15-Rope-Climb-15a-Review]] § 9: у дереві реєстр не змінено
(`git diff --cached --stat HEAD -- docs/system/` → порожньо).

- **Клас 5 (обіцянка без гарда): +1, після запису 15а — 18 → 19.** Пропоную дописати:
  > 2026-10-15, повторний аудит 15а (дерево `93ba633` + індекс, 84 файли): [[2026-10-15-Rope-Input-Acceptance-Fix]] § 2 обіцяє
  > «`dash` на тросі й звисі після відпускання не спрацьовує». Гард судить лише звис Skea (`_perch_dash`). Мутант «такт троса
  > не забирає `dash`» → `rope-climb-rules-skea` / `-choko` зелені. Зонд T4 (`_perch_dash` на тросі): продукт без DASH,
  > мутант `dashed true` × 2. Закрито в тій самій хвилі: ADR-028 п. 4 (14 м) і п. 5 (швидкість на E), вікно липкості 15 —
  > мутанти T4 червоні у своїх родинах — [[2026-10-15-Rope-Climb-15a-Recheck]].

  Статус ВІДКРИТО.
- **Клас 10 (перевірка проксі не доводить поверхню героя): 1 → 2.** Пропоную дописати:
  > 2026-10-15, хвиля 15а: гарди звису (`perch_head`, `leap_clear`) міряли центри кісток, а волосся й плече Skea заходили в
  > брус і ковпак (знайшла T6, [[2026-10-15-T6-Rope-Climb-Acceptance]]).
  >
  > Механізм — у тій самій хвилі: `tools/grapple/rope_mesh_clearance.gd` (точний CPU-скінінг, відсікання сферами кісток) і
  > родини `pull_ceramic`, `perch_head_mesh`, `sleeve_strut`, `leap_mesh`. Продуктові мутанти T4 червоні. Без відсікання ті
  > самі рядки (`md5`, 4 прогони).
  >
  > Залишок: `perch_legs`, `perch_head`, `leap_clear` — на центрах кісток — [[2026-10-15-Rope-Climb-15a-Recheck]].

  Статус: ЗАКРИТО для троса в гілці.
- **Клас 18: лічильник 2 без змін.** Статус пропоную: «ЗАКРИТО в гілці (T2-К + T2-О)». Зміст:
  - правило раннера читає родину з розбору regex;
  - рядок списку — `ім'я|скрипт|аргументи`; «привид» і перев'язка → rc 2;
  - правило судить `all_cases`;
  - гейт СТЕ звіряє з merge-base `origin/main`, без історії → rc 2;
  - `fetch-depth: 0` у задачі `gates`;
  - канарки T4 (5 обходів 15а + 10 нових форм) → rc 2; ріст у станах «гілка» / «main» → rc 2.

  Залишки:
  - стан «список ще ні в якому коміті» пропускає повернення одного з 8 імен `city-bounds` / `city-perch` (rc 0). Це
    закриває коміт, що вводить список;
  - sentinel рядків списку не заморожено.

  Остаточно закрити — після цього коміту й першого зеленого CI з `fetch-depth: 0`.
- **Клас 17: без нового випадку, лічильник 2.** Пропоную дописати:
  > Повторний аудит 15а: `KNOWN_LEAP_SURFACE` — 9 ключів, значення = замір батареї дослівно, допуск 0,003 м, «більше не
  > стається» — червоне. Мутанти T4 → `leap_mesh`. Переходи: `rewinds` / `denied` закріплено на 0 (мутант →
  > `transfer_denied`). Залишок-кандидат: група тіла й коробка пришпиленого стрибка не закріплені.
- **Клас 15:** нового немає — у 137 позитивах `battery-w15b` `WARNING` 0. Механізму досі немає (пропозиція 6), ВІДКРИТО.
- **Кандидат 19:** нового випадку немає — повна батарея T1 483 / 0. Лишається кандидатом.

## Пропозиції — YELLOW, кому

- **Y-A, T2: `dash` на тросі.** У `_perch_dash` додати варіант на тросі.
  - Skea, LAlt і Y + X на тросі, за ≤ 2 тики — Z / B: 8 тиків без DASH. Контроль — свіжий LAlt після відпускання.
  - Негатив `hang_flash` (`rope_climb_fighter.gd`: такт троса не забирає `dash`) → `red=perch_dash` або власна родина.
- **Y-B, T2: перехожі провулка та ятки справжнім G**, як P10b для листків. Негативи «виклик через `in_talk_reach`» → `talk`.
- **Y-C, T5 → T2 (Y2 15а).**
  - Т5: чи крок лазіння й спуску має бути рівно 3,6 / 60 і 2,0 / 60 (± 1e-6) до межі.
  - Т2: гард нижньої межі. Зараз 3,0 і 1,6 м/с зелені.
- **Y-D, T1.**
  - Закомітити список, раннер і гейт одним комітом (порада T2-О) — це закриває люфт 8 рядків.
  - Після першого CI з `fetch-depth: 0` звірити рядок `СТЕ` у задачі `gates` і її тривалість.
- **Y-E, T2.**
  - `KNOWN_LEAP_SURFACE`: закріпити ще групу й коробку (наприклад, `upperarm@Arm`).
  - Ключ, якого прогін не відвідав, — червоне (на випадок зміни `LEAP_ANCHORS`).
- **Y-F, T2:** передумови П-4 far (`rope_climb_check.gd:1515`, `:1546`) — під `count`, а не `reel_refuse`. Сьогодні позитив
  їх ловить, але негатив `reel_range` зарахувався б і за зламану передумову.
- **Y-G, документи.**
  - T8 — [[06-UI-UX]] § ROPE CLIMB `:166`, `:204` і номери рядків.
  - T2 — коментар `blood_content_check.gd:110`; шапка [[2026-10-15-Rope-Climb-City-Fix]].
  - T1 — стовпець «коміт» у [[Screenshots]] при коміті; `state.md` і журнал зустрічі на закритті. Потім
    `make summary-check PLAYABLE_LOG_DIR=…/battery-w15b/playable`.
- **Y-H, T6:** [[2026-10-15-Rope-Perch-Mesh-Clearance-Fix]] § 10 п. 1–4:
  - голова 25°;
  - Skea на 0,19;
  - дальня кисть 0,56;
  - пірнання 0,30;
  - мотузка над маківкою Choko.
- **Y-I, T2 через T1:** клас 15 — підсумок WARNING у позитивних логах у раннері (пропозиція 6).

## Related
- [[2026-10-15-Rope-Climb-15a-Review]] · [[ADR-028-Rope-Climb-Perch-And-Retrieval]] · [[2026-10-15-Rope-Climb-Perch-Release]]
- [[2026-10-15-Rope-Climb-City-Fix]] · [[2026-10-15-Negative-Families-Runner-Fix]] · [[2026-10-15-Runner-Rule-Bypass-Fix]]
- [[2026-10-15-Rope-Perch-Entry-Fix]] · [[2026-10-15-Rope-Input-Acceptance-Fix]] · [[2026-10-15-Rope-Perch-Mesh-Clearance-Fix]]
- [[2026-10-15-T6-Rope-Climb-Acceptance]] · [[2026-10-15-T8-Rope-Climb-Input-Acceptance]] · [[2026-10-15-Rope-Climb-Input]]
- [[2026-10-15-Rope-Climb-Numbers]] · [[06-UI-UX]] · [[Screenshots]] · [[recurring_class_register]] · [[state]]
