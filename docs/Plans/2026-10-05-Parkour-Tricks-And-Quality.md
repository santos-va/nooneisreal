# Паркурні трюки та стабільна якість картинки

**Дата:** 2026-10-05 · **Роль:** T1 Дедал · **Статус:** `done` — обмежена хвиля для draft review; camera corner залишається відкритим
**Виріс з:** прямого доручення Santos новій сесії, [[2026-10-05-Parkour-Tricks-Session]], [[2026-10-05-Responsive-Parkour]], [[2026-10-03-Behaviour-Cloth-VFX-Shaders]].

## Що хоче Santos

Запустити нових агентів, продовжити заплановане, покращити фізику, додати види трюків і викрутків, шейдери та приємнішу оптимізовану картинку. Це прямий дозвіл реалізувати обмежену хвилю gameplay/presentation, не лише дослідити її.

## Аудит і погляди

| Джерело цієї сесії | Перевірений стан |
|---|---|
| `git status --short`, `git log -5 --oneline` | Чиста база `6c08328`, merge PR #180 з міським сюжетним епізодом. Нова гілка `codex/parkour-tricks-visual-quality`. |
| `docs/system/state.md`, Remaining-Work, Roadmap | Попередні паркур/обличчя/сюжет реалізовані; кінцевий рух, матеріали та graphics profiles лишаються відкритими напрямами. |
| T2 physics: `CityParkourMotor.gd`, `CityFighter.gd`, `CityParkourProfile.gd` | Є hang/mantle/wall_run, collision probes і finite Skea budget; немає wall kick/landing roll. Наявні jump/crouch достатні. |
| T2 motion: `ParkourMotion.gd`, UAL GLB animation names | У локальних джерелах є Roll і WallRun_Jump_L/R; новий paid asset не потрібен. Root/sole/gear треба виміряти. |
| T2 quality: `city_surface.gdshader`, `project.godot`, `ComfortPanel.gd` | Є шви/fwidth і fade, але wood/cloth phases потребують окремого derivative filtering. Default renderer Forward+, MSAA4; QualityProfile ще відсутній. |
| T4: існуючі parkour fixtures і мотор | Потрібні негативні controls jump release, repeated wall budget, obstacle/edge, lock/revision/rope, presentation authority. |
| `godot --version`, `ls /opt/godot` | Вбудований 4.6.3 не є потрібним 4.7; до authoritative acceptance слід отримати й звірити 4.7. |
| Сусіди | Локальний state і git перечитані. Початковий fetch не дістався proxy; повторний network fetch розпочато, remote CI ще не перевірений. |

Чинні [[ADR-004-Physics-Is-Presentation]], [[ADR-019-Audit-And-Many-Views-Before-Decision]], [[ADR-023-City-First-Exploration]] збережені. Нові трюки ізольовані містом; бойові числа, damage, hitboxes не змінюються. Числа нового руху та якості — PLACEHOLDER tuning.

| Варіант | Наслідки | Вибір |
|---|---|---|
| Лише нові кліпи/кольори | Малий ризик, але не додає фізичних дій або контролю вартості рендера | Відхилено |
| Повний фізичний контролер, vault/акробатика скрізь, cloth simulation | Потребує нової геометрії та великих змін collision/rig; непропорційний ризик | Відкладено |
| Два bounded city tricks + authored presentation + filtering/quality | Видимий і перевірюваний результат на наявному світі й input | Обрано |

| Погляд | Що враховано |
|---|---|
| Автор | Нові дії справді керовані, Sketch-Cel палітра залишається цілісною. |
| Новачок | Контекстні підказки й наявні jump/crouch; без додаткових клавіш. |
| Змагальний гравець | Roll без невразливості/bonus speed, wall kick без відновлення air budget; arena не змінюється. |
| Чутливий до руху | Без forced camera roll/нового shake; рух героя відокремлений від камери. |
| Слабкий GPU | Явний збережуваний quality preset, default зберігає чинну якість; жодних вигаданих FPS. |
| Мешканець/кіт на даху | Реальна стіна, опора й swept capsule; анімація не телепортує через світ. |
| Художник | Матова палітра, стабільні дрібні візерунки, огляд двох різних героїв зі спорядженням. |

Мірила: чесна фізична дія, читабельний силует, стабільність деталей у русі, нуль генераційних витрат і відтворювані тести.

**Оновлення бази:** повторний `git fetch origin` успішний. Перед production UI/runner правками гілку fast-forward оновлено до `abce638` (PR #181 Lower Mark та #182 reconciliation). Обидва епізоди збережені, стартова батарея тепер 85 сценаріїв. Official Godot 4.7 завантажено й SHA512 звірено; бінар `/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`, версія `4.7.stable.official.5b4e0cb0f`.

## Кроки

| # | Хто / файли | Робота й ризик | Перевірка → очікування |
|---|---|---|---|
| 1 | T2 physics: CityParkourMotor/Profile, CityFighter, city_parkour.tres | Wall kick один раз за повітряний цикл після release/jump; landing roll за crouch+напрямом після достатнього падіння, без boost. Ризик: повторний budget, collision/lock. | Нова city_tricks regression + existing city_parkour → 0 failures; `make check`, `make gates`. |
| 2 | T2 motion: ParkourMotion, authored hook sources/rig wiring лише за потреби | Authored пози двох трюків, metadata API із motor; physics authority збережена. Ризик: body/gear/sole penetration. | trick_motion check, parkour/gear regressions, native side/3⁄4 кадри обох героїв → немає blocker. |
| 3 | T2 quality: нові core QualityProfile/GraphicsSettings, project autoload, ComfortPanel, city_surface | Три профілі Low/Medium/High, High=current default; stable wood/cloth filtering. Ризик: зіпсований save, UI blur, unsupported renderer API. | graphics_check, city_style native, paired quality frames із реальними viewport параметрами; default незмінний. |
| 4 | T8 UI | CityHud/help/onboarding — опис реально доступних трюків, без зміни input map. | Наявні UI/input checks плюс нові snapshot cases. |
| 5 | T4 та T6 | Незалежне читання, негативні controls, художній native огляд. | docs/Audit та docs/Art із точними межами доказів. |
| 6 | T1 + T2 | Послідовна інтеграція, journal/state, reviewable branch | `make check`, `make gates`, `make check-playable` → завершені rc0 та відсутність unexpected errors. |

## Хендофи

П'ять агентів уже досліджують свої непересічні смуги; окремий T8 додає підказки. Production редагування лише власником. Godot запуски серіалізує T1. Native Linux є доказом картинки, не M3 FPS/feel. Публікація збірки, paid generation й merge не входять у цю хвилю.

## Підсумок передачі

Перевірений пакет передається до review: `make check`, `make gates` і
`make check-playable` завершені rc0, фінальна батарея — 93 сценарії / 0
провалів. Технічні докази й статус реалізації належать T2 Fix та T4 Audit;
цей `done` закриває обсяг плану, не оголошує повне художнє або апаратне
приймання. Камерна межа нижче лишається явним наступним завданням.

## Наступний обмежений напрям

Native production огляд виявив тісну station, де spring arm наближає камеру,
а proximity dither майже прибирає героя під час відскоку. Camera/proximity
source ця хвиля не змінює; причинну regression нового коду не встановлено.
Це окремий camera-readability case для наступного плану: порівняти hang,
звичайний відхід і kick на тих самих опорах, потім обрати корекцію за
видимістю героя, геометрії та відсутністю camera clipping. Не переносити
художнє приймання відкритих ракурсів на цей випадок. Vault та інші трюки
додаються після оцінки цих переходів і апаратного приймання, не автоматично
розширюють поточну інтеграцію.

## Related

- [[state]] · [[constitution]] · [[2026-10-05-Parkour-Tricks-Session]] · [[2026-10-05-Responsive-Parkour]] · [[2026-10-03-Behaviour-Cloth-VFX-Shaders]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]]
