# Ресерч — toon/cel високої якості, рівні якості, тканина, VFX з альфою (2026-10-03)

**Роль:** T3 Архімед (суб-агент лише на читання; файл записала головна сесія). Дата доступу до всіх джерел — **2026-10-03**.
**Задача:** D0 плану [[2026-10-03-Behaviour-Cloth-VFX-Shaders]] (issue santos-va/nooneisreal#42). На бриф спираються D3 (Гефест, `QualityProfile.gd`) і ТЗ шейдера (Аполлон).
**Статус:** нижче — факти рушія й чужого коду. Вибір профілів і вигляду лишається за Аполлоном, Гефестом і Гермесом.

**Питання.**
1. Як зробити toon/cel під [[Style-Guide]] — контур `#2B2230`, одна тінь у маджента-ліловий, rim? Ramp у `light()`; контур inverted hull, stencil чи post-process.
2. Скільки це коштує на Forward+ (Mac, Apple M3, Metal)? Що недоступне або дороге на Mobile renderer?
3. Як перемикати Low/Medium/High/Ultra в рантаймі?
4. Тканина на мобільних — `SpringBoneSimulator3D`, `SoftBody3D` (Jolt) чи ланцюги `PhysicalBone3D`?
5. Чи дає якась модель Higgsfield відео з альфою? Чи вміє Godot 4.7 грати відео з альфою?

**Звідки версії (перевірено в цій сесії).**
- `gh api repos/godotengine/godot/git/refs/tags/4.7.2-stable --jq .object.sha` → `ed1daf0bf001…`.
- Локальний рушій `/Applications/Godot.app/Contents/MacOS/Godot --version` → `4.7.2.stable.official.ed1daf0bf` (той самий коміт).
- Документація — гілка `godot-docs` `4.7`, коміт `9adca4c1c7` (2026-09-21). `https://docs.godotengine.org/en/4.7/…` → HTTP `200`.
- Класи — `doc/classes/*.xml` @ `4.7.2-stable`. Номери рядків нижче — рядки цих файлів.

**Що є в проєкті (місце).**
- `game/project.godot:17` → `config/features=PackedStringArray("4.7", "Forward Plus")`. `:230` `renderer/rendering_method="forward_plus"` · `:231` `renderer/rendering_method.mobile="mobile"`.
- `:233` `anti_aliasing/quality/msaa_3d=2` — це **4×** (`Viewport.xml:591` `MSAA_4X value="2"`). Перевизначення `.mobile` для MSAA **немає** (`grep -n msaa game/project.godot` → один рядок).
- `:223` `3d/physics_engine="Jolt Physics"` · `:224` 60 тіків · `:18` `run/max_fps=120`.
- `game/shaders/toon.gdshader:26–37` — `light()` з `floor(lit * bands)`, `bands = 3.0` (`:8`); тінь `shadow_tint = vec4(0.25, 0.3, 0.45, 1.0)` (`:10`) — **синя**. Rim лише на освітленому боці, бо множиться на `step(0.0, ndl)` (`:36`).
- `game/shaders/outline.gdshader:3` `render_mode cull_front, unshaded, depth_draw_opaque`. Витискання в просторі об'єкта — `VERTEX += NORMAL * width` (`:9`), тож товщина в пікселях змінюється з відстанню. Колір за замовчуванням `vec4(0.06, 0.05, 0.09)` (`:5`), а не `#2B2230`.
- `game/scripts/fighter/RigAnimator.gd:130–139` і `Ragdoll.gd:137` — кожен `_mat()` створює `ShaderMaterial` з `next_pass = outline`. У `RigAnimator` це 6 базових `_mat()` (`:44–49`), сталь (`:94`) і рюкзак (`:109`). Кожен меш малюється двічі.
- `game/scenes/arena/Arena.tscn:55–59` — `DirectionalLight3D "Sun"`, `shadow_enabled = true`; `:18–20` — glow.
- `grep -rn 'quality\|scaling_3d\|msaa\|SpringBone\|SoftBody\|GPUParticles' game --include='*.gd' --include='*.tscn'` → **нічого**: профілю якості, тканини й частинок у коді ще немає.
- Кольори [[Style-Guide]]: `#2B2230` → (0.169, 0.133, 0.188); `#B07AA6` → (0.690, 0.478, 0.651).

---

## 1. Toon/cel у Godot 4.7

### 1.1 Що каже рушій

| # | факт | джерело (4.7, доступ 2026-10-03) |
|---|---|---|
| T1 | `light()` викликається «for every light in every pixel», у циклі за типами світла; внесок **додається** в `DIFFUSE_LIGHT` (`+=`) | `tutorials/shaders/shader_reference/spatial_shader.rst:549, 566` → https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html |
| T2 | `light()` **не виконується**, якщо ввімкнено `vertex_lighting` або `rendering/shading/overrides/force_vertex_shading`; туторіал додає «(It's enabled by default on mobile platforms.)» | `spatial_shader.rst:570–572` |
| T3 | **Розбіжність із T2.** Клас: `force_vertex_shading` `default="false"`, «Can be used to optimize performance on low-end mobile devices», варіанта `.mobile` немає. Сирці: `GLOBAL_DEF_RST("rendering/shading/overrides/force_vertex_shading", false);` — `.mobile` є лише в сусіднього `force_lambert_over_burley.mobile = true` | `ProjectSettings.xml:3441–3442`; `servers/rendering/rendering_server.cpp:3711–3713` @ 4.7.2-stable |
| T4 | Контур inverted hull (Grow): другий прохід, unshaded, Cull Front; вимагає **з'єднаних граней зі спільними вершинами** (smooth), інакше розриви | `tutorials/3d/standard_material_3d.rst:725–734` |
| T5 | Stencil (з 4.5): режими **Outline** і X-Ray ставлять готовий матеріал у `next_pass`; такі матеріали «always drawn in the transparent pass» — обмеження сортування прозорих; та сама вимога до граней; «won't look identical» до Grow на перетинах з непрозорим | `standard_material_3d.rst:834–862` |
| T6 | Stencil у `ShaderMaterial` (`render_mode` stencil) — «**experimental**, use at your own risk… may change in the next minor version»; читати stencil можна лише в прозорому проході | `spatial_shader.rst:103–128` |
| T7 | `BaseMaterial3D.stencil_mode` / `stencil_color` / `stencil_outline_thickness` (типово 0.01) — `experimental="May be affected by future rendering pipeline changes."`. Це поля `StandardMaterial3D`, не нашого `ShaderMaterial` | `BaseMaterial3D.xml:381–393` |
| T8 | `next_pass` «not necessarily drawn immediately after the source Material» | `Material.xml:53–56` |
| T9 | Буфер **Normal/Roughness — лише Forward+**; screen texture і depth texture є в усіх трьох рендерах | `tutorials/rendering/renderers.rst:334–339`; `screen-reading_shaders.rst:173–175` |

### 1.2 Відкритий код (ліцензія перевірена; як приклад, не копія)

| шейдер | що дає | ліцензія | URL · дата |
|---|---|---|---|
| eldskald, Godot 4 Complete Cel Shader | ramp через `global uniform sampler2D diffuse_curve` (`GradientTexture1D`) у `light()`, fresnel/rim; контур `next_pass` + `cull_front` з витисканням **у clip space** (`/ VIEWPORT_SIZE * clip_position.w * outline_width`) — стала ширина в пікселях | **MIT** (`gh api repos/eldskald/godot4-cel-shader` → `MIT`, pushed 2025-11-04) | https://github.com/eldskald/godot4-cel-shader · https://godotshaders.com/shader/complete-cel-shader-for-godot-4/ (2023-10-28) |
| EMBYRDEV, godot-toon-outline | post-process контур по depth + normal на повноекранному quad; бере `hint_normal_roughness_texture` → **лише Forward+** (T9); README: «Does not work well with TAA», «TESTED ENGINE VERSION: 4.0.3» | **MIT** (pushed 2023-05-25) | https://github.com/EMBYRDEV/godot-toon-outline |
| atzuk4451, Flexible Toon Shader (Godot 4) | смуги, крутизна, wrap, rim у `light()`; без контуру | **MIT** | https://godotshaders.com/shader/flexible-toon-shader-godot-4/ (2023-10-28) |
| relink, Toon Shader | ramp з `GradientTexture`, rim із порогом, `light()`; перевірено автором на 4.3 | **MIT** | https://godotshaders.com/shader/toon-shader/ (2024-12-07) |
| rakaisahakarya, Toon Shader inspired by Genshin | `toon_ramp` sampler, `rim_power`/`rim_size` у `light()` | **CC0** | https://godotshaders.com/shader/toon-shader-inspired-of-genshin-impact/ (2021-04-03; версія Godot не вказана — до 4.0, ймовірно Godot 3, **не перевірено**) |
| GDQuest, godot-shaders | демо контурів 2D/3D | код **MIT**, арт CC-BY-NC-SA 4.0 (GitHub показує `NOASSERTION`) — брати тільки код | https://github.com/gdquest-demos/godot-shaders |

Явно Godot 4.7 не вказано ні в кого; компіляцію на 4.7.2 **не перевіряли**.

### 1.3 Три підходи до контуру

| підхід | Forward+ | Mobile | плюс | мінус |
|---|---|---|---|---|
| inverted hull (`next_pass`, `cull_front`) — **у нас зараз** | так | так (звичайний spatial-прохід) | керований: товщина з вершинного кольору R ([[Style-Guide]] § У грі), clip-space ширина (eldskald) | подвоює проходи на кожен матеріал (T8); розриви на flat-гранях (T4) |
| stencil Outline (4.5+) | так | **не перевірено** (у таблиці рендерів рядка «stencil» немає) | без подвійних ліній на перекриттях ([[Cel-Shading]]) | experimental (T6, T7); прозорий прохід (T5); у `ShaderMaterial` — лише сирий `render_mode` |
| post-process depth + normal | так | **ні** з нормалями (T9); лише глибина — без джерела якості | рівна ширина, внутрішні лінії | повноекранний прохід; погано з TAA |

---

## 2. Вартість: Forward+ (Mac, M3, Metal) проти Mobile

| що | Forward+ | Mobile | джерело |
|---|---|---|---|
| Освітлення | clustered forward; 512 omni/spot на кластер | forward single-pass; **8 omni + 8 spot на меш, 256 + 256 у кадрі, «currently cannot be changed»** | `renderers.rst:197–210`; `lights_and_shadows.rst:68–70` |
| Directional | 8 | 8 | `renderers.rst` § Lights |
| PCSS directional | так | ні | там само |
| SSAO / SSR / SSIL / SDFGI / VoxelGI / volumetric fog | так | **ні** | `renderers.rst:229–278` |
| Glow, тонмапінг, повноекранний post-process | так | так | `renderers.rst:279–282` |
| CompositorEffects | так | так | `renderers.rst:284` |
| TAA / FSR2 | так | **ні** | `renderers.rst:300–302`; `3d_antialiasing.rst:342` |
| FXAA / SMAA / MSAA 3D | так | так | `renderers.rst:298–306` |
| Порада AA на мобільних | — | «FXAA is usually the only viable option. 2× MSAA may be usable… higher MSAA levels are unlikely to run smoothly on mobile GPUs»; для cartoon-стилю «MSAA can work well» | `3d_antialiasing.rst:302–308` |
| Screen / depth texture | так | так | `renderers.rst:334–336` |
| Normal/roughness buffer | так | **ні** | `renderers.rst:339` |
| Колір буфера | RGBA16F | RGB10A2 | `renderers.rst:352` |
| Автоінстансинг | так | **ні** | `optimizing_3d_performance.rst:110` |
| Тіні за замовчуванням | directional 4096 | `size.mobile` = 2048, `soft_shadow_filter_quality.mobile` = 0 | `ProjectSettings.xml:3146, 3149, 3157, 3178, 3186` |
| Апскейл | bilinear, FSR1, FSR2, **MetalFX spatial/temporal** (лише драйвер Metal, «macOS and iOS») | bilinear; MetalFX — **не перевірено** (туторіал: FSR1/FSR2 «Only available when using the Forward+ renderer», про MetalFX мовчить) | `Viewport.xml:555–581`; `resolution_scaling.rst:45–57` |

**FPS / мс — UNGROUNDED:** жодне джерело не дає чисел для M3 чи телефона, заміру в сцені не було. Що виміряти (Гефест, D3):
1. Арена з двома бійцями: `--rendering-method forward_plus` і `--rendering-method mobile` на Mac (ключ CLI — `ProjectSettings.xml:3284`).
2. Кожен профіль — з контуром і без (`next_pass = null`), з тінню і без, MSAA 0/2×/4×, `scaling_3d_scale` 1.0/0.75/0.5.
3. Знімати `Performance.get_monitor(TIME_PROCESS)`, `RenderingServer.get_frame_setup_time_cpu()`, кадри й draw calls (`Viewport.get_render_info`).
4. Те саме на реальному телефоні — пристрій **не названо**.

---

## 3. Рівні якості в рантаймі

| важіль | API (4.7.2) | у рантаймі? | примітка |
|---|---|---|---|
| Роздільність 3D | `Viewport.scaling_3d_scale` (типово 1.0), `scaling_3d_mode` (`BILINEAR`=0, `FSR`=1, `FSR2`=2, `METALFX_SPATIAL`=3, `METALFX_TEMPORAL`=4, `NEAREST`=5) | так | `Viewport.xml:428–436, 555–581`; пресети AMD FSR 0.77 / 0.67 / 0.59 / 0.5 (`:434`) |
| MSAA | `Viewport.msaa_3d` / `RenderingServer.viewport_set_msaa_3d` | так | налаштування проєкту «only read when the project starts» (`ProjectSettings.xml:2866`) |
| Screen-space AA | `Viewport.screen_space_aa` (FXAA=1, SMAA=2) | так | `Viewport.xml:437, 618–626` |
| Атлас тіней | `RenderingServer.directional_shadow_atlas_set_size(size, is_16bits)`; `Viewport.positional_shadow_atlas_size` (0 — без позиційних тіней) | так | `RenderingServer.xml:1248–1254` — «global and cannot be set on a per-viewport basis»; `Viewport.xml:424–426` |
| Фільтр тіней | `RenderingServer.directional_soft_shadow_filter_set_quality`, `positional_soft_shadow_filter_set_quality` | так | `RenderingServer.xml:1256, 3380` — глобальні |
| Тінь сонця | `DirectionalLight3D.shadow_enabled` (`Arena.tscn:59`) | так | — |
| Контур | `ShaderMaterial.next_pass = null` / повернути | так | `Material.xml:53`. `width = 0` прибирає витискання, але **прохід лишається** — не економія |
| Rim / смуги | `set_shader_parameter` (`rim_strength`, `bands`) | так | `toon.gdshader:8–12` |
| Частинки | `GPUParticles3D.amount` | так, але **зміна `amount` перезапускає систему** | `GPUParticles3D.xml:77–79`; `amount_ratio` «has no performance benefit» (`:81–83`) → міняти між боями |
| Тканина | `SkeletonModifier3D.active = false` (`SkeletonModifier3D.xml:54`); при поверненні — `SpringBoneSimulator3D.reset()` (`SpringBoneSimulator3D.xml:318–323`) | так | — |
| Рендер Forward+ ↔ Mobile | у `RenderingServer` лише `get_current_rendering_method()` (`RenderingServer.xml:1644–1648`), сеттера немає; ключ — з налаштування, `--rendering-method` або фолбеку | **ні, лише з перезапуском** | через `override.cfg` / `application/config/project_settings_override = "user://…"` (`ProjectSettings.xml:10, 352–354`); на iOS/Android **не перевірено** |
| Перевизначення платформи | ключ із суфіксом `.mobile` (feature tag `mobile`) | при старті | `ProjectSettings.xml:9`; `tutorials/export/feature_tags.rst:107` |

**Висновок для D3 (факт, не вибір).** Усе, крім рендера, перемикається одним ресурсом без перезапуску; рендер — окреме налаштування «потребує перезапуску». Глобальні параметри тіней (`RenderingServer`) діють на всі в'юпорти, зокрема на 3D-діораму меню ([[ADR-012-Menu-As-3D-Diorama]]).

---

## 4. Тканина на мобільних

| | `SpringBoneSimulator3D` | `SoftBody3D` (Jolt) | ланцюг `PhysicalBone3D` |
|---|---|---|---|
| З якої версії | **4.4** (`…/4.3-stable/doc/classes/SpringBoneSimulator3D.xml` → 404, `…/4.4-stable/…` → 200) | клас давній; Jolt вбудований з 4.4 (`using_jolt_physics.rst:9`), типовий для нових проєктів з 4.6 (`soft_body.rst:15`) | давній |
| Що це | `SkeletonModifier3D`, «wiggle hair, cloth, and tails», повертається до пози; ланцюг root→end **без розгалужень**; колізії — власні `SpringBoneCollision3D`, «not related to PhysicsServer3D» | деформований фізичний меш, вітер з `Area3D`; «It's recommended to use Jolt… faster and more reliable» | фізичне тіло на кістці через `PhysicalBoneSimulator3D` |
| Параметри | на суглоб: `stiffness`, `drag`, `gravity`, `gravity_direction`, `radius`, `rotation_axis`; криві `*_damping_curve`; `external_force` (вітер); `mutable_bone_axes` (false — «increases performance slightly») | `simulation_precision` (типово 5, «can affect performance»), підрозділ меша, pinned points | джойнти й ліміти |
| Як рахує | CPU, Verlet по суглобах із циклом по колізіях — **O(суглоби × колізії)** на кадр (`scene/3d/spring_bone_simulator_3d.cpp:1820–1858`) | CPU, Jolt **5.5.0** (`thirdparty/README.md:511–515` @ 4.7.2) | CPU, PhysicsServer |
| Коли рахує | за `Skeleton3D.modifier_callback_mode_process`, типово **IDLE** — щокадру рендеру (`Skeleton3D.xml:376, 429–431`) | на тіку фізики; «Physics interpolation currently does not affect soft bodies» (`soft_body.rst:18–21`) — при 60 тіках і `max_fps=120` будуть сходинки | на тіку фізики |
| Межа [[ADR-004-Physics-Is-Presentation]] | поза PhysicsServer — хітбокси не чіпає | у фізичному світі — розділити шари | у фізичному світі |
| Вартість у числах | **UNGROUNDED** | **UNGROUNDED** («higher subdivision levels will impact performance», `soft_body.rst:111–115`) | **UNGROUNDED** |

**Рекомендація з джерел (вибір — Дедал).** Джерела підтримують план (розвилка 3) — `SpringBoneSimulator3D` на ланцюжках: вимикається одним `active`, не торкається PhysicsServer (а отже бою), рахує щокадру без сходинок 60/120. `SoftBody3D` на мобільних не підтверджений жодним числом і без інтерполяції гірший.

**Ризик для D4 (читання коду, не замір).** Verlet додає `(current_tail - prev_tail) * (1.0 - drag)` незалежно від `p_delta` (`spring_bone_simulator_3d.cpp:1833–1835`) — при delta = 0 інерція не зникає. Hitstop у нас — лічильник бійця (`Fighter.gd:248–249`), не `time_scale`, тож скелет під час hitstop анімується далі, і пружини реагують. Перевірити кадром; на різких змінах пози — `reset()`.

---

## 5. Відео з альфою: Higgsfield і Godot

| # | що | відповідь | джерело |
|---|---|---|---|
| V1 | Генерація відео з альфою в будь-якій моделі Higgsfield | **UNGROUNDED** | V2–V4 |
| V2 | Seedance 2.5, API | `prompt`, `duration` 4–30, `resolution` 480p/720p/1080p, `aspect_ratio`, **`output_format` "mp4" / "mov"**, `generate_audio`; про alpha/transparency/codec — нічого; чи несе `mov` альфу — невідомо | https://open.higgsfield.ai/models/bytedance/seedance-2.5/text-to-video/api-reference |
| V3 | AI Video Background Changer | **розходження**: пошуковий сніпет — «exports video with a clear alpha channel as WebM or MOV»; у живій сторінці (`curl`, пошук у HTML) «alpha» — 0, «ProRes» — 0, «WebM» — 1 (лише ім'я JS-файлу). Це постобробка, не генерація | https://higgsfield.ai/ai-video-background-changer |
| V4 | Замір T6 через `models_explore` | у `kling3_0_turbo` параметра прозорості немає; у `gpt_image_2_5` (**картинки**) є `background: transparent` | issue #42; [[2026-10-03-Behaviour-Cloth-VFX-Shaders]] |
| V5 | Відеоформати Godot 4.7 | «The only supported format in core is **Ogg Theora**»; WebM прибрано в 4.0, H.264/H.265 — ні (патенти) | `tutorials/animation/playing_videos.rst:11–21` |
| V6 | Theora і альфа | **альфи немає**: декодер бере площини Y/Cb/Cr (`modules/theora/video_stream_theora.cpp:235–247`), конвертер пише `*(DSTPTR)++ = 255;` (`thirdparty/misc/yuv2rgb.h:837`) — кадр завжди непрозорий | @ 4.7.2-stable |
| V7 | Вартість Theora | декодування на CPU; для мобільних «720p at most (preferably at 30 FPS or even lower)» | `playing_videos.rst:134–148`; `VideoStreamTheora.xml:6` |
| V8 | Хромакей | офіційний приклад — `CanvasItem`-шейдер на `VideoStreamPlayer`, `discard` за відстанню до `chroma_key_color`; у 3D — `VideoStreamPlayer.get_video_texture()` на quad | `playing_videos.rst:266–330`; `VideoStreamPlayer.xml:27–30` |

**План Б для D5 (кредити — лише слово Santos).**
- **(а) Основний — спрайт-шит.** Картинки з `background: transparent` (`gpt_image_2_5`, V4) → флібук `AnimatedSprite3D` або quad з атласом (`BaseMaterial3D.particles_anim_h_frames`, `BaseMaterial3D.xml:318`). Справжня альфа, без CPU-декодера, темп кадрів у руках гри.
- **(б) Запасний — відео на однотонному тлі** → Theora + хромакей (V8). Мінуси: ореол по краю, CPU-декодування (V7), напівпрозорий дим і пил ключуються погано.
- Чи є в Higgsfield `remove_background` для картинок/відео і скільки він коштує — **не перевірено**; підтверджує головна сесія через `models_explore`.

---

## Рекомендація для Аполлона і Гефеста (ТЗ шейдера D3) — факт чи вибір

| пункт | факт / місце | вибір (чий) |
|---|---|---|
| Колір контуру | `outline.gdshader:5` зараз `(0.06, 0.05, 0.09)`; Style-Guide `#2B2230` = (0.169, 0.133, 0.188) | замінити — колір підтверджує Аполлон |
| Одна тінь | `toon.gdshader:8` `bands = 3.0`; Style-Guide — «одна тінь» → `bands = 2` або ramp `GradientTexture1D` з двома зупинками (як eldskald / relink) | ramp чи `floor` — Гефест; м'якість межі — Аполлон |
| Тінт тіні | `toon.gdshader:10` синій; Style-Guide `#B07AA6` | замінити — Аполлон |
| Rim | `toon.gdshader:34–36`, лише освітлений бік | товщина й колір — Аполлон |
| Ширина контуру | у нас — простір об'єкта (`outline.gdshader:9`); clip-space — eldskald (MIT) | Гефест + Аполлон (Style-Guide: «вершинний колір R → товщина») |
| Контур на Low | `next_pass = null` (§3) | Гефест |
| Stencil як Ultra | experimental (T6, T7), прозорий прохід | Дедал/Гефест — чи брати experimental |
| Post-process контур | на Mobile з нормалями неможливий (T9) | лише Forward+, якщо взагалі |
| **Mobile: `light()`** | T2 ↔ T3 розходяться; якщо правий туторіал — на телефоні toon зникне | Гефест: явно задати `rendering/shading/overrides/force_vertex_shading.mobile=false` **і** перевірити кадром на пристрої |
| MSAA | `project.godot:233` — 4× на всіх платформах, `.mobile` немає; документація: >2× «unlikely to run smoothly on mobile» | профілі — Гермес/Гефест; `.mobile`-перевизначення — Гефест |

---

## Відкрите

1. **UNGROUNDED:** FPS/мс на M3 (Forward+ і Mobile) і на будь-якому телефоні — замір за списком §2; тестовий телефон не названо.
2. **Розбіжність T2 ↔ T3** (`force_vertex_shading` на мобільних): туторіал проти класу й сирців 4.7.2 — вирішить кадр на пристрої.
3. Stencil Outline на Mobile renderer — у таблиці рендерів рядка немає, не перевірено.
4. MetalFX на Mobile renderer — клас обмежує лише драйвером Metal, туторіал мовчить; не перевірено.
5. Перемикання рендера через `project_settings_override` у `user://` на iOS/Android — не перевірено на пристрої.
6. Вартість `SpringBoneSimulator3D` / `SoftBody3D` / `PhysicalBone3D` у числах — UNGROUNDED; пружини при hitstop — замір у D4.
7. Альфа-відео в Higgsfield — UNGROUNDED (V3: сніпет проти живої сторінки); `remove_background` і кодек `mov` — підтвердити головною сесією.
8. Компіляція сторонніх шейдерів (§1.2) на 4.7.2 не перевірена; Genshin-шейдер (CC0), ймовірно, для Godot 3.

## Related
- [[2026-10-03-Behaviour-Cloth-VFX-Shaders]] · [[Style-Guide]] · [[Cel-Shading]] · [[VFX-Direction]] · [[06-UI-UX]]
- [[2026-10-02-Engine-Physics]] · [[2026-10-03-Combat-Numbers-Grounding]] · [[2026-10-03-Picks-to-Game-and-Animation]]
- [[ADR-004-Physics-Is-Presentation]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-012-Menu-As-3D-Diorama]] · [[Higgsfield-Pipeline]] · [[Export-Platforms]] · [[state]]
