# Бібліотека промптів (Sketch-Cel)

Готові до запуску тексти. Кожен = **стильова формула (байт-у-байт) + слоти**. Мова промптів — англійська.
Перед запуском: референс-ідентичність через `media_import_url` (URL зі старих карток у [[Textures-Registry]]),
`get_cost`, слово Santos ([[Higgsfield-Pipeline]]). Що і скільки — [[Asset-Manifest]].

## Стильова формула (STYLE)

```
Hand-drawn character art in a loose, expressive western animation sketch style, NOT anime: lively slightly sketchy line art in dark plum-graphite brown (not pure black), thicker outer contour and thinner inner lines with small line breaks, flat base colors with a single cel shadow tone that is hue-shifted toward magenta-violet (skin shadows pinkish lilac, khaki shadows mauve, blue shadows indigo), almost no highlights, no gradients, no gloss; stylized proportions with head about one fifth of body height, long limbs, slightly oversized hands and shoes; simple dark pupils with thick lashes, no anime sparkles; big chunky hair clumps with pointed tips; few graphic clothing folds; strong gesture and silhouette.
```

## Хвіст (NEG)

```
No anime style, no glossy eyes, no 3D render look, no gradients, no realistic skin texture, no text except the sheet title, no logos, no watermark, no infinity symbol unless specified, hands only as fists or gripping objects with five clearly separated fingers.
```

## 1. Лист поз (8 поз) — `<ch>-sheet-v1`

Референс: стара картка персонажа (ідентичність). Аспект 16:9, gpt_image_2_5 high 2k.

```
{STYLE} Character pose sheet on a flat muted mint-sage background (#B8CBB1), eight full-body poses of the same original character in two rows of four, evenly spaced, no frames: 1) relaxed standing with weight on one leg, 2) hands-on-hips confident, 3) three-quarter walking, 4) dynamic fighting lunge, 5) arms crossed annoyed, 6) back view looking over shoulder, 7) side view idle, 8) pointing or taunting gesture toward the viewer. Keep the identity, outfit and colors of the reference image: {IDENTITY}. Small title "{NAME}" in the top-left corner in hand-lettered marker. {NEG}
```

**IDENTITY — Choko:**
```
young man, lean narrow face, long straight nose, grey-green eyes, thick curly dark-brown hair covering temples and ears; fitted jacket of fine gunmetal chainmail rings with muted dusty-orange leather panels and a thin cream stripe, high collar, sleeves to the wrists; slate blue-grey trousers; black leather gloves; large analog wristwatch on the left wrist; emerald-green pike-style sword with dark green wrapped grip and brass guard
```

**IDENTITY — Skea** (v2 з 2026-10-03, santos-va/nooneisreal#33; попередня — § 12 «Було»; до Skea завжди додавати `{NEG_SKEA}` і пози § 12):
```
lanky, very tall and thin young man of about twenty — for this character only, head about one sixth to one seventh of his height (taller and thinner than the usual proportions), long thin fingers; sharp cheekbones, hollow cheeks, dark magenta-violet shadows under the eyes; pale grey eyes with tiny pinpoint pupils that almost never blink — the eyes stay calm and cold and take no part in the smile; an unnaturally wide smile whose corners reach slightly past where the cheeks should end, too many teeth, thin dark dental braces with a faint violet glint, the smile stays frozen while the rest of the face moves; faint, barely visible freckles; messy curly brown hair falling over the forehead; purple hoodie with the hood down, sleeves in a teal-green camouflage pattern, crossed leather straps; loose black cargo pants with kunai holstered on the thighs; shins wrapped in bandages like a Muay Thai fighter; black-and-purple sneakers; a book-shaped backpack, an old leather grimoire, whose glowing purple infinity-eight sigil sits centered on the back panel only, nothing on its sides; tattoo on the forearm; slack, slouching posture, head tilted, shoulders dropped, standing unnervingly still
```

## 2. Turnaround — `<ch>-turn-v1`

```
{STYLE} Character turnaround model sheet on a flat mint-sage background, four consistent full-body views in a row: front, three-quarter, side profile, back; neutral relaxed standing pose, arms slightly away from the body, same scale and ground line for all views. Identity: {IDENTITY}. Title "{NAME} TURNAROUND". {NEG}
```

## 3. T-pose для 3D — `<ch>-tpose-<view>` (по одній фігурі!)

nano_banana_pro 2k, 3:4. Чотири окремі запуски: `front`, `left side`, `back`, `three-quarter front`.

```
{STYLE} Single full-body figure only, {VIEW} view, standing in a clean T-pose with arms straight out to the sides and palms down, legs slightly apart, feet flat, whole body in frame head to toe, centered. Pure white background, no shadow, no ground plane, no props in hands, weapon removed. Flat even lighting, flat colors with inked lines. Identity: {IDENTITY}. {NEG}
```

## 4. Картка предмета з 4 боків — `<ch>-item-<name>`

```
{STYLE} Item design card on a flat mint-sage background: the {ITEM} shown alone four times in a row — front view, side view, back view, top or three-quarter view — plus two small circled detail insets ({DETAILS}). Same scale in all views, thin inked outline, flat colors with magenta-tinted cel shadow, small hand-written numbers by each view. Title "{ITEM_TITLE}". No hands, no characters. {NEG}
```

| ITEM | DETAILS |
|---|---|
| Choko's emerald pike-style sword with dark green wrapped grip and brass guard | hilt and wrap; blade tip edge |
| Choko's large analog wristwatch with a cracked glass and glowing green hands | dial close-up; clasp |
| Skea's set of three kunai held in a knuckle-ring grip, plus one single kunai | ring grip; blade with purple wrap |
| Skea's grimoire: heavy old leather book with iron corners and a glowing purple infinity-eight sigil | open pages with sealed villain silhouettes; spine and clasp |
| Skea's backpack: an old heavy leather grimoire-book worn as a backpack, with iron corners and shoulder straps; a glowing purple infinity-eight sigil (#9E4CF2) centered on the back panel only, facing away from the wearer, nothing on the sides, straps, flap or spine; the sigil is a plain infinity-eight shape with no face, no eyes, no teeth, no mouth; only the back view shows the sigil | the sigil on the back panel with a faint neon trail drifting off it and dissolving into sparks; strap buckles |
| Choko's ultimate sword: the leftmost sword of the reference sheet, keep its shape and colors (reference image: `weapons-choko-ult`) | crossguard and grip; blade tip |
| Choko's fitted jacket of fine gunmetal chainmail rings with muted dusty-orange leather panels, a thin cream stripe and a high collar | chainmail ring weave; collar and leather panel seam |
| Skea's purple hoodie with the hood down and sleeves in a teal-green camouflage pattern | camouflage sleeve pattern; hood and drawstrings |

## 5. Безшовна текстура — `<ch>-tex-<name>`

nano_banana_pro 2k, 1:1. Шов перевіряти локально (зсув на 50 % і огляд).

```
Seamless tileable flat texture swatch of {MATERIAL}, hand-drawn flat illustration style with inked lines in plum-graphite brown, flat base color with a single magenta-violet shadow tone, perfectly seamless edges on all four sides, flat even lighting, no perspective, no objects, no text.
```

MATERIAL: `fine gunmetal chainmail rings` · `muted dusty-orange leather with stitching` · `teal-green camouflage fabric` · `purple knit cotton` · `cloth bandage wraps` · `river water with flat foam shapes` · `small ripples on dark teal water`.

## 6. Арена «Річка» — `stage-river-plate-v1`

Референс: `game/assets/backgrounds/bg_kronshift_river.jpg` — фон, що зараз у грі; Santos хоче перевести **саме його** ([[2026-10-03-Generation-Waves]], застереження 6). gpt_image_2_5 high 2k, 21:9.

```
Wide game background, 21:9, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines, flat colors with magenta-violet cel shadows. A broad calm river runs through the middle of the old European-industrial city of Cronshift at dusk: brick and terracotta facades along both banks, brass rooftops, the twin domed clock towers of the city, an arched stone bridge in the distance, hanging lanterns reflected as broken flat strokes on the water. Muted palette of terracotta, slate blue and deep teal, warm lantern accents. The lower third is open river surface with flat graphic wave shapes and foam lines, empty and readable as a fighting floor. No people, no boats in the foreground, no text, no logos.
```

## 6b. Арена «Базарчик» — `stage-bazaar-plate-v1`

```
Wide game background, 21:9, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines, flat colors with magenta-violet cel shadows. A narrow bustling bazaar street of the old European-industrial city of Cronshift at early evening: market stalls under faded striped awnings, stacked crates and baskets, hanging lanterns and string lights, brick facades with balconies, steam from a vent, the twin domed clock towers of the city visible far away above the rooftops. Muted palette of terracotta, slate blue and deep teal with warm lantern accents. The lower third is an empty cobblestone street readable as a fighting floor. No people in the foreground, only a few tiny distant silhouettes, no text, no logos.
```

## 6c. Арена «Площа з фонтаном» (ніч) — `stage-fountain-plate-night-v1`

```
Wide game background, 21:9, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines, flat colors with magenta-violet cel shadows. The central square of the old European-industrial city of Cronshift at night: a large round stone fountain with a bronze statue in the middle ground, wet cobblestones, gas lamps, surrounding facades with lit windows. Far in the background a very tall thin tower rises above the city, and near its top glow big neon letters reading "CRONSHIFT", partly veiled by drifting night clouds. Deep teal and slate night palette, warm lamp light, the neon sign the only saturated glow. The lower third is an open square readable as a fighting floor. No people in the foreground, no other text, no logos.
```

Сутінковий варіант — той самий кадр як референс: «same composition at dusk, the neon sign on the distant tower is switched off and barely visible».
Шар напису окремо (прозорий фон): `Neon letters "CRONSHIFT" glowing in {COLOR}, hand-drawn sketch style, transparent background, no tower, no other text.` Написання — CRONSHIFT ([[ADR-010-City-Name-Cronshift]]); модель малює текст, тож кожен варіант перевірити по літерах до відбору.

## 7. VFX — зірка влучання (прозорий фон)

gpt_image_2_5, `background:"transparent"`, 1:1.

```
Single hand-drawn hit impact star burst for a fighting game, sharp irregular spikes, inked plum-graphite outline, flat {COLOR} fill with a white hot core, a few loose ink speed strokes around it, transparent background, centered, no text.
```

COLOR: `warm cream` (звичайний) · `violet #9E4CF2` (крит Skea) · `emerald #29C775` (Choko) · `pale blue` (блок).

## 8. Головне меню «Погляд з даху»

Окремий файл — [[Menu-Skyline-Prompts]] (панорама, передній план, перехожі, парові машини, пара, пози прольоту).

## 9. Лист поз з двома референсами (хвиля 2, `skea-sheet-v1`)

Шаблон § 1 з одною зміною: референсів два — затверджений лист Choko `f21298f4` (манера) і стара картка Skea
`4cf75fc8` (ідентичність). Фраза «Keep the identity, outfit and colors of the reference image:» замінена на
«Match the drawing style, line and shading of the first reference image exactly; keep the identity, outfit and colors of the character in the second reference image:».
Turnaround, T-pose і картки предметів хвилі 2 — шаблони § 2–4 байт-у-байт, референс = затверджений лист персонажа
(Choko `f21298f4`, Skea `9c0b4476`); ульт-меч — другий референс `d41babe1` (`weapons_choko_ultimate.png`).

## 10. Пропси-якорі — `props-anchors-v1` ([[ADR-011-Diegetic-Grapple-Anchors]])

gpt_image_2_5 high 2k 16:9, референс — переможець річки `a2913501`.

```
Prop design sheet for a fighting game, on a flat muted mint-sage background (#B8CBB1), hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines with small line breaks, flat colors with a single magenta-violet cel shadow tone, no gradients, no gloss. Four grappling-hook anchor props of the old European-industrial city of Cronshift, matching the architecture and dusk palette of the reference image, each shown twice — front view and three-quarter view — in two rows with even spacing: 1) a big heavy wrought-iron street lamp with a thick curled arm and a caged lantern; 2) a large billboard on a riveted steel frame with legs, the board showing a simple painted picture with no letters at all (a steaming teacup under a smiling sun); 3) an industrial brick-and-iron chimney stack with a service ladder and heavy iron clamps; 4) a tall rooftop ventilation pipe column with a cowl, bolted collars and a valve wheel. On every prop a sturdy iron ring or hook point where a grappling line can catch, clearly visible. Same scale reference, small hand-written numbers by each prop. No people, no letters or words anywhere on the billboard or props, no logos, no watermark.
```

## 11. Важкий дрон — `drone-heavy-v1` ([[ADR-011-Diegetic-Grapple-Anchors]])

gpt_image_2_5 high 2k 16:9, референс — переможець річки `a2913501`.

```
Prop design sheet for a fighting game, on a flat muted mint-sage background (#B8CBB1), hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines with small line breaks, flat colors with a single magenta-violet cel shadow tone, no gradients, no gloss. A heavy, almost silent cargo drone of the old European-industrial city of Cronshift, matching the dusk palette of the reference image: a riveted brass and dark-teal hull like a small airship gondola, four enclosed ducted rotors in round iron cages, a strong winch with a big iron hook hanging under its belly, small warm lamps. The same drone shown in five panels with even spacing and the same scale: 1) hovering calm and level; 2) tilting hard toward a pull from the lower left, the hook cable taut, rotors straining; 3) sagging down under a heavy load, hull slightly squashed, small vibration lines, rotor rims glowing warmer; 4) recovering back to level with a small wobble; 5) a small silhouette seen from directly below. Small hand-written numbers by each panel. No people, no letters or words, no logos, no watermark.
```

Тайли води (§ 5) у хвилі 2 — з референсом річки `a2913501`. Outpaint річки (§ 6) — промпт «Continue the same hand-drawn
sketch-style dusk river city seamlessly to the left and right…» — не пройшов (422), див. [[Menu-Skyline-Prompts]] § Хвиля 2.

## 12. Skea — психопат із надприродною посмішкою (santos-va/nooneisreal#33)

Бриф — [[2026-10-03-Skea-Redesign]]. `{STYLE}` і `{NEG}` — без змін (§ 0); IDENTITY Skea в § 1 замінено на v2.
**Конфлікт, який закриваємо явно:** `{STYLE}` каже «head about one fifth of body height» (це пропорції Choko); у
IDENTITY v2 стоїть «for this character only, head about one sixth to one seventh» — модель отримує обидва, перевага в
пізнішого й конкретнішого. Якщо на пробі Skea вийде з головою 1/5 — правка `{STYLE}` окремим словом Santos.

**`{NEG_SKEA}`** (додається після `{NEG}` у кожному промпті Skea):
```
Not cute, not chibi, not goofy, not comedic, not kawaii, not wholesome, not childlike, no round baby face, no big sparkly eyes, no cheerful grin; unsettling and quietly menacing, yet still the same flat hand-drawn sketch style — no horror realism, no gore, no blood.
```

**Пози листа Skea** (заміна поз § 1 для Skea):
```
1) head tilted about thirty degrees, staring straight at the viewer with the frozen smile, 2) crouched low on his heels, a kunai spinning on one finger, 3) standing perfectly straight, arms hanging loose, the smile, 4) laughing with the head thrown back, 5) mid flash-step with a fading violet ghost of himself left behind, 6) the grimoire open in his hands, his face lit from below in violet, 7) back view, looking over the shoulder with the smile, the sigil glowing on the back of the backpack, 8) fingers drumming on his lips, eyes sliding to the side
```

### 12a. Лист поз Skea v2 — `skea-sheet-v2`

gpt_image_2_5 high 2k 16:9. Референси: 1) лист Choko `f21298f4` (манера), 2) стара картка Skea `4cf75fc8` (одяг, кольори).

```
{STYLE} Character pose sheet on a flat muted mint-sage background (#B8CBB1), eight full-body poses of the same original character in two rows of four, evenly spaced, no frames: {POSES_SKEA}. Match the drawing style, line and shading of the first reference image exactly; take only the outfit and colors from the second reference image, not its face or proportions: {IDENTITY_SKEA_V2}. Small title "SKEA" in the top-left corner in hand-lettered marker. {NEG} {NEG_SKEA}
```

### 12b. Лист облич Skea — `skea-faces-v1`

gpt_image_2_5 high 2k 16:9, ті самі два референси. Основа для 3D: обличчя моделі — намальований атлас виразів ([[2026-10-03-Skea-Redesign]] § Як посмішка переживе 3D).

```
{STYLE} Expression sheet on a flat muted mint-sage background (#B8CBB1): eight head-and-shoulders portraits of the same original character in two rows of four, all in the same three-quarter angle and the same scale, small hand-written numbers: 1) calm, a blank cold stare, mouth closed; 2) his base smile, eyes not smiling; 3) the smile stretched impossibly too wide, corners past the cheeks; 4) laughing, head thrown slightly back; 5) rage, teeth bared through the braces; 6) boredom, half-lidded eyes; 7) predatory interest, head tilted, eyes locked on the viewer; 8) the supernatural moment: a faint violet glow behind the teeth and deep in the pinpoint pupils. Match the drawing style of the first reference image exactly; outfit colors from the second reference image: {IDENTITY_SKEA_V2}. Title "SKEA FACES". {NEG} {NEG_SKEA}
```

### 12c. Картка рюкзака v2 — `skea-item-backpack-v2` (S2b)

Шаблон § 4 з новим рядком ITEM рюкзака (вісімка лише ззаду). Референси: лист Choko `f21298f4`, стара картка Skea `4cf75fc8`.
Загальний `{NEG}` «no infinity symbol unless specified» лишається: тепер сигіл specified, з місцем.

### 12d. Було (v1, хвиля 2 — «дитячий» Skea)

```
wiry young man, messy curly brown hair, wide grey eyes, a manic toothy grin with dental braces, freckles; purple hoodie with the hood down, sleeves in a teal-green camouflage pattern, crossed leather straps; loose black cargo pants with kunai holstered on the thighs; shins wrapped in bandages like a Muay Thai fighter; black-and-purple sneakers; a book-shaped backpack with a glowing purple infinity-eight sigil; tattoo on the forearm
```

## Related
- [[Style-Guide]] · [[Asset-Manifest]] · [[Higgsfield-Pipeline]] · [[Prompts]] · [[Choko]] · [[Skea]] · [[Stage-River]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[2026-10-03-Skea-Redesign]]
