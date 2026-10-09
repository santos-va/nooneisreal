# Пропи міста — промпти концепт-аркушів і карток для Meshy

2026-10-08, оновлено 2026-10-09 · T6 Аполлон · **Статус:** `ready` — тексти й параметри готові до запуску, **жодного
запуску не було**. Розвилки закрито в [[ADR-027-City-Modern-Props-Style-And-Path]]. Навіщо, що й скільки —
[[2026-10-08-City-Modern-Realism-Props]] (каталог, правила П1–П8, критерії приймання кожного запуску). Мова промптів —
англійська, блоки байт-у-байт. Кредити — Red: `balance` → `get_cost` на кожен JSON нижче (T1) → слово Santos із числом.

## Що змінилось 2026-10-09 (ADR-027)

| що | було | стало | чому |
|---|---|---|---|
| `{PAINT}` | «cast iron painted deep green-teal», без відтінку | блок `{PAINT}` з орієнтиром `#577368` | A/B T6 2026-10-09, [[2026-10-08-City-Modern-Realism-Props]] § A/B відтінку чавуну |
| Орнамент | рослинні вигини жили в спільному `{PROP_STYLE}`, отже потрапляли й у L1 | спільний стиль без орнаменту + групові блоки: `{GROUP_MACHINE}` (L1, V1, V2) прямо забороняє орнамент, `{GROUP_NOUVEAU}` — лише L2, `{GROUP_YARD}` (L3) без орнаменту | ADR-027 п. 1, П2, П5 |
| L1 · 6 колонка тиску | «a leaf-shaped crown» | «a plain domed cap» | листя на машині порушує П5 |
| Картки V | 4 види в ряд | сітка 2 × 2 | на 2688×1520 панель у ряду має 672×1520 px, а в сітці — 1344×760. Вантажівка 5 м і стріла крана в сітці не стискаються. Чверті ріжуться без ручної розмітки (§ Нарізка) |
| Кузов V1 | теракота | сланець `#4A5C73` | теракота `#C8623A` має ΔE76 31,1 від К1, сланець — 62,8. До того ж теракота майже збігається з курткою Choko `#BD6133`. Референс-вантажівка червона (медіана `#6C3131`, ΔE76 15,9 від `#711126`), тож «теракоту» модель тягнутиме в червоне (`python3 -I`, `colorlib.py`, scratchpad `t6-paint/py/`) |
| Заборони | — | «no gallows-like silhouette» уточнено для крана (стріла під кутом, кабіна, противага); додано «no number plates», «no mirror-polished metal», «scarlet, cherry» | кран — це не стовп із балкою й гаком |
| Довжина | — | L1 = 4578 символів; найдовший промпт, що вже пройшов у цьому акаунті, — 4579 (`74cba24f`, лист Ліхтарника, `show_generations` 2026-10-09) | довших за 4579 ми ще не запускали; межу провайдера не перевіряв |

## Модель і параметри

`models_explore get` 2026-10-09 (T6, цей захід):

| модель | що приймає | що беремо |
|---|---|---|
| `gpt_image_2_5` | `variant` flare/sunburst · `quality` low…max · `resolution` 1k/2k/4k · `background` auto/opaque/transparent · `medias` роль **лише** `image_references` · аспект 16:9 є | `quality: high`, `resolution: 2k`, `aspect_ratio: 16:9`, `background: opaque` (плашку чи білий задає текст), `count: 1`. `variant` не задаємо (типово flare), як у всіх запусках за 2.75 |
| `multi_image_to_3d` (Meshy) | `medias` 1–4, роль **лише** `image`, обов'язково · `should_texture` · `enable_pbr` (лише з текстурою) · `enable_rigging` · `enable_animation` · `should_remesh` (типово true; false ігнорує `topology` і `target_polycount`) · `topology` quad/triangle · `target_polycount` 100–300000 (типово 30000) · `symmetry_mode` off/auto/on · `texture_prompt` · `texture_image_url` · `pose_mode` · `seed` | § M1, M2 |
| `meshy_v7_image_to_3d` | `model_type` standard/lowpoly · `medias` роль `image_references`, ліміту кількості опис не дає | **не беремо**: чи вміє він кілька ракурсів одного предмета — опис не каже. `multi_image_to_3d` прямо описаний як «1-4 images of the same subject» |

**Ціни тут немає навмисно.** `balance` 2026-10-09 (T6) → **3692.5**, план ultra. Довідка з журналів, не звірка сьогодні:
`gpt_image_2_5` high 2k з 1–2 рефами — 2.75 ([[Item-Sheets-Prompts]], [[Prompt-Library]] § 18); `multi_image_to_3d` з 4
ракурсів, текстура, без рига, quad 20k — 30 ([[Higgsfield-Pipeline]] § Ціни 3D, 2026-10-03). Конфігурацію `triangle`
10000 ніхто не звіряв. T1 робить `get_cost` на кожен із 7 JSON.

## Референси

Усі три є в історії цього акаунта: `show_generations` type=image, 6 сторінок по 100 (T6, 2026-10-09), статус `completed`.

| ярлик | job id (повний) | створено, UTC | файл на диску | що беремо |
|---|---|---|---|---|
| R1a | `55ccd85c-bd41-492b-afc6-b299d6eb969e` | 2026-10-08 08:12 | аркуш у scratchpad, у `game/assets/` лише вирізки (`ui-icon-item-rye_loaf` та ін. у [[Textures-Registry]]) | манера свіжого прийнятого аркуша 2 × 4 на нашій лінії й тіні |
| `props-anchors-v1` | `c5900952-f4f0-4728-8ada-5b30d641be3a` | 2026-10-03 01:34 | `game/assets/props/props_anchors_v1.png` | палітра чавуну, цегли й латуні; масштаб малюнка пропів |
| `sprite-steamcars-v1` | `4603954f-5b46-4067-826c-43788b9d8b79` | 2026-10-03 01:33 | `game/assets/sprites/sprite_steamcars_v1.png` | форма вантажівки (права машина), **без** червоного |
| обраний L1 | `<L1_JOB_ID>` | — | — | L2, L3, V2: T1 підставляє job id L1 після приймання T6. Інших змін у JSON немає |

У реєстрі для `props-anchors-v1` і `sprite-steamcars-v1` UUID скорочено (`c5900952-…`); повні — у [[Menu-Skyline-Prompts]],
рядки 255 і 262, і в історії вище. Якщо `medias` не прийме job id, тоді `media_upload` файлу з диска або `media_import_url` з
CDN-адреси ([[Higgsfield-Pipeline]] § Конвеєр п. 2).

## Блоки

Джерело правди — блоки нижче. JSON у § Запуски зібрано з них скриптом `t6-paint/py/build_prompts.py` (scratchpad; він
перевіряє, що кожен JSON парситься, і що в L1, V1, V2 поза запереченнями немає слів орнаменту).

**`{PAINT}`** — фарбований чавун міста (ADR-027 п. 2). Остаточний hex обрано A/B, у промпті — словами плюс орієнтир.

```
a muted deep green-teal (close to #577368): a medium-dark greyish green with a slight teal cast, matte like old park-railing paint, clearly lighter and greener than the ink lines, never black, never bright emerald, never turquoise
```

**`{PROP_STYLE}`** — у кожному запуску; `{PAINT}` вписано всередину.

```
Prop design sheet for a video game, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite (#2B2230) inked lines with small line breaks, thicker outer contour and thinner inner lines, flat muted base colors with a single cel shadow tone hue-shifted toward magenta-violet, almost no highlights, no gradients, no gloss, no 3D render look. Street objects of the old European-industrial city of Cronshift at the turn of the century, in a muted dusk palette of terracotta, ochre, slate blue, deep teal, cream and dull brass; nothing saturated. Materials only: cast iron and riveted steel painted {PAINT}; copper with pale green patina; dull brass only on handles, grips, rings and valve wheels; cream and teal glazed tiles; worn wood; glass; brick; canvas and rope. At most three graphic wear marks per object (brown-orange rust streaks under rivets, an oil stain, a soot patch above a firebox), no photo texture.
```

**`{GROUP_MACHINE}`** — L1, V1, V2. Орнамент заборонено (П2, П5).

```
Working steam-age machinery, plausible and functional: every pipe leads somewhere, every boiler has a firebox door, a pressure gauge and a safety valve. Only engineering detail — rivets, flanges, bolted bands, plain spoked wheels — and no ornament: no plant curves, no whiplash lines, no leaves, no flowers, no decorative gears.
```

**`{GROUP_NOUVEAU}`** — лише L2. Сецесія живе тільки тут (ADR-027 п. 1).

```
Art Nouveau (Secession) street furniture and street lights in cast and wrought iron: flowing plant-like forms — the whiplash curve, slender stem-like posts, chestnut leaves, sunflower discs, flower-shaped lantern glasses — drawn as clear bold shapes that read at a distance, never as fine lace; the ornament lives only in the iron frames, bases, brackets and crowns.
```

**`{GROUP_YARD}`** — L3.

```
Plain everyday cargo and yard objects of a working street: hand-made, worn and functional, with no ornament at all — no plant curves, no whiplash lines, no decorative ironwork.
```

**`{GRID_PROP_8}`** — аркуші L1–L3.

```
Eight separate objects in two rows of four on a flat muted mint-sage background (#B8CBB1), evenly spaced, each object alone in its own cell with a generous empty margin, each drawn in a three-quarter view from slightly above, as from a third-person game camera. One clear closed silhouette per object, readable as a flat grey shape; objects never touch or overlap; only a soft flat ground shadow ellipse under each.
```

**`{CARD_4}`** — картки V1, V2 (сітка 2 × 2 для нарізки на 4 ракурси Meshy).

```
Single object only, shown four times in a two-by-two grid at exactly the same scale, each view alone in its own quarter of the image with a generous white margin and never crossing into another quarter: top left — straight front view; top right — straight side view; bottom left — straight back view; bottom right — three-quarter view from slightly above. Pure white background, no shadow, no ground plane, no grid lines, flat even lighting, flat colors with inked lines, the whole object inside its quarter in every view, nothing cut off.
```

**`{NEG_PROP}`** — у кожному запуску. К1 `#A3243B` і `#711126` — лише кров ([[Style-Guide]] § Колір).

```
No people, no hands, no faces, no animals, no text, no letters, no numbers, no numerals on dials or gauges (tick marks only), no writing on signs, boards, plates or posters, no brand names, no logos, no watermark, no bright crimson, scarlet or blood-red anywhere (reds only as muted brick-terracotta), no neon, no glowing screens, no LEDs, no chrome, no mirror-polished metal, no plastic, no decorative gears or cogs, no pipes that end in nothing, no open fire except a small warm glow behind a closed firebox door, no smoke clouds covering the objects, no gallows-like silhouette (never a lone upright post with one horizontal beam and a hanging hook), no weapons, no product-photo look.
```

**`{REF_L1}`** — L1 (R1a + `props-anchors-v1`).

```
Both reference images are earlier sheets of the same game: copy the line work, flat coloring, violet shadow and two-rows-of-four layout of the first, the iron, brick and brass palette of the second, and none of their objects.
```

**`{REF_SET}`** — L2, L3 (обраний L1).

```
Take the line work, line thickness, shadow color, palette and drawing scale of the reference image exactly; it is an earlier sheet of the same set of city props, so do not copy its objects.
```

**`{REF_TRUCK}`** — V1 (`sprite-steamcars-v1`).

```
The reference image shows two earlier steam vehicles of the same game: draw the cargo truck on its right in the same form — boiler at the front, open driver's seat, long cargo bed under a tarpaulin, four spoked wheels — and take its line work and flat coloring, but repaint it exactly as described here: nothing of its red color survives.
```

**`{REF_CRANE}`** — V2 (обраний L1, клітинка 4).

```
The reference image is the accepted sheet of steam machines of the same set: draw exactly the slewing steam crane from its fourth cell (top row, right) — the same column, cab, boom, counterweight and hook, the same colors and line work — and nothing else from it.
```

**Формули:**
- аркуш — `{PROP_STYLE} {GROUP_*} {GRID_PROP_8} Objects, left to right, top row then bottom row: {SLOTS} {REF} {NEG_PROP}`;
- картка — `{PROP_STYLE} {GROUP_MACHINE} {CARD_4} {OBJECT} {REF} {NEG_PROP}`.

## Слоти

### L1 — парові машини (`sheet-city-steam-v1`), каталог № 7, 8 (фон), 10–16

```
1) a vertical street steam boiler: a tall riveted cylinder on a cast-iron base, a small arched firebox door with a warm glow in the gap, a pressure gauge, a safety valve and a whistle, a tall thin chimney, a coal shovel leaning on it; twice a man's height; 2) a steam winch: a horizontal drum wound with thick rope, a single steam cylinder with a piston rod and a big spoked flywheel on a heavy iron bed, a steam pipe coming in; chest-high; 3) a steam water pump: a horizontal duplex pump with two parallel cylinders, a domed air chamber on top, an inlet pipe going down into the ground, a flanged outlet pipe along the ground, a pressure gauge; waist-high; 4) a small slewing steam crane on a riveted round column: a short boxy cab with a small chimney, a long straight lattice boom with few diagonals rising at about forty degrees, a counterweight box at the back of the cab, a hook block on a chain hanging from the boom tip; very tall; 5) an air compressor for the pneumatic post: a long riveted receiver tank on cast-iron feet, an upright piston block with a flywheel, a gauge and a safety valve, a pipe into the ground; chest-high; 6) a street pressure post: a slender cast-iron column with a large round dial near the top, one needle and tick marks only, a plain domed cap, a small pipe entering its foot, like a public clock for steam pressure; taller than a man; 7) a steam vent in the pavement: a square cast-iron grate set flush in stone paving, a small valve handwheel beside it, a soft white puff of steam rising; 8) a wall steam pipe kit: a straight pipe with bolted flanges, a ninety-degree elbow, a handwheel valve, a small condensate trap with a drip tray and two wall brackets.
```

### L2 — меблі й світло сецесії (`sheet-city-moderne-v1`), каталог № 17–24

Латунне кільце під ліхтарем і кронштейном — це якір троса: латунь там, де можна торкатись (П6, розвилка Р3 «а»).

```
1) a tall gas street lamp on an Art Nouveau cast-iron post: a flared base with flowing plant-like relief, a slim stem-like post, one curved whiplash arm ending in a flower-shaped glass lantern with a warm light, a sturdy dull brass ring under the arm; 2) a wrought-iron wall bracket lamp with one bold whiplash curve and a small caged lantern with a warm light, the wall plate visible, a sturdy dull brass ring under the bracket; 3) an octagonal Art Nouveau street kiosk: a cast-iron frame with stem-like corner posts, glazed windows, a base of cream and teal glazed tiles, a bell-shaped copper dome with pale green patina and a small flower finial, a short canvas awning, a plain blank fascia with nothing written on it; 4) a street clock on a column: a slender stem-like cast-iron column with chestnut-leaf relief at its foot, a two-sided round clock head, dials with tick marks only and no numerals, a crown of iron leaves; 5) a bench with cast-iron side frames in flowing plant-like whiplash curves and worn wooden slats, the seat at knee height; 6) a cast-iron litter bin shaped like a slotted basket with a small domed lid and a simple leaf motif on the rim; 7) a cast-iron post box on a short pillar with a plain blank front, and beside it a pneumatic tube post pillar with a round dull brass hatch; 8) an advertising column: a thick cylinder with a small domed cap and a flower finial, covered with posters that show only simple pictures (a teacup, a boat, a flower) and plain colored blocks, no lettering.
```

### L3 — вантаж і двір (`sheet-city-yard-v1`), каталог № 1–6, 25, 27–28

```
1) an oak beer barrel with a bulging belly and three iron hoops, about waist-high, and beside it a smaller barrel lying on a wooden cradle with a dull brass tap; 2) a wooden rain-water barrel with a closed wooden lid under the lower end of a copper downpipe, no ladle, no cup; 3) a riveted steel tar drum with a round lid and thick dark plum-brown tar drips down its side; 4) a stack of three wooden cargo crates with iron corner straps and blank painted stencil blotches with no letters; 5) a wooden coal bunker with iron corner straps, chest-high, a heap of coal inside and a shovel stuck in the coal; 6) a two-wheeled wooden hand cart with spoked wheels carrying tied cloth sacks; 7) a rope-and-pulley cargo lift against a short piece of brick wall: a wooden platform hanging on four ropes, a hooded pulley fixed under a small roof bracket on the wall, a counterweight; 8) three hanging shop signs on plain wrought-iron brackets, each a flat wooden board cut as a simple pictogram silhouette: a mug, a pair of scissors, a pocket watch.
```

### V1 — паромобіль-вантажівка (`card-city-steamtruck-v1`), каталог № 9

```
The object: a steam cargo truck of the early 1900s, about five metres long and a little taller than a man: a round riveted boiler at the front with a short chimney and two round lamps, a small open driver's seat behind it with a plain steering wheel, a long wooden cargo bed with plank sides under a tied grey canvas tarpaulin, four spoked wooden wheels with iron rims, the front pair smaller. The boiler, the chimney base, the chassis frame and the wheel hubs are cast iron and steel painted the muted deep green-teal described above, held by bolted iron bands; the side boards of the cargo bed and the mudguards are painted muted slate blue (close to #4A5C73); dull brass only on the steering wheel rim; the rest is worn natural wood, grey canvas and rope. No number plate, nothing written on the boards.
```

### V2 — паровий кран (`card-city-crane-v1`), каталог № 10

Слова збігаються з L1 · 4; референс — обраний L1, тож форма береться з тієї клітинки, яку T6 прийняв.

```
The object: a small slewing steam crane on a riveted round cast-iron column: a short boxy cab with a small chimney and a pressure gauge on its side, a long straight lattice boom with few diagonals rising at about forty degrees, a counterweight box at the back of the cab, a hook block on a chain hanging from the boom tip; the column about twice a man's height, the boom about three times. Column, cab, boom and counterweight are cast iron and steel painted the muted deep green-teal described above; the cab roof is copper with pale green patina; dull brass only on the gauge rim and the control lever.
```

## Запуски — точний JSON

Хвилі: **1** — L1 і V1 (не залежать одне від одного); **2** — L2, L3, V2 (після того, як T6 прийняв L1); **3** — M1, M2
(після того, як T6 прийняв V1 і V2 та їх нарізано). Разом **7**. Стеля 11 (+ V3/M3 і 2 повтори лише з причиною в журналі).

| № | хвиля | модель | `medias` (роль) | що з нього береться |
|---|---|---|---|---|
| L1 | 1 | `gpt_image_2_5` high 2k 16:9 opaque | R1a + `props-anchors-v1` (`image_references`) | канон форм парових машин № 7–8, 10–16; `{REF_SET}` для L2, L3, V2 |
| V1 | 1 | те саме | `sprite-steamcars-v1` (`image_references`) | 4 ракурси вантажівки № 9 → вхід M1 |
| L2 | 2 | те саме | обраний L1 (`image_references`) | канон сецесії: ліхтарі, кронштейни, кіоск, годинник, лавка, урна, пошта, тумба № 17–24 |
| L3 | 2 | те саме | обраний L1 (`image_references`) | бочки, ящики, бункер, візок, ліфт, вивіски № 1–6, 25, 27–28 |
| V2 | 2 | те саме | обраний L1 (`image_references`) | 4 ракурси крана № 10 → вхід M2 |
| M1 | 3 | `multi_image_to_3d` | 4 чверті V1 після `media_upload` (`image`) | GLB вантажівки → децимація й постеризація (T2) |
| M2 | 3 | `multi_image_to_3d` | 4 чверті V2 після `media_upload` (`image`) | GLB крана → те саме |

### L1

```json
{
 "model": "gpt_image_2_5",
 "prompt": "Prop design sheet for a video game, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite (#2B2230) inked lines with small line breaks, thicker outer contour and thinner inner lines, flat muted base colors with a single cel shadow tone hue-shifted toward magenta-violet, almost no highlights, no gradients, no gloss, no 3D render look. Street objects of the old European-industrial city of Cronshift at the turn of the century, in a muted dusk palette of terracotta, ochre, slate blue, deep teal, cream and dull brass; nothing saturated. Materials only: cast iron and riveted steel painted a muted deep green-teal (close to #577368): a medium-dark greyish green with a slight teal cast, matte like old park-railing paint, clearly lighter and greener than the ink lines, never black, never bright emerald, never turquoise; copper with pale green patina; dull brass only on handles, grips, rings and valve wheels; cream and teal glazed tiles; worn wood; glass; brick; canvas and rope. At most three graphic wear marks per object (brown-orange rust streaks under rivets, an oil stain, a soot patch above a firebox), no photo texture. Working steam-age machinery, plausible and functional: every pipe leads somewhere, every boiler has a firebox door, a pressure gauge and a safety valve. Only engineering detail — rivets, flanges, bolted bands, plain spoked wheels — and no ornament: no plant curves, no whiplash lines, no leaves, no flowers, no decorative gears. Eight separate objects in two rows of four on a flat muted mint-sage background (#B8CBB1), evenly spaced, each object alone in its own cell with a generous empty margin, each drawn in a three-quarter view from slightly above, as from a third-person game camera. One clear closed silhouette per object, readable as a flat grey shape; objects never touch or overlap; only a soft flat ground shadow ellipse under each. Objects, left to right, top row then bottom row: 1) a vertical street steam boiler: a tall riveted cylinder on a cast-iron base, a small arched firebox door with a warm glow in the gap, a pressure gauge, a safety valve and a whistle, a tall thin chimney, a coal shovel leaning on it; twice a man's height; 2) a steam winch: a horizontal drum wound with thick rope, a single steam cylinder with a piston rod and a big spoked flywheel on a heavy iron bed, a steam pipe coming in; chest-high; 3) a steam water pump: a horizontal duplex pump with two parallel cylinders, a domed air chamber on top, an inlet pipe going down into the ground, a flanged outlet pipe along the ground, a pressure gauge; waist-high; 4) a small slewing steam crane on a riveted round column: a short boxy cab with a small chimney, a long straight lattice boom with few diagonals rising at about forty degrees, a counterweight box at the back of the cab, a hook block on a chain hanging from the boom tip; very tall; 5) an air compressor for the pneumatic post: a long riveted receiver tank on cast-iron feet, an upright piston block with a flywheel, a gauge and a safety valve, a pipe into the ground; chest-high; 6) a street pressure post: a slender cast-iron column with a large round dial near the top, one needle and tick marks only, a plain domed cap, a small pipe entering its foot, like a public clock for steam pressure; taller than a man; 7) a steam vent in the pavement: a square cast-iron grate set flush in stone paving, a small valve handwheel beside it, a soft white puff of steam rising; 8) a wall steam pipe kit: a straight pipe with bolted flanges, a ninety-degree elbow, a handwheel valve, a small condensate trap with a drip tray and two wall brackets. Both reference images are earlier sheets of the same game: copy the line work, flat coloring, violet shadow and two-rows-of-four layout of the first, the iron, brick and brass palette of the second, and none of their objects. No people, no hands, no faces, no animals, no text, no letters, no numbers, no numerals on dials or gauges (tick marks only), no writing on signs, boards, plates or posters, no brand names, no logos, no watermark, no bright crimson, scarlet or blood-red anywhere (reds only as muted brick-terracotta), no neon, no glowing screens, no LEDs, no chrome, no mirror-polished metal, no plastic, no decorative gears or cogs, no pipes that end in nothing, no open fire except a small warm glow behind a closed firebox door, no smoke clouds covering the objects, no gallows-like silhouette (never a lone upright post with one horizontal beam and a hanging hook), no weapons, no product-photo look.",
 "quality": "high",
 "resolution": "2k",
 "aspect_ratio": "16:9",
 "background": "opaque",
 "count": 1,
 "medias": [
  {
   "role": "image_references",
   "value": "55ccd85c-bd41-492b-afc6-b299d6eb969e"
  },
  {
   "role": "image_references",
   "value": "c5900952-f4f0-4728-8ada-5b30d641be3a"
  }
 ]
}
```

### V1

```json
{
 "model": "gpt_image_2_5",
 "prompt": "Prop design sheet for a video game, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite (#2B2230) inked lines with small line breaks, thicker outer contour and thinner inner lines, flat muted base colors with a single cel shadow tone hue-shifted toward magenta-violet, almost no highlights, no gradients, no gloss, no 3D render look. Street objects of the old European-industrial city of Cronshift at the turn of the century, in a muted dusk palette of terracotta, ochre, slate blue, deep teal, cream and dull brass; nothing saturated. Materials only: cast iron and riveted steel painted a muted deep green-teal (close to #577368): a medium-dark greyish green with a slight teal cast, matte like old park-railing paint, clearly lighter and greener than the ink lines, never black, never bright emerald, never turquoise; copper with pale green patina; dull brass only on handles, grips, rings and valve wheels; cream and teal glazed tiles; worn wood; glass; brick; canvas and rope. At most three graphic wear marks per object (brown-orange rust streaks under rivets, an oil stain, a soot patch above a firebox), no photo texture. Working steam-age machinery, plausible and functional: every pipe leads somewhere, every boiler has a firebox door, a pressure gauge and a safety valve. Only engineering detail — rivets, flanges, bolted bands, plain spoked wheels — and no ornament: no plant curves, no whiplash lines, no leaves, no flowers, no decorative gears. Single object only, shown four times in a two-by-two grid at exactly the same scale, each view alone in its own quarter of the image with a generous white margin and never crossing into another quarter: top left — straight front view; top right — straight side view; bottom left — straight back view; bottom right — three-quarter view from slightly above. Pure white background, no shadow, no ground plane, no grid lines, flat even lighting, flat colors with inked lines, the whole object inside its quarter in every view, nothing cut off. The object: a steam cargo truck of the early 1900s, about five metres long and a little taller than a man: a round riveted boiler at the front with a short chimney and two round lamps, a small open driver's seat behind it with a plain steering wheel, a long wooden cargo bed with plank sides under a tied grey canvas tarpaulin, four spoked wooden wheels with iron rims, the front pair smaller. The boiler, the chimney base, the chassis frame and the wheel hubs are cast iron and steel painted the muted deep green-teal described above, held by bolted iron bands; the side boards of the cargo bed and the mudguards are painted muted slate blue (close to #4A5C73); dull brass only on the steering wheel rim; the rest is worn natural wood, grey canvas and rope. No number plate, nothing written on the boards. The reference image shows two earlier steam vehicles of the same game: draw the cargo truck on its right in the same form — boiler at the front, open driver's seat, long cargo bed under a tarpaulin, four spoked wheels — and take its line work and flat coloring, but repaint it exactly as described here: nothing of its red color survives. No people, no hands, no faces, no animals, no text, no letters, no numbers, no numerals on dials or gauges (tick marks only), no writing on signs, boards, plates or posters, no brand names, no logos, no watermark, no bright crimson, scarlet or blood-red anywhere (reds only as muted brick-terracotta), no neon, no glowing screens, no LEDs, no chrome, no mirror-polished metal, no plastic, no decorative gears or cogs, no pipes that end in nothing, no open fire except a small warm glow behind a closed firebox door, no smoke clouds covering the objects, no gallows-like silhouette (never a lone upright post with one horizontal beam and a hanging hook), no weapons, no product-photo look.",
 "quality": "high",
 "resolution": "2k",
 "aspect_ratio": "16:9",
 "background": "opaque",
 "count": 1,
 "medias": [
  {
   "role": "image_references",
   "value": "4603954f-5b46-4067-826c-43788b9d8b79"
  }
 ]
}
```

### L2

```json
{
 "model": "gpt_image_2_5",
 "prompt": "Prop design sheet for a video game, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite (#2B2230) inked lines with small line breaks, thicker outer contour and thinner inner lines, flat muted base colors with a single cel shadow tone hue-shifted toward magenta-violet, almost no highlights, no gradients, no gloss, no 3D render look. Street objects of the old European-industrial city of Cronshift at the turn of the century, in a muted dusk palette of terracotta, ochre, slate blue, deep teal, cream and dull brass; nothing saturated. Materials only: cast iron and riveted steel painted a muted deep green-teal (close to #577368): a medium-dark greyish green with a slight teal cast, matte like old park-railing paint, clearly lighter and greener than the ink lines, never black, never bright emerald, never turquoise; copper with pale green patina; dull brass only on handles, grips, rings and valve wheels; cream and teal glazed tiles; worn wood; glass; brick; canvas and rope. At most three graphic wear marks per object (brown-orange rust streaks under rivets, an oil stain, a soot patch above a firebox), no photo texture. Art Nouveau (Secession) street furniture and street lights in cast and wrought iron: flowing plant-like forms — the whiplash curve, slender stem-like posts, chestnut leaves, sunflower discs, flower-shaped lantern glasses — drawn as clear bold shapes that read at a distance, never as fine lace; the ornament lives only in the iron frames, bases, brackets and crowns. Eight separate objects in two rows of four on a flat muted mint-sage background (#B8CBB1), evenly spaced, each object alone in its own cell with a generous empty margin, each drawn in a three-quarter view from slightly above, as from a third-person game camera. One clear closed silhouette per object, readable as a flat grey shape; objects never touch or overlap; only a soft flat ground shadow ellipse under each. Objects, left to right, top row then bottom row: 1) a tall gas street lamp on an Art Nouveau cast-iron post: a flared base with flowing plant-like relief, a slim stem-like post, one curved whiplash arm ending in a flower-shaped glass lantern with a warm light, a sturdy dull brass ring under the arm; 2) a wrought-iron wall bracket lamp with one bold whiplash curve and a small caged lantern with a warm light, the wall plate visible, a sturdy dull brass ring under the bracket; 3) an octagonal Art Nouveau street kiosk: a cast-iron frame with stem-like corner posts, glazed windows, a base of cream and teal glazed tiles, a bell-shaped copper dome with pale green patina and a small flower finial, a short canvas awning, a plain blank fascia with nothing written on it; 4) a street clock on a column: a slender stem-like cast-iron column with chestnut-leaf relief at its foot, a two-sided round clock head, dials with tick marks only and no numerals, a crown of iron leaves; 5) a bench with cast-iron side frames in flowing plant-like whiplash curves and worn wooden slats, the seat at knee height; 6) a cast-iron litter bin shaped like a slotted basket with a small domed lid and a simple leaf motif on the rim; 7) a cast-iron post box on a short pillar with a plain blank front, and beside it a pneumatic tube post pillar with a round dull brass hatch; 8) an advertising column: a thick cylinder with a small domed cap and a flower finial, covered with posters that show only simple pictures (a teacup, a boat, a flower) and plain colored blocks, no lettering. Take the line work, line thickness, shadow color, palette and drawing scale of the reference image exactly; it is an earlier sheet of the same set of city props, so do not copy its objects. No people, no hands, no faces, no animals, no text, no letters, no numbers, no numerals on dials or gauges (tick marks only), no writing on signs, boards, plates or posters, no brand names, no logos, no watermark, no bright crimson, scarlet or blood-red anywhere (reds only as muted brick-terracotta), no neon, no glowing screens, no LEDs, no chrome, no mirror-polished metal, no plastic, no decorative gears or cogs, no pipes that end in nothing, no open fire except a small warm glow behind a closed firebox door, no smoke clouds covering the objects, no gallows-like silhouette (never a lone upright post with one horizontal beam and a hanging hook), no weapons, no product-photo look.",
 "quality": "high",
 "resolution": "2k",
 "aspect_ratio": "16:9",
 "background": "opaque",
 "count": 1,
 "medias": [
  {
   "role": "image_references",
   "value": "<L1_JOB_ID>"
  }
 ]
}
```

### L3

```json
{
 "model": "gpt_image_2_5",
 "prompt": "Prop design sheet for a video game, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite (#2B2230) inked lines with small line breaks, thicker outer contour and thinner inner lines, flat muted base colors with a single cel shadow tone hue-shifted toward magenta-violet, almost no highlights, no gradients, no gloss, no 3D render look. Street objects of the old European-industrial city of Cronshift at the turn of the century, in a muted dusk palette of terracotta, ochre, slate blue, deep teal, cream and dull brass; nothing saturated. Materials only: cast iron and riveted steel painted a muted deep green-teal (close to #577368): a medium-dark greyish green with a slight teal cast, matte like old park-railing paint, clearly lighter and greener than the ink lines, never black, never bright emerald, never turquoise; copper with pale green patina; dull brass only on handles, grips, rings and valve wheels; cream and teal glazed tiles; worn wood; glass; brick; canvas and rope. At most three graphic wear marks per object (brown-orange rust streaks under rivets, an oil stain, a soot patch above a firebox), no photo texture. Plain everyday cargo and yard objects of a working street: hand-made, worn and functional, with no ornament at all — no plant curves, no whiplash lines, no decorative ironwork. Eight separate objects in two rows of four on a flat muted mint-sage background (#B8CBB1), evenly spaced, each object alone in its own cell with a generous empty margin, each drawn in a three-quarter view from slightly above, as from a third-person game camera. One clear closed silhouette per object, readable as a flat grey shape; objects never touch or overlap; only a soft flat ground shadow ellipse under each. Objects, left to right, top row then bottom row: 1) an oak beer barrel with a bulging belly and three iron hoops, about waist-high, and beside it a smaller barrel lying on a wooden cradle with a dull brass tap; 2) a wooden rain-water barrel with a closed wooden lid under the lower end of a copper downpipe, no ladle, no cup; 3) a riveted steel tar drum with a round lid and thick dark plum-brown tar drips down its side; 4) a stack of three wooden cargo crates with iron corner straps and blank painted stencil blotches with no letters; 5) a wooden coal bunker with iron corner straps, chest-high, a heap of coal inside and a shovel stuck in the coal; 6) a two-wheeled wooden hand cart with spoked wheels carrying tied cloth sacks; 7) a rope-and-pulley cargo lift against a short piece of brick wall: a wooden platform hanging on four ropes, a hooded pulley fixed under a small roof bracket on the wall, a counterweight; 8) three hanging shop signs on plain wrought-iron brackets, each a flat wooden board cut as a simple pictogram silhouette: a mug, a pair of scissors, a pocket watch. Take the line work, line thickness, shadow color, palette and drawing scale of the reference image exactly; it is an earlier sheet of the same set of city props, so do not copy its objects. No people, no hands, no faces, no animals, no text, no letters, no numbers, no numerals on dials or gauges (tick marks only), no writing on signs, boards, plates or posters, no brand names, no logos, no watermark, no bright crimson, scarlet or blood-red anywhere (reds only as muted brick-terracotta), no neon, no glowing screens, no LEDs, no chrome, no mirror-polished metal, no plastic, no decorative gears or cogs, no pipes that end in nothing, no open fire except a small warm glow behind a closed firebox door, no smoke clouds covering the objects, no gallows-like silhouette (never a lone upright post with one horizontal beam and a hanging hook), no weapons, no product-photo look.",
 "quality": "high",
 "resolution": "2k",
 "aspect_ratio": "16:9",
 "background": "opaque",
 "count": 1,
 "medias": [
  {
   "role": "image_references",
   "value": "<L1_JOB_ID>"
  }
 ]
}
```

### V2

```json
{
 "model": "gpt_image_2_5",
 "prompt": "Prop design sheet for a video game, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite (#2B2230) inked lines with small line breaks, thicker outer contour and thinner inner lines, flat muted base colors with a single cel shadow tone hue-shifted toward magenta-violet, almost no highlights, no gradients, no gloss, no 3D render look. Street objects of the old European-industrial city of Cronshift at the turn of the century, in a muted dusk palette of terracotta, ochre, slate blue, deep teal, cream and dull brass; nothing saturated. Materials only: cast iron and riveted steel painted a muted deep green-teal (close to #577368): a medium-dark greyish green with a slight teal cast, matte like old park-railing paint, clearly lighter and greener than the ink lines, never black, never bright emerald, never turquoise; copper with pale green patina; dull brass only on handles, grips, rings and valve wheels; cream and teal glazed tiles; worn wood; glass; brick; canvas and rope. At most three graphic wear marks per object (brown-orange rust streaks under rivets, an oil stain, a soot patch above a firebox), no photo texture. Working steam-age machinery, plausible and functional: every pipe leads somewhere, every boiler has a firebox door, a pressure gauge and a safety valve. Only engineering detail — rivets, flanges, bolted bands, plain spoked wheels — and no ornament: no plant curves, no whiplash lines, no leaves, no flowers, no decorative gears. Single object only, shown four times in a two-by-two grid at exactly the same scale, each view alone in its own quarter of the image with a generous white margin and never crossing into another quarter: top left — straight front view; top right — straight side view; bottom left — straight back view; bottom right — three-quarter view from slightly above. Pure white background, no shadow, no ground plane, no grid lines, flat even lighting, flat colors with inked lines, the whole object inside its quarter in every view, nothing cut off. The object: a small slewing steam crane on a riveted round cast-iron column: a short boxy cab with a small chimney and a pressure gauge on its side, a long straight lattice boom with few diagonals rising at about forty degrees, a counterweight box at the back of the cab, a hook block on a chain hanging from the boom tip; the column about twice a man's height, the boom about three times. Column, cab, boom and counterweight are cast iron and steel painted the muted deep green-teal described above; the cab roof is copper with pale green patina; dull brass only on the gauge rim and the control lever. The reference image is the accepted sheet of steam machines of the same set: draw exactly the slewing steam crane from its fourth cell (top row, right) — the same column, cab, boom, counterweight and hook, the same colors and line work — and nothing else from it. No people, no hands, no faces, no animals, no text, no letters, no numbers, no numerals on dials or gauges (tick marks only), no writing on signs, boards, plates or posters, no brand names, no logos, no watermark, no bright crimson, scarlet or blood-red anywhere (reds only as muted brick-terracotta), no neon, no glowing screens, no LEDs, no chrome, no mirror-polished metal, no plastic, no decorative gears or cogs, no pipes that end in nothing, no open fire except a small warm glow behind a closed firebox door, no smoke clouds covering the objects, no gallows-like silhouette (never a lone upright post with one horizontal beam and a hanging hook), no weapons, no product-photo look.",
 "quality": "high",
 "resolution": "2k",
 "aspect_ratio": "16:9",
 "background": "opaque",
 "count": 1,
 "medias": [
  {
   "role": "image_references",
   "value": "<L1_JOB_ID>"
  }
 ]
}
```

### Нарізка карток V1, V2 → 4 зображення (0 кр., головна сесія)

1. Завантажити прийняту картку (2688×1520 за прецедентом R1a) у scratchpad.
2. Розрізати на чверті й покласти кожну по центру білого квадрата:

```
python3 -I -c "
import sys
from PIL import Image
src, tag = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGB'); W, H = im.size
for i, view in enumerate(['front', 'side', 'back', 'three_quarter']):
    x, y = (i % 2) * (W // 2), (i // 2) * (H // 2)
    q = im.crop((x, y, x + W // 2, y + H // 2)); w, h = q.size
    band = [(u, v) for u in range(w) for v in range(h) if u < 8 or v < 8 or u >= w - 8 or v >= h - 8]
    dark = sum(1 for p in band if min(q.getpixel(p)) < 245)
    s = max(w, h); c = Image.new('RGB', (s, s), (255, 255, 255)); c.paste(q, ((s - w) // 2, (s - h) // 2))
    c.save(f'card_{tag}_{view}.png'); print(view, q.size, 'non-white edge px', dark)
" <картка>.png v1
```

3. `non-white edge px` має бути **0** у кожній чверті. Інакше предмет перетинає межу чверті, і M не запускаємо (критерій
   V-4).
4. `media_upload` → `media_confirm` для кожного з 4 файлів. Отримані `media_id` вписуємо в M1 (M2) замість заглушок.

### M1 — паромобіль

```json
{
 "model": "multi_image_to_3d",
 "medias": [
  {
   "role": "image",
   "value": "<V1_FRONT_MEDIA_ID>"
  },
  {
   "role": "image",
   "value": "<V1_SIDE_MEDIA_ID>"
  },
  {
   "role": "image",
   "value": "<V1_BACK_MEDIA_ID>"
  },
  {
   "role": "image",
   "value": "<V1_THREE_QUARTER_MEDIA_ID>"
  }
 ],
 "should_texture": true,
 "enable_pbr": false,
 "enable_rigging": false,
 "enable_animation": false,
 "should_remesh": true,
 "topology": "triangle",
 "target_polycount": 10000,
 "symmetry_mode": "auto",
 "texture_prompt": "flat matte painted colors exactly as in the input views, no baked lighting, no shadows, no highlights, no reflections, no text, no red"
}
```

### M2 — кран

```json
{
 "model": "multi_image_to_3d",
 "medias": [
  {
   "role": "image",
   "value": "<V2_FRONT_MEDIA_ID>"
  },
  {
   "role": "image",
   "value": "<V2_SIDE_MEDIA_ID>"
  },
  {
   "role": "image",
   "value": "<V2_BACK_MEDIA_ID>"
  },
  {
   "role": "image",
   "value": "<V2_THREE_QUARTER_MEDIA_ID>"
  }
 ],
 "should_texture": true,
 "enable_pbr": false,
 "enable_rigging": false,
 "enable_animation": false,
 "should_remesh": true,
 "topology": "triangle",
 "target_polycount": 10000,
 "symmetry_mode": "auto",
 "texture_prompt": "flat matte painted colors exactly as in the input views, no baked lighting, no shadows, no highlights, no reflections, no text, no red"
}
```

Чому так:
- `should_texture: true`, `enable_pbr: false` — наш шейдер читає лише альбедо.
- `enable_rigging: false`, `enable_animation: false`, без `pose_mode` — це не персонаж, машини стоять (ADR-027 п. 4).
- `should_remesh: true` — інакше `topology` і `target_polycount` ігноруються (`models_explore`).
- `topology: triangle`, `target_polycount: 10000` — **PLACEHOLDER до бюджету T3**. Чому 10000: це чинний PLACEHOLDER пропів
  у [[Arenas-360-Prompts]] (рядки 270–271) і нижня межа «5K–20K mobile/web» гайду Meshy ([[2026-10-08-Modern-Realism-And-Prop-Budget]]
  § 3). `quad` 20k давав ~37 тис. трикутників, тобто ×1,86 від цілі (T3); з `triangle` фактичне число невідоме.
- `symmetry_mode: auto` — типове значення.
- `texture_prompt` — Image-to-3D запікає світло ([[Pipeline-2D-to-3D]]); прохання про пласкі кольори зменшує постеризацію.

## Журнал

Запусків ще не було. Сюди записуються job id, `get_cost`, `balance` до й після, вибір і причини — і для вдалих, і для
невдалих промптів.

## Related

- [[2026-10-08-City-Modern-Realism-Props]] · [[ADR-027-City-Modern-Props-Style-And-Path]] · [[2026-10-09-City-Tidy-And-Modern-Props]] · [[Prompt-Library]] · [[Item-Sheets-Prompts]] · [[Menu-Skyline-Prompts]] · [[Arenas-360-Prompts]]
- [[Higgsfield-Pipeline]] · [[Pipeline-2D-to-3D]] · [[Style-Guide]] · [[Textures-Registry]] · [[2026-10-08-Modern-Realism-And-Prop-Budget]] · [[PROPOSAL-City-Machines-And-Objects]]
