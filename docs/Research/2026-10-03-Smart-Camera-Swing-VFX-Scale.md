# Бриф — розумна камера, свінг «як SpiderHeck», масштаб VFX, живе тіло

**Дата:** 2026-10-03 · **Роль:** T3 Архімед · **Замовник:** T5 Арес, передача з [[2026-10-03-Ares-Smart-Camera-Alive-Fight]]
(а, б, в) + запит Santos «опенсорсні інструменти, що закриють наші недоліки» (г).
**Правило брифу:** число з джерелом — референс, а не наша правда. Що не відкрито в цій сесії — так і позначено. Вибір
варіанта лишається за Аресом (бій), Дедалом (архітектура), Аполлоном (стиль).

**Доступ (R0).** Проксі хмари повернув 403 / EGRESS_BLOCKED на: youtube.com, gdcvault.com, gamedeveloper.com,
docs.godotengine.org, store.steampowered.com, itch.io, wikipedia, archive.org, nexusmods.com, theorangeduck.com,
mathforgameprogrammers.com, box2d.org, ggxrd.com, api.github.com. Робочий шлях — `raw.githubusercontent.com` і
`git clone`: сирці рушіїв і бібліотек читалися напряму. Позначка **«зріз»** = факт із підсумку WebSearch, сторінку не
відкрито; він годиться як напрямок, але не як число для `.tres`.

## 0. Що в нас зараз — недоліки, знайдені в коді (перевірено в цій сесії)

| # | недолік | місце | чим доведено |
|---|---|---|---|
| N1 | **Свінгу-маятника немає.** Поки R утримано, мотузка коротшає 9 м/с **і** діє тяга 70 м/с² до якоря; відпустив R — свінг скінчився. «Утримання» = довший зип. [[04-Grapple-System]] рядок 10 про тягу 70 мовчить | `GrappleHook.gd:190-192`, `:214` | порт `drive()` у python (§2.3): з підлоги на 4–12 м від якоря — «reached» за 0.35–1.15 с на стелі 26 м/с |
| N2 | **Дуга з підлоги не влазить у висоту якорів.** Якорі на 6.3–7.8 м, рука на 1.25 м → щоб ноги не торкнулись підлоги внизу дуги, мотузка ≤ 5.05–6.55 м; гарпун бере якорі до 14 м | `Arena.tscn:96,103,110`, `GrappleHook.gd:13` | `python3`: `ya − 1.25` |
| N3 | **Свінг гасне сам.** Проєкція позиції на сферу на 60 Гц забирає ≈ 6–7 % швидкості за півперіод: замість 90° дуга доходить до 76–81° | `GrappleHook.gd:199-205` | симуляція без вкорочення, L = 4/6/10 м (§2.3) |
| N4 | **Тряска камери — білий шум на рендер-кадр**: `randf_range` щокадру, тож на 144 Гц вона інша, ніж на 30; амплітуда — **зсув до 0.6 м** (`h_offset`), не кут | `DuelCamera.gd:146-149`, `Arena.gd:139` | читання коду; загасання `lerp ×11·dt` до 5 % — 0.233 с на 30 fps і 0.264 с на 144 fps (`python3`) |
| N5 | **Фокус камери — експонента, а не пружина**: `1 − 0.0015^dt` = half-life **0.107 с**; рушає різко (10.3 % шляху за перший кадр) | `DuelCamera.gd:145`, `:178`, `:120` | `python3`: `ln 0.5 / ln 0.0015` |
| N6 | **Камера не знає станів бою**: два режими на матч (`behind` / `side`), без станів «свінг», «ульта», «погоня» | `DuelCamera.gd:57-58` | читання коду |
| N7 | **Модель 1.70 м, а GDD каже 1.8 м**; масштабу до 1.8 у коді не знайдено (кістки масштабуються лише за висотою тазу) | `SkeletalRig.gd:126` | `td.py` (scratchpad, розбір GLB): обидві моделі — висота меша 1.700 |

## 1. (а) Розумна камера

### 1.1 Математика плавності — першоджерела в коді

| джерело (відкрито) | формула дослівно | що значить для нас |
|---|---|---|
| Unity `Mathf.SmoothDamp`, `raw.githubusercontent.com/Unity-Technologies/UnityCsReference/master/Runtime/Export/Math/Mathf.cs:278-306`, коментар «Based on Game Programming Gems 4 Chapter 1.10» (перевірено `curl | grep` у цій сесії) | `omega = 2/smoothTime; x = omega·dt; exp = 1/(1 + x + 0.48x² + 0.235x³); temp = (v + omega·change)·dt; v = (v − omega·temp)·exp; out = target + (change + temp)·exp` | **критично демпфована пружина**: без перельоту, рушає м'яко (ease-in-out) |
| Daniel Holden, `github.com/orangeduck/Spring-It-On` `common.h`, MIT © 2021 | `damper_exact: lerp(x, g, 1 − 2^(−dt/halflife))`; `critical_spring_damper_exact` з тим самим наближенням exp | half-life-параметризація; ω_Unity = 2/T ⇔ **hl ≈ T·ln2** |
| Cinemachine 3.1.8-pre.2 `Runtime/Core/Predictor.cs:95-96,160` | `kNegligibleResidual = 0.01`; damping T = час до 1 % залишку | Cinemachine «Damping T» ⇒ **hl = 0.1505·T** |
| Freya Holmér «Lerp smoothing is broken» (2024) — **зріз** | `lerp(target, value, exp2(−rate·dt))` | те саме, що `damper_exact`; наш N5 уже frame-rate-незалежний |

**Таблиці (python3, dt = 1/60):**

| експонента, hl | шлях за 1-й кадр | до 95 % | до 99 % |
|---|---|---|---|
| 0.10 с | 10.9 % | 0.43 с | 0.66 с |
| **0.107 с (наш N5)** | 10.3 % | 0.46 с | — |
| 0.15 с | 7.4 % | 0.65 с | 1.00 с |
| 0.25 с | 4.5 % | 1.08 с | 1.66 с |

| критична пружина, T (ω = 2/T) | шлях за 1-й кадр | до 95 % | до 99 % | переліт |
|---|---|---|---|---|
| 0.10 с | 4.5 % | 0.24 с | 0.33 с | 0 |
| 0.15 с | 2.1 % | 0.36 с | 0.50 с | 0 |
| 0.25 с | 0.8 % | 0.59 с | 0.83 с | 0 |
| 0.30 с | 0.6 % | 0.71 с | 1.00 с | 0 |

Висновок-розрахунок: пружина з T 0.15 с доходить до 95 % **швидше** за нашу експоненту (0.36 проти 0.46 с), але
перший кадр рухає в 5 разів менше — саме це око читає як «плавно». Наш yaw уже обмежено по швидкості й прискоренню
(3°/такт = 180°/с, 0.25°/такт² = 900°/с², `DuelCamera.gd:12,23`) — це кусково-параболічний профіль, перельоту теж нема.

### 1.2 Кадр на пару — референси з коду бібліотек

| джерело | факт | застосування |
|---|---|---|
| **Phantom Camera** (`github.com/ramokz/phantom-camera`): `LICENSE` MIT © 2022 Marcus Skov; `plugin.cfg` `version="0.11.0.3"` (обидва перевірено `curl` у цій сесії); реліз 2026-07-19 (releases.atom, агент); README «Godot 4.4+» | `FollowMode.GROUP`: AABB усіх цілей → `distance = lerp(min, max, longest_axis / divisor)`, дефолти 1 / 5 / 10; `LookAtMode.GROUP`; згладжування — копія Unity SmoothDamp, `follow_damping_value` 0.1 (`phantom_camera_3d.gd:1198-1206, 1527-1548`, агент) | той самий клас, що наша формула `5.0 + 0.35·(sep−4)`, стеля 9. На Godot 4.7 **не перевірено** — `make check` на гілці (Гефест) |
| Cinemachine Group Framing `Reset()` (агент, raw GitHub) | FramingSize **0.8**, Damping 2, SizeAdjustment **DollyThenZoom** | порядок «спершу відстань, потім fov» = наша стеля fov 60 (ADR-018 п. 1) |
| Cinemachine Rotation Composer (доки пакета, агент) | три зони: **Dead Zone** (камера не рухається) → **Soft Zone** (damping) → **Hard Limits** (ціль не виходить) | готова рамка для «станів»: зони й damping — параметри стану |
| Godot 4.7 `SpringArm3D.xml` (raw, тег 4.7) | лише `collision_mask`, `margin`, `shape`, `spring_length` — **демпфування нема** | плавність — наш код або плагін |

### 1.3 Тряска

| джерело | факт | статус |
|---|---|---|
| Squirrel Eiserloh, GDC 2016 «Math for Game Programmers: Juicing Your Cameras With Math», `gdcvault.com/play/1023146` | trauma ∈ [0,1], удар **додає** trauma, trauma спадає **лінійно**, shake = trauma² або ³, зсув — **Perlin/гладкий шум** від часу, а не random | **зріз** (Vault, YouTube, слайди — 403) |
| Bevy `examples/camera/2d_screen_shake.rs` (raw main), посилається на доповідь | `TRAUMA_DECAY_PER_SECOND 0.5`, `TRAUMA_EXPONENT 2.0`, `MAX_ANGLE 10°`, `NOISE_SPEED 20`, `TRAUMA_PER_PRESS 0.4`; три канали шуму зі зсувом t+0/+100/+200 | відкрито (агент); **це числа Bevy, не Eiserloh**, і 2D |

Що прямо лікує N4: шум від часу (не від кадру) → однаково на 30 і 144 Гц; урон додає trauma, а не амплітуду;
кутова тряска замість зсуву 0.6 м. Числа (`MAX_ANGLE`, decay) — вибір Ареса; Bevy — лише референс.

### 1.4 Naruto Storm і схожі — **UNGROUNDED**

Доповідей CyberConnect2 про камеру (CEDEC/GDC) не знайдено; Storm-моддинг (UltimateStormAPI «Global FOV», «Camera
Manager») — лише назви, значень нема; Nexus — 403. Demon Slayer, JJK, Sparking Zero — лише гравцеві налаштування
(відстань, lock-on, тряска вкл/викл), чисел нема. Що вже є у вікі: [[2026-10-03-Free-Movement-References]] C1–C2
(камера Storm «covers a majority of angles… centre behind either character»), C8 (Nesky). **Шлях до чисел Storm** —
замір із 60-fps відео (кадри на перехід, частка героя в кадрі) руками Santos або Ареса; з хмари відео закрите.

### 1.5 Стани камери — каркас для Ареса (ДИЗАЙН-питання, без рекомендації)

Кожен рядок — набір параметрів, які вже є в коді або в джерелах вище; числа ставить Арес.

| стан | вхід | що змінюється | параметри |
|---|---|---|---|
| ближній бій | `sep` ≤ 6 | нинішні K-1 | `behind`, `side`, мертва зона фокуса |
| підхід / погоня | `sep` > 6 або деш | ширше, фокус ближче до того, хто біжить | T пружини, частка кадру ≥ 12.5 % ([[06-UI-UX]]) |
| свінг на гаку | `grapple.attached` | фокус на тому, хто висить, + якір у кадрі | T, частка, `fov` ≤ 60 |
| ульта | стан ульти | кінематограф — частина B, R3 ([[2026-10-03-Fight-Craft-Research]]) | — |
| перехід між станами | зміна стану | лише пружиною, без різу (ADR-015 п. 3, Nesky #20 у FM C8) | T переходу |

## 2. (б) Свінг «як SpiderHeck»

### 2.1 Джерела

| джерело | техніка / число | статус | що нам |
|---|---|---|---|
| SpiderHeck: розробник **Neverjam**, видавець tinyBuild, Unity, 2D, реліз 2022-09-22 (Steam 1329500, wiki.gg) | — | **зріз** | еталон 2D: беремо принципи, не числа |
| SpiderHeck devlog 0.61, `neverjam.itch.io/spiderheck/devlog/200800` | «further reworked web swinging for **more swing and less zip**» | **зріз** (itch — 403) | наш N1 — це саме «zip» |
| Jamie Fristrom, GDC 2019 «Classic Game Design Postmortem: Swinging with Spider-Man», `gdcvault.com/play/1025725` | «a bob on a pendulum», якорі — «rays like feelers», гравітація «about 10 times Earth normal» | **зріз** | наше ×2.45 (24 / 9.81) — помірне |
| Fristrom, tutsplus «Swinging Physics for Player Movement» | проєкція на сферу (= наш код) + `currentLength` плавно тягнеться до `desiredLength` | уже в [[2026-10-03-Combat-Numbers-Grounding]] H11 | вкорочення — плавним наближенням, не кроком |
| Doug Sheahan (Insomniac), GDC 2019 «**Concrete Jungle Gym**: Building Traversal in Marvel's Spider-Man», `gdcvault.com/play/1026422` | свінг фізичний, але «cheats physics a lot» | **зріз**; назва з брифу Ареса «A Deep Dive…» — **хибна**, правильна ця | чесний маятник + підправлення там, де заважає гравцеві |
| Insomniac, GDC 2024 (Spider-Man 2), стаття cheatcc.com | «fast is a feeling, not a speedometer»; «fast traversal is continuous traversal» | **зріз** | безперервність важливіша за стелю швидкості |
| Worms Ninja Rope, worms.miraheze.org | вкорочення → швидше обертання (момент імпульсу) | **зріз** | вкорочення — підсилювач, а не тяга |
| Dani `FPS_Movement_Rigidbody` `GrapplingGun.cs`, коміт `e268850` 2020-03-23, MIT (`git clone`, агент) | Unity `SpringJoint`: `maxDistance = 0.8·d`, `minDistance = 0.25·d`, spring 4.5, damper 7 | відкрито | інша школа: пружна мотузка, одразу вкорочена до 80 % — лікує N2 |
| Titanfall 2 grapple, fandom | слінгшот на межі дальності | **зріз**, чисел нема — UNGROUNDED | — |

Механіка павутини SpiderHeck у числах (пружина чи жорстка, coyote-час, автонаведення) — **UNGROUNDED**: Steam,
itch і Reddit — 403, знайдено лише цитату 0.61.

### 2.2 Фізика маятника

Wikipedia «Pendulum (mechanics)» — 403; копія-PDF sos.clayton.edu і physics.info — **зріз**. Формули стандартні й
перевірені розрахунком нижче: `T = 2π√(L/g)` (малі кути; на 90° точний період через еліптичний інтеграл ≈ +18 %),
`v_низ = √(2gh)`, при вкороченні центральною силою зберігається момент імпульсу `L·v` (точно — без гравітації).

### 2.3 Розрахунок для наших чисел (python3, g = 24 × 0.9 = 21.6)

`project.godot:227` `3d/default_gravity=24.0`, `Fighter.gd:21`, множник 0.9 — `GrappleHook.gd:189`.

| L, м | період (малий кут) | період (90°) | v низ із 90° | v низ із 45° | для g 9.81: v низ із 90° |
|---|---|---|---|---|---|
| 4 | 2.70 с | 3.19 с | 13.2 м/с | 7.1 | 8.9 |
| 6 | 3.31 с | 3.91 с | 16.1 | 8.7 | 10.9 |
| 8 | 3.82 с | 4.51 с | 18.6 | 10.1 | 12.5 |
| 10 | 4.28 с | 5.05 с | 20.8 | 11.3 | 14.0 |

Швидкості в нас ×1.48 земних, періоди ×0.67. Відпускання за 30° після низу з ×1.15 і балістика g 24: політ
7.1 / 10.7 / 14.3 / 17.9 м за 0.59–0.93 с для L 4 / 6 / 8 / 10 м.

**Порт `drive()` 1:1** (`swing.py`, scratchpad; R утримано, стік у спокої, якір на 7.2 м):

| старт | як зараз (тяга 70 + вкорочення 9) | лише маятник після зипу 12 кадрів |
|---|---|---|
| з підлоги, 4 м від якоря | досяг якоря за 0.35 с, пік 26.0 м/с (стеля) | приземлився за 0.97 с |
| з підлоги, 6 м | досяг за 0.40 с, пік 26.0 | приземлився за 0.82 с |
| з підлоги, 9 м | досяг за 0.93 с, пік 26.0 | приземлився за 0.60 с |
| з підлоги, 12 м | досяг за 1.15 с, пік 26.0 | приземлився за 0.45 с |

| у повітрі (y 2.5 м, біг 8 м/с до якоря, без тяги) | вкорочення 0 | 3 м/с | 9 м/с |
|---|---|---|---|
| 4 м від якоря | маятник, качається | досяг за 1.30 с, пік 12.2 | досяг за 0.43 с, пік 22.3 |
| 6 м | приземлився за 0.48 с | досяг за 1.77 с, пік 14.2 | досяг за 0.62 с, пік 25.6 |
| 9 м | приземлився за 0.48 с | приземлився за 0.48 с | досяг за 0.92 с, пік 26.0 |

Що видно: (1) сьогоднішній «свінг» завжди впирається в `max_speed 26` і закінчується біля якоря — це N1;
(2) чистий маятник на наших якорях працює лише з повітря й на короткій мотузці — це N2; (3) ідеальне вкорочення
10 → 6 м за `L·v` дало б 20.8 → 34.6 м/с (KE ×2.78), але проєкція цей приріст майже не додає, а стеля 26 зрізає —
тому 9 м/с не «забагато», а «в стелю» (агент, `nir_swing.py`).

### 2.4 Варіанти для Ареса (без рекомендації — це дизайн)

| варіант | суть | закриває | джерело техніки |
|---|---|---|---|
| С1 | утримання = маятник зі сталою L; тяга 70 лише в зипі (тап) | N1 | SpiderHeck 0.61 «more swing, less zip»; Fristrom |
| С2 | при зачепі L = min(відстань, `y_якоря − 1.25 − запас`) — «вибрати слабину» плавно (`current → desired`) | N2 | Fristrom `desiredLength`; Dani `maxDistance = 0.8·d` |
| С3 | компенсувати втрату енергії проєкції (зберігати модуль швидкості при проєкції) | N3 | розрахунок §2.3; Insomniac «cheats physics» |
| С4 | вкорочення — окремий ввід (стік угору / друга кнопка) | N1 | Worms, Spider-Man 2 |
| С5 | лишити як є, перейменувати в GDD «утримання = довгий зип» | чесність GDD | — |

Детермінізм зберігається в будь-якому варіанті: математика лишається кінематичною на 60 Гц ([[ADR-004-Physics-Is-Presentation]]).

### 2.5 Відкритий код мотузок (для презентації мотузки, не для симуляції)

| репо | ліцензія | Godot | останній коміт | вердикт |
|---|---|---|---|---|
| mphe/GDNative-Ropesim | MIT | 4.7 | 2026-08-08 | 2D Verlet, C++ — лише як ідея |
| sanyabeast/verlet_rope_4_gd | MIT | — | 2025-11-26 | візуал мотузки 3D: **адаптувати** |
| 2nafish117/godot-verlet-rope | MIT | — | 2024-03-24 | те саме, старіше |
| ivan-resetnikov/grappling-hook-3d | MIT | 4.2 | 2024-06-24 | лише тяга, без маятника — **ні** |
| mujtaba-io/godot-grappling-hook | LICENSE нема | 4.3 | 2024-10-13 | **ні** (без ліцензії) |
| ctwobosius/Grappling-Hook-Example | GPL | — | 2021-05-17 | **ні** (GPL) |

Усе — `git clone --depth 1` агентом; ліцензія — з файла `LICENSE`. Готового 3D-маятника для Godot, кращого за наш
код, не знайдено: наша схема вже Fristrom'івська, бракує лише варіантів §2.4.

## 3. (в) Масштаб VFX і текстур відносно героя

### 3.1 Arc System Works і правило «спарк = X % тіла»

| джерело | факт | статус |
|---|---|---|
| Junya Motomura, GDC 2015 «GuiltyGearXrd's Art Style», `gdcvault.com/play/1022031` | контур inverted hull, ширина — у кольорі вершин (не в текстурі, бо «pixel data easily can get jaggy at super close-ups»), лінії вздовж UV, ~40 000 трикутників на модель | **зріз** (PDF ggxrd.com — 403); частково вже в [[2026-10-02-Engine-Physics]] §3 |
| DBFZ (Kotaku, ResetEra) | моделі анімовано на 15 fps при грі 60 fps | **зріз** |
| Sakurai, «Make It "Pop"» (2022-09-22), «Let Your Characters Shine» (2022-11-09) | адитивне змішування й відблиск; ефект не має затуляти героя | **зріз** (YouTube — 403) |

**Числового правила «розмір спарку / товщина контуру відносно героя» не знайдено — UNGROUNDED.** Шлях — замір кадрів
референсів (Аполлон). Факт рушія для правила Аполлона: `QuadMesh.size` за замовчуванням 1 × 1 м
(`QuadMesh.xml:15`, 4.7.2), `ParticleProcessMaterial.scale_min/max` = 1 → спарк на дефолтному квадраті = **0.56
зросту** героя 1.8 м; `GPUParticles3D.visibility_aabb` за замовчуванням 8 м у ребрі — довший слеш треба розширювати (агент, raw 4.7.2-stable).

### 3.2 Щільність текстур — розрахунок для нашої камери

| джерело | число | статус |
|---|---|---|
| Polycount, `polycount.com/discussion/192245` | «1024 per metre is about as high as you'll see… lower than 512 per metre starts to look pretty ropey for fps» | **зріз** |
| Clinton Crumpler (PDF), inspirant.substack | 10.24 px/см (1024 px/м); третя особа — 512 px/м | **зріз** |

Наші моделі (`td.py`, scratchpad, розбір GLB у цій сесії): Choko M-0 — текстура 2048², 24 кістки, висота меша 1.70,
**992.5 px/одиницю**; Skea M-1 — **930.0 px/одиницю**. Екран (`Camera3D.keep_aspect` за замовчуванням KEEP_HEIGHT —
частка героя не залежить від ширини):

| частка героя у висоті кадру | 1080p потребує | телефон 2532×1170 (1170 по висоті) |
|---|---|---|
| 12.5 % (межа Гермеса) | 75 px/м | 81 px/м |
| 15 % / 30 % (K-1 Ареса) | 90 / 180 | 98 / 195 |
| 80 % (гіпотетичний крупний план ульти) | 480 | 520 |

Висновок-розрахунок: у бою екран бере ≤ 195 px/м, текстура дає 930–990 → запас **×4.8–5.1**, GPU семплює ≈ 2-й mip
(512² із 2048²). Мила нема; є запас пам'яті. 2048 потрібні лише на крупному плані ≥ 80 % кадру. Чи стискати на
mobile — Аполлон і Гефест.

## 4. (г) Живе тіло — що є в Godot 4.7 і відкрито

### 4.1 Вбудовані модифікатори скелета — версія появи

Метод: HTTP-код `raw.githubusercontent.com/godotengine/godot/<тег>/doc/classes/<Клас>.xml` (агент по всіх; у цій
сесії вибірково перевірено `TwoBoneIK3D`: 4.5-stable → 404, 4.6-stable → 200).

| клас | з версії | що дає | під наш риг Meshy (24 кістки) | вердикт |
|---|---|---|---|---|
| `PhysicalBoneSimulator3D` | 4.3 | регдол, `influence` 0..1 — фізика поверх анімації | усі 24 кістки | **взяти** (вже в [[2026-10-02-Engine-Physics]]) |
| `TwoBoneIK3D` (+ `FABRIK3D`, `CCDIK3D`, `JacobianIK3D`, `SplineIK3D`) | **4.6** | стопи на нерівному, рука до цілі (картка `new_ik` релізу 4.6: «feet to plant on uneven terrain») | ланцюги `LeftUpLeg→LeftLeg→LeftFoot`, `LeftArm→LeftForeArm→LeftHand` є | **взяти** — В3/В6 [[2026-10-03-Living-Combat]] |
| `LookAtModifier3D` | 4.4 | голова й корпус на суперника | `neck`, `Head` є | **взяти** |
| `LimitAngularVelocityModifier3D` | 4.6 | стеля кутової швидкості кістки | будь-яка | **взяти** — згладжує ривки ретаргету |
| `SpringBoneSimulator3D` | 4.4 | волосся, тканина | кісток волосся/тканини **нема** | **адаптувати**: додаткові кістки (Аполлон/Гефест); див. [[2026-10-03-Toon-Quality-Cloth]] |
| `BoneConstraint3D`, `AimModifier3D`, `CopyTransformModifier3D` | 4.5 | обмеження й копії трансформів | — | за потреби |
| `SkeletonIK3D` | — | deprecated у 4.7.2 | — | **ні** |

### 4.2 Аддони (LICENSE відкрито через raw; дати — агент)

| репо | що дає | ліцензія · Godot · коміт | вердикт |
|---|---|---|---|
| Manik2607/auto-ragdoll | майстер регдолу: маси за Plagenhoef 1983, ліміти суглобів | MIT · `config/features "4.7"` · 2026-09-22 | **взяти** для генерації; чи розпізнає імена Meshy без `mixamorig:` — перевірити в редакторі |
| PiCode9560/Godot-4-Active-ragdoll | active ragdoll (Human Fall Flat) | MIT · Godot 4.3 · дата UNGROUNDED | **референс** |
| cberry22/active-ragdoll---physics-animations-in-godot-4.0 | `PhysicalBone3D` тягнуться силами до анімованого скелета | MIT · 4.0 · 2023-03-05 | **референс** (API старий) |
| limbonaut/limboai | BT + HSM для ШІ (частина B, R5) | MIT · v1.8.1 2026-08-20, збірка під 4.7.2 | взяти, коли дійде до ШІ (Дедал) |
| MMMaellon/renik | IK тіла | MIT · модуль Godot 3 · 2020 | **ні** — замінює `TwoBoneIK3D` |
| R3X-G1L6AME5H/Godot-Active-Ragdolls | RigidBody + 6DOF | MIT · Godot 3 | **ні** |

Навчальний референс: David Rosen, GDC 2014 «An Indie Approach to Procedural Animation» (Overgrowth) — **зріз**: мало
ключових кадрів, фізика відгуку під ними. URL у Vault не отримано.

### 4.3 PD-суглоб для «живого» тіла — розрахунок і межа стабільності

`kp = (2πf)²·I`, `kd = 2ζ(2πf)·I`, dt = 1/60 (`project.godot:225`). Агент, `pd.py`:

| f, Гц | ζ | ω·dt | встановлення 2 % | переліт |
|---|---|---|---|---|
| 4 | 0.7 | 0.42 | 0.23 с | 4.6 % |
| 6 | 0.7 | 0.63 | 0.15 с | 4.6 % |
| 6 | 1.0 | 0.63 | 0.155 с | 0 |
| 8 | 0.7 | 0.84 | 0.11 с | 4.6 % |
| 8 | 1.0 | 0.84 | **розходиться** у напівнеявному Ейлері (ρ = 1.032) | — |

Межа з першоджерела (відкрито в цій сесії): Jolt `Docs/Architecture.md:545` — «Valid frequencies are in the range
(0, 0.5 * simulation frequency]… For a 60 Hz physics simulation, 20 is a good value for a stiff spring»; `:553` —
Jolt інтегрує симплектичним Ейлером. Jolt `SpringPart.h` посилається на Erin Catto, GDC 2011 «Soft Constraints» —
неявний крок «unconditionally stable». Тобто: пружини тіла через `SpringSettings` Jolt (частота + демпфування) —
стабільні до 30 Гц; самописний явний PD — ризик уже на 8 Гц.

## 5. Що лишилось відкритим

1. **Storm-камера в числах** — UNGROUNDED; потрібен замір 60-fps відео (Santos/Арес) або доступ до YouTube.
2. **SpiderHeck у числах**, Eiserloh дослівно, Keren GDC 2015, Nesky — UNGROUNDED (403).
3. Phantom Camera на Godot 4.7 — не зібрано; `make check` на гілці (Гефест), рішення «плагін чи своє» — Дедал.
4. Модель 1.70 м ↔ GDD 1.8 м (N7) — Гефест / Аполлон.
5. auto-ragdoll на іменах Meshy, PD на `PhysicalBone3D` у Jolt — заміри в редакторі.
6. Правило масштабу VFX — Аполлон, з дефолту 1 м квадрата й заміру кадрів референсів.

## Related
- [[2026-10-03-Ares-Smart-Camera-Alive-Fight]] · [[02-Combat-System]] · [[04-Grapple-System]] · [[ADR-018-Camera-Frames-Fight-With-Air]] ·
  [[ADR-015-Solo-Camera-Behind-Fighter]] · [[ADR-004-Physics-Is-Presentation]] · [[2026-10-03-Combat-Numbers-Grounding]] ·
  [[2026-10-03-Free-Movement-References]] · [[2026-10-02-Engine-Physics]] · [[2026-10-03-Toon-Quality-Cloth]] ·
  [[2026-10-03-Fight-Craft-Research]] · [[2026-10-03-Living-Combat]] · [[06-UI-UX]] · [[VFX-Direction]] · [[state]]
