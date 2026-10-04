# Місто спочатку: перший прохідний квартал Cronshift

**Дата:** 2026-10-04 · **Роль:** T1 Дедал · **Статус:** `approved` для плану розвитку і початку функціонального прототипу, за прямим дорученням Santos.
**Виріс з:** [[2026-10-04-T1-City-First]], [[ADR-023-City-First-Exploration]], [[Cronshift]], [[2026-10-04-City-NPC-Development]], [[Handoff/2026-10-04-Remaining-Work]].

## Намір і межа першої поставки

Santos: спочатку спільний відкритий світ-місто, місця боїв визначати всередині нього; існуючі карти поки не чіпати. Далі сюжетний вступ із навчанням, інші світи через портали. Потрібна справжня3Dглибина намальованого світу, наявні й майбутні текстури/Higgsfield; щонайменше три паралельні Гефести з якісною перевіркою.

Перша поставка — функціональний район64×64м (PLACEHOLDER з попереднього брифу) з вулицями, справжніми фасадними об'ємами,4м проходом, похилою рампою, дахами на4м, мостом, видимими зачепами та3кандидатами місць бою. Вхід окремою кнопкою меню; герой обирається чинним P1 picker. Наявні арени, їхні STAGES/ROTATION, бойові дані та попередні незакомічені виправлення зберігаються. Це початок відкритого світу, не завершена велика карта, сюжетна кампанія чи фінальний арт.

## Аудит і погляди

Поточна база `65435de` з локальним перевіреним combat-control diff. Прочитано AGENTS/state/constitution, handoff, Cronshift та City-NPC бриф. `game/scripts/world` відсутній. Наявні міські backgrounds є2Dпанорамами/смугами; runtime hero GLB й toon shader існують, міських3Dprops у робочому дереві немає. `Fighter::_post_move/floor_y/_soft_wall` прив'язані до world0/20м/нулевої підлоги; Skea `_start_flash` викликає статичний arena clamp. Частина skills прив'язана до земліY0. MainMenu/GameState маршрутизують у бій; InputRouter має UI ownership/neutral fences. Попередній engine4.7 і logs доступні; новий city runtime ще не перевірено. Відкриті remote PR не встановлено: попередній GitHub API повернувForbidden.

| варіант | наслідок | вибір |
|---|---|---|
| A: оформити всі арени окремо | суперечить city-first, дублює виробництво | відкладено |
| B: спільний модульний район і ізольований exploration adapter | швидкий прохідний прототип, повторне використання героя/матеріалів, менший ризик бою | обрано |
| C: одразу безшовне велике місто, streaming/NPC/сюжет/портали | немає перевірених масштабів/бюджету/контенту, широкий ризик | поетапно після району |

Погляди: новачок отримує короткий skip-able вступ; досвідчений гравець одразу досліджує; користувач M3/8GB потребує виміряного обсягу; художник отримує реальні3Dсилуети/поверхні для конкретного арт-брифу; виконавець має три незалежні смуги; майбутній бій потребує читабельних відкритих кишень і вільних маршрутів; інша істота/NPC матиме власні захищені проходи, а не бойову мішень. Вибір мірилами гри: передбачуваний рух, просторова глибина, короткий цикл перевірки, без порушення перевіреного файтингу.

## Контракт простору та runtime

- CityLayout — спільні bounds/spawn/route_points/combat_pockets; геометрія є джерелом плану. Площа(0,0,0), західний двір(-22,0,0), східний дах(20,4,-20) — орієнтири прототипу, не збалансовані бойові арени. Не запускати бій у кишенях цього зрізу.
- Будівлі з товщиною, дахом, цоколем, читабельними відкосами; відкритий прохід має реальну глибину й напрям. Закриті фасади не обіцяють доступні інтер'єри. Верх кварталу — відкрите небо. Асиметрія: площа як центр, верхній шлях на півночі, головний підйом на сході, повернення на заході. Не застосовувати штучну симетрію арени до міста.
- Основна рампа й бічний прохід — 4 м; вторинна західна рампа — 3 м. Перевірка маршруту додала майданчики підходу на z=10, щоб шлях не зрізав похилу бічну грань. Машинні метадані фактичної геометрії зберігаються поруч у `city-first/plan-metadata.json`; оглядовий план отримується з тієї самої сцени.
- CityFighter успадковує героя без копії Fighter; ізольовані ground ray/support, сходження з уступу, межі району, air-dash endpoint. Немає прихованого dummy opponent. Навички/ульт/ворожий гарпун поки недоступні в exploration, оскільки ще мають arena assumptions; показати це в controls. Рух, стрибок, звичайні удари, меч, dash і parkour hook дозволені, якщо пройшли city probes.
- CityCamera одна для одного героя, world-space/physics view packets, ручний огляд і contact-safe arm. Жодного інвертованого вводу або прив'язки до фіктивного ворога. Вихід міста прибирає camera/rope/effects/input context і відновлює попередній free_move/profile/duel config. Вода старої арени не протікає в місто.
- Меню `EXPLORE CITY · PROTOTYPE`; CityHud показує прогрес навчання, controls, pause/resume/skip/restart/return. Навчання підтверджує фактичні move/look/jump/rope події, не лише натискання. Не споживати battle input черезUI; neutral-before-resume. Немає запису tutorial progress у користувацькі preferences без потреби.
- Цільовий бюджет із попереднього брифу: квартал без героїв/VFX≤250тис.видимих трикутників,≤64MiBresident textures; це PLACEHOLDER target, не обіцянка60FPS наM3. У цьому зрізі спільні матеріали/інстанси, мала кількість lights, нема тисячNPC/скінченних декораційних physics bodies.

## Паралельні смуги й перевірки

| хто | власність | ризик | команда й критерій |
|---|---|---|---|
| T2·A city_geometry | нові CityLayout/CityMaterials/CityDistrict, CityDistrict.tscn, tools/world/city_geometry_check.gd | фальшиві проходи, непрохідна рампа, герой без опори | focused sentinel0fail; реальні collision rays/capsule passage, кількість геометрії; make check/gates |
| T2·B city_runtime | нові CityWorld/CityCamera/CityFighter, CityWorld.tscn, city_runtime_check | world0 clamp, провал із даху, stale input, state leakage | headless actual traversal up/down/outside20м + grapple + restore; make check/gates |
| T2·C city_onboarding | MainMenu/GameState, нові CityOnboarding/CityHud, city_onboarding_check, playable runner, layout_check | кнопка не вміщується, fake tutorial completion, pause leak | actual menu routing, step transitions/skip/restart/UI neutral; layout3viewport; make check-playable/gates |
| T7 city_world_brief | docs/World/2026-10-04-City-First, Meeting | вигадана завершеність сюжетки/ассетів | source-backed brief, PROPOSAL маркування, wikilinks |
| T4 review | docs/Audit/2026-10-04-City-First-Review | непомічена регресія бою, phantom world promises | diff audit, raw logs, native actual-camera frames |

Godot запускає координатор послідовно; на провалі власник виправляє свою смугу й повторює релевантну перевірку. Нові .gd статично типізовані. Shared Fighter/Arena/InputRouter не редагуються без явного узгодження вузької потреби. Три T2 запущені паралельно до плану для аудиту, реалізація — після звірки цього плану.

## Місто після прототипу

1. Пройти district обома героями, затвердити план/масштаб/підйоми/оглядові кадри.
2. Виділити reusable kit: штукатурка/цегла/камінь/метал, модулі фасадів/дахів/балконів, опори зачепів. Наявні намальовані фони — mood reference і допустимий далекий шар, не заміна близького3Dміста. Ліцензія/реєстр/записи provenance кожного нового asset.
3. Higgsfield: конкретні ізольовані references/тайли за прийнятою геометрією; перед платним виробництвом поточні balance/estimate та окремо погоджена партія. Сам факт доступного інструмента не є генерацією. Не витрачати на десятки картинок перед підтвердженим runtime.
4. Одна battle pocket у тій самій3Dгеометрії: scene lifecycle, actor spawn, межі/камера/перехід exploration→fight→exploration, перший чесний бій. Потім2інші кишені. Не припускати, що дані старих arena skills уже придатні до довільної висоти.
5. District seams/streaming, save/checkpoints, мешканці/сценарні події, onboarding у вступному маршруті; пролог і портал у наступний biome після конкретного сюжетного та production брифу.

## Skill gates і межі доказів

Build3DGameRooms використовується як Function contract для custom outdoor district: player envelope, circulation, collision, camera, budgets, opening schedule і оглядові докази. Поточне доручення дозволяє дослідження/код/graybox. Function залишається pending до огляду конкретного плану й reference sheet; Form/Runtime approvals також не вигадуються. Немає платних Meshy jobs, final composition/export/deployment у цій поставці. Прохідна Godot scene є функціональним прототипом, не доказом прийнятого фінального світу. Native Linux render не є M3 performance acceptance.

## Related

- [[2026-10-04-T1-City-First]] · [[World/2026-10-04-City-First]] · [[2026-10-04-City-First-Review]] · [[Cronshift]] · [[2026-10-04-City-NPC-Development]] · [[Style-Guide]] · [[Textures-Registry]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]] · [[Handoff/2026-10-04-Remaining-Work]]
