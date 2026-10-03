# Ресерч — звідки брати анімації для манекена і героїв (C0, 2026-10-03)

**Роль:** T3 Архімед (суб-агент лише на читання; файл записала головна сесія). Дата доступу до всіх джерел — **2026-10-03**.
**Задача:** C0 плану [[2026-10-03-Picks-to-Game-and-Animation]]. Старий бриф [[2026-10-02-Animation-Assets-Pipeline]] лишав у Quaternius UAL позначку «бій — verify». Тут це закрито списками кліпів, витягнутими з самих файлів.
**Статус:** нижче — факти про паки й рушій. Яким кліпом грати який удар, вирішують Арес (C3, #36) і Гефест (C1); гроші й кредити — Santos.

## Питання

1. У якому CC0-паку є гуманоїд-манекен і кліпи: бойова стійка, удар мечем ×2–3, удар ногою, блок, ухил/перекат, **сальто**, реакція на удар ×3 зони (голова / корпус / ноги), падіння, KO?
2. Чи сумісний його скелет із `SkeletonProfileHumanoid` у Godot 4.7 — BoneMap, ретаргет при імпорті, пальці, хребет?
3. Формат — GLB чи FBX; з якої версії вбудований ufbx?
4. Що з цього дає Meshy / Higgsfield `animation_actions`?
5. Який один пак брати для C1 і звідки кожен відсутній кліп?

## Перевірено власноруч у цій сесії

- **Quaternius UAL1/UAL2 Standard** завантажено з itch.io (безкоштовний тир) у scratchpad; у git нічого не потрапило.
  - `shasum -a 256`: `Universal Animation Library[Standard].zip` → `cc73fc4e…37724`; `Universal Animation Library 2[Standard].zip` → `4008ea20…a2b2177d`.
  - Імена кліпів і кісток прочитано з JSON-чанка GLB (`python3`, `json.loads(glb[20:20+len])`) у `Unreal-Godot/UAL1_Standard.glb` і `Unreal-Godot/UAL2_Standard.glb`. Обидва зібрані `Khronos glTF Blender I/O v4.5.48`.
  - `License.txt` в обох zip → «CC0 1.0 Universal … https://creativecommons.org/publicdomain/zero/1.0/».
- **Повні списки Pro/Source** — з `index.pck` переглядача https://quaternius.com/animviewer.html (Godot web-експорт, `GDPC`, 4.4.1): `strings index.pck | grep -oE 'UAL[12]_Source/[A-Za-z0-9_]+'` → UAL1 126 імен, UAL2 134.
- **Розподіл Standard / Pro** — за картинками `quaternius.com/assets/images/fullres/universalanimationlibrary{,2}/standard.jpg`.
- **KayKit Character Animations 1.1** — zip з itch (`65882f31…be20f`), `License.txt` → CC0; кліпи й кістки з `Animations/gltf/Rig_Medium/*.glb`.
- **KayKit Adventurers 1.0** — `Knight.glb` з GitHub `KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0` (останній коміт 2023-09-16).
- **Kenney** — `kenney_blocky-characters_20.zip`, `kenney_animated-characters-protagonists.zip`; `License.txt` → CC0.
- **Godot 4.7.2.stable** (`/Applications/Godot.app/Contents/MacOS/Godot --version` → `4.7.2.stable.official.ed1daf0bf`; `game/project.godot:17` → `"4.7"`):
  - скрипт `SkeletonProfileHumanoid.new()` → `bone_size 56`, імена й `is_required` (§4);
  - `--doctool` → класи `FBXDocument`, `EditorSceneFormatImporterUFBX`, `RetargetModifier3D`, `BoneMap` є.
- **Сирці Godot** `4.7.2-stable` (тег → `ed1daf0bf0`): `editor/scene/3d/bone_map_editor_plugin.cpp`, `BoneMapper::auto_mapping_process`, рядки 643–1348.
- **Meshy** — публічна таблиця https://docs.meshy.ai/en/api/animation-library: парсинг `<table>` → 656 рядків, max id 696.

---

## 1. Що потрібно з коду

- Стани бійця — `game/scripts/fighter/Fighter.gd:19` → `IDLE, WALK, CROUCH, JUMP, DASH, ATTACK, BLOCK, HITSTUN, BLOCKSTUN, LAUNCHED, KNOCKDOWN, GETUP, GRAPPLE, KO, STUMBLE`.
- Сімейства поз ударів (`grep -n '^anim' game/data/characters/*.tres`):
  - Choko: `light`/`light2`, `slash`, `crouch_light`, `air_light`, `watch`, `sword_up`, `throw`;
  - Skea: `light`/`elbow`, `roundhouse`, `low_kick`, `flying_knee`, `toss`, `veil`, `book`, `throw`.
- Зони флінчу — `RigAnimator.gd:21` → `high | mid | low` (наші «голова / корпус / ноги»).
- Тривалість ударів у кадрах 60 Гц (`startup+active+recovery`): Choko `light` 5+3+9 = 17, `heavy` 11+4+17 = 32; Skea `jab_elbow` 4+3+8 = 15, `roundhouse` 11+4+18 = 33.

## 2. Паки-кандидати

| пак | версія / дата | ліцензія (URL) | формат | манекен | скелет | бойових кліпів у безкоштовному тирі | інші тири |
|---|---|---|---|---|---|---|---|
| **Quaternius UAL1** | itch «Updated» 16 Sep 2026; файли в zip 2026-06-17 | CC0 — `License.txt` + https://quaternius.com/packs/universalanimationlibrary.html | FBX (Unity) + **GLB (Unreal-Godot)**, з root motion (`_RM`) і без | `Mannequin` (у тому самому GLB) | 65 кісток, UE-подібні (`pelvis`, `spine_01..03`, `neck_01`, `clavicle_l`, пальці ×3 + `_leaf`) | 43 разом з `A_TPose` | Pro $9.99 (120+ у FBX/GLB), Source $14.99 (.blend) — https://quaternius.itch.io/universal-animation-library |
| **Quaternius UAL2** | itch «Updated» 28 Sep 2026; файли 2026-06-17 | CC0 — `License.txt` + https://quaternius.com/packs/universalanimationlibrary2.html | те саме + `Female Mannequin/Mannequin_F.glb` (без кліпів, «same rig») | `Mannequin`, `Mannequin_F` | **той самий** 65-кістковий скелет | 43 разом з `A_TPose` | Source $14.99; Pro на itch немає — https://quaternius.itch.io/universal-animation-library-2 |
| **KayKit Character Animations** | 1.1 (`License.txt` «Creation date: 10/12/2025»; itch 16 Sep 2026) | CC0 — `License.txt` + https://kaylousberg.itch.io/kaykit-character-animations | FBX + GLB за категоріями | `Mannequin Character` (6 мешів) | **23 кістки** `Rig_Medium`: `hips spine chest head`, без `neck`, **без ключиць**, без пальців | усі безкоштовні (161 за сторінкою); CombatMelee — 22 | Source $14.99 (.blend) |
| KayKit Adventurers | 1.0, коміт 2023-09-16 | CC0 — `LICENSE.txt` у репо | FBX + GLB | 4 герої, не манекен | 41 кістка з IK-контролами, теж без ключиць | 76 (стара версія тих самих) | — |
| Kenney Blocky Characters | 2.0 (zip 2025-06-10) | CC0 — `License.txt` | GLB | блокові фігури | **скіна немає** (`skins` порожній) → ретаргет неможливий | `attack-melee-*`, `attack-kick-*`, `die` | — |
| Kenney Animated Characters Protagonists | FBX 2019–2020 | CC0 — `License.txt` | FBX | `characterMedium` | не перевірено | лише `idle`, `jump`, `run` | — |
| Rokoko free (13 fight, 6 martial arts) | сторінки 2026-10-03 | «any … game … commercial use» — https://www.rokoko.com/resources/rokoko-mocap-13-free-fight-animations | FBX (`Combat.zip`, Google Drive) | — | не перевірено | **імена не прочитано** | — |
| Mixamo | — | royalty-free, **не CC0**; сирі файли не поширювати (за витягом пошуку зі сторінки https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html; curl/WebFetch → 403) | FBX | — | — | вхід лише через Adobe ID | — |

## 3. Таблиця «потрібний кліп × пак»

**Std** — безкоштовний тир; **Pro/Src** — платний (лише за переглядачем, файли не відкривались). Тривалість (с) — максимум часу семплерів у GLB. Meshy — `id Назва` з публічної таблиці.

| потрібно | UAL1 Std | UAL2 Std | UAL Pro/Src | KayKit Anim 1.1 | Meshy |
|---|---|---|---|---|---|
| бойова стійка | `Sword_Idle` (1.667) · `Idle_Loop` | `Idle_Shield_Loop` (зі щитом) | `Sword_Aerial_Idle` (Src) | `Melee_2H_Idle` · `Melee_Unarmed_Idle` | 89 Combat_Stance |
| меч ×2–3 | `Sword_Attack` (1.533) | **`Sword_Regular_A` (0.433) + `_A_Rec` (0.967) · `_B` (0.533) + `_B_Rec` (1.033) · `_C` (2.0) · `_Combo` (3.0) · `Sword_Heavy_Combo` (4.333) · `Sword_Dash` (1.567)** | `Sword_Light_A..D`, `Sword_Heavy_A..D`, `Sword_Aerial_A/B`, `Sword_UpperCut_RM` (Src); `Sword_Attack_Standing` (Pro) | `Melee_1H_Attack_Chop / Slice_Diagonal / Slice_Horizontal / Stab / Jump_Chop` | 97 Left_Slash · 102 Sword_Judgment · 4 Attack · 219 Right_Hand_Sword_Slash · 240 Thrust_Slash |
| удар ногою | **немає** | **немає** | `Kick` (UAL1 Pro); `Melee_Knee` (UAL2 Src) | `Melee_Unarmed_Attack_Kick` | 103 Simple_Kick · 207 Roundhouse_Kick · 213 Leg_Sweep · 215 High_Kick |
| руки (Skea `light`/`elbow`) | `Punch_Jab` (0.867) · `Punch_Cross` (1.0) | `Melee_Hook` (0.467) + `_Rec` (0.6) | `Melee_Uppercut`, `Melee_Combo` (Src) | `Melee_Unarmed_Attack_Punch_A` | 96 Kung_Fu_Punch · 92 Double_Combo_Attack |
| блок | **немає** | `Sword_Block` (1.233) · `Shield_OneShot` | — | `Melee_Block` · `Melee_Blocking` · `Melee_Block_Hit` | 138… Block1… · 147 Sword_Parry |
| ухил / перекат | `Roll` (1.467) | `Slide_Start/Loop/Exit` | `Dodge_Left/Right` (Pro) | `Dodge_Backward/Forward/Left/Right` | 156 Stand_Dodge · 158 Roll_Dodge |
| **сальто** | **немає** | **немає** | `BackFlip` (UAL1 Pro) · `JogToFlip`, `KipUp` (UAL2 Src) | **немає** | 452 Backflip · 462 Backflip_Jump · 413 Backflip_and_Rise · 453 Backflip_Sweep_Kick |
| реакція: голова | `Hit_Head` (0.433) | — | — | `Hit_A` / `Hit_B` (зона не вказана) | 174 Face_Punch_Reaction |
| реакція: корпус | `Hit_Chest` (0.333) | — | `Hit_Stomach`, `Hit_Shoulder_L/R` (Pro) | `Hit_A` / `Hit_B` | 178 Hit_Reaction · 171 Hit_Reaction_to_Waist |
| реакція: ноги | **немає** | **немає** | **немає** | **немає** | **за назвою не знайдено** |
| падіння / нокдаун | — | `Hit_Knockback` (0.833) · підйом `LayToIdle` (1.533) | `LiftAir_Fall`, `LiftAir_Fall_Impact` (Src) | `Lie_Down` / `Lie_StandUp` (Simulation) | 187 Knock_Down · 7 BeHit_FlyUp |
| KO | `Death01` (2.4) | — | `Death02` (Pro) | `Death_A` / `Death_B` (+ `_Pose`) | 8 Dead |
| кидок (`throw`/`toss`) | — | `OverhandThrow` | — | `Throw` | — |
| удар у повітрі (`air_light`) | — | — (`NinjaJump_*` — лише стрибок) | `Sword_Aerial_A/B/Combo` (Src) | `Melee_1H_Attack_Jump_Chop` | 94 Flying_Fist_Kick · 422 Rising_Flying_Kick |

**Висновок таблиці.** Безкоштовні UAL1 + UAL2 Standard разом закривають стійку, меч ×3 (з окремими кліпами відновлення `_Rec`), руки, блок, перекат, голову, корпус, нокдаун із підйомом і KO. **Немає:** удару ногою, сальто, реакції ніг. Реакції ніг немає в жодному переглянутому паку.

## 4. Скелет і Godot 4.7

**Профіль** (Godot 4.7.2, скрипт): `SkeletonProfileHumanoid` → 56 кісток, root `Root`, scale base `Hips`.
- Обов'язкові: `Hips`, `Spine`, `Head`, `Left/RightShoulder`, `UpperArm`, `LowerArm`, `Hand`, `UpperLeg`, `LowerLeg`, `Foot`.
- Необов'язкові: `Chest`, `UpperChest`, `Neck`, очі, `Jaw`, усі пальці, `Toes`.
- Хребет — три кістки `Spine → Chest → UpperChest`, далі `Neck`. Пальці — по 3; великий — `ThumbMetacarpal/Proximal/Distal`.

**Як UAL лягає на профіль.** Ієрархія з GLB: `root → pelvis → spine_01 → spine_02 → spine_03 → neck_01 → Head`, ключиці від `spine_03`. Прогін евристик `auto_mapping_process` (4.7.2) **вручну, за сирцями**:
- `Hips ← pelvis` (picklist `hip|pelvis…`, рядки 651–652); `Root ← root` (батько Hips з ім'ям «root», 663–680).
- Хребет: `search_path = [spine_01, spine_02]` → `Spine ← spine_01`, `Chest ← spine_02`, `UpperChest ← spine_03` (1336–1343).
- `Shoulder ← clavicle_*` (1122), `UpperArm ← upperarm_*` (`up.*arm`), `LowerArm ← lowerarm_*` (`(low|fore).*arm`).
- `UpperLeg ← thigh_*`, `LowerLeg ← calf_*`, `Toes ← ball_*` (775).
- Пальці: `thumb_01..03 → Metacarpal/Proximal/Distal`; `index/middle/ring/pinky_01..03 → Proximal/Intermediate/Distal`; кінчики `*_04_leaf` відсікаються пошуком «tip|leaf» (896–900).
- Без пари лишаються `LeftEye`, `RightEye`, `Jaw` — необов'язкові.

**Очікування:** 53 з 56, усі обов'язкові змаплені. `BoneMap` в інспекторі імпорту потребує редактора — **підтвердити на Mac**.

**Незалежне підтвердження:** (а) у паку лежить `Godot_Setup.png`: Skeleton3D → Retarget → `Bone Map` → New BoneMap → Profile `New SkeletonProfileHumanoid` → Reimport; (б) переглядач Quaternius (Godot 4.4.1) містить `GeneralSkeleton` та імена профілю (`LeftThumbMetacarpal`, `UpperChest`…) — автор сам ретаргетить UAL через профіль.

**KayKit Rig_Medium:** немає `clavicle`/`shoulder` (обов'язкові `Left/RightShoulder`), немає `neck`, хребет із двох кісток. Автомапінг (1121–1132) дасть «couldn't guess LeftShoulder»; імпорт не блокується, але, за документацією, «animations may not be shared correctly». Для спільного скелета з UAL чи Meshy KayKit гірший.

**Документація** — https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html («Godot Engine (4.7)»):
- автомапінг запускається, коли призначено `SkeletonProfileHumanoid`;
- «Overwrite Axis» — «the most important option for sharing animations in Godot 4»;
- «Unimportant Positions» лишає position-треки лише на `Root` і `Hips`;
- «Fix Silhouette» для T-pose не потрібен, **для A-pose — потрібен** (Meshy з `pose_mode` `a`; у плані t-pose, [[Higgsfield-Pipeline]]).

**Відомі проблеми** (`api.github.com/search/issues`):

| # | стан | що |
|---|---|---|
| [#123782](https://github.com/godotengine/godot/issues/123782) | **open**, 2026-09-24, відтворено на **4.7.2.stable** | `Retarget → Remove Tracks → Except Bone Transform` стирає й самі bone-треки (KayKit `Walking_A`: 21 → 0). **Опцію тримати вимкненою.** |
| [#89725](https://github.com/godotengine/godot/issues/89725) | closed, 4.3-dev5 | автомапінг ReadyPlayerMe хибно обирав пальці; лікувалось вручну |
| [#96153](https://github.com/godotengine/godot/issues/96153) | closed, 4.3 | частина треків губилась після імпорту з BoneMap на неповному скелеті |
| [#94483](https://github.com/godotengine/godot/issues/94483) | open, 2024-07-17 | анімації, збережені як `.res`, не враховують bonemap |

## 5. Формат

- **GLB** — документація 4.7 (https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html): «glTF 2.0 (recommended)».
- **FBX** — «supported via the ufbx library»; «By default any FBX file added to a Godot project in **Godot 4.3 or later** will use the ufbx import method». `FBXDocument` і `EditorSceneFormatImporterUFBX` є в 4.7.2 (`--doctool`).
- UAL кладе GLB у `Unreal-Godot/`, FBX — у `Unity/`. Для C1 — **GLB без `_RM`**: рух тіла задає код (`MoveData.forward_step`), не root motion.
- Розмір: `UAL1_Standard.glb` 7 618 436 байт, `UAL2_Standard.glb` 8 091 444 (`unzip -l`). `.gitattributes` у репо немає — LFS не налаштовано.

## 6. Meshy / Higgsfield `animation_actions`

- **Id з вікі збігаються з публічною таблицею Meshy** — звірено 15 з [[Animation-Plan]]:22–28 (89 Combat_Stance, 96 Kung_Fu_Punch, 103 Simple_Kick, 94 Flying_Fist_Kick, 97 Left_Slash, 102 Sword_Judgment, 4 Attack, 147 Sword_Parry, 138 Block1, 156 Stand_Dodge, 158 Roll_Dodge, 178 Hit_Reaction, 174 Face_Punch_Reaction, 7 BeHit_FlyUp, 8 Dead) і 87 Boxing_Practice ([[Higgsfield-Pipeline]]:34).
- **Розбіжність 1.** [[Animation-Plan]]:26 — «138–146 Block1…Block10»; у таблиці Meshy `Block7` немає (143 = Block6, 144 = Block8).
- **Розбіжність 2.** Вікі — «678 кліпів» ([[Library]]:12, [[Pipeline-2D-to-3D]]:26); публічна таблиця — 656 рядків. Число **UNGROUNDED**.
- **Сальто в Meshy є** (публічна таблиця): 452 Backflip, 462 Backflip_Jump, 413 Backflip_and_Rise, 453 Backflip_Sweep_Kick, 375 Handstand_Flip, 401 Sprint_Roll_and_Flip, 450 Wall_Flip. Чи є вони в каталозі Higgsfield — **UNGROUNDED** (MCP у суб-агента немає, у вікі цих id немає).
- **Ціна** — лише з вікі: [[Higgsfield-Pipeline]]:40–42 — риг готової GLB + 1 кліп = **8 кр.**, кожен додатковий кліп — новий виклик `3d_rigging` + кліп = 8. Публічний API Meshy має `action_ids` (кілька кліпів в одному файлі); чи пропускає це Higgsfield — **UNGROUNDED**.
- **Скелет Meshy-ригу** — вікі каже «шаблон Mixamo» ([[Pipeline-2D-to-3D]]:25); звірено на реальних M-0/M-1 — див. §6.1.
- Кліп Meshy приходить **на модель, яку ригав Meshy**: сальто для манекена = пропустити його GLB через `3d_rigging` (RED, слово Santos) і ретаргетити.

### 6.1 Скелет Meshy-ригу — звірено на M-0 і M-1 (2026-10-03, головна сесія)

**Звідки:** `show_generations` (Higgsfield, лише читання) → `rawUrl` GLB для M-0 Choko `2488e146` і M-1 Skea `f7f95324` (`multi_image_to_3d`, `enable_rigging: true`, `pose_mode: "t-pose"`). Файли — у scratchpad, не в репо: `curl` → 200, 5 240 128 і 6 131 300 байт. Скелет прочитано з JSON-чанка GLB (`python3`); генератор `Khronos glTF Blender I/O v4.5.51`.

- **24 кістки, однакові імена й порядок у M-0 і M-1** (`a[0]==b[0]` → `True`):
  `Hips → Spine02 → Spine01 → Spine → neck → Head (+ head_end, headfront)`; від `Spine` — `Left/RightShoulder → Arm → ForeArm → Hand`; від `Hips` — `Left/RightUpLeg → Leg → Foot → ToeBase`.
- **Це не Mixamo дослівно:** імена схожі, але без префікса `mixamorig:`, а хребет **нумерується згори вниз** (`Spine02` — найнижча, біля `Hips`; у Mixamo навпаки). **Пальців немає**, кореневої кістки над `Hips` немає (вузол `Armature` зі `scale 0.01`, кістки в сантиметрах: `Hips` y = 103.9 у M-0, 101.4 у M-1).
- У GLB є одна анімація `Armature|clip0|baselayer` тривалістю 0.033 с — поза зв'язування, не кліп.

**Автомапінг Godot 4.7.2 — прогін сирців `bone_map_editor_plugin.cpp` @ `4.7.2-stable`, не редактора:**

| профіль | кістка M-0/M-1 | чому (рядок сирців) |
|---|---|---|
| Hips | `Hips` | picklist `hip` (651) |
| LeftFoot / LowerLeg / UpperLeg | `LeftFoot` / `LeftLeg` / `LeftUpLeg` | `foot` (707); `leg` — серед предків стопи береться найкоротше ім'я, `<=` (586–592) → `LeftLeg`; далі `up.*leg` (750) |
| LeftToes | `LeftToeBase` | `toe` (774) |
| LeftHand | `LeftHand` | `hand` (811), спершу з ≥ 5 дітьми, потім без (815–818) |
| LeftShoulder | `LeftShoulder` | `shoulder` |
| LeftLowerArm / UpperArm | `LeftForeArm` / `LeftArm` | `(low\|fore).*arm`, потім `arm` між плечем і передпліччям; пошук зупиняється на першому слові з влучанням (600–602) |
| Neck / Head | `neck` / `Head` | `neck` (1186); `head` — найкоротше з `Head`, `head_end`, `headfront` |
| UpperChest / Chest / Spine | `Spine` / `Spine01` / `Spine02` | крок 9: UpperChest = батько шиї, далі шлях до `Hips` у зворотному порядку → `Spine` = перший від `Hips`, `Chest` = останній (1321–1343). **Порядок за ієрархією, не за цифрами в імені — тож зворотна нумерація не заважає.** |

**Підсумок:** 22 з 56 кісток профілю, **усі 19 обов'язкових** — змаплені; без пари — пальці, очі, `Jaw`, `Root` (усі необов'язкові). Отже, **UAL-кліпи ретаргетяться на Choko і Skea без кредитів**; від Meshy потрібні лише дірки з §8 п. 3.

**Наслідки для C1/C2:**
- Пальці UAL при ретаргеті відкидаються — кисть M-0/M-1 лишається в позі моделі. Кулак чи хват меча — окрема поза кисті (Арес/Гефест).
- Немає `Root`: беремо кліпи UAL без `_RM` (як і в §8) — рух тіла задає код.
- Масштаб (`Armature` 0.01, кістки в см) і різна висота `Hips` у M-0 і M-1 — ретаргет масштабує за `Hips` (scale base профілю); перевірити, що ноги не «пливуть».
- **Ще не перевірено в редакторі** — підтвердити на Mac разом із першим комітом C1/C2 (BoneMap → `SkeletonProfileHumanoid` → Reimport, «Except Bone Transform» вимкнено, godot#123782).

## 7. Ліцензії — коротко (глибоко — на воротах релізу, [[ADR-013-License-Check-At-Release]])

- **CC0, комерційно без атрибуції:** UAL1/UAL2 Standard, KayKit, Kenney — за `License.txt` в архівах. Що платні тири UAL теж CC0, каже сторінка Quaternius («All still free to use in personal, educational and commercial projects»); zip платних тирів не відкривались.
- **Rokoko free:** «commercial use», не CC0; повний текст умов не читано.
- **Mixamo:** royalty-free, без поширення сирих файлів (лише витяг пошуку). FBX із Mixamo у публічному git — ризик.
- **Meshy/Higgsfield:** умови плану — на воротах релізу.
- **Обов'язок проєкту:** кожен файл у `game/assets/` — рядок у [[Textures-Registry]] (гейт `texture_registry_check.py`).

## 8. Рекомендація для Гефеста (C1)

1. **Пак-манекен:** `Mannequin` з `Unreal-Godot/UAL1_Standard.glb` + бібліотека кліпів `Unreal-Godot/UAL2_Standard.glb` — скелет той самий, 84 кліпи на одній моделі. Імпорт за `Godot_Setup.png` (BoneMap + `SkeletonProfileHumanoid`); **«Except Bone Transform» не вмикати** (#123782); варіанти без `_RM`.
2. **Кандидати кліпів для смоку C1** (остаточно зіставляє Арес у C3):

   | стан / анімація | кліп |
   |---|---|
   | стійка | `Sword_Idle` / `Idle_Loop` |
   | Choko `light` → `light2` → `slash` | `Sword_Regular_A` → `_B` → `_C` (атака і `_Rec` окремо: удар на `startup+active`, `_Rec` — на `recovery`) |
   | Skea `light`/`elbow` | `Punch_Jab` / `Punch_Cross` або `Melee_Hook` |
   | блок | `Sword_Block` |
   | DASH | `Roll` |
   | HITSTUN high / mid | `Hit_Head` / `Hit_Chest` |
   | KNOCKDOWN → GETUP | `Hit_Knockback` → `LayToIdle` |
   | KO | `Death01` |
   | `throw`/`toss` | `OverhandThrow` |

   **Масштаб швидкості:** `Sword_Regular_A` 0.433 с ≈ 26 кадрів проти 17 у Choko `light` → прискорити ≈ ×1.53. Секунду пози контакту (`contact_time`) у кліпі **не виміряно** — знімає Гефест у редакторі.
3. **Дірки і звідки закрити** (обирає Santos/Дедал):
   - **сальто:** UAL1 Pro `BackFlip` ($9.99) · UAL2 Source `JogToFlip` ($14.99) · Meshy 452 Backflip (8 кр., RED);
   - **удар ногою** (`roundhouse`, `low_kick`): UAL1 Pro `Kick` · Meshy 207/213/103 (8 кр. кожен) · KayKit `Melee_Unarmed_Attack_Kick` (безкоштовно, але скелет без ключиць — ретаргет неповний);
   - **`flying_knee`, `air_light`, `crouch_light`, `sword_up`:** у Standard немає; у Source — `Melee_Knee`, `Sword_Aerial_*`, `Sword_UpperCut_RM`;
   - **реакція ніг:** кліпа немає ніде. Варіант — наявна пружина флінчу `RigAnimator` (`low` = «knees buckle», `RigAnimator.gd:191`) як адитивний шар поверх скелета.
4. **Для C2:** якщо Meshy-риг Choko/Skea сам змапиться на `SkeletonProfileHumanoid` (перевірити на першій моделі), UAL-кліпи підуть на героїв без кредитів, а від Meshy потрібні лише дірки з п. 3.

## Відкрите

1. Автомапінг BoneMap на UAL без ручних правок — не перевірено в редакторі (§4 — прогін сирців). Перевірка — Mac, з першим комітом C1.
2. `contact_time` для кожного кліпу — замір у редакторі.
3. ~~Скелет Meshy-ригу~~ — звірено на M-0/M-1 (§6.1): 24 кістки, без пальців, усі обов'язкові кістки профілю мапляться за сирцями; лишається підтвердження в редакторі.
4. Чи є 452 Backflip та інші id поза [[Animation-Plan]] у каталозі Higgsfield `animation_actions`; 678 проти 656 кліпів; чи підтримує Higgsfield `action_ids`.
5. Імена кліпів і скелет Rokoko `Combat.zip` — не відкривались.
6. Вміст і ліцензійний файл UAL Pro/Source — відомі лише за переглядачем і сторінкою.
7. Дрібна розбіжність: скриншот UAL1 Standard каже «45 completely free animations», у GLB — 42 кліпи + `A_TPose`.
8. Демо-проєкти Godot з гуманоїдом не досліджено.
9. Реакції ніг немає в жодному паку — як закрити (процедурно, кліпом чи без зони), вирішують Арес/Гефест.
10. Для Кліо: `Animation-Plan.md:26` (немає `Block7`) і «678» у `Library.md:12`, `Pipeline-2D-to-3D.md:26` — виправити у вікі.

## Related
- [[2026-10-03-Picks-to-Game-and-Animation]] · [[2026-10-02-Animation-Assets-Pipeline]] · [[Animation-Plan]] · [[Library]] · [[Active-Ragdoll]]
- [[Higgsfield-Pipeline]] · [[Pipeline-2D-to-3D]] · [[Textures-Registry]] · [[ADR-013-License-Check-At-Release]]
- [[2026-10-03-Behaviour-Cloth-VFX-Shaders]] · [[2026-10-03-Toon-Quality-Cloth]] · [[Choko]] · [[Skea]] · [[state]]
