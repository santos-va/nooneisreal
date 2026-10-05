# Паркур: native візуальний аудит

2026-10-05 · T6 Аполлон · завдання [[2026-10-05-Responsive-Parkour]]. Нові ассети й provider-генерації не створюються.

## Метод і межі

`tools/animation/parkour_capture.gd` запускає справжній `CityFighter` через `InputRouter`: наближення, стрибок, захоплення, відпускання й повторний jump для підтягування. Анімаційні metadata не підставляються. Типовий маршрут використовує справжній `CityDistrict`: навчальний уступ 2.8 м для обох героїв і південну стіну східного крила для Skea. Камера огляду та освітлення ізольовані від production `CityWorld`; це не gameplay-camera приймання. Додатковий `--fixtures` режим явно ізолює collision solids від міста й не видається за міський маршрут.

Ранній review geometry виявив, що запропонований уступ 1.4 м за `hang_height=1.65` вимагав би ніг на 0.25 м під підлогою; T2 підняв навчальний уступ до 2.8 м перед фізичною перевіркою. Це виправлений контрприклад, а не native результат.

Нативний display підготовлено через встановлений Xorg dummy `:98`; `xdpyinfo` підтвердив живий X11 server. Xvfb у середовищі відсутній. Перший preview використовував встановлений **4.6.3**; пізніше координатор надав перевірений офіційний **4.7 stable 5b4e0cb0f**, і наступний запис виконується цільовою версією. Linux/Mesa llvmpipe не є прийманням Mac/M3 або апаратного FPS.

Точка доказів: `/workspace/nooneisreal-evidence/parkour/visual/`. `trace.json` має реальні координати, швидкість, фазу, progress, animation cycle, authored source і grip error. PNG знімаються через `RenderingServer.frame_post_draw`; кадри не домальовуються. Приймання потребує фактичних фаз `hang`/`mantle` для обох героїв та `wall_run` для Skea, успішного native завершення й огляду послідовностей.

## Перший native preview: відхилений для фінального приймання

`visual/preview/`: **225 PNG, 450 physics ticks, rc=0**, `PARKOUR_NATIVE_COMPLETE images=225 ticks=450 failures=0`. `source.json` містить SHA-256 джерел саме цього запуску. Native 4.6.3 Compatibility / Mesa llvmpipe, є попередження unsupported VSync; shader/runtime помилок у `native.log` немає. Це не фінальний source й не цільова 4.7.

Фактичні фази: Choko 13 hang + 31 mantle; Skea на уступі 4 wall-run + 13 hang + 31 mantle; Skea на високій стіні 39 wall-run ticks. Огляд трьох 12-frame sheets і окремих повнорозмірних кадрів підтвердив працездатний маршрут, але виявив дві причини не приймати presentation:

1. **Mantle читається як підскок із руками перед обличчям.** Старий `Climb_Up` — циклічне лазіння; руки залишають край рано, коліна піднімаються, тіло рухається над уступом. T2 знайшов наявний authored `ClimbLedge` і готує заміну джерела. Стабільний Choko hang має близько 0.050 м grip error, перехідний tick14 — 0.117 м; ці величини не змішані в одне зелене твердження. Для Skea найбільше виміряне в цій послідовності — 0.0051 м.
2. **Площина wall-run не враховує виступи фасаду.** На маршруті x14 південна площина крила — z30, декоративна центральна пілястра сягає z30.20, горизонтальний пояс — z30.28 (`CityArchitecture._facade`, `_local_box` без collider). У tick34 тіло стоїть на z30.35086, опорний ankle — z30.07; видимі перекриття руки/обличчя/стопи потребують фізичного розв'язання виступів. Це не виправляється вибором камери або записом гладкої стіни замість проблемної. Точний skinned triangle intersection цим знімком не виміряно.

Докази огляду: `preview/choko-transition.jpg`, `preview/skea_ledge_mantle-sheet.jpg`, `preview/skea_wall_run-sheet.jpg`; координати — `preview/trace.json`. Після виправлень потрібен повтор на 4.7 і огляд протилежного ракурсу. Фізичні clearance/budget та точні контактні помилки належать незалежним runtime-регресіям.

## Цільовий 4.7: повтор і додатковий контрприклад стопи

`visual/final47/` — назва директорії кандидата, не твердження остаточного GREEN. **180 PNG / 360 ticks / rc=0**, додатковий `opposed47/` — **30 PNG / 60 ticks / rc=0**. Підтверджені версія 4.7, actual CityDistrict і незмінність source SHA-256 під час основного запису. Обидва raw native журнали мають лише unsupported VSync warning.

- Новий `ClimbLedge` завершує mantle випрямленням і опущеними руками, без повторного циклу рук над головою. Choko stable hang — **18.76 мм**; Skea — **менше 0.001 мм**. Початковий Choko blend tick14 має **82.44 мм**, тож не видається за той самий stable contact. Обидва герої реально отримують floor contact на висоті **2.8009 м**: Choko ticks61–87, Skea63–87. Наприкінці збережений forward input веде їх за дальній край; це не невдалий mantle.
- Skea має **22 wall-run ticks**, припиняє підйом біля фізичного фасадного пояса і падає. Корпус/обличчя більше не проходять крізь виступ. Ранні 39 ticks із відсутнім trim collider не є вимогою до виправленого маршруту.
- Додано **справжню input-послідовність Choko hook → reel → release**: WINDUP10, FLIGHT8, контакт tick26, 44 HANG ticks, укорочення **1.2 м**, block-release tick 70 і ground contact наприкінці. Зачеп не підставляється через metadata або примусове attach.

Протилежний ракурс виявив, що одна перевірка ankle ray ще не захищає ширину взуття. `visual/shoe-before/trace.json` підтвердив точними weighted skin samples: у tick26 **353 із 1227** правих shoe vertices строго всередині реальної пілястри x13.89–14.11, y0.15–7.85, z30–30.20; максимальна внутрішня глибина **69.30 мм**. У tick18 — **466 vertices / 94.74 мм**. Це реальне проникнення, не камера. Headless proof має teardown resource warnings, тому його rc/sentinel не оголошується загальним зеленим тестом; збережені координати прямо доводять контрприклад. T2 отримав footprint repair; повтор має перевірити **весь** shoe footprint і нуль strict-inside vertices, з непорожніми samples як передумовою.

Helper підтримує `--case=skea_wall_run --ticks=60 --foot-proof --check-feet` для числового повтору; `--check-feet` без `--foot-proof` зберігає той самий oracle разом із native PNG. Guard перевіряє кожен tick, включно з входом/виходом і падінням: непорожні samples, finite skin vertices і нуль strict-inside vertices.

## Прийнятий локальний зріз після footprint repair

T2 замінив ankle-radius припущення реальною проєкцією всіх shoe vertices та footprint rays по фізичних поверхнях. Після цього T6 повторив числовий guard і потрібні native маршрути на **4.7**:

| Доказ | Реальний результат |
|---|---|
| `shoe-clean.log`, `shoe-clean/trace.json` | 60 ticks, **1220/1227** shoe samples, **0 invalid / 0 strict-inside**, rc0, чистий raw |
| `wall-fixed47/` | 90 ticks / 45 PNG, той самий guard на всіх ticks, **0 failures**, rc0 |
| `wall-opposed-fixed47/` | 60 ticks /30 PNG з протилежної камери, **0 invalid /0 strict-inside /0 failures**, rc0 |
| `ledge-fixed47/` | 90 ticks / 45 PNG, Skea wall→hang→mantle→ground, **0 failures**, rc0 |

Headless teardown виправлено в самому capture helper: verbose показав активний `land_2.ogg` playback, а simulation timer під `--fixed-fps` не давав аудіомікшеру реального часу на звільнення. Застосовано наявний project pattern із 250 мс wall-time drain. Повтор `shoe-clean.log` більше не має resource/ObjectDB leak. Нові native журнали не мають shader/runtime помилок або leaks; лишається відоме попередження unsupported VSync.

T6 особисто переглянув `wall-fixed47/wall-sheet.jpg`, обидва повнорозмірні tick26 та `ledge-fixed47/skea-ledge-sheet.jpg`. Колишня занурена стопа тепер видима перед пілястрою з обох боків, чергування колін/стоп лишається читабельним; корпус зупиняється перед виступом, після блокування підйому герой падає. У Skea mantle збережені контакт і вихід на верхню опору; помітної інверсії коліна/ліктя чи перетину книги з тілом у переглянутих кадрах не знайдено. Точна cloth/gear геометрія підтверджується окремим T2/T4 oracle, а не лише цим оглядом.

Порівняння sidecar до/після **лише footprint repair**: **0 відмінностей tick/phase/body position/velocity/grounded** на обох 90-tick маршрутах Skea. Фінальний `wall-fixed47/source.json` побайтово звірено після native записів. Choko ledge та rope з `final47/` залишено в прийнятому наборі: подальша production зміна обмежена Skea wall shoe contact; provenance демонстрації явно зберігає обидва manifests.

Прийнятий набір: **210 native PNG /420 ticks** — чотири основні 90-tick маршрути та протилежний wall ракурс60. Це обмежене локальне візуальне приймання реалізації, не гарантія всіх фасадів, комбінацій інпутів, camera modes або завершеного художнього полірування. Mac/M3 feel, апаратний FPS і слухове приймання тут не виконувалися.

Демонстрація: `/workspace/nooneisreal-evidence/parkour/visual/parkour-demo.mp4`; `parkour-demo-provenance.json` містить порядок маршрутів, source manifests, ffprobe і SHA-256. Чотири native послідовності з'єднано без інтерполяції/генерації кадрів: **180 кадрів, 30 fps, 6 с, 960×640**. Швидкість відповідає записаній фізиці: PNG знімалися кожного другого 60 Hz tick. Аудіо не записувалося.

## Останній hook delta: близький low-hook і оновлення демонстрації

Після розширеної регресії T2 виправив city HANG: після catch корпус читає фізичне навантаження, а рука розв'язується до справжнього grip з нейтральної площини плеча; авторська орієнтація кисті збережена. Візуальний повтор виконано **після** замороження цього джерела, без зміни gameplay або cloth clearance меж у T6.

`hooks-final47/` має новий source SHA manifest та два завершені 4.7 native записи:

- **Choko actual CityDistrict:** 90 ticks / 45 PNG, rc0/0 failures. Збережені attach tick 26, укорочення 1.2 м, release tick 70 та фінальна опора. Порівняння з попереднім записом дало **0 відмінностей** tick/phase/position/velocity/grounded/rope length/attached.
- **Skea low-hook close:** 80 ticks / 40 PNG, rc0/0 failures. Це явно підписаний fixture з реальним `CityFighter` і `GrappleHook.drive`: body=(0,0,0), anchor=(0,2,-4), reel ticks 30–69; не вигадана точка в production районі. Є справжні WINDUP→FLIGHT→HANG, контакт tick 15; 65 HANG ticks. Найбільша виміряна grip error у HANG — **0.000000293 м**.

T6 особисто оглянув обидві 12-frame sheets та повнорозмірні low-hook ticks 24/32. Кисті тримають мотузку; у catch→reel→settled hang не побачено нової інверсії ліктя або складеного всередину грудей передпліччя. Під час reel корпус нахиляється з фізичним навантаженням і повертається після укорочення. Міліметровий cloth-contact не оцінюється на око: його перевіряє окремий geometry oracle. Обидва native raw logs без runtime/shader помилок та leaks, лише unsupported VSync warning. SHA джерел до/після цих запусків збігаються.

Choko rope segment у `parkour-demo.mp4` **замінено новим записом**; попередню версію збережено як `parkour-demo-before-hook.mp4` з власним provenance. Чинний demo перевірений ffprobe: 180 кадрів / 30 fps / 6.000 с / 960×640, SHA-256 `d7acd2eea0fe4988eef7f44e294e0c3a961de106011d2577548d307cf5f9ddaa`. Окремий `/workspace/nooneisreal-evidence/parkour/visual/skea-low-hook.mp4` містить 40 native кадрів / 30 fps / 1.333333 с, без інтерполяції. Прийняті ledge/wall записи залишені зі своїми manifests, бо ця поправка стосується city hook HANG. Остаточний сукупний scoped набір — **250 PNG /500 ticks**, включно з додатковим low-hook close; попередні відхилені previews до цього числа не входять.

## Related

- [[2026-10-05-Responsive-Parkour]] · [[2026-10-05-Responsive-Parkour-Session]] · [[Style-Guide]] · [[2026-10-05-Whole-Body-Visual-Audit]]
