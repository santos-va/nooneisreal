# Бриф «Ремесло бою», частина A — R4 «живе тіло в Godot 4.7»

**Дата:** 2026-10-03 · **Роль:** T3 Архімед · **Замовник:** запуск 7 хвилі 2 ([[2026-10-03-Living-Combat]]), хендоф T1
у `docs/Plans/2026-10-03-Wave-2-Kickoff.md` (гілка `claude/dreamy-turing-7rsxo9`, коміт `b0967b2`; у `main` цього файла
ще немає) · рядок R4 у [[2026-10-03-Fight-Craft-Research]].
**Правило брифу:** порахувати можу, обрати — ні. Яким вузлом робити 7.1/7.2 — Дедалу й Гефесту; зони, пороги й висоти — Аресу.
**Статус частин:** R4 — цей бриф. R1, R2, R8 — **ще не зроблено**, допишуться сюди наступними розділами.

**Доступ (R0).** `docs.godotengine.org` з хмари → `000` (`curl -s -o /dev/null -w '%{http_code}' -L https://docs.godotengine.org/en/stable/classes/class_twoboneik3d.html`).
Тому джерело кожного твердження про API — **сам рушій тегу `4.7.2-stable`**, з якого збирається і онлайн-документація:

| джерело | як отримано | що дає |
|---|---|---|
| бінар `Godot_v4.7.2-stable_linux.x86_64` | `--version` → `4.7.2.stable.official.ed1daf0bf` | дамп API, експерименти |
| `extension_api.json` (6 965 057 байт) | `godot --headless --dump-extension-api` | список класів, спадкування, властивості, методи |
| сирці `godotengine/godot` тег `4.7.2-stable` | `git clone --depth 1 --branch 4.7.2-stable` → HEAD `ed1daf0bf001b61586d9930840f2f1394092c079` | `doc/classes/*.xml` (текст документації), `scene/3d/*`, `modules/jolt_physics/*`, `thirdparty/jolt_physics/*` |
| `doc/classes/<Клас>.xml` на тегах `4.2…4.7-stable` | `curl -w '%{http_code}' https://raw.githubusercontent.com/godotengine/godot/<тег>/doc/classes/<Клас>.xml` | з якої версії клас існує (200 / 404) |

Доступ 2026-10-03. Онлайн-сторінка класу: `https://docs.godotengine.org/en/stable/classes/class_<клас у нижньому регістрі>.html` —
з хмари не відкрита, текст той самий, що у XML вище.

## Коротко

| питання R4 | відповідь | джерело |
|---|---|---|
| Які `SkeletonModifier3D` є в 4.7.2 | 22 класи (список у § 1) | дамп API |
| IK кінцівок | `TwoBoneIK3D` (з **4.6**), також `FABRIK3D`, `CCDIK3D`, `JacobianIK3D`, `SplineIK3D` (з 4.6); старий `SkeletonIK3D` теж є | § 1, § 2 |
| Погляд | `LookAtModifier3D` (з **4.4**) з лімітами кута й часом переходу; простіший `AimModifier3D` (з 4.5) | § 3 |
| Spring bones | `SpringBoneSimulator3D` (з **4.4**); **не любить масштабований скелет** — з документації | § 4 |
| Частковий регдол поверх анімації | так: `physical_bones_start_simulation(["кістка", …])` + `influence` модифікатора; несимульовані кістки йдуть за анімацією | § 5, сирці |
| «М'язи» на `PhysicalBone3D` | **кутові пружини 6DOF є і працюють на Jolt** (експеримент: 18.5° → 0.0°); моторів немає. Це **розходиться** з [[Active-Ragdoll]] § Jolt («лише ліміти») | § 5.2 |
| `AnimationTree`: 8 напрямків, верх/низ, адитив | класи є (`AnimationNodeBlendSpace2D`, фільтри кісток на `AnimationNode`, `AnimationNodeAdd2`, `AnimationNodeOneShot`); у грі `AnimationTree` зараз не використовується | § 6 |
| Вартість на бійця | хмара (Xeon 2.1 ГГц, 4 vCPU): `TwoBoneIK3D` ×4 + `LookAtModifier3D` ≈ **+31…77 мкс** на бійця на кадр, медіана +46 | § 7 |
| Вартість на M3 і телефоні, межа Low | **UNGROUNDED** — пристроїв у сесії немає | § 7 |
| Чому Jolt лається на масштаб (Н7) | **сплющення від удару** (`Fighter.gd:569-574`, `:1018` → `:1026`) потрапляє в трансформи тіл регдола; **не присід** | § 8 |
| Демо-проєкти з ліцензією | **не перевірено** | § Відкрите |

## 1. Модифікатори скелета в 4.7.2

`python3` по `extension_api.json`: усі класи, у ланцюжку спадкування яких є `SkeletonModifier3D`. Версія появи — перший тег, на
якому `doc/classes/<Клас>.xml` віддає 200 (на `4.2-stable` усі нові — 404).

| клас | батько | з якої версії | для чого (з `doc/classes`) |
|---|---|---|---|
| `SkeletonModifier3D` | `Node3D` | 4.3 | база: `active`, `influence`; «a modification always performs after playback process of the AnimationMixer» (`SkeletonModifier3D.xml:8`) |
| `PhysicalBoneSimulator3D` | `SkeletonModifier3D` | 4.3 | батько `PhysicalBone3D`, пише симуляцію в скелет |
| `LookAtModifier3D` | `SkeletonModifier3D` | 4.4 | повернути кістку на ціль |
| `SpringBoneSimulator3D` | `SkeletonModifier3D` | 4.4 | інерційне колихання ланцюжків (волосся, тканина, хвіст) |
| `RetargetModifier3D` | `SkeletonModifier3D` | 4.4 | ретаргет |
| `AimModifier3D`, `CopyTransformModifier3D` (через `BoneConstraint3D`) | `BoneConstraint3D` | 4.5 | прицілювання на кістку; копіювання трансформу |
| `IKModifier3D` → `ChainIK3D` → `IterateIK3D` → `FABRIK3D`, `CCDIK3D`, `JacobianIK3D`; `TwoBoneIK3D`, `SplineIK3D` | `SkeletonModifier3D` | 4.6 | нове сімейство IK |
| `BoneTwistDisperser3D`, `LimitAngularVelocityModifier3D` | `SkeletonModifier3D` | 4.6 | розподіл скруту; обмеження кутової швидкості кісток |
| `SkeletonIK3D` | `SkeletonModifier3D` | XML є і на 4.2 (тоді ще не модифікатор) | старий FABRIK через `bones_global_pose_override` (`SkeletonIK3D.xml`) |
| `ConvertTransformModifier3D`, `ModifierBoneTarget3D`, `XRBodyModifier3D`, `XRHandModifier3D` | — | не перевіряв версію | службові / XR |

Повний список з дампу: `AimModifier3D, BoneConstraint3D, BoneTwistDisperser3D, CCDIK3D, ChainIK3D, ConvertTransformModifier3D,
CopyTransformModifier3D, FABRIK3D, IKModifier3D, IterateIK3D, JacobianIK3D, LimitAngularVelocityModifier3D, LookAtModifier3D,
ModifierBoneTarget3D, PhysicalBoneSimulator3D, RetargetModifier3D, SkeletonIK3D, SplineIK3D, SpringBoneSimulator3D, TwoBoneIK3D,
XRBodyModifier3D, XRHandModifier3D` — 22.

**Порядок і змішування** (сирці `scene/3d/skeleton_3d.cpp:1192-1205`): скелет проходить модифікатори по черзі; якщо
`influence < 1.0`, результат модифікатора змішується з позою до нього: `modifier_pose_cache.interpolate_with(pose_cache, influence)`.
Отже `influence` — «наскільки» для будь-якого модифікатора, включно з регдолом. Документація вимагає, щоб сам модифікатор
застосовував 100 % результату, а змішування лишав скелету (`SkeletonModifier3D.xml`, член `influence`).

## 2. IK кінцівок — `TwoBoneIK3D` (і сімейство)

- Опис: «This IKModifier3D **requires a pole target**. It provides **deterministic results** by constructing a plane from each
  joint and pole target and finding the intersection of two circles» (`TwoBoneIK3D.xml:7`).
- Один вузол — кілька кінцівок: властивість `setting_count`, у методах параметр `index` (`settings/<index>/root_bone_name`).
- Методи з дампу: `set_root_bone_name`, `set_middle_bone_name`, `set_end_bone_name`, `set_target_node`, `set_pole_node`,
  `set_pole_direction`, `set_pole_direction_vector`, `set_use_virtual_end`, `set_extend_end_bone`, `set_end_bone_length`;
  від `IKModifier3D` — `mutable_bone_axes`, `reset()`.
- Ітеративні (`FABRIK3D`, `CCDIK3D`, `JacobianIK3D` через `IterateIK3D`): `max_iterations`, `min_distance`,
  `angular_delta_limit`, **`deterministic`** (за замовчуванням `false`, `IterateIK3D.xml:152`), ліміти суглобів
  `set_joint_limitation*`. `JacobianIK3D` — «converges more slowly … gentler and less immediate tracking» (`JacobianIK3D.xml`).
- **Перевірено на нашому героєві** (`choko_m0.glb`, Meshy, 24 кістки): `TwoBoneIK3D` з 4 налаштуваннями
  `LeftArm/LeftForeArm/LeftHand`, `RightArm/…`, `LeftUpLeg/LeftLeg/LeftFoot`, `RightUpLeg/…` + цілі й полюси `Marker3D`;
  поза ставиться скриптом щокадру (як у `SkeletalRig.gd:252` `_physics_process`), модифікатор відпрацьовує поверх:
  `LeftHand` з `(51.35, 124.61, -7.71)` (rest) у `(49.32, 124.70, 8.50)` — кістки в сантиметрах (армату Meshy масштабовано,
  `SkeletalRig.gd:140`). Скрипт — § Додаток, `bench.gd`.

## 3. Погляд — `LookAtModifier3D`

Властивості з дампу: `target_node`, `bone_name`, `forward_axis`, `primary_rotation_axis`, `use_secondary_rotation`,
`relative`, `origin_from` (+ `origin_bone*`, `origin_external_node`, `origin_offset`, `origin_safe_margin`), **`duration`**,
`transition_type`, `ease_type`, **`use_angle_limitation`**, `symmetry_limitation`, `primary_limit_angle`,
`primary_damp_threshold` (і `positive/negative`, і те саме для `secondary_*`); методи `is_interpolating`,
`is_target_within_limitation`.

- `duration` — час переходу при зміні цілі або «перевороті» осі при виході за ліміт (`LookAtModifier3D.xml`, член `duration`).
- `use_angle_limitation` — «helps to prevent a character's neck from rotating 360 degrees».
- Кілька `LookAtModifier3D` (шия + голова): модифікатор батьківської кістки має стояти **вище** в списку.
- `AimModifier3D` (4.5) — «simple version of LookAtModifier3D» без лімітів і переходу.

## 4. Spring bones — `SpringBoneSimulator3D`

Ланцюжок `root_bone` → `end_bone` (без розгалужень), на суглоб `stiffness`, `drag`, `gravity`, `radius`, криві згасання;
власні колізії `SpringBoneCollision3D`, не через `PhysicsServer3D`. **Попередження з документації:** «A scaled
SpringBoneSimulator3D will likely not behave as expected. Make sure that the parent Skeleton3D and its bones are not scaled»
(`SpringBoneSimulator3D.xml:13`). У нас скелет героя масштабується сплющенням (`Fighter.gd:574` `skeletal.scale = k`) — див. § 8.

## 5. Частковий active ragdoll на скелеті (стадія 3 [[Active-Ragdoll]])

### 5.1 Що дає рушій (сирці)

- `physical_bones_start_simulation(bones: Array[StringName] = [])` — «Optionally, a list of bone names can be passed-in,
  allowing only the passed-in bones to be simulated» (`PhysicalBoneSimulator3D.xml`; реалізація
  `physical_bone_simulator_3d.cpp:302-319`).
- Кістки, які **не** симулюються, щокадру скидаються в позу анімації: `if (!is_simulating_physics()) { _bone_pose_updated(…);
  reset_to_rest_position(); }`, а симульовані пишуться в скелет: `skeleton->set_bone_global_pose(i, …)`
  (`physical_bone_simulator_3d.cpp:370-385`, рядок 380).
- Скільки фізики видно — `influence` симулятора (§ 1, `skeleton_3d.cpp:1205`).
- Тобто «вдарена рука симулюється, решта тіла грає кліп, видно на 40 %» — три штатні виклики. Числа (які кістки, `influence`,
  скільки кадрів) — Аресу; у [[Active-Ragdoll]] стоїть «0.3–0.6 на 6–12 кадрів» без джерела.

### 5.2 «М'язи»: кутові пружини `PhysicalBone3D` на Jolt — розходження з нашим документом

- [[Active-Ragdoll]] § «Jolt — що працює, що ні»: «`PhysicalBone3D` має лише ліміти (без моторів)».
- Сирці 4.7.2: при `joint_type = JOINT_TYPE_6DOF` у `PhysicalBone3D` є властивості
  `joint_constraints/<x|y|z>/angular_spring_enabled`, `angular_spring_stiffness`, `angular_spring_damping`,
  `angular_equilibrium_point` (`physical_bone_3d.cpp:706-709`), передаються в `PhysicsServer3D`
  (`G6DOF_JOINT_FLAG_ENABLE_ANGULAR_SPRING`, `:581`); Jolt їх обробляє (`modules/jolt_physics/joints/jolt_generic_6dof_joint_3d.cpp:428-439`, кутові `case` у `set_param`).
  Слова `motor` у `physical_bone_3d.cpp` немає: `grep -c motor` → `0`.
- **Експеримент** (Jolt, 4.7.2, гравітація 0, дві кістки, симулюється лише дочірня, поштовх `apply_impulse(Vector3(0.3,0,0), (0,0.15,0))`,
  120 кадрів фізики): без пружини кут від пози **18.5°**, з пружиною (`stiffness 50`, `damping 2`) — **0.0°**. Скрипт — § Додаток, `exp3.gd`.
- Висновок: «без моторів» — правда; «лише ліміти» — **неправда для пружин**. Пружина тягне до **фіксованої** точки
  рівноваги на вісь; щоб тягнути до пози кліпу, яка змінюється, — або оновлювати `angular_equilibrium_point` щокадру,
  або PD-момент у `_integrate_forces` (`PhysicalBone3D.xml:14-18`, `custom_integrator`). Котрий — не мені обирати.
  Виправлення [[Active-Ragdoll]] — власнику документа (Гефест), не мені.

## 6. `AnimationTree` — 8 напрямків, верх/низ, адитив

| потреба | клас 4.7.2 | що каже документація |
|---|---|---|
| обхід у 8 напрямках | `AnimationNodeBlendSpace2D` (`add_blend_point`, `auto_triangles`, `blend_mode`, `sync`) | «Outputs the linear blend of the three adjacent animations using a Vector2 weight» |
| верх/низ окремо | фільтри на будь-якому `AnimationNode`: `filter_enabled`, `filters`, `set_filter_path` + `AnimationNodeBlend2` / `AnimationNodeOneShot` | `OneShot`: «fading in and out can be customized, as well as filters» |
| адитивні реакції | `AnimationNodeAdd2` | «Blends two animations additively based on the amount value» |
| одноразовий удар поверх | `AnimationNodeOneShot` (`mix_mode`, `fadein_time`, `fadeout_time`) | — |

**Як у грі зараз:** `grep -rln AnimationTree game/scripts` → порожньо. Кліпи UAL грає `AnimationPlayer` манекена, поза
копіюється на кістки героя скриптом у `_physics_process` (`SkeletalRig.gd:252`). Отже `AnimationTree` став би на манекен
(65 кісток UAL, `SkeletalRig.gd:4`), а модифікатори — на скелет героя (24 кістки) після копіювання. Це факт про код, не рекомендація.

## 7. Вартість

**Хмара, не M3 і не телефон.** `bench.gd` (§ Додаток): 32 копії `choko_m0.glb`, 600 кадрів, щокадру скрипт крутить `Hips`
(замість анімації) і рухає цілі. Режим `base` — без модифікаторів; `ik` — на кожну копію `TwoBoneIK3D` (4 кінцівки) +
`LookAtModifier3D` (`Head`). Міра — `Performance.TIME_PROCESS`, поділена на 32. 7 пар прогонів, процесор `Intel(R) Xeon(R) Processor @ 2.10GHz`, `nproc` → 4.

| | мкс на бійця на кадр (7 прогонів, відсортовано) | медіана |
|---|---|---|
| `base` | 10.86 · 10.88 · 18.15 · 30.21 · 33.15 · 33.43 · 48.73 | 30.21 |
| `ik` | 63.12 · 64.41 · 67.01 · 71.31 · 79.45 · 87.24 · 87.46 | 71.31 |
| різниця в парі | 30.72 … 76.58 | 46.26 |

- Розкид великий (спільний vCPU), тому — порядок величини, не число в GDD: **десятки мікросекунд на бійця**, при бюджеті
  кадру 60 FPS = 16 667 мкс.
- **Обмеження міри (не перевірено):** чи входить оновлення скелета повністю в `TIME_PROCESS` — з сирців не звіряв. Стіни
  часу міряти не вийшло: `--headless` тримає кадр 6.9 мс незалежно від навантаження (обидва режими — 4140 мс на 600 кадрів).
- **M3, телефон, межа профілю Low — UNGROUNDED.** Пристроїв у сесії немає. Як заземлити: той самий `bench.gd` на Mac Santos
  (`godot --headless --path <dir> -s bench.gd -- base|ik`) і на Android-збірці; не вигадую.
- Регдол (`PhysicalBoneSimulator3D`) не міряв.

## 8. Н7 — чому Jolt лається на масштаб тіл регдола

### 8.1 Що каже лог

`make check` на `main` `7dc1d90` (бінар 4.7.2, ця сесія): `[smoke] ALL OK (161 checks) in 19712 frames`, rc=0.

| що | команда | вихід |
|---|---|---|
| скільки попереджень | `grep -c "not supported by Jolt" make_check.log` | **165** |
| які тіла | `grep … \| sed "s/.*body '\([a-z_]*\):.*/\1/" \| sort \| uniq -c` | 11 імен (`pelvis`, `torso`, `head`, `upper_arm_*`, `forearm_*`, `thigh_*`, `shin_*`) — **по 15 разів** кожне |
| значить | 165 = 15 × 11 | 15 появ регдола (`Ragdoll.gd`, `RigidBody3D`), кожна — на всі 11 тіл |
| компонента z масштабу | `sed … \| sort \| uniq -c` | `1.024` ×11, `1.0264` ×11, `1.029867` ×22, `1.032` ×11, `1.0416` ×11, `1.06` ×66, `1.0624` ×33 |

Приклад рядка: `Failed to correctly scale body 'shin_r:<RigidBody3D#…>'. A scale of (1.019603, 0.962131, 1.024000) is not
supported by Jolt Physics for this shape/body. The scale will instead be treated as (1.001912, 1.001912, 1.001912).`

### 8.2 Ланцюжок у нашому коді

1. Удар: `squash = maxf(squash, SQUASH_HIT * clampf(m.damage / 60.0, 0.5, 1.6))` → `_apply_squash()` (`Fighter.gd:1018-1019`).
2. `_apply_squash`: `k = (1 + 0.08·s, 1 − 0.14·s, 1 + 0.08·s)`; `animator.scale = k`, `skeletal.scale = k` (`Fighter.gd:569-574`).
3. Той самий удар далі: `_enter_ragdoll(kb * m.ragdoll_impulse)` (`Fighter.gd:1026`) → `animator.part_snapshot()` (`Fighter.gd:1334`).
4. Знімок бере `mi.global_transform` частини — **з масштабом батька** (`RigAnimator.gd:178`).
5. `rb.global_transform = s.transform` (`Ragdoll.gd:54`) — тіло `RigidBody3D` з капсулою отримує нерівний масштаб.

Звірка чисел: z-компонента масштабу в лозі щоразу дорівнює `1 + 0.08·s` рівно (x і y «змішані» обертанням частини
в площині XY, z — ні; що частини обертаються лише навколо z, з коду не доводив — це випливає з чисел). `1.024` → `s = 0.30` (`SQUASH_HIT 0.6 × 0.5`, мінімальний клемп), `1.06` →
`s = 0.75`, `1.0624` → `s = 0.78` — усі в межах `0.6 × [0.5, 1.6]` (`python3`: `(z−1)/0.08`). Пункт 1→3 — **гіпотеза
порядку, звірена числами**; що саме ці 15 регдолів ішли через `:1026`, а не через `:1244`, — не трасував.

**Присід (PR santos-va/nooneisreal#141) — не причина за цими даними:** `grep -n "crouch" Fighter.gd | grep -i "scale\|squash"` →
порожньо; z-компоненти точно лягають на формулу сплющення. Здогадка плану Wave-2 («від присіду») — **спростована числами**,
остаточна перевірка (A/B до і після #141) — у Феміди за її хендофом.

### 8.3 Чому саме попередження (сирці Jolt)

- `CapsuleShape::MakeScaleValid` → `ScaleHelpers::MakeUniformScale(scale.Abs())` = середнє трьох осей
  (`thirdparty/jolt_physics/Jolt/Physics/Collision/Shape/CapsuleShape.cpp:424-428`, `ScaleHelpers.h:42`). Капсула й сфера в
  Jolt приймають **лише рівний** масштаб; циліндр — рівний у XZ (`CylinderShape.cpp:404-408`).
- Godot порівнює задане з допустимим із допуском `0.01` і друкує `ERR_PRINT` (`modules/jolt_physics/shapes/jolt_shape_3d.h:110-117`,
  `jolt_shape_3d.cpp:276-277`); лише в debug-збірках (`#ifdef DEBUG_ENABLED`, `jolt_shape_3d.h:96`; у release макрос порожній, `:123`).
- Наслідок для фізики: тіло рахується з **рівним** масштабом ≈ 1.002 замість (1.02, 0.96, 1.02) — форма майже та сама,
  поведінка відрізняється на ~0.2 %; шкода — шум у лозі (165 рядків `ERROR`).

### 8.4 Що це означає для 7.1 (регдол на скелеті героя) — перевірено експериментом

- `PhysicalBone3D` під `Skeleton3D` з `scale = (1.06, 0.895, 1.06)` → та сама помилка вже при `add_child` (експеримент `exp.gd`,
  2 тіла → 2 рядки; при `scale = (1,1,1)` — 0).
- **Кістки, що не симулюються, теж лаються**: `exp2.gd` — скелет змінює масштаб за формулою сплющення 10 кадрів, симуляції
  немає → **10** рядків `not supported by Jolt` (по одному на кадр).
- Отже, якщо `PhysicalBone3D` житимуть під `skeletal` (його масштабує `Fighter.gd:574`), шум буде на **кожному кадрі
  сплющення кожного бійця**, а не лише при регдолі. Спосіб уникнути — рішення Гефеста/Дедала; факт: Jolt капсулам
  нерівний масштаб не дає, а рівний (армата Meshy масштабована рівно, `SkeletalRig.gd:140`) — дає (`MakeUniformScale` від
  рівного = він сам).

## Відкрите

- **R4, вартість на M3 / телефоні, межа Low** — UNGROUNDED, потрібен прогін `bench.gd` на пристроях.
- **R4, демо-проєкти з ліцензією** — не дивився (`godotengine/godot-demo-projects` та ін.). Наступна сесія.
- **R4, вартість `PhysicalBoneSimulator3D`** (повний і частковий регдол) — не міряв.
- **R4, чи `TIME_PROCESS` покриває оновлення скелета** — не звіряв із сирцями `main_loop` / `scene_tree`.
- **R4, детермінізм реплеїв:** `TwoBoneIK3D` — «deterministic» за документацією; `IterateIK3D.deterministic` за замовчуванням
  `false`. Чи впливає це на хеш реплею — ні, якщо модифікатори лише картинка; перевіряє гард Гефеста, не я.
- **Розходження з [[Active-Ragdoll]] § Jolt** (пружини на `PhysicalBone3D` є) — передаю власнику документа.
- **R1, R2, R8** — наступні розділи цього брифу; потім Ф2.1 (різкість імпорту) з [[2026-10-03-Santos-Packs-Arenas]].

## Додаток — скрипти експериментів

Запуск: окрема тека з `project.godot` (`3d/physics_engine="Jolt Physics"` для `exp*.gd`), `godot --headless --path . -s <файл>`.

`exp2.gd` (Н7 без симуляції):

```gdscript
extends SceneTree
func _init():
	var sk := Skeleton3D.new(); sk.add_bone("hips"); get_root().add_child(sk)
	var sim := PhysicalBoneSimulator3D.new(); sk.add_child(sim)
	var pb := PhysicalBone3D.new(); pb.bone_name = "hips"
	var cs := CollisionShape3D.new(); cs.shape = CapsuleShape3D.new(); pb.add_child(cs); sim.add_child(pb)
	await physics_frame
	for i in 10:
		var s := 1.0 - 0.1 * i
		sk.scale = Vector3(1.0 + 0.08 * s, 1.0 - 0.14 * s, 1.0 + 0.08 * s)   # формула Fighter.gd:570
		await physics_frame
	quit()
# → grep -c "not supported by Jolt" = 10
```

`exp3.gd` (пружини `PhysicalBone3D`): дві кістки `a`→`b` (`b` на 0.5 м вгору), капсули r 0.05 h 0.3, `gravity_scale 0`;
`b.joint_type = JOINT_TYPE_6DOF`; для x/y/z: `angular_limit_enabled false`, `angular_spring_enabled <false|true>`,
`angular_spring_stiffness 50`, `angular_spring_damping 2`; `physical_bones_start_simulation(["b"])`;
`b.apply_impulse(Vector3(0.3,0,0), Vector3(0,0.15,0))`; через 120 кадрів фізики кут `basis.y` до `UP`: **18.5° / 0.0°**.

`bench.gd` (вартість): `N = 32` копій `choko_m0.glb`, `Engine.max_fps = 0`; режим `ik` — на кожну копію `TwoBoneIK3D`
(`setting_count = 4`, кінцівки з § 2, цілі й полюси `Marker3D`) + `LookAtModifier3D` (`bone_name = "Head"`, ціль `Marker3D`);
30 кадрів розігріву, далі 600 кадрів, щокадру `set_bone_pose_rotation(Hips, …)` і зсув цілей, сума
`Performance.get_monitor(Performance.TIME_PROCESS)` / 600 / 32.

## Related
- [[2026-10-03-Fight-Craft-Research]] · [[2026-10-03-Living-Combat]] · [[Active-Ragdoll]] · [[ADR-017-Post-Ragdoll-Position]] ·
  [[2026-10-03-Santos-Packs-Arenas]] · [[02-Combat-System]] · [[2026-10-03-T3-Fight-Craft-R4]] · [[state]]
