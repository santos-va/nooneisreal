# Родини негативів `city-bounds` / `city-perch`, правило раннера і гард відмови `CityProps` — журнал виконання

**Дата:** 2026-10-15 · **Роль:** T2 Гефест (T2-К) · **Статус:** зроблено в дереві без коміту. `make check` і
`make gates` — rc 0; уся батарея 423 / 0 (§ «Батарея»); кожен мутант T4 і новий мутант червонить батарею. Мерж — Santos.
**Задача:** пропозиції 1 і 4 аудиту T4 [[2026-10-15-Wave-14-Review-Part-2]]; клас 18 [[recurring_class_register]]
(«негатив зараховується за будь-яку причину»).

Дерево — scratchpad `t2k-tree`, detached `93ba633`. Не комічу, не пушу. Основне дерево не чіпаю. Кредитів не витрачав.
Логи — scratchpad `t2k/` (далі `K/`). Godot — scratchpad `tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`
(`--version` → `4.7.stable.official.5b4e0cb0f`).

## Звірка задачі з реальністю

| що в задачі | команда / місце | вихід | що роблю |
|---|---|---|---|
| голова дерева | `git log --oneline -1` | `93ba633 Record Santos's rope forks in ADR-028 and approve the rope climb plan`; `git status --short` порожньо | — |
| негативи без `red=` | `K/count_cases.py` (виконує частину `cases` heredoc батареї дослівно; негатив = очікуваний rc 1; «без родини» = у sentinel немає `red=`) | `cases 413 negatives 294 negatives_without_red 164 dupe_names 0` | 164 = число T4; список — `K/nored_base.txt` |
| з них `city-bounds` / `city-perch` / `city-rim-exit` | `grep -E '^(city-bounds\|city-perch\|city-rim)' K/nored_base.txt` | 5 + 3 + 3 | 8 отримують родину; 3 `city-rim-exit` лишаються в замороженому списку (не в задачі) |
| як друкує `red=` `city_tidy_check.gd` | `:496–503`, `:3103–3106` | `_check(ok, label, family="")` → `red[tag] = true`, рядок `… red=<родини через кому або none>` | та сама схема |
| мітки гардів `city_bounds_check.gd` | `grep -o '_check(.*"B[1-5]' …` | усі мітки починаються з `B1`…`B5` | родина = `b1`…`b5` з першого слова мітки |
| мітки гардів `city_perch_check.gd` | те саме | `P1`…`P4` + одна мітка `"%s the dress form's torso collider is there"` | родина `p1`…`p4`, торс — явна `p0` |
| P4 і `mc7s3` без негатива | `grep -n "p4\|mc7s3" tools/gates/playable_check.sh` | порожньо; `city_tidy_check.gd:2576` — єдиний `_check(…, "mc7s3")` | додаю негативи |
| мутанти T4 | `diff` проти голови: `t4-w14b/mut/bounds_b2low.gd` (`:240` `top = 6.0`), `bounds_b5west.gd` (6 рядків `RUNS` прибрано), `perch_p2off.gd` (`:211` `true or`), `perch_p3weak.gd` (`:233` `best <= 120`) | по одному місцю в кожному | той самий мутант накладаю на нову фікстуру |
| `_refuse_kind` | `game/scripts/world/CityProps.gd:341–342`; `KindProbe` у `city_tidy_check.gd:331–335` перекриває без `super` | продуктовий `push_error` не викликається жодним гардом | гард у фікстурі (див. нижче) |
| чи можна зловити `push_error` у тому ж процесі | зонд `K/probe/logger_probe.gd` (`OS.add_logger` + `Engine.print_error_messages = false`) | власний `Logger` бачить помилку лише разом із друком `ERROR:`; з вимкненим друком — не бачить нічого | у позитивному лозі `ERROR:` заборонений → перевіряю в дочірньому процесі Godot |

## Як зроблено

Предмет: для всіх негативів батареї: негатив зараховується, лише коли червоніє в тих родинах, які сам називає.

### 1. `red=` у `city-bounds` і `city-perch` (пропозиція 1)

- `tools/world/city_bounds_check.gd`: `_check` додає тег мітки (`b1`…`b5`) у `red`, друкує `CITY_BOUNDS: [bN] …`;
  sentinel `CITY_BOUNDS_COMPLETE checks=N failures=M mutation=<m> red=<родини|none>`. Поведінка гардів не змінена.
- `tools/world/city_perch_check.gd`: те саме (`p1`…`p4`, торс — `p0`); у рядок `CITY_PERCH_INFO P4` додано кінцеву точку.
- Родини, які дали наявні негативи на цьому дереві (`K/logs/<скрипт>-<m>.log`, команда батареї через `K/run_case.sh`) — ті
  самі, що в T4 (§ 1 її аудиту), і ті самі числа провалів:

| негатив | `failures` | `red=` | вимагає sentinel |
|---|---|---|---|
| bounds `gap` | 7 | b1,b2,b5 | b1 b2 b5 |
| bounds `low` | 17 | b1,b2,b5 | b1 b2 b5 |
| bounds `world` | 12 | b1,b3,b4 | b1 b3 b4 |
| bounds `mesh` | 1 | b1 | b1 |
| bounds `hero` | 23 | b2,b3,b5 | b2 b3 b5 |
| perch `flat` | 9 | p1,p2,p3 | p1 p2 p3 |
| perch `cone` | 5 | p1,p2,p3 | p1 p2 p3 |
| perch `edge` | 3 | p2,p3 | p2 p3 |

  Кожна родина — предмет цього зламу (вуаль зникла / низька / видима світу / намальована / не тримає героя; верх, на якому
  стоять). Sentinel вимагає **всі** свої родини (lookahead на кожну): мутант T4, що вимикає будь-який із цих гардів,
  знімає родину хоча б з одного негатива. Позитиви: суфікс ` red=none`.

### 2. Негативи P4 і `mc7s3`

- **P4** (`city_perch_check.gd`, `RIM_STEPS`): сходинка під щілиною між краєм столу (z 14,05) і ніжкою манекена (z 13,48),
  від західної до східної стіни крамниці. `rim_step` (0,3 м, обидва боки), `rim_west` (лише бік A), `rim_east` (лише бік
  D), `rim_low` (0,08 м — над порогом підлоги 0,05). Кожен → `red=p4` і нічого більше; `rim_west` червоніє лише в A,
  `rim_east` лише в D (`K/logs/perch-rim_*.log`).
- **`mc7s3`** (`city_tidy_check.gd`): не машина, а тіло поперек вулиці за героєм S3 — стіна 4 м на z −3 (арм 2,800 з
  машинами й без: червоніє лише `mc7s3`) і на порозі брус 1 м на z 0, y 2,4–3,4 біля лінзи (арм 5,889, на 0,11 м менше).
  Положення бруса підібране зондом `K/probe/s3_arm_probe.gd` (z 0 → 5,889; 0,05 → 5,940; 0,1 → 5,992; 0,15 → 6,000).

### 3. Гард продуктового `_refuse_kind` (пропозиція 4) — гра не змінена

`KindProbe` лишається (позитивний лог без `ERROR:`). Новий `_m0_refusal_log()` у M0 запускає дочірній Godot — той самий
скрипт із `--refusal-child=<форма>`; дитина кличе **продуктовий** `CityProps._place_glb` на `steam_bus`. Батько рахує
в її виводі рядки `ERROR: CITY_PROPS: …Refusal_probe…«steam_bus»…nothing placed` (має бути 1), інші рядки з тими самими
словами (0), рядок дитини `placed=null nodes=0 solids=0`, rc 0; у свій лог друкує лише лічильники. Родина `m0log`.
Негативи (`RefusalBreak` у дитині): `refuse_silent` (форма `KindProbe`: нічого не друкує), `refuse_print`,
`refuse_warning`, `refuse_twice`. Дитина ≈ 0,45 с (`K/probe/exec_probe.gd`: `rc=0 ms=446`).

### 4. Правило раннера (`playable_check.sh`, логіка після `isolated_profile`)

Перед першим кейсом: негатив (rc 1) без `red=` у sentinel поза `tools/gates/playable_unfamilied_negatives.txt` →
`PLAYABLE REFUSED`, rc 2. Список лише скорочується: кейс зі списку, що вже має `red=` (або не негатив), → rc 2, доки не
вийде зі списку; у списку рівно `UNFAMILIED_CEILING = 156` імен (дублікати теж → rc 2). Вбудована канарка щоразу:
вигаданий негатив без `red=` мусить бути відмовлений, з `red=` — ні; інакше rc 2. Рядок `PLAYABLE FAMILIES: …`.
Підрахунок списку: `K/count_cases.py tools/gates/playable_check.sh` → `cases 423 negatives 304 negatives_without_red 156`
(на `93ba633` — 164; мінус 8 негативів bounds/perch). Рядки T2-И (трос) раннер не чіпає; блок правила стоїть у логіці.

## Перевірка

### Мутанти (п. 5): підбатарея через `run_subset.py` (heredoc батареї дослівно, `MUTANT_SCRIPT=<скрипт>=<мутант>`)

«До» — оригінальні файли T4 (`t4-w14b/mut/*.gd`) проти раннера `git show HEAD:tools/gates/playable_check.sh`
(`K/mutrun_before.sh`, логи `K/mutrun_before/`). «Після» — той самий однорядковий мутант, накладений на нову фікстуру
(`K/mut/*.gd`, різниця з деревом — 2 рядки `diff`, у `b5west` — 6 прибраних рядків `RUNS`), проти нового раннера
(`K/mutrun.sh`, логи `K/mutrun/`).

| мутант | до (раннер `93ba633`) | після | що почервоніло (sentinel) |
|---|---|---|---|
| T4 B2 лише до 6 м | 6 / 0 FAIL | 6 / 1 FAIL | `bounds-negative-low`: `red=b1,b5` — немає `b2` |
| T4 B5 лише захід | 6 / 0 FAIL | 6 / 1 FAIL | `bounds-negative-gap`: `red=b1,b2` — немає `b5` |
| T4 P2 вимкнено | 4 / 0 FAIL | 8 / 3 FAIL | `flat` `red=p1,p3`, `cone` `p1,p3`, `edge` `p3` — немає `p2` |
| T4 P3 до 120 тиків, без висоти | 4 / 0 FAIL | 8 / 3 FAIL | `flat` `p1,p2`, `cone` `p1,p2`, `edge` `p2` — немає `p3` |
| P4 лише D | — | 8 / 1 FAIL | `rim_west`: `red=none` |
| P4 лише A | — | 8 / 1 FAIL | `rim_east`: `red=none` |
| P4 поріг 0,5 м | — | 8 / 4 FAIL | усі чотири `rim_*`: `red=none` |
| P4 поріг 0,1 м | — | 8 / 1 FAIL | `rim_low`: `red=none` |
| `mc7s3` поріг 5,5 м | — | 5 / 1 FAIL | `machine_s3_edge`: `red=none` (`machine_s3_wall` тримає) |
| `mc7s3` вимкнено | — | 5 / 2 FAIL | обидва `machine_s3_*`: `red=none`; `machine_cross` PASS (вимагає `mc7arm`) |
| `m0log` вимкнено | — | 9 / 4 FAIL | усі `refuse_*`: `red=none` |
| `m0log` «≥ 1 помилки» | — | 9 / 1 FAIL | `refuse_twice`: `red=none` |

Кожен позитив під мутантом — PASS (`city-bounds`, `city-perch`, `city-tidy` у кожній підбатареї).

### Канарки правила раннера (`K/runner_canaries.sh`, логи `K/canary/<форма>.out`)

Кожна форма — копія раннера й списку в окремому корені; копія зупиняється (rc 0, рядок `CANARY STOP`) одразу після
правила, тобто до першого кейсу.

| форма | rc | рядок |
|---|---|---|
| без змін | 0 | `PLAYABLE FAMILIES: 304 negatives, 156 of them without red= and listed (ceiling 156); canary refused` |
| вигаданий негатив без `red=` | **2** | `PLAYABLE REFUSED: invented-negative-x: a negative whose sentinel names no family (red=), not listed …` |
| вигаданий негатив з `red=` | 0 | `PLAYABLE FAMILIES: 305 negatives, 156 …` |
| у список додано ім'я | **2** | `… holds 157 names (157 distinct), UNFAMILIED_CEILING is 156 …` |
| ім'я зі списку прибрано, кейс без `red=` | **2** | `city-rim-exit-negative-old: a negative whose sentinel names no family …` + `holds 155 names` |
| кейс зі списку отримав `red=` | **2** | `city-rim-exit-negative-old: listed … but names its family now: remove it and lower UNFAMILIED_CEILING` (×3) |
| дубль у списку | **2** | `holds 156 names (155 distinct)` + незагальнений кейс |
| файлу списку немає | **2** | `… unreadable ([Errno 2] …)` |
| правило зламане (ловить лише `city-*`) | **2** | `the rule is broken: its canary gave []` |
| ім'я додано **і** стелю піднято до 157 | 0 | — механізм у дереві цього не бачить: видно лише в diff (див. «Відкрите») |

### Батарея, логи, базові команди

| що | команда | вихід |
|---|---|---|
| рядки кейсів | розбір `cases` до/після (`K/pc_head.sh` = `git show HEAD:…` проти дерева) | 413 → 423; видалено 0; додано 10 (`rim_*` ×4, `machine_s3_*` ×2, `refuse_*` ×4); змінено 10, у кожного новий sentinel = старий + суфікс (` red=none` або ` red=` з lookahead родин) |
| уся батарея | `run_subset.py` з деревом, `ONLY='.*'`, `SHARD=0/3`, `1/3`, `2/3` паралельно (`K/battery/shard*.out`, логи `K/battery/playable/`) | `PLAYABLE CHECK: 141 scenarios, 0 failures` ×3, rc 0 ×3 → **423 / 0**; `PLAYABLE FAMILIES` 99 + 102 + 103 = 304 негативи, 53 + 52 + 51 = 156 у списку; canary refused |
| скан логів | `K/scan_logs.py` | 423 логи, 0 відсутніх; 119 позитивів: ERROR 0, WARNING 0, «leaked» 0; 304 негативи: `SCRIPT ERROR` 0; `PLAYABLE TIMEOUT` 0 |
| `make check` | `GODOT_BIN=… make check` (`K/make_check_final.log`) | rc 0; GDS `перевірено: 144 · не парсяться: 0 · не виміряно: 0 · канарка: FAIL як треба`; `[smoke] ALL OK (165 checks) in 19847 frames` |
| `make gates` | `GODOT_BIN=… make gates` (`K/make_gates.log`) | rc 0, `БАТАРЕЯ ЗЕЛЕНА`; 553 стор., 9251 лінк, 0 зламаних; реєстр 187/187; GDS 144/0 |
| `--check-only` фікстур | `godot --headless --path game --check-only --script <файл>` для трьох `.gd` | rc 0 ×3 |
| `game/` | `git status --short game \| wc -l` | 0 — гра не змінена (гард `_refuse_kind` зроблено у фікстурі) |

**Чесна примітка про батарею.** Батарея стартувала о 14:11:59 UTC. О 14:13:16 і 14:13:58 я змінив лише коментарі в
шапках `city_tidy_check.gd` (рядок про `m0log`) і `city_perch_check.gd` (перенос рядка sentinel); `--check-only` обох
після цього rc 0. За порядком шардів (старт кейсу = кінець попереднього логу в шарді) жоден кейс цих двох скриптів не
стартував раніше правки: перший `city-tidy.log` записаний о 14:16:12. Перепрогін не знадобився.

`git status --short` (кінець роботи):

```
 M tools/gates/playable_check.sh
 M tools/world/city_bounds_check.gd
 M tools/world/city_perch_check.gd
 M tools/world/city_tidy_check.gd
?? docs/Fix/2026-10-15-Negative-Families-Runner-Fix.md
?? tools/gates/playable_unfamilied_negatives.txt
```

## Що лишилось відкритим

- **Стеля списку піднімається разом зі списком.** Додати ім'я в `playable_unfamilied_negatives.txt` і підняти
  `UNFAMILIED_CEILING` до 157 — механізм у дереві цього не бачить (канарка `list_grows_ceiling` → rc 0). Видно в diff
  одного числа; перевірка «стеля не росте» потребує історії git (гейт у `make gates`) — не зроблено, рішення T1/T4.
  *Пізніше (T2-О):* гейт СТЕ, формат списку `ім'я|скрипт|аргументи` і решту обходів аудиту T4 закрито —
  [[2026-10-15-Runner-Rule-Bypass-Fix]].
- **3 негативи `city-rim-exit`** (`old`, `wall`, `near`) — у замороженому списку, без родини (поза задачею).
- **Злиття з T2-И.** Правило раннера відмовить (rc 2) будь-якому новому негативу без `red=`, зокрема тросовим кейсам
  T2-И, якщо їхні sentinel не називають родину. Список доповнювати не можна — родину називає сам кейс.
- `state.md` і реєстр класів не чіпав (T1 і T4).

## Related
- [[2026-10-15-Wave-14-Review-Part-2]] · [[recurring_class_register]] · [[2026-10-15-Tidy-Sentinel-Families-Fix]]
- [[2026-10-15-Stall-Wedge-Boundary-Fix]] · [[state]]
