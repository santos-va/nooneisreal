# Рух і читабельність кварталу

2026-10-05 · T1 · **Статус: approved**. Пряме продовження Santos після merged PR #176, main `6d929f8`. Журнал [[2026-10-05-District-Motion-Session]]. Підстава — [[ADR-004-Physics-Is-Presentation]], [[ADR-023-City-First-Exploration]]; нових бойових правил немає.

## Аудит і погляди

Перевірено в актуальному source: `SkeletalRig` обирає idle/процедурне перенесення для dodge; `DodgeMotion` задає кути через sin(progress), хоча UAL1 уже містить `Dodge_Left/Right`. `AuthoredLocomotion` допускає `Jump_Land` лише при speed≤STOP_SPEED; moving landing переходить одразу до gait. Старт стрибка й Sprint переходи вже реалізовані та не створюються повторно. Native попереднього приймання показує порожній дальній горизонт, а ближній парапет перекриває ноги героя на даху. CityCamera уже має SpringArm collision: будь-який її дефект спершу треба фізично відтворити, не припускати відсутність collision.

Варіанти: (1) ще більше процедурних поз без використання бібліотеки; (2) заміна rig/physics/світу новим пакетом; (3) інтеграція наявних authored dodge/landing у чинний retarget, окреме виправлення доведених camera occlusion і обмежена фонова архітектура. Обрано третій: локальний перевірюваний результат без нових покупок і перебудови механік.

Погляди: активний гравець бачить напрям ухилення; гравець із мотузкою не отримує змінену траєкторію; Choko з мечем потребує clearance рук/зброї; Skea з іншими пропорціями потребує окремої перевірки колін/стоп; дослідник на даху має бачити героя та читати продовження міста; власник слабкого пристрою не отримує необмежену геометрію; тестувальник відділяє native visual від Linux FPS і реального M3.

## Роботи, ризики й приймання

1. **T2 motion:** `SkeletalRig.gd`, `AuthoredLocomotion.gd`, новий bounded presentation helper за потреби. Адаптувати наявні Dodge_Left/Right до реального напрямку й progress, перевірити ground/air та входи/виходи. Додати короткий authored контакт приземлення під час руху зі збереженням gait. Ризики: спотворення анатомії, foot sliding, sword clearance, stale overlays. Приймання: обидва герої, чотири напрями, ground/air, running landing/roof drop; native повні послідовності й before/after, контроль незмінних траєкторій/stamina/timing. Не міняти Fighter gameplay.
2. **T2 camera:** `CityCamera.gd` лише після native reproduction. Перевірити pivot/near-plane/collision біля трьох крамниць, парапетів і відновлення checkpoint. Ризик: penetration, input basis/orbit зміниться. Приймання: геометричні swept-volume/LOS міри, native before/after, збережений orbit та ціль мотузки. Якщо дефект не підтвердиться — не робити косметичний rewrite.
3. **T6 world:** `CityDistrict.gd`, окремий environment helper за потреби. Фонова архітектура за чинними межами, масштаб/силует з наявної palette; жодних нових прохідних областей або обіцянки нового району. Ризик: перекриття маршрутів/опор, visual clutter, зайві draw calls. Native ground/roof/market before-after, bounded node count, незмінні gameplay collision/landmarks. Геометричні ресурси без нових game/assets; paid generation і зміна ліцензій не потрібні.
4. **T4:** незалежна перевірка анатомії/цілої послідовності, камерних метрик, фонового масштабу, усіх старих регресій; `make check-playable`, `make gates`, релевантні negative probes. Нові тестові сценарії ізолюють save. PR до main без self-merge; native M3/фізичний controller не заявляються.

## Контракти смуг

Motion володіє fighter presentation, camera — CityCamera, art — CityDistrict/новим фоновим модулем. Ніхто не змінює файли іншої смуги без узгодження. У shared checkout одночасно один Godot; агенти повторно використовують ізольовані копії й бережуть дисковий бюджет. Root координує документи/інтеграцію/коміти. Версія наступного пакета 0.4.2 після приймання. Іконка чекає саме PNG Santos, ніякої підміни.

## Related

- [[2026-10-05-District-Motion-Session]] · [[2026-10-05-District-Journey-Checkpoint]] · [[2026-10-05-Locomotion-States]] · [[2026-10-05-Authored-Combat]] · [[2026-10-05-Playable-District-Art]] · [[state]]
