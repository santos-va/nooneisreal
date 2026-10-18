# T8 — приймання вводу троса 15а: лазіння, спуск, звис, E відпускає, ROPE CLIMB

**Дата:** 2026-10-15 · **Роль:** T8 Гермес · **Що приймаю:** реалізацію T2-И за моєю специфікацією
[[2026-10-15-Rope-Climb-Input]] (рішення [[ADR-028-Rope-Climb-Perch-And-Retrieval]] п. 1–5, 8). Журнал виконання —
[[2026-10-15-Rope-Climb-City-Fix]], разом із розділом T2-Л «Після батареї T1: кільце фокусу». · **Дерево:** staging T1
`scratchpad/t15-tree`, база `93ba633` + індекс T1 (T2-К, T2-И, T2-Л), без коміту. · **Godot:**
`Godot_v4.7-stable_linux.x86_64` зі `scratchpad/tools/godot-4.7/`. Продукт я не змінював. У дереві записав лише цю
сторінку і правку [[06-UI-UX]]. Кредитів 0.

## Підсумок

| # | пункт | вердикт | що переробити | хто |
|---|---|---|---|---|
| 1 | Ввід: клавіатура SOLO і геймпад, P3 | **YELLOW** | Продукт поводиться як у специфікації: клавіатурою це перевіряють гарди, геймпадом — мій зонд. Але гард не надсилає жодної події геймпада, P3 не покрито. Немає канарки N2. P5 не перевіряє `denied`. Ухилення зі звису не покрито. Skea: flash, натиснутий на звисі, спрацьовує після відпускання | T2, ТЗ 3–6 |
| 2 | Підказки HUD, пауза, COMFORT HARPOON, smoke | **GREEN** | нічого. Три відхилення приймаю (§ 2). Ширина виміряна і з гліфами геймпада | — |
| 3 | Рядок ROPE CLIMB і кільце фокусу | **YELLOW** | порядок DRUGS → ROPE CLIMB → RESTORE приймаю. Заголовок має стати `ROPE CLIMB · CITY ONLY` | T2, ТЗ 2 |
| 4 | Дефект G біля NPC на тросі | **YELLOW** | з мешканцями виправлено. Розмову з перехожим випадку G і далі відкриває на тросі та під час змотування | T2, ТЗ 1 |
| 5 | Вибір ROPE CLIMB справжніми клавішами й геймпадом | **YELLOW** | продукт працює (зонд F1–F4). Гард потрібен: зараз фікстура шле `item_selected.emit` | T2, ТЗ 3 |

**Загалом — YELLOW, RED немає.** Дефектів продукту два: перехожий на тросі (п. 4) і буфер flash на звисі (п. 1, низький
пріоритет). Решта — заголовок і гарди. Своя помилка: у специфікації § 2.3 я вимагав «не на тросі» лише для мешканців
(`can_talk`) і пропустив перехожих випадків (`can_talk_to`). Т2-И зробив рівно те, що було написано.

## Як перевіряв

Мій каталог — `scratchpad/t8r/` (зонди `probe/`, логи `probe/out/`, батарея `battery*/`). Зонди не є гейтами й лежать
поза репо. Кожен запуск — з окремим `XDG_DATA_HOME` (`t8r/xdg-choko`, `t8r/xdg-skea`), тож `user://` ізольований.

- **Зонд вводу** `t8r/probe/t8_rope_probe.gd`. Справжній `CityWorld`, SOLO, справжні події `InputEventJoypadButton` і
  `InputEventJoypadMotion`, обидва герої. Трос — шляхом продукту через `hook.fire(…)` на якорі 3, як у `rope_climb_check`.
  Команда: `XDG_DATA_HOME=… godot --headless --audio-driver Dummy --path game --fixed-fps 60 --quit-after 20000 --script
  t8r/probe/t8_rope_probe.gd -- --hero=<choko|skea>`. Обидва rc 0, рядків `ERROR` / `SCRIPT ERROR` / `leaked` /
  `warning` 0 (`grep -ciE … out/choko.log` → 0, `out/skea.log` → 0).
- **Зонд 2** `t8r/probe/t8_rope_probe2.gd` (Skea): ухилення зі звису і перемикання в TOGGLE, rc 0.
- **Зонд заголовка** `t8r/probe/title_width.gd`: ширина заголовка шрифтом панелі 32 px, rc 0.
- **Батарея-підмножина** — тілом раннера (`battery-w15/run_subset.py`, фільтр за іменем):
  - `ONLY='(blood-content|comfort-ui|city-controls|city-thirst|city-onboarding|traversal|rope-contact|rope-climb-rules-(choko|skea)|rope-climb-duel)'`
    у 2 шарди → `PLAYABLE CHECK: 5 scenarios, 0 failures` × 2, rc 0 / 0;
  - `BLOOD_CONTENT_COMPLETE checks=75 failures=0`, `ROPE_CLIMB_COMPLETE checks=56 failures=0` (rules, обидва герої),
    `checks=7 failures=0` (duel), `TRAVERSAL_COMPLETE checks=76 failures=0`, `ROPE_CONTACT_COMPLETE checks=96
    failures=0`, `CITY_CONTROLS_COMPLETE checks=48 failures=0`, `COMFORT_UI PASS`, `CITY_THIRST_COMPLETE checks=103
    failures=0`, `CITY_ONBOARDING_COMPLETE checks=72 failures=0`;
  - негативи `ONLY='(traversal-negative-.*|rope-climb-negative-duel_flag|rope-pull-negative-(overlong|stuck))'` →
    `PLAYABLE CHECK: 5 scenarios, 0 failures`, усі 5 `PASS rc=1`, `PLAYABLE FAMILIES: 5 negatives, 0 of them without
    red=`.
- Повна батарея T1 до правки T2-Л: `grep -c ': FAIL' battery-w15/shard*.out` → 0 / 1 / 0, єдиний FAIL — `blood-content`.
  T2-Л його виправив, мій прогін вище — `checks=75 failures=0`.

## 1. Ввід — YELLOW

### Що збігається зі специфікацією (§ 1, § 3)

| дія | клавіатура SOLO | геймпад | чим перевірено |
|---|---|---|---|
| угору | утримувати Space; лише натиск після зачепу | утримувати A | `rope-climb-1…5`, rules P9; зонд A1: L 4,7500 → 4,1500 за 10 тиків (обидва герої) |
| униз | утримувати LShift, без DASH | утримувати X | `rope_pull_check` `_slide`; зонд A2: L 4,1500 → 4,4833, `dash=false` |
| P3: Y + X | — | не спуск, а маршрут dash. Буфер dash забирає трос | **лише зонд** A3: L 4,4833 → 4,4833, `held_dodge=false held_dash=true`. A4: Y + X, далі B — після відпускання dash немає |
| відпустити | E без цілі ≥ 15 тиків; Z; F / L | L3 або Y + LT без цілі; B | `traversal` (E, `v_press`), rules (E на звисі); зонд A6 (L3, `since 29`), A7 (Y + LT), A8 (B) — `phase 0`, `JUMP` |
| ціль < 15 тиків | герой на тросі | те саме | `traversal` «a target shown 3 ticks ago» + негатив `drop_on_flicker` → `red=flicker` |
| перехід | E з ціллю | L3 / Y + LT з ціллю | `rope_choice --transfer`, `traversal` «valid» |
| змотати | G на землі, ≤ 14 м, останнім у ланцюжку | Y + D-pad ↓ | rules П-3, П-4, P11; зонд D2: підказка `Y / Triangle + D-pad Down · Reel in your rope · 1.1m` |
| звис: стрибок | новий натиск Space + стік | новий натиск A + стік | rules (клавіатура); зонд B1 (A, затиснутий з лазіння, 15 тиків — стрибка немає), B4 (A + стік: \|v_гор\| 6,80, v_y 7,4) |
| звис: відпустити | Z, F / L, X; E без цілі | B, D-pad ↓; L3 без цілі | rules Z, X; зонд B2 (B), B3 (D-pad ↓) |
| звис: ухилення | LShift | X | **лише зонд 2** G1: LShift і X → стани `[5, 5, 5]` (DASH) |
| TOGGLE | дотик лізе / стоїть, LShift спускає, пауза зупиняє | A / X | rules P12 (клавіатура); зонд 2 H1–H2 (геймпад) |
| дуель без змін | Space ≤ 1,2 м, LShift — DASH, E без цілі — висить | — | `rope-climb-duel` 7/0, канарка `duel_flag` → `red=duel` |

Нових дій немає: `git diff HEAD -- game/project.godot` → порожньо. `InputRouter.ACTIONS` (`InputRouter.gd:8`) не
змінено. Прапор лазіння ставить лише місто: `grep -rn "climb_enabled\s*=" game/scripts` →
`CityFighter.gd:56`.

### Відхилення від специфікації — приймаю

- **TOGGLE, друга клавіша.** У специфікації § 5 під час спуску Space «зупиняє». У коді Space перемикає на лазіння, а
  LShift під час лазіння — на спуск (`CityFighter.gd:194–198`; зонд 2 H1: `5.0500 → 4.5100 → 4.0300`, «climbs»).
  Симетричне правило простіше: кожна клавіша вмикає свій напрям, повторний натиск зупиняє. До того ж підпис
  `Space: climb / stop` саме так і читається. Приймаю код. Мій текст § 5 тут неточний.
- Перехід на звисі, E з ціллю: замах 10 тиків, −1 гак. Це правило T5, з вводом не конфліктує.

### Що не покрито гардом (T2-И сам назвав P3)

1. **Жодної події геймпада** в `tools/grapple/rope_climb_check.gd`: `grep -c "Joypad" tools/grapple/rope_climb_check.gd` → 0.
   Не покриті A, X, Y + X (P3), L3, Y + LT, B, D-pad ↓ — ні на тросі, ні на звисі. Поведінку я виміряв зондом, але без
   гарда регресію ніхто не побачить (клас 5 [[recurring_class_register]]).
2. **Канарки N2 немає.** Специфікація просила: «такт троса не забирає буфер `dodge`» → P7 червоний. Серед мутантів
   `rope_climb_mutants.gd` є `double`, `far`, `hung`, `duel_flag`, `tie_rod`, а N2 немає.
3. **P5 без `denied`.** `traversal_check` перевіряє, що герой висить, але не що прийшла причина (`hook.denied`) і HUD
   показав рядок `HOOK_REASONS`.
4. **Ухилення зі звису** (LShift / X) — у гардах немає (`grep -n "dodge" tools/grapple/rope_climb_check.gd` — лише
   P7 / P8 і пауза змотування).

### Дефект продукту, низький пріоритет: flash Skea на звисі

Skea натискає LAlt або Y + X на звисі. Там це нічого не робить. Потім B протягом 2 тиків — і flash спрацьовує в повітрі:
зонд B5 Skea `dash in 8 ticks true` для обох способів. У Choko — `false`, бо його dash у повітрі можливий лише з
«Spring» (`Fighter.gd:703`, `:717`). На тросі буфер `dash` забирається (`CityFighter.gd:120–121`), а на звисі — ні
(`_tick_perch`, `CityFighter.gd:218`). Правило T8 одне: на тросі і на якорі натиск, який там нічого не означає, не
спрацьовує після відпускання. ТЗ 6.

## 2. Підказки HUD і довідки — GREEN

Тексти з таблиці § 4 стоять дослівно: `CityHud.gd:36` (`NO HARPOONS · reel in a left rope, or grab one`), `:618`,
`:623`, `:627`, `_rope_hint` `:1215–1227`, `_perch_hint` `:1231–1239`, маркер `:1076` (на звисі `HOOK`, бо
`attached = false` у `_grip_anchor`, `GrappleHook.gd:1040`), `REEL_PROMPT` (`CityWorld.gd:386`). Блок HARPOON у COMFORT
(`ComfortPanel.gd:222`, у специфікації `:194` — дрейф рядка) збігається з § 4 слово в слово. Хвіст `Enemy grapple still
uses hold / release.` лишився, як і мало бути («решта блоку без змін»). `.replace("Let go: Z", …)` на місці. Smoke
`SmokeTest.gd:429`: `Let go: Z / B, or block`, `hold jump to climb`, `Hold jump to reel in`.

Відхилення, які приймаю:
- `Grip N.Ns · ` на звисі — правило T5 З1, таке саме, як на краю;
- `CLIMBING` на 30 тиків «до опори» (`CityHud.gd:1200`) — у специфікації його не було. Рядок короткий і нічого не
  обіцяє. Z на цьому етапі працює, але рядок цього не називає, а тривалість 0,5 с;
- smoke шукає `hold jump to climb` з малої літери. Розбіжність була в моєму документі: текст § 4 — з малої, таблиця
  гардів — з великої. Правильно — як у тексті.

**Ширина** (зонд, шрифт мітки підказки 18 px, межа 1552; пауза — шрифт 22 px, межа 1000):

| рядок | px | знаків |
|---|---|---|
| найширший клавіатурний `ROPE · Pulling you up · Hold Space: climb · Hold Left Shift: slide down · Z: let go` | 676 | 83 |
| найширший рядок троса з гліфами `ROPE · Pulling you up · A / Cross: climb / stop · X / Square: slide down / stop · B / Circle (while hanging): let go` | 932 | 116 |
| найширший рядок взагалі, звис із ціллю: `ANCHOR · Grip 2.7s · A / Cross + move: leap · Y / Triangle + LT / L2 / L3: next anchor · B / Circle (while hanging): drop` | 989 | 121 |
| пауза: 11 рядків (`E2 pause rows=11`), найширший `Sword: V / R3 · Talk or reel rope: …` | 931 | 88 |
| пауза `Rope: hold Space / A up · hold Left Shift / X down · hook: transfer or let go · move: swing` | 924 | 91 |

Усі рядки однорядкові, запас до межі не менше 563 px на підказці і 69 px на паузі. Гард P13 міряє лише клавіатурні
рядки. Рядки з гліфами геймпада додати дешево, ТЗ 4.

Для T7: у COMFORT стоїть `press interact near it to reel it in`, а змотування діє до 14 м. Слово `near` — PLACEHOLDER
T7, не дефект.

## 3. Рядок ROPE CLIMB і кільце фокусу — YELLOW

### Порядок: приймаю В1 — DRUGS → ROPE CLIMB → RESTORE

**Аудит.** `_focus_order.append(rope_climb_choice)` стоїть на `ComfortPanel.gd:178`, між DRUGS (`:167`) і RESTORE
(`:187`). Варіанти та мутанти T2-Л — у журналі, розділ «Чи логічне місце». Що я додав сам: зонд F1 — Enter на COMFORT,
фокус `MasterSlider`; F2 — 7 × ↓ від фокуса при відкритті приводять на ROPE CLIMB. Від BACK — 3 × ↑.

| варіант | що ламає (виміряно мутантами T2-Л) |
|---|---|
| **В1** DRUGS → ROPE CLIMB → RESTORE | нічого: MASTER на тих самих пікселях (запас 24 px на 1600×900), кроки Д3 ті самі |
| В2 RESTORE → ROPE CLIMB → довідка | крок RESTORE → довідка, `comfort-ui` червоний |
| В3 над MASTER | MASTER зсувається на 134 px при запасі 24 px, `comfort-ui` червоний |
| В4 між BLOOD і DRUGS | розриває групу «зміст» Д3 |

**Погляди.**
- Гравець, якому важко тримати кнопку, знаходить перемикач у кінці налаштувань, а під ним довідку CONTROLS про трос.
- Клавіатура / геймпад: 7 кроків від MASTER, як до DRUGS + 1.
- Опікун: BLOOD і DRUGS поруч, як і були.
- Чутливий до спалахів гравець: HIT FLASH біля CAMERA SHAKE, як і був.
- CI: повне кільце літералами тримає одна фікстура, `blood_content_check`; MASTER тримає `comfort_ui_check`.

Вибір — В1. Літерал кільця в [[06-UI-UX]] § «Випадки міста: COMFORT і HUD» п. 1 оновлено.

### Суфікс `· CITY ONLY` — потрібен

**Аудит.**
- Лазіння вмикає лише місто: `CityFighter.gd:56`.
- `InputRouter.rope_climb` впливає на гру лише у двох місцях: `CityFighter.gd:194` і `CityHud.gd:1220`. Третє
  місце, `ComfortPanel.gd:261`, тільки показує значення (`grep -rn "InputRouter.rope_climb" game/scripts` → 3).
- Панель відкривається і з головного меню, і з бойової паузи. У дуелі рядок нічого не робить: так вирішено в ADR-028
  п. 7, і це не тимчасово.
- Сусідній рядок уже має суфікс: `DRUGS, ALCOHOL & TOBACCO · CITY ONLY` (`ComfortPanel.gd:45`).
- Ширина заголовка шрифтом 32 px (зонд заголовка): `ROPE CLIMB` — 189 px, `ROPE CLIMB · CITY ONLY` — 376 px,
  заголовок DRUGS — 655 px. Вміст панелі ≤ 892 px.

| варіант | що дає | ціна |
|---|---|---|
| С1 без суфікса (як зараз) | коротко | у дуелі перемикач «нічого не робить» — схоже на зламане налаштування |
| **С2 `ROPE CLIMB · CITY ONLY`** | той самий шаблон, що в DRUGS; межу видно ще до вибору | одна константа; гард на літерал |
| С3 підпис 24 px під рядком | можна пояснити більше | +1 рядок висоти, нове слово для T7 |
| С4 ховати рядок поза містом | — | ламає літеральне кільце; не можна налаштувати до входу в місто |

**Погляди.**
- **Santos:** питає, що робить кожне налаштування. Суфікс відповідає на це сам.
- **Гравець у дуелі:** перемкнув TOGGLE, а Space у дуелі далі тягне на 1,2 м. Без суфікса це виглядає як баг.
- **Гравець, якому важко утримувати:** суфікс чесно каже, що перемикач стосується лише троса в місті. Утримання на краю,
  стінні кроки й перекат він не змінює ([[2026-10-15-Rope-Climb-Input]] § 5, «не входять у цю хвилю»).
- **T7:** слова PLACEHOLDER, шаблон уже є.
- **CI:** заголовок зараз не читає жоден гард (`grep -rn "ROPE_CLIMB_TITLE\|\"ROPE CLIMB\"" tools` → порожньо).
  Літерал додається в гард разом зі зміною.
- **Майбутнє:** якщо лазіння колись прийде в дуель, суфікс прибирається однією константою.

Вибір — **С2**, ТЗ 2.

## 4. Дефект G біля NPC на тросі — YELLOW

- **Мешканці — виправлено.** `can_talk` повертає false, коли `grapple.busy()` (`CityNpcDirector.gd:149–153`). Отже, і
  на тросі, і на звисі, і поки мотузка змотується. Гард rules P10 червоніє, якщо розмова доступна на тросі, і
  перевіряє, що на землі біля того самого мешканця вона є. P11 — розмова перемагає змотування. Обидва PASS.
- **Перехожі випадків — не виправлено.** Розмову з перехожим відкривають три випадки:
  - провулок — `CityAlleyEvent.gd:173–180`;
  - «П'ять листків» — `CityLeavesEvent.gd:113–119`;
  - ятка — `CityVendorEvent.gd:116–122`.

  Підказку показує `director.can_talk_to(person)` (`CityEventDirector.gd:225–231`). Вона міряє лише висоту, відстань і
  лінію, а трос не перевіряє. Зонд:
  - D1, герой висить: `busy true` → `can_talk_to = true`;
  - D3, змотування: `phase 4`, на землі, `busy true` → `can_talk_to = true`.

  Мешканці на тросі повертають `find_nearest() < 0`, тож підказка перехожого лишається єдиною на G. Натиск G відкриває
  меню (за кодом, `open_ask()` / `open_offer()`; повний шлях випадку зондом не проганяв).
- **Коли таке трапляється.** Випадок стартує лише на землі й з вільним гаком (`CityEventDirector.gd:139`). Але
  перехожий чекає з підказкою `ask_seconds` / `offer_seconds`, і за цей час герой встигає вистрілити й повиснути низько
  або змотати мотузку. Це та сама вимога § 2.3, тільки на паралельному шляху. ТЗ 1.

## 5. Вибір ROPE CLIMB справжніми клавішами й геймпадом — YELLOW

**Продукт працює** (зонд, обидва герої):
- F1–F2: пауза міста → Enter на COMFORT → фокус на MASTER → 7 × ↓ → фокус на `RopeClimb`;
- F3: Enter → список відкрито, ↓, Enter → `rope_climb toggle`, `selected 1`, у `user://settings.cfg` `[input]
  rope_climb=toggle`;
- F4: на геймпаді A, D-pad ↑, A → `hold`, `selected 0`, у файлі `hold`;
- F5: заголовок `ROPE CLIMB`, пункти `Hold — climb and slide while held` / `Toggle — press to start, press again to stop`.

**Гард потрібен.** `rope_climb_check.gd:601–619` шле `row.item_selected.emit(…)`. Він не помітить, якщо список не
відкривається, фокус не доходить, `_syncing` залип або сигнал не під'єднаний (клас 5).

Застереження T2-Л («фікстура не перенаправляє `InputRouter` на власний `settings.cfg`») знімається:
- батарея ізолює профіль — `XDG_DATA_HOME` на Linux і власна тека користувача на macOS (`isolated_profile`, `playable_check.sh:548`);
- чинний `item_selected.emit` теж іде в `set_rope_climb(mode)` із записом (`InputRouter.gd:105–116`, `ComfortPanel.gd:179–181`),
  тож справжні клавіші ризику не додають;
- і зараз, і після ТЗ фікстура при ручному запуску поза батареєю пише в справжній `settings.cfg`. ТЗ 3 додає
  збереження байтів і їх повернення.

## ТЗ для T2

Імена дій не змінюються. `project.godot` не чіпати. Кожен новий негатив — з `red=<родина>` у sentinel (клас 18).

1. **Перехожий на тросі (п. 4).** `CityEventDirector.can_talk_to` (`:225`) повертає false, коли
   `player.grapple.busy()`. Так одна правка закриває всі три випадки.
   - Гард у `rope_climb_check --part=rules`, рядок P10b. Перехожий (`events.spawn_passerby`) на відстані розмови:
     - поки герой висить низько, `can_talk_to` = false;
     - поки змотується мотузка, `can_talk_to` = false;
     - на землі з вільним гаком `can_talk_to` = true (контроль).
   - Якщо це можна зробити без великої обв'язки, справжній G при підказці випадку не відкриває меню.
   - Негатив `--break=passerby` (без перевірки) → `red=talk`.
2. **Заголовок (п. 3).** `ComfortPanel.ROPE_CLIMB_TITLE` = `"ROPE CLIMB · CITY ONLY"` (`:52`). У `_comfort_row`
   перевірити, що мітка перед `RopeClimb` дорівнює цьому літералу T8.
3. **ROPE CLIMB справжнім вводом (п. 5).** У `rope_climb_check._comfort_row` замінити `item_selected.emit`:
   - пауза → COMFORT, фокус на MASTER;
   - 7 × KEY_DOWN → фокус на `RopeClimb` (літерал T8);
   - KEY_ENTER, KEY_DOWN, KEY_ENTER → `InputRouter.rope_climb == "toggle"` і `[input] rope_climb = "toggle"` у
     `user://settings.cfg`;
   - на геймпаді A, D-pad ↑, A → `hold`.

   До першого натиску зберегти байти `user://settings.cfg`, після тесту повернути (або видалити файл, якщо його не
   було). Негатив `--break=rope_row` (обробник `item_selected` від'єднано, як `drugs_row`) → `red=comfort`.
4. **Геймпад на тросі й на звисі (п. 1, P3).** У `--part=rules` — справжні `InputEventJoypadButton` /
   `InputEventJoypadMotion`, як у моєму зонді `t8r/probe/t8_rope_probe.gd`:
   - утримувати A — L спадає; утримувати X — L росте, DASH немає;
   - **P3:** утримувати Y + X 10 тиків — L не змінилась, DASH немає;
   - L3 і Y + LT без цілі ≥ 15 тиків — відпустив; B — відпустив;
   - на звисі: B і D-pad ↓ — відпустив; X — ухилення; клавіатурою LShift — ухилення; A + стік — стрибок.

   P13: рядки, показані з гліфами геймпада, теж ≤ 1552 px. Негатив `--break=pad_dash` (спуск читає і `held("dash")`)
   → `red=pad`.
5. **Канарка N2 (п. 1).** Мутант `rope_buffer`: такт троса в місті не забирає буфер `dodge`. P7 має почервоніти,
   `red=dodge`.
6. **Буфер flash на звисі (п. 1, низький пріоритет).** `_tick_perch` щотакту забирає буфер `dash`, як такт троса
   (`CityFighter.gd:120–121`). Гард: Skea, LAlt і Y + X на звисі, далі B за ≤ 2 тики — DASH протягом 8 тиків немає.
7. **P5 з причиною (п. 1, низький пріоритет).** У `traversal_check`, випадок «a target shown 3 ticks ago», перевірити,
   що прийшов `hook.denied` з причиною з `HarpoonAim.REASONS`.

Після ТЗ: `make check`, `make gates`; підмножина `rope-climb-.*`, `blood-content.*`, `comfort-ui.*`, `city-.*event.*`,
`traversal.*` → rc 0; негативи червоні своєю родиною.

## Відкрите

- **T8, наступний захід:** [[05-Platforms-Input]] — таблиці троса і `REEL LIMIT` у § «Міський паркур» за кодом 15а
  ([[2026-10-15-Rope-Climb-Input]] § «Відкрите»). Сюди я його не вносив: ТЗ дозволяло правити лише [[06-UI-UX]].
- **T8 / T2:** `settings.cfg`, що не читається, рядок ROPE CLIMB не перезаписує, як і вимагала специфікація. Але й
  статусу помилки не показує, на відміну від `content.cfg` і `graphics.cfg`. Не дефект за специфікацією, кандидат на
  наступний захід.
- **T7:** `near it` у COMFORT при дальності 14 м; слова рядка ROPE CLIMB.
- **M3:** клавіатура й геймпад окремо, кадри підказок 1280×720 і 3840×2160 — не знято.

## Related

- [[2026-10-15-Rope-Climb-Input]] · [[2026-10-15-Rope-Climb-City-Fix]] · [[ADR-028-Rope-Climb-Perch-And-Retrieval]]
- [[2026-10-15-Rope-Climb-Perch-Release]] · [[2026-10-15-Rope-Climb-Numbers]] · [[06-UI-UX]] · [[05-Platforms-Input]]
- [[2026-10-15-T8-Colour-Switch-Row-Acceptance]] · [[recurring_class_register]] · [[state]]
