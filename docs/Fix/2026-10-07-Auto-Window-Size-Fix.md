# Вікно гри розгортається автоматично: виконання кроків 1–2

**Дата:** 2026-10-07 · **Роль:** T2 Гефест · **Статус:** кроки 1–2 виконано в робочому дереві гілки `claude/t1-orchestration-2026-10-07` поверх `f7f8a78`; коміт робить T1. Регресія headless і нативна перевірка під Xvfb зелені. На Mac вікно ще не перевірене.

Виконую [[2026-10-07-Auto-Window-Size]] (`approved`). Слова Santos: «виправ розширення екрану на автомат». Він запускає гру через `make run` на Mac, і вікно відкривається на 1152×648.

## Звірка плану з реальністю

1. `grep -n -A9 "^\[display\]" game/project.godot` → `window/size/mode=0`, `window_width_override=1152`, `window_height_override=648`, база 1600×900, `canvas_items` + `expand`. Це збігається з аудитом плану.
2. `grep -rn "window/size\|window_get_mode\|window_set_mode\|WINDOW_MODE\|window_set_size\|get_window()" game/scripts game/scenes tools` → порожньо. Режим вікна в коді ніхто не читає й не задає.
3. `framing_check.gd:36,141` і `comfort_ui_check.gd:42` самі задають розмір SubViewport. Нативна перевірка ставить `root.size = Vector2i(480,360)` (`city_camera_renderer_check.gd:28`). Так само записано в плані.
4. Бінар: `Godot_v4.7-stable_linux.x86_64 --version` → `4.7.stable.official.5b4e0cb0f`. `git ls-remote https://github.com/godotengine/godot refs/tags/4.7-stable` → `5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88`. Бінар зібраний із того самого тегу, з якого читаю сирці нижче.

## Джерело: що означає `mode=2`

Сирці тегу `4.7-stable` (raw.githubusercontent.com/godotengine/godot/4.7-stable/…):

| що | файл:рядок | вміст |
|---|---|---|
| оголошення налаштування | `core/config/project_settings.cpp:1722` | `GLOBAL_DEF_BASIC(PropertyInfo(Variant::INT, "display/window/size/mode", PROPERTY_HINT_ENUM, "Windowed,Minimized,Maximized,Fullscreen,Exclusive Fullscreen"), 0);` |
| перелік | `servers/display/display_server_enums.h:196-202` | `WINDOW_MODE_WINDOWED, WINDOW_MODE_MINIMIZED, WINDOW_MODE_MAXIMIZED, …`: індекс 2 = `WINDOW_MODE_MAXIMIZED` |
| документація | `doc/classes/DisplayServer.xml:3266-3267` | `WINDOW_MODE_MAXIMIZED value="2"`: вікно займає весь екран, крім панелі задач, і зберігає рамку |
| старт рушія | `main/main.cpp:2724` | `window_mode = (DisplayServerEnums::WindowMode)(GLOBAL_GET("display/window/size/mode").operator int());`, далі передається в `DisplayServer::create` (`:3364`) |
| override | `main/main.cpp:2684-2694` | `window_*_override` задає лише початковий `window_size` |
| headless | `main/main.cpp:1500-1503` | `--headless` → `display_driver = NULL_DISPLAY_DRIVER` |
| headless ігнорує режим | `servers/display/display_server_headless.cpp:38-42` | `create_func` не використовує `p_mode`. `display_server_headless.h:122-123`: `window_set_mode(...) {}`, `window_get_mode` завжди повертає `WINDOW_MODE_MINIMIZED` |
| macOS | `platform/macos/display_server_macos.mm:257, 2296-2303` | `_create_window` викликає `window_set_mode(p_mode, id)`. `MAXIMIZED` → `zoom:` до `[screen visibleFrame]`, тобто екран без рядка меню й Dock |
| X11 без WM | `platform/linuxbsd/x11/display_server_x11.cpp:3011-3017` | чекає на WM до 0,5 с, потім здається |

## Що змінено

| крок | файл | суть |
|---|---|---|
| 1 | `game/project.godot` | `window/size/mode=0` → `window/size/mode=2`. Override 1152×648 не змінено: це розмір вікна після «відновити» |
| 2 | `docs/Tech/Build-and-Run.md` | одне речення в «Режими й керування» |
| 2 | цей журнал | — |

## Перевірка

Бінар — official `Godot_v4.7-stable_linux.x86_64` (`4.7.stable.official.5b4e0cb0f`, sha256 `f85bbc6b…ae55a75`). Raw-логи лежать у scratchpad сесії T2, тека `window-auto/`. Поки йшов `make check-playable`, T1 закомітив `dd2f3d1..f7f8a78`. `git diff --quiet 69036a4 HEAD -- game tools Makefile .github` → rc0: змінилися лише доки. Отже код під тестом = `f7f8a78` + рядок `mode=2`.

| команда | rc | ключовий рядок |
|---|---:|---|
| `make check-playable` (тягне `make check`) | 0 | GDS `перевірено: 126 · не парсяться: 0`; `[smoke] ALL OK (165 checks) in 19847 frames`; `PLAYABLE CHECK: 131 scenarios, 0 failures` |
| `make gates` | 0 | wikilinks `зламаних: 0`; assets `176 · у реєстрі: 176`; GDS `126 · не парсяться: 0`; `БАТАРЕЯ ЗЕЛЕНА` |
| нативна `tools/camera/city_camera_renderer_check.gd`, як у `.github/workflows/ci.yml:78-80` (xvfb 1280×720, `gl_compatibility`, llvmpipe) | 0 | `CITY_CAMERA_RENDERER_COMPLETE checks=4 failures=0`; валідатор CI → `NATIVE_COMPATIBILITY_PASS checks=4 errors=0`. Є лише відоме llvmpipe-попередження V-Sync |
| `make gates-docs` | 0 | `ДОКИ ЗЕЛЕНІ; КОД НЕ ВИМІРЯНО` |

### Чи доходить налаштування до вікна

Предмет: для всіх стартів гри з цим `project.godot` віконний DisplayServer отримує `WINDOW_MODE_MAXIMIZED`, а вікно займає робочу область екрана замість 1152×648. Headless від налаштування не залежить.

Перевіряв зондом `window_mode_probe.gd` у scratchpad, не в репо. Він друкує налаштування, `DisplayServer.window_get_mode()`, розмір вікна й `screen_get_usable_rect()` на старті та на 10-му кадрі:

| запуск | драйвер | setting | reported | вікно | робоча область |
|---|---|---:|---:|---|---|
| `game/`, `--headless` | headless | 2 | 1 (заглушка `MINIMIZED`) | (0, 0) | (0, 0) |
| `game/`, xvfb 1280×720 | X11 | 2 | 2 | **1280×720** | 1280×720 |
| контроль: мініпроєкт із тією самою секцією `[display]`, але `mode=0`, xvfb | X11 | 0 | 0 | **1152×648** | 1280×720 |
| мініпроєкт, `mode=2`, xvfb | X11 | 2 | 2 | 1280×720 | 1280×720 |

Зонд розрізняє дві форми: «режим не застосувався» (контроль `mode=0` дає 1152×648) і «headless залежить від режиму» (у headless reported = 1 і розмір 0 при setting 2). Третю форму, «на macOS інша поведінка», тут не перевірити: Mac у сесії немає. Сирці (`display_server_macos.mm:257, 2296-2303`) кажуть, що буде `zoom:` до `visibleFrame`, але це не спостереження.

Нативна перевірка CI після зміни так само ставить своє `root.size = 480×360` і проходить 4/0. Під Xvfb без WM вікно спершу стає 1280×720, але це її не ламає.

## Відкрите

- **Mac Santos.** Розгорнуте вікно на M3 ніхто не бачив. Перевірка: `make run`, вікно має зайняти екран без рядка меню й Dock, а зелена кнопка «відновити» має дати 1152×648.
- **Збірка в `/Applications`** отримає новий режим лише після наступного експорту з цим `project.godot`. Цього не перевіряв.
- **FPS на Retina / 4K.** Пікселів стало більше. На повній роздільності не міряв. Важелі — профілі Low/Medium.
- **Вбудована гра в редакторі.** `doc/classes/ProjectSettings.xml:1044`: «Game embedding is available only in the "Windowed" mode». Чи `make editor` → Run тепер відкриває гру окремим вікном, не перевіряв.
- **Крок 3 плану** (перемикач DISPLAY) — GAP для T8 у [[06-UI-UX]], не мій.

## Related
- [[2026-10-07-Auto-Window-Size]] · [[Build-and-Run]] · [[Testing]] · [[06-UI-UX]] · [[state]] · [[constitution]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]] · [[2026-10-07-T1-Orchestration-Session]]
