# Cronshift: початок розробки міста та п’яти NPC

Власник: T6 Аполлон. Дата: 2026-10-04. Статус: **передвиробничий бриф, не готові моделі**. Підстава — запит Santos: місто з вищими зачепами, менше точок гарпуна, п’ять недоступних бою NPC з різною пластикою, дивним позачасовим одягом, сучасним взуттям та аналоговими ШІ-пристроями. Назви нижче — робочі, не затверджений лор.

## Аудит і погляди

Перевірено `game/scripts/arena/ArenaLayout.gd`: у `fountain` зараз 17 якорів (центральний, два кільця по 8), висоти 5.5–7 м; у `bazaar` — 16, висоти 5–7 м. `Arena.gd::_anchors_around` розмножує старі річкові точки та додає кільце; тому відчуття надмірної кількості має конкретне джерело. Тут код і розкладка не змінюються. [[Choko]] вже має канон принтера без екрана, паперу та латунного дрона; NPC отримують споріднену мову предметів, а не копії його пристрою.

Варіанти: A — ще одна плоска площа з намальованим силуетом; B — компактний квартал із товстими фасадами, поперечними вулицями й балконами; C — суцільне багатоповерхове місто з доступними інтер’єрами. **Пропозиція B**: дає паралакс і висоту без обіцянки десятків непобудованих приміщень. A не виконує запит на об’єм; C відтягує виправлення самого бою.

П’ять перевірок задуму: новачок має відрізнити зачіп від декору; боєць після дешу має бачити загрозу; гравці удвох мають рівний доступ до високих точок; мешканець міста має власний маршрут поза боєм; власник MacBook Air має отримати контрольоване навантаження. Для користувача з чутливістю до руху NPC не миготять і не роблять синхронний танець за героями.

## Простір і функція

Новий квартал — пропозиція для окремого прототипу, не непомітна заміна поточних арен. Усі наведені нижче числа — **PLACEHOLDER / дизайн**, а не виміряний бюджет або затверджений баланс.

- Бойове коло чинного радіуса 20 м зберегти до рішення T5; фасади розташувати за руховим конвертом, включно з вильотом і поверненням гарпуном. Попередній габарит ділянки 64 × 64 м, висота забудови 18 м.
- Чотири квартальні кути, два зустрічні проходи, читабельні бічні вулиці. Базова двобічна симетрія для руху, якорів і відновлення; винятки тільки в кольорах вітрин та NPC. У центрі головні об’єкти — бійці.
- Початкова пропозиція: **6 зачепів**, два нижчих на висоті 6 м і чотири на 9 м. Це не готові координати. T5/T2 мають побудувати карту досяжності для фактичної обмеженої довжини троса, прямої видимості, траєкторії розмаху й безпечного відпускання; високі недосяжні точки не ставити як інтерактивні.
- Зачіп — реальна поперечина на кронштейні/балконній рамі з видимим кріпленням. Малий контрастний керамічний обідок позначає взаємодію; решта труб і ліхтарів його не мають. Не заповнювати кожне вікно мішенню.
- Стіни мають товщину, цоколь і справжні відкоси; проходи прорізані, за ними видно глибину. Основний прохід пропонується 4 м завширшки, 4.5 м заввишки, з 6 м видимого продовження. Намальовані двері не видаються за доступний маршрут.
- Текстури: великі площини штукатурки з низькою частотою деталей, темні відкоси, небагато графітових стиків. Одна тінь в маджента-ліловий, сланець/теракота/бірюза за [[Style-Guide]]. Вода не дублює контраст фасадів; матеріал перевіряється з реальною камерою бою.
- NPC живуть на підвищеній задній галереї та в бокових заглибленнях поза максимальною досяжністю бойових дій. Галерея відокремлена зрозумілою архітектурою. Їх не додають у групи бійців, цілей, grapple_anchor чи damageable; у них немає hitbox/hurtbox, бойового AI й колізії з гравцями. Самої відсутності hurtbox замало: потрібен тест вибору цілі, гарпуна, AoE і камери.

## П’ять мешканців

Розміри — орієнтири для нормалізації майбутнього mesh, **PLACEHOLDER**. Руки порожні в базовому A-pose; гаджети окремими об’єктами. Взуття без брендів. Виразні плечі, таз і опорна нога; відмінність характеру не досягається постійним трясінням голови.

| ID / робоча назва | Силует, костюм і розмір | Пристрій та звичка | Рух / окремі кліпи |
|---|---|---|---|
| NPC01 — Листоноша | 1.74 м, вузький силует, асиметричний кремовий комір поверх короткої сланцевої куртки, широкі укорочені штани, великі коралові сучасні кросівки | Поясний латунний принтер-гармошка випускає коротку паперову пораду; людина вирівнює край паперу двома пальцями | Пружний короткий крок із переносом ваги; зупинка на двох ногах, погляд на папір, один кивок. `idle_read`, `walk`, `stop`, `paper_fold` |
| NPC02 — Налаштовувачка | 1.62 м, широкий трапецієподібний верх, теракотова накидка поверх робочого фартуха, вузькі штани, шавлієві кросівки | Наручний механічний калібратор і маленький рулон рекомендацій, без екрана | Стійка з широкою опорою; присідання з колінами вздовж стоп, огляд механізму; підйом через ноги. `idle_listen`, `walk`, `crouch_inspect`, `rise` |
| NPC03 — Архіваріус | 1.86 м, вертикальний силует, довгий розрізаний з боків сливовий жилет, короткі рукави, світлі масивні кросівки | Нагрудна коробочка з окремими паперовими картками та механічним сортувачем | Повільна впевнена хода з довшим кроком; при повороті спочатку погляд, потім грудна клітка, таз і переступ. `idle_sort`, `walk`, `turn_step`, `card_store` |
| NPC04 — Кур’єрка котушок | 1.70 м, діагональний силует ременя, коротке бірюзове пончо, м’які накладки колін, темні бігові кросівки з кремовими підошвами | Спинна котушка паперу з ручною подачею; коротка смужка на плечі, жодного довгого хвоста | Швидкий, але спокійний крок, гальмування двома кроками, зміна опорної ноги під час очікування. `idle_wait`, `brisk_walk`, `decelerate`, `check_spool` |
| NPC05 — Майстерка швів | 1.78 м, округлі рукави й вузький поділ незвичної хакі-туніки, знімні кишені, лілові технічні кросівки | Портативний перфоратор порад кріпиться на поясі; ШІ відповідає перфорацією короткої паперової стрічки | Неквапливий асиметричний жест, але симетрична здорова хода; на місці перенос ваги і перевірка шва обома руками. `idle_measure`, `walk`, `half_turn`, `tape_check` |

Це різні ритми та завдання, а не п’ять випадкових циклів. Утримувати контакт стопи протягом опорної фази; довжину кроку й швидкість переміщення калібрувати разом. Не масштабуємо clip довільно до будь-якої швидкості. Стрічки не перетинають руки й не симулюються як довгі канати. Обличчя і пальці — другий етап після силуету, стоп і плечей.

## Точні промпти для майбутніх референсів

Ці тексти — чернетки T6, ще не прогнані через недоступний тут `higgsfield-game-art`. Генерація не виконана; провайдер, версія моделі, ціна, ліцензія та затвердження зображення ще не визначені. Кожен запит = один ізольований персонаж, без предметів у руках. Окремий гаджет генерується окремим запитом після узгодження силуету. Для Meshy потрібен затверджений референс, не багатопозний лист.

Спільний префікс, який додається **дослівно** до кожного рядка нижче:

> Original adult background citizen for Cronshift. Full body, one single character, neutral A-pose, both empty hands visibly separated from torso, both shoes fully in frame, front three-quarter view, neutral eye-level orthographic-like lens, flat muted sage background #B8CBB1. Sketch-Cel design: expressive elongated limbs, large practical shoes, medium simple eyes, lively graphite-plum #2B2230 contours, flat restrained colors, one magenta-lilac shadow, matte cloth and brass. Clear construction, readable front and back separation, no dramatic foreshortening. No text, no logos, no weapons, no extra people, no collage, no cropped extremities, no glowing cyberpunk effects, no glossy skin. Clothing must read as an unfamiliar mixture of eras with contemporary unbranded sneakers.

| ID | Дослівне продовження |
|---|---|
| NPC01 | Slim paper courier, asymmetrical cream standing collar, short slate jacket, wide cropped trousers, coral technical running shoes with layered matte panels. Small closed brass accordion-printer dock at the belt, no loose paper during the reference pose. Calm alert face, narrow silhouette, one broad diagonal seam. |
| NPC02 | Compact maintenance specialist, terracotta trapezoid shoulder cape over a plain dark work apron, narrow trousers, sage contemporary sneakers. Small closed mechanical calibration cuff on left forearm, clearly separate from skin, no screen. Broad grounded shoulders, practical pinned-up hair, relaxed attentive face. |
| NPC03 | Tall archive keeper, long plum sleeveless vest with open side splits over short cream sleeves, straight charcoal trousers, oversized ivory running shoes. Small flat closed brass card-sorter attached high on the chest with visible cloth straps. Upright vertical silhouette, thoughtful expressive eyebrows. |
| NPC04 | Athletic spool courier, short muted teal poncho with a clear diagonal shoulder strap, cropped dark trousers, soft knee patches, charcoal running shoes with cream soles. Compact enclosed paper spool secured flat against upper back, nothing dangling. Energetic poised face, compact angular silhouette. |
| NPC05 | Seam technician, rounded full sleeves and narrow lower silhouette of a muted khaki tunic, detachable rectangular pockets, slate trousers, lilac technical sneakers. Small closed brass paper-perforator secured to right hip with a short strap, no loose tape. Soft deliberate posture and curious expressive face. |

Спільний промпт предмета + один опис з таблиці мешканців:

> One isolated original compact analog AI paper device, entire object in frame, neutral three-quarter orthographic-like product view on muted sage #B8CBB1, no character or hand, matte aged brass housing and dark slate mechanical fittings, visible mounting plate and paper exit, simple readable construction, restrained Sketch-Cel graphite-plum outlines and one lilac shadow. Separate solid housing from moving spool, no floating components, no text, no screen, no hologram, no logos, no scene. [Append the selected citizen device description.]

Гаджети нормалізувати під кріплення до корпуса, не вшивати в кисть. Місце виходу паперу має бути геометрично можливим. Відхилити референс, якщо ремінь зливається з рукою, підошва обрізана, немає опори пристрою або одяг закриває коліна так, що неможливо перевірити деформацію.

## Контракти виробництва і приймання

Початковий бюджет **PLACEHOLDER**: NPC LOD0 ≤ 12 тис. трикутників, LOD1 ≤ 4 тис.; 1 атлас 1024² на мешканця, ≤ 2 матеріалів на тіло, ≤ 65 кісток без пальців; усі п’ять ≤ 60 тис. трикутників LOD0. Гаджет ≤ 1.5 тис. трикутників, спільний атлас 1024². Квартал без бійців і VFX ≤ 250 тис. видимих трикутників, ≤ 64 MiB resident texture target. Це цілі прототипу, **не гарантія FPS на M3**. Після заміру видимості/CPU/GPU бюджети переглянути, особливо шкіру та прозорість.

Майбутні mesh: метри, опора між стопами на y=0 у Godot, іменовані кістки, окремі матеріали шкіри/одягу, нормалі без розривів на відкритих швах. Чотири ваги на вершину як початковий контракт. Не приймати авториг лише тому, що він завантажився: перевірити присід, опорну ногу, підйом руки, поворот таза і зачепи одягу. Папір — короткий окремий mesh без непотрібної фізики.

Пакет чернеток створено поза `game/assets`: `/workspace/nooneisreal-env/city-npcs/` — `room-brief.json`, `props.json`, `openings.json`, `milestone-reviews.json`, `final-report.json`. Це робочі локальні артефакти, не відтворюваний runtime-пакет у репозиторії; цей документ зберігає задум і параметри. Генерацій 0, витрат 0, нових файлів у `game/assets` 0.

Function gate **pending**: немає затверджених зображень, реального інженерного плану з геометрії, elevations, contact sheet прорізів та перевірки досяжності. Відкритий верх кварталу явно означає небо, а не забуту стелю; майбутні center-up/oblique кадри показують балкони й верхні кріплення. Form і Runtime теж pending. `validate_room.py` не запускався: переходу через gate і фінальної композиції немає. Успішний JSON parse не замінює жодного gate.

Наступний конкретний результат: T2 робить небойовий сірий layout і контрольні камери; T5 перевіряє довжину/видимість/приземлення гарпуна; T6 збирає окремі затверджувані reference images і silhouette sheet; T3 перевіряє джерела/ліцензії; T4 порівнює з виробничою камерою. NPC поки не заселяються в бій. Відповідно до Build 3D Game Rooms, затвердження конкретної розкладки й contact sheet потрібне перед фінальною композицією; запит на початок розробки не підміняє ці ще не створені докази.

## Related

- [[Style-Guide]] · [[Choko]] · [[Cronshift]] · [[04-Grapple-System]] · [[Pack-Review]] · [[Textures-Registry]] · [[Plans/2026-10-04-Free-Movement-Limbs]]
