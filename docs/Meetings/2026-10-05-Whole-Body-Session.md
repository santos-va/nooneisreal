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

## Related

- [[2026-10-05-Whole-Body-Motion]] · [[2026-10-05-Living-District-Session]] · [[2026-10-05-Living-District-Checkpoint]] · [[2026-10-05-Physics-Motion-Signals]] · [[2026-10-05-Whole-Body-Retarget-Research]] · [[2026-10-05-Whole-Body-Anatomy-Review]] · [[state]]
