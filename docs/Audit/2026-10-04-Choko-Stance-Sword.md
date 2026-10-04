# Choko: стійка, меч і передача — аудит T4

2026-10-04. За [[Plans/2026-10-04-Choko-Stance-Sword]]. Одна видима активна зброя та V/R3 підтверджені користувачем; це не дозвіл посилити damage/range. T4 володіє лише аудитом. Godot запускає T1 послідовно.

## Вердикт

**GREEN у межах затвердженої стійки, одного меча та V/R3 передачі. Початкове native відхилення виправлено; остаточні runtime, visual і gates перевірено нижче.** Прочитано план, RigAnimator, IdlePresence, SkeletalRig, Fighter і ресурс Choko. Команди: `sed -n '72,89p' game/scripts/fighter/RigAnimator.gd`, `sed -n '95,149p' game/scripts/fighter/IdlePresence.gd`, `sed -n '195,228p' game/scripts/fighter/SkeletalRig.gd`, `rg -n 'weapon_kind|idle_clip|sword' game/data/characters/choko.tres`.

## Підтверджена відправна точка

Старий capsule меч — BoxMesh0.05×0.95×0.12 на `forearm_r`, без моделі передачі. `_hide_capsules` ховає всі descendant MeshInstance3D, включно з цим клинком; mesh на hero hand немає. Choko має `weapon_kind=sword` і `Sword_Idle`. `_guard_arm` задає руки над плечима на0.18/0.26 arm length. Fighter вже розділяє frozen/hitstop, має hands_busy recovery та одноразовий kick-extract callback; нова передача не повинна обходити ці контракти або повертати rope token.

## Критерії й ризики, передані власникам

| контракт | потрібний доказ |
|---|---|
| Один owner | `sword_hand` змінюється лише на simulation contact один раз; два напрямки, повторна кнопка, відсутність дубля меша. |
| Межа контакту | Влучання/скасування до commit зберігає стару руку, після commit — нову; окремо перевірити exact contact tick і порядок повідомлення про hit. |
| Пауза | Pause/hitstop/freeze не просувають передачу або ownership; resume не програє кнопку з меню. Reset дає праву й очищає всі presentation переходи. |
| Конкуренція рук | Початок лише grounded safe state, без будь-якої busy фази hook. Під час SWAP скіли/гарпун/ручні атаки не запускаються одночасно й не вилітають через6frame buffer на виході. Нога/dash діють за явним правилом переривання. |
| Snapshot атаки | Озброєна/вільна рука визначається на початку конкретної атаки; подальший V/R3 не міняє поточний удар. Legacy/air/crouch/skill/ult шляхи мають узгоджене правило. |
| Бойові дані | Damage/startup/active/recovery/hitbox поля донорів незмінні. Мечова поза не створює прихованого reach бонусу; передача не змінює заряд/довжину/recovery гарпуна. |
| Реальна зброя | Hilt контактує з фактичною hero кистю, scale кінцевого персонажа врахований. Mesh finite, одна видима зброя, neutral wrist, без capsule дубля. |
| Видима передача | Native N−1/N/N+1 біля handoff, R→L та L→R; руків’я без стрибка через корпус, руки справді зустрічаються. Interruption не породжує floating blade. |
| Ульта | Золотий варіант тимчасовий; повернення смарагдового зберігає законного власника, у тому числі interruption/KO/reset. Skea не отримує меч. |
| Стійка | Baseline з/без additive шару front/side/¾; нижчі руки з читаними ліктями й кистями, опора/hips без регресії, Skea збережений. Обидві сторони володіння мечем. |
| Ввід | Реальні V/R3, SHARED collision scan, R3 не змінює look-axis і навпаки; owner UI fence, release-before-repress, відсутність automatic repeat при hold. |
| Приймання | Чисті completion sentinels, `make check-playable`, `make gates`, meaningful негативні контроли, actual-input native кадри. Не прирівнювати finite-transform test до природної анатомії. |

Після узгодження T5 правило24/12 кадрів PLACEHOLDER має порядок INPUT FIRST: якщо interruption приходить при поточному counter11, передача завершується зі старою рукою; counter12 вже committed і лишає нову. Лише якщо SWAP триває після обробки вводу, counter просувається. Тести мають називати спостережений counter, а не неоднозначний «tick12». Runtime результат ще не виміряний.

## Незалежне рев’ю реалізації — триває

T4 прочитав Fighter/InputRouter/LimbMoves, SwordMotion/SwordPresentation, SkeletalRig та нові harness. Лог T1 `/workspace/nooneisreal-env/choko-sword/logs/sword-state.log` містить `SWORD_STATE_COMPLETE checks=795 failures=0`, без ERROR. Це перевірка авторитетної логіки, не прийняття картинки. Harness охоплює справжні V/R3/H/P, UI fences, counter11/12, receive_hit, ноги/dash, freeze/hitstop/pause, busy hook та незмінні combat donors. T4 Godot не запускав.

Передані власникам ризики, до закриття яких приймання лишається YELLOW:

- **Потенційна невідповідність руки authored атакам.** Нові `sword_left/right_hand_*` мають sided procedural motion, але legacy та ульта беруть незмінні Sword_* кліпи. Сам snapshot і прикріплення до лівої кисті не доводять, що саме ліва завдає удар. Потрібні обидва owner для ульти/legacy та активна кінцівка; початковий presentation harness перевіряє лише gold після правої руки.
- **Життєвий цикл additive стійки.** Відновлення збережених owned-bone poses перед seek прибирає накопичення на unkeyed spine; pause/freeze return стоїть раніше. Запитано тривалий цикл, повтор фіксованої фази та незалежний raw/fresh-rig контроль виходу IDLE. Порівняння лише з повторним seek недостатнє: unkeyed залишок збережеться в обох вимірах.
- **Reset і stow.** Початковий SwordPresentation зберігає stow_weight поза reset_for_round. Запитано reset зі схованого меча, повернення в атаку й повну transform-стабільність freeze/hitstop, а не лише стабільну вагу.

Початкові presentation contact та gaze невдачі виправляють власники; повторні clean sentinels, native actual-input кадри й повний suite ще потрібні. Не оголошено природну анатомію чи готовність на macOS лише за unit checks.

## Native відхилення та повторні докази

T4 незалежно відкрив `render/actual/02_V_right_to_left_12_side.png` і `..._threequarter.png` у `/workspace/nooneisreal-env/choko-sword/`. На кадрі12 меч спрямований назад крізь тулуб, голова схилена й плече підняте. Sentinel45/0 доводить виконання fixture, але цей вигляд **відхилено**. Нове приймання потребує exterior траєкторії леза guard→tip, чистого силуету збоку, зібраного погляду, ліктів нижче плечей та відсутності різкого розвороту зброї на виході IK; перевірити обидва напрями й кадри0/11/12/13/24.

Окремо перевірено логи `sword-presentation3.log` (121/0) та `idle-final-target.log` (17484/0). Mirror authored Sword_* тепер має restore unkeyed rotations перед seek, reset очищає stow/handoff, freeze/pause мають повний earlyreturn. 720-frame gaze стабільний близько−11°, додані fixed-phase repeat і fresh-rig negative controls. Ці виправлення закривають відповідні початкові ризики, але не виявлену native проблему передачі. Запитано також actual endpoint доказ mirrored руки, а не лише непорожній cache.

## Остаточне приймання T4

Початковий RED закрито. T4 переглянув фінальні `03_left_idle_threequarter.png` і `06_R3_left_to_right_12_side.png`, а перед остаточним калібруванням — обидва contact-напрями. Є один видимий смарагдовий меч, клинок спрямований назовні та вгору під час handoff, попередній прохід назад через тулуб прибрано. Відхилені попередні кадри не є фінальними доказами.

Калібрування лівої кисті враховує aligned hand rests, віддзеркалення сагітальною площиною і переворот симетричної осі ширини зброї; hand offset віддзеркалено тим самим способом. Це виправило legacy left-light frame7 з0.1199м до0.1780м до core (right0.1793м), не рухаючи бойові hitbox. Тест порівнює реальні mirrored endpoints/осі, а не лише наявність helper-cache. Probe40/0 перевіряє centerline проти спрощеного torso/head core0.13м у вибраних кадрах; **це не гарантія відсутності перетинів усієї поверхні леза зі skinned mesh в усіх анімаціях**.

Фінальні логи `/workspace/nooneisreal-env/choko-sword/`, прочитані T4:

| доказ | результат |
|---|---|
| `regression-final/sword-state.log` | 797 перевірок,0 failures |
| `regression-final/sword-presentation.log` | 228 перевірок,0 failures |
| `regression-final/idle.log` | 18114 перевірок,0 failures; довгий цикл, fixed-phase і fresh-rig negatives |
| `logs/actual-sword-final.log` | 45 знімків,0 failures; очікуваний VSync warning software-renderer |
| `logs/sword-clearance2.log` | 40 sampled cases,0 core intersections |
| `logs/check-playable-final.log` | smoke164 перевірки/19824 frames;32 сценарії,0 failures |
| `logs/gates-final.log` | БАТАРЕЯ ЗЕЛЕНА;59 GDS,0 parse failures |

T4 окремо просканував усі23 positive scenario logs: немає ERROR або SCRIPT ERROR. Ще9 сценаріїв є очікуваними негативними контролями, тому rc1 для них — pass за контрактом runner. Godot запускав T1, не T4. `git diff --check` без зауважень.

Відкритих блокерів у цьому scope немає. Межі: stylized procedural вигляд, спрощене stow повернення й геометрична proxy-перевірка; немає твердження про реалістичні м’язи, всі можливі skin intersections або продуктивність/керування на фізичному MacBook Air M3. Ці межі не розширюють поточний PR.

## Related

- [[Plans/2026-10-04-Choko-Stance-Sword]] · [[Audit/2026-10-04-Harpoon-Inventory-Ropes]] · [[Characters/Choko]] · [[02-Combat-System]] · [[03-Skills-Framework]] · [[05-Platforms-Input]] · [[ADR-004-Physics-Is-Presentation]] · [[constitution]]
