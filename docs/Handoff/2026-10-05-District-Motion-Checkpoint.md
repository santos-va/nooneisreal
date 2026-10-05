# Контрольна точка — рух і читабельність

2026-10-05 · T1. [PR #177](https://github.com/santos-va/nooneisreal/pull/177), branch `codex/district-motion-and-camera`, production `9685dfaa7d75829066ca54faf5c56c3fd820d91c`, база merged #176 `6d929f8`. Merge виконує Santos; перед наступною сесією перечитати GitHub і local status.

## Завершений зріз

- UAL Dodge_Left/Right тепер реально керують позою обох героїв. Час active segment адаптований до наявного dodge_progress, recovery не додає блокування керування. Рухоме приземлення використовує криву Jump_Land для обмеженого стискання й анатомічного розв'язання ніг, зберігаючи gait-цілі стоп. Це не нова фізика й не повний Jump_Land поверх зупинених ніг.
- CityCamera зберігає SpringArm collision, обмежено піднімає близький ракурс і локально прибирає перекриття тілом/мечем/перев'яззю. Native Compatibility dither має default-off, active-camera guard, незмінні тіні та точне відновлення матеріалів.
- Відкриті перила мосту; 10 декоративних будинків поза playable bounds; підвішений одяг, годинник/інструменти. Усі 256 фізичних колізій побайтово тотожні базі; backdrop має 6 mesh batches. Нова прохідна ділянка не додана.
- Версія 0.4.2. Іконка незмінна за вибором Santos до оригінального PNG.

## Докази

`make check-playable` **62/0**, smoke **164 checks / 19847 frames**, **94 GDS/0**, `make gates` GREEN. Targeted authored evasion **13760/0**, camera **432/0**, geometry **1813/0**. Незалежний T4 GREEN: 1080 motion frames, 12 native world views, lifecycle **394/0**, active-camera mutation виявляється. Траси592dodge+200landing тотожні BEFORE за position/velocity/state; dodge також за stamina/frames. Незмінність RNG/rope/HP додатково перевірена цільовим evasion тестом.

Exact-SHA PCK9685dfa: **208643364 B**, SHA256 `a4b3fc8a50260c88b1acd1371dba16596f373570c99d17218fe4e1b09775828d`; native `--main-pack` **19/0**, version0.4.2/fullSHA, helper/include resources, quests6/audio й shader compilation перевірені. Пакет локальний, не опублікований реліз. [[2026-10-05-District-Motion-Delivery]].

Root logs `/workspace/nooneisreal-evidence/district-motion/`; camera `/workspace/nooneisreal-evidence/district-motion-camera/`; world `/workspace/nooneisreal-evidence/district-motion-world/`. Компактні кадри в `docs/assets/screenshots/2026-10-05-district-motion/` і `2026-10-05-district-readability/`; відео порівняння `district-motion/motion-before-after.mp4` поза repo. Ранній candidate/world містить відхилені shader-error кадри; фінальний правильний набір — `district-motion/after/world/`. Не плутати історію відмови з прийнятими доказами.

## Доставка та що далі

Попередній main6d929f8 реально доступний у macOS-каналі; run37245037969 build/verify-macos/publish success і live manifest звірені. Поточний PR177 потрапляє до каналу тільки після merge та успішної публікації. Стан finalCI/merge дивитися в самому PR; локальні виміри не є підтвердженням встановленого app Santos.

Native CI renderer-step додається після реально виявленого headless blind spot. M3, фізичний controller, hardware FPS, звук і 30-хвилинне ручне приймання досі відкриті. Фінальні hero art/анатомія, ширша кампанія/герої, світи/бої в місті, модинг і комерційна політика не закриті цим зрізом. [[2026-10-04-Remaining-Work]] описує історичну чергу: звіряти з новими PR, не повторювати вже виконане.

## Related

- [[2026-10-05-District-Motion-And-Readability]] · [[2026-10-05-District-Motion-Session]] · [[2026-10-05-District-Motion-Review]] · [[2026-10-05-Authored-Evasion-And-Landing]] · [[2026-10-05-District-Silhouette-And-Readability]] · [[2026-10-05-District-Motion-Delivery]] · [[state]]
