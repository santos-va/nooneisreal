# Запуск 4 — звірка після UAL Source: план повертається Дедалу

**Хто:** T2 Гефест, 2026-10-03. **Статус:** код запуску 4 **не почато** — звірка показала розбіжності плану з реальністю,
за роллю план іде назад до T1 Дедала (Santos: «Давай може з цим до дедала?»).

## Що є насправді (перевірено в цій сесії)

- **Ассети в гілці.** `git log --oneline -1 origin/assets/ual` → `77277d3 Add Quaternius UAL1 (Source) / UAL2 (Source) GLBs`;
  `git ls-tree -l -r origin/assets/ual game/assets/animations/` → `UAL1.glb` 21 378 992 B, `UAL2.glb` 20 717 364 B; у
  [[Textures-Registry]] рядки `anim-ual1`, `anim-ual2` — «Source… куплено Santos 2026-10-03», CC0. Злито в цю гілку fast-forward.
- **Тир — Source, не Standard.** Santos купив Source для обох паків. План ([[2026-10-03-Path-to-First-Fight]] рядок 4) і
  `state.md` досі кажуть «UAL1+UAL2 Standard» і гілку `assets/ual-standard`.
- **Кліпів більше, ніж у таблиці Ареса.** `python3` розбір glTF-JSON обох GLB (scratchpad `glbinfo.py`): UAL1 — 120 кліпів,
  UAL2 — 141. Кандидати на «дірки» з [[02-Combat-System]] § Кліп → удар, **0 кредитів** (вибір — Ареса, не мій):

  | дірка в таблиці | є в Source (кадри при 60 fps) |
  |---|---|
  | сальто Choko | `BackFlip` (UAL1, 116), `JogToFlip` (UAL2, 72) |
  | `light` ×3.3 / ×6.4 «смикано» | `Sword_Light_A` 22 + `_A_Rec` 30 (ближче до 8 / 9, ніж `Sword_Regular_A` 26 + 58) |
  | `heavy` без `_Rec` | `Sword_Heavy_A..C` + `_Rec` (44+60, 30+46, 42+34) |
  | `air_light` Dive Kick | `Sword_Aerial_A` 24 + `_Rec` 26, `Sword_GroundPound` 70 |
  | `sword_storm` | `Sword_UpperCut` 42, `Sword_Heavy_D` 140 |
  | `flying_knee` · `low_kick` · `roundhouse` Skea | `Melee_Knee` 52 + `_Rec` 14, `Kick` (UAL1, 66), `Melee_Uppercut` 64 |
  | реакції за зоною (§ C1: три різні) | `Hit_Head` 26, `Hit_Chest` 20, `Hit_Stomach` 40, `Hit_Knockback` 50 |
  | інше | `DoubleJump`, `NinjaJump_*`, `Dodge_Left/Right`, `KipUp` (підйом), `Death01/02`, `Sword_Block`, `Crouch_Idle_Loop` |

  Отже рішення «дірки анімацій ($) — 8 кр./кліп, 48 за 6» (RED, мало бути на запуску 4) треба переглянути: частину дір
  Source закриває безкоштовно.
- **Скелет однаковий — ретаргет на запуску 4 не потрібен.** `godot --headless -s` проба: обидва GLB —
  `Armature/Skeleton3D` з 65 кістками (UE-імена `pelvis`, `hand_r`, `thigh_l`…), `AnimationPlayer.root_node = ".."`,
  треки `Armature/Skeleton3D:<кістка>`. Бібліотеку UAL2 можна додати в плеєр манекена UAL1 як є. BoneMap →
  `SkeletonProfileHumanoid` знадобиться лише на запуску 5 (скелет Meshy інший). Манекен — 1.83 м (`get_aabb()`).
- **Імпорт:** `godot --headless --import` обох GLB — 13.7 с; `.import` з'являються поруч (у репо `.import` комітяться — 83 шт.).

## Знахідка поза запуском 4 — гейт червоніє після імпорту M-0/M-1

`godot --headless --import` на `main` (M-0/M-1 змерджено, PR #67) витягує з GLB текстури
`game/assets/characters/models/choko_m0_Image_0.jpg` і `skea_m1_Image_0.jpg`. Після цього `make gates` →
`незареєстрованих: 2`, «БАТАРЕЯ ЧЕРВОНА». Тобто на будь-якій машині `make check` → `make gates` червоні, поки ці файли не
зареєстровані або імпорт не налаштований не витягувати текстури. Я їх видалив локально (`make gates` → «БАТАРЕЯ ЗЕЛЕНА»),
у git не клав. Рішення — Аполлон (реєстр) або Гефест на запуску 5 (налаштування імпорту); Дедал вирішує, куди.

## Питання до Дедала

1. Рядок 4 плану й `state.md`: Standard → Source, `assets/ual-standard` → `assets/ual` (`77277d3`).
2. Чи віддати Аресу перегляд таблиці «Кліп → удар» під Source **до** коду запуску 4 (тоді RED-рішення про 48 кр. зникає
   чи меншає), чи Гефест робить запуск 4 на нинішній таблиці, а заміни — окремим кроком.
3. Куди знахідка з текстурами M-0/M-1: фікс до запуску 4 чи на запуск 5.

## Related
- [[2026-10-03-Path-to-First-Fight]] · [[2026-10-03-Picks-to-Game-and-Animation]] · [[02-Combat-System]] · [[Textures-Registry]] · [[2026-10-03-launch-3-printer]] · [[state]]
