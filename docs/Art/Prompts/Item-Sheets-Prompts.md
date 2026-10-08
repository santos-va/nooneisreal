# Аркуші предметів — їжа, вода, алкоголь, тютюн, листки (промпти; хвилі 1 і 2 запущені, відібрані)

**Роль:** T6 Аполлон, 2026-10-08 · **Слово Santos (2026-10-08):** «Давай ше паралельно промалюємо добре косяки бонги
алкашку сигарети й воду. Додатково треба й корисні продукти що дають вітаміни або протеїнові для мʼязів». ·
**Рішення, аудит і критерії:** [[2026-10-08-Substances-And-Food-Items]] · **Стиль:** [[Style-Guide]].
**Статус:** хвиля 1 (R1a, R1b) запущена T1 2026-10-08. T6 прийняв обидва аркуші як ключ стилю й обрав **R1a** як
`{REF_SET}` (§ Відбір R1). Хвилю 2 (R2–R5) T1 запустив того ж дня, 4 зображення. Відбір T6 — § Відбір хвилі 2. Вирізки лежать
лише в scratchpad головної сесії, у `game/assets/` нічого не перенесено. Повторів використано 0 з 2. Кредити витрачає T1 у
головній сесії: `balance` → `get_cost` на кожну конфігурацію нижче → слово Santos на конкретне число зображень → генерація.
Назви предметів — PLACEHOLDER до T7.

## Модель і параметри (перевірено `models_explore get gpt_image_2_5` 2026-10-08)

| параметр | значення | чому |
|---|---|---|
| модель | `gpt_image_2_5` | має `background: transparent` і `image_references`; на ній зроблено 6 іконок HUD і 2 портрети в `game/assets/ui/` ([[HUD-Skill-Icons-Prompts]]), пропи § 10–11 і VFX ([[Prompt-Library]], [[VFX-Sheets-Prompts]]) |
| `quality` | `high` | як у прецедентах; `xhigh` / `max` тепер існують, але їхню ціну й різницю не перевіряв |
| `variant` | не задавати (типово `flare`) | прецеденти запускались до появи параметра; `sunburst` не пробувався |
| `resolution` | `2k` | клітинка 4 × 2 на 2k 16:9 ≈ 672 × 760 px, тобто після обрізки ≥ 512 px — як іконки HUD |
| `aspect_ratio` | `16:9` | 4 × 2 клітинки на кожному аркуші |
| `background` | `transparent` | вирізка за альфою без `remove_background` |
| сід | **параметра немає** | у `models_explore get` лише `variant`, `quality`, `resolution`, `background`. Консистентність тримають однакові блоки байт-у-байт і референс-аркуш (хвиля 2) |
| `count` | 1 на конфігурацію; 2 лише для R1 (a/b) | 1 результат на слот, решта в репо не йде |

**Ціна — не факт сьогодні.** Остання звірка `get_cost` для `gpt_image_2_5` high 2k — 2.75 за зображення
([[Higgsfield-Pipeline]] § Ціни, 2026-10-03). Відтоді в моделі з'явились `variant` і `quality` до `max`. T1 запускає
`get_cost` на кожну конфігурацію: без референсу (R1a) і з одним референсом (R1b, R2–R5).
**2026-10-08, хвиля 1:** T1 — `get_cost` 2.75 для обох конфігурацій (без рефу й з одним рефом). Узгоджено з `balance`
(T6, sub-agent): 3808 до запуску (T1) → **3802.5** після, тобто 2 × 2.75. R2–R5 мають ту саму конфігурацію, що й R1b
(один реф). T1 звіряє `get_cost` ще раз перед хвилею 2.
**2026-10-08, хвиля 2:** T1 — `get_cost` 2.75 на кожен із 4 запусків, `balance` 3802.5 → 3791.5. T6 (sub-agent) викликав
`balance` → **3791.5**, план ultra. 3802.5 − 4 × 2.75 = 3791.5, тобто збігається.

## Блоки (англійською, байт-у-байт)

**`{ITEM_STYLE}`** — виведено з префікса пропів § 10–11 [[Prompt-Library]]. Персонажних ознак (`{STYLE}`: голова 1/5,
зіниці, волосся) тут немає, бо людей на аркуші немає.

```
Item sheet for a video game, hand-drawn in a loose expressive western animation sketch style, not anime: lively plum-graphite (#2B2230) inked lines with small line breaks, thicker outer contour and thinner inner lines, flat muted base colors with a single cel shadow tone hue-shifted toward magenta-violet, almost no highlights, no gradients, no gloss, no 3D render look. Ordinary everyday goods of the old European-industrial city of Cronshift: worn, handmade, slightly imperfect, in a muted dusk palette of terracotta, ochre, slate blue, deep teal, cream and dull brass; nothing saturated. Glass is drawn as a flat pale tint with a clear liquid level line, without reflections.
```

**`{GRID_8}`**

```
Eight separate objects in two rows of four, evenly spaced, each object alone in its own cell with a generous empty margin, all drawn at a similar size so that each one reads as a game icon at 64 pixels: one clear closed silhouette per object, objects never touch or overlap, no shadows on the ground. Fully transparent background.
```

**`{NEG_ITEM}`** — у кожному аркуші.

```
No people, no hands, no faces, no characters, no animals, no text, no letters, no numbers, no writing on labels, no brand names, no logos, no trademarks, no watermark, no price tags, no frames, no circle or square badges behind the objects, no bright crimson or blood-red color anywhere, no glow, no sparkles, no glossy reflections, no advertising or product-photo look, no studio lighting, no modern plastic packaging.
```

«No bright crimson» стоїть навмисно: К1 `#A3243B` і `#711126` — лише кров у смертельному бою ([[Style-Guide]] § Колір).
Червоні продукти (яблуко, ковбаса, вино) мають бути цеглясто-приглушеними, як `cloth_red` `#98685E` ящика яблук у «Шавлії».

**`{NEG_PLAIN}`** — додатково в S4 і S5 (алкоголь, тютюн, листки). Заборона гламуру й показу вживання
([[2026-10-08-Substances-And-Food-Items]] § Заборони).

```
Shown plain and unglamorous, as ordinary worn objects lying unused: nothing lit, no burning tips, no smoke, no smoke rings, no ice, no condensation drops, no splashes, no pouring, no toasting glasses, no luxury or premium look, no gold, no wax seals or crests, no stylish or cool presentation, nobody using anything.
```

**`{REF_RIVER}`** — лише R1b. Референс — канон річки `a2913501-694d-4bbc-9908-66892760bf7e` (повний UUID з [[Prompt-Library]]
§ 18; той самий, що в пропах § 10–11). Зображення в цьому акаунті T1 перевіряє до запуску.

```
Take only the line work, the shadow color and the muted dusk palette of the reference image; it shows a city, not these objects, and nothing from it is drawn on this sheet.
```

**`{REF_SET}`** — R2–R5. Референс — **обраний** аркуш R1: **R1a, job `55ccd85c-bd41-492b-afc6-b299d6eb969e`**
(вибір T6 2026-10-08, причини — § Відбір R1). Текст блоку не змінено.

```
Take the line work, line thickness, shadow color, palette and object size of the reference image exactly; it is an earlier sheet of the same set of game items, so do not copy its objects.
```

Формула: `{ITEM_STYLE} {GRID} Objects, left to right, top row then bottom row: {SLOTS} {REF} {NEG_ITEM} {NEG_PLAIN}`.
Порожні блоки пропускаються разом із пробілом.

## Аркуші (слоти англійською)

### S1 — «Шавлія»: те, що вже продається, і пиріг (`sheet-items-grocer-v1`)

`{GRID_8}`. Клітинки 1–3 збігаються з чинним меню `CityHunger.gd:48–51` (робоче дерево, не закомічено), 4–8 —
з [[PROPOSAL-Food-Of-Cronshift]] § 3.

```
1) a heavy clay mug of hot sage tea, the brew a muted green-brown, two short inked curls of steam above it; 2) an oblong loaf of dark rye bread with a cracked crust, three shallow cuts on top and a dusting of flour; 3) one thick end slice of the same rye bread, the crumb dense and grey-brown; 4) a round homemade cabbage pie with a braided ochre rim, one wedge cut out showing the pale green filling; 5) a muted brick-red apple with a short stem and one leaf; 6) a pale sage-green apple with a short stem; 7) a small travel bundle of cream cloth tied at the top with twine, a rusk, a corner of cheese and an apple peeking out; 8) a bundle of dried sage sprigs tied with twine.
```

### Звірка з T7

Слоти S2–S5 вирівняно за колонкою «для T6» з [[PROPOSAL-Substances-And-Healthy-Food]] § 4. Цей файл T7 з'явився під
час моєї сесії; він **[P], не канон** і ще не в git. Якщо Santos змінить предмет, слот правиться **до** запуску. Де я
від T7 відступаю, сказано біля слота; причини — в [[2026-10-08-Substances-And-Food-Items]] § Відкрите.

### S2 — вітаміни (`sheet-items-vitamins-v1`)

`{GRID_8}` + `{REF_SET}`. Клітинки 4–7 — позиції T7 § 4.2, 8 — ятка Д1 з [[PROPOSAL-Food-Of-Cronshift]] § 6. Червоні
ягоди (шипшина, журавлина) — цегляно-приглушені, не К1.

```
1) a ripe pear, ochre-yellow with a muted rosy side; 2) a bunch of three carrots with leafy tops, tied with twine; 3) a whole head of green cabbage with loose outer leaves; 4) a small linen pouch of dried rosehips, a few muted brick-red hips spilled beside it; 5) a small wooden tub of pickled apples under a round wooden pressing board with a stone on top; 6) a terracotta pot of sauerkraut with a few muted brick-red cranberries and a wooden fork stuck in it; 7) a clay jug of cold dried-fruit compote with a string of dried pear and plum slices hanging beside it; 8) a baked apple on a small clay plate, its skin wrinkled and darker.
```

### S3 — протеїн (`sheet-items-protein-v1`)

`{GRID_8}` + `{REF_SET}`. Клітинки 1–5 — T7 § 4.3, 6–8 — мої доповнення. Сучасних протеїнових банок і шейкерів немає
навмисно — обґрунтування в [[2026-10-08-Substances-And-Food-Items]] § Список предметів. Відступ від T7: сир **без**
ножа-лопатки, бо поруч з ножем В1 це другий клинок в іконці.

```
1) two boiled eggs in a small straw basket with a tiny twist of paper holding salt; 2) a round wheel of crumbly white sheep cheese with one wedge cut out; 3) a bundle of three small golden-brown smoked river fish tied on a string; 4) a clay bowl of thick bean soup with bits of onion, a slice of rye bread lying beside it; 5) a small crimped pastry pie with a pale cheese filling showing at the edge; 6) a ring of dark brown smoked sausage tied with string; 7) a glass bottle of milk with a cork stopper, the milk opaque cream-white; 8) a small enamel lunch pail with its lid ajar, meat broth visible inside, no steam.
```

**Правка 2026-10-08 після відбору R1 (клітинка 8).** Було: `…, hot meat broth inside, two short inked curls of steam.`
Стало: `…, meat broth visible inside, no steam.` Причина: пара на R1a і R1b — окремі завитки, що на іконці 32 px мають
ширину 1,3–3,6 px (§ Відбір R1). Це провал критерію 2: «відірвані шматки, менші за 2 px». До того ж чорнильна пара на
панелі діалогу `#090F14` не видна вже на 64 px. Слово `hot` прибрано, бо воно саме кличе пару. Інших слотів хвилі 2 з
парою немає.

### S4 — вода, квас і алкоголь (`sheet-items-drinks-v1`)

`{GRID_8}` + `{REF_SET}` + `{NEG_PLAIN}`. Клітинки — T7 § 4.1 і § 4.4. Вода: ковш, кухоль без піни, фляга. Алкоголь:
кухоль із металевим обідком і шапкою піни, четвертинка, чарка. Квас T7 дає в «тому самому кухлі», тож в іконці його
відрізняє лише відсутність піни й колір; назву несе рядок меню (T7 § 2). Вино «майже графітове» — темна слива, не К1.

```
1) an iron ladle of clear water with a short chain hanging from its handle; 2) a glazed clay mug filled with clear water, no foam; 3) a tin water flask in a grey felt cover with a small brass cap on a chain; 4) a tall stoneware beer mug with a metal rim, dark beer inside and a thick head of foam; 5) the same stoneware mug with a metal rim filled with brown kvass, no foam; 6) a small flat quarter-size bottle without any label, filled with almost graphite-dark plum wine, with a cork; 7) a small thick shot glass of clear rye spirit standing beside a small clay jug with a cork; 8) a small wooden barrel lying on a stand with a brass tap.
```

### S5 — тютюн, самокрутка, «булька», листки події (`sheet-items-smoke-v1`)

`{GRID_8}` + `{REF_SET}` + `{NEG_PLAIN}`. Клітинки 1–6 — T7 § 4.5 і § 4.6. Відступ від T7: пачка «Рейка» **без** назви й
номера на арті, бо генерацій з текстом у нас немає ([[Style-Guide]] § Чого уникати). Назва живе лише в тексті гри.
Газетний папір самокрутки — сіра штриховка замість друку, без літер.

Клітинки 7–8 — альфа-картка для кільця листків (`CityPasserby.gd:100–158`): плоско, без перспективи, стебло внизу по
центру, вершина вгорі — як `leaf_mesh`. Колір листка — чинний `LEAF_FILL` `#8E9A86` (`CityPasserby.gd:12`), тінь виведена
правилом [[Style-Guide]]: `#8E9A86` × `#B07AA6` = `#624A57` (python у цій сесії). Чинний код має сіру тінь `#6F7A6A`
(`:13`); розбіжність винесено в [[2026-10-08-Substances-And-Food-Items]] § Відкрите.

```
1) a plain flat grey paper cigarette pack, slightly worn at the corners, closed, with one small empty stamped rectangle and no writing at all; 2) a single unlit thin cigarette of plain grey paper without a filter; 3) a small matchbox with a dark striking strip on its side, slightly open, a few matches visible; 4) a small paper cone of dark shredded loose tobacco next to a short plain wooden pipe; 5) a single unlit hand-rolled cigarette made of greyish newsprint paper shown only as faint illegible grey hatching, thicker than a cigarette, uneven, with a torn ragged edge and a twisted end; 6) a homemade water pipe: a squat flask of thick greenish old lantern glass half full of water, a brass tube stuck through a cork, a strip of rag wrapped around the neck, no light inside; 7) one flat leaf drawn perfectly flat with no perspective, seen straight from the front, stem at the bottom center: seven narrow lance-shaped leaflets with finely serrated edges fanned from a short stem, the middle leaflet longest and the outer ones shortest, muted grey-green (#8E9A86) with one shadow tone (#624A57) along one side of each leaflet and a single thin vein line down each leaflet; 8) the same leaf, drawn flat from the front, with its leaflet tips slightly curled.
```

**Якщо провайдер відхилить S4 або S5** (фільтр безпеки — **не перевірено**): текст **не переписуємо**, щоб обійти
модерацію. Відхилений аркуш → процедурний шлях (0 кр.) з [[2026-10-08-Substances-And-Food-Items]] § Вибір; запис у
журнал нижче.

### R6 — картка ножа В1 (опційно, **не рекомендую**)

Шаблон § 4 [[Prompt-Library]] (м'ятна плашка, назва — це лист-референс, не іконка). `{ITEM}`: `a cheap folding street
knife with a short clip-point blade of dull grey steel and a worn dark wooden handle with two brass rivets` ·
`{DETAILS}`: `the knife folded shut; the two handle rivets` · `{ITEM_TITLE}`: `KNIFE`. Хвіст після `{NEG}`:
`No blood, no red, no glow, no hands.` Чому не рекомендую: ніж 0,2 м у руці дає ≈ 28 px на 1080p з 6 м, тож
вирішує силует, а не мальована текстура. Силует T6 описує словами для процедурного ножа T2 (0 кр.) у документі рішення.

## Запуски

| # | аркуш | блоки | референс | зображень | хвиля |
|---|---|---|---|---|---|
| R1a | S1 | `{ITEM_STYLE} {GRID_8}` S1 `{NEG_ITEM}` | — | 1 | 1 |
| R1b | S1 | те саме + `{REF_RIVER}` | `a2913501-694d-4bbc-9908-66892760bf7e` | 1 | 1 |
| R2 | S2 | `{GRID_8}` + `{REF_SET}` | R1a `55ccd85c-bd41-492b-afc6-b299d6eb969e` | 1 | 2 |
| R3 | S3 | `{GRID_8}` + `{REF_SET}` | R1a `55ccd85c-bd41-492b-afc6-b299d6eb969e` | 1 | 2 |
| R4 | S4 | `{GRID_8}` + `{REF_SET}` + `{NEG_PLAIN}` | R1a `55ccd85c-bd41-492b-afc6-b299d6eb969e` | 1 | 2 |
| R5 | S5 | `{GRID_8}` + `{REF_SET}` + `{NEG_PLAIN}` | R1a `55ccd85c-bd41-492b-afc6-b299d6eb969e` | 1 | 2 |
| R6 | картка ножа | § 4 | — | 0 (опційно 1) | — |

Мінімум **6** зображень, стеля **8** (+2 повтори лише з рішення T6 з причиною в журналі). Хвиля 2 стартує після того,
як T6 прийняв R1 за критеріями документа рішення: інакше чотири аркуші успадкують невдалий стиль.
**Після відбору R1:** хвиля 2 — рівно **4** запуски (R2, R3, R4, R5), по 1 зображенню з одним референсом R1a. Повтор
R1 не потрібен, використано 0 з 2 повторів. Разом за проєктом буде 6 зображень.
**Факт 2026-10-08:** хвиля 2 запущена, 4 × 2.75. Разом 6 зображень, повторів 0 з 2. Чернетку повтору P1 подано в
§ Відбір хвилі 2. Запускати її зараз не треба.

## Відбір R1 (T6, 2026-10-08)

Аркуші T1 завантажив у scratchpad головної сесії: `r1a.png`, `r1b.png`, обидва 2688×1520 RGBA. `sha256sum` →
`5031ff22…f922a3` і `f46d6f55…9a5b4`, збігається з T1. Заміри зроблено на `python3 -I` з numpy 2.5.3 і Pillow 12.3.0
(скрипти в scratchpad, у репо їх немає). «Ядро» — пікселі з a ≥ 250; кільце d — шахова відстань від ядра в px.

| що | R1a | R1b | критерій |
|---|---|---|---|
| a = 0 · a = 255 · max a | 59,59 % · 0 px · 254 | 58,06 % · 0 px · 254 | 3 — альфу підняти вирізкою |
| шум a 1–2 (невидимий, плямами по всьому тлу) | 2,92 % | 3,97 % | — вирізка обнуляє |
| **ореол**: a 3–127 | 30 486 px (0,75 %) | 28 894 px (0,71 %) | «no glow» |
| частка a 1–200 у смузі d ≤ 6 px | 43,2 % (59 331 / 137 325) | 43,9 % (61 193 / 139 410) | — |
| середня a в кільцях d1…d6 · d12 | 238 · 177 · 95 · 46 · 27 · 18 · 3 | 236 · 166 · 88 · 41 · 21 · 13 · 1 | — |
| колір пікселів кільця d3–d12 | ≈ (59–66, 38–45, 48–51) — чорнило | ≈ (54–63, 35–42, 47–51) — чорнило | — |
| компоненти при a ≥ 128 | 10: 8 предметів по одному в клітинці + 2 завитки пари в клітинці 1; < 200 px — 0 | те саме | 8 ✓ |
| max(R,G,B) < 20, a ≥ 128 | 0,043 % | 0,040 % | 4 ✓ (< 1 %) |
| найтемніші 2 % (лінія) | (29, 12, 28) | (27, 11, 30) | 4 ✓ сливова, не нейтральна |
| тінь: (тінь/світло) B − G (зелене яблуко · червоне · кухоль) | +0,34 · +0,31 · +0,41 | +0,33 · +0,40 · +0,09 | 4 ✓ (правило `#B07AA6` дає +0,17, сіра тінь ≈ 0) |
| **кров**, евклід ≤ 30 від `#A3243B` / `#711126`, по іконках | лише кл. 5: 0 / 21 px | кл. 1: 0 / 2 · кл. 5: 822 / 34 · кл. 7: 115 / 12 | 4 (див. примітку) |
| те саме за Чебишовим (max по каналу ≤ 30), весь аркуш | 1,43 % / 2,55 % | 2,60 % / 2,45 % | — |
| S > 0,7 при V > 0,3 | кл. 4 (пиріг) 14,8 %, решта 0 | кл. 4 0,45 %, решта 0 | — у межах теракоти `#C8623A` (S 0,71) |
| відблиски | немає | світла пляма на обох яблуках | `{ITEM_STYLE}` «almost no highlights» |
| текст, псевдолітери, логотипи (100 % і 200 %) | немає | немає (на кухлі сколи, не знаки) | 5 ✓ |
| пара в кл. 1 на 32 px | завитки ≈ 3,6×6,5 і 1,6×3,5 px; над вінцем 11 px з a ≥ 64 | ≈ 1,4×6,0 і 1,3×4,3 px; 5 px з a ≥ 64 | **2 ✗** |

**Ореол** — це м'яке матування чорнильного контуру: хвіст кольору лінії з a ≤ 95 на відстані 3–12 px. Профіль майже
однаковий в обох запусках, хоча промпт і референс різні, а `no glow` у промпті вже є. Отже, це постобробка прозорого
тла провайдера, а не намальоване сяйво. Слова на кшталт «no halo, crisp alpha edge» в промпт хвилі 2 **не додаю**: з
цих двох замірів не видно, що текст на це впливає, а блоки мають лишатися байт-у-байт. Ореол прибирає вирізка (0 кр.):
**a < 128 → 0, a ≥ 250 → 255, між ними — лінійно.** Проба на всіх 16 клітинках: кути a = 0, max a = 255, частково
прозорих пікселів 4–6 тис. на іконку 512² (шавлія — 15–16 тис. через тонкі стебла). Хвіст a 3–127 зникає повністю.
Лишається край лінії a 128–249, переважно в кільцях d1–d2, — звичайне згладжування. Огляд ×4 краю яблука (кл. 5)
обох аркушів до й після вирізки на `#FFFFFF`, `#090F14` і `#183039`: після вирізки край чіткий. Інші краї не збільшував.

**Примітка до кров'яного порога.** У критерії 4 «ΔRGB ≤ 30» не визначено. Метрику уточнено **після** цього заміру,
тому в таблиці наведено обидва числа. Робоча метрика — евклідова відстань. За Чебишовим (max по каналу) поріг
провалює вже тінь теракоти зі [[Style-Guide]]: `#C8623A` × `#B07AA6` = (138, 47, 38), до `#711126` Чебишов = 30,
евклід = 39,1. Тобто така метрика забороняла б власну палітру міста.

**Читабельність.** Монтаж 32 / 48 / 64 / 96 / 128 px на панелі `#090F14`, кнопці `#183039` і плашці `#B8CBB1`, плюс
тест у сірому на 32 px. T6 назвав усі 8 предметів на 32 px в обох аркушах. Пари всередині S1 розрізняються:
червоне ↔ зелене яблуко (листок і тон), буханець ↔ окраєць (силует). Santos назви **не перевіряв** — критерій 1 для
нарізки лишається відкритим. Чай R1a читається краще: зелений відвар із листям видно на 32 px, у R1b рідина
оливкова й дрібна. Шавлія R1a має ліловаві колоски й може читатися як лаванда, шавлія R1b — ні.

**Клітинки як іконки** (критерії 1–8; 9 — після хвилі 2 і нарізки):

| кл. | слот | R1a | R1b |
|---|---|---|---|
| 1 | `sage_tea` | ✗ 2 (пара) | ✗ 2 (пара), ✗ 4 (2 px) |
| 2 | `rye_loaf` | ✓ | ✓ |
| 3 | `rye_crust` | ✓ | ✓ |
| 4 | `cabbage_pie` | ✓ (найнасиченіший) | ✓ |
| 5 | `apple_red` | ✗ 4 (21 px) | ✗ 4 (856 px) |
| 6 | `apple_green` | ✓ | ✓ (відблиск) |
| 7 | `travel_bundle` | ✓ | ✗ 4 (127 px) |
| 8 | `dried_sage` | ~~✓ (ризик «лаванди»)~~ **✗ 2** (корекція хвилі 2: на 32 px відривається шматок 1×1 px) | ✓ — **іде на слот** (§ Відбір хвилі 2) |

**Вердикт.**
- **R1a — ПРИЙНЯТО** як ключ стилю (лінія, тінь, палітра, сітка, без тексту) і як джерело 6 іконок. **Обрано
  `{REF_SET}`.** Головна причина — хвиля 2 має «червоні» слоти: шипшину, журавлину, ковбасу, сливове вино. R1a несе
  найменше кров'яних тонів: 21 px проти 985 сумарно в R1b. До того ж R1a пласкіший (без відблисків), і чай у ньому
  читається краще.
- **R1b — ПРИЙНЯТО як ключ стилю, не обрано.** За лінією й тінню він рівний R1a. Як іконки придатні 5 клітинок:
  2, 3, 4, 6, 8. Шавлія R1b — кандидат на слот `dried_sage`, якщо Santos прочитає шавлію R1a як лаванду. Правило
  «1 результат на 1 слот» застосовується під час нарізки.
- **Відкрите з R1:** іконки `sage_tea` без провалу немає в жодному аркуші, бо пару просив сам промпт S1 (моя помилка
  в слоті). Меню зараз текстове (рішення T8), тож це нічого не блокує. Коли T8 введе іконки, варіанти такі: повтор S1
  з чаєм без пари (1 з 2 повторів) або процедурна іконка. `apple_red` R1a провалює критерій 4, але слота-іконки для
  нього в грі немає.
- **Корекція (2026-10-08, під час відбору хвилі 2). Помилка T6 у цьому відборі.** Критерій 2 я перевіряв на компонентах
  повної роздільності, а не на самій іконці 32 px. Після рендеру в 32 px у R1a · кл. 8 (`dried_sage`) від стебел
  відривається шматок 1×1 px з a = 135. Це **✗ 2**. R1b · кл. 8 на 32/42/48/64 px лишається одним шматком, кров'яних
  пікселів 0. Тому на слот `dried_sage` іде **R1b · 8**, і заодно знімається ризик «лаванди» (§ Відкрите п. 14 документа
  рішення). R1a дає не 6 іконок, а **5**: кл. 2, 3, 4, 6, 7. Інші клітинки R1a/R1b цей тест не змінив, вони одним шматком
  на 32 px. Числа — § Відбір хвилі 2.

## Відбір хвилі 2 (T6, 2026-10-08)

**Звірка входу.**
- **Тексти.** Скрипт `prompt_check.py` склав промпти з блоків цього файлу за формулою й порівняв їх із `wave2_prompts.json`
  T1. Результат: R2 / R3 / R4 / R5 — `IDENTICAL` (2304 / 2286 / 2625 / 3246 символів).
- **Файли.** `curl` усіх шести CDN-URL (R1a, R1b, R2–R5) дав HTTP 200. `sha256sum` завантаженого збігається з файлами в
  scratchpad і з префіксами T1. Усі аркуші 2688×1520 RGBA.
- **Модерація.** Фільтр провайдера R4 і R5 не відхилив (T1: усі 4 completed), тож запасний шлях E не знадобився.

Метод той самий, що в § Відбір R1 (`python3 -I`, numpy 2.5.3, Pillow 12.3.0; скрипти в scratchpad `t6-wave2/`, у репо їх
немає). Додано два тести:
- шматки силуету на самій іконці, відрендереній у 32 px (a ≥ 128);
- кров'яні тони на вихідній роздільності аркуша, до LANCZOS.

| що | R2 · S2 | R3 · S3 | R4 · S4 | R5 · S5 |
|---|---|---|---|---|
| a = 0 · a = 255 · max a | 51,90 % · 0 · 254 | 51,37 % · 0 · 254 | 48,17 % · 0 · 254 | 61,16 % · 0 · 254 |
| ореол a 3–127 | 34 601 px (0,85 %) | 35 130 px (0,86 %) | 25 892 px (0,63 %) | 43 428 px (1,06 %) |
| середня a в кільцях d1…d6 · d12 | 241·191·124·69·36·19 · 3 | 242·196·125·63·29·14 · 1 | 231·133·59·19·5·1 · 0 | 240·189·112·54·24·11 · 1 |
| компоненти a ≥ 128; з них < 200 px | 9; 0. Кл. 4: ягоди окремою плямою | 8; 0 | 9; 0. Кл. 7: чарка окремо від глечика | 9; 0. Кл. 4: люлька окремо від кульку |
| найменший проміжок між клітинками | 37 px (2–6) | 41 px (3–7) | 108 px (1–5) | 107 px (7–8) |
| max(R,G,B) < 20, найгірша іконка | 0,023 % | 0,143 % | 0,208 % | 0,344 % |
| найтемніші 2 % (лінія), діапазон | (30–38, 12–15, 28–33) | (26–33, 5–6, 22–28) | (24–27, 1–3, 23–25) | (22–26, 4–5, 23–26) |

Після вирізки за критерієм 3 у всіх 48 вирізок обох хвиль кути a = 0 і max a = 255. 36 вирізок, покладених в `icons/`,
мають PNG colortype 6 і розмір 512×512 (перевірено `struct` по IHDR).

**Тінь.** На око скрізь маджента-лілова. Там, де предмет одного матеріалу і 2-means осмислений, B − G (тінь/світло) таке:
груша +0,27, капуста +0,13, кухоль пива +0,14, квасу +0,16, цигарка +0,11, сірники +0,13, листки +0,19 / +0,20. Правило
`#B07AA6` дає +0,17. Сіра тінь давала б ≈ 0.

**Кров'яні тони (критерій 4) — головна знахідка.** Евклід ≤ 30 від `#A3243B` / `#711126`. Колонки: пікселі іконки
(a ≥ 128) · пікселі аркуша · найбільша пляма в аркуші. Решта клітинок R2–R5 — 0 / 0.

| клітинка | іконка | аркуш | пляма | клас |
|---|---|---|---|---|
| R2 · 4 `rosehip` | 735 | 1469 (0,72 %) | 68 | **A**: колір самої ягоди |
| R2 · 6 `sauerkraut` | 173 | 428 (0,21 %) | 108 | **A**: журавлина |
| R2 · 8 `baked_apple` | 15 | 38 (0,022 %) | 6 | B |
| R3 · 4 `bean_soup` | 13 | 27 | 4 | B |
| R4 · 2 `water_mug` | 7 | 13 | 2 | B |
| R3 · 8 `broth` | 4 | 6 | 5 | B |
| R2 · 7 `uzvar` | 3 | 10 | 3 | B |
| R3 · 5 `cheese_pastry` | 2 | 4 | 1 | B |
| R2 · 1 `pear` | 1 | 6 | 1 | B |
| R3 · 1 `eggs` | 1 | **0** | — | B: артефакт LANCZOS |
| R2 · 2 `carrots` · R3 · 3 `smoked_fish` · R4 · 7 `rye_spirit` | 0 | 8 · 1 · 1 | 4 · 1 · 1 | B, критерій пройдено |
| для порівняння: R1a · 5 `apple_red` (✗ у § Відбір R1) | 21 | 43 | 4 | B |
| для порівняння: R1b · 5 · R1b · 7 | 856 · 127 | 1397 · 405 | 249 · 102 | A |

**Два класи.**
- **Клас A** — справжній червоний: ягода, журавлина, яблуко R1b. Це видно оком.
- **Клас B** — поодинокі зерна «паперової» фактури в теплій тіні теракоти й охри. Плями ≤ 6 px, лише біля `#711126`,
  середній колір (97–105, 40–44, 33–43). На найбільшому показі 128 px пляма в 6 px аркуша менша за 1 піксель.

Яйця мають у самому аркуші 0 таких пікселів, а після LANCZOS — 1. Отже, правило «0 px на іконці» ловить також шум
різайзу. Повтор клас B не лікує: це фактура стилю, і на вихідній роздільності вона є в 13 з 48 клітинок обох хвиль. **У
вердикті нижче критерій 4 застосовано в чинній редакції** (0 px на іконці, як у § Відбір R1). Клітинки, які провалюють
**лише** його і **лише** класом B, позначено «умовно».

**Пропозиція 4′ — не чинна.** Я сформулював її **після** цього заміру, тому рішення за T1. Формулювання:
- рахувати на вихідній роздільності аркуша;
- немає жодної зв'язної плями кров'яного тону площею ≥ (L / 107,5)² px, де L — довша сторона предмета в px аркуша
  (поріг 15–44 px). Така пляма займала б ≥ 1 піксель на показі 128 px, де предмет — 84 % сторони;
- сумарна частка кров'яних пікселів < 0,05 % непрозорих.

Між класами великий проміжок: B ≤ 6 px і ≤ 0,025 %, A ≥ 68 px і ≥ 0,16 %. `crit4prime.py`: усі клітинки класу B — PASS, а
R1b · 5, R1b · 7, R2 · 4, R2 · 6 — FAIL. Якщо T1 приймає 4′, «умовні» переходять у прийняті, разом із R1a · 5 `apple_red`.
Якщо ні, вони лишаються без іконки, а повтор їх не врятує.

**Інші знахідки.**
- **R3 · 5 `cheese_pastry` — копія пирога R1a · 4.** Плетений край, вирізаний клин, шість прорізів-листків, начинка із
  зеленими цятками. Порушено `do not copy its objects` у `{REF_SET}`. Скрипт `pair.py` (128 px) дає проти R1a · 4: перетин
  гістограм 0,817, IoU силуету 0,881, середній ΔRGB 41,3. Це найближча пара серед 47 іконок (медіана 0,237 / ΔRGB 79,7),
  ближча навіть за R1b · 4, тобто той самий слот S1 · 4 з іншого запуску (0,599 / 0,870 / 52,4). У сірому на 32 px:
  IoU 0,88, |Δ| 19,3, найменше серед пар різних предметів. Гравець назве це «пирогом», як S1 · 4. Отже, **✗ 1 і 2**.
- **R5 · 5 `joint` — псевдодрук.** На 100 % і 200 % читабельних літер немає. Проте «газетна штриховка» намальована
  рядками знаків, що імітують друк: це псевдолітери, **✗ 5** для іконки. Як референс форми для процедурного пропа T2
  придатна, бо ТЗ T2 уже «без друку».
- **R5 · 6 `water_pipe`** — світла дуга на склі колби, тобто блиск скла, **✗ 6** для іконки. Трубка стоїть поруч із
  корком, а не крізь нього. Як референс форми (формат П) придатна: блик і цю деталь у проп не переносити.
- **R5 · 7–8 листки.** Стебло на x 257,0 і 258,0 при центрі 255,5 (допуск ±4), низ на y 472, тобто поле 7,8 %. На 42/48/64
  px кожен листок одним шматком. На 32 px у листка A відривається стебло (1×2 px, a 163), але картка ніколи не показується
  менше ніж 42 px. Як іконку 32 px листок A не використовувати. Заливка картки ≈ (119, 116, 101), тобто темніша й
  оливковіша за `LEAF_FILL` `#8E9A86` (`CityPasserby.gd:12`). Тінь (91, 72, 82) близька до `#624A57`. Листки впізнавані,
  як і треба для події.
- **Пари в сірому на 32 px (критерій 2, `greypairs.py`).**
  - Квас ↔ пиво: IoU 0,96, тобто той самий кухоль, але сірий у горлі 72 проти 174 (піна).
  - Вода ↔ квас: 0,85 / |Δ| 32,9; вода ↔ пиво: 0,83 / 44,5. Кухоль води глиняний, пузатий, з хвилястим пояском.
  - Чарка ↔ кухоль: 0,46–0,49. Цигарка ↔ самокрутка: 0,61 / 33,6. Яблуко ↔ груша: 0,58–0,64.
  - Усі пари розрізняються і на око. Побоювання п. 10 документа рішення (квас «у тому самому кухлі») не справдилось.
- **R4 · 2 `water_mug`** — та сама глиняна кружка, що й чай R1a · 1: перетин гістограм 0,820, ΔRGB 32,6. Чай зараз без
  іконки. Якщо повтор S1 дасть чай без пари в такому самому кухлі, вода й чай розрізнятимуться лише кольором рідини.
- **R3 · 8 `broth`** без пари, тобто правка слота до запуску спрацювала.
- **Читабельність (критерій 1).** T6 назвав усі 32 предмети на 32 px на панелі `#090F14`. Застереження:
  - S2 · 5 на 32 px читається як «діжка під гнітом», яблука видно від 48 px;
  - S2 · 7 — як «глечик», скибки видно від 48 px;
  - S4 · 3 — фляга впізнається переважно за кришкою на ланцюжку.

  Назву несе рядок меню (T7 § 2). Santos контакт-аркуш ще не бачив, тому критерій 1 для нього відкритий.
- **Один стиль (критерій 7).** На контакт-аркуші при 64 px жодна іконка не випадає з ряду. Лінія R4–R5 трохи темніша
  (G 1–5 проти 12–15), але на 64 px цього не видно.

**Клітинки** (критерії 1–8; формат з документа рішення: І — іконка, П — референс форми, К — картка):

| кл. | R2 · S2 | R3 · S3 | R4 · S4 | R5 · S5 |
|---|---|---|---|---|
| 1 | `pear` — умовно (✗ 4: 1 px, B) | `eggs` — умовно (✗ 4: 1 px, артефакт) | `water_ladle` — ✓ І | `cig_pack` — ✓ П |
| 2 | `carrots` — ✓ І | `sheep_cheese` — ✓ І | `water_mug` — умовно (✗ 4: 7 px, B) | `cigarette` — ✓ І |
| 3 | `cabbage` — ✓ І | `smoked_fish` — ✓ І | `water_flask` — ✓ І | `matches` — ✓ І |
| 4 | `rosehip` — **✗ 4** (A) | `bean_soup` — умовно (✗ 4: 13 px, B) | `dark_beer` — ✓ І | `loose_tobacco` — ✓ П |
| 5 | `pickled_apples` — ✓ І | `cheese_pastry` — **✗ 1, 2** (копія R1a · 4) | `kvass` — ✓ І | `joint` — ✗ 5 як І; ✓ лише П-референс |
| 6 | `sauerkraut` — **✗ 4** (A) | `sausage` — ✓ І | `plum_wine` — ✓ І | `water_pipe` — ✗ 6 як І; ✓ лише П-референс |
| 7 | `uzvar` — умовно (✗ 4: 3 px, B) | `milk` — ✓ І | `rye_spirit` — ✓ І | `leaf_a` — ✓ К |
| 8 | `baked_apple` — умовно (✗ 4: 15 px, B) | `broth` — умовно (✗ 4: 4 px, B) | `beer_barrel` — ✓ П | `leaf_b` — ✓ К |

**Вердикт.**
- **R2 — прийнято частково:** 3 іконки (2, 3, 5), 3 умовні (1, 7, 8), 2 відкинуті (4, 6). Тут промпт сам просив
  «muted brick-red» ягоди, а модель поклала їх у межі К1.
- **R3 — прийнято частково:** 4 іконки (2, 3, 6, 7), 3 умовні (1, 4, 8), 1 відкинута (5, копія).
- **R4 — прийнято:** 6 іконок (1, 3–7) і П-референс бочки (8); 1 умовна (2).
- **R5 — прийнято:**
  - 2 іконки (2, 3), 2 П-референси (1, 4), 2 картки К (7, 8);
  - самокрутка й «булька» — лише референси форми, не іконки.

**Нарізка** (критерій 3, 512×512, поле 8 %; у листків стебло по центру). Усе лежить у scratchpad головної сесії
`art-items/icons/`, у `game/assets/` нічого не перенесено:
- **26 прийнятих:** 21 іконка, тобто R1a · 2, 3, 4, 6, 7, R1b · 8 і 15 з хвилі 2; 3 П-референси і 2 картки;
- **8 умовних** у `icons/conditional/`;
- **2 лише-референси** в `icons/ref-only/`;
- **контакт-аркуш** для Santos — `art-items/icons/contact.png`: 64 і 32 px на `#090F14`, підписи slug, чотири розділи за
  вердиктом.

Переносить у `game/assets/` T2 разом із кодом підключення, `.import` і рядком реєстру (документ рішення § Рядки).

**Повтор зараз не потрібен (0 з 2).** Жоден слот гри не заблокований:
- меню їжі текстове: `CityHunger.gd:49–51` — `tea`, `loaf`, `crust`; `grep -rn -i icon` по `CityHunger.gd`, `CityHud.gd`,
  `NpcDialogue.gd` нічого не знаходить;
- місця Л1–Л4 для нових предметів — [P].

Коли T8 введе іконки в меню, рекомендую **1 повтор — зведений аркуш P1** із чотирьох провалів, які не лікує 4′. Решта
клітинок P1 — на рішення T6 і T7 у день запуску. Ціну звіряє T1 через `get_cost`; сьогодні `balance` 3791.5.

### Чернетка повтору P1 (не запускати; слово Santos і `get_cost` — у T1)

`{ITEM_STYLE} {GRID_8} … {REF_SET}` (R1a) `{NEG_ITEM}`. Слоти, що змінюються:
- **S1 · 1 → чай без пари:** `a heavy clay mug of sage tea, the brew a muted green-brown with a few sage leaves floating, no steam`
- **S2 · 4 → шипшина без К1:** `a small linen pouch of dried rosehips, the hips dull orange-brown like dried clay, a few spilled beside it`
- **S2 · 6 → без журавлини:** `a terracotta pot of pale sauerkraut with thin shreds of orange carrot and a wooden fork stuck in it`
- **S3 · 5 → не копія пирога:** `a small half-moon hand pie with a crimped edge and a golden-ochre crust, a little pale cheese filling showing at the crimp, not a round pie, no cut wedge`

## Журнал запусків

| запуск | job-id (повний UUID) | результат | `balance` до → після |
|---|---|---|---|
| — | — | не запускалось | 3826 (`balance` 2026-10-08, T6 sub-agent, без списання) |
| R1a · S1 · без рефу · 2026-10-08 · T1 · `get_cost` 2.75 | `55ccd85c-bd41-492b-afc6-b299d6eb969e` | 2688×1520 RGBA, sha256 `5031ff22…f922a3`. **ПРИЙНЯТО, обрано `{REF_SET}`** для R2–R5. Іконки: кл. 2, 3, 4, 6, 7, 8 ✓; кл. 1 ✗ кр. 2 (пара); кл. 5 ✗ кр. 4. Ореол знімає вирізка (§ Відбір R1) | 3808 (T1) → 3802.5 за обидва R1 (`balance`, T6 sub-agent) |
| R1b · S1 · реф `a2913501-694d-4bbc-9908-66892760bf7e` · 2026-10-08 · T1 · `get_cost` 2.75 | `5c576362-43a0-4f5d-b3dc-ef431e838a22` | 2688×1520 RGBA, sha256 `f46d6f55…9a5b4`. **ПРИЙНЯТО як стиль, не обрано**: резерв кл. 2, 3, 4, 6, 8; кл. 1 ✗ кр. 2 і 4; кл. 5, 7 ✗ кр. 4. Палітри присмерку від референсу річки на аркуші не видно: пікселів бірюзово-сланцевого тону (H 170–240°, S > 0,2) 0,00 % в обох аркушах. **Корекція хвилі 2:** кл. 8 іде на слот `dried_sage` замість R1a · 8 | те саме |
| R2 · S2 · реф R1a · 2026-10-08 · T1 · `get_cost` 2.75 | `2fb2812f-04e1-435d-83d2-d19f070d6052` | 2688×1520 RGBA, sha256 `6eb7406c…33346449`. Частково: І кл. 2, 3, 5; умовно кл. 1, 7, 8 (лише кр. 4, клас B); ✗ кл. 4, 6 (кр. 4, клас A — ягоди) | 3802.5 → 3791.5 за R2–R5 (T1; `balance` T6 sub-agent 3791.5) |
| R3 · S3 · реф R1a · 2026-10-08 · T1 · `get_cost` 2.75 | `be0b2d43-1bda-4a5b-8c71-cdc05cbce529` | 2688×1520 RGBA, sha256 `7af76105…0809a91`. Частково: І кл. 2, 3, 6, 7; умовно кл. 1, 4, 8; ✗ кл. 5 — копія пирога R1a · 4 (кр. 1, 2) | те саме |
| R4 · S4 · реф R1a · `{NEG_PLAIN}` · 2026-10-08 · T1 · `get_cost` 2.75 | `153ed9ac-1497-4f10-977e-780a63d22a25` | 2688×1520 RGBA, sha256 `a852f84f…41c0c087`. Фільтр не відхилив. І кл. 1, 3–7; П кл. 8; умовно кл. 2 | те саме |
| R5 · S5 · реф R1a · `{NEG_PLAIN}` · 2026-10-08 · T1 · `get_cost` 2.75 | `83ec26fc-a4e8-4a3f-a405-94a7dd94fb21` | 2688×1520 RGBA, sha256 `386a7699…6f42ee42`. Фільтр не відхилив. І кл. 2, 3; П кл. 1, 4; К кл. 7, 8; кл. 5 ✗ 5 (псевдодрук), кл. 6 ✗ 6 (блик) — лише П-референси | те саме |

## Related

- [[2026-10-08-Substances-And-Food-Items]] · [[Prompt-Library]] · [[HUD-Skill-Icons-Prompts]] · [[VFX-Sheets-Prompts]] · [[Style-Guide]]
- [[Higgsfield-Pipeline]] · [[Textures-Registry]] · [[PROPOSAL-Food-Of-Cronshift]] · [[PROPOSAL-Substances-And-Healthy-Food]] · [[2026-10-07-Drug-And-Street-Crime-Rating]]
