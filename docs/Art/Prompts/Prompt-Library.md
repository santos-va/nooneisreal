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

**IDENTITY — Choko** (v5.2 з 2026-10-03 — кросівки **P-6000 за описом T1** (сітка з горизонтальними й вертикальними накладками, вікна на носку й п'яті, висока підошва) з монограмою «C» Z-2, Santos «б»; v5.1 — куртка **без жодних смуг**, ні спереду, ні ззаду, Santos після вибору спини Z-1; v5 з 2026-10-03: гладка спина + кросівки, [[2026-10-03-Choko-Outfit-v5]]; до Choko завжди додавати `{NEG_CHOKO}` § 15; попередня v4 — § 15 «Було»):
```
young man, lean narrow face, long straight nose, grey-green eyes, thick curly dark-brown hair covering temples and ears; the whole back of the jacket is one smooth plain dusty-orange cloth panel with no stripe, no seam and no metal on the back; light fitted cloth jacket in plain solid muted dusty orange with no stripes anywhere and a high collar, sleeves to the wrists, cut for a fast acrobatic swordsman, with small sewn-on patches of fine gunmetal ring mesh on the shoulder caps and the outer forearms only; slate blue-grey trousers; low-top Y2K-era retro running sneakers: breathable light-grey mesh base with layered horizontal and vertical metallic silver-grey synthetic overlays, windowed mesh panels on the toe and heel, a tall chunky foam midsole and a full rubber outsole; muted dusty-orange accent panels on the heel tab, around the lace eyelets and along the outsole, the same orange as the jacket; no brand logos; the only mark is a hand-lettered cursive capital C with a curled tail on the outer side panel of each sneaker, in muted dusty orange; black leather gloves; large analog wristwatch on the left wrist; emerald-green pike-style sword with dark green wrapped grip and brass guard
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
| Choko's low-top 2000s retro running sneakers, a pair: breathable mesh base with layered silver-grey synthetic overlays, chunky segmented light-grey midsole with a visible heel cage, light grey with muted orange accent panels on the heel tab, around the lace eyelets and on the outsole, no logos, no brand marks, plain side panels (§ 15, без референсу) | heel cage and orange heel tab; lace eyelets with the orange panel and the segmented outsole |

## 5. Безшовна текстура — `<ch>-tex-<name>`

nano_banana_pro 2k, 1:1. Шов перевіряти локально (зсув на 50 % і огляд).

```
Seamless tileable flat texture swatch of {MATERIAL}, hand-drawn flat illustration style with inked lines in plum-graphite brown, flat base color with a single magenta-violet shadow tone, perfectly seamless edges on all four sides, flat even lighting, no perspective, no objects, no text.
```

MATERIAL: `fine gunmetal chainmail rings` · `muted dusty-orange leather with stitching` · `teal-green camouflage fabric` · `purple knit cotton` · `cloth bandage wraps` · `river water with flat foam shapes` · `small ripples on dark teal water`.

### 5a. Піна річки v2 — `tex-water-foam-v2` (T6, Santos «go», 2026-10-03)

v1 `b0a9189d` (з референсом річки `a2913501`) вийшла з розмазаною смугою відблисків міста на 55–87 % висоти — гіпотеза T6: місто
протягнув референс. v2 — **без референсу**, кольори hex із тайла брижів (`convert … -colors 4 histogram` → `#244657`, `#2F3C4F`, `#503F59`).
`nano_banana_pro` 2k 1:1, `get_cost` → 2, ×1; результат `3e04a378` — **канон**. Шов: `convert -roll +1024+1024` — стиків не видно,
кілька плям на старих краях трохи розмиті.

```
Seamless tileable flat texture swatch of river water foam seen straight from above: scattered flat foam shapes and thin foam streaks floating on dark teal water (#244657, darker patches #2F3C4F), foam in pale lilac-white with a single magenta-violet shadow edge (#503F59), hand-drawn flat illustration style with inked lines in plum-graphite brown, flat base color, perfectly seamless edges on all four sides, the same even density of foam everywhere, flat even lighting, orthographic top-down, no perspective, no horizon, no sky, no reflections, no city, no lights, no gradient bands, no objects, no text.
```

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

## 13. Choko — одяг v4 (рішення Santos 2026-10-03)

Santos побачив, що на різних картках верх Choko різний: десь кольчужна куртка, десь сорочка. Канон тепер один —
**легка приталена тканинна куртка** приглушено-помаранчева, кремова смуга, високий комір, рукави до зап'ясть;
**кольчуга лише вставками** на плечах і передпліччях. Повної кольчужної куртки й сорочки більше немає. IDENTITY в § 1 замінено.

Промпти, що просили **повну** кольчугу (тобто можуть розходитися з v4; що саме намальовано — **не перевірено мною**,
CDN із хмари закритий): лист `f21298f4`, поворот `1fa22c1b` (Х2-5), T-пози `c280d939`/`822b889d`/`f0763795`/`cbaf6f58`
(Х2-8…11), картка куртки `4b792412` (Х2-19). Рядок ITEM куртки в § 4 застарів; нова картка куртки:
«Choko's light fitted cloth jacket in muted dusty orange with a thin cream stripe and a high collar, chainmail ring panels only on the shoulders and forearms» · DETAILS «chainmail shoulder panel; collar and cream stripe».

Було (v3):
```
young man, lean narrow face, long straight nose, grey-green eyes, thick curly dark-brown hair covering temples and ears; fitted jacket of fine gunmetal chainmail rings with muted dusty-orange leather panels and a thin cream stripe, high collar, sleeves to the wrists; slate blue-grey trousers; black leather gloves; large analog wristwatch on the left wrist; emerald-green pike-style sword with dark green wrapped grip and brass guard
```

### 13a. Передача T1 (не робота T6)

Santos хоче Choko «вправнішим мечником і акробатом» — це мувсет і пози бою (T5 Арес) і план (T1 Дедал). Одяг v4 уже
легший під це; пози листа Choko v4 — після рішення T1/T5.

## 14. Skea — одяг v3 (Santos 2026-10-03, у роботі)

Поверх § 12 (обличчя, посмішка, постава лишаються з v2; канон листа — `dcdef91d`, S-1):

| що | рішення Santos | промпт |
|---|---|---|
| Худі | фото від Santos у чаті (фіолетове оверсайз-зіп-худі з білим потертим каліграфічним принтом) | `an oversized boxy purple zip-up hoodie with dropped shoulders, a full-length silver zipper, long baggy sleeves gathered in ribbed cuffs, a ribbed hem and a kangaroo pocket, printed across the chest and down both sleeves with a large flowing white cracked, distressed calligraphic script ornament that has no readable letters` — фото в репо й у Higgsfield **не кладемо**. **Напису немає** (Santos: «не треба», орнамент складно тримати однаковим) — канон картки `ab80973c` (N-5) |
| Капюшон | висить донизу за спиною, майже схований рюкзаком | `hood down, hanging low on his back, mostly hidden behind the backpack` |
| Взуття | «типу New Balance 1960, без лого, повністю білі з чорними акцентами» | `chunky retro running sneakers, layered suede and mesh panels, thick sculpted white midsole, all white with small black accent panels and a black accent stripe on the side, no logos, no brand marks` — бренд у промпті **не називаємо** |
| Штани й бинти | оверсайз карго; бинти щільно поверх низу штанин, як в оригіналі | `loose oversized black cargo pants, their lower legs tightly wrapped over the fabric with cloth bandages from the ankle to below the knee, like a Muay Thai fighter` |

### 14a. IDENTITY Skea v3 (одяг v3 + обличчя v2)

```
lanky, very tall and thin young man of about twenty — for this character only, head about one sixth to one seventh of his height (taller and thinner than the usual proportions), long thin fingers; sharp cheekbones, hollow cheeks, dark magenta-violet shadows under the eyes; pale grey eyes with tiny pinpoint pupils that almost never blink — the eyes stay calm and cold and take no part in the smile; an unnaturally wide smile whose corners reach slightly past where the cheeks should end, too many teeth, thin dark dental braces with a faint violet glint, the smile stays frozen while the rest of the face moves; faint, barely visible freckles; messy curly brown hair falling over the forehead; an oversized boxy purple zip-up hoodie with dropped shoulders, a full-length silver zipper, long baggy sleeves gathered in ribbed cuffs, a ribbed hem and a kangaroo pocket, printed across the chest and down both sleeves with a large flowing white cracked, distressed calligraphic script ornament that has no readable letters, the hood down, hanging low on his back, mostly hidden behind the backpack; crossed leather straps; loose oversized black cargo pants with kunai holstered on the thighs, their lower legs tightly wrapped over the fabric with cloth bandages from the ankle to below the knee, like a Muay Thai fighter; chunky retro running sneakers with layered suede and mesh panels and a thick sculpted white midsole, all white with small black accent panels and a black accent stripe on the side, no logos, no brand marks; a book-shaped backpack, an old leather grimoire, whose glowing purple infinity-eight sigil sits centered on the back panel only, nothing on its sides; tattoo on the forearm; slack, slouching posture, head tilted, shoulders dropped, standing unnervingly still
```

### 14b. S3 — поворот і 4 T-пози Skea v3 (Santos 2026-10-03, [[2026-10-03-Picks-to-Game-and-Animation]] § A)

Лист v3 N-4 не перегенеровуємо (рішення T1). gpt_image_2_5 high 2k: поворот 16:9 ×1, T-пози 3:4 ×4 (`front`, `left side`, `back`, `three-quarter front`).
Референси в цьому порядку (пріоритет, якщо модель візьме менше): 1) лист S-1 `dcdef91d` — обличчя, пропорції, манера; 2) худі N-5
`ab80973c`; 3) кросівки N-6 `d2ac65b6`; 4) обличчя S-5 `36ace5cf`. IDENTITY — § 14a. Хвіст `{NEG_S3}` = `{NEG} {NEG_SKEA}` + `Both arms fully visible, two hands.`

**Поворот** `skea-turn-v3`:
```
{STYLE} Character turnaround model sheet on a flat mint-sage background, four consistent full-body views in a row: front, three-quarter, side profile, back; neutral relaxed standing pose, arms hanging slightly away from the body, both arms fully visible, same scale and ground line for all views. Take the face, body proportions and drawing style from the first reference image; take the hoodie exactly from the second reference image, the sneakers exactly from the third, and the face and smile from the fourth; nothing else from the item cards. Identity: {IDENTITY_SKEA_V3}. Title "SKEA TURNAROUND". {NEG_S3}
```

**T-пози** `skea-tpose-<view>-v3`:
```
{STYLE} Single full-body figure only, {VIEW} view, standing in a clean T-pose with both arms straight out to the sides and palms down, two hands clearly visible, legs slightly apart, feet flat, whole body in frame head to toe, centered. Pure white background, no shadow, no ground plane, no props in hands, kunai removed from the hands. Flat even lighting, flat colors with inked lines. Take the face, body proportions and drawing style from the first reference image; the hoodie exactly from the second reference image, the sneakers exactly from the third, the face and smile from the fourth. Identity: {IDENTITY_SKEA_V3}. {NEG_S3}
```

## 15. Choko — одяг v5: гладка спина і кросівки (Santos 2026-10-03, [[2026-10-03-Choko-Outfit-v5]])

Причини, чому кільця лізли на спину, і ліки — у плані v5 § Діагноз. Що змінилось у тексті:
1. Спина описана **першою і прямо**: гладка тканина. Спочатку в тексті стояла «кремова смуга по хребту» з плану T1. Santos 2026-10-03 (X-2): **смуги по центру спини не повинно бути**, тож смугу прибрано з IDENTITY, § 15a і `{NEG_CHOKO}`. Поворот W-1 і T-пози X-0…X-3 запускались ще зі смугою.
2. Слова «chainmail» в IDENTITY немає; вставки — «ring mesh» лише на плечах і зовнішньому боці передпліч.
3. Заперечення — лише в окремому хвості `{NEG_CHOKO}`, не в IDENTITY.
4. Взуття вперше в IDENTITY: форма ретро-ранера на кшталт P-6000 (бренд у промпті **не називаємо**, лого немає), сірі з помаранчевими вставками.

**`{NEG_CHOKO}`** (додається після `{NEG}` у кожному промпті Choko з людиною):
```
No chain mail or metal rings on the back, chest or torso, no mail shirt, no armor vest, no stripes anywhere on the jacket, front or back, no brand logos on the shoes — the cursive C is the only mark.
```

**Картка кросівок** `choko-item-sneakers-v1` — шаблон § 4, рядок ITEM «Choko's low-top 2000s retro running sneakers…».
gpt_image_2_5 high 2k 16:9, **без референсу** (обличчя не потрібне, стиль задає `{STYLE}`; старий лист `f21298f4` тягне кольчугу).

Було (v4):
```
young man, lean narrow face, long straight nose, grey-green eyes, thick curly dark-brown hair covering temples and ears; light fitted cloth jacket in muted dusty orange with a thin cream stripe and a high collar, sleeves to the wrists, with panels of fine gunmetal chainmail rings only on the shoulders and forearms, cut for a fast acrobatic swordsman (no full chainmail coat, no shirt); slate blue-grey trousers; black leather gloves; large analog wristwatch on the left wrist; emerald-green pike-style sword with dark green wrapped grip and brass guard
```

### 15a. Поворот і T-пози Choko v5 (Santos 2026-10-03, план v5 кроки 3–4)

gpt_image_2_5 high 2k. Референси в цьому порядку: 1) куртка N-2 `a2bf79a1` (канон v4); 2) кросівки V-1 `482bfc6d` (канон v5);
3) лист `f21298f4` — **лише обличчя, волосся й манера**, бо він несе стару кольчугу. Спина в тексті описана прямо.

**Поворот** `choko-turn-v5` ×2, 16:9:
```
{STYLE} Character turnaround model sheet on a flat mint-sage background, four consistent full-body views in a row: front, three-quarter, side profile, back; neutral relaxed standing pose, arms slightly away from the body, same scale and ground line for all views. In the back view the whole back of the jacket is one smooth plain dusty-orange cloth panel with no stripe, no seam and no metal on the back. Take the jacket exactly from the first reference image and the shoes exactly from the second; take only the face, hair and drawing style from the third reference image, not its clothing. Identity: {IDENTITY_CHOKO_V5}. Title "CHOKO TURNAROUND". {NEG} {NEG_CHOKO}
```

**T-пози** `choko-tpose-<view>-v5` ×4, 3:4 — після вибору повороту; референси: 1) переможець повороту, 2) куртка N-2, 3) кросівки V-1.
**Для 3D — чистий персонаж без меча** (Santos 2026-10-03): `{IDENTITY_CHOKO_V5}` тут береться **без** кінцевого «; emerald-green pike-style sword…», а «cut for a fast acrobatic swordsman» → «cut for fast acrobatic movement». Меч — окремий 3D-пропс (картка Х2-16).
```
{STYLE} Single full-body figure only, {VIEW} view, standing in a clean T-pose with both arms straight out to the sides and palms down, legs slightly apart, feet flat, whole body in frame head to toe, centered. Pure white background, no shadow, no ground plane, no props in hands, sword removed. Flat even lighting, flat colors with inked lines. Take the character exactly from the first reference image; the jacket from the second and the shoes from the third. Clean character only: no sword, no scabbard, no sheath, no weapon on the back, hip or belt, empty hands. The whole back of the jacket is one smooth plain dusty-orange cloth panel with no stripe, no seam and no metal on the back. Identity: {IDENTITY_CHOKO_V5}. {NEG} {NEG_CHOKO}
```

**Переробка X-1 (бік) і X-2 (спина)** — вердикт Santos: X-1 «ніби хтось стиснув», X-2 «полоски по центру не повинно бути».
Референси: 1) T-поза X-0 `b529a3bd` (так; пропорції й обличчя), 2) куртка N-2, 3) кросівки V-1. Поворот W-1 **не беремо**: на ньому
спина, ймовірно, теж зі смугою (не перевірено — CDN закритий). До `{VIEW}`-рядка § 15a додається:
- бік: `true side profile, the body keeps exactly the same height, shoulder width and limb length as the first reference image, not squashed, not compressed, not shortened; the arms point straight toward and away from the viewer`;
- спина: `the back of the jacket is completely plain and uniform dusty orange, no stripe, no seam, no line down the middle`.

### 15b. Спина Choko v5 (друга переробка) і гліф «C» (Santos 2026-10-03)

**Бік не робимо** (Santos, варіант А): `multi_image_to_3d` бере 1–4 види, тож 3D іде з трьох — front X-0, back, ¾ X-3; так само для Skea.
**Спина** `choko-tpose-back-v5` ×2, 3:4. Опис спини N-2 дістати не можу (CDN закритий), тому N-2 **не беру референсом**: її промпт спину не
описував, а референсом мав старий лист із кольчугою. Референси: X-0 `b529a3bd`, X-3 `5b045b7a`, кросівки V-1 `482bfc6d`. Спина описана словами
повністю, IDENTITY — без меча (`cut for fast acrobatic movement`):
```
{STYLE} Single full-body figure only, seen exactly from behind (back view), standing in a clean T-pose with both arms straight out to the sides and palms down, legs slightly apart, feet flat, whole body in frame head to toe, centered. Pure white background, no shadow, no ground plane. Empty hands: he holds nothing, no sword, no scabbard, no weapon or object anywhere on the body. Flat even lighting, flat colors with inked lines. Take the face, hair, body proportions and the jacket front details from the first and second reference images (front and three-quarter views of the same character) and the shoes from the third. What the back looks like, described exactly: the back of the jacket is one single uninterrupted piece of plain dusty-orange cloth from the collar to the hem and from sleeve seam to sleeve seam; there is no stripe, no line, no seam, no zipper, no panel and no metal anywhere in the middle of the back; the only details on the back are the back of the high collar at the top, a few soft cloth folds, and the small gunmetal ring-mesh patches on the shoulder caps and on the outer forearms where they wrap around from the front; the sleeves are plain dusty orange; the slate blue-grey trousers and the heels of the sneakers are visible below. Identity: {ID}. {NEG} {NEG_CHOKO}
```

**Гліф** `choko-monogram-c-v1` ×2, 16:9, без референсу — [[2026-10-03-Choko-Outfit-v5]] § Монограма (гілка T1): рукописна «C» з петлею й хвостом
на зовнішній панелі кросівки, помаранчевий `#BD6133` ([[Style-Guide]]) на сірому. Загальний `{NEG}` тут не ставиться: він забороняє текст.
```
{STYLE} Monogram design card on a flat mint-sage background (#B8CBB1): a single hand-lettered cursive capital letter C drawn like a calligraphy signature, with an opening loop at the top and a long tail that curls back on itself and then stretches out horizontally to the right, as a mark for the outer side panel of a sneaker. Show it four times: 1) large in the center in dark plum-graphite line on white, 2) filled in muted dusty orange #BD6133 on a light grey mesh swatch, 3) small on a plain light grey low-top sneaker side panel silhouette with no other marks, 4) a thin single-line version. Same letter shape in all four, sketchy hand-drawn line. No other letters, no words, no numbers, no title, no brand logos, no swoosh or stripe shapes, no watermark.
```

**Монограма «C» — канон Z-2 `327a6ef9`** (Santos). Застереження Santos: **«кросівки не ті — пам'ятай і не пропусти»**. Кросівка на картці
Z-2 — лише силует-підкладка, не Choko. Береться **тільки літера**: декаль кладеться на кросівки V-1 `482bfc6d` (у 3D — на зовнішні
бокові панелі). Форму кросівки зі Z-2 не брати ні в 2D, ні в 3D.

### 15c. Кросівки v2 (P-6000) і T-пози front/¾ без смуг (Santos 2026-10-03, «б»)

Santos: V-1 «не ті» — форма має бути P-6000 з його фото (опис — [[2026-10-03-Choko-Outfit-v5]] крок 1.4). Порядок:
1. **Картка** `choko-item-sneakers-v2` ×2, 16:9, референс — лише гліф Z-2 `327a6ef9` (літера, не кросівка). `{SNEAKERS_V2}` — кросівки з IDENTITY v5.2:
```
{STYLE} Item design card on a flat mint-sage background: Choko's sneakers, a pair of {SNEAKERS_V2}, shown alone four times in a row — outer side view, inner side view, back view, top or three-quarter view — plus two small circled detail insets (the cursive C monogram on the outer side panel; the windowed mesh heel with the orange heel tab). Take only the cursive letter C from the reference image, exactly its shape, and place it on the outer side panel of each sneaker; do not copy the sneaker drawn in the reference image. Same scale in all views, thin inked outline, flat colors with magenta-tinted cel shadow, small hand-written numbers by each view. Title "CHOKO SNEAKERS". No hands, no characters. No anime style, no 3D render look, no gradients, no text except the sheet title and the single letter C, no brand logos, no swoosh, no watermark.
```
2. **T-пози front і ¾** (замість X-0, X-3) — після вибору картки; референси: спина Z-1 `50734236`, переможець картки, X-0 `b529a3bd`
   (лише обличчя й пропорції). Шаблон § 15a з IDENTITY v5.2 без меча.

## 16. Пристрій-принтер Choko — `choko-item-printer-v1` (канон H13, [[Lore]] § Портрет, пристрій і помічник)

gpt_image_2_5 high 2k 16:9, `count: 2`, референс — картка годинника Choko `cecf569d` (латунь і зелене світло: ШІ живе в годиннику,
скринька — його друк). `get_cost` 2026-10-03 → 2.75 за шт., ×2 = **5.5**. **Згенеровано** (Santos «даю добро на все», 2026-10-03): `e74e5c35` — **канон** (вибір T6: рулон видно в боковому вікні, стікер читається), `792c502a` — ні. **Остаточно** (Santos: «обирай, що тобі більше зайде», 2026-10-03).

```
Item design card for a fighting game, on a flat muted mint-sage background (#B8CBB1), hand-drawn in a loose expressive western animation sketch style, NOT anime: lively plum-graphite inked lines with small line breaks, flat colors with a single magenta-violet cel shadow tone, almost no highlights, no gradients, no gloss. The item: Choko's portable printing device — a small hand-held brass box, half instant camera and half typewriter, matching the aged brass, dark plum leather and glowing green accents of the reference wristwatch: one round glass lens on the front with a brass bezel, a folding crank handle on the right side, a leather carry strap, a paper roll visible through a small side window, a slot on top where a short printed paper strip curls out, tiny warm glowing lamp windows and green-glowing tick marks like the watch hands. Shown alone four times in a row with the same scale — front view, side view with the crank, back view, three-quarter view — plus two small circled detail insets: 1) a printed sticker coming out of the slot, with a torn ragged edge and a simple sketched face silhouette on it; 2) the lens and the crank. Small hand-written numbers by each view. Title "CHOKO PRINTER". No screens, no displays, no buttons with digits, no cyberpunk, no neon cables, no hands, no characters, no letters except the title, no logos, no watermark.
```

## 17. Дрон-помічник Choko — `choko-drone-helper-v1` (канон H14-A, ім'я не обране: Tick / Spool)

gpt_image_2_5 high 2k 16:9, `count: 2`, референси — годинник Choko `cecf569d` (латунь, зелене світло) і важкий дрон `e9fd9e33`
(та сама родина машин Cronshift, але помічник — маленький і легкий). `get_cost` 2026-10-03 → 2.75 за шт., ×2 = **5.5**.
**Згенеровано** (2026-10-03): `d829cadc` — **канон** (вибір T6: кругле зелене око, дружній), `df9e8675` — ні (вертикальна зіниця, хижий погляд). **Остаточно** (Santos, те саме слово). Око — зелене (Santos «добро на все» на пропозицію T6).
**Розвилка Santos:** око-лінза світиться зеленим, як стрілки годинника (пропозиція T6: це той самий ШІ), а пилюжно-помаранчевий
(як куртка Choko) — акцент на корпусі; інакше — помаранчеве око.

```
Character prop design sheet for a fighting game, on a flat muted mint-sage background (#B8CBB1), hand-drawn in a loose expressive western animation sketch style, NOT anime: lively plum-graphite inked lines with small line breaks, flat colors with a single magenta-violet cel shadow tone, no gradients, no gloss. A tiny friendly flying helper drone of the old European-industrial city of Cronshift, about the size of a teapot: a round riveted brass body with muted dusty-orange painted panels, ONE big round eye-lens in the front with a brass shutter ring and a soft green glow like the hands of the reference wristwatch, two small caged rotors on short arms, a little paper roll mounted under its belly feeding a printing slot, a short antenna with a tiny warm lamp. Much smaller, lighter and cuter than the heavy cargo drone in the second reference, same brass-and-rivets family. The same drone shown in five panels with even spacing and the same scale: 1) front view hovering; 2) side view; 3) three-quarter view tilting curiously, eye shutter half closed; 4) printing — a short sticker with a torn ragged edge coming out from under its belly; 5) back view. Small hand-written numbers by each panel. Expressive but no face other than the single lens, no mouth, no screens, no displays, no letters or words, no logos, no watermark, no people.
```

## 18. Ключ стилю для 3D-пропів — `style-key-props-{tavern,quay}-v1` ([[2026-10-03-Santos-Packs-Arenas]], хвиля T6-1)

**Навіщо.** Пропи з паків уже мають геометрію, а наш стиль на них дає перефарбований атлас ([[Palette-Remap]]). Ключ стилю —
кадр із паку, перемальований у Sketch-Cel. З нього ми дізнаємося, як наш стиль «бачить» камінь, дерево, латунь і воду пропів.
Після ключа hex у [[Palette-Remap]] звіряється з ним: якщо матеріал на ключі виходить інакшим, рядок таблиці міняється разом із
причиною. Один ключ — один погляд, тому їх **два**, з різним набором матеріалів.

| id | вхід 1 (що малювати) | що перевіряє |
|---|---|---|
| `style-key-props-tavern-v1` | KayKit `Samples/Dungeon_sample12.png`, шинок: стійка, бочки, полиці, пляшки, табурети, дощата підлога | дерево (`r0c4`, `r0c2`, `r0c6`), полотно, латунь, пляшки, сланцева кладка |
| `style-key-props-quay-v1` | KayKit `Samples/Dungeon_sample5.png`, причал: кам'яна стіна, сходи до води, грати, бочки у воді | камінь (`r0c0`, `r0c1`, `r0c5`), вода, мох, ковані грати |

Вхід 2 в обох — канон річки `a2913501-694d-4bbc-9908-66892760bf7e` (стиль і палітра). Модель — `gpt_image_2_5`, `quality: high`,
`resolution: 2k`, 16:9 для шинку, 4:3 для причалу. `get_cost` 2026-10-03 з двома референсами → **2.75** за шт., разом **5.5**.

**Вхід 1 без логотипів.** Рендери KayKit мають плашку «DUNGEON ASSET PACK» і лого KayKit, а модель домальовує текст, який
бачить. Обрізаємо локально (CC0, 0 кр.):

```
python3 -c "
from PIL import Image, ImageDraw
S = '<KayKit>/Samples/'
a = Image.open(S + 'Dungeon_sample12.png').convert('RGB'); ImageDraw.Draw(a).rectangle([60, 830, 640, 1080], fill=a.getpixel((60, 1060)))
a.crop((280, 150, 1600, 860)).save('style_key_in_tavern.png')
b = Image.open(S + 'Dungeon_sample5.png').convert('RGB'); ImageDraw.Draw(b).rectangle([380, 830, 640, 1080], fill=b.getpixel((420, 1040)))
b.crop((400, 60, 1530, 1035)).save('style_key_in_quay.png')"
```

`sha256`: шинок 1320×710 → `5751774e…20e`, причал 1130×975 → `24dd0290…8e`. Інший хеш означає інший вхід, тоді спершу дивимось
очима. Обидва файли далі йдуть у `media_upload`, а `medias` бере **повний** UUID.

```
Redraw the first reference image as a hand-drawn illustration in exactly the drawing style, line work and palette of the second reference image: a loose expressive western animation sketch style, not anime, lively plum-graphite inked lines with small line breaks, thicker outer contours and thinner inner lines, flat base colors with a single magenta-violet cel shadow tone, no gradients, no gloss, no 3D render look. Keep every object, its shape, its place and the camera angle exactly as in the first image; change only how it is drawn and colored. Recolor everything into the muted palette of the old European-industrial city of Cronshift: cool slate-grey stone, red-brown and pale ochre wood, muted terracotta, dull brass, {MATERIAL_NOTE} cream cloth; nothing saturated except small warm lamp accents. Replace the dark background with a flat muted mint-sage background (#B8CBB1). No people, no characters, no text, no letters, no numbers, no logos, no watermark.
```

`MATERIAL_NOTE`: шинок — `olive-green old glass bottles,` · причал — `flat graphic deep teal water with simple pale foam lines, olive moss,`.

**Відбір (Santos):** «стиль так» → хвиля T6-2; «ні» → правимо промпт, проба повторюється. Після «так» зчитуємо кольори з ключа
медіаною по плямах кожного матеріалу і звіряємо з [[Palette-Remap]]. Розбіжність понад 10 одиниць світлоти HSL — рядок таблиці
міняється.

## Related
- [[Style-Guide]] · [[Asset-Manifest]] · [[Higgsfield-Pipeline]] · [[Prompts]] · [[Choko]] · [[Skea]] · [[Stage-River]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[2026-10-03-Skea-Redesign]] · [[Lore]] · [[Palette-Remap]] · [[2026-10-03-Santos-Packs-Arenas]]
