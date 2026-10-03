# Fix-журнал — Запуск 4: манекен C1 (`-- --skeletal-rig`), каркас

**Роль:** T2 Гефест, 2026-10-03. **План:** [[2026-10-03-Path-to-First-Fight]] § Запуски, рядок 4; [[2026-10-03-Picks-to-Game-and-Animation]] § C1.
**Статус:** зроблено — каркас, потім кліпи з таблиці 4a (PR #85 → `68fb03b`, змерджено під час PR #86) і жовті пункти аудиту
Феміди `docs/Audit/2026-10-03-Launch-4.md` (santos-va/nooneisreal#81).

## Звірка плану з репо (до роботи)

- `main` `300634e` (4-0 змерджено, PR #82, #83). Godot `4.7.stable.official` у контейнері є.
- UAL1/UAL2 Source у `game/assets/animations/ual/`, рядки реєстру `anim-ual1/2` є. Проба `godot --headless` (scratchpad `ual.gd`):
  обидва GLB — `Armature/Skeleton3D` 65 кісток (`root`, `pelvis`, `spine_01..03`, `Head`, пальці, `ball_l/r`), `AnimationPlayer`
  з однією бібліотекою `""`, `root_node = ".."`, треки `Armature/Skeleton3D:<кістка>`; AABB 1.83 м.
- **Розбіжність із GDD (не з планом):** імпортер Godot прибирає суфікс `_Loop` і сам вмикає луп: у плеєрі `Idle` (loop 1, 2.5 с),
  `Walk`, `Jog_Fwd`, а не `Idle_Loop`. GDD 02 пише GLB-назви — лишаю їх, код мапить (`SkeletalRig.clip_name()`).
- Модель дивиться в **+Z** (`ball_r` z 0.113 > `foot_r` z −0.036), капсульний риг і `hitbox_offset` — у **+X** → поворот на +90°.
- `RigAnimator.setup()` робить `queue_free()` усім дітям — тому манекен не дитина `Rig`, а сусідній вузол бійця.
- `part_snapshot()` (регдол, афтерімеджі) і `pose` (smoke) — з капсульного рига: план каже «регдол поки капсульний» → капсульний
  риг лишається і тікає, лише його меші сховані.

## Що зроблено

- `game/scripts/fighter/SkeletalRig.gd` (новий): манекен UAL1 + бібліотека UAL2 під `ual2/` в одному `AnimationPlayer`
  (без ретаргету). Плеєр у ручному режимі; `_physics_process` (іде після `Fighter`, батько першим) ставить позу через
  `seek(t, true)` — поза є чистою функцією лічильників бійця: детерміновано. Видимість і yaw дзеркалить з `animator`
  (сховався капсульний — сховався манекен: Shadow Veil, регдол). Time stop / hitstop — тримає кадр.
- Кліпи станів — `STATE_CLIPS` з GDD 02 § «Спільні стани» (Арес). HITSTUN low кліпа в GDD немає → поки `Hit_Chest` (= mid).
- Атака: `attack_clip_time()` — startup мапиться 0 → `contact_time` (поза контакту рівно на першому `active`), далі до кінця
  кліпу за active + recovery; без заміряного `contact_time` кліп іде на startup + active (правило GDD 02).
- `MoveData.anim_clip`, `MoveData.contact_time`, `CharacterData.idle_clip` (дефолт `Idle_Loop`; Choko `Sword_Idle` — з 4a).
- `GameState.skeletal_rig = false`; `-- --skeletal-rig` через `Main.apply_launch_args`; `make run-rig`.
- Smoke: стадії 110–112 — та сама арена з `skeletal_rig = true` після всіх старих; `--smoke-only=rig` для швидкого прогону.
  Таймаут smoke 14000 → 15000 кадрів (`--quit-after 20000` у `Makefile` не чіпав).

## Перевірка

- `make check` → `[smoke] ALL OK (101 checks) in 13666 frames`, `SMOKE ЗЕЛЕНИЙ`; GDS `перевірено: 37 · не парсяться: 0`.
  Старі 95 перевірок — без змін і з `skeletal_rig = false` (детермінізм 0.3-6 теж); нові: 2 на завантаження арени + 4 манекена.
- `bash tools/gates/run_gates.sh` → ВІК 0 зламаних, РЕЄ 88/88, `БАТАРЕЯ ЗЕЛЕНА`.
- Кадр: `xvfb-run godot --rendering-driver opengl3 -- --skeletal-rig --screenshot=…` → `docs/assets/screenshots/2026-10-03-launch-4-mannequin.png`
  (llvmpipe, кадр 230: два манекени на річці, капсул немає).

**Негативний контроль** (scratchpad `nc2.sh`, `--smoke-only=rig`; R8 — повний smoke). 10 / 10 червоні:

| # | злам | результат |
|---|---|---|
| R1 | контакт на кадр раніше (`startup + 1`) | `FAIL attack_clip_time: … first active → 0.222 … (want … 0.25 …)` |
| R2 | `contact_time` ігнорується | `FAIL attack_clip_time: … first active → 0.727` |
| R3 | `seek` прибрано | `FAIL mannequin idle is frozen: spine_02 unchanged over 40 frames` |
| R4 | зона флінчу ігнорується | `FAIL mannequin hit high: clip 'Hit_Chest', want 'Hit_Head'` |
| R5 | видимість не дзеркалиться | `FAIL mannequin during ragdoll: visible true (capsule rig visible false)` |
| R6 | капсули не сховано | `FAIL mannequin: 13 capsule meshes still drawn` |
| R7 | `_Loop` не мапиться | `FAIL mannequin idle: clip '', want '' (Idle_Loop)` |
| R8 | манекен будується завжди | `FAIL capsule mode built a SkeletalRig — skeletal_rig is off by default` |
| R9 | прапорець `--skeletal-rig` ігнорується | `FAIL Main.apply_launch_args(["--skeletal-rig"]) left skeletal_rig false` |
| R10 | дефолт `skeletal_rig = true` | `FAIL Main.apply_launch_args(["--plane"]) left skeletal_rig true` |

Предмет: для всіх станів бійця з `skeletal_rig` — манекен грає кліп стану з GDD 02, поза контакту атаки — на першому `active`,
видимість = видимість капсульного рига; без прапорця — манекена немає.

**Не зроблено / не перевірено** (оновлено після 4a — нижче):
- Шар `crouch_light`, вибір `Dodge_Left/Right`, ланцюг Skea на манекені в smoke не ганяю (лише light Choko), удар у splat.
- Афтерімеджі (Flash-Step, Chrono Step) лишаються капсульними — вони з `part_snapshot()`.
- Поворот +90° і вигляд у грі — лише на кадрі llvmpipe; на Mac `make run-rig` не грав ніхто. BoneMap у редакторі — запуск 5.

## Після 4a і аудиту Феміди (YELLOW: low = mid, кадр звуку не перевірено)

- `git merge origin/main` → таблиця 4a: [[02-Combat-System]] § Кліп → удар (Арес), кліпи лише в описах `.tres`.
- **Поля:** `MoveData.anim_clip_rec` (пара «атака + `_Rec`»: перший на startup + active, `_Rec` на recovery), `anim_clip_chain(_rec)` +
  `contact_time_chain` (непарні удари ланцюга, як `anim_chain`); `CharacterData.dash_clip`, `getup_clip`. Без `_Rec` кліп цілий на весь удар
  («цілий на N» у таблиці = s+a+r).
- **Значення в `.tres`** — переписані з таблиці 4a: Choko — `Sword_Idle`, `Roll`, `LayToIdle`; light `Sword_Light_A`+`_Rec` / ланцюг
  `Sword_Light_B`+`_Rec`; heavy `Sword_Heavy_C`+`_Rec`; air `Sword_Aerial_A`+`_Rec`; ульта `Sword_Heavy_D` цілий; гарпун `OverhandThrow`.
  Skea — `Idle_Loop`, `KipUp`; light `Punch_Jab` цілий / ланцюг `Melee_Hook`+`_Rec`; roundhouse `Kick`; flying_knee `Melee_Knee`+`_Rec`;
  kunai_rain і гарпун `OverhandThrow`. Порожні (за таблицею): RigA-скіли (`record`, `time_stop`, `shadow_veil`, `cursed_grimoire`),
  дірка `low_kick`, **`crouch_light` Choko — «шар» (низ + верх, `AnimationTree` R4) не зроблено**, поки стійка.
  Skea DASH: у таблиці `Dodge_Left / Dodge_Right` — взяв `Dodge_Right` (одне поле), вибір за напрямком — не зроблено.
- **`contact_time` заміряно скриптом** (scratchpad `contact.gd`): кадр за кадром (1/60 с) — найбільший виніс ударної кістки вперед (+Z моделі),
  поза з локальних поз кісток (`get_bone_global_pose` у `-s` скрипті не оновлювався — перша спроба дала 0 скрізь, відкинув).
  Ударна кістка — та з пари, що виноситься далі: `Sword_Light_A` hand_r 0.233 с · `_Light_B` 0.233 · `_Heavy_C` 0.483 · `_Aerial_A` 0.233 ·
  `OverhandThrow` 0.383 · `Punch_Jab` hand_l 0.200 · `Melee_Hook` hand_r 0.267 · `Kick` ball_r 0.517 · `Melee_Knee` calf_r 0.533.
  `Sword_Heavy_D` (ульта, 2.33 с, кілька замахів) — без контакту, лінійно. **На око ніхто не підтверджував.**
- HITSTUN low → `Hit_Stomach` (таблиця 4a): три різні реакції.
- `Sfx.last_frame` — фізкадр останнього `play()`; smoke: Skea за 1 м, light влучає, `hit_light` зіграно рівно на кадрі влучання.
- Пропозиція Феміди 1: у стадії splat `hurt_shape.disabled == false` (GDD 02:116). Удар нападника на 2–5 кадрі splat — **не перевіряю**.
- `make check` → `[smoke] ALL OK (101 checks) in 13685 frames` (лічильник той самий: перевірки розширено всередині рядків); батарея зелена.
- Кадр з ударом: `docs/assets/screenshots/2026-10-03-launch-4-mannequin-attack.png` (llvmpipe, кадр 330). Куди дивиться Skea — з кадру не певен.

| # | злам | результат |
|---|---|---|
| S1 | `hit_low` → `Hit_Chest` | `FAIL … 2 different reactions (want 3)` |
| S2 | `_Rec` ігнорується | `FAIL mannequin attack recovery plays 'ual2/Sword_Light_A', want 'Sword_Light_A_Rec'` |
| S3 | `Sfx.play(m.sfx_hit)` прибрано | `FAIL mannequin hit sound: 'hit_light' last played on frame -1, the hit landed on 132` |
| S4 | звук на кадр пізніше | `FAIL … last played on frame 133, the hit landed on 132` |
| S5 | `Sword_Heavy_X` у `.tres` | `FAIL choko: clip 'Sword_Heavy_X' from the .tres is not in UAL1/UAL2` (перша спроба червоніла не з тієї причини — виправив порядок перевірок) |
| S6 | `contact_time` 0.9 > довжини | `FAIL choko heavy: contact_time 0.900 past the end of 'Sword_Heavy_C'` |
| S7–S9 | = R1–R3 на новій сигнатурі | червоні (`first active → 0.222` / `0.727`; `idle is frozen`) |
| S10 | `idle_clip = "Idle_Lop"` | `FAIL skea: clip 'Idle_Lop' …` |
| S11 (= NC8) | `hurt_shape.disabled = true` у `_wall_splat` | `FAIL wall splat: hurtbox disabled during the splat` |

## Related
- [[2026-10-03-Path-to-First-Fight]] · [[2026-10-03-Picks-to-Game-and-Animation]] · [[02-Combat-System]] · [[2026-10-03-launch-4-ual-source]] · [[2026-10-03-launch-4-0-gates]] · [[state]]
