# Stencil для «темної фігури» і пряма видимість лінзи

**Дата:** 2026-10-07 · **Роль:** T3 Архімед

> Текст — T3 Архімед (sub-agent з інструментами лише для читання). Записав T1 Дедал-оркестратор без змін змісту. T1 особисто відкрив зведений кадр вимірів (скопійовано як `docs/assets/screenshots/2026-10-07-tight-station/t3-stencil-variants.png`): V0/V1 при vis 0,25 — темна маса; V2/V3 — сцена крізь заливку, контур зовні; на парі сфер V2 втрачає внутрішній контур, V3 зберігає. Репозиторій T3 не змінював: `git status --short | wc -l` → 0 на `3ee34e9`. Мінімальний проєкт для рушія лежить поза репо, у `<scratchpad>/t3/stencil_proj/`, де `<scratchpad>` = `/tmp/claude-0/-home-user-nooneisreal/4c591b0b-bd83-5f00-bbc5-b305eb8acb26/scratchpad`.

## Питання
1. Чи підтримує Godot 4.7-stable stencil у ShaderMaterial (Compatibility і Forward+), з яким синтаксисом і порядком проходів? Чи можна прибрати ink-hull зсередини силуету розрідженої заливки? Які є альтернативи без stencil?
2. R1/R2: як перевіряти пряму видимість лінза→герой, щоб spring arm не перескакував через верх стіни? Потрібні варіанти для T1, рішення тут не ухвалюється.

## Джерела (доступ 2026-10-07)
Сирці Godot: `https://raw.githubusercontent.com/godotengine/godot/4.7-stable/<шлях>`. За `version.py` на тегу це 4.7.0 stable. Бінар звітує `4.7.stable.official.5b4e0cb0f`. Відповідність тегу й хешу через API не звірена, бо API дає 403.

| ID | Джерело, версія | Клас |
|---|---|---|
| G1 | `doc/classes/BaseMaterial3D.xml`, `Material.xml`, `PhysicsRayQueryParameters3D.xml` | P |
| G2 | `servers/rendering/shader_language.cpp`, `shader_types.cpp`, `shader_compiler.cpp`; `scene/resources/material.cpp` | P |
| G3 | `drivers/gles3/rasterizer_scene_gles3.cpp/.h`, `storage/material_storage.cpp`, `storage/render_scene_buffers_gles3.cpp` | P |
| G4 | `servers/rendering/renderer_rd/forward_clustered/{scene_shader,render}_forward_clustered.cpp`, `forward_mobile/render_forward_mobile.cpp` | P (лише сирці) |
| G5 | `godot-docs@4.7/tutorials/shaders/shader_reference/spatial_shader.rst` | P; в одному імені розходиться з G2 |
| E1 | Вимір: Godot 4.7 official, `--rendering-method gl_compatibility`, llvmpipe (LLVM 20.1.2), Mesa 25.2.8, xvfb | P (вимір) |
| U1 | `raw.githubusercontent.com/Unity-Technologies/com.unity.cinemachine/main/com.unity.cinemachine/`: `package.json:4` = 3.1.8-pre.2; `Documentation~/CinemachineDeoccluder.md`, `CinemachineDecollider.md`, `CinemachineThirdPersonFollow.md`; `Runtime/Behaviours/CinemachineDeoccluder.cs`, `Runtime/Components/CinemachineThirdPersonFollow.cs` | P (чужий рушій; коміт не закріплено) |
| D1 | `raw.githubusercontent.com/godotengine/godot-demo-projects/3.x/3d/platformer/player/follow_camera.gd` | P (офіційне демо гілки 3.x, не 4.7) |
| X1 | Unreal `USpringArmComponent`: dev.epicgames.com → EGRESS_BLOCKED, є лише пошуковий фрагмент | **UNGROUNDED** |
| X2 | Nesky, «50 Game Camera Mistakes», GDC 2014: gamedeveloper.com → EGRESS_BLOCKED, gdcvault → 403 | **UNGROUNDED** |
| X3 | Рендер Forward+: `VK_KHR_surface not found` → «switching to OpenGL 3». Прогін з `forward_plus` насправді пройшов у gl_compatibility | **не виміряно** |

## 1. Stencil у ShaderMaterial (Godot 4.7)

**Синтаксис (G2, G5)**
- `stencil_mode` — окреме глобальне ключове слово, а не частина `render_mode` (`shader_language.cpp:348`).
- Допустимі режими: `read`, `write`, `write_depth_fail`, `compare_{always,less,equal,less_or_equal,greater,not_equal,greater_or_equal}` (`shader_types.cpp:261-264`), плюс ціле число 0..255 (`shader_language.cpp:9322-9340`).
- Рушій сам генерує такий самий рядок для BaseMaterial3D: `stencil_mode write, compare_always, 1;` (`material.cpp:887-934`). Пресет OUTLINE збирає next_pass так: grow, alpha, `read` + `compare_not_equal`, `render_priority + 1` (`material.cpp:3154-3167`).
- **Без числа reference stencil мовчки вимкнений:** `stencil_enabled = stencil_referencei != -1` (`gles3/storage/material_storage.cpp:3153`; `scene_shader_forward_clustered.cpp:209`).
- **Документація розходиться з сирцями.** G5 пише `write_if_depth_fail` (`spatial_shader.rst:138`), а сирці знають `write_depth_fail` (`shader_types.cpp:263`). Варіант з документації проходить парсер через префіксне зіставлення `smode.begins_with(name)` (`shader_language.cpp:11269`), а компілятор його мовчки ігнорує (`shader_compiler.cpp:477-482`). Перевірено: у headless `bad_stencil.gdshader` вантажиться без помилки, а `bad_ref.gdshader` (reference 300) дає «Stencil mode reference value cannot be greater than 255».
- API позначене як experimental (G5 `:108`; `BaseMaterial3D.xml:390`).

**Черги й проходи (G3, G4)**
- **Читати stencil можна лише в alpha-черзі.** Інакше рушій пише ERR (`rasterizer_scene_gles3.cpp:270-278`; `render_forward_clustered.cpp:4211-4217`; `render_forward_mobile.cpp:2925`). Матеріал потрапляє в alpha-чергу, якщо має alpha, `depth_draw_never` або вимкнений depth test (`rasterizer_scene_gles3.cpp:257`).
- Stencil не діє в depth-проході: у GLES3 умова `p_pass_mode != PASS_MODE_DEPTH` (`:3339`), у Forward+ stencil вмикається лише для `PIPELINE_VERSION_COLOR_PASS` (`scene_shader_forward_clustered.cpp:363`).
- Opaque-матеріал зі stencil примусово вмикає depth prepass для всієї сцени (`rasterizer_scene_gles3.cpp:1497-1498, 2712-2713`; `render_forward_clustered.cpp:1178-1179, 2112`).
- Alpha-список сортується спершу за `render_priority` (менший малюється раніше), далі від дальнього до ближнього (`rasterizer_scene_gles3.h:723-727`). next_pass не обов'язково йде одразу за джерелом (`Material.xml:55`). Отже порядок проходів задає тільки `render_priority`.
- Буфер у GLES3 — `GL_DEPTH24_STENCIL8`, і для MSAA теж (`render_scene_buffers_gles3.cpp:193, 309`).
- У Forward+ той самий набір режимів і ті самі правила (`scene_shader_forward_clustered.cpp:155-167, 363-400`). Рендер Forward+ не перевірено (X3).

**Вимір E1.** Сцена: сфера r=1, тіло unshaded помаранчеве з тим самим хешем dither, що `camera_proximity.gdshaderinc:14`, hull товщиною 0,06, зелений фон, 480×360. Силует S — 31136 px помаранчевого в REF. Кільце — S, розширений на 10 px, мінус S (8360 px).
- `godot --headless --path <proj> --check-only -s res://probe.gd` → rc 0.
- `godot --headless --path <proj> -s res://shadercheck.gd` → rc 0. Завантажено 10 шейдерів, SHADER ERROR лише на `bad_ref` (dummy `material_storage.cpp:192`).
- `xvfb-run -a godot --path <proj> --rendering-method gl_compatibility -s res://probe.gd -- variant=… vis=…` → 19 прогонів, усі rc 0, `renderer=gl_compatibility`. ERROR є лише у V1o (очікуваний: читання stencil поза alpha-чергою). Інших попереджень, крім V-Sync, немає.
- `python3 -I classify.py out` дає таблицю:

| Варіант | Ланцюг матеріалів | vis | Всередині S: тіло / сцена / чорнило, % | Кільце: чорнило, % |
|---|---|---|---|---|
| V0 (як зараз) | тіло (discard) → hull opaque `cull_front` | 1,0 | 100 / 0 / 0 | 49,8 |
| V0 | те саме | 0,25 | 25,0 / 0,0 / **75,0** | 49,8 |
| V1 «наївний» | тіло `write, compare_always, 1` + discard → hull `read, compare_not_equal, 1`, `depth_draw_never`, prio 1 | 0,25 | 25,0 / 0,0 / **75,0** | 49,8 |
| V2 маска stencil | тіло (discard) → маска (ALPHA 0, `write, compare_always, 1`, `depth_draw_never`, prio 0) → hull `read` (prio 1) | 0,25 | 25,0 / **75,0** / 0,0 | 49,8 |
| V3 маска глибини, без stencil | тіло → маска (ALPHA 0, `depth_draw_always`, prio 0) → hull `depth_draw_never` (prio 1) | 0,25 | 25,0 / **75,0** / 0,0 | 49,8 |
| V5 пресет `STENCIL_MODE_OUTLINE` | StandardMaterial3D | 1,0 | 100 / 0 / 0 | 49,8 |
| MSAA 2×: V0 / V2 / V3 | як вище | 0,25 | 24,9/0/75,0 · 24,9/75,0/0 · 24,9/75,0/0 | 46,4 / 44,3 / 44,3 |

Окремо дві сфери, мала попереду. Рахуємо чорнило всередині силуету великої, тобто внутрішній контур малої на тлі великої: V0 → 1173 px, **V2 → 0**, V3 → 1173 px. При vis 0,25 числа ті самі.

**Висновки (сирці + вимір):**
1. **Stencil у ShaderMaterial у Compatibility 4.7 працює** (V2). Пресет BaseMaterial3D OUTLINE теж працює (V5).
2. **Наївна схема «тіло пише, hull читає» темну фігуру не лікує:** V1 дає ті самі 75 % чорнила, що й V0. Фрагмент, відкинутий `discard`, stencil не пише. Тому в дірках dither stencil лишається 0, і hull проходить перевірку. Потрібен окремий прохід-маска без discard. До того ж opaque-запис stencil увімкнув би prepass усієї сцени (див. вище).
3. **V2 (маска stencil).** Ціна: ще один прохід скінованого меша, а hull переходить з opaque в alpha-чергу. Prepass не форсується, бо маска сидить в alpha-черзі (`:1497`). Втрати: поки маска пише, зникають внутрішні контури (1173 → 0 px). Якщо два герої мають однаковий reference, вони гасять контури один одному.
4. **V3 (маска глибини)** дає той самий результат без stencil і зберігає внутрішні контури, бо працює через глибину. Ризик (висновок із сортування, не виміряно): у дірках зникнуть прозорі об'єкти з prio ≥ 1, що стоять за героєм.
5. **Спільне для V2 і V3** (висновок з `:257-266`, не виміряно): hull в alpha-черзі перестає кидати тінь (`FLAG_PASS_SHADOW` ставиться лише в opaque-гілці). Він малюється після всіх прозорих об'єктів з prio 0, тож лінія може лягти поверх прозорого VFX перед героєм.

**Альтернативи без stencil**

| Техніка | Що каже джерело | Статус |
|---|---|---|
| Маска глибини (V3) | E1 | працює |
| Рушієвий depth prepass тіла | prepass проганяє opaque-список тим самим шейдером із discard (`rasterizer_scene_gles3.cpp:2746`) | висновок із сирців: дірки будуть і в глибині, тож не допоможе |
| `depth_test_disabled` на hull | матеріал іде в alpha-чергу (`:257`) і малюється крізь стіни | висновок: це x-ray, а не контур; не рендерив |
| Екранний контур (depth edge) | DEPTH_TEXTURE у GLES3 є (`:240-241`) | висновок: dither дає дірки і в глибині, тож контур буде довкола кожної крапки; не перевірено |
| План Б: межа заливки 0,4 | у V0 чорнило всередині = 1 − vis (0,25 → 75 %) | арифметика: при 0,4 буде 60 % |

## 2. Клас R1/R2: пряма видимість лінза→герой

**Що в нашому коді.** Жоден крок не перевіряє відрізок лінза→тіло:
- Sweep SpringArm3D іде від pivot (підйом ≤ 0,65 м, `CityCamera.gd:176-193`; плече — `:158-174`) до лінзи.
- Proximity міряє відстань до відрізка 0,55–1,9 м (`CityCameraProximity.gd:68-70`), а не видимість.

Ряд arm Skea з T6 (0,41 → 1,21 → 0,45 → 1,24 → 1,92 → 2,50 → 0,30) точно повторює кроки `_limit_arm_recovery` (`:147-156`). При α = 1 − e^(−9,21/60) = 0,1423 (`python3`): 0,41 → 1,205; 0,45 → 1,240; 1,24 → 1,917 → 2,498. Отже ріст означає, що sweep чистий і лінза відходить назад і вгору, понад верх стіни; падіння означає, що sweep влучив. **R2** — це чергування «чистий / влучив». **R1** — sweep чистий, але пряму лінза→тіло перекриває стіна.

Примітиви для перевірки вже є: `CityConversationFrame.clear()` (ray з `hit_from_inside`, `CityConversationFrame.gd:20-24`; G1 `PhysicsRayQueryParameters3D.xml:47-49`) і зонд M1 (`tight_station_probe.gd:524-535`).

Порядок у тіку: CityCamera має пріоритет −50 і виконується раніше за SpringArm з пріоритетом 0 (знахідка 3 у [[2026-10-07-Tight-Support-Camera-Research]]). Тому корекцію за видимістю можна вбудувати двома способами: або обмежувати `spring_length` до sweep, або поставити окремий вузол із пріоритетом > 0 після arm. Узгодити з `aim.capture` (`:126`).

| # | Техніка | Джерело | Що робить | Ціна | Як лягає на `CityCamera.gd` |
|---|---|---|---|---|---|
| 1 | Pull Camera Forward | U1 `Deoccluder.md:27`; `.cs:603-629`: sphere-cast від цілі (відступ `MinimumDistanceFromTarget` 0,3 + `CameraRadius` 0,4, `:43,151`) до камери; лінза стає в `hit.point + normal·(r + 0,001)`. D1 `:51,54-56`: промінь ціль→камера, за влучання камера наближається | лінза завжди перед найближчою до героя перешкодою | 1 cast за тік; лінза близько, отже вмикається dither, і результат залежить від п. 1 | крок після `_limit_arm_recovery`: cast від грудей/голови до лінзи, результат обмежує `arm.spring_length` |
| 2 | Утримання / гістерезис | U1 `md:30,34`; `.cs:417-453`; типово SmoothingTime 0, MinimumOcclusionTime 0 (`:150,154`), Damping 0,4 / WhenOccluded 0,2 (`:155-156`, вибір `:469`) | тримає найближчу відстань N с; ігнорує оклюзії, коротші за T | 0 кастів; відхід запізнюється | відновлювати лише після N с чистого sweep/видимості; `_close_weight` рахувати від утриманої довжини, а не від сирої `get_hit_length()` (`:179`) |
| 3 | Preserve Camera Height / Distance | U1 `md:28-29`; `.cs:631-700`: кроки вздовж стіни, ≤ MaximumEffort 4 (`:153`), видимість цілі перевіряється на кожному кроці (`:671-678`) | шукає іншу точку огляду | ≥ 4 casts; рух ініціює не гравець | лінза зсувається вбік без зміни `_yaw`, тож вид розходиться з базисом вводу (`:203`, тест M6) |
| 4 | Whiskers / авто-поворот | D1 `:50-62`: ±25°, 50°/с | yaw відходить від перешкоди | 3 rays за тік | конфлікт із M6; T2 бачив, що ±45° на старій станції не вистачає ([[state]]), тож 25° найімовірніше мало (висновок) |
| 5 | Гейт видимості на підйом | U1 `Decollider.md:3,6`: terrain resolution піднімає камеру над колайдером і прямо не зберігає видимість — той самий клас, що наш lift | підйом і pitch діють лише поки лінза бачить тіло | 1 ray за тік | у `_update_close_framing`: якщо промінь лінза→груди перекритий, lift → 0 |
| 6 | Колізія root→hand→camera | U1 `ThirdPersonFollow.cs:266-268` | так само, як у нас | — | `TPF.md:47` обіцяє «always keeps the target in sight», але код перевіряє лише root→hand і hand→camera, а відрізок camera→target — ні (висновок з коду). Тож R1 цим не закривається |
| 7 | Правило розміщення | [[2026-10-07-Tight-Station-Fix-Review]] | не ставити тісних опор | 0 | дизайн |

Для п. 1 і 2 є і P-джерело, і демо. Для п. 5 — аналогія з U1 плюс наш код. Unreal (X1), Nesky (X2) і Lyra feelers — **UNGROUNDED**.

## Відкрите
- Stencil у Forward+ і на Metal (M3) не рендерився (X3).
- Вимір зроблено лише на сфері. Скінований герой, кілька матеріалів (`SkeletalRig.gd:211-219`, `RigAnimator.gd:144`, `SwordPresentation.gd:112`), тіні, VFX і High/Low у грі не перевірені.
- Не перевірено V2 з маскою, що робить discard при vis ≥ 1, щоб на повній видимості повертати внутрішні контури.
- Чи закривають п. 1, 2 і 5 фікстуру R1/R2 — це має виміряти T2.
- Коміт U1 не закріплено.

**Підсумок T3 для T1.** Stencil у ShaderMaterial у Compatibility 4.7 працює, але «тіло пише, hull читає» лишає ті самі 75 % чорнила, бо `discard` не пише stencil. Працюють V2 (stencil-маска) і V3 (маска глибини без stencil): 0 % чорнила всередині силуету, зовнішнє кільце без змін. V2 гасить внутрішні контури, V3 їх зберігає; в обох hull переходить в alpha-чергу (зникає його тінь, лінія може лягти поверх прозорого VFX). Для R1/R2 найкраще заземлені Pull Forward, утримання/гістерезис і гейт видимості на lift.

## Related
- [[state]] · [[2026-10-07-Camera-Readability-Iteration-2]] · [[2026-10-07-Tight-Support-Camera-Research]] · [[2026-10-07-Tight-Station-Fix-Review]]
- [[2026-10-07-Tight-Support-Camera]] · [[2026-10-07-Tight-Support-Camera-Fix]] · [[2026-10-07-Tight-Station-Camera-Baseline]] · [[2026-10-07-Camera-And-Gate-Review]]
- [[Cel-Shading]] · [[Style-Guide]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]]
