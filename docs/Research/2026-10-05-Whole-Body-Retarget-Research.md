# Рух усього тіла: анатомічний ретаргет, стопи й вторинні рухи

2026-10-05 · T3 Архімед · аудит source **`3df43a5`**, PR #178 ще не змерджено на момент доручення. Файли й versioned Godot4.7 API прочитано в цій сесії; production не змінювався. Native contact-виміри виконує окрема foot/audit смуга — наведені тут GLB-числа є читанням source, не симуляцією на M3.

## Висновок

У грі вже є ретаргет усього тіла, distance-driven gait, authored dodge/landing і аналітичні дволанкові IK. Найменший обґрунтований крок — **анатомічне калібрування чинного ретаргету + явні contact phases стоп + один упорядкований шар малих spine/head корекцій**, зі збереженням authored pelvis і фізичного руху героя. Купівля додаткових анімацій чи повна заміна animation graph не потрібна для цього виправлення.

Важливі розмежування: ankle/toe endpoint не дорівнює нижній поверхні черевика; напрямок кістки не визначає її twist; правильна довжина кінцівки не доводить природну позу. Root-motion API не створює відсутній у source root travel.

## Що реально є в репозиторії

GLB JSON chunks прочитано без запуску Godot; тривалості — максимум input accessor анімації. Повний inventory з SHA-256 кожного asset збережено поза checkout у `/workspace/nooneisreal-evidence/whole-body-motion/source_inventory.json`.

| Asset | Факти з GLB |
|---|---|
| `game/assets/animations/ual/UAL1.glb` | 120 анімацій, 65 skin joints, 21378992 B |
| `game/assets/animations/ual/UAL2.glb` | 134 анімації, той самий список із65 skin joints, 20717364 B |
| `choko_m0.glb` | 24 skin joints, 1 власна анімація, 5240128 B |
| `skea_m1.glb` | 24 skin joints, 1 власна анімація, 6131300 B |

У `SkeletalRig.HERO_BONES` є22 відповідності. `head_end` і `headfront` лишають rest, використовуються як anatomical reference; у Meshy немає UAL finger chains. Ланцюг корпусу має зворотну нумерацію: **Meshy Spine02 → UAL spine_01, Spine01 → spine_02, Spine → spine_03**. Звичайне сортування імен за номером тут дасть неправильний порядок.

`Head` не має окремого запису в `HERO_AIM`, тому під час setup успадковує alignment батьківської шиї. Цього достатньо для перенесення rotation, але воно не калібрує фактичний Meshy face vector `headfront − Head`. Чинна `_align_attack_gaze()` натомість обмежує вже анімований world pitch до−20°…+15°; якщо вся source дуга опиняється нижче нижньої межі, весь кадрований рух зводиться до сталої межі. Це властивість коду, не бажана анатомічна стабілізація. Координатор повідомив про native saturation і нижній gait gaze; числові результати його trace тут не дублюються як мої виміри.

| Потреба | Уже наявні raw GLB clips і тривалість |
|---|---|
| Хода | UAL1 `Walk_Loop`1.333s; UAL2 backward/left/right/diagonal Walk1.333s |
| Біг | UAL1 `Jog_Fwd_Loop` та directional Jog0.933s; `Sprint_Loop`0.667s, `Sprint_Enter`0.867s, `Sprint_Exit`1.667s |
| Стрибок/контакт | `Jump_Start`1.333s, `Jump_Loop`2.5s, `Jump_Land`1.267s |
| Ухилення | `Dodge_Left`, `Dodge_Right` по1.3s; це source довжина, не gameplay dodge duration |
| Погляд/розмова | `Idle_LookAround_Loop`4.6s, `Idle_Talking_Loop`2.933s, `Sitting_Nodding_Loop`2.933s |
| Жести | UAL2 `Yes`2.5s, `Idle_No_Loop`2.5s, `Idle_FoldArms_Loop`2.5s |
| Поворот | UAL1 `Turn90_L/R`2s; UAL2 `Turn180_L/R`1.667s |

Це наявність кліпів, не дозвіл одночасно програвати їх поверх будь-якого стану. Наприклад, sitting nod не варто переносити цілком на героя, який біжить. Чинний `clip_name()` прибирає `_Loop` після імпорту; UAL2 додається як бібліотека `ual2/`. Новий selector повинен використовувати це зіставлення, а не raw names напряму.

Ліцензія UAL у [[Textures-Registry]] — CC0 1.0, Source придбано Santos2026-10-03. Сам `License.txt` придбаного zip не знайдений/не перечитаний у цьому checkout, тому незалежного повторного ліцензійного приймання архіву тут немає. Нових assets або ліцензій не пропонується.

## Чинний ланцюг та його межі

`SkeletalRig` вручну seek-ає прихований UAL AnimationPlayer у physics time. Після authored pose і donor overlays сигнал `skeleton_updated` запускає ретаргет на Meshy. Для кожної mapped bone переноситься rotation-from-source-rest × rest alignment × hero rest; local rotation обчислюється через inverse parent rotation. Довжини hero bones зберігаються; лише root Hips position бере donor pelvis delta × `_hip_scale`. Окремий `_gait_scale` вимірює world leg length для cadence — його не слід підміняти співвідношенням висоти таза.

Поточний порядок: restore попередніх overlays → source clip/locomotion blend → authored combat/dodge/hook/sword/idle → hero retarget → lowhand contact → moving landing → hook hands → attack gaze → вузький `HeroFootContact` → sword transfer. Це вже кілька власників тих самих кінцівок: ще один незалежний `_process` із IK може перетерти попередню роботу.

Source findings:

- `Quaternion(dh.normalized(), ds.normalized())` вирівнює одну вісь кістки. Обертання навколо цієї осі геометрично лишається додатковим ступенем свободи. Чинний `aim_error()` порівнює напрями і не бачить twist; потрібні calibrated secondary axis/roll, площина коліна/ліктя і напрям face/sole, а не лише менший aim angle.
- `HeroFootContact` навмисно підтримує crouch, hook windup і окремі lowhand attacks. WALK/IDLE він не покриває. Surface у `penetration()` — WaveField або y=0; це не raycast до міського тротуару/даху. Додавати його до всіх станів без зміни surface contract не можна.
- Поточний helper уже читає реальні skinned shoe vertices, але виправляє лише penetration до bounded0.25m; це не plant/release policy. Загальний foot lock має відпускати swing foot і не тягнути стрибок до землі.
- `AuthoredLandingMotion` зберігає **цього кадру** hero gait ankles під час невеликого hip compression. Це правильне відокремлення landing від freeze обох ніг, але не доказ нульового world slip протягом stance.
- `AuthoredCombatMotion._solve_chain()` зберігає bone lengths й ankle/wrist rotation, clamp-ає недосяжну дальність; near-collinear bend повертає без solve. Це bounded analytic IK, а не whole-body optimizer. Перехід через майже пряме коліно потребує стабільного pole, не випадкової нової осі.
- `gait_check.gd` вимагає slip менше40% від старого fixed Walk; це відносне покращення. Воно явно не заявляє absolute plant. `measure_gait.py` оцінює source stance за envelope3cm — provisional calibration, не collision evidence. Саме ці два різні мірила не можна змішувати.
- `IdlePresence` уже має малі spine/neck counter-rotations, приватний phase, freeze/hitstop guards і restore для unkeyed tracks. Дублювати breathing/random head jitter поверх нього не потрібно; спершу узгодити, хто володіє upper-body шаром у кожному стані.

## Перевірені конвенції Godot4.7

Джерела — офіційний tag **4.7-stable**, [MIT LICENSE](https://github.com/godotengine/godot/blob/4.7-stable/LICENSE.txt).

Наявність `TwoBoneIK3D`, `RetargetModifier3D`, `LookAtModifier3D`, `SkeletonModifier3D`, `SpringBoneSimulator3D` додатково підтверджена реальним `ClassDB.class_exists()` на встановленому Godot4.7-stable,5/5true, rc0. Ізольований мінімальний проект/журнал: `/workspace/nooneisreal-evidence/whole-body-motion/api-verifier/result.log`. Перший запуск без writable XDG cache аварійно завершився до probe; повтор із власними data/config/cache пройшов. Це перевірка доступності API, не їх інтеграції у гру.

| API | Перевірений контракт і наслідок |
|---|---|
| [Skeleton3D](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/Skeleton3D.xml) | `get_bone_global_pose()` — **skeleton space**, не world. World endpoint = `skeleton.global_transform * bone_pose.origin`; world target назад — `affine_inverse()`. Final pose може змінюватися deferred modifiers; для відповідного final результату API рекомендує modifier completion signal. |
| [SkeletonModifier3D](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/SkeletonModifier3D.xml) | Виконується після AnimationMixer playback; child Skeleton3D. У4.7 рекомендований `_process_modification_with_delta()`, старий callback deprecated. Не множити власні rotations на `influence` вдруге — Skeleton застосовує його сам. Callback може прийти з delta0, тож не ділити на нього й не просувати secondary clock. |
| [TwoBoneIK3D](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/TwoBoneIK3D.xml) | Штатний analytic intersection-of-two-circles solver, явний pole target; не ітеративний важкий full-body IK. Pole direction не має бути collinear forward. Якщо між root/middle/end є додаткові bones, їх rotations ігноруються, відстані трактуються як virtual bones. Не вмикати без калібрування elbow/knee plane. |
| [LookAtModifier3D](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/LookAtModifier3D.xml) | Для neck+head parent modifier мусить бути раніше child. `forward_axis` задається явно; default+Z не дорівнює автоматично Meshy face direction. `relative` визначає pose-relative чи rest-relative поведінку. Є angle limits і попередження про flip за межами допустимого сектора. |
| [RetargetModifier3D](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/RetargetModifier3D.xml) | Пише child skeleton pose під час parent update; post-retarget правки мають бути child modifiers. **`use_global_pose=true` потребує однакових bone lengths**, інакше примусово стискає/розтягує їх. Це небезпечна default заміна нашого пропорційно відмінного Meshy ретаргету. Local rotation/profile варіант потребує зіставлення bone names/profile. |
| [AnimationMixer root motion](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/AnimationMixer.xml) | `root_motion_track` скасовує visual transform обраного bone track і віддає delta/accumulator; неверний type/path дає нуль. Це extracted movement, а не foot solver. У source Walk/Jog_Fwd/Sprint/Jump_Land реально виміряний translation span bone`root` **[0,0,0]**. Extraction звідти не створить travel; selection pelvis може прибрати authored weight shift. Gameplay/Fighter тут має залишитися єдиним авторитетом руху. |

`SpringBoneSimulator3D`, описаний у [[2026-10-05-Local-NPC-Models-And-Physics-Reuse]], годиться насамперед декоративним hair/tail/cloth chains. Для опорної ноги або контролю погляду це інше завдання; додавання spring на весь spine не гарантує анатомії чи stabilised gaze.

## Три реалістичні альтернативи

| Варіант | Що повторно використовуємо | Вартість/межі | Оцінка |
|---|---|---|---|
| **A. Чинний retarget + calibrated axes + stance metadata + existing analytic IK** | Усі254 UAL, HERO_BONES, distance cadence, існуючі restore/freeze/двокісткові solves | Потрібні локальні дані roll/pole/sole для двох героїв, bounded contact state та surface query. Без native plugin/нових assets; runtime кілька коротких chains, але кількість raycasts/sole samples треба виміряти. | **Рекомендований перший пілот**: найменший ризик для вже перевірених gameplay/rope/weapon контрактів. |
| **B. Чинний clip/retarget + native TwoBoneIK3D/LookAtModifier3D у явному modifier graph** | Godot4.7 MIT, ті самі UAL/Meshy; штатний solver/pole/influence | Нуль додаткового package size, але це міграція порядку запису pose. Потрібні target/pole nodes, callback/freeze parity та точна forward axis; не запускати одночасно два foot solvers на одній нозі. | Хороший ізольований прототип, якщо потрібне редагування targets у сцені; не автоматичне покращення проти нашого analytic solve. |
| **C. Offline bake обраних UAL→кожен hero + малий runtime contact/secondary шар** | Наявні CC0 clips і Meshy models, поточний retarget як bake input; без сторонньої бібліотеки | Можна перевірити anatomy заздалегідь і прибрати частину щокадрового donor work. Ціна — дублікати animation data на2героїв, bake tool/asset provenance й повторний bake при зміні rig. Не bake-ати всі254 без потреби; заміряти export size. | Доцільно для стабільного невеликого набору gait/idle після доведення calibration; дорожче зараз, ніжA. |

Godot-native рішення мають MIT engine license, існуючі UAL — за поточним реєстром CC0; жоден варіант не скасовує provenance Meshy-моделей. Ліцензії стороннього нового коду не додаються. Твердження про runtime cost — структура алгоритму, **не вимір FPS** чи обіцянка швидшого M3.

## Рекомендований bounded експеримент і приймання

Почати з Choko та Skea на flat/elevated floor: Idle, forward/side/back Walk/Jog, stop/turn, landing. До зміни зафіксувати source phase та final hero vertices. Offline calibration формує contact windows із мінімуму foot/toe height і source trajectory, із ручною перевіркою transition edges; threshold3cm з наявного script — лише стартовий кандидат. Для in-place gait низька world velocity donor foot **не** є універсальним stance detector: опорна стопа рухається назад відносно нерухомого source root.

У runtime: authored whole-body pose → невелика body/neck counter-motion → retarget з calibrated anatomical frames → контактні корекції → bounded hand target → final gaze/props у єдиному погодженому порядку. Якщо body correction змінює pelvis після foot solve, розв'язок стоп уже застарів. Plant target зберігати у world або local space фактичної moving support, а не у вчорашньому skeleton space; release за clip phase/state/дальністю, без teleport і без зміни фізичної капсули. При teleport/hero switch/airborne/freeze потрібні явні reset/hold правила.

Для head/spine: перевіряти `headfront` як фактичний напрям обличчя; розподіляти невелику відповідь між нижнім/верхнім spine та neck/head, зберігаючи authored pelvis arc. Контрольований bounded lag від швидкості повороту/прискорення може бути кориснішим за додаткові незалежні синуси. Амплітуди/частоти/limits — art tuning, їх слід позначити provisional і оцінити в повному циклі. Attack/hook authored contacts мають вищий пріоритет за декоративний gaze; не перетирати нинішню `_align_attack_gaze()` другим нерозпізнаним шаром.

Спершу виправити **сталий rest/reference face offset**, а не збільшувати clamp range чи додавати spring. Після зіставлення координат знайти відкалібрований reference frame голови `G_ref`, що узгоджує face/up і neck chain. Переносити source animation delta як `G_hero(t) = D_source(t) × G_ref`, потім переводити через inverse поточного parent rotation у local pose. Усі множники мають бути в одному model-space базисі; це уточнення наявного retarget, не універсальна формула для довільних різних global transforms. Така стала калібровка зберігає часову дугу authored head/neck delta. Окремі м'які limits можна залишити лише для справжніх крайніх поз; acceptance має рахувати clamp saturation та preserved angular range, а не лише факт потрапляння в межі.

Для scaled Meshy кешувати anatomical rest data й один узгоджений current world transform/inverse на pose pass. World target переводити `affine_inverse()`, displacement — inverse basis без втрати масштабу; не віднімати world metres від centimetre-space bone coordinates. Rest lengths/poles/sole offsets кешуються при setup або зміні skeleton, а current contact transform — при актуальній позі. Це важливіше за заміну чинного аналітичного solver штатним лише заради назви.

Приймання не обмежувати angle-to-child тестом: world drift стопи **під час оголошеного stance**, skinned sole clearance/penetration до фактичної поверхні, knee/elbow pole continuity, bounded bone-length error, headfront pitch/yaw та angular velocity, absence of pose accumulation при repeat-seek, stop/turn/landing transitions. Окремо — незмінні Fighter position/velocity/stamina/frame timing/RNG і rope/weapon endpoints у frozen/paused стані. Числові дозволені межі треба обрати після baseline foot-аудиту; нових «нормальних сантиметрів» без вимірів тут не оголошено.

NPC procedural pivots не мають автоматично hero Skeleton3D contract. Новий NPC feature rewrite до цього аудиту не входить; застосовувати загальні принципи whole-body support й hierarchy можна лише після окремого зіставлення його visual rig. Результати й source caveats передані combat та foot/audit смугам.

## Уточнення калібрування за фактичним trace

Прочитаний combat trace `/workspace/nir-hook-motion/head-calibration.log` показує межу самої сталої rest-корекції: для Skea jab після калібрування лишається приблизно−26.88°…−20.11°, lowhand−71.66°…−61.82°. Попередній final gaze був−20° у всіх15/19 sampled frames відповідно. Це виміри combat probe, не мій повторний native capture. Rest calibration прибирає сталу похибку face frame, але source posture також дивиться вниз. Тому потрібне перевірене м'яке перетворення pitch із ненульовою часовою похідною і розподілом neck/head; константний offset сам не розв'язує весь дефект. Точні амплітуди нового helper лишаються provisional до native приймання.

## Семантика callback: джерело й ізольований вимір

Перевірено [Skeleton3D implementation4.7](https://github.com/godotengine/godot/blob/4.7-stable/scene/3d/skeleton_3d.cpp) і [header/default mode](https://github.com/godotengine/godot/blob/4.7-stable/scene/3d/skeleton_3d.h). `advance(delta)` накопичує modifier delta та ставить deferred update; кілька advance до flush можуть об'єднатися. `skeleton_updated` надсилається після pose/modifier update, до оновлення skin bindings і відновлення backup poses. Це сигнал оновлення pose, не гарантія одного виклику на physics tick.

Engine-only probe: `/workspace/nooneisreal-evidence/whole-body-motion/api-verifier/signal_check.gd`, журнал `signals.log`. Один Skeleton3D/одна bone, modifier навмисно змінює її кожного свого update; реальні сигнали, без `emit_signal()` чи примусової notification. Godot4.7 headless,60Hz physics, короткі≈1s windows після warmup, rc0:

| Modifier mode / max FPS | Physics ticks | Реальні signals | Максимум signals за physics tick |
|---|---:|---:|---:|
| Idle /30 |60|30|1|
| Idle /120 |60|121|2|
| Physics /30 |62|62|1|
| Physics /120 |61|61|1|

Два manual `advance(0.01)` і `advance(0.02)` до deferred flush дали один modifier callback із delta0.03. Точна кількість ticks у часовому window залежить від scheduler; тут важливі семантика coalescing і можливість кількох idle updates за physics tick. Headless достатньо для цього API-доказу; оцінка зображення потребує native renderer.

**Це не знайдений FPS-баг чинного Fighter.** У грі AnimationPlayer seek вручну dirty-ить skeleton із physics. Незалежний T4 actual-Fighter baseline при30/60/120 FPS повідомив482 callbacks на480 physics frames з урахуванням initialization, без природних повторів і з точно нульовою різницею pose на спільних physics frames. Engine fixture спеціально має інший producer updates; переносити його121 callbacks на гру неправильно. Нові helper треба повторно перевірити після freeze, а не оголошувати заздалегідь виправленням FPS-регресії.

Контракт нових helper розділяє `begin_frame/update` у physics після freeze guard і повторне застосування до свіжого retarget. Clock, contact history, plant/release і surface queries просуваються один раз за serial. Повторний callback може повторно розв'язати pose з кешованими targets: просто пропустити весь solve неправильно, бо новий retarget уже міг стерти попередню корекцію. При низькому display FPS owner має забезпечити capture кожного потрібного physics frame, а не покладатися лише на deferred display callback. Це захист контракту, а не твердження про вже виміряну регресію.

## Підготовлений bounded вимір вартості

Raw GLB inventory `/workspace/nooneisreal-evidence/whole-body-motion/sole_source_counts.json` порахував shoe vertices за сумарною foot/toe weight≥0.5. Це source topology, ще не замір нового runtime helper:

| Hero | Left / right vertices | Разом vertices | Positive skin influences |
|---|---:|---:|---:|
| Choko |1301 /1402|2703|6072|
| Skea |1220 /1227|2447|5589|

Отже бюджет «два raycasts» не описує всю ціну: точна skinned sole перевірка проходить тисячі samples та weights, а повторні pose passes можуть множити цю роботу. Потрібно кешувати rest/sample inventory при setup і current world transform/inverse один раз на pose pass; getter transform усередині кожного vertex loop зайвий. Це не привід заміняти реальну підошву радіусом ankle без геометричного приймання.

Після **явного freeze власників** протокол: ізольований imported snapshot, Choko і Skea послідовно; flat idle, forward/side gait, elevated support, landing та airborne skip. Початковий bounded бюджет —30 warmup і120 measured physics frames на scenario. Заміряти перший повний pose pass та три повторні застосування до свіжого retarget із тим самим serial, без повторного `begin_frame`. Звітувати median/p95/max microseconds, відокремивши setup/import/render; це Linux workspace CPU, жодного висновку про M3.

Знімати `begin_frames`, `apply_calls`, `cache_hits`, `query_count`, `pose_reads`, `sample_count`, captures/history/rejected counters. Приймання: не більш як два surface queries за eligible physics serial; повтор не просуває history/clock і не додає rays; airborne skip не шукає ground; rest/sample cache не перебудовується щокадру. Повторний FK/solve для свіжого retarget допустимий, але його вартість треба показати окремо. На момент цього доповнення candidate performance не запускалася: власники ще змінюють helper, чисел швидкодії або M3 FPS немає.

## Ранній CPU baseline і точна оптимізація, 2026-10-05

Координатор окремо дозволив **ранній candidate snapshot до фінального freeze**, щоб не пропустити суттєву вартість нового full-skin контакту. Вимір виконаний у власних ізольованих проектах, production не змінювалася. Baseline — exact`3df43a5`; early candidate — копія робочих source files, manifest SHA256`c29d152e312ac2c9ec383269522e7582204af045726f47de9bd29673924b08f0`. Baseline manifest SHA256`0b00916f5e1edc7476069c9c466bb22953b9c8817b83890ad004b214b0f40a4e`. Optimization1 — та сама candidate копія, замінено **тільки** `HeroGroundContact.gd`, SHA256`fef87a4c2743dfc6f4733b3a5892b60411a503b049899318c535744f444422ce`. Це не фінальний committed build.

Godot4.7 headless, Linux x86_64 / AMD EPYC9V74,5 доступних logical CPUs. Послідовні запуски, власні writable XDG; інші агенти могли навантажувати спільний host. На кожний hero/scenario30 warmup+120 measured physics frames. Fixture задає реальні Fighter/Rig state і траєкторію3m/s, викликає animator tick та physics presentation; це **не** повний ігровий input/AI/render benchmark. Сценарій `walk` фактично обирає `Jog_Fwd`; idle — `Sword_Idle` Choko/`Idle` Skea, hang — повітряний GRAPPLE/HANG. Flat collider — box на y=0. Water — default WaveField, `use_z=true`, reset перед case, tick кожен physics frame, body.y дорівнює фактичному height.

Ізольовані timing wrappers додають лише вимір `SkeletalRig._physics_process` і `_on_mannequin_updated`. **Total = physics time + callback time поза physics**, без подвійного рахунку вкладеного retarget. Import/setup, animator tick, gameplay simulation, render/GPU сюди не входять. Час у таблицях — **median / p95, microseconds**. Шум host особливо видно у Choko idle; медіани не доводять гарантованого frame budget. Це не FPS чи M3-приймання.

| Solid plane | Baseline | Early candidate | Optimization1 |
|---|---:|---:|---:|
| choko idle | 451 / 2950 | 5401 / 7996 | 2402 / 5247 |
| choko walk | 308 / 383 | 2373 / 4418 | 1332 / 2177 |
| choko hang | 321 / 511 | 410 / 536 | 422 / 660 |
| skea idle | 198 / 329 | 3569 / 4009 | 1612 / 1818 |
| skea walk | 237 / 311 | 1955 / 2857 | 959 / 1312 |
| skea hang | 375 / 495 | 335 / 381 | 355 / 433 |

| WaveField | Baseline | Early candidate | Optimization1 |
|---|---:|---:|---:|
| choko idle | 434 / 3015 | 15851 / 24324 | 14926 / 16469 |
| choko walk | 204 / 285 | 7942 / 12075 | 7584 / 11182 |
| skea idle | 186 / 259 | 13298 / 13894 | 13154 / 13646 |
| skea walk | 185 / 268 | 7861 / 12603 | 7030 / 10437 |

Early candidate має два callbacks за frame: перший явний physics retarget і один deferred; другий відтворює кешовані6 leg quaternions. Baseline має один deferred callback. На solid plane —2 foot rays+1 body support read за eligible frame,1 cache hit; повтор не додає sample/FK/ray роботи. Idle samples5406 Choko/4894 Skea; jog median2703/2447, максимум4105/3674; hang0. Water має0 rays, але той самий full-skin volume і нелінійний height на вершину.

Окремий bounded attribution replay раннього кандидата підтвердив hotspot: Choko idle ground helper median3565µs, із них sole loop3470; Skea3283/3180. Це інший короткий запуск із додатковими timers, тому його абсолютні числа не слід підставляти замість основної таблиці. Optimization1 переносить точну проєкцію plane на cached per-bone row/bias і зберігає **всі** оригінальні weighted vertices; зменшення числа вершин не було. Solid-plane результат суттєво кращий, але water13–15ms на idle hero лишається блокером. Власнику передана обмежена друга ітерація: зберегти нелінійне height у кожному фактичному skinned XZ, кешувати незмінні coefficients часу/напрямків, без апроксимації ankle radius чи пропуску water.

Додатковий фактичний imported inventory exact bone/weight signatures, без округлення: Choko Left1301vertices/200single-influence/375signatures, Right1402/151/392; Skea Left1220/63/378, Right1227/52/392. Велика частка mixed influences означає, що дешеве припущення rigid shoe неприйнятне без доказу.

Відтворення й raw evidence: `/workspace/nooneisreal-evidence/whole-body-motion/early-perf/` містить `source-hashes.json` кожного snapshot, `optimized/source-delta.json`, `probe.gd`, `water.gd`, `prepare.py`, `run.sh`, `summary.json`, per-frame JSON і logs. Команда `bash …/early-perf/run.sh baseline|candidate|optimized flat|water` виконує один bounded case-set; Godot instances треба запускати послідовно. Probe SHA256`fac1aca09556c129eddb7ce2a77dff355313b3645f351c979af24b7e0add2521`; water probe`a0dc4ab751151d9b145fef30ac4d2ec17e69b4b5f27912f683a42fd6bc642251`. Усі6 основних set-runs завершили sentinel, rc0, без ERROR; attribution і signatures окремі. Raw workspace evidence не входить у portable game package.

Уточнення після першого timing replay: owner equality-test виявив, що imported skin weights не завжди мають точну суму1. Розподіл `rig.origin` усередину weighted bone sum змінює початковий алгоритм на `rig.origin × (Σweights−1)`; повідомлена похибка≈0.12mm на elevated floor. Поправка `rig.origin × (1−Σweights)` потрібна обом новим paths. Тому таблиця Optimization1 показує лише **ранню вартість**, не математичне чи геометричне приймання. Iteration2 snapshot`cc85a6dc…` також відхилений для приймання після повідомлення про equality failure; його швидкі числа тут навмисно не подано. Виправлений helper і final body snapshot ще потребують окремого виміру.

### Виправлена друга ітерація: цілісний snapshot

Після повідомлених owner4633/0 correctness checks повторено **повну поточну game копію**, а не тільки helper swap: manifest SHA256`c207f946171cb60d88e5dcf6618f4c37cdba3aba445532b32d893460d3769bef`; `HeroBodyMotion`=`2ce8f97627947693468cd5641b3cd21d3fc1a34a9970534d89838ccdf4f8bfdf`, `SkeletalRig`=`78c98cf4b8bb9d3e4a3427eb776c85a6316070ed1fe12add512d6c47dfa6ae53`, `HeroGroundContact`=`1e04ea9d50985e4c3f550ebe553e24045d7ee1d68bed042d982d551e9fdfe197`. Source manifest записаний до додавання тих самих isolated timing wrappers. Це кандидат із повідомленим freeze власників, ще не фінальний committed/exported acceptance.

Remainder ваг виправлений. Water path зберігає skinning усіх vertices і height у кожному їхньому фактичному XZ; незмінні per-pass coefficients та bone transforms кешуються, не декімуються samples. Owner перевірив translated ramps,2D/3D waves та active swell із20µm equality bound; мій наведений тут test — timing/counters, не повтор того correctness proof.

| Поверхня / hero / case | Median / p95 / max µs |
|---|---:|
| flat / choko / idle | 2009 / 3336 / 4084 |
| flat / choko / walk | 1113 / 1669 / 1731 |
| flat / choko / hang | 423 / 577 / 1827 |
| flat / skea / idle | 1690 / 1986 / 3180 |
| flat / skea / walk | 1008 / 1463 / 1578 |
| flat / skea / hang | 383 / 514 / 687 |
| water / choko / idle | 3491 / 5196 / 7037 |
| water / choko / walk | 1911 / 2883 / 9102 |
| water / skea / idle | 3052 / 4998 / 16295 |
| water / skea / walk | 1860 / 3352 / 4393 |

Обидва set-runs чисті, rc0:720 measured flat frames і480 water frames, ті самі30 warmup на case. Матеріальне зменшення проти раннього кандидата підтверджено: water idle приблизно4–5× дешевше, solid idle2–2.7×; жодної заяви про native FPS. У water idle медіана **3.05–3.49ms/hero все ще перевищує provisional1.5–2ms**, тож цей бюджет не можна позначити досягнутим. У цьому single-hero запуску два герої не вимірювалися одночасно; складати їхні median/p95 і називати результат виміряним frame time неправильно. Фінальне рішення про цей залишковий CPU budget належить координатору; дві дозволені optimization iterations завершено.

Лічильники лишилися тими самими: idle5406/4894 samples, jog median2703/2447; solid2rays+1supportread, water0rays+1supportread, hang0samples/queries; два callbacks/physics frame, cached repeat не виконує повторного skinning. `validated/flat.log`, `validated/water.log`, JSON rows і source manifest збережені поряд. Відтворення: `bash …/early-perf/run.sh validated flat` та `… validated water` послідовно. Shared production не змінювалась.

### Фактична пара героїв у вільному вікні

За окремим запитом координатора виконано Choko+Skea **одночасно** у тому самому physics frame, а не додано single-hero medians. Фінальний helper після додавання standing reactions має SHA256`46864f2c2dce2afccd4dcff2dcec120f01d4443dff15f5a224aa098a38aff5ce`; idle/jog/hang math не змінено. `paired-final/source-delta.json` посилається на validated manifest`c207f946…` і фіксує цю єдину заміну helper; Body/Skeletal hashes вище незмінні. Owner повідомив5407/0 correctness checks.

Перший pair run збігся з двома native combat captures; `/proc` підтвердив сторонні Godot processes. Його log/rows позначені `pair-contended` і **не використані** для physics-budget рішення. Після завершення captures T2/T4/T6/NPC погодили коротку паузу, а `run_pair.sh` перед стартом підтвердив `PAIR_WINDOW_NO_OTHER_GODOT`. Наведені нижче числа — новий quiet run:5cases,30 warmup+120 measured frames кожен,600 measured frames, rc0, без ERROR. Обидва герої проходять ту саму задану траєкторію/фазу; це ізольована пара presentation rigs, не повна arena simulation.

| Два герої разом | Median / p95 / max, ms |
|---|---:|
| flat / idle | 3.734 / 6.104 / 9.914 |
| flat / walk | 2.171 / 3.152 / 3.635 |
| flat / hang | 0.566 / 0.831 / 1.597 |
| water / idle | 6.016 / 7.586 / 8.449 |
| water / walk | 3.349 / 4.882 / 9.265 |

У всіх600 samples виміряна presentation частина нижча за16.67ms physics tick; найбільше9.914ms, тобто арифметичний залишок щодо tick6.756ms. Це **не** вимір резерву цілого кадру: actor simulation, input/AI, native render/GPU та інші системи виключені. Також немає доказу FPS на M3 чи гарантії хвостів поза цим bounded window. Початкову per-hero water target1.5–2ms не досягнуто; наведена pair вартість дає координатору фактичні дані для окремого прийняття залишкового feature cost, без третьої оптимізації чи sole approximation.

Пара:4 callbacks/frame; flat4foot rays+2body support reads, water0rays+2reads; idle10300samples, jog median5150/max7779; hang0samples/queries. Cumulative repeat caching збережено. Reproduction: `bash /workspace/nooneisreal-evidence/whole-body-motion/early-perf/run_pair.sh paired-final`; runner зупиняється зrc2, якщо вже працює інший Godot. Probe `pair.gd` SHA256`766d1ebc85d42643083abbd0b1dd6426bba38324022e67d3db6f7cc588bada5b`. Raw `paired-final/pair.log`, `pair-flat-*.json`, `pair-water-*.json`, `summary.json` і source delta збережені. Після завершення вікна всі смуги повідомлені, подальші native/tests розблоковані.

## Related

- [[2026-10-05-Whole-Body-Motion]] · [[2026-10-05-Local-NPC-Models-And-Physics-Reuse]] · [[2026-10-05-Reusable-Game-Systems]] · [[2026-10-05-Locomotion-States]] · [[2026-10-05-Authored-Combat]] · [[Textures-Registry]] · [[ADR-004-Physics-Is-Presentation]] · [[state]]
