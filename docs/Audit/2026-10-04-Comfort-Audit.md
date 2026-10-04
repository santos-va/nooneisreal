# Комфорт звуку, зображення й керування — аудит T4

2026-10-04. Наступний зріз після PR #164 за дорученням T1 після Santos «гра яка не мозолить вуха, очі, керування». T4 володіє цим аудитом; ігровий код, state та GDD не змінює. Godot запускає послідовно T1: прочитані логи відрізняються від власного запуску аудитора. Авторська проводка нових сценаріїв runner буде позначена окремо.

## Вердикт

**YELLOW загалом; GREEN для перевірених контрактів цього технічного зрізу, без відкритого блокера рев’ю.** Збереження, UI/input isolation, нульова тряска, вузька читабельність і регресії підтверджені нижче. Комфорт тембру на слух, довга сесія, фізичний геймпад і FPS M3 залишаються неперевіреними. Під час роботи PR #164 увійшов у main; `git branch --show-current` → `codex/comfort-settings-input`, `git log -1 origin/main` → `aa65f10 Merge pull request #164`. Цей новий diff проходить окреме рев’ю. Початковий стан: Прочитано AGENTS, state, constitution, T4 та попередній [[Audit/2026-10-04-Camera-Foot-Contact]]. Команди `cat`, `rg`, `git status --short`, `git diff --stat`: на початку дерево чисте; існуючий runner містить 13 сценаріїв. Попередній аудит зафіксував обрізаний footer у native1152×648. Налаштувань комфортної гучності/тряски у базі немає. CI попереднього зрізу не доводить цей diff.

## Контракти приймання

| предмет | перевірка | ризик / межа |
|---|---|---|
| Збереження | ізольований test config; roundtrip; невідомі секції/ключі збережені; пошкоджений файл не перезаписаний | тести не повинні змінювати `user://` гравця |
| Дані | clamp 0..1, NaN/Inf і нечислові значення відкинуті; відсутні ключі мають default | гучність і shake не можуть отримати невалідне число |
| Аудіо | справжні Master/SFX/Music, нуль mute, наявні send/effects не стерті | числовий gain не доводить приємність звуку на слух |
| Камера | live shake preference в обох камерах, zero без імпульсу; gameplay state/RNG незмінні | зменшення shake не замінює доступність інших спалахів |
| Пауза | Esc/Start один раз; видимий focus; keyboard і virtual gamepad дістаються slider, reset, resume | тест тільки через прямий виклик callback не доводить input |
| Footer | native1152×648 та844×390: фізичний font floor, перенос і відсутність обрізання | логічні bounds1600×900 не доводять фізичну читабельність |
| Regression | make check-playable + gates, строгі sentinel/error guards; негативні контроли | quit-after rc0 не PASS; cloud не вимірює M3 FPS |

## Проміжний огляд реалізації

**GREEN вузько, сервіс налаштувань.** Прочитано `ComfortSettings.gd`, `comfort_check.gd` та `/workspace/nooneisreal-env/comfort/logs/settings.log`: `COMFORT_CHECK_COMPLETE checks=28 failures=0`, без ERROR/WARNING. Це запуск T1, не T4. PID-файл призначається перед `_ready`, справжній comfort.cfg не записується. Невідомі ключі/секції переживають save, пошкоджений файл не перезаписується. Навмисна синтаксична помилка ConfigFile приглушена лише навколо цього load, прапорець Engine відновлено перед assertion; production помилки не ховаються. Autoload після Sfx/UltMusic зберігає наявні SFX effects/send, додає один іменований Master HardLimiter. Перевірено структуру й параметри ланцюга, не почутий звук і не реальний peak виходу.

**YELLOW, знайдені UI/test ризики закриті кодом, очікують engine повтору.** Початкове створення прихованої панелі могло округлити preferences кроком slider, а SmokeTest close записував реальний comfort.cfg. T4 передав власнику; фінальний прочитаний варіант має `_syncing=true` під час побудови, окремий PID storage_path у smoke, видалення лише тестового файла й повернення початкового шляху. Довідка тепер фокусована й має обробку scroll клавіатурою/падом; footer32 логічних px перевіряється через масштаби цільових вікон, а не лише canvas bounds. Native кадри ще не прийняті.

**YELLOW, реальні регресії ще відкриті.** Початковий `input.log`:19 checks/1 failure — UI tap, відпущений до resume, відтворювався через Godot just_pressed на physics tick. Власник додав окрему `_ui_consumed` fence, що знімається лише новою device подією; assertion не видалено. Початковий `ui.log`:3 failures — досяжність кінця довідки, повторне відкриття падом і другий Escape resume. Це корисні спіймані проблеми, не PASS; потрібні повтори після виправлень.

## Підтверджений повтор та native огляд

**GREEN, input і UI після діагностики.** Прочитано повторні `input.log`:31/0 і `ui.log`:COMFORT_UI PASS(0), без ERROR/WARNING. Додані UI-only gamepad bindings виявили реальну відсутність A/B/D-pad у builtin action map; кожна додається ідемпотентно, бойові p1/p2 події не змінені. Окремий held-neutral та stale-just-pressed guard усувають відтворення меню-натискання після resume. Hud отримав можливість обробляти resume, коли Arena правильно paused. UI сценарій перевіряє keyboard slider, Tab до довідки, D-pad до її кінця, A/B відкриття/закриття, дві послідовні Escape дії; обидві camera controllers показують ненульовий active impulse при1 і нуль при0. Реальний фізичний геймпад на Mac цим не перевірений.

**GREEN вузько, візуальна читабельність нової панелі/підказки.** T4 відкрив через view_image native `render/laptop/menu.png`, `pause.png`, виправлений `menu-comfort.png`, `render/small/menu.png`, `menu-comfort.png`, `render/classic/menu-comfort.png`:1152×648,844×390,1024×768. Чотири підписи/значення, MASTER і BACK видно; compact footer не обрізаний праворуч. Початковий MASTER ховався від follow-focus; цей кадр відхилено, повтор показує його. Мінімальний32 logical font дає13.87 physical px на844×390 — явна локальна ціль, не універсальна норма доступності. Старі десять рядків головного меню на844 усе ще дрібні; повний мобільний UX не прийнятий. Renderer Mesa llvmpipe; FPS/Retina M3 не виміряні.

**YELLOW до виправленої довідки.** T4 виявив у новому `controls-bottom.png` хибне `Crouch: Menu`: реальна binding12 — D-pad Down, formatter пропустив назву й повертав Menu за замовчуванням. Передано T2; необхідні виправлений mapping, assertion і повтор кадру. Це помилка інструкції, а не зміна бойового binding.

## Авторська проводка runner

За дорученням T1 T4 додав settings/input/UI та три негативні мутації footer/focus/bounds до `playable_check.sh` — разом19 сценаріїв. Це авторська tooling зміна, не незалежний аудит власного коду. Runtime/SCRIPT ERROR далі блокують PASS. Лише навмисні negative cases допускають власний точний assertion prefix `UI_LAYOUT:` або `COMFORT_UI:`; довільна engine помилка не проходить. `bash -n`, `git diff --check`: rc0. Окремий fake-executable selfcheck (без Godot):19 правильних sentinel → rc0; пропущений comfort sentinel → rc1; indented ERROR після success → rc1. Повний engine запуск ще очікується.

## Кінцеве приймання

**GREEN, негативні контроли та повний запуск.** T4 прочитав `/workspace/nooneisreal-env/comfort/logs/check-playable.log`: smoke ALL OK164/19944 frames, PLAYABLE CHECK19/0. У всіх13 позитивних regression logs пошук ERROR/WARNING порожній. Кожна нова UI mutation завершується rc1 і трьома потрібними assertion: footer — фізичний font floor; focus — focusable/Tab/help end; bounds — три canvas sizes. Старі три UI mutations також PASS як очікувані відмови. `logs/gates.log`: БАТАРЕЯ ЗЕЛЕНА,50 gd/0 parse failures. Власні команди T4: читання логів/пошук діагностик, `bash -n`, `git diff --check`, wikilinks4201/0 broken; engine запуски виконані T1 централізовано. Після повної батареї лише текст помилки save збільшено до32 logical px; наступні native import/gates пройшли, повний smoke для одного шрифту не повторювався.

**GREEN, правильна довідка й завершені native captures.** `_pad_label` тепер називає всі D-pad directions, Menu/Back лише для їхніх binding, невідомий button показує номер; новий assertion вимагає `Crouch: D-pad Down`. T4 повторно відкрив виправлений1152 `controls-bottom.png`: напис правильний, останній рядок досяжний, BACK видимий. Додатково відкрито844 `pause-comfort.png`: labels/slider values/BACK у межах. Три фінальні render logs мають COMFORT_CAPTURE_COMPLETE для1152×648,844×390,1024×768, без ERROR/leaks; лише очікуваний software-driver V-Sync warning. Попередні несправні кадри й прогони не зараховані.

**YELLOW, межі обіцянок.** Не було прослуховування, запису фактичного master peak, перевірки на фізичному M3/Retina/геймпаді або тривалого playtest. Master limiter і нижчі defaults не доводять комфорт усіх тембрів чи клінічну безпеку. Усі старі рядки меню на844 не збільшені; це не повний мобільний UX. Нові preference не вимикають усі світлові спалахи й VFX. За цих явних меж технічний diff придатний до рев’ю.

## Related

- [[Audit/2026-10-04-Camera-Foot-Contact]] · [[2026-10-04-Playable-Slice]] · [[constitution]] · [[recurring_class_register]] · [[06-UI-UX]] · [[07-Audio]]
