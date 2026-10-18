# MASTER видно при відкритті COMFORT: без підпису під COLOURS (TEST) і гард на трьох полотнах — журнал виконання

**Дата:** 2026-10-15 · **Роль:** T2 Гефест (T2-З) · **Статус:** зроблено в дереві без коміту. `make check` і
`make gates` — rc 0; `comfort-ui` з 8 негативами і всі 57 кейсів, що відкривають панель, зелені; уся батарея 413 / 413
(§ «Перевірка»). Мерж — Santos.
**Задача:** ТЗ T8 [[2026-10-15-T8-Colour-Switch-Row-Acceptance]] § «ТЗ для T2» (YELLOW п. 3 і перейменування п. 1).

Дерево — scratchpad `t2h-tree`, detached `69cffac`. Не комічу, не пушу. Основне дерево не чіпаю. Кредитів не витрачаю.
Логи — scratchpad `t2h/` (далі `H/`). Шейдери, логіку перемикача й кільце фокусу не чіпаю.

## Звірка задачі з реальністю

| що в ТЗ | команда / місце | вихід | що роблю |
|---|---|---|---|
| голова дерева | `git -C t2h-tree log --oneline -1` | `69cffac Name the failing guard family in city-tidy negatives and refuse unknown prop kinds` | — |
| ТЗ писано на `407595d`; чи мінявся `ComfortPanel.gd` після | `git diff --stat 407595d 69cffac` | 7 файлів, `ComfortPanel.gd` серед них немає | рядки ТЗ чинні |
| мітка `colour_help` | `game/scripts/ui/ComfortPanel.gd:114–116` | `var colour_help := _label(COLOUR_HELP, 24)` · autowrap · `content.add_child` | прибираю |
| константа `COLOUR_HELP` | `ComfortPanel.gd:31` | `"A colour test for comparing two looks. Applies immediately; A is the game as it is."` | прибираю |
| підпис A | `ComfortPanel.gd:30` | `["A — current", "B3 — palette-true light"]` | `A — current` → `A — the game as it is` |
| хто ще читає підпис / підпис-довідку | `grep -rn -E 'A — current\|COLOUR_HELP\|colour_help\|comparing two looks'` (gd/sh/py/tscn/md, без Audit/Fix) | лише `ComfortPanel.gd:30,31,114–116` і `docs/GDD/06-UI-UX.md:129–130` | 06-UI-UX — сторінка T8 (ТЗ крок 5), не чіпаю |
| фікстура підпису | `tools/settings/colour_switch_check.gd:345` | `labels[0].begins_with("A ") and labels[1].begins_with("B3 ")` | посилюю до точних літералів T8 і «одразу за рядком — MASTER» |
| три полотна гарда | `tools/ui/comfort_ui_check.gd:35` | `for dimensions in [Vector2i(1600, 900), Vector2i(1600, 1200), Vector2i(1948, 900)]` | ті самі, що в ТЗ |
| sentinel `comfort-ui` | `tools/gates/playable_check.sh:84`, `:156–159` | `COMFORT_UI PASS \(0 failures; mutation=\)`; негативи `footer`, `focus`, `bounds` без родин | рядки не міняю (лише додаю); родини — окремим рядком `COMFORT_UI_FAMILIES … red=…` |
| префікс асертів негативів | `playable_check.sh:529` | `('comfort-ui-negative-', 'ERROR: COMFORT_UI: ')` | уже є, новий негатив під ним |
| зонд T8 | `sha256sum t8-acc/probe/t8_colour_row_probe.gd` | `ee6f00e3d2d625f2…` — як в аудиті | ганяю для звірки до і після |
| база дерева | `GODOT_BIN=… make check` (`H/make_check_base.log`, з імпортом) | rc 0; GDS `перевірено: 144 · не парсяться: 0 · канарка: FAIL як треба`; `[smoke] ALL OK (165 checks) in 19847 frames` | — |

### Дефект до правки — відтворено

Зонд T8 без змін, headless, `--size=1600x900 --quick` (`H/before/t8probe_1600x900.log`, rc 0) дав ті самі числа, що в
аудиті: `view=[P: (354.0, 107.0), S: (892.0, 619.0)]` (видимо y 107–726), `master_title` y 702, `master_slider` y 751 (до
791), `slider_visible=false title_visible=false`, `block_height=223.0`, `OPEN_WITHOUT_HELP master_slider` y 662 (до 702)
`slider_visible=true title_visible=true`.

Мій зонд `H/probe/t2h_open_probe.gd` (не гейт: відкриває панель справжнім шляхом MainMenu → Enter і друкує, що видно при
відкритті), до правки, `H/before/probe_<W>x<H>.log`, усі rc 0:

| полотно | видимо, y | MASTER заголовок / повзунок, y | запас знизу | фокус | у видимій частині |
|---|---|---|---|---|---|
| 1600×900 | 107–726 | 702–747 / 751–791 | −65 | MasterSlider | ні / ні |
| 1600×1200 | 107–1026 | 702–747 / 751–791 | 235 | MasterSlider | так / так |
| 1948×900 | 107–726 | 702–747 / 751–791 | −65 | MasterSlider | ні / ні |

Два запаси, які я заміряв заздалегідь, бо після правки запас буде лише 24 px (726 − 702):
- **рядок AUTO** під GRAPHICS QUALITY — найдовший можливий текст `Auto: 3D at 100 % of 3840×2160 · MetalFX. Text and
  controls stay sharp.` має 824 px з 884 при шрифті 24, тобто один рядок (`T2HPROBE AUTO_W`). Запасу не з'їдає;
- **рядок статусу при помилці збереження** (`Could not save preferences; …`, шрифт 32) займає 2 рядки, 93 px замість
  45 порожнього (`T2HPROBE OPEN_SAVE_ERROR … view_y=107..678 … status_h=93 status_lines=2`). Видима частина меншає на
  48 px. Це більше за запас 24 px — див. «Що лишилось відкритим».

## Як зроблено

### 1. Гард у `tools/ui/comfort_ui_check.gd` (ТЗ крок 3) — написаний першим, до правки продукту

**Предмет: для всіх полотен `comfort_ui_check` (1600×900, 1600×1200, 1948×900): щойно відкрита панель має фокус на
MASTER, повзунок MASTER і його заголовок повністю лежать у видимій частині скролу, а скрол стоїть на 0 з першим рядком
угорі.**

- У тому самому циклі полотен, де вже є `modal fits canvas`, панель на кожному полотні закривається Escape й
  відкривається Enter на кнопці COMFORT & CONTROLS (справжні події через `viewport.push_input`): скрол скидається лише в
  `show_panel`, тож без повторного відкриття гард міряв би старий скрол.
- Чотири перевірки, кожна в своїй родині: `master_focus` (фокус на MASTER), `master_slider`, `master_title`
  (`scroll.get_global_rect().encloses(…)`, як у ТЗ), `open_top` (скрол 0 і заголовок першого рядка у видимій частині).
  `open_top` — понад ТЗ: це мірило T8 «DISPLAY угорі при скролі 0». Без нього гард пропускав би відкинутий варіант О2
  (прокрутити до MASTER при відкритті).
- **Родини.** Кожен виклик `_check` тепер несе родину. 22 старі перевірки отримали 10 родин: `open`, `fit`, `footer`,
  `font`, `slider`, `restore`, `help`, `close`, `shake`, `pause`. Умови й тексти старих перевірок не змінено. Перед
  підсумковим рядком друкується окремий рядок `COMFORT_UI_FAMILIES failures=N mutation=M red=<родини або none>`. Сам
  підсумковий рядок `COMFORT_UI PASS|FAIL (…)` не змінено, тож старі sentinel у `playable_check.sh` збігаються як були.
  Асерт тепер `COMFORT_UI: [<родина>] <опис>` — префікс `ERROR: COMFORT_UI: ` той самий.
- **Негативи — п'ять форм зламу предмета**, не повтор прикладу:

| `--break=` | форма | як | має почервоніти |
|---|---|---|---|
| `master_label` | вміст над MASTER росте | мітка панелі (`_label`, 24 px) у 2 рядки одразу над рядком MASTER — ТЗ T8 | `master_slider` |
| `master_window` | видима частина меншає знизу | рядок статусу під скролом заввишки 93 px (2 рядки по 32, виміряно на `OPEN_SAVE_ERROR`) | `master_slider` |
| `master_focus` | відкриття падає на інший рядок | на `visibility_changed` фокус відкладено йде на GRAPHICS QUALITY | `master_focus` |
| `master_title` | повзунок видно, заголовок — ні | після відкриття скрол на половину заголовка MASTER нижче | `master_title` |
| `open_scrolled` | скрол не на 0 | після відкриття скрол на половину заголовка DISPLAY | `open_top` |

**Відтворення на старому продукті** (не негативний контроль, лише доказ, що гард бачить дефект): гард на коді `69cffac`,
кейс `comfort-ui` батареї (`H/run_subset.py`, `ONLY='comfort-ui'`, лог `H/repro/comfort-ui.log`) →
`PLAYABLE comfort-ui: FAIL rc=1`, рівно чотири асерти, усі на полотнах заввишки 900:
`[master_slider] 1600x900: … (y 751..791 in 107..726)`, `[master_title] 1600x900: … (y 702..747 in 107..726)`, те саме
для 1948x900; `COMFORT_UI_FAMILIES failures=4 mutation= red=master_slider,master_title`. 1600×1200 зелене. Числа ті самі,
що в T8.

`H/run_subset.py` — копія раннера T2-Ж: виконує heredoc `playable_check.sh` без змін (та сама команда Godot, ізольований
профіль, 180 с, перевірка sentinel і стороннього `ERROR:`) і додає лише відбір кейсів за іменем (`ONLY`).

**Кейси в батареї** (`tools/gates/playable_check.sh`, лише додано): після трьох старих негативів `comfort-ui` — цикл із
п'яти пар `(mutation, family)`, sentinel
`COMFORT_UI_FAMILIES failures=[1-9][0-9]* mutation={mutation} red=[a-z_,]*\b{family}\b[a-z_,]*`, очікуваний rc 1.
Префікс асертів `('comfort-ui-negative-', 'ERROR: COMFORT_UI: ')` уже був у списку, нових рядків там не треба. Старі
рядки батареї не змінено. Кейсів 408 → 413 (розбір `cases` з heredoc).

### 2. Продукт: `game/scripts/ui/ComfortPanel.gd` (ТЗ кроки 1–2)

- Прибрано константу `COLOUR_HELP` і три рядки мітки `colour_help`. Заголовок `COLOURS (TEST)`, пункт
  `B3 — palette-true light`, ключі `a` / `b3`, обробник `item_selected` і місце в `_focus_order` не змінено.
- `COLOUR_LABELS[0]`: `A — current` → `A — the game as it is`.
- Коментар над рядком: чому під ним немає підпису (з посиланням на § 3 T8).

### 3. Фікстура підпису: `tools/settings/colour_switch_check.gd` (ТЗ крок 2)

Стара перевірка `begins_with("A ")` / `begins_with("B3 ")` лишилась як була. Додано дві перевірки в родині `row`:
- пункти дослівно `A — the game as it is` і `B3 — palette-true light`. Літерали взято з приймання T8;
- одразу за рядком іде рядок MASTER, підпису між ними немає.

Перевірка розташування `choice.get_index() == quality.get_index() + 3` (заголовок і підпис якості між ними) не
змінилась і далі зелена: індекси вузлів до рядка ті самі.

### Після правки — що видно при відкритті

Мій зонд, `H/after/probe_<W>x<H>.log`, усі rc 0, `ERROR` 0, `WARNING` 0:

| полотно | видимо, y | MASTER заголовок / повзунок, y | запас | фокус | видно | при помилці збереження |
|---|---|---|---|---|---|---|
| 1600×900 | 107–726 | 613–658 / 662–702 | 24 | MasterSlider | так / так | видимо до 678: повзунок **ні** (−24), заголовок так |
| 1600×1200 | 107–1026 | 613–658 / 662–702 | 324 | MasterSlider | так / так | так (276) |
| 1948×900 | 107–726 | 613–658 / 662–702 | 24 | MasterSlider | так / так | повзунок **ні** (−24) |

`TEXT … items="A — the game as it is | B3 — palette-true light" next=@VBoxContainer@98` — одразу за рядком рядок
MASTER. Числа збігаються з передбаченням T8 (`OPEN_WITHOUT_HELP`: 613 / 662–702).

## Перевірка

### Кейси батареї, що відкривають панель — 57 / 57

Відібрано всі кейси, чий скрипт відкриває `ComfortPanel` або `MainMenu`
(`grep -rl -E '_comfort|ComfortPanel|colour_choice|MainMenu.tscn' tools --include=*.gd` → 12 файлів; два з них —
`display_capture.gd` і `district_ui_capture.gd` — не в батареї). Це `ui`, `district-ui`, `city-controls`, `graphics-ui`,
`display-auto`, `colour-switch`, `comfort-ui`, `blood-content`, `city-onboarding`, `city-haze` з усіма негативами — 57
кейсів, серед них усе з ТЗ крок 4. `H/run_subset.py`, `ONLY='(ui|district-ui|…|city-haze)(-negative-.*)?'`, 3 шарди
паралельно (`H/subset/s0..2.out`, логи `H/subset/s*/`): `PLAYABLE CHECK: 19 scenarios, 0 failures` ×3, rc 0 ×3.

| кейс | рядок результату |
|---|---|
| `comfort-ui` | `COMFORT_UI_FAMILIES failures=0 mutation= red=none` · `COMFORT_UI PASS (0 failures; mutation=)` |
| `…-negative-master_label` | `failures=4 red=master_slider,master_title`: 1600x900 і 1948x900, `y 751..791 in 107..726` |
| `…-negative-master_window` | `failures=2 red=master_slider`: `y 662..702 in 107..678` на двох полотнах заввишки 900 |
| `…-negative-master_focus` | `failures=3 red=master_focus`: `focus GraphicsQuality` на всіх трьох полотнах |
| `…-negative-master_title` | `failures=6 red=master_title,open_top`: заголовок `y 84..129`, скрол 529 |
| `…-negative-open_scrolled` | `failures=3 red=open_top`: скрол 23 на всіх трьох |
| `…-negative-footer` / `focus` / `bounds` | `red=footer` / `red=help` / `red=fit` (по 3) — старі sentinel збіглися |
| `colour-switch` | `checks=146 failures=0 mutation=none red=none` (було 144: +2 нові перевірки підпису) |
| `colour-switch-negative-row` | `checks=146 failures=5 mutation=row red=row,row_save` |

Кожен негатив червоніє у своїй родині. Сусідня родина червоніє лише там, де той самий злам зачіпає і її: у
`master_label` мітка зсуває вниз і заголовок MASTER (`master_title`), у `master_title` скрол ≠ 0 (`open_top`).
Негативи `master_focus` і `open_scrolled` червоніють і на 1600×1200, бо там злам не залежить від висоти полотна.

### Нативний кадр 1280×720 (ТЗ крок 4)

`xvfb-run -a -s '-screen 0 1280x720x24 -nolisten tcp' godot --path game --rendering-method gl_compatibility
--audio-driver Dummy --fixed-fps 60 --script H/probe/t2h_open_probe.gd -- --shot=H/shots/native-open-1280x720.png`, власний
`XDG_DATA_HOME` → rc 0 (`H/after/probe_native_1280x720.log`):
- `display=X11 window=(1280, 720) canvas_scale=(0.8, 0.8) renderer=gl_compatibility`;
- `OPEN … view_y=107..726 master_title_y=613..658 master_slider_y=662..702 margin=24 focus=MasterSlider … slider_in=true
  title_in=true first_in=true` — ті самі логічні числа, що headless;
- `FOCUS master has_focus=true visible_focus=true` (`has_focus(true)` — фокус не прихований);
- `ERROR` 0; `WARNING` 1 — `Could not set V-Sync mode` (llvmpipe, як у T8).

Кадр → `docs/assets/screenshots/2026-10-15-comfort-colours-row.jpg`
(`convert … -strip -quality 92`, 1280×720, **89 073 байти**). На ньому видно DISPLAY угорі, GRAPHICS QUALITY з рядком AUTO,
`COLOURS (TEST)` з пунктом `A — the game as it is`, заголовок `MASTER 80%` і повзунок цілком, BACK унизу.

**Рамка фокуса — уточнення до ТЗ.** У Godot 4.7 у `Slider` немає теми `focus`. Його theme items — `grabber_highlight`
(«the grabber when it's focused») і `grabber_area_highlight` (`doc/classes/Slider.xml` на коміті `5b4e0cb0f`, збережено в
`H/ref/Slider_47.xml`). Тому фокус MASTER на кадрі — це підсвітка повзунка, а не рамка. Для порівняння в тому самому запуску
зроблено другий кадр без прокрутки, з фокусом на рядку COLOURS (`H/shots/native-open-1280x720-unfocused.png`). Пікселі
повзунка (`convert … -format '%[pixel:p{x,y}]'`): заповнена частина (560, 545) — 197 з фокусом проти 116 без нього, бігунок
(845, 545) — 254 проти 195. Порожня доріжка однакова (23). Пара кропів — `H/shots/crop-master-pair.png`. Чи досить такої
підсвітки як видимого фокуса, вирішує T8.

### Зонд T8 на виправленому коді

Зонд T8 без змін (`--size=1600x900 --quick`, `H/after/t8probe_1600x900.log`) проходить `Enter on COMFORT & CONTROLS opens
the panel` і `the panel opens on MASTER`, далі падає:
`SCRIPT ERROR: Trying to assign value of type 'VBoxContainer' to a variable of type 'Label'. at: _run (…t8_colour_row_probe.gd:150)`.
Рядок 150 бере підпис як `get_child(choice.get_index() + 1)`, а тепер там рядок MASTER. Це очікувано: підпису більше
немає. Для свого приймання T8 треба прибрати із зонда рядки, що читають `help`
(`grep -n -w help …/t8_colour_row_probe.gd` → 150, 154, 156, 168–170, 179, 197, 208). Чужий зонд я не правив. Ті самі числа відкриття на виправленому коді дає мій зонд (§ «Після правки»).

### `make check` і `make gates` — фінальний код

- `make check` (`H/make_check_final.log`) → rc 0: GDS `перевірено: 144 · не парсяться: 0 · не виміряно: 0 · канарка: FAIL
  як треба`; `[smoke] ALL OK (165 checks) in 19847 frames`; `SMOKE ЗЕЛЕНИЙ`.
- `make gates` (`H/make_gates_final.log`; повтор після останніх правок журналу — `H/make_gates_final2.log`) → rc 0 обидва рази, `БАТАРЕЯ ЗЕЛЕНА`: wikilinks `сторінок: 549 · … · зламаних: 0`; реєстр
  `на диску: 187 · у реєстрі: 187`; ролі 8 / 0; якорі state ок; R8 48 планів; канарка ЧИС ок; GDS 144 / 0.
- GDS парсить лише `game/**/*.gd`. Змінені фікстури в `tools/` розібрав сам Godot у кейсах батареї: `comfort-ui` і
  `colour-switch` зелені, `SCRIPT ERROR` 0.

### Уся батарея — 413 кейсів

Запущено о 09:13:19 UTC на фінальному коді (після останньої правки — коментар у `colour_switch_check.gd`), `H/run_subset.py`
з `ONLY='.*'`, 3 шарди (`H/full/s0..2.out`, логи `H/full/s*/`), кінець 09:41:15:
`PLAYABLE CHECK: 138 scenarios, 0 failures` · `138 …, 0 failures` · `137 …, 0 failures`, rc 0 ×3 → **413 / 413**
(119 позитивних, 294 негативи; `ls H/full/s*/*.log | wc -l` → 413). У цьому прогоні:
`COMFORT_UI_FAMILIES failures=0 mutation= red=none`, `COLOUR_SWITCH_COMPLETE checks=146 failures=0 mutation=none red=none`.

### Скан логів

`grep -c -E '^\s*(SCRIPT ERROR|ERROR):'`, `grep -c WARNING`, `grep -c -i 'leaked\|orphan'` по кожному логу:
- 10 позитивних кейсів підбірки — `E=0 W=0 leak=0` кожен;
- 47 негативів — жодного `ERROR` поза власним префіксом фікстури, `WARNING` 0, витоків 0;
- зонди до / після headless — 0 / 0 / 0. Нативний — `W=1`, це рядок V-Sync від llvmpipe;
- `H/repro/comfort-ui.log` — `E=4`: це чотири навмисні асерти гарда на старому коді (див. § 1).
- уся батарея, 413 логів: 119 позитивних — `E=0 W=0 leak=0` кожен; 294 негативи — витоків 0, `WARNING` лише в одному:
  `auto-hook-negative-no_recheck` — `Jolt Physics job system exceeded the maximum number of jobs`. Кейс тросу, його код не
  мінявся (`git diff --stat 69cffac -- tools/grapple game/scripts/grapple` → порожньо). Найімовірніше, причина — три шарди
  паралельно на 4 ядрах; окремо не відтворював. Сторонні `ERROR` у негативах раннер і так валить — їх немає.

### `git status --short` (фінал)

```
 M game/scripts/ui/ComfortPanel.gd
 M tools/gates/playable_check.sh
 M tools/settings/colour_switch_check.gd
 M tools/ui/comfort_ui_check.gd
?? docs/Fix/2026-10-15-Comfort-Colour-Row-Fold-Fix.md
?? docs/assets/screenshots/2026-10-15-comfort-colours-row.jpg
```

`git diff --numstat`: `ComfortPanel.gd` 4 / 7, `playable_check.sh` 9 / 0 (лише додано), `colour_switch_check.gd` 6 / 0,
`comfort_ui_check.gd` 67 / 24 (24 видалені рядки — це 22 старі виклики `_check`, тепер із родиною, сигнатура `_check` і
рядок `push_error`; `git diff … | grep '^-[^-]'`).

## Що лишилось відкритим

- **Запас 24 px і рядок помилки збереження (T8 / T1).** Після правки на полотнах заввишки 900 повзунок MASTER закінчується
  на y 702 при видимій частині до 726. Коли запис налаштувань не вдався, під скролом з'являється
  `Could not save preferences; changes apply for this session.` у 2 рядки по 32 px. Видима частина меншає до 678, і
  повзунок знову не видно (`OPEN_SAVE_ERROR … margin=-24 slider_in=false title_in=true` на 1600×900, 1948×900 і нативно
  1280×720). Стан рідкісний: файл профілю не пишеться. Гард у такому стані не ганяю: це не дефект із ТЗ, а той самий клас
  в іншому стані, і як його лагодити — питання до T8 (коротший статус, статус в один рядок, статус поверх BACK тощо).
  Негатив `master_window` імітує саме цю висоту (93 px) і доводить, що гард її помітить, коли стан додадуть у фікстуру.
- **Будь-який наступний рядок над MASTER** (зокрема TEXT SIZE 125–150 % з GAP T8) з'їсть запас 24 px. Тепер це червоне
  `comfort-ui` (`master_slider` / `master_title`), а не тихий дефект.
- **Рамка фокуса на повзунку.** У Godot 4.7 у `Slider` немає теми `focus`, лише підсвітка бігунка й доріжки (197 / 254
  проти 116 / 195). Чи досить цього — T8.
- **[[06-UI-UX]] § COLOURS (TEST)** досі цитує `A — current` і підпис (`06-UI-UX.md:129–130`). Сторінка T8, за ТЗ крок 5
  її оновлює T8 разом із прийманням кадру. Я її не чіпав.
- **Зонд T8** треба звільнити від `help` (§ «Зонд T8 на виправленому коді»).
- **Не перевірено:** телефонний макет (без DISPLAY — фікстура його не відкриває на трьох полотнах), Retina / Forward+ на
  M3, фізичний геймпад. `state.md` не чіпав: статус пише T1 після зведення гілок.

## Related
- [[2026-10-15-T8-Colour-Switch-Row-Acceptance]] · [[2026-10-15-Colour-Switch-Fix]] · [[06-UI-UX]]
- [[2026-10-14-T6-Acceptance-Crane-Albedo-AB]] · [[state]]
