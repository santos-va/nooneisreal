# state — поточна правда

**Оновлено:** 2026-10-05, T1 — вузький план [[2026-10-05-Eyelid-Anchoring]] закрито після повторного native-приймання посадки очей; журнал [[2026-10-05-Eyelid-Anchoring-Session]]. Попередні овали над очима відхилено; чинний доказ — original aperture, protected forehead pixels і фази моргання. Статус виконання та перевірки — у поточній секції T2 нижче. Godot 4.7 збережено; доставка на Mac окрема.
**Фаза:** прохідний 3D-квартал Cronshift і локальний бій інтегровані; напрям розвитку — спільне місто, далі бої всередині нього. Чинний художній еталон — свіжі окремі текстури/вирізки Higgsfield; старі панорами — чернетки. Santos повідомив про приймання попереднього зрізу на M3; фінальний арт і вимірювання FPS залишаються окремими.

## Поточна реалізація T2: посадка очей і прив'язка повіки, 2026-10-05

За [[2026-10-05-Eyelid-Anchoring]] виправлено відхилений Santos світлий овал над очима. Верхня повіка закриває лише справжню eye aperture між виміряними upper/lower UV landmarks; райдужка читається з нерухомого original UV, повіка лишається в межах вихідного контуру; protected ділянки брів, лоба й волосся при морганні незмінні. Native markers перевірили actual surface anchors. Геометрія, вихідні atlas/GLB, gameplay, outline, body materials та mouth controls не змінені — [[2026-10-05-Eyelid-Anchoring-Fix]].

T6 і T1 особисто прийняли scoped eye placement на однаковій нейтральній експозиції: front/3⁄4 half/closed, actual timer phases 0→0,707→1→0,707→0, hurt/KO. Незалежний oracle, визначений за original neutral до candidate, відхиляє старий closed на шести forehead/brow/hair patches; новий candidate має exact pixel delta 0 на всіх шести та позитивне закриття чотирьох aperture (Choko225/168, Skea96/41 pixels). Eye focused **1742/0**, gear **7946/0**, rc0 clean. T2 особисто прочитав `eye-correction/validation/review-check.log` і `.rc`: **112 GDS/0**, smoke **164/19847**, rc0. Фінальні gates особисто прочитані T2: **112 GDS/0**, **175/175 assets**, wikilinks/roles чисті, rc0. Вузький eye fix завершено. До/після перевірок незмінні **779 sources**, digest `c09463ae8cfc28bf8914205976a5acef5fe983c5638c74043c7bc5af9a1dbc03`. Evidence `/workspace/nooneisreal-evidence/eye-correction/` містить old/new native, калібрування, exact source manifests і raw. Повну81 батарею для вузької shader/profile зміни повторно не заявляємо.

Межа: поверхнева повіка не є анатомічним facial rig. Незмінена попередня міміка рота Skea при dim-close 3⁄4 KO має ламаний rim, у front hurt — ступінчастий шов; T6 зафіксував це окремо, mouth art не приймається цим eye fix.

## Попередня реалізація T2: міміка, матеріали героїв і відгук бою, 2026-10-05

Виконано [[2026-10-05-Expressive-Heroes-And-Combat]]. На вихідній поверхні Choko/Skea працюють локальні вирази: детерміноване моргання, зосередження, реакція на удар і KO. Вирази читають фізичний час і стани; повторні render callbacks не прискорюють їх, hitstop/freeze утримують позу, restart/rewind прибирають старий вираз. Локальний shader використовує оригінальний atlas; анатомічний facial rig та audio lip sync не додавали. Після відхилених native кандидатів усунуто чорні уламки inverted hull на закритих очах: hull вимкнений у виміряній безперервній ділянці голови, вихідне волосся збережене — [[2026-10-05-Hero-Facial-Expression]].

Локальна маска зменшує запечені світлі плями на дозволених ділянках рукавів і передньої нижньої тканини Skea; контур тіла зменшено до 6 mm. Захищені фактичні кисті, голова, шия, взуття, символи, рюкзак та Choko; вихідні GLB/atlas, геометрія, UV, skin weights й усі LOD збережені. Білі запечені позначки на грудях і верхньому плечі залишаються: прийнята локальна корекція, повного перемалювання atlas немає. Художні сили й тривалості — PLACEHOLDER. Деталі та точні межі pixel/anatomy доказів — [[2026-10-05-Hero-Material-Readability]].

Наступне натискання кінцівки під підтвердженим normal hitstop зберігається в одному слоті зі своїм первісним віком; поза власним hitstop чинні шість тактів знову спливають. Продовження починається після active, без четвертого удару, повтору утриманої кнопки чи обходу skill/dodge priority. Whiff/block не відкривають захищений слот; свіжий generic late-recovery buffer збережено. Grounded hitstun повертає утриманий дозволений блок у перший такт після stun. Menu/control lock/freeze/interruption/reset/rewind очищають захищений намір; revision fencing і disconnect не дають воскресити старий запис, історії двох гравців ізольовані. Це очищення pending continuation, не нова глобальна політика всіх натискань під lock/freeze. Damage/frame data, кути блока й хитбокси незмінні — [[2026-10-05-Combat-Intent-And-Guard]], [[02-Combat-System]].

T2 особисто прочитав фінальні raw та rc на Godot **4.7-stable** у `/workspace/nooneisreal-evidence/expressive-heroes/validation/`: `review-check.log` — smoke **164 checks / 19847 frames**, rc0; `review-gates.log` — **112 GDS / 0 parse failures**, **175 assets**, 0 broken wikilinks, зелена батарея, rc0; `playable-final.log` — **81 сценарій / 0 failures**, rc0. Фінальні case logs підтверджують **hero-face1734/0**, **combat-intent160/0**, **hero-gear7946/0**, **city-parkour73/0**. `final-raw-scan.json` фіксує 81 raw log і **0 unexpected errors/warnings/leaks**; очікувані негативні assertions прийняті strict runner. Власний скан усіх case logs не виявив warnings, script errors або leaks. До/після runner незмінні **779 sources**, digest **`916816f998abde2b91315cbdf77092b16918c792cae6dfc19942f38e6bd8339b`** — `playable-source-before.json` / `playable-source-after.json`.

Незалежний T4 підтвердив повну батарею та негативні controls для menu epoch, повторного face serial і фактичних anatomy/LOD corners — [[2026-10-05-Expressive-Heroes-And-Combat-Review]]. T6 прийняв фінальні front/3⁄4/body та вирази обох героїв — [[2026-10-05-Hero-Face-And-Material-Audit]]. Особисто прочитаний `/workspace/nooneisreal-evidence/face-combat/final-sequence/receipt.json`: **156 native PNG**, rc0, **280 captured code sources незмінні**. `hero-face-demo.mp4` — 5 s / 150 frames / 30 fps / 960×720 з цих native кадрів; body pose навмисно утримується у fixture, це не запис реального бою. Фінальні `hero-face-sequence-sheet.png` та `hero-materials-before-after.png` збережені поруч; native має лише відоме llvmpipe VSync warning.

Godot 4.7 збережено: [[2026-10-05-Hero-Tools-And-Engine-Compatibility]] не встановив виміряного blocker для downgrade. Це локальний перевірений зріз; апаратний M3 FPS/feel, фізичний геймпад, слухове приймання та оновлення встановленого macOS застосунку цими результатами не підтверджені.

## Попередня реалізація T2: чуйна мотузка й міський паркур, 2026-10-05

Виконано [[2026-10-05-Responsive-Parkour]]. Міський гарпун має коротший замах без гальмування руху, швидші політ і підтягування та виразніше підкачування; дуельний і ворожий профілі збережено. На однаковій тестовій мішені підтверджений контакт скоротився з 45 до 18 ticks. Кінцевий запас, досяжність руки, swept collision, ліміт підтягування 1,2 м та відчеплення без boost лишаються чинними — [[2026-10-05-Responsive-Rope]].

Обидва герої захоплюють доступний уступ під час jump + руху в стіну; повторний jump після відпускання запускає підйом. Skea отримав одну обмежену серію стінних кроків до нового контакту з підлогою. Є навчальний уступ і маршрут сходинками до даху, перевірка реальної опори/вільного місця та collision видимих архітектурних виступів — [[2026-10-05-City-Parkour]]. Анімації читають фактичне переміщення, точки кистей і повний shoe footprint; підтримка стоп не продовжує пілястр у нескінченну площину. Контакт мотузки не підмінено позою, а спорядження зберігає чинні геометричні допуски — [[2026-10-05-Parkour-Motion]]. HUD показує доступні дії та вичерпаний хід підтягування. Нові фізичні й художні параметри — PLACEHOLDER до ігрового приймання.

Фінальну інтеграцію **Godot 4.7 stable** T2 особисто звірив у raw-журналах `/workspace/nooneisreal-evidence/responsive-parkour/validation/`: `review-check.log/.rc` — smoke **164 перевірки / 19 847 кадрів**, rc0; `review-gates.log/.rc` — **109 GDS / 0**, **175/175 assets**, зелена батарея; `playable-final.log/.rc` — **79 сценаріїв / 0 failures**, rc0. У 79 окремих raw-журналах немає WARNING/SCRIPT ERROR або неочікуваних runtime errors; навмисні mutation assertions відокремлені. Серед них механіка паркуру **73/0**, parkour motion **15 466/0**, city hook gear **2 978/0 на 276 позах**, hero gear **7 930/0**. Source manifests T4 до/після та фінальний `playable-final-source.json` мають однаковий digest `ff65c07d15eae5b17b236c29ff981577de44edf6b6d110e36488cf4574f1e444`. Початковий aggregate **78/2** збережено й не зараховано: виправлено реальний контакт передпліччя з тканиною та audio teardown тестового fixture; після цього виконано повний повтор.

Окреме scoped native-приймання T6 — **250 PNG / 500 ticks**, включно з явно позначеним Skea low-hook fixture, — [[2026-10-05-Parkour-Visual-Audit]]. Докази й демо: `/workspace/nooneisreal-evidence/parkour/visual/`. Це перевірений локальний зріз; M3 feel/FPS, всі фасади й camera modes, слухове приймання та оновлення встановленого macOS застосунку цими результатами не підтверджені.

## Попередня реалізація T2: спорядження героїв і короткі краї тканини, 2026-10-05

Виконано вузьку геройську частину [[2026-10-05-Equipment-And-Cloth]]: аналоговий годинник Choko, тонкий гримуар ∞8 зовні baked рюкзака Skea, поясні кунаї та cel-поверхні наявних інструментів. [[2026-10-05-Hero-Equipment-And-Cloth]] містить точні межі, відхилені candidates і докази. Cached garment mask додає деталі лише дозволеним cloth-регіонам; face/skin, atlas, UV, skin weights та всі 3 LOD збережені. Кеш не додає skinned трикутників. Shared GearSurface використовується лише окремими garment/tool мешами; camera policy ізолює hero uniforms від NPC і відновлює late/nested матеріали після виходу.

Обмежений вторинний рух читає фактичне прискорення, не змінює скелет або gameplay. Choko має 60-мм краї на фактичній mesh facet; Skea — короткі 25-мм кінці ремінця (скорочені зі 100 мм за виміряними crossed-arm contacts). Це не повна cloth simulation. На gameplay-відстані Skea tabs малопомітні; native close підтверджує посадку книги/годинника, без жорстких waist bars. T6 static 30 + close 12 кадрів поточного source записані без shader/runtime помилок; motion-приймання охоплює 1 800 native кадрів і чотири оглянуті sheets; цей запис документований як geometry-only зі старими поверхнями. Новий hook render зупинено за steering, незалежні numeric hook guards збережені.

Прийнята motion-база T2 до окремого emblem delta нижче: `HeroGearPresentation b9db31123d0d`, mask `4659ca51`, camera policy `0bc164d7`. Permanent hero regression **7 925 / 0**, включно із 7 точними actual-body/hook poses, 0 skin intersections / invalid shapes, позитивним pin margin **0,535807–3,191756 мм** при незмінних межах 0,5–4 мм. Незалежний T4: **54 / 54 actual poses**, 0 intersections/invalid; natural render 30/60/120 при physics 60 — по 480 rows / 482 callbacks, exact-ідентичні cloth/body/bones на спільних ticks. Native mask прийнятий окремо з захищеними face/skin/baked backpack. Production commit — `f6d31fa7a4b7e873e696276dab0e844c9694a7cf`. T1 підтвердив smoke **164 / 19 847 кадрів**, corrected runner **76 / 0** до окремої surface correction; після неї current gear **7 930 / 0**, muted presentation **230 / 0**, фінальні gates **106 GDS / 0**, **175 / 175 assets** і native Compatibility camera **4 / 0**, raw clean. Перший native Exact-SHA PCK `f6d31fa` відхилено: **137 перевірок / 2 camera-isolation failures**, native trace довів fixture-only lazy shader default `null → 1` при коректних clone/fade/reset pointer. Після виправлення лише verifier прийнято exact-SHA пакет **0.5.0** source `08b443dcbfe544a1624ed48569a4089eb31a71be`: game тотожний `f6d31fa`, native Compatibility з порожнього cwd **137 / 0**, rc 0, raw clean. PCK **208 767 116 байтів**, SHA256 `aade8b44a80061f298418bd201a366b19e78fa15fa04f95d42d0ef50da0ac8d9`; незалежна звірка T1 і докази в `/workspace/nooneisreal-evidence/district-close/pck-08b443d/{native.log,evidence.json}`. Це не підтверджує оновлення встановленого macOS застосунку. Фінальний CI очікується в [PR #178](https://github.com/santos-va/nooneisreal/pull/178). Повний runner після surface delta тут не заявлений.

Важливий контрприклад збережено: strict chest-bone candidate `c5ef` давав порожні Skea pins, тож первісний одноразовий triangle oracle помилково бачив нуль контактів. Positive pin/link guards відхилили candidate; geometry acceptance відкликано, oracle посилено count/area/finite передумовами, production отримав unsupported/invalid guards. Старий waist-pin negative control також відхиляється реальною skin-intersection регресією. Не переносити старі GREEN на інший hash.

Після прямого уточнення Santos помилкові чотири круги на гримуарі замінено одним горизонтальним violet ∞ з підписаного [[2026-10-05-Equipment-Canonical-References]]. Scoped `HeroGear d1e0719a` / shader `aa191264` — **7 930 / 0**, raw clean. Motion-частина прийнятого `b9db` не змінена; новий glyph має окреме завершене native reference-приймання T6 і T1: 18 poses + 6 close, чисті журнали, підтверджені back close та gameplay back. Докази — `/workspace/nooneisreal-evidence/gear-readability/reference-correction/`. Докладний delta — [[2026-10-05-Hero-Equipment-And-Cloth]].

Шість оплачених provider PNG (63 credits) ще заблоковані для завантаження; їх немає у shipped ресурсах і samplers мають strength 0. Реально підключений original `cloth_weave.svg` використовується CityCosmetics; нові карти не підмінено заглушками. Підготовлено mean-centered neutral fabric slots і окрему full-UV/raw-albedo cover face. Пов’язана робота інших смуг: [[2026-10-05-Equipment-Sword-Craft]], [[2026-10-05-NPC-Tailoring-And-Cloth]], [[2026-10-05-Gear-And-Cloth-Review]], [[2026-10-05-Equipment-Visual-Audit]].

## Попередня реалізація T2: цілісний рух і фізичні сигнали, 2026-10-05

Кандидат **0.5.0**, продовження [[2026-10-05-Whole-Body-Motion]]; підсумок і подальша доставка — [[2026-10-05-Whole-Body-Checkpoint]]. Таз, хребет, шия й голова узгоджені під час розгону, зупинки, повороту та зміни стійок. Погляд калібровано за реальною анатомією обох героїв; авторська дуга удару не затискається на сталому pitch. Під час висіння корпус і ноги реагують на фізичну опору, кисті зберігають контакт — [[2026-10-05-Whole-Body-Presentation]].

Стопи враховують повний skin підошви й справжню поверхню: підлогу, рампу, дах або WaveField. Контактні фази наявних CC0 UAL відокремлюють опору від swing/toe-off; у повітрі контакт відпускається. Standing удари й реакції отримують корекцію проникнення, без примусового опускання ударної ноги — [[2026-10-05-Hero-Ground-Contact]]. Grounded WINDUP зберігає рух ніг, поки тіло фізично гальмує; cadence читає відстань уздовж опори. Restart/rewind явно скидають історію замість помилкових 600 м/с анімації. Gameplay trajectory, бойові кадри, hitboxes, запас мотузки та RNG не передані презентаційним helpers — [[2026-10-05-Physics-Motion-Signals]].

Інтеграційні результати T1 звірено з raw-журналами `/workspace/nooneisreal-evidence/whole-body/validation/`: smoke **164 перевірки / 19847 кадрів**, фінальний playable **73 сценарії / 0 failures** зі збереженням усіх попередніх 70; whole-body **12686/0**, ground-contact **5407/0**, physics-motion **1149/0**. Gates: **102 GDS / 0**, **174/174 assets**, батарея зелена. HTTP protocol/Director **34/0 + 17/0** (без real-model inference), native Compatibility camera **4/0**, distribution **25/0**. Перший aggregate мав shutdown-витік аудіо нового physics-тесту й не зарахований: виправлено лише teardown, після чого повтор усіх 73 сценаріїв пройшов без неочікуваних runtime/shader errors і витоків. Подробиці виправлення — у Fix фізичних сигналів.

Незалежні межі та native-послідовності обох героїв — [[2026-10-05-Whole-Body-Anatomy-Review]] і [[2026-10-05-Whole-Body-Visual-Audit]]. Вартість опори на WaveField лишається виміряним обмеженням; Linux CPU probe не є FPS на M3. Source `d27b60821f264c0b407ad844e128ede299d698f5` має перевірений exact-SHA пакет **0.5.0**: native Compatibility PCK **86/0**, SHA256 `5176551e558d197412fbf6800671952aca92f3a8ad9eb6a4c7f64249909f259a`; деталі — у checkpoint. Фінальний CI актуальної вершини гілки відстежується в [PR #178](https://github.com/santos-va/nooneisreal/pull/178) і тут не заявлений зеленим. Цей розділ не стверджує оновлення встановленого macOS застосунку чи апаратне приймання Santos.

## macOS застосунок та канал main — реалізація T8, 2026-10-04

Додано universal macOS export preset, build-скрипт із `NIRBuildRevision` до ad-hoc підпису, перевірку metadata/arm64+x86_64/PCK, офлайн Installer.command і per-user updater. Updater перевіряє hash/розмір/bundle/signature, відкидає небезпечні ZIP до extraction, відкладає заміну відкритої гри, відновлює backup після перерваного rename й не чіпає Godot saves. Workflow main має окремі build/read та publish/write jobs, перевірку реального bundle й exported smoke на macOS перед публікацією immutable SHA release та manifest каналу. [[Export-Platforms]] · [[Build-and-Run]].

На Linux реально виконаний Godot 4.7-stable export; перевірений проміжний пакет у `/workspace/scratch/mac-app-build` містить universal Mach-O/PCK і SHA бази `e27b746`. Це ще не фінальна committed збірка. Updater adversarial tests **14/0**; використані OS mocks не є macOS-прийманням. Реальна M3-інсталяція, launchctl/login, Gatekeeper, слухове приймання й FPS не перевірені. Workflow ще не запускався у GitHub; після commit потрібна фінальна збірка з його SHA. Художня іконка не завантажена, діє явний fallback `game/icon.svg`, без твердження про інтеграцію нового арту.

## Довантаження після merge — реалізація T8, 2026-10-04

За уточненням Santos updater довантажує лише змінені 4 MiB-блоки точного підписаного bundle, включно з executable/signature і PCK; schema1 full ZIP лишається сумісним зі старим updater та offline installer. Малий NoOneIsReal-Updater.zip реєструє новий updater поверх наявного перевіреного app без мережі й повторного завантаження гри. Manifest/index/chunk/file hashes, строгі шляхи й casefold-перевірки, codesign/arm64, fresh stage, running guard та rollback збережені.

Локальна батарея **21/0**; незалежний фактичний proof `e27b746 → 1793559`: **22 921 549 B** з index проти **265 941 840 B** full ZIP, **91,38%** менше; 87 локальних блоків/9 завантажених, усі 7 кінцевих файлів і права byte-exact. Це конкретний замір, не гарантований розмір майбутніх дельт. PR CI включає updater tests, майбутній native macOS publish gate — змішану реконструкцію й справжній codesign. Реальна M3/LaunchAgent-інсталяція та запуск нового workflow ще не перевірені. [[Export-Platforms]] · [[Build-and-Run]].

## Відновлення локального Mac installer — T8, 2026-10-05

Після повідомлення Santos про відмову Godot-version helper перевіряє кожен
кандидат, пропускає старий/недоступний `GODOT_BIN`, підтримує command-name,
headless version banner/CRLF та продовжує до офіційного SHA512-verified download.
Середовище й checkout не змінюються; помилка downloaded binary показує шлях і
фактичний вивід. Регресії включають fallback/checksum і різні pinned SHA/HEAD.
Фактичний повторний запуск на M3 ще очікується; [[2026-10-05-Mac-Installer-Recovery]].

## База й джерела правди

- [PR #170](https://github.com/santos-va/nooneisreal/pull/170) змерджено 2026-10-04 о18:37:42 UTC; merge `2c50938`, пакет `1773ac2`. #164–169 також входять у цю базу. Це вже не неопублікована локальна робота.
- [CI пакета #170](https://github.com/santos-va/nooneisreal/actions/runs/37224056701) завершився успішно. Перевірка не є художнім або апаратним прийманням гри.
- Для нової роботи спочатку `git fetch`, робоче дерево й актуальний GitHub: цей файл — датований знімок. Поточні кнопки визначає `game/scripts/core/InputRouter.gd`; запуск — [[Build-and-Run]].
- Короткий англомовний маршрут: [[Handoff/2026-10-04-Start-Here]], [[Handoff/2026-10-04-Delivery-Ledger]], [[Handoff/2026-10-04-Decisions-And-Validation]], [[Handoff/2026-10-04-Remaining-Work]].

## Інтегрований пакет PR #172

Пряме доручення Santos — [[Plans/2026-10-04-Living-City-Traversal]]. Попередній фікс `f1c147d` запушено до запуску шести смуг; інтегрований пакет `f17cba3` — після технічного T4 огляду [[2026-10-04-Living-City-Review]]. У PR: камерний приціл/мотузники й повернення до залишених мотузок, окреме ухилення зі stamina поряд із signature dash, компактні підказки/зручніші bindings, 12 постійних NPC з memory/save і seed-зовнішністю. Це фундамент району, не завершена симуляція життя чи сюжетна кампанія. Справжні три біти Santos Soundtracks недоступні; Music та importer готові, manifest порожній. LLM backend не підключено. Mac/4.7 і художнє приймання відкриті.

## Попередня реалізація T2: живі мешканці та близький контакт, 2026-10-05

Source candidate **0.5.0**, база merged #177 `f4defd5`, виконання [[2026-10-05-Living-District-Characters]]. Pre-grab тепер перевіряє ≤0,70 м від поточної руки до авторитетного сегмента без прогнозу руху; NPC prompt і відкриття розмови спільно перевіряють ≤0,70 м між поверхнями, висоту й видимість. Працівники доступні збоку прилавків, без винятку на далеку розмову. Камера показує обличчя ліворуч від адаптивної правої панелі, зберігає solid collision та повертає ручний огляд — [[2026-10-05-Rope-Contact-Range]], [[2026-10-05-Close-NPC-Conversations]], [[2026-10-05-Conversation-Camera]].

Дванадцять NPC мають особисті контекстні репліки, окрему історію знайомства й чинну per-hero довіру; під час розмови зупиняється лише співрозмовник. Невірні Variant-типи identity у сейві відкидаються атомарно без runtime error. Три seed-фенотипи, робочі реквізити, плавні жести й обмежений просторовий невербальний звук описані в [[2026-10-05-Fantasy-Residents-And-Chatter]]. Авторські UAL-жести кидка, хвату, підтягування, перенесення й повернення адаптовані до обох героїв; physics trace, запас і RNG не змінюються — [[2026-10-05-Authored-Hook-Motion]].

Необов’язкові локальні репліки вимкнені за замовчуванням: фіксований loopback Ollama/tag, async timeout, кеш і відкидання застарілих відповідей, негайна авторська запасна репліка. Модель не керує завданнями, довірою, нагородами або сейвом. **Реальні ваги та inference не перевірені**: мережевий доступ до ваг заблокований policy 403; перевірки fake HTTP server не є доказом роботи моделі. Джерела, ліцензії й ручне локальне налаштування — [[2026-10-05-Local-NPC-Models-And-Physics-Reuse]].

T1 підтвердив інтегровані **70/0 playable**, smoke **164 перевірки / 19847 кадрів** і gates **99 GDS/0**, зі збереженими 62 попередніми сценаріями та негативними контролями. Окремий HTTP protocol/Director — **34/0 + 17/0**, close-dialogue — **107/0**, malformed-save — **272/0**. Native UI 720/900 показує справжніх героїв і працівників; фінальне незалежне приймання й exact-SHA export/PR фіксують [[2026-10-05-Living-District-Review]] та [[2026-10-05-Living-District-Session]]. Це ще source candidate, не твердження про встановлену 0.5.0 на Mac. Попереднє приймання Santos на M3 не є виміром FPS/RAM цього пакета. Online/spільне місто — наступна робота; нових героїв не відкрито, іконку в цій хвилі не змінено.

## Попередня реалізація T2: прохідний квартал PR #175, 2026-10-05

Пакет PR #175 додав три робочі місця у справжніх інтер'єрах, дев'ять нерегулярно розташованих перехожих і діалоги з вибором. Шість конкретних доручень охоплюють знайомства, доставку ниток, дах/вежу, дві різні мотузкові опори та перев'язь із виходом на ринок. Нагороди одноразові; trust/friendship/memory, завдання, жетони й кольори окремі для Choko/Skea. Старий NPC save мігрує без приписування невідомої історії одному з героїв. Тканинна перев'язь видима на герої й не перефарбовує шкіру — [[2026-10-05-District-Life]].

Геометрія й спільний API місць — [[2026-10-05-Playable-District-Art]]. Наявні UAL-джерела тепер використовуються для authored ударів через `AuthoredCombatMotion` — [[2026-10-05-Authored-Combat]]; незалежний T4 закрив blockers lowhand/hammer і кріплення меча після native-перегляду — [[2026-10-05-Playable-District-Review]]. `AuthoredLocomotion` вибирає Walk/Jog/Sprint за реальним переміщенням, зберігає ноги в русі під час гальмування й обирає Walk для повільного змотування — [[2026-10-05-Locomotion-States]]. Попередній шар завершення удару описано в [[2026-10-05-Combat-Animation]].

Меню ставить квартал і продовження обраного героя першими, HUD/журнал читають фактичний прогрес; збірка показує version/SHA — [[2026-10-05-District-Delivery]]. Оригінальна іконка лишається відкладеною, нових героїв поза Choko/Skea не відкрито. Декларативний JSON має whitelist і не є менеджером довільних модів.

На production `0999c77` незалежний T4 дав GREEN перевіреному зрізу; інтегрований playable завершився **57/0**, gates — **87 GDS/0**. Чинні докази, точні журнали й PR-стан — [[2026-10-05-Playable-District-Session]] та [[2026-10-05-Playable-District-Review]]. Це не приймання встановленого застосунку: повне 30-хвилинне ручне проходження, апаратний FPS, фізичний геймпад і Mac/M3 залишаються відкритими.

## Попередня реалізація T2: city-action-polish, 2026-10-05

Звірено змінені файли у робочому дереві; цей розділ описує реалізацію до загального інтеграційного приймання, не встановлену збірку Santos.

- **NPC:** компактну нерухому сітку замінено окремими маршрутами вздовж вулиці; короткі парні вітання мають дистанцію, пряму видимість, cooldown і двосторонню пам'ять. Streaming відновлює позицію в межах сесії; ідентичність/save залишаються чинними. Повна навігація та сюжетні розмови не додані — [[2026-10-05-Npc-Crowding]].
- **Мотузка:** solo-підказка враховує видиму область та напрям руху; camera orbit явно переважає цей вибір. Кандидат стабілізується на physics tick, solid-геометрія блокує видимість/політ/transfer, а transfer оновлює точку цілі до витрати пристрою — [[2026-10-05-Rope-Assistance]].
- **Бойова презентація:** обмежене плавне повернення після удару до IDLE/WALK/CROUCH, очищення залишкової procedural-пози та обов'язковий останній recovery-малюнок. Новий удар/реакція/ривок переривають повернення; бойові числа не змінені — [[2026-10-05-Combat-Animation]].
- **Поверхні:** процедурний шейдер розрізняє край каменю, цегляний розчин, нахлест сланцю, дошки та переплетення тканини. Нових texture-файлів немає. `app_icon.png` досі відсутній у checkout, preset посилається на старий SVG; іконка встановленого застосунку не виправлена — [[2026-10-05-City-Texture-And-Icon]].

Локальні результати смуг наведено у відповідних журналах. Загальні `make check`/`make gates` і живе приймання Mac/контролера зазначає координатор після власної перевірки; жоден із цих результатів тут не припускається.

## База до PR #172 — звірка T2 cleanup, 2026-10-04

| напрям | чинна реалізація та межа |
|---|---|
| Бійці й керування | Видимі GLB Choko/Skea зі скелетною та процедурною анімацією; людський рух за актуальним physics-базисом камери, чотири кінцівки, трьохударні чергування, діставання/передача й переформування меча. Це прототипна анімація, не остаточне художнє приймання. |
| Ривки й ульти | Choko має 5 зарядів, Skea — 3; більше витрачених зарядів подовжує відновлення. Flash Step має видимий повітряний шлях із jump/fall momentum. Ульта Skea має левітаційну позу й фіолетову хвилю, що розширює звичайний удар без другої шкоди. Баланс/CD залишаються PLACEHOLDER. |
| Гарпун і матч | Запас Choko7/Skea2, контактний постріл, заборона дубля на зайнятій точці, повторне використання мотузок. Space обмежено підтягує; пологий трос тягне до опори, для підйому треба бути ближче під нею. Мотузки зберігаються між раундами та очищаються новим матчем/рематчем. Типово до 2 перемог, щонайбільше 3 раунди. |
| Міський прототип | EXPLORE CITY запускає обраного героя в окремому районі 64×64 м: колізії, рампи/дахи/міст, зачепи, камера й навчання. Фасади, мансарди, годинниковий орієнтир, чотири ятки та матові матеріали спираються на чинні окремі вирізки. Після PR #172 є 12 постійних NPC, memory/save і локальне завантаження їхніх акторів; поточні зміни описані вище. Міські бої, сюжет, портали й стримінг районів ще не реалізовані; навички/ульт/ворожий гарпун/Printer тут вимкнені. |

Джерела звірено в цій сесії: `Fighter.gd`, `DuelFrame.gd`, `SkeletalRig.gd`,
`RigAnimator.gd`, `GrappleHook.gd`, `MatchRopes.gd`, `MatchFlow.gd`, `SkeaWave.gd`,
`game/data/characters/*.tres` та `game/scripts/world/`. Довідка запуску — [[Build-and-Run]],
структура — [[Architecture]]. Звукова бібліотека й події є; слухове приймання не завершене.

**Фінальна перевірка cleanup**, особисто перечитана T2 у raw-журналах координатора:
`current-state-cleanup/playable-final.log` — `make check-playable`, smoke
**164/19847 кадрів**, **43 сценарії/0 помилок**; `gates-final.log` — **БАТАРЕЯ ЗЕЛЕНА,
70 GDS/0 помилок парсингу**. Журнали: `/workspace/nooneisreal-env/current-state-cleanup/`.
Виправлено актуальність описів/підказок і відповідне очікування smoke; нове gameplay
не додається. Native матеріали **23/0** та capture **18/0** — докази попереднього
`city-style/`, у cleanup їх не запускали повторно. Остаточний арт, комфорт, звук,
фізичний геймпад і продуктивність на M3 залишаються відкритими.

## ▶ Хвиля — поточний маршрут

[[2026-10-05-Eyelid-Anchoring]] закрито вузьким виправленням посадки очей і повторним native-прийманням. Чинний before/after — `/workspace/nooneisreal-evidence/eye-correction/eyes-before-after.png`; старий eye demo не є доказом нового результату. Повний facial rig та край рота Skea у hurt/KO залишаються окремою художньою роботою. Доставка на Mac, онлайн та нові ассети поза цим виправленням.

## Ще не завершено

- Santos прийняв попередній зріз на M3; окремі вимірювання FPS/frame-time, Retina/фізичного контролера й звуку не надані. Нові зміни потребують свого приймання.
- Фінальні мальовані лінії, деталізація кварталу, авторські анімації/баланс. Параметри руху й бою залишаються PLACEHOLDER до приймання.
- Повне місто, бої в міських кишенях, п’ять захищених NPC, сюжетний вступ, повне збереження кампанії (NPC-збереження вже в PR #172), портали, нові світи, кілька ворогів та онлайн.
- Опрацювання анатомії/відновлення після регдола, тканина/профілі якості, фінальна звукова палітра й голоси; конкретні незакриті питання — [[Handoff/2026-10-04-Remaining-Work]].
- Codex coworker: [[Plans/2026-10-04-Codex-Coworker]] та [[ADR-021-Codex-Coworker-Adapter]] — інтеграційна пропозиція; наявність документа не означає встановлений адаптер. Ручний boot з AGENTS.md чинний.

## Історія

Повний попередній state винесено до [[Handoff/2026-10-04-State-History]]. Датовані журнали й аудити зберігають свої історичні результати; виконані PR та старі числові виміри не повторюються тут як поточні призначення чи баланс провайдера.

## Нативна metadata після експорту — T8, 2026-10-05

Santos успішно пройшов import/export, але отримав GNU `stat` помилку для `%z`.
Helper тепер викликає `/usr/bin/stat`, `/usr/bin/plutil` і `/usr/bin/ditto`
явно, не змінюючи PATH для пошуку Godot/git. Розмір і SHA256 обчислюються
окремо з перевіркою статусу та формату до створення manifest. Невдала metadata
зупиняє встановлення; завершений пакет після подальшої помилки installer
зберігається в надрукованій `/tmp/nir-completed-package.*` директорії для retry.
Офіційні editor/template downloads кешуються в `~/Library/Caches/No One Is Real/Installer/4.7-stable`; повторне використання щоразу звіряє SHA512 з офіційним списком, пошкоджений кеш завантажується заново. Це зменшує повторні завантаження пакета 1,28 GB.
Updater вже задає системний PATH, тому його BSD stat не затінюється Homebrew.

PR CI distribution тепер має Ubuntu/macOS matrix; на macOS metadata-regression
використовує справжні `/usr/bin/stat` та `plutil`, а PATH містить шкідливу для
цього виклику підміну `stat`. Linux використовує ізольований native shim та
справжній GNU stat на початку PATH. Перевірено відмову native stat до install.
Результат нового native CI ще очікується; усі помилки на M3 не оголошені усуненими.

## Related

- [[index]] · [[constitution]] · [[Handoff/2026-10-04-Start-Here]] · [[Handoff/2026-10-04-Remaining-Work]]
- [[Plans/2026-10-04-City-Style-Match]] · [[ADR-022-Combat-Control-And-Match-Resources]] · [[ADR-023-City-First-Exploration]] · [[Meetings/2026-10-04-Current-State-Cleanup]]
