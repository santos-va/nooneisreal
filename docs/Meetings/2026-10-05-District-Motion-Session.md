# 2026-10-05 — рух і читабельність кварталу

Santos: «Давай тоді продовжувати». Перевірено GitHub: PR #176 merged у `6d929f8f938686c2803de9aa47eeca40e85fb852`. Чисту нову гілку `codex/district-motion-and-camera` створено від origin/main. macOS run37245037969 ще виконується; наявність merge не дорівнює доставленому app.

## CP0

Read-only аудит T2 підтвердив невикористані authored Dodge_Left/Right і відсутність moving landing; T6 — незавершений дальній горизонт та roof readability. План [[2026-10-05-District-Motion-And-Readability]] прийнятий у межах прямого доручення продовжувати. Зміни видимі в грі, але presentation-only: physics/stamina/timing незмінні. Нова платна генерація, ліцензії, іконка, main push/self-merge не входять.

## Уточнення після native аудиту

T2 camera виміряв 72 пози: SpringArm не входить у world solids, але всередині крамниць стискається до 0,231 м й опиняється в герої. T6 окремо відтворив near-side кадр 0,689 м із волоссям/мечем перед камерою. Виправляємо саме close-body readability, не перебудовуємо collision. Для перил лишається чинне safety body; змінюється лише видимий цоколь/решітка. T6 також адаптує впізнавані настінні предмети ательє/майстерні без нових ассетів і проходів.

## CP1 — інтеграційний кандидат

Смуги заморозили production. Targeted authored evasion **13760/0**, locomotion **306/0**, idle **18120/0**, sword **230/0**, authored combat **10173/0**; camera **432/0**; world **1813/0**. Новий runner містить 62 сценарії: усі старі 60 без зміни guard/save isolation плюс evasion/camera. Повний `make check-playable` виконується; поки не позначений PASS.

Native BEFORE/AFTER dodge охоплює 592 кадри; T4 підтвердив однакові physics/stamina/state/RNG значення. Moving landing й armed-послідовність ще переглядаються. World 8 пар ракурсів, усі 256 collision shape/transform/layers побайтово однакові; geometry 77112→88004 triangles, nodes618→626. Це не FPS-замір. [[2026-10-05-Authored-Evasion-And-Landing]] · [[2026-10-05-District-Silhouette-And-Readability]] · [[2026-10-05-District-Motion-Review]].

Перший shadow-pass guard мав помилку scope shader built-ins, виявлену native renderer; виправлення передає матриці з fragment і повторно перевіряється у справжньому Compatibility. Ця рання відмова не прихована зеленим headless. Збережені матеріали/перев'язь відновлюються, NPC не є об'єктом proximity policy.

Попередній main PR #176 реально опубліковано: build/verify-macos/publish run37245037969 success, live manifest revision `6d929f8f938686c2803de9aa47eeca40e85fb852`. Наступний кандидат — 0.4.2; його локальний PCK перевіряється лише після code commit, без публікації. [[2026-10-05-District-Motion-Delivery]].

## Related

- [[2026-10-05-District-Motion-And-Readability]] · [[2026-10-05-District-Journey-Session]] · [[state]]
