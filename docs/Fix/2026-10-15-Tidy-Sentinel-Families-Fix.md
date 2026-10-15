# Родини в sentinel `city-tidy` і явна відмова на невідомий `kind` — журнал виконання

**Дата:** 2026-10-15 · **Роль:** T2 Гефест (T2-Ж) · **Статус:** зроблено в дереві без коміту. `make check` і
`make gates` — rc 0; `city-tidy*` 74/74; уся батарея 408/408 (§ «Перевірка»). Мерж — Santos.
**Задача:** пропозиції аудиту T4 [[2026-10-15-Wave-14-Review]] — п. 2 / YELLOW 2 (кандидат класу 18
[[recurring_class_register]]) і YELLOW 5 (`CityProps._place_glb`).

Дерево — scratchpad `t2g-tree`, detached `407595d`. Не комічу, не пушу. Основне дерево не чіпаю. Кредитів не витрачав.
Логи — scratchpad `t2g/` (далі `G/`). Трос, якорі, геометрію міста, шейдери кольорів не чіпав. Журнал пишеться по ходу.

## Звірка задачі з реальністю

| що в задачі | команда / місце | вихід | що роблю |
|---|---|---|---|
| голова дерева | `git -C t2g-tree log --oneline -1` | `407595d Fix the stall wedge, close the district edge and add the A/B3 colour switch` | — |
| sentinel негативів `city-tidy` | `grep -n "city-tidy" tools/gates/playable_check.sh` | 6 циклів, усі з `failures=[1-9][0-9]* mutation={mutation}` — без причини | звужую кожен до своєї родини |
| скільки кейсів | розбір `cases` із heredoc батареї (inline `python3`) | усього 403, негативів 284; `city-tidy*` 69, з них негативів 68 | — |
| як зроблено `red=` у сусідів | `grep -n "red" tools/grapple/rope_choice_check.gd tools/settings/colour_switch_check.gd` | `_check(ok, family, label)` → `red[family] = true`; рядок `… red=<родини через кому або none>`; sentinel `red=[a-z,]*\b{family}\b[a-z,]*` | та сама схема |
| мітки гардів `city_tidy_check.gd` | перше слово кожної мітки `_check(…, "<TAG> …")` (`grep -o`, `uniq -c`) | 116 викликів, усі починаються з тега гарда: `C1…C5`, `D17/D19/D24`, `K`, `K4…K9`, `K4/Н1`, `M`, `M1…M8`, `MC`, `MC1…MC10`, `S`, `V`, `V+`, `V-M`, `V-MC` | родина = тег; V+ і MC7 ділю на підгарди |
| поріг MC7 seen | `grep -n STREET_SEEN_FLOOR tools/world/city_tidy_check.gd` | `const STREET_SEEN_FLOOR: float = 4.0`; гард `seen == 0 or seen_low >= STREET_SEEN_FLOOR - 0.001` | — |
| мутант T4 | `diff t2g-tree/tools/world/city_tidy_check.gd t4-w14/mut/city_tidy_seen2.gd` | крім `STREET_SEEN_FLOOR 4.0 → 2.0` — ще 5 старих блоків (`STEP_PROPS`, `STEP_WEDGE_OPEN`, `wedge_more/deeper` — файл старший за дерево) | той самий однорядковий мутант накладаю на нову фікстуру (`G/mut/city_tidy_seen2.gd`) |
| `_place_glb` | `game/scripts/world/CityProps.gd:299-326` | `var scene: PackedScene = STEAM_CAR_TARP`, `match` без гілки за замовчуванням | невідомий `kind` → помилка й `null` |
| як у файлі прийнято про помилку | `grep -n push_error game/scripts/world/CityProps.gd` | `:318` `push_error("CITY_PROPS: …")` + `continue` | той самий префікс `CITY_PROPS:`, нічого не ставити |
| хто ще кличе `_place_glb` | `grep -rn "_place_glb\|CITY_PROPS" tools game` | лише `_vehicle`, `_machine` у `CityProps.gd` | обидва пропускають `null` |
| база дерева | `make check` (`G/make_check_base.log`) | rc 0; GDS `перевірено: 144 · не парсяться: 0 · канарка: FAIL як треба`; `[smoke] ALL OK (165 checks) in 19847 frames` | — |
| база батареї `city-tidy*` | `G/run_subset.py` (heredoc батареї дослівно + фільтр імені), 3 шарди (`G/before/`) | `PLAYABLE CHECK: 23 scenarios, 0 failures` ×3 → 69/69 PASS | — |

`G/run_subset.py` виконує heredoc `playable_check.sh` без змін: та сама команда Godot, ізольований профіль, 180 с,
перевірка sentinel і стороннього `ERROR:`. Додано лише відбір кейсів за іменем (`ONLY`, `SHARD=i/n`) і, для мутанта,
підміну шляху скрипта (`MUTANT_SCRIPT=<старий>=<новий>`) і батареї (`BATTERY=<файл>`).

**Чесна примітка про базу.** Під час базового прогону (≈ 07:44–07:45:31 UTC) у дереві хвилину лежала моя правка
`CityProps.gd` (лише нова гілка невідомого `kind`; чотири відомі `kind` ставлять ті самі сцени). Кейси, що стартували в
цьому вікні (машинні й автомобільні негативи), бачили її; невідомого `kind` жоден із них не викликає. Я прибрав правку
(`git diff > G/cityprops.patch`, `git checkout`) і повернув після бази. Числа «до» нижче — з цього прогону.

## Як зроблено

### 1. Родини в sentinel `city-tidy` (YELLOW 2, кандидат класу 18)

`tools/world/city_tidy_check.gd`:
- `_check(ok, label, family = "")`. Червона перевірка додає родину в `red` і друкує `CITY_TIDY: [родина] мітка`.
  Родина — тег гарда, перше слово мітки до `/`, малими, без дефіса: `C1` → `c1`, `K4/Н1` → `k4`, `V-M` → `vm`,
  `MC10` → `mc10` (`_family()`).
- Два гарди мають підгарди, і виклики називають їх явно:
  - **V+:** `vstep` (неперелічений або зниклий щабель), `vwedge` (новий клин і підсумок), `vopen` (закріплений OPEN
    зник або зсунувся), `vgrow` (OPEN ширший чи глибший);
  - **MC7:** `mc7hull` (тверде над вулицею), `mc7arm` (машини змінюють арм), `mc7cross` (грань між лінзою й героєм),
    `mc7s3` (арм на S3 = 6,00 м), `mc7seen` (лінза бачить точку нижче 4,0 м).
- Підсумковий рядок: `CITY_TIDY_COMPLETE checks=N failures=M mutation=<m> red=<родини через кому|none>`.

`tools/gates/playable_check.sh`: позитив `city-tidy` вимагає `… mutation=none red=none`. Кожен негатив — пару
`(mutation, family)` і sentinel `… mutation={mutation} red=[a-z0-9,]*\b{family}\b[a-z0-9,]*`, як у `rope-pull` /
`rope-choice`. Рядків кейсів не видалено. Кожен із 69 старих sentinel — дослівно старий плюс суфікс ` red=…`; скрипт,
аргументи й очікуваний rc ті самі. Це перевірено розбором `cases` обох версій (`git show HEAD:…` проти дерева):
`69 = 69`, некейсів `city-tidy` змінено 0.

Родину кожного негатива я брав із наміру, записаного в його коментарі, і звіряв із тим, що він реально червонить на базі.
Для цього `G/families_from_errors.py` вивів родини з міток `ERROR: CITY_TIDY:` базових логів за тим самим правилом. У
всіх 68 базових негативів намічена родина вже була червоною — до того, як sentinel цього вимагав.

| родина | негативи |
|---|---|
| `c1` · `c2` · `c3` · `c4` | pane_strut, pane_wire · float_barrel, float_loaf, sink_crate, float_plate · zfight_fascia, zfight_jamb · dup_wall, dup_barrel |
| `c5` · `d17` | solid_planter, solid_dressform, solid_sign, pump_spout, pump_lever, pump_layer · service |
| `k` · `k4` · `k6` · `k7` | anchor · ink_strip · court, lane · passage |
| `v` · `s` | vault_high, vault_deep · steam_hero, steam_flash |
| `m1`…`m8` · `vm` | vehicle_layer · vehicle_material · vehicle_float, vehicle_sink · vehicle_nocollider, vehicle_shift · vehicle_anchor · vehicle_lane · vehicle_runup · vehicle_gap · vehicle_vault |
| `mc1`…`mc6` | machine_layer, machine_nocollider · machine_material, machine_brass · machine_float, machine_sink · machine_shift · machine_column, machine_anchor · machine_pocket, machine_lane |
| `mc7hull` · `mc7arm` · `mc7cross` · `mc7seen` | machine_street_hull · machine_cross · machine_occlude · machine_seen_hook, _street, _float, **_low** |
| `mc8` · `mc9` · `mc10` · `vmc` | machine_gap · machine_slot · machine_budget · machine_vault |
| `vstep` · `vwedge` · `vopen` · `vgrow` | step_new, step_low, step_moved, machine_step · wedge_wall, wedge_round, wedge_deep · wedge_open · wedge_more, wedge_deeper |
| `m0` (нове, п. 2) | glb_standin, glb_silent, glb_both, glb_swap |

Два вибори варто назвати. `vehicle_nocollider` (знято корпус котла вантажівки) вимагає `m4`: у M1 немає переліку корпусів
(на відміну від MC1), тож зняття ловить лише M4 — грань без колайдера. `machine_cross` (кран на вулиці між героєм S3 і
лінзою) вимагає `mc7arm`, а не `mc7cross`: колона скорочує арм, лінза опиняється перед краном, і `crossing` = 0. Так і
сказано в його коментарі: «its column takes the arm».

**Негатив біля порогу MC7 seen** — `machine_seen_low`: той самий декор крана, що й у `machine_seen_hook` (блок
0,3 × 0,8 × 0,3 м, (29,3; ·; −8,8), над вулицею за краєм тераси), але низом на 3,9 м (3,9–4,7). Він вимагає `mc7seen`.

### 2. Невідомий `kind` у `CityProps._place_glb` (YELLOW 5)

`game/scripts/world/CityProps.gd`:
- `match` без запасного: `steam_truck`, `steam_car_tarp`, `steam_crane`, `steam_winch`, інакше `_refuse_kind(spec,
  prefix)` і `return null`. `_refuse_kind` друкує `push_error("CITY_PROPS: <prefix><id> asks for kind «…», which has no
  GLB: nothing placed")`. Префікс і «нічого не ставити» — як у наявній гілці невідомого матеріалу (`:318`).
- `_vehicle` і `_machine` виходять на `null`.

Ручний зонд `G/probe/unknown_kind_probe.gd` кличе продукт без override:
- **база** `407595d` (`git show HEAD:…` на хвилину в дереві, потім повернуто): `PROBE unknown -> res://…/prop_steam_car_tarp_v1.glb children=1 solids=4`, помилки немає (`G/probe/unknown_kind_probe_base.log`);
- **після:** `ERROR: CITY_PROPS: Vehicle_probe asks for kind «steam_bus», which has no GLB: nothing placed`, `PROBE unknown -> null children=0 solids=0`; відомий `steam_car_tarp` → свій GLB, 4 тіла (`G/probe/unknown_kind_probe.log`).

**Гард M0** у `city_tidy_check.gd` (родина `m0`, фаза `kind`: позитив і `glb_*`). `KindProbe extends CityProps` поза
деревом. Його єдиний override — `_refuse_kind`: він записує відмову замість друку, бо позитив батареї не має права
друкувати `ERROR:`. `_place_glb` — продуктовий.
- Для кожного `kind` з `VEHICLES` + `MACHINES` `_place_glb` ставить `res://assets/props/city/prop_<kind>_v1.glb` (шлях
  — з назви `kind` за іменуванням реєстру, не з таблиці коду), без відмов. Вузол `Vehicle_|Machine_<id>` живого
  кварталу — та сама сцена.
- Для `steam_bus`, `""`, `Steam_Truck`, `steam_truck_v2` повертається `null`, без нових вузлів, без нових тіл, і рівно
  одна відмова з цим `kind`.

Позитив: 12 перевірок, рядок `CITY_TIDY_INFO M0 listed=4 unknown=4 probe_nodes=4 refusals=4`.

**Предмет: для всіх `kind`: `_place_glb` ставить GLB саме цього `kind`, а невідомий відмовляється один раз і не ставить нічого.**
Чотири форми зламу (`_place_glb` зламаний лише в зонді, `KindProbe.form`):
- `glb_standin` — невідомий `kind` стає вантажівкою, без відмови;
- `glb_silent` — нічого не ставить і нічого не каже;
- `glb_both` — відмовляє, але ставить вантажівку;
- `glb_swap` — кран ставиться як лебідка.

### Варіанти перевірки п. 2, які я відкинув

| варіант | чому ні |
|---|---|
| Кликати продуктовий `_place_glb` у позитиві й ловити помилку `Logger` | `push_error` друкує `ERROR: CITY_PROPS:`, а позитив батареї з будь-яким `ERROR:` — FAIL. Заглушити `Engine.print_error_messages = false` не можна: зонд `G/probe/logger_probe.gd` показав `PROBE lines=0` — приглушена помилка до `Logger` не доходить |
| Дозволити в батареї рядок `ERROR: CITY_PROPS: …` для `city-tidy` | Послаблює чистоту позитивних логів. Свідомий `ERROR` у позитиві суперечив би підсумкам «0 ERROR у позитивних логах» |
| Чиста функція `kind → сцена` без помилки | Не перевіряє, що `_place_glb` не ставить нічого, а негатив без override продукту неможливий |
| **Override одного методу відмови (обрано)** | Так само, як фікстура вже перекриває будівельні методи (`PropsRec`, `MarketRec`). Що продуктова відмова справді друкує помилку й повертає `null`, показує ручний зонд вище |

## Перевірка

### Батарея `city-tidy*`, до і після

| | кейсів | негативів | PASS | команда / лог |
|---|---|---|---|---|
| до (`407595d`) | 69 | 68 | 69/69 | `ONLY='city-tidy.*'`, 3 шарди → `G/before/shard*.out`: `PLAYABLE CHECK: 23 scenarios, 0 failures` ×3 |
| після | 74 | 73 | 74/74 | те саме → `G/after/shard*.out`: `25, 0` · `25, 0` · `24, 0` |

Уся батарея за розбором `cases`: було 403 кейси / 284 негативи, стало 408 / 289. Видалено 0. Нові:
`machine_seen_low`, `glb_standin`, `glb_silent`, `glb_both`, `glb_swap`.

**Жоден негатив не став зеленим, і жоден не перестав збігатися через звуження.**
- `checks`/`failures` кожного з 68 старих негативів до і після тотожні: `diff G/before/sentinels.txt G/after/sentinels.txt`
  → відрізняються лише 5 нових рядків і позитив, 516 → 528 (+12 перевірок M0).
- Родини, виведені з міток базових логів, і надруковані `red=` після тотожні: `diff G/before/derived.txt G/after/red.txt`
  → ті самі 5 нових рядків і `-` → `none` у позитиві.
- Знахідки «причина справді інша» немає: у всіх 68 намічена родина була червоною вже на базі.

Що sentinel справді вимагає родину, перевірив інакше. У рядку кожного з 73 негативів я вилучив його родину з `red=`
(порожній список → `none`): новий sentinel відкинув усі 73 (inline `python3` над `G/after/logs`).

Нові негативи (`G/after/logs`):

| негатив | `red=` | що червоне |
|---|---|---|
| `machine_seen_low` | `mc3,mc7seen` | `lowest seen 3.90 m` на S2, S3, S4 (без мутації 4,30 / 4,45 / 4,30); MC3 бачить низ блока, `sinks 0.100` |
| `glb_standin` | `m0` | 4 невідомі `kind` → `prop_steam_truck_v1.glb, 1 new nodes, 3 new solids, 0 refusals` |
| `glb_silent` | `m0` | 4 невідомі → `null, 0 new nodes, 0 new solids, 0 refusals` |
| `glb_both` | `m0` | 4 невідомі → `…truck…, 1 new nodes, 3 new solids, 1 refusals` |
| `glb_swap` | `m0` | `kind steam_crane places its own GLB (…prop_steam_winch_v1.glb; want …prop_steam_crane_v1.glb)` |

### Мутант T4: `STREET_SEEN_FLOOR` 4,0 → 2,0

Мутант — той самий рядок, `sed` у копії фікстури:
- стара фікстура + стара батарея (`git show HEAD:…` → `G/mut/*.base.*`), кейси `city-tidy` і `machine_seen_*`;
- нова фікстура + нова батарея, усі 74 `city-tidy*`.

`diff` кожної копії з оригіналом — лише рядок 142 / 161.

| кейс | стара батарея | нова батарея | `red=` під мутантом |
|---|---|---|---|
| `city-tidy` (позитив) | PASS | PASS | `none` |
| `machine_seen_hook` | PASS rc 1 | **FAIL** rc 1 | `mc3` |
| `machine_seen_float` | PASS rc 1 | **FAIL** rc 1 | `mc3,mc4,mc7hull,mc8,vstep` |
| `machine_seen_street` | PASS rc 1 | PASS rc 1 | `mc7seen` (lowest seen 0,00 м < 2,0) |
| `machine_seen_low` | — | **FAIL** rc 1 | `mc3` |
| решта 69 `city-tidy*` | — | PASS | — |

- Стара батарея: `PLAYABLE CHECK: 4 scenarios, 0 failures` (`G/mut/before/run.out`) — мутант непомітний, як у T4.
- Нова: `25, 1` · `25, 2` · `24, 0` (`G/mut/after/shard*.out`) — **3 FAIL із 74**, батарея червона. Отже, ослаблений
  поріг тепер червонить батарею.
- `machine_seen_low` ловить будь-який поріг нижче 3,9 м, тобто ослаблення більше ніж на 0,1 м.

### Команди перед «готово»

- `make check` (`G/make_check.log`, після правок; повтор наприкінці — `G/make_check_final.log`, те саме): rc 0. GDS `перевірено: 144 · не парсяться: 0 · не виміряно: 0 · канарка: FAIL як
  треба`; `[smoke] ALL OK (165 checks) in 19847 frames`; `SMOKE ЗЕЛЕНИЙ`.
- `make gates` (фінальний, після останньої правки журналу, `G/make_gates_final.log`): rc 0. `сторінок: 546 · джерел: 554 · лінків: 9097 · зламаних: 0`; реєстр `187 · у реєстрі: 187`;
  ролей 8 / 0; GDS 144 / 0; `БАТАРЕЯ ЗЕЛЕНА`.
- Скан логів (`grep -E "ERROR|WARNING|leaked"`):
  - `G/after/logs` (74) і `G/new1/logs` (6): у позитиві 0; у негативах рядків `ERROR:` не з `CITY_TIDY:` — 0;
    `WARNING`/`leaked` — 0;
  - `G/mut/*/logs`: те саме, 0 / 0;
  - `make_check.log`: лише рядок smoke з «0.0° error», не помилка.

### Уся батарея `playable_check.sh` (через зміну `CityProps.gd`)

`CityProps.gd` вантажить кожна сцена міста, тож я прогнав усю батарею, а не лише `city-tidy*`:
`ONLY='.*'`, 3 шарди → `G/full/shard*.out`.
- `PLAYABLE CHECK: 136 scenarios, 0 failures` ×3, тобто **408/408 PASS**, rc 0 у кожному шарді.
- Скан 408 логів `G/full/logs` за списком `cases`:
  - 119 позитивних: `ERROR` 0 · `WARNING` 0 · `leaked` 0;
  - 289 негативів: `WARNING` 0 · `leaked` 0. Сторонні `ERROR:` у негативі батарея й так рахує як FAIL — їх 0.

Шардування — мій засіб. Офіційний `make check-playable` іде послідовно, і цілим я його не запускав. Команда, середовище,
ізоляція й таймаут ті самі (heredoc дослівно).

### `git status --short` (дерево `t2g-tree`, без коміту)

```
 M game/scripts/world/CityProps.gd
 M tools/gates/playable_check.sh
 M tools/world/city_tidy_check.gd
?? docs/Fix/2026-10-15-Tidy-Sentinel-Families-Fix.md
```

`git diff --numstat`: `CityProps.gd` +19/−3, `playable_check.sh` +40/−22, `city_tidy_check.gd` +122/−22
(разом +181/−47).

## Що лишилось відкритим

- **Клас 18 загалом.** Родини тепер вимагають усі 73 негативи `city-tidy`. Але негатив біля порогу є лише для MC7 seen.
  Ослаблення інших порогів (`SUPPORT_GAP`, `ANCHOR_COLUMN`, `SLOT_MIN` тощо) ловиться, лише якщо негатив тієї родини
  стоїть ближче до порогу, ніж мутант. Мутантів інших порогів я не ганяв.
- Інші фікстури з `failures=[1-9]` без `red=` у батареї (`city-bounds`, `city-rim-exit`, `city-perch`,
  `city-substances` тощо) — поза задачею. Механізм класу 18 для них — рішення T4 / T1.
- Родина `mc7s3` не має свого негатива: її червонить лише `machine_cross` разом з `mc7arm`.
- `state.md` і реєстр [[recurring_class_register]] не чіпав. Статус у `state.md` пише T1 після зведення гілок, рядок 18
  реєстру веде T4.

## Related
- [[2026-10-15-Wave-14-Review]] · [[recurring_class_register]] · [[2026-10-14-Steam-Crane-Winch-Fix]]
- [[2026-10-14-T6-Crane-Winch-Acceptance]] · [[2026-10-15-Stall-Wedge-Boundary-Fix]] · [[2026-10-15-Colour-Switch-Fix]]
- [[state]]
