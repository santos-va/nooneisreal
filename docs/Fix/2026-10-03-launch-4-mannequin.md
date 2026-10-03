# Fix-журнал — Запуск 4: манекен C1 (`-- --skeletal-rig`), каркас

**Роль:** T2 Гефест, 2026-10-03. **План:** [[2026-10-03-Path-to-First-Fight]] § Запуски, рядок 4; [[2026-10-03-Picks-to-Game-and-Animation]] § C1.
**Статус:** каркас зроблено; `anim_clip` у `.tres` — **порожні**, чекають таблицю Ареса 4a (не змерджено: `git log origin/main` і гілок `ares*` немає).

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

**Не зроблено / не перевірено:**
- `anim_clip` ударів — після мержу 4a (smoke ставить тестовий `Sword_Regular_A`, 0.2 с, і повертає `light` назад). До того удари
  на манекені — стійка.
- Кадр `Sfx.play(sfx_hit)` = кадр влучання і «3 різні реакції» з § C1: зараз 2 (low = mid за GDD) — Арес у 4a.
- Пропозиція Феміди 1 (hurtbox під час splat) — чекає «так» Ареса в 4a.
- Афтерімеджі (Flash-Step, Chrono Step) лишаються капсульними — вони з `part_snapshot()`.
- Поворот +90° і вигляд у грі — лише на кадрі llvmpipe; на Mac `make run-rig` не грав ніхто. BoneMap у редакторі — запуск 5.

## Related
- [[2026-10-03-Path-to-First-Fight]] · [[2026-10-03-Picks-to-Game-and-Animation]] · [[02-Combat-System]] · [[2026-10-03-launch-4-ual-source]] · [[2026-10-03-launch-4-0-gates]] · [[state]]
