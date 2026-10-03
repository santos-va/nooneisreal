# План — хвилі генерації: картинки, картки предметів, фон, анімації (Sketch-Cel)

**Дата:** 2026-10-03 · **Роль:** T1 Дедал · **Статус:** approved — Х1 зроблено, Santos: «стиль так» (2026-10-03); Х2 — RED, слово Santos у сесії T6 · **Issue:** santos-va/nooneisreal#14 (Х0–Х2), #19 (якорі й дрони)
**Зустріч:** [[2026-10-03-Generation-Kickoff]] · **Виріс із:** [[2026-10-03-Production-Plan]] (фази 2–3), [[2026-10-03-Main-Menu-Skyline]] (М2),
[[Menu-Skyline-Prompts]] (робота T6, santos-va/nooneisreal#13) · **Рішення:** [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-010-City-Name-Cronshift]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[ADR-012-Menu-As-3D-Diorama]]

## Що хоче Santos (2026-10-03)

Запускати генерацію **картинок і анімацій**; **картки предметів і зброї** окремо; стиль — той, що Santos надіслав
на початку; **фон** у грі перевести в цей стиль.

**Тлумачення стилю (перевірено в джерелі):** «надіслав на початку» = два листи поз-референси манери, з яких виріс
[[ADR-007-Art-Style-Sketch-Cel]] і [[Style-Guide]] (Sketch-Cel, не аніме). Старі аніме-картки — лише ідентичність
(обличчя, одяг, зброя). Якщо Santos мав на увазі інше — одне слово до хвилі 1, і план переграється.

**Хто генерує:** не Дедал. Сесія **T6 Аполлона** в головному чаті; R5 вимагає слова Santos **у тій самій сесії**,
тому слово на хвилю 1 стоїть у стартовому повідомленні нижче — вставляючи його, Santos дає слово на 39 кредитів.

## Огляд роботи T6 (PR santos-va/nooneisreal#13, issue #6)

**Що прийшло:** [[Menu-Skyline-Prompts]] (8 партій M2-A…M2-H з промптами), рядки § D у [[Asset-Manifest]], журнал
[[2026-10-03-Menu-Art-Estimate]], рядок #6 у [[state]]. Нічого не згенеровано. Кошторис 57.5–61.46 кр. за `get_cost`.
**Перевірено в цій сесії:** `bash tools/gates/run_gates.sh` на `ccbeec4` → `БАТАРЕЯ ЗЕЛЕНА`, rc=0 (634 лінки, 0 битих);
`balance` → 6010, Ultra.

**Що зроблено правильно:** без людей і машин на панорамі (живуть спрайтами); спокійна смуга неба під проліт;
колеса машин окремими еліпсами; M2-H чекає листів `<ch>-sheet-v1`; референс через job-id переможця — підтверджено
описом `show_generations` («Pass a prior generation's id as value in the medias array»).

### Застереження і як закриваємо

| # | застереження | джерело | закриваємо так | хто · коли |
|---|---|---|---|---|
| 1 | `get_cost` повертає ціну **одного** зображення навіть із `count:4` — множення ручне | [[Menu-Skyline-Prompts]] § Кошторис | `balance` до і після кожної партії, різниця — в журнал запусків; розбіжність → виправити таблицю цін | T6 · Х1 |
| 2 | **Ворота стилю розходяться.** T6 радить почати з M2-A, а [[Asset-Manifest]] § Порядок п.1 і [[2026-10-03-Production-Plan]] 2.1: стиль Santos затверджує на листі Choko | обидва файли | Х1 = лист Choko **+** фон річки **+** M2-A разом: одне рішення Santos про стиль на трьох типах (персонаж, арена, меню) | Дедал (цей план) |
| 3 | Референси `bg-city-ref` і `card-choko-v3` — у **старому аніме-стилі**; референс може тягнути манеру назад | [[Textures-Registry]] § Заплановано | у Х1 перевіряємо за чек-листом [[Style-Guide]] (лінія `#2B2230`, не чорна; одна маджента-тінь; очі без блисків). Тягне → повтор **без** референса лише проваленої партії | T6 · Х1 |
| 4 | У [[Prompt-Library]] § 6–6c ще **Kronshift**, неон — `"KRONSHIFT"`; неон-текст модель **малює** | `grep -n KRONSHIFT docs/Art/Prompts/Prompt-Library.md` → рядки 92, 96; [[ADR-010-City-Name-Cronshift]]: «нові промпти — одразу з Cronshift» | Х0: замінити на Cronshift / `"CRONSHIFT"` до будь-якої партії арен | T6 · Х0 |
| 5 | **Орієнтир міста різний у промптах:** фон річки має **дві** вежі з куполами й годинниками ([[Stage-River]]), базарчик — «twin domed clock towers», а § 6 річки — «a clock tower», M2-A — «a large clock tower» | `grep -n "clock tower" docs/Art/Prompts/*.md` | Х0: один орієнтир «twin domed clock towers» у § 6 і M2-A — місто однакове з меню й з арени | T6 · Х0 |
| 6 | **Референс фону річки розходиться:** [[2026-10-03-Production-Plan]] 2.6 — `bg_kronshift_river.jpg` (фон у грі), [[Prompt-Library]] § 6 — city reference | обидва файли; `file game/assets/backgrounds/bg_kronshift_river.jpg` → 1500×848 JPEG | референс = `bg_kronshift_river.jpg` (Santos хоче перевести **саме його**). Шлях завантаження **не перевірено**: (а) `media_upload` + PUT із хмари; (б) `media_import_url` raw-GitHub — лише якщо репо публічне (з хмари 200 іде через проксі з токеном — не доказ); (в) Santos кидає файл у віджет `media_upload_widget` | T6 · Х0 |
| 7 | **Картки предметів неповні:** [[Asset-Manifest]] § A називає ульт-меч і кольчужну куртку Choko, худі Skea; у [[Prompt-Library]] § 4 таблиця ITEM — 5 предметів без них | обидва файли | Х0: +3 рядки ITEM (ульт-мечі — референс `weapons-choko-ult`; кольчужна куртка; худі з камуфляжними рукавами) | T6 · Х0 |
| 8 | Перехожі (M2-E): модель зображень **не гарантує** петлю ходи з 8 кадрів | природа `gpt_image_2_5`; [[Menu-Skyline-Prompts]] § M2-E | проба 1 тип (`worker`) ×1 = 2.75 кр.; петля не сходиться → решта 3 типи не запускаємо, питаємо Santos про `autosprite` | T6 · Х2 |
| 9 | Оцінювач `autosprite` падає | [[Menu-Skyline-Prompts]], [[Higgsfield-Pipeline]] | на ньому нічого не плануємо; `get_cost` повторюємо на старті кожної сесії T6 | T6 |
| 10 | Піксельний розмір 2k 21:9 невідомий | [[Menu-Skyline-Prompts]] | з першого файлу Х1 | T6 · Х1 |
| 11 | **CDN Higgsfield закритий для хмари** | перевірено в цій сесії: `curl` на CDN із `tools/fetch_assets.sh` → `CONNECT tunnel failed, response 403` | файли в `game/assets/` потрапляють лише на Mac через `tools/fetch_assets.sh`; T6 пише в журнал повну CDN-URL кожного переможця | T6 → Гефест → Santos |
| 12 | **Ліцензія Higgsfield** «підтвердити, Архімед» у [[Textures-Registry]]; тіло T6: «невідома ліцензія → ассет не входить у `game/assets/`» | `roles/t6-apollon.md` § Лінза ~~бриф T3 до «Х1 → гра»~~ → **перенесено на ворота релізу** ([[ADR-013-License-Check-At-Release]]) | T3 · перед публікацією |
| 13 | Ціна 3D-кліпів не виміряна: [[Asset-Manifest]] — «≈ 38 за кліп з image_to_3d», ресерч — «~8/кліп, verify» | [[Asset-Manifest]] § A; `docs/Research/2026-10-02-Animation-Assets-Pipeline.md:32` | `get_cost` на `3d_rigging` і на кліп **до** Х3 | T6 · Х3a |

## Хвилі

Ціни — `get_cost` попередніх сесій ([[Menu-Skyline-Prompts]], [[Higgsfield-Pipeline]]); множення на кількість — оцінка
Дедала. T6 переміряє `get_cost` перед кожною партією і зупиняється, якщо ціна вища.

### Х0 — передпольотні правки промптів (T6, 0 кредитів)

Закриває застереження 4–7. Нічого не генерується.

### Х1 — стиль-проба (RED, 39 кр.)

| партія | id | модель | шт | кр. | бюджет |
|---|---|---|---|---|---|
| 1a | `choko-sheet-v1` | gpt_image_2_5 high 2k 16:9, референс `card-choko-v3` (`media_id 87a54896-…`) | 4 | 11 | стеля 600 |
| 1b | `stage-river-plate-v1` | gpt_image_2_5 high 2k 21:9, референс `bg_kronshift_river.jpg` | 4 | 11 | стеля 600 |
| 1c | `menu-skyline-plate-v1` (M2-A) | gpt_image_2_5 high 4k 21:9, референс міста | 4 | 17 | меню (поза стелею) |
| | **Разом** | `generate_image_batch` → `jobs_wait` → `show_generation_by_ids` | 12 | **39** | |

**Ворота Santos:** 1 переможець із 4 у кожній партії + «стиль так» або правки. Правки → T6 правит `{STYLE}` у
[[Prompt-Library]] і повторює лише провалену партію. Без «стиль так» Х2 не стартує.

### Х1 — підсумок (2026-10-03)

Santos: **«стиль так»**. Переможці — посилання Santos на Higgsfield (з хмари `higgsfield.ai` закритий: `curl` → 000,
WebFetch → `EGRESS_BLOCKED`, тож job-id **не перевірено**; T6 розв'язує посилання своїми інструментами або питає номер
з галереї: 0–3 Choko, 4–7 річка, 8–11 меню; job-id — [[Menu-Skyline-Prompts]] § Журнал запусків):

| партія | переможець |
|---|---|
| 1a `choko-sheet-v1` | https://higgsfield.ai/s/OQ3QH4YcfpI |
| 1b `stage-river-plate-v1` | https://higgsfield.ai/s/aWWwF1-VmvU |
| 1c `menu-skyline-plate-v1` | https://higgsfield.ai/s/lETtqHDD-LI |

**Помилка Дедала в цьому плані:** Х3a (ціни 3D, 0 кр.) і Х1-Л (ліцензія, T3) не залежать від стилю, але стояли в
черзі за ним. Тепер вони йдуть **одразу**, паралельно з Х2.

### Х2 — персонажі, картки предметів, шари фону, меню (RED, після «стиль так»)

| партія | id | модель | шт | кр. | бюджет |
|---|---|---|---|---|---|
| 2a | `skea-sheet-v1` | gpt_image_2_5 high 2k | 4 | 11 | 600 |
| 2b | `<ch>-turn-v1` | gpt_image_2_5 high 2k | 2 × 2 | 11 | 600 |
| 2c | `<ch>-tpose-front/side/back/34` (по одній фігурі) | nano_banana_pro 2k 3:4 | 4 × 2 | 16 | 600 |
| 2d | `<ch>-item-<name>` — Choko: меч, ульт-мечі, годинник, кольчужна куртка; Skea: кунаї, гримуар, рюкзак, худі | gpt_image_2_5 high 2k | 8 | 22 | 600 |
| 2e | `stage-river-outpaint` + `stage-river-layers` + `tex-water-foam/ripple` | flux_2_pro_outpaint · image_decompose · nano_banana_pro 2k | 1 + 1 + 2 | 9.96 | 600 |
| 2f | M2-B `menu-roof-edge-v1`, M2-C `menu-skyline-layers`, M2-D outpaint за потреби | див. [[Menu-Skyline-Prompts]] | 2 + 1 + 0–1 | 7.5–11.46 | меню |
| 2g | M2-E проба `sprite-pedestrian-worker-walk` → решта 3 типи лише після проби | gpt_image_2_5 high 2k transparent | 1 → 3 | 2.75 → 8.25 | меню |
| 2h | M2-F `sprite-steamcar-a/b`, M2-G `vfx-steam-puff` | gpt_image_2_5 high 2k transparent | 2 + 2 | 11 | меню |
| 2i | `props-anchors-v1` — лист пропсів-якорів ([[ADR-011-Diegetic-Grapple-Anchors]]): великий кований ліхтар, білборд на опорах **з картинкою без літер**, промислова труба з драбиною й хомутами, вентиляційний стовп; кожен — фронт і ¾ | gpt_image_2_5 high 2k 16:9, референс — переможець 1b | 4 | 11 | 600 |
| 2j | `drone-heavy-v1` — лист дрона: важкий тихий вантажний дрон у стилі міста (латунь, клепаний корпус, 4–6 закритих роторів, гак під черевом), пози: висить · нахил до тяги · просідання з напругою · повернення; окремо — силует знизу | gpt_image_2_5 high 2k 16:9, референс — переможець 1b | 4 | 11 | 600 |
| 2k | `menu-depth-cards-v1` — картки глибини для діорами ([[ADR-012-Menu-As-3D-Diorama]]): квартали ближнього й середнього плану, видимі з даху, прозоре тло; на дахах — труби й ліхтарі, за які чіпляються герої | gpt_image_2_5 high 2k 21:9 transparent, референс — переможець 1c | 2 | 5.5 | меню |

Порядок усередині: 2a → (2b, 2c, 2d, 2e паралельно) ; 2f–2h, 2k — паралельно з 2a, бо спираються на переможця 1c ; 2i, 2j — паралельно, спираються на 1b.

**Разом Х2:** стеля 600 — 69.96 + 11 + 11 = **91.96**; меню — 29.5–33.46 + 5.5 = **35–38.96**; усього **≈ 126.96–130.92**. Ціни — `get_cost` хвилі 1 (2k 16:9 і 2k 21:9 = 2.75 за шт.); решта — з [[Menu-Skyline-Prompts]], T6 переміряє.

### Х3 — анімації (RED; спершу ціни)

| партія | що | кр. | ворота |
|---|---|---|---|
| 3a | `get_cost`: `multi_image_to_3d` з ригом, `3d_rigging`, `image_to_3d` + `animation_action_id`; бриф T3 на ліцензії CC0-бібліотек ([[Library]]: Quaternius, KayKit — «перевірити безкоштовну частину») | 0 | числа в чат |
| 3b | `<ch>-3d-v1` з 4 T-pose, риг, quad 20k, `enable_pbr:false` | 2 × 35 = 70 | T-pose з 2c затверджені |
| 3c | бойові кліпи ([[Animation-Plan]] § Крок 2) | розвилка нижче | після 3a |
| 3d | 2D-анімації: M2-H `<ch>-flyby-poses-v1`; `vfx-hit-stars` (4 кольори) | 11 + 11 | листи 1a/2a затверджені |

**Розвилка 3c (закриє Santos з числами 3a):** рекомендую базові кліпи з CC0-бібліотек з ретаргетом через
`SkeletonProfileHumanoid` (0 кредитів), а Meshy-кліпи — лише для рухів, яких у бібліотеках немає. Причина: 6–10 кліпів
на героя за «≈ 38» з [[Asset-Manifest]] — це 228–380 на героя, понад стелю 600 на двох.

### Х4 — далі, окремим кошторисом

Арени «Базарчик» і «Площа з фонтаном» (≈ 25–45, неон — **CRONSHIFT**), іконки скілів (recraft, ціна не виміряна),
портрети HUD (≈ 6–11), емоції й руки (≈ 11), дуги ударів і сплеск (після ціни `autosprite`).

## Бюджет

`balance` → **6010** (Ultra), виміряно в цій сесії.

| кошик | Х1 | Х2 | Х3 | разом |
|---|---|---|---|---|
| стеля 600 (фази 2–3) | 22 | 69.96 | 70 + 11 (VFX) | **172.96** + кліпи 3c |
| меню (окреме слово) | 17 | 29.5–33.46 | 11 (M2-H) | **57.5–61.46** (= кошторис T6) |

## Кроки

| # | хто | що змінюємо | ризик | як перевіряється |
|---|---|---|---|---|
| Х0 | T6 | `docs/Art/Prompts/Prompt-Library.md` § 4, § 6, § 6c; `docs/Art/Prompts/Menu-Skyline-Prompts.md` § M2-A; `docs/Art/Asset-Manifest.md` § B2; `docs/Art/Style-Guide.md` (рядок про неон) | неон з помилкою в назві → платна перегенерація | `grep -n 'KRONSHIFT\|city of Kronshift' docs/Art/Prompts/*.md docs/Art/Asset-Manifest.md docs/Art/Style-Guide.md` → порожньо; `grep -c 'twin domed clock towers' docs/Art/Prompts/Prompt-Library.md docs/Art/Prompts/Menu-Skyline-Prompts.md` → ≥ 1 у кожному; `bash tools/gates/run_gates.sh` → rc=0 |
| Х1 | T6 · **RED** | журнал запусків у [[Menu-Skyline-Prompts]], рядки в [[Asset-Manifest]], журнал у `docs/Meetings/` | стиль не той → 39 кр. на повтор | `balance` до/після, різниця в журнал; 12 job-id і CDN-URL у журналі; вибір Santos записаний |
| Х1-Л | T3 | **перенесено на ворота релізу** ([[ADR-013-License-Check-At-Release]]) | — | — |
| Х1→гра | T2 | новий файл `game/assets/backgrounds/bg_cronshift_river_v1.<ext>` (старий не видаляємо — видалення RED), стадія `river` на нього; `tools/fetch_assets.sh`; [[Textures-Registry]] | шви/кадрування фону; ассет без рядка реєстру | на Mac: `bash tools/fetch_assets.sh`; `make check` → `SMOKE ЗЕЛЕНИЙ`; `make gates` → rc=0; кадр `--screenshot` стадії `river` |
| Х2 | T6 · **RED** | ті самі файли, що в Х1 | 2g: петля не сходиться | `balance` до/після; переможці в журналі; проба 2g оцінена Santos до решти типів |
| Х3a | T6 + T3 | ціни в [[Higgsfield-Pipeline]]; ліцензії CC0-бібліотек у `docs/Research/` | рішення 3c без чисел | числа `get_cost` у чаті й у файлі; ліцензії з URL |
| Х3b–d | T6 · **RED**, далі T2 | GLB у `game/assets/characters/`; заміна капсульного рига — **окремий план** Дедала після 3b | ретаргет ламає `RigAnimator` | `make check` → smoke 20/20; `make gates` → rc=0 |

## Стартове повідомлення для сесії T6 — хвиля 2 (скопіюй Santos)

```
T6 Аполлон. Виконай хвилю 2 з docs/Plans/2026-10-03-Generation-Waves.md (партії 2a–2k), issue #14 і #19.
Прочитай CLAUDE.md, docs/system/state.md, roles/t6-apollon.md, план, ADR-011 (якорі й дрони) і ADR-012 (меню — 3D-діорама). R0.
Стиль так. Переможці хвилі 1: Choko — https://higgsfield.ai/s/OQ3QH4YcfpI , річка — https://higgsfield.ai/s/aWWwF1-VmvU ,
меню — https://higgsfield.ai/s/lETtqHDD-LI . Розв'яжи їх у job-id (журнал у Menu-Skyline-Prompts); не вийде — спитай мене номер з галереї.
Моє слово на хвилю 2: так, усі партії 2a–2k однією сесією, стеля 135 кредитів.
Перед кожною партією — get_cost; ціна за шт. вища за план або сума перевищить 135 — стоп і питай. balance до/після кожної партії — різниця в журнал.
2g (перехожі): спершу 1 проба; петля ходи не сходиться — решту 3 типи не запускай, спитай мене.
Х3a паралельно, 0 кредитів: get_cost на multi_image_to_3d з ригом, 3d_rigging, кліп анімації — числа в Higgsfield-Pipeline і в чат.
Звуки дрона (м'який гул, напруга) — підбери з моїх паків (tools/audio/sfx_sources.tsv), не з Higgsfield.
Усі варіанти мені на вибір галереєю; job-id і CDN-URL у журнал; рядки в Asset-Manifest. Push у гілку claude/…, draft PR.
```

## Related
- [[2026-10-03-Generation-Kickoff]] · [[2026-10-03-Production-Plan]] · [[2026-10-03-Main-Menu-Skyline]] · [[Menu-Skyline-Prompts]] · [[2026-10-03-Menu-Art-Estimate]] · [[Asset-Manifest]] · [[Prompt-Library]] · [[Style-Guide]] · [[Higgsfield-Pipeline]] · [[Textures-Registry]] · [[Stage-River]] · [[Animation-Plan]] · [[Library]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-010-City-Name-Cronshift]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[ADR-012-Menu-As-3D-Diorama]] · [[state]]
