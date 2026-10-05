# Відштовхування від стіни та перекат після приземлення

**Дата:** 2026-10-05 · **Роль:** T2 Гефест · **Статус:** локальну реалізацію й інтеграцію перевірено; вузький camera corner залишається художньо не прийнятим.

Предмет: для всіх нових міських трюків: реальна collision лишається авторитетною, повітряне зусилля скінченне, а перекат не додає швидкості або невразливості.

План [[2026-10-05-Parkour-Tricks-And-Quality]] звірено з CityParkourMotor/Profile, CityFighter, Fighter та InputRouter. Виявлені hang/mantle/wall_run та фактичний landing branch відповідають плану. Дані нових рухів позначені PLACEHOLDER; дуельний Fighter та character data не редагуються.

Wall kick: нове натискання jump після відпускання, напрям від реальної вертикальної стіни; один поштовх за цикл між опорами. Landing roll: crouch та напрям під час достатньо швидкого приземлення з JUMP; лише широка майже горизонтальна опора, швидкість зберігається з обмеженням і далі гальмується. Нові стани presentation читають фізичні metadata. Капсула залишається вертикальною й не проходить під низькими перешкодами завдяки позі.

## Перевірка

Команда: `tools/parkour/city_tricks_check.gd` і попередній `city_parkour_check.gd` через Godot 4.7; проходження — завершений sentinel, 0 failures, чистий raw. На провалі виправляється мотор або явно помилковий fixture; старий провал зберігається. Незалежні форми зламу: stale/held input і повторний бюджет; стіна/стеля/край або відсутність опори; lock/revision/rope та відсутність bonus speed/invulnerability. `make check`, `make gates` і загальну батарею серіалізує координатор. Після передання Godot token виконано перші локальні перевірки (нижче); фінальне інтеграційне приймання наведено нижче.

Перший фактичний 4.7 запуск дав **50/8**: свіжий press після release-observing manual physics tick може мати той самий InputRouter frame. Strict `press_frame > release_frame` помилково відкидав коректний edge. Мотор тепер приймає `>=`, водночас вимагає held jump, попереднього release та відкидає старіші buffered presses. Fixture й oracle не послаблювалися. Повтор `city-tricks-second.log/.rc` — **50/0, rc0**, без errors/warnings/leaks; `city-parkour-current.log/.rc` — попередні **73/0, rc0**, clean. Усі raw збережені в `/workspace/nooneisreal-evidence/tricks-quality/validation/`; початковий провал не зараховується.

Після цього focused fixture розширено незалежними маршрутами hang→kick, Skea wall-run release→kick, напрямом у стіну, краєм опори, timeout та перериванням jump. Розширений focused final — **84/0, rc0**, попередній parkour final — **73/0, rc0**; обидва raw clean, особисто прочитані T2 (`city-tricks-final.log/.rc`, `city-parkour-final.log/.rc`). Дані wall/roll explicit у `city_parkour.tres`; foot support перевіряє центр і чотири точки радіуса капсули, це bounded probe, а не доведення довільної топології всередині всієї підошви.

Окремий source review виявив: відхилений через перешкоду away kick із hang міг провалитися у старий jump→mantle. Тепер такий запит лишає hang; тест ставить backstop позаду капсули при вільному mantle попереду, відхиляє неправильний підйом, прибирає blocker та виконує реальний kick.

Проміжний augmented **84/2** (`city-tricks-expanded.log/.rc`) не зараховано: test setup ставив hook WINDUP разом із Fighter IDLE, але наявний Fighter.tick_regen правильно detach-ить таку неузгоджену пару до motor. Fixture виправлено на справжній MISS_REWIND recovery, який законно співіснує з grounded state; production для цього не змінювався. Перевірено також вузьку/похилу опору, край, finite duration, release, UI owner/revision, jump priority та busy hook.

Ці focused журнали доводять мотор без skeletal rig. Окреме native анімаційне приймання описане нижче та в [[2026-10-05-Trick-Motion]]; M3 feel/FPS не виміряно.

## Справжня камера та світло міста

Новий `tools/animation/trick_production_capture.gd` запускає справжню `CityWorld.tscn`, CityCamera зі SpringArm, освітлення, NPC та HUD. Фізичні/render callbacks залишаються звичайними; InputRouter створює кожний трюк, metadata й пози після стартової станції не підміняються. Чотири declared station маршрути дають **90 PNG / 249 ticks / 0 failures**, rc0; default High, 960×640, Godot 4.7 Compatibility/llvmpipe. Журнали `native-production-final.log/.rc` у `parkour-tricks/validation/motion/`; PNG та receipt у `parkour-tricks/native-production/`.

Первісний запуск `native-production.log/.rc` не прийнятий: preload Fighter у SceneTree fixture починав компіляцію до готовності GameState autoload, далі виникали каскадні initialization/teardown errors. Виправлений лише fixture: runtime load після першого process frame, перевірка успішної ініціалізації та непорожньої очікуваної множини маршрутів. Зелений sentinel без реально виконаних маршрутів більше неможливий. Початкові raw збережені.

На вузькій практичній станції `(4,0,31.4)` production camera стискається до 0,434 м вже до стрибка; під час kick proximity dither та уступ приховують героя. T6 відхилив читабельність цього station kick. Camera code у хвилі незмінний, але порівняння зі старим executable немає: причинність не доведена. Обидва production roll читаються за оглядом T6; камера має 6 м. Додатковий kick обох героїв з чинної відкритої сходинки `(12,0,-3.3)` без camera override дав по **19 PNG / 52 ticks / 0**, rc0: `native-production-open-choko/` та `native-production-open-skea/`. Початкова проблемна станція збережена поруч і не прихована supplemental кадрами. У трьох прийнятих runtime raw немає script/shader/teardown errors; є лише відоме llvmpipe VSync warning. Художній вердикт і durable sheets належать T6.

## Фінальна інтеграція, особисте читання T2

На базі `abce638` у локальній гілці `codex/parkour-tricks-visual-quality` реалізацію перевірено, але не змерджено. T2 особисто прочитав `review-check.log/.rc`, `review-gates.log/.rc`, `check-playable.log/.rc` у `/workspace/nooneisreal-evidence/tricks-quality/final/`: **smoke 164 / 19847 кадрів**, **119 GDS / 0**, **175/175 assets**, **93 сценарії / 0 failures**, усі rc0. Чинні case logs: **city-tricks84/0**, **city-parkour73/0**, незалежні **tricks54/0**, **trick-motion3265277/0**, graphics **63/0**, independent graphics **62/0**, actual-input graphics UI **15/0**.

Власне повторне читання й скан **95 engine raw logs** не виявили неочікуваних errors/warnings/leaks; deliberate negative assertions звірено з їхнім явним whitelist у full-raw-scan. Чотири before/after manifests мають однакові **808 sources**, digest `c5b5d42190c355cb4b416914bed8f5941d1b57a9a7def29e8311734865b7f024`; T2 додатково порівняв фактичні поточні game/tools bytes з останнім manifest — тотожні. Після цього змінено лише документацію.

T6 прийняв scoped open-station kick та production roll обох героїв, збереження палітри й оглянуті High/Low кадри. Тісний practice camera corner лишається **YELLOW / художньо не прийнятий**; його демонструє durable counterexample sheet. Ці результати не підтверджують встановлену Mac-збірку, M3/Forward+ FPS, фізичний геймпад або слухове приймання. Нові числові параметри — PLACEHOLDER.

## Related

- [[2026-10-05-Parkour-Tricks-And-Quality]] · [[2026-10-05-City-Parkour]] · [[ADR-004-Physics-Is-Presentation]]
