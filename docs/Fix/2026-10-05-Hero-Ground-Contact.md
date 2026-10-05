# Опора стоп Choko та Skea

2026-10-05 · T2 Гефест · виконання [[2026-10-05-Whole-Body-Motion]]. Поточний кандидат; остаточне native-приймання й загальні гейти координує T1.

## Причина і виправлення

Попередній `HeroFootContact` виправляв лише crouch / WINDUP / lowhand і використовував глобальний Y=0 поза WaveField. Він не закривав idle, старт, зміну напрямку чи elevated floor. Незалежний actual-input baseline `3df43a5` показав підошви Choko −6,8 см / Skea −2,6 см у idle та −9,3 / −8,6 см після crouch. Стара оцінка ковзання за «низькою стопою» помилково включала toe-off: за окремо замороженими source-only вікнами steady Jog вже мав 1,9–3 см, але старт — 9–11 см, поворот Choko — 26,7 см.

`HeroGroundContact` після ретаргету й попереднього вузького solver читає фізичну опору тіла і по одному solid ray під кожною стопою. Площина actual hit підтримує рампи й дахи; WaveField дає висоту води окремо для кожної skinned точки. Підошва вимірюється всіма вершинами з сумарною вагою Foot/ToeBase ≥0,5, разом з іншими їхніми skin influences. Meshy сантиметри переводяться через фактичний transform Skeleton3D.

Горизонтальна фіксація ToeBase дозволена тільки в source-фазах опори; у нерухомих idle/crouch/block — стаціонарна опора. Піднята swing-стопа не притягується вниз. Для grounded ATTACK дозволене лише підняття прониклої підошви: немає горизонтального anchor чи притягування вниз, тому ударна нога frontkick лишається авторською. Це окремий CP5 після незалежно знайдених −25…49 мм під час Jab/hammer; фінальний semantic-contact шар рук виконується після стоп. Та сама upward-only норма закриває grounded HITSTUN/BLOCKSTUN/STUMBLE (незалежний baseline −35…61 мм), але не collapsed, launched, airborne чи ragdoll. Двокістковий solve змінює лише rotations, зберігає довжини сегментів, поточний knee pole і світову орієнтацію Foot. Немає записів у фізичне тіло, velocity, hitbox, RNG, мотузку чи бойовий стан. Повітря, ragdoll, dodge, відсутність опори та lifecycle reset відпускають anchor. Поза досяжністю горизонтальний anchor відпускається; доступне вертикальне виправлення підошви залишається. PLACEHOLDER межі: вертикально 0,25 м, горизонтально 0,40 м; більші помилки не приховуються розтягуванням ніг.

`begin_frame()` викликається один раз у physics tick. Повторний `skeleton_updated` у тому самому tick відтворює шість кешованих локальних rotations без повторних rays, FK, skinning чи зміни історії. Бюджет свіжого solve: одна перевірка `floor_y`, максимум два foot rays; кеш shoe samples створюється один раз і повторно використовує legacy samples. `query_count/body_support_reads/pose_reads/sample_count` вимірюють поточний physics tick; накопичувальні `begin_frames/apply_calls/cache_hits/history_updates/target_captures/rejected_targets` доступні для незалежного профілювання. Наявність двох rays сама по собі не доводить низьку CPU-вартість skinning.

## Заморожені source-фази й відтворення

`game/data/animation/foot_contacts.json` походить із raw FK UAL GLB, до появи solver; не читає виправлені пози й helper flags. Критерій: ball_l/ball_r біля власного мінімуму +15 мм, обидва сусідні source samples мають |vertical speed| ≤0,15 м/с, вікно ≥0,05 с. Горизонтальна швидкість не є фільтром; toe roll навколо ball дозволено. 18 clip-профілів; wrap-вікна перетинають межу циклу без відпускання anchor.

Відтворення з кореня репозиторію, Python із NumPy та SciPy:

```sh
python3 tools/animation/calibrate_foot_contacts.py --output /tmp/foot_contacts.json --raw-output /tmp/source-gait-raw.json
cmp game/data/animation/foot_contacts.json /tmp/foot_contacts.json
```

Перевірено byte-for-byte: JSON SHA-256 `2cfdc436f6e5b2dde362e1b739783c74b5a1362149473edf5ec74f6c9351dda9`; raw samples `63e37af2f5d09fcacfca87ec2c6d2603126b31361373b8666b7bbe2ef994dc3a`. Вхідні GLB SHA-256:

- UAL1: `d1cb4537efa4c06a953ca951e5935062f88c2580ac68e45045592d587bddb43d`.
- UAL2: `ad3ae049c7d3d4846133b59dba6218fdabebe05d3aec646caef6665f6c540684`.

Це вже придбані Quaternius UAL1/UAL2 **Source** assets, зареєстровані як CC0 у [[Textures-Registry]] (`anim-ual1`, `anim-ual2`), походження й перевірка — [[2026-10-03-launch-4-ual-source]] та [[2026-10-03-Animation-Sources]]. Нових ассетів, завантажень або ліцензій ця зміна не додає. JSON — числова калібрація на цих джерелах.

Metadata приймається атомарно: типи, finite duration, bounded кількість кліпів/інтервалів, обидві сторони, впорядковані фази в [0,1]. Відсутній файл, malformed JSON, некоректний профіль чи невідомий clip дають нейтральну відсутність горизонтального plant; геометричне виправлення проникнення залишається. Дані не містять виконуваного коду.

## Перевірки та межі

Постійний `tools/animation/ground_contact_check.gd` запускає обох справжніх CityFighter через InputRouter: старт, Jog, поворот на 90°, stop, crouch / вихід, block. Перевіряє skinned soles, frozen source-вікна та окремі незмінні baseline transition-вікна, незмінність фізики й довжин кісток, повторний retarget у тому самому tick, actual floor на висоті 4 м, sloped solid floor, edge/air release, malformed metadata. Це не тест ankle target замість взуття.

Поточний інтегрований ізолят: **5407/0**, raw log чистий (`ground-contact-positive.log`). Actual-input мінімальна підошва +2,74 мм Choko / +2,75 мм Skea; максимум ToeBase excursion у восьми source-вікнах кожного героя — 2–3 мікрометри. Окремі незмінні baseline transition-вікна залишаються в тесті навіть при зміні metadata/кліпа. Actual `_start_move` Jab/hammer/frontkick, обидві сторони й усі attack frames: підошви ≥+3 мм; ударна стопа frontkick у ACTIVE піднята на 1,11–1,16 м. Реальні `receive_hit` зі звичайним block input та HITSTUN, плюс initialized swell-flinch STUMBLE: 21/21/23 перевірені reaction frames на героя; minimum soles ≥+2,88 мм. Перевірка точної формули порівнює оптимізований solid-plane результат із повним weighted skinning, включно з перекладеною рампою, а WaveField — у 2D/3D з активним swell; допуск 20 мікрометрів.

Два mutation negative controls у власному ізоляті на фінальному helper й 5407 checks: вимкнути helper → **1447 очікуваних failures**, зокрема actual Jab/hammer penetration; обнулити metadata intervals → **5**, з них незалежні fixed start/turn world excursions 11,7 / 25,3 / 12,2 см. Обидва rc=1 зі штатним sentinel без parser/runtime errors; production відновлено. Це доводить видимі дефекти, а не лише те, що поле helper існує.

Незалежний T4 другий actual-input probe **54/0** закрив fixed start 11/9 см і turn 26,7 см до числової похибки без зміни gameplay body. Виявлений STOP Skea −7,52 мм виправлено fallback для недосяжного anchor, повтор пройшов ≤5 мм (`whole-body/candidate-second/acceptance.log`). Цей probe передує CP5, тому independent attack/native приймання ще очікується.

## CPU: точність і виміряні межі

Перший повний skinned solver коштував Choko idle 5,401 мс, Skea 3,569 мс median; на WaveField — близько 13–15 мс. Це стало CP4 blocker, а не прихованим результатом «лише два rays». Дві обмежені ітерації прибрали повторну арифметику, зберігши **всі** вершини й ваги:

1. Для solid plane: per-bone projection rows/biases, flattened Packed caches та зважені bind-позиції. Minimum математично тотожний повному skinning, децимації немає.
2. Для нелінійної води: cached per-bone world transforms і незмінні коефіцієнти трьох waves/swell, але синуси рахуються в actual skinned world XZ кожної вершини. Imported weights не всюди сумуються до 1: окремий translation remainder зберігає стару формулу без перенормування ваг. Equality-тест на висоті 4 м ловить пропуск цього доданка.

Незалежний T3, той самий sealed fixture, 30 warmup +120 physics ticks/case, фінальна математична версія до єдиного CP5 attack gate:

| Presentation median / p95, мс | Choko | Skea |
|---|---:|---:|
| Solid idle | 2,009 / 3,336 | 1,690 / 1,986 |
| Solid Jog | 1,113 / 1,669 | 1,008 / 1,463 |
| WaveField idle | 3,491 / 5,196 | 3,052 / 4,998 |
| WaveField Jog | 1,911 / 2,883 | 1,860 / 3,352 |

Повторні callbacks кешовані, без додаткового skinning. Water idle усе ще перевищує provisional орієнтир 1,5–2 мс/героя; ці числа не є заявою про 60 FPS на M3 чи завершений performance gate. Вимірювальний запуск/артефакти — `/workspace/nooneisreal-evidence/whole-body-motion/early-perf/run.sh`, `summary.json`; T1 після двох обмежених ітерацій прийняв залишковий бюджет provisional, з окремим two-hero вимірюванням перед закриттям; третя оптимізація не розпочинається. Фінальні CP5 attack/reaction gates не змінюють виміряні neutral/Jog шляхи.

Окремий **одночасний two-hero** quiet-run із фінальним helper SHA `46864f2c2dce2afccd4dcff2dcec120f01d4443dff15f5a224aa098a38aff5ce`, 600 виміряних physics frames, чистий rc0: solid idle median/p95/max **3,734 / 6,104 / 9,914 мс**, solid Jog **2,171 / 3,152 / 3,635**, hang **0,566 / 0,831 / 1,597**, water idle **6,016 / 7,586 / 8,449**, water Jog **3,349 / 4,882 / 9,265**. Це виміряна сумарна presentation-вартість обох героїв із повторними callbacks; не весь rendered frame і не M3. Усі спостережені presentation samples <16,67 мс. Доказ: `early-perf/paired-final/pair.log`, `source-delta.json`; T3 запускав без конкурентних native captures.

Докази: `/workspace/nooneisreal-evidence/hero-anatomy/feet-before/` (контрольовані translation-проби; їхній старий широкий low-height classifier не є фінальним plant-критерієм), `/workspace/nooneisreal-evidence/hero-anatomy/feet-candidate/`, незалежні `/workspace/nooneisreal-evidence/whole-body/baseline-actual.json` та `baseline-frozen-stance-metrics.json`. Native knees/stance, реальні moving platforms і повне художнє приймання не доводяться цими числами. Рухомі платформи в цьому static-city scope не реалізуються.

## Related

- [[2026-10-05-Whole-Body-Motion]] · [[2026-10-05-Whole-Body-Retarget-Research]] · [[2026-10-05-Whole-Body-Anatomy-Review]]
- [[2026-10-05-Physics-Motion-Signals]] · [[2026-10-05-Whole-Body-Visual-Audit]] · [[ADR-004-Physics-Is-Presentation]]
- [[Textures-Registry]] · [[2026-10-03-launch-4-ual-source]] · [[2026-10-03-Animation-Sources]]
