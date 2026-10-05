# Зброя та одяг — сесія

2026-10-05 · T1 координатор. Santos попросив виправити напрям меча, зробити тонкі візерунчасті індивідуальні поверхні зброї й усіх наявних інструментів, підвищити якість та фізику одягу героїв і NPC. Уточнення користувача: **меч перевернути і в руці, і на спині**.

## CP0 — база й контракт

PR #178 на `4c68473` перевірений через GitHub: відкритий, незмерджений. Для нової хвилі повернутий у draft; попередній GREEN не видається за приймання нових змін. Шість чинних агентів отримали окремі ownership смуги: sword; hero gear/cloth; NPC clothes; art/native; research; independent audit.

План [[2026-10-05-Equipment-And-Cloth]] містить R8, видимі критерії та межі. Початковий source-аудит підтвердив широкий меч без UV, спинний напрям угору, єдиний material_override hero та жорсткий косметичний sash без cloth solver. Native baseline й topology деталізуються до відповідних правок. Немає витрат провайдерів, нових здібностей або зміни hitboxes.

Game Development Studio CLI відсутній; про обмеження повідомлено. Чинні Godot4.7 засоби проєкту доступні. Нову іконку користувач раніше відклав до оригінального PNG; рішення збережено.

## CP1 — аудит завершено, виконання дозволено

Native T2/T4 виміряли зворотний first-active sword напрям і розрив між draw target та back grip. T3 підтвердив єдиний hero atlas та відсутність cloth bones; T2 NPC перевірив12profiles×180ticks — garment-relative рух нульовий. Визначено конкретний gear scope й адресні garment overlays, shared GearSurface власник rope. Новий план CP1 прийняв незалежні критерії контактів, прикріплення тканини, bounded motion, camera fade та naturalFPS до початку реалізації.

## CP2 — ранній кандидат не прийнято

Новий напрям меча пройшов старі230sword guards, але незалежний actual-input T4 виявив нові blockers: ліва рука не доходить до mount приблизно15см, після draw→IDLE tip стрибає1,33–1,43м/77–83° заtick. Source freeze й приймання не оголошені; старі позитивні assertions не підміняють безперервну анімацію. T2 combat отримав вимогу узгодити досяжний socket і плавний armed-ready перехід до geometry polish. Root/T6 native right-neutral також показав перекриття щоки старою широкою гардою; повторити після thin profile, а якщо потрібно — виправити справжню armed arm stance.

NPC кандидат зберігає старий budget:47meshes/2884triangles максимум у100seeds, старий presentation1076/0. Це не фінальне cloth-приймання. Для героя розглядається кешована семантична mask тканинних регіонів без зміни atlas/skin/позицій, щоб поліпшення не обмежилося лише навішеними речами. Повторне skinning дублікатів torso/trousers не є автоматичним вибором; coverage й вартість мають native/runtime доказ.

## CP3 — якісні матеріали з дозволеним бюджетом

Нове пряме доручення Santos дозволяє витрату Higgsfield кредитів на якісні текстури. Balance:4568,5/Ultra; preferences:auto_create_project=false; GPT Image2.5 max/2k estimate9credits/image. T6 визначив шість UV-придатних maps, root координує paid batch54credits, T2 підключають samplers; prompts/job IDs/source hashes і фактична витрата зберігаються. План CP3 явно замінює старе «без provider». CLI game-dev досі недоступний; використовуємо native repository intake/registry, без неправдивих CLI receipts.

Геройський cloth shader тепер має semantic vertex mask для оригінального mesh; це уточнення початкових added overlays. Атлас і skin зберігаються. T3 виявив втрату трьох imported LOD у ранній копії mesh; T2 виправляє/перевіряє збереження до фінального ресурсного приймання. T4 також знайшов steady-walk перетин NPC coat із ногами; виконавець виправляє A-line форму, не послаблює кутові межі.

Перший batch завершився п'ятьма успіхами та terminal failure Skea knit. Перевірений balance після нього **4523,5**, різниця **45 кредитів**. Для невдалої карти подано один повтор із тим самим prompt/params за quote9: job `30db9a22-4f6a-42c3-8e48-516e929360c6`; повтор успішно завершився, усі шість карт створено. Фінальний balance **4514,5**, фактична загальна витрата **54 кредити**. Початкові успішні jobs не дублюються. Exact receipts — [[2026-10-05-Equipment-Texture-Production]]. Локальний CDN download отримав CONNECT403 від network policy, тому requested runtime integration ще не виконана. Santos отримав async запит дозволити конкретний CDN domain; обхід мережевої політики не застосовується.

## CP4 — незалежні геометричні та ресурсні перевірки

Нові all-variant sword guards виявили проникнення після перевороту клинка; T4 підтвердив actual full-skinned torso/hips перетини у cut16, thrust14–16 і lowcut6–7, тому це не просто надмірний capsule guard. T2 змінює actual forearm/wrist при незмінній wrist/contact position; до candidate зафіксував total50°/forearm45°/wrist45°, target core0,160м, чинний acceptance0,130м не послаблено. Перенесення цієї корекції на draw створило дві continuity failures — відхилено; draw trajectory виправляється окремо. Final sword acceptance ще відкрите.

NPC незалежно пройшов743580 panel-interior envelope samples та natural30/60/120 replay без відмінностей; native T6 перевірив side-fit/рух original-material candidate. Root прочитав raw quiet budget log:12NPC, idle104/149µs median/p95, move-stop-turn108/170µs; max1378µs. Три respawn cycles збережені кеші й звільнені weakrefs, failures0. Це helper CPU Linux, не FPS/M3. Докладні snapshot hashes і межі — [[2026-10-05-Equipment-And-Cloth-Research]].

Root прочитав незалежний garment-LOD log: обидва герої, base+3LOD, нуль protected-anatomy triangles із ненульовою маскою. Positions/UV/skin/indices збережені; повторна компресія дає normal≤0,007412° і tangent component≤0,000119, тому ці два buffers не називаються byte-exact. Маска в COLOR.g зберігає R/B/A. Hero fitting, camera lifecycle, повний regression/native/PCK і provider-map admission ще не закриті.

## Related

- [[2026-10-05-Equipment-And-Cloth]] · [[2026-10-05-Whole-Body-Checkpoint]] · [[2026-10-05-Whole-Body-Session]] · [[state]]
