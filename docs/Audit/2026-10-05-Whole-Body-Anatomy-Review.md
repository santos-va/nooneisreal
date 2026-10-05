# Анатомія всього тіла — незалежне приймання

2026-10-05 · T4 Феміда · **Baseline RED → bounded code/native/integrated acceptance GREEN. Exact-commit package GREEN; CI перевіряється окремо.** Цей додатковий аудит PR #178 використовує саме `3df43a520e494c809905854efff44ffe7de4341f`, а не стару базу `f4defd5`. Попередній [[2026-10-05-Living-District-Review]] приймав конкретні hook/gesture/interaction сценарії; він не доводив відсутність ковзання опорної стопи у звичайній ході та поворотах. Нове доручення Santos розширює художнє приймання на цілу анатомію.

## Незалежна виміряна база

Ізолят створено `git archive 3df43a5` у `/workspace/nir-anatomy-review-before`. Скрипт `/workspace/nooneisreal-evidence/whole-body/probes/actual_anatomy.gd` виконує справжні `InputRouter` → `Fighter._physics_process` → skeletal update, двох героїв по660 physics ticks: idle, рух, поворот90°, гальмування, crouch/exit, block/exit, jump/landing, settle. Позиція чи velocity не підставляються щокадру. Native-смуга art має окремий baseline-compatible actual-input сценарій і front/side ракурси.

Незалежний скрипт зчитує actual GLB bone transforms та skinning усіх mesh vertices із сумарною Foot/ToeBase вагою≥0.5; мінімальну висоту підошви обчислює з bind matrices й поточної пози, не з висоти capsule та не через `HeroFootContact.penetration`. JSON sidecar — `whole-body/baseline-actual.json`, **1320 рядків**, raw log — `baseline-actual.log`. Початковий запуск має environment Fontconfig cache warnings, але без Godot SCRIPT ERROR; це вимір бази, не проголошений clean shipping gate.

| Дефект бази | Вимір |
|---|---|
| Підошва під реальною плоскою підлогою при grounded idle | Choko до−0.0677м; Skea до−0.0260м |
| Вихід із crouch проходить крізь підлогу | Choko до−0.0931м; Skea до−0.0859м |
| Низька стопа ковзає при steady jog | ToeBase excursion Choko0.069–0.127м, Skea0.122–0.185м у9–10tick windows. Це первинні sole<4cm вікна; остаточний stance classifier додатково відділяє toe-off. |
| Choko починає рух ривком голови | frame59→60, Sword_Idle→Walk: head32.38° закадр, hips1.64° |
| Choko зупиняється ривком голови | frame265→266, Walk→Sword_Idle: head22.84°, hips1.65° |
| Choko crouch exit | frame389→390: head41.74° |
| Choko block exit | frame449→450: head31.06°, spine71.29° |

Кути тут — різниця global bone quaternion у skeleton space між сусідніми physics ticks; рух зовнішнього Fighter heading не додається. Head відносно neck у jog змінюється на33°/40° зацикл при малій global head зміні; це потребує перевірки authored head/neck mapping і природної стабілізації погляду, а не автоматичного додавання випадкового хитання.

World-space довжини ніг у landing також змінюються, проте `Fighter` явно застосовує presentation squash scale. Це саме по собі ще не доказ зламаних local rest lengths; локальні довжини й видимий squash треба перевірити окремо. `HeroFootContact.permitted` виключає IDLE/WALK; старий foot-contact тест прямо вимагав цю відсутність корекції. Отже старі зелені assertions не були доказом опори у звичайній ході.

## Зафіксована класифікація опори

До появи candidate зафіксовано `whole-body/source-stance-windows.json`, SHA256 `2cfdc436f6e5b2dde362e1b739783c74b5a1362149473edf5ec74f6c9351dda9`. Незалежний Python FK читає18 UAL Walk/Jog/Sprint clips безпосередньо з baseline GLB. Вікно визначається source ball height≤minimum+15мм на обох кінцях відрізка та |vertical velocity|≤0.15м/с; source interval≥0.05s. Вимірюється actual hero ToeBase, тому heel roll навколо опорного ball допускається. Phase-wrap вікна з'єднуються. Candidate pose, helper.planted flag і horizontal speed не визначають вибір успішних кадрів.

Ця точніша класифікація виправила первинну оцінку: **steady forward Jog має1.9–3.0см drift**, а не7–19см (широке sole<4см вікно включало toe-off). Penetration у genuine support усе ще6.5–13.4мм. Стартові вікна дають9.1–11.0см, поворот Choko26.66см, але під час clip blend phase нового кліпу ще не описує всю змішану позу: їх відокремлено як transition diagnostics, не підмінено ними сталу stance-вибірку. `baseline-frozen-stance-metrics.json` містить точні кадри.

Native4 baseline front/side sheets особисто переглянуто: обидва герої при ході дивляться вниз. Actual headfront→Head world pitch уJog: Choko−35.6°, Skea−34.8°, амплітуда близько0.2°; idle Choko−11°, Skea−25..−29°. Це конкретна перевірка напрямку обличчя, а не припущення зі skeleton bone name.

## CP2 мірила приймання

Координатор погодив наведені **PLACEHOLDER художні пороги** після виміру бази. Вони не змінюють бойові числа чи gameplay-фізику.

- На genuine support phases фактична skinned підошва не проникає в sampled solid surface глибше **5мм**. Перевіряються flat, elevated floor та похила опора, обидва герої, idle/block/crouch exit/landing.
- Опорна стопа має world excursion **≤3см** у stance window довжиною **≥4physics ticks**. Swing і authored toe-off не приклеюються до підлоги. Неправильно визначене вікно документується; поріг мовчки не розширюється.
- Local hero bone segment lengths відрізняються від rest не більше **0.5%**; зовнішній squash враховується окремо. Згин коліна не переходить на протилежний бік при ненульовому згині. Досяжність не забезпечується розтягуванням кісток.
- Для наведених повільних переходів head step **≤10°**, spine step **≤12°** заphysics tick; немає переносу stale pose або накопичення offset після повторів. Ці пороги не накладаються механічно на швидкий удар чи hit reaction.
- Голову/шию перевіряють відносно хребта й напряму руху: природний authored рух або обмежений погляд; вимога не означає безперервного шуму чи обов'язкової мінімальної амплітуди.
- Actual input/native sequences обох героїв показують ціле тіло спереду й збоку. Незмінність authority trace, token/RNG та gameplay state необхідна, але не замінює перевірку видимої анатомії.

## Частота render та physics

Незалежний `probes/callback_lifecycle.gd` спостерігає справжній `skeleton_updated`, без ручного emit або примусового повтору handler. Baseline запускали при fixedfps30/60/120 та physics60. Для кожного запуску:480physics rows і482natural callbacks включно зініціалізацією; у Choko process spans120/240/480 відповідають240physics ticks. **Same-physics duplicate callbacks:0**, world body й observed bone transforms на спільних ticks **точно однакові** між частотами. Докази `whole-body/fps-before/`, `comparison.json`.

Це відділяє engine-only можливість повторних callback від фактичної частоти нинішнього Fighter: його manual AnimationPlayer змінює позу наphysics tick. Фінальний candidate окремо пройшов той самий natural-callback replay нижче; baseline результат не переносився автоматично.

## Проміжний кандидат

Незалежний `probes/anatomy_acceptance.py` читає actual-input1320rows і перевіряє54змістовні інваріанти, без helper flags. Повтор baseline із повними world head/spine quaternions дав **31failures/54**, перший candidate — **5/54**, другий — **0/54** (`candidate-second/acceptance.log`). Зокрема full world rotation включає head roll; поворот голови у skeleton-local space не плутається з компенсацією повороту тіла.

Збережено ті самі frame windows дефектів, без відкидання start/turn після появи candidate: ChokoLeft64–69, ChokoRight203–206, SkeaLeft63–68, SkeaLeft212–217. Toe excursion став меншим за0.000002м при видимій опорі, sole clearance3–8мм; це не ухилення від guard підняттям ноги. Наукової заяви про нульове ковзання в усій грі немає. Фінальний steady-source-window/ramp/native огляд наведено нижче.

Перший candidate уже вирівняв gaze до приблизно−12° і підошви, але незалежний probe лишав RED: SkeaSTOP sole−7.52мм, block entry/exit spine до18.88°/tick. Після bounded vertical fallback для unreachable horizontal anchor та довшого neutral blend цей самий guard пройшов. Candidate local bone-length variation<0.002%, gameplay body positions/states точно збіглися зbaseline. Natural FPS30/60/120 першого candidate також має exact0 pose differences і0повторних callbacks наphysics tick; повтор фінального source наведено нижче.

## Додаткова опора в authored combat

Окремий незалежний `probes/combat_support.gd` запускає справжній `_start_move` після50ticks осідання на фізичну підлогу й потім звичайний `Fighter._physics_process`; `move_frame` чи поза не підставляються. Два герої × jab/hammer/frontkick × обидві сторони,1440physics rows, повний weighted skin підошов; raw log чистий.

Це виявило **blocker раннього candidate, закритий фінальним replay нижче**, який не покривається правильним контактом ударної руки: у ACTIVE jab Choko має sole−49.1мм, Skea−41.6мм; у hammer опорна нога Choko−41.1мм, Skea−25.2мм. GroundContact поки допускав лише neutral/lowhand, тому інші grounded атаки зберегли старе проникнення. Натомість frontkick має справжню протилежну опорну стопу вище підлоги0.2–12.5мм; ударна стопа перебуває близько0.72м над підлогою і не повинна примусово приклеюватися. Доказ `candidate-second/combat-support.json`; blocker передано T2/T7 і координатору.

Додатковий actual `receive_hit` non-launcher light зі звичайним guard input відтворив той самий клас дефекту у grounded BLOCKSTUN (Choko−60.8мм/Skea−48.0мм) і HITSTUN (−39.6/−35.1мм). STUMBLE ініціалізовано тим самим `flinch`/`_set_state`, що викликає swell, і далі програно звичайну фізику на flat fixture: −40.2/−35.7мм. Це перевірка стоячої реакції, не доказ реального запуску хвилі; collapsed/getup/KO/air не включено до standing contract. `reaction_support.gd` та `candidate-second/reaction-support.json` містять1080rows; усі виміряні реакції залишалися grounded. Власник отримав blocker до фінального freeze.

Повторний незалежний `steady_support.py` застосував frozen source windows до всіх рядків candidate, не використовуючи helper flags:16вікон по≥4ticks, найбільший world Toe excursion0.0000029м, мінімальна skinned sole clearance+0.0030м. Source intervals не звужувалися після candidate.

Окремий native replay тих самих660tick inputs зняв292кадри front/side обох героїв у turn195–218, stop265–278, block419–435/449–466. Усі послідовні кадри особисто переглянуто у12contact sheets (`candidate-second/focus/`): немає видимого перевороту коліна чи head-roll flip; це вузьке підтвердження переходів, не остаточне приймання terrain/combat.

## Фінальний незалежний replay

Ізолят `candidate-final/source.json` зберігає SHA256 кожного script. Перевірені ключові файли: HeroGroundContact `46864f2c2dce2afccd4dcff2dcec120f01d4443dff15f5a224aa098a38aff5ce`, HeroBodyMotion `2ce8f97627947693468cd5641b3cd21d3fc1a34a9970534d89838ccdf4f8bfdf`, SkeletalRig `78c98cf4b8bb9d3e4a3427eb776c85a6316070ed1fe12add512d6c47dfa6ae53`.

| Незалежний сценарій | Підсумок |
|---|---|
| Actual-input1320rows, незмінні54анатомічні assertions | **54/0**, у baseline той самий guard31failures |
| Frozen source-phase stance | 16вікон, максимум Toe excursion0.0000029м; мінімум sole+3.0мм |
| Actual `_start_move`, jab/hammer/frontkick, обидві сторони/герої | 1440rows; найнижча ACTIVE sole+3.06мм, ударна нога frontkick лишилася вільною |
| Lowhand + його власний planted-foot шар | 480actual rows, обидві руки/герої; усі ATTACK frames sole≥+2.49мм |
| Grounded block/hit/stumble reactions | 1080rows; найнижча sole+2.89мм, знайдені ранні−25..−61мм проникнення закриті |
| CityFighter flat/roof4м/10°slope | 1440rows,1260grounded samples після осідання; усі повні skinned soles≥+2.66мм від реальної collider plane |
| Natural callbacks при30/60/120render FPS, physics60 | По480physics rows/482callbacks;0дублікатів наtick; world bones/body/authority точно однакові між частотами |
| Native combat BEFORE/AFTER | 878кадрів/рядків; усі gameplay authority поля, включно зRNG, збігаються точно |

Terrain probe використовує справжній `CityFighter`, box collider із відомою нормальною та справжній input: рух, stop, crouch/exit. Кожен foot-weighted vertex проходить незалежне повне skinning; distance рахується від точного top plane колайдера, не від helper clearance чи nominal body height. На схилі capsule справді піднімається до5.45/5.61м; це не переміщення картинки поверх плоскої фізичної підлоги. Raw logs чотирьох final probes і трьох FPS runs перевірено на Godot errors, усі завершилися0.

Особисто переглянуто **всі16послідовних AFTER combat sheets,878native кадрів**: jab/lowhand/hammer/frontkick, обидва герої, front/side. Немає видимої інверсії коліна або head-roll flip; опорна нога лишається під корпусом, ударна піднімається. Це додається до292кадрів focus replay. Capture мав CP5 attack helper; єдина наступна різниця final helper допускає HITSTUN/BLOCKSTUN/STUMBLE, а записані бойові стани рівноIDLE/ATTACK. Це перевірена еквівалентність використаного шляху, а не удаваний запис реакцій, яких у відео немає.

Фінальний art locomotion pass також прийнято в перевіреному обсязі:1800native кадрів збережено, T4 особисто переглянув усі24послідовні transition sheets (**700кадрів**) і4overview sheets. Stop/turn/crouch enter/exit/block exit/landing→jab не показали інверсії коліна чи старого ривка head/spine. Всі1800physics sidecar rows BEFORE/AFTER збіглися за body/velocity/state/grounded (`after/locomotion60/authority-comparison.json`). Це не заява, що T4 вручну програв усе MP4 у realtime; перевірено послідовні raster frames та числовий sidecar.

Hook front/side replay також пройшов незалежне звірення720CSV rows BEFORE/AFTER без жодної authority різниці (`after/hook-authority-comparison.json`). Переглянуто обидва повні moving windup0–29/reel58–73 sheets і додаткові суцільні catch28–58/end74–89 sheets для всіх8hero/scenario/view варіантів. Ноги продовжують крок у moving windup, після catch симетрично опускаються під тазом; нахил корпуса й хват лишаються узгодженими, видимого knee flip немає. Це462унікальні особисто переглянуті native кадри. Кінець90tick capture ще у висінні: ним не заявляється rope-release landing, яка перевіряється іншими runtime guards.

## Статус

**GREEN для перевіреного code/native/runtime обсягу.** Знайдені незалежні числові blockers закрито без зміни мірила приймання. Production, state і shared Godot аудитор не змінював. Exact-commit package окремо прийнято нижче; поточний CI ще не заявляється зеленим.

CityWorld native прийнято: особисто переглянуто обидва city overview sheets і matched before/after ramp/roof comparison. На справжній східній рампі та даху 4 м немає поміченої нової інверсії коліна, head-roll flip або проникнення підошви. Збережено 450 native кадрів; T4 незалежно звірив усі 450 sidecar rows body/floor/state/grounded — **0 відмінностей** (`after/city-authority-comparison.json`). NPC приховані, production world/light/camera збережені. Сценарій починається на рампі, далі має actual input, а frame150 явно переносить героя на дах: це не удаване безперервне проходження всього маршруту.

Додатковий незалежний `probes/city_skin_final.gd` повторив цей actual CityWorld input без renderer і виміряв повне weighted skinning від точного collider plane східної рампи (rise4/run18) та даху. Із 450 рядків 410 grounded samples після осідання: мінімум ramp sole **+2.92 мм**, roof sole **+2.73 мм**, обидва герої. Власний helper не визначає виміряну опору. Початковий зовнішній probe мав indentation parse error і не виконувався; після виправлення лише probe фінальний `candidate-final/city-skin.log` чистий, exit0. Це доповнення до раніше зеленого незалежного 10° terrain replay.

Особисто прочитано фінальні `validation/playable-final.log` та raw logs позитивних сценаріїв: **73 scenarios / 0 failures**, без SCRIPT ERROR, ERROR чи resource/ObjectDB leaks. Перший aggregate мав 72/73: assertions physics-motion1149/0 пройшли, але teardown лишив аудіоресурси, і strict runner правильно відхилив запуск. Після cleanup-only mixer drain той самий physics-motion1149/0 має чистий raw log; production hashes не змінено. Smoke у `validation/check-playable.log`: **164 checks / 19847 frames**. `validation/gates.log`: **102 GDS / 0 parse failures**, батарея зелена. Окремо особисто прочитано `native-renderer.log` **4/0** та `http.log` **34+17/0**; HTTP доказ прямо позначає `real_model_inference=false`. Expected failures негативних mutation controls не видаються за production errors.

Прийнятий production commit: `d27b60821f264c0b407ad844e128ede299d698f5`. Ключові три production SHA256 вище повторно звірено зі shared checkout після final suite. Візуальні докази — Linux Godot4.7 Compatibility/llvmpipe; це не вимір FPS чи художнє приймання на M3. Повні 60fps captures існують, але особисте T4 приймання спирається на названі послідовні кадри й незалежні виміри, а не неправдиву заяву про тривалу ручну гру.

## Exact-commit package

T4 особисто прочитав `district-close/pck-d27b608/evidence.json`, import/export/native raw logs і verifier source та переглянув `native-package.png`. Незалежно перерахована SHA256 `living-district.pck`: **5176551e558d197412fbf6800671952aca92f3a8ad9eb6a4c7f64249909f259a**, розмір **208716528 bytes**. Packed version **0.5.0**, packed revision **d27b60821f264c0b407ad844e128ede299d698f5**.

Native `--main-pack` verifier працював із окремої директорії, де є лише `project.godot`, і без підключення checkout resources: **86 checks / 0 failures**. Перевіряються packed source-contact metadata, обидва actual hero rigs, runtime body/gaze/ground helpers на solid support, authored hook sources, NPC fallback/OFF-by-default HTTP та Compatibility shaders. Import/export/native logs не містять errors або resource leaks; native VSync unsupported warning є обмеженням llvmpipe, не прихованою shader failure. Цей пакетний smoke підтверджує доставку перевірених ресурсів, а не повторює весь числовий anatomy acceptance. CI та встановлений macOS/M3 build залишаються окремими доказами.

## Related

- [[2026-10-05-Whole-Body-Motion]] · [[2026-10-05-Whole-Body-Session]] · [[2026-10-05-Whole-Body-Visual-Audit]] · [[2026-10-05-Whole-Body-Retarget-Research]]
- [[2026-10-05-Living-District-Characters]] · [[2026-10-05-Living-District-Session]] · [[2026-10-05-Living-District-Review]] · [[2026-10-05-Authored-Hook-Motion]] · [[2026-10-05-Locomotion-States]] · [[ADR-004-Physics-Is-Presentation]] · [[recurring_class_register]]
