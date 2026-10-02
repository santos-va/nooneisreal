---
name: godot-fighting-dev
description: Як писати код гри в game/ (Godot 4.7, GDScript) — стейт-машина бійця, MoveData/CharacterData, кінематичні хітбокси, гарпун, регдол, smoke-тест, headless-перевірки. Активується на «додай удар/скіл», «зміни кадри», «баг у бою», «гарпун», «регдол», «smoke», «make check».
---

# Godot fighting dev (T2 Гефест)

## Інваріанти
- 60 Гц, цілі кадри; дані бою — `game/data/characters/*.tres` (`MoveData` саб-ресурси), не магічні числа в коді.
- Влучання — `PhysicsDirectSpaceState3D.intersect_shape` у `Fighter._check_hit`; фізика Jolt — лише `Ragdoll.gd`.
- Бійці не стикаються фізикою (`collision_mask = 1`); push-box у `_post_move`.
- Натискання читаються через `InputRouter.buffered()` **тільки** у станах, де дія можлива (буфер 6 кадрів споживається).
- CPU і тести ходять через `InputRouter.v_*` — той самий шлях, що в людини.
- Нові стани — у `Fighter.State` + поза в `RigAnimator._compute_target` + стадія в `SmokeTest`, якщо механіка критична.

## Пастки GDScript (клас №1 у реєстрі)
Приватні методи не називати як віртуали `Object/Node`: `_set`, `_get`, `_init`, `_ready`, `_process`, `_notification`,
`_input`, `_to_string`. `--check-only` не бачить автолоадів — хибне «Identifier not found: GameState» ігнорується гейтом; авторитет — smoke.

## Додати удар
1. `.tres`: новий `[sub_resource type="Resource" id="…"] script = ExtResource("2")` з полями `MoveData`; підключити в `[resource]`.
2. Поза: гілка `match anim` у `RigAnimator._attack_pose` (phase 0..3 = startup/active/recovery).
3. Якщо нова дія — інпут у `project.godot` (`p1_*`, `p2_*`, пад device 0/1) і зчитування в `Fighter._tick_ground`.
4. `make check` (import → парс → smoke) і `make gates`. Опис у `docs/GDD/02-Combat-System.md`, журнал у `docs/Meetings/`.

## Перевірки
`GODOT_BIN=… make check` · `make gates` · скриншоти: `xvfb-run godot --path game --rendering-driver opengl3 --rendering-method gl_compatibility -- --screenshot=DIR`.
«Готово» = обидва зелені + запис у `docs/Fix/` + оновлений `docs/system/state.md`.
