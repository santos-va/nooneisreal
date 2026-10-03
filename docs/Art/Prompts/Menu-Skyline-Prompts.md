# Промпти меню «Погляд з даху» (М2)

Власник: T6 Аполлон · **Дата:** 2026-10-03 · **Issue:** santos-va/nooneisreal#6 · **План:** [[2026-10-03-Main-Menu-Skyline]] § М2
**Статус:** M2-A — переможець `73ee9806` (хвиля 1); M2-B, M2-C, M2-E (проба), M2-F, M2-G і нова M2-K згенеровано в хвилі 2 (santos-va/nooneisreal#14) — чекають вибору Santos; M2-D outpaint не пройшов (422); M2-H чекає Х3d. Меню — поза стелею 600 кредитів фази 2–3.

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
21:9 на 4K-моніторі розтягується (2k 21:9 = 2688×1152, 4k 21:9 = 3840×1648 — `show_generation_by_ids`, хвиля 1).

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
Wide main-menu background for a fighting game, 21:9, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines with small line breaks, flat colors with a single magenta-violet cel shadow tone, no gradients, no gloss. The view from the flat rooftop of a tall skyscraper looking out over the old European-industrial city of Cronshift at dusk. Composition in depth: on the left quarter of the frame the near edge of an even taller neighbouring skyscraper rises out of frame, dark brick with a steel cornice; along the very bottom a low stone rooftop parapet and the curved side of a riveted water tower barrel. Middle ground far below: two or three cobblestone streets with wide sidewalks seen from high above at a steep angle, gas lamps already lit, empty of people and vehicles. Background: a dense skyline of brick and terracotta roofs, brass domes, chimneys and water tanks, the twin domed clock towers of the city slightly right of center, a river glinting between buildings. Sky: dusk with a warm terracotta glow at the horizon fading to slate blue, a few long flat cloud shapes. Muted palette of terracotta #C8623A, slate blue #4A5C73, deep teal #1F4D5A, warm lamp accents. The upper-middle band of the sky is calm and uncluttered. No people, no cars, no text, no logos, no signs with letters, no neon.
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

## M2-K · Картки глибини діорами — `menu-depth-cards-v1` ([[ADR-012-Menu-As-3D-Diorama]])

gpt_image_2_5, high, 2k, 21:9, `background:"transparent"`, ×2, референс = переможець M2-A `73ee9806`. Згенеровано в хвилі 2.

```
Depth layer cards for a 3D diorama main menu, transparent background, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite inked lines with small line breaks, flat colors with a single magenta-violet cel shadow tone, no gradients, no gloss. Matching the city, palette and dusk lighting of the reference image, as seen from a high skyscraper roof. Two separate horizontal cut-out strips with clean edges and full transparency around them: the upper strip is a middle-distance row of city blocks (brick and terracotta roofs, brass domes, chimneys, water tanks, lit windows); the lower strip is a nearer row of the closest rooftops, larger and more detailed, with chimney stacks, big iron street lamps and ventilation pipes sticking up from the roofs, each with an iron ring a grappling hook could catch. No sky, no streets, no ground, no people, no cars, no letters or words, no logos, no neon.
```

Decompose (M2-C) у хвилі 2 — `mode:"standard"`, `prompt`: «Split into depth layers for a 3D diorama: sky with clouds, distant skyline with the twin domed clock towers, middle city blocks, streets far below, the near neighbouring skyscraper edge, the rooftop parapet and water tower in the foreground.»

## Повторне використання — екран вибору (Б1, santos-va/nooneisreal#11)

Панорама M2-A, шари M2-B/C, перехожі, машини, пара — ті самі, без нових кредитів. Нове для Б1 (пози «стоїть на даху»
×2, іконки скілів) — у кошторисі В2, коли до нього дійде черга.

## Журнал запусків

Хвиля 1 ([[2026-10-03-Generation-Waves]] § Х1, santos-va/nooneisreal#14) — усі 12 зображень, не лише меню, щоб журнал був один.
`balance` до → **6010**, після → **5971**, різниця **39** = кошторис (`get_cost` перед запуском: 2.75 / 2.75 / 4.25 за шт.).
Модель `gpt_image_2_5` high (у `show_generation_by_ids` — `model: flare`); роль референса `image_references` сервер привів до `image`.
Референси: 1a — `card-choko-v3` `87a54896-…`; 1b — `bg_kronshift_river.jpg` → `media_import_url` raw-GitHub → `8e7345cb-24be-46a6-b876-d1b1f5e6c420`
(шлях (а) `media_upload` + PUT із хмари: `upload.higgsfield.ai` → `CONNECT tunnel failed, response 403`); 1c — місто `59110bbd-…`.
Піксельні розміри (застереження 10 закрите): 2k 16:9 = 2688×1520, **2k 21:9 = 2688×1152**, 4k 21:9 = 3840×1648.
Стиль за чек-листом [[Style-Guide]] **не перевірено** — CDN із хмари закритий (застереження 11), картинки бачить лише Santos у віджеті.

| дата | партія | job-id | розмір · CDN-URL | результат |
|---|---|---|---|---|
| 2026-10-03 | 1a `choko-sheet-v1` · v1 | `f21298f4-515d-4120-b0e7-872339de695a` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005206_f21298f4-515d-4120-b0e7-872339de695a.png | **переможець** (Santos: галерея № 0) |
| 2026-10-03 | 1a `choko-sheet-v1` · v2 | `acbfa81a-284f-4426-ad87-3b0075dbac00` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005205_acbfa81a-284f-4426-ad87-3b0075dbac00.png | не обрано |
| 2026-10-03 | 1a `choko-sheet-v1` · v3 | `eeffc2e0-745c-494e-80b5-1bba2455fcaf` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005204_eeffc2e0-745c-494e-80b5-1bba2455fcaf.png | не обрано |
| 2026-10-03 | 1a `choko-sheet-v1` · v4 | `392c6101-eaf2-4da2-bf2a-7168a734d233` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005205_392c6101-eaf2-4da2-bf2a-7168a734d233.png | не обрано |
| 2026-10-03 | 1b `stage-river-plate-v1` · v1 | `a2913501-694d-4bbc-9908-66892760bf7e` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005206_a2913501-694d-4bbc-9908-66892760bf7e.png | **переможець** (Santos: галерея № 4) |
| 2026-10-03 | 1b `stage-river-plate-v1` · v2 | `6c0a40e1-398d-4b22-ae4b-087006644dff` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005206_6c0a40e1-398d-4b22-ae4b-087006644dff.png | не обрано |
| 2026-10-03 | 1b `stage-river-plate-v1` · v3 | `7fcf598e-01b4-4b7f-b18f-2fd20e41eb0d` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005204_7fcf598e-01b4-4b7f-b18f-2fd20e41eb0d.png | не обрано |
| 2026-10-03 | 1b `stage-river-plate-v1` · v4 | `806a4f16-141f-4bac-a7b0-14811e40d7c5` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005206_806a4f16-141f-4bac-a7b0-14811e40d7c5.png | не обрано |
| 2026-10-03 | 1c M2-A `menu-skyline-plate-v1` · v1 | `73ee9806-ca24-4dcc-965f-848941e01fe7` | 3840×1648 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005204_73ee9806-ca24-4dcc-965f-848941e01fe7.png | **переможець** (Santos: галерея № 8) |
| 2026-10-03 | 1c M2-A `menu-skyline-plate-v1` · v2 | `b4df3f33-4afe-4e0a-b430-4d7c5a635da5` | 3840×1648 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005205_b4df3f33-4afe-4e0a-b430-4d7c5a635da5.png | не обрано |
| 2026-10-03 | 1c M2-A `menu-skyline-plate-v1` · v3 | `62038161-9911-4a55-81c3-03de63fea3ea` | 3840×1648 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005205_62038161-9911-4a55-81c3-03de63fea3ea.png | не обрано |
| 2026-10-03 | 1c M2-A `menu-skyline-plate-v1` · v4 | `1992adf3-5099-429d-b001-390152ba70a4` | 3840×1648 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_005205_1992adf3-5099-429d-b001-390152ba70a4.png | не обрано |

### Хвиля 2 (2026-10-03, [[2026-10-03-Generation-Waves]] § Х2, santos-va/nooneisreal#14, #19)

Слово Santos: «усі партії 2a–2k однією сесією, стеля 135 кредитів». Переможці хвилі 1 посилання `higgsfield.ai/s/…`
з хмари не розв'язали (`curl` → 000; `show_generations` кодів посилань не містить) — Santos назвав номери з галереї:
**1a = 0 `f21298f4`, 1b = 4 `a2913501`, 1c = 8 `73ee9806`**; канон Skea 2a — **2 `9c0b4476`**.
Референси імпортовано (`media_import_url` raw-GitHub, 0 кр.): `card_skea_v1.jpg` → `4cf75fc8-7484-4298-bb5e-a2884f6ea964`,
`weapons_choko_ultimate.png` → `d41babe1-6fc4-4c6a-8822-7264f5aa8454`.

`get_cost` перед партіями (за шт., = план): gpt_image_2_5 high 2k 16:9/21:9, з референсом і transparent — 2.75 ·
nano_banana_pro 2k 3:4 і 1:1 — 2 · image_decompose — 2 · flux_2_pro_outpaint 2688×1152 +512/+512 — 3.96, +256/+256 — 3.52.

| партія | `balance` до | після | різниця |
|---|---|---|---|
| 2a лист Skea ×4 | 5971 | 5960 | 11 |
| 2b turnaround Choko ×2 | 5960 | 5954.5 | 5.5 |
| 2c T-pose Choko ×4 | 5954.5 | 5946.5 | 8 |
| 2d предмети Choko ×4 | 5946.5 | 5935.5 | 11 |
| 2b turnaround Skea ×2 | 5935.5 | 5930 | 5.5 |
| 2c T-pose Skea ×4 | 5930 | 5922 | 8 |
| 2d предмети Skea ×4 | 5922 | 5911 | 11 |
| 2e тайли води ×2 | 5911 | 5907 | 4 |
| 2e outpaint річки | 5907 | 5907 | 0 — **422 ×5, не згенеровано** |
| 2e decompose річки | 5907 | 5905 | 2 |
| 2f передній план ×2 + decompose меню | 5905 | 5897.5 | 7.5 |
| 2g проба перехожого `worker` | 5897.5 | 5894.75 | 2.75 |
| 2h машини ×2 + пара ×2 | 5894.75 | 5883.75 | 11 |
| 2i пропси-якорі ×4 | 5883.75 | 5872.75 | 11 |
| 2j дрон ×4 | 5872.75 | 5861.75 | 11 |
| 2k картки глибини ×2 | 5861.75 | 5856.25 | 5.5 |
| **Разом** | **5971** | **5856.25** | **114.75** (стеля 135) |

Відхилення й факти (R0):
- **Outpaint (2e, M2-D) не пройшов:** `generate_image` / `generate_image_batch` → `422 Unprocessable Entity` на +512/+512 і +256/+256,
  з `input_width/height` і без, роль `image_references` і `image` (5 спроб; без `prompt` — «prompt is required»). `get_cost` при цьому працює. Кредити не списано.
- **Decompose потребує `prompt`** (інакше «prompt is required for Image Decompose»), але в збереженій генерації `prompt:""`;
  обидва decompose `completed`, проте **URL шарів не повертає жоден інструмент** (`jobs_wait`, `show_generation_by_ids`, `job_display`, `show_generations`) — Santos бачить шари лише в галереї Higgsfield.
- **T-pose і тайли:** замовлено `nano_banana_pro`, сервер у результатах пише `model: nano_banana_2`; ціна 2 = `get_cost`. Розмір 3:4 2k = 1792×2400, 1:1 2k = 2048×2048.
- Стиль, петлю ходи (2g), відсутність літер на білборді (2i) **не перевірено мною**: CDN із хмари закритий, картинки бачить лише Santos.
- Моя помилка в сесії: перший `media_import_url` ульт-мечів пішов на вигаданий хвіст UUID (403, 0 кр.); повторено зі справжнього файла в репо.

| № | партія · варіант | job-id | розмір · CDN-URL | результат |
|---|---|---|---|---|
| 0 | 2a `skea-sheet-v1` · v1 | `2c1ee808-b456-4edf-92d6-ef8b1e02af37` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012249_2c1ee808-b456-4edf-92d6-ef8b1e02af37.png | не обрано |
| 1 | 2a `skea-sheet-v1` · v2 | `cb13b1a6-c70c-4436-a395-dca98a0088a3` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012248_cb13b1a6-c70c-4436-a395-dca98a0088a3.png | не обрано |
| 2 | 2a `skea-sheet-v1` · v3 | `9c0b4476-966b-48ae-bfb8-2d8841bec089` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012248_9c0b4476-966b-48ae-bfb8-2d8841bec089.png | **канон** (Santos: галерея № 2) |
| 3 | 2a `skea-sheet-v1` · v4 | `2ac654ed-cb81-453b-90d5-80d4823b2d46` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012249_2ac654ed-cb81-453b-90d5-80d4823b2d46.png | не обрано |
| 4 | 2b `choko-turn-v1` · v1 | `051d4752-b0d3-4a26-aaef-5d2e23dd1c4a` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012311_051d4752-b0d3-4a26-aaef-5d2e23dd1c4a.png | чекає вибору Santos |
| 5 | 2b `choko-turn-v1` · v2 | `1fa22c1b-8d5a-4ddf-b4e3-17cf3ed89605` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012312_1fa22c1b-8d5a-4ddf-b4e3-17cf3ed89605.png | чекає вибору Santos |
| 6 | 2b `skea-turn-v1` · v1 | `e6929d03-e058-4567-817b-feb97fadf5d1` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013047_e6929d03-e058-4567-817b-feb97fadf5d1.png | чекає вибору Santos |
| 7 | 2b `skea-turn-v1` · v2 | `58f56291-a110-4a59-805a-563052c3757d` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013047_58f56291-a110-4a59-805a-563052c3757d.png | чекає вибору Santos |
| 8 | 2c `choko-tpose` · front | `c280d939-8332-4887-9862-a56893a6c5d3` | 1792×2400 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012338_c280d939-8332-4887-9862-a56893a6c5d3.png | чекає вибору Santos |
| 9 | 2c `choko-tpose` · side | `822b889d-c3e3-4394-acff-119ee99aeab2` | 1792×2400 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012338_822b889d-c3e3-4394-acff-119ee99aeab2.png | чекає вибору Santos |
| 10 | 2c `choko-tpose` · back | `f0763795-0ef7-4c4b-a0e3-06dc6e42735b` | 1792×2400 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012338_f0763795-0ef7-4c4b-a0e3-06dc6e42735b.png | чекає вибору Santos |
| 11 | 2c `choko-tpose` · 34 | `cbaf6f58-0594-43b2-a6ad-437ea58486e7` | 1792×2400 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012338_cbaf6f58-0594-43b2-a6ad-437ea58486e7.png | чекає вибору Santos |
| 12 | 2c `skea-tpose` · front | `efb93ee1-5602-4686-ae4b-f9258a9c8e9a` | 1792×2400 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013112_efb93ee1-5602-4686-ae4b-f9258a9c8e9a.png | чекає вибору Santos |
| 13 | 2c `skea-tpose` · side | `a596463b-7f3c-4827-bb2b-2abc0d52c04c` | 1792×2400 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013112_a596463b-7f3c-4827-bb2b-2abc0d52c04c.png | чекає вибору Santos |
| 14 | 2c `skea-tpose` · back | `1d611f5b-e104-4707-b5a9-45a4af3cdffb` | 1792×2400 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013113_1d611f5b-e104-4707-b5a9-45a4af3cdffb.png | чекає вибору Santos |
| 15 | 2c `skea-tpose` · 34 | `78951fe0-3c7f-4d36-9e57-249ab9141e38` | 1792×2400 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013112_78951fe0-3c7f-4d36-9e57-249ab9141e38.png | чекає вибору Santos |
| 16 | 2d `choko-item` · sword | `07225208-8944-4359-8d3e-236b77ab3567` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012412_07225208-8944-4359-8d3e-236b77ab3567.png | чекає вибору Santos |
| 17 | 2d `choko-item` · ult-sword | `e212477a-a758-4a3e-b976-b5f4ce561350` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012412_e212477a-a758-4a3e-b976-b5f4ce561350.png | чекає вибору Santos |
| 18 | 2d `choko-item` · watch | `cecf569d-47f2-4e78-b757-8d9eb633b046` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012412_cecf569d-47f2-4e78-b757-8d9eb633b046.png | чекає вибору Santos |
| 19 | 2d `choko-item` · jacket | `4b792412-45c1-40b2-a1d2-f5bdcfc8fc2e` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_012412_4b792412-45c1-40b2-a1d2-f5bdcfc8fc2e.png | чекає вибору Santos |
| 20 | 2d `skea-item` · kunai | `68218084-7494-402e-861d-c5f4819506d7` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013135_68218084-7494-402e-861d-c5f4819506d7.png | чекає вибору Santos |
| 21 | 2d `skea-item` · grimoire | `d65011c3-36c5-48d2-bdfe-1cf01d2b66dd` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013135_d65011c3-36c5-48d2-bdfe-1cf01d2b66dd.png | чекає вибору Santos |
| 22 | 2d `skea-item` · backpack | `14c45bff-1045-49e3-81e4-601398f322ab` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013134_14c45bff-1045-49e3-81e4-601398f322ab.png | чекає вибору Santos |
| 23 | 2d `skea-item` · hoodie | `28d02e0f-b70e-4992-b658-51189bbed263` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013135_28d02e0f-b70e-4992-b658-51189bbed263.png | чекає вибору Santos |
| 24 | 2e `tex-water` · foam | `b0a9189d-0b0a-435f-b5a5-459b105374ce` | 2048×2048 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013154_b0a9189d-0b0a-435f-b5a5-459b105374ce.png | чекає вибору Santos |
| 25 | 2e `tex-water` · ripple | `bb5e3e44-27c1-478c-9b2d-2252bf2e9339` | 2048×2048 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013154_bb5e3e44-27c1-478c-9b2d-2252bf2e9339.png | чекає вибору Santos |
| 26 | 2e `stage-river-layers` · decompose standard | `bc9d78b2-7241-4167-a16b-c78cd5200d56` | — · URL шарів інструменти не повертають | чекає вибору Santos |
| 27 | 2f `menu-roof-edge-v1` · v1 | `f500c1cf-46e3-4931-a83e-8cda14c5fdd2` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013309_f500c1cf-46e3-4931-a83e-8cda14c5fdd2.png | чекає вибору Santos |
| 28 | 2f `menu-roof-edge-v1` · v2 | `af419cb5-32e7-48b1-8527-7fdf361756ac` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013309_af419cb5-32e7-48b1-8527-7fdf361756ac.png | чекає вибору Santos |
| 29 | 2f `menu-skyline-layers` · decompose standard | `9fe905f1-0b7a-4d67-896e-7b9269fc3fa2` | — · URL шарів інструменти не повертають | чекає вибору Santos |
| 30 | 2g `sprite-pedestrian-worker-walk` · проба | `cc4637e4-da18-48d9-90b0-45ca3e8c3941` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013319_cc4637e4-da18-48d9-90b0-45ca3e8c3941.png | чекає вибору Santos |
| 31 | 2h `sprite-steamcar-a/b` · v1 | `4603954f-5b46-4067-826c-43788b9d8b79` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013335_4603954f-5b46-4067-826c-43788b9d8b79.png | чекає вибору Santos |
| 32 | 2h `sprite-steamcar-a/b` · v2 | `2f8837ee-4d7d-4e20-8b5e-86044538ffd1` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013335_2f8837ee-4d7d-4e20-8b5e-86044538ffd1.png | чекає вибору Santos |
| 33 | 2h `vfx-steam-puff` · v1 | `bd9797c1-11f4-4ef3-9e32-a26aef2dc1ca` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013334_bd9797c1-11f4-4ef3-9e32-a26aef2dc1ca.png | чекає вибору Santos |
| 34 | 2h `vfx-steam-puff` · v2 | `0fb87128-7f6e-4746-a9d6-c046618a1034` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013335_0fb87128-7f6e-4746-a9d6-c046618a1034.png | чекає вибору Santos |
| 35 | 2i `props-anchors-v1` · v1 | `74200113-20d7-4507-9bea-c493e3d4aacc` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013416_74200113-20d7-4507-9bea-c493e3d4aacc.png | чекає вибору Santos |
| 36 | 2i `props-anchors-v1` · v2 | `f7528c35-3939-4ffd-b1d0-c32956f9f1f4` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013415_f7528c35-3939-4ffd-b1d0-c32956f9f1f4.png | чекає вибору Santos |
| 37 | 2i `props-anchors-v1` · v3 | `b0ecfbc6-47fb-45e8-bf79-5d2eb1aeafca` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013415_b0ecfbc6-47fb-45e8-bf79-5d2eb1aeafca.png | чекає вибору Santos |
| 38 | 2i `props-anchors-v1` · v4 | `c5900952-f4f0-4728-8ada-5b30d641be3a` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013416_c5900952-f4f0-4728-8ada-5b30d641be3a.png | чекає вибору Santos |
| 39 | 2j `drone-heavy-v1` · v1 | `e9fd9e33-beaa-43b7-8e1c-573c12691253` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013436_e9fd9e33-beaa-43b7-8e1c-573c12691253.png | чекає вибору Santos |
| 40 | 2j `drone-heavy-v1` · v2 | `84113d16-906e-4cd3-99c1-eabc30c46077` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013437_84113d16-906e-4cd3-99c1-eabc30c46077.png | чекає вибору Santos |
| 41 | 2j `drone-heavy-v1` · v3 | `148ff101-872e-4274-bc78-4d6934414e06` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013437_148ff101-872e-4274-bc78-4d6934414e06.png | чекає вибору Santos |
| 42 | 2j `drone-heavy-v1` · v4 | `88a358da-1306-44d1-9dd8-0963025fc403` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013437_88a358da-1306-44d1-9dd8-0963025fc403.png | чекає вибору Santos |
| 43 | 2k `menu-depth-cards-v1` · v1 | `08c09625-7766-4984-81c8-f03d9bae618f` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013449_08c09625-7766-4984-81c8-f03d9bae618f.png | чекає вибору Santos |
| 44 | 2k `menu-depth-cards-v1` · v2 | `134a6b14-a16c-48cc-9912-cf833230da72` | 2688×1152 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_013448_134a6b14-a16c-48cc-9912-cf833230da72.png | чекає вибору Santos |

### Skea v2 (2026-10-03, santos-va/nooneisreal#33, [[2026-10-03-Skea-Redesign]] S2 + S2b)

Слово Santos: «лист Skea ×4 + лист облич ×2 + картка рюкзака ×2 (вісімка лише ззаду), до 25 кредитів». Промпти —
[[Prompt-Library]] § 12. Референси всіх 8: лист Choko `f21298f4` (манера) + стара картка Skea `4cf75fc8`
(= `card_skea_v1.jpg`, імпорт raw-GitHub у хвилі 2). У картці рюкзака `{NEG_SKEA}` не додавався (предмет, не обличчя).
`get_cost` gpt_image_2_5 high 2k 16:9 з двома референсами → 2.75 за шт.

| партія | `balance` до | після | різниця |
|---|---|---|---|
| S2a лист Skea v2 ×4 | 5856.25 | 5845.25 | 11 |
| S2a лист облич ×2 | 5845.25 | 5839.75 | 5.5 |
| S2b картка рюкзака ×2 | 5839.75 | 5834.25 | 5.5 |
| **Разом** | **5856.25** | **5834.25** | **22** (стеля 25) |

8 робіт `completed`, 0 failed. Стиль, вік, посмішку і місце вісімки **не перевірено мною** — CDN із хмари закритий.

| № | партія · варіант | job-id | розмір · CDN-URL | результат |
|---|---|---|---|---|
| 0 | S2a `skea-sheet-v2` · v1 | `9190fcfa-46f2-41c2-918e-6d871c68ec98` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_014952_9190fcfa-46f2-41c2-918e-6d871c68ec98.png | чекає вибору Santos |
| 1 | S2a `skea-sheet-v2` · v2 | `dcdef91d-396f-4334-875b-035b07452457` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_014953_dcdef91d-396f-4334-875b-035b07452457.png | чекає вибору Santos |
| 2 | S2a `skea-sheet-v2` · v3 | `d56e2671-ba09-4766-8d1a-b04087e1cb14` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_014952_d56e2671-ba09-4766-8d1a-b04087e1cb14.png | чекає вибору Santos |
| 3 | S2a `skea-sheet-v2` · v4 | `ca895e35-1d8d-4851-9a0e-42b58f72b029` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_014954_ca895e35-1d8d-4851-9a0e-42b58f72b029.png | чекає вибору Santos |
| 4 | S2a `skea-faces-v1` · v1 | `f4a48750-2e45-4709-a7ff-066452179e15` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_015024_f4a48750-2e45-4709-a7ff-066452179e15.png | чекає вибору Santos |
| 5 | S2a `skea-faces-v1` · v2 | `36ace5cf-6698-45d7-bc08-9fdc49737ff1` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_015023_36ace5cf-6698-45d7-bc08-9fdc49737ff1.png | чекає вибору Santos |
| 6 | S2b `skea-item-backpack-v2` · v1 | `84849343-bdbe-46b5-83f5-ae95b0994f8a` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_015043_84849343-bdbe-46b5-83f5-ae95b0994f8a.png | чекає вибору Santos |
| 7 | S2b `skea-item-backpack-v2` · v2 | `241dd472-ac05-46f7-8f96-e7f577349973` | 2688×1520 · https://d8j0ntlcm91z4.cloudfront.net/user_3K9iQemvOo6IqNE4zXhvuukTwKO/hf_20261003_015042_241dd472-ac05-46f7-8f96-e7f577349973.png | чекає вибору Santos |

## Related
- [[2026-10-03-Main-Menu-Skyline]] · [[Asset-Manifest]] · [[Prompt-Library]] · [[Style-Guide]] · [[Higgsfield-Pipeline]] · [[Textures-Registry]] · [[ADR-010-City-Name-Cronshift]] · [[04-Grapple-System]] · [[Kronshift]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[ADR-012-Menu-As-3D-Diorama]] · [[2026-10-03-Wave-2]] · [[2026-10-03-Skea-Redesign]]
