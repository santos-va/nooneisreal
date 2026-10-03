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

**IDENTITY — Skea:**
```
wiry young man, messy curly brown hair, wide grey eyes, a manic toothy grin with dental braces, freckles; purple hoodie with the hood down, sleeves in a teal-green camouflage pattern, crossed leather straps; loose black cargo pants with kunai holstered on the thighs; shins wrapped in bandages like a Muay Thai fighter; black-and-purple sneakers; a book-shaped backpack with a glowing purple infinity-eight sigil; tattoo on the forearm
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
| Skea's book-shaped backpack with straps | sigil plate; strap buckles |
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

## Related
- [[Style-Guide]] · [[Asset-Manifest]] · [[Higgsfield-Pipeline]] · [[Prompts]] · [[Choko]] · [[Skea]] · [[Stage-River]]
