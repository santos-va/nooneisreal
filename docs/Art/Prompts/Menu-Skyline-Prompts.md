# Промпти меню «Погляд з даху» (М2)

Власник: T6 Аполлон · **Дата:** 2026-10-03 · **Issue:** santos-va/nooneisreal#6 · **План:** [[2026-10-03-Main-Menu-Skyline]] § М2
**Статус:** промпти готові, **нічого не згенеровано** — кожна партія чекає слова Santos (RED). Меню — поза стелею 600 кредитів фази 2–3.

Місто в промптах — **Cronshift** ([[ADR-010-City-Name-Cronshift]]). Стиль — [[Style-Guide]]; блоки `{STYLE}` і `{NEG}`
персонажних партій — байт-у-байт з [[Prompt-Library]]. Фонові партії використовують фонову формулу з
[[Prompt-Library]] § 6 (без пропорцій персонажа). Мова промптів — англійська.

## Кошторис (виміряно в цій сесії, 2026-10-03)

`balance` → **6010** кредитів, Ultra; `list_workspaces` → `bf32c161-…` `is_selected:true`.
Ціни — `generate_image` з `get_cost:true` (нічого не списано). **Увага:** `get_cost` повертає ціну **одного**
зображення навіть із `count:4` (2.75 і для `count:1`, і для `count:4`) — множення на кількість нижче моє, не виміряне.

| що виміряно | параметри | кредитів |
|---|---|---|
| `gpt_image_2_5` | high, 2k, 21:9 (і 16:9; з `background:transparent` і з референсом — так само) | **2.75** |
| `gpt_image_2_5` | high, **4k**, 21:9 (і transparent) | **4.25** |
| `nano_banana_pro` | 4k, 21:9 | **4** |
| `image_decompose` | референс міста (`media_id 59110bbd-…`) | **2** |
| `flux_2_pro_outpaint` | вхід 2688×1152, +512 ліворуч і праворуч | **3.96** |
| `autosprite` | `walk`, `iso_walk_right`, `custom` — **оцінювач падає** («Something went wrong», 3 спроби) | **не виміряно** |

### Партії

| # | id | що | модель | шт | кредитів |
|---|---|---|---|---|---|
| M2-A | `menu-skyline-plate-v1` | панорама з даху, 21:9, присмерк (шари 0–2) | gpt_image_2_5 high **4k** | 4 варіанти | 4 × 4.25 = **17** |
| M2-B | `menu-roof-edge-v1` | передній план: парапет, бак, край хмарочоса — **прозорий фон** (шар 4) | gpt_image_2_5 high 2k transparent | 2 | 2 × 2.75 = **5.5** |
| M2-C | `menu-skyline-layers` | decompose переможця M2-A на небо / skyline / вулиці | image_decompose | 1 | **2** |
| M2-D | `menu-skyline-outpaint` | лише якщо кадр тісний для 21:9 / UI-плашки | flux_2_pro_outpaint | 0–1 | 0–**3.96** |
| M2-E | `sprite-pedestrian-<type>-walk` | цикл ходи, 4 силуети, вид згори під кутом | gpt_image_2_5 high 2k transparent | 4 | 4 × 2.75 = **11** |
| M2-F | `sprite-steamcar-<a/b>` | дві парові машини, вид згори під кутом | gpt_image_2_5 high 2k transparent | 2 варіанти | 2 × 2.75 = **5.5** |
| M2-G | `vfx-steam-puff` | кадри клубу пари (6 кадрів) | gpt_image_2_5 high 2k transparent | 2 варіанти | 2 × 2.75 = **5.5** |
| M2-H | `<ch>-flyby-poses-v1` | замах / політ / відпуск — Choko і Skea | gpt_image_2_5 high 2k transparent + референс | 2 × 2 варіанти | 4 × 2.75 = **11** |
| | **Разом** | | | | **57.5** (+ 3.96 outpaint = **61.46**) |

Дешевший варіант панорами — 2k: 4 × 2.75 = 11 → разом **51.5**. Рекомендую 4k: меню — перший кадр гри, а 2k
21:9 на 4K-моніторі розтягується (точна піксельна ширина 2k 21:9 — **не перевірено**, побачимо по першому файлу).

### Порядок і рекомендація Аполлона

1. **M2-A** першою і окремо — вона задає світло й палітру для решти. Santos обирає 1 з 4.
2. **M2-B, M2-C** (і M2-D, якщо треба) — на основі обраної панорами (референс = job-id переможця).
3. **M2-E, M2-F, M2-G** — разом, з панорамою як референсом палітри.
4. **M2-H — після листів поз `<ch>-sheet-v1`** ([[Asset-Manifest]] § A, фаза 2 [[2026-10-03-Production-Plan]]). Зараз у
   репо персонажі лише в старому аніме-стилі (`grep -n "sheet-v1" docs/Art/Textures-Registry.md` → порожньо);
   генерувати пози прольоту зі старої картки — значить малювати героя двічі. До того М3 літає плейсхолдером.

**Альтернатива для перехожих** — `autosprite` `iso_walk_*` (справжній цикл ходи з одного кадру, без ручного
нарізання). Ціну виміряти не вдалося — пропоную лише після того, як оцінювач запрацює; одна пробна партія зі слова Santos.

## Референси (імпортовано `media_import_url`, кредитів не бере)

| що | media_id | джерело |
|---|---|---|
| референс міста (палітра, архітектура) | `59110bbd-6b9c-411c-8fc0-edb48c951021` | `bg-city-ref` у [[Textures-Registry]] |
| картка Choko v3 (ідентичність, старий стиль) | `87a54896-15ff-4a9d-a2d3-ff9df2669eac` | `card-choko-v3` у [[Textures-Registry]] |

## M2-A · Панорама — `menu-skyline-plate-v1`

gpt_image_2_5, quality high, 4k, 21:9, `count:4`, референс міста (`image_references`).

```
Wide main-menu background for a fighting game, 21:9, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines with small line breaks, flat colors with a single magenta-violet cel shadow tone, no gradients, no gloss. The view from the flat rooftop of a tall skyscraper looking out over the old European-industrial city of Cronshift at dusk. Composition in depth: on the left quarter of the frame the near edge of an even taller neighbouring skyscraper rises out of frame, dark brick with a steel cornice; along the very bottom a low stone rooftop parapet and the curved side of a riveted water tower barrel. Middle ground far below: two or three cobblestone streets with wide sidewalks seen from high above at a steep angle, gas lamps already lit, empty of people and vehicles. Background: a dense skyline of brick and terracotta roofs, brass domes, chimneys and water tanks, a large clock tower slightly right of center, a river glinting between buildings. Sky: dusk with a warm terracotta glow at the horizon fading to slate blue, a few long flat cloud shapes. Muted palette of terracotta #C8623A, slate blue #4A5C73, deep teal #1F4D5A, warm lamp accents. The upper-middle band of the sky is calm and uncluttered. No people, no cars, no text, no logos, no signs with letters, no neon.
```

Чому без людей і машин: вони живуть окремими спрайтами (шар 2), інакше намальовані перехожі стоятимуть поверх живих.
Чому спокійна смуга неба: туди пролітає герой (шар 3) і туди ж не лягають пункти меню — уточнить Гермес у М1 (#5).

## M2-B · Передній план — `menu-roof-edge-v1`

gpt_image_2_5, high, 2k, 21:9, `background:"transparent"`, `count:2`, референс = job-id переможця M2-A.

```
Foreground overlay layer for a 21:9 main-menu background, transparent background, hand-drawn in a loose expressive western animation sketch style, not anime: plum-graphite inked lines, flat colors with a single magenta-violet cel shadow. Only the nearest rooftop elements, matching the lighting and palette of the reference image: along the bottom edge a low stone parapet with a worn copper cap, on the left quarter the tall vertical edge of a neighbouring skyscraper running from the bottom to the top of the frame (dark brick, steel cornice, a few lit windows), and at the bottom right a riveted wooden-and-iron water tower barrel on short legs. Everything else is fully transparent: no sky, no city, no streets. No people, no text, no logos.
```

Край хмарочоса ліворуч — з-за нього вилітає герой (план, композиція кадру). Якщо Гермес у М1 поставить плашку меню
ліворуч — дзеркалимо шар у рушії, перегенерація не потрібна.

## M2-C · Шари — `menu-skyline-layers`

`image_decompose` на переможця M2-A. Очікувані шари: небо · skyline · вулиці. Якщо decompose злипне вулиці зі
skyline — у М3 Гефест бере панораму цілою як шари 0–2, а паралакс дає лише M2-B (рішення на око, без кредитів).

## M2-D · Outpaint — `menu-skyline-outpaint` (за потреби)

`flux_2_pro_outpaint`, `input_width`/`input_height` — фактичні розміри переможця, `expand_left/right` 512.
Запускаємо лише якщо в кадрі бракує місця під плашку меню або safe area 21:9 → 32:9. Промпт не потрібен.

## M2-E · Перехожі — `sprite-pedestrian-<type>-walk`

gpt_image_2_5, high, 2k, 16:9, `background:"transparent"`, по одному запуску на тип, референс = переможець M2-A (палітра).

```
Sprite sheet for a 2D game, transparent background, hand-drawn in a loose expressive western animation sketch style, not anime: plum-graphite inked outline, flat colors with a single magenta-violet cel shadow, no gradients. One small pedestrian, {TYPE}, seen from high above at a steep three-quarter top-down angle as if from a skyscraper roof, walking to the right. Eight frames of one looping walk cycle in a single horizontal row, evenly spaced, identical scale and identical ground line in every frame, the same character and colors in every frame, clear readable silhouette. Muted dusk palette of terracotta, slate blue and deep teal with small warm accents. No shadows on the ground, no text, no numbers, no frames or grid lines.
```

| type | TYPE |
|---|---|
| `worker` | a factory worker in a flat cap and a long apron carrying a toolbox |
| `lady` | a woman in a long coat and a small hat carrying a paper bag |
| `courier` | a thin teenage courier in a short jacket with a satchel, walking briskly |
| `elder` | an old man in a wide coat with a walking cane and a scarf |

Рух ліворуч — дзеркало в рушії. Натовп густішає копіями з різними відтінками (modulate), не новими генераціями.

## M2-F · Парові машини — `sprite-steamcar-a/b`

gpt_image_2_5, high, 2k, 16:9, `background:"transparent"`, `count:2`, референс = переможець M2-A.

```
Game sprite sheet, transparent background, hand-drawn in a loose expressive western animation sketch style, not anime: plum-graphite inked outline, flat colors with a single magenta-violet cel shadow, no gradients, no gloss. Two different small steam-powered automobiles of an old European-industrial city, each shown once, side by side with empty space between them, both seen from high above at a steep three-quarter top-down angle and driving to the right: A) a compact boxy brass-and-dark-green steam car with a tall thin chimney at the back and big spoked wheels; B) a long rust-red steam delivery van with a riveted boiler in front, a short fat chimney and a canvas roof. Same scale, same ground line, wheels drawn as clean separate ellipses. Muted dusk palette with warm brass accents, lit headlamps. No steam clouds, no drivers visible, no text, no logos, no license plates.
```

Колеса окремими еліпсами — щоб Гефест міг підмінити їх обертовим спрайтом. Пара — окремий шар (M2-G).

## M2-G · Клуб пари — `vfx-steam-puff`

gpt_image_2_5, high, 2k, 16:9, `background:"transparent"`, `count:2`.

```
VFX sprite sheet for a 2D game, transparent background, hand-drawn in a loose expressive western animation sketch style: soft plum-graphite inked outline with line breaks, flat off-white #E8F1EC fill with a single lilac cel shadow tone, no gradients. Six frames in one horizontal row of a single puff of steam from a chimney: 1) small tight puff, 2) growing, 3) round full cloud, 4) stretching up and drifting right, 5) breaking into two clumps, 6) thin fading wisps. Same scale reference and same base point in every frame, evenly spaced. No text, no numbers, no frames or grid lines.
```

Той самий шит — дим із труб skyline (шар 1) у меншому масштабі.

## M2-H · Пози прольоту — `<ch>-flyby-poses-v1` (після `<ch>-sheet-v1`)

gpt_image_2_5, high, 2k, 16:9, `background:"transparent"`, `count:2` на персонажа. Референс = затверджений лист
поз `<ch>-sheet-v1` у новому стилі (не стара картка). `{STYLE}`, `{NEG}`, `{IDENTITY}` — з [[Prompt-Library]].

```
{STYLE} Three full-body poses of the same original character swinging across the sky on a grappling rope, shown left to right in one row with empty space between them, transparent background, all seen from the side at a slightly low angle: 1) WIND-UP — leaping off a ledge, one arm thrown up holding a taut rope that runs straight up out of frame, legs tucked, body coiled; 2) SWING — at the bottom of the pendulum arc, body stretched long and horizontal, the rope hand above the head, the free arm and legs trailing back, clothes and hair streaming; 3) RELEASE — letting go of the rope at the top of the arc, both arms flung open, body arching forward, flying free. The rope is a thin dark line ending in the gripping hand. Identity: {IDENTITY}. No background, no ground, no text, no numbers. {NEG}
```

Мотузка обрізана краєм кадру — в рушії її продовжує лінія до якоря ([[04-Grapple-System]]). Персонаж летить
праворуч; ліворуч — дзеркало.

## Повторне використання — екран вибору (Б1, santos-va/nooneisreal#11)

Панорама M2-A, шари M2-B/C, перехожі, машини, пара — ті самі, без нових кредитів. Нове для Б1 (пози «стоїть на даху»
×2, іконки скілів) — у кошторисі В2, коли до нього дійде черга.

## Журнал запусків

| дата | партія | job-id | результат |
|---|---|---|---|
| — | — | — | ще нічого не запускалось |

## Related
- [[2026-10-03-Main-Menu-Skyline]] · [[Asset-Manifest]] · [[Prompt-Library]] · [[Style-Guide]] · [[Higgsfield-Pipeline]] · [[Textures-Registry]] · [[ADR-010-City-Name-Cronshift]] · [[04-Grapple-System]] · [[Kronshift]]
