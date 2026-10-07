# Приймання на MacBook M3 — чек-лист для Santos

**Дата:** 2026-10-07 · **Роль:** T8 Гермес · **Збірка:** `v0.5.0 · build f27fd67`
(main після PR #183: wall kick, landing roll, Low/Medium/High, підказки HUD).
**Час:** 25–30 хв. Цей документ — порядок перевірки. Сам він нічого не вимірює:
результати з'являться лише після проходу Santos.

На 2026-10-07 опублікований канал macOS вказує на той самий коміт, що й main:
`curl -sSL https://github.com/santos-va/nooneisreal/releases/download/macos-main/manifest.json`
→ `"revision": "f27fd679ccb1def97290c9c5cc261801cedbcbc6"`, `godot 4.7-stable`,
`ad-hoc; not notarized`. Чи встановлена ця збірка на твоєму Mac — **не перевірено**.

## 0. Оновити й звірити збірку (3 хв)

1. Закрий гру. Updater ніколи не замінює відкриту гру ([[Build-and-Run]]).
2. Із малого `NoOneIsReal-Updater.zip` (реліз `macos-main` на GitHub) відкрий
   **Check Updates.command**. Він нічого не встановлює. Очікування:
   `Installed build: f27fd679…` і `No update available; this is a successful check.`
3. Якщо там `Builds differ`, сторінка [[Build-and-Run]] пропонує три шляхи:
   - auto-updater уже ввімкнений: залиш гру закритою; оновлення прийде при вході в систему
     або протягом 15 хв. Негайний запуск — та сама команда, яку виконує LaunchAgent
     (`install_agent` у `tools/distribution/update-macos.sh`):
     `/bin/bash "$HOME/Library/Application Support/No One Is Real/Updater/update-macos.sh"`;
   - старий updater: спершу **Enable Updates.command** з того самого zip;
   - гри немає в `/Applications`: повний `NoOneIsReal-Installer.zip` → **Install.command**.
   Логи — `~/Library/Application Support/No One Is Real/Updater/`. Наново запусти Check Updates.
4. У грі внизу головного меню має бути `v0.5.0 · build f27fd67`. Той самий рядок є в паузі міста.
   Запиши, що показано насправді.

Збереження (`~/Library/Application Support/Godot/app_userdata/No One Is Real/`) updater
не чіпає ([[Export-Platforms]]). Кнопки стирання кампанії в грі немає.

## 1. Записати середовище (2 хв)

| Поле | Значення |
|---|---|
| Модель Mac, версія macOS (Apple menu → About This Mac) | |
| Дисплей: вбудований / зовнішній; масштаб у System Settings → Displays | |
| Вікно гри: як відкрилось (типово windowed, `project.godot` 1152×648) / на весь екран | |
| Живлення: від мережі / батарея; Low Power Mode on/off | |
| Ввід: вбудована клавіатура + трекпад / миша / геймпад (модель, USB чи Bluetooth) | |
| Профіль якості на старті (COMFORT & CONTROLS → GRAPHICS QUALITY) | |

## 2. Запустити з лічильником кадрів (1 хв)

**Вбудованого FPS/frame-time оверлея в грі немає.**
`grep -rn "Performance.get_monitor\|get_frames_per_second\|TIME_PROCESS" game/scripts` → 0 збігів, rc=1.
Поки його немає (GAP нижче), запускай гру з Terminal:

```bash
MTL_HUD_ENABLED=1 "/Applications/No One Is Real.app/Contents/MacOS/No One Is Real" --print-fps
```

- `--print-fps` — офіційний аргумент Godot 4.7. Його наявність у release-шаблонах
  перевірена в коді ([main.cpp 4.7-stable](https://github.com/godotengine/godot/blob/4.7-stable/main/main.cpp):
  рядки 686 і 1970; мітка доступності за замовчуванням `TEMPLATE_RELEASE`, `main.h:51`).
  CI так само запускає цей бінар з аргументами Godot (`.github/workflows/macos-main.yml`).
  Раз на секунду в Terminal виводиться `Project FPS: N (X mspf)`, де mspf — **середнє**
  за секунду, тобто 1000/FPS. Окремих стрибків кадрів цей рядок не показує. На старті
  ще виводяться `Requested V-Sync mode: …` і рядок `… - Using Device #…: …`. Обидва
  треба записати. Межа FPS: `run/max_fps=120` у `project.godot`, а з V-Sync ще й частота дисплея.
- `MTL_HUD_ENABLED=1` вмикає Apple Metal Performance HUD: середні FPS, GPU time,
  frame interval і графік останніх 120 кадрів
  ([Apple](https://developer.apple.com/documentation/xcode/monitoring-your-metal-apps-graphics-performance)).
  Godot 4.7 на macOS за замовчуванням працює на `metal` (`main.cpp:2389`), проєкт це
  не перевизначає. Чи з'явиться HUD на твоїй macOS — **не перевірено**. Якщо його немає,
  це не дефект гри: досить рядків `--print-fps`.
- Читай значення просто з вікна Terminal, не перенаправляй виведення у файл. Release-збірка
  не скидає stdout після кожного рядка (`flush_stdout_on_print=false`, `main.cpp:1079`).
  Перед закриттям скопіюй останні рядки.

**Протокол виміру.** На кожну точку — 30 с без меню. Запиши мінімальне й типове FPS/mspf,
а також GPU time і frame interval, якщо видно HUD:
A головне меню · B місто, старт, герой стоїть · C біг від старту до станції з поворотом
камери на 360° · D тісна станція (розділ 5) · E FIGHT проти CPU, один раунд.
Спершу все на **High**, потім B, D і E на **Low** (Medium — якщо лишиться час). Наприкінці
сесії повтори B, щоб побачити, чи змінились цифри після ~20 хв гри.

## 3. Трюки на клавіатурі — Choko, потім Skea (8 хв)

Головне меню → `HERO ◂ ▸` → ENTER/CONTINUE DISTRICT. Місто вмикає SOLO + 3D.
Повні прив'язки — [[05-Platforms-Input]].

| Перевірка | Як | Очікувана підказка внизу (`CityHud.gd:592–601`) |
|---|---|---|
| Hang | у стрибку тримати Space і рухатися до краю | `LEDGE · Grip N.Ns · Release, then press Space: climb / + move away: kick · Z: drop` |
| Wall kick | відпустити Space, напрям **від** стіни + Space; з висіння так само | `WALL KICK · Touch down before another kick` |
| Повторний kick | у тому ж стрибку спробувати ще раз | без другого поштовху до приземлення |
| Landing roll | стрибнути з верху уступу (2,8 м), до приземлення тримати X + напрям | `LANDING ROLL · Release X to stop rolling` |
| Без бонусу | відпустити X посеред перекату | перекат зупиняється, без прискорення |

Розрахунок за кодом, у грі не виміряно: поріг перекату `roll_min_fall_speed = 6.0` м/с
(`city_parkour.tres`) за `default_gravity=24` дає приблизно 0,75 м вільного падіння.
**Відкритий уступ для kick** (орієнтир виведено з `CityDistrict.gd:41–42`, мною не пройдений):
від центральної площі на північний схід. Якщо дивитись у початковому напрямку камери,
ліворуч від східної рампи стоять дві кам'яні тераси з латунним краєм, 2 і 4 м заввишки.
Підходити з півдня.

## 4. Геймпад, якщо є (4 хв)

Підключи до запуску; P1 — device 0. Ті самі рядки таблиці 3: стрибок A/Cross, перекат
D-pad ↓ + лівий стік, огляд правим стіком. У підказках має стояти `A / Cross`,
`B / Circle (while hanging)`, `D-pad Down`. Перемкнись між пристроями: натисни кнопку
pad, потім клавішу. Пристрій визначається за останнім натисканням (`HarpoonAim.gd:43–49`),
тож підказка має перемикатися при наступному стані. Рух мишею без кліку перемикання
не викликає.

## 5. Тісна станція `(4, 0, 31.4)` (3 хв)

Відомий YELLOW: камера стискається, герой зникає в dither ([[2026-10-05-Traversal-And-Surface-Review]]).
Ця перевірка потрібна, щоб побачити дефект на справжньому M3, а не щоб його закрити.

**Як дійти** (виведено з коду; суцільний ручний маршрут не перевірено): старт `(0, 0, 23)`
(`CityLayout.gd:9`). У початковому ракурсі тренувальний блок `PracticeLedge`
(2,8 × 2,8 × 2,4 м, латунний край, центр `(4, 1.4, 29)`, `CityDistrict.gd:40`) стоїть
≈4 м праворуч і ≈6 м позаду. Латунний край дивиться на південну межову стіну, і між
ними лишається ≈1,8 м (`CityLayout.gd:50`). Стань у цю щілину обличчям до блока,
стрибни з рухом уперед (hang), далі kick назад.

Запиши таке: чи видно героя (так / частково / ні); FPS-рядок; чи допомагає повернути
камеру ПКМ+перетягуванням (на трекпаді — вторинний клік із перетягуванням: чи це взагалі
вдається?) або правим стіком. Скрін або запис — Cmd+Shift+5.

## 6. Якість Low / Medium / High (5 хв)

- Де: **COMFORT & CONTROLS → GRAPHICS QUALITY** (`ComfortPanel.gd:51–64`). Панель
  відкривається з головного меню і з паузи бою FIGHT/TRAINING. У паузі міста її **немає**
  (`grep -rn "ComfortPanel\|GraphicsSettings" game/scripts/world/` → rc=1). Тому профілі
  найшвидше порівнювати в FIGHT. Для міста: RETURN TO MAIN MENU → змінити → CONTINUE DISTRICT.
- Очікування: застосовується одразу; текст і HUD лишаються чіткими; Low помітно м'якший
  (scale 0,75, без MSAA — [[2026-10-05-Graphics-Quality-And-Surface-Filtering]]).
  Профілі — PLACEHOLDER, вони не обіцяють певного FPS.
- Збереження: обрати **Medium** → QUIT GAME → запустити знову → у списку має бути Medium.
  Додатково можна перевірити файл:
  `cat "$HOME/Library/Application Support/Godot/app_userdata/No One Is Real/graphics.cfg"`
  → `[graphics]` і `profile="medium"`. Якщо збереження не вдалось, панель показує
  `Could not save preferences…`.

## 7. Сюжетні епізоди не зламані (4 хв)

Для героя з прогресом: Esc · Help → журнал. Завершені «Слід під годинником» і «Нижня
позначка» мають лишатися історією, службова хвіртка — відкритою
([[2026-10-05-Clocktower-Trace]], [[2026-10-05-Lower-Mark]]). Для героя без прогресу:
поговорити з Ладою в майстерні «Мідна година» (G / pad Y + D-pad ↓), прийняти справу й
оглянути один слід. Картка цілі має оновитися. Прогрес Choko і Skea окремий.

## Дефект-звіт

```
D-<n>: <одне речення>
Збірка/середовище: v0.5.0 · build f27fd67 · macOS … · дисплей … · профіль …
Герой · режим · місце: …
Вхід (кроки й клавіші/кнопки): 1) … 2) … 3) …
Очікування: …
Факт: …
Частота: завжди / N з M
Доказ: скрін або запис (Cmd+Shift+5) + рядок FPS з Terminal
Вплив: блокує / заважає / косметика
```

Результати й дефекти — у чат сесії. T1/T8 перенесуть їх у журнал і [[state]];
задачі з кодом підуть T2.

## GAP для T2: вбудований лічильник кадрів

Тумблер `PERFORMANCE OVERLAY` у ComfortPanel, типово вимкнений. Він має відкриватися
також із паузи міста. Показує: FPS (`Performance.TIME_FPS`), CPU кадру
(`TIME_PROCESS`), фізику (`TIME_PHYSICS_PROCESS`), GPU
(`RenderingServer.viewport_set_measure_render_time` →
`viewport_get_measured_render_time_gpu`), max/p95 за ~5 с, профіль, render scale і
`BuildInfo.label()`. API звірені з `doc/classes/*.xml` Godot 4.7-stable. F-клавіша означала б
нову дію `debug_*`, а це спершу [[05-Platforms-Input]] і ADR; до того ж F-ряд на Mac часто
зайнятий системою. Тому пропоную тумблер.

## Related

- [[Build-and-Run]] · [[Export-Platforms]] · [[Testing]] · [[state]]
- [[05-Platforms-Input]] · [[06-UI-UX]] · [[2026-10-05-District-Delivery]]
- [[2026-10-05-Parkour-Tricks-And-Quality]] · [[2026-10-05-City-Parkour-Tricks]] · [[2026-10-05-Graphics-Quality-And-Surface-Filtering]]
- [[2026-10-05-Traversal-And-Surface-Review]] · [[2026-10-05-Clocktower-Trace]] · [[2026-10-05-Lower-Mark]]
