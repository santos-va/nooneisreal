# 2026-10-03 — Арес: 4a, таблиця «кліп → удар» під UAL Source

**Роль:** T5 Арес · **Завдання:** `state.md`, черга T5 (1) 4a · [[2026-10-03-launch-4-ual-source]] · [[2026-10-03-Fight-Craft-Research]] § Відкриті анімації

## Що обговорили
- Santos: «T5 привіт (4a)».
- Довжини кліпів заміряно в цій сесії розбором glTF-JSON `UAL1.glb`/`UAL2.glb`: max `input` accessor × 60. Цифри збіглися з виміром Гефеста.
- Кадри руху взято з `.tres` через `awk`.

## Що вирішили
- [[02-Combat-System]] § Кліп → удар переписано під Source, позначки Src / Src≈ / шар / RigA / дірка $.
- Choko:
  - light → `Sword_Light_A`: ×2.75/×3.3, було ×3.3/×6.4.
  - heavy → `Sword_Heavy_C` + `_Rec`: ×2.8/×2.0.
  - crouch_light → шар із двох кліпів.
  - air_light → `Sword_Aerial_A`, рух перейменовано **Dive Cut**.
  - sword_storm → `Sword_Heavy_D` ×1.5.
  - сальто → `BackFlip`.
- Skea:
  - roundhouse → `Kick` ×2.0.
  - flying_knee → `Melee_Knee`: ×4.7, ризик.
  - DASH → `Dodge_L/R`.
  - підйом → `KipUp`.
- Спільне: HITSTUN low → `Hit_Stomach`.
- Дірок лишилась одна, `low_kick`: Higgsfield 217. RED падає з 48 до 8 кр. Ціну тут не перевірено.
- Пропозиція 5 Феміди:
  - `hook_pull` позначено як слот `throw`, tracking і backhit 0 → закриває п. 15.
  - hurtbox під час splat **увімкнений**, одне добивання дозволено. Smoke-рядок під це додає Гефест (п. 6).
- `.tres`: змінено лише `description` (Clip) і `display_name` air_light Choko. Числа кадрів не чіпав.

## Що відкладено
- Чи ляже кліп на вигляд, вирішуємо на запуску 4 в редакторі (Арес + Santos).
- Розподіл прискорення по фазах — R2 (Гефест).
- Генерація 217 — тільки слово Santos + `get_cost` (T6).

## Related
- [[02-Combat-System]] · [[03-Skills-Framework]] · [[2026-10-03-launch-4-ual-source]] · [[2026-10-03-Fight-Craft-Research]] · [[Choko]] · [[Skea]] · [[state]]
