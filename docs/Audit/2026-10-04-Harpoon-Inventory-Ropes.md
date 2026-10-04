# Запас гарпунів, залишені мотузки й наведення — аудит T4

2026-10-04. Окрема фаза за [[Plans/2026-10-04-Harpoon-Inventory-Ropes]]. Позитивні результати [[Audit/2026-10-04-Free-Movement-Limbs]] належать попередній основі, а не новому обліку7/2 чи persistent ropes. T4 не змінює гру; Godot запускає лише T1 послідовно.

## Вердикт

**GREEN для перевірених технічних контрактів фінального diff; YELLOW загалом для суб’єктивної якості, фізичних пристроїв та зазначених нижче меж. Відкритих блокерів цього рев’ю немає.** На початку цієї фази власне читання `GrappleHook.gd` підтвердило старі `max_charges=3`, `reset()` повністю відновлює заряди, `tick_regen()` додає їх за таймером, окремого match registry немає. Це відправна точка, не виконання нового контракту. Команди: `cat docs/Plans/2026-10-04-Harpoon-Inventory-Ropes.md`, `rg -n 'charges|reset|rope|aim' game/scripts/grapple/GrappleHook.gd`, `git status --short`.

## Передані ризики й критерії

| контракт | потрібний доказ |
|---|---|
| Облік7/2 | На кожному переході `available + shot/recovery + deployed == capacity`; ціле число у межах0…capacity. Жоден старий timer regen не створює предмет з нічого. |
| Єдиний refund | Token і його owner незмінні; повтор callbacks, interruption після extract, kick на першому active та round reset не повертають заряд двічі. |
| Round / match | Round reset зберігає deployed і витрату; unfinished recoverable shot повертається один раз. New match очищає registry й відновлює запас. Старі node references/tokens не протікають у новий матч. |
| Спільна мотузка | P2 може зачепитися за P1 rope навіть із0 available; це не створює deployed duplicate, не переносить право refund і не змінює жоден запас. Поведінка одночасних двох користувачів визначена. |
| Recovery | Промах/переривання не дають нового launch до завершення recovery; частково повернена довжина зберігається після ухилення/оглушення. Release/repress не скидає дистанцію заради instant refund. |
| Enemy extraction | Руки не атакують під час зайнятості; ноги працюють. Charge повертається рівно на першому active кадрі kick або на визначеній події звичайного витягання. Перерваний startup ще не є successful extraction. Hitbox/damage лишаються бойовими даними. |
| Q/E та пад | Фізичні Q enemy/E parkour, Y+RT/Y+LT окремі; старі SHARED Q/E skills переміщено явно. Немає подвійного fire через legacy virtual grapple; усі нові кнопки під UI fences. |
| World aim | Input містить записуваний world intent. Replay з тією самою послідовністю не читає новий camera transform. UI/manual aim/reset не залишають stale device state. |
| Candidate cue | Показана ціль відповідає тому самому mode/range/hand-to-target LOS, який застосовує launch. Укриття перед ближчою ціллю не рекламує гарантоване влучання. |
| Decorative rope | Стала верхня межа nodes/segments/iterations; finite points, reset cleanup. Сегменти не вирішують hit, inventory, authoritative length. Visual on/off дає однаковий simulation результат. |
| Реальне зображення | Native actual-input miss→water→rewind, interrupt→resume, leave→foreign reattach, enemy hit→kick extraction. Manual pose replay сам по собі цього не доводить. |
| Регресії | Чисті completion sentinels, `make check`, попередні27 плюс нові сценарії, `make gates`; runtime/SCRIPT ERROR не ховаються за expected assertion. |

Ці ризики передано власникам hook/input/aim/motion через coordination messages до реалізації. Числа декоративної мотузки та ручної камери залишаються PLACEHOLDER до заміру; фізичний M3 і тривалий playtest не підміняються llvmpipe capture.

## Проміжне рев’ю реалізації

T4 прочитав `MatchRopes.gd`, `GrappleHook.gd`, `HarpoonAim.gd`, зміни Fighter/Hud/камер та бойовий harness. Ledger відділено від декоративних nodes: issue створює owner token, refund не приймає чужий чи deployed token, round reset повертає лише unfinished, foreign reuse стоїть перед перевіркою available. Живий Arena створює registry на час матчу; новий Arena має новий registry. World aim зберігає point/target_id, а HUD `capture(..., false)` не змінює hysteresis на render FPS. Shared mode manual orbit наразі вимкнений, це явно обмежена реалізація.

**Передані блокери рев’ю, виправлення очікуються:**

1. `ENEMY_EXTRACT` звичайний45f таймер працює під час startup удару ногою. Пізній kick може отримати refund до first active та втратити extraction event. Потрібен тест із пізнім kick через реальні simulation ticks, а не ручне встановлення `move_frame=startup`.
2. `recovery_paused` пропускає `STUMBLE` і `WALL_SPLAT`: remaining length змінюється під час цих incapacitated states. Власнику передано додати стани й перевірку.
3. `fire(false)` повторно зачіплює будь-яку nearby rope ще до capture/recorded aim. HUD може показати передню нову anchor, коли постріл фактично чіпляється за стару мотузку позаду. Manual/snapshot selection має бути одним джерелом для cue та launch.
4. Hud candidate cue жорстко показує Q/E, хоча погоджений SHARED P1 має T/R зі збереженими Q/E skills. Потрібна актуальна прив'язка або нейтральна назва дії.

**GREEN тільки для прочитаних цільових результатів, не закриття пунктів вище.** Власні команди T4: `cat`, `rg` по `/workspace/nooneisreal-env/rope-inventory/logs/`; harpoon46/0, input170/0, comfort31/0, aim16/0, recovery-motion284/0, rope-visual24730/0 (17points, wet14water entries). Пошук ERROR/SCRIPT ERROR/WARNING у цих шести позитивних логах порожній. Широкий `check-playable.log` має PLAYABLE30/0. Це прогони до виправлення щойно знайдених edge cases; вони не перевіряли описану late-kick/cue mismatch поведінку. Godot виконував T1 централізовано.

## Повтор критичних edge cases

Власне читання коду після виправлення та `logs/harpoon-final.log`: **55/0, чистий**. Знайдені пункти1–3 закрито вузько: ordinary extraction timer не випереджає committed leg; STUMBLE/WALL_SPLAT/INTRO входять до pause; fire спершу бере recorded/captured snapshot і повторно використовує лише обрану deployed rope. Додатково заміна живого hook скидає його старий стан, а reuse не збільшує мотузку понад original length/range. Контракт SHARED збережено без колізій: SOLO Q/E, SHARED P1 T/R, P2 O/I; регуляри Q/E залишаються skills. Candidate labels ще очікують повтору.

**Окрема UX-межа ручної камери:** manual orbit/aim не перебудовує `DuelFrame.human_to_world`; новий жест руху досі використовує simulation arena basis, не нову орієнтацію камери. Це не можна описувати як повністю camera-relative movement. T4 рекомендував наступний обмежений крок: записуваний basis як input intent на початку жесту, зафіксований до нейтралі, зі спеціальними90°/180°/replay тестами; не читання smoothing-camera кожний simulation tick. Поточний вердикт не зараховує цю майбутню зміну.

## Native діагностика й доданий input basis

T4 відкрив `render/actual/02_release_persistent.png`, `03_foreign_Y_LT_reuse.png`, `04_Q_enemy_extract.png`, `05_kick_extract_active.png` та прочитав telemetry. Видно залишену мотузку й повторне використання Skea без витрати2/2; enemy extraction переходить6/7→7/7 на kick. Але весь цей перший capture **відхилено**: `actual-inventory.log` має runtime `clear_view_basis` mismatch через старий завантажений autoload і10shots/2fail. `06_miss_water_rewind` у telemetry вже phase0/remaining0, а07interrupt немає; самі назви PNG не доводять rewind. Передано власнику зробити чистий capture стабільного diff із phase4/remaining>0 та paused-length assertion.

Пункт4 cue labels виправлено в коді через `InputRouter.binding_label`, дві підказки більше не приховуються раннім return. Root окремо затвердив bounded movement-basis input: `DuelFrame` бере normalized forward packet тільки на початку SOLO P1 gesture; recorded playback блокує live publication, UI/profile/disconnect/control lock очищають packet. T4 прочитав real-W90°/180°, held invariance, replay під трьома camera yaw, malformed/vertical packet та CPU/shared tests. Runtime повтор ще очікується; попередня UX-межа вище описує стан ДО цього доданого виправлення.

## Кінцеве приймання

**GREEN, повний фінальний прогін.** Власними командами T4 прочитано `rope-inventory/logs/check-playable-final.log`: smoke164/19824 frames, PLAYABLE30/0. Переглянуто всі30 `regression-final/*.log`:21 позитивний без ERROR/SCRIPT ERROR,9 negative відмовляють очікувано. Ключові фінальні результати: harpoon55, input177, movement54, aim21, recovery284, rope geometry24732, foot774, gait630, limb combat2950 — усі0fail. `logs/gates-final.log`:57 GDS/0 parse errors та БАТАРЕЯ ЗЕЛЕНА. Власні статичні команди: `git diff --check` чистий, wikilinks4369/0 broken. Godot виконував T1 послідовно; це незалежне читання його артефактів, не власний engine запуск аудитора.

**GREEN, lifecycle нового basis.** UI history тепер синхронно очищає також latch у DuelFrame. Тест закриває випадок: pause→release→resume→fresh press без жодного Fighter tick під час паузи; нова W отримує новий packet, а утримана W після UI не рухає. SOLO new gesture90°/180°, held gesture invariance, replay packet при різних camera yaw, invalid/vertical vectors, profile/disconnect/control lock та CPU/shared isolation підтверджені54/0. Cue labels використовують реальну binding для SOLO/SHARED/геймпада, aim21/0. Попередні чотири review findings закрито.

**GREEN, реальні native події.** `logs/actual-inventory.log`: ACTUAL_INVENTORY_COMPLETE11shots/0fail, без engine errors; лише відоме llvmpipe V-Sync warning. T4 відкрив фінальні06/07/09/11 та раніше01–05, прочитав telemetry. E: Choko6/7, deployed1; release зберігає запис; Y+LT іншого гравця: Skea2/2 при тій самій мотузці. Q: extraction phase5/6зарядів; kick active повертає7/7 і прибирає pending token. Miss: phase4/6зарядів/remaining12.2000m; наступний dash кадр також phase4, pending12.0500m; helper окремо перевірив незмінність довжини протягом двох DASH ticks. Завершення дає phase0/7зарядів/records0. На кадрі є висячий/провислий канат, foreign attachment, kick, водяний rewind, реальний dash і кандидат із відповідною клавішею; mouse/right-stick змінюють ручний ракурс. Діагностичні fixture placement/camera явно підписані; hook phases не підставлені. Раніші збої capture та неправильна synthetic LeftShift location виправлені й не зараховані як PASS.

**YELLOW, межі приймання.** Пакети input/aim дозволяють записувати й відтворювати намір, але цей diff не додає повний мережевий transport чи готову систему збереження реплеїв. Наведення/ручний orbit — SOLO P1; shared manual orbit не прийнято. Немає виміру FPS/Retina на M3 або фізичного геймпада, слухового й тривалого playtest. RopeVisual має16сегментів/4ітерації, спрощене дно/воду й не моделює анатомічні м'язи; декоративний канат не визначає шкоду. Довгі gamepad cue labels перевірені у фінальному центральному кадрі; повний edge-clamping усіх позицій viewport лишається дрібним UX боргом. Це не блокер перевірених механік і не обіцянка остаточної візуальної поліровки.

## Related

- [[Plans/2026-10-04-Harpoon-Inventory-Ropes]] · [[Audit/2026-10-04-Free-Movement-Limbs]] · [[Research/2026-10-04-Harpoon-Aim-Rope]] · [[ADR-004-Physics-Is-Presentation]] · [[02-Combat-System]] · [[05-Platforms-Input]] · [[constitution]]
