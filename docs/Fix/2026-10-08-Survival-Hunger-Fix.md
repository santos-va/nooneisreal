# Доробки етапу 1 подій і шкала голоду — журнал виконання

**Дата:** 2026-10-08 · **Роль:** T2 Гефест · **Статус:** блоки А (з доповненням T1 за аудитом T4) і Б виконано; на
остаточному дереві `make check`, `make check-playable` (205 / 0) і `make gates` зелені, дуель біт у біт. Журнал писався по
ходу: контейнер уже перезапускався. Гілка `claude/t1-orchestration-2026-10-07`, база `60e484b`. Коміт і push — T1 після власної
перевірки; merge — Santos. Кредитів не витрачено. `.tres`, input map і `project.godot` не змінюються.
Сирі логи — `scratchpad/hunger/`.

Джерела:
- блок А — специфікація T8 [[06-UI-UX]] § «Випадки міста: COMFORT і HUD — GAP-специфікація 2026-10-08»;
- блок Б — план [[2026-10-08-Survival-Hunger]] крок 4, числа T5 [[2026-10-08-Hunger-Numbers]], HUD T8 [[06-UI-UX]]
  § «Шкала голоду в HUD міста», їжа T7 [[PROPOSAL-Food-Of-Cronshift]] § 3, [[ADR-025-Street-Scuffle-And-City-Events]] п. 4.

## Хід роботи

- 2026-10-08: прочитано роль, конституцію, `state.md` (▶ Хвиля п. 7), специфікації T8, числа T5, пропозицію T7, план.
  `git status --short` → порожньо; `git rev-parse HEAD` → `60e484b…`. Godot:
  `Godot_v4.7-stable_linux.x86_64 --version` → `4.7.stable.official.5b4e0cb0f`.
- Блок А (код, фікстури, прогони) → посеред роботи доповнення T1 (6 пунктів аудиту T4) → мутації продукту на копії →
  блок Б → мутації продукту блоку Б → перша батарея `make check-playable` (08:01 UTC): smoke 165 / 19 847, GDS 137 / 0,
  перші 52 сценарії — 51 PASS і `city-controls` FAIL (пауза за 900 px, див. Б3); виправлено, батарею зупинено на
  стенді й запущено заново на остаточному дереві (08:11 UTC).
- Друга батарея (08:11–08:57 UTC): `make check` зелений (GDS 137 / 0, smoke 165 / 19 847), `PLAYABLE CHECK: 205
  scenarios, 1 failures`, rc 2. Єдиний FAIL — `auto-hook-negative-base`: сам негатив червоний як треба
  (`AUTO_HOOK_COMPLETE checks=162 failures=40 mutation=base`), але на виході рушій надрукував `WARNING: 4 ObjectDB
  instances were leaked at exit` і `ERROR: 2 resources still in use at exit` — рядок не з префіксом негативу, тож обв'язка
  його відкинула. Повтор того самого негативу на копії тієї ж версії тричі — без цього рядка. Причина — вихід фікстури без
  шаблону (`auto_hook_check.gd` не звільняв `Sfx` / `UltMusic` / `Music`, як інші фікстури з 2026-10-07, клас «нестабільний
  вихід», [[2026-10-07-Living-Body-Fix]]). Додав шаблон у `tools/grapple/auto_hook_check.gd`; повтор негативу 6 разів —
  rc 1, `failures=40`, 0 рядків про витоки. У позитивних логах другої батареї — 0 `WARNING`, 0 `ERROR`
  (`grep` по `*.log` без `negative`). Третя батарея — на остаточному дереві (09:00 UTC).
- Окремий S12–S14 спершу стояв у `city_alley_check`, але з ним прогін виходив за `--quit-after 12000` кадрів (негативи
  `sword` і `zero` закінчувались без рядка-сторожа). Тому меню подій — окрема фікстура `city_event_menus_check.gd`.

## Звірка блоку А з реальністю

| що в задачі / специфікації T8 | команда | вихід |
|---|---|---|
| рядка DRUGS немає | `grep -n -i drugs game/scripts/ui/ComfortPanel.gd` (до змін) | порожньо — збігається |
| `blood_content_check.gd` рядки 220, 234–238, 246–252, 253–255 | `grep -n "Down from" tools/fx/blood_content_check.gd` (до змін) | коментар `:221`, кроки `:237`, `:248`, `:255` — зсув на 1 рядок, суть збігається |
| `NpcDialogue.gd:88` — підпис кнопки виходу | `sed -n 88p game/scripts/npc/NpcDialogue.gd` | `close_button.text = "Завершити розмову · Esc / B"` — збігається |
| `CityAlleyEvent.gd:252–253` — Esc у пастці = погоня | `sed -n 252,253p game/scripts/world/CityAlleyEvent.gd` | `"trap": _start_chase()` — збігається |
| `CityAlleyEvent.gd:160` — прихований таймер | `sed -n 160p game/scripts/world/CityAlleyEvent.gd` | `if phase_time > ask_seconds or …` — збігається; `phase_time` росте в `_physics_process` (`:111`) і тоді, коли меню відкрите |
| нуль жетонів перевіряється лише на старті | `grep -n "alley_min_credits" game/scripts/world/CityEventDirector.gd` | `:148` — збігається |
| `CityLayout.gd:60` — «dead end» | `sed -n 60p game/scripts/world/CityLayout.gd` | `# Southeast passage (a dead end): …` — збігається |
| `HAZE FADES`, `NOT IN THIS STATE` | `grep -rn "HAZE FADES\|NOT IN THIS STATE" game/scripts` | `CityHud.gd:82`, `CityWorld.gd:332` — збігається |
| дуель до змін | `living_body_check.gd -- --dump=scratchpad/hunger/duel-before` на чистому `60e484b` | rc 0, `LIVING_BODY_COMPLETE checks=10 failures=0`; sha256 `a3b96348…511a` (choko×skea, off = on) і `84b63712…9adb` (skea×choko) — ті самі, що в журналі етапу 1 |

Розбіжностей, що міняють мету, немає.

## Блок А — що зроблено (2026-10-08, по ходу)

### А1. Рядок `DRUGS · CITY ONLY` у COMFORT

- `ComfortPanel.gd`: блок HIT FLASH переїхав перед BLOOD, одразу після BLOOD — рядок `DRUGS · CITY ONLY` (вузол
  `DrugsMode`, `drugs_choice`, `DRUGS_LABELS` = `Full — a passer-by may offer a smoke` / `Off — no offer and no haze`,
  підпис T8 дослівно). Застосування за шаблоном BLOOD: `set_drugs_mode` → `save_settings` → статус. RESTORE рядок не
  скидає. `drugs_choice` — у `_choices()` і `_sync_values()`. Пошкоджений `content.cfg` → рядок показує Off
  (`ContentSettings.drugs_mode()` повертає `off`), запис відмовляє наявним статусом.
- Порядок фокусу (літерали T8): DISPLAY → GRAPHICS QUALITY → MASTER → SOUND EFFECTS → MUSIC → CAMERA SHAKE → HIT FLASH
  → BLOOD → DRUGS → RESTORE → довідка → BACK → DISPLAY; телефон — без DISPLAY, BACK → GRAPHICS QUALITY.
- `tools/fx/blood_content_check.gd`: кільце звіряється літералами для десктопу й телефону (`mobile_override = 1`);
  CAMERA SHAKE ↓ → HIT FLASH; BLOOD ↓ → DRUGS; HIT FLASH ↓ → BLOOD; DRUGS ↓ → RESTORE; DRUGS справжніми подіями:
  клавіатура (з BLOOD) ↓ Enter ↓ Enter → Off, `content.cfg` має `drugs="off"`; геймпад A, D-pad ↑, A → Full; RESTORE не
  чіпає DRUGS. Новий негатив `drugs_row` — рядок, що не викликає `set_drugs_mode`.

**Предмет:** для всіх виборів у рядку DRUGS: значення доходить до `ContentSettings` і `content.cfg` одразу, а кільце
фокусу має рівно порядок T8.

| команда (`scratchpad/hunger/scripts/run_fx.sh`, як `playable_check`: ізольований XDG, `--fixed-fps 60`) | вихід |
|---|---|
| `blood_content_check.gd` | rc 0, `BLOOD_CONTENT_COMPLETE checks=74 failures=0 mutation=none`, 0 ERROR, 0 WARNING |
| `… -- --break=drugs_row` | rc 1, `checks=29 failures=2`: «keyboard picks DRUGS Off (got full)», «the DRUGS choice is saved to content.cfg» |
| `display_auto_check.gd` | rc 0, `DISPLAY_AUTO_COMPLETE checks=187 failures=0` — не ламається, як і казав T8 |
| `comfort_ui_check.gd` | rc 0, `COMFORT_UI PASS (0 failures; mutation=)` |
| `graphics_ui_check.gd` | rc 0, `GRAPHICS_UI_COMPLETE checks=16 failures=0` |
| `city_controls_check.gd` | rc 0, `CITY_CONTROLS_COMPLETE checks=48 failures=0 mutation=none` |

**Розбіжність 6 журналу етапу 1 — T8 правий.** `display_auto_check.gd:500–504` перевіряє лише DISPLAY першим, GRAPHICS
другим, відкриття на MASTER і BACK ↔ DISPLAY; вставка в середину кільця їх не ламає — прогін вище (187 / 0). Рядок
журналу етапу 1 виправлено.

### А2. Чотири дефекти меню (код)

- (а) `NpcDialogue.show_choices(text, choices, close_label, guard)`: кнопка виходу бере підпис від меню й має мітку
  `close`. Пастка передає `Тікати · Esc / B`; окремий пункт «Тікати» прибрано — Esc / B і кнопка роблять одне:
  `dialogue_closed()` → `_start_chase()`. Решта розмов — без змін (типовий підпис).
- (б) Захист: меню, яке відкрив світ (`guard = true`), не пропускає `ui_accept` / `ui_cancel` (натиск і відпуск) у
  `_input` до GUI перші `guard_seconds` = 0,35 с (PLACEHOLDER T8) і доки клавіша, утримана в цей час, не відпущена.
  ↑ / ↓ діють одразу, вигляд не змінюється. Захищені: пастка, що спрацювала сама, і факти після світової події
  (наздогнали, відповідь на меч). Меню, відкриті гравцем (interact, вибір пункту), — без захисту.
- (в) `CityAlleyEvent._physics_process`: `phase_time` не росте, поки фаза `ask` і меню відкрите.
- (г) **Нуль жетонів — вибір T2.** Жетони рахуються заново при кожному відкритті пастки. Варіанти: В1 — показати
  `Віддати · 0 жет.` вимкненим (перший безпечний вихід зникає, фокус іде на «Говорити», яке загрози напевно не
  закінчує — проти правила T8 § 3); В2 — замість «Віддати» перший і з фокусом пункт `Вивернути кишені · жетонів немає`:
  грабіжники нічого не беруть і йдуть (результат `empty`), обличчя пам'ятається; В3 — не запускати пастку (прохач «не
  може знати» про порожні кишені — нечесно до вигадки, і подія зникала б мовчки). **Обрано В2:** безпечний вихід
  лишається першим, ціна в ньому правдива (нуль), пункт закінчує загрозу без бою. Якщо наздогнали з нулем — «Обшукують —
  порожньо», нічого не взято. Слова — PLACEHOLDER для T7. Вибір «give» при нулі (застарілий натиск) нічого не робить.
- Також за T8 § 3: для знайомого обличчя `Я тебе пам'ятаю` стоїть першим і з фокусом.

### Доповнення T1 до блоку А (аудит T4 `31caa4c`, YELLOW без RED), отримано посеред роботи

T1: PR #187 змерджений, `main` = `28958f0`, гілку перезапущено від `main`; `git diff --stat 60e484b HEAD -- game tools` →
порожньо, тож точка «до» для дуелі лишається `60e484b`. Шість пунктів:
1. рядок «Здається, одне з твоїх доручень уже можна завершити.» (`NpcConversationContext.gd:43-47`) згасає разом із
   `current_fallback` — зробити незгасним; так само рядок ціни Кравця «М’ятну можна приміряти без жетонів.»; у H5 —
   випадок із готовим дорученням на 4 ходи;
2. згасання спрацьовує й після кінця стану — перевіряти `haze_active()`; перевірка в H9;
3. жодна фікстура не ловить `director.rng.randf()` → `randf()` у відповіді на меч — сторож глобального RNG у S7/S8 і
   «той самий сід → та сама реакція»;
4. L6 після «Затягнутись» перевіряє лише жетони — порівнювати весь `progress.snapshot()` і `relationships`, як L4;
5. гілка `sword` у пастці: не переходити в `react`, якщо `draw_sword_for_event()` повернув false; негатив;
6. журнал етапу 1 `:80`: «pocket (4)» → «(3)».
Кожен новий сторож має ловити мутацію продукту (клас 5): мутацію записую тут, прогін на копії — FAIL.

### Доповнення T1 — виконано (код і фікстури)

1. `NpcConversationContext`: константи `QUEST_READY_LINE`, `PRICE_LINES` і `never_fade()`; `CityHaze.fade_line(text,
   salt, keep)` пропускає речення з `keep` і рахує парність лише серед згасальних (без `keep` — біт у біт як раніше);
   `CityNpcDirector` передає `never_fade()`. Обрав «не згасати на місці», а не перенос у хвіст: результат той самий
   (рядок ніколи не згасає), а текст `reply()` для локальної моделі не змінюється. `city_haze_check` H5: готове доручення
   Міри, 4 вітання поспіль у стані — рядок цілий у 4 з 4, а щось інше згасає в 4 з 4; рядок ціни Кравця цілий для солей
   0–3.
2. `CityNpcDirector._physics_process`: згасання лише якщо `haze.haze_active()`. H9: репліка, показана за 1 с до кінця
   стану, після кінця лишається цілою.
3. `city_alley_check` S7/S8: сторож глобального RNG (`seed(4242)` → `randi()` до й після «Вийняти меч»), новий S15 — той
   самий сід режисера → та сама відповідь (50/50).
4. `city_leaves_check` L6: увесь `progress.snapshot()`, `relationships` мешканців і `drugs_mode` — як L4.
5. `CityAlleyEvent.choose("sword")`: спершу `draw_sword_for_event()`; false → пастка лишається з меню. S7: герой у BLOCK
   тисне «Вийняти меч» → фаза `trap`, меню відкрите, меча немає, реакції немає.
6. Журнал етапу 1: `pocket (4)` → `(3)`; T2 переміряв `city_event_director_check.gd -- --break=pocket` двічі →
   `failures=3` обидва рази. Там же виправлено розбіжність 6 (див. А1).

**Мутації продукту на копії** (`scratchpad/hunger/scripts/mutrun.py`: копія `game/` у `scratchpad/hunger/mut/game`, одна
заміна в одному файлі, фікстура з репо чи знімка `snapA`; сирі логи — `scratchpad/hunger/mut/logs/`). Усі — FAIL:

| мутація (файл: що замінено) | фікстура | вихід |
|---|---|---|
| `ComfortPanel`: обробник DRUGS не викликає `set_drugs_mode` | `blood_content_check` | rc 1, failures 2 |
| `ComfortPanel`: рядок DRUGS перед BLOOD | `blood_content_check` | rc 1, failures 10 (кільце, кроки фокусу) |
| `ComfortPanel`: обробник DRUGS не викликає `set_drugs_mode` | `city_leaves_check` (L7 через рядок) | rc 1, failures 2 |
| `CityAlleyEvent`: типовий підпис кнопки + окремий «Тікати» | `city_event_menus_check` | rc 1, failures 2 |
| `NpcDialogue._input`: захист прибрано (`pass`) | `city_event_menus_check` | rc 1, failures 2 |
| `NpcDialogue._process`: захист знімається, хоч клавіша ще утримана | `city_event_menus_check` | rc 1, failures 1 (M1 «held past 0.35 s») |
| `CityAlleyEvent`: `phase_time` росте й при відкритому меню | `city_event_menus_check` | rc 1, failures 2 (M3) |
| `CityAlleyEvent.open_trap`: «Віддати» завжди, і при 0 | `city_event_menus_check` | rc 1, failures 2 (M4: `Віддати · 0 жет.`) |
| `CityHud`: старі слова `HAZE FADES` | `city_haze_check` | rc 1, failures 1 (H6) |
| `CityWorld`: старі слова `NOT IN THIS STATE · …` | `city_haze_check` | rc 1, failures 1 (H8) |
| п. 1 `CityNpcDirector`: `fade_line` без `never_fade()` | `city_haze_check` | rc 1, failures 1: «kept 2, faded 4» — рівно знахідка T4 (2 з 4) |
| п. 2 `CityNpcDirector`: згасання без `haze_active()` | `city_haze_check` | rc 1, failures 1 (H9) |
| п. 3 `CityAlleyEvent`: `director.rng.randf()` → `randf()` | `city_alley_check` | rc 1, failures 2 (S7, S8 сторож RNG) |
| п. 4 `CityLeavesEvent`: «Затягнутись» ще й `remember_face("leaves_man", 0)` | `city_leaves_check` | rc 1, failures 1 (L6) |
| п. 4 `CityLeavesEvent`: «Затягнутись» ще й `population.bond_once(5, …)` | `city_leaves_check` | rc 1, failures 1 (L6) |
| п. 5 `CityAlleyEvent`: старий порядок (`react`, потім спроба вийняти меч) | `city_alley_check` | rc 1, failures 2: «stays in the trap … (react)», «Choko's sword is drawn» |

Сторожі блоку А з фікстурними негативами (`--break=`) додатково мають і негатив продукту — рядки вище: кожен новий
сторож ловить мутацію коду гри, а не лише фікстури.

### А3–А4. Слова HUD, коментар

- `CityHud.HAZE_FADES_TEXT` = `HAZE LIFTING · Steps and view come back`; `CityWorld.HAZY_ENTRY_TEXT` = `TOO HAZY TO FIGHT
  · Wait it out, or eat at «Шавлія» to clear it sooner` (обидва — остаточні слова T8).
- `CityLayout.gd:60`: «a dead end» → «open to the south: it ends in the strip z 30–32 along SouthBoundary».

## Звірка блоку Б з реальністю

| що в плані / джерелах | команда | вихід |
|---|---|---|
| голоду в коді немає | `git grep -il -E "hunger\|голод" 60e484b -- game/scripts game/data` | 1 файл — `CityHaze.gd`, і там лише коментар «No hunger flag»; системи немає — збігається |
| `restart_at` скидає hp (T5 § 4) | `git grep -n "hp = data.max_hp" 60e484b -- game/scripts/fighter/Fighter.gd` | `:203`, `:273` (`reset_for_round`), `:338` — збігається |
| тік ухилу `Fighter.gd:770-779` | `git grep -n "func _tick_dodge_stamina" 60e484b -- …/Fighter.gd` | `:770` — збігається; перевизначено в `CityFighter`, `Fighter.gd` не змінено |
| раунд 1 кишені з повним hp (`MatchFlow.gd:55-69`) | `sed -n 55,69p game/scripts/arena/MatchFlow.gd` | збігається; `MatchFlow.gd` не змінено — hp входу ставить `CityLethalFight` після `setup` / `rematch` |
| «Поїсти · 1 жет.» у Міри | `git grep -n "Поїсти" 60e484b -- game/scripts` | `CityNpcDirector.gd:355` — збігається; замінено прилавком |
| безпечна точка — `CityJourney.resume_position()` через `recover_to_spawn` | `grep -n "resume_position\|func recover_to_spawn" game/scripts/world/CityWorld.gd` | збігається |

**Розбіжності джерел між собою і з кодом** (жодна не міняє мети; рішення названо, для T1 / T5 / T7 / T8 — у «Відкрите»):
1. **Їжа в «Заплутаності».** T5 § 6: «будь-яка їжа … стан переходить у згасання 10 с»; рішення T1 у задачі: так робить
   перекус «Відвар шавлії»; T7 § 3 дає цю властивість саме відвару. Зроблено буквально за T1: лише відвар; буханець і
   окраєць стан не скорочують (`city_hunger_check` K9 це перевіряє).
2. **hp після кишені.** T5 § 4 («після кишені hp і H такі самі, як були до входу») писав для П2а. З «Повним переносом»
   лишив те саме: рани з кишені в місто не переходять, місто не лікує й не ранить. Чи так — T5.
3. **Слово в кишені.** T8 дав лише `HUNGRY · slower stamina`; для FAMISHED / FAINT дописав `… · slower stamina and walk`
   (PLACEHOLDER, T8).
4. **Пункт Міри в стані.** Специфікація подій T8 (§ 3) хотіла `Поїсти · 1 жет. · голова проясниться` першим; специфікація
   голоду замінила одиничний пункт прилавком. Старт стану знижує H до ≤ 45, тож прилавок і так іде першим; суфікс не
   додавав, щоб підписи в стані й без нього були біт у біт (T8 N2). Про відвар каже репліка Міри М9 у тілі прилавка.
5. **Голод під час навчання.** T8 радить «не тікає», T5 цього не вирішив. Тікає за правилом T5 § 2 («у міському
   дослідженні») — до рішення T5.
6. **Відлік окрайця зберігається** (`crust_wait`, ≤ 216 000 кадрів), інакше вихід і повторний вхід обнуляли б «раз на
   15 хв». Борг (T7 § 3.2) не зберігається. Підтвердити — T5.
7. **hp міста — лише на сесію** (T5 § 4 «на час сесії»): новий вхід у місто — повне hp; зберігається лише H.
8. «hp з міста (не нижче межі 40 %)» реалізовано як hp входу = `max(hp міста, 40 %)`.

## Блок Б — шкала голоду (2026-10-08, по ходу)

### Б1. Модель і ефекти

- `game/scripts/world/CityHunger.gd` (новий, вузол `CityWorld`): H у сотих 0…10000, −1 кожні 18 кадрів годинника міста;
  годинник стоїть у паузі, розмові й будь-якому модалі (`InputRouter.ui_suppressed`), у смертельній кишені й під час
  падіння. У скриптовому прогоні (`GraphicsSettings.scripted_run`) H = 100 і годинника немає, доки фікстура не викличе
  `enable_for_test`. `simulate(n)` — той самий крок кадру `n` разів (для 25 хв у фікстурі без 90 000 кадрів рушія).
  Усі числа T5 — `@export`, PLACEHOLDER.
- Пороги 50 / 25 / 10 (sated / hungry / famished / faint). Ефекти — лише тіло:
  - `CityFighter._tick_dodge_stamina`: відновлення ухилу × 1 / 0,75 / 0,6 / 0,5 (пауза 0,22 с, ціна, невразливість — як
    були); `speed_mult()` × 1 / 1 / 0,85 / 0,75 (множиться із «Заплутаністю» й утомою);
  - `CityParkourMotor`: біг по стіні (вертикальний Skea і вбік) лише до «famished»; хапання, відштовх, перескок —
    без змін;
  - hp міста: +1 % / 6 с (ситий), +1 % / 12 с (голодний), стоїть (виснажений), −1 % / 5 с до межі 40 % (знесилений);
    нижче межі не тане й не росте; `restart_at` hp не наповнює (місто тримає своє значення).
- Падіння на H = 0: `CityFighter.collapse_from_hunger()` — наявний KO (регдол без імпульсу, стан KO, без шкоди, крові й
  сигналу `knocked_out`); темрява наростає в другій половині 1,5 с; `CityWorld.recover_to_spawn()` → безпечна точка;
  H = 30, hp ≥ 40 %, жетони −min(жетони, 3); підказка `You collapsed from hunger · lost N tokens` 4 с; перша розмова з
  Мірою — М6.
- «Заплутаність»: на сигнал `CityHaze.started` (лише свіжий старт) H = max(min(H − 20, 45), min(H, 11)).
- Кишеня («Повний перенос»): `CityLethalFight` бере `CityHunger.pocket_entry_hp()` після `flow.setup` і після кожного
  `rematch` (RETRY); H у бою стоїть; після кишені `closed` → hp міста. `LethalHud.status_suffix` — слово стану в рядку
  героя. Дуель, VERSUS, тренування: `Fighter.gd`, `MatchFlow.gd`, `Hud.gd` не змінено.
- Збереження: `CityProgress` поля `hunger` (0…10000) і `crust_wait` — необов'язкові; наявні мусять бути точними, інакше
  збереження не перезаписується (як `faces`). `set_hunger` пише файл без сигналу `changed` (журнал не перебудовується за
  тік). Запис: зміна порогу, їжа, падіння, раз на хвилину годинника, вихід зі сцени.

### Б2. Їжа в «Шавлії»

- Пункт Міри `Поїсти · FOOD n% · жетони n` — першим, коли H ≤ 50, інакше після доручень. Прилавок: заголовок
  `Припаси «Шавлії» · Жетони: n · FOOD n%`, репліка Міри (М7 / М8 / М9 T7), три страви
  `<назва> · +N% → M% · K жет.`: «Відвар шавлії» +25 / 1, «Житній буханець» +60 / 2, «Окраєць у борг» +30 / 0 (лише
  0 жетонів і H ≤ 25, потім 54 000 кадрів годинника). Недоступне показане вимкненим із причиною словами: `бракує N жет.`,
  `ти ситий`, `лише коли жетонів немає`, `коли FOOD ≤ 25%`, `Міра пригостить пізніше` (PLACEHOLDER T7/T8). Потім
  `Назад до розмови`. Купив — одразу з'їв; `ui_confirm`; фокус лишається на страві, якщо її ще можна взяти, інакше —
  на «Назад». H не вище 100. Репліки порогів М3–М5 — у хвості вітання (не згасають).

### Б3. HUD

- `CityHud`: у картці статусу під смугою stamina — `FOOD n%[ · HUNGRY|FAMISHED|FAINT]` (ширина зарезервована під
  `FOOD 100% · FAMISHED`) і власна смуга 8 px (`CityMeterBar`, новий) з насічками 50 / 25 / 10; у FAINT смуга отримує
  рамку 2 px. `HEALTH n%` + смуга з насічкою 40 % — лише коли hp < max або FAINT. HAZE лишився останнім рядком.
  Зростання FOOD ≤ 0,3 с, спад — одразу. Перетин порогу вниз — підказка 3 с і `Sfx.play("hunger_cue", -8)` один раз;
  знову — лише після підйому на +5; FAINT повторює звук раз на 30 с. Черга нижнього рядка з двох (FAINT не витісняється).
  Темрява падіння — `CollapseVeil` під паузою. Довідка в паузі: окремий рядок T8 виштовхнув паузу за 900 px
  (`city_controls_check` у першій батареї: «RETURN TO MAIN MENU [P: (300, 863), S: (1000, 59)] fits (1600, 900)» — FAIL),
  тож, як T8 і передбачив, він замінив частину наявного тексту: рядок розмови тепер
  `Sword: V / R3 · Talk for tasks: G / Y + D-pad Down · Food: Mira in «Шавлія»`; слова станів показує сам рядок FOOD.
  Після цього `city_controls_check` 48 / 0 і `district_ui_check` 33 / 0. Без тряски, пульсу, фільтрів. Файлу
  `hunger_cue` немає — виклик мовчить (`Sfx.gd:6`).

### Б4. Перевірка: `tools/world/city_hunger_check.gd` (новий)

Справжній `CityWorld` (збереження вимкнені), Choko, K0–K11 — кожен пункт T5 § 9, «Повний перенос» і HUD T8 (P1–P4,
P6–P8, N3, N5, N6). Літерали — T5 / T8, з коду фікстура їх не читає.

**Предмет:** для всіх кадрів міської гри H втрачає одну соту на 18 кадрів і більше ніщо його не змінює, крім їжі, старту
стану й падіння; годинник стоїть у паузі, розмові й кишені; ефекти порогу точні, межа тримає; H = 0 завжди закінчується
на безпечній точці з H 30, hp ≥ 40 % і −min(жетони, 3); кишеня бере hp міста (≥ межі), відновлення й ходу порогу, а RETRY
повертає hp входу; окраєць — лише за умовою; збереження тримає H точно.

| команда (`run_fx.sh`, як `playable_check`) | вихід |
|---|---|
| `city_hunger_check.gd` | rc 0, `CITY_HUNGER_COMPLETE checks=79 failures=0 mutation=none`, 0 ERROR, 0 WARNING |
| `… --break=rate` (18 → 20 кадрів) | rc 1, failures 2: «3000 frames → 98.34 (98.50)», «90 000 → 50.00 (55.00)» |
| `… --break=gate` (розмова відпускає токен UI) | rc 1, failures 1: «a conversation: 300 frames, H unchanged (7984)» |
| `… --break=pocket_clock` (`hunger.lethal = null`) | rc 1, failures 1: «the lethal pocket: … (7984)» |
| `… --break=floor` (межа 0) | rc 1, failures 5 (K4 межа, K7 hp входу) |
| `… --break=collapse` (втрата 0 жетонів) | rc 1, failures 3 (K5) |
| `… --break=haze` (без стелі 45) | rc 1, failures 1: «H 100 → 45 (80.00)» |
| `… --break=retry` (RETRY без hp входу) | rc 1, failures 2: «RETRY gives back the entry hp 630 (1050)», «… 420 (1050)» |
| `… --break=crust` (окраєць без умови H ≤ 25) | rc 1, failures 1: «K8 at H 30: no crust» |

Супутні прогони після блоку Б: `city_economy_check` 24 / 0 (негатив `price` — rc 1, failures 2), `city_haze_check` 34 / 0,
`district_ui_check` 33 / 0 (пауза з новим рядком довідки вміщується), `layout_check` PASS, `lethal_fight_check` 121 / 0
(голод у скриптовому прогоні не біжить → кишеня як була), `city_parkour_check` 73 / 0, `parkour_moves_check` 68 / 0.

**Мутації продукту блоку Б на копії** (той самий `mutrun.py`, знімок `scratchpad/hunger/snapB`, фікстура
`city_hunger_check.gd`; кожна — FAIL):

| мутація (файл: що замінено) | вихід |
|---|---|
| `CityHunger`: `_decay_left = decay_frames - 2` (інший темп) | rc 1, failures 2 (K1 98.13 / 43.76) |
| `CityHunger.ticking`: без `ui_suppressed()` | rc 1, failures 1 (K2 розмова) |
| `CityHunger`: годинник не бачить кишені (дві заміни) | rc 1, failures 6 (K2, K7) |
| `CityFighter.speed_mult`: без множника голоду | rc 1, failures 2 (K3) |
| `CityFighter._tick_dodge_stamina`: без множника голоду | rc 1, failures 4 (K3, K7 22,5 / с) |
| `CityHunger.wall_run_allowed`: завжди true | rc 1, failures 2 (K3) |
| `CityHunger._tick_hp`: знесилений тік без `maxf(межа, …)` | **спершу rc 0** — 630 і 1050 лежать над межею рівно на ціле число кроків 10,5, тож перескок не видно. K4 переписано на 625; повтор — rc 1, failures 2 («… (415.0)») |
| `CityHunger._tick_hp`: тане й нижче межі (`if true`) | rc 1, failures 1 (K4) |
| `CityHunger._physics_process`: без повернення hp міста після `restart_at` | rc 1, failures 1 (K4 «a restart refills nothing») |
| `CityHunger._wake`: `spend_credits(0)` | rc 1, failures 3 (K5) |
| `CityHunger._wake`: H = 100 замість 30 | rc 1, failures 2 (K5) |
| `CityHunger._on_haze_started`: `H − 20` без стелі й підлоги | rc 1, failures 4 (K6) |
| `CityLethalFight.open`: `entry_hp = -1` | rc 1, failures 4 (K7) |
| `CityLethalFight.retry`: без `_apply_entry_hp()` | rc 1, failures 2 (K7) |
| `CityHunger.food_state`: окраєць без умови H ≤ 25 | rc 1, failures 1 (K8) |
| `CityHunger.feed`: окраєць не ставить відлік 15 хв | rc 1, failures 3 (K8) |
| `CityProgress.restore`: без перевірки поля `hunger` | rc 1, failures 4 (K10: пошкоджене перезаписано) |
| `CityHud`: гістерезис +5 прибрано | rc 1, failures 3 (K11 «one hint» → 11, K5) |
| `CityNpcDirector`: прилавок не першим, коли голодний | rc 1, failures 1 (K9) |
| `CityHunger.feed`: будь-яка їжа скорочує стан | rc 1, failures 1 (K9 «the loaf does not end it») |
| `CityHunger.setup`: годинник і в скриптовому прогоні | rc 1, failures 2 (K0) |

### Дуель біт у біт

`living_body_check.gd -- --dump=<тека>`, 900 тиків на кожен порядок героїв; «до» — чистий `60e484b` (на початку
сесії), «після» — робоче дерево з блоками А і Б:

| траса | sha256 до | sha256 після | TSV |
|---|---|---|---|
| choko × skea (off / on) | `a3b963487086876f…511a` | `a3b963487086876f…511a` | `cmp` — тотожні |
| skea × choko (off / on) | `84b63712d0ed7740…9adb` | `84b63712d0ed7740…9adb` | `cmp` — тотожні |

`git diff --stat -- game/scripts/fighter game/scripts/arena game/scripts/ui/Hud.gd game/data game/project.godot` →
порожньо: `Fighter.gd`, `MatchFlow.gd`, `Hud.gd`, `.tres`, input map і `project.godot` не змінено.

## Остаточна батарея (2026-10-08, остаточне дерево)

Сирі логи — `scratchpad/hunger/final/`. Джерела під час прогону не мінялися: sha256 усіх `game/**/*.gd` і `tools/**/*.gd`,
`*.sh`, `*.py` до і після — `diff -q` без різниці.

- `GODOT_BIN=… make check-playable` → rc 0, 08:59–09:48 UTC. Він містить `make check`:
  - імпорт без помилок;
  - GDS «перевірено: 137 · не парсяться: 0», канарка — FAIL як треба (було 135; нові `CityHunger.gd`, `CityMeterBar.gd`);
  - `[smoke] ALL OK (165 checks) in 19847 frames`, `SMOKE ЗЕЛЕНИЙ`;
  - `PLAYABLE CHECK: 205 scenarios, 0 failures` (було 190: +2 сценарії `city-event-menus`, `city-hunger`; +13 негативів:
    `blood-content` `drugs_row`, `city-leaves` `row`, `city-event-menus` ×3, `city-hunger` ×8).
- Нові й змінені сценарії: `CITY_HUNGER_COMPLETE checks=79 failures=0`, `CITY_EVENT_MENUS_COMPLETE checks=16 failures=0`,
  `CITY_ALLEY_COMPLETE checks=45 failures=0`, `CITY_LEAVES_COMPLETE checks=35 failures=0`, `CITY_HAZE_COMPLETE checks=34
  failures=0`, `CITY_ECONOMY_COMPLETE checks=24 failures=0`, `BLOOD_CONTENT_COMPLETE checks=74 failures=0`.
- Усі 110 негативів — `PASS rc=1`. У логах позитивних сценаріїв — 0 рядків `ERROR:` / `SCRIPT ERROR:` і 0 `WARNING:`
  (`grep -lE` по `*.log` без `negative` → 0 файлів).
- `GODOT_BIN=… make gates` → rc 0, `БАТАРЕЯ ЗЕЛЕНА`: wikilinks 0 зламаних (7682 лінки), реєстр 176 / 176, якорі `state.md`
  ок, R8 у планах ок, GDS 137 / 0.

## Що відкрите

- **T5.** Усі числа голоду — PLACEHOLDER (`CityHunger` `@export`). Підтвердити: їжа в стані (розбіжність 1: зроблено
  «лише відвар» за T1, T5 § 6 казав «будь-яка»); рани з кишені не переходять у місто (розбіжність 2); відлік окрайця в
  збереженні (6); голод під час навчання тікає (5); гістерезис +5; голод у сутичці етапу 2 (бриф § 3.3 «встає з повним
  HP» з голодом не сходиться — T5 § 7 пропонує `hp = max(hp, 40 %)`). Вимога до економіки (≥ 4 жет./год повторних
  джерел) у цьому заході не робилась — за рішенням T1.
- **T7.** Слова (усе PLACEHOLDER): `Вивернути кишені · жетонів немає`, «Голодранець», «Обшукують — порожньо», причини
  недоступності на прилавку, репліки після їжі; М3–М9 узято з [[PROPOSAL-Food-Of-Cronshift]] § 4 як є.
- **T8.** Нативні кадри 1280×720 і 3840×2160: картка з FOOD / HEALTH, COMFORT із рядком DRUGS, меню пастки, прилавок; слово
  стану в кишені для FAMISHED / FAINT (розбіжність 3); safe area й TEXT SIZE для `CityHud` / `NpcDialogue` — не робилось
  (GAP T8, поза цим заходом); підпис `Esc / B` на кнопці виходу досі зашитий (загальний GAP гліфів).
- **T6.** Кольори станів FOOD, насічок, рамки FAINT і темряви падіння; пози порогів (бурчання, рука на животі,
  `Idle_Tired_Loop`) і анімація `Consume` за прилавком — не робилось; кадри в сірому.
- **T3.** Джерело для 0,35 с захисту меню; джерело й ліцензія `hunger_cue` (файлу немає, виклик мовчить).
- **T1.** `state.md` (статус виконання) T2 не правив — оновлює T1 після власної перевірки; журнал зустрічі — T1.
- **Межі реалізації.** hp міста живе лише в сесії; падіння в повітрі чи на тросі — трос відчіпляється, регдол падає
  фізикою; поведінки «новачок не знав про їжу» поза підказками й окрайцем немає.

## Related

- [[2026-10-08-Survival-Hunger]] · [[2026-10-08-Hunger-Numbers]] · [[06-UI-UX]] · [[PROPOSAL-Food-Of-Cronshift]]
- [[ADR-025-Street-Scuffle-And-City-Events]] · [[2026-10-08-City-Events-Stage-1]] · [[2026-10-08-City-Events-Stage-1-Fix]] · [[state]]
