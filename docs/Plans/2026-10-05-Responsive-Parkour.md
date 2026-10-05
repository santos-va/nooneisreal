# Чуйна мотузка, уступи та стінний рух Skea

**Дата:** 2026-10-05 · **Роль:** T1 Дедал · **Статус:** `done`
**Виріс з:** прямого доручення Santos цієї сесії, [[2026-10-05-Responsive-Parkour-Session]], [[ADR-019-Audit-And-Many-Views-Before-Decision]], [[2026-10-05-Whole-Body-Motion]]. Дозвіл охоплює реалізацію й перевірку руху, анімацій та паркуру.

## Що хоче Santos

Виправити слабке, повільне й незрозуміле користування мотузкою; додати місця захоплення та залізання, відповідні анімації, швидке перебирання ногами Skea зі стінним рухом. Розподілити роботу й повернути перевірений результат.

## Аудит і погляди

| Що перевірено | Джерело цієї сесії | Висновок |
|---|---|---|
| База | `git log -3 --oneline`, `git status --short` | Чисте дерево `work`, HEAD `fe37869`, merge PR #178; старий state ще називає PR draft. |
| Актуальність remote | `git fetch origin` | Немає з'єднання з proxy:8080; remote-стан не підтверджено. Локальна база відома. |
| Мотузка | `GrappleHook.gd`, аудит T2 rope_physics | WINDUP 30 ticks гасить горизонтальний рух; reel 2, pump 5, drag .65. Це чинні PLACEHOLDER, а не вимір сприйняття. |
| Паркур | `CityFighter.gd`, аудит T2 parkour | Є адаптація підлоги/меж, але немає ledge-hang/mantle/wall-run. Капсула .35/1.8. |
| Анімації | Список `game/scripts/fighter/` | Наявні authored hook, whole-body, cadence й sole correction; зберігаємо їхні контракти. |
| Інструменти | `command -v godot`, `command -v game-dev` | Godot доступний, game-dev відсутній; використовуємо чинний native workflow. |
| Сусідні роботи | Локальний HEAD/state та чисте дерево | Спорядження вже в базі; його contact/cloth перевірки потрібні після нових поз. Remote CI і живі сторонні термінали не перевірені. |

**Уточнення середовища після стартового аудиту:** повторний `git fetch origin` із дозволеним мережевим доступом успішний; `origin/main` = `fe37869`. Офіційний Godot 4.7 завантажено в `/workspace/tools/godot-4.7/`, SHA512 звірено з release manifest, `--headless --version` = `4.7.stable.official.5b4e0cb0f`. Початкові focused результати 4.6.3 не підміняють фінальну перевірку 4.7.

Чинні рішення: [[ADR-004-Physics-Is-Presentation]], [[ADR-023-City-First-Exploration]], [[2026-10-05-Whole-Body-Motion]]. Рух міста змінюємо в окремому профілі; бойові hitboxes/frame data лишаються за своїм контрактом. Художнє приймання й M3 FPS не випливають з headless тестів.

| Варіант | Наслідки | Вибір |
|---|---|---|
| Лише прискорити кліпи | Невеликий diff, але механічне гальмування й відсутність уступів залишаються | Відхилено |
| Повністю замінити контролер на фізичний | Великий ризик бою, rewind, inventory і collision | Відхилено |
| Окремий city traversal profile + bounded parkour motor + presentation | Реально виправляє відгук, дає уступи й стіни, ізолює бій | Обрано |

| Погляд | Виграш / ризик | Наслідок для рішення |
|---|---|---|
| Автор | Виразний швидкий Skea / безмежне лазіння руйнує маршрут | Обмежені стінні кроки з одним повітряним бюджетом |
| Новачок | Хват і підйом читаються / автозахоплення може заважати стрибку | Намір через jump + рух, явний вихід, контекстна підказка |
| Змагальний гравець | Незмінні бойові кадри / city tuning може протекти в duel | Окремий city predicate й регресія дуельного профілю |
| Гравець з чутливістю до руху | Короткі переходи / хитання камери | Не додавати forced camera roll/shake |
| Мешканець світу, інша істота | Фізичні уступи зрозумілі / проходження крізь NPC | Solid collision, капсульний clearance й перевірка опори |
| Виконавець | Реальні повторювані тести / непомітний regress спорядження | Серійні Godot запуски, focused + повний playable |
| Художник | Збережений Sketch-Cel / нові пози можуть перетинати книгу | Існуючі assets, окремий visual огляд та gear regressions |

Вибір відповідає мірилам гри: чесний бій, чинні bindings, читабельність руху, нуль provider credits і прохідний прототип.

## Кроки

| # | Хто | Файли / робота | Ризик | Перевірка |
|---|---|---|---|---|
| 1 | T2 rope_physics | `GrappleHook.gd`, `tools/grapple/`, вузьке уточнення grapple GDD: короткий city windup без гальмування, активніше reel/pump | Надмірна енергія, втрата token/contact | traversal/weighted-swing/harpoon/contact сценарії → 0 failures |
| 2 | T2 parkour | `CityFighter.gd`, новий motor/profile, solid уступи міста; справжні collider на виступних фасадних деталях `CityArchitecture.gd` | Прохід крізь стіни/декор, нескінченний підйом, stale state | нова parkour регресія: reach, clearance, release, reset, budget; city geometry/runtime → 0 failures |
| 3 | T2 animation | `RigAnimator.gd`, hook/body/cadence helpers, parkour poses | Foot sliding, зірвані кисті, gear penetration | animation focused/ground/whole-body/gear → 0 failures |
| 4 | T8 ui | `CityHud.gd`, потрібні onboarding/help | Незрозумілі bindings, перекриття HUD | UI/input/onboarding сценарії → 0 failures |
| 5 | T4 review | `docs/Audit/`, незалежне читання diff і negative cases | Помилкове зелене приймання | Висновок із доказами й явними межами |
| 6 | T1 coordination | Цей план, журнал, маршрут state; серійна інтеграція | Конфлікт shared checkout, застаріле приймання | `make check`, `make gates`, `bash tools/gates/playable_check.sh` → rc=0 і кінцеві sentinels; останній крок разом із `make check` відповідає складу `make check-playable` |

Нові фізичні числа — PLACEHOLDER до ігрового приймання. Публікація, merge та paid генерації в цю хвилю не входять. Higgsfield відео не є імпортованими Godot skeletal clips; поточна реалізація використовує наявний rig та authored/procedural шари.

Native preview виявив реальну різницю поверхонь: пілястра та пояс південного фасаду виступали на 0,20–0,28 м за collision-площину, тож wall-foot target ішов за видимий камінь. Вузьке виправлення — фізична колізія фактичних деталей, зі збереженням вільних проходів. Невидиме загальне потовщення стіни й перенесення capture на іншу стіну відхилені: вони приховали б дефект. Нова перевірка має проходити на тому самому фасаді.

## Хендофи

Смуги запущено як агенти зі спільним деревом і неперетинними власниками файлів. Parkour передає анімації/UI metadata `parkour_presentation`: phase (`hang`, `mantle`, `wall_run`), wall_normal, left_hand, right_hand, progress, speed, direction, wall_point, hold_remaining. `parkour_snapshot()` повертає копію; неактивний стан очищає metadata. Кожен виконавець веде свій Fix; T4 перевіряє незалежно. Godot виконується лише одним агентом одночасно. Кожна смуга повідомляє координатору завершення та raw log. План закривається після звірки кінцевого дерева.

## Результат і приймання

Локальний зріз реалізовано: city-профіль мотузки, справжні уступи й двоступеневий mantle, скінченні стінні кроки Skea, узгоджені кисті/стопи та контекстні підказки. Деталі виконання — [[2026-10-05-Responsive-Rope]], [[2026-10-05-City-Parkour]], [[2026-10-05-Parkour-Motion]]. Перше інтеграційне приймання 78/2 відхилено; виправлені arm/cloth контакти та audio teardown описані в журналі сесії. Допуски одягу збережені, постійна батарея доповнена city hook guard.

Фінальний Godot **4.7 stable**: незалежні `make check` і `make gates` — **rc 0**, **109 GDS / 0**, smoke **164 / 19 847 кадрів**, **175 / 175 assets**. Координатор повторив повний playable: **79 сценаріїв / 0 failures**, rc 0; усі 79 raw logs без WARNING/SCRIPT ERROR, навмисні assertion errors негативних контролів перевіряє runner. Журнали — `/workspace/nooneisreal-evidence/responsive-parkour/validation/`, `playable-final.log`, `review-check.log`, `review-gates.log`. Усі **764** game/tools файли тотожні між незалежними перевірками й завершенням aggregate; digest `ff65c07d15eae5b17b236c29ff981577de44edf6b6d110e36488cf4574f1e444`.

Native scoped-приймання — **250 PNG / 500 ticks**, [[2026-10-05-Parkour-Visual-Audit]]. Демо `/workspace/nooneisreal-evidence/parkour/visual/parkour-demo.mp4`: **6 с / 180 кадрів / 30 fps**, справжні Godot captures. Це локально перевірена реалізація; tuning залишається PLACEHOLDER, Mac/M3 FPS і оновлення встановленого застосунку цим прийманням не підтверджуються.

## Related

- [[state]] · [[constitution]] · [[2026-10-05-Responsive-Parkour-Session]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]] · [[2026-10-05-Whole-Body-Motion]]
