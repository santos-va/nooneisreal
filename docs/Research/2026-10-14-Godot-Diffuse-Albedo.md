# Godot 4.7: чи множить рушій `DIFFUSE_LIGHT` на `ALBEDO` після `light()`

**Дата:** 2026-10-14 · **Роль:** T3 Архімед · **Крок:** 1 плану [[2026-10-14-T6-Acceptance-Crane-Albedo-AB]]

> Текст написав T3 Архімед (sub-agent з інструментами лише для читання). Сесія, що викликала, записує його без змін змісту. Репозиторій T3 не змінював. Сирці, документація й зонд лежать у scratchpad: `t3-albedo-src/`, `t3-albedo-docs/`, `t3-albedo-probe/`. Godot запускався лише з `--path <scratchpad>/t2b-tree/game`; після прогону `git status --short --ignored` у `t2b-tree` порожній. На M3 і на Forward+ нічого не запускалось: висновки про Forward+ і Mobile зроблені лише з сирців і документації.

## Питання

1. Чи множить Godot 4.7 у spatial-шейдері накопичений `DIFFUSE_LIGHT` на `ALBEDO` після `light()`? Якщо так, то `city_surface.gdshader:119-120` дає колір у квадраті.
2. Як із цим пов'язана `EMISSION` (`city_surface.gdshader:112`: `EMISSION = paint * (painted_fill + glow)`)?
3. У якому просторі живе `ALBEDO`: лінійному чи sRGB? Як рушій перетворює `source_color` і uniform-и?
4. Який рендерер у проєкті, що буде на M3, і чи там те саме множення?

## Джерела (доступ 2026-10-14)

| ID | Джерело, версія | Як отримано |
|---|---|---|
| G | Сирці `https://raw.githubusercontent.com/godotengine/godot/4.7-stable/<шлях>`. Тег = `5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88` | `git ls-remote https://github.com/godotengine/godot.git refs/tags/4.7-stable` → цей хеш. `version.py`: `major = 4`, `minor = 7`, `status = "stable"`. Бінар: `godot --version` → `4.7.stable.official.5b4e0cb0f`. Копії в scratchpad `dl_godot47_shaders/` і `godot47/` побайтно ті самі, що й тег: sha256 `453d31b4…` (`scene_forward_clustered.glsl`) і `2c77be0c…` (`scene.glsl`) |
| C | Class reference = `G/doc/classes/ProjectSettings.xml`. Це джерело сторінки `docs.godotengine.org/en/4.7/classes/class_projectsettings.html` | curl 200 з тегу G |
| D | Документація «Spatial shaders»: `https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html`. Джерело сторінки — `godot-docs`, гілка `4.7` = `9adca4c1c72917bfe1b7be3108abed5ce26696a6`, файл `tutorials/shaders/shader_reference/spatial_shader.rst` (sha256 `fca41f1c…`). Також `shading_language.rst` тієї ж гілки | Сайт docs.godotengine.org недоступний (curl: `CONNECT tunnel failed, response 403`; WebFetch: `ENOTFOUND`), тому цитується RST. `git ls-remote` гілки `4.7`, curl 200. Гілка `stable` дає побайтно той самий RST (`cmp` → same) |
| E | Зонд: Godot 4.7 official, `gl_compatibility`, llvmpipe (Mesa 25.2.8), xvfb. Скрипт `t3-albedo-probe/probe.gd` будує сцену в коді: SubViewport 800×160, MSAA off, тонмап Linear, ambient вимкнено, одне `DirectionalLight3D` (енергія 1), 5 квадів зі своїми шейдерами | Команда й вихід — нижче |
| P | Проєкт на `e6379ed`: `game/project.godot`, `game/shaders/*.gdshader`, `CityMaterials.gd`, `CityWorld.gd` | `grep -n`, `sed -n` |

## Відповідь: **ТАК**, у всіх трьох рендерерах

Код `light()` вставляється всередину рушійної функції `light_compute()`. Після циклу всіх світел рушій один раз множить накопичене `diffuse_light` на `albedo`. Це та сама змінна, яку `light()` читає як `ALBEDO`. Отже, якщо `light()` уже клала `ALBEDO` в `DIFFUSE_LIGHT`, на екрані пряме світло пропорційне `ALBEDO²`.

| рендерер | `light()` пише в | множення після циклу | вихід |
|---|---|---|---|
| Forward+ (`scene_forward_clustered.glsl`) | `scene_forward_lights_inc.glsl:121` `#if defined(LIGHT_CODE_USED)` → `:155` `vec3 albedo_highp = vec3(albedo);` → `:163` `vec3 diffuse_light_highp = vec3(diffuse_light);` → `:171` `#CODE : LIGHT` → `:174` `diffuse_light = hvec3(diffuse_light_highp);` | `:3048` `diffuse_light *= albedo; // ambient must be multiplied by albedo at the end` (гілка кольорового проходу: `#ifdef MODE_RENDER_DEPTH` `:2904` … `#else` `:3045`) | `:3090` `frag_color = vec4(emission + ambient_light + diffuse_light + direct_specular_light + indirect_specular_light, alpha);` |
| Mobile (`scene_forward_mobile.glsl`) | той самий include, `:1038` `#include "../scene_forward_lights_inc.glsl"` | `:2311` `diffuse_light *= albedo; // ambient must be multiplied by albedo at the end` | `:2346` `hvec4 out_color = hvec4(emission + ambient_light + diffuse_light + …)` |
| Compatibility (`drivers/gles3/shaders/scene.glsl`) | `:1575` `#if defined(LIGHT_CODE_USED)` → `:1593` `#CODE : LIGHT` | `:2778` `diffuse_light *= albedo;` (базовий прохід); `:3054` те саме в додатковому проході світла | `:2782` `frag_color = vec4(diffuse_light + specular_light, alpha);` · `:2783` `frag_color.rgb += emission + ambient_light;` |

**Чому `ALBEDO` у `light()` — це те саме `albedo`, що множиться:**
- `scene_shader_forward_clustered.cpp:748` `actions.renames["ALBEDO"] = "albedo_highp";` і `:805` `actions.renames["DIFFUSE_LIGHT"] = "diffuse_light_highp";`.
- Mobile: `scene_shader_forward_mobile.cpp:688` і `:745`, ті самі імена.
- Compatibility: `drivers/gles3/storage/material_storage.cpp:1305` `actions.renames["ALBEDO"] = "albedo";` і `:1362` `actions.renames["DIFFUSE_LIGHT"] = "diffuse_light";`.
- Після `fragment()`: Forward+ `:1356` `vec3 albedo = albedo_highp;`, Mobile `:1274` `hvec3 albedo = hvec3(albedo_highp);`. Цей `albedo` передається в `light_compute(...)` (Forward+ `:2671`, Compatibility `:2965`) і множиться в `:3048` / `:2311` / `:2778`.

**Документація (D) словами цього не каже, але й не суперечить.** `spatial_shader.rst:551` — «Below is an example of a custom ``light()`` function using a Lambertian lighting model». У прикладі `:562` немає `ALBEDO`: `DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;`. Ламбертова модель (альбедо/π · світло · cos) виходить із цього рядка лише тоді, коли альбедо домножує рушій. Таблиця: `:621` `in vec3 ALBEDO` — «Base albedo.», `:629` `out vec3 DIFFUSE_LIGHT` — «Diffuse light result.». Розбіжності немає, є неявність. Явно це сказано в коді G і підтверджено зондом E.

### Зонд E на офіційному бінарі (Compatibility)

Команда (з `<scratchpad>/t3-albedo-probe`, XDG-теки в scratchpad):

```
xvfb-run -a -s '-screen 0 1280x480x24 -nolisten tcp' <scratchpad>/bin/godot --path <scratchpad>/t2b-tree/game \
  --rendering-method gl_compatibility --rendering-driver opengl3 --audio-driver Dummy -s <scratchpad>/t3-albedo-probe/probe.gd
```

Вихід (`run2.log`, rc=0; помилки автозавантажень проєкту без імпорту на зонд не впливають, бо він має власний SubViewport і `own_world_3d`):

```
T3PROBE renderer=gl_compatibility version=4.7-stable (official) image=(800, 160)
T3PROBE A_albedo05_diffuse1 rgb8=(128,128,128)
T3PROBE B_albedo05_diffuseALBEDO rgb8=(61,61,61)
T3PROBE C_emission008_albedo0 rgb8=(17,17,17)
T3PROBE D_uniformC_in_light_albedo1 rgb8=(188,188,188)
T3PROBE E_albedo_from_uniformC rgb8=(128,128,128)
```

| кейс | шейдер | прогноз «рушій множить» | прогноз «не множить» | виміряно |
|---|---|---|---|---|
| A | `ALBEDO = vec3(0.5)`; `DIFFUSE_LIGHT += vec3(1.0)` | 128 | 255 | **128** |
| B | `ALBEDO = vec3(0.5)`; `DIFFUSE_LIGHT += ALBEDO` | 61 (A²) | 128 | **61** |
| C | `ALBEDO = 0`; `EMISSION = vec3(0.08)` | 17, якщо `EMISSION` читається як sRGB-число; 80, якщо як лінійне | — | **17** |
| D | `uniform vec4 c : source_color` = `Color(0.5,0.5,0.5)`; `ALBEDO = 1`; `DIFFUSE_LIGHT += c.rgb` | 188, якщо uniform сирий (sRGB); 128, якщо перетворений у лінійний | — | **188** |
| E | `ALBEDO = c.rgb`; `DIFFUSE_LIGHT += vec3(1.0)` | 128 | — | **128** |

Прогнози порахував за формулами Compatibility з `tonemap_inc.glsl:14-25` до запуску. У кейсах A–D гіпотези розходяться на 60–127 рівнів з 255. Кейс B ще й відрізняє лінійне освітлення (61) від освітлення на sRGB-числах (0,5 · 0,5 → 64). Forward+ і Mobile тут не запускаються: Vulkan ICD немає (`ls /usr/share/vulkan/icd.d/` → «No such file or directory»).

## `EMISSION`

`EMISSION` додається **один раз і лінійно**. На альбедо вона не множиться: Forward+ `:3090`, Mobile `:2346`, Compatibility `:2783`. У Forward+ перед цим `:1682` `emission *= scene_data.emissive_exposure_normalization;`. Без `CameraAttributes` цей множник 1,0 (`render_scene_data_rd.cpp:255-256`); `grep -rn CameraAttributes game/scenes game/scripts` → порожньо.

Отже, у `city_surface` заливка `paint · painted_fill` — лінійна за альбедо, а пряме світло — квадратичне. Для темних кольорів у Forward+ переважає заливка. **У Compatibility заливка значно слабша**, бо рушій читає `EMISSION` як sRGB-число (`scene.glsl:2399` `emission = srgb_to_linear(emission);`, кейс C). У Forward+ заливка дорівнює 0,16 · lin(p), у Compatibility — s2l(0,16 · p), тобто в 4,8–7,5 раза менше для p від 0,2 до 0,9. Розрахунок: `python3 -I <scratchpad>/t3-albedo-probe/formula_table.py` → `emission ratio F+/Compat: [(0.2, 4.77), (0.5, 6.2), (0.9, 7.47)]`, s2l — поліном `tonemap_inc.glsl:22-25`.

## Колірний простір: `source_color` і uniform-и

**Forward+ і Mobile.** Рахують у лінійному просторі (D, `shading_language.rst:939-941`: «This is because Godot renders in linear color space»).
- Колір uniform-а перетворюється з sRGB у лінійний на CPU, точною формулою (`core/math/color.h:192-198`).
- Значення, задане з коду (`set_shader_parameter(…, Color)`), перетворюється, якщо це `Color`. Правило: `storage_rd/material_storage.cpp:801` → `storage/variant_converters.h:208-211`. Виняток — uniform-и з підказкою `color_conversion_disabled` (`:798-799`).
- Значення за замовчуванням із шейдера перетворюється лише з `source_color` (`:806`).
- Для 3D прапорець увімкнено: `scene_shader_forward_clustered.cpp:596` і `scene_shader_forward_mobile.cpp:549` (`…, true, true)`).
- Проєкт передає `Color("…")` (`CityMaterials.gd:37-39`). Тому у Forward+ `albedo`, `ink_color` і `shadow_tint` приходять у шейдер уже лінійними. Уся арифметика `fragment()` і `light()` іде в лінійному просторі.
- Колір світла: `light->color.srgb_to_linear()`, енергія × π (`storage_rd/light_storage.cpp:761`, `:768`). Тонмап і перетворення в sRGB — окремим проходом після сцени.

**Compatibility.**
- Uniform-и **не** перетворюються: `drivers/gles3/storage/material_storage.cpp:766-770` викликає `_fill_std140_*` без прапорця кольору. Тому `fragment()` рахує на сирих sRGB-числах.
- Після `fragment()` рушій сам переводить у лінійний простір лише `ALBEDO` і `EMISSION`: `scene.glsl:2397-2399` `// Convert colors to linear` · `albedo = srgb_to_linear(albedo);` · `emission = srgb_to_linear(emission);`.
- Світло рахується лінійно (колір світла `.srgb_to_linear()`, `rasterizer_scene_gles3.cpp:1763`; × π `:1756`). Вихід — `linear_to_srgb` прямо в шейдері (`:2798`).
- Обидва перетворення — наближені поліноми (`tonemap_inc.glsl:14-25`, «Approximation from …chilliant…»).
- Uniform, який читає сама `light()` (у нас `shadow_tint.rgb`), лишається **сирим sRGB-числом** (кейс D).

**UNGROUNDED щодо колірного простору Compatibility.** Документація й код тут розходяться:
- C, `ProjectSettings.xml:3283` (`gl_compatibility`): «Lighting calculations are performed on nonlinear sRGB-encoded color data, which produces inaccurate results that may look acceptable for some games.»
- G, `scene.glsl:2397-2399` і `:2798`: альбедо й емісія переводяться в лінійний простір перед освітленням, результат — назад у sRGB. Зонд E (кейси B, C, D) збігається з кодом, а не з цим реченням.
- `shading_language.rst:948-953` («The ``source_color`` hint is optional for the Compatibility renderer») з кодом узгоджується: для `ALBEDO` рушій перетворює колір сам (кейс E = кейс A).

На головну відповідь («так, множить») ця розбіжність не впливає.

## Формула кінцевого кольору

Позначення:
- A — `ALBEDO` після `fragment()`, лінійне;
- E — `EMISSION`;
- c, e — колір і енергія сонця;
- k — `key_gain`;
- f, g — `painted_fill`, `glow`;
- T — `shadow_tint`;
- S = 0,5 · 0,65 + 0,35 · T;
- `lit` — `city_surface.gdshader:118`.

`LIGHT_COLOR` = lin(c) · e · π (D, `spatial_shader.rst:607-610`; G, `light_storage.cpp:761`, `:768`).

**Загально (усі рендерери, `METALLIC` 0, AO 1, specular вимкнено):**
`колір_лін = E + A · Σ DIFFUSE_LIGHT(світла) + A · ambient`, далі тонмап і sRGB.

**`city_surface`, Forward+ і Mobile** (ambient вимкнено, `:4`; одне сонце):
- `DIFFUSE_LIGHT = mix(A·S, A, lit) · lin(c)·e·π · k / π`
- світло: `колір_лін = A·(f+g) + A² · lin(c)·e·k`
- тінь: `колір_лін = A·(f+g) + A² · S · lin(c)·e·k`
- A, T — лінійні значення палітри.

**`city_surface`, Compatibility:**
- форма та сама, `A = s2l(p)`, `E = s2l(p · (f+g))`;
- p — колір `fragment()`, порахований на sRGB-числах;
- S бере T сирим;
- результат — `l2s(колір_лін)` у шейдері (s2l, l2s — поліноми з `tonemap_inc.glsl`).

Квадрат A² є в обох випадках. Емісія й колір тіні між рендерерами різні.

**Ілюстрація за формулою, не замір кадру.** Сонце `CityWorld.gd:466-467` (1,0; 0,97; 0,94), енергія 0,95; k = 2,2, f = 0,16 (`city_surface.gdshader:17-18`). Тонмап Linear (у `CityWorld.gd` не задано, тож лишається типовий `Environment`). Колір — sRGB 0–255, освітлена смуга, `surface_kind` 0:

| ключ | палітра | Forward+ зараз | Forward+ без другого множення (Б1) | Compatibility зараз |
|---|---|---|---|---|
| `iron_paint` `#577368` | 87, 115, 104 | 52, 82, 67 | 128, 162, 143 | 41, 71, 56 |
| `plaster` `#b6aa92` | 182, 170, 146 | 193, 166, 122 | 255, 237, 199 | 182, 154, 111 |
| `paving` `#8a8581` | 138, 133, 129 | 116, 106, 98 | 199, 187, 176 | 105, 95, 86 |

Команда: `python3 -I <scratchpad>/t3-albedo-probe/formula_table.py`. Для Forward+ — точна формула sRGB, для Compatibility — поліноми `tonemap_inc.glsl`. Числа ΔE і кадри A/B — крок 5 (T2-Б).

## Що це означає

**`city_surface.gdshader`.**
- `:119-120` кладе `ALBEDO` в `DIFFUSE_LIGHT`, рушій множить ще раз. Пряме світло міста дорівнює A² на всіх трьох рендерерах. Знахідку T6 ([[2026-10-08-City-Modern-Realism-Props]] § «Як рахується тінь шейдера») підтверджено.
- Б1 з плану (прибрати `ALBEDO` з `light()`) дає `DIFFUSE_LIGHT = mix(S, 1, lit) · LIGHT_COLOR · k / π`. Тоді на екрані `A·(f+g) + A · lin(c)·e·k`.
- Обирати варіант — не T3, а Santos після кадрів T6.

**Знахідка для кроку 5.** Кадри A/B на Linux робляться в Compatibility. Santos грає у Forward+ (див. нижче). У двох рендерерах однакова палітра дає різний екран:
- емісія у Compatibility в 4,8–7,5 раза слабша (кейс C);
- `shadow_tint` у `light()` сирий, а не лінійний (кейс D).

Отже, ΔE з llvmpipe не є ΔE на M3. Це треба або рахувати за формулою Forward+ поруч, або явно позначати «Compatibility».

**Модель Compatibility пояснює лише напрям розбіжності T6.** У [[2026-10-08-City-Modern-Realism-Props]] T6 підганяв сірі кулі й отримав світло 2,685·A² + 0,074·A проти формули 2,09·A² + 0,16·A. Для тіні — 1,617·A² + 0,059·A проти 1,00·A² + 0,16·A. Причину T6 «не з'ясував». Модель Compatibility (поліноми, сира `T`, емісія як sRGB) на тих самих сірих `#40…#C0` дає світло 2,052·A² + 0,038·A і тінь 1,172·A² + 0,031·A (той самий `formula_table.py`, `numpy.linalg.lstsq`). Тобто напрям пояснено: емісія слабша, тінь вища. Величину не пояснено. Відкрите.

**4 шейдери з rim: поправка до таблиці аудиту плану.** `ALBEDO` в них не лише в rim, а й в основному тоні. Тому A² — це все пряме світло героїв, спорядження й меча:

| шейдер | основний тон з `ALBEDO` | rim з `ALBEDO` |
|---|---|---|
| `toon.gdshader` | `:39` `shade = mix(ALBEDO * shadow_tint.rgb, ALBEDO, k)` → `:40` `DIFFUSE_LIGHT += shade * …` | `:43` |
| `sword_dissolve.gdshader` | `:87` → `:88` | `:91` |
| `hero_garment.gdshader` | `:67-69` → `:70` | `:73` |
| `gear_surface.gdshader` | `:56-57` (`shadow`, `shaded` з `ALBEDO`) → `:60` | `:60` (`ALBEDO * edge * rim`) |

Ще три деталі цих чотирьох шейдерів:
- (а) Вони не ділять на π, а `LIGHT_COLOR` уже містить π. Тому їхнє пряме світло в π разів сильніше, ніж у ламбертовому прикладі документації `spatial_shader.rst:562` з тією самою енергією (D `:607-610`, G `light_storage.cpp:761`).
- (б) Ambient у них увімкнено, і рушій множить його на альбедо один раз: Forward+ `:2185`, Mobile `:1863`, Compatibility `:2580`. Отже, у героїв тінь від ambient лінійна за A, а пряме світло квадратичне.
- (в) `shadow_tint.rgb` у `light()` так само сирий у Compatibility і лінійний у Forward+.

## Рендерер проєкту й M3

- `game/project.godot:17` `config/features=PackedStringArray("4.7", "Forward Plus")`, `:283` `renderer/rendering_method="forward_plus"`, `:284` `renderer/rendering_method.mobile="mobile"`.
- `rendering_device/driver*` і `force_vertex_shading` у `project.godot` не задано (`grep -n "driver\|vertex_shading" game/project.godot` → порожньо). Типові значення (C):
  - `driver.macos` = `"metal"` (`ProjectSettings.xml:3333-3337`: «Metal from native drivers, only supported on Apple Silicon Macs»);
  - `force_vertex_shading` = `false` (`:3441`), тобто `light()` виконується (D `spatial_shader.rst:568-572`).
- Отже, на M3 очікується Forward+ на Metal: той самий `scene_forward_clustered.glsl` і те саме множення `:3048`. **На M3 не перевірено.** `AutoQuality.gd:125` лише враховує можливий фолбек на `gl_compatibility`, але не вмикає його.
- Linux CI і нативні кадри T2/T6 роблять явно `--rendering-method gl_compatibility` (`.github/workflows/ci.yml:79`, `tools/camera/tight_station_probe.gd:8`). Множення там теж є (`scene.glsl:2778`), але колірний простір інший (див. вище).

## Відкрите

- Forward+ і Mobile не запускались: тут немає Vulkan ICD. Для них відповідь стоїть на G і D без заміру. Замір на M3 — разом із [[2026-10-07-M3-Acceptance-Checklist]].
- Речення `ProjectSettings.xml:3283` про sRGB-освітлення в Compatibility суперечить коду й заміру (UNGROUNDED вище). Чи це застарілий текст документації — не з'ясовано.
- Модель Compatibility пояснює напрям, але не величину коефіцієнтів T6 (2,685 / 1,617).
- Мобільний порт: D `spatial_shader.rst:572` пише, що Force Vertex Shading «enabled by default on mobile platforms» (тоді `light()` не виконується взагалі). C `ProjectSettings.xml:3441` дає лише `default="false"` і не має `.mobile`-перевизначення. Для Android/iOS це треба перевірити окремо; на M3 це не впливає.
- Вибір А / Б1 / Б2 — Santos після кадрів кроку 5. T3 не обирає.

## Related
- [[2026-10-14-T6-Acceptance-Crane-Albedo-AB]] · [[ADR-027-City-Modern-Props-Style-And-Path]] · [[2026-10-08-City-Modern-Realism-Props]]
- [[2026-10-09-City-Vehicles-And-Iron-Paint-Fix]] · [[Cel-Shading]] · [[Style-Guide]] · [[2026-10-03-Toon-Quality-Cloth]]
- [[2026-10-07-M3-Acceptance-Checklist]] · [[state]] · [[constitution]]
