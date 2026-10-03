# Арени 360° — промпти смуги C (спринт)

**Роль:** T6 Аполлон, 2026-10-03 · **План:** спринт «тверда арена, три карти день/ніч, VFX, меню» (T1, смуга C, PR santos-va/nooneisreal#107)
· **Канон арен:** [[Cronshift]] § Нові арени · **Стиль:** [[Style-Guide]], [[ADR-007-Art-Style-Sketch-Cel]].
**Статус:** проба v1 — «занадто багато деталізацій» (Santos); **v2** — простіше, у стилі героїв, вирізками (§ v2); проба v2 — **обрано v2 і там, і там** (Santos): `9d96757d` (river N), `bc50c97d` (bazaar N); вони — референс стилю для решти напрямків. Генерація — лише після слова Santos на стелю (§ Кошторис).

## v2 — простіше, у стилі героїв (відгук Santos на пробу v1)

Santos 2026-10-03 про пробу v1: «занадто багато деталізацій, треба, щоб було в стилі персонажів і відчувалось так. Перехожі,
машини й шматочки будівель вийшли здраво — так і зараз». Що спрацювало там (порівняння промптів [[Menu-Skyline-Prompts]] § M2-E,
M2-F, M2-K з § 6 [[Prompt-Library]]):

| там (вийшло) | у v1 арен (не вийшло) |
|---|---|
| один предмет або один ряд, 3–4 названі елементи | ціла сцена, 8–10 елементів (фасади, дахи, вежі, міст, ліхтарі, відблиски) |
| вирізка на прозорому тлі, неба й землі немає | повна ілюстрація з небом, світлом і атмосферою |
| «flat colors with a single magenta-violet cel shadow» без опису світла | «late afternoon light, warm low sun, dusty-orange sky» — модель малює освітлення й глибину |
| референс — затверджений арт у новому стилі | референс — `a2913501`, сам уже насичений деталями |

**Що змінюю у v2:**
1. **Референс манери — лист героя** `f21298f4` (Choko, канон 1a): лінія, заливка, одна тінь — ті самі, що в персонажів. Другий
   референс — картки будівель `08c09625` (переможець M2-K): масштаб і форма «шматочків міста».
2. **Формула STYLE героїв** ([[Prompt-Library]] § STYLE), переписана під тло: «великі прості форми, мало деталей, як фон
   західного мультсеріалу».
3. **Арена = вирізки, а не картини.** Кожен напрямок — 2 смуги на прозорому тлі: ближній ряд (3–5 будинків або пропів) і
   далекий силует міста. Небо й світло (день/ніч) дає рушій. Так шви між напрямками зникають (у смуг прозорі краї), а ніч — це
   світло рушія плюс шар вікон, а не нова картина.
4. **Сцена — максимум 4 елементи.** Решту доповнюють пропи-картки й частинки (пара, вогні).

**ARENA_STYLE_V2:**

```
Background cut-out art for a 2D/3D fighting game, drawn in exactly the same loose expressive western animation sketch style as the character in the first reference image, NOT anime: lively slightly sketchy line art in dark plum-graphite brown (not pure black), thicker outer contour and thinner inner lines with small line breaks, flat base colors with a single cel shadow tone hue-shifted toward magenta-violet, almost no highlights, no gradients, no gloss, no painted texture. Big simple shapes and few details, like a background in a western animated series: each building is a few flat color blocks with a handful of simple windows, rooftops as clean flat shapes, calm empty flat areas. Muted palette of terracotta, slate blue, deep teal and brass.
```

**STRIPS_V2:**

```
Transparent background. Two separate horizontal cut-out strips with clean edges and full transparency around them, matching the scale of the city pieces in the second reference image: the upper strip is {FAR}; the lower strip is {NEAR}, larger. No sky, no ground, no water, no light effects, no people, no cars, no letters or words, no logos, no neon.
```

`gpt_image_2_5`, high, 2k, 21:9, `background: "transparent"`, референси `f21298f4` + `08c09625` (`image_references`).
Промпт: `{ARENA_STYLE_V2} {STRIPS_V2}`.

| id | FAR | NEAR |
|---|---|---|
| `stage-river-n-strips` | `a low distant city silhouette with the twin domed clock towers in the middle` | `a row of four narrow brick and terracotta houses along a stone quay, with two simple iron street lamps` |
| `stage-river-e-strips` | `a distant row of warehouse roofs and two thin chimneys` | `an arched stone bridge seen from the side, with one street lamp on it` |
| `stage-river-s-strips` | `a distant row of rooftops with water tanks` | `wide stone steps going down from a quay, two moored flat barges and one tall iron lamp post` |
| `stage-river-w-strips` | `distant factory chimneys` | `a riveted iron tram bridge on two brick pillars, seen from the side` |
| `stage-bazaar-n-strips` | `the twin domed clock towers far away above a few rooftops` | `three market stalls under faded striped awnings with a string of lights between them` |
| `stage-bazaar-e-strips` | `a few distant rooftops and a chimney` | `two narrow houses with balconies and a washing line between them, a staircase going up` |
| `stage-bazaar-s-strips` | `a distant glass-and-iron market hall roof` | `the arched brick entrance of a covered market, stacked crates by the door, one street lamp` |
| `stage-bazaar-w-strips` | `a few distant rooftops` | `stacked wooden crates and barrels, a hand cart and a spice stall with two hanging lanterns` |
| `stage-fountain-n-strips` | `a very tall thin tower far away with a frame of big dark unlit letters near its top that cannot be read` | `a row of four calm town houses with flower boxes` |
| `stage-fountain-e-strips` | `distant rooftops with overhead tram wires` | `a tram stop shelter with a curved roof and two iron wire poles` |
| `stage-fountain-s-strips` | `a distant clock tower` | `the old town hall with a clock and a wide staircase, two gas lamps` |
| `stage-fountain-w-strips` | `a few distant rooftops` | `two café terraces under awnings with folded chairs and one lamp post` |

**Ніч у v2** — без нової картини: шар «вікна світяться» для кожної смуги (`NIGHT_WINDOWS`) + світло рушія.

```
Same cut-out strips as the reference image, identical shapes and line art, transparent background; only the windows and lamps are lit with flat warm yellow light, everything else fully transparent.
```

Якщо шар вікон не вийде чистим — запасний шлях: ніч редагуванням смуги (`NIGHT_EDIT` нижче), той самий кадр.

## v1 (стиль-проба 2026-10-03 — «занадто деталізовано», лишаю як журнал)

### Форма v1 — 4 картки на арену

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

## Кошторис v2 (`get_cost` 2026-10-03: transparent, 21:9, high 2k, референси `f21298f4` + `08c09625` → 2.75)

| пакет | генерацій | кредити |
|---|---|---|
| **проба v2:** `stage-river-n-strips` ×2 + `stage-bazaar-n-strips` ×2 | 4 | **11** |
| решта 10 напрямків, по 2 варіанти | 20 | 55 |
| ніч: шар вікон на 12 напрямків, по 1 | 12 | 33 |
| текстури, пропи, неон — як у v1 | 10 | 23 |
| **арени v2 разом** | 46 | **122** (замість 155 у v1) |

## Журнал генерацій

| дата | що | job id | розмір · URL | вибір |
|---|---|---|---|---|
| 2026-10-03 | проба v1 `stage-river-n-day` · v1 | `1ac2d361-4ad0-4d64-b729-45d0eba08f88` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_102633_1ac2d361-4ad0-4d64-b729-45d0eba08f88.png | ні — «занадто деталізовано» |
| 2026-10-03 | стиль-проба `stage-river-n-day` · v2 | `ba93fc22-b3d6-4d7b-8731-e10783392edf` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_102632_ba93fc22-b3d6-4d7b-8731-e10783392edf.png | ні — «занадто деталізовано» |
| 2026-10-03 | стиль-проба `stage-river-n-night` · v1 | `a470d3e8-9422-4ab6-9ed0-2711e327f5d9` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_102632_a470d3e8-9422-4ab6-9ed0-2711e327f5d9.png | ні — «занадто деталізовано» |
| 2026-10-03 | стиль-проба `stage-river-n-night` · v2 | `aa24a131-71be-4635-9f44-51266c89aab3` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_102632_aa24a131-71be-4635-9f44-51266c89aab3.png | ні — «занадто деталізовано» |
| 2026-10-03 | стиль-проба v2 `stage-river-n-strips` · v1 | `7d605bc7-3469-4c2b-a0c2-efabbb7001b5` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_103524_7d605bc7-3469-4c2b-a0c2-efabbb7001b5.png | ні |
| 2026-10-03 | стиль-проба v2 `stage-river-n-strips` · v2 | `9d96757d-da5c-4491-9134-311113be796a` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_103524_9d96757d-da5c-4491-9134-311113be796a.png | **так** (Santos «і там і там v2») |
| 2026-10-03 | стиль-проба v2 `stage-bazaar-n-strips` · v1 | `d523c637-2140-488d-ac6f-b4878ad21d8e` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_103524_d523c637-2140-488d-ac6f-b4878ad21d8e.png | ні |
| 2026-10-03 | стиль-проба v2 `stage-bazaar-n-strips` · v2 | `bc50c97d-27f6-41d5-be65-3799cb4a45d1` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_103525_bc50c97d-27f6-41d5-be65-3799cb4a45d1.png | **так** (Santos «і там і там v2») |

Проба v2: слово Santos «GO!», 2026-10-03, у сесії T6. `gpt_image_2_5` high 2k 21:9 transparent, референси `f21298f4` + `08c09625`; промпт зібрано скриптом із блоків § v2 байт-у-байт. `balance` 5544.25 → 5533.25 (−11).

Слово Santos «Так» на стиль-пробу (11 кр.), 2026-10-03, у сесії T6. `gpt_image_2_5` high 2k 21:9, референс `a2913501`,
`generate_image_batch` (4 запити). `balance` 5555.25 → 5544.25 (−11). Відхилення від § Блоки: ніч у пробі зроблена з `a2913501`
паралельно з днем, а не редагуванням денної картки — щоб не чекати вибору дня. У пакеті 2 ніч робиться з обраного дня.
T6 у хмарі картинок не бачив (CDN → 403); відбір — оком Santos.

## Related
- [[Cronshift]] · [[Prompt-Library]] · [[Menu-Skyline-Prompts]] · [[Style-Guide]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[Textures-Registry]] · [[Prompts]] · [[2026-10-03-Apollon-Sprint-C-Prompts]]
