# План — найкоротший шлях до нормального файту

**Дата:** 2026-10-03 · **Роль:** T1 Дедал · **Статус:** draft (чекає слова Santos про паузу побічних треків)
**Виріс із:** [[2026-10-03-First-Fight-Recap]] · [[2026-10-03-Prototype-0.3-Free-Movement]] ·
[[2026-10-03-Picks-to-Game-and-Animation]] · [[2026-10-03-Animation-Sources]] · [[2026-10-03-C2-3D-Heroes]]

## Що хоче Santos

Запустити гру, потестити і «нормально пофайтитись». Знати, що з початкового плану вже є, чого бракує і як він
сам може пришвидшити.

## Що є зараз (виміряно в цій сесії)

| що | команда | вихід |
|---|---|---|
| `main` збирається, smoke зелений | `GODOT_BIN=…/Godot_v4.7.2-stable_linux.x86_64 make check` на `ded4583` | `[smoke] ALL OK (56 checks) in 4874 frames`, `SMOKE ЗЕЛЕНИЙ`, rc=0 |
| гейти | `bash tools/gates/run_gates.sh` (з `GODOT_BIN`) | `БАТАРЕЯ ЗЕЛЕНА`, rc=0 |
| PR #48 (0.3-4 CPU у 3D + 0.3-5 річка в 3D) | `make check` у worktree на `e7540ee` | `[smoke] ALL OK (64 checks) in 6841 frames`, rc=0; PR draft, `mergeable_state: clean` |
| меню | `sed -n 56,63p game/scripts/ui/MainMenu.gd` | FIGHT P1 vs CPU · VERSUS P1 vs P2 · TRAINING · вибір бійців · арена · профіль клавіш · QUIT |
| 3D-режим | `grep -n free-move game/scripts/core/Main.gd` | лише прапорець запуску `-- --free-move`; **кнопки в меню немає**, `make run` його не передає |
| клавіші 3D | `grep -n 'TODO #26' game/scripts/core/InputRouter.gd` | тимчасові: W/S = обхід (#26 Гермеса не зроблено) |
| тіла | `find game -name '*.glb' \| wc -l` | `0` — бійці досі капсули; 3D Choko M-0 і Skea M-1 є лише в Higgsfield |
| моделі в завантажувачі | `grep -nE '2488e146\|f7f95324' tools/fetch_assets.sh docs/Art/Textures-Registry.md` | порожньо — URL ще не внесено |
| числа бою | `git log --oneline -2 -- game/data/characters/choko.tres` | `79388d1` числа Ареса, `31a59e1` кадри з джерел; описи в `.tres` досі кажуть «PLACEHOLDER» (борг) |
| звук | `git merge-base --is-ancestor cbb7f97 origin/main` | бібліотека SFX у `main`; `ls game/assets/audio/sfx/*.ogg \| wc -l` → 40 |

**Не перевірено ніким:** гра на Mac після змін 0.2 → 0.3 (лише headless у хмарі). Це головна дірка.

## Три рівні «нормального файту»

| рівень | що це | де зараз |
|---|---|---|
| **Р0** — 2.5D-бій капсулами | легкий/важкий/присід/повітря, 2 скіли, ульта, блок, деш, гарпун на 3 зарядах, регдол, CPU, тренування, 2 арени (річка, провулок) | **є в `main`**, грається вже сьогодні |
| **Р1** — 3D-дуель як у Storm, на капсулах | вільний рух, lock-on, камера дуелі, гарпун і скіли в 3D, CPU обходить, річка в 3D | 0.3-1…0.3-3 у `main`; 0.3-4 і 0.3-5 — PR #48; бракує клавіш (#26), кнопки режиму, 0.3-6/0.3-7 |
| **Р2** — живі тіла з анімацією | манекен із кліпами → справжні Choko і Skea на тому самому скелеті | C1 вільний, не почато; моделі згенеровано, не завантажено |

## Кроки

Позначка **[S]** — крок, який може зробити лише Santos. Кожен крок Гефеста закінчується `make check` → рядок
`[smoke] ALL OK (N checks)` і `make gates` → rc=0.

| # | хто | що змінюємо | ризик | як перевіряється |
|---|---|---|---|---|
| П1 | **[S]** | нічого в коді: зіграти на Mac `main` в обох режимах, 5 рядків відгуку в santos-va/nooneisreal#27 | відгук запізниться → Гефест тюнить наосліп | коментар Santos у #27; команди — § Як запустити |
| П2 | T2 Гефест → **[S]** | PR #48 з draft у ready; Santos мерджить | регрес площинного режиму | `make check` → `ALL OK (64 checks)` (виміряно на `e7540ee`); Santos — `make update && make run` |
| П3 | T8 Гермес · #26 | `docs/GDD/05-Platforms-Input.md` § Вільний рух, ADR-014; **плюс рядок у `docs/GDD/06-UI-UX.md`:** перемикач «РЕЖИМ 2.5D / 3D» у меню | конфлікт клавіш у SHARED; ламаємо ADR-009 | `bash tools/gates/run_gates.sh` → rc=0; таблиця без жодної клавіші на двох діях |
| П4 | T2 Гефест · #27 | `InputRouter.gd` (клавіші з ADR-014, прибрати `TODO #26`), `MainMenu.gd` + `GameState.gd` (кнопка режиму, збереження в `user://settings.cfg`) | порядок у `GameState.gd` з #12 і #7 | smoke: кнопка → `free_move=true`, камера дуелі `current`; старий рядок «no key clashes» зелений з новими клавішами |
| П5 | T2 Гефест · #27 | C1: `game/scripts/fighter/SkeletalRig.gd`, `MoveData.gd` (`anim_clip`, `contact_time`), манекен UAL1+UAL2 Standard (CC0) у `game/assets/` + рядки [[Textures-Registry]]; за прапорцем `skeletal_rig` | регрес капсул; BoneMap без перевірки в редакторі | за [[2026-10-03-Picks-to-Game-and-Animation]] § C1; Santos дивиться на Mac (BoneMap, «Except Bone Transform» вимкнено) |
| П6 | T5 Арес · #36 | C3: мапа кліп → удар у `choko.tres` / `skea.tres`; описи «PLACEHOLDER frame data» → реальний стан | кліп довший за `startup+active+recovery` | `bash tools/gates/run_gates.sh` → rc=0; `grep -c 'PLACEHOLDER frame data' game/data/characters/*.tres` → 0 |
| П7 | **[S]** → T6 → **[S]** → T2 | Santos: «M-0, M-1 — так»; T6: URL і рядки реєстру в `tools/fetch_assets.sh`, `docs/Art/Textures-Registry.md`; Santos на Mac: `make fetch-assets`; Гефест: моделі замість манекена | CDN закритий для хмари (403) — без Mac не завантажити | `make gates` → РЕЄ `незареєстрованих: 0`; smoke C1 зелений із новими моделями без зміни коду |
| П8 | T2 Гефест → T4 Феміда → **[S]** | 0.3-6 (обидва режими + детермінізм у `SmokeTest.gd`), вердикт у `docs/Audit/`; Santos: «free_move за замовчуванням» → `true` окремим комітом | відчуття не те | вердикт без RED; слово Santos у #27 |

**Порядок.** П1 і П3, П6 — паралельно, зараз. П2 — щойно Гефест зніме draft. Гефест далі: **П5 (C1) раніше за П4**,
бо C1 не чекає ні на кого, а П4 чекає Гермеса. П7 — коли Santos подивиться моделі (чекає з C2). П8 — останнім.

**Одночасно не більше трьох терміналів, що пишуть код або state.md:** Гефест (один), Гермес, Арес. Два Гефести
поспіль у `Fighter.gd` / `RigAnimator.gd` дадуть конфлікти.

## Що ставимо на паузу до Р1 (рекомендація Дедала, вирішує Santos)

Меню-діорама (#4, #6, #7, #8), вибір персонажа на даху (#11), перейменування Cronshift (#12), нові партії одягу
й стікерів, шейдери D3, тканина D4, сюжет. Жоден із них не потрібен, щоб битися. Плюс: #12 і #7 правлять
`GameState.gd` — той самий файл, що П4. Мінус: меню лишається плейсхолдерним довше.

**Рішення про анімаційні дірки** (сальто, удар ногою — $9.99 / $14.99 / Meshy 8 кр.) — **відкласти** до показу
манекена П5: C1 стартує на безкоштовному Standard, а що саме бракує в русі, видно лише в грі.

## Як запустити (Mac)

```bash
cd ~/nooneisreal            # шлях до клону — твій
git checkout main
make update                 # оновити й переімпортувати
make run                    # меню → FIGHT / VERSUS / TRAINING; 2.5D
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT_BIN" --path game -- --free-move   # те саме меню, але бій у 3D (W/S — обхід, тимчасово)
```

Після мержу PR #48 — ще раз `make update`, у 3D з'являться CPU, що обходить, і річка під ногами.

## Стартові повідомлення для паралельних сесій (скопіюй Santos)

- **T8** — «T8 Гермес. Візьми santos-va/nooneisreal#26 за [[2026-10-03-Path-to-First-Fight]] П3: розкладка вільного руху + ADR-014 + рядок про перемикач режиму в 06-UI-UX.»
- **T5** — «T5 Арес. santos-va/nooneisreal#36, C3 за [[2026-10-03-Path-to-First-Fight]] П6: кліпи UAL до ударів і чесні описи в `.tres`.»
- **T2** (після П2) — «T2 Гефест. C1 манекен за [[2026-10-03-Path-to-First-Fight]] П5, потім П4, коли Гермес закриє #26.»
- **T6** (після «так» на моделі) — «T6 Аполлон. П7: M-0 `2488e146` і M-1 `f7f95324` у `fetch_assets.sh` і реєстр.»

## Related
- [[state]] · [[Roadmap]] · [[2026-10-03-First-Fight-Recap]] · [[2026-10-03-Prototype-0.3-Free-Movement]] ·
  [[2026-10-03-Picks-to-Game-and-Animation]] · [[2026-10-03-Animation-Sources]] · [[2026-10-03-C2-3D-Heroes]] ·
  [[05-Platforms-Input]] · [[06-UI-UX]] · [[Textures-Registry]]
