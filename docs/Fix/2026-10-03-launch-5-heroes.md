# Fix-журнал — Запуск 5: справжні Choko і Skea замість манекена

**Роль:** T2 Гефест, 2026-10-03. **План:** [[2026-10-03-Path-to-First-Fight]] § Запуски, рядок 5;
[[2026-10-03-Picks-to-Game-and-Animation]] § C2. **Слово Santos:** «T2 Гефест: запуск 5 (скини), потім кристальна ульта, потім запуск 6».
**Статус:** зроблено в гілці `claude/friendly-ritchie-3ti2sm` від `main` `38b1597`, PR на ревʼю (Феміда — аудит, Santos — на око).

## Звірка плану з репо (до роботи)

- Ворота плану «Santos → Аполлон → Santos» уже пройдені: `ls game/assets/characters/models/` → `choko_m0.glb`, `skea_m1.glb`
  (PR #67); рядки реєстру `model-choko-m0`, `model-skea-m1` є (`grep -n choko_m0 docs/Art/Textures-Registry.md` → рядок 53).
- Скелети різні (python, glTF-JSON, скрипт у scratchpad): M-0/M-1 — `skins [24]`, імена Meshy (`Hips`, `Spine02`…`Spine`, `neck`,
  `Head`, `LeftArm`…, `LeftToeBase`, плюс `head_end`, `headfront`); UAL1/UAL2 — `skins [65]` (`pelvis`, `spine_01..03`, пальці).
  Пальців у Meshy немає — їх і не переносимо.
- Проба `godot --headless -s` (Godot `4.7.stable.official.5b4e0cb0f`): Meshy `Armature` має масштаб 0.01 (кістки в см), обидва
  скелети Y-вгору, обличчям у **+Z** (`headfront.z` > `Head.z`; UAL `ball_l.z` > `foot_l.z`), ліва рука в **+X** в обох.
  Rest Meshy — **A-поза** (`LeftArm` y 134.1 → `LeftHand` y 124.6), rest UAL — **T-поза** (`upperarm_l` → `hand_l` y 1.4408 = 1.4408).
- **Уточнення до плану, не розбіжність:** «smoke запуску 4 зелений з моделями без зміни коду» — читаю як «без зміни smoke».
  Старі 9 перевірок `--smoke-only=rig` пройшли з героями до того, як я додав нові. Сам ретаргет — код (`SkeletalRig.gd`), бо
  BoneMap у редакторі на Mac план лишав Santos, а з A-позою Meshy голий BoneMap дав би руки на ~15° нижче.

## Що зроблено

- `CharacterData.model_scene` (`@export_file`, дефолт `""` — тоді видно голий манекен); у `choko.tres` / `skea.tres` — шляхи до GLB.
- `SkeletalRig.gd`: герой — сусід манекена під тим самим `SkeletalRig`, той самий поворот +90°. Манекен грає далі, але схований:
  він джерело пози, і smoke читає саме його. Щокадру після `seek()` — `retarget()`:
  глобальний поворот кістки героя = (поворот кістки UAL відносно її rest) · вирівнювання rest · rest героя; локальний = батько⁻¹ · глобальний.
  Вирівнювання — найкоротша дуга, що кладе напрям кістки героя в rest на напрям близнюка UAL у rest (A-поза → T-поза).
  Кістки без дитини (`LeftHand`, `Head`, `*ToeBase`) беруть вирівнювання батька. Довжини кісток лишаються героя;
  рухаються лише стегна, масштабовані відношенням висоти стегон.
- Матеріал героя — той самий `toon` + чорнильний контур, що в капсул, на власній текстурі моделі. Він доданий в `animator.materials`,
  тож хіт-флеш і сірий тон time stop лягають і на героя. Ширину контуру поділено на масштаб `Armature` (0.01).
- Анімаційний плеєр самої Meshy-моделі вимкнено (`active = false`).
- Smoke (+2 перевірки): «heroes: … drawn, mannequins hidden, 22 bones retargeted each» (і тон-матеріал у списку рига);
  «hero retarget: 17 aimed bones follow the mannequin through the light, worst … ≤ 3°, hips ≤ 0.5 см» — максимум за **кожен
  кадр** легкого удару, а не один кадр.

**Предмет:** для всіх 17 кісток героя з напрямком, на кожному кадрі удару: напрям кістки героя = напрям близнюка UAL (± 3°), стегна — ± 0.5 см.

## Перевірка

| команда | результат |
|---|---|
| `make check` | `[smoke] ALL OK (114 checks) in 15957 frames`, `SMOKE ЗЕЛЕНИЙ` (було 112) |
| `make gates` | `БАТАРЕЯ ЗЕЛЕНА` |
| `godot … -- --smoke --smoke-only=rig` | `ALL OK (11 checks)`; worst `RightFoot` 0.00°, hips 0.00 см |
| `xvfb-run godot --path game --rendering-driver opengl3 -- --skeletal-rig --screenshot=<scratchpad>` | 4 кадри `[shot] … OK`; на кадрах 230 і 420 обидва герої з текстурою й контуром, у стійці й у ходьбі (не в git) |

**Негативні контролі** — тимчасова правка, `--smoke-only=rig`, повернення з копії; усі 6 червоні:

| форма зламу | що каже smoke |
|---|---|
| без вирівнювання rest (`_align = IDENTITY`) | `worst bone 'RightShoulder' 45.97°` |
| ліва/права рука переставлені | `worst bone 'LeftArm' 102.11°` |
| `retarget()` не викликається | `'LeftArm' 152.12°, hips 21.38 cm` |
| хребет зсунуто на одну кістку | `'Spine02' 38.81°` |
| стегна не рухаються (+3 см) | `hips 24.38 cm off` |
| `model_scene = ""` у Choko | `choko: no hero model` |

## Відомо / не перевірено

- **Меча в Choko немає:** у M-0 одна сітка без окремого меча; кліпи `Sword_*` махають порожньою рукою. Меч — окремий ассет (Аполлон).
- Герої 1.70 м (`get_aabb()` → 1.7), манекен 1.83 м: хітбокси від капсул не змінювались — числа Ареса.
- Пальці й вивороти кисті не переносяться (у Meshy немає кісток); перекрут передпліччя — лише з повороту `lowerarm`.
- Регдол — досі капсульний: під час польоту герой схований разом з манекеном (як у запуску 4).
- На Mac `make run-rig` з героями ніхто не грав; кадр — лише llvmpipe під Xvfb.

## Запуск 5 — що перевірити (Santos)

`make update BRANCH=claude/friendly-ritchie-3ti2sm && make run-rig`:
1. Choko і Skea у своєму дизайні замість манекена, з контуром; ходять, б'ють, реагують — ті самі кліпи, що в запуску 4.
2. Руки не «падають» у A-позу і не прокручуються в плечах; ноги стоять на землі, не пливуть.
3. Удар Choko по Skea — білий флеш на Skea; time stop — Skea сіріє.

## Related
- [[2026-10-03-Path-to-First-Fight]] · [[2026-10-03-Picks-to-Game-and-Animation]] · [[2026-10-03-launch-4-mannequin]] ·
  [[2026-10-03-launch-4-ual-source]] · [[Textures-Registry]] · [[02-Combat-System]] · [[state]]
