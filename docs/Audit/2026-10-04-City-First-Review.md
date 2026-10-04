# City-first foundation — незалежний аудит

T4 Феміда, 2026-10-04. Початковий технічний стан: після незакоміченого [[Audit/2026-10-04-Combat-Control-Review]], база git `65435de`. Власність тільки цього аудиту; `game/`, GDD і `state.md` не змінюю. **Вердикт: технічний GREEN для окремого прототипу першого кварталу; художнє й цільове device-приймання YELLOW.** Фінальні diff, raw logs і native кадри перевірено. Нових відкритих технічних блокерів у цьому зрізі не знайдено.

## Початковий аудит

| Ризик | Перевірене джерело | Необхідний контракт прототипу |
|---|---|---|
| Глобальний центр і межа | `Fighter.gd`: `ARENA_RADIUS=20`, `_soft_wall`, static `clamp_arena`; площина має окремі12.5. | City adapter не повертає героя до world0; бойовий радіус/арени не змінюються. Walk/dash/rope перевірити поза20м. |
| Поверхи й відновлення | `floor_y` повертає water або0; `_ground_spot` задаєY0; `_post_move` не допускаєY<0. | Власний floor/support контракт у місті, відсутність прилипання до даху над головою, реальний collider як опора; падіння/respawn із безпечної точки. |
| Не-city-ready skills | `Printer.print_now` використовує arena clamp іY0; `SwordStormFx.in_arena` використовує20м; `KunaiRain` перевіряє абсолютну висоту жертви<4. | Не видавати ці скіли за придатні для багатоповерхового світу. Авторизований traversal prototype може явно відключити combat skills/passive без витрат meter/cooldown; бій на чинних аренах збережений. |
| Single opponent | `Fighter._physics_process` синхронізує пару; `_check_hit` працює з одним opponent; `DuelCamera` потребуєдвох. | City explorer без фальшивого прихованого суперника; окрема chase/orbit camera, null-safe рух/норми/гарпун. NPC не маскуються під бойових цілей. |
| Geometry collision | `Fighter.tscn` mask1; `ArenaLayout.COVER_LAYER=8`; `GrappleHook.line_clear` перевіряє COVER_LAYER. | Стіни/дахи solid1\|8, опорна підлога1; реальні openings/проходи, а не накладені намальовані двері. |
| UI й перехід сцени | `InputRouter.acquire_ui/release_ui` очищають buffers і вимагають neutral; `MainMenu` вже володіє UI-token; camera basis — global input adapter state. | City UI не обходить fences через raw Input; пауза/довідка/skip/tutorial/portal не випускають утриманий jump/dash/interaction у gameplay. Restore input profile і basis на виході. |
| Життєвий цикл | `GameState` тримає global water/free_move/config; `Engine.time_scale`, tree pause глобальні; `Fx.root` спирається на current_scene/FX. | Перехід city↔menu↔localfight відновлює saved choices, water/mode/profile/pause/time_scale; FX/rope/record не переживають заміну explorer або teleport ненавмисно. |
| Обіцяні напрямки | На старті немає world/city runtime, існуючий city/NPC документ — preproduction. | Відвідувана область має реальний простір і безпечну arrival marker; planned/unavailable route не видається за готовий портал або за успішний перехід. |
| Boot і відтворення | `Main._ready`: smoke і screenshot маршрути перед menu, saved choices перед launch flags. | Додатковий city route не ламає smoke/screenshot/plane/localmatch. Напрям city-first сам собою не доказ завершеного seamless open world. |

Команди: `git status --short`, `rg -n`, `sed`, `cat` відповідних файлів у цій сесії. Первісно у повідомленні помилково названо radius12.5/COVER16; перевірка джерела дала20/8, виправлення надіслано координатору й виконавцям до реалізації.

## Збереження чинних карт — початкові SHA256

Зафіксовано `sha256sum` до city edits. Попередні незакомічені combat changes не приписуються міській смузі.

| Файл | SHA256 |
|---|---|
| `game/scripts/arena/Arena.gd` | `c257ba641e008e5cfdbdb3841c89ac42bdba89f8f7f8bf9fb27a89f66dddefdd` |
| `game/scripts/arena/ArenaLayout.gd` | `c6edf37cb19702716ca11b4210a30ff7ed691e372a0981cdd0743b3b02fd500f` |
| `game/scenes/arena/Arena.tscn` | `ed1d291f6564c4fe3a707c20091f0d680b0081c7d862f7bfd2c070e0ae3d37d5` |
| `game/scripts/arena/Water.gd` | `59c06332022c1a5d44fec6464436ef8d698c8922aa1ee824afcb34a5ebbeeca1` |
| `game/data/stages/river_water.tres` | `5f97a4ae604dcb02c9392d2b25b690e0c12c2bfa5f4dd418b57adbbf1649c090` |

## Очікувані негативні перевірки

- Actor проходить20м і не повертається до центра; rooftop floor не стає0; overhead roof не телепортує на поверх.
- Рух/стрибок/деш/rope без opponent, обидва персонажі, stock exhausted, release/respawn, ceiling/стіна.
- Вихід із pause/onboarding/scene із затиснутими кнопками потребує neutral; gamepad chord/keyboard однаковий контракт.
- City exit відновлює saved local setup; first-to-two/rematch та поточна бойова батарея все ще проходять.
- Усі exposed routes мають досяжний простір і safe spawn. Недоступне не має активної удаваної кнопки.

## Function / Form / Runtime межі

Поточне доручення дозволяє code prototype й функціональну перевірку маршруту. Paid Meshy, фінальна композиція/експорт і фінальне художнє приймання не виконуються цим аудитом; Function brief не підмінює native геометрію чи затверджений production layout. Немає підстав блокувати авторизоване програмування запитом додаткового дозволу.

## Review початкового diff

Перечитано `CityFighter`, `CityWorld`, `CityCamera`, `CityHud`, `CityLayout`, `CityDistrict`, onboarding model та три focused scripts. Ізольований subclass залишає бойовий `Fighter` незмінним у міській смузі; немає прихованого opponent. Сцена зберігає і відновлює water/free_move/input profile/duel/time_scale; UI використовує власника InputRouter. Геометричні проби перевіряють реальні colliders, capsule clearance, інтерполяцію маршруту й cover sight.

Передано власникам до runtime-приймання:

- На початковому diff `CityWorld` не мав власного Environment/Light. Окремий geometry capture додає своє світло і тому не може виявити цю production-помилку. Потрібні кадри справжнього `CityWorld` з його камерою й HUD.
- Look-event рахував тільки yaw: вертикальний огляд верхнього маршруту не просував навчання. Врахувати pitch, без автокамери як штучної події.
- City HUD приховував finite rope/dash inventory, тому вичерпання виглядало як непрацююча клавіша. Показати remaining/CD та спосіб reuse/restart.
- Negative ultimate-test мав meter0: це не доказ блокування city ultimate. Запас повний, skill2/enemy hook і відсутність витрат мають бути перевірені окремо; додати overhead/ledge/stock cases.

## Фінальний diff і доказ

Проміжні журнали координатора власноруч прочитані: `city-first/geometry.log` —1110/0,221 meshes; `onboarding.log` —52/0; `check.log` —smoke164/19847frames GREEN. `git diff --check` чистий; повторні п’ять SHA256 карт збігаються з baseline.

Початковий `runtime.log` —56/2, обидва герої не піднімались при Space. Diagnostic підтвердив: довжина9.568→8.835м, X0.013→0.918м, Y≈0.0009 незмінна. Це реальна провалена acceptance-перевірка, не GREEN; гіпотеза конфлікту floor snap перевірена окремим probe й не підтвердилась. `rope-probe.log` при snap0 показав:8м lateral — рух уздовж землі;3м lateral — підняття0.315м;1м —0.665м за22кадри без walking input. Це залежність реального напряму натягу від кута мотузки. Тест зберігає перевірку далекого скорочення й додає ближню перевірку підйому. Поведінка «Space піднімає з кожного кута» не заявляється; UI має пояснювати ближчий/крутіший підхід. Terrain snap обмежений walking states, що не змінює спільний маятник. У diagnostic audio teardown уже чистий. `runtime-final.log` власноруч прочитано:60/0, без runtime errors/leaks. Повна батарея ще очікується.

Native `capture.log`:14PNG/0, лише відоме попередження VSync у Linux llvmpipe. Оглянуто production entry/upper route/pause, cornerSW, passage та monochrome overhead. Герой/міст/реальний прохід/HUD видимі; production світло присутнє. Геометрія явно graybox, без претензії на прийнятий мальований арт. Початковий monochrome overhead засвічений майже до білого квадрата, тому не прийнятий як читабельний Function floor plan; передано capture-only виправлення контрасту. Production кадри постановочні у справжній сцені/камері, не запис живого input. Повтор `capture-final.log` —14/0, `onboarding-final.log` —52/0: журнали власноруч прочитані, native повтор оглянутий. Оновлений monochrome overhead читає обидві рампи/міст/корпуси; cornerSE показує верхні площини рамп; production pause містить точне пояснення Space/кута/відпускання обох клавіш і вміщується.

Додаткова реальна знахідка T2 після native: верхні грані рамп мали неправильний winding. Виправлено напрям трикутників та flat smoothing; два нові assertions спершу виявили змішані vertex normals у повній батареї. Остаточний `geometry-final.log` —1112/0,221 meshes. Перший повний `playable-final.log`43/1 є невдалим проміжним прогоном; єдиний провал — ці два normals assertions, інші42 сценарії пройшли. T4 переглянув усі43 raw logs: поза очікуваними negative tests лише цей geometry error, без інших runtime/leak знахідок. Наступний `playable-verified.log` мав harness false failure: geometry повернула rc0 і1112/0, але strict sentinel не враховував suffix `meshes=221`. Власник виправив regex, залишивши повне зіставлення рядка й позитивний mesh count.

## Остаточна верифікація

Координатор виконав фінальні engine-команди послідовно. T4 окремо прочитав aggregate і всі43 файли `regression-complete/`: позитивні сценарії без ERROR/SCRIPT ERROR/leaks, negative controls залишилися scoped очікуваними провалами.

| Доказ у `/workspace/nooneisreal-env/city-first/` | Результат |
|---|---|
| `playable-complete.log` |43 сценарії,0 failures; актуальні city1112/60/52 та combat-control549/0 |
| `check.log` / `playable-verified.log` (актуальний smoke) |164 checks,19847 frames, GREEN |
| `gates-final.log` |GREEN;68 GDScript /0 parse failures;171/171 assets;4784 wikilinks /0 broken |
| `capture-final.log` |14PNG /0; лише відоме Linux VSync warning |
| `geometry-final.log`, `runtime-final.log`, `onboarding-final.log` |1112/0,60/0,52/0 |
| Повторні SHA256 п’яти карт |Повністю збігаються з початковою таблицею |

T4 самостійно виконав `git diff --check` та wikilink gate; міський код і стан гри не редагував. Відтворювані команди й source capture harness збережені в `docs/Plans/city-first/README.md`; PNG/logs зовнішні до git, їхня доступність у наступній сесії не гарантована.

## Межі вердикту

Це прохідний64×64м graybox з одним героєм, двома маршрутами, камерою, паркуром і пропускним навчанням. Бойові кишені лише metadata; немає активних порталів, NPC-системи, стримінгу, кампанії чи збереження дослідження. Навички/ульт/ворожий гарпун відключені лише в city prototype і явно названі уHUD. Залежність підйому від кута мотузки описана вище й уhelp.

Оглянуті production кадри використовують справжню камеру, світло йHUD, але сцени для кадрів встановлені harness. Це не доказ живого device-input, M3FPS чи прийнятого мальованого стилю. Function/Form/Runtime людські approvals у skill-пакеті залишилися pending/false; платних job, final export і deployment не було. Перший наступний продуктовий крок — оцінити маршрут і камеру в живому проходженні, потім інтегрувати одну бойову кишеню й спільний фінальний арт.

## Related

- [[Plans/2026-10-04-City-First]] · [[Meetings/2026-10-04-T1-City-First]] · [[World/2026-10-04-City-First]]
- [[Audit/2026-10-04-Combat-Control-Review]] · [[Art/2026-10-04-City-NPC-Development]]
- [[Handoff/2026-10-04-Remaining-Work]] · [[system/constitution]] · [[system/recurring_class_register]]
