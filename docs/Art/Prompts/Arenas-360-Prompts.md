# Арени 360° — промпти смуги C (спринт)

**Роль:** T6 Аполлон, 2026-10-03 · **План:** спринт «тверда арена, три карти день/ніч, VFX, меню» (T1, смуга C, PR santos-va/nooneisreal#107)
· **Канон арен:** [[Cronshift]] § Нові арени · **Стиль:** [[Style-Guide]], [[ADR-007-Art-Style-Sketch-Cel]].
**Статус:** промпти й ціни готові, **кредитів не витрачено**. Генерація — лише після слова Santos на стелю (§ Кошторис).

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

## v2 — «менше деталей» (хвиля T6-0, план [[2026-10-03-Santos-Packs-Arenas]], пункт 0d)

Стиль-пробу v1 (річка N, день і ніч) Santos відхилив: «занадто багато деталізацій» ([[Stage-River]]). Тепер ближній план
3–8 м за колом дають **3D-пропи з паків** ([[Pack-Review]]): бочки, ящики, ятки, лавки, сходи, причальні тумби. Тому картці
їх малювати не треба. Картка v2 — лише дальнє кільце: **3–5 великих мас** (дахи, вежі, міст), широкі пласкі площі кольору,
вікна простими повторами. Без вивісок, людей і дрібниць. Це прибирає надмір деталей і не дублює 3D.

Блоки `ARENA_STYLE`, `RING`, `DAY`, `NIGHT_EDIT` — без змін (вище). Нові:

**SIMPLE** (між `SCENE` і `DAY`):

```
Draw it with very few, very large shapes: three to five big masses of buildings, towers or bridges, broad flat areas of color, windows only as simple repeated marks, no shop signs, no small details, no street furniture, no clutter. The strip along the bottom edge is a plain, empty street or quay edge, because 3D props will stand in front of it.
```

**NEG_ARENA_V2** (замість `NEG_ARENA`): `No people at all, no silhouettes, no boats, carts or vehicles in the foreground, no text, no letters, no logos, no watermark, no anime style, no 3D render look, no gradients, no neon signs.`

Промпт: `{ARENA_STYLE} {SCENE_V2} {SIMPLE} {DAY} {RING} {NEG_ARENA_V2}`; ніч — `{NIGHT_EDIT} {NEG_ARENA_V2}` з денною карткою v2
як референсом. Референс стилю для першої картки — канон `a2913501`. Кожна наступна картка арени бере ще й попередню картку,
щоб збігались масштаб і лінія даху.

### Річка — `river` v2

| id | SCENE_V2 | 3D перед карткою ([[Pack-Review]]) |
|---|---|---|
| `stage-river-n-day-v2` | `Across the river: the whole embankment as one long simple band of brick and terracotta facades, and the twin domed clock towers rising high above it as the two biggest shapes against a plain sky.` | — (за водою) |
| `stage-river-e-day-v2` | `Downstream: the river bends away between two big warehouse blocks standing on stone piers; one large arched stone bridge crosses in the middle distance.` | міст Creative Trio — після ліцензії |
| `stage-river-s-day-v2` | `The near bank behind the arena: a plain stone quay wall and a simple row of tall facades above it; the steps down to the water are left out.` | сходи, балюстрада, бочки, ящики KayKit |
| `stage-river-w-day-v2` | `Upstream: one riveted iron tram bridge on three brick pillars crossing the river, two tall factory chimneys behind it.` | — |

### Базарчик — `bazaar` v2

| id | SCENE_V2 | 3D перед карткою |
|---|---|---|
| `stage-bazaar-n-day-v2` | `The bazaar street runs away ahead between two simple rows of tall facades under big plain awnings; the twin domed clock towers far away are the only tall shapes.` | ятки з рам KayKit + тенти |
| `stage-bazaar-e-day-v2` | `A side alley: two tall facades leaning toward each other, one staircase going up between them, a single washing line high above.` | — |
| `stage-bazaar-s-day-v2` | `The big arched brick entrance of a covered market hall, its iron-and-glass roof as one large simple shape.` | ящики, мішки, ліхтар-якір |
| `stage-bazaar-w-day-v2` | `A plain brick warehouse wall with two big loading doors and one steam vent; the stacked goods are left out.` | бочки, ящики, візок |

### Площа — `fountain` v2

| id | SCENE_V2 | 3D перед карткою |
|---|---|---|
| `stage-fountain-n-day-v2` | `Far beyond the square, one very tall thin tower rises above a simple band of rooftops; near its top there is a frame of big unlit letters that cannot be read in daylight.` | — |
| `stage-fountain-e-day-v2` | `The edge of the square: a simple row of facades with only the overhead tram wires on a few iron poles in front of them; the tram shelter is left out.` | трамвайна зупинка (герой, § Пропи) |
| `stage-fountain-s-day-v2` | `The old town hall as one big symmetrical shape with a clock and a wide staircase.` | колони KayKit по боках сходів |
| `stage-fountain-w-day-v2` | `Tall facades with flower boxes as one simple band; the café terraces are left out.` | столи, стільці, лавки KayKit / Creative Trio |

Ніч N площі — як у v1: `NIGHT_EDIT` + `The letters near the top of the far tower are dark; leave room for a glowing sign there.`

**Роздільність.** 2k 21:9 дає 2688 px на картку, тобто 1.14 тексель/піксель на 1080p (формула R11, план § Що є зараз).
4k коштує 4.25 замість 2.75 (`get_cost`, нижче) і тягне 1440p. Пропоную пробу робити на 2k, а 4k вирішувати після «стиль так».

## Текстури підлоги — безшовні

Шаблон § 5 [[Prompt-Library]] байт-у-байт, `nano_banana_pro`, 2k, 1:1, референс `a2913501`. Шов — зсув на 50 % і огляд.

| id | MATERIAL |
|---|---|
| `tex-floor-cobble` | `worn rounded cobblestones in slate grey and faded terracotta with dark plum-graphite joints` |
| `tex-floor-market-planks` | `weathered wooden market floor planks with nail heads and a few dusty-orange stains` |
| `tex-floor-square-tiles` | `large square stone paving tiles in pale sand and slate blue laid in a simple grid` |
| `tex-floor-quay-stone` (0g) | `large rectangular granite quay slabs in cool slate grey and faded sand with dark plum-graphite joints and thin olive moss lines in some of the joints` |
| `tex-floor-wet-cobble` (0g) | `rain-wet rounded cobblestones in dark slate and faded terracotta with darker wet joints and a few flat pale streaks on the stone tops` |

Вода річки вже є: тайли `b0a9189d` / `bb5e3e44` (хвиля 2) — завантажити, а не генерувати.

`tex-floor-wet-cobble` — це **матеріал** (мокрий камінь), а не «нічна» текстура, як було в плані (`-night`). Ніч у грі дає
світло ([[Palette-Remap]] правило 5). Відблиски ліхтарів в альбедо світилися б і вдень. Мокрі плями дають калюжі-декалі
(§ Декалі), а світло на них уночі — ліхтарі рушія.

## Пропи-картки

- **Ліхтар** (якір гарпуна, [[ADR-011-Diegetic-Grapple-Anchors]]) — уже є на листі якорів `c5900952` (§ 10 [[Prompt-Library]]): завантажити, 0 кр.
- **Ятка і фонтан** — один лист за шаблоном § 10: `gpt_image_2_5`, high, 2k, 16:9, референс `a2913501`.

```
Prop design sheet for a fighting game, on a flat muted mint-sage background (#B8CBB1), hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines with small line breaks, flat colors with a single magenta-violet cel shadow tone, no gradients, no gloss. Two props of the old European-industrial city of Cronshift, matching the palette of the reference image, each shown twice — front view and three-quarter view: 1) a market stall with a faded striped awning, a wooden counter, crates of fruit and a hanging lantern; 2) a large round stone fountain with a low basin, a bronze statue in the middle and flat water jets. Same scale reference, small hand-written numbers by each prop. No people, no letters or words, no logos, no watermark.
```

### Героїчні пропи v2 — у 3D (хвиля T6-0, пункт 0f)

У 3D з Higgsfield ідуть лише ті пропи, яких **немає в паках** і які стоять у центрі уваги. Решту складаємо з паків за 0 кр.
([[Pack-Review]]). Ятка змінила маршрут: її скелет — дерев'яні рами KayKit EXTRA (`scaffold_*`), прилавок — `table_long_*`,
тент — полотно `banner_*` після перефарбування. Окрема генерація ятці не потрібна.

| проп | маршрут | вхід | кр. (`get_cost`) |
|---|---|---|---|
| ліхтар-якір ([[ADR-011-Diegetic-Grapple-Anchors]]) | `image_to_3d` | вид ¾ ліхтаря № 1 з листа `props_anchors_v1.png` (`c5900952`, уже на диску, 2688×1520): `crop((350, 40, 680, 890))`, по центру квадрата 850×850 кольору тла листа | 30 |
| фонтан ([[Stage-Fountain]]) | `gpt_image_2_5` → `image_to_3d` | один об'єкт, PROP3D нижче | 2.75 + 30 |
| трамвайна зупинка (`fountain` E) | `gpt_image_2_5` → `image_to_3d` | один об'єкт, PROP3D нижче | 2.75 + 30 |
| кран над річкою (опційно) | `gpt_image_2_5` → `image_to_3d` | один об'єкт, PROP3D | 2.75 + 30 |
| кам'яний міст `river` E (опційно) | `meshy_v5_retexture` | меш `Stone_Bridges_01.fbx` (Creative Trio) + ключ стилю як `image_style_url` | 9.5 — **лише після ліцензії** (план Ф0.2): ретекстур завантажує меш у Higgsfield |

**PROP3D** — один предмет на картинку. Лист на кілька пропів `image_to_3d` не розбирає, а тінь і лінія землі стають частиною мешу:

```
Single prop for 3D modeling, one object only, shown once in a clean three-quarter view from slightly above, centered with a wide empty margin, on a flat plain light mint-sage background (#B8CBB1) with no ground, no floor line and no cast shadow, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines, flat colors with a single magenta-violet cel shadow tone, no gradients, no gloss. Match the palette and the architecture of the reference image. The prop: {PROP}. No people, no animals, no text, no letters, no numbers, no logos, no watermark.
```

`gpt_image_2_5`, high, 2k, 1:1, референс `a2913501`.

| id | PROP |
|---|---|
| `prop-fountain-v1` | `a large round stone fountain of the old European-industrial city of Cronshift: a low wide basin of pale sand stone with a thick rim, a short central column and {STATUE} on top; a few flat stylized water jets falling into the basin` |
| `prop-tram-stop-v1` | `a tram stop shelter of the old European-industrial city of Cronshift: a curved riveted iron roof on four slim cast-iron posts, a plain wooden bench under it, a round blank iron sign disc on a pole, a small gas lamp on one corner post` |
| `prop-crane-v1` (опційно) | `a riveted iron dockside crane of the old European-industrial city of Cronshift on a brick base, a long lattice arm, a hanging hook on a chain, a small operator cabin with one window` |

`{STATUE}` — **розвилка Santos/Кліо**: що за статуя, не визначено ([[Stage-Fountain]] § Не визначено). Поки лор мовчить, стоїть
нейтральне `a plain bronze obelisk with a small clock face near its top`: годинник перегукується з вежами-куполами й нічого
не вигадує.

**`image_to_3d`:** `should_texture: true`, `texture_prompt: "flat cel colors with hand-inked plum-graphite lines, one magenta-violet shadow tone, no baked lighting, no gradients"`,
`topology: quad`, `target_polycount` — PLACEHOLDER 10000, бюджет полігонів пропу дає Архімед/Гефест (FPS на M3 і телефоні —
UNGROUNDED у `state.md`). Масштаб і чи фонтан стоїть у центрі кола — Арес (план Ф4.1).

## Декалі — вид згори, з альфою (хвиля T6-0, пункт 0e)

Калюжі, тріщини, мох, люки, рейки — пласкі наклейки на підлогу (`Decal` або квад над підлогою, крок Гефеста). Один лист = 4
декалі в сітці 2×2 з широкими проміжками. Нарізка — локально, по порожніх проміжках, як у флипбуків (`repack_flipbook.py`
рівняє клітинки). Літер немає ніде: єдиний напис у місті — CRONSHIFT ([[ADR-011-Diegetic-Grapple-Anchors]] п. 5).

**DECAL** (`gpt_image_2_5`, high, 2k, 1:1, `background: "transparent"`, референс `a2913501`):

```
Top-down orthographic decal sheet for a game floor: four separate decals in a 2x2 grid with wide empty gaps, each decal centered in its own cell and touching nothing, transparent background, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked edges, flat colors, a single magenta-violet shadow tone, no gradients, no perspective, no cast shadows. Match the palette of the reference image. The decals: {DECALS}. No text, no letters, no numbers, no logos, no watermark.
```

| id | DECALS | де |
|---|---|---|
| `dec-puddles-v1` | `four rain puddles of different shapes, flat dark-teal water with two pale flat reflection streaks each` | усі арени, ніч і дощ |
| `dec-cracks-v1` | `four patches of cracked paving: thin branching cracks and a few chipped stone edges, only the cracks` | `bazaar`, `fountain` |
| `dec-moss-v1` | `four strips of olive moss and small weeds growing in the joints between paving slabs, only the moss and weeds` | `river` набережна, `fountain` |
| `dec-manhole-v1` | `two round cast-iron manhole covers and two square drain grates with simple raised geometric patterns` | `fountain`, `bazaar` |
| `dec-rails-v1` | `four pieces of tram rails embedded in the ground: a straight segment, a gentle curve, a crossing and a rail end, steel rails with dark grooves` | `fountain` E |
| `dec-market-v1` | `a torn fishing net, a small spill of ochre and red-brown spices, a splash of slate-blue paint, a scatter of straw` | `river` S, `bazaar` W |

## Кошторис v2 — паки й арени (`get_cost` T6 2026-10-03, ця сесія; кредити не списуються)

`balance` до → 5054.75, після 9 викликів `get_cost` → 5054.75.

| що | `get_cost` | кр. |
|---|---|---|
| `gpt_image_2_5` high 2k 16:9, 2 референси (ключ стилю) | `generate_image` | 2.75 |
| `gpt_image_2_5` high 2k 21:9, референс (картка, редагування ночі) | `generate_image` | 2.75 |
| `gpt_image_2_5` high 2k 1:1 `background: transparent`, референс (декалі, неон) | `generate_image` | 2.75 |
| `gpt_image_2_5` high **4k** 21:9, референс | `generate_image` | 4.25 |
| `gpt_image_2_5` **xhigh** 2k 21:9, референс | `generate_image` | 4.5 |
| `nano_banana_pro` 2k 1:1, референс (підлога) | `generate_image` | 2 |
| `image_to_3d`, `should_texture`, quad, 20000 | `generate_3d` | 30 |
| `meshy_v5_retexture` (`enable_original_uv`) | `generate_3d` | **9.5** — уперше виміряно |
| `upscale_image` 4k | `upscale_image` | 2 |

| хвиля | пакет | шт | кр. |
|---|---|---|---|
| **T6-1** | ключ стилю: шинок + причал (Prompt-Library § 18) | 2 | 5.5 |
| **T6-1** | стиль-проба кільця v2: `river` N день + ніч, по 2 варіанти | 4 | 11 |
| | **разом T6-1** | 6 | **16.5** |
| T6-2 | решта кільця v2: `river` 6, `bazaar` 8, `fountain` 8 (день + ніч), 1 варіант | 22 | 60.5 |
| T6-2 | шар неону CRONSHIFT, 2 варіанти | 2 | 5.5 |
| T6-2 | підлоги: 5 × 2 варіанти | 10 | 20 |
| T6-2 | декалі: 6 листів | 6 | 16.5 |
| T6-2 | апскейл `card_skea_v1.jpg` 4k (спершу `media_upload`: id генерації невідомий, [[Textures-Registry]]) | 1 | 2 |
| | **разом T6-2** | 41 | **104.5** |
| T6-3 | ліхтар-якір `image_to_3d` з наявного листа | 1 | 30 |
| T6-3 | фонтан і зупинка: PROP3D + `image_to_3d` | 2 + 2 | 65.5 |
| | **разом T6-3** | 5 | **95.5** |
| опційно | кран (PROP3D + 3D) · міст (ретекстур, після ліцензії) · кільце 4k замість 2k (+1.5 × 26) | | 32.75 · 9.5 · 39 |

**Хвилі 1–3 разом — 216.5 кр.** (план T1 рахував ≈ 240–270; дешевше, бо ятка складається з паку, а ліхтар береться з наявного
листа). Лишок стелі спринту: T1 рахував ≈ 513 на 5068.25, зараз 5054.75. Різниця 13.5 = 3 × 4.5 кр. «GPT Image 2.5 Flare»
о 15:10Z (`transactions`), **не ця сесія**. Яка конфігурація, з `transactions` не видно: 4.5 збігається з xhigh 2k. Отже лишок ≈ 499.5, і хвилі 1–3 в нього вміщаються.

## Кошторис v1 (`get_cost` 2026-10-03, кредити не списуються)

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

## Related
- [[Cronshift]] · [[Prompt-Library]] · [[Menu-Skyline-Prompts]] · [[Style-Guide]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[Textures-Registry]] · [[Prompts]] · [[2026-10-03-Apollon-Sprint-C-Prompts]] · [[Pack-Review]] · [[Palette-Remap]] · [[2026-10-03-Santos-Packs-Arenas]] · [[Stage-Fountain]]
