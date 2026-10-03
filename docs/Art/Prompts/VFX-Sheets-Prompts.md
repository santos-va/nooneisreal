# VFX-аркуші — промпти смуги D (спринт)

**Роль:** T6 Аполлон (T6·B), 2026-10-03 · **План:** [[2026-10-03-Sprint-Arenas-VFX]], смуга D · **Напрям:** [[VFX-Direction]] ·
**Стиль:** [[Style-Guide]], [[ADR-007-Art-Style-Sketch-Cel]] · **Бюджет смуги:** ≈ 400 кр. (поділ T1 у стелі 1000).
**Статус:** смуга D згенерована повністю — D1 (Santos «Генеруй давай!!», 21.25 кр.) і D2 (Santos «yes» на «стиль так», 55 кр.); 13 файлів у `game/assets/vfx/`. Потім D3 (Santos «go, … готуй матеріал», 66 кр.): +11 файлів. Разом **142.25** з ≈ 400.

## Навіщо і для кого

Флипбуки беруть **T2·B** (смуга B: `game/scripts/fx/`, шейдери). Зараз дим, шматки й іскри — процедурні примітиви
(`SmokeCloud.gd`, `SmearShards.gd`, `HitSpark.gd` — квадратний плейсхолдер, [[VFX-Direction]] § Далі). Аркуші дають
мальований шар із § Принцип: окремі кадри «на четвірках» (≈ 12 fps), без motion blur.

Кристальна ульта Choko сюди **не входить**: пірамідки й меч №1 — процедурні, 0 кр. ([[VFX-Direction]] § Кристальна ульта).

## Формат аркуша — однаковий для всіх, щоб T2·B писав один завантажувач

| параметр | значення |
|---|---|
| модель | `gpt_image_2_5`, `quality: high`, `resolution: 2k`, `aspect_ratio: 1:1`, `background: transparent` |
| сітка | **4 × 4 = 16 кадрів**, клітинка ≈ 512 px; кадр 1 — угорі ліворуч, читання зліва направо, згори вниз |
| у Godot | `StandardMaterial3D` / `ParticleProcessMaterial`: `particles_anim_h_frames = 4`, `v_frames = 4`; або `Sprite3D` `hframes/vframes = 4` |
| темп | 12 fps (кадр гри × 5 при 60 Гц) — 16 кадрів ≈ 1.33 с; короткі ефекти грають рядок (4 кадри) |
| змішування | дим і пил — `BLEND_MODE_MIX` з альфою; іскри, електро, сліди — можна `BLEND_MODE_ADD` |
| шлях | `game/assets/vfx/<id без vfx->.png`, рядок у [[Textures-Registry]] тим самим заходом |

Модель малює сітку «на око»: у D1 великі кадри диму заходили за межу 512 px (`smoke_a` — 476 px на лініях сітки).
Тому кожен аркуш проходить **`python3 tools/art/repack_flipbook.py in.png out.png`**: знаходить справжні проміжки між кадрами,
ріже по них і кладе кадри в рівні клітинки 512 px з одним масштабом на весь аркуш (центр — номінальний центр клітинки, щоб
не тремтіло). `--check` лише звітує. Немає 4 × 4 проміжків → `FAIL`, аркуш перегенеровується.
У D2 більшість аркушів уже лягла рівно на номінальну сітку (0 px на лініях 512) — тоді інструмент бере номінальні клітинки як є
(режим `nominal grid`); пошук проміжків на рідких іскрах ловив не ті щілини й давав масштаб 0.4. Порожній останній кадр
(ефект зник) — не помилка, а `note`.

## Блоки (англійською, байт-у-байт у кожному промпті)

**VFX_STYLE** (з [[Prompt-Library]] STYLE — лінія, тінь і «не аніме»; анатомію прибрано, бо фігур немає):

```
Hand-drawn 2D effect animation for a fighting game, in a loose expressive western animation sketch style, NOT anime: lively slightly sketchy line art in dark plum-graphite brown (#2B2230, not pure black), thicker outer contour and thinner inner lines with small line breaks, flat base colors with a single cel shadow tone that is hue-shifted toward magenta-violet, almost no highlights, no gradients, no airbrush glow, no gloss.
```

**SHEET:**

```
Sprite sheet of exactly 16 animation frames arranged in a 4 by 4 grid on a fully transparent background; read left to right, top to bottom, frame 1 in the top-left corner. Each frame sits centered in its own equal square cell with an empty margin, nothing crosses the cell borders, the same scale and the same center point in every frame. Limited animation on fours: each frame is a clearly different drawing, shapes change in steps, not by motion blur. No grid lines, no numbers, no text.
```

**NEG_VFX:**

```
No characters, no hands, no faces, no weapons, no background scenery, no ground, no text, no numbers, no logos, no watermark, no frame borders, no photorealistic smoke, no 3D render look, no lens flare.
```

Палітри — з `game/data/characters/*.tres` (`grep -n vfx_ game/data/characters/*.tres`): Choko `vfx_primary`
(0.2, 0.9, 0.55) → `#33E68C`, `vfx_secondary` (0.6, 0.78, 1.0) → `#99C7FF` (колір часу); Skea `vfx_primary` (0.62, 0.3, 0.95)
→ `#9E4CF2`, `vfx_secondary` (0.24, 0.48, 0.42) → `#3D7A6B`. Тінь — за [[Style-Guide]], у маджента-ліловий.

## Аркуші

Промпт = `{VFX_STYLE} {SHEET} ` + рядок «опис» + ` {NEG_VFX}`.

| # | id | для чого (вузол) | опис (слот, англійською) |
|---|---|---|---|
| 1 | `vfx-smoke-puff` | приземлення, деш, загальний клуб; `SmokeCloud` | `A single puff of soft dusty lilac-grey smoke (#8E8399 base, #5E4E6E magenta-violet shadow) drawn as chunky round cloud clumps with inked outlines: frames 1-3 a small tight puff appears, frames 4-8 it blooms outward into big rounded clumps, frames 9-13 the clumps drift apart and curl, frames 14-16 only a few small curls and dots remain. It disappears by breaking into smaller pieces, not by fading. Match the drawing style and line of the reference image (a steam puff).` |
| 2 | `vfx-smoke-veil` | SHADOW VEIL Skea, ульта з диму | `A dense rising column of dark indigo-violet smoke (#3A2C52 base, #241A36 shadow) with a few small sharp violet sparks (#9E4CF2) inside it: frames 1-4 smoke bursts up from a low swirl, frames 5-12 a tall churning column with rolling clumps, frames 13-16 the column tears into ragged strips and drifting wisps. Inked outline on every clump.` |
| 3 | `vfx-dust-land` | приземлення після стрибка, падіння регдолу | `A low wide landing dust burst seen from the side, warm grey-terracotta dust (#A88B7A base, #7A5C66 shadow): frames 1-3 a flat squashed splash at the bottom center, frames 4-10 two crescent dust waves roll outward to the left and right and rise slightly, frames 11-16 they break into small dust clumps and dots that settle. Wide and flat, the bottom edge of every frame is a straight invisible floor line.` |
| 4 | `vfx-trail-chrono` | Chrono Step Choko (деш) | `A horizontal motion trail of a fast dash moving to the right: a long tapering emerald-green streak (#33E68C, shadow #1E7A5A) with small pale time-blue clock tick marks (#99C7FF) along it, like the minute marks of a watch dial: frames 1-4 the streak stretches out from left to right, frames 5-8 it snaps tight, frames 9-16 it breaks from the left end into separate tick-mark fragments and small green chips that fall back and vanish.` |
| 5 | `vfx-trail-flash` | Flash Step Skea, `SmearShards` | `A horizontal teleport smear moving to the right: ragged torn pieces like ripped paper in violet (#9E4CF2, shadow #5B2A8C) and plum-graphite ink black, with jagged edges and a few thin speed strokes: frames 1-4 a ghostly stretched smear tears open, frames 5-10 it rips into a dozen spinning shards that fly back to the left, frames 11-16 the shards shrink and drop away one by one.` |
| 6 | `vfx-speed-lines` | швидкий рух, прольот гарпуна | `A cluster of horizontal ink speed lines and thin cream-white (#EFEED4) streaks of different lengths, as in comic-book motion, all pointing left to right: frames 1-4 they shoot out, frames 5-12 they flicker and shift position in steps, frames 13-16 they thin out and break into dashes.` |
| 7 | `vfx-spark-hit` | усі влучання, заміна квадрата `HitSpark` | `Four rows, each row a 4-frame hit impact star burst with sharp irregular spikes and a white hot core: row 1 warm cream (#EFEED4) for a normal hit, row 2 violet (#9E4CF2) for Skea's critical hit, row 3 emerald (#33E68C) for Choko, row 4 pale blue (#99C7FF) for a blocked hit. In each row: frame 1 a small bright flash, frame 2 the full star at maximum size, frame 3 the spikes break off and fly outward, frame 4 a few small embers and ink strokes.` |
| 8 | `vfx-spark-metal` | блок, удар меча об меч, гарпун об метал | `A burst of metal sparks from a sword clash: thin bright cream-yellow (#F2D98C) spark streaks with tiny inked outlines flying radially from one point, a few glowing dots: frames 1-3 a sharp star of streaks, frames 4-10 streaks fly outward and bend down with gravity, frames 11-16 they shorten into falling dots and vanish.` |
| 9 | `vfx-electro-arc` | електро (С4 Santos), запасний шлях до Kling | `A crackling electric arc between two points at the left and right of the cell: a jagged branching lightning bolt with a pale cream-white core (#F4F1E6) and a cold pale blue edge (#99C7FF), thick inked outline, flat colors: every frame the bolt jumps to a different jagged path with new side branches, frames 13-16 it breaks into short sparking segments.` |
| 10 | `vfx-choko-timestop` | TIME STOP Choko, декаль на землі (вид згори) | `A flat ring decal seen straight from above, like a watch dial lying on the ground: an emerald (#33E68C) ring with pale time-blue (#99C7FF) minute tick marks around it and thin ink cracks: frames 1-4 the ring expands from a small dot to full size, frames 5-8 the tick marks appear one by one clockwise, frames 9-12 thin cracks spread across the ring as time freezes, frames 13-16 the ring shatters into flat tick-shaped pieces. Perfect circle, centered, top-down orthographic view.` |
| 11 | `vfx-choko-rewind` | перемотка RECORD (Fighter.rewind) | `A counter-clockwise spiral of emerald (#33E68C) and pale time-blue (#99C7FF) clock tick marks and short ink arcs winding inward to the center, like time being wound back: frames 1-4 the spiral appears at full size, frames 5-12 it winds inward counter-clockwise and tightens, frames 13-16 it collapses into a single bright dot that pops.` |

**12. `vfx-choko-record-sticker`** — гліф RECORD як надрукований стікер ([[03-Skills-Framework]]: «гліф RECORD — надрукований
стікер, механіка без змін, лише арт»). Не аркуш, одне зображення, 1:1, transparent:

```
{VFX_STYLE} A single die-cut vinyl sticker, as if just printed by a small portable printer, lying flat and seen straight from above: a round watch-face design with emerald-green (#33E68C) clock hands, pale time-blue (#99C7FF) minute tick marks, a small solid red recording dot at the top, a thick white sticker border and one corner slightly peeled up showing the paper backing. Centered, fully transparent background around the sticker. {NEG_VFX}
```

Слово «REC» на стікері навмисно не просимо: модель малює текст, а напис на землі в 3D читається погано й вимагає
перевірки літер. Червона крапка запису каже те саме без тексту.

## Тест Kling — один кліп (С4 Santos: «електро, мечі — у Kling через Higgsfield»)

**Питання:** чи виходить із кліпу Kling флипбук із прозорим тлом.

**Що відомо до кредитів** (`models_explore` 2026-10-03): у `kling3_0`, `kling2_6`, `kling3_0_turbo` **немає параметра
прозорого тла чи альфи**; у `recommend` для «VFX on pure black, alpha» його немає в жодної відеомоделі. Отже, альфа з
коробки — ні. Перевіряємо інше: чи тримає Kling **чисто чорне тло** і манеру Sketch-Cel. Якщо так, чорне ключиться:
для світних ефектів (електро, іскри) достатньо `BLEND_MODE_ADD` (чорне = 0 = прозоре), для решти — luma-key в альфу.

**Кроки:**
1. Стартовий кадр — `gpt_image_2_5` high 2k, 1:1, **`background: opaque`**:
   ```
   {VFX_STYLE} A single crackling electric arc between two points at the left and right, jagged branching lightning bolt with a pale cream-white core (#F4F1E6) and a cold pale blue edge (#99C7FF), thick inked outline, flat colors, on a pure solid black background (#000000) with no glow on the background, no texture, no vignette. {NEG_VFX}
   ```
2. Кліп — `kling3_0`, `mode: std`, `duration: 5`, `sound: off`, `aspect_ratio: 1:1`, `medias: [{role: start_image}]`:
   ```
   The hand-drawn electric arc crackles and flickers in limited, stepped animation: the bolt jumps between new jagged paths and side branches snap on and off, flat colors and inked outline stay the same. Static locked camera, no zoom, no camera movement. The background stays pure solid black the whole time, no light spill, no new objects, no smoke.
   ```
3. Перевірка (Mac, 0 кр.): `ffmpeg -i clip.mp4 -vf fps=12 f_%02d.png` → 60 кадрів; чорнота тла — `ffmpeg -i clip.mp4 -vf "crop=64:64:0:0,signalstats" -f null -`
   (YMAX кута ≤ 20 з 255 — тло чисте); 16 найкращих кадрів → `ffmpeg … -vf "colorkey=black:0.08:0.1,tile=4x4"` → аркуш PNG з альфою.
4. Висновок — у [[VFX-Direction]] § Тест Kling: виходить / ні / чому. Не виходить — електро лишається аркушем № 9.

Чому std, а не pro: питання про тло й манеру, а не про деталь. `pro` — 8.75 замість 7.5, різниця мала, але сенсу в
тесті немає.

## Кошторис (`get_cost`, 2026-10-03, кредитів не списує)

| виклик | `get_cost` → |
|---|---|
| `gpt_image_2_5` high 2k 1:1 transparent | **2.75** |
| те саме з `count: 2` | 2.75 у `get_cost`; batch D1 списав по 2.75 за **кожне** зображення (баланс −21.25 на 5 зображень + кліп) |
| `kling3_0` std 5 с sound off 1:1 | **7.5** |
| `kling3_0` std 3 с sound off | 4.5 · `kling3_0` pro 5 с — 8.75 · `kling3_0_turbo` 720p 3 с — 4.5 |
| `balance` перед кошторисом | **5544.25** (ultra) |

| пакет | розрахунок | кредитів |
|---|---|---|
| **D1 — стиль-проба:** `vfx-smoke-puff` і `vfx-spark-hit`, по 2 варіанти | 4 × 2.75 | 11 |
| **D1 — тест Kling:** стартовий кадр + кліп 5 с | 2.75 + 7.5 | 10.25 |
| **D2 — решта аркушів** (№ 2–6, 8–12) після «стиль так» Santos на D1, по 2 варіанти | 20 × 2.75 | 55 |
| **разом смуга D** | | **76.25** |

Від бюджету ≈ 400 лишається ≈ 324. Пропозиція T6: не витрачати «на пробу». Якщо тест Kling вийде — другий кліп (змах
меча, 7.5); перегенерації аркушів, що не ріжуться на 16; решту віддати смузі C або в запас спринту — рядком для Santos у PR.

## D3 — те, чого в грі ще немає (Santos 2026-10-03: «не стій без роботи, готуй матеріал»)

Звідки список: ефекти, що є в коді без арту або в [[Asset-Manifest]] § C без ассета. Формат, блоки й перепаковка — ті самі.
Кольори стікерів — `Printer.gd:20` `COLORS` (`patch` (0.35, 0.85, 0.45) → `#59D973`, `seen` (0.65, 0.4, 1.0) → `#A666FF`,
`spring` (1.0, 0.82, 0.25) → `#FFD140`); стікери малюються з референсом стікера RECORD `35bf0bfb`, щоб усі чотири були однієї серії.

| # | id | звідки потреба | опис (слот, англійською) |
|---|---|---|---|
| 13 | `vfx-sticker-patch` | `Printer.gd:8` «placeholder disc until T6 art»; Латка +30 HP | одне зображення: `A single die-cut vinyl sticker from the same series as the reference sticker, lying flat and seen straight from above: a round badge with a chunky crossed adhesive bandage in fresh green (#59D973) and a small plus sign, thick white sticker border, one corner slightly peeled up showing the paper backing.` |
| 14 | `vfx-sticker-seen` | той самий; «Побачено» — мітка суперника на 4 с | одне зображення: `… a round badge with a wide-open stylized watchful eye in bright violet (#A666FF) with a small dark pupil and a few radiating lines, thick white sticker border, one corner slightly peeled up …` |
| 15 | `vfx-sticker-spring` | той самий; Пружина — зайвий стрибок | одне зображення: `… a round badge with a bouncy coiled metal spring in warm yellow (#FFD140) with two small motion arcs above it, thick white sticker border, one corner slightly peeled up …` |
| 16 | `vfx-slash-choko` | [[Asset-Manifest]] `vfx-slash-arcs`; меч Choko | `A crescent sword slash arc sweeping from upper left to lower right, a thick emerald-green (#33E68C) blade trail with a pale cream (#EFEED4) leading edge and a dark green (#1E7A5A) shadow side: frames 1-3 a thin sharp sliver appears, frames 4-7 it widens into a full crescent, frames 8-12 the crescent thins and splits into ribbon strips, frames 13-16 small chips fade out by breaking apart.` |
| 17 | `vfx-slash-skea` | той самий; кунаї Skea | `Two quick crossing kunai slash marks forming an X, thin sharp violet (#9E4CF2) slash trails with plum-graphite ink edges and tiny ink droplets: frames 1-4 the first slash cuts across, frames 5-8 the second slash crosses it, frames 9-16 both slashes split into thin shards and ink specks that drop away.` |
| 18 | `vfx-water-splash` | [[Asset-Manifest]] `vfx-splash`; арена `river` | `A splash of river water seen from the side as a foot lands in shallow water: deep teal water (#1F4D5A base, #2E3A5C magenta-indigo shadow) with flat cream foam (#EFEED4) edges: frames 1-3 a flat ring splash at the bottom, frames 4-9 a crown of water rises with droplets flying out, frames 10-16 droplets fall back and the ring flattens into small foam rings. The bottom edge of every frame is a straight invisible water line. Match the drawing style of the reference water texture.` (референс — `b0a9189d`, `tex_water_foam`) |
| 19 | `vfx-grimoire-page` | `GrimoireFx.gd:4` — 12 спектральних сторінок навколо Skea | `One torn spectral grimoire page fluttering and turning in the air, old parchment (#D9C9A8, shadow #A88B9C) with faint violet (#9E4CF2) glowing edges and small dark ink silhouettes of sealed figures printed on it, no readable text: the 16 frames show one full turn of the page, flipping and curling in steps, then the page edge starts to burn away into violet sparks in the last 4 frames.` |
| 20 | `vfx-sigil-imprint` | ульта Skea: 8 відбитків під бас ([[03-Skills-Framework]] § Ульта Skea під бас) | `A glowing violet (#9E4CF2) infinity-eight sigil stamped flat on the ground, seen straight from above: a plain figure-eight infinity shape with a thin outer ring and small tick marks, no face, no eyes, no mouth: frames 1-3 it slams in as a bright flash, frames 4-8 it burns steady with crisp inked edges, frames 9-16 it cracks and crumbles into flat violet embers. Top-down orthographic, centered.` |
| 21 | `vfx-weak-mark` | `WeakMarks.gd` — фіолетові кільця на зонах жертви (зараз процедурні) | `A small targeting mark for a weak point: a violet (#9E4CF2) reticle of two broken concentric rings with four short inward ticks and a tiny diamond in the center, inked outline: a looping pulse — frames 1-8 the rings contract and brighten in steps, frames 9-16 they expand and dim back to the start pose so the loop is seamless.` |
| 22 | `vfx-armor-break` | Armor Break від KUNAI RAIN | `An armor break burst: a flat plate of pale lilac glassy armor (#C9B8E0, shadow #8A6FA8) cracks with dark ink lines and shatters outward into angular shards with a violet (#9E4CF2) flash behind: frames 1-3 cracks spread across the plate, frames 4-6 a violet flash, frames 7-12 shards fly outward and spin, frames 13-16 small shards fall and vanish.` |
| 23 | `vfx-ground-crack` | важке приземлення, вибух кристальної ульти в упор | `A ground impact crack decal seen straight from above: dark plum-graphite (#2B2230) jagged crack lines radiating from a central crater on a transparent background, with small flat stone chips (#7A6A73, shadow #4E3E52): frames 1-4 the cracks shoot out from the center, frames 5-8 chips pop up and land, frames 9-16 the cracks stay and slowly fade by losing branches, not by transparency.` |

**№ 14, перегенерація (варіанти c/d).** Перший промпт дав фіолетовий диск зі зрачком і рисками — ока не видно, на землі
плутається з годинником RECORD. Робочий промпт: `… a round badge with a light cream face, and in the middle one big clearly
readable almond-shaped open eye drawn as a simple icon: an upper and a lower eyelid line meeting in sharp corners, three short
lashes on top, a bright violet (#A666FF) round iris and a small dark pupil, like a 'watching you' warning icon …` + у NEG
`no clock, no tick marks`. Урок: «stylized eye» без опису повік модель малює як диск; іконку треба описувати лініями.

Ціна — та сама модель і параметри, що D1/D2 (`gpt_image_2_5` high 2k 1:1 transparent → 2.75): 11 видів × 2 варіанти = **22 × 2.75 = 60.5**.

## Журнал запусків

| пакет | job-id | результат | `balance` до → після |
|---|---|---|---|
| D1 стиль-проба + кадр Kling (`generate_image_batch`, 5 × 2.75) | дим `3b728cd6` (a), `40c23ea4` (b) · іскри `427c7774` (a), `6473ae78` (b) · кадр електро `10f078bc` | у гру — дим **b** (чистіша лінія, 35 px на лініях сітки проти 476 у a; після перепаковки запас 8 px) і іскри **b** (0 px на лініях, масштаб 1.000); a — відкинуто, лишаються в історії Higgsfield. Альфа справжня: прозорих 55–84 % пікселів | 5478.25 → |
| D1 тест Kling (`kling3_0` std 5 с, без звуку) | `52a1ea68` | 960×960, 24 fps, 121 кадр; висновок — [[VFX-Direction]] § Тест Kling | → **5457** (−21.25, як у кошторисі) |
| D2 партія 1 (`generate_image_batch`, 12 × 2.75): дим вуалі, пил, Chrono, Flash, лінії, метал — по a/b | `e8e28039`/`c444986c` · `d60b12b8`/`66c1ff6b` · `724adb23`/`98020776` · `6d67fb8b`/`243f7e00` · `8515fb44`/`37c79b0f` · `204a5842`/`d0da8518` | у гру — усі **b** (переможці й масштаб перепаковки — [[Textures-Registry]] рядки `vfx-*`) | 5457 → |
| D2 партія 2 (8 × 2.75): електро, TIME STOP, перемотка, стікер — по a/b | `72f920ef`/`8fbc7de8` · `8d1a6cf5`/`40e1d193` · `51e0ca4a`/`6f2526bd` · `3fa2e2fc`/`35bf0bfb` | у гру — електро **a**, TIME STOP **b**, перемотка **a** (менше стиснення: 0.883 проти 0.790), стікер **b** (світлий циферблат читається на бруківці, темний a зливається) | → **5402** (−55, як у кошторисі) |
| D3 (`generate_image_batch` 10 + 12): стікери, дуги, сплеск, сторінка, ∞8, мітка, Armor Break, тріщина — по a/b | 22 job-id — [[Textures-Registry]] рядки `vfx-*` (обраний і відкинутий); 2 перші заявки сплеску відхилені до запуску (короткий id референсу `b0a9189d` замість UUID), 0 кр. | у гру — 10; «Побачено» — ока не видно в a/b | 5402 → |
| D3, перегенерація № 14 (2 × 2.75) | `3376a9c1` (c), `1d9e50b8` (d) | у гру — c | → **5336** (−66 = 60.5 + 5.5) |

## Related
- [[2026-10-03-Sprint-Arenas-VFX]] · [[VFX-Direction]] · [[Style-Guide]] · [[Prompt-Library]] · [[Textures-Registry]] ·
  [[03-Skills-Framework]] · [[Arenas-360-Prompts]] · [[Choko]] · [[Skea]] · [[ADR-007-Art-Style-Sketch-Cel]]
