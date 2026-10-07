# Повний екран, 3D-апскейл, текстури й рантайм-детект — заземлення в Godot 4.7-stable

**Дата:** 2026-10-07 · **Роль:** T3 Архімед · **Крок:** 1 плану [[2026-10-07-Auto-Display-And-Quality]]

> Текст написав T3 Архімед (sub-agent з інструментами лише для читання). T1 записує його без змін змісту. Репозиторій T3 не змінював. Сирці, документи й зонд лежать поза репо, у `<scratchpad>/t3-display/`. На Mac, Windows і Wayland нічого не запускалось: висновки про M3 зроблені лише з сирців.
>
> T1 переперевірив у клоні тегу (`git rev-parse HEAD` → `5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88`): `display_server_macos.mm:2287-2293`, `rendering_device_driver_metal.cpp:2342-2345`, `renderer_viewport.cpp:1022-1030`, `rendering_server.cpp:3719` — збігаються. Підказка анізотропії в сирцях повна: «Disabled (Fastest),2× (Faster),4× (Fast),8× (Average),16× (Slow)», нижче вона скорочена.

## Питання
- (а) Чим `WINDOW_MODE_FULLSCREEN` (3) відрізняється від `WINDOW_MODE_EXCLUSIVE_FULLSCREEN` (4) на macOS, Windows, X11 і Wayland? Що робить `display/window/size/mode=3/4` при старті? Чи є в рушії готова клавіша повного екрана, і як це роблять на Mac?
- (б) `Viewport.scaling_3d_mode`: Bilinear, FSR 1.0, FSR 2.2, MetalFX spatial і temporal. Що доступне в Forward+ і Mobile на Metal, Vulkan і D3D12? Що буде, якщо вибрати недоступне? Як дізнатися про доступність у рантаймі?
- (в) Текстури: анізотропна фільтрація 16×, VRAM-формати й `textures/vram_compression/*`, максимальний розмір текстури, texture streaming.
- (г) Як у рантаймі дізнатися роздільність і масштаб екрана, назву й тип GPU і час кадру GPU?

## Джерела (доступ 2026-10-07)

| ID | Джерело, версія | Як отримано |
|---|---|---|
| G | Сирці `https://raw.githubusercontent.com/godotengine/godot/4.7-stable/<шлях>`. Тег = `5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88` | `git ls-remote … refs/tags/4.7-stable`. Shallow clone того самого тегу (`git rev-parse HEAD` → той самий хеш), тож рядки збігаються з raw URL. `version.py`: 4.7, stable. Бінар: `4.7.stable.official.5b4e0cb0f` |
| C | Class reference = `G/doc/classes/*.xml`. Це джерело сторінок docs.godotengine.org/en/4.7 | Сайт docs.godotengine.org → EGRESS_BLOCKED, тому цитується XML |
| D | Туторіали `https://raw.githubusercontent.com/godotengine/godot-docs/4.7/<шлях>`, гілка `4.7` = `9adca4c1c729…` | `git ls-remote`, curl 200 |
| A1 | Apple, Metal Feature Set Tables, `https://developer.apple.com/metal/Metal-Feature-Set-Tables.pdf`, нижній колонтитул «May 21, 2026», 18 с. | curl 200, 3 041 713 байт, `pdftotext` |
| A2 | Apple Support, Mac keyboard shortcuts (Control-Command-F) | support.apple.com → EGRESS_BLOCKED. Є лише пошуковий фрагмент (`support.apple.com/en-nz/guide/mac-help/mchl9c21d2be/10.14/mac`) |
| M1 | Microsoft, `D3D12_REQ_TEXTURE2D_U_OR_V_DIMENSION` | learn.microsoft.com → EGRESS_BLOCKED. Є лише пошуковий фрагмент «(16384)» (`learn.microsoft.com/en-za/windows/win32/api/d3d12video/ns-d3d12video-d3d12_video_size_range`) |
| E1 | Зонд: локальний Godot 4.7 official `--headless -s probe.gd` | Вихід наведено нижче |
| P | Проєкт: `game/project.godot`, `game/shaders/*.gdshader` на `7367e3e` | `grep -n` |

Вихід E1:
`WM_FULLSCREEN=3 WM_EXCL=4` · `S3D BILINEAR=0 FSR=1 FSR2=2 MFX_S=3 MFX_T=4 NEAREST=5` · `RD SUPPORTS_METALFX_SPATIAL=3 TEMPORAL=4 LIMIT_MAX_TEXTURE_SIZE_2D=12` · `ANISO_16X=4` · `aniso default=2` · `scaling mode default=0` · `driver.macos=metal driver.windows=vulkan` · `adapter_name='' type=0` · `rd=<Object#null>`.

## (а) Повний екран

**Що кажуть документи**
- FULLSCREEN (3): вікно без рамки на весь екран, «The display's video mode is not changed» (`G/doc/classes/DisplayServer.xml:3269-3271`). На macOS «A new desktop is used» (`:3273`).
- EXCLUSIVE (4): одне вікно, менше накладних витрат. Дочірнє вікно або перемикання застосунку викликає перехід із повного екрана (`:3277`). Відеорежим не змінюється (`:3278`). Може не працювати із запис-софтом (`:3279`).
  - Windows: можливе коротке чорне блимання (`:3281`).
  - macOS: окремий робочий стіл, Dock і меню не з'являються при наведенні на край (`:3282`).
  - X11: оминає композитор (`:3283`).
  - Wayland: те саме, що FULLSCREEN (`:3284`).
- Повний екран примусово вмикає borderless (`:2517`).

**Що робить код**
- **macOS.** Обидва режими викликають нативний `toggleFullScreen:`, тобто окремий Space (`G/platform/macos/display_server_macos.mm:2277-2284`). Вікно має `NSWindowCollectionBehaviorFullScreenPrimary` (`:153`), тому працює і зелена кнопка.
  - 4: `NSApplicationPresentationHideDock | HideMenuBar` (`:2287-2290`).
  - 3: `update_presentation_mode()` → `AutoHideMenuBar | AutoHideDock | FullScreen` (`:2292-2293`, `:2108-2124`, рядок `:2120`). Отже, при 3 рядок меню й Dock виїжджають, коли курсор біля краю; при 4 — ні. Код і документація збігаються.
  - Вхід у fullscreen ззовні (зелена кнопка) синхронізує режим: `windowDidEnterFullScreen` → `wd.fullscreen = true` (`G/platform/macos/godot_window_delegate.mm:112-118`).
- **Windows.**
  - EXCLUSIVE → `multiwindow_fs = false`, FULLSCREEN → `true` (`G/platform/windows/display_server_windows.cpp:2762-2766`).
  - Для FULLSCREEN вікно навмисно не дорівнює екрану: `MoveWindow(... size + off)` (`:2793-2794`), де `off` = (0,2) або (2,0) (`:219-251`). Плюс обрізка регіоном (`:2182`). EXCLUSIVE має точний розмір екрана.
  - На D3D12 рушій вимикає системний Alt+Enter DXGI: `MakeWindowAssociation(..., DXGI_MWA_NO_ALT_ENTER | DXGI_MWA_NO_WINDOW_CHANGES)` (`G/drivers/d3d12/rendering_device_driver_d3d12.cpp:2842`).
- **X11.** `_NET_WM_STATE_FULLSCREEN`. `_NET_WM_BYPASS_COMPOSITOR` = 1 для exclusive (композиція OFF) і 2 для FULLSCREEN (композиція ON) (`G/platform/linuxbsd/x11/display_server_x11.cpp:3079-3086`).
- **Wayland.** Обидва режими → `xdg_toplevel_set_fullscreen` (`G/platform/linuxbsd/wayland/wayland_thread.cpp:4957-4960`).
- **Відеорежим не змінюється ніде.** `grep -rn "ChangeDisplaySettings\|CGDisplaySetDisplayMode" platform/` → 0. `grep -c XRRSetCrtcConfig platform/linuxbsd/x11/display_server_x11.cpp` → 0 (є лише обгортки dlopen). API для зміни режиму екрана немає: у `DisplayServer.xml` з `screen_set_*` є лише `screen_set_keep_on` і `screen_set_orientation`.

**При старті**
- Значення в інспекторі: `"Windowed,Minimized,Maximized,Fullscreen,Exclusive Fullscreen"`, дефолт 0 (`G/core/config/project_settings.cpp:1722`).
- `main.cpp` читає `display/window/size/mode` (`G/main/main.cpp:2724`). На macOS його застосовує `_create_window` → `window_set_mode(p_mode, id)` (`display_server_macos.mm:257`), тобто анімований перехід у новий Space одразу на старті.
- Прапорець CLI `-f/--fullscreen` теж дає режим 3 (`main.cpp:1335-1337`).
- **Вбудовування гри в редактор** доступне лише у Windowed (`G/doc/classes/ProjectSettings.xml:1044`). Код повертає `EMBED_NOT_AVAILABLE_FULLSCREEN` для 3/4 і `..._MAXIMIZED` для 2 (`G/editor/run/game_view_plugin.cpp:886-895`).
- Підвікна типово вбудовані в головне вікно (`display/window/subwindows/embed_subwindows` = true, `ProjectSettings.xml:1102`). У P цього ключа немає: `grep -c subwindows game/project.godot` → 0. Тому обмеження EXCLUSIVE «одне вікно на екран» стосується лише нативних вікон.

**Порада документації D.** «Games should use the Exclusive Fullscreen window mode». Обґрунтування стосується Windows: FULLSCREEN «leaving a 1-pixel line at the bottom», а EXCLUSIVE «allows Windows to reduce jitter and input lag» (`D/tutorials/rendering/multiple_resolutions.rst:360-368`). Опис геометрії розходиться з кодом — див. U1.

**Клавіша**
- Готової клавіші або дії в рантаймі немає: `grep -c fullscreen core/input/input_map.cpp` → 0.
- Редактор Godot має свою: `Shift+F11`, а на macOS `Cmd+Ctrl+F` (`G/editor/editor_node.cpp:8983-8984`). Обробник просто викликає `window_set_mode(WINDOW_MODE_FULLSCREEN)` і повертає попередній режим (`:3881-3893`). Ті самі виклики доступні грі з GDScript.
- Стандартне меню macOS, яке створює рушій: Window → Minimize (⌘M), Zoom, Bring All to Front. Пункту повного екрана в ньому немає (`display_server_macos.mm:3747-3779`).
- Mac-конвенція Control-Command-F: Godot-редактор (G) + Apple (A2, лише пошуковий фрагмент).

## (б) 3D-апскейл

**Перелік режимів.** `SCALING_3D_MODE_BILINEAR=0, FSR=1, FSR2=2, METALFX_SPATIAL=3, METALFX_TEMPORAL=4, NEAREST=5` (`G/doc/classes/Viewport.xml:555-583`; E1). MetalFX: «Only supported when the Metal rendering driver is in use» (`Viewport.xml:569, :576`). У редакторі пункти MetalFX показуються лише в `mode.macos/.ios` (`G/servers/rendering/rendering_server.cpp:3757-3767`).

**Хто що може (код).** Бар'єр 1 — сеттер `viewport_set_scaling_3d_mode`:
- Якщо рендерер не `forward_plus`, FSR1/FSR2/MetalFX temporal дають `WARN_PRINT_ONCE_ED` і `return`: режим **не змінюється** (`G/servers/rendering/renderer_viewport.cpp:1022-1038`).
- MetalFX spatial блокується лише в `gl_compatibility` (`:1040-1043`).

Бар'єр 2 — щокадрові fallback-и в `renderer_viewport.cpp`:

| умова | що стається |
|---|---|
| spatial-режим при scale = 1,0 | OFF; temporal при 1,0 = native AA (`:147-154`) |
| Compatibility, будь-що крім Bilinear/Nearest | → Bilinear + WARN (`:156-160`) |
| Mobile + FSR / FSR2 / MetalFX temporal | → Bilinear + WARN (`:162-166`) |
| MetalFX temporal, `!has_feature(SUPPORTS_METALFX_TEMPORAL)` | → MetalFX spatial, якщо він є; інакше → FSR2 (`:168-179`) |
| MetalFX spatial, `!has_feature(SUPPORTS_METALFX_SPATIAL)` | → FSR1 (`:181-184`) |
| MetalFX temporal, scale поза [min; max] | → FSR2; якщо scale в межах — MSAA 3D вимикається внутрішньо (`:189-199`) |
| будь-що не-bilinear при scale > 1 | → Bilinear (`:204-210`) |
| апскейлер недоступний (`fsr_enabled = !is_low_end()`, `:999`) | → Bilinear (`:212-218`) |
| FSR2 або MetalFX temporal разом із TAA | TAA вимикається (`:219-224`) |

Помилки немає ніде, лише `WARN_PRINT_ONCE`.

**Де береться підтримка MetalFX**
- Metal: `metal_fx_spatial/temporal = MTLFX::{Spatial,Temporal}ScalerDescriptor::supportsDevice(...)`, лише якщо macOS ≥ 13 (`G/drivers/metal/metal_device_properties.cpp:181-187`). `METAL_MFXTEMPORAL_ENABLED` визначено для Metal без visionOS (`G/servers/rendering/renderer_rd/effects/metal_fx.h:33-35`).
- Vulkan і D3D12: `has_feature` → `default: return false` (`G/drivers/vulkan/rendering_device_driver_vulkan.cpp:7382-7421`; `G/drivers/d3d12/rendering_device_driver_d3d12.cpp:5879-5897`).
- Apple: MetalFX spatial — від Apple3, temporal — від Apple7. M3-series = Apple9 (A1, с. 2 і с. 5).
- Межі temporal scale: на macOS ≥ 14 беруться з `supportedInputContentMin/MaxScale`, інакше дефолт 1,0…3,0 (`metal_device_properties.cpp:337-350`). Ліміт = 1/maxScale … 1/minScale, помножений на 10⁶ (`G/drivers/metal/rendering_device_driver_metal.cpp:2646-2649`). За дефолтом це scale ∈ [0,333; 1,0].

**Таблиця для нашого проєкту.** У P: `renderer/rendering_method="forward_plus"`, `.mobile="mobile"` (`game/project.godot:283-284`). Ключа `rendering_device/driver*` немає.

| рендерер / драйвер | Bilinear, Nearest | FSR 1.0 | FSR 2.2 | MetalFX spatial | MetalFX temporal |
|---|---|---|---|---|---|
| Forward+ / Metal (macOS, дефолт `metal`, `G/main/main.cpp:2389`) | так | так | так (сирці не обмежують; на M3 не виміряно) | так, якщо `supportsDevice` | так, якщо `supportsDevice` і scale в межах |
| Forward+ / Vulkan (Windows у нашому P: дефолт `vulkan`, `main.cpp:2384`; Linux) | так | так | так | → FSR1 | → FSR2 |
| Forward+ / D3D12 (лише якщо в P прописати `driver.windows="d3d12"`; нові проєкти 4.6+ отримують його через `G/editor/editor_node.cpp:8351`) | так | так | так | → FSR1 | → FSR2 |
| Mobile / Metal (iOS) | так | ні → Bilinear | ні → Bilinear | так (`mfx_spatial`, `G/servers/rendering/renderer_rd/renderer_scene_render_rd.cpp:1881-1883`) | ні → Bilinear |
| Mobile / Vulkan | так | ні | ні | → FSR1, але об'єкт `fsr` у Mobile не створюється → **U5** | ні |

**Межа рендера.** Bilinear/Nearest обмежують внутрішній рендер `CLAMP(target * scale, 1, 16384)` (`renderer_viewport.cpp:233-240`). У FSR/MetalFX такого обмеження немає (`:242-249`).

**Як дізнатися в рантаймі**
- `RenderingServer.get_current_rendering_method()` і `get_current_rendering_driver_name()` (`G/doc/classes/RenderingServer.xml:1635-1648`).
- `RenderingServer.get_rendering_device().has_feature(RenderingDevice.SUPPORTS_METALFX_SPATIAL / _TEMPORAL)` (`G/doc/classes/RenderingDevice.xml:713-718, 2825-2830`).
- `limit_get(LIMIT_METALFX_TEMPORAL_SCALER_MIN_SCALE / _MAX_SCALE)`, значення ÷ 1 000 000 (`RenderingDevice.xml:2961-2967`).
- `get_rendering_device()` повертає null в OpenGL і headless (`RenderingServer.xml:1667`; E1 `rd=<Object#null>`).
- **`Viewport.get_scaling_3d_mode()` повертає запитаний режим, а не ефективний** (`G/scene/main/viewport.cpp:5056-5062`). Ефективний режим після fallback-ів іде в `rb_config.set_scaling_3d_mode` (`renderer_viewport.cpp:291`). Прочитати його можна лише через `RenderSceneBuffersRD.get_scaling_3d_mode()` (`G/doc/classes/RenderSceneBuffersRD.xml:117`), тобто зсередини CompositorEffect.

**Розходження документів між собою**
- `ProjectSettings.xml:3412`: «FSR will fall back to bilinear» у несумісному рендерері. Код (`:1026-1038`) просто ігнорує сеттер, тож білінійний результат буде лише тоді, коли попередній режим був Bilinear.
- `D/tutorials/3d/resolution_scaling.rst:46-57` не згадує ні MetalFX, ні Nearest. Туторіал відстає від C і G.

## (в) Текстури

**Анізотропна фільтрація**
- `rendering/textures/default_filters/anisotropic_filtering_level`, підказка `"Disabled,2×,4×,8×,16×"`, дефолт 2 = 4× (`G/servers/rendering/rendering_server.cpp:3719`; `ProjectSettings.xml:3464-3470`; E1 `aniso default=2`). **16× = значення 4** (`Viewport.xml:612`, E1).
- Сэмплер отримує `anisotropy_max = 1 << level` (`G/servers/rendering/renderer_rd/storage_rd/material_storage.cpp:2667`).
- Project setting читається лише на старті. У рантаймі треба задавати `Viewport.anisotropic_filtering_level` на root viewport (`ProjectSettings.xml:3469`; `viewport.cpp:5114-5121`, ініціалізація `:5582`).
- Діє лише на матеріали з фільтром `*_WITH_MIPMAPS_ANISOTROPIC` (`ProjectSettings.xml:3467`). `BaseMaterial3D.texture_filter` типово дорівнює 3 = `LINEAR_WITH_MIPMAPS` (`G/doc/classes/BaseMaterial3D.xml:427, 563`).
- У P анізотропію вже мають два шейдери: `filter_linear_mipmap_anisotropic` у `game/shaders/gear_surface.gdshader:8` і `game/shaders/hero_garment.gdshader:10`. `Flipbook.gd:59,103` ставить `LINEAR_WITH_MIPMAPS`.
- На Vulkan анізотропія вмикається лише за `samplerAnisotropy` пристрою (`G/drivers/vulkan/rendering_device_driver_vulkan.cpp:2768-2769`).

**VRAM-формати**
- `compress/high_quality` (`G/editor/import/resource_importer_texture.cpp:233`) обирає BPTC замість S3TC і ASTC замість ETC2 (`:935-939`, `:951-955`). Документація пояснює: BC7 для SDR, BC6H для HDR; без high_quality — DXT1/DXT5 і ETC2 (`D/tutorials/assets_pipeline/importing_images.rst:285-294`).
- `rendering/textures/vram_compression/import_s3tc_bptc` і `import_etc2_astc` — обидва дефолтно false (`rendering_server.cpp:3659-3660`). Це лише override: хост-формат імпортується завжди (`ProjectSettings.xml:3495-3504`; `G/editor/import/resource_importer_texture_settings.cpp:38-54`). ARM-хост віддає перевагу ETC2/ASTC, x86 — S3TC/BPTC (`G/core/os/os.cpp:747-755`).
- У P: `textures/vram_compression/import_etc2_astc=true` (`game/project.godot:285`).
- **Експорт macOS universal** додає features `s3tc`, `bptc` (`G/platform/macos/export/export_plugin.cpp:62-64`; arm64 — `etc2`, `astc`, `:65-67`). Universal вимагає ввімкнених обох імпортів (`:2488-2498`). Експорт пакує лише варіанти `path.<feature>` із цих features (`G/editor/export/editor_export_platform.cpp:1644-1678`).
- Рантайм перевіряє формат через `texture_is_format_supported_for_usage` (`G/servers/rendering/renderer_rd/storage_rd/utilities.cpp:274-288`). Metal — через `supportsBCTextureCompression` (`metal_device_properties.cpp:118`). Apple: «BC pixel formats … As of Apple9 all GPUs have support» (A1, с. 3, примітка 2).
- `compress_with_gpu` стискає на GPU лише BC1/3/4/5/6 (`ProjectSettings.xml:3490-3494`).
- Пам'ять (D, `importing_images.rst:230-246`): RGBA8 із mipmaps, 4096²: Lossless 85,33 МіБ, VRAM Compressed 21,33 МіБ.
- Арифметика T3 для 8192×4096 RGBA8: 8192·4096·4 = 134 217 728 Б = 128 МіБ, з mip ×4/3 = 170,67 МіБ. VRAM-стиснення 4:1 (за таблицею D) дає 32 МіБ, з mip — 42,67 МіБ.

**Максимальний розмір**

| де | ліміт | місце |
|---|---|---|
| Метод `RenderingDevice.limit_get(LIMIT_MAX_TEXTURE_SIZE_2D)` | значення 12 | `RenderingDevice.xml:2886`; E1 |
| Metal, Apple3+ | 16384 (інакше 8192) | `metal_device_properties.cpp:198-222`, віддається в `rendering_device_driver_metal.cpp:2585-2586` |
| Apple (A1, с. 8) | Apple3–Apple9 = 16 384 px, Apple10 = 32 768 px. Для M3 (Apple9) — 16384, збіг | A1 |
| Godot на Apple10 | лишає 16384 | `metal_device_properties.cpp:198-209` |
| D3D12 | `D3D12_REQ_TEXTURE2D_U_OR_V_DIMENSION`, значення 16384 лише з пошукового фрагмента M1 | `rendering_device_driver_d3d12.cpp:5806-5807` |
| Vulkan | `maxImageDimension2D` пристрою | `rendering_device_driver_vulkan.cpp:7290-7291` |
| `Image` | `MAX_WIDTH`/`MAX_HEIGHT` = 2²⁴, `MAX_PIXELS = 268435456 // 16384 ^ 2` | `G/core/io/image.h:69-71` |
| Імпортер без `process/size_limit` | Lossy 16383, Basis 16384, інакше 32768, з WARN | `resource_importer_texture.cpp:738-755`; опція 0..16383 — `:258` |
| D про mobile/web | «usually can't display textures larger than 4096×4096» | `importing_images.rst:500` |

**Texture streaming у 4.7 — ні.** `// Support for texture streaming is not implemented yet.` / `const bool stream = false;` (`resource_importer_texture.cpp:757-758`). У class reference немає жодного класу чи методу streaming: `grep -rn "texture streaming" doc/classes/` → 0.

## (г) Рантайм

**Екран**
- `screen_get_size` — «screen's size in pixels» (`DisplayServer.xml:1858`). На macOS це `NSScreen.frame` (пункти) × `screen_get_max_scale()` (`display_server_macos.mm:1448-1463`), а max scale — максимум серед усіх екранів, підрахований на старті (`:3686-3689`). Він не оновлюється при зміні конфігурації (`:1511`).
- `screen_get_usable_rect` — `visibleFrame` × max scale (`:1515-1535`). Реалізовано на X11, macOS і Windows (`DisplayServer.xml:1866-1868`).
- `screen_get_scale` на macOS = `backingScaleFactor`, якщо HiDPI дозволено (`display_server_macos.mm:1490-1506`). `display/window/dpi/allow_hidpi` дефолтно true (`main.cpp:2754`); у P ключа немає (`grep -n dpi game/project.godot` → порожньо). Документація: 2.0 на Retina, 1.0 в інших випадках. Метод реалізовано на Android, iOS, Web, macOS і Wayland; на Windows і X11 завжди 1.0 (`DisplayServer.xml:1849-1851`).
- `screen_get_max_scale` реалізовано лише на macOS (`DisplayServer.xml:1789`). `screen_get_dpi` неточний на macOS при дробовому масштабуванні (див. опис методу `screen_get_dpi` у тому ж XML).
- Обробки safe area або нотча в macOS-коді немає: `grep -n -i "safeArea\|notch" platform/macos/*.mm` → 0.

**GPU**
- `RenderingServer.get_video_adapter_name()` і `get_video_adapter_type()` (`RenderingServer.xml:1718-1731`) повертають `RenderingDevice.device.name/type` (`G/servers/rendering/renderer_rd/storage_rd/utilities.cpp:315-325`; `G/servers/rendering/rendering_device.cpp:7840-7846`).
- **Metal:** `device.type = DEVICE_TYPE_INTEGRATED_GPU` задано жорстко, `name = "<MTLDevice.name> (AppleN)"` (`G/drivers/metal/rendering_context_driver_metal.cpp:71-75`). Точний рядок на M3 не бачено.
- В OpenGL і headless тип = `DEVICE_TYPE_OTHER`=0 (`RenderingServer.xml:1730`; `RenderingDevice.xml:1370`; E1 `type=0`), ім'я порожнє (`:1722`; E1).

**Час кадру GPU**
- API є: `viewport_set_measure_render_time(rid, true)` → `viewport_get_measured_render_time_gpu(rid)` у мс (`RenderingServer.xml:4105-4112, 4286-4292`; реалізація — `renderer_viewport.cpp:1571-1590`).
- **На Metal у 4.7 результат = 0.** `timestamp_query_pool_get_results`: «Metal doesn't support timestamp queries, so we just clear the buffer» — `bzero` (`rendering_device_driver_metal.cpp:2342-2345`), а `command_timestamp_write` порожній (`:2354-2355`). Отже, `time_gpu_end - time_gpu_begin` = 0. Це висновок із сирців, на M3 не виміряно.
- CPU-частина: `viewport_get_measured_render_time_cpu` (`RenderingServer.xml:4097-4103`) і `get_frame_setup_time_cpu` (`:1657-1661`).

## UNGROUNDED
- **U1 — геометрія Windows FULLSCREEN.** D: «leaving a 1-pixel line at the bottom» (`multiple_resolutions.rst:366`). G: вікно на 2 px **більше** за екран (вниз або вправо) з обрізкою регіоном (`display_server_windows.cpp:219-251, 2182, 2793-2794`). Спільне в обох: FULLSCREEN навмисно не дорівнює екрану, EXCLUSIVE дорівнює. Деталі розходяться.
- **U2 — Windows-конвенція F11 / Alt+Enter.** Джерела в цій сесії немає. Редактор Godot використовує Shift+F11 (`editor_node.cpp:8983`), а DXGI Alt+Enter рушій вимикає (D3D12, `:2842`).
- **U3 — чи спрацює Ctrl+Cmd+F на Mac без коду гри**, тобто чи вставляє AppKit пункт «Enter Full Screen» у меню Window, яке створює рушій. У меню рушія такого пункту немає (`display_server_macos.mm:3747-3779`). Поведінку AppKit не заземлено, на Mac не перевірено.
- **U4 — значення 16384 для D3D12** відоме лише з пошукового фрагмента (M1). Сторінку не відкрито (EGRESS_BLOCKED).
- **U5 — Mobile + MetalFX spatial на не-Metal.** Fallback веде у FSR1 (`renderer_viewport.cpp:181-184`), але в Mobile `fsr` не створюється (`renderer_scene_render_rd.cpp:1878-1880`; `G/servers/rendering/renderer_rd/forward_mobile/render_forward_mobile.cpp:464-466`). Фактичний результат не визначено.

## Що лишилось відкритим
- Нічого не запускалось на macOS, Windows чи Wayland. Не бачено: перехід у Space на старті з mode 3/4, нотч MacBook у fullscreen, якість і вартість FSR2 на Metal, точний рядок назви адаптера на M3, нульовий GPU-час на Metal.
- Apple Support (A2), Microsoft (M1) і docs.godotengine.org недоступні (EGRESS_BLOCKED). Class reference взято з XML-джерела (C).
- Чи вистачить для AUTO-контролера на M3 CPU-часу рендера й часу кадру — не досліджено.

## Що з цього випливає для плану (лише факти)
1. На macOS режими 3 і 4 — це той самий нативний fullscreen в окремому Space. Різниця одна: при 3 рядок меню й Dock виїжджають біля краю, при 4 — ні. Жоден режим на жодній платформі не змінює відеорежим монітора. Опис Е3 («зі зміною роздільності монітора») у 4.7 не існує.
2. Готової клавіші повного екрана в рантаймі немає. Редактор Godot сам робить Shift+F11 і на macOS Cmd+Ctrl+F через `window_get_mode`/`window_set_mode`, і ті самі виклики доступні грі. На D3D12 системний Alt+Enter вимкнений рушієм.
3. Запуск з редактора при mode 2/3/4 не вбудовується в редактор: гра відкривається окремим вікном. Вбудовування — лише при mode 0.
4. MetalFX (обидва) є лише на Metal. Для macOS у нашому P це дефолтний драйвер. На Windows наш P іде через Vulkan (ключа `driver.windows` немає), тому там доступні FSR1/FSR2. Mobile дає лише Bilinear/Nearest (і MetalFX spatial на Metal).
5. Недоступний режим не дає помилки: тихий fallback з `WARN_PRINT_ONCE` (temporal → spatial → FSR2; spatial → FSR1; Mobile → Bilinear). `Viewport.get_scaling_3d_mode()` при цьому показує запитаний режим, тому доступність треба перевіряти до вибору: `get_current_rendering_method()` + `has_feature(SUPPORTS_METALFX_*)` + `limit_get(LIMIT_METALFX_TEMPORAL_SCALER_*)`.
6. MetalFX temporal і FSR2 вимикають TAA. MetalFX temporal ще й MSAA 3D. Поточні MSAA 2×/4× профілів у такому режимі не діятимуть.
7. `viewport_get_measured_render_time_gpu` на Metal у 4.7 = 0 (timestamp-заглушки), тож AUTO-контролер на M3 не має GPU-часу з рушія.
8. 16× анізотропія = `anisotropic_filtering_level=4` (дефолт 2 = 4×). Вона діє лише на матеріали з анізотропним фільтром (дефолт BaseMaterial3D — без нього). Два наші шейдери його вже мають.
9. Ліміт 2D-текстури на M3 — 16384 (Godot і Apple збігаються). Bilinear-рендер 3D обмежений 16384, 8K (7680×4320) у межах. Texture streaming у 4.7 немає. Universal-збірка macOS пакує S3TC/BPTC, і M3 їх підтримує.
10. На macOS `screen_get_size` = пункти екрана × max scale усіх екранів, а не фізичні пікселі панелі (у scaled-режимах вони різні). `screen_get_scale` дорівнює 2.0 лише на macOS/Wayland/мобільних, на Windows і X11 завжди 1.0. Тип GPU на Metal завжди INTEGRATED, тож тип адаптера не розрізняє силу Apple GPU.

## Related
- [[state]] · [[constitution]] · [[2026-10-07-Auto-Display-And-Quality]] · [[2026-10-07-Auto-Window-Size]] · [[2026-10-07-Auto-Window-Size-Fix]]
- [[2026-10-05-Graphics-Quality-And-Surface-Filtering]] · [[2026-10-07-M3-Acceptance-Checklist]] · [[Export-Platforms]] · [[Textures-Registry]] · [[06-UI-UX]]
