# Пропи міста — промпти концепт-аркушів і карток для Meshy

2026-10-08 · T6 Аполлон · **Статус:** `draft`, **жодного запуску**. Навіщо, що й скільки —
[[2026-10-08-City-Modern-Realism-Props]] (каталог, правила П1–П8, критерії К1–К11). Мова промптів — англійська, блоки
байт-у-байт. Генерація — лише після `get_cost` (T1) і слова Santos із числом.

## Модель і параметри

| параметр | значення | джерело |
|---|---|---|
| модель аркушів і карток | `gpt_image_2_5` | `models_explore get gpt_image_2_5` 2026-10-08: `quality` low…max, `resolution` 1k/2k/4k, `background` auto/opaque/transparent, `image_references` |
| `quality` · `resolution` · `aspect_ratio` | `high` · `2k` · `16:9` | як у § 10–11 [[Prompt-Library]] і в [[Item-Sheets-Prompts]] |
| `background` | не задавати: плашку й білий фон задає текст | аркуші — це референси форми, не вирізки |
| `count` | 1 | 1 результат на слот |
| 3D | `multi_image_to_3d` (Meshy), до 4 зображень | `models_explore list type=3d` 2026-10-08 |
| 3D — альтернатива | `meshy_v7_image_to_3d`, `model_type: lowpoly` | там само; чи приймає кілька ракурсів — не перевірено |

**Ціни тут немає навмисно.** T1 робить `get_cost` на кожну конфігурацію: аркуш з 2 рефами, аркуш з 1 рефом, картка, 3D.

## Референси (наші власні генерації, на диску)

| блок | файл | job (повний UUID) | що беремо |
|---|---|---|---|
| `{REF_OWN}` | `game/assets/props/props_anchors_v1.png` | `c5900952-f4f0-4728-8ada-5b30d641be3a` ([[Menu-Skyline-Prompts]], рядок 262) | лінія, тінь, палітра чавуну й цегли |
| `{REF_OWN}` | `game/assets/sprites/sprite_steamcars_v1.png` | `4603954f-5b46-4067-826c-43788b9d8b79` ([[Menu-Skyline-Prompts]], рядок 255) | парова машинерія, латунь, колеса |

Якщо `medias` не прийме job-id у поточному акаунті — `media_upload` файлу з диска (він у репо) або `media_import_url`
з CDN-адреси з [[Textures-Registry]] ([[Higgsfield-Pipeline]] § Конвеєр п. 2).

## Блоки

**`{PROP_STYLE}`** — виведено з префікса § 10–11 [[Prompt-Library]] і `{ITEM_STYLE}` [[Item-Sheets-Prompts]]; додано
правила П1, П2, П5–П7.

```
Prop design sheet for a video game, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite (#2B2230) inked lines with small line breaks, thicker outer contour and thinner inner lines, flat muted base colors with a single cel shadow tone hue-shifted toward magenta-violet, almost no highlights, no gradients, no gloss, no 3D render look. Street objects of the old European-industrial city of Cronshift at the turn of the century: Art Nouveau street furniture with flowing plant-like wrought-iron curves, and working steam-age machinery that looks plausible and functional — every pipe leads somewhere, every boiler has a firebox door, a pressure gauge and a safety valve. Machines carry rivets, flanges and bolted bands, not ornament. Materials only: cast iron painted deep green-teal, riveted steel, copper with pale green patina, dull brass only on handles, grips and rings, cream and teal glazed tiles, worn wood, glass, brick, canvas and rope. Muted dusk palette of terracotta, ochre, slate blue, deep teal, cream and dull brass; nothing saturated. At most three graphic wear marks per object (brown-orange rust streaks under rivets, an oil stain, a soot patch above a firebox), no photo texture.
```

**`{GRID_PROP_8}`** — аркуші L1–L3.

```
Eight separate objects in two rows of four on a flat muted mint-sage background (#B8CBB1), evenly spaced, each object alone in its own cell with a generous empty margin, each drawn in a three-quarter view seen slightly from above, as from a third-person game camera. One clear closed silhouette per object, readable as a flat grey shape; objects never touch or overlap; only a soft flat ground shadow ellipse under each.
```

**`{CARD_4}`** — картки видів для Meshy (V1, V2).

```
Single object only, shown four times in a row at the same scale and on the same ground line: front view, side view, back view, and a three-quarter view from slightly above. Pure white background, no shadow, no ground plane, flat even lighting, flat colors with inked lines, the whole object inside the frame in every view, nothing cut off.
```

**`{NEG_PROP}`** — у кожному запуску. «No bright crimson» — К1 `#A3243B` і `#711126` лише для крові ([[Style-Guide]] § Колір).

```
No people, no hands, no faces, no characters, no animals, no text, no letters, no numbers, no numerals on dials or gauges (tick marks only), no writing on signs, boards or posters, no brand names, no logos, no trademarks, no watermark, no frames, no badges, no bright crimson or blood-red color anywhere, no neon, no glowing screens, no LEDs, no holograms, no chrome, no plastic, no decorative gears or cogs, no goggles, no pipes that end in nothing, no open fire except a small warm glow behind a closed firebox door, no smoke clouds covering the objects, no gallows-like post with a single beam and a hook, no weapons, no skulls, no glossy reflections, no studio lighting, no product-photo look.
```

**`{REF_OWN}`** — L1 і V1.

```
Take the line work, line thickness, shadow color and muted palette of the reference images exactly; they are earlier prop sheets of the same game, so do not copy their objects, and do not copy the red color of the cargo truck.
```

**`{REF_SET}`** — L2, L3, V2: референс — обраний L1 (job-id впишу після відбору).

```
Take the line work, line thickness, shadow color, palette and drawing scale of the reference image exactly; it is an earlier sheet of the same set of city props, so do not copy its objects.
```

Формули: аркуш — `{PROP_STYLE} {GRID_PROP_8} Objects, left to right, top row then bottom row: {SLOTS} {REF} {NEG_PROP}`;
картка — `{PROP_STYLE} {CARD_4} The object: {OBJECT} {REF} {NEG_PROP}`.

## Аркуші

### L1 — парові машини (`sheet-city-steam-v1`), реф `{REF_OWN}`

Каталог № 7, 8, 10–16.

```
1) a vertical street steam boiler: a tall riveted cylinder on a cast-iron base, a small arched firebox door with a warm glow in the gap, a round pressure gauge, a safety valve and a whistle on top, a tall thin chimney with a cap, a coal shovel leaning against it; about twice a man's height, the chimney taller; 2) a steam winch: a horizontal drum wound with thick rope, a small single steam cylinder with a piston rod and a big spoked flywheel on a heavy iron bed; chest-high; 3) a steam water pump: a horizontal duplex pump with two parallel cylinders, a domed air chamber on top, a thick inlet pipe going down into the ground and a flanged outlet pipe, a pressure gauge; waist-high; 4) a small slewing steam crane on a riveted round column: a short cab with a chimney, a long simple lattice boom with few diagonals, a counterweight box, a hook on a chain; very tall; 5) an air compressor for a pneumatic tube network: a long horizontal riveted receiver tank on cast-iron feet, an upright piston block with a flywheel, a pressure gauge; chest-high; 6) a street pressure post: a slender painted cast-iron column with a large round dial near the top showing one needle and tick marks only, a leaf-shaped crown, like a public clock but for steam pressure; taller than a man; 7) a steam vent in the pavement: a square cast-iron grate set flush in stone paving, a small valve handwheel beside it and a soft white puff of steam rising from it; 8) a wall steam pipe kit laid out as a set: a straight pipe with bolted flanges, a ninety-degree elbow, a handwheel valve, a small condensate trap with a drip tray and two wall brackets.
```

### L2 — меблі й світло модерну (`sheet-city-moderne-v1`), реф `{REF_SET}`

Каталог № 17–24.

```
1) a tall gas street lamp on an Art Nouveau cast-iron post: a flared base with flowing plant-like relief, a slim stem-like post, a curved arm ending in a flower-shaped glass lantern with a warm light, a sturdy iron ring under the arm; 2) a wrought-iron wall bracket lamp with one whiplash curve and a small caged lantern, the wall plate visible; 3) an octagonal Art Nouveau street kiosk: a wrought-iron frame, glazed windows, a base of cream and teal glazed tiles, a bell-shaped copper dome with pale green patina and a small finial, a short canvas awning, a plain blank fascia; 4) a street clock on a column: an ornate cast-iron column with a two-sided round clock head, dials with tick marks only, a leaf-shaped crown; 5) a bench with cast-iron side frames in flowing plant-like curves and worn wooden slats; 6) a cast-iron litter bin shaped like a slotted basket with a small domed lid; 7) a cast-iron post box on a short pillar, and beside it a pneumatic tube post pillar with a round brass hatch; 8) an advertising column: a thick cylinder with a small domed cap and finial, covered with posters that show only simple pictures (a teacup, a boat, a flower) and plain colored blocks.
```

### L3 — вантаж і двір (`sheet-city-yard-v1`), реф `{REF_SET}`

Каталог № 1–6, 25, 27–28.

```
1) an oak beer barrel with a bulging belly and three iron hoops, and beside it a smaller barrel lying on a wooden cradle with a brass tap; 2) a wooden rain-water barrel with a closed wooden lid under the lower end of a copper downpipe, no ladle; 3) a riveted steel tar drum with a round lid and thick dark plum-brown drips down its side; 4) a stack of three wooden cargo crates with iron corner straps and blank painted stencil blotches; 5) a wooden coal bunker with iron corner straps, chest-high, a heap of coal inside and a shovel stuck in the coal; 6) a two-wheeled wooden hand cart with spoked wheels carrying tied cloth sacks; 7) a rope-and-pulley cargo lift against a short piece of brick wall: a wooden platform hanging on four ropes, a hooded pulley fixed under a small roof bracket on the wall, a counterweight; 8) three hanging shop signs on wrought-iron brackets, each a flat wooden board cut as a simple pictogram silhouette: a mug, a pair of scissors, a pocket watch.
```

## Картки для Meshy (фаза 2, за розвилкою Р1)

### V1 — паромобіль-вантажівка (`card-city-steamtruck-v1`), реф `{REF_OWN}` (лише `sprite_steamcars_v1`)

```
The object: a steam cargo truck of the early 1900s, the same machine as the truck on the right of the reference image: a round riveted boiler at the front with a short chimney and two round lamps, a small open driver's seat behind it, a long wooden cargo bed with plank sides under a tied grey canvas tarpaulin, four spoked wooden wheels with iron rims. The cargo bed and the mudguards are painted muted terracotta, the boiler is dark painted iron with dull brass bands.
```

### V2 — паровий кран (`card-city-crane-v1`), реф `{REF_SET}`

`{OBJECT}` — опис обраної клітинки L1·4 після відбору (слова беру з того, що вийшло, щоб картка не розійшлась з аркушем).

### Параметри 3D (M1, M2)

| параметр | значення | чому |
|---|---|---|
| `medias` | 3–4 панелі картки, нарізані локально (як T-пози, [[Pipeline-2D-to-3D]]) | більше ракурсів — точніша геометрія |
| `should_texture` · `enable_pbr` | `true` · `false` | наш шейдер читає лише альбедо |
| `texture_prompt` | `flat cel-shaded colors, no baked shadows, no highlights, no text` | Image-to-3D запікає світло — менше роботи постеризації |
| `enable_rigging` · `pose_mode` | `false` · не задавати | це не персонаж |
| `topology` · `target_polycount` | `triangle` · **від T3** | бюджет на проп дає T3; точка відліку — колонка 1 836 трикутників ([[2026-10-08-City-Modern-Realism-Props]] § Аудит) |
| `symmetry_mode` | `auto` | вантажівка й кран несиметричні в деталях |

## Порядок запусків

| # | що | реф | к-сть | після чого |
|---|---|---|---|---|
| L1 | аркуш парових машин | `{REF_OWN}` ×2 | 1 | слово Santos |
| L2, L3 | аркуші меблів і двору | обраний L1 | 2 | T6 прийняв L1 |
| V1, V2 | картки видів | `sprite_steamcars_v1` / обраний L1 | 2 | розвилка Р1 = б |
| M1, M2 | 3D | панелі V1 / V2 | 2 | T6 прийняв картки |

Мінімум 3 (L1–L3), рекомендовано 7, стеля 11 — [[2026-10-08-City-Modern-Realism-Props]] § Шлях виготовлення.

## Журнал

Запусків ще не було. Сюди записуються job-id, `get_cost`, `balance` до і після, вибір і причини — і для вдалих, і для
невдалих промптів.

## Related

- [[2026-10-08-City-Modern-Realism-Props]] · [[Prompt-Library]] · [[Item-Sheets-Prompts]] · [[Menu-Skyline-Prompts]] · [[Higgsfield-Pipeline]] · [[Pipeline-2D-to-3D]] · [[Style-Guide]] · [[Textures-Registry]]
