# Читабельна тканина й тонший контур героїв

2026-10-05 · T2 Гефест · [[2026-10-05-Expressive-Heroes-And-Combat]].
Статус: scoped матеріальний результат прийнято T6; focused-перевірки пройдено,
повна інтеграція координатору.

## Аудит і реалізація

Перед зміною прочитано план, `HeroGarmentMask`, `hero_garment.gdshader`,
`outline.gdshader`, material setup та вісім baseline PNG. У вбудованому
Skea atlas великі білі розриви вже намальовані на фіолетовій тканині:
`specular_disabled` підтверджує, що зниження specular не усуває причину.
Baseline `front_no_outline` доводить окремий дефект чорних гранованих
фрагментів товстого контуру.

Наявний bone-domain G cloth whitelist збережено окремим; консервативна
перевірка всіх LOD звужує його межі, тому сам G buffer не названо bit-exact.
B — нова маска локальної
корекції світлих ділянок Skea: рукави й передня нижня частина торса.
Верхній центральний chest/neck, zipper, ноги, взуття, волосся, кисті,
спина й backpack лишаються поза B. Аудит вихідної GLB геометрії виявив,
що відкрита шкіра грудей має shoulder weights: одного списку bone names
для захисту недостатньо. Тому додано консервативні просторові межі й
відсікання pink complexion texels; білі відблиски шкіри захищає геометрія.
Кожний трикутник, що торкається забороненого регіону, обнуляє всі кути
маски в базовій сітці та всіх імпортованих LOD.

Узгоджений канал R належить measured facial API смуги animation, G —
попередній cloth, B — de-light, A — оригінальний. Старий коментар тесту
називав R каналом outline, але фактичний `outline.gdshader` COLOR взагалі
не читає; перевірено поточний код, не успадковано застарілий коментар.
Face include підключено тільки до hero shader. Оригінальні atlas/GLB,
позиції, UV, skin weights, індекси та всі LOD не замінюються.

Тонший hero outline 6 мм замість 22 мм внесла animation-смуга у власний
`SkeletalRig`. Її подальший no-outline diagnostic окремо довів, що навіть
6-мм hull іноді перекривав закрите око внутрішніми гранями. Додано окремий
`hero_outline.gdshader`: у межах R facial features він прибирає hull, а
контур тіла/волосся лишає 6 мм. Камерний include та uniform contract
збережено. Саме цей новий hero shader свідомо читає R; загальний
`outline.gdshader` і NPC/world не змінено. De-light strength 0,96,
purple highlight `(0,40; 0,16; 0,50)` sRGB та геометричні межі —
**PLACEHOLDER** до візуального приймання. Перший світлоліловий candidate
T6 відхилив як надто контрастний; темніший варіант проходить окремий native
огляд. Проміжний темніший варіант усе ще залишав великі білі шматки на
передпліччі через змішані Hand weights. За погодженням координатора B
отримав окрему геометричну межу фактичного рукава; G не розширено.

Godot rest/UV та оригінальний atlas показують початок pink hand samples
на 0,520176 / 0,522235 м від центральної осі. B закінчується до 0,500 м,
залишаючи близько 20 мм запасу, навіть якщо тканина має Hand weights.
Торс окремо обмежений 0,18 м убік, 0,28 м над hips та front plane;
центральний 35-мм zipper і bare upper chest виключені. Pink classifier
є додатковим консервативним фільтром, не універсальним детектором шкіри.
Коротке shader-перетворення інтерпольованого B зменшує білий halo лише
в уже дозволених cloth triangles; повністю захищений трикутник лишається
точним нулем.

## Перевірки

Предмет: для всіх cached hero buffers локальна корекція тканини не
перефарбовує захищену анатомію й не змінює topology, skin або стан іншого
екземпляра героя.

`hero_gear_check.gd` зберігає повний skinned-cloth oracle й допуски контактів,
byte-exact UV/positions/weights/indices та exact LOD guards. Додано
семантичний контракт RGBA, ненульові cloth/face/highlight samples,
захист фактичної shoulder-weighted neckline, zero G/B на кожному
protected triangle всіх LOD та ізоляцію shader/outline/face uniforms
двох однакових героїв зі спільним cached mesh. Камерні restore/NPC guards
лишаються чинними. Успіх потребує completion sentinel/rc0/чистого raw;
відмова блокує передачу й потребує локального виправлення.

Перший scoped Godot 4.7: **HERO_GEAR_COMPLETE 7 942 / 0**, rc0,
`/workspace/nooneisreal-evidence/face-combat/materials/hero-gear-first.log`.
Це не повна фінальна батарея. Negative control та native-приймання
проводяться незалежно.

## Завершений scoped доказ

Фінальний focused `hero-gear-refined.log`: **7 946 / 0**, rc0, чистий raw,
включно з actual wrist/skin guard, all-LOD protected triangles, незалежними
surface/outline матеріалами однакових героїв та camera fade нового hull.
Повний cloth-contact oracle й допуски не послаблено.

`refined-ab/` містить **12 native PNG**: по front/body/back на кожного героя,
пари мають одну нерухому позу й відрізняються лише `garment_delight` 0/0,96.
Прогін 4.7 Compatibility завершився rc0 без runtime/shader помилок і leaks;
лише відоме unsupported VSync warning. Початковий допоміжний capture мав
indentation parse error; виправлено тільки зовнішній helper, після чого
цей завершений повтор прийнято. T6 особисто оглянув on/off пари й прийняв
помітне приглушення рукавів/маскованої тканини. **На грудях і верхньому
плечі лишаються білі запечені marks**: це не повне перемальовування atlas
й не твердження, що прибрано кожну пляму.

`protected-proof.json` та відтворюваний `protected_proof.py` у
`/workspace/nooneisreal-evidence/face-combat/materials/` містять:

- Фактичні **33 108** Skea vertices, **2 214** enabled B проти 1 686 у
  проміжному dark candidate. Дані — Godot `mesh-refined.json`, не лише CPU
  припущення про GLB transforms.
- Ненульові protected sets: hands 1 938, head/neck/feet 7 382, upper central
  chest 4 845, zipper 195, back torso 2 394, pink-color candidates 1 900.
  Кожна група має **0 B vertices** і **0 affected triangles** в base та
  всіх трьох LOD. Групи перекриваються, їхні кількості не додаються.
- Вісім зафіксованих native ROI / **29 159 pixels** — neck/chest, teeth,
  zipper, hand, white shoes, head, backpack interior, book ∞ — мають
  **0 змінених pixels**. Три повні Choko on/off зображення bit-exact.
  Ширша початкова рамка backpack охопила 6 змішаних sleeve-boundary pixels;
  незмінність усієї рамки не заявляється, прийнята ROI описує саме interior.
- Source SHA-256 зафіксовано після capture; усі вісім релевантних source
  timestamps передують першому PNG. Власник material lane не змінював
  mask/shader/outline під час або після запису.

Це докази конкретних поверхонь і поз. Вони не замінюють окремого facial
state/native-приймання animation-смуги, фінальних make check/gates/playable
або апаратного огляду M3. Подробиці незалежного візуального приймання —
[[2026-10-05-Hero-Face-And-Material-Audit]].

## Related

- [[2026-10-05-Expressive-Heroes-And-Combat]] · [[2026-10-05-Expressive-Heroes-Session]] · [[2026-10-05-Hero-Face-And-Material-Audit]] · [[2026-10-05-Hero-Equipment-And-Cloth]]
