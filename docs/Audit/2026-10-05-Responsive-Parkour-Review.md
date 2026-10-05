# Аудит чуйної мотузки й міського паркуру

**Дата:** 2026-10-05 · **Роль:** T4 Феміда · **Вердикт: GREEN у перевіреному обсязі.** Фінальні check/gates та строгий playable пройшли на тому самому source. Апаратні й художні межі наведені нижче.

## Межі та база

Незалежний read-only огляд gameplay; T4 змінює лише цей аудит. `git rev-parse HEAD origin/main` після відновлення мережі особисто підтвердив обидва `fe37869f7232194084f33cee4b1bf9162ab06965`. Початковий `git log main..HEAD` не виконався, бо локального `main` немає; чинний еквівалент `git log origin/main..HEAD` порожній. `git diff --stat origin/main -- game/assets docs/Art/Textures-Registry.md` порожній: paid/generated assets ця хвиля не додає.

`Godot --version` з XDG-оточенням: **4.7.stable.official.5b4e0cb0f**. Фінальний T4 запуск використовує `/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`, `XDG_DATA_HOME=/tmp/nir-review-data`, `XDG_CACHE_HOME=/tmp/nir-review-cache`, `XDG_CONFIG_HOME=/tmp/nir-review-config`. Ранні 4.6 і sandbox-failed import logs не є фінальним прийманням.

## Вердикти

- **GREEN — план R8.** Особисто прочитаний план містить три альтернативи, сім поглядів і критерії ізоляції міста, collision та скінченного повітряного бюджету.
- **GREEN — scope і контракти.** Прочитано фактичні diff `GrappleHook`, `CityFighter`, motor/profile, `ParkourMotion`, `SkeletalRig`, `SwordPresentation`, `CityArchitecture`, HUD і guards. Швидкий профіль має явний city opt-in та parkour action; finite inventory, 0,70 м hand reach, bounded reel і release без доданої енергії збережені. Нових duel станів/frame data немає. Нові фасадні colliders відповідають розміру та basis видимих виступів.
- **GREEN — незалежний make check.** Особистий `GODOT_BIN=… make check`: rc 0, **109 GDS / 0 parse failures**, smoke **164 checks / 19 847 frames**, `SMOKE ЗЕЛЕНИЙ`; raw log без `SCRIPT ERROR`, `ERROR:` або попереджень Jolt. Це запуск T4, а не переказ звіту власника.
- **GREEN — незалежний негативний контроль.** Тимчасовий підклас `/tmp/nir-t4-support-bypass.gd` змінює тільки `_support_valid()` на `true`; копія кінцевого 73-check fixture підключає його до обох героїв. Вихід **rc 1, 73 checks / 4 failures**: disabled support та moved support для Choko і Skea. Жодних сторонніх parse/runtime errors. Production і tracked tests не мутувалися. Контроль доводить, що конкретна втрата перевірки опори помітна регресії.
- **GREEN — незалежні gates.** Особистий `make gates`: rc 0, `БАТАРЕЯ ЗЕЛЕНА`; **175 / 175 assets**, **0 broken links**, **109 GDS / 0 parse failures**. Вісім наявних попереджень про неоднозначні wiki basename явно залишені в raw log; їх не названо новими помилками.
- **GREEN — остаточна інтеграція.** Координатор виконав строгий runner; T4 незалежно прочитав `playable-final.log`, rc-файл та всі **79** шляхів raw logs: **79 сценаріїв / 0 failures, rc 0**. Немає `SCRIPT ERROR`, `WARNING:` або неочікуваних `ERROR:`; навмисні негативні сценарії мають очікуваний rc 1 і прийняті runner. Ключові підсумки: legacy gear **7 930 / 0**, dense city hook **2 978 / 0** на **276** реальних позах, city parkour **73 / 0**, parkour motion **15 466 / 0**. `playable-final-source.json` повністю тотожний особистому `review-source-after.json` для всіх **764** файлів.

Перший aggregate збережено як відхилений: **78 / 2 failures**. `hero-gear` мав **7 930 / 1** із pin margin **−2,880092 мм** (`skea/low/60`); `city-parkour` мав 73 / 0, але **14 ObjectDB instances / 4 resources** у teardown. Виправлення не послаблювали acceptance: фінальний dense city raw має pin margin **1,513033–3,192836 мм**, runtime errors 0; попередні GREEN не переносилися на новий source без повтору.

## Знайдені дефекти й виправлення

1. Первісний `_support_valid()` перевіряв лише node/transform: вимкнений collider залишав хибний хват. Тепер на кожному active tick повторно перевіряються справжні grip-top/wall rays. Негативний контроль вище незалежно відтворив саме цю регресію.
2. Первісний `valid_snapshot()` робив `float(progress)` до type guard, а metadata довіряв як Dictionary. У кінцевому коді є container, numeric, finite та vector guards; wrong-type випадки додані до motion regression.
3. Первісний animation fixture не відповідав motor-геометрії та не пересував root під час mantle. Кінцевий fixture використовує live-profile forward 0,43 м / height 1,42 м / half-width 0,24 м, справжню двосегментну траєкторію й другу орієнтацію. Замір реальних коротких рук спричинив виправлення hang-висоти; ліміт visual hip correction 0,15 м не зсуває physics body.
4. Native огляд інших смуг виявив відсутні colliders фасадних виступів і shoe-width penetration, яку не бачить ankle ray. Кінцевий код використовує справжній shoe skin footprint, дев’ять surface probes, post-IK guards і кеш повторних render callbacks. Повний playable має перевірити сусідні city маршрути після додавання collider.
5. Drawn sword міг переписувати support-arm IK. Кінцевий `SwordPresentation` вважає parkour hands busy; `SkeletalRig` не застосовує sword arm transfer у support phase. Gameplay sword ownership не передано анімації; повторні bone-pose guards збережені.
6. Dense city перевірка підтвердила, що forearm може заходити на chest pin під час швидкого catch/reel. Кінцеве виправлення зберігає classic 0,20 с / повний reel stroke, а city 0,12 с / 0,65 м; після catch фізичний load керує torso, supported arm IK виходить із rest plane зі справжньою ціллю на rope та authored wrist orientation. Спекулятивний elbow search і caches повністю видалені. Числа pin/shape oracle не послаблені; новий `city-hook-gear` зареєстрований у строгому runner. Fixture teardown використовує звичайний queue_free та 250 мс реального audio drain, без suppress/skip.

## Докази й відтворення

Каталог: `/workspace/nooneisreal-evidence/responsive-parkour/validation/`:

- `review-check.log`, `review-check.rc` — особистий make check.
- `review-gates.log`, `review-gates.rc` — особисті фінальні gates.
- `playable-final.log`, `playable-final.rc`, `playable-final/` — завершений координатором runner; усі 79 raw logs незалежно прочитані T4. `playable-final-source.json` підтверджує ті самі bytes.
- `review-negative.log`, `review-negative.rc` — очікувано червоний support bypass.
- `review-source-before.json` — SHA256 кожного з **764** game/tools файлів; aggregate **ff65c07d15eae5b17b236c29ff981577de44edf6b6d110e36488cf4574f1e444**. `review-source-after.json` після check/gates **byte-identical** до before для всіх 764 файлів; aggregate тотожний.

Окремо T4 особисто відкрив `final47/skea_wall_run-sheet.jpg`, `choko-transition.jpg` і `choko_hook_reel-sheet.jpg` у `/workspace/nooneisreal-evidence/parkour/visual/`: читаються catch/mantle/вихід на уступ, стінні кроки з завершенням та flight/reel/release. Це вибірковий огляд попереднього до shoe-width delta набору, не доказ кожного фінального кадру. Після останньої hook-корекції T4 також особисто відкрив `visual/hooks-final47/skea_low_hook/contact-sheet.jpg`: видно catch/reel/settled low-rope пози без колишнього forearm crossing; точний clearance доводить dense oracle, а не зображення. Кінцевий native/actual shoe proof належить [[2026-10-05-Parkour-Visual-Audit]].

## Межі приймання

Headless Godot 4.7 не доводить FPS на M3, Retina, фізичний геймпад, звук, оновлення встановленого macOS застосунку чи публікацію пакета. Додаткові facade colliders і shoe sampling потребують окремого апаратного performance-виміру; чисел FPS тут немає. Немає заяви про весь parkour у довільних майбутніх рівнях: перевіряються поточний квартал, негативні fixtures та визначені маршрути. Художні motion/tuning числа залишаються PLACEHOLDER до ігрового приймання.

## Related

- [[2026-10-05-Responsive-Parkour]] · [[2026-10-05-Responsive-Parkour-Session]] · [[2026-10-05-Parkour-Visual-Audit]] · [[constitution]] · [[recurring_class_register]]
