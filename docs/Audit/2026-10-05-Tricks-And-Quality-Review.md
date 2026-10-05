# Аудит нових трюків і якості кварталу

**Дата:** 2026-10-05 · **Роль:** T4 Феміда · **Вердикт: YELLOW через відкритий тісний camera corner.** Особисті check/gates, focused probes та незалежний огляд фінальної батареї **93/0 — GREEN**. Обмежений пакет можна передати draft PR, але не називати повністю художньо готовим. FPS цей аудит не заявляє.

## База, перевірена в цій сесії

Початкова чиста база була `6c083286d600aa3de834411d2c55773c77fe2543`, гілка `work`, без локального `origin/main`. Після fetch/fast-forward координатора особистий `git rev-parse HEAD origin/main` дав однакові **`abce638b44ad68b50ef10b9d9eb2f7fc6b257b1b`**; compact state повторно прочитаний. Нові Lower Mark fixtures з цієї бази збережені в runner: вихідна батарея має 85 сценаріїв.

Прочитані `CityParkourMotor.gd`, `CityParkourProfile.gd`, `CityFighter.gd`, `ParkourMotion.gd`, `tools/parkour/city_parkour_check.gd`, `CityWorld.gd`, `city_surface.gdshader`, `project.godot` і попередній незалежний аудит [[2026-10-05-Responsive-Parkour-Review]]. Чинний motor має hang/mantle/wall_run, Skea-only wall steps, скінченні grip/wall бюджети, sweep та повторну перевірку реальної опори. Чинний fixture містить late ceiling, thin/narrow support, moved/disabled collider й actual-input маршрут. Нові wall kick і landing roll цим старим fixture не доведені.

`python3 tools/gates/texture_registry_check.py` завершився rc0: **175 файлів / 175 рядків, незареєстрованих 0, неіснуючих 0**. Це перевірка реєстру, не повторне встановлення походження кожного ассета.

Початковий `/usr/local/bin/godot` був symlink на `/opt/godot/4.6.3/Godot_v4.6.3-stable_linux.x86_64`, без project class cache. Координатор підготував окремий official 4.7 та імпорт. Особисто прочитані raw `/workspace/nooneisreal-evidence/tricks-quality/validation/city-tricks-second.log/.rc` і `city-parkour-current.log/.rc` мають **Godot 4.7.stable.official.5b4e0cb0f**, відповідно **50/0** та **73/0**, обидва rc0, без runtime errors. Це проміжні виконання T2, не особистий запуск T4 або фінальний source proof.

## Обсяг і незалежність

**GREEN — план і поділ відповідальності.** Особисто прочитаний [[2026-10-05-Parkour-Tricks-And-Quality]] має три альтернативи, сім поглядів і межу двох city-only трюків. T4 не редагує gameplay/state: його зміни — цей аудит, два окремі fixtures та реєстрація cases у runner за handoff T1. `git diff --stat origin/main -- game/assets docs/Art/Textures-Registry.md` порожній; нових paid/generated assets немає у дельті.

**GREEN — focused gameplay й settings.** Справжній InputRouter та CityFighter проходять позитивні сценарії й ворожі ситуації нижче. Freeze зберігає поточний малюнок і рух до розмороження; control/UI/revision скасовують стару презентацію. Це не нова глобальна політика всіх натискань під freeze. Quality змінює root viewport, тому обраний profile свідомо лишається між сценами.

**GREEN — інтеграція; YELLOW — camera corner.** Фінальні playable та broad gear/whole-body regression завершені нижче. Collision wall/ceiling/edge і geometry prerequisites перевіряють звичайні safeguards у fixtures. Окремі sweep-bypass та static-clip мутації цього заходу не виконувалися й не заявляються як доказ.

## Виконані негативні контроли

1. `tools/parkour/tricks_independent_check.gd --break=budget`: між двома справжніми стінами, без touchdown, очищається лише spent-прапорець. Той самий oracle відхилив повторний kick та upward impulse обох героїв.
2. `tools/settings/graphics_independent_check.gd --break=apply`: вибраний profile лишається Low/Medium, але viewport повертається до High. Незалежна зафіксована таблиця очікувань відхилила обидві фальшиві live-зміни.

Controls та позитивні cases зареєстровані в `tools/gates/playable_check.sh`. Особисті `bash -n`, `ast.parse` й розбір списку дали **93 сценарії / 93 унікальні назви / 0 відсутніх fixtures**. ERROR допускається лише з точними prefixes двох named negative controls; SCRIPT ERROR та сторонні engine errors не дозволені. Позитивний запуск кожного того самого oracle є обов’язковим сусіднім case.

## Особистий focused запуск T4

**GREEN — незалежні перевірки у своєму обсязі.** Виконано послідовно через `/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 --headless --audio-driver Dummy --path game --fixed-fps 60 --quit-after 12000 --script <fixture>`. Кожен case отримав окремий XDG_DATA_HOME; raw banner підтвердив official **4.7.stable.5b4e0cb0f**.

| Fixture | Вихід | Що доведено |
|---|---|---|
| `tricks_independent_check.gd` | **54 checks / 0 failures, rc0** | Обидва герої проходять коридор до протилежної стіни без підлоги; held initial jump не запускає kick, fresh input запускає, другого upward impulse немає. Freeze тримає position/velocity/progress; actual touchdown запускає пасивний roll, швидкість не зростає, невразливості немає; modal cancel не оживає після закриття. |
| Той самий fixture `--break=budget` | **54 / 4, rc1 — очікувано** | Скинутий лише spent-прапорець; червоні рівно second kick/upward impulse для Choko та Skea. |
| `graphics_independent_check.gd` | **62 / 0, rc0** | Live root viewport відповідає незалежній таблиці Low/Medium/High. Wrong runtime/disk types атомарно відкидаються, пошкоджені schema bytes не перезаписуються; правильний файл знову дозволяє save, невідомі секції лишаються, pause й simulation clock збережені. |
| Той самий fixture `--break=apply` | **62 / 2, rc1 — очікувано** | Вибір рядка без застосування до viewport відхиляється рівно для Low/Medium. |
| Актуальний власницький `city_tricks_check.gd` | **84 / 0, rc0** | T4 особисто повторив розширені cases wall/hang/Skea run kick, clearance, roll wall/edge/timeout/revision/UI/rope/action interruption. |

Raw та rc: `/workspace/nooneisreal-evidence/tricks-quality/validation/t4-{tricks,tricks-negative,graphics,graphics-negative,city-tricks}.log/.rc`. Особистий regex scan збережений у `t4-focused-scan.json`: **0 unexpected errors/warnings/leaks**, допускаються лише названі deliberate assertions controls. Teardown звичайний queue_free із 250 мс wall-clock drain, без загального приглушення помилок.

Вихідні motion floor checks окремо виявили **74 failures**, зокрема Skea min−0,234437 м, у `parkour-tricks/validation/motion/first.log` (особисто прочитано, rc1). Це відхилений candidate. Фінальний прочитаний `compact-head.log` дав **3 265 277 / 0**. Консервативні межі `RollGroundSupport` відсікають лише групи, які не можуть змінити minimum; решта зберігає всі weighted influences. Підготовка — під час завантаження міського актора, повторний callback повторно solve не виконує. Це джерельний незалежний огляд алгоритму й прочитаний owner test, не власний T4 performance benchmark. Зміна facet sign у `HeroGearPresentation` зберігає чинні pin-допуски й потребує старих gear/city-hook cases у повній батареї.

## Особисті фінальні check/gates та source freeze

**GREEN.** T4 виконав `GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 make check`, потім `make gates`. Raw `/workspace/nooneisreal-evidence/tricks-quality/final/review-check.log/.rc`: **rc0, smoke164 checks / 19847 frames, SMOKE ЗЕЛЕНИЙ**. `review-gates.log/.rc`: **rc0, 119 GDS / 0 parse failures, 175/175 assets, 0 broken wikilinks, БАТАРЕЯ ЗЕЛЕНА**. Дев’ять неоднозначних wiki basename лишаються явними notices; це не нуль notices.

`review-source-before.json` та `review-source-after.json` побайтово однакові: **808 game/tools source files**, SHA256 aggregate **`c5b5d42190c355cb4b416914bed8f5941d1b57a9a7def29e8311734865b7f024`**. Manifest включає assets/import/UID і виключає лише `.godot`, `__pycache__`, `.pyc`; docs можуть дописуватися. Новий `RollGroundSupport.gd.uid` (`uid://v7wpsgctopcx`) включений.

Межа Makefile: import/smoke спочатку тримають повний вивід у shell variables і друкують фільтрований результат. Особистий make check підтвердив sentinel, rc, runtime-error та Jolt guards. Повний raw warning/leak proof забезпечив наступний required `make check-playable` координатора через evidence-only recorder; T4 незалежно перевірив його нижче.

## Фінальна інтеграція: незалежне читання T4

**GREEN.** Особисто прочитані `final/check-playable.log/.rc`, усі **93** case logs та **95** повних engine raw: import, smoke, 93 scenarios. Aggregate: **93 scenarios / 0 failures, rc0**. Власний скан `t4-final-cases-scan.json` і `t4-engine-raw-scan.json` дав **0 unexpected errors/warnings/leaks**. Deliberate controls мають свої exact assertion prefixes та очікуваний rc1; кожен решта engine run — rc0. Повний import — `engine-raw/run-xLSXxZ.log`, повний smoke — `run-avczFK.log`, поруч їх `.args/.rc`; smoke знову **164/19847**.

| Фінальні raw cases | Результат |
|---|---|
| hero-gear / city-hook-gear | **7946/0 · 2978/0**, другий на 276 poses |
| parkour-motion / ground-contact | **15466/0 · 5407/0** |
| trick-motion / city-tricks | **3265277/0 · 84/0** |
| independent tricks / graphics | **54/0 · 62/0**, deliberate controls окремо прийняті як expected-fail |
| graphics-settings / graphics-ui | **63/0 · 15/0**, UI перевіряє реальні keyboard/gamepad events |
| Lower Mark story / gallery | **86/0 · 78/0**, нові fixtures з підтягнутої бази збережені |

Чотири manifests — review before/after та playable before/after — повністю однакові для всіх **808 sources** із digest вище. Фінальна батарея перевірила саме source із власного T4 check/gates. Після такого proof документи дописуються окремо; engine rerun без зміни game/tools не потрібний.

## Native приймання й відкрита межа

Прочитано остаточний [[2026-10-05-Traversal-And-Surface-Review]]. T6 прийняв обмежені матеріальні A/B, roll side/3⁄4, видимий протилежний wall-kick ракурс та production відкриту опору. Прихований стіною первісний quarter-view залишився відхиленим; alternate capture його не перетворює на доказ.

**YELLOW — камера біля тісної навчальної опори `[4,0,31.4]`.** T4 особисто відкрив `parkour-tricks/native-production/choko_wall_kick/0036.png`: герой майже розчиняється в proximity dither, уступ перекриває низ кадру. У `native-production-open-choko/choko_wall_kick/0029.png` герой та опора читаються. Відкрита станція не виправляє тісну. Camera/proximity source не змінювався, але baseline такого самого старого backward drop не знято, тож ані нову регресію, ані доведене старе походження не стверджуємо. За рішенням T1 це явна окрема межа draft delivery, не прихований GREEN.

Roll є стилізованим: у середній фазі Choko опора спорядження може підняти body skin приблизно на 0,29 м; combined geometry clearance не означає безперервний анатомічний shoulder contact. Native використовує Godot 4.7 Compatibility/llvmpipe та задані початкові станції. Forward+, M3 FPS/frame-time, фізичний контролер і встановлений macOS застосунок цими перевірками не підтверджені.

## Related

- [[constitution]] · [[recurring_class_register]] · [[2026-10-05-Parkour-Tricks-And-Quality]] · [[2026-10-05-Parkour-Tricks-Session]] · [[2026-10-05-Responsive-Parkour-Review]] · [[2026-10-05-Whole-Body-Anatomy-Review]]
