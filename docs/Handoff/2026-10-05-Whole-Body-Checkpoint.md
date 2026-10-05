# Checkpoint: цілісний рух, опора та фізичні сигнали

2026-10-05 · координатор T1 · гілка `codex/living-district-characters` · кандидат **0.5.0**, продовження відкритого [PR #178](https://github.com/santos-va/nooneisreal/pull/178). База цієї хвилі `3df43a5`. План [[2026-10-05-Whole-Body-Motion]], журнал [[2026-10-05-Whole-Body-Session]]. Попередній [[2026-10-05-Living-District-Checkpoint]] описує збережені NPC/rope/UI зміни; ця хвиля відповідає новому пріоритету Santos — ноги, голова й анатомія всього тіла.

## Що змінилося

- Таз, хребет, шия й голова узгоджені під час повороту, розгону, гальмування та переходів між стійками. Погляд калібрований за реальною віссю обличчя кожного героя; авторська дуга удару більше не затискається на однаковому куті — [[2026-10-05-Whole-Body-Presentation]].
- На мотузці нижня частина тіла реагує на опору й швидкість: ноги звисають під тазом, грудна клітка компенсує навантаження, кисті зберігають контакт. Наземна підготовка кидка продовжує крок, поки герой фізично гальмує.
- Опора враховує повний skin підошви, реальну підлогу, рампу, дах або WaveField. Справжні контактні фази взято з наявних CC0 UAL; стопа не приклеюється в toe-off або повітрі. Standing удари й реакції мають лише корекцію проникнення вгору, без примусового опускання ударної ноги — [[2026-10-05-Hero-Ground-Contact]].
- Крок відповідає фактичному переміщенню вздовж поверхні. Restart/rewind скидають історію, тому телепорт не стає помилковою швидкістю анімації. Бойові кадри, hitboxes, рух тіла та RNG збережені — [[2026-10-05-Physics-Motion-Signals]].

## Докази й межі

Незалежний [[2026-10-05-Whole-Body-Anatomy-Review]] містить незмінні критерії до/після, повний skinning, actual input, lowhand/combat/reactions і terrain. Native [[2026-10-05-Whole-Body-Visual-Audit]] показує обох героїв спереду й збоку, цілий перехід, а не один вдало вибраний кадр. Бойові та міські сценарії мають власні чесно зазначені межі.

Відео порівняння: `/workspace/nooneisreal-evidence/whole-body/after/whole-body-before-after-33s.mp4` — **33 секунди, 1980 кадрів, 60 fps**, before/after поруч, без інтерполяції. Компактні зображення збережені в `docs/assets/screenshots/2026-10-05-whole-body/`; raw probes, logs і довгі послідовності — `/workspace/nooneisreal-evidence/whole-body/`.

[[2026-10-05-Whole-Body-Retarget-Research]] містить джерела Godot/UAL, вимірювання й дві оптимізації точної математики без відкидання vertices. У тихому парному CPU probe найбільший presentation p95 — **7,586 мс на двох героїв** для water idle. Це не повний кадр і не FPS на M3. Початковий орієнтир 1,5–2 мс на одного героя на воді не досягнутий; залишкова вартість не приховується.

## Приймання й доставка

Production commit **`d27b60821f264c0b407ad844e128ede299d698f5`**. Подальший checkpoint commit містить лише документацію й native зображення. PR мерджить Santos; встановлений macOS застосунок оновлює чинний канал main після успішної публікації, а не локальний source checkout.

Root прочитав smoke **164 перевірки / 19847 кадрів** та фінальний runner **73 сценарії / 0 помилок**. Нові whole-body / ground-contact / physics-motion: **12686 / 5407 / 1149**, усі без failures. Перший aggregate із shutdown-витоком actual rewind audio нового fixture не прийнято. Після cleanup-only ремонту повторено всі 73 сценарії; strict raw logs чисті. `make gates`: **102 GDS / 0**, усі гейти зелені; native camera **4/0**, HTTP mock **34+17/0**, distribution **25/0**. Журнали — `whole-body/validation/`; це не real-model inference або Mac-встановлення.

Свіжий `git archive` точного production commit, окремий import/export Godot 4.7 та staging-only build marker дали PCK **208716528 B**, SHA256 **`5176551e558d197412fbf6800671952aca92f3a8ad9eb6a4c7f64249909f259a`**. Від попереднього PCK `2a72f9d` це +33508 B, не обіцянка розміру macOS updater delta. Імпорт та експорт завершені без engine/script/shader errors.

Native `--main-pack` із порожньої verifier-директорії: **86/0**, packed version **0.5.0**, revision точно **`d27b608…`**. Додатково до NPC/JSON/shader/default-OFF guards перевірено всі три нові motion helpers, упаковані contact profiles та actual support/gaze обох героїв. Checkout не міг підмінити відсутні packed resources. Metadata, SHA й screenshot: `/workspace/nooneisreal-evidence/district-close/pck-d27b608/`.

Фінальний CI після push checkpoint визначається актуальним head [PR #178](https://github.com/santos-va/nooneisreal/pull/178). Цей датований документ не переносить старий CI з `3df43a5` на новий код. Перед готовністю до merge координатор перевіряє всі jobs саме фінального head. Публікації release й merge агент не виконує.

## Продовження

Не починати новий retarget з нуля: порядок шарів і frozen source-contact metadata вже мають регресії. Наступні зауваження відтворювати з конкретним героєм, дією та build SHA; перевіряти всю позу й реальну поверхню. Подальша оптимізація водної опори потребує такого самого full-skin parity guard.

Ця хвиля не є твердженням про завершення всієї гри. Реальне приймання нового зрізу на M3, апаратний FPS/звук і комфорт керування залишаються окремими. Іконка чекає саме оригінального PNG. Онлайн, повний сюжет восьми героїв, model inference, mod SDK та комерційна ліцензія зберігають межі попереднього checkpoint.

## Related

- [[2026-10-05-Whole-Body-Motion]] · [[2026-10-05-Whole-Body-Session]] · [[2026-10-05-Whole-Body-Anatomy-Review]] · [[2026-10-05-Whole-Body-Visual-Audit]] · [[2026-10-05-Whole-Body-Retarget-Research]] · [[2026-10-05-Living-District-Checkpoint]] · [[Build-and-Run]] · [[state]]
