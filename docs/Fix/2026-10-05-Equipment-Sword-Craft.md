# Меч Choko: напрям хвату, спинне кріплення і тонка орнаментика

2026-10-05 · T2 Гефест. Виконання [[2026-10-05-Equipment-And-Cloth]], baseline `4c68473`. Статус: геометрія/рух заморожені; незалежна actual-geometry перевірка пройдена. Приглушену fallback-палітру прийнято окремою material-only перевіркою; generated map досі не отримана.

Зміна стосується обох рук, усіх трьох форм і шести чинних бойових варіантів меча. MoveData, траєкторія тіла, RNG, власник зброї та момент gameplay-контакту не змінюються.

## Підтверджені дефекти

Native baseline у `/workspace/nooneisreal-evidence/weapon-craft/before/` містить десять кадрів із тієї самої камери/світла. First-active cut обох рук: проєкція клинка на forward **−0,41609**, grip.y≈1,11 м, tip.y≈0,264 м — клинок іде назад до власної ноги. На спині grip.y≈0,726 м, pommel.y≈0,589 м і tip.y≈1,546 м: ручка внизу, вістря вгорі.

`SwordPresentation` будував лезо вздовж +Y, але правий хват задавав Rx(−90°), а carry — +UP. `SwordMotion.apply_draw` тягнув руку до окремої приблизної точки над плечем, не до фактичного руків'я. Старі equality/mirror guards не доводили правильний бік хвату. Raw GLB Choko має тільки LeftHand/RightHand, без thumb/index bones; відсутній landmark не видається за перевірений.

Перша спроба перевернути лише prop виявила head/torso penetration у neutral/transfer. Наступний actual-input аудит T4 виявив недосяжний лівою рукою socket (15 см) та draw→idle стрибок вістря 1,3–1,4 м. Після виправлення руки/socket окремий full-skin triangle oracle підтвердив проникнення клинка в torso під час lowcut та recovery cut/thrust/cleave. Перевірка лише centerline потім пропустила перетини широкої грані. Ці кандидати відхилені; старі ранні PNG не є final-прийманням.

## Хват і рух руки

Правий хват тепер Rx(+90°); лівий обчислюється sagittal mirror зі збереженням positive determinant. `back_grip()` повертає одне кріплення, прив'язане до остаточної пози torso: вістря вниз, ручка над плечем. Draw обчислює wrist target з цього самого кріплення, calibration та palm offset. Sword переходить на руку під час hold біля руків'я, а не стрибає між двома незалежними точками.

Actual ready arm IK опускає й виносить кисть із boxer-стійки. Зміщення обмежене **24 см**, axial forearm roll — **120°**, залишковий wrist swing — **25°**. Це PLACEHOLDER art/anatomy bounds, а не додатковий бойовий reach. Локальні сегменти не розтягуються. Draw починається й закінчується в цій самій ready-позі; після hold реальна рука проходить дугу до **10 см у бік нахилу stored blade та 8 см угору**, щоб клинок не зрізав torso під час виймання.

Для authored ATTACK source/contact position кисті зберігається. `SwordMotion._clear_body_grip` знаходить обмежену ітеративну поправку actual hand orientation поза torso/head envelope. Вона розподілена між обертанням передпліччя навколо його осі та зап'ястком. Межі **50° total / 45° forearm / 45° wrist** лишаються фіксованими; жодного відриву меча від руки, зсуву attack wrist або зміни hitbox.

Геометрія береться з **реальних tapered mesh**, а не з прямокутника максимальної ширини: під час setup кешуються поздовжні ребра граней та centerline кожної форми (17 / 17 / 25 сегментів). Використовується саме `attack_sword_form`, як і видима зброя. `Geometry3D` обчислює exact closest-segment points до torso/head та обох upper/lower leg segments; максимум вісім ітерацій. Centerline envelope 160 мм, крайова поправка 15 мм враховує фактичну грань, не роздуває вузьку основу клинка до максимальної ширини. Acceptance centerline guard **130 мм** не зменшено; додатково незалежний actual blade triangle ↔ full-skinned body oracle вимагає **нуль перетинів**. Clock/RNG, накопичення між callbacks та gameplay geometry відсутні.

Проміжний прямокутний envelope був відхилений: він подвоював ширину біля гарди й заводив корекцію lowcut вниз у стегно. Offline вимір реальної шкіри знайшов 380 допустимих орієнтацій у чинних angular bounds, з мінімумом близько 33°; збільшувати bounds не знадобилося. Після переходу на actual profile/leg constraints незалежні 36 worst poses стали чистими.

## Вибір authored thrust перед наступним candidate

T3 перевірив усі 36 installed sword clips на actual retarget при 60 Hz. Названого Thrust/Stab/Spear немає. Три варіанти:

1. **Sword_Light_D**, обраний для candidate: naked RightHand між source t=0,20 і 0,30 с проходить вперед відносно hips від −0,260589 до +0,509615 м (**+0,770204 м**), lateral змінюється лише на 9,4 мм. Blade.forward≈0,84 на t=0,30 і≈0,81 на t=0,433. Авторський корпус/ноги/return зберігаються. Contact **0,300 с**, follow **0,433 с**, recovery — решта власного clip до **1,667 с**, без неіснуючого `_Rec`.
2. Sword_Attack_Standing на t≈0,45 має blade.forward≈0,95, але кисть відразу падає й іде вбік: sweep, а не чисте витягнення.
3. Sword_Heavy_D на t≈0,633 має blade.forward≈0,877, але кисть уже нижче hips; це follow-through чинного cleave. Процедурне перевертання Light_B на≈90° менш виправдане, ніж reuse належного authored витягнення.

Старий Sword_Light_B на t≈0,30: blade.forward≈0,02, blade.up≈−0,75, що пояснює vertical cut замість thrust. Вибір D потребує actual-move native й ground-support приймання; source scan не є готовим acceptance. `MoveData` startup/active/recovery та hitbox незмінні. Чинні 18 foot profiles призначені тільки gait loops; ATTACK має geometric penetration correction без stance lock, тому вигаданий D_Rec/непотрібний gait profile не додається.

### Контакт низького зрізу

Новий actual blade→MoveData hitband guard відхилив left lowcut обох yaw: старий contact source **0,233 с** давав blade.forward≈0,27 і майже поперечний blade; наступні ACTIVE samples вже піднімалися вище low band. Знайдено належний момент у **тому самому Sword_Regular_A — 0,250 с**: forward≈0,77, up≈0,04, naked wrist forward≈0,41 м. Candidate змінює тільки цей source contact на один кадр UAL; follow **0,433** та весь окремий Regular_A_Rec незмінні, отже не створює нового recovery splice. Gameplay startup/active/recovery й hitbox залишаються чинними. Обидві руки проходять ті самі actual progression / full-skinned edges / hitband guards; остаточний результат наведено нижче.

## Форма та поверхня

Наявний reference `weapon_choko_main_sword.png` особисто переглянуто: смарагдові грані, тонка золота нитка, ажурна латунна гарда та перехресна темна обмотка. Baseline ширина/товщина 0,23/0,066 м і outline 4 мм робили клинок масивним.

Три кешовані mesh мають різні профілі, а не лише scale: ширина **0,130 / 0,076 / 0,140 м**, товщина **0,020 / 0,016 / 0,022 м**. Довжини чинних форм збережені. Тонка відкрита гарда, менші quillons/pommel/gem та темний wrapped handle узгоджені з reference. Outline леза зменшено до **1,1 мм**.

Нові UV реально читаються матеріалом: центральна золота нитка й ромб для base, парні риски/жолоб для narrow, стримані chevrons для wide. Латунь має etching, руків'я — перехресну обмотку. Деталі прив'язані до поверхні, без TIME shimmer або спільного RNG. Золота ultimate-форма збережена. Інтеграція окремої авторизованої користувачем provider texture відстежується в [[Textures-Registry]]; до отримання й огляду файла її наявність не заявляється.

## Перевірки і межі

- `weapon-allforms-final.log`: **10950/0**, actual input draw/два handoff, обидві руки, три форми × шість attacks; base перевірено при двох yaw, narrow/wide — yaw0. Додатково actual 2D arena draw обох facing/рук. Authority invariant, actual wrist/contact збережений ≤20 мкм, angular bounds, all-bone repeated-retarget positions/rotation/scale та hitstop.
- Постійний independent oracle перевіряє **54 worst poses actual blade edges ↔ full imported skin triangles**, в обох напрямах перетину, з незмінними skin weights і AABB preselection. Він не читає production capsule/solver flags. В усіх варіантів реальний клинок перетинає оголошену MoveData hitband щонайменше в одному ACTIVE кадрі; hitbox не розширено.
- `negative-edge-control.log`: вимкнення clearance correction тільки в ізольованій копії відтворило **6 failures**, зокрема два actual-skin failures. Final source відновлено й SHA перевірено; наступний повний запуск — 10950/0.
- `sword-final-headless.log`: **230/0**; `combat-final-headless.log`: **167/0**. Єдина адаптація старого combat fixture: форми порівнюються за actual mesh AABB, оскільки тепер це три mesh, а не три scale.
- Незалежний T4 `/gear-review/sixth/skin-edges.log`: **36/36 poses без перетину**, включно з остаточним lowcut contact 0,250. New thrust full-skinned sole probe: **480 actual ticks**, обидві руки × два yaw, minimum sole **+2,692…+2,857 мм** у всіх фазах.
- T3 CPU, 40 відновлених raw poses ×120 samples, найширша форма: найгірший helper median **319 мкс**, p95 **458–459 мкс**; safe poses близько **45–50 мкс**. Один outlier **34,616 мс** збережено в raw. Це bounded helper-only Linux вимір, не whole-frame/M3 FPS гарантія. Fixture зберігає важкий попередній lowcut pose; фінальна зміна contact source не видається за повторно виміряний весь gameplay кадр.

Geometry-native: **1376 PNG**, front/side по **5966/0**, 28 повних послідовностей. Порівняння всіх **1376 BEFORE→AFTER authority rows** дало нуль відмінностей для body position/velocity, state, move_frame, hand, form, drawn і RNG. Baseline helper не записував hp/meter, тому ця CSV/JSON-парність їх не заявляє; вони покриті owner runtime invariant. Суцільні sheets і real-60-fps MP4 передані T4. **Native geometry/anatomy GREEN** у перевіреному обсязі: T4 особисто оглянув front/side draw25–40, side swaps49–83 обох рук, усі шість variants обох рук у sampled фазах, повні front lowcut37/thrust35 sheets. Додатковий exact full-skin edge oracle перевірив 16 draw-handoff поз обох рук без перетинів. Це огляд sheets/excerpts разом із geometry/runtime guards; твердження про перегляд усіх 28 MP4 не робиться.

Final native джерела зафіксовано у `/workspace/nooneisreal-evidence/weapon-craft/final-native/source.json`; front/side послідовності знято тим самим helper, що й immutable baseline `4c68473` у `/gear-review/before-weapon/`. Renderer Compatibility/llvmpipe, actual gameplay progression 60 Hz. FX створюються/завершуються, але їхній окремий контейнер прихований в обох anatomy captures, щоб shards не закривали кисті. Нового provider bitmap під час цього motion capture немає: демонструється перевірена procedural UV поверхня, sampler hookup не видається за готову generated map.

### Приглушена палітра за новим запитом користувача

Користувач відхилив яскраву кислотну поверхню після checkpoint. T6 особисто звірив canonical weapon reference і картку Choko: зберігаємо темний bottle emerald, темну обмотку та aged brass. Новий material-only candidate: blade **#315D52**, wrap **#263B35**, brass/inlay **#9A8960**, ultimate gold **#B8AA7B**; лілова cel shadow **#514559**, rim 0,10 замість 0,18. Це підібрані reference-based значення, не виміряні pixel samples. Геометрія, пози, контактні дуги та physics не змінюються.

Optional map path перейменовано на `sword_inlay_muted_20261005.png`: старий paid job не може автоматично активувати відхилену поверхню. Попередні motion PNG доводять геометрію та безперервність, але не видаються за final palette proof. Material-only targeted regression `muted-material-check.log`: **230/0**, raw-clean. Root інтегрований playable suite: **76 сценаріїв, 0 failures**. Палітра оновлювалася під час цього прогону, тому suite підтверджує frozen geometry/gameplay, а не приписується цілком новому material snapshot. T6 bounded palette acceptance: **18 matched native + 6 close кадрів**, raw-clean. Особистий огляд stow-back / right-idle-side / gold-side підтвердив forest emerald із приглушеною brass без acid green; ultimate лишається окремим теплим станом. Material SHA `e5d19e6c… / 9cc1365e…` підтверджено. Compact proof: `docs/assets/screenshots/2026-10-05-equipment/reference-correction.jpg`. Це приймання fallback-палітри; якість ще не отриманої generated map не заявляється.

 Обмеження Choko asset: glove fingers не огортають руків'я повністю; повний thumb-contact або finger rig не заявляється.

## Related

- [[2026-10-05-Equipment-And-Cloth]] · [[2026-10-05-Equipment-Session]] · [[2026-10-05-Equipment-And-Cloth-Research]] · [[2026-10-05-Equipment-Visual-Audit]] · [[2026-10-05-Gear-And-Cloth-Review]] · [[Textures-Registry]] · [[Characters/Choko]] · [[2026-10-05-Whole-Body-Presentation]] · [[ADR-004-Physics-Is-Presentation]]
