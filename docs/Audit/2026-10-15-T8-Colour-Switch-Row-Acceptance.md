# T8 — приймання рядка COLOURS (TEST) у COMFORT

**Дата:** 2026-10-15 · **Роль:** T8 Гермес · **Що приймаю:** крок 9 [[2026-10-14-T6-Acceptance-Crane-Albedo-AB]] (частина T8):
рядок `COLOURS (TEST)` у `game/scripts/ui/ComfortPanel.gd` з журналу [[2026-10-15-Colour-Switch-Fix]] і відхилення
виконавця (+1 зупинка в кільці фокусу, три фікстури). · **Дерево:** `scratchpad/t8-acc-tree`, detached `407595d`
(`git -C t8-acc-tree log --oneline -1` → `407595d Fix the stall wedge, close the district edge and add the A/B3 colour
switch`), після роботи прибране. · **Godot:** `4.7.stable.official.5b4e0cb0f`. Продукт не змінював. У репо записав лише
цю сторінку і правку [[06-UI-UX]]. Кредитів 0.

## Підсумок

| # | пункт | вердикт | що переробити | хто |
|---|---|---|---|---|
| 1 | Підписи `COLOURS (TEST)` · `A — current` · `B3 — palette-true light` | **GREEN** | як є приймаю; разом із п. 3 `A — current` → `A — the game as it is` (ТЗ, крок 2) | T2 |
| 2 | Місце під GRAPHICS QUALITY | **GREEN** | нічого: місце як у плані, рядок видно одразу при відкритті | — |
| 3 | Фокус і геймпад | **YELLOW** | кільце правильне. Але на екранах 16:9 і ширших панель відкривається з фокусом на MASTER, якого не видно: блок рядка (223 логічних px) зсунув MASTER нижче видимої частини скролу | T2 за ТЗ нижче |
| 4 | Застосування одразу й збереження | **GREEN** | нічого | — |
| 5 | Ширина рядка на екрані | **GREEN** | нічого: найдовший пункт 349 з 884 px | — |
| 6 | Тач | **GREEN в емуляції** | нічого. На пристрої не перевірено. Розмір кнопки — спільний успадкований GAP панелі | — |
| 7 | Відхилення T2: нове кільце в трьох фікстурах | **приймаю** | новий порядок правильний. Літерал у [[06-UI-UX]] оновлено (§ нижче) | — |

**Загалом — YELLOW, RED немає.** Дефект один (п. 3): з'явився разом із рядком. На M3 у повному екрані (16:10) його немає,
у вікні 1152×648 на тому ж M3 — є.

## Як перевіряв

Усі шляхи `scratchpad/…` — у scratchpad головної сесії; мій каталог — `scratchpad/t8-acc/` (зонди `probe/`, логи `logs/`,
кадри `shots/`). Кадри лежать лише там: у репо дозволено писати тільки цю сторінку й 06-UI-UX.

- Імпорт: `godot --headless --path game --import` → rc 0, 3 хв 36 с, рядків `ERROR` 0 (`logs/import.log`).
- **Фікстури T2** — тим самим командним рядком, що в `tools/gates/playable_check.sh` (`--headless --audio-driver Dummy
  --fixed-fps 60 --quit-after 12000`), з окремим `XDG_DATA_HOME` на кейс (`t8-acc/run4.sh`):

```
colour-switch      rc=0  COLOUR_SWITCH_COMPLETE checks=144 failures=0 mutation=none red=none rs=not-measured-headless
graphics-ui        rc=0  GRAPHICS_UI_COMPLETE checks=17 failures=0
display-auto       rc=0  DISPLAY_AUTO_COMPLETE checks=187 failures=0 mutation=
blood-content      rc=0  BLOOD_CONTENT_COMPLETE checks=74 failures=0 mutation=none
comfort-ui         rc=0  COMFORT_UI PASS (0 failures; mutation=)
city-controls      rc=0  CITY_CONTROLS_COMPLETE checks=48 failures=0 mutation=none
ui                 rc=0  UI_LAYOUT PASS (0 failures; mutation=)
graphics-settings  rc=0  GRAPHICS_CHECK_COMPLETE checks=63 failures=0
colour-switch --break=row       rc=1  … failures=5 mutation=row red=row,row_save
colour-switch --break=row_save  rc=1  … failures=3 mutation=row_save red=row_save
```

  У восьми позитивних логах `ERROR` 0, `WARNING` 0, витоків 0.
- **Мій зонд** `probe/t8_colour_row_probe.gd` (sha256 `ee6f00e3d2d625f2…`), незалежний від фікстур T2. Панель відкривається
  справжнім шляхом: `MainMenu.tscn` → фокус на COMFORT & CONTROLS → Enter. Події клавіатури, геймпада й дотику йдуть через
  `Input.parse_input_event`. Конфіг — власний `user://t8_probe_*`. Остаточна версія, headless, полотно 1600×900:
  `T8PROBE_COMPLETE checks=22 failures=0`, rc 0, `ERROR` 0 / `WARNING` 0 / витоків 0 (`logs/probe_final_full.log`).
- **Нативно** (xvfb, `--rendering-method gl_compatibility`, llvmpipe, екран = вікно в повному екрані): 1280×720 —
  `checks=22 failures=0` (`logs/probe_native_1280x720.log`); 3840×2160 — режим `--quick` без обходів кільця (повний
  обхід на llvmpipe 4K не вклався в 400 с, rc 124, `logs/probe_native_3840x2160.log`), `checks=6 failures=0`. У кожному
  нативному лозі `ERROR` 0, `WARNING` 1 — це рядок драйвера `Could not set V-Sync mode` (llvmpipe). Кадри знято
  проміжними ревізіями того самого зонда; код кадрів і кроків перед ними не змінювався.

## 1. Підписи — GREEN

Тексти дослівно з рантайму (`logs/probe_final_full.log`):
`title="COLOURS (TEST)" items="A — current | B3 — palette-true light" help="A colour test for comparing two looks. Applies
immediately; A is the game as it is."` — збігаються з `ComfortPanel.gd:29–31`.

- `(TEST)` у заголовку чесно каже, що рядок тимчасовий. Журнал T2 (п. 8 «Що лишилось відкритим») прибирає рядок після вибору
  Santos.
- `A` / `B3` — латиниця від назв варіантів А / Б3 з плану й аркушів, які читає Santos. Панель уся англійська, тож
  латиниця на місці. Інших написань `color` / `colour` у рядках гравця немає (`grep -rn -o -i -E
  '"[^"]*\bcolou?rs?\b[^"]*"' game/scripts/ui` → лише `ComfortPanel.gd:29`, `:31`).
- `palette-true light` можна прочитати як «світліше». На аркушах Compatibility Б3 справді світліший
  (`docs/assets/screenshots/2026-10-15-colour-switch-street.jpg`), тож тут підпис не бреше. На M3 Б3 у тіні буде темнішим
  ([[2026-10-15-Colour-Switch-Fix]], відкрите п. 1). Для одного тестувальника, який знає, що таке Б3, це прийнятно.
- `A — current` двозначне, коли вибрано Б3: «current» можна прочитати як «той, що діє зараз». Зараз це знімає підпис під
  рядком (`A is the game as it is`). ТЗ п. 3 прибирає підпис, тому пункт треба перейменувати на `A — the game as it is`:
  320 px на 32 px (`probe/t8_text_width.gd` → `T8WIDTH A — the game as it is = 320.0`). Фікстура тримає лише
  `begins_with("A ")` (`colour_switch_check.gd:345`), тож перейменування її не ламає.

## 2. Місце — GRAPHICS QUALITY, одразу під нею — GREEN

`T8PROBE ORDER children: quality=4 quality_help=5 colour_title=6 colour=7 colour_help=8`, далі — блок MASTER. Тобто
порядок такий: список якості → його підпис → COLOURS (TEST) → список → підпис → MASTER. Це крок 8 плану («рядок у
`ComfortPanel` під якістю графіки»). При відкритті рядок видно: `row_rect` y 542–595 у видимій частині скролу y 107–726
(`row_visible_at_open=true`); кадр `shots/native-atopen-1280x720.png`.

Ціну я сам називав для рядка апскейлера (§ GRAPHICS QUALITY, U2: «зайва зупинка фокуса й зламаний крок MASTER ↔ GRAPHICS»).
Тут я її приймаю: рядок тимчасовий, а місце Santos погодив разом із планом.

## 3. Фокус і геймпад — YELLOW

**Кільце правильне.** Зонд обходить кільце від MASTER, поки фокус не повернеться (повтори на довідці, яка спершу
прокручується, згорнуто). Імена — вузли панелі, `@Button@142` = RESTORE, `@Label@143` = CONTROLS (довідка),
`@Button@145` = BACK:

```
keyboard ↓ / D-pad ↓ / Tab : MasterSlider → SfxSlider → MusicSlider → ShakeSlider → HitFlash → BloodMode → DrugsMode
                             → RESTORE → CONTROLS → BACK → DisplayMode → GraphicsQuality → ColourTest → MasterSlider
keyboard ↑ / D-pad ↑       : MasterSlider → ColourTest → GraphicsQuality → DisplayMode → BACK → CONTROLS → RESTORE
                             → DrugsMode → BloodMode → HitFlash → ShakeSlider → MusicSlider → SfxSlider → MasterSlider
```

Геймпад іде тим самим кільцем, що й клавіатура (`pad_down == down`, `pad_up == up` → OK). У рядку: Enter / pad A
відкриває список, pad B закриває лише список (фокус лишається на рядку, панель відкрита), Esc закриває панель і повертає
фокус на COMFORT & CONTROLS. Після вибору фокус лишається на рядку. Телефонне кільце (без DISPLAY) перевіряють фікстури T2:
`colour_switch_check.gd:411–413` і `blood_content_check.gd` `_ring(…, false)`. Обидві зелені, сам на телефонному
макеті не обходив.

**Дефект: при відкритті фокус на MASTER, а MASTER не видно.** `show_panel` ставить фокус на MASTER (`ComfortPanel.gd:225`)
і повертає скрол на 0 (`:224`, `:229`), щоб DISPLAY стояв угорі. Новий блок (заголовок 45 + рядок 53 + підпис у 2 рядки
71 + 3 × 18 проміжків = **223** логічних px; `T8PROBE OPEN block_height=223.0`) зсунув MASTER нижче видимої частини:

| вікно (фізичне) | полотно (логічне) | видима частина скролу, y | MASTER: заголовок / повзунок, y | видно |
|---|---|---|---|---|
| 1152×648 (WINDOWED), 1280×720, 1920×1080, 3840×2160 | 1600×900 | 107–726 | 702–747 / 751–791 | **ні** |
| 2560×1080 (21:9), 2532×1170 | 1600×900, ширше | 107–726 | 702–747 / 751–791 | **ні** |
| 1680×1050 (16:10) | 1600×1000 | 107–826 | те саме | так |
| 2560×1664, 2940×1912 (форма екрана M3) | 1600×1040 | 107–866 | те саме | так |
| 1024×768 (4:3) | 1600×1200 | 107–1026 | те саме | так |
| 1600×900 **без** трьох вузлів COLOURS (як до кроку 8) | 1600×900 | 107–726 | 479–524 / 528–568 | так |

Джерело — `T8PROBE OPEN …` у `logs/probe_open_<W>x<H>.log` (headless, `--size`) і в нативному
`logs/probe_native_1280x720_open.log` (ті самі логічні числа, `canvas_scale=(0.8, 0.8)`). На кадрі
`shots/native-atopen-1280x720.png` заголовок `MASTER 80%` обрізаний знизу, повзунка й рамки фокуса не видно ніде.

Що це означає для гравця:
- на 16:9 панель відкривається без видимого фокуса;
- ← / → змінюють гучність MASTER, якої гравець не бачить (`city_controls_check` якраз на цьому кроці знижує MASTER клавішею ←);
- ↓ прокручує, і лише тоді MASTER з'являється.

Телефона це не стосується: там немає рядка DISPLAY. Це висновок за розрахунком, на телефонному макеті не міряв.

## 4. Застосування одразу й збереження — GREEN

Зонд, той самий кадр після вибору (значення в сесії й значення, передане в `RenderingServer` — `colours_applied`):
- клавіатура ↑ Enter ↓ Enter → `setting b3, handed b3`, `graphics.cfg` `colours="b3"`;
- pad A, D-pad ↑, A → `a` / `a`, `colours="a"`;
- дотик (п. 6) → `b3`, збережено;
- повторне відкриття показує поточне значення.

Фікстура T2 (`colour-switch` 144/0) додатково тримає: RESTORE не скидає рядок, невідоме чи пошкоджене значення дає A і не
перезаписує файл, невдалий запис видно в статусі. Негатив `row` (рядок без `set_colours`) → `red=row,row_save`, а
`row_save` (без збереження) → `red=row_save`.

Межа: значення в самому рушії headless назад не читається. Що шейдери справді перемикаються, доводять нативні кадри T2
([[2026-10-15-Colour-Switch-Fix]], «Нативно»), я їх не переганяв.

**Спостереження, не дефект.** Панель затемнює світ на α 0,94 (`ComfortPanel.gd:58`). Тому «Applies immediately» правдиве
для рушія, але різницю A / Б3 Santos побачить лише після закриття панелі. Для порівняння «туди-назад» на M3 це
Esc → COMFORT → ↑ → Enter → ↓ → Enter → Esc щоразу. Окрема клавіша означала б нову дію `debug_*` у `[input]`, тобто ADR.
Не пропоную, доки Santos не скаже, що так незручно.

## 5. Ширина рядка — GREEN

Headless і нативно числа однакові (`T8PROBE SIZE …`):

| що | логічні px | 1280×720 (×0,8) | 1920×1080 (×1,2) | M3 2940×1912 (×1,84) | 3840×2160 (×2,4) |
|---|---|---|---|---|---|
| ширина стовпця = рядок | 884 (892 − смуга прокрутки 8) | 707 | 1061 | 1624 | 2122 |
| висота рядка | 53 (як у GRAPHICS QUALITY) | 42 | 64 | 97 | 127 |
| шрифт пунктів / заголовка | 32 | 25,6 | 38,4 | 58,8 | 76,8 |
| найдовший пункт `B3 — palette-true light` | 349 тексту, мінімум кнопки 381 | 279 | 419 | 641 | 838 |
| заголовок `COLOURS (TEST)` | 250 | 200 | 300 | 459 | 600 |
| підпис, шрифт 24 | 937 в один рядок → 2 рядки, висота 71 | шрифт 19,2 | 28,8 | 44,1 | 57,6 |
| список, що розкрився | 389 × 106 | 311 × 85 | — | — | 934 × 254 |

Запас по ширині — 884 − 381 = 503 px, обрізання немає (`min 381 ≤ 884` → OK). Кадри:
- `shots/native-focus-1280x720.png`, `shots/native-open-1280x720.png`;
- `shots/native-focus-3840x2160.png`, `shots/native-open-3840x2160.png`.

На обох масштабах текст рядка й списку читається, перенос є лише в підписі.

Позначка вибраного пункту в списку — стандартна радіо-іконка теми Godot, вона не масштабується з шрифтом 32 px і стоїть
впритул до тексту. Так у всіх шести списках панелі, це не особливість рядка. Розмір іконки не міряв.

## 6. Тач — GREEN в емуляції

`input_devices/pointing/emulate_mouse_from_touch=true` (типове, зонд друкує його). Дотик у центр рядка відкриває список, а
дотик у нижню половину списку з двох пунктів вибирає B3 і зберігає його (`a tap on the row opens the list`, `a tap on the
second item picks B3`, `touch pick saved` → OK). На пристрої не перевірено: мобільного вводу ще немає ([[05-Platforms-Input]]).
Висота 53 логічних — та сама, що в сусідніх рядках. Тач-розміри панелі приймаються окремо, як і записано в [[06-UI-UX]]
§ DISPLAY п. 5.

## 7. Відхилення T2: +1 зупинка в кільці — приймаю

- **Порядок правильний.** Він збігається з порядком `_focus_order` у коді (`ComfortPanel.gd:86`, `:97`, `:109`, `:132`,
  `:144`, `:152`, `:164`, `:177`, `:181`, `:189`) і з моїм обходом у п. 3.
- **Фікстури змінено лише в кроках кільця.** `git diff --numstat 69b56d1 407595d`:
  - `blood_content_check.gd` — `3 2`: `colour_choice` у `_ring()` і рядок-коментар;
  - `display_auto_check.gd` — `5 1`: ще одне ↑, повідомлення `↑↑↑ from MASTER`;
  - `graphics_ui_check.gd` — `4 1`: ↑ на COLOURS (TEST) з новою перевіркою, далі ↑ на GRAPHICS.
- **Жодної перевірки не прибрано:** `graphics-ui` 16 → 17, `display-auto` 187 = 187, `blood-content` 74 = 74.
- **Старі версії справді тримали кільце.** Ті самі три файли з `69b56d1` проти коду `407595d`:
  - `GRAPHICS_UI_COMPLETE checks=16 failures=11`, перша причина — `keyboard reaches graphics through focus order`;
  - `DISPLAY_AUTO … failures=9`, перша — `keyboard reaches DISPLAY: ↑↑ from MASTER`;
  - `BLOOD_CONTENT … failures=2` — `the desktop ring follows the T8 literals` і `the phone ring …`.

  Усі rc 1 (`logs/old_*.log`). Нові версії зелені (вище).

**Текст для [[06-UI-UX]]** (вписав сам, § «Випадки міста: COMFORT і HUD» п. 1, де літерали для фікстур):

```
DISPLAY → GRAPHICS QUALITY → COLOURS (TEST) → MASTER → SOUND EFFECTS → MUSIC → CAMERA SHAKE → HIT FLASH → BLOOD → DRUGS
→ RESTORE SOUND & SHAKE DEFAULTS → CONTROLS (довідка) → BACK → DISPLAY
```

Телефон: те саме без DISPLAY, кільце замикається BACK → GRAPHICS QUALITY. Фокус при відкритті — MASTER, скрол 0.

Інші правки сторінки:
- нова підсекція «COLOURS (TEST)» під GRAPHICS QUALITY. Лише те, що є в коді, плюс посилання на дефект п. 3;
- шляхи клавіатури й геймпада до DISPLAY: ↑↑ → ↑↑↑;
- рядок про ↑ від MASTER у § GRAPHICS QUALITY.

Нових рішень щодо заголовка чи кільця там немає.

## ТЗ для T2 (п. 3 і п. 1)

**Аудит:** вище, п. 3 — таблиця вікон і `block_height=223`.

**Варіанти:**

| варіант | що дає | що коштує | вердикт |
|---|---|---|---|
| **О1 — прибрати підпис під рядком (2 рядки по 24 px), пункт A перейменувати на `A — the game as it is`** | MASTER видно на 1600×900: заголовок y 613–658, повзунок 662–702 при видимій частині до 726 (`T8PROBE OPEN_WITHOUT_HELP`, ті самі вузли з прихованим підписом). DISPLAY угорі, кільце й «відкриття на MASTER» без змін | губиться речення «Applies immediately» (через затемнення 0,94 воно й так не видно оком, п. 4) | **обрано** |
| О2 — лишити підпис, а при відкритті прокручувати до MASTER | тексти без змін | на 16:9 треба ≈ 65 px прокрутки (791 − 726): заголовок DISPLAY (45) іде за верхній край. Це суперечить «скрол 0 показує DISPLAY угорі» (§ DISPLAY п. 1). Логіка прокрутки поруч із `follow_focus` | відкинуто |
| О3 — підпис скоротити до одного рядка | слова лишаються | за оцінкою економить ≈ 34 px (один рядок із двох у 71): повзунок ≈ 717–757 > 726, тобто все одно не видно | відкинуто |
| О4 — фокус при відкритті на першому рядку | MASTER не потрібен угорі | ламає усталене «відкривається на MASTER» у 4 фікстурах і шляхи ↑ у 06-UI-UX; ← / → на DISPLAY перемикали б режим вікна | відкинуто |
| О5 — лишити як є до вибору Santos | 0 змін | на кожному екрані 16:9 і у вікні панель відкривається без видимого фокуса | відкинуто |

**Погляди:**

| погляд | що виграє / що втрачає | що це змінило |
|---|---|---|
| Santos на M3, повний екран 16:10 | зараз не зачеплений; з О1 бачить заголовок і два пункти, підпис йому не потрібен | О1 не шкодить головному тестувальнику |
| Santos у вікні 1152×648 або на зовнішньому 1080p / 4K | зараз відкриває панель без видимого фокуса | О1 / О2 / О4 це лагодять, О5 ні |
| гравець з геймпадом на дивані, 1080p | ← «на пробу» мовчки знижує MASTER | потрібен видимий фокус одразу: О1 або О2 |
| слабозорий / майбутній TEXT SIZE 125–150 % (GAP) | більший текст ще нижче зсуне MASTER | гард класу, а не лише цього рядка (крок 3) |
| тестер, CI | наступний рядок над MASTER повторить дефект | гард на трьох полотнах `comfort_ui_check` з негативом |
| виконавець (T2) | О1 — видалити 3 рядки й константу, змінити 1 рядок тексту; гард ≈ 10 рядків | О2 і О4 дорожчі й зачіпають чужі контракти |
| сам рядок тимчасовий | після вибору Santos його приберуть | О1 не лишає нічого, що треба відкочувати; гард лишається корисним |

**Мірила:** фокус видно при відкритті на всіх полотнах, які перевіряє `comfort_ui_check`; кільце й «відкриття на MASTER»
без змін; DISPLAY угорі при скролі 0; 0 нових дій вводу; найменша правка.

**Кроки для T2:**
1. `game/scripts/ui/ComfortPanel.gd`: прибрати мітку `colour_help` (`:114–116`) і константу `COLOUR_HELP` (`:31`).
   Заголовок `COLOURS (TEST)` і `B3 — palette-true light` не міняти.
2. Там само `COLOUR_LABELS[0]`: `A — current` → `A — the game as it is`. Решта порядку й ключі `a` / `b3` без змін.
3. Гард у `tools/ui/comfort_ui_check.gd`. На кожному з трьох полотен (1600×900, 1600×1200, 1948×900) відкрити панель
   заново: прокрутка скидається лише в `show_panel`. Вимога: `scroll.get_global_rect()` повністю містить і повзунок MASTER,
   що має фокус, і його заголовок. Негатив `comfort-ui-negative-<ім'я T2>`: над MASTER вставлено мітку у 2 рядки по 24 px
   → червоний. Рядок кейсу додати в `playable_check.sh` з префіксом `ERROR: COMFORT_UI: `.
4. Перевірка:
   - кейси `comfort-ui` з негативами, `colour-switch` з 9 негативами, `graphics-ui`, `display-auto`, `blood-content`,
     `city-controls` → `PLAYABLE … 0 failures`;
   - `make check`, `make gates` → rc 0;
   - нативний кадр 1280×720 при відкритті: видно заголовок і повзунок MASTER з рамкою фокуса.
5. Після правки T8 оновлює § COLOURS (TEST) у [[06-UI-UX]] (підпис і пункт A) і приймає кадр.

## Відкрите

- **T2:** ТЗ вище (YELLOW п. 3 і перейменування п. 1).
- **T6:** кадри «увімкнено» — друга половина кроку 9, не моя.
- **Santos / T1:** порівняння вимагає закривати панель (затемнення 0,94). Якщо на M3 це заважатиме, окрема клавіша — нова
  дія `debug_*` через ADR (п. 4).
- **Не перевірено:** фізичний геймпад і тач на пристрої, Retina / Forward+ на M3, телефонний макет панелі (окрім фікстур
  T2), нативні кадри перемикання шейдерів (їх знімав T2).

## Related

- [[2026-10-14-T6-Acceptance-Crane-Albedo-AB]] · [[2026-10-15-Colour-Switch-Fix]] · [[2026-10-15-Albedo-B3-Fix]]
- [[06-UI-UX]] · [[05-Platforms-Input]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]] · [[state]]
