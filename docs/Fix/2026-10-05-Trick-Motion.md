# Презентація відштовхування й перекату

2026-10-05 · T2 Гефест · [[2026-10-05-Parkour-Tricks-And-Quality]].

**Статус:** реалізацію й scoped motion-приймання завершено; відкрита camera limitation і апаратні межі наведені нижче.

Предмет: для всіх нових міських trick-поз анімація читає стан фізичного motor, не змінює authority, не розтягує кістки й не ховає skinned floor/gear проникнення.

## Звірка та рішення

Перечитано state, конституцію, роль T2, чинний ParkourMotion/SkeletalRig, authored landing/hook, старі parkour regression/native captures. JSON усередині встановлених CC0 UAL GLB підтвердив `Roll` (1,4667 с) та `WallRun_Jump_L/R` (0,7333 с). Нові ассети не потрібні. Реалізація обмежена двома metadata phases із [[2026-10-05-Parkour-Tricks-And-Quality]].

Перекат потребує вертикальної компресії таза з source; горизонтальне source переміщення відкидається. Звичайні grounded landing/stance/foot/gaze overlays під час цього цілісного руху не застосовуються. Фізична капсула незмінна. Wall kick використовує rotations-only із поверненням до звичайного air silhouette на виході. Усі художні blend-числа — PLACEHOLDER.

## Перевірка

Додано `tools/animation/trick_motion_check.gd`: незмінність gameplay authority, finite/реальні довжини кісток, повторна ретаргетація, whole-body skinned floor, cloth/pin margins і stale metadata. Перший Godot 4.7 прогін: **3 261 602 / 74 failures**, raw `validation/motion/first.log` у `/workspace/nooneisreal-evidence/parkour-tricks/`. Source roll проникнув у підлогу до **0,234437 м** (Skea). Збережено початкові source copies/hash. Обвід за окремими bone hulls не прийнято: він прибрав проникнення, але давав **0,98 м** зависання через маловагові skin influences.

Наступний кандидат обчислює точну зважену відстань всієї skin до фактичної площини лише раз на physics tick; повторні callbacks використовують той самий offset. Корекція в обидва боки тримає наземний перекат на опорі; доданий двосторонній floor guard і CPU timing probe. Цей кандидат ще не прийнятий.

Перевірка повного callback (разом зі спорядженням) також відкрила старий дефект Choko pin normal: знак deformed triangle підмінявся blended shading normal, що під час roll дало **−3 мм** замість чинних **+3 мм**. За погодженою вузькою правкою normal читає Godot clockwise indexed facet, як незалежний cloth oracle. Shape/stand-off й допуски незмінні; старі hero/city-hook gear regressions обов’язкові. Native actual-input capture та інтеграційні результати додаються після перевірки.

## Точна опора без важкого кожного кадру skinning

Повний weighted projection був геометрично правильний, але перший Linux CPU probe дав median **14,230 / 22,500 мс** для Choko/Skea; цей варіант відхилено. Bone-hull union теж відхилено через зависання. Чинний `RollGroundSupport` групує справжні weighted influences за bone IDs/просторовою клітиною, обчислює консервативну нижню межу з weighted coordinate bounds **і діапазоном ваг**, а повний exact projection виконує лише для груп, що можуть змінити minimum. Anchor/reference offset робить межу вузькою; Packed arrays прибирають Variant casts у точній частині. Ваги/вершини не відкидаються з відповіді, approximation curve не використано.

Cache залежить від mesh, Skin і переліку bone names. Підготовка виконується під час завантаження міського актора; arena не готує ці дані. Повторний render callback не повторює solve. Видиме спорядження після свого callback може стати фактичною найнижчою опорою; додатковий root offset також кешується на тому самому physics serial. Фізична капсула, velocity, HP/RNG/ресурси й gameplay sword ownership незмінні.

Незалежний T2 physics прочитав попередній exact-helper hash `c702179af0a918f2d13d28fb4d91d7953bb41e436a153c9503c6f4bcb25de47c`: median **1,032 / 0,993 мс**, p95 **2,298 / 2,831 мс**, cold prep **248,520 / 322,722 мс**; source він не змінював. Його `support-before-flat.log` ще мав два Choko cloth failures і не був прийманням усього руху.

## Підтверджений focused кандидат

`compact-head.log/.rc`, Godot **4.7 stable**: **3 265 277 перевірок / 0 failures**, rc0, без warnings/errors/leaks. Choko short-torso/clavicle adaptation та менший authored neck/head tuck прибирають виміряне входження `headfront` у нагрудний tab; pelvis/ноги зберігають повний перекат. Ці коефіцієнти художні PLACEHOLDER. Wall kick та roll використовують наявні джерела, а не procedural заміну всього персонажа.

Independent full-skin mesh+Skin oracle перевіряє всі 49 sampled фаз обох героїв: finite/nonempty weights, незмінні limb lengths, exact repeat full callback, authority, реальну плоску опору. Видимі faces меча/книги/одягу/годинника також перевірено; Choko лишає gameplay sword drawn і проходить right/left hand intent. Чинний `SwordPresentation` автоматично прибирає видимий меч на спину на час будь-якої parkour phase та повертає його після завершення; це **не** перекат із довгим мечем у кисті. Near-floor вимір стосується **найнижчої фактичної body-or-equipment геометрії**, а не обов’язкової опори лише шкірою. Старі нижні допуски −6 мм та pin +0,5…4 мм збережені. 20 повних cloth samples — 0 intersections / 0 invalid shapes.

Фінальний локальний CPU probe цього focused source: Choko median **1,047 мс**, p95 **1,730 мс**, max **2,372 мс**; Skea median **0,971 мс**, p95 **2,417 мс**, max **5,138 мс**. Preparation **236,253 / 299,647 мс** належить loading; samples що справді потребували exact solve у фінальній фазі — **1069 / 999** із **28 520 / 33 108** body vertices. Це Linux CPU вимір вузького solver, не frame-time/FPS або M3 performance.

Native side кандидат `visual/motion-side/`: **93 PNG / 275 ticks / 0 failures**, actual InputRouter/CityFighter/CityDistrict. Початкові станції явно задані fixture, це не суцільне ручне проходження. Повний body skin після actual wall kick не перетинає wall plane: мінімум **0,198 / 0,228 м**. Roll body мінімум близько **3 мм**, максимальна відстань body від floor **0,290 / 0,117 м**, коли опирається спорядження. T6 переглянув roll side/3⁄4: фази читаються, короткий gap через опору на спорядження не виглядає тривалим зависанням; це стилізована акробатика, не анатомічна гарантія безперервного контакту лише тіла.

Первісний quarter-wall ракурс закрила стіна, тому його відхилено. Замінний `visual/motion-kicks-opposed/` має **42 PNG / 124 ticks / 0 failures**, герой видимий із протилежного підвищеного ракурсу. Геометрію світу не змінювали. `visual/motion-drawn-left/`: **25 PNG / 75 ticks / 0 failures**, з них **36** actual roll ticks з незмінним `sword_drawn=true`, `sword_hand=left`; body min **2,995 мм**, accessory min **3,000 мм**, combined nearest surface max **3,017 мм**. Цей proof перевіряє намір і чинне stow/повернення, не меч у кисті під час roll. Усі фінальні native raw мають лише відоме llvmpipe VSync warning.

П’ять production motion файлів тотожні між side, quarter, opposed і drawn captures — `native-motion-source.sha256`. Headless editor import **rc0**, без warnings/errors, згенерував `RollGroundSupport.gd.uid`. Особисто прочитані production-camera raw/rc: `native-production-final` — **90 PNG / 249 ticks / 4 routes / 0 failures**, додаткові `native-production-open-choko` та `native-production-open-skea` — по **19 PNG / 52 ticks / 0 failures**, rc0. T2 відкрив Choko open-kick tick29 та Skea production-roll tick38: справжні CityCamera, освітлення, NPC й HUD збережені. T6 scoped-приймання зафіксоване у [[2026-10-05-Traversal-And-Surface-Review]]. Тісна станція `[4,0,31.4]` відкрила проблему camera proximity/stipple; її вигляд **не прийнятий** і лишається окремою межею, нова відкрита станція її не виправляє. Camera/proximity код цією смугою не змінювався.

Особисто прочитані T4 `review-check.log/.rc` та `review-gates.log/.rc` у `/workspace/nooneisreal-evidence/tricks-quality/final/`: **rc0/rc0**, smoke **164 / 19847 кадрів**, **119 GDS / 0 parse failures**, **175 assets**, зелена батарея. Власний скан не виявив engine ERROR/WARNING/leak markers. Порівняні `review-source-before/after.json` тотожні: **808** sources, digest `c5b5d42190c355cb4b416914bed8f5941d1b57a9a7def29e8311734865b7f024`. Особисто прочитані завершені case logs та `PASS rc=0` у чинному повному runner: **hero-gear 7946/0**, **city-hook-gear 2978/0** (276 поз), **parkour-motion 15466/0**, **trick-motion 3265277/0**, **whole-body-motion 12686/0**, **ground-contact 5407/0**. У цих шести raw немає warnings/errors/leaks. Сукупні **321 cloth samples** чотирьох gear/parkour/trick сценаріїв мають **0 intersections / 0 invalid shapes**; найменший legacy pin margin **+0,5358 мм** збережено. Отже narrow facet correction перевірено також старими support/combat/hook позами, не лише новим roll.

Фінальний runner CPU probe: Choko median **1,039 мс**, p95 **1,689 мс**; Skea median **0,973 мс**, p95 **2,435 мс**. Це повтор тих самих Linux CPU меж, не апаратний FPS. Повний runner особисто перечитаний після завершення: `check-playable.log/.rc` — **93 scenarios / 0 failures**, **rc0**. `playable-source-before/after.json` власноруч порівняні: **808** sources незмінні, digest `c5b5d42190c355cb4b416914bed8f5941d1b57a9a7def29e8311734865b7f024`. Перечитано `full-raw-scan.json` і самі **95** engine raw (import + smoke + 93 cases): **0 unexpected errors/warnings/leaks**; у 14 негативних запусках є лише їхні заявлені assertion errors, які runner прийняв очікуваним rc1.

Реалізацію wall-kick/landing-roll presentation та її bounded support/gear інтеграцію завершено. Це локальний Godot 4.7 зріз із scoped native-прийманням; тісна production camera, анатомічно безперервний shoulder roll, M3/Forward+ FPS і оновлення встановленого застосунку цим завершенням не оголошені виправленими чи прийнятими.

## Related

- [[2026-10-05-Parkour-Tricks-And-Quality]] · [[2026-10-05-Parkour-Motion]] · [[2026-10-05-Traversal-And-Surface-Review]]
