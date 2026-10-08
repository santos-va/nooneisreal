# Спрага, стани речовин і «Сила», іконки предметів — журнал виконання

**Дата:** 2026-10-08 · **Роль:** T2 Гефест · **Статус:** блоки 1–3 зроблені; остаточна батарея зелена (друга; перша впала на моєму форматі сентинела — розділ «Остаточна батарея»). Журнал пишеться
по ходу: контейнер уже перезапускався. Гілка `claude/t1-orchestration-2026-10-07`, база `82a44e7`. Коміт і push — T1
після власної батареї; merge — Santos. Кредитів не витрачено. `.tres`, input map і `project.godot` не змінюються.
Сирі логи — `scratchpad/thirst/`.

Джерела:
- план [[2026-10-08-Thirst-Substances-Icons]] (кроки 1–3, «Рішення T1 після кроку 0»);
- рішення [[ADR-026-Substances-Nutrition-And-Thirst]] п. 1–4;
- числа T5 [[2026-10-08-Thirst-Numbers]] (§ 11), [[2026-10-08-Substances-And-Nutrition]] (§ 10), усе PLACEHOLDER;
- HUD T8 [[06-UI-UX]] § «Спрага, стани речовин і іконки предметів — GAP-специфікація 2026-10-08»;
- лор T7 [[PROPOSAL-Substances-And-Healthy-Food]] ([P]);
- арт T6 [[2026-10-08-Substances-And-Food-Items]], [[Item-Sheets-Prompts]].

## Хід роботи

- Прочитано роль, конституцію, `state.md`, план, ADR-026, обидва документи T5, розділ T8, бриф T7, документи T6.
  `git status --short` → порожньо; `git rev-parse HEAD` → `82a44e7…`. Godot:
  `Godot_v4.7-stable_linux.x86_64 --version` → `4.7.stable.official.5b4e0cb0f`. Штамп імпорту був `97ffd62`, тож
  `--headless --import` (rc 0, 0 рядків error/warning) і `godot_guard.sh stamp`.
- Дуель «до» на чистому `82a44e7`: `living_body_check.gd -- --dump=scratchpad/thirst/duel-before` → rc 0,
  `LIVING_BODY_COMPLETE checks=10 failures=0`; sha256 `choko_skea_{off,on}` = `a3b963487086876f…28511a`,
  `skea_choko_{off,on}` = `84b63712d0ed7740…989adb` (ті самі, що в [[2026-10-08-Survival-Hunger-Fix]]).

## Звірка плану з реальністю

| що в плані / джерелах | команда | вихід |
|---|---|---|
| `CityHunger.gd` 352 рядки, пороги `:27` | `wc -l game/scripts/world/CityHunger.gd`; `sed -n 27p` | 352; `BANDS` на `:27` — збігається |
| спраги в коді немає | `grep -rln -i -E "thirst\|спраг" game/scripts game/data \| wc -l` | 0 — збігається |
| колонки немає | `grep -rn -i -E "pump\|колонк" game/scripts --include=*.gd` | 5 рядків: гарпун `GrappleHook.gd:4,691,693,694` і коментар `CityCamera.gd:134` — збігається |
| «Кухля» немає | `grep -rn -i "Кухоль\|tavern" game/scripts \| wc -l` | 0 → вода лише з колонки (план, крок 1), квасу ніде не продають (T5 § 4 дає його лише «Кухлю») |
| колонка T5 «≈ (0; 0; 17)» | `sed -n 30,35p game/scripts/world/CityLayout.gd`; `sed -n 61,66p tools/world/city_geometry_check.gd`; `sed -n 693,705p tools/grapple/auto_hook_check.gd` | **розбіжність 1**: (0; 0; 17) лежить на маршруті spawn (0; 0; 23) → центр `route_points()`. `city_geometry_check` пробує там капсулу r 0,32 кожні 0,75 м, а `auto_hook_check` P11 ставить героя в (0; 0; 17,25). Колонка там ламає дві регресії й саму головну вулицю. T5 сам пише «саме місце вибирають T2 і T6» |
| смуги мешканців поруч | `sed -n 19,27p game/scripts/npc/CityNpcActor.gd` | мешканець 6: x −4,5…−3,5, z 9…17; мешканець 7: x −3,5…−2,5, z 19…27 |
| ятки ринку | `sed -n 14,19p game/scripts/world/CityMarket.gd` | (±8,5; 0; 18 / 25), прилавок до x ±7,5 |
| `hang_seconds` для «Сили» | `grep -n hang_seconds game/scripts/world/CityParkourMotor.gd game/scripts/world/CityParkourProfile.gd` | `CityParkourMotor.gd:93`, `:564`; профіль спільний (`CityParkourProfile.gd:14`) — не мутувати (T5 § 11) |
| гліфи `→` `✓` | Godot 4.7 `ThemeDB.fallback_font.has_char()` (зонд `scratchpad/thirst/probe/font_probe.gd`) | `FontFile` «Open Sans SemiBold», `fallbacks` 0, `allow_system_fallback=true`. `→` false, `✓` false, `◇` false, `▬` false; `·` `«` `»` `—` `−` `і` `ї` `…` `×` `•` `‹` `›` true — збігається з T1/T8 |
| де ще непокриті гліфи | зонд `lit_probe.gd`: лише рядкові літерали `.gd` (коментарі пропущено) | **розбіжність 2**: окрім `CityNpcDirector.gd:467` і `LethalHud.gd:226` — ще 30 літералів: `CityHud.gd:443,457,464` (`✓`), `:902` (`◇`), `Hud.gd:310,522,523` (`✓`), `:643` (`◇`), `MainMenu.gd:255–261` (`◂ ▸`), `:280`, `:352` (`↗`), `CityQuestGuide.gd:65–78` (стрілки), `CityInteriors.gd:234,236`, `CityMaintenance.gd:48`, `CityLowerGallery.gd:127,141` (вивіски Label3D), і дані `data/story/lower_mark.json:21` (`→`). `skea.tres:9` `Jab → Elbow` — `MoveData.display_name`, на екран не потрапляє (`grep -rn "display_name" game/scripts`) |

Розбіжності 1–2 не змінюють задуму плану: місце колонки T5 лишив T2, а «знайди ще» — у дорученні T1. Рішення — у блоках.

## Блок 1 — спрага

### Що зроблено

- **`CityThirst.gd` (новий).** W у сотих (0…10000) на героя в `CityProgress`. Свого годинника немає:
  `CityHunger.step_frame()` кличе `thirst.step_frame()`, тож W стоїть рівно там, де H (пауза, розмова й модаль, кишеня,
  падіння, скриптовий прогін), а `simulate()` покриває обидві шкали. −1 сота / 12 кадрів (3,0 / хв), пороги 50 / 25 / 10
  (усе `@export`, PLACEHOLDER T5). Власних ефектів немає.
- **Тілесний поріг B = max(b(H), b(W))** — `CityHunger.body_band_index()`. Звідти беруть множник ухилу, ходу, біг по стіні
  й **один** тік hp (`_tick_hp`, `_reset_counters`). `band_index()` лишився порогом голоду (слово FOOD, репліки Міри).
- **Одне падіння.** `step_frame`: H = 0 **або** W = 0 → `_begin_collapse()` один раз, причина `hunger` / `thirst` / `both`
  (`last_collapse_cause`), подія міста обривається з причиною `thirst`, якщо винна спрага. Пробудження:
  `H = max(H, 30)` (було `= 30`; для H = 0 те саме), `thirst.wake()` → `W = max(W, 30)`, жетони −min(жетони, 3) один раз.
  Слова: `You collapsed from thirst · …` / `… from hunger and thirst · …` (T8 п. 2).
- **Кишеня («Повний перенос»).** Множники входу — від B (`CityFighter` читає ті самі функції). W у бою стоїть (годинник
  спільний). `pocket_status()`: гірша шкала — її слово й ефект (`THIRSTY · slower stamina`, `PARCHED · slower stamina and
  walk`); рівні — обидва слова без ефекту (`HUNGRY · THIRSTY`); обидва FAINT — одне слово й ефект (моє рішення, див. нижче).
- **Збереження.** `CityProgress`: необов'язкове поле `thirst`, `thirst_centi()`, `set_thirst()`, `set_hunger(…, thirst)`
  (хвилинний запис голоду несе й W). Наявне значення мусить бути цілим 0…10000, інакше файл не перезаписується.
- **Колонка `CityWaterPump.gd` (новий)** — процедурна (чавун, важіль, носик, ковш на ланцюжку, калюжа, 0 кредитів), будує
  її `CityDistrict` (`water_pump`), колайдер — циліндр r 0,2 м на шарі 9, як у решти твердих тіл кварталу. Місце — див.
  розбіжність 1 нижче. Взаємодія — наявний `interact` біля носика, рядок `<клавіша> · Drink water · free` у рядку сюжету
  (T8 п. 2), без меню. Досяжність — як у сюжетних точок (≤ 1,35 м по горизонталі, |Δy| ≤ 0,75, промінь без перешкод).
  Пиття: W → 100, H і жетони без змін, «Заплутаність» лишається (її скорочує лише відвар); `Sfx` `pump_drink` (−8 дБ) —
  ім'я PLACEHOLDER, файлу немає, виклик мовчить (`Sfx.gd:6`).
- **Гард «без колонки — без спраги».** `CityThirst.setup`: `running = clock_running and has_source()`; і
  `enable_for_test()` теж вмикає лише за наявного джерела. Без джерела W = 100, годинник W не рухає, рядок WATER схований.
- **Напої-їжа.** Відвар: `"water": 3000` → W +30 (T5 § 4). Тверда їжа W не дає. `food_state` віддає `water` і
  `water_after`; `«ти ситий»` — лише коли всі шкали напою на 100 і він не скорочує стану (T8 п. 5): відвар за H 100 і
  W 60 тепер можна взяти.
- **HUD (T8 С2).** `WaterLine` + `WaterBar` 8 px одразу під FOOD, насічки 0,5 / 0,25 / 0,1, рамка в FAINT, резерв ширини
  `WATER 100% · PARCHED`, колір «напився» `8fb8de` (PLACEHOLDER T6). HEALTH — коли hp < max або B = 3. Підказки порогів
  — окремо для кожної шкали (гістерезис +5 кожному порогу): B зріс → підказка шкали; не зріс → `<СЛОВО> · no extra effect
  yet · <де>`; друга шкала в межах вікна першої підказки → **одна** злита підказка, другого звуку немає. Ознака FAINT —
  B = 3, передається явно (`push_body_hint(…, faint, scale, band)`), а не префікс тексту. Повтор звуку у FAINT — один
  таймер на B = 3. `thirst_cue` (−8 дБ) — ім'я PLACEHOLDER, файлу немає. Рядок паузи: `… · Food: «Шавлія» · Water: the
  pump`.
- **Прилавок Міри.** Рядок: `<страва> · FOOD +n% → n%[ · WATER +n% → n%] · n жет.` (`CityNpcDirector.food_label`),
  заголовок дописує ` · WATER n%`. Літерали, які T8 назвав, оновлено: `city_hunger_check.gd` (K9, 2 рядки),
  `city_economy_check.gd` (E3, 2 рядки). Решта фікстур T8 п. 6 не змінювалась.

### Розбіжності й рішення блоку 1

1. **Місце колонки.** (0; 0; 17) T5 стоїть на маршруті spawn → центр (звірка вище). Поставив **(−2,2; 0; 17,8)**, носик
   на +X (до вулиці від спавну до кишені): 1,5 м від кута смуги мешканця 6 (−3,5; 17), 1,8 м від кута смуги мешканця 7
   (−3,5; 19), 3,1 м від центру Ринкової площі (r 3), 5,7 м від спавну, 8,6 м від безпечної точки кишені.
   `city_geometry_check` (1775 / 0), `auto_hook_check` (162 / 0), `tight_station_probe --check` (31 / 0),
   `conversation_camera_check` (81 / 0) — зелені з колонкою. Остаточне місце й вигляд — T6.
2. **Gamepad `interact` ніколи не спрацьовував у місті** (знайдено фікстурою: ключ — так, Y + D-pad Down — ні).
   `InputRouter._route_pad` штампував `_routed_just[name] = _frame`, а `_physics_process` спершу робить `_frame += 1`,
   тож `just_pressed()` для маршрутизованого натиску пада ніколи не збігався. Читають `just_pressed` лише міські
   `interact` (`grep -rn "just_pressed(" game/scripts` → `CityWorld` ×3, `CityNpcDirector`, `CityLeavesEvent`,
   `CityAlleyEvent`), дуель читає `buffered()`. Виправлено одним рядком: `_frame + 1` (подія належить наступному тіку, як
   у Godot `Input.is_action_just_pressed`). `limb_input_check` 227 / 0, `city_controls_check` 48 / 0.
3. **Обидва FAINT.** T8 для рівних порогів дає «обидва слова без ефекту», а злита підказка — «обидва слова й ефект». Для
   двох однакових `FAINT` пишу одне слово (`FAINT · slower stamina and walk` у кишені; `FAINT · health drains … · food:
   «Шавлія» · water: the pump, free` у підказці). На рішення T8.
4. **Поза `Drink` (3 с, T5 § 4)** не зроблена — як і `Consume` за прилавком у голоді. Смуга WATER росте ≤ 0,3 с.
5. **Квасу немає**: T5 дає його лише «Кухлю», якого в коді немає.

### Перевірка блоку 1

Нова фікстура `tools/world/city_thirst_check.gd`: справжній `CityWorld` (збереження вимкнені), Choko, потім Skea;
T0–T13 (T5 § 11 п. 1–6, 9–13) і H1–H8 (T8 W1–W6, W13, N3, N6); клавіатура й пад справжніми подіями. Літерали — T5 / T8.

**Предмет:** для всіх кадрів міської гри W втрачає одну соту на 12 кадрів на годиннику H і більше ніщо його не змінює,
крім води, напою й падіння; тіло бере гірший із двох порогів (ніколи добуток) для ухилу, ходи, бігу по стіні й одного тіку
hp; H = 0 або W = 0 — одне падіння, що піднімає кожну шкалу щонайменше до 30 і бере −min(жетони, 3) один раз; кишеня бере
B, а W у ній стоїть; колонка дає W 100 задарма й ніколи H; без джерела води W не рухається; збереження тримає W точно.

| команда (`scratchpad/thirst/scripts/run_fx.sh`, як `playable_check`) | вихід |
|---|---|
| `city_thirst_check.gd` | rc 0, `CITY_THIRST_COMPLETE checks=96 failures=0 mutation=none`, 0 ERROR, 0 WARNING, 0 leaked |
| `… --break=rate` (12 → 14 кадрів) | rc 1, failures 8: «3000 frames → 97.50 (97.86)» — рівно негатив T5 |
| `… --break=gate` (розмова відпускає токен UI) | rc 1, failures 1: «a conversation: … (7975)» |
| `… --break=pocket_clock` (`hunger.lethal = null`) | rc 1, failures 1: «the lethal pocket: … (7975)» |
| `… --break=ignore` (W не рахується для тіла) | rc 1, failures 44 |
| `… --break=source` (шкала біжить без джерела) | rc 1, failures 1: «… pump taken away: W 99.00 …» |

**Мутації продукту на копії** (`scratchpad/thirst/scripts/mut_block1.py` + `mutrun.py`: легка копія `game/` на кожну
мутацію, одна заміна, фікстура з репо; логи — `scratchpad/thirst/mut/logs/`). Усі 21 — FAIL (rc 1):

| мутація (файл: що замінено) | вихід |
|---|---|
| `CityHunger`: ухил і хода — добуток множників | failures 7: «T4 … 2.410 m/s», «T3 H 8 + W 8 … refill 15.0 / s (7.500)» — числа T5 § 3.3 |
| `CityHunger.body_band_index`: лише H | failures 16 |
| `CityHunger.step_frame`: другий тік hp, коли W у FAINT | failures 2 після посилення T3 (спершу 1: тест бачив лише 150 / 300 кадрів, додано 600) |
| `CityThirst.drink_water`: + H / − жетон / скорочує «Заплутаність» | failures 1 / 2 / 1 |
| `CityHunger._wake`: H = 30 замість max | failures 1 («H 30.00» при H 80) |
| `CityHunger._wake`: друге пограбування при `both` | failures 2 («lost 5 tokens») |
| `CityHunger._wake`: без `thirst.wake()` | failures 3 («W 0.00») |
| `CityHunger._physics_process`: W тікає в кишені | failures 7 |
| `CityProgress.restore`: без перевірки `thirst` | failures 4 (пошкоджене перезаписано) |
| `CityThirst.setup` / `enable_for_test`: без гарда джерела | failures 1 / 2 |
| `CityHud`: без злиття / FAINT за префіксом / WATER без слова / «no extra» ніколи / HEALTH лише від H | failures 4 / 1 / 1 / 1 / 2 |
| `CityHunger._on_haze_started`: старт стану знижує W | failures 6 |
| `InputRouter._route_pad`: старий штамп `_frame` | failures 2 (T5 пад, S Skea) |
| `CityHunger.foods`: відвар без W | failures 3 |

Супутні прогони після блоку 1 (усі rc 0, 0 ERROR / WARNING / leaked): `city_hunger_check` 79 / 0, `city_economy_check`
24 / 0, `city_haze_check` 34 / 0, `city_onboarding_check` 72 / 0, `lethal_fight_check` 121 / 0, `city_controls_check`
48 / 0, `district_ui_check` 33 / 0, `city_geometry_check` 1775 / 0, `auto_hook_check` 162 / 0, `tight_station_probe
--check` 31 / 0, `conversation_camera_check` 81 / 0, `city_leaves_check` 35 / 0, `city_alley_check` 45 / 0,
`city_event_menus_check` 16 / 0, `limb_input_check` 227 / 0, `blood_content_check` 74 / 0, `quest_journal_check` 32 / 0,
`city_runtime_check` 68 / 0. GDS: `gd_check_all.sh` → «перевірено: 139 · не парсяться: 0», канарка FAIL як треба.
`playable_check.sh`: +1 сценарій `city-thirst` і 5 негативів (211 сценаріїв, python-частина — `ast.parse` ок).

## Блок 2 — стани й корисна їжа

### Що зроблено

- **`CitySubstances.gd` (новий)** — «Хміль» і «Задишка» як профілі даних за зразком `CityHaze`, не стани бійця. Час міста
  (стоїть у паузі), наростання 3 с, згасання 10 с, `weight()` без пульсу. «Хміль» 120 с: гальмування × 0,5, бігу по стіні
  немає; «Задишка» 60 с: відновлення ухилу × 0,75 (усе `@export`, PLACEHOLDER T5). Екранних ефектів немає (М4). Стани не
  накладаються з «Заплутаністю» й між собою (`any_state()`, М6). `drink()` (вода, будь-який напій) → залишок ≤ 10 с, а в
  «Хмелі» ще й без похмілля. Природний кінець «Хмелю» без напою → `CityThirst.hangover()`: `W = max(W − 15, min(W, 11))`,
  H не чіпається (Р6′). `clear()` — Off і рестарт: одразу, без згасання, без підказки, без похмілля.
- **`CityFighter`.** `dodge_regen_scale()` (поріг B × «Сила» × «Задишка»), `decel_scale()` («Заплутаність» або «Хміль»),
  `wall_run_allowed()` (+ «Хміль»), `hang_bonus_seconds()` («Сила», лише в місті). Стани речовин не діють у кишені.
- **Звис «Сили».** Єдиний новий гачок (T5 § 11): `CityParkourMotor.hang_limit(actor)` = `profile.hang_seconds` + бонус
  тіла; спільний `CityParkourProfile` не мутується. Ним користуються і таймер звису (`:93`), і `hold_remaining`.
- **«Сила» й «Вітаміни» (`CityHunger`).** Таймери в кадрах часу голоду (стоять у паузі, розмові, кишені), сесійні.
  «Сила» 54 000 кадрів: ухил × 1,2 з порогом; звис +1 с у місті; переноситься в кишеню (там × 1,2, таймер стоїть, hp не
  росте). «Вітаміни» 36 000 кадрів: період тіку hp × 0,5 для ситого й голодного (360 → 180, 720 → 360), танення FAINT не
  змінюється. Повторна страва — повний таймер, не сума. `effect_ended` → HUD `STRENGTH WEARS OFF · Stamina and grip back to
  normal`.
- **Корисне в Міри (T7 Л1, класи T5 § 5.2):** `Мочені яблука` 1 жет. +15 «Вітаміни»; `Узвар` 1 жет. +15, W +30, напій,
  «Вітаміни»; `Два яйця в мундирі` 1 жет. +15 «Сила»; `Пиріжок із сиром` 2 жет. +40 «Сила». Рядок прилавка називає
  ефект і час перед ціною: `… · STRENGTH 15:00 · 2 жет.` (T8 п. 3). Відвар і узвар скорочують «Хміль» / «Задишку» (T5 § 4).
- **Продавець алкоголю й тютюну — перехожий `CityVendorEvent.gd` (новий) через `CityEventDirector`**, як В2 (розбіжність 1
  нижче). Біля Ринкової площі; пропонує `Темне з бочки` («Хміль») і `Гільза` («Задишка») по 1 жет., `Ні, дякую`, `Піти`.
  Кнопка: `<назва> · TIPSY 2:00 · <наслідок> · 1 жет.` (T8 п. 3; слова наслідку PLACEHOLDER T7). Алкоголь — ні при H ≤ 50
  (`· спершу поїж`, Ш6), ні при W ≤ 50 (`· спершу вода`, T5 Thirst § 7); цигарку це не обмежує; брак жетонів — словами.
  Відмова нічого не змінює (М2).
- **Режисер.** `EVENTS` += `vendor`; одна пропозиція речовини на сесію спільна для листків і продавця (`leaves_count +
  vendor_count ≥ leaves_per_session`, T5 § 3.6); новий блок `state` — жодної пропозиції, поки триває будь-який стан (М6), і
  для листків теж. Off (`_on_content_changed`): листки або продавець → `abort_active("content")`, `haze.clear()`,
  `substances.clear()`.
- **Кишеня.** Вхід закритий у кожному стані: `TOO TIPSY TO FIGHT · Wait it out, or drink water to clear it sooner`,
  `TOO WINDED TO FIGHT · …` (T8 п. 3); «Заплутаність» — як була. Рядок героя: `CityHunger.pocket_words()` =
  `pocket_status()` + ` · STRENGTH`.
- **HUD (T8 п. 3).** `EffectsLine` (бірюзовий `7bc9c6`) одразу над `HazeLine`: `STRENGTH m:ss · VITAMINS m:ss`.
  `HazeLine` — останній рядок картки, рівно один стан: `HAZE` / `TIPSY` / `WINDED m:ss`. Підказки кінця в чергу тіла на
  2 с: `TIPSY WEARS OFF · Steady steps again`, `WINDED PASSES · Breath comes back`; похмілля без перетину порогу —
  `DRY MOUTH · WATER −15`, з перетином — підказка порогу (п. 2).
- **COMFORT (T8 п. 4, варіант Р2).** Заголовок `DRUGS, ALCOHOL & TOBACCO · CITY ONLY`, пункти `Full — may be offered or sold
  in the city` / `Off — never offered or sold, no states`, довідка T8. Ключ, вузол, порядок і фокус — без змін.

### Розбіжності й рішення блоку 2

1. **Продавець.** Ятки «Кухоль» у коді немає. Обрав перехожого через режисера, а не пункт у мешканця: T7 § 3.1 / § 7 — жоден
   із 12 не п'є, не курить і не продає речовин, а Міра — «ніколи». Перехожий — тимчасовий актор, як В1/В2, і
   ділить з В2 одну пропозицію на сесію (дослівно T5 § 3.6). Вина й міцного немає: T5 дає їм той самий «Хміль», різниця
   лише в ціні — найменший шлях. Квасу немає (лише «Кухоль»).
2. **М6 і для листків.** Новий блок `state` не пускає В2, поки триває стан. `city_leaves_check` L7 починав листки під
   «Заплутаністю» з L6. Змінено лише порядок: стан починається, коли перехожий уже пропонує (`tools/world/city_leaves_check.gd`
   L7, 2 місця). Літерал фікстури, якого T8 п. 6 не називав, — через нове правило T5.
3. **Прилавок.** `city_hunger_check` K9 тримав точний список із трьох страв. Тепер їх сім (+4 корисні), літерал оновлено.
4. **Гальмування «Хмелю».** T5 § 10.5 рахує `v² / 2a` (неперервно): Choko 0,63, Skea 0,69 ± 0,05. Гра інтегрує 60 Гц
   (швидкість оновлюється, потім рух): заміряно **Choko 0,581, Skea 0,636 м**; та сама інтеграція чисел T5 (v 5,6 / 6,2,
   a 50 / 56 × 0,5) дає 0,581 / 0,636. Skea на 0,004 нижче допуску T5. Фікстура порівнює з інтегрованим числом ± 0,02 і
   друкує обидва (`CITY_SUBSTANCES_INFO`). Без стану: 0,268 / 0,293 м. Питання до T5 — допуск.
5. **«Камера біт у біт».** FOV і власний поворот лінзи (yaw ріга, pitch плеча) порівнюються точно. Повний базис — з
   допуском 1e-4: два прогони взагалі без стану розходяться шумом фізики (`player.z` на кадрі 0: 25,9875 проти 25,98556;
   зонд `scratchpad/thirst/probe/subst_dbg.gd`).
6. **«Ти ситий» для корисного.** За H 100 (і W 100 для напою) корисна страва вимкнена, навіть якщо дала б «Силу» — як було.
   Чи продавати ефект ситому, — питання до T5.
7. **Ефекти й стани — лише в сесії**, без поля збереження (як «Заплутаність»). Поз `Drink`, куріння й хиткого кроку немає.

### Перевірка блоку 2

Нова фікстура `tools/world/city_substances_check.gd`: справжній `CityWorld`, Choko, потім Skea; B1–B11 (T5 Substances
§ 10 п. 1–11, Thirst § 11 п. 5, 7, 8), W7, W11 (T8). Ключ і клавіші — справжні події.

**Предмет:** для всіх станів речовин і кожного їхнього кадру нічого не стає кращим (хода, відновлення ухилу й гальмування
≤ 1, бігу по стіні не з'являється, H і hp не вищі, жетони, довіра, пам'ять, доручення — байт у байт); відмова нічого не
змінює; стани не накладаються й закривають кишеню; вода й напої скорочують їх, напій скасовує похмілля, похмілля б'є
лише по W; Off знімає стан одразу без наслідків і жодної пропозиції не буває; «Сила» й «Вітаміни» дають рівно свої числа,
не накопичуються, «Сила» переходить у кишеню.

| команда (`run_fx.sh`) | вихід |
|---|---|
| `city_substances_check.gd` | rc 0, `CITY_SUBSTANCES_COMPLETE checks=85 failures=0 mutation=none`, 0 ERROR / WARNING / leaked |
| `… --break=walk` (`haze.walk_scale` 1,05) | rc 1, failures 1: «B2 haze … walk ≤ 1 (max 1.0500)» |
| `… --break=decel` («Хміль» 1,05) | rc 1, failures 3 |
| `… --break=regen` («Задишка» 1,05) | rc 1, failures 3 |
| `… --break=stack` (стан «забуває» себе) | rc 1, failures 4 |
| `… --break=hangover` (напій не знімає похмілля) | rc 1, failures 1: «W 100 and no hangover (85.00)» |

**Мутації продукту на копії** (`scratchpad/thirst/scripts/mut_block2.py`, фікстура `city_substances_check.gd`). Усі 24 —
FAIL (rc 1). Три спершу вижили — гарди посилено, повтор FAIL:

| мутація (файл: що замінено) | вихід |
|---|---|
| `CitySubstances.begin`: «Хміль» +1 H / цигарка −3 H / `winded_regen_scale` 1,05 | failures 6 / 5 / 3 |
| `CitySubstances.begin`: «Хміль» `bond_once` мешканцю (довіра) | **спершу rc 0**: `bond_once` спрацьовує раз, і перший «Хміль» сесії стався в B1 до гарду. B2 поставлено першим — повтор rc 1, failures 1 |
| `CityVendorEvent`: «Ні, дякую» запам'ятовує обличчя | failures 1 (B3 байт у байт) |
| `CityVendorEvent`: пиво ще й W +10 | **спершу rc 0**: перевірка була `W ≥ 51 − 0,01`. Тепер W і H точно (шкали втримано) — повтор rc 1, failures 1 |
| `CityVendorEvent`: `<` замість `≤` (W 50) | **спершу rc 0**: годинник W тікав, поки підходив перехожий, і край 50 / 51 не перевірявся. Тепер шкали втримано — повтор rc 1, failures 1 |
| `CityEventDirector`: продавець без ключа / без блоку `state` | failures 1 / 3 |
| `CitySubstances.begin`: без перевірки `any_state()` | failures 2 |
| `CitySubstances.step`: «Хміль» звужує FOV | failures 2 (B5, Skea) |
| `CitySubstances.drink`: без `_drank` / похмілля ще й −10 H | failures 1 / 4 |
| `CityWorld`: кишеня відкрита в «Хмелі» | failures 4 |
| `CityThirst.drink_water`: + скорочує «Заплутаність» / + H | failures 1 / 2 |
| `CityHunger`: «Вітаміни» прискорюють і танення / «Сила» сумується / «Сила» не діє в кишені / напій не скорочує стан | failures 1 / 4 / 2 / 3 |
| `CityParkourMotor.hang_limit`: без бонусу | failures 1 («3.02 s with «Сила»») |
| `CityHud`: рядок ефектів під `HazeLine` / червоний колір ефектів | failures 1 / 1 |
| `CityEventDirector`: Off → `drink()` замість `clear()` | failures 2 (B1, W11) |

Супутні прогони після блоку 2 (rc 0, 0 ERROR / WARNING / leaked): `city_hunger_check` 79 / 0, `city_leaves_check` 35 / 0,
`city_thirst_check` 96 / 0, `city_event_director_check` 19 / 0, `city_alley_check` 45 / 0, `city_event_menus_check`
16 / 0, `lethal_fight_check` 121 / 0, `city_controls_check` 48 / 0, `city_economy_check` 24 / 0, `city_haze_check`
34 / 0, `blood_content_check` 74 / 0, `comfort_ui_check` PASS, `comfort_check` 28 / 0, `display_auto_check` 187 / 0,
`graphics_ui_check` 16 / 0, `city_parkour_check` 73 / 0, `parkour_moves_check` 68 / 0, `city_tricks_check` 84 / 0,
`tricks_independent_check` 54 / 0, `tight_station_probe --check` 31 / 0. GDS — 141 / 0. `playable_check.sh`: +1 сценарій
і 5 негативів (217 сценаріїв).

## Блок 3 — іконки й гліфи

### Іконки

- **У гру пішли лише ті, що стоять у меню:** 7 вирізок T6 → `game/assets/ui/icons/items/icon_item_<slug>.png`.
  Прилавок Міри: `rye_loaf` (R1a · 2), `rye_crust` (R1a · 3), `pickled_apples` (R2 · 5), `uzvar` (R2 · 7, умовна → прийнята
  рішенням T1 щодо 4′), `eggs` (R3 · 1, так само). Меню продавця: `dark_beer` (R4 · 4), `cigarette` (R5 · 2). Відвар
  (клітинка провалила кр. 2) і пиріжок (копія пирога) — без іконки, текстом із тим самим полем. Колонка меню не має →
  ковш не потрібен. Решту 19 + 6 вирізок не додавав (критерій 9 T6).
- **Формат:** `python3 -I` по IHDR — усі 7 файлів 512 × 512, depth 8, colortype 6 (RGBA). `.import` створив імпорт Godot
  (`--headless --import`), потім `mipmaps/generate=true`, як у 6 наявних UI-іконок, і повторний імпорт. Зонд
  `scratchpad/thirst/probe/mip_probe.gd`: усі 7 текстур 512 × 512, `has_mipmaps() = true`.
- **Реєстр:** 7 рядків `ui-icon-item-<slug>` у [[Textures-Registry]] § «На диску» за шаблоном T6: job UUID і CDN-URL
  аркуша з [[2026-10-08-Substances-And-Food-Items]] § Джерела вирізок, клітинка, обробка альфи, `gpt_image_2_5` high 2k
  transparent, реф., посилання на [[Item-Sheets-Prompts]], ліцензія як у сусідніх рядках Higgsfield, де використано.
  `python3 tools/gates/texture_registry_check.py` → «на диску: 183 · у реєстрі: 183 · незареєстрованих: 0 · неіснуючих: 0»,
  rc 0 (було 176).
- **Кнопка (T8 п. 5, `NpcDialogue`).** Вибір може назвати `icon` (slug). У списку, де є хоч одна іконка, кожна кнопка
  отримує іконку 32 × 32 ліворуч від тексту: `expand_icon` вимкнено, `icon_max_width` 32, `h_separation` 10, текст
  ліворуч, фільтр `LINEAR_WITH_MIPMAPS`. Рядок без іконки (відвар, пиріжок, «Назад», вихід, «Ні, дякую», «Піти») —
  прозора текстура 32 × 32, тож текст стоїть одним стовпцем. Перенос — `panel_width − 76 − 42`. Список без іконок
  (розмова, доручення) — як був. Вимкнений рядок тьмяніє типовим `icon_disabled_color` (α 0,4), причина — словами.
- **Розбіжність з T8 N5.** T8 боявся, що `expand_icon = true` розтягне іконку у дворядковій кнопці до 64–87 px. За кодом
  Godot 4.7 (`scene/gui/button.cpp:347–374`, `_fit_icon_size` `:477–486`) `icon_max_width` обрізає й розтягнуту іконку
  до 32. Тож N5 ловить прапорець `expand_icon`, а не розмір.

### Гліфи

- **Як гард знає покриття шрифту.** Проєкт не має теми й шрифтів (`grep -n -E "theme|font" game/project.godot` →
  порожньо, як в аудиті T8), тож кожен Label, Button і Label3D малює вбудованим `ThemeDB.fallback_font` — `FontFile`
  «Open Sans SemiBold», `fallbacks` 0. `Font.has_char()` відповідає з карти символів самого шрифту (і його fallbacks, яких
  немає) і **не** питає системний fallback (`allow_system_fallback = true` діє лише під час малювання). Саме тому
  `→` / `✓` «є» на машині з системними шрифтами й «немає» тут. Гард спершу доводить, що відповідь «ні» можлива:
  `A` покритий, `→` (U+2192) і U+E000 — ні; інакше червоне.
- **Що таке «екранний рядок».** Рядкові літерали всіх `res://scripts/**/*.gd` (коментарі пропущено; `\uXXXX` і
  `\UXXXXXX` розкодовуються), окрім викликів консолі (`print*`, `push_error`, `push_warning`, `assert`) і `SmokeTest.gd`
  (лише консоль); усі рядки `res://data/**/*.json`; `display_name` кожного `CharacterData`; `text = "…"` у `.tscn`.
  `MoveData.display_name` (`skea.tres:9` `Jab → Elbow`) на екран не потрапляє — `.tres` не чіпав.
- **Чому фікстура, а не гейт.** Покриття знає лише рушій: шрифт вшито в бінар Godot. Python-гейт мусив би тримати копію
  woff2 і читати cmap (brotli) — друге джерело правди. Фікстура `tools/ui/glyph_coverage_check.gd` питає той самий
  `FontFile`, яким гра малює, і йде в `make check-playable`.
- **Заміни** (усе — покриті символи; перевірено тим самим `has_char`):

| де | було | стало |
|---|---|---|
| прилавок (`CityNpcDirector.food_label`) | `FOOD +25% → 65%` | `FOOD +25% » 65%` |
| кишеня (`LethalHud.gd:227`), дуель (`Hud.gd:310`, `:522–523`) | `S1 ✓` | `S1 OK` (резерв 40 px у дуелі не змінено) |
| журнал паузи (`CityHud.gd`) | `✓ TRACKING ·`, `✓ СЮЖЕТ ·`, `QUEST GUIDE OFF ✓` | `• TRACKING ·`, `• СЮЖЕТ ·`, `• QUEST GUIDE OFF` |
| мітка гака (`CityHud.gd`, `Hud.gd:643`) | `◇ E · HOOK` | `• E · HOOK` |
| головне меню (`MainMenu.gd`) | `HERO:  ◂ CHOKO ▸`, `Comfort & controls ↗` | `HERO:  ‹ CHOKO ›`, `Comfort & controls ›` |
| напрямок цілі (`CityQuestGuide.gd`) | `↑ Ahead`, `→ Right`, `↶ Behind`, `· Higher ↑` | `Ahead`, `Right ›`, `‹ Behind`, `· Higher` |
| вивіски Label3D (`CityInteriors`, `CityMaintenance`, `CityLowerGallery`) | `КРАМНИЦІ  ←`, `ВЕЖА · МІСТ  ↑`, `ОБХІД ↑`, `ДВІР → НИЖНІ СХОДИ → ВЕЖА` | `‹  КРАМНИЦІ`, `ВЕЖА · МІСТ  ›`, `ОБХІД ›`, `ДВІР › НИЖНІ СХОДИ › ВЕЖА` |
| сюжет (`data/story/lower_mark.json` `copied_fact`) | `двір → нижні сходи → годинникова вежа` | `двір — нижні сходи — годинникова вежа` |

  T8 варіантів заміни в документі не дав (`grep -rn "U+2192\|notdef" docs` → лише аудит T8 і план), тож символи обрав я:
  `»` — «стає», `OK` — готово (вужче за `READY`, рядок кишені лишається ≤ 644 px), `•` — обраний пункт, `‹ ›` — бік.
  Остаточні слова — T8 / T7. Літерали фікстур з `→` оновлено: `city_hunger_check` K9 (3 рядки), `city_economy_check`
  E3 (2 рядки).

### Перевірка блоку 3

**Предмет (гліфи):** для всіх екранних рядків гри s і кожного символу c ∈ s шрифт, яким гра малює, має гліф c.
**Предмет (іконки):** для всіх кнопок списку з іконкою іконка стоїть 32 × 32 ліворуч, текст усіх кнопок починається в одному
стовпці, слова цілі, вимкнений рядок пояснює причину словами, список без іконок — як був.

| команда (`run_fx.sh`) | вихід |
|---|---|
| `tools/ui/glyph_coverage_check.gd` | rc 0, `GLYPH_COVERAGE_INFO literals=7365 chars=77`, `GLYPH_COVERAGE_COMPLETE checks=7368 failures=0 mutation=none` (формат рядка виправлено після першої батареї — розділ «Остаточна батарея») |
| той самий гард на чистих сирцях `82a44e7` (`git archive` → копія) | rc 1, **failures 34** — повний список «було» з таблиці вище (`scratchpad/thirst/mut/logs/pm3-base82.log`) |
| `… --break=inject_gd` / `inject_json` / `inject_triple` / `font` | rc 1, failures 1 кожен: `✓` у `.gd`, `→` у JSON, `◇` у потрійних лапках; шрифт, що «має все» → «coverage is not measured» |
| `tools/ui/item_icons_check.gd` | rc 0, `ITEM_ICONS_COMPLETE checks=63 failures=0 mutation=none` |
| `… --break=expand` / `center` / `blank` | rc 1, failures 14 кожен |

**Мутації продукту на копії** — усі FAIL (rc 1):
- гліфи (`mut_block3.py`): `✓` назад у `LethalHud`, `→` у рядку прилавка, `◂ ▸` у `HERO:`, `→` у `lower_mark.json`,
  `"\u2191 Ahead"` (екрановане), `↑` на вивісці, `✗` в одинарних лапках — failures 1 кожна;
- іконки (`mut_block3b.py`): `expand_icon = true` (14), без прозорої заглушки (14), перенос без −42 (2: рядки 560 і 527 px
  при межі 522), без мипмап-фільтра (14), без `icon_max_width` (14: «drawn 512 × 512»), буханець з іконкою окрайця (1),
  продавець без іконок (15), іконки в кожному списку (1).

**Нативні кадри для T8 / T6** (`tools/world/thirst_items_capture.gd`, xvfb, `gl_compatibility`, як `ci.yml:78–80`; rc 0,
`THIRST_ITEMS_CAPTURE_COMPLETE frames=6`, єдиний WARNING — відомий V-Sync llvmpipe): `scratchpad/thirst/frames/` —
`card_plain.png` (FOOD 100 % / WATER 100 %), `card_states.png` (FOOD 45 % HUNGRY, WATER 22 % PARCHED, HEALTH 77 %,
`STRENGTH 14:58 · VITAMINS 9:58`, `TIPSY 1:58` останнім), `counter.png` (прилавок з іконками), `vendor.png` (продавець),
`comfort.png` (новий рядок DRUGS), `pump.png` (колонка й `G · Drink water · free`). Усі 1280 × 720. Кадрів 3840 × 2160 не
знімав.

## Остаточна батарея (2026-10-08, остаточне дерево)

**Перша батарея — червона, моя помилка.** `make check-playable` (14:02–15:05 UTC, логи `scratchpad/thirst/final/`) → rc 2,
`PLAYABLE CHECK: 226 scenarios, 4 failures`: чотири `glyph-coverage-negative-*`. Сама фікстура працювала (rc 1, одна власна
помилка `GLYPH_COVERAGE:` у кожному), але друкувала `… failures=1 literals=… chars=… mutation=inject_gd`, а шаблон
негативу в `playable_check.sh` вимагає рядка, що закінчується `failures=[1-9][0-9]* mutation=<m>`. Негативи блоку 3 я
ганяв `run_fx.sh`, не шаблоном гарнесу, тож не побачив. Виправлено: лічильники — окремим рядком
`GLYPH_COVERAGE_INFO literals=L chars=C`, сентинел — `GLYPH_COVERAGE_COMPLETE checks=N failures=M mutation=<m>`, регекс
позитиву в `playable_check.sh` — так само. Перевірено кодом самого гарнесу на підмножині
(`scratchpad/thirst/scripts/playable_subset.sh` — копія `playable_check.sh` з фільтром `ONLY`, `diff` — 2 рядки):
`PLAYABLE CHECK: 5 scenarios, 0 failures`. Решта 222 сценарії першої батареї — PASS; у позитивах 0 ERROR, 0 leaked і
**1 WARNING**: `city-maintenance.log` — `Jolt Physics job system exceeded the maximum number of jobs`
(`jolt_job_system.cpp:123`, рушій). Повтор `city-maintenance` тим самим гарнесом 3 рази — 0 WARNING; у 34 інших теках
логів батарей у `scratchpad/` цього рядка немає (`grep -rl` → лише цей лог). Фікстура ходить дахами в `CityDistrict` і
спраги, станів чи іконок не торкається. Вважаю перебоєм потоків рушія; на огляд T4.

**Друга батарея — остаточне дерево** (логи `scratchpad/thirst/final2/`). Джерела під час прогону не мінялися: sha256
усіх файлів `git ls-files -co --exclude-standard game tools Makefile` до і після — `diff` порожній, 907 файлів.

- `GODOT_BIN=… make check-playable` → rc 0, 15:07–16:06 UTC. Він містить `make check`:
  - імпорт без помилок;
  - GDS «перевірено: 141 · не парсяться: 0», канарка — FAIL як треба (було 137: нові `CityThirst`, `CityWaterPump`,
    `CitySubstances`, `CityVendorEvent`);
  - `[smoke] ALL OK (165 checks) in 19847 frames`, `SMOKE ЗЕЛЕНИЙ`;
  - `PLAYABLE CHECK: 226 scenarios, 0 failures` (було 205: +4 сценарії `city-thirst`, `city-substances`,
    `glyph-coverage`, `item-icons`; +17 негативів: 5 + 5 + 4 + 3).
- Нові й змінені сценарії: `CITY_THIRST_COMPLETE checks=96 failures=0`, `CITY_SUBSTANCES_COMPLETE checks=85 failures=0`
  (`CITY_SUBSTANCES_INFO` гальмування: Choko 0,581 м, Skea 0,636 м), `GLYPH_COVERAGE_COMPLETE checks=7368 failures=0`
  (`literals=7365 chars=77`), `ITEM_ICONS_COMPLETE checks=63 failures=0`, `CITY_HUNGER_COMPLETE checks=79 failures=0`,
  `CITY_ECONOMY_COMPLETE checks=24 failures=0`, `CITY_LEAVES_COMPLETE checks=35 failures=0`, `CITY_HAZE` 34 / 0,
  `CITY_EVENT_DIRECTOR` 19 / 0, `CITY_ALLEY` 45 / 0, `CITY_EVENT_MENUS` 16 / 0, `LETHAL_FIGHT` 121 / 0,
  `CITY_CONTROLS` 48 / 0, `BLOOD_CONTENT` 74 / 0, `CITY_MAINTENANCE` 74 / 0.
- Усі 127 негативів — `PASS rc=1`, у кожному є власний `ERROR:`. У 99 логах позитивів — 0 `ERROR:`, 0 `WARNING:`,
  0 `leaked` / `still in use at exit` (`scratchpad/thirst/scripts/scan_logs.sh`).
- `GODOT_BIN=… make gates` → rc 0, `БАТАРЕЯ ЗЕЛЕНА`: wikilinks 0 зламаних (7883 лінки), реєстр 183 / 183, якорі
  `state.md`, R8 у планах, парність ролей — ок, GDS 141 / 0.
- **Дуель біт у біт.** `living_body_check.gd -- --dump=scratchpad/thirst/duel-after` (14:03, після останньої правки
  `game/`: `find game -newer duel-after/choko_skea_off.tsv -type f` → 0 файлів) → `cmp` усіх 4 дампів із
  `duel-before` (чистий `82a44e7`) — однакові; sha256 `choko_skea_{off,on}` `a3b963487086876f…`,
  `skea_choko_{off,on}` `84b63712d0ed7740…`. `git diff --stat 82a44e7 -- game/scripts/fighter game/scripts/arena
  game/scenes/fighter game/scenes/arena game/data/characters '*.tres' game/project.godot` → порожньо.

## Що відкрите

- **T5.** Усі нові числа — PLACEHOLDER (`@export` у `CityThirst`, `CitySubstances`, `CityHunger`). Підтвердити: допуск
  гальмування «Хмелю» (Skea 0,636 м інтегровано проти 0,69 ± 0,05 неперервно — розбіжність 4 блоку 2); чи продавати
  корисну страву ситому (6); ефекти й стани лише в сесії (7); одна пропозиція на сесію на В2 і продавця разом (§ 3.6
  дослівно); місце колонки (−2,2; 0; 17,8) замість (0; 0; 17) (розбіжність 1 блоку 1); квас без «Кухля» не продається.
- **T6.** Колонка — процедурна заглушка (форма, матеріал, місце); кольори WATER `8fb8de` і рядка ефектів `7bc9c6`;
  прийняття 6 нативних кадрів (`scratchpad/thirst/frames/`); пози `Drink` (3 с), куріння й хиткого кроку не зроблено;
  чай і пиріжок без іконки (прозора заглушка); звуки `thirst_cue` і `pump_drink` — лише імена, файлів немає (виклик мовчить,
  `Sfx.gd:6`).
- **T7.** Слова — усе PLACEHOLDER: WATER-слова й підказки, «Темне з бочки», «Гільза», відмова продавця, «спершу поїж» /
  «спершу вода», `DRY MOUTH · WATER −15%`, `TIPSY WEARS OFF`, `WINDED PASSES`, `STRENGTH WEARS OFF`, `TOO TIPSY TO FIGHT` / `TOO WINDED TO FIGHT` на вході в кишеню, підписи станів у меню;
  тексти вивісок після заміни гліфів (`‹  КРАМНИЦІ`, `ВЕЖА · МІСТ  ›`, `ОБХІД ›`, `ДВІР › НИЖНІ СХОДИ › ВЕЖА`) і
  `copied_fact` у `lower_mark.json` (`двір — нижні сходи — годинникова вежа`).
- **T8.** Остаточні символи замість `→ ✓ ◇ ◂ ▸ ↗ ↑ ↶ ←` (обрав T2: `» OK • ‹ ›`), зокрема в дуельному `Hud.gd`
  (`S1 OK`, `• E · HOOK`); одне слово для двох FAINT (розбіжність 3 блоку 1); N5 ловить прапорець `expand_icon`, а не
  розмір (Godot обрізає до 32); кадри 3840 × 2160 не знято; підпис DRUGS і його довідка.
- **T3.** «Показане вживання» (PEGI): у грі є лише покупка в меню й стан на HUD, без анімації пиття чи куріння — чи цього
  досить для оцінки з [[2026-10-08-Alcohol-Tobacco-Rating]].
- **T4.** Умова 4′ для узвару й яєць (іконки прийняті рішенням T1) — у грі, кадр `counter.png`.
- **T1.** `state.md` T2 не правив — оновлює T1 після власної батареї; журнал зустрічі — T1. Виправлення `InputRouter`
  (розбіжність 2 блоку 1) вмикає gamepad `interact` у всьому місті — не лише в колонки: розмови, прилавок, листки, пастка.

## Related

- [[2026-10-08-Thirst-Substances-Icons]] · [[ADR-026-Substances-Nutrition-And-Thirst]] · [[2026-10-08-Thirst-Numbers]] · [[2026-10-08-Substances-And-Nutrition]]
- [[06-UI-UX]] · [[PROPOSAL-Substances-And-Healthy-Food]] · [[2026-10-08-Substances-And-Food-Items]] · [[Item-Sheets-Prompts]] · [[Textures-Registry]]
- [[2026-10-08-Survival-Hunger-Fix]] · [[state]]
