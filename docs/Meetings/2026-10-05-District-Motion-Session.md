# 2026-10-05 — рух і читабельність кварталу

Santos: «Давай тоді продовжувати». Перевірено GitHub: PR #176 merged у `6d929f8f938686c2803de9aa47eeca40e85fb852`. Чисту нову гілку `codex/district-motion-and-camera` створено від origin/main. macOS run37245037969 ще виконується; наявність merge не дорівнює доставленому app.

## CP0

Read-only аудит T2 підтвердив невикористані authored Dodge_Left/Right і відсутність moving landing; T6 — незавершений дальній горизонт та roof readability. План [[2026-10-05-District-Motion-And-Readability]] прийнятий у межах прямого доручення продовжувати. Зміни видимі в грі, але presentation-only: physics/stamina/timing незмінні. Нова платна генерація, ліцензії, іконка, main push/self-merge не входять.

## Уточнення після native аудиту

T2 camera виміряв 72 пози: SpringArm не входить у world solids, але всередині крамниць стискається до 0,231 м й опиняється в герої. T6 окремо відтворив near-side кадр 0,689 м із волоссям/мечем перед камерою. Виправляємо саме close-body readability, не перебудовуємо collision. Для перил лишається чинне safety body; змінюється лише видимий цоколь/решітка. T6 також адаптує впізнавані настінні предмети ательє/майстерні без нових ассетів і проходів.

## CP1 — інтеграційний кандидат

Смуги заморозили production. Targeted authored evasion **13760/0**, locomotion **306/0**, idle **18120/0**, sword **230/0**, authored combat **10173/0**; camera **432/0**; world **1813/0**. Новий runner містить 62 сценарії: усі старі 60 без зміни guard/save isolation плюс evasion/camera. Повний `make check-playable` виконується; поки не позначений PASS.

Native BEFORE/AFTER dodge охоплює 592 кадри; T4 підтвердив однакові position/velocity/stamina/state/frames значення. Moving landing й armed-послідовність ще переглядаються. World 8 пар ракурсів, усі 256 collision shape/transform/layers побайтово однакові; geometry 77112→88004 triangles, nodes618→626. Це не FPS-замір. [[2026-10-05-Authored-Evasion-And-Landing]] · [[2026-10-05-District-Silhouette-And-Readability]] · [[2026-10-05-District-Motion-Review]].

Перший shadow-pass guard мав помилку scope shader built-ins, виявлену native renderer; виправлення передає матриці з fragment і повторно перевіряється у справжньому Compatibility. Ця рання відмова не прихована зеленим headless. Збережені матеріали/перев'язь відновлюються, NPC не є об'єктом proximity policy.

Попередній main PR #176 реально опубліковано: build/verify-macos/publish run37245037969 success, live manifest revision `6d929f8f938686c2803de9aa47eeca40e85fb852`. Наступний кандидат — 0.4.2; його локальний PCK перевіряється лише після code commit, без публікації. [[2026-10-05-District-Motion-Delivery]].

## CP2 — повний набір регресій

Production `9685dfaa7d75829066ca54faf5c56c3fd820d91c`; [PR #177](https://github.com/santos-va/nooneisreal/pull/177) відкрито як draft для завершення native/PCK/CI, без self-merge. `make check-playable` rc0: **94 GDS/0**, smoke **164 checks / 19847 frames**, **62 scenarios / 0 failures**. `make gates` rc0, батарея зелена. Raw logs — `/workspace/nooneisreal-evidence/district-motion/check-playable.log`, `gates.log`, per-case `playable/`.

T4 прийняв motion: **1080 AFTER кадрів** (592 dodge, 288 armed, 200 moving landing), без виявлених anatomy/weapon/stale-pose блокерів. Фізичні траси 592+200 frames тотожні BEFORE. Камерні lifecycle/renderer probes та PCK exact-SHA перевіряються окремо й не підміняються цими числами. Фінальний запис і межі — [[2026-10-05-District-Motion-Review]], [[2026-10-05-District-Motion-Delivery]].

## Запобігання повтору renderer-відмови

Ранній shader scope дефект дав би зелений headless, але білі матеріали у native. Варіанти: лише ручний proof, намагатися прогнати pixel probe в headless, окремий native software-rendered CI-крок. Обрано третій: уже готовий `city_camera_renderer_check.gd` перевіряє 4 умови, зокрема видимість, тінь і відновлення. Технічні межі M3/FPS незмінні; CI перевіряє саме фактичну компіляцію й pixels у Compatibility. T8 додає fail-closed step без зміни production/PCK9685dfa або 62 headless сценаріїв.

## CP3 — приймання й передача

T4 GREEN за [[2026-10-05-District-Motion-Review]]. Native lifecycle **394/0**, active-camera mutation ламає guard очікуваною відмовою. PCK точного9685dfa з нативним запуском **19/0**, size208643364/SHA256a4b3fc8a50260c88b1acd1371dba16596f373570c99d17218fe4e1b09775828d; shader include/helper metadata реально всередині. Відео before/after20,7с з існуючих кадрів показує real60fps та окремо позначене0,25×slow, не нову швидкість гри.

Контрольна точка — [[2026-10-05-District-Motion-Checkpoint]]. Статус CI/merge зберігається в PR #177, не припускається наперед. Наступні documentation/verification commits не змінюють прийнятий production9685dfa.

## Related

- [[2026-10-05-District-Motion-And-Readability]] · [[2026-10-05-District-Journey-Session]] · [[state]]
