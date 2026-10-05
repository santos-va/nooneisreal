# Поверхнева міміка героїв

2026-10-05 · T2 Гефест · [[2026-10-05-Expressive-Heroes-And-Combat]].

Предмет: для підтриманих облич Choko/Skea поверхнева міміка змінює лише виміряні риси вихідного атласу, зберігаючи геометрію, UV, skin/LOD, physics authority та незалежність інстансів.

## Звірка

Власний розбір двох GLB: 24 joints, одна skinned surface/material, один embedded JPEG 2048², немає morph targets чи окремих кісток ока/повіки/брови/щелепи. Choko має 28 520 vertices / 37 448 triangles, Skea 33 108 / 37 138. `headfront` непридатний для міміки: у Choko впливає на 6894 vertices широко по голові/шиї, у Skea лише на 54 з вагою до 0,0444. Його роль у gaze не змінена. Вихідні GLB та атлас не редагуються.

`HeroFaceProfile` зберігає виміряні pixel-регіони й осі вихідного атласу; `HeroFacePresentation` читає стани гри та physics serial. Блимання детерміноване, без RNG; focus/hurt/KO мають пріоритет, freeze/hitstop зберігають поточне зображення. `motion_revision` через наявний discontinuity path скидає stale позу при restart/rewind. Повторний render callback не просуває фазу. Параметри тривалості й сили виразу — художні PLACEHOLDER у `.tres`.

Маска обличчя узгоджена з матеріальною смугою: COLOR.r — face, g — попередня тканина, b — локальна корекція запечених highlights, a збережено. Фінальний R admission читає неперервну суму Head/head_end/headfront weights; точні UV envelopes у fragment shader окремо обмежують видимі зміни рис. Поріг 0,90 враховує виміряне змішування Skea eye-region від 0,9318: vertex 4784, UV (0,098828; 0,142019), решта впливу RightShoulder 0,0641742 та neck 0,0040226; точний власний розбір з GLB hash — `face-combat/face-profile-anatomy.json`. Це не дозвіл фарбувати торс. Матеріальний builder зберігає skin/UV/геометрію та захищає triangle corners усіх наявних LOD.

Shader стискає оригінальний малюнок очної щілини, закриває її тоном сусідньої шкіри й лишає тонку лінію, взяту з фактичного ink атласу. Окремий warp вихідної брови Choko та стискання наявного mouth paint дають напруження/розслаблення; neutral повертає вихідний малюнок без змін. Посмішка Skea у neutral збережена; нової пари очей, намальованих зубів, пласкої картки чи camera-facing geometry немає. Це стилізована поверхнева міміка, не анатомічний facial rig і не audio lip sync. Семантична розмовна міміка без реального speaking event не підставляється.

## Перевірка й відхилені кандидати

Перша eyes-only перевірка Godot 4.7: `HERO_FACE_COMPLETE checks=1718 failures=0`, raw `/tmp/nir-face-first-pass47.log`. Перевірено фактичні eye-region vertices обох моделей, authority/bones, фізичний clock, пріоритети, freeze/reset та негативні форми: NaN-регіон, нульова UV-вісь, нульовий interval, невідомий герой/не-head anatomy.

Перший native candidate `face-combat/eyes-first/` не прийнято. Він змінив 1444 face pixels Choko та 452 Skea на ідентичній позі; T6/T4 побачили залишкову білу очну щілину. Ненульовий pixel delta не означає завершене моргання. Регіони та покриття уточнено, у повному closure стиснена sclera тепер повністю прибирається, лишається skin і оригінальна темна лінія. Перший raw мав ALSA fallback errors; чистий native результат ним не заявляється. Подальша перевірка має окремо охопити кожне око, брови й mouth tension/KO на реальній поверхні, крупно й під кутом.

Друга native-серія `face-combat/states-second/` показала окремі focus/hurt/KO mouth зміни, але bilateral blink ще відхилений. Читання atlas RGB виявило неправильний Choko ink sample: (588,158) був тоном шкіри (255,211,188); замінено виміряним темним (596,166) = (41,6,13). Тон закритої повіки тепер читається з фіксованої виміряної точки шкіри, без ковзання семплера у волосся.

Порівняння `mask-diagnostic/` та `no-outline-diagnostic/` довело ще одну незалежну причину: навіть 6-мм inverted hull створював чорні внутрішні фрагменти над очима, які читалися як зіниці після закриття. Вимкнення лише next_pass у діагностиці прибрало основні артефакти. Матеріальна смуга додала окремий `hero_outline.gdshader`: підтриманий head-domain пригнічує внутрішній hull, generic outline та контур тіла збережені. Спершу вузький UV-based R залишав нульові трикутники саме над очима, тож новий outline пропускав ті самі артефакти. Після цього перевіреного контрприкладу R змінено на неперервний head-domain ≥0,90 із чинним all-LOD corner guard; лише fragment envelopes змінюють atlas pixels. Це також прибирає зайвий hull на підтриманій частині волосся, зберігаючи вихідну геометрію й намальоване волосся. T1 і T6 особисто прийняли bilateral blink та чистіший силует у `face-combat/head-domain/`.

Фінальний focused **HERO_FACE_COMPLETE 1734 / 0**, rc 0, чистий raw `face-combat/head-domain/focused.log`. Додано до першого guard повну валідацію mouth/brow/ink/skin параметрів, незалежність двох однакових героїв та фактичний round reset у тій самій позиції. Умова R тепер перевіряє неперервний head-domain; обмеження actual pixel effect належить shader envelopes, а не нульовому R поза UV-колом.

Фінальний локальний native набір `face-combat/head-domain/`: **20 PNG**, neutral/focus/hurt/closed/KO, front та 3/4, обидва герої; **rc 0**, shader/runtime errors і leaks відсутні, лише відоме unsupported VSync warning. Це явно підписані стани міміки на однаковій позі тіла, а не симуляція бою. `source.json` містить SHA-256 усіх відповідних production/helper файлів; `native.log` зберігає фактичні closure/mouth/brow controls. Mouth/KO збережено після окремого приймання T6; моргання перевіряється окремо як timed послідовність. `hero-face` зареєстрований у playable runner, без збільшення ліміту.

## Related

- [[2026-10-05-Expressive-Heroes-And-Combat]] · [[2026-10-05-Parkour-Motion]] · [[2026-10-05-Hero-Equipment-And-Cloth]] · [[Style-Guide]]
