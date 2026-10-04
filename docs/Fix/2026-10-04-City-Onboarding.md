# Навчання й окремий вхід у міський прототип

**Дата:** 2026-10-04 · **Виконавець:** T2·Місто-C Гефест · **Статус:** реалізовано; focused onboarding52/0 перевірено за журналом, повна батарея очікується.

## Звірка

Прочитано state/constitution/AGENTS/T2, чотири handoff сторінки й затверджений [[Plans/2026-10-04-City-First]]. MainMenu будується кодом; GameState раніше маршрутизував лише бій/меню. InputRouter уже має acquire/release UI owner з нейтраллю після утримання. Layout probe очікував10дій; новий окремий вхід дає11. Наявний незакомічений бойовий зріз збережено.

## Реалізація

- EXPLORE CITY · PROTOTYPE запускає окрему CityWorld.tscn з поточним P1. STAGES/ROTATION й конфіг бою не змінюються. Runtime смугиB володіє тимчасовим3D/SOLOконтекстом і його відновленням.
- CityOnboarding приймає лише фактичні move/look/jump/rope події від runtime. Кроки послідовні; натискання кнопки саме по собі не виконує завдання. Пороги3м/0.35радіан/одна подія є PLACEHOLDER навчання, не зміна балансу. Invalid/негативні/майбутні/paused події не завершують крок.
- CityHud має окремого власника паузи, resume/skip/restart/return, keyboard/gamepad focus, короткі контекстні підказки. Позначено exploration prototype, навички/зустрічі й майбутні місця бою/портали не активні. Текст вступу — Opening sketch, пропозиція T7, не затверджений сюжет.
- Прогрес живе лише в сесії; збережені налаштування користувача не переписуються. Exit/dispose звільняє input owner й паузу. У меню зменшено вертикальні проміжки, щоб нова кнопка вміщалась у900px логічного полотна.
- На запит T4 додано hook/dash запас і час відновлення через чинні сигнали Fighter; при0мотузок показано можливість reuse/restart. Help явно називає недоступні combat skills/ultimates/enemy hooks. HUD не мутує бойові дані.

## Перевірка

Предмет: для всіх tutorial observations і UI transitions: лише спостережена допустима дія просуває поточний крок; пауза/вихід не пропускають утриманий бойовий ввід.

`city_onboarding_check.gd` перевіряє три незалежні форми зламу: майбутні/невідомі події, invalid/nonfinite observations, paused observations; додатково actual Escape/resume/skip/restart/dispose, нейтраль утриманих jump/dash/hand/parkour і межі контролів у3viewport. `layout_check.gd` перевіряє всі11дій меню та явний prototype label. City runtime/geometry тести додаються до serial playable runner. Godot запускає тільки координатор; до читання його журналів результати не оголошуються зеленими.

T2·C власноруч прочитав `/workspace/nooneisreal-env/city-first/onboarding.log`: `CITY_ONBOARDING_COMPLETE checks=52 failures=0`, чистий runtime output. Додатково перевірено реальний сигнал кнопки меню→CityWorld з обраним Skea→кнопка return, відновлення plane/shared/fountain/night/training/P2config та повідомлення finite resources. Перший stalled запуск через eager autoload-dependent class references у harness виправлено delayed load; він не є доказом проходження. Full check/gates, native screenshot і M3приймання ще не оголошені завершеними.

T2·C оглянув native `production_pause.png` і `production_player_camera.png` у `city-first/captures`: критичні кнопки й поточний HUD у межах viewport, герой видимий у міському3Dпросторі. Після цього за actual runtime висновком смугиB/T4 підказку уточнено: ближче під зачепом мотузка піднімає, дальня лінія спершу тягне до опори; відпустити і parkour, і jump для відчеплення. Текст більше не обіцяє вертикальне підняття з будь-якого кута. Повторний fit probe після цього тексту підтверджено нижче.

Фінальні focused журнали прочитано власноруч: `onboarding-final.log`52/0 після уточнення тексту, `gates-final.log`68GDS/0 і БАТАРЕЯ ЗЕЛЕНА. `playable-verified.log` спершу відхилив citygeometry1112/0 через додатковий `meshes=221` у sentinel: runner очікував коротший exact line. Виправлено контракт regex із обов'язковим `meshes=[1-9][0-9]*`, збережено whole-line перевірку й failures0; shell syntax/whitespace чисті. Повторний strict runner очікується, попередній43/1 не оголошується зеленим.

## Related

- [[Plans/2026-10-04-City-First]] · [[World/2026-10-04-City-First]] · [[Handoff/2026-10-04-Remaining-Work]] · [[Fix/2026-10-04-Comfort-Input]]
