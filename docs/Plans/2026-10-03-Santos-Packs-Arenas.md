# План — паки Santos у гру: 3D-пропи, стиль через Higgsfield, три арени, на яких хочеться битись

**Дата:** 2026-10-03 · **Роль:** T1 Дедал · **Статус:** `approved` — Santos «ааа» 2026-10-03: Р1 = A, Р2 = A, Р3 = A ([[2026-10-03-T1-Repo-Cleanup-Packs]]).
**Виріс із:** голосових Santos 2026-10-03 ([[2026-10-03-T1-Santos-Packs]]) · [[2026-10-03-Sprint-Arenas-VFX]] (смуги A, C, H) ·
[[2026-10-03-Free-Cartoon-Texture-Sources]] (звідки Santos брав паки) · [[2026-10-03-Arena-360-Textures]] (R11) ·
[[Arenas-360-Prompts]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[ADR-013-License-Check-At-Release]].
**Кредити:** у цьому плані не витрачено жодного. Кожен пакет Higgsfield — `RED: потребує слова Santos`, перед ним `balance` → `get_cost`.

## Що хоче Santos (його словами, стисло)

| # | бажання |
|---|---|
| П1 | «Завелися новими текстурками» — паки дають різноманіття. Подивитись **усе**, що є, і **розфасувати зручно** |
| П2 | Що назване не за функцією — **перейменувати** |
| П3 | Підрівняти **різкість і чіткість** текстур |
| П4 | **Повну стилістику** нашого геймдизайну передавати через Higgsfield; 3D-моделі з паків — щоб не навантажувати Higgsfield там, де можна без нього |
| П5 | Широкий план для **T6**: промпти, всі потрібні текстури, рендер, пакування, підписи, wikilinks. «Запрягаємо хлопця, нехай не відпочиває» |
| П6 | Найгарніші мапи, на яких приємно битись, — щоб захотілось задонатити й купити скін |
| П7 | Наступний пак — **Quaternius Fantasy Props MegaKit [Standard]**: як закинути в репо |

## Що є зараз (виміряно в цій сесії)

| що | команда | вихід |
|---|---|---|
| паки Santos | `git log --oneline origin/main..origin/textures/santos-pack` | 1 коміт `7ce1ba3` «Prop packs from Santos: KayKit Dungeon EXTRA + FBX props», 10 файлів у `tools/packs/`; у `main` не змерджено, PR немає |
| KayKit Dungeon 1.1 EXTRA | `unzip` → `License.txt` | **CC0 1.0**, Kay Lousberg, «free to use in personal, educational and commercial projects» (файл відкрито в цій сесії) |
| скільки моделей KayKit | `ls Assets/gltf/*.gltf \| wc -l` | **283**; формати: gltf, fbx, fbx(unity), obj |
| текстура KayKit | `Assets/textures/dungeon_texture.png` (PNG-заголовок) | **одна палітра-атлас 1024×1024**: 8×4 плашки-градієнти; ще 6 альтернатив (`Golden`, `BlackAndWhite`, `SepiaA/B`, `NightA/B`). Деталей у текстурі немає — «чіткість» KayKit дає наш toon + контур, не роздільність |
| масштаб KayKit | `accessors[POSITION].min/max` у gltf | `barrel_large` 1.80×**2.00**×1.80 м, `crate_large` 2.00×0.80×1.40, `chair` 0.75×**1.23**×0.75, `wall` 4×4×1, `floor_tile_large` 4×0.15×4 — масивніше за реальні речі |
| 9 FBX | розбір бінарного FBX (`python3`, scratchpad `fbxinfo.py`) | автор — тека `Creative Trio` у шляхах текстур; Blender 2.92–4.4.3; **187 мешів** |
| текстури 9 FBX | вузли `Video` → `Content` | **не вбудовані й не в коміті**: `CT_Pallete.png` (6 паків), `EK_Pallete.png` (двері, столи), `CT_Rocks_Palette.png` (каміння). Без них у Godot — сіро |
| ліцензія 9 FBX | — | **не перевірено**: у коміті немає `License`, сайт автора з хмари закритий |
| імена не за функцією | імена мешів у FBX | `Wooden_Bridges_001.fbx` — 10 × `Cube.*`; `Potions_Final_CT.fbx` — `Cylinder.003…006`, `Sphere.002…015`; решта названа (`Door.01`, `Gate.03.L`, `Bridge.07`, `Rock_Formation.010`, `Fence.07.Damaged.01`, `Bench`, `Tree.031`) |
| масштаб 9 FBX | вершини × `Lcl Scaling` | скаче: двері 2.03 м заввишки, але `Hamburguer` 3.11 м, `Hot Dog` 4.02 м, усі 24 дерева рівно 1.00 м, `Bridge.01` 18.72 м |
| арени в грі | `Arena.gd:212-227`, `ArenaLayout.gd` | укриття — `BoxMesh` / `CylinderMesh`-заглушки: ятки 1.1 м, ящики 1×1×1, чаша фонтану r 3 м × 0.9 м; підлога — `BoxMesh` |
| фон 360° | `Backdrop.gd:15` | `RING_CARDS := 4`, **усі 4 картки — одна картинка** `stage.texture`. Різні N/E/S/W з [[Arenas-360-Prompts]] у гру без кроку Гефеста не стануть |
| фон `river` за замовчуванням | `GameState.gd:15`; PNG/JPEG-заголовок | `bg_kronshift_river.jpg` **1500×848**; на картці 144 м з 48 м (кут 112.6°) треба ≈ **2363 px** ширини на 1080p → **0.63 тексель/піксель** (мило ×1.6); 2688 px дали б 1.14 (`python3`, формула — R11 §1.2) |
| імпорт тайлів води | `tex_water_*.png.import` | `mipmaps/generate=false`, `detect_3d/compress_to=1` |
| не підключено в код | `grep` імені файла по `game/scripts game/scenes game/data` | 0 прямих посилань: `tex_water_foam/ripple`, `props_anchors_v1`, `drone_heavy_v1`, `stage_river_plate_v1`, меню ×3, спрайти ×5, іконки ×6, портрети ×2 (динамічні імена на кшталт `"sticker_" + kind` `grep` не бачить) |
| стиль-проба 360° v1 | `docs/World/Stage-River.md:27` | **відхилена Santos: «занадто багато деталізацій»** |
| кредити | `balance` | **5068.25** (ultra). На старті спринту — 5555.25 (`state.md`, рядок T1) → витрачено 487 зі стелі 1000, лишок ≈ 513 |
| ретекстур 3D у Higgsfield | `models_explore list type=3d` | є `meshy_v5_retexture`: GLB за URL + `text_style_prompt` або `image_style_url`, `enable_original_uv` (за замовчуванням true). Ціну не питав — `get_cost` T6 |

## Головна ідея

**Ближній план — 3D з паків (0 кредитів), дальній — мальоване спрощене кільце, Higgsfield — там, де без нього ніяк.**

1. Пропи паків — це вже геометрія. Їхня «текстура» — палітра-атлас. Наш стиль на них дає **перефарбована палітра**
   (кольори [[Style-Guide]]) + наш `toon.gdshader` + контур `#2B2230`. Це 0 кредитів і один стиль на сотні моделей.
2. Higgsfield передає **стиль**, а не малює кожен предмет: один «ключ стилю» (кадр із паку → перемальований у Sketch-Cel
   з референсом канону річки `a2913501`) → з нього береться палітра-ціль. Далі Higgsfield робить те, чого в паках немає:
   дальнє кільце N/E/S/W, безшовні підлоги, декалі, неон, і **4–6 героїчних пропів** (фонтан, ятка, ліхтар-якір, трамвайна
   зупинка) через `meshy_v5_retexture` або `image_to_3d`.
3. Коли ближній план — 3D, дальнє кільце може бути **простим**: великі силуети, мало дрібниць. Це прямо закриває
   «занадто багато деталізацій» Santos.
4. **Вигляд підганяється під коробку Ареса, не навпаки.** Колізія укриттів уже в `ArenaLayout.gd` (смуга F); проп ставиться
   так, щоб його силует збігся з коробкою. Нові укриття — тільки через Ареса.

## Розвилки для Santos

**Закрито (Santos «ааа», 2026-10-03): Р1 = A, Р2 = A, Р3 = A.** За Р2 = A гілка `textures/santos-pack` — склад сирців паків:
у `main` не мерджиться і живе довше за робочі гілки.

**Р1 — як фарбуємо пропи паків.**
- **A (рекомендую):** усі пропи — перефарбована палітра + наш toon/контур, 0 кр.; `meshy_v5_retexture` — лише 4–6 героїчних
  пропів у центрі уваги. Один стиль, мало кредитів, міняється за хвилину.
- B: ретекстур Higgsfield для кожного пропу. Кредити × сотні моделей, кожен виходить трохи інакшим, атласи ростуть.

**Р2 — що з паків іде в `main`.**
- **A (рекомендую):** у `main` іде тільки те, що в грі: вибрані моделі в `game/assets/models/props/…` + перефарбовані
  палітри. Сирці (zip 38 МБ, FBX) живуть на гілці `textures/santos-pack` і на Mac; у реєстрі — назва паку, версія, автор, дата.
  Історія `main` не росте на 38 МБ за кожен пак.
- B: змерджити гілку як є — усе в `main`, кожен наступний пак теж.

**Р3 — дальнє кільце.**
- **A (рекомендую):** 4 **різні** картки N/E/S/W на нинішньому кільці (Гефест: `texture` → `textures: [N, E, S, W]` у
  `STAGES`), промпти v2 «великі форми, мало деталей», ближні 3–8 м — 3D-пропи.
- B: панорама-небо (R11, форма А) — 0 паралаксу, але свій sky-шейдер і шов 0°↔360°, якого Higgsfield не гарантує.

Поза цим планом: **крамниця скінів і донат** — окремий план і ADR, коли Santos скаже; бачення вже записане в
[[Stage-Bazaar]] § Базар у майбутньому. Цей план дає їй вітрину — гарні арени.

## Як розфасовуємо (цільова структура)

Верх `game/assets/` лишається за типами (так уже працюють `Flipbook.gd`, `GameState.gd`, реєстр). Нове:

```
game/assets/
  models/props/<категорія>/<id>.glb|gltf     # 3D з паків і героїчні пропи: market, furniture, light, street,
                                             # architecture, river, nature
  models/props/palettes/<pack>_<time>.png    # перефарбовані атласи: kaykit_dungeon_day.png, kaykit_dungeon_night.png
  textures/floor/<stage>_<матеріал>.png      # безшовні тайли підлоги
  textures/decals/<id>.png                   # калюжі, тріщини, мох, люки, рейки — з альфою
  backgrounds/<stage>/<stage>_<dir>_<time>_v<N>.png   # river_n_day_v2.png … — кільце 360°
```

**Імена:** `snake_case`, англійською, **функція → варіант → версія**: `crate_large`, `stall_awning_red`, `lamp_anchor_v1`.
Імена мешів `Cube.006`, `Sphere.012` у гру не потрапляють.

**Наявні файли, названі або покладені не за функцією** (перейменування — Гефест скриптом, разом із `.import`, кодом і
реєстром; ідентифікатори флипбуків `vfx/*` **не чіпаємо** — це ключі в коді `Flipbook.play(…, "kunai_impact")`):

| зараз | що це насправді | пропоную | посилань у коді (`grep`) |
|---|---|---|---|
| `characters/cards/hands_choko.png` | референс рук, не картка | `characters/refs/choko_hands_ref.png` | 0 |
| `characters/cards/weapon_choko_main_sword.png` | референс меча | `characters/refs/choko_sword_main_ref.png` | 0 |
| `characters/cards/weapons_choko_ultimate.png` | референс ульт-мечів | `characters/refs/choko_swords_ult_ref.png` | 0 |
| `props/props_anchors_v1.png` | лист-референс якорів, не текстура | `props/sheets/anchors_sheet_v1.png` | 0 |
| `props/drone_heavy_v1.png` | лист-референс дрона | `props/sheets/drone_heavy_sheet_v1.png` | 0 |
| `vfx/vfx_steam_puff_v1.png` | пара меню-діорами, не бойовий флипбук | `menu/menu_steam_puff_v1.png` | 0 |
| `backgrounds/bg_kronshift_{market_street,back_alley,main_street,city_reference}.webp` | старий стиль, поза ротацією; зараз — заглушки `bazaar`/`fountain` | `backgrounds/legacy/…` **після** того, як кільце v2 замінить їх у `STAGES` | по 1 |

## Що з паків куди (функція → арена)

**KayKit Dungeon 1.1 EXTRA, 283 моделі** (групування — регулярки по іменах, `python3`):

| к-сть | група | арена | приклад |
|---|---|---|---|
| 26 | столи-прилавки | `bazaar` ятки; `fountain` тераси кав'ярень | `table_long_tablecloth`, `bartop_A_large`, `table_round_medium` |
| 8 | ящики, коробки | `bazaar`, `river` (баржі) | `crate_large`, `crates_stacked`, `box_stacked` |
| 7 | бочки, діжки, відра | `bazaar`, `river` | `barrel_large`, `barrel_small_stack`, `keg` |
| 16 | пляшки, тарілки, їжа, книги | ятки `bazaar` (дрібниця на прилавках) | `bottle_A_labeled_green`, `plate_food_A` |
| 17 | монети, скрині | майбутня крамниця на `bazaar` | `coin_stack_large`, `chest_large_gold`, `trunk_medium_A` |
| 42 | тенти, прапорці | гірлянди над ятками `bazaar` (після перефарбування) | `banner_patternA_red`, `banner_triple_*` |
| 16 | меблі, полиці | `fountain` тераси; `bazaar` | `chair`, `stool_round`, `bench`, `shelves_decorated` |
| 9 | свічки, смолоскипи | декор; **якорі — ні** (якорі — ліхтарі, [[ADR-011-Diegetic-Grapple-Anchors]]) | `torch_mounted`, `candle_triple` |
| 21 + 6 | підлога, фундамент | острівці під ятками, причал `river` | `floor_tile_large`, `floor_wood_large`, `floor_foundation_front` |
| 38 | стіни, арки, вікна | ближні фасади-краї кола (за 20 м) | `wall_window_open`, `wall_arched`, `wall_doorway` |
| 4 · 15 | колони · сходи | ратуша `fountain` S; сходи до води `river` S | `pillar_decorated`, `stairs_wide` |
| 12 | риштування | індустріальний Cronshift: кран, ремонт фасаду | `scaffold_frame_large` |
| 6 | каміння, руїни | береги `river` | `rocks`, `rubble_half` |
| 39 + 1 | поза Cronshift: грати, шипи, мімік, ліжка, зброя, ключі, кирки | резерв, у гру не йде | `bar_straight_A`, `floor_tile_big_spikes`, `chest_mimic` |

**Creative Trio, 9 FBX, 187 мешів** (ліцензія — не перевірено):

| файл | мешів | що | арена | зауваги |
|---|---|---|---|---|
| `Stone_Bridges_01.fbx` | 12 | кам'яні мости 15–19 м | `river` E — міст у ближньому плані | герой-кандидат на ретекстур |
| `Wooden_Bridges_001.fbx` | 10 | дерев'яні мости/помости | `river` S — причал, баржі | імена `Cube.*` → перейменувати |
| `Doors_Pack.fbx` | 45 | двері, ворота, арки дерев'яні й кам'яні | фасади всіх арен; арка входу в критий ринок `bazaar` S | `Base_Material_Emission` — світні вікна вночі? |
| `Tables_Chairs_01.fbx` | 15 | лавки, столи, стілець | тераси `fountain` W | |
| `Trees_Pack_02.fbx` | 24 | дерева, усі нормовані до 1 м | `fountain` площа, `river` набережна | матеріал `GenshinMaterial.Default` |
| `Rocks_01.fbx` | 29 | каміння, скельні формації | береги `river` | своя палітра `CT_Rocks_Palette.png` |
| `Wooden_Fences_01.fbx` | 26 | паркани, зламані дошки | `bazaar` задвірки, `river` | |
| `Potions_Final_CT.fbx` | 16 | пляшки-зілля | ятка спецій `bazaar` W; **«хілочки»** майбутньої крамниці | імена `Cylinder.*`, `Sphere.*` → перейменувати; є emission |
| `Food_01_CT.fbx` | 10 | бургер, картопля, хот-дог, стейк, сосиска, пиріг | їжа на ятках `bazaar` | бургер і паперовий стакан — сучасні; чи пасує старому Cronshift — Кліо/Santos |

**Quaternius Fantasy Props MegaKit [Standard]** — **на гілці** `textures/santos-pack` (`6210890`, T1 за словом Santos):
`tools/packs/Fantasy_Props_MegaKit_Standard/` — лише `Exports/glTF` (94 `.gltf` + 94 `.bin` + 13 `.png`, 43 МБ) і
`License_Standard.txt` (CC0 1.0; «standard FREE version… only contains a portion of the models» — повні Pro/Source платні).
Архів 150 МБ цілим не проходить ліміт GitHub 100 МБ; FBX, OBJ і нормалі UE не взято. Далі — той самий інвентар (Ф0.3),
що вище, і рядок у цій таблиці.

## Кроки

Кожен крок: **хто · що змінюємо · ризик · як перевіряється.**

### Ф0. Пак у порядок — Santos, потім T2 Гефест

| # | хто | що | ризик | перевірка |
|---|---|---|---|---|
| 0.1 | Santos | докласти на гілку `textures/santos-pack` палітри `CT_Pallete.png`, `EK_Pallete.png`, `CT_Rocks_Palette.png` і файли ліцензії Creative Trio з тих самих завантажень (на Mac їх немає: `mdfind -name CT_Pallete` → 0 — докачати); ~~закинути MegaKit~~ — **зроблено** (`6210890`) | без палітр 9 FBX — сірі | `git ls-tree -r --name-only origin/textures/santos-pack tools/packs \| grep -ci pal` → ≥ 3 |
| 0.2 | T3 Архімед | ліцензія Creative Trio і MegaKit: текст `License`/сторінки з дати завантаження; бриф `docs/Research/2026-10-03-Pack-Licenses.md` | CC-BY → рядок у титрах; NoAI → не можна ганяти через Higgsfield | файл існує; у кожного паку — цитата + URL + дата або `UNGROUNDED` |
| 0.3 | T2 Гефест | контакт-лист паків: PNG-сітка всіх мешів з іменами (будь-яким способом — Godot на Mac або скрипт у `tools/art/`), у `docs/assets/screenshots/` | без картинки T6 і Кліо називають наосліп | `ls docs/assets/screenshots/packs_*.png` → по одному на пак |

### Ф1. Каталог і імена — T7 Кліо + T2 Гефест

| # | хто | що | ризик | перевірка |
|---|---|---|---|---|
| 1.1 | T7 Кліо | `docs/Art/Prop-Catalog.md`: кожен вибраний проп — id за функцією, пак, оригінальне ім'я меша, арена, роль (укриття / декор / якір), масштаб; wikilinks на сторінки арен | розбіжність з реєстром | `bash tools/gates/run_gates.sh` rc=0 |
| 1.2 | T2 Гефест | `tools/art/rename_asset.py`: `git mv` файла з `.import`, заміна шляху в `game/` і `docs/`; прогін на 6 рядках таблиці § Наявні файли | зламаний шлях у сцені → чорний квад | `make check` → `[smoke] ALL OK`; `make gates` rc=0; `grep -rn 'cards/hands_choko' game docs` → 0 |

### Ф2. Різкість — T3 Архімед, потім T2 Гефест

| # | хто | що | ризик | перевірка |
|---|---|---|---|---|
| 2.1 | T3 | бриф у `docs/Research/`: імпорт у Godot 4.7 для трьох класів — (а) палітри-атласи (плашки зливаються на мипах? ETC2/ASTC зсуває колір?), (б) тайли підлоги (мипи + анізотропія, якість VRAM), (в) кільце фону (≥ 2363 px на картку на 1080p, стеля мобільних 4096); чи імпортує 4.7 FBX сам | неправильний пресет = мило або «блимання» тайлів | у брифі — кожен пункт з місцем у сирцях `4.7.2-stable` або `UNGROUNDED` |
| 2.2 | T2 | пресети імпорту за 2.1 (`.import` або `import_defaults` у `project.godot`) + `tools/art/texture_audit.py`: розмір, альфа, мипи, тексель/піксель для фону | масова зміна `.import` | `python3 tools/art/texture_audit.py` → таблиця без рядків `< 1.0 texel/px` для кільця; `make check` |

### Ф3. Стиль пропів без кредитів — T6 Аполлон + T2 Гефест

| # | хто | що | ризик | перевірка |
|---|---|---|---|---|
| 3.1 | T6 | `docs/Art/Palette-Remap.md`: кожна з 32 плашок `dungeon_texture.png` (і плашки `CT_Pallete`) → колір [[Style-Guide]], день і ніч | кольори «пливуть» від ключа стилю | таблиця 32 рядки, кожен з hex «було → стало» |
| 3.2 | T2 | `tools/art/recolor_palette.py` (PIL): атлас + таблиця 3.1 → `models/props/palettes/<pack>_{day,night}.png`; градієнт у плашці зберігається або плющиться — за 3.1 | зсув UV-плашок | скрипт ідемпотентний: другий прогін → той самий `sha256sum` |
| 3.3 | T2 | імпорт вибраних моделей (Ф1.1) у `game/assets/models/props/<категорія>/`, матеріал-перекриття: toon + контур + палітра дня/ночі | 283 моделі = повільний імпорт; беремо лише вибрані | `make check`; `texture_registry_check.py` → N/N |

### Ф4. Арени збираються — T5 Арес → T2 Гефест

| # | хто | що | ризик | перевірка |
|---|---|---|---|---|
| 4.1 | T5 | масштаб паків під бійця й укриття: один множник на пак (KayKit `barrel_large` 2.0 м — більше за реальну бочку); що з пропів — укриття з колізією, що — декор без неї; фонтан у центрі кола чи ні ([[Stage-Fountain]]) | проп вищий за коробку → «невидима стіна» | рядки в [[04-Grapple-System]] § Якорі й укриття, кожне число PLACEHOLDER або з джерелом |
| 4.2 | T2 | `PropKit`: на кожну коробку/циліндр `ArenaLayout.cover()` — набір пропів того самого габариту; декор — по колу 20–30 м | розбіжність вигляду й колізії | smoke: AABB візуалу в межах коробки з допуском від Ареса (4.1, PLACEHOLDER) — `make check` |
| 4.3 | T2 | `Backdrop.gd` + `STAGES`: `textures: [N, E, S, W]` для дня й ночі (Р3 = A) | 4 шви на кутах | `make check`; скрин 4 боків на Mac у PR |
| 4.4 | T2 | підлога — тайл `textures/floor/<stage>_*.png` зі світовими UV | розтяг на колі 20 м | скрин з камери на краю кола |

### Ф5. Підписи, wikilinks, аудит — T7 Кліо, T4 Феміда

| # | хто | що | перевірка |
|---|---|---|---|
| 5.1 | T7 | таблиці «Ассети арени» на [[Stage-River]], [[Stage-Bazaar]], [[Stage-Fountain]]; `docs/Art/Prop-Catalog.md` (Ф1.1); глосарій (ключ стилю, палітра-атлас) | `bash tools/gates/run_gates.sh` rc=0 |
| 5.2 | T4 | аудит кожного PR Ф0–Ф4 і черги T6: реєстр, ліцензії, кредити проти `transactions` | вердикт `docs/Audit/2026-10-03-Packs-*.md` без RED |

## Черга T6 Аполлона — «щоб не відпочивав»

Порядок жорсткий: **хвиля без кредитів іде першою і цілком**, кредитні хвилі — кожна після `balance` → `get_cost` → слова Santos.
Ціни нижче — з `get_cost`, який T6 уже міряв ([[Arenas-360-Prompts]] § Кошторис: `gpt_image_2_5` high 2k з референсом → 2.75;
`nano_banana_pro` 2k 1:1 → 2; [[2026-10-03-Apollon-Sprint-C-Prompts]]: `meshy_image_to_3d` з текстурою → 30). Ціну `meshy_v5_retexture`
ніхто не міряв. «≈» — множення ціни на кількість, не виміряна партія.

### Хвиля T6-0 — 0 кредитів, починати зараз

| # | що | де |
|---|---|---|
| 0a | реєстр: розділ «Паки-джерела» — KayKit Dungeon 1.1 EXTRA (CC0, `License.txt` відкрито), Creative Trio ×9 (ліцензія — після Ф0.2), MegaKit | [[Textures-Registry]] |
| 0b | **ключ стилю**: промпт «перемалюй цей кадр у Sketch-Cel» — вхід `Samples/Dungeon_sample_big.png` з паку KayKit (CC0) + канон `a2913501`; виходом визначається палітра-ціль | [[Prompt-Library]] новий § «Ключ стилю» |
| 0c | `Palette-Remap.md` (Ф3.1) — чернетка з hex [[Style-Guide]] ще до ключа стилю | `docs/Art/Palette-Remap.md` |
| 0d | **кільце v2 «менше деталей»**: переписати SCENE трьох арен — великі силуети, 3–5 масивів на картку, жодних дрібних вивісок і людей; ближні 3–8 м прибрати з картки (їх дають 3D-пропи) | [[Arenas-360-Prompts]] § v2 |
| 0e | **декалі** (альфа, вид згори): калюжі, мокра бруківка, тріщини, мох між плитами, люк, трамвайні рейки, рибальська сітка, розсипані спеції, сліди фарби. Без літер — єдиний напис у місті CRONSHIFT (ADR-011 п. 5) | [[Arenas-360-Prompts]] § Декалі |
| 0f | **героїчні пропи**: фонтан зі статуєю, ятка з тентом, ліхтар-якір, трамвайна зупинка, (опційно) кран над річкою — для кожного: вхід (меш з паку для `meshy_v5_retexture` або лист для `image_to_3d`), промпт стилю | [[Arenas-360-Prompts]] § Пропи |
| 0g | підлоги: до наявних трьох (`tex-floor-cobble`, `-market-planks`, `-square-tiles`) — `tex-floor-quay-stone` (набережна `river`) і `tex-floor-wet-cobble-night` | [[Arenas-360-Prompts]] § Текстури |
| 0h | `get_cost` на кожен пакет 1–4 нижче + `balance`; таблиця кошторису в PR | PR T6 |
| 0i | перевірка паків очима (контакт-лист Ф0.3): які пропи «наші», які викинути за стилем | `Prop-Catalog.md`, колонка «Аполлон» |

### Хвиля T6-1 — RED: потребує слова Santos (≈ 16.5 кр.)

| пакет | шт | ≈ кр. |
|---|---|---|
| ключ стилю, 2 варіанти | 2 | 5.5 |
| стиль-проба кільця v2: `river` N день + ніч, по 2 варіанти | 4 | 11 |

Santos каже «стиль так» → хвиля 2. «Ні» → T6 правит 0b/0d, проба повторюється.

### Хвиля T6-2 — RED (≈ 102.5 кр. з 1 варіантом)

| пакет | шт | ≈ кр. |
|---|---|---|
| решта кільця: `river` 6, `bazaar` 8, `fountain` 8 (день + ніч-редагування), 1 варіант | 22 | 60.5 |
| шар неону CRONSHIFT, 2 варіанти | 2 | 5.5 |
| підлоги, 5 × 2 варіанти | 10 | 20 |
| декалі, 6 листів-сіток | 6 | 16.5 |
| апскейл `card_skea_v1.jpg` (1500×848, є в коді) — якщо `get_cost` дешевий | 1 | `get_cost` |

### Хвиля T6-3 — RED (≈ 120–150 кр.)

| пакет | шт | ≈ кр. |
|---|---|---|
| героїчні пропи: фонтан, ятка, ліхтар-якір, трамвайна зупинка (+ кран) | 4–5 | ≈ 30 кожен, якщо `image_to_3d`; ретекстур — `get_cost` |

### Хвиля T6-4 — 0 кредитів, після кожної кредитної

Завантажити (`tools/fetch_assets.sh`) → нарізати й назвати за § Як розфасовуємо → рядок у [[Textures-Registry]] (id, джерело,
модель, промпт, ліцензія, використання) → wikilinks у [[Arenas-360-Prompts]] і на сторінках арен → PR не draft з
`balance` до/після.

### Хвиля T6-5 — лише промпти, 0 кр., коли Santos відкриє тему крамниці

Концепти скінів Choko і Skea (3 на героя) і вітрина крамниці на `bazaar` — промпти й `get_cost`, без генерації.

**Разом хвилі 1–3:** ≈ 240–270 кр. (16.5 + 102.5 + 120–150) з 1 варіантом кільця. Лишок стелі спринту ≈ 513 (розрахунок у § Що є зараз).
Понад стелю — нове слово Santos.

## Як закинути пак (Santos, на Mac)

У тій копії репо, з якої ти пушив `textures/santos-pack` (не `~/dev/nir-play` — та для гри):

```bash
cd <твоя копія nooneisreal>
git fetch origin
git switch textures/santos-pack
git pull
ls -lh ~/Downloads/*MegaKit*            # GitHub не прийме файл > 100 МБ
cp ~/Downloads/<архів MegaKit>.zip tools/packs/
cp <теки Creative Trio>/CT_Pallete.png <…>/EK_Pallete.png <…>/CT_Rocks_Palette.png tools/packs/
# файл ліцензії кожного паку Creative Trio — під своїм іменем, щоб не перезаписались:
cp <тека паку>/License.txt tools/packs/License_<пак>.txt
git add tools/packs
git commit -m "Packs from Santos: Quaternius Fantasy Props MegaKit Standard, Creative Trio palettes"
git push
```

Якщо `ls -lh` показує архів понад 100 МБ — розпакуй і клади лише теку з glTF і текстурами + файл ліцензії. Далі скажи
будь-якому терміналу «пак на гілці» — він робить інвентар (Ф0.3) і додає рядок у § Що з паків куди.

## Related
- [[2026-10-03-T1-Santos-Packs]] · [[2026-10-03-Sprint-Arenas-VFX]] · [[Arenas-360-Prompts]] · [[2026-10-03-Arena-360-Textures]]
- [[2026-10-03-Free-Cartoon-Texture-Sources]] · [[Textures-Registry]] · [[Style-Guide]] · [[Prompt-Library]]
- [[Stage-River]] · [[Stage-Bazaar]] · [[Stage-Fountain]] · [[Cronshift]] · [[04-Grapple-System]]
- [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[ADR-013-License-Check-At-Release]] · [[state]]
