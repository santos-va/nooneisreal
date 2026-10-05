# Повіка в межах справжнього ока

2026-10-05 · T2 Гефест · [[2026-10-05-Eyelid-Anchoring]].

Santos відхилив очі бази `fda6983`: «Очі на лоба лізуть». Попередні headless checks і visual GREEN не доводили анатомічне положення, тому приймання очей відкликано. Повторний native front/3⁄4 при білому ambient 0,18 / key 0,65 показав причину: симетричний ellipse envelope зафарбовував надочну шкіру, темний обідок і частину брови; source UV compression водночас рухав райдужку. Особливо помітний великий світлий овал Skea.

## Реалізація

За справжнім нейтральним зображенням обрані верхня/нижня межі кожної eye aperture. Skinned mesh projection + perspective-correct barycentric UV дають п'ять atlas landmarks на кожну повіку; native червоні/бірюзові UV markers особисто перевірені поверх моделі. Діагностика спершу помилково змішувала логічний viewport 1600×1200 із PNG 1152×864; масштаб 1600/1152 виправлено до production. Один Skea pick перекривав передній hair triangle: перенесено лише в справжню видиму aperture на screen (403,489), UV (237,4333;299,3887). Остаточні anchors та fixtures збережені в evidence.

Shader триангулює вузьку смугу між upper/lower landmarks. Верхня повіка закриває її згори донизу; ink crease лишається всередині вихідного обідка. Original iris UV не масштабується й не зміщується; відкритий фрагмент завжди читає вихідний texel, навіть коли зовнішня брова має вираз. Напрям верх/низ задають анатомічні landmarks, а не знак осі дзеркального UV island. Міміка рота, body materials, outline, canonical atlas/GLB, gameplay, skin/LOD і кістки не змінені. Це обмежена поверхнева повіка, не повний facial rig; fill та тривалість лишаються стилізованими художніми PLACEHOLDER.

Profile validation відкидає відсутні/nonfinite/out-of-atlas landmarks, розірвані corners, нульову aperture, перехрещений напрям і немонотонний порядок. Регресія перевіряє malformed arrays разом із попередніми lifecycle/authority/instance/bone guards. Перший тестовий negative fixture випадково мутував shared PackedVector2Array у duplicate Resource; виправлено явним копіюванням масиву перед внесенням поломки, oracle не послаблено. Raw відхиленого запуску збережено.

## Перевірка

Evidence root: `/workspace/nooneisreal-evidence/eye-correction/`. `before/` містить старі neutral/focus/closed на однаковій позі й експозиції, fixture та source manifest `fda6983`; `markers/` — UV sanity; `calibration/actual-lid-picks.json` — остаточні координати; `candidate1/` — 16 native front/3⁄4 neutral/focus/half/closed; `natural/` — 18 native кадрів: по 5 actual-timer blink phases і front/3⁄4 hurt/KO. Лог фіксує closure 0 → 0,707 → 1 → 0,707 → 0 без прямого присвоєння closure. Source manifest фіксує перевірені production файли.

Незалежний T6 oracle `t6-oracle/placement_rois.py` визначений лише з original neutral до candidate: шість protected forehead/brow/hair patches і чотири справжні aperture interiors. Старий closed провалює всі шість protected patches; candidate1 — PASS, 0 failures: усі protected pixels мають exact delta 0, всі чотири aperture дають позитивне закриття. Це bounded image guard і особистий front/3⁄4 огляд, не твердження про всі можливі камери. Focus має законний рух брови й не використовується як protected blink oracle.

T6 незалежно прийняв scoped eye placement: front/3⁄4 half/closed, п’ять природних фаз, hurt/KO не зсувають очі; protected pixels і повернення до open мають exact 0 змін. При нейтральному світлі T6 окремо помітив попередній ламаний mouth rim Skea у 3⁄4 KO та ступінчастий шов у front hurt. Mouth shader/profile цим виправленням не змінені; це зафіксована межа попередньої поверхневої міміки, не твердження про повністю анатомічне обличчя.

Godot 4.7 focused: `HERO_FACE_COMPLETE checks=1742 failures=0`, `validation/hero-face.log`. Спорядження: `HERO_GEAR_COMPLETE checks=7946 failures=0`, `validation/hero-gear.log`, обидва focused rc 0 без runtime errors. Фінальні `make check` / `make gates` T1 запустив після source freeze, T2 особисто прочитав raw і rc: smoke **164 checks / 19847 frames**, **112 GDS / 0**, **175/175 assets**, wikilinks/roles чисті, обидва rc0. `validation/review-{check,gates}.log/.rc` і `review-source-{before,after}.json`: **779 sources** незмінні, digest `c09463ae8cfc28bf8914205976a5acef5fe983c5638c74043c7bc5af9a1dbc03`. Вузьке виправлення очей завершено; повну81 батарею для цього shader/profile delta повторно не запускали за планом.

## Related

- [[2026-10-05-Eyelid-Anchoring]] · [[2026-10-05-Eyelid-Anchoring-Session]] · [[2026-10-05-Hero-Facial-Expression]] · [[2026-10-05-Hero-Face-And-Material-Audit]] · [[state]]
