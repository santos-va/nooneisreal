# Рух на уступах і виразна робота мотузки

2026-10-05 · T2 Гефест · [[2026-10-05-Responsive-Parkour]].

Предмет: для всіх міських parkour-поз анімація читає фактичний рух і точки контакту, зберігаючи gameplay authority, довжини кісток, physics-clock та чинні контакти спорядження.

## Звірка й виконання

Baseline: `LocomotionCadence` вже має distance-driven phase та виміряні швидкості authored UAL clips. Прискорювати наземний кліп окремо від швидкості означало б повернути ковзання; цей контракт збережено. `AuthoredHookMotion` вже використовує actual rope span та bounded IK, але один рух підтягування займав повний бюджет 1,2 м. Новий художній PLACEHOLDER цикл — 0,65 м реального скорочення, catch — 0,12 с лише для responsive міського `grapple_parkour`; input і gameplay від нього не залежать. Звичайний/дуельний профіль зберігає catch 0,20 с та цикл у чинний `reel_distance`.

`ParkourMotion` читає city metadata `parkour_presentation` тільки в `JUMP`, без зайнятого гарпуна. Використовує вже встановлені CC0 `Climb_Idle`/`Climb_Up` та окремий `ClimbLedge` (джерело UAL1, довжина 0,6333 с), без нових ассетів. Wall cadence просувається лише фактичним 3D переміщенням; вертикальний рух враховано. Source-корекція використовує rotations та повернення pelvis до rest замість успадкованого backward Jump root; чиста поза відновлюється перед наступним seek. Кисті цілиться у справжні точки уступу, похибка рахується до них; при mantle хват звільняється за progress і фактичною досяжністю плеча. Стопи під час опорної півфази прив'язані до реальної площини стіни. Повторні render callbacks не просувають цикл і не змінюють точки опори.

Ранній тест виявив реальну невідповідність: руки моделей мають сумарну довжину близько 0,37 м, початковий hang 1,65 м під краєм давав 0,24–0,34 м похибки. Виправлено разом із motor: hang 1,42 м; collider offset 0,43 м збережено. Анімація допускає лише обмежену корекцію таза до 0,15 м та нахил підтриманого торса до 8° (художні PLACEHOLDER), без подовження кісток. Попередню корекцію 0,28 м не прийнято. Окремий native before-перегляд виявив lift/jump силует mantle зі звичайного climb loop; його замінено спеціальним `ClimbLedge`.

## Перевірка

Проміжний Godot 4.6.3: `parkour_motion_check.gd` **11 009 / 0** на профілі 1,42 м і pelvis cap 0,15 м; `authored_hook_check.gd` **11 498 / 0**, max grip **0,000001 м**; `whole_body_motion_check.gd` **12 686 / 0**. Raw logs `/tmp/nir-parkour-motion.log`, `/tmp/nir-authored-hook.log`, `/tmp/nir-whole-body.log`. Це попередня перевірка до `ClimbLedge`/8° та розширеного cloth oracle; цільовий 4.7 результат наведено нижче.

Регресія перевіряє реальні пропорції обох героїв, live-profile геометрію хвату, actual two-stage mantle trajectory, дві орієнтації, stale/некоректні metadata, незмінну authority, відсутність treadmill на заблокованому тілі, release/reset і повторну ретаргетацію. Повний skinned-cloth oracle додає вибірку нових hang/mantle/wall поз; її виміряні результати наведено нижче.

Цільовий **Godot 4.7 stable**, поточний source із `ClimbLedge`, нахилом 8°, per-foot solid rays та sword busy isolation: **PARKOUR_MOTION_COMPLETE 15 320 / 0**, rc 0, raw `/tmp/nir-parkour-motion47.log`. **18** повних skinned-cloth вибірок: 0 перетинів, 0 invalid shapes, позитивні pin margins близько 3 мм. Settled world-grip error: Choko **0,018761 м**, Skea **0,0000001 м**. Це не гарантія нульової похибки в кожному перехідному кадрі; native-перехід оцінюється окремо.

Негативні форми: NaN/відсутня кисть/невірний тип progress та контейнера, stale metadata у HITSTUN, невідповідний герой для wall-run, зникла реальна поверхня під стопою, нерухоме тіло з wall-mode. Ray contact не продовжує вузький пілястр нескінченною площиною: без solid hit під конкретною стопою plant не створюється. Кеш цього кадру не повторює raycast або фазу при повторній ретаргетації.

Додаткова знайдена колізія шарів: drawn Choko sword спершу залишався у руці, а `_ready_grip` після parkour IK переписував три кістки руки. Перший 4.7 прогін чесно впав на **12** повторних pose guards; виправлено busy back-stow та пропуск sword arm-overlay лише в активній support-позі. Gameplay `sword_drawn`/`sword_hand` незмінні; після звільнення рук видиме положення меча повертається. Точні повторні pose guards не послаблено.

## Виправлення контакту всієї стопи після native-аудиту

Протилежний native-ракурс дав підтверджений геометричний контрприклад до ankle-only ray. У фактичному city wall-run tick26 **353 / 1 227** shoe vertices правої ноги були всередині пілястри, максимальна глибина **69,3 мм**; tick18 — **466**, до **94,74 мм**. Ankle center був поза вузькою пілястрою, тож один промінь бачив задню стіну. Доказ T6 — `visual/shoe-before/trace.json`; старе приймання тільки ankle-target відкликане.

Тепер кожний свіжий physics frame опорної ноги використовує наявні `HeroFootContact.samples`: фактичні skinned shoe vertices задають ширину, висоту й передній край взуття. Дев'ять променів по цьому відбитку обирають найближчу реальну виступну поверхню. Точка опори зберігає дотичні координати; нормальний відступ дорівнює виміряній геометрії взуття плюс чинний 3-мм clearance. Немає невидимої додаткової стіни або постійного зсуву героя. Повторні render callbacks використовують кеш без нових raycasts; порожня поверхня/вибірка не створює plant.

Godot 4.7, актуальний source: **PARKOUR_MOTION_COMPLETE 15 466 / 0**, raw `/tmp/nir-parkour-footprint47.log`. Нові assertions перевіряють **після IK** всі sampled shoe vertices біля справжньої стіни та вузької виступної смуги, центр якої навмисно минає ankle ray; positive contact, missing-surface negative, повторна ретаргетація та всі cloth guards збережені.

Незалежний T6 helper на тому самому actual CityDistrict/input, `--case=skea_wall_run --ticks=60 --foot-proof --check-feet`: **60 ticks / 0 failures**, жодної shoe vertex всередині перевіреної пілястри в wall-run, evidence `visual/shoe-after/trace.json`. Перший helper raw `/tmp/nir-parkour-shoe-after47.log` містив exit-leaks **4 ObjectDB / 2 resources**. T6 виправив teardown і повторив той самий guard: `visual/shoe-clean.log` — **60 ticks / 0 failures**, чистий exit. Фінальні native-ракурси з поточним footprint source: `visual/wall-fixed47`, `visual/wall-opposed-fixed47`, `visual/ledge-fixed47`; вони замінюють попереднє приймання ankle-only.

## Виправлення міського rope overlay та повна перевірка спорядження

Перший повний playable-прогін виявив **7930 / 1** у старому `hero-gear`: Skea low/60 мав pin margin **−2,880 мм** замість чинних **+0,5…4 мм**. Діагностика найближчої фактичної skinned triangle показала `LeftForeArm`, а не помилкову нормаль торса. Глобальне прискорення authored cycle також зачепило звичайний Fighter; його timing повернуто до 0,20 с / `reel_distance`, новий 0,12 с / 0,65 м обмежено responsive city profile.

Окремий новий `city_hook_gear_check.gd` використовує справжні CityFighter/GrappleHook, обох героїв, low/high/transfer та кожний catch/reel tick до 56, пізні 60/75: **276** реальних поз. Перший baseline цього guard — **1598 / 8**: пришвидшений wall-climb overlay згортав передпліччя до нагрудних тканин. Геометричний пошук кутів ліктя не став фінальним рішенням і повністю видалений разом із кешами.

Фінальний шар лишає authored torso для catch, після нього торсом керує вже наявний фізичний rope load. Джерело зберігає жести кисті й фазу regrip; опорні Arm/ForeArm вирішуються з власної rest-площини моделі до фактичного rope span, без успадкованого wall-climb axial twist. Від моменту фактичної підтримки кисть повністю стоїть на мотузці: blend через невалідну позу не застосовується. Компактне regrip переміщення обмежене пропорцією фактичної довжини руки; reach-sphere та gameplay rope budget незмінні. Жодних змін pin stand-off, форми спорядження, фізики чи допусків oracle.

Цільовий Godot 4.7: **CITY_HOOK_GEAR_COMPLETE 2978 / 0, samples=276**; **HERO_GEAR_COMPLETE 7930 / 0**; **AUTHORED_HOOK_COMPLETE 11498 / 0**, max grip **0,000001 м**. Усі три final raw чисті, rc 0. Новий guard додатково перевіряє точну незмінність пози/циклу при повторному retarget, фактичні довжини рук, незмінну authority, grip <4 см, непорожні форми, нуль skinned cloth intersections та чинні позитивні pin margins. Зареєстрований у `playable_check.sh` без збільшення 180-секундного ліміту. Raw before/final logs збережені окремо в `/workspace/nooneisreal-evidence/responsive-parkour/validation/animation-final/`.

Фінальне native-приймання T6 виконано після замороження source: `visual/hooks-final47/` — **85 PNG / 170 ticks**, обидва записи rc 0 / 0 failures, SHA до/після збігаються. Choko проходить справжній CityDistrict hook/reel/release; порівняння tick/phase/position/velocity/grounded/rope length/attached дало **0 відмінностей**. Окремий Skea low fixture явно підписаний, використовує фактичний CityFighter/GrappleHook; HANG grip error ≤ **0,000000293 м**. T6 переглянув послідовності та повнорозмірні ticks 24/32: нової інверсії ліктя чи складеного до грудей передпліччя не виявлено. Raw без runtime/shader errors і leaks, лише відоме unsupported VSync warning. Деталі й межі локального приймання — [[2026-10-05-Parkour-Visual-Audit]]. Чинний `visual/parkour-demo.mp4` містить оновлений Choko rope segment; додатковий `visual/skea-low-hook.mp4` показує близький low-hook. Це приймання перевірених маршрутів, без твердження про всі input-комбінації, gameplay-камери чи апаратний FPS; точні cloth контакти підтверджує незалежний geometry oracle.

## Related

- [[2026-10-05-Responsive-Parkour]] · [[2026-10-05-Whole-Body-Motion]] · [[2026-10-05-Hero-Equipment-And-Cloth]]
