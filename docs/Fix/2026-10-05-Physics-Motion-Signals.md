# Фізичний рух і темп анімації

2026-10-05 · T2 Гефест · виконання [[2026-10-05-Whole-Body-Motion]].

Предмет: для всіх grounded-переміщень Choko/Skea анімаційна відстань походить із фактичної підтриманої траєкторії; явний телепорт не є кроком чи імпульсом інерції.

## Виміряний дефект

Actual CityFighter baseline `3df43a5`, 60 Hz, справжня геометрія CityDistrict:

| Випадок | Choko | Skea |
|---|---:|---:|
| Grounded WINDUP, реальне гальмування | 0,476667 м, ноги Idle | 0,590000 м, ноги Idle |
| `restart_at` на 10 м | анімаційна швидкість 600 м/с, Sprint_Enter | 600 м/с, Sprint_Enter |
| 74 кроки EastRamp, фактична 3D-відстань | 6,903700 м | 7,643693 м |
| Те саме, колишня XZ-відстань кроків | 6,739303 м | 7,461674 м |

Причини: grounded WINDUP виключався двома gates; SkeletalRig зберігав стару позицію після lifecycle reset; XZ-проєкція обрізала підйом по рампі. `velocity.y` на підтриманій рампі дорівнює нулю після `_ground_physics`, тож він не є мірою фактичного вертикального руху.

## Зміна

`FighterMotionSignals` один раз на physics tick читає позицію, нормаль фактичної опори й lifecycle revision. Підтримана відстань — довжина переміщення в дотичній площині; у повітрі/без solid-опори площина горизонтальна, тому вертикальне падіння не крутить кроки. Actual velocity й acceleration доступні спільному шару корпуса. Helper не пише transform, velocity, hitbox, RNG або запас мотузки.

`Fighter.motion_revision` змінюється при `reset_for_round` (включно з City restart/resume) та справжньому `rewind`. Перший знімок/нова revision дає нуль відстані, швидкості й прискорення; SkeletalRig очищає gait, cadence та body/feet історії після відновлення попередніх overlays. Звичайні dash/flash, arena clamp, separation і рух ragdoll не позначені телепортами. SWAP — зміна руки меча, не перенесення тіла.

Grounded WINDUP тепер зберігає авторські рухомі ноги під upper-body throw, доки фізичний герой гальмує. Gameplay friction і швидкості не змінені. При зупинці ноги повертаються в idle за звичайним gait-контрактом.

## Перевірка

Постійний `tools/animation/physics_motion_check.gd`: обидва справжні CityFighter, WINDUP, lifecycle restart, EastRamp, штатний InputRouter start/stop/jump/landing, held input проти solid wall і повільне змотування після miss. На кожному visual tick порівнює transform, velocity, state, HP, meter, grapple token/phase/length/recovery та RNG. Опційний `--output=<absolute JSON>` зберігає 182 рядки для порівняння з baseline.

Власний ізолят із вузьким integration-патчем: **1121/0**, raw log чистий. Усі 182 рядки фактичного руху (стан, фаза, velocity, displacement, floor normal, підтримка) тотожні baseline. WINDUP gait active 0/16 → 16/16; restart 600 → 0 м/с; ramp cadence збігається з підтриманою 3D-відстанню з похибкою <0,000001 м.

Три окремі source-mutation negative controls у власному ізоляті, production після кожного відновлений: прибрати revision guard → **8 очікуваних failures**; повернути XZ на рампі → **2**; вимкнути gait у grounded WINDUP → **44**. Кожен rc=1 зі штатним sentinel, без parser/runtime error. Це не runner-випадки з дозволеними errors: загальний runner додає лише позитивний сценарій і зберігає всі попередні 70.

Стара перевірка `gait_check.gd` зберігає всі вимоги. Її контрольна fixed-Walk гілка тимчасово від'єднує лише новий `HeroGroundContact`, щоб кеш актуального Jog не виправляв історичний baseline; точний початковий helper із його станом повертається після контролю. Результат **722/0**, `locomotion_states_check` **306/0**. Незалежний негативний контроль cadence ×0,25 дає **722/2**: вимога знизити ковзання більш ніж на 60% падає для обох героїв. Поріг не послаблено. Журнали `gait-regression.log`, `gait-cadence-negative.log` та `locomotion-states-regression.log` у тій самій evidence-папці.

Докази: `/workspace/nooneisreal-evidence/whole-body/physics-motion-{audit,candidate}.json`, відповідні `.log`, `physics-motion-negative-{restart,slope,windup}.log`. Інтегрований snapshot із body/feet та додатковим actual Choko rewind / restart під час руху пройшов **1149/0** у власному ізоляті (`physics-motion-integrated.{log,json}`). Незалежні native-послідовності й загальні гейти ще приймаються координатором; ці цифри не є заявою про остаточне художнє приймання.

## Інтеграційне уточнення: завершення прискореного тесту

Перший загальний runner правильно відхилив цей сценарій: усі **1149 assertions пройшли**, проте на shutdown були 6 ObjectDB instances і 2 ресурси. Повтор exact runner `--fixed-fps 60 --verbose` у власному ізоляті назвав конкретно `rewind.ogg`, `AudioStreamOggVorbis` / `OggPacketSequence` та їхні playback-об’єкти. Попередній власний запуск без прискорення physics не відтворював цю гонку завершення.

Виправлено тільки teardown тесту: після всіх assertions звільняються district і звукові autoloads; deferred destruction та audio mixer отримують 200 мс **wall time**, як у чинних `tools/audio/sfx_check.gd` / `music_check.gd`. SceneTree timer під `--fixed-fps` не є wall-time drain. Ігровий код, кількість і вимоги перевірок та strict runner не змінені. Повтор exact arguments із `--verbose` — **1149/0**, rc=0, без leaks/errors; журнал `/workspace/nooneisreal-evidence/whole-body/physics-motion-cleanup-verbose.log`. Фінальний aggregate й стан публікації належать координатору.

## Related

- [[2026-10-05-Whole-Body-Motion]] · [[2026-10-05-Locomotion-States]] · [[2026-10-05-Authored-Hook-Motion]] · [[ADR-004-Physics-Is-Presentation]]
