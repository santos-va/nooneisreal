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

## Related

- [[2026-10-05-Whole-Body-Motion]] · [[2026-10-05-Local-NPC-Models-And-Physics-Reuse]] · [[2026-10-05-Reusable-Game-Systems]] · [[2026-10-05-Locomotion-States]] · [[2026-10-05-Authored-Combat]] · [[Textures-Registry]] · [[ADR-004-Physics-Is-Presentation]] · [[state]]
