# Трос у місті: YELLOW повторного аудиту 15а — журнал виконання (T2-С)

**Дата:** 2026-10-15 · **Роль:** T2 Гефест (T2-С) · **Статус:** зроблено в дереві без коміту (§ «Де зупинився»):
`make check` і `make gates` — rc 0; підмножина батареї 74 / 0; мутанти T4 Y-A / Y-B / Y-C червоні; дуель біт у біт. Мерж — Santos.
**Задача:** Y-A, Y-B, Y-C, Y-E, Y-F і частина Y-G сторінки [[2026-10-15-Rope-Climb-15a-Recheck]] (вердикт T4 — YELLOW, RED
немає). Продовження кроку 5 (15а) плану [[2026-10-15-Rope-Climb-Perch-Release]]. 0 кредитів.

Дерево — `scratchpad/t2s-tree`: detached `93ba633` + індекс (фінальне зведення 15а і сторінка повторного аудиту T4). Не комічу,
індекс не міняю. Godot `4.7.stable.official.5b4e0cb0f` (`$GODOT_BIN --version`). Логи — `scratchpad/t2s/` (далі `ТС/`).

## 0. Звірка

Кожне посилання задачі переведено заново в цьому дереві до першої правки:

| посилання | команда | що є |
|---|---|---|
| джерела = фінальна батарея T1 | `git ls-files -co --exclude-standard -z game tools Makefile \| sort -z \| xargs -0 sha256sum` → 951 рядок; `cmp` з `battery-w15b/src.before` | однакові (`ТС/src.before`) |
| базовий `make check` | `make check` | rc 0, GDS 144 / 0, `[smoke] ALL OK (165 checks) in 19847 frames` (`ТС/make_check_base.log`) |
| зонд T4 (Y-A) | `diff rope_climb_check.gd t4-w15b/mut-tree/tools/grapple/t4_hang_dash_probe.gd` | 3 ханки: `_hang_on` замість `_perch_pad`, `_settle_pull`, `phase == HANG` |
| `_take_rope_presses` | `CityFighter.gd:143–146` | на тросі забирає `dodge` і `dash`, на якорі — лише `dash` |
| провулок / ятка (Y-B) | `grep -n can_talk_to` | `CityAlleyEvent.gd:174` (фаза `ask`, `asker`), `CityVendorEvent.gd:116` (фаза `offer`, `person`), `CityLeavesEvent.gd:113` |
| П-4 far (Y-F) | `sed -n '1515p;1546p' rope_climb_check.gd` | обидві передумови під `reel_refuse` |
| коментар (Y-G) | `sed -n 110p blood_content_check.gd` | «(the place awaits T8)»; T8 прийняла місце — [[2026-10-15-T8-Rope-Climb-Input-Acceptance]] рядок 3 таблиці, `06-UI-UX` «Повне кільце» |
| шапка (Y-G) | `sed -n 3p docs/Fix/2026-10-15-Rope-Climb-City-Fix.md` | «Статус: у роботі» |
| мутанти T4 | `t4-w15b/bin/mut2.py`, рядок кожного в цьому дереві — `count` → 1 | `hang_dash_kept`, `alley_reach`, `vendor_reach`, `climb_30`, `slide_16` |

**Числа T5 (Y-C).** [[2026-10-15-Rope-Climb-Numbers]]: Л1 = 3,6 м/с (`:34`), С1 = 2,0 м/с (`:40`). § 8 дає лише верхні межі:
«не більше ніж на 3,6 / 60 + 1e-6 за тик» (`:420`) і «≤ 2,0 / 60 + 1e-6 за тик» (`:440`). Нижнього допуску T5 не дав
(`grep -rn "Y-C\|нижн" docs` → відповіді T5 немає). Тому нижня межа — з ТЗ T1: **3,6 − 0,1 = 3,5 м/с** і **2,0 − 0,1 = 1,9 м/с**
на тик. Верхня лишається T5-івська (+1e-6), вона суворіша за «+ 0,1».

**Розбіжність у посиланні ТЗ (не блокує).** ТЗ називає пороги «≥ 2,4 м/с» «P12 у `Rope-Climb-Numbers.md`». У тому документі
P12 немає (`grep -n P12` → порожньо). P12 — рядок T8 у [[2026-10-15-Rope-Climb-Input]] `:367` (TOGGLE). Пороги 2,4 / 1,2 —
літерали фікстури `rope_climb_check.gd:1086`: `l1 < l0 − 0.4` за 10 тиків і `l4 > l3 + 0.2` за 10 тиків. Так їх і назвав перший
аудит ([[2026-10-15-Rope-Climb-15a-Review]] `:243`). Суть ТЗ від цього не змінюється.

**Межі.** `game/` не змінюю: усі правки — фікстури, їхні мутанти, раннер і документи. Дуель біт у біт — § 7.

## 1. Y-A — `dash`, натиснутий на тросі

Предмет: для всіх натисків `dash` (LAlt, Y + X), зроблених у звисі на тросі: після відпускання DASH не стається, а свіжий
натиск після відпускання спрацьовує.

- `rope_climb_check.gd` `_hang_dash` (новий, `--part=rules`, лише Skea — як `_perch_dash`, бо в Choko немає повітряного dash
  без «Spring»). Зонд T4 перенесено дослівно: звис на якорі 3, `_settle_pull`, LAlt або Y + X, через тик — B. Далі 8 тиків
  без DASH, контроль — свіжий LAlt після відпускання. Родина **`rope_dash`** — окрема від `perch_dash`, щоб негатив звису й
  негатив троса не підміняли один одного.
- Негатив `rope-climb-negative-hang_flash` (`rope_climb_fighter.gd`: такт троса забирає `dodge`, але не `dash`; якір — як був;
  це поведінка мутанта T4 `hang_dash_kept`) → `red=rope_dash`.

## 2. Y-B — провулок і ятка справжнім G

Предмет: для всіх трьох вуличних подій (листки, провулок, ятка), чий перехожий стоїть у досяжності розмови біля героя на
тросі: підказка схована, справжній G меню не відкриває.

- `_passerby` тепер кличе `_passerby_event` для `leaves`, `alley`, `vendor`. Перехожий — `asker` у провулку (фаза `ask`) і
  `person` у листках та ятці (фаза `offer`). Передумови — у `count`: подія стартувала, герой висить, мешканця поруч немає,
  перехожий у фазі й у досяжності. Предмет — у `talk`. Рядки листків ті самі, змінилась лише дужка «(offer …)».
- Негативи `rope-climb-negative-alley_reach` і `-vendor_reach`. `rope_climb_events.gd` `can_talk_to`: для активної події з
  цим id питає лише `in_talk_reach`. Так поводяться мутанти T4 у продукті — виклик `in_talk_reach` у рядку `:174` / `:116`.
  Решта подій — як у продукті. Обидва → `red=talk`.

## 3. Y-C — нижня межа лазіння й спуску

Предмет: для всіх тиків лазіння (спуску), які не впираються в межу 2,0 м (у довжину розгортання): крок ≥ (3,6 − 0,1) / 60
(≥ (2,0 − 0,1) / 60) − 1e-6. Останній тик, обрізаний до межі, не судиться: `GrappleHook.gd:871`, `:873` — `minf(швидкість ×
delta, залишок)`.

- Лазіння — `rope_climb_check.gd` `_climb_anchor` (усі 50 підйомів `rope-climb-1…5`), родина `climb_rate`. `RATE_TOLERANCE
  = 0.1`, джерело записане в коді. Тик судиться, коли `hook.climbing` і `L > 2,0 + 1e-6`; передумова «≥ 1 такий тик» — `count`.
  Новий рядок логу `ROPE_CLIMB_RATE`.
- Спуск — `rope_pull_check.gd` `_slide`, частини a, b, d, обидва герої; там уже стоїть верхня межа T5. Родина `sliderate`,
  передумова — `count`. Рядок `ROPE_PULL slide` отримав `full=` і `min_step=`.
- Негативи: `rope-climb-negative-climb_slow` (`GrappleHook.climb_speed = 3.0` на екземплярі) → `climb_rate`;
  `rope-pull-negative-slide_slow` (`slide_speed = 1.6`) → `sliderate`.

## 4. Y-E — `KNOWN_LEAP_SURFACE`: група, коробка, невідвіданий ключ

Предмет: для всіх пришпилених стрибків — не більше тиків і глибини, ніж у шпильці, і лише ті «коробка:група», що в ній;
кожна шпилька судиться в прогоні свого героя.

- Третій елемент шпильки — список «коробка:група» з **усіх** тиків стрибка (не лише з найглибшого). Номер якоря відкинуто, бо
  він уже в ключі. Будь-яка пара поза списком → `leap_mesh`. Шпилька, якої прогін героя не судив, → `count`: це покриття,
  а не предмет.
- Списки поміряно на цьому коді (`ТС/r2/rope-climb-rules-*.log`, поле `boxes=` рядка `ROPE_CLIMB_LEAP`). Найглибший тик
  показує не все: у `skea|3|along+`, `skea|22|along+`, `skea|16|along+` на інших тиках у ковпак заходить ще тулуб, а в
  `skea|3|along-` — плече. Перший прогін зі списками з одного найглибшого тику дав `red=leap_mesh` × 4 — саме на цих ключах.
  Списки виправлено за заміром, решта рядків не змінилась.
- Рядки `ROPE_CLIMB_LEAP` без поля `boxes=` побайтно збігаються з логами T1 `battery-w15b`. Команда: `diff` → порожньо, 30
  рядків.

## 5. Y-F — передумови П-4 far

`rope_climb_check.gd` (у старій нумерації `:1515` і `:1546`): «є місце за 14,5 м з чистою лінією» і «передумова тримається» —
тепер `count`. Предмет `:1549` лишився в `reel_refuse`. Негатив `reel_range` тепер не може зарахуватись за зламану передумову.

## 6. Y-G — мої документи

- `blood_content_check.gd:110`: «(the place awaits T8)» → T8 місце підтвердила, з посиланням на її приймання й «Повне кільце»
  `06-UI-UX`. Код і кільце не змінились.
- Шапка [[2026-10-15-Rope-Climb-City-Fix]]: «у роботі» → «зроблено в дереві без коміту» з посиланнями на журнали 15а та
  повторний аудит. Текст журналу нижче не чіпав.
- [[06-UI-UX]] не чіпав (Y-G T8).

## 7. Перевірка

**Базові команди** (фінальне дерево, після всіх правок):
- `make check` → rc 0: GDS «перевірено: 144 · не парсяться: 0 · канарка: FAIL як треба», `[smoke] ALL OK (165 checks) in 19847
  frames`, «SMOKE ЗЕЛЕНИЙ» (`ТС/make_check.log`).
- `make gates` → rc 0, «БАТАРЕЯ ЗЕЛЕНА» (`ТС/gates.log`): 563 стор. / 9497 лінків / 0 зламаних; реєстр 187 / 187; ролі 8 / 0;
  СТЕ «дерево: 156 рядків, UNFAMILIED_CEILING 156»; GDS 144 / 0.
- Раннер приймає нові негативи: `PLAYABLE FAMILIES: 351 negatives in the battery, 156 of them without a family and listed
  (ceiling 156); canary 12/12`. Було 346 / 156: +5 негативів, усі з родиною. Список винятків не змінився.

**Підмножина батареї** — `battery-w14s/run_subset.py` (heredoc раннера дослівно), `ONLY='rope-climb-.*|rope-pull.*|blood-content.*'`,
3 шарди: `PLAYABLE CHECK` 25 / 0 + 25 / 0 + 24 / 0 = **74 / 0**, `SUBSET_DONE rc=0` × 3 (`ТС/final-subset/`). Це всі кейси
змінених скриптів, разом зі старими негативами.

| кейс | вихід |
|---|---|
| `rope-climb-rules-choko` / `-skea` | `checks=160` / `188 failures=0 red=none` (у T1 було 152 / 162. Choko: +6 рядків P10b, +2 шпильки. Skea: +6 P10b, +4 `rope_dash`, +16 шпильок) |
| `rope-climb-1…5` | `checks=290 / 288 / 286 / 282 / 294 failures=0`, `anchors=10/10 perched=10` (+20 на частину: 2 рядки × 10 підйомів) |
| `rope-pull` | `checks=19596 failures=0` (+12: 2 рядки × 3 частини × 2 героїв) |
| `rope-climb-negative-hang_flash` | `failures=2 red=rope_dash` — обидва рядки «… on the rope, B 2 ticks later … dashed true» |
| `rope-climb-negative-alley_reach` / `vendor_reach` | `failures=1 red=talk` — лише рядок своєї події (листки й друга подія зелені) |
| `rope-climb-negative-climb_slow` | `failures=5 red=climb_rate` — 5 підйомів Choko, «the slowest 0.05000» |
| `rope-pull-negative-slide_slow` | `failures=3 red=sliderate` — частини a, b, d, «the smallest 0.02667» |
| `rope-climb-negative-reel_range` | `failures=1 red=reel_refuse` (Y-F: передумови в `count` зелені) |

- Заміри продукту: усі 50 підйомів — `slowest=0.060000` (= 3,6 / 60), судилося від 2 до 80 тиків на підйом. Спуск — `min_step=0.03333`
  (= 2,0 / 60), 16 / 16 / 14 тиків.
- Рядки, які продукт малює й міряє (`ROPE_CLIMB`, `_STROKE`, `_MESH`, `_POSE`, `_LEAP` без `boxes=`), у `rope-climb-1…5`,
  `rules-skea` і `duel` такі самі, як у логах T1 `battery-w15b`: `diff` → 0 рядків.

**Мутанти T4 у продукті** — копія `ТС/mut-tree`, скрипт `ТС/mut.py` (рядки мутантів T4 дослівно з `t4-w15b/bin/mut2.py`, кожен
знайдено рівно раз). Кейси — тим самим раннером (`ТС/mutrun.sh`, `ТС/mut/`). Після прогону копію відновлено, `filecmp` → однакові.

| мутант (продукт) | було в T4 | тепер |
|---|---|---|
| `hang_dash_kept` | `rules-skea`, `rules-choko` зелені | `rules-skea` `failures=2 red=rope_dash`; `rules-choko` зелений — у Choko немає повітряного dash, як і в T4 |
| `alley_reach` | усе зелене | `rules-choko` `failures=1 red=talk` |
| `vendor_reach` | усе зелене | `rules-choko` `failures=1 red=talk` |
| `climb_30` (3,0 м/с) | `rope-climb-1`, `rules-choko`, `rope-pull` зелені | `rope-climb-1` `failures=10 red=climb_rate`; `rope-pull` зелений (лазіння судить `rope-climb-*`) |
| `slide_16` (1,6 м/с) | `rules-choko`, `traversal`, `rope-pull` зелені | `rope-pull` `failures=6 red=sliderate`; `rules-choko` зелений (спуск судить `rope-pull`) |

Ще форми того самого предмета:
- `climb_34` → `rope-climb-1` `red=climb_rate` (10 / 10);
- `climb_35` (рівно на межі) → зелене;
- `climb_stutter` — кожен 20-й тик лазіння вдвічі повільніший, стала швидкість та сама. → `rope-climb-1` `failures=8`, `rope-climb-3`
  `failures=6`, `red=climb_rate`. Зелені лише підйоми, коротші за 20 тиків;
- `slide_18` → `rope-pull` `red=sliderate`;
- `slide_19` (на межі) → зелене.

Y-E — форми з боку заміру, бо продуктового мутанта «голова на місці плеча» немає:
- `arm_as_head` (вершини плеча зараховано до голови: ті самі тики й глибина) → `rules-skea` `failures=8 red=leap_mesh`, напр.
  «enters by ["Arm:head", "Ceramic:torso"], pinned ["Arm:upperarm", "Ceramic:torso"] only»;
- `arm_as_cap` (брус названо ковпаком) → `failures=6 red=leap_mesh`;
- `leap_no16` (`LEAP_ANCHORS` без 16) → `rules-skea` `failures=3`, `rules-choko` `failures=1`, `red=count`: «the pinned leap
  «skea|16|none» was judged (LEAP_ANCHORS [3, 22])».

**Дуель біт у біт.** `game/` не змінено: `sha256sum` по `git ls-files -co --exclude-standard game` до / після → 744 файли,
однакові (`ТС/src.before`, `ТС/src.after`; змінено лише 6 файлів `tools/`). Smoke той самий: `165 checks in 19847 frames`.
`rope-climb-duel` → `checks=7 failures=0`, рядки = T1. 12 дуельних кейсів T4 (`combat-control` … `rope-contact`) — 12 / 0, кожен
лог = лог T1 після відкидання рядків із кадрами й часом (`cmp` → 12 / 12).

**Скан логів** (`python3` по `ТС/final-subset/` і `ТС/duel/`):
- 86 результатів, 86 PASS: 22 позитиви, 64 негативи;
- у позитивах `ERROR` 0, `WARNING` 0, `leaked` / `still in use` 0;
- у негативах `SCRIPT ERROR` 0, чужих `ERROR` (не префікс свого скрипта) 0, `red=none` 0.

## 8. Відкрите

- **Лазіння в `weighted_swing_check`** (Л-а T5) міряє від `climb_speed` самого гака, тобто відносно. Мутант 3,0 там лишиться
  зеленим обома межами. Предмет тепер судить `rope-climb-1…5` літералом T5. Дублювати в `weighted_swing` — рішення T1 / T4, не
  робив.
- **Допуск ± 0,1** — з ТЗ T1, не від T5. Якщо T5 назве інший, міняється одна константа в кожному з двох скриптів
  (`RATE_TOLERANCE`).
- **Контроль `rope_dash`** («свіжий LAlt спрацьовує») стоїть у родині предмета, як контроль `perch_dash`. У негативі `hang_flash`
  червоні лише рядки предмета (лог), але за правилом Y-F контроль у тій самій родині теоретично міг би зарахувати негатив. Однаково
  з наявними контролями (`dodge`, `pad`, `talk`) — питання до T4, чи переносити всі контролі в `count`.
- Y-D (коміт списку), Y-G для T8 і T1, Y-H (T6), Y-I — не мої.

## Де зупинився

Готово до приймання T1, не закомічено, індекс не змінено. `git status --short` (фінальний, лише рядки поза чистим індексом;
усього 86 рядків, 85 індексованих файлів як були):

```
AM docs/Fix/2026-10-15-Rope-Climb-City-Fix.md
MM tools/fx/blood_content_check.gd
MM tools/gates/playable_check.sh
AM tools/grapple/rope_climb_check.gd
AM tools/grapple/rope_climb_events.gd
AM tools/grapple/rope_climb_fighter.gd
MM tools/grapple/rope_pull_check.gd
?? docs/Fix/2026-10-15-Rope-Recheck-Yellow-Fix.md
```

`git diff --stat` (робоче дерево проти індексу) → 7 files changed, 211 insertions(+), 42 deletions(-). Новий файл один — цей журнал
(T1 бере через `git add -N`).

## Related
- [[2026-10-15-Rope-Climb-15a-Recheck]] · [[2026-10-15-Rope-Climb-15a-Review]] · [[2026-10-15-Rope-Climb-Perch-Release]]
- [[2026-10-15-Rope-Climb-City-Fix]] · [[2026-10-15-Rope-Input-Acceptance-Fix]] · [[2026-10-15-Rope-Perch-Mesh-Clearance-Fix]]
- [[2026-10-15-Rope-Climb-Numbers]] · [[2026-10-15-Rope-Climb-Input]] · [[2026-10-15-T8-Rope-Climb-Input-Acceptance]]
- [[ADR-028-Rope-Climb-Perch-And-Retrieval]] · [[state]]
