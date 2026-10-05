# Зброя, інструменти та одяг: якість і фізичний рух

2026-10-05 · T1 · **Статус: approved**. Пряме доручення Santos: тонкі візерунчасті індивідуальні мечі, якість усіх наявних інструментів і одягу героїв/NPC, фізика одягу. Окремо уточнено: меч треба перевернути **і на спині, і в руці**. База `4c68473ce88e167828c3425fa1ecbe3062dc96ca`, PR #178 відкритий та незмерджений за поточним API. Журнал [[2026-10-05-Equipment-Session]], попередній результат [[2026-10-05-Whole-Body-Checkpoint]].

## Аудит і погляди

До production-правок прочитані SwordPresentation, CityCosmetics, SkeletalRig, NpcAppearance та чинний Style-Guide. Меч має процедурний diamond-section mesh без UV, суцільний emerald матеріал і окремі латунні рейки. Поточні максимальні ширина/товщина — 0,23/0,066 м із `_blade_mesh`; спинне кріплення спрямовує клинок угору. Нова текстура сама не виправить цей силует чи напрям.

Hero GLB отримує один material_override на весь mesh. Тому загальний fabric shader може зіпсувати шкіру, волосся й обличчя. CityCosmetics називає sash фізичним, але зараз лише жорстко слідує за hip/neck: strap BoxMesh і belt TorusMesh не мають незалежної тканинної реакції. NPC вже мають original SVG seams/knit, проте матеріали й вільні частини одягу потребують окремого огляду. Native baseline, точний перелік інструментів і topology audit виконують T2/T3/T4/T6 у незалежних копіях до зміни їхнього напряму.

| Варіант | Наслідок | Вибір |
|---|---|---|
| Просто змінити колір меча й хитати весь mesh | Не виправляє ширину, хват, поверхні; викривляє тіло | Відхилено |
| Замінити героїв і ввімкнути повну cloth simulation | Великий re-rig, ризик втратити прийняту анатомію й M3 бюджет | Відкладено |
| Переробити наявну зброю, додати цільові UV/поверхні й обмежену фізику вільних тканинних деталей | Видима зміна без зміни бою; можна перевірити конкретний контакт/прикріплення | Обрано |

| Погляд | Критерій |
|---|---|
| Santos зблизька | Правильний напрям меча й тонкий силует, виразні персональні деталі |
| Гравець у бою | Читабельна зброя в обох руках, жодної зміни damage/reach/timing |
| Гравець у місті | Ремінці, край тканини й інструменти реагують на розгін/зупинку та лишаються прикріпленими |
| Інший герой, Skea | Власна предметна мова; не отримує Choko sword, зберігає свої чинні інструменти |
| NPC і натовп | Різні матеріали/професії, обмежена вартість на багатьох мешканцях, кешовані ресурси |
| M3 | Локальні поверхні, небагато сегментів, physics-rate update; без глобальної дороговартісної симуляції |
| Художник/модер | Профілі, ясна власність матеріалів, provenance та реєстр, без маскування незавершеного під нову texture |

## Власність і виконання

1. **T2 combat:** SwordPresentation, SwordMotion, sword_dissolve та weapon regressions. Перевернути напрям у обох руках і на спині, узгодити hand/stow mount та transition. Створити тонший профіль, UV/цільову орнаментику, grip/guard матеріали за ТЗ T6. Ульта зберігає особливу gold форму. Перед будь-якою правкою SkeletalRig узгодити з rope.
2. **T2 rope:** геройські інструменти/одяг, окремий shared equipment/garment material helper за погодженим API; SkeletalRig інтеграція за потреби. Інвентаризувати всі реально видимі поточні інструменти обох героїв і оновити їх, не створюючи неіснуючих здібностей. Додати bounded рух вільних cloth/strap частин від фактичного руху; кріплення слідує остаточній позі. Оригінальні шкіра/обличчя/волосся лишаються поза тканинним шаром.
3. **T2 npc:** NPC appearance, одяг і його вторинний рух. Розрізнювати тканину/шкіру/метал, індивідуальні seams/patches/професійні інструменти за seed. Спільні ресурси; не міняти маршрути, діалоги, identity/save або skin marks. Спільний material API узгоджується з rope.
4. **T6 art:** точне художнє ТЗ, наявні референси, native before/after, registry для кожного нового asset. Нові оригінальні векторні/процедурні assets дозволені в межах доручення; існуючі зображення не редагуються Python. Оплачені зовнішні генерації й заміна GLB не входять у цей крок.
5. **T3:** topology/API/source/performance факти, lightweight reuse. **T4:** незалежне приймання напрямку/контактів/анатомії, фізичних меж тканини, поведінки після reset/freeze та native видимості.
6. **T1:** послідовна інтеграція, snapshot checkpoints, загальні гейти, exact-commit export і PR з фінальним CI. Shared Godot запускає лише root; агенти використовують ізольовані game копії.

## Перевірка та ризики

- До/після з однаковими камерою/світлом: меч у правій/лівій руці, на спині, draw/stow/swap, атаки й гарпун; hero/NPC тканина у спокої, русі, гальмуванні, повороті, crouch/jump, розмові й роботі.
- Незалежна перевірка кінчик/руків'я/кисть і детермінантів basis; очікування старого тесту, яке кодує стару помилку напряму, замінюється новим геометричним контрактом, а не видаляється без заміни.
- Cloth anchors не відриваються від тіла; вільні сегменти мають обмежені stretch/angle/penetration, не накопичують offset, reset/rewind/freeze без вибуху. Числа художні PLACEHOLDER до native-приймання; gameplay/RNG незмінні.
- Material detail не заміняє оригінальні обличчя/шкіру. Fine ornament читається на близькій і звичайній дистанції без мерехтіння; прозорість/dissolve/camera occlusion й outline збережені.
- Ресурси кешуються; кількість mesh/vertices/materials та CPU вплив вимірюються, не видаються за M3 FPS. Всі нові game/assets мають provenance/license рядок у Textures-Registry.
- Фінально `make check-playable`, `make gates`, native Compatibility/raw shader logs, нові регресії й незалежний до/після; точний committed PCK та CI останнього head. PR мерджить Santos.

## CP1 — конкретний контракт після baseline

T2/T4 native підтвердили: first-active cut обох рук має blade forward dot −0,416; back grip близько0,726м, tip1,546м. Поточні contact tests порівнюють pose із тим самим helper і не відхиляють симетрично неправильну орієнтацію. Тому незалежний oracle використовує landmarks і фізичний зміст напрямку, не нову функцію як власне очікування.

T3 raw GLB підтвердив для обох героїв1mesh/primitive/material, один2048²JPEG atlas,24bones, жодного morph/cloth chain. SpringBone4.7 не є drop-in для scaled cm skeleton. Обрано окремі unit-scale garment/gear transforms без переприв’язки hero. Shared `GearSurface.make(kind, color, accent)` і shader належать T2 rope; T6 задає artwork/матеріальні деталі, NPC лише споживає API. Оригінальний Choko back лишається гладким; Skea ∞8 читається на grimoire/backpanel, не розкидається по тілу.

Дозволений конкретний hero scope: Choko wristwatch та чинні rope/tool surfaces; Skea grimoire, hip kunai, чинні projectile/rope surfaces; тонкі tailored garment overlays/вільні краї та straps обох героїв, поліпшений CityCosmetics. Окремий літаючий drone не додається як нова система. Обидва оригінальні outfit silhouettes і їхні тканинні кольори зберігають ідентичність; нові речі мають давати видиме поліпшення і на звичайній дистанції камери.

T4 приймання: back grip над плечем, tip униз; єдиний actual mount target для draw, правильний hand-side landmark і positive determinant; torso/head clearance, all sword variants, handoff contact guard збережений. Для тканини pinned anchors≤1мм; natural30/60/120 same-physics secondary pose≤1мм/0,1° (PLACEHOLDER); bounds/stretch/clamp виконавець фіксує до candidate. Pause/hitstop freeze й restart/teleport reset без whip, original bone/skin/gameplay/RNG/save незмінні. Camera proximity охоплює вкладені/пізні gear і відновлюється після виходу; shared NPC materials не отримують player fade. Ніякого physics-driven деформування всього героя.

## Інструментальні межі

Game Development Studio прочитано для маршруту asset→integration→visual. Локальний `game-dev` не знайдено в PATH чи відомих tool directories; цей CLI-конвеєр недоступний. Нічого не встановлюється й не підмінюється стороннім сервісом. Використовуємо чинні repository Godot/native засоби; не заявляємо receipts або валідацію від недоступного CLI. Іконка незмінна до оригінального PNG.

## Related

- [[2026-10-05-Equipment-Session]] · [[2026-10-05-Whole-Body-Checkpoint]] · [[Style-Guide]] · [[Textures-Registry]] · [[Characters/Choko]] · [[Characters/Skea]] · [[ADR-004-Physics-Is-Presentation]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]] · [[state]]
