# Аудит хвилі 15а — трос у місті (T2-И) і правило раннера класу 18 (T2-К)

**Дата:** 2026-10-15 · **Роль:** T4 Феміда (вердикт подано текстом; інструменти лише для читання) ·
**Предмет:** зведене дерево scratchpad `t4c-tree`: detached `93ba633` + індекс. `git -C t4c-tree diff --cached --stat HEAD` →
41 файл, 3760+ / 78−; `git status --short` → лише індексовані зміни. Джерела тотожні дереву повної батареї T1:
`sha256sum` по `git ls-files -co game tools Makefile` → 948 рядків, `diff` з `battery-w15/src.before` порожній.
Логи, мутанти, скрипти — scratchpad `t4-w15/` (далі `Ф/`). Мутанти — у копіях `Ф/mut-tree` і `Ф/k-tree`; `t4c-tree` не
змінювала. Кейси ганяла командним рядком батареї (`Ф/bin/mrun.sh`, `run_subset.py` з тілом раннера дослівно). Повну
батарею не запускала — її логи T1 (`battery-w15/`).
**Вердикт: RED.** Два RED: позитив `blood-content` червоний; правило «змотати з ≤ 14 м» і «E відпускає, швидкість
зберігається» гарди не ловлять (продуктові мутанти зелені).

| # | пункт | вердикт | доказ (команда цієї сесії → вихід) |
|---|---|---|---|
| 0 | базові команди | **RED** | `make check` → rc 0: GDS 144/0, канарка «FAIL як треба», `[smoke] ALL OK (165 checks) in 19847 frames` (`Ф/make_check.log`). `bash tools/gates/run_gates.sh` → rc 0, 554 стор. / 9280 лінків / 0 зламаних, реєстр 187/187 (`Ф/gates_full.log`). `git diff --cached --stat HEAD -- game/assets docs/Art/Textures-Registry.md` → порожньо. **Батарея T1:** три шарди `PLAYABLE CHECK: 153/0, 153/1, 152/0` → 458 / 1; FAIL — `blood-content`. Мій перепрогін у `t4c-tree` → `BLOOD_CONTENT_COMPLETE checks=74 failures=3` (§ 1) |
| 1 | ADR-028 п. 1–5, 8 у коді | GREEN | § 2 |
| 2 | дуель біт у біт | GREEN | § 3 |
| 3 | гарди під нове правило | **RED** | 17 нових негативів червоніють кожен у своїй родині. З 25 моїх продуктових мутантів ловиться 20 (3 — лише побічно), 1 еквівалентний, 4 зелені: змотування з 16 / 20 м, E обнуляє швидкість, вікно липкості 5 тиків (§ 4) |
| 4 | закріплення | YELLOW | `KNOWN_CUTS` 11, `KNOWN_DENIED` 18, `OPEN_AIR` 61 / 58, `KNOWN_TRANSFER_CUTS` 2 + 2 — збігаються із заміром. Клас 17: ключі вузькі, але відмови й перемотки переходу (заміряно 0) не закріплені (§ 5) |
| 5 | правило раннера T2-К | YELLOW | список 156 = множина негативів без `red=`; мої B2 / B5 / P2 / P3 червонять підбатарею; продуктовий мутант `_refuse_kind` → `red=m0log`. Канарки: слабке `red=`, «привид» у списку і ріст стелі → rc 0 (§ 6) |
| 6 | дефект G біля NPC на тросі | GREEN | `CityNpcDirector.can_talk`: `grapple.busy()` → `false`. Мутант (перевірку вимкнено) → `rope-climb-rules-choko` `red=talk` |
| 7 | кадри T2-И | GREEN (факт) | 12 файлів, 90 542…139 573 байт, кожен рядком у [[Screenshots]] рівно раз. Що на них — § 7; художнє приймання — T6 |
| 8 | документи | YELLOW | `## Related` у 2 нових Fix і в [[Screenshots]]; wikilinks 0 зламаних. Дрібне: шапка Fix T2-И «у роботі», застарілий коментар, журналу зустрічі хвилі ще немає (§ 8) |
| 9 | рецидиви | — | клас 5 +1, клас 15 +1, клас 18 — механізм частковий, кандидат 19 (§ 9) |

## 1. RED — позитив `blood-content`

- Командний рядок батареї через `run_subset.py`, `ONLY='blood-content'`, дерево `t4c-tree` → `PLAYABLE CHECK: 1 scenarios, 1 failures`,
  `checks=74 failures=3` (`Ф/bc/blood-content.log`):
  - `the desktop ring follows the T8 literals (… → DrugsMode → RopeClimb → @Button…)`;
  - `Down from DRUGS reaches RESTORE`;
  - `the phone ring: the same without DISPLAY …`.
- Причина: `ComfortPanel.gd` T2-И вставляє рядок `RopeClimb` перед RESTORE (`_focus_order.append(rope_climb_choice)`). Кільце —
  літерал T8 ([[06-UI-UX]] «Випадки міста: COMFORT і HUD» п. 1) у `blood_content_check.gd:274, :319, :330`. Ні T8-текст, ні
  фікстура не оновлені.
- На тих самих джерелах без тросу `blood-content` зелений: `t2k/battery/playable/blood-content.log` і `battery-w14s` →
  `checks=74 failures=0`. Підмножина T2-И (244 кейси, Fix § 5а) цей кейс не містила.
- Побічно (клас 18, спадок): `blood-content-negative-{cfg,drugs_row,flash}` у списку без родини дають по 5 провалів, і 3 з
  них — це ці самі кільця. Тобто зараз вони зараховуються й за чужу причину.

## 2. ADR-028 п. 1–5, 8 у коді (GREEN)

- **Прапор.** `grep -rn "climb_enabled\s*=" game tools` → `CityFighter.gd:56` (`= true`) і `rope_climb_check.gd:807` (канарка
  дуелі). `responsive_parkour` його не ставить. Мутант «прапор `true` за замовчуванням» → `rope-climb-duel` `red=duel`.
- **Угору 3,6 до звису.** `GrappleHook.climb_speed = 3.6`; крок `min(climb_speed·dt, L − 2,0)`; на 2,0 з утриманим Space —
  `_begin_climb_top`. Мій прогін 35 нових кейсів (`Ф/new/run.out` → `35 scenarios, 0 failures`): 50 лазінь (25 якорів × 2
  героя) — усі `pull_up=30 grip=0.3000 feet=-1.3200 held=179`. `rope-climb-1…5` → `checks=103/103/103/99/107 anchors=10/10
  perched=10 blocked=0`.
- **Униз 2,0.** `slide_speed = 2.0`, межа `record.length`, підлога → `_release` того ж тику. Мутанти «без межі довжини» →
  `pull` `red=slidelength`; «на підлозі не відпускає» → `red=slidefloor` (450).
- **Звис 3 с (+1 «Сила»).** `perch_limit()` = `parkour.hang_limit` = `hang_seconds` 3,0 (`CityParkourProfile.gd:14`) + бонус
  «Сили». Мутант +2 с → `rules` `red=grip`.
- **E без цілі, липкість 15.** `CityFighter.ROPE_STICKY_TICKS := 15`; `rope_e_lets_go()`: мотузка в 0,70 м або показана
  ціль → перехід, інакше `ticks_since_target() ≥ 15` → `let_go()` (швидкість не чіпає). Мутанти «ніколи не відпускає» →
  `traversal` `red=empty`, `rules` `red=perch_e`; «вікно 0» → `red=flicker`; «вікно 30» → `red=empty`. Вікно 5 — зелене (§ 4).
- **Змотування.** `reel_candidate` / `begin_reel`: своя, ніхто не висить, рука → якір ≤ `range_m` (14 з `.tres`), вільна
  лінія; далі `MISS_REWIND` з `rewind_speed = 9.0`. Гард П-3 (`d / 9 ± 1 тик`, рух × 0,35, пауза ухиленням) — зелений.
  Межа 14 м гардом не ізольована (§ 4).
- **+1 на звисі, інваріант.** `_grip_anchor` → `MatchRopes.retrieve` (запис знято, `_notify(owner)`). 50 лазінь: `stock 6→7`
  × 25, `1→2` × 25. Мутанти «+2» і «нічого не повертає» → `climb1` `red=inventory`.
- **Ухилення з троса прибрано, буфер забирається.** `CityFighter._tick_grapple`: на `HANG`/`CLIMB_TOP` щотакту
  `InputRouter.buffered(…, "dodge")` і `"dash"`. Мутант «буфер не забирається» → `rules` `red=dodge` (P7).
- **Ввід (п. 8).** `git diff --cached --stat HEAD -- game/project.godot game/data` → порожньо; нових дій немає. COMFORT
  `ROPE CLIMB`, `settings.cfg [input] rope_climb`, типово `hold`.

## 3. Дуель біт у біт (GREEN)

База — `t2i/base-tree`, звірена з комітом: `git archive 93ba633 game tools Makefile` → 944 файли, `sha256sum -c` у
`t2i/base-tree` → rc 0. «Після» — `game` з `t4c-tree` + `tools` бази (ті самі фікстури). `Ф/bin/duel_cmp.sh`:
- `smoke.log` — однакові (171 рядок);
- зонд T3 `duel_rope_probe.gd`: `choko_shared`, `skea_solo`, `skea_shared` — однакові; `choko_solo` — тіло 20 рядків однакове
  (`cmp <(head -20 …)`), у базі хвіст `6 ObjectDB instances were leaked` — гонка аудіо зонда з `quit`, у базі теж;
- 12 дуельних кейсів батареї (`combat-control`, `match-lifecycle`, `harpoon`, `harpoon-aim`, `free-movement`, `limb-combat`,
  `dodge-stamina`, `rope-visual`, `rope-recovery`, `rope-contact`, `traversal`, `weighted-swing`) — 12/0 PASS в обох,
  `cmp` після заміни шляху дерева → 12 / 12 однакові.

## 4. Гарди (RED)

**Негативи T2-И** (мій прогін, `Ф/new/playable/*negative*`) — кожен у своїй родині: `double` → `inventory`; `far`, `hung` →
`reel_refuse`; `duel_flag` → `duel`; `tie_rod` → `perch`; `overlong` → `slidelength`; `stuck` → `slidefloor`;
`transfer_skip`, `late_wall` → `cut`; `drop_on_flicker` → `flicker`; `stay_on_empty` → `empty`; `boost` → `e6`; `fast` →
`climb_rate`; `lift` → `perch`; `noreq` → `e1,e2,noreq`; `perpetual` → `e1,e2`; `twosided` → `e2`.

**Старе правило не просто прибране.** У `weighted_swing`, `traversal`, `contact`, `rope_pull`, `rope_choice` зникли лише
сигнатури `check()` і один літерал довідки (`git diff … | grep "^-.*check("`). Дуельні рядки лишились. Міські 1,2 м
замінено на Л-а…Л-в.

**Мої продуктові мутанти** (`Ф/bin/mut.py`, матриця `Ф/mut/matrix.out`; кейси: `weighted-swing`, `traversal`, `rope-contact`,
`rules-choko`, `duel`, `climb 1/5 choko`, `transfer 3/5 choko`, для руху — `rope-pull --hero=choko`; база — усі rc 0):

| мутант (продукт) | що почервоніло |
|---|---|
| лазіння без Space (`climb_input >= 0`) | ws `e1,e2,noreq`; traversal; contact; rules `arm,toggle`; transfer `cut,open`; pull |
| лазіння 4,2 м/с | ws, climb1 `climb_rate` |
| лазіння нижче 2,0 (до 1,5) | ws, climb1 `climb_rate`; pull `target` |
| на підлозі не відпускає | pull `slidefloor`; rules `hud,reel,reel_refuse` |
| спуск за `record.length` + 3 | pull `slidelength` |
| ухилення: буфер не забирається | rules `dodge` |
| звис 5 с | rules `grip` |
| ціль зі звису ≥ 1,5 м | rules `perch_shot` |
| власний якір як ціль | rules `perch_e` |
| +2 на звисі | climb1 `inventory` |
| нічого не повертається | climb1 `inventory`; rules `perch_e,perch_shot` |
| E ніколи не відпускає | traversal `empty`; contact; rules `perch_e` |
| вікно 0 / 30 | traversal `flicker` / `empty` |
| перехід без пропуску старого стовпа | transfer `cut` (`cut_first=3 open=1`) |
| прапор `true` за замовчуванням | duel `duel` |
| G говорить на тросі | rules `talk` |
| типово TOGGLE | лише pull `slidefloor,sliderate` (див. Y3) |
| лазіння 1,8 / спуск 1,0 м/с | лише rules `toggle` (пороги P12, див. Y2) |
| спуск під час тяги | нічого — еквівалентний: `if pull/reel … elif slide` у `drive` уже не подовжує під тягою |
| **змотування з 20 м** | **нічого** |
| **змотування з 16 м** | **нічого** |
| **E-відпускання обнуляє швидкість** | **нічого** |
| **вікно липкості 5 тиків** | **нічого** |

- **RED-а: «з відстані до 14 м» (ADR п. 4) не судиться.** Мій зонд — копія гарда з одним `print` у П-4 (`Ф/probe/reel-probe.log`):
  `far … dist=16.839 line_clear=false offered=false`. Відмова «за 14 м» — через закриту лінію, не через відстань. Продукт
  може змотувати з будь-якої відстані при вільній лінії, і гард зелений.
- **RED-б: «цілі немає — відпустити, швидкість зберігається» (ADR п. 5, T5 Е1).**
  - `traversal_check.city_transfer` ставить `city.velocity = Vector3.ZERO` (`:424`), тож `city.velocity == velocity` порівнює нуль із
    нулем.
  - Е-6 у `weighted_swing_check.gd:412–420` кличе `hook.let_go()` напряму, повз шлях E у `CityFighter`.
  - Мутант `velocity = Vector3.ZERO` після `let_go()` на E — зелений у всіх 8 кейсах.
- **YELLOW.** Вікно липкості судиться лише в межах (3; 20] тиків: вікно 5 — зелене, хоча T5 Е2 вимагає ≥ 6.

## 5. Закріплення (YELLOW)

- `OPEN_AIR`, мій прогін `rope_pull_check --hero=choko|skea` → `in the air 61 ticks (pinned ≥ 61 − 2)` / `58 … (≥ 58 − 2)`;
  `checks=9472 / 10112 failures=0`. «Ті самі».
- `KNOWN_CUTS` / `KNOWN_DENIED` — логи T1 `rope-choice-*` (10 / 10 PASS): OPEN Choko 1+0+2+1+0 = 4, Skea 2+0+2+1+2 = 7 (= 11);
  DENIED 5+1+2+1+2 = 11, 4+0+0+1+2 = 7 (= 18). Мої прогони `choko 1/5`, `skea 1/5`, `skea 5/5` → ті самі рядки OPEN / DENIED
  (md5 відсортованих рядків = T1).
- `KNOWN_TRANSFER_CUTS` — мій прогін 10 частин `--transfer`:
  - `presses` 4 + 2 + 7 + 3 + 5 = 21 на героя, `hangs = presses`;
  - `cut_first = open`: частини 3 і 5 в обох героїв → 2 + 2 = 4 записи (22 → 19, 14 → 22);
  - `S7B … held=true` × 2.
- Клас 17: ключ `герой|перехід|блокер` + точка ± 0,1 м, «більше не стається → червоне» (`rope_choice_check.gd:223–225`).
  Ширше за дефект — ні.
- Але `rewinds=[0-9]+ denied=[0-9]+` у сентинелі переходу не закріплені: заміряно 0 / 0 у всіх 10 частинах. Відмова
  переходу «друкується, не провалює», хоча в звичайному режимі такі натиски закріплені (`KNOWN_DENIED`).
- Дрібне: коментар `rope_choice_check.gd:45` «(none so far)» — при 4 записах.

## 6. Правило раннера T2-К (YELLOW)

- **Підрахунок.** Мій розбір `cases` (`Ф/bin/cases.py`): голова 413 / 294 негативи / 164 без `red=`; зведене 458 / 321 / 156.
  Список: 156 імен, 156 різних, множина = 156 негативів без `red=` (`equal True`). Жоден негатив із `red=` не приймає
  `red=none`, `red=zzz` чи порожнє.
- **Діф кейсів.** Видалено 0, додано 45, змінено 10. Кожен змінений має новий sentinel = старий + суфікс (` red=none` або
  lookahead родин).
- **Канарки** (`Ф/bin/rule_canary.py`, копія тіла раннера до першого кейсу; `Ф/canary/rule_canaries.out`):

| форма | rc |
|---|---|
| без змін | 0, `321 negatives, 156 … (ceiling 156)` |
| новий негатив без `red=` | **2** |
| новий негатив із `red=[a-z_,]*` (родини не вимагає) | **0** |
| новий негатив із `red=(none\|[a-z,]+)` | **0** |
| кейс зі списку видалено з раннера (ім'я лишилось) | **0**, `155 of them … (ceiling 156)` |
| те саме ім'я віддано новому негативу без родини | **0** |
| ім'я додано і стелю піднято до 157 | **0** |

- **Мої мутанти класу 18** на нових фікстурах (`Ф/k-tree/tools/world/t4_*.gd`, `MUTANT_SCRIPT`). Кожна підбатарея rc 1:
  - B2 до 6 м → `bounds-negative-low` FAIL (`red=b1,b5`);
  - B5 лише захід → `gap` FAIL (`red=b1,b2`);
  - P2 вимкнено → `flat`, `cone`, `edge` FAIL (без `p2`);
  - P3 до 120 тиків → ті самі три FAIL (без `p3`).
- **`push_error` у `_refuse_kind`.**
  - Лог батареї `city-tidy` → `M0 refusal child form=none rc=0 errors=1 other=0 done=true`, `checks=529 failures=0`.
  - Мій продуктовий мутант (`push_error` → `push_warning` у `CityProps.gd:342`) → `city-tidy` FAIL, `errors=0 other=1`,
    `red=m0log`.
- **Чи потрібен механізм для «список + стеля».** Так. Клас 18 рахується вдруге, тож механізм мусить закривати й обхід. Ріст
  стелі видно лише в історії, тому потрібен гейт у `make gates`, що звіряє з merge-base `origin/main`. Рішення — Дедал.

## 7. Кадри T2-И (факт)

Переглянула `up-choko`, `perch-lamp-choko`, `perch-lamp-skea`, `perch-bracket-choko`, `perch-bracket-skea`, `down-skea`,
`reel-choko`, `leap-skea`. Кожен аркуш — дві плитки: камера гри | бічна камера.
- **Угору / униз.** Рядок `ROPE · Hold Space: climb · Hold Left Shift: slide down · Z: let go`, маркер `E · TRANSFER`.
  `HOOKS 6 / 7` (Choko), `1 / 2` (Skea). Хвіст мотузки висить до бруківки.
- **Звис на ліхтарі.** `HOOKS 7 / 7`, тобто +1. Рядок `ANCHOR · Grip 2.8s · Release Space, then press it to leap · Z: drop`,
  маркер `E · HOOK`.
  - Збоку голову героя закриває голова ліхтаря (світло-зелений блок).
  - Стовп іде в одній колонці з тілом.
- **Звис на кронштейні 16.** Камера гри притиснута до фасаду: уламки стіни затуляють кадр. Збоку голова — за блоком
  кронштейна.
- **Змотування.** Стоїть на бруківці, мотузка від якоря до руки, `HOOKS 6 / 7`.
- **Стрибок.** У повітрі після звису, поза `wall_kick`.

## 8. Документи (YELLOW)

- `## Related` — останні рядки обох нових Fix і [[Screenshots]].
- `run_gates.sh --docs-only` → rc 0, 554 сторінки, 9280 лінків, 0 зламаних.
- Дрібне:
  - шапка [[2026-10-15-Rope-Climb-City-Fix]] — «Статус: у роботі», хоча «Де зупинився» — «Готово до приймання»;
  - у [[Screenshots]] стовпець «коміт» = «дерево від `93ba633`, не закомічено». Після коміту це застаріє (клас 13);
  - журналу `docs/Meetings/2026-10-15-*` про 15а ще немає — на закритті хвилі (T1).

## 9. Рецидиви — текст для реєстру

- **Клас 5 (обіцянка без гарда): 17 → 18.**
  - Пропоную дописати: «2026-10-15, хвиля 15а (дерево `93ba633` + індекс): ADR-028 п. 4 "з відстані до 14 м" — продукт
    14 → 20 м і 14 → 16 м зелений. Випадок П-4 "far" відмовляє через закриту лінію (`dist=16.839 line_clear=false`).
  - ADR-028 п. 5 / T5 Е1 "швидкість зберігається" — обнулення швидкості на E-відпусканні зелене: міські рядки `traversal`
    стартують із v = 0, а Е-6 кличе `let_go()` повз E.
  - Вікно липкості 5 тиків зелене (T5 Е2 ≥ 6) — [[2026-10-15-Rope-Climb-15a-Review]]».
  - Статус ВІДКРИТО: механізм — код гардів, T2 через T1.
- **Клас 15 (WARNING Jolt у позитиві): 3 → 4.**
  - Пропоную дописати: «2026-10-15, повна батарея T1 `battery-w15`, шард 1/3: `combat-intent` PASS із `WARNING: Jolt Physics
    job system exceeded…` (рядок 3 логу); соло-перепрогін T4 → `checks=160 failures=0`, WARNING 0».
  - Механізму досі немає (пропозиція 6 T4). ВІДКРИТО.
- **Клас 18: лічильник 2 без змін, статус «ВІДКРИТО, механізм частковий».**
  - Пропоную дописати: «механізм T2-К (хвиля 15а): правило раннера відмовляє (rc 2) негативу без `red=` поза списком 156 (`UNFAMILIED_CEILING`),
    з канаркою. Мутанти T4 B2 / B5 / P2 / P3 на нових фікстурах → rc 1.
  - Обходи (канарки T4 → rc 0): `red=` без вимоги родини (`red=[a-z_,]*`, `red=(none|…)`); ім'я видаленого кейсу лишається в
    списку і може бути віддане іншому; ріст списку разом зі стелею — [[2026-10-15-Rope-Climb-15a-Review]]».
- **Кандидат 19 (новий, 1).**
  - Пропоную текст: «Виконавець ганяє підмножину батареї й оголошує готовність; позитив поза підмножиною червоний.
    2026-10-15: рядок COMFORT `RopeClimb` (T2-И, підмножина 244) зламав `blood-content` (кільце фокусу T8); упіймала повна
    батарея T1 (458 / 1)».
  - Механізм уже є — повна батарея T1 перед PR (крок 9 плану) — і спрацював. Лишається кандидатом.
- **Клас 17:** без нового випадку. Незакріплені `rewinds` / `denied` переходу (заміряно 0) — пропозиція, не рецидив.

## Пропозиції

**RED (мінімально):**
1. **T8 → T2 (T2-Л уже правит).**
   - T8 записує місце `ROPE CLIMB` у кільці [[06-UI-UX]]: DRUGS → ROPE CLIMB → RESTORE, на телефоні так само.
   - T2 міняє літерали в `blood_content_check.gd:274, :319, :330` на це місце. Саме ім'я `RopeClimb` у цій позиції, без
     послаблення: «Down from DRUGS reaches ROPE CLIMB», «Down from ROPE CLIMB reaches RESTORE».
   - Перепрогін: `blood-content`, 13 `blood-content-negative-*`, `comfort-ui*`.
2. **T2, `rope_climb_check.gd` `_reel`.**
   - П-4 «far»: герой на вільній лінії за 14,5 м від якоря. `line_clear == true` — передумова (клас 11).
   - Позитивний контроль: 13,5 м → пропонується і змотується.
   - Негатив `rope-climb-negative-reel_range` (межа 16 м, лінію не чіпати) → `red=reel_refuse`.
3. **T2, `traversal_check.gd` `city_transfer`.**
   - Рядки «E відпускає» — з ненульовою швидкістю, наприклад (3; 0; 1), і точною рівністю.
   - Негатив «E обнуляє швидкість» (через `rope_climb_fighter.gd`) → `red=empty`.

**YELLOW — кому:**
- Y1, T2: рядки 14 тиків (висить) і 15 тиків (відпускає), щоб вікно було саме 15.
- Y2, T5 → T2:
  - Л-а / С-рядок судять лише верхню межу; нижню ловлять тільки пороги P12 (≥ 2,4 / ≥ 1,2 м/с);
  - T5 — чи крок має бути рівно 3,6/60 (2,0/60) ± 1e-6 до межі; T2 — гард.
- Y3, T2: «ROPE CLIMB HOLD by default» перевіряється після `set_rope_climb("hold")` самого гарда (кінець P12). Перенести перевірку
  на початок `_rules`.
- Y4, T2: у сентинелі переходу `rewinds=0 denied=0`, або закріпити, як `KNOWN_DENIED`.
- Y5, T2-К → T1 / Дедал:
  - правило вимагає, щоб хвіст після `red=` не збігався з `''`, `none`, `zzz`;
  - кожне ім'я списку — негатив у повному `cases` (врахувати, що `run_subset.py` фільтрує до правила);
  - рядок списку — `ім'я|скрипт`;
  - гейт «стеля не росте» проти merge-base `origin/main` у `make gates`; без історії — rc 2;
  - канарки на кожну форму.
- Y6, T5 / T1: `perch_feet_below` 1,32 (поза T6) проти Л5 1,75; З2 — 37 / 56 пар проти 45 / 56. Прийняти число або
  заперечити.
- Y7, T6: кадри § 7 (голова за блоком ліхтаря / кронштейна, тісна камера на кронштейні 16) і відкрите T2-И § 7 п. 1–4.
- Y8, T8 / T2: геймпад P3 (Y + X на тросі) гардом не покритий (відкрите T2-И).
- Y9, T2-И / T1: шапка Fix, коментар `rope_choice_check.gd:45`, стовпець «коміт» у [[Screenshots]] при коміті.
- Y10, T2 через T1: клас 15 — підсумок WARNING у позитивних логах у раннері (пропозиція 6).

## Related
- [[ADR-028-Rope-Climb-Perch-And-Retrieval]] · [[2026-10-15-Rope-Climb-Perch-Release]] · [[2026-10-15-Rope-Climb-Numbers]]
- [[2026-10-15-Rope-Climb-Input]] · [[2026-10-15-Rope-Climb-Animation]] · [[2026-10-15-Rope-Climb-City-Fix]]
- [[2026-10-15-Negative-Families-Runner-Fix]] · [[2026-10-15-Wave-14-Review-Part-2]] · [[2026-10-14-Quality-Debt-Review]]
- [[06-UI-UX]] · [[04-Grapple-System]] · [[Screenshots]] · [[recurring_class_register]] · [[state]]
