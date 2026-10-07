# Тісна опора: читабельність міської камери

**Дата:** 2026-10-07 · **Роль:** T3 Архімед

> Текст — T3 Архімед (sub-agent з інструментами лише для читання). Записав T1 Дедал-оркестратор без змін змісту, за механізмом адаптера «бриф повертається текстом» (`CLAUDE.md`, розділ «Агенти»). T1 особисто звірив: `CityCamera.gd:36-47` (margin 0.2, сфера 0.18, priority −50), `city_camera_check.gd:50` (`visibility < 0.15`), геометрію `CityDistrict.gd:40` і `CityLayout.gd:50`, і в сирцях `godotengine/godot@4.7-stable` `scene/3d/physics/spring_arm_3d.cpp` — `dist -= margin` лише в гілці променя, гілка `shape` іде через `cast_motion` без margin.

Бриф стосується станції `(4,0,31.4)`, яка має YELLOW в аудиті й художньому огляді. Godot у цій сесії не запускався. Усе нижче взято з трьох джерел: сирці main `f27fd67`, класова документація й сирці Godot `4.7-stable`, сирці Cinemachine. Виміри в рушії робить T2. Геометричні висновки — арифметика з сирців, а не вимір.

## Питання
1. Як зараз рахуються колізія, стискання, підйом і dither, і що саме фейдиться.
2. Яку форму мають потрібні API Godot 4.7.
3. Які техніки для тісних просторів мають першоджерело і чим за них платять.
4. Якими мірилами T1 може приймати зміну.

## Джерела (доступ 2026-10-07)
| ID | Джерело, версія | Статус |
|---|---|---|
| G1 | `raw.githubusercontent.com/godotengine/godot/4.7-stable/doc/classes/`: SpringArm3D, Camera3D, ShapeCast3D, PhysicsDirectSpaceState3D, BaseMaterial3D, Node `.xml` | відкрито; з цих XML будується class reference |
| G2 | там само: `scene/3d/physics/spring_arm_3d.cpp`, `scene/3d/camera_3d.cpp`, `scene/main/scene_tree.cpp`, `drivers/gles3/rasterizer_scene_gles3.cpp` | відкрито |
| G3 | `raw.githubusercontent.com/godotengine/godot-docs/4.7/tutorials/3d/spring_arm.rst` | відкрито |
| U1 | `github.com/Unity-Technologies/com.unity.cinemachine`, гілка `main` = пакет `3.1.8-pre.2` (`package.json:4`): `Documentation~/CinemachineThirdPersonFollow.md`, `CinemachineDeoccluder.md`, `CinemachineDecollider.md`; `Runtime/Components/CinemachineThirdPersonFollow.cs`, `Runtime/Behaviours/CinemachineDeoccluder.cs`, `Runtime/Core/Predictor.cs` | відкрито; коміт не закріплено, бо GitHub API недоступний |
| W1 | `github.com/w3c/wcag` `main`, `understanding/21/animation-from-interactions.html` (WCAG 2.3.3) | відкрито; це веб-норма, для гри лише аналогія |
| X1 | `docs.godotengine.org/en/4.7/...` | **403 egress**; відрендерену сторінку не бачив, розбіжності з G1 не перевірені |
| X2 | Nesky, «50 Game Camera Mistakes», GDC 2014 (`gdcvault.com/play/1021262/50-Camera`, адреса з пошуку) | **403**; є лише пошуковий фрагмент, зміст **UNGROUNDED** |
| X3 | Unreal `USpringArmComponent` (`dev.epicgames.com`, `docs.unrealengine.com/4.27`) | **403**; є лише пошуковий фрагмент, значення **UNGROUNDED** |
| X4 | Lyra «penetration avoidance feelers»; Haigh-Hutchinson, «Real-Time Cameras» (2009) | не відкрито, **UNGROUNDED** |

## 1. Поточний механізм (main `f27fd67`)

**Колізія лінзи.** Камеру тримає `SpringArm3D`: `collision_mask = 1`, `margin = 0.2`, сфера `r = 0.18`, довжина `follow_distance = 6.0` (`CityCamera.gd:6,38-45`). З перевірки виключено лише тіло героя (`:76`). Параметри камери: `fov 65`, `near 0.1` (`:51-52`). `keep_aspect` не задано, тож діє типовий `KEEP_HEIGHT` (G1 `Camera3D.xml:201,230`). У проєкті `stretch/aspect="expand"` (`project.godot:44`).

- **Знахідка 1: `margin` у нас не діє.** У `4.7-stable` margin віднімається лише в гілці променя (`spring_arm_3d.cpp:179`). Коли задано `shape`, рушій робить `cast_motion`, і довжина дорівнює `spring_length × safe_fraction` без margin (`:183-194`). XML (`SpringArm3D.xml:44-47`) цього не уточнює, тобто документація розходиться з сирцями; поведінку визначають сирці. Від стіни лінзу відділяє лише радіус сфери.
- **Знахідка 2: стискання й відновлення миттєві.** Дочірній вузол переставляється кожен physics tick (`spring_arm_3d.cpp:53-55,195-204`). Параметрів демпфування клас не має (G1 `SpringArm3D.xml:40-57`).
- **Знахідка 3: затримка в один тік.** CityCamera має `process_physics_priority = -50` (`CityCamera.gd:37`), SpringArm має типовий `0` (G1 `Node.xml:1070`). SceneTree сортує вузли за пріоритетом і в тому самому циклі шле internal та звичайний physics process (`scene_tree.cpp:1190,1220,1223`). Тому `arm.get_hit_length()` у `_update_close_framing` (`CityCamera.gd:160`) повертає довжину попереднього тіку (`physics_ticks_per_second=60`, `project.godot:276`). Підйом і pitch поточного тіку sweep уже враховує.
- **Підйом у тісноті.** Вага `w = 1 − smoothstep(0.35, 1.5, hit)` (`:160`), згладження `k = 10` (`:161`). Pivot піднімається до `close_lift = 0.65` м, рух перевіряє sweep сфери `0.25` (`:9,46-47,162-173`). Pitch додатково змінюється на `−0.12·w` рад ≈ 6.88° (`:107,174`; `python3`).
- **Плече** зсуває pivot до `aim_shoulder_offset = 1.0` лише під час прицілювання вгору (`smoothstep(0.1,0.6,pitch)`, `:8,142`), з `k = 12` і sweep (`:143-155`). Бокового зсуву для уникання стін немає.
- **Pivot** наздоганяє героя з `k = 15` (`:108`). `cast_motion` ігнорує форми, з якими вже перетинається на старті (G1 `PhysicsDirectSpaceState3D.xml:21`); це стосується всіх трьох sweep-ів.

**Proximity dither фейдить героя, а не оклюдери.**
- Відстань міряється від лінзи до відрізка `player + 0.55…1.9 м` по вертикалі (`CityCameraProximity.gd:52-54`); радіус тіла не враховано.
- `visibility = smoothstep(0.35, 0.85, d)` (`:5-6,55`), симетричне згладження `k = 18` (`:8,56`), дотяг до цілі при різниці `< 0.002` (`:57-58`).
- Збираються лише матеріали героя: animator (`:19-20,46-47`), одяг CityCosmetics (`:194-213`), спорядження (`:142-192`). Самі вузли не ховаються (`:3`).
- Світові матеріали не збираються, тож оклюдери ніколи не стають прозорими.
- Шейдер (`camera_proximity.gdshaderinc:7-10`): поріг — хеш від `floor(FRAGCOORD)` без часу, тобто статичний screen-door. Піксель відкидається (`discard`), коли поріг ≥ visibility. Діє лише в головному проході, тіні зберігаються.
- Include стоїть у 8 шейдерах (`grep -rn camera_proximity game/shaders`): toon, outline, hero_outline, hero_garment, gear_surface, camera_cloth, sword_dissolve, grimoire_sigil. Тому контур героя зникає разом із тілом (`hero_outline.gdshader:18`).
- Нижньої межі немає: при `d ≤ 0.35` герой стертий повністю.
- Константи хеша схожі на Interleaved Gradient Noise (Jimenez 2014), але атрибуцію не перевірено: iryoku.com дав 403.

**Чинні тести закріплюють приховування** (`tools/camera/city_camera_check.gd`):
- біля стіни очікується `hit < 0.4`, підйом `> 0.5` і `visibility < 0.15` («lens inside head/torso clears local body», `:49-50`);
- `|Δvisibility| < 0.3` за тік (`:60`);
- `visibility > 0.99` після відходу (`:63`);
- `clear_lens` перевіряє лише сферу 0.05 м у центрі лінзи (`:20-26`).

Будь-яка «мінімальна видимість» героя суперечить `:50`. Це питання рішення, а не факту.

**Геометрія станції (арифметика з сирців, не вимір).**
- `PracticeLedge`: центр `(4,1.4,29)`, розмір `(2.8,2.8,2.4)` (`CityDistrict.gd:40`). Отже лицьова грань `z = 30.2`, верх `y = 2.8`.
- `SouthBoundary`: центр `z 32.5`, товщина 1, висота 4 (`CityLayout.gd:50`). Отже внутрішня грань `z = 32.0`, верх `y = 4`.
- Обидва об'єкти мають шар `9`, тобто біти 1 і 4, і потрапляють у маску арма.
- Коридор між ними 1.8 м, від станції до межі 0.6 м (`python3`).
- `reset_view` ставить yaw 0 (`CityCamera.gd:89`), напрям «вперед» = `(0,0,−1)` (`:184`). Арм дивиться вздовж +Z (G1 `SpringArm3D.xml:7`), тобто прямо в межову стіну.
- У capture kick запускається через «down» після hang (`trick_production_capture.gd:99,112-114`; знак осі `InputRouter.gd:402`). **Це висновок, а не вимір:** герой відштовхується в бік уже стиснутої лінзи. Підтвердити має T2.

**Near-plane проти сфери** (`python3`, fov 65 по вертикалі, near 0.1). Відстань від центру лінзи до кута near-plane:

| Співвідношення сторін | Відстань до кута |
|---|---|
| 3:2 | 0.152 м |
| 16:9 | 0.164 м |
| 2560×1080 | 0.192 м |

Сфера радіусом 0.18 м покриває кути лише до приблизно 16:9. `clear_lens` кутів не перевіряє.

## 2. API Godot 4.7 (G1–G3)
| API | Місце | Що підтверджено |
|---|---|---|
| `SpringArm3D` | `SpringArm3D.xml:13-56` | `collision_mask` (типово 1), `margin` (0.01), `shape`, `spring_length` (1.0), `get_hit_length()` повертає поточну довжину, `add_excluded_object(RID)`; демпфування немає |
| `SpringArm3D` без `shape` з дочірньою `Camera3D` | `spring_arm_3d.cpp:146-167`; `camera_3d.cpp:464-480,842-868`; `spring_arm.rst:37-47,85-87` | рушій робить sweep піраміди «вершина + 4 кути near-plane», а це точний захист near-plane. Туторіал радить лишати `shape` порожнім, а сферу згадує як форму, що «slides smoothly along edges». У `Camera3D.xml:54` сказано «ignoring the camera's near plane»: це формулювання розходиться з сирцями, де точки беруться саме з near-plane |
| `ShapeCast3D` | `ShapeCast3D.xml:3-12,41-47,162` | `target_position`, `shape`, `margin` (0.0), `get_closest_collision_safe_fraction()`, `force_shapecast_update()`; дорожчий за промінь |
| `cast_motion` / `intersect_shape` / `get_rest_info` | `PhysicsDirectSpaceState3D.xml:15-21,34-40,78-84` | повертає `[safe, unsafe]`, без зіткнення `[1,1]`; ігнорує форми, з якими вже перетинається; `intersect_shape` типово дає до 32 результатів |
| `Camera3D` | `Camera3D.xml:186,201,204-206` | `fov` 75, `keep_aspect` 1 = `KEEP_HEIGHT`, `near` 0.05; для мірил є `is_position_in_frustum`, `unproject_position`, `project_position` |
| `BaseMaterial3D`, distance fade | `BaseMaterial3D.xml:201-211,844-849` | `DISTANCE_FADE_PIXEL_DITHER` / `OBJECT_DITHER`; якщо min > max, напрям інвертується. Це рушієва версія «dither біля камери» |
| `BaseMaterial3D.stencil_mode = XRAY` | `BaseMaterial3D.xml:381-396,857-860`; `rasterizer_scene_gles3.cpp:253-276,2712-2713` | «silhouette of the object behind walls», позначено **experimental**; stencil-код є і в Compatibility. Пресет працює для BaseMaterial3D, а наш герой на ShaderMaterial; шлях через custom stencil не перевірено |

## 3. Техніки для тісних просторів
| Техніка | Першоджерело | Що дає | Ціна | Ризик для чутливих до руху |
|---|---|---|---|---|
| Pull-in уздовж арма (наша) | G2; U1 `ThirdPersonFollow.md:45-47` | лінза не заходить у геометрію | лінза опиняється впритул до героя, тіло доводиться ховати (наш YELLOW) | різкий «зум» через миттєве стискання й відновлення (знахідка 2) |
| Асиметричне демпфування | U1 `ThirdPersonFollow.cs:110-112,358`: всередину `0`, назовні `0.5` с; `Deoccluder.cs:155-156,460-469`: всередину `0.2`, назовні `0.4` с | немає проникнення на вході й «помпи» на виході | відновлення запізнюється; **сталого** стискання не лікує | зменшує коливання дистанції (висновок T3, не дослідження) |
| Згин ригу: pivot убік або вгору, колізія root→hand→camera | U1 `ThirdPersonFollow.md:12-14` (дефолти пакета: shoulder `0.7/0.3/−0.5`, vertical arm `0.5`); `ThirdPersonFollow.cs:262-268` | лінія зору повз край опори, лінза далі від тіла | потрібен вільний простір; бічний простір біля станції **не перевірено** | автоматичний бічний зсув — рух, який ініціює не гравець |
| Підйом висоти / pitch (у нас частково) | U1 `Decollider.md:6`; `Deoccluder.md:26-29`, `Deoccluder.cs:638` («step along the wall») | погляд над уступом | чи вистачить 0.65 м до верху межі `y = 4`, міряє T2; крутіший кут гірше читає горизонт | вертикальний рух камери |
| Розширення FOV при стисканні | лише `Camera3D.fov` (G1); ігрового першоджерела не відкрито, **UNGROUNDED** | більше героя в кадрі на малій дистанції | розтяг країв | зум — типовий «non-essential motion» (W1, аналогія) |
| Whisker / предиктивне уникання | X4, **UNGROUNDED**; примітиви є (`intersect_ray`, `ShapeCast3D`) | обхід перешкоди до зіткнення | N кастів за тік, тюнінг | авто-yaw дезорієнтує найбільше; у нас yaw задає базис вводу (`CityCamera.gd:184`), це стереже тест `city_camera_check.gd:47` |
| Фейд героя (наша) | рушієвий аналог — distance fade (G1) | не видно нутра меша | герой зникає | камера не рухається; статичний screen-door у часі не мерехтить (з коду), великі ділянки не міряні |
| Фейд оклюдерів | U1 `Deoccluder.md:33` (Transparent Layers лише «не перекривають», прозорість — справа гри) | герой за уступом видимий | потрібна політика для матеріалів світу. **Проблему лінзи на станції не лікує**, бо межа стоїть позаду лінзи; допомагає лише з уступом унизу кадру | мінімальний |
| Силует / x-ray | G1 `STENCIL_MODE_XRAY` (experimental) | герой читається за оклюдером | experimental API; шлях для ShaderMaterial не перевірено | мінімальний |
| Гарантія мінімальної видимості | зовнішнього джерела немає | герой не зникає | суперечить `city_camera_check.gd:50`, ризик побачити нутро меша | немає |

**Довідка про демпфування** (U1 `Predictor.cs:95-96,160`). Cinemachine рахує `Damp = x·(1 − e^(−4.605·dt/T))`. Наше `1 − exp(−k·dt)` має ту саму форму, тож `T = 4.605/k` (`python3`):

| Наш вузол | k | T, с |
|---|---|---|
| proximity | 18 | 0.256 |
| pivot | 15 | 0.307 |
| плече | 12 | 0.384 |
| підйом | 10 | 0.461 |

Дефолти U1 0.5 / 0.4 / 0.2 с відповідають k 9.21 / 11.51 / 23.03. Це референс пакета, а не норма.

**Nesky (X2).** Пошуковий опис згадує категорії «breaking line-of-sight» і «triggering simulation sickness». Конкретних «помилок» T3 не читав, тож їх не цитувати.

**Unreal (X3).** Пошуковий фрагмент каже лише, що `bDoCollisionTest` працює через сферу `ProbeChannel/ProbeSize`, і згадує camera lag та `CameraLagMaxDistance`. Дефолтні значення **UNGROUNDED**.

## 4. Мірила приймання
| Мірило | Як міряти (API G1) | Поріг |
|---|---|---|
| M1: частка видимих ключових точок (голова, груди, таз, кисті, стопи) | `is_position_in_frustum` + `intersect_ray` від лінзи до точки (маска 1, без героя) × `proximity.visibility` | **PLACEHOLDER**, зовнішнього числа немає |
| M2: немає near-plane clipping | 4 кути через `project_position(кути viewport, near)`, у кожному `intersect_shape` / `intersect_point` дає 0; окремо перевірити 21:9 | 0 перетинів; бінарне мірило, випливає з семантики піраміди (G2) |
| M3: найсильніший dither на героя за вікно hang→kick→landing | мінімум `proximity.visibility` | **PLACEHOLDER**; конфлікт із `city_camera_check.gd:50` вирішує T1 |
| M4: швидкість зміни дистанції | `\|Δget_hit_length\|` за тік і за секунду; `\|Δvisibility\|` за тік | чинне `< 0.3` за тік (`:60`) — проєктний PLACEHOLDER; зовнішнього порогу немає, **PLACEHOLDER** |
| M5: відступ лінзи від стіни | найменша відстань від центру лінзи до поверхні (`get_rest_info`) проти радіуса sweep | не менше за радіус форми (G2); `margin` зараз не враховується |
| M6: базис вводу не обертається | чинний `city_camera_check.gd:47` | зберегти |
| M7: комфорт | чи можна вимкнути автоматичний рух камери | **PLACEHOLDER**; W1 — лише веб-аналогія; у `ComfortSettings.gd:6` є тільки `shake` |

## Відкрите
- Для T2: `hit_length`, відстань від лінзи до осі тіла і `visibility` у hang, kick та звичайному відході на станції; чи виводить підйом 0.65 м лінзу над `y = 4`; кути near-plane на 21:9.
- Чи свідомо задано `margin = 0.2` разом зі сферою (зараз він не діє).
- Чи вільний бічний простір біля `x = 4` (street details T3 не розбирав).
- Чи працює stencil з ShaderMaterial у 4.7: shading reference T3 не читав.
- X2–X4 потребують доступу. Чи кут зламався новою хвилею, чи був таким і раніше, не встановлено ([[state]]).

**Підсумок T3 для T1.** Найкраще заземлений для цього кута — «згин ригу» з Cinemachine Third Person Follow: pivot зсувається плечем або висотою з власним sweep root→hand, і лише потім ставиться камера (`ThirdPersonFollow.cs:262-268`). Він лягає на sweep-и `cast_motion`, які вже є в `CityCamera.gd:139-174`, і лікує саме стале стискання; демпфування і dither цього не роблять. Друге — асиметричне демпфування (вхід/вихід, не сталий кут). Не заземлені: розширення FOV, whiskers, Nesky, дефолти Unreal. Мінімальна видимість героя — дизайнерське рішення проти тесту `city_camera_check.gd:50`.

## Related
- [[state]] · [[2026-10-05-Parkour-Tricks-And-Quality]] · [[2026-10-05-Tricks-And-Quality-Review]] · [[2026-10-05-Traversal-And-Surface-Review]]
- [[ADR-018-Camera-Frames-Fight-With-Air]] · [[ADR-020-Camera-Continuity-And-Impact]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]]
- [[2026-10-04-Camera-Impact-Readability]] · [[2026-10-03-Smart-Camera-Swing-VFX-Scale]] · [[2026-10-07-Tight-Support-Camera]]
