# Кров і налаштування контенту в смертельному бою

**Дата:** 2026-10-07 · **Роль:** T2 Гефест · **Статус:** зроблено в робочому дереві, без коміту. Це крок 3 і решта кроку 4 [[2026-10-07-First-Enemy-Lethal-Fight]] (рішення [[ADR-024-Lethal-Fights-And-First-Enemy]] п. 4, п. 7).
- Вигляд — [[2026-10-07-Blood-Visual-Language]] (варіант A + краплі на землі).
- Правила подій — [[02-Combat-System]] § Кров: коли і скільки.
- Кольори — [[Style-Guide]] § Колір; К1 `#A3243B` Santos підтвердив прямо («2 так», `4bf9111`).
- База — `13fd6ac`: ядро бою, [[2026-10-07-Lethal-Fight-Core-Fix]]. T1 переставив `0d55f48` на нову основу; `git diff --quiet 0d55f48 13fd6ac` → тотожні.
- Коміт робить T1.

## Звірка плану з реальністю

1. **Посилання T1 зсунулись на 12 рядків.** `RigAnimator.gd:194` (`flash_time = 0.09`) правильне для `c1cdd4e` (`git show c1cdd4e:… | grep -n` → 194). У `13fd6ac` гілка жердини `staff` зсунула цей рядок на `:206` (`git show HEAD:game/scripts/fighter/RigAnimator.gd | grep -n "flash_time = 0.09"` → 206). `HitSpark.gd:38` — `_light.light_energy = 1.5 if blocked else 4.0`, збігається.
2. **Специфікації T8 «S3» у документах немає.** `grep -rn "S3\|content.cfg\|notice_seen\|HIT FLASH" docs` знаходить лише рядок 4 плану та рядок «Погляди» плану. Тож специфікацією слугують рядок плану й доручення T1. Де зберігати HIT FLASH, ніде не сказано (див. «Рішення»).
3. **Повноекранного спалаху в грі немає.** `grep -rn -i flash game/scripts/{arena,ui,fx,skills}` знаходить лише два спалахи: матеріальний `hit_flash` (тіло біліє) і світло `HitSpark`. ColorRect-оверлею немає, і новий не додається.
4. **Proximity у кишені не працює.** `CityCameraProximity` збирає матеріали лише гравця і працює лише з `CityCamera` (`CityCamera.gd:195-200`). Під час бою поточна камера — `DuelCamera`, а в ній proximity немає; на відкритті бою `CityLethalFight.gd:195` скидає заливку героя. Тому правило T6 треба виконати незалежно від камери (див. «Рішення»): нових крапель немає біля героя з видимістю < 0,5 і ближче ніж 1 м до лінзи.
5. **Пласкі квади на підлозі вже є** — `Flipbook.Mode.FLOOR` (`Flipbook.gd:73-74`). `Decal` у Compatibility не працює (T6 цитує `Decal.xml` 4.7), тому лише квад.
6. **`QualityProfile` мав лише `render_scale` і `msaa`** (`QualityProfile.gd:5-7`). Бюджету частинок не було, тож потрібне нове поле. Інші фікстури полів профілю не перелічують: `grep -rn "QualityProfile" tools` знаходить лише `ids()`, `make()`, `render_scale`.
7. **Порядок фокуса в `ComfortPanel` закріплений фікстурами:**
   - `graphics_ui_check` — з MASTER «вгору» на GRAPHICS QUALITY;
   - `comfort_ui_check` — з RESTORE «Tab» на довідку.

   Нові рядки стають між CAMERA SHAKE і RESTORE, тож обидва переходи лишаються такими, як були.
8. **Кров не для UI** ([[Style-Guide]], застереження). У картці та в `ComfortPanel` червоного немає.
9. **`ComfortSettings` зберігає лише числа 0–1** (`ComfortSettings.gd:4-6`: `changed(key, value: float)`, `DEFAULTS` — гучності й тряска). RESTORE скидає саме їх («RESTORE SOUND & SHAKE DEFAULTS»).

## Хід роботи

- [x] `ContentSettings` (autoload, `user://content.cfg`):
  - ключі: `blood` full|muted|ink|off, `notice_seen`, `hit_flash` full|reduced;
  - пошкоджений файл або невідоме значення → у сесії `ink` / `reduced` / картка не бачена; `save_settings` відмовляє, і байти файла лишаються (як у `GraphicsSettings`);
  - рядок у `project.godot`.
- [x] Три нові файли: `BloodFx`, `BloodSplash`, `fx_blood.gdshader`.
  - Вигляд: коми й розбризки з обідком, краплі-квади на підлозі, калюжа трьома ступенями.
  - Поведінка: режими, ліміти `QualityProfile` (нові поля, дефолти = High), правило лінзи.
  - `BloodFx` слухає `hit_landed` лише в lethal-бою і лише з `Fx.enabled`.
- [x] HIT FLASH: `RigAnimator.flash()` і світло `HitSpark` множаться на `ContentSettings.hit_flash_scale()` (Full 1,0 · Reduced 0,5).
- [x] `ComfortPanel`: рядки BLOOD і HIT FLASH між CAMERA SHAKE і RESTORE. `content.cfg` пишеться лише тоді, коли змінився вибір контенту, — smoke і наявні фікстури цей файл не створюють.
- [x] `ContentNotice` (новий): картка перед ROUND 1 першого смертельного бою, вхід через `CityLethalFight.request_open()`.
- [x] Зонд `probe_trace.gd`: два свіжі світи з `full` і один з `off`, 700 тіків бою з ударами героя й CPU.
  - Перша розбіжність full/full і full/off — `-1` (розбіжностей немає).
  - У `full` — 14 бризків.
  - `lethal_fight_check` → 118/0, CPU-статистика та сама.
- [x] Фікстура `tools/fx/blood_content_check.gd` → 52/0 і 9 негативів, усі червоні; зареєстровано в `playable_check.sh`.
- [x] `make check-playable`, `make gates` — див. «Перевірки».

## Що змінено

| файл | суть |
|---|---|
| `game/scripts/core/ContentSettings.gd` (новий), `game/project.godot` | Autoload, 1 рядок у `[autoload]` після `GraphicsSettings`.<br>**API:** `blood_mode()`, `hit_flash()`, `hit_flash_scale()`, `notice_seen()`, `storage_ok()`, `set_blood_mode()`, `set_hit_flash()`, `mark_notice_seen()`.<br>**Читання:** `load_settings()` вимагає в `[content]` усі три ключі. Сміття, яке `ConfigFile` таки розбирає, — це `ERR_INVALID_DATA`.<br>**Запис:** `save_settings()` пише через `.tmp` + rename і відмовляє, якщо файл не прочитався.<br>**Дефолт:** `full` (PLACEHOLDER до рейтингових рядків кроку 7) |
| `game/scripts/fx/BloodFx.gd` (новий) | Спостерігач бою, власний RNG `0x0B100D`.<br>**Рівні:** 1–4 від `move.damage` (< 50 / 50–89 / ≥ 90), крит +1, стеля 4.<br>**Кількість:** крапель у бризку 4/6/8/11; під жертвою на землі 1/2/3/4 краплі на підлозі.<br>**Вирішальний KO:** +1 рівень; калюжа лише під `cpu_only`-ворогом і лише в Full — після 45 кадрів осідання, три ступені 0,45 → 0,8 → 1,2 м по 4 кадри.<br>**Висихання:** плями висихають за 3 с одним кроком.<br>**Muted:** `#711126` / тінь `#4E0819`, життя ×0,5, без калюжі.<br>**Ink:** `SmearShards` у палітрі атакувальника, без крапель.<br>**Off:** нічого, лише наявні іскри.<br>**Правило лінзи:** див. «Рішення».<br>**Закриття кишені:** `clear()` — кров ступенями згасає за 0,5 с.<br>**RETRY:** `reset_match()` одразу витирає підлогу.<br>Усі кількості й тривалості — PLACEHOLDER для T6 |
| `game/scripts/fx/BloodSplash.gd` (новий) | Один бризок: краплі-коми летять уздовж удару під гравітацією 9, дивляться в камеру, меншають і зникають ступенями, живуть 0,25–0,55 с |
| `game/shaders/fx_blood.gdshader` (новий) | unshaded, `depth_draw_never`, жорсткий SDF-край.<br>**Форми:** кома · розбризк із пелюстками · пляма/калюжа.<br>**Заливка:** колір заливки, тінь з одного боку (колір × `#B07AA6`), обідок `#2B2230`.<br>**Згасання:** `dry`, ступінчастий `fade` |
| `game/scripts/core/QualityProfile.gd` | Чотири нові поля, дефолти = High: `blood_drops` 1,0 · `blood_size` 1,0 · `blood_rim` true · `blood_floor_limit` 16.<br>Medium — 0,5 / 10.<br>Low — 0,25 / ×1,6 / без обідка / 6.<br>`render_scale` і `msaa` не чіпано |
| `game/scripts/fighter/RigAnimator.gd` | `FLASH_SECONDS = 0.09` (було літералом), `flash_strength`. `flash()` множить час і білизну на `hit_flash_scale()`. Шейдери змішують `mix(base, white, hit_flash)` (`toon.gdshader:28`), тож 0,5 — це половина білизни |
| `game/scripts/fx/HitSpark.gd` | Світло удару `(1.5 / 4.0) × hit_flash_scale()` |
| `game/scripts/ui/ComfortPanel.gd` | Рядок `BLOOD · LETHAL FIGHTS ONLY` (4 режими) з довідкою «Sparring between Choko and Skea never shows blood.» і рядок `HIT FLASH` (Full / Reduced). Обидва між CAMERA SHAKE і RESTORE.<br>Збереження відбувається лише у виборі контенту, помилка запису видна в рядку статусу. Попапи обох рядків обробляються так само, як GRAPHICS QUALITY.<br>RESTORE контенту не чіпає |
| `game/scripts/ui/ContentNotice.gd` (новий) | Картка, шар 21: «THIS FIGHT SHOWS BLOOD», рядок «можна змінити в COMFORT & CONTROLS», 4 кнопки з фокусом на поточному режимі (вгору/вниз по колу).<br>**Enter / A:** зберігає режим, `notice_seen = true`, запис, бій.<br>**Esc / B:** назад у місто без бою, картка лишається небаченою.<br>Нових дій вводу немає, червоного немає |
| `game/scripts/world/CityLethalFight.gd`, `CityWorld.gd` | `request_open()`: якщо `notice_seen`, бій відкривається одразу, інакше спершу картка. На `open()` створюється `BloodFx "LethalBlood"`; `retry()` → `reset_match()`, `close()` → `clear()` |
| `tools/fx/blood_content_check.gd` (новий), `tools/gates/playable_check.sh` | Фікстура з 52 перевірками і 9 негативами з префіксом `ERROR: BLOOD_CONTENT: ` |
| `tools/match/lethal_fight_check.gd` | Картку тут позначено як бачену (лише в сесії, без запису): вона належить фікстурі крові, а `interact` має відкривати бій одразу |

**Межі (перевірено командами):** числа бою, `.tres` героїв та ворога, input map не змінено. У `project.godot` — лише один рядок autoload. Див. «Перевірки».

## Рішення в межах T2

| розвилка | варіанти | обрано і чому |
|---|---|---|
| Де живе HIT FLASH | (а) `ComfortSettings`; (б) `GraphicsSettings`; (в) `ContentSettings` | **(в).** `ComfortSettings` зберігає лише числа 0–1 із сигналом `float`, а RESTORE скидає «звук і тряску». Вибір із двох режимів у цю схему не лягає, а RESTORE мовчки повертав би яскравий спалах. Профіль графіки — бюджет рендера, а не доступність. В одному файлі контенту однакове правило пошкодженого файла діє для крові й спалаху. Ціна: `content.cfg` тепер містить не лише «контент», а й «спалах» |
| Пошкоджений або невідомий `content.cfg` | (а) дефолти (Full) і запис поверх; (б) Off у сесії; (в) Ink + Reduced + картка небачена, без запису | **(в)** — як у дорученні T1. Варіант (а) показав би кров тому, хто обрав Off, і стер би його вибір. Ink — найстриманіший режим, що ще показує влучання. Картка знову питає, тож гравець бачить вибір у тій же сесії. Байти лишаються для відновлення |
| Правило лінзи без proximity у кишені | (а) proximity для `DuelCamera`; (б) нічого; (в) перевірка в `BloodFx` від поточної камери | **(в).** Не народжується нічого ближче 1 м до активної `Camera3D` (`get_viewport().get_camera_3d()`) і біля бійця, чия заливка `camera_visibility` < 0,5. Правило не залежить від того, яка камера активна. Варіант (а) — камерна хвиля, поза межами цього заходу. Наявні краплі живуть ≤ 0,55 с, тож окремо їх не гасимо |
| Кров після бою (питання Santos № 4 у T6, відкрите) | лишити як пам'ять двору; стерти ступенями | **Стерти ступенями** за 0,5 с, як рекомендує T6. Кров не переходить у місто. Якщо Santos обере «лишити», зміна обмежиться `clear()` |
| `content.cfg` у smoke і наявних фікстурах | писати на кожне закриття панелі; лише на зміну вибору | **Лише на зміну вибору.** Інакше `make check` і `comfort_*` фікстури створювали б файл у профілі користувача |
| Перший бій у фікстурі ядра | картка в `lethal_fight_check`; позначити бачену | **Позначити бачену** в сесії: картку перевіряє фікстура крові, а негативи ядра не мають червоніти через неї |

**Не зроблено цим заходом:**
- плями на тілі (варіант B-тіло, крок 2 T6 і рядок GDD 02 «плями лишаються між раундами»);
- чи застигає бризок разом із замороженою жертвою;
- RED-аркуші № 4–5.

## Регресія

`tools/fx/blood_content_check.gd`, базовий запуск → `BLOOD_CONTENT_COMPLETE checks=52 failures=0 mutation=none`. Пороги — літерали:
- GDD 02 § Кров (рівні 50/90, краплі 1/2/3/4, калюжа ≈ 1,2 м за 3 ступені);
- T6 § Профілі якості (High 16 на підлозі, Medium ½, Low ¼) і § Proximity (лінза 1 м, заливка 0,5);
- T8/T1 (Reduced ≤ 0,5 від 0,09 с і 4,0).

| властивість | як перевірено | негатив (форма зламу) |
|---|---|---|
| спаринг без крові | справжня `Arena` (lethal вимкнено) зі своїм `BloodFx`: 5 чистих ударів — 0 бризків, 0 ink, 0 крапель | `sparring` — арена стає lethal |
| пошкоджений cfg | немає файла → Full/Full/картка не бачена; запис і перечитування; невідомі режими відкидаються. «Зламаний» і «невідомий» файли → Ink/Reduced/небачена, `storage_ok` false, запис відмовляє, байти ті самі | `cfg` — файл перезаписано |
| ComfortPanel | клавіатура: вниз із CAMERA SHAKE → BLOOD, Enter відкриває вибір, вниз + Enter → Muted, запис у `content.cfg`; вниз → HIT FLASH; геймпад: A, хрестовина вниз, A → Reduced; вниз → RESTORE | — (порядок фокуса тримають і `graphics_ui` / `comfort_ui`) |
| HIT FLASH | Full: 0,09 с × 1,0, світло 4,0. Reduced: ≤ 0,045 с, ≤ ×0,5, світло ≤ 2,0 | `flash` — Reduced лишається Full |
| картка | перший `interact` → картка, не бій, ввід у UI; заголовок, 4 режими, фокус Full; Esc і геймпад B → назад у місто без бою й без паузи, картка небачена, файла немає, наступний `interact` знову показує картку; вниз → Muted; Enter на Full → бій | `notice` — `notice_seen` не збережено; `back` — крок назад рахується як «бачено» |
| рівні | `level_for`: 49 → 1, 50 → 2, 89 → 2, 90 → 3, 40 + крит → 2, 60 + крит → 3, 95 + крит → 4 | — (таблиця з літералів) |
| чисте / крит / блок / DoT / заморожений | чистий легкий → 1 бризок + 1 крапля; крит → 2 краплі; блок (blockstun) → нічого; тік DoT знімає HP без крові; удар по замороженому → бризок | `block` — кров на блоці |
| режими | Off → ні бризків, ні ink, ні крапель; Ink → 1 ink-сплеск, ні бризків, ні крапель; Muted → бризок темніший за К1, життя ≤ 0,275 с | `mode` — Off кровить; `ink` — Ink лишає краплі |
| якість | на рівні 3 краплі High 8 · Medium 4 · Low 2 (½ і ¼); на High живуть ≤ 16 крапель на підлозі (народилось 37) | — |
| лінза | 0,5 м від камери — ні; груди ворога — так; герой із заливкою 0,3 — ні | — |
| KO | KO 1-го раунду — калюжі немає; вирішальний легкий → 2 краплі (+1 рівень); калюжа `[0.45, 0.8, 1.2]` | — |
| закриття | кишеня закрита, `blood` null, у світі 0 вузлів крові | — |
| кров не змінює бій | два свіжі світи (Full і Off), 700 тіків з ударами героя й CPU. Порівнюються hp, стани, позиції, кадри й hitstop обох бійців: перша розбіжність −1, бризків 14 / 0. Повторна картка не з'являється | `state` — кров знімає 1 HP (перша розбіжність 149) |

Негативи у фінальній батареї (`grep BLOOD_CONTENT_COMPLETE playable/blood-content-negative-*.log`):
- sparring — 1/1;
- cfg — 21/2;
- flash — 21/2;
- notice — 26/1;
- back — 26/6;
- block — 26/1;
- mode — 26/1;
- ink — 26/1;
- state — 4/1.

Кожен негатив дає rc 1. Гейт пропускає лише рядки `ERROR: BLOOD_CONTENT: `. Частина зламу «пошкоджений файл» навмисно глушить власну помилку розбору `ConfigFile` через `Engine.print_error_messages = false` — так само, як `comfort_check`.

## Перевірки

Godot 4.7 official (`4.7.stable.official.5b4e0cb0f`). Сирі логи лежать у scratchpad сесії, `lethal/blood-final/`: `check-playable.raw`, `gates.raw`, `playable/*.log` (131 файл).

| команда | результат |
|---|---|
| `GODOT_BIN=… PLAYABLE_LOG_DIR=… make check-playable` (включає `make check`) | rc 0.<br>Smoke: `[smoke] ALL OK (165 checks) in 19847 frames`.<br>GDS: `перевірено: 126 · не парсяться: 0`, ContentSettings у фільтрі autoload.<br>Playable: `PLAYABLE CHECK: 131 scenarios, 0 failures` (було 121; +1 база й +9 негативів крові) |
| у тій самій батареї | `lethal-fight` — `LETHAL_FIGHT_COMPLETE checks=118 failures=0`; `blood-content` — `checks=52 failures=0`, усі 9 негативів PASS з rc 1 |
| скан сирих логів (`grep -E "^\s*(SCRIPT ERROR\|ERROR):"` поза негативами; `WARNING`; `jolt`) | 0 · 0 · лише назва smoke-перевірки «the hero falls with Jolt» |
| `make gates` | rc 0, `БАТАРЕЯ ЗЕЛЕНА`:<br>wikilinks 6902, зламаних 0;<br>ассети 176/176;<br>GDS 126/0 |
| межі: `git diff --stat -- game/data game/project.godot` | лише `game/project.godot \| 1 +` (рядок autoload); `game/data` без змін: `.tres` героїв і ворога, числа бою |
| межі: `git diff HEAD --name-only` | 10 файлів, жодного з `Fighter.gd`, `MatchFlow.gd`, `MoveData`, `CharacterData`, input map |
| бюджет гейта для нової фікстури | `--quit-after 12000`, ліміт 180 с → базовий запуск rc 0 за 33 с |

## Відкрите

- **T6:** огляд кадрів крові High/Medium/Low (кількості, розміри, тривалості — PLACEHOLDER); чи застигає бризок у TIME STOP; B-тіло.
- **T8:** тексти картки й рядків панелі (PLACEHOLDER). Підтвердження в картці кнопкою A геймпада окремо не перевірене (Enter перевірено; A як `ui_accept` перевірено в панелі).
- **T3 (крок 7):** чи лишається Full типовим після звірки рейтингових рядків (`DEFAULT_BLOOD` — одна константа).
- **Santos (T6 № 4):** стерти кров після бою (зараз так) чи лишати.
- **Окремий огляд кадрів не робився**: заходу був потрібен headless-доказ. Вигляд крові на справжньому GPU не перевірено.

## Related

- [[2026-10-07-First-Enemy-Lethal-Fight]] · [[ADR-024-Lethal-Fights-And-First-Enemy]] · [[2026-10-07-Blood-Visual-Language]] · [[02-Combat-System]] · [[Style-Guide]] · [[06-UI-UX]] · [[2026-10-07-Lethal-Fight-Core-Fix]] · [[ADR-004-Physics-Is-Presentation]] · [[state]]
