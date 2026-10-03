# Арени 360° — промпти смуги C (спринт)

**Роль:** T6 Аполлон, 2026-10-03 · **План:** спринт «тверда арена, три карти день/ніч, VFX, меню» (T1, смуга C, PR santos-va/nooneisreal#107)
· **Канон арен:** [[Cronshift]] § Нові арени · **Стиль:** [[Style-Guide]], [[ADR-007-Art-Style-Sketch-Cel]].
**Статус:** промпти й ціни готові; стиль-проба згенерована (11 кр., § Журнал генерацій), чекає «стиль так». Генерація — лише після слова Santos на стелю (§ Кошторис).

## Форма — 4 картки на арену (поки немає R11)

Фон більше не повертається з камерою, тож навколо кола 20 м потрібне оточення на всі 360°. Поки Архімед не дав R11
(кільце карток чи панорама), готую **кільце з 4 карток: N / E / S / W**, кожна на 90°. Якщо R11 скаже «панорама», ті самі
описи напрямків стануть 4 ділянками однієї панорами.

Правила для кожної картки — щоб кільце зшивалося й читалося під бійцями:
- **Нижній край — лінія вулиці за ареною.** Підлоги на передньому плані немає: її дає текстура в рушії (§ Текстури).
- **Лівий і правий край — небо та дахи без обрізаних предметів.** Так шов між сусідніми картками видно найменше. Кожна
  наступна картка генерується з попередньою як референсом (той самий масштаб і висота даху).
- **День → ніч редагуванням того ж кадру**, а не новою генерацією: геометрія збігається, і рушій може міняти картку без
  стрибка. Неон CRONSHIFT — лише вночі й окремим шаром.
- Референс стилю для всіх карток — канон річки `a2913501` (Sketch-Cel, 2688×1152, уже згенерований, у гру не потрапив).

Модель — `gpt_image_2_5`, `quality: high`, `resolution: 2k`, `aspect_ratio: 21:9`, референс `image_references`.

## Блоки

**ARENA_STYLE** (з § 6 [[Prompt-Library]], байт-у-байт перша фраза):

```
Wide game background, 21:9, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines, flat colors with magenta-violet cel shadows.
```

**RING** (вимоги кільця):

```
This is one of four cards that surround a round fighting arena; the bottom edge of the image is the street level just beyond the arena, with no foreground floor. The left and right edges show only sky and rooftops, nothing cut in half by the frame. Match the drawing style, line weight, palette and the scale of buildings of the reference image exactly.
```

**DAY:** `Late afternoon light in the old European-industrial city of Cronshift: warm low sun, muted palette of terracotta, slate blue and deep teal, soft dusty-orange sky.`

**NIGHT_EDIT** (референс — денна картка того ж напрямку):

```
Same composition, same buildings, same line art and camera as the reference image, now at night: deep teal and slate night sky, warm gas lamps and lit windows casting flat pools of light, shadows still a single magenta-violet cel tone, no new objects, nothing moved.
```

**NEG_ARENA:** `No people in the foreground, only a few tiny distant silhouettes, no text, no letters, no logos, no watermark, no anime style, no 3D render look, no gradients, no neon signs.`

## Річка — `river` (стиль-проба: N день + N ніч)

Бій на воді перед набережною з двома вежами-куполами ([[Cronshift]]).

| id | напрямок | SCENE |
|---|---|---|
| `stage-river-n-day` | N | `Across the calm river: the embankment with brick and terracotta facades, brass rooftops and the twin domed clock towers of the city rising above them, hanging lanterns along the quay.` |
| `stage-river-e-day` | E | `Downstream: the river bends away between old warehouses on stone piers, an arched stone bridge in the middle distance, mooring posts and a crane.` |
| `stage-river-s-day` | S | `The near bank behind the arena: wide stone steps going down to the water, moored flat barges, tall iron lamp posts on the quay, balconies with laundry lines above.` |
| `stage-river-w-day` | W | `Upstream: a riveted iron tram bridge on brick pillars crossing the river, factory chimneys with thin steam behind it.` |

Промпт: `{ARENA_STYLE} {SCENE} {DAY} {RING} {NEG_ARENA}`; нічні `stage-river-*-night` = `{NIGHT_EDIT} {NEG_ARENA}` з денною карткою як референсом.

## Базарчик — `bazaar`

Вузька ринкова вулиця з ятками, тентами, ящиками, ліхтарями.

| id | напрямок | SCENE |
|---|---|---|
| `stage-bazaar-n-day` | N | `The bazaar street continues ahead: rows of market stalls under faded striped awnings, string lights across the street, the twin domed clock towers far away above the rooftops.` |
| `stage-bazaar-e-day` | E | `A narrow side alley opening off the street: awnings, hanging baskets, washing lines between balconies, a staircase going up.` |
| `stage-bazaar-s-day` | S | `The arched brick entrance of a covered market hall with an iron-and-glass roof, stacked crates and sacks by the door, a wrought-iron street lamp.` |
| `stage-bazaar-w-day` | W | `Stacked wooden crates and barrels, a parked hand cart, a spice stall with hanging lanterns, brick facades with balconies and steam from a vent.` |

## Центральна площа — `fountain`

Площа з фонтаном; висока вежа з неоновим написом CRONSHIFT, **видно лише вночі**.

| id | напрямок | SCENE |
|---|---|---|
| `stage-fountain-n-day` | N | `Beyond the square, far away, a very tall thin tower rises above the city; near its top there is a frame of big unlit letters that cannot be read in daylight.` |
| `stage-fountain-e-day` | E | `A tram stop at the edge of the square: overhead tram wires on iron poles, a shelter with a curved roof, rails curving away.` |
| `stage-fountain-s-day` | S | `The old town hall with a clock and a wide staircase, gas lamps on both sides of the steps.` |
| `stage-fountain-w-day` | W | `Café terraces under awnings with folded chairs, lamp posts, tall facades with flower boxes.` |

Ніч N — `NIGHT_EDIT` + `The letters near the top of the far tower are dark; leave room for a glowing sign there.` Сам напис — окремий
шар із § 6c [[Prompt-Library]] (прозорий фон, перевірка по літерах), щоб рушій вмикав його лише вночі й ховав хмарами.

Фонтан стоїть **у центрі кола**, тож на картках його немає: він — проп (§ Пропи).

## Текстури підлоги — безшовні

Шаблон § 5 [[Prompt-Library]] байт-у-байт, `nano_banana_pro`, 2k, 1:1, референс `a2913501`. Шов — зсув на 50 % і огляд.

| id | MATERIAL |
|---|---|
| `tex-floor-cobble` | `worn rounded cobblestones in slate grey and faded terracotta with dark plum-graphite joints` |
| `tex-floor-market-planks` | `weathered wooden market floor planks with nail heads and a few dusty-orange stains` |
| `tex-floor-square-tiles` | `large square stone paving tiles in pale sand and slate blue laid in a simple grid` |

Вода річки вже є: тайли `b0a9189d` / `bb5e3e44` (хвиля 2) — завантажити, а не генерувати.

## Пропи-картки

- **Ліхтар** (якір гарпуна, [[ADR-011-Diegetic-Grapple-Anchors]]) — уже є на листі якорів `c5900952` (§ 10 [[Prompt-Library]]): завантажити, 0 кр.
- **Ятка і фонтан** — один лист за шаблоном § 10: `gpt_image_2_5`, high, 2k, 16:9, референс `a2913501`.

```
Prop design sheet for a fighting game, on a flat muted mint-sage background (#B8CBB1), hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines with small line breaks, flat colors with a single magenta-violet cel shadow tone, no gradients, no gloss. Two props of the old European-industrial city of Cronshift, matching the palette of the reference image, each shown twice — front view and three-quarter view: 1) a market stall with a faded striped awning, a wooden counter, crates of fruit and a hanging lantern; 2) a large round stone fountain with a low basin, a bronze statue in the middle and flat water jets. Same scale reference, small hand-written numbers by each prop. No people, no letters or words, no logos, no watermark.
```

## Кошторис (`get_cost` 2026-10-03, кредити не списуються)

| що | ціна за 1 | `get_cost` |
|---|---|---|
| картка арени / лист пропів / редагування з референсом | 2.75 | `gpt_image_2_5`, high, 2k, 21:9 або 16:9, з референсом `a2913501` → `2.75` |
| текстура | 2 | `nano_banana_pro`, 2k, 1:1 → `2` |

| пакет | генерацій | кредити |
|---|---|---|
| **1. Стиль-проба:** river N день + N ніч, по 2 варіанти | 4 | **11** |
| 2. Решта карток: river 6, bazaar 8, fountain 8, по 2 варіанти | 44 | 121 |
| 3. Шар неону CRONSHIFT, 2 варіанти | 2 | 5.5 |
| 4. Текстури підлоги, 3 × 2 варіанти | 6 | 12 |
| 5. Лист ятки й фонтану, 2 варіанти | 2 | 5.5 |
| 6. Ліхтар, вода — завантаження наявних | 0 | 0 |
| **Арени разом (1–5)** | 58 | **155** |
| 7. Меню M2 — [[Menu-Skyline-Prompts]] (кошторис уже є) | — | 57.5–61.46 |
| **Смуга C разом** | | **212.5–216.46** |

Ощадний варіант: пакет 2 по 1 варіанту — 60.5 замість 121; смуга C — 152–156. Оцінку T1 «≈ 300 без Kling і 3D»
смуга C не перевищує.

## Журнал генерацій

| дата | що | job id | розмір · URL | вибір |
|---|---|---|---|---|
| 2026-10-03 | стиль-проба `stage-river-n-day` · v1 | `1ac2d361-4ad0-4d64-b729-45d0eba08f88` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_102633_1ac2d361-4ad0-4d64-b729-45d0eba08f88.png | чекає Santos |
| 2026-10-03 | стиль-проба `stage-river-n-day` · v2 | `ba93fc22-b3d6-4d7b-8731-e10783392edf` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_102632_ba93fc22-b3d6-4d7b-8731-e10783392edf.png | чекає Santos |
| 2026-10-03 | стиль-проба `stage-river-n-night` · v1 | `a470d3e8-9422-4ab6-9ed0-2711e327f5d9` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_102632_a470d3e8-9422-4ab6-9ed0-2711e327f5d9.png | чекає Santos |
| 2026-10-03 | стиль-проба `stage-river-n-night` · v2 | `aa24a131-71be-4635-9f44-51266c89aab3` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_102632_aa24a131-71be-4635-9f44-51266c89aab3.png | чекає Santos |

Слово Santos «Так» на стиль-пробу (11 кр.), 2026-10-03, у сесії T6. `gpt_image_2_5` high 2k 21:9, референс `a2913501`,
`generate_image_batch` (4 запити). `balance` 5555.25 → 5544.25 (−11). Відхилення від § Блоки: ніч у пробі зроблена з `a2913501`
паралельно з днем, а не редагуванням денної картки — щоб не чекати вибору дня. У пакеті 2 ніч робиться з обраного дня.
T6 у хмарі картинок не бачив (CDN → 403); відбір — оком Santos.

## Related
- [[Cronshift]] · [[Prompt-Library]] · [[Menu-Skyline-Prompts]] · [[Style-Guide]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[Textures-Registry]] · [[Prompts]] · [[2026-10-03-Apollon-Sprint-C-Prompts]]
