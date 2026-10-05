# Цілісний скелет — продовження після живого кварталу

2026-10-05 · координатор T1 Дедал. Santos пріоритезував анімації та фізику: ноги втрачають правильну опору, голова лишається рівною, потрібен рух усієї анатомії.

## CP0 — аудит перед змінами

GitHub API підтвердив відкритий незмерджений [PR #178](https://github.com/santos-va/nooneisreal/pull/178), head `3df43a520e494c809905854efff44ffe7de4341f`. Робоче дерево було чистим. Продовжуємо цю гілку; не стверджуємо, який SHA встановлено у Santos. Попереднє технічне приймання не закриває нове візуальне зауваження.

Шість агентів відновлені: T2 combat — цілісний retarget/layers, T2 npc — опора стоп, T2 rope — physics-сигнали; T6 art — native baseline, T3 — доступні джерела й engine API, T4 — незалежні метрики/приймання. Production чекає конкретного контракту [[2026-10-05-Whole-Body-Motion]]. Ізоляти й докази лишаються у `/workspace`, бо `/tmp` має мало місця.

R8: порівнюються локальні процедурні латки, новий framework та узгоджений bounded presentation поверх чинних UAL; план описує сім поглядів. Доручення Santos дозволяє поведінкові виправлення; додаткового дозволу для них не потрібно. Бойові числа/ліцензії/публікація не змінюються. Іконка чекає саме нового PNG.

## CP1 — підтверджена причина нерухомої голови

T1 прочитав runtime head-аудит combat: у Jab обмежувач тримає голову рівно на −20° протягом усіх 17/15 кадрів Choko/Skea, хоча початкова дуга змінюється. Source-аудит підтвердив відсутність звичайної ground-contact корекції та city-surface sampling у чинному вузькому helper. План переведено в approved: калібрований погляд, окремий bounded helper опори та виправлення виміряних gait-сигналів. Native/sole baseline і уточнення windup тривають; production дозволений в описаній власності. Траси помилково підписаних hammer/lowhand відхилені як докази.

## Виміряний baseline

T1 прочитав `whole-body/physics-motion-audit.json`: grounded WINDUP лишає gait inactive попри рух; сума переміщень Choko 0,476667 м / 11 кадрів, Skea 0,59 м / 12 кадрів. City restart на 10 м породжує хибні 600 м/с в animation speed; на EastRamp враховується лише XZ, приблизно на 2,38% менше пройденого вздовж поверхні. Дані є сигналом для presentation-виправлень; дефект solver-фізики цим не доведений.

У `hero-anatomy/feet-before/metrics.json` source-defined stance та повний skinning підошов дають forwardWalk drift 6,35/6,09 см; lateralWalk — приблизно 35/32 см. T1 відкрив actual native Choko front frame120: під час Jog обличчя нахилене до землі. Ці докази визначають цілі поточної хвилі. Кадри та JSON лишаються у `/workspace/nooneisreal-evidence/`; у репозиторій потрапляють стислий доказ і відтворювані перевірки.

## CP2 — перший інтегрований сигнал руху

Прочитано raw `whole-body/physics-motion-integrated.log`: **1121/0**, без runtime помилок. Це кандидат у власному ізоляті rope зі snapshot спільної інтеграції, ще не фінальний freeze. Три source-mutation контроли окремо відхиляють повернення старого restart, XZ-відстані та WINDUP idle; загальна фізика не змінена.

Дослідження [[2026-10-05-Whole-Body-Retarget-Research]] перевірило чинні джерела й Godot4.7; нових бібліотек чи assets не потрібно. Engine-only probe показав, що `skeleton_updated` не є універсальним physics clock. Окремий actual-Fighter baseline при30/60/120FPS дав нуль розбіжностей пози та жодного повторного callback на physics tick (`fps-before/comparison.json`); потенційний ризик API не видаємо за доведений баг старої гри. Новий шар повинен зберегти цю рівність.

T4 уточнив метрику опори: ранній sole<4см classifier помилково включав toe-off. За замороженими raw-source ball-contact вікнами steady forwardJog уже переважно має1,9–3см drift; справжні дефекти лишаються при старті9–11см, поворотіChoko26,66см і penetration. Приймання не приклеює правильний перекат черевика до підлоги. Докладно [[2026-10-05-Whole-Body-Anatomy-Review]].

## CP3 — анатомічний кандидат та вартість

T4 другим незалежним actual-input прогоном прийняв54/0 fixed anatomy assertions проти31failures на baseline; native та повна стара батарея ще очікуються. Перший кандидат мав5failures; пороги не послаблювали. Нова перевірка руху тіла пройшла11360/0 у власника. Foot/helper та physics тести зареєстровані разом із попередніми70 в runner73.

Ранній T3 timing виявив істотне зростання CPU у повному skinning опорних підошов. До freeze додано CP4 плану: дві bounded exact-math оптимізації зі збереженням independent full-vertex truth, окреме вимірювання solid/WaveField. Художня правильність не виправдовує приховану регресію вартості.

## CP4 — бойова опора й завершення оптимізації

Незалежний T4 розширив audit із ходи на actual grounded combat/reactions і знайшов старе проникнення взуття35–61мм. Прийнято CP5 плану: один upward-only support rule для standing attack/blockstun/hitstun/stumble, без зміни swing/air/ragdoll. Кількісний GREEN нейтральної ходи не був прийнятий за завершення всіх потрібних дій.

Дві CP4 ітерації зберігають усі skin vertices: лінійна проєкція для площини й кешовані коефіцієнти нелінійних хвиль. Першу версію другої ітерації відхилив equality guard: імпортовані weights не складаються точно в1, тому origin не можна без поправки розподілити між influences. Виправлена математика проходить direct full-skinning/WaveField parity, включно з піднятою поверхнею,2D/3D та swell. Залишкова CPU-ціна води документується; timing перевірка не є M3/FPS-прийманням.

## CP5 — фінальна перевірка й виправлення fixture

Фінальні production hashes зафіксовані в незалежному аудиті. T4 повторив actual-input, standing combat/reactions, lowhand, elevated/sloped CityFighter та natural30/60/120FPS; геометричні критерії пройдено, authority не змінена. T6 завершив matched locomotion1800, hook720 і actual city450 native кадрів; компактне before/after відео має33с/1980кадрів при60fps.

Root `make check-playable` дав smoke164/19847 та72/73сценаріїв: єдина відмова — cleanup нового physics-motion fixture після actual rewind audio, попри1149/0 assertions. Strict runner правильно відхилив6leaked objects/2resources. T2 відтворив це з `--fixed-fps60 --verbose` і виправив лише завершення тесту за чинним audio pattern: штатне звільнення та200мс wall-time mixer drain. Production і runner не змінено. Повний runner73 повторено: **73 сценарії / 0 помилок**, усі raw logs без engine/script/shader errors та leaked resources. Whole-body12686/0, ground-contact5407/0, physics-motion1149/0; попередній smoke164/19847 лишився чинним, бо production не змінено. Перший невдалий журнал збережено.

Root окремо прочитав зелені `make gates` (102GDS/0), native renderer4/0, HTTP mock34+17/0 та distribution25/0. Парний presentation CPU probe T3 на600кадрах має найбільший p95 у water idle7.586мс на двох героїв; це не full-frame FPS і не M3. Provisional per-hero water budget1.5–2мс не досягнуто, залишкова ціна явно прийнята після парного заміру; третьої прихованої оптимізації чи vertex decimation немає.

## CP6 — точний пакет і передача

Production зафіксовано як `d27b60821f264c0b407ad844e128ede299d698f5` після незалежного code/native acceptance. Root звірив усі28production entries native manifest зі shared checkout: hashes однакові. Свіжий exact-commit PCK з порожньої verifier-директорії пройшов86/0, version0.5.0 та revision збіглися; packed helpers/contact metadata справді виконуються на обох героях. Розмір208716528B, SHA256 `5176551e558d197412fbf6800671952aca92f3a8ad9eb6a4c7f64249909f259a`; strict import/export/native logs чисті.

Подальша передача й відтворення — [[2026-10-05-Whole-Body-Checkpoint]]. PR#178 отримує цей зріз, фінальний CI перевіряється на його актуальному head після checkpoint push. Merge й release лишаються за чинним процесом Santos; Linux-перевірка не стверджує автоматичне оновлення вже встановленої гри на M3.

## Related

- [[2026-10-05-Whole-Body-Motion]] · [[2026-10-05-Living-District-Session]] · [[2026-10-05-Living-District-Checkpoint]] · [[2026-10-05-Physics-Motion-Signals]] · [[2026-10-05-Whole-Body-Retarget-Research]] · [[2026-10-05-Whole-Body-Anatomy-Review]] · [[state]]
