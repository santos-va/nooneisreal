# Fix-журнал — Запуск 4-0: гейти після імпорту героїв

**Роль:** T2 Гефест, 2026-10-03. **План:** [[2026-10-03-Path-to-First-Fight]] § Запуски, рядок 4-0 (T1). **Аудит:** [[2026-10-03-Launch-2-PR60]] пропозиції 2 і 3.

## Звірка плану з репо (до роботи)

- `git checkout -B claude/friendly-ritchie-3ti2sm origin/main` → `bc835fa` (PR #74 моєї гілки вже змерджено, нових комітів на гілці немає).
- `godot --version` → `4.7.stable.official.5b4e0cb0f` — Godot у цьому контейнері **є** (план каже «немає» — то про контейнер T1).
- `ls game/assets/characters/models/` → лише `choko_m0.glb`, `skea_m1.glb`; `.import` для них у git немає.
- `godot --headless --path game --import` (11.8 с) → `git status --porcelain`: нові `choko_m0_Image_0.jpg` (2 995 097 B, 2048²),
  `skea_m1_Image_0.jpg` (3 575 326 B, 2048²) + їхні `.import` + два `.glb.import`. Заява з [[2026-10-03-launch-4-ual-source]] підтверджена.
- Причина — `gltf/embedded_image_handling=1` у згенерованому `.glb.import`. Назва константи — з самого рушія
  (`ClassDB.class_get_integer_constant_list("GLTFState")`): `0 DISCARD`, `1 EXTRACT_TEXTURES`, `2 EMBED_AS_BASISU`, `3 EMBED_AS_UNCOMPRESSED`.
- `Main.gd:4–10`: розбір `OS.get_cmdline_user_args()` вбудовано в `_ready()` — чистої функції немає (п. 9 аудиту підтверджено).
- `GameState.gd:43` → `var free_move: bool = true`; `SmokeTest._ready():81` → `set_free_move(false)` без перевірки дефолту (п. 8 підтверджено).
- Розбіжностей із планом немає.

## Що зроблено

- **(а) Імпорт героїв.** Закомічено `choko_m0.glb.import` і `skea_m1.glb.import` (згенеровані рушієм) з однією правкою:
  `gltf/embedded_image_handling=2` (Embed as Basis Universal) замість `1`. Текстура лишається всередині зареєстрованого GLB:
  на свіжому клоні (`rm -rf game/.godot` → `--import`) `git status` показує лише два `.glb.import`, жодного `*_Image_0.jpg`.
  Проба `load(...).instantiate()` → `albedo_texture` = `choko_m0.glb::PortableCompressedTexture2D_…`, 2048×2048 (так само Skea).
  Рядки реєстру Аполлону не потрібні. Чому BasisU, а не `3` (без стиснення): один формат на десктоп і мобільні, менше VRAM;
  якщо cel-матеріалу Аполлона на запуску 5 знадобиться окремий файл або без стиснення — це рішення запуску 5 (ризик із плану).
- **(б) Пропозиція Феміди 2** — `SmokeTest._check_boot()`: дефолт `free_move` читається зі свіжого, не доданого в дерево екземпляра
  скрипта `GameState` (`get_property_default_value` поза редакторською збіркою повертає `null` — перша спроба червоніла саме так),
  плюс живе значення після `Main._ready` має збігатися з тим, що просять аргументи.
- **(б) Пропозиція Феміди 3** — `Main.free_move_arg(args) -> int` (0 площина, 1 вільний рух, −1 дефолт; `--plane` перемагає);
  `Main._ready` викликає її; smoke перевіряє 5 випадків: `["--plane"]`, `["--free-move"]`, `[]`, обидва разом, `["--plane-off"]`.
- **Гард на імпорт** у тому ж `_check_boot()`: кожен `MeshInstance3D` обох GLB має `albedo_texture`, і її шлях починається з
  `<glb>::`. Гейт РЕЄ ловить лише «витягнуто»; «викинуто» (`=0`) лишає гейти зеленими — це ловить тільки smoke (NC-C2).
- Лічильник smoke: 92 → 95 (`make check` → `[smoke] ALL OK (95 checks)`).

## Перевірка

- `rm -rf game/.godot && make check` → `[smoke] ALL OK (95 checks) in 13501 frames`, `SMOKE ЗЕЛЕНИЙ`; GDS `перевірено: 36 · не парсяться: 0`.
- `bash tools/gates/run_gates.sh` → ВІК 129 стор. / 0 зламаних, РЕЄ `на диску: 88 · у реєстрі: 88 · незареєстрованих: 0`, ПАР 0, `БАТАРЕЯ ЗЕЛЕНА`, rc=0.

**Негативний контроль** (scratchpad `nc.sh`: правка → smoke → відкат; для імпорту — ще свіжий `--import` і батарея). 11 / 11 червоні:

| # | злам | результат |
|---|---|---|
| NC-A1 (= NC10) | `var free_move: bool = false` | `FAIL GameState.free_move defaults to false` |
| NC-A2 | `var free_move: bool` (без значення) | `FAIL … defaults to false` |
| NC-A3 | `Main._ready` завжди `set_free_move(mode == 1)` | `FAIL GameState.free_move is false at boot, launch flags ["--smoke"] ask for true` |
| NC-A4 | `GameState._init()` ставить `false` | `FAIL … defaults to false` |
| NC-B1 (= NC11) | `"--plane"` → `"--plane-off"` | `FAIL Main.free_move_arg(["--plane"]) → -1, expected 0` |
| NC-B2 | порядок гілок навпаки | `FAIL … (["--smoke", "--plane", "--free-move"]) → 1, expected 0` |
| NC-B3 | без прапорця → `0` | `FAIL … ([]) → 0, expected -1` |
| NC-B4 | `begins_with("--plane")` | `FAIL … (["--plane-off"]) → 0, expected -1` |
| NC-C1 | Choko `embedded_image_handling=1` | smoke `FAIL … texture is a separate file …choko_m0_Image_0.jpg`; РЕЄ `незареєстрованих: 1`, `БАТАРЕЯ ЧЕРВОНА` |
| NC-C2 | Skea `embedded_image_handling=0` | smoke `FAIL skea_m1.glb: char1 has no albedo texture`; батарея **зелена** — гейт це не бачить |
| NC-C3 | рядок налаштування видалено з `.import` (дефолт рушія) | smoke `FAIL … extracted`; `БАТАРЕЯ ЧЕРВОНА` |

Предмет: для всіх запусків гри без прапорців — вільний рух; для всіх наборів аргументів — `--plane` → площина, `--free-move` → 3D, інакше дефолт;
для всіх GLB героїв — текстура всередині GLB, а не окремим файлом і не загублена.

**Не перевірено:** Mac (`make update && make check && make gates` — Santos); вигляд BasisU-текстури на екрані (headless без рендера).
Пропозиції 1, 4, 5 аудиту — не цей запуск (1 — запуск 4 після «так» Ареса, 4 — запуск 6, 5 — Арес у 4a).

## Related
- [[2026-10-03-Path-to-First-Fight]] · [[2026-10-03-Launch-2-PR60]] · [[2026-10-03-launch-4-ual-source]] · [[Textures-Registry]] · [[state]]
