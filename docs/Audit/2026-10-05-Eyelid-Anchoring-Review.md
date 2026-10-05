# Повторний аудит прив'язки повік

2026-10-05 · T4 Феміда. **Фінальний вердикт: GREEN для вузького виправлення placement; baseline `fda6983` лишається RED.** Незалежний old-fail/new-pass, позитивне actual aperture coverage, особистий native огляд і raw check/gates підтверджені нижче. Scope — лише відхилені Santos очі; попередні бойові, lifecycle, gear та паркурні регресії цим дефектом не спростовані й повторно тут не розгортаються.

## Відкликання попереднього приймання

Santos: «Очі на лоба лізуть і це дивно — виправляй». Попередній [[2026-10-05-Expressive-Heroes-And-Combat-Review]] помилково дав eye GREEN. Він довів відсутність hull fragments, ненульову зміну міміки, lifecycle і незмінність gameplay authority, але не перевірив розташування повіки відносно original aperture. Світлу овальну ділянку вище Skea eye прийняли за допустиме закриття. Це blind spot T4 і native-приймання, а не спростування user feedback технічними 81/0. Відповідний eye verdict у попередньому аудиті відкликано.

Особисті команди `git log -2 --oneline`, `git status --short`, читання plan/shader/profile підтвердили базу `fda6983 Improve hero presentation and combat input responsiveness`. Старий `hero_eye_color` використовує `point.y / aperture` для нового source UV, замінює широку еліптичну область одним skin sample і додає центральну crease. Це змінює масштаб початкового eye image та не містить окремого контракту нерухомої верхньої/нижньої очної межі. Approved [[2026-10-05-Eyelid-Anchoring]] обмежує виправлення anchored upper lid і unchanged iris UV.

## Вимоги до вузького доказу

- Позитивне actual eyelid coverage в neutral/half/full blink/hurt/KO на незмінній позі, камері та нейтральній експозиції, front і 3/4 обох героїв.
- Protected forehead/upper-eye boundary розмічено за оригінальним atlas/aperture незалежно від нової shader ellipse. Визначення allowed region тією самою profile-константою не є незалежним oracle.
- Старий `fda6983` candidate має провалити саме placement/protected-region перевірку; виправлений має пройти її з ненульовою зміною справжньої повіки. Нульова зміна всього обличчя не проходить як fix.
- При half blink не перекриті повікою iris/pupil pixels лишаються на своїх початкових UV; source image не стискається та не переноситься вище.
- Read-only shader/profile review підтверджує вузьку межу: geometry, canonical atlas, model identity, бойова authority та матеріали тіла не змінені. Наявні face/gear focused checks доповнюють placement oracle; T1 виконує check/gates. Повтор full81 не потрібний без ширшої зміни або нової регресії.

Godot у цьому повторному аудиті T4 не запускає: animation/native виконує T2, фінальні check/gates — T1. Власні T4 команди тут — читання diff/raw, перевірка hashes, image comparison і розбір actual profile geometry; результат не спирається на старий acceptance.

## Незалежний негативний baseline

Особисто відкрито `eye-correction/t6-oracle/skea-neutral-landmarks.png` і `eye-correction/before/skea_front_closed.png`: на нейтральній експозиції світлий овал явно перекриває початкові brow/hair pixels над очною щілиною. T6 розмітив шість protected ROI за **оригінальними neutral PNG**, без читання profile/shader ellipse. Власна Python-команда повторно порівняла original RGB neutral/closed у цих координатах: усі шість ROI порушені; Choko **278/306**, **135/144**, **125/180** pixels зі зміною понад3 рівні; Skea **111/152**, **108/108**, **377/378**. Остання forehead/hair область має максимальну зміну **243/255**.

Доказ: `/workspace/nooneisreal-evidence/eye-correction/t4-review/baseline-forehead-rejection.json`. Це **REJECT** старого candidate, а не довіра до підсумку чужого скрипта. Початковий `placement_rois.py` лише друкував report і пропускав відсутні state PNG: T4 передав це T6, який додає обов'язкові neutral/closed файли, критерій нульових protected змін і позитивне actual aperture coverage. Focus містить власний brow tension, тому його виміри інформаційні й не повинні помилково трактуватися як isolated blink guard.

## Candidate1: статична межа і фактичний результат

Особисто прочитано `git diff` shader, обох `.tres`, profile/helper і focused-тесту. Eye source compression видалено. `hero_lid_coordinate` триангулює лише смугу між п'ятьма upper і п'ятьма lower original-atlas landmarks; поза нею `hero_eye_color` повертає вхідний колір. Усередині не перекритий iris читається як `texture(albedo_tex, uv)`, тому brow UV warp не зсуває сам iris. Напрям upper→lower задають анатомічні криві, а не довільний знак дзеркального UV island.

Власний Python-розбір **усіх чотирьох** actual `.tres` curves підтвердив п'ять точок на кожній межі, спільні corners і шість невироджених triangles однакового winding на aperture. Два вироджені triangles — спільні endpoint corners, які shader явно пропускає. Результат `t4-review/actual-aperture-triangles.json`. Усі чотири packed curves передаються матеріалу; profile validation перевіряє розмір, finite/out-of-atlas, corners, напрям і monotonic order. Перевірка стосується фактичних admitted профілів, не доводить всі можливі довільні polygons.

Повторний власний Python image comparison використовує незалежні незмінені T6 coordinates, без читання shader/profile для allowed ROI. `t4-review/placement-before-after.json`:

| Зріз | Protected forehead/brow/hair | Позитивне закриття чотирьох actual aperture | Вердикт |
|---|---|---|---|
| Старий `before` | усі6 ROI порушені | 225 / 168 / 96 / 55 змінених pixels | FAIL6 саме через placement |
| `candidate1` | усі6 ROI exact delta0; neutral patches незмінні | **225 / 168 / 96 / 41** змінених pixels, кожне≥20 | PASS0 |

T6 після зауваження T4 додав required neutral/closed PNG, жорсткий fail для protected змін>3 та позитивний поріг actual aperture coverage; відсутня або неактивна міміка не може дати GREEN. Це **independent bounded acceptance oracle** з exact script/reference provenance, не новий permanent CI guard і не частина старої81-case батареї.

Особисто відкрито обидва `candidate1/*front_closed.png`, Skea3/4 focus, `eyes-before-after.png` і `eyes-blink-phases.png`. Нова fill лишається у вихідній очній щілині; овал над brow/hair зник у переглянутих ракурсах, початкові очі відновлюються після моргання. Власний повторний pixel comparison усіх п'яти actual blink phases двох героїв дає **30 protected перевірок / exact delta0**; `t4-review/natural-and-source.json`. Dark-rim/corner guides мають ручну точність±2px і не заявляються bit-exact по всій межі: додатковий T6 огляд зафіксував кілька changed edge pixels, а не плаваюче око. Це стилізована surface eyelid, не анатомічний facial rig.

## Перевірки й provenance

Особисто прочитано `validation/hero-face.log` **1742/0** та `validation/hero-gear.log` **7946/0**, banner Godot4.7, без ERROR/WARNING/leak. Відхилений `rejected-fixture-shared-array.log` містить SCRIPT ERROR після випадкового shared-array mutation у negative fixture; він не прийнятий. Фінальний test diff явно копіює PackedVector2Array перед псуванням, не послаблює production validation.

Особисте hash-порівняння всіх **9** файлів `source-manifest.json` збіглося з current source; actual natural log має closure `0 → 0.707107 → 1 → 0.707107 → 0`, лише відоме llvmpipe VSync warning. Canonical GLB/atlas, body materials, outline, bones/skin/LOD та gameplay поза diff.

T1 виконав фінальні `make check` і `make gates`; T4 особисто прочитав обидва `validation/review-{check,gates}.log`, відповідні rc та порівняв source manifests. Обидва **rc0**, **0 ERROR/WARNING/leak**, **112 GDS/0**, smoke **164 checks / 19847 frames**, **175/175 assets**, **0 broken wikilinks**, батарея зелена. `review-source-before.json` та `review-source-after.json` byte-identical: **779 files**, digest **`c09463ae8cfc28bf8914205976a5acef5fe983c5638c74043c7bc5af9a1dbc03`**. Full81 у цьому вузькому виправленні не перезапускався, його старий результат не подається як новий. Апаратне приймання та всі можливі ракурси цим bounded native evidence не доведені.

## Related

- [[2026-10-05-Eyelid-Anchoring]] · [[2026-10-05-Eyelid-Anchoring-Session]] · [[2026-10-05-Eyelid-Anchoring-Fix]] · [[2026-10-05-Expressive-Heroes-And-Combat-Review]] · [[2026-10-05-Hero-Facial-Expression]] · [[2026-10-05-Hero-Face-And-Material-Audit]]
