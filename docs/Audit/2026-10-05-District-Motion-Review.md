# Рух і читабельність — незалежне приймання

2026-10-05 · T4 Феміда. **Статус: YELLOW, робота триває.** План [[2026-10-05-District-Motion-And-Readability]] прочитано; BEFORE із незмінного `git archive 6d929f8`, окрема копія `/workspace/nir-motion-review-before`. Native-докази — `/workspace/nooneisreal-evidence/district-motion/`; production/state аудитор не змінює.

## Аудит бази та мірила

Поточний до змін SkeletalRig обирає idle clip для dodging і вмикає процедурний перенос. Jump_Start/Loop/Land вже існують; новий предмет — moving landing та authored dodge. Переглянутий попередній native кадр roof_bridge показує перекриті парапетом ноги й порожній дальній горизонт. Наявність sphere SpringArm доводить лише swept collision, не читабельність героя.

| Напрям | Приймання |
|---|---|
| Dodge | Full-frame обидва справжні GLB, вперед/назад/ліво/право, ground/air; при двох yaw — правильна напрямленість. Видимі кисті/лікті/коліна/стопи й опора, без вигинів, розтягнення або завислої recovery-пози. Actual Fighter trajectory/stamina/state/RNG до й після тотожні. |
| Moving landing | Справжній стрибок і сходження з даху, рухоме приземлення й подальший gait. Стопи стикаються з поверхнею, ноги не зупиняються під час горизонтального переміщення. Hitstop, interruption й повторний seek не накопичують overlay. |
| Камера | Підтверджений BEFORE дефект; actual capsule трьох крамниць/дахів, orbit/pitch і near-body. Камера не проникає в стіни; герой/ціль читаються. InputRouter basis, grapple target/occlusion та collision sweep зберігаються. |
| Render policy | Лише активна city camera; NPC/геометрія незмінні. Нові sword/FX nodes не зависають hidden. Visible/layers/матеріали відновлюються після exit/hero/duel, shared material не забарвлює інший екземпляр. |
| Дахи й дальній фон | SAME-camera before/after center/±6м bridge, tower/north roof, market, 3 shop interiors. Парапет має стару collision-форму; checkpoints/routes/anchors лишаються. Дальня архітектура bounded, не нова прохідна територія. |
| Регресії | Попередні 60 сценаріїв, усі 14 hero/checkpoint clearance, strict logs, gates. Негативне втручання в ізольованій копії має ламати новий guard. |

## Межі

Native — Godot 4.7, Linux llvmpipe/Xvfb; це не Mac/M3, hardware FPS або фізичний геймпад. Scripts, source provenance й точні журнали будуть прив'язані до завершеного коду. Широке художнє приймання, нова доступна область та нові бойові правила не заявляються.

## Related

- [[2026-10-05-District-Motion-And-Readability]] · [[2026-10-05-District-Motion-Session]] · [[2026-10-05-District-Journey-Review]] · [[2026-10-05-Playable-District-Review]] · [[ADR-004-Physics-Is-Presentation]] · [[recurring_class_register]]
