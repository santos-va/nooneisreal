# Перемикач кольорів А / Б3 у налаштуваннях — журнал виконання

**Дата:** 2026-10-15 · **Роль:** T2 Гефест (T2-Е) · **Статус:** зроблено в межах кроку 8; `make check` і `make gates` —
§ «Перевірка»; приймання T8 / T6 (крок 9) і M3 — відкриті.
**План:** [[2026-10-14-T6-Acceptance-Crane-Albedo-AB]], розділ «Рішення Santos про кольори (2026-10-15)» і крок 8, варіант
**В1**. **Еталон Б3:** [[2026-10-15-Albedo-B3-Fix]] (`b1_source()` + `b3_edits()` у `tools/art/albedo_ab_capture.gd`).

Дерево — scratchpad `t2f-tree`, detached `54208e1`. Не комічу, не пушу. Основне дерево не чіпаю. Кредитів не витрачав.
Логи й сирі кадри — scratchpad `colour-switch/` (далі `CS/`). Журнал пишеться по ходу.

## Звірка задачі з реальністю

| що в задачі | команда / місце | вихід | що роблю |
|---|---|---|---|
| голова дерева | `git -C t2f-tree log --oneline -1` | `54208e1 Plan an in-game A/B3 colour switch…` | — |
| `3e215c0` = голова без моїх змін | `git diff --stat 3e215c0 54208e1` | лише план, `+42` рядки; `game/`, `tools/` однакові | еталонні кадри знімаю на `54208e1` без моїх змін (копія `git archive HEAD` → `CS/ref-tree`) |
| глобальних uniform-ів немає | `grep -n shader_globals game/project.godot` | порожньо | додаю секцію `[shader_globals]` |
| «GRAPHICS QUALITY» | `grep -n "GRAPHICS QUALITY" game/scripts/ui/ComfortPanel.gd` | `:87` | рядок кольорів — одразу під блоком якості |
| збереження | `grep -n "func save_settings" game/scripts/core/GraphicsSettings.gd` | `:339`, секція `graphics`, `_save_value()` з охороною `_load_error` | той самий шлях |
| хто малює п'ятьма шейдерами | `grep -rln "city_surface.gdshader\|toon.gdshader\|…" game/scripts game/scenes game/data` | 10 файлів: `Arena.tscn`, `Water.gd`, `GearSurface.gd`, `WaveField.gd`, `HeroGarmentMask.gd`, `Ragdoll.gd`, `RigAnimator.gd`, `SwordPresentation.gd`, `NpcAppearance.gd`, `CityMaterials.gd` | глобальний uniform дістає всіх, зокрема копії камери (`CityCameraProximity.gd:134`, `:217`) |
| інші шейдери з `ALBEDO` у `light()` | скан усіх `game/**/*.gdshader*` (inline `python3`: тіло `light()`, токен `ALBEDO`) | рівно п'ять: `city_surface` 2, `toon` 3, `sword_dissolve` 3, `gear_surface` 3, `hero_garment` 5; решта без `light()` | інших не чіпаю |
| еталон Б3 | `godot --headless --path game --script tools/art/albedo_ab_capture.gd -- --out=CS/dump --dump-shaders` | `edits=[1,1,1]` / `[1,1,1]` / `[1,1,1]` / `[1,1]` / `[1,1,1,1]`; `diff <f>.A.gdshader <f>.B3.gdshader` — рядки нижче | гілка Б3 = цей текст дослівно |
| числа Б3 = таблиця журналу Б3 | `B3` у `albedo_ab_capture.gd:65-70` проти таблиці «Нові числа» [[2026-10-15-Albedo-B3-Fix]] | 0,028 / 1,053 / тінь b 0, m 1 / HG 0,914 / ss 1,000, 0,945, 0,895 / тканина 0,355 — збігаються | — |
| `CityInteriors` / `CityBackdrop` | `grep -rn "painted_fill\|key_gain" game/scripts` (журнал Б3) | `CityInteriors.gd:21-22`, `CityBackdrop.gd:27-28` задають свої числа | множник у шейдері, як в інструменті: ці файли не чіпаю |
| база дерева | `make check` (`CS/logs/make_check_base.log`) | rc 0; GDS `перевірено: 144 · не парсяться: 0`; `[smoke] ALL OK (165 checks) in 19847 frames` | — |
| глобальний uniform у headless | `CS/probe/rs_global_probe.gd`, `godot --headless` | `global_shader_parameter_get_list()` → `[&"probe_b3"]`, але `global_shader_parameter_get()` → `<null>` і до, і після `set(true)` | headless-рушій (dummy) значень не зберігає: значення в `RenderingServer` міряю лише нативно (див. «Фікстура») |
| глобальний uniform у Compatibility | `CS/probe/native_shader_probe.gd`, xvfb, `--rendering-method gl_compatibility` (`CS/logs/native_shader_probe.log`) | п'ять шейдерів із `global uniform bool colour_b3` компілюються без помилок; `global_shader_parameter_get()` і `_get_list()` друкують `ERROR: This function should never be used outside the editor` і дають `<null>` / `[]`; кадр п'яти куль з `set(true)` ≠ кадру з `false`, повтор `false` = першому кадру | **Compatibility підтримує глобальні uniform-и, В1 працює.** Прочитати значення назад рушій дозволяє лише в редакторі — тому ні продукт, ні фікстура getter не викликають; доказ — кадр |

## Як зроблено

**Глобальний uniform.** `game/project.godot`, нова секція `[shader_globals]`: `colour_b3` — `bool`, `false` (А). Назва —
`colour_b3`: значення `true` означає рівно «Б3», інших варіантів немає.

**Гілка в п'яти шейдерах.** У кожному — оголошення `global uniform bool colour_b3;` з коментарем (план, крок 8; числа Б3
— PLACEHOLDER із посиланням на [[2026-10-15-Albedo-B3-Fix]]) і `if (colour_b3) { Б3 } else { А }`:

| шейдер | де гілка | що в Б3 |
|---|---|---|
| `city_surface` | `fragment()`: рядок `EMISSION`; `light()`: два рядки після `lit` | `painted_fill * (0.028 / 0.16)`; тінь `mix(vec3(0.000), shadow_tint.rgb, 1.000)`; `key_gain * (1.053 / 2.20)`; без `ALBEDO` |
| `toon`, `sword_dissolve` | `light()` після `a` | `shadow_strength * (1.000 / 0.45)` / `(0.945 / 0.45)`; кожен рядок `DIFFUSE_LIGHT` × `0.914 / PI`; без `ALBEDO` |
| `hero_garment` | `light()` після `a` | `shadow_strength * (0.895 / 0.45)`; тінь тканини × `0.355`; × `0.914 / PI`; без `ALBEDO` |
| `gear_surface` | `light()` після `lit` | тінь × `0.355`; × `0.914 / PI`; без `ALBEDO` |

Чому гілка цілими блоками, а не множники `1.0` у спільному коді: «вимкнено = кадр піксель у піксель». Гілка А — це
старі рядки дослівно, у тому самому порядку; множення на `1.0` чи `mix` з перемикачем змінили б порядок операцій, і
компілятор шейдера міг би округлити інакше. Гілка Б3 — дослівно текст інструмента (`b1_source()` + `b3_edits()`), щоб
кадр «увімкнено» можна було тримати проти кадру Б3 інструмента.

`CityInteriors` / `CityBackdrop` зберігають відношення до району тим самим множником `(нове / старе)`, що й в
інструменті: `painted_fill` / `key_gain` матеріалу множаться на `0.028 / 0.16` і `1.053 / 2.20` у шейдері.
`CityInteriors.gd` і `CityBackdrop.gd` не змінені.

**Текстова перевірка гілки** (`CS/py/branch_text_check.py`): з кожного шейдера знімаю оголошення і беру тільки гілку
А → файл має дорівнювати `git show 54208e1:game/shaders/<f>`; беру тільки гілку Б3 (без рядків-коментарів) → має
дорівнювати дампу інструмента `CS/dump/shaders/<f>.B3.gdshader`.

```
python3 -I CS/py/branch_text_check.py t2f-tree CS/dump/shaders 54208e1
BRANCH_TEXT city_surface: decl=1 branches=2 A==HEAD:True B3==tool:True
BRANCH_TEXT toon: decl=1 branches=1 A==HEAD:True B3==tool:True
BRANCH_TEXT sword_dissolve: decl=1 branches=1 A==HEAD:True B3==tool:True
BRANCH_TEXT gear_surface: decl=1 branches=1 A==HEAD:True B3==tool:True
BRANCH_TEXT hero_garment: decl=1 branches=1 A==HEAD:True B3==tool:True
BRANCH_TEXT_COMPLETE failures=0
```

**`GraphicsSettings.gd`.** `COLOURS = ["a", "b3"]`, типово `"a"`; ключ `colours` у секції `graphics` поруч із
`profile`. `set_colours()` відкидає все, крім двох рядків, і одразу викликає
`RenderingServer.global_shader_parameter_set(&"colour_b3", value == "b3")`; `save_colours()` пише лише свій ключ через
той самий `_save_value()` (охорона `_load_error`: пошкоджені або невідомі байти не перезаписуються, помилка запису —
у `save_error` для панелі). `load_settings()`: відсутній ключ або файл → А; невідоме значення → А і
`ERR_INVALID_DATA` (як `window_mode`), читабельний профіль діє далі; файл, що не парситься → А. Значення ставиться при
старті (`_ready` → `load_settings`) і при кожній зміні. `colours_applied` — значення, яке востаннє передано в
`RenderingServer`: рушій назад його не віддає, тож headless-фікстура бачить саме це.

**`ComfortPanel.gd`.** Під блоком GRAPHICS QUALITY (після рядка-пояснення якості): заголовок `COLOURS (TEST)`, вибір
`A — current` / `B3 — palette-true light`, пояснення `A colour test for comparing two looks. Applies immediately; A is
the game as it is.` Підпис — мій, остаточний приймає T8. Той самий `_choice()` (48 px, шрифт 32), у кільці фокусу
між GRAPHICS QUALITY і MASTER, `_choices()` (ховає список при закритті, `Esc` не закриває панель поверх відкритого
списку), `_sync_values()`. Вибір застосовується одразу (`set_colours`) і зберігається (`save_colours`), статус панелі
показує невдалий запис. RESTORE SOUND & SHAKE DEFAULTS кольорів не чіпає.

**Змінені наявні фікстури — лише очікуваний порядок фокусу (+1 зупинка).** Нова зупинка між GRAPHICS QUALITY і
MASTER змінює літеральне кільце T8, яке перевіряють три фікстури:
- `tools/ui/graphics_ui_check.gd` — ↑ від MASTER тепер спершу COLOURS (TEST), ще ↑ — GRAPHICS QUALITY;
- `tools/settings/display_auto_check.gd` — DISPLAY тепер ↑↑↑ від MASTER (було ↑↑);
- `tools/fx/blood_content_check.gd` — `_ring()` має `colour_choice` після `quality_choice` (і рядок-коментар кільця).

Інших змін у них немає. Кільце в [[06-UI-UX]] — сторінка T8; її не правлю, T8 приймає рядок (крок 9).

## Фікстура і негативи

`tools/settings/colour_switch_check.gd`, власні файли `user://colour_switch_*_<pid>.cfg`, налаштування гравця не
чіпає. Кожна перевірка має родину; підсумковий рядок називає червоні родини:
`COLOUR_SWITCH_COMPLETE checks=… failures=… mutation=… red=<родини> rs=<…>`.

Предмет: для всіх шляхів, якими задається вибір (API `GraphicsSettings`, `graphics.cfg`, рядок COLOURS (TEST) з
клавіатури й геймпада), грає і зберігається рівно обране значення, це саме значення передано в `RenderingServer` як
`colour_b3`, на яке розгалужуються п'ять шейдерів; свіжий профіль — А; невідомий або пошкоджений файл — А, і його байти
не перезаписуються.

| родина | що перевіряє |
|---|---|
| `global` | `[shader_globals] colour_b3` — `bool`, `false`; `GraphicsSettings` ставить ту саму назву |
| `shader` | кожен із п'яти шейдерів оголошує `global uniform bool colour_b3;` один раз; `light()` розгалужується на нього; у частині Б3 немає `ALBEDO`, у частині А він є |
| `default` | старт гри — А; свіжий профіль (файлу немає) — А, навіть якщо сесія була на Б3; читання файл не створює |
| `persist` | Б3 зберігається і читається назад; поруч із `profile`; чужі ключі й секції лишаються; збереження профілю не стирає `colours` |
| `unknown` | 11 недопустимих значень у `set_colours` відкинуто, сесія не змінилась; 7 невідомих значень у файлі (`"b1"`, `"B3"`, `""`, `1`, `true`, `["b3"]`, словник) → А, `ERR_INVALID_DATA`, читабельний `profile="low"` діє |
| `cfg` | після невідомого значення й після файлу, що не парситься, зміна кольорів і профілю не змінює байтів; невдалий запис видно в `save_error` |
| `row` | рядок одразу під GRAPHICS QUALITY і його поясненням, заголовок COLOURS (TEST), 2 пункти; кільце GRAPHICS QUALITY ↕ COLOURS (TEST) ↕ MASTER (і на телефоні); висота й фокус як у якості; ↑ з MASTER; Enter ↓ Enter — Б3 одразу; геймпад A, D-pad ↑, A — А одразу; B закриває лише список; RESTORE не чіпає; повторне відкриття показує значення |
| `row_save` | вибір рядка з клавіатури й геймпада записано в `graphics.cfg` і читається назад |
| `apply` | після кожної зміни `colours_applied` (передане в `RenderingServer`) = вибраному |
| `rs` | **лише нативно:** п'ять куль із п'ятьма шейдерами; у смузі кожної кулі кадр Б3 ≠ кадру А, а повернення на А дає кадр А байт у байт. У headless рушій нічого не малює — рядок каже `rs=not-measured-headless`, і батарея вимагає саме цього |

Негативи (`--break=<m>`), кожен ламає одну річ у пам'яті:

| форма | що ламає |
|---|---|
| `default` | читання свіжого профілю стартує на Б3 |
| `persist` | читання забуває збережений ключ (грає А поверх збереженого Б3) |
| `unknown` | читач грає Б3 на будь-яке значення, крім `"a"` |
| `cfg` | шлях запису без охорони `_load_error` |
| `row` | рядок, що ніколи не викликає `set_colours` |
| `row_save` | рядок застосовує, але не зберігає |
| `global` | `project.godot` з `colour_b3 = true` |
| `shader` | `hero_garment` без гілки (`if (false)`); нативно його куля малюється цим кодом |
| `apply` | рядок міняє значення, не передаючи його в `RenderingServer`; нативно ще й uniform повернуто на А одразу після перемикання |

`tools/gates/playable_check.sh` — лише додані рядки (`git diff tools/gates/playable_check.sh | grep -c "^-[^-]"` → 0,
`git diff --numstat` → `13 0`): кейс `colour-switch` (sentinel вимагає `failures=0 … red=none rs=not-measured-headless`),
9 кейсів `colour-switch-negative-<m>` (rc 1, sentinel вимагає `<m>` серед червоних родин) і префікс
`ERROR: COLOUR_SWITCH: ` для дозволених рядків помилок негативів.

Прогін — тим самим Python, командним рядком, sentinel-ом і правилом помилок, що в `playable_check.sh` (`CS/run_cases.sh`
бере його Python дослівно й фільтрує кейси за `PLAYABLE_ONLY`; лог `CS/logs/cases1.log`):

```
PLAYABLE colour-switch: PASS rc=0
PLAYABLE colour-switch-negative-default: PASS rc=1     red=default
PLAYABLE colour-switch-negative-persist: PASS rc=1     red=persist
PLAYABLE colour-switch-negative-unknown: PASS rc=1     red=unknown
PLAYABLE colour-switch-negative-cfg: PASS rc=1         red=cfg
PLAYABLE colour-switch-negative-row: PASS rc=1         red=row,row_save
PLAYABLE colour-switch-negative-row_save: PASS rc=1    red=row_save
PLAYABLE colour-switch-negative-global: PASS rc=1      red=global
PLAYABLE colour-switch-negative-shader: PASS rc=1      red=shader
PLAYABLE colour-switch-negative-apply: PASS rc=1       red=apply
PLAYABLE CHECK: 10 scenarios, 0 failures
```

(`red=` — з рядка `COLOUR_SWITCH_COMPLETE` кожного логу `CS/cases1/*.log`; позитив: `checks=144 failures=0`.)
Перша причина кожного негативу, дослівно з логу: `default` — `a fresh profile plays A (want a, got b3)`; `persist` —
`a saved B3 reads back and plays at load (want b3, got a)`; `unknown` — `unknown colours "b1" play A (want a, got b3)`;
`cfg` — `the refused write is reported to the panel (colours="b1")`, `unknown colours bytes preserved after a colour
change`; `row` — `the keyboard pick plays at once (want b3, got a)`; `row_save` — `the keyboard pick is saved to
graphics.cfg`; `global` — `… colour_b3 is a bool that defaults to false / A (got { "type": "bool", "value": true })`;
`shader` — `hero_garment: light() branches on colour_b3`; `apply` — `the keyboard pick plays at once: RenderingServer
was handed a, the setting is b3`.

**Нативно** (`CS/run_native_fixture.sh`: xvfb, `--rendering-method gl_compatibility`, 1280×720, ізольований профіль):

| запуск | підсумок |
|---|---|
| позитив (`CS/logs/native_fixture_none.log`) | rc 0, `checks=150 failures=0 mutation=none red=none rs=measured-pixels-gl_compatibility`; змінених вибраних пікселів у смузі: `city_surface` 3019, `toon` 2697, `sword_dissolve` 2646, `gear_surface` 2865, `hero_garment` 3015 |
| `--break=apply` (`…_apply.log`) | rc 1, `red=apply,rs`: у смузі кожного з п'яти шейдерів 0 змінених пікселів |
| `--break=shader` (`…_shader.log`) | rc 1, `red=rs,shader`: смуга `hero_garment` — 0, решта чотири — ті самі числа, що в позитиві (смуги не перетинаються) |

Наявні кейси, яких торкається зміна (панель, налаштування, кільце): `CS/logs/cases2.log` → `PLAYABLE CHECK: 29 scenarios,
0 failures` — `ui`, `district-ui`, `city-controls`, `comfort-settings`, `graphics-settings`, `graphics-ui`,
`graphics-independent`, `display-auto`, `comfort-ui`, `blood-content` і їхні негативи (`ui-negative-*` 3,
`comfort-ui-negative-*` 3, `graphics-independent-negative-apply`, `blood-content-negative-cfg|flash|drugs_row`,
`display-auto-negative-*` 5, `city-controls-negative-*` 4).

## Кадри: вимкнено / увімкнено

**Інструмент.** `tools/art/albedo_ab_capture.gd --switch`: справжня гра, шейдери продукту, перемикання через
`GraphicsSettings.set_colours()`; жодної текстової підміни в кадрах OFF / ON / OFF2. На станції, у паузі: OFF (А) → ON (Б3)
→ OFF2 (А); rc 1, якщо ON = OFF, OFF2 ≠ OFF, `colours_applied` ≠ поставленому або перепис знайде шейдер з `ALBEDO` у
`light()` без гілки `colour_b3`. Старий режим (А / Б1 / Б3) на нових шейдерах працює як був:
`--dump-shaders` → `albedo_tokens_in_light` 2/3/3/3/5, `edits` усі `1` (`CS/logs/dump_new.log`).

**Чому два еталони.** Перший прогін (`CS/sw/`, без `--ref-shaders`) дав на станції `pump` OFF ≠ A у 18 825 px, хоча
`market` і `plaster` — 0. Різні пікселі (`CS/diff/pump_offA.png`) — це мешканці та їхні тіні. Контроль — той самий
незмінений інструмент на тій самій незміненій голові двічі (`CS/ref/choko_b` проти `CS/ref/choko_b_repeat`,
`CS/py/ref_repeat.py`, `CS/logs/ref_repeat.log`):

| станція | різних px, A | з них поза мешканцями обох прогонів |
|---|---|---|
| `truck` | 12 721 | 2 533 |
| `car` | 30 917 | 0 |
| `hero` | 22 372 | 389 |

Отже між двома процесами мешканці стоять інакше навіть для однакового коду. Залишок поза маскою мешканців — це їхні
тіні на бруківці: маска покриває лише самі тіла. Тому до еталона з іншого процесу додано **еталон у тому самому
процесі**: `--ref-shaders=CS/dump/shaders` — тексти п'яти шейдерів голови `54208e1` без моїх змін (дамп
незміненого інструмента; `cmp` з `git show 54208e1:game/shaders/<f>` → однакові всі п'ять). Після ON той самий
кадр у паузі малюється з кодом А цієї голови (refA) і з кодом Б3 інструмента (refB3). Потім код продукту
повертається, і OFF2 мусить дорівнювати OFF. Інструмент дає rc 1, якщо OFF ≠ refA.

**Прогони.** Еталон — `CS/run_ref.sh` у `CS/ref-tree` (`git archive 54208e1`, незмінений інструмент), логи
`CS/logs/ref_series.log`, rc 0, `errors=0` ×4. Перемикач — `CS/run_switch.sh` у `t2f-tree`, лог
`CS/logs/switch_series2.log`, rc 0, `errors=0` ×3, `ALBEDO_AB_COMPLETE mode=switch … failures=0`. Порівняння:

```
python3 -I tools/art/colour_switch_compare.py --ref CS/ref/choko_a CS/ref/choko_b CS/ref/skea \
  --switch CS/sw2/choko_a CS/sw2/choko_b CS/sw2/skea --out CS/compare.tsv \
  --sheets docs/assets/screenshots --prefix 2026-10-15-colour-switch --max-kb 292
→ rc 0, COLOUR_SWITCH_COMPARE_COMPLETE stations=8 failures=0   (CS/logs/compare.log)
```

Кадр 1920 × 1080 = 2 073 600 px; Compatibility / llvmpipe.

| станція · герой | OFF ≠ refA | ON ≠ refB3 | OFF ≠ A (інший процес) | ON ≠ B3 (інший процес) | з них на самому герої | ON ≠ OFF | OFF2 = OFF |
|---|---|---|---|---|---|---|---|
| `pump` · Choko | **0** | **0** | 21 628 | 21 717 | 0 / 0 | 1 902 512 | так |
| `benches` · Choko | **0** | **0** | 7 006 | 7 024 | 0 / 0 | 1 917 805 | так |
| `market` · Choko (героя в кадрі немає) | **0** | **0** | **0** | **0** | — | 2 073 600 | так |
| `plaster` · Choko (героя в кадрі немає) | **0** | **0** | **0** | **0** | — | 1 825 198 | так |
| `truck` · Choko | **0** | **0** | 10 010 | 10 038 | 0 / 0 | 1 815 588 | так |
| `car` · Choko | **0** | **0** | 30 249 | 30 311 | 0 / 0 | 1 856 888 | так |
| `hero` · Choko | **0** | **0** | 22 881 | 23 016 | 0 / 0 | 1 891 251 | так |
| `hero` · Skea | **0** | **0** | 22 392 | 22 451 | 0 / 0 | 1 900 533 | так |

«З них на самому герої» — `CS/py/cross_run_where.py` (`CS/logs/cross_run_where.log`): маска героя з ID-проходу
еталонного прогону (мітки `hero:*`, звужена на 2 px; на станції `hero` у Choko 158 696 px, у Skea 198 124 px). Різних
пікселів на герої між процесами 0 і для OFF / A, і для ON / B3 на всіх шести станціях з героєм.

Висновок:
- **вимкнено = сьогоднішній код за результатом:** OFF = refA піксель у піксель на 8 кадрах із 8, з героєм на шести;
  між процесами — 0 на `market` і `plaster`, а на станціях з героєм різняться лише мешканці та їхні тіні (контроль вище);
- **увімкнено = Б3 інструмента:** ON = refB3 піксель у піксель на 8 із 8. Між процесами різниця ON / B3 така сама, як
  OFF / A (мешканці), на самому герої — 0. Гілка Б3 — дослівно текст інструмента (`branch_text_check.py`), тож інших
  джерел різниці немає.

**Аркуші для T6** «вимкнено | увімкнено», підписані (`stat -c "%s %n" docs/assets/screenshots/2026-10-15-colour-switch-*`):

| файл | станції | байт |
|---|---|---|
| `docs/assets/screenshots/2026-10-15-colour-switch-street.jpg` | колонка, лавки | 286 321 |
| `docs/assets/screenshots/2026-10-15-colour-switch-market.jpg` | ринок | 169 337 |
| `docs/assets/screenshots/2026-10-15-colour-switch-plaster.jpg` | фасад, штукатурка | 153 179 |
| `docs/assets/screenshots/2026-10-15-colour-switch-vehicles.jpg` | паровантажівка, паролегковик | 286 538 |
| `docs/assets/screenshots/2026-10-15-colour-switch-hero.jpg` | крупний план Choko і Skea | 296 586 |

Сирі PNG (`*_off`, `*_on`, `*_off2`, `*_refA`, `*_refB3`) — `CS/sw2/`; еталон — `CS/ref/`. Версії (`sha256sum`):
еталонний інструмент `3dcf3771…` (той самий, що в серії Б3), інструмент перемикача `24986791…`, `city_surface.gdshader`
`f32490ad…` — однакові в серії й негативах (`CS/logs/switch_tool_sha.txt`, `CS/logs/ref_tool_sha.txt`).

### Негативи інструмента і порівняння

Предмет: для всіх станцій і обох героїв кадр OFF — це код А, кадр ON — код Б3, перемикач справді доходить до рушія
і повертається без сліду, і жоден матеріал світу не малює шейдером без гілки.

`CS/run_switch_neg.sh`, станція `hero`, `--ref-shaders` (лог `CS/logs/switch_neg.log`); те саме — порівняльний скрипт
на цих кадрах (`CS/logs/compare_neg_<m>.log`):

| форма | що ламає | інструмент | `colour_switch_compare.py` |
|---|---|---|---|
| `switch_stuck` | uniform повернуто на А одразу після перемикання | rc 1: `frame ON is byte-identical to OFF` | rc 1: `ON equals OFF` |
| `switch_leak` | Б3 лишається на останньому проході | rc 1: `frame OFF2 differs from OFF` | rc 1: `OFF2 differs from OFF` |
| `switch_foreign` | одна міська поверхня на `Shader.duplicate()` без гілки | rc 1: перепис `start: 1 slots …` і те саме на станції | — (кадри не судить) |
| `switch_drift` | у гілці А `city_surface` `key_gain × 1.01` | rc 1: `frame OFF differs from refA` | rc 1: `OFF differs from refA in 1347532 px` |

## Перевірка

У `t2f-tree`, `GODOT_BIN=scratchpad/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64` (`4.7.stable.official.5b4e0cb0f`),
логи `CS/logs/`, після останньої правки коду:
- `make check` (`make_check_final.log`) → rc 0: GDS `перевірено: 144 · не парсяться: 0 · не виміряно: 0 · канарка: FAIL
  як треба`; `[smoke] ALL OK (165 checks) in 19847 frames`, `SMOKE ЗЕЛЕНИЙ` — ті самі числа, що на базі;
- `make gates` (`make_gates_final.log`) → rc 0, `БАТАРЕЯ ЗЕЛЕНА`: ВІК `сторінок: 539 · … · зламаних: 0`; РЕЄ `на диску:
  187 · у реєстрі: 187 · незареєстрованих: 0`; ПАР `проблем: 0`; GDS `перевірено: 144 · не парсяться: 0`. Після
  дописаних розділів цієї сторінки — повтор (`make_gates_final2.log`): rc 0, `БАТАРЕЯ ЗЕЛЕНА`, ВІК `лінків: 8943 ·
  зламаних: 0`, решта чисел ті самі;
- інструменти поза GDS-гейтом: `godot --headless --path game --check-only --script <f>` → rc 0, рядків помилок 0 для
  `tools/art/albedo_ab_capture.gd`, `tools/settings/colour_switch_check.gd`, `tools/ui/graphics_ui_check.gd`,
  `tools/settings/display_auto_check.gd`, `tools/fx/blood_content_check.gd` (`checkonly_final_*.log`);
  `python3 -m py_compile tools/art/colour_switch_compare.py` і `bash -n tools/gates/playable_check.sh` — без помилок;
- кейси за правилами `playable_check.sh` (`cases3.log`, остаточні версії): `PLAYABLE CHECK: 18 scenarios, 0 failures` —
  `colour-switch` і 9 негативів, `graphics-settings`, `graphics-ui`, `graphics-independent`, `display-auto`, `comfort-ui`,
  `city-controls`, `blood-content`, `blood-content-negative-drugs_row`; ширший набір до того — `cases2.log`, 29 / 0;
- нативно: `native_fixture_final.log` → rc 0, `checks=150 failures=0 … rs=measured-pixels-gl_compatibility`;
- скан логів: у позитивних кейсах `cases3` (8), нативній фікстурі, семи прогонах інструмента (`CS/sw2/*`, `CS/ref/*`) і
  `make_check_final.log` — 0 рядків `ERROR`, 0 `leaked / still in use at exit`, 0 `WARNING`, крім одного рядка
  драйвера в кожному нативному прогоні: `WARNING: Could not set V-Sync mode … not supported by the graphics driver`
  (llvmpipe під xvfb). У 9 негативах — 0 рядків `ERROR`, крім навмисних `ERROR: COLOUR_SWITCH: …`;
- `git -C t2f-tree status --short` (`git_status_final.txt`):

```
 M game/project.godot
 M game/scripts/core/GraphicsSettings.gd
 M game/scripts/ui/ComfortPanel.gd
 M game/shaders/city_surface.gdshader
 M game/shaders/gear_surface.gdshader
 M game/shaders/hero_garment.gdshader
 M game/shaders/sword_dissolve.gdshader
 M game/shaders/toon.gdshader
 M tools/art/albedo_ab_capture.gd
 M tools/fx/blood_content_check.gd
 M tools/gates/playable_check.sh
 M tools/settings/display_auto_check.gd
 M tools/ui/graphics_ui_check.gd
?? docs/Fix/2026-10-15-Colour-Switch-Fix.md
?? docs/assets/screenshots/2026-10-15-colour-switch-hero.jpg
?? docs/assets/screenshots/2026-10-15-colour-switch-market.jpg
?? docs/assets/screenshots/2026-10-15-colour-switch-plaster.jpg
?? docs/assets/screenshots/2026-10-15-colour-switch-street.jpg
?? docs/assets/screenshots/2026-10-15-colour-switch-vehicles.jpg
?? tools/art/colour_switch_compare.py
?? tools/settings/colour_switch_check.gd
```

`CityInteriors.gd`, `CityBackdrop.gd`, `CityProps` / `CityMarket`, межові колайдери й `city_tidy_check.gd` (зона T2-Д) не
змінені. Палітра, стайл-гайд, рух і бій не змінені. Повну батарею `make check-playable` не запускав — її запускає T1.

## Що лишилось відкритим

1. **M3 не бачено.** Усі кадри — Compatibility / llvmpipe. Глобальні uniform-и в Forward+ (Metal на M3) тут не
   запускались: «не перевірено». Кадри Б3 на M3 будуть темніші й насиченіші в тіні, ніж на аркушах
   ([[2026-10-15-Albedo-B3-Fix]], п. 5 «Для Santos»).
2. **Ціна гілки на M3 не виміряна.** Гілка рівномірна (одне значення на кадр, без нових варіантів шейдера), але FPS
   на M3 ніхто не міряв.
3. **Батарея headless не бачить значення в `RenderingServer`.** Рушій віддає глобальні uniform-и назад лише в
   редакторі, а headless їх не зберігає. У батареї — `colours_applied` і рядок `rs=not-measured-headless`; кадр п'яти
   шейдерів міряє лише нативний запуск фікстури (`CS/run_native_fixture.sh`). У CI його немає: чи додавати — рішення T1.
4. **Підписи й кільце — T8** (крок 9): `COLOURS (TEST)`, `A — current`, `B3 — palette-true light`, пояснення; нова
   зупинка в кільці фокусу; літерал кільця в [[06-UI-UX]] — правка T8. Тач окремо не перевіряв (той самий
   `OptionButton`, що в сусідніх рядках).
5. **Кадри «увімкнено» приймає T6** (крок 9) — аркуші вище.
6. **Мешканці між процесами не однакові** навіть для того самого коду (контроль: 12 721 / 30 917 / 22 372 px). Для
   перемикача це обійдено еталоном у тому самому процесі; для майбутніх порівнянь кадрів між запусками це варто знати.
   Причину не шукав.
7. У режимі `--switch` повідомлення перепису каже «not one of the swapped five» — формулювання старого режиму; суть та
   сама (шейдер з `ALBEDO` у `light()` без гілки).
8. Якщо Santos обере Б3: числа з [[2026-10-15-Albedo-B3-Fix]] ідуть у шейдери, `CityInteriors.gd`, `CityBackdrop.gd`
   як звичайні значення, гілка й перемикач прибираються — окремий крок (Yellow, з ADR). Якщо А — прибираються гілка,
   uniform і рядок.
9. `state.md` і журнал зустрічі не правлю: рядок стану після зведення — T1. Не комічу, не пушу.

## Related
- [[2026-10-14-T6-Acceptance-Crane-Albedo-AB]] · [[2026-10-15-Albedo-B3-Fix]] · [[2026-10-14-Albedo-AB-Fix]] · [[2026-10-14-Godot-Diffuse-Albedo]]
- [[06-UI-UX]] · [[Style-Guide]] · [[Cel-Shading]] · [[state]]
