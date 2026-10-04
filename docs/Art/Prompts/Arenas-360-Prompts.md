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

**THIRD_V2** (крок 1, після вибору проби): третій референс — обрана смуга тієї ж арени (`river` → `9d96757d`, `bazaar` → `bc50c97d`, `fountain` → `9d96757d`); промпт `{ARENA_STYLE_V2} {STRIPS_V2} {THIRD_V2}`:

```
Match the hand, line, colors and level of detail of the third reference image exactly: it is an approved strip of this same city.
```

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

## ~~v2 — «менше деталей»~~ — ЗАМІНЕНО (хвиля T6-0, план [[2026-10-03-Santos-Packs-Arenas]], пункт 0d)

> **Замінено вибором Santos — вирізки** (§ «v2 — простіше, у стилі героїв» на початку файла: `9d96757d` river N, `bc50c97d` bazaar N + 20 смуг кроку 1). Суцільні картки нижче не генеруємо; хвилі T6-1 і T6-2 скасовано ([[2026-10-03-Arena-Depth-Life]] Ф3.0, Ф3.9). Розділ лишається як журнал.


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

| 2026-10-03 | крок 1 `stage-river-e-strips` · v1 | `9353d0e1-3a6a-4ae6-8e26-fee3dd3bb945` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105012_9353d0e1-3a6a-4ae6-8e26-fee3dd3bb945.png | ні |
| 2026-10-03 | крок 1 `stage-river-e-strips` · v2 | `6a0d67d3-9ee7-43df-b1c7-f62b8f3e0b6c` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105011_6a0d67d3-9ee7-43df-b1c7-f62b8f3e0b6c.png | **так** (T6 за дорученням Santos, 2026-10-04) |
| 2026-10-03 | крок 1 `stage-river-s-strips` · v1 | `8dfc14ec-fe34-42b8-911f-2755bd8cb4ef` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105012_8dfc14ec-fe34-42b8-911f-2755bd8cb4ef.png | **так** (T6 за дорученням Santos, 2026-10-04) |
| 2026-10-03 | крок 1 `stage-river-s-strips` · v2 | `bdd6f0ea-a09b-4598-91bf-ddf533713bf8` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105010_bdd6f0ea-a09b-4598-91bf-ddf533713bf8.png | ні |
| 2026-10-03 | крок 1 `stage-river-w-strips` · v1 | `a3fc26af-3d60-4f3e-b567-79d4683640ea` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105012_a3fc26af-3d60-4f3e-b567-79d4683640ea.png | ні |
| 2026-10-03 | крок 1 `stage-river-w-strips` · v2 | `58ae71af-8b94-4c48-b9e4-bbc408737744` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105011_58ae71af-8b94-4c48-b9e4-bbc408737744.png | **так** (T6 за дорученням Santos, 2026-10-04) |
| 2026-10-03 | крок 1 `stage-bazaar-e-strips` · v1 | `839c0ef8-71dc-41bf-bca3-3764b11d7364` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105013_839c0ef8-71dc-41bf-bca3-3764b11d7364.png | ні |
| 2026-10-03 | крок 1 `stage-bazaar-e-strips` · v2 | `9a1f06b2-6661-4fef-8ba5-773eb89cc3a9` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105011_9a1f06b2-6661-4fef-8ba5-773eb89cc3a9.png | **так** (T6 за дорученням Santos, 2026-10-04) |
| 2026-10-03 | крок 1 `stage-bazaar-s-strips` · v1 | `f328309b-0116-4052-a5e8-4e5f224c43e2` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105012_f328309b-0116-4052-a5e8-4e5f224c43e2.png | ні |
| 2026-10-03 | крок 1 `stage-bazaar-s-strips` · v2 | `19181cec-e4bc-4a4e-b299-590d33622f90` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105012_19181cec-e4bc-4a4e-b299-590d33622f90.png | **так** (T6 за дорученням Santos, 2026-10-04) |
| 2026-10-03 | крок 1 `stage-bazaar-w-strips` · v1 | `039a422b-0076-48ed-b186-73ee3b0faffd` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105013_039a422b-0076-48ed-b186-73ee3b0faffd.png | **так** (T6 за дорученням Santos, 2026-10-04) |
| 2026-10-03 | крок 1 `stage-bazaar-w-strips` · v2 | `d5f907dd-67c1-4fcf-a04a-22311efcaeff` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105013_d5f907dd-67c1-4fcf-a04a-22311efcaeff.png | ні |
| 2026-10-03 | крок 1 `stage-fountain-n-strips` · v1 | `c766678a-1cef-4667-bcb0-0ef7065b5ad9` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105056_c766678a-1cef-4667-bcb0-0ef7065b5ad9.png | ні |
| 2026-10-03 | крок 1 `stage-fountain-n-strips` · v2 | `c190a897-5057-417e-ac06-bebf3f3fba18` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105057_c190a897-5057-417e-ac06-bebf3f3fba18.png | **так** (T6 за дорученням Santos, 2026-10-04) |
| 2026-10-03 | крок 1 `stage-fountain-e-strips` · v1 | `3b78eacc-4038-4c13-b876-f5e6d6b1fec0` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105056_3b78eacc-4038-4c13-b876-f5e6d6b1fec0.png | **так** (T6 за дорученням Santos, 2026-10-04) |
| 2026-10-03 | крок 1 `stage-fountain-e-strips` · v2 | `5876d02c-2a49-467c-b954-6c869f6eb103` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105056_5876d02c-2a49-467c-b954-6c869f6eb103.png | ні |
| 2026-10-03 | крок 1 `stage-fountain-s-strips` · v1 | `39b433fa-becf-4c77-a05d-48b97b12bed2` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105055_39b433fa-becf-4c77-a05d-48b97b12bed2.png | **так** (T6 за дорученням Santos, 2026-10-04) |
| 2026-10-03 | крок 1 `stage-fountain-s-strips` · v2 | `01da3a84-707d-4512-8082-b436180ec066` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105057_01da3a84-707d-4512-8082-b436180ec066.png | ні |
| 2026-10-03 | крок 1 `stage-fountain-w-strips` · v1 | `df3b68bb-5041-41ad-a7e8-fcc1ca8e2931` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105056_df3b68bb-5041-41ad-a7e8-fcc1ca8e2931.png | **так** (T6 за дорученням Santos, 2026-10-04) |
| 2026-10-03 | крок 1 `stage-fountain-w-strips` · v2 | `dd8800b8-1722-4675-b257-2d522497b5d4` | 2688×1152, transparent · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_105057_dd8800b8-1722-4675-b257-2d522497b5d4.png | ні |

Крок 1: слово Santos «Go», 2026-10-03, у сесії T6. 20 генерацій (10 напрямків × 2), референси `f21298f4` + `08c09625` + обрана смуга арени (`THIRD_V2`); `get_cost` 3 референси → 2.75; `balance` 5533.25 → 5478.25 (−55).

Проба v2: слово Santos «GO!», 2026-10-03, у сесії T6. `gpt_image_2_5` high 2k 21:9 transparent, референси `f21298f4` + `08c09625`; промпт зібрано скриптом із блоків § v2 байт-у-байт. `balance` 5544.25 → 5533.25 (−11).

Слово Santos «Так» на стиль-пробу (11 кр.), 2026-10-03, у сесії T6. `gpt_image_2_5` high 2k 21:9, референс `a2913501`,
`generate_image_batch` (4 запити). `balance` 5555.25 → 5544.25 (−11). Відхилення від § Блоки: ніч у пробі зроблена з `a2913501`
паралельно з днем, а не редагуванням денної картки — щоб не чекати вибору дня. У пакеті 2 ніч робиться з обраного дня.
T6 у хмарі картинок не бачив (CDN → 403); відбір — оком Santos.

## Related
- [[Cronshift]] · [[Prompt-Library]] · [[Menu-Skyline-Prompts]] · [[Style-Guide]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[Textures-Registry]] · [[Prompts]] · [[2026-10-03-Apollon-Sprint-C-Prompts]] · [[Pack-Review]] · [[Palette-Remap]] · [[2026-10-03-Santos-Packs-Arenas]] · [[Stage-Fountain]] · [[2026-10-03-Arena-Depth-Life]]
