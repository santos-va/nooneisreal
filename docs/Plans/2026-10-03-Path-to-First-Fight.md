# План — найкоротший шлях до нормального файту

**Дата:** 2026-10-03 · **Роль:** T1 Дедал · **Статус:** approved (Santos 2026-10-03: «так, ставимо на паузу… покроково, тести на кожен запуск»)
**Виріс із:** [[2026-10-03-First-Fight-Recap]] · [[2026-10-03-Prototype-0.3-Free-Movement]] ·
[[2026-10-03-Picks-to-Game-and-Animation]] · [[2026-10-03-Animation-Sources]] · [[2026-10-03-C2-3D-Heroes]] ·
[[2026-10-03-Ares-Printer-Items]]

## Що хоче Santos

Запустити гру, потестити і «нормально пофайтитись». Іти покроково: кожен крок закривається тестами, і кожен новий
запуск гри оформлюється окремо, з переліком нових деталей, які треба перевірити. Термінал ролі, якому Santos каже
«привіт», сам знаходить своє завдання в черзі [[state]].

## Що є зараз (виміряно в цій сесії)

| що | команда | вихід |
|---|---|---|
| `main` збирається, smoke зелений | `GODOT_BIN=…/Godot_v4.7.2-stable_linux.x86_64 make check` на `37e6fb5` (+ лише docs цього плану) | `[smoke] ALL OK (64 checks) in 6841 frames`, `SMOKE ЗЕЛЕНИЙ`, rc=0 |
| гейти | `bash tools/gates/run_gates.sh` (з `GODOT_BIN`) | `БАТАРЕЯ ЗЕЛЕНА`, rc=0 |
| 0.3-4 і 0.3-5 | `git log --oneline origin/main` | PR #48 змерджено (`5bdd257`): CPU у 3D обходить, річка в 3D |
| меню | `sed -n 56,63p game/scripts/ui/MainMenu.gd` | FIGHT P1 vs CPU · VERSUS P1 vs P2 · TRAINING · вибір бійців · арена · профіль клавіш · QUIT |
| 3D-режим | `grep -n free-move game/scripts/core/Main.gd` | лише прапорець запуску `-- --free-move`; **кнопки в меню немає** |
| клавіші 3D | `grep -n 'TODO #26' game/scripts/core/InputRouter.gd` | тимчасові: W/S = обхід; присіду й підтяжки з SOLO немає |
| пасивка Choko | `grep -n passive_id game/data/characters/choko.tres` → `"printer"`; `grep -rn printer game/scripts` → порожньо | **Choko зараз без пасивки**: дані перемкнув Арес (PR #50), коду ще немає |
| тіла | `find game -name '*.glb' \| wc -l` | `0` — капсули; 3D Choko M-0 і Skea M-1 є лише в Higgsfield |
| моделі в завантажувачі | `grep -nE '2488e146\|f7f95324' tools/fetch_assets.sh docs/Art/Textures-Registry.md` | порожньо |

**Не перевірено ніким:** гра на Mac після змін 0.3 — лише headless у хмарі.

## Протокол запуску (однаковий для кожного)

1. **Гефест** — одна гілка й один PR від свіжого `main` на запуск, **не draft**. В описі PR — розділ
   «Запуск N — що перевірити» (перелік із таблиці нижче). `make check` → `[smoke] ALL OK (N checks)` з новими
   перевірками й негативним контролем, `make gates` → rc=0. Наступний запуск — лише після мержу попереднього.
2. **Феміда** — вердикт `docs/Audit/2026-10-03-Launch-N.md`: перепрогнати обидві команди у своїй сесії, звірити
   чекліст запуску. RED → назад Гефесту, мержу немає.
3. **Santos** — мерджить, `make update && make run`, проходить чекліст і пише один коментар в issue запусків:
   «Запуск N: працює / не так …».
4. **Дедал** — на «T1 привіт» читає відгук і зсуває чергу в [[state]].

Godot у хмарі (перевірено 2026-10-03): `curl -sL -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip && unzip g.zip`
у scratchpad, далі `GODOT_BIN=<шлях> make check`.

## Запуски

| запуск | хто | що змінюємо | ризик | автотест | Santos перевіряє в грі |
|---|---|---|---|---|---|
| **1** — `main` зараз | Santos; Феміда — базовий вердикт | нічого | — | `make check` → `ALL OK (64 checks)` | 2.5D: FIGHT / VERSUS / TRAINING на річці й провулку, удари, скіли, ульти, гарпун (3 заряди), регдол, звук. 3D (`-- --free-move`): обхід W/S, камера дуелі, гарпун у конусі, скіли в 3D, CPU обходить, хвилі по колу. **Відомо:** Choko без пасивки, капсули, присіду в 3D немає |
| **2** — пасивка Printer | Гефест | нода друку й підбору для `passive_id = "printer"` за [[03-Skills-Framework]] і [[2026-10-03-Ares-Printer-Items]]; прибрати `_perfect_block` (`Fighter.gd`); id `grimoire_page*` → нові назви (`GrimoireFx.gd`); стікер — плейсхолдер-квад, арт на паузі | регрес Chrono Guard у smoke; стікер у 3D за спиною не там | smoke: стікер на 8-й с, 1.5 м позаду, живе 8 с, максимум 1; суперник рве; підбір дає ефект черги | стікер з'являється за Choko, підбирається, Skea його рве; ефект відчутний |
| **3** — манекен C1 | Гефест | [[2026-10-03-Picks-to-Game-and-Animation]] § C1: `SkeletalRig.gd`, `MoveData.gd` (`anim_clip`, `contact_time`), UAL1+UAL2 Standard (CC0) у `game/assets/` + рядки [[Textures-Registry]]; прапорець запуску `-- --skeletal-rig`; кліпи — з таблиці Ареса (#36), до неї — кандидати [[2026-10-03-Animation-Sources]] §8 п. 2 | регрес капсул; BoneMap не перевірений у редакторі | § C1: кадр контакту = перший `active` ±1, кадр звуку = кадр влучання, 3 різні реакції | у редакторі на Mac: BoneMap → `SkeletonProfileHumanoid`, «Except Bone Transform» вимкнено; у грі — удар, звук і реакція збігаються |
| **4** — клавіші 3D і кнопка режиму | Гермес (#26) → Гефест | Гермес: [[05-Platforms-Input]] § Вільний рух, ADR-014, рядок у [[06-UI-UX]] про кнопку «РЕЖИМ 2.5D / 3D»; Гефест: `InputRouter.gd` (прибрати `TODO #26`), `MainMenu.gd`, `GameState.gd` (кнопка, `user://settings.cfg`) | конфлікт клавіш у SHARED; ламаємо ADR-009 | гейти rc=0; smoke: кнопка → `free_move=true` і камера дуелі `current`; «no key clashes» з новими клавішами | 3D вмикається з меню без термінала; присід, обхід, підтяжка — кожне на своїй клавіші; SHARED удвох |
| **5** — справжні Choko і Skea | Santos → Аполлон → Santos → Гефест | Santos: «M-0, M-1 — так» (галерея Higgsfield); Аполлон: URL у `tools/fetch_assets.sh` + рядки [[Textures-Registry]]; Santos на Mac: `make fetch-assets`; Гефест: моделі замість манекена | CDN для хмари закритий (403) — лише Mac | РЕЄ `незареєстрованих: 0`; smoke запуску 3 зелений з моделями без зміни коду; `--screenshot` обох | герої замість манекена, анімації ті самі, ніщо не пливе |
| **6** — фінал 0.3 | Гефест → Феміда → Santos | 0.3-6: прогін обох режимів + детермінізм (`SmokeTest.gd`); вердикт Феміди по всьому 0.3; слово Santos «3D за замовчуванням» → `free_move=true` окремим комітом | відчуття не те | `make check` → `ALL OK`; вердикт без RED | бій від меню до KO у 3D без прапорців — **«нормальний файт»** |

**Паралельно із запусками, без коду:** Гермес (#26) і Арес (#36 — таблиця кліп → удар, чесні описи замість
«PLACEHOLDER frame data» у `choko.tres`, нових полів не додає) — зараз; Феміда — на кожен PR запуску. Терміналів,
що пишуть у `game/` або `state.md`, одночасно не більше трьох.

## Пауза до запуску 6 (Santos 2026-10-03)

Меню-діорама (#4, #6, #7, #8), вибір персонажа на даху (#11), перейменування Cronshift (#12), нові партії арту
(#14, арт #19, #33, #38, стікери принтера, пристрій і дрон), #42 D1–D6 (поведінка, тканина, VFX, шейдери), сюжет,
дірки анімацій ($9.99 / $14.99 / Meshy — вирішуємо після запуску 3). Код запусків іде без них: стікер — плейсхолдер,
меню — нинішнє.

## Як запустити (Mac)

```bash
cd ~/nooneisreal            # шлях до клону — твій
git checkout main
make update                 # оновити й переімпортувати
make run                    # меню → FIGHT / VERSUS / TRAINING; 2.5D
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT_BIN" --path game -- --free-move   # те саме меню, бій у 3D (W/S — обхід, тимчасово)
```

## Related
- [[state]] · [[Roadmap]] · [[2026-10-03-First-Fight-Recap]] · [[2026-10-03-Prototype-0.3-Free-Movement]] ·
  [[2026-10-03-Picks-to-Game-and-Animation]] · [[2026-10-03-Animation-Sources]] · [[2026-10-03-C2-3D-Heroes]] ·
  [[2026-10-03-Ares-Printer-Items]] · [[03-Skills-Framework]] · [[05-Platforms-Input]] · [[06-UI-UX]] · [[Textures-Registry]]
