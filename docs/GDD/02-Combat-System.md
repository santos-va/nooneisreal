# 02 — Система бою

Власник: T5 Арес. Реалізація: `game/scripts/fighter/Fighter.gd`, дані — `game/data/characters/*.tres`.
Усі числа нижче — `PLACEHOLDER` до тестів на Mac і інтерв'ю.

## Такт і детермінізм

- 60 фізичних кадрів/с (`physics/common/physics_ticks_per_second=60`). Усі таймінги — в кадрах.
- Хітбокси — кінематичні запити `PhysicsDirectSpaceState3D.intersect_shape` на такті, не сигнали Area3D (без затримки в 1 кадр і без недетермінованого порядку).
- Бійці — `CharacterBody3D`; між собою фізикою не стикаються — push-box розводимо вручну (`MIN_SEPARATION` 0.95 м).
- Фізика (Jolt) — лише регдол і пропси. [[ADR-004-Physics-Is-Presentation]]

## Стани

`INTRO · IDLE · WALK · CROUCH · JUMP · DASH · ATTACK · BLOCK · HITSTUN · BLOCKSTUN · LAUNCHED (регдол у польоті) · KNOCKDOWN · GETUP · GRAPPLE · KO`

## Дії (один мувсет для всіх пристроїв)

| дія | клавіатура P1 | опис |
|---|---|---|
| Рух / присід / стрибок | A D / S / W, Space | назад повільніше (back_walk_speed) |
| Легкий | F | швидкий, ланцюжок ×3 (light → light → heavy/skill) |
| Важкий | G | повільніший, крок уперед, скасовується у скіли/ульт |
| Блок | LShift (утримання) | лицем до нападника; чіп-дамаг тільки від важких/скілів |
| Деш | C | 12 кадрів; бекдеш має 6 кадрів невразливості; з деша — атака |
| Скіл 1 / Скіл 2 | Q / E | кулдаун у секундах; можуть вартувати метр |
| Ультимейт | V | потребує 100 метру |
| Гарпун | R (S+R = підтягнути ворога) | 3 заряди, див. [[04-Grapple-System]] |

## Кадри (модель `MoveData`)

`startup · active · recovery · damage · chip · hitstun · blockstun · hitstop · knockback(x, y) ·
launcher · knockdown · effect("freeze") · hitbox_offset/size · meter_gain · cooldown · forward_step · cancel_tier`

Приклад (Choko, PLACEHOLDER): легкий 5/3/9 кадрів, 42 дамаг, hitstun 14, blockstun 8, hitstop 4;
важкий 11/4/17, 95, hitstun 20, hitstop 7, knockback (6.5, 2.0).

## Правила влучання

- Блок: стан BLOCK/BLOCKSTUN і `facing == -attacker.facing`; кидки (`Kind.THROW`) не блокуються.
- Комбо-скейлінг: кожен наступний удар у комбо −10 % дамагу (мін. 35 %).
- Launcher/knockdown/удар у повітрі → регдол із імпульсом `knockback * ragdoll_impulse / weight`;
  поки летить — невразливий (щоб не було нескінченних жонглювань); встає з 26 кадрами невразливості.
- `effect = "freeze"` (TIME STOP Choko): стан 45+ кадрів без нокбеку, без дамагу.
- Метр: +8 за влучання (×0.5 жертві), +3 за блок; 100 = ульт.

## Скасування (cancel_tier)

0 легкий → 1 важкий → 2 скіли → 3 ульт: після влучання можна скасувати в дію вищого рівня.

## Раунди

Best of 3, 99 с; KO або тайм-аут; slow-mo 0.4× на 30 кадрів після KO; тренування — безкінечний
таймер і автолікування нижче 40 %.

## Відкриті питання (до інтерв'ю)

- Низькі/верхні удари (хай/лоу-блок)? Кидок окремою кнопкою чи лишити гарпун-підтягування?
- Чи має ульт бути кат-сценою (Storm) чи ігровим ударом?

## Related
- [[03-Skills-Framework]] · [[04-Grapple-System]] · [[05-Platforms-Input]] · [[Active-Ragdoll]] · [[Glossary]]
