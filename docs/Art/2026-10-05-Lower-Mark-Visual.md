# Нижня позначка: художня ціль і native-приймання

T6 Аполлон, 2026-10-05. План [[2026-10-05-Lower-Mark-Expansion]] approved. **Поточний статус: scoped native-приймання галереї, освітлення, копії та сюжетного UI виконано після виправлення стрілок.** Production geometry/state належать T2; цей документ не оголошує їх перевіреними за самим задумом.

## Місце й предметна мова

Нова архівна галерея займає невеликий фрагмент чинного NW даху на y4. Це відкрите службове місце поруч із попереднім двором: кам'яна основа, темна залізна рама, дерев'яна полиця/опора, матова світла плита й стримана латунна головка оглядового ліхтаря. Джерело палітри — `CityMaterials.palette()` і [[Style-Guide]]. Нова фототекстура, неоновий маркер чи платний ассет не потрібні.

Відкритий фронт і невисокі борти мають залишати видимими плиту й поворотний корпус із звичайної gameplay camera. Галерея не повинна перекривати збережений підхід x=-16, рампу службового двору або чинний верхній маршрут. Художній вигляд не доводить прохідність: обидва герої мають пройти фізичні тести власника геометрії.

Велика схема читається як три різні прості форми, з'єднані напрямом: двір → нижня сходова клітка → вежа. Це предметний міський документ; немає порталу, сяючих рун, нового винуватця чи зображення вже доступного підземелля. На плиті потрібні великі темні лінії на світлій матовій поверхні; дрібний Label3D сам по собі не замінює малюнок. Текстове спостереження дублює зміст для 540p і слабкого зору.

Копія після завершення справи в майстерні має повторювати впізнавану тричастинну схему на меншій світлій площині з фізичною опорою. Її видно поблизу Лади, не лише як новий рядок журналу. До завершення предмет відсутній; огляд копії й NPC не мають конкурувати за один input prompt. Масштаб, сили світла й геометричні розміри — художні PLACEHOLDER до native-приймання.

## Ліхтар: доказ справжнього освітлення

Положень два, без таймера й точного прицілювання. Поворот змінює напрямок видимого корпусу і реального світла: away освітлює інше місце, toward — саму плиту. Матовий світлий камінь не має вибілювати темні символи; різниця читається на самій поверхні, а не лише в HUD. Світлова дія не вимагає вигаданого volumetric-променя у повітрі.

T6 прочитав `city_surface.gdshader`: чинний `light()` використовує `ATTENUATION` тільки для порога lit band, але додає shaded-term навіть за attenuation=0. Тому простий SpotLight із цим спільним матеріалом ризикує давати additive-засвіт поза конусом. Власнику геометрії передано рекомендацію локального plate material із коректним attenuation; глобальну заміну поверхонь міста цією хвилею не пропонуємо. T6 уже прочитав перший `CityLowerGallery.gd`: плита, геометричні символи й away receiver використовують локальні StandardMaterial3D із disable_ambient_light та render layer8, SpotLight має cull mask8, lens і світло спільний pivot. Це обґрунтоване локальне рішення; його нативна пляма й читабельність перевірені нижче. Окремо передано вимогу різних силуетів двору/вежі та повторення glyphs на workshop copy.

Не приймаємо як заміну реального світла: state-only напис «освітлено», приховування/появу символів або простий emissive toggle на плиті. Якщо використано допоміжну графічну підказку, вона описується окремо від доказу SpotLight. Для нативної пари зберігаються однакова камера, експозиція й незмінений матеріал; trace записує реальний напрямок/позицію світла.

## Контракт приймання

1. Actual offer/accept другого епізоду після **durable** завершення першого для того самого героя. Сюжетний стан не підставляється ручним присвоєнням. Збереження — окремі custom paths у свіжому XDG; fixture не зачіпає користувацький профіль.
2. Загальний вид галереї поруч із дахом і підхід зі звичайної gameplay camera. Оглядова камера — окрема Camera3D, не дочірня SpringArm, який може змістити її між кадрами.
3. Однакова близька камера away/toward: видно корпус ліхтаря та всю схему. Дія проходить production interaction handler з чинними grounded/range/LOS/UI guards; стабільна ділянка плити показує фактичну різницю освітлення без підміни експозиції.
4. Реальне зняття відбитка, повернення ліхтаря вбік і незмінний факт отриманої копії. Положення світла й сюжетний факт не видаються за одну змінну.
5. Actual return/complete у Лади; парні workshop absent/present кадри з видимою копією, durable save і журналом. Телепорти між review stations явно записуються; не називаємо їх ручним проходженням маршруту.
6. Offer, current objective й обидві глави журналу у фізичних 960×540 та 960×720. Metadata записує actual PNG/logical viewport dimensions. На 540p перевіряємо middle і bottom власного scroll, щоб останній сюжетний висновок був доступний. Один узгоджений guide/card, NPC priority без подвійного prompt.

T6 особисто дивиться raw native, T8 незалежно перевіряє читабельність UI, T1 оглядає короткий фінальний артефакт. State/save/input негативи й реальний рух — окремі T2/T4 перевірки. Стан source фіксується SHA-256 до/після; script/log/save/trace і rejected fixture зберігаються поза `game/assets/`. Подальший validation-only delta не приховується під старим receipt.

Невеликий contact sheet із незмінних native PNG достатній; новий довгий ролик не потрібний. Linux llvmpipe не доводить M3 FPS, встановлення macOS застосунку або повну кампанію. Без нових asset files реєстр текстур не змінюється.

## Перший native і відхилений напрям стрілок

Перший actual success chain збережено у `/workspace/nooneisreal-evidence/lower-mark/native-rejected-arrows/`: 21 PNG, exit0, 0 fixture failures, source793 digest `4375c728c3b4e575e5d3533a3af0fee0502c4ac4bfb48329855ad1c2aea0efaf` до/після однаковий. Це **відхилений art candidate**, попри правильні state assertions: T6 на `plate_toward.png` побачив два геометричні arrowheads, відкриті вправо й з'єднані зліва — форму fork/Y замість напрямку →. T1 незалежно підтвердив. Власник геометрії поміняв тільки два знаки `rotation.x` верхньої/нижньої частини наконечника; нових колізій чи матеріалів не додавав. Копія в майстерні вже мала правильні три glyphs і типографічні →, її не міняли.

Пара before/toward довела реальний світловий принцип: camera transform, material instance ID, SHA параметрів та обидва serialized material `.tres` ідентичні; світло повернулось із +Z до +X. Темна плита стала теплою матовою, символи й текст лишилися темними та читабельними. Це позитивний scoped proof освітлення, але не підстава прийняти помилковий малюнок стрілок. Фінальна серія після correction збережена окремо у `native-final/`.

Перша gameplay camera біля lamp station частково затуляє героя стійкою/корпусом ліхтаря; цей один постановочний близький ракурс не доводить постійне застрягання камери. Окремий вхідний огляд показує відчинений отвір і весь простір, а plate camera — незатулену поверхню. Подальшої production camera зміни за одним кадром не вимагали.

## Остаточний actual native

Evidence root: `/workspace/nooneisreal-evidence/lower-mark/`. Official Godot **4.7**, Compatibility/llvmpipe, Dummy audio, незмінне production світло/експозиція. `native-final/` — **21 PNG / 0 failures / exit0**; `orphan-native/` — **1 PNG / 0 failures / exit0**, але лише handler diagnostic; див. уточнення reachability нижче. У кожній серії до/після ідентичні **793 game/tools sources**, digest **`0beea2abbfde9b603487a1c8aa3084f0337d3e842ab0d772d701789e09b6b32c`**. `CityLowerGallery.gd` SHA-256 `195e62ca116c27c6101e99b684c91ae567ef7bd8c9af62fbf9dfd9c007a0ea22`. Raw logs мають тільки відомий VSync warning; script errors/resource leaks немає.

Попередню главу підготовлено окремим durable `CityStory` model setup через accept/inspect/open/complete в ізольованих user paths. Це явно позначений prerequisite fixture, не повторне ручне проходження першої глави. **Усі дії нової глави** проходять production NPC offer/accept/complete та `CityWorld.interact_story`; lower flags/геометричні наслідки не присвоюються fixture. Межі review stations лишаються телепортами. У кінцевому збереженні accepted/copied/completed=true, lamp_aligned=false: копія збереглась після повторного відведення світла.

T6 особисто переглянув final `plate_toward`, `workshop_after`, `copy_readonly_hud`, `copy_retained_away`, і orphan, а також парні away/overview та UI попередньої серії з незміненими UI джерелами. T1 незалежно відкрив final plate й overview: напрям обох стрілок → правильний, три glyphs і текст узгоджені, вхід галереї читається. Final workshop показує впізнавану копію на стіні під годинником; `workshop_before` з тієї самої камери її не має. Жодної нової текстури або зовнішнього ассета не додано.

`light-and-copy-proof.json` доповнює особистий перегляд: для away/toward camera transform, material instance, параметри матеріалу та serialized `.tres` byte-identical. SHA матеріалу `f7aab395c38c4384d5a4152ba631d29690373b29ff8c1f9e5c95740867b9b735`; energy постійна 3.4, світло повертається +Z→+X. У вручну визначеній за native blank patch плити `[355,272,415,291]` (1140 pixels, без shader-derived mask) середня sRGB8 luma змінюється **0→136.62**. Це опис реальної render-різниці, не калібрування lux чи повний raster regression. Геометричні символи й матеріал існують в обох положеннях; немає emissive/visibility підміни.

## UI, orphan і межі

У success-серії **12 actual 960×720** (logical1600×1200) і **9 actual 960×540** (logical1600×900); orphan — ще один actual 960×540. До прийняття справи фізичний prompt веде лише до пояснення, ліхтар не повертається. На темній плиті відбиток не видається. Після отримання копії prompt змінено на «Переглянути схему»; відведення ліхтаря прямо пояснює, що знятий відбиток лишився в журналі. Картка й direction guide показують ту саму актуальну дію; довга назва у вузькому QUEST полі має ellipsis, повний текст лишається у правій картці.

Обидві глави журналу доступні через власний scroll: top540 — «Нижня позначка», middle170 — отриманий відбиток і межа неперевіреного маршруту, lower340 — попередній «Слід під годинником», bottom — останні district tasks. Область має приблизно 3–4 рядки, весь текст одночасно не вміщується; кнопки pause доступні й не виходять за кадр. Native не доводить фізичну клавіатурну/геймпадну навігацію, яку окремо перевіряють T4/T8.

Перший orphan diagnostic — **окремий новий CityWorld**, валідний successor file зі справжнього success chain та інший missing predecessor path. Native NPC повідомляє: «Продовження призупинено; збережені дані не змінено». Effective stage=locked, has_copy=false, delivered=false; немає повідомлення про нове завершення. SHA successor bytes до/після однаковий у `orphan-native/trace.json`; це не ручне обнулення lower flags. Не видаємо цей diagnostic за звичайний безперервний маршрут.

Приймання scoped: нова невелика галерея, світлова дія, документ і UI. Сходи нижнього маршруту **ще лише на схемі**, прохід до катакомб не реалізований. Немає нової анімації ручного натирання паперу чи повороту рукою: показані реальні предметні зміни та production результат взаємодії. M3 FPS/feel й встановлення macOS застосунку не вимірювали.

T8 незалежно переглянув десять final UI PNG та перший orphan handler diagnostic, прочитав обидва trace/rc: scoped UI прийнято, blockers немає. Повні формулювання, усі pause controls і дві глави доступні; ellipsis у верхньому guide й малий journal viewport залишені як явні межі.

## Уточнення reachability orphan-повідомлення

Після приймання T1 знайшов помилку scope зовнішнього fixture: він напряму викликав `_choose("lower:hint")`, хоча при missing predecessor NPC не показує такої опції в реальному меню. T6 визнає цю межу: `orphan-native/orphan_suspended_540.png` **не є доказом доступного гравцю menu path**. Збережено raw/trace/source і `acceptance-scope.json`; вони лишаються валідною діагностикою handler-а, effective suspension і незмінності bytes. Production не змінюється, бо доступний pause journal уже показує призупинення.

Виконано новий окремий `orphan-journal/capture-fixture.gd`: fresh world з тим самим actual completed successor та missing predecessor; інжектовані фізичні key events **Escape → Shift-Tab до журналу → Up** проходять справжній UI. Hidden lower choice не викликається, текст label або scroll position не призначається вручну. Перша спроба з Down відскролила великий Label до кінця через follow-focus: хоча trace містив suspension, PNG показував лише errands. T6 і T7 відхилили цей кадр як proof читабельності; його збережено в `orphan-journal-initial-scroll/` із точним scope.

Фінальний **`orphan-journal/orphan_journal_540.png` — 1 PNG / 0 failures / exit0**. T6 особисто прочитав у кадрі два повні рядки: «Нижня позначка · Прогрес попередньої справи не вдалося відновити або зберегти» та «Продовження призупинено; збережені дані не змінено». T8 незалежно відкрив цей PNG, fixture, trace та rc й підтвердив scoped reachable-journal приймання. Наступна глава нижче viewport, її одночасної видимості в цьому конкретному кадрі не заявляємо.

Trace фіксує actual 960×540 / logical1600×900, journal scroll89 при labelY106, stage=locked, copied=false, delivered=false; збережені successor bytes до/після SHA-identical. Маніфести before/after містять ті самі **793 sources**, digest **`0beea2abbfde9b603487a1c8aa3084f0337d3e842ab0d772d701789e09b6b32c`**, без production змін. Raw лише відомий VSync warning, жодних script errors/leaks. Цей один reachable-journal кадр закриває scope gap; основний 21-frame success chain і обидві таблиці незмінні та не містили старого orphan handler кадру. Runtime передано T1, T6 source/doc freeze після цього запису.

## Артефакти та відтворення

- `lower-light-copy.png` — actual away/toward і workshop absent/present.
- `lower-story-ui.png` — actual offer, відбиток, повернення до Лади, завершальний висновок журналу.
- `native-final/capture-fixture.gd`, `run_native.py`, `compose_review.py`, `review-artifact-provenance.json` — точні scripts і receipts. На таблицях raw PNG вставлено без resize/ретуші; тільки зовнішні підписи.
- `native-final/{trace.json,source-before.json,source-after.json,completed-lower-save.json,predecessor-save.json,light-and-copy-proof.json,native.log,native.rc}` та equivalent orphan receipts. Оригінальні кадри збережені окремо від таблиць і rejected arrows.

## Related

- [[2026-10-05-Lower-Mark-Expansion]] · [[2026-10-05-Clocktower-Story-Visual]] · [[Style-Guide]] · [[Textures-Registry]] · [[Lore]] · [[ADR-023-City-First-Exploration]]
