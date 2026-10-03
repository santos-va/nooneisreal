# Аудит спринту, смуга I — PR смуг A–D і закриття RED п. 3

**Дата:** 2026-10-03 · **Роль:** T4 Феміда · **План:** [[2026-10-03-Sprint-Arenas-VFX]] § Смуги, рядок I («кожен PR смуг A–D;
першим — закриття RED п. 3»). Міряно в чистих worktree поза iCloud (`git worktree add … `): `main` `3d022b1`,
PR #111 `aaa6754`, PR #110 `b621ca2` (`git merge-base --is-ancestor origin/main HEAD` → так, `main` уже всередині).
Godot `4.7.2.stable.official.ed1daf0bf` (`/Applications/Godot.app/Contents/MacOS/Godot --version`).

## Вердикт: **RED** — переноситься п. 3 з [[2026-10-03-Launch-5-6]]. Жоден PR спринту нового RED не вносить

| # | що | вердикт | команда → вихід |
|---|---|---|---|
| 1 | `main` `3d022b1`: батарея | GREEN | `make check` → `[smoke] ALL OK (133 checks) in 18843 frames`, rc=0; `bash tools/gates/run_gates.sh` → `БАТАРЕЯ ЗЕЛЕНА`, rc=0 |
| 2 | **RED п. 3 на `main`** (`side`, `sep` 6, P1 ≥ 15 % — [[02-Combat-System]] рядок «частка висоти кадру») | **RED** (відкритий) | § п. 2 нижче: гард `p1_min = 0.148`, замір P1 **14.84 %**; N1 (поріг 0.15) → `FAIL … sep 6: P1 14.84–15.12 %` |
| 3 | половина п. 3: `p2_min = minf(p2_min, p1_min)` | GREEN | `grep -n "minf(p2_min" game/scripts/core/SmokeTest.gd` → 0 рядків; проба: `side sep 6 … p2_min 0.150` |
| 4 | PR santos-va/nooneisreal#111 (смуга F, Арес): числа | GREEN | § п. 4: якорі, модель кадру, константи коду й кліпи UAL перераховано — усе збіглося |
| 5 | PR #111: закриває п. 3 лише на папері | YELLOW | `git diff --stat origin/main...aaa6754 -- game` → порожньо. Після мержу самого #111 GDD каже 0.68, код 0.7, smoke-літерал `[DuelCamera.SIDE_DIST_PER_M, 0.7]` — зелений. Клас 5 |
| 6 | PR #111: гейти | GREEN | worktree `aaa6754`: `run_gates.sh` → `БАТАРЕЯ ЗЕЛЕНА`, rc=0 |
| 7 | PR santos-va/nooneisreal#110 (смуга A1 + бюджет ×2): батарея | GREEN | `make check` → `[smoke] OK  A1 fixed world: ring of 4 cards, none moved … (facing card 2 → 0)`, `ALL OK (134 checks) in 19088 frames`, `budget used 19088 / 38000 frames (50 %)`, rc=0; `run_gates.sh` → rc=0 |
| 8 | PR #110: гард «світ стоїть» ловить зломи | GREEN | 5/5 червоні, § п. 8 |
| 9 | PR #110: бюджет smoke 19000 → 38000, `--quit-after` 20000 → 40000 | GREEN | розширення гарда, але це крок 0 approved-плану (рішення T1), розкрите в PR і в коментарі `SmokeTest.gd`; іменований таймаут іде першим: `FRAME_BUDGET := 3000` → `[smoke] FAIL timeout at stage 141` |
| 10 | PR #110: журнал зустрічі | YELLOW | `git grep -l "2026-10-03-sprint-a1-fixed-world" b621ca2 -- docs/Meetings` → 0. Клас 7 |
| 11 | PR #110: «Xvfb frames on the river … no seams» | не виміряно | у мене не було знімка, а smoke шви перевіряє лише геометрично (ширина ≥ 2 × відстань). Очима — Santos у `~/dev/nir-play` |
| 12 | PR santos-va/nooneisreal#108 (смуга C, змерджено) | YELLOW | § п. 12: у тілі «Код не змінювався», але `tools/fetch_assets.sh` +10/−1 |
| 13 | Кредити спринту | GREEN | `balance` → **5533.25**; `transactions` → 8 × −2.75 (4 о 10:26:32Z, 4 о 10:35:24Z) = 22 = 5555.25 − 5533.25. Слова — «Так» і «GO!» у `Apollon-Sprint-C-Prompts.md` (гілка `claude/practical-hopper-rmfgi4`, `52518b9`). Стеля 1000: витрачено 22 |
| 14 | Смуги B і D | не аудитовано | `gh pr list --state open` → #109 (G), #110 (A), #111 (F). PR B і D ще немає |

## п. 2 — RED п. 3 на `main`: що змінилось і що ні

**Код** (`SmokeTest.gd:2395–2399`, `DuelCamera.gd:37`): нахил `SIDE_DIST_PER_M := 0.7`, поріг P1 у `side` на `sep` ≥ 6 — **0.148**,
P2 — 0.15. Коментар Гефеста розкриває: модель 0.7 дає 15.3 %, рушій 14.84 %, передано Аресу.

**Проба** (тимчасовий `print` через python у копії, `--smoke-only=cam`, файл повернено з `.bak`):

| режим, `sep` | поріг P1 / P2 | P1 мін–макс | P2 мін–макс |
|---|---|---|---|
| behind 6 | 0.150 / 0.125 | 0.2423–0.2437 | 0.1293–0.1297 |
| side 4 | 0.150 / 0.150 | 0.1709–0.1733 | 0.1787–0.1809 |
| **side 6** | **0.148** / 0.150 | **0.1484**–0.1512 | 0.1575–0.1600 |

Запас над порогом — 0.04 п. п. Рядок smoke друкує `%.0f`, тож 14.84 % у логу виглядає як «P1 15–15 %».

**Негативні контролі** (`--smoke-only=cam`; правки python-заміною з `assert count == 1`, повернення з `.bak`, `git status --short game` → чисто):

| # | злам | очікую | вихід |
|---|---|---|---|
| N1 | `p1_min` 0.148 → **0.15** (як у GDD) | червоний | `FAIL ADR-018 frame, side: sep 6: P1 14.84–15.12 %, P2 15.75–16.00 %` |
| N2 | P2 у `side` 0.15 → 0.14 | — | зелений: P2 15.75 %, послаблення не кусає. Не доказ гарда, лише запас |
| N3 | нахил **0.68** + літерал 0.68 + `p1_min` 0.15 | зелений | `OK … side … sep 6 — P1 15–15 %, margin ≥ 21 %`, `ALL OK (19 checks)` — варіант (а) Ареса працює в рушії й не ламає решту камери |
| N4 | нахил 0.75 (старий), поріг 0.148 | червоний | `FAIL … sep 6: P1 14.43–14.68 %` |

**Чому досі RED.** GDD 02 вимагає ≥ 15 % на `sep` ≤ 6, а гард пропускає 14.84 % (N1). Розкрито, тож це не приховування, але PASS
однаково хибний. RED закриється одним PR Гефеста: `SIDE_DIST_PER_M` 0.68 + літерал у `SmokeTest.gd:672` 0.68 + `p1_min` 0.15.
N3 показує, що цей набір зелений.

## п. 4 — PR #111: перерахунок

| твердження PR | моя команда | вихід |
|---|---|---|
| найгірша точка кола до якоря: fountain 8.99 м, bazaar 10.97 м (3D, рука 1.4 м) | `python3`, сітка 801 × 801 у колі 20 м | fountain **8.99** у (−20, 0); bazaar **10.97** у (0, −20). Кількість 17 / 16 |
| сусідні якорі ≥ 5 м, кожен ≥ 1.5 м над рукою | те саме | мін. пара xz: fountain 9.15, bazaar 7.00; мін. `h − 1.4`: 4.1 / 3.6 |
| `grapple_range` 14 м | `grep grapple_range game/scripts/fighter/CharacterData.gd` | `:65 … = 14.0` |
| модель `side` 0.68: 19.5 / 17.9 / 15.5 %, кламп Гермеса до `sep` 9.5 | `python3` `1.8 / (2·d·tan 30°)` | 19.5 / 17.9 / 15.5 %, `sep` 9.51 |
| підйом 18 кадрів, гарпун 3.0 с, раунд 99 с | `grep` | `Fighter.gd:25 GETUP_FRAMES := 18`; `CharacterData.gd:63 grapple_cooldown … 3.0`; `GameState.gd:32 round_seconds … 99` |
| кліпи втоми `Idle_Tired_Loop`, `LayToIdle` | glTF-JSON UAL1/UAL2 (`python3`) | `UAL1.glb ['Idle_Tired_Loop']`, `UAL2.glb ['LayToIdle']` |

Втома — уся PLACEHOLDER з причиною (брифу R9 нема). Розвилка «від часу чи від дій» закрита з обґрунтуванням (снігова куля).

## п. 8 — PR #110: негативні контролі A1

Стадія 137, `--smoke-only=cam` (база: `OK A1 fixed world … facing card 2 → 0`, `ALL OK (20 checks) in 3049 frames`). Три зломи
з PR я не повторював. Мої — ті, яких автор не пробував:

| # | злам `Backdrop.gd` | вихід |
|---|---|---|
| N1 | повернути старий yaw-follow (`rotation.y = atan2(z.x, z.z)`) | `FAIL … cards moved 97.9286 (want 0), facing card 0 → 0` |
| N4 | паралакс 2.5D протікає в 3D (`quad.position.x = cam.x · 0.2`) | `FAIL … cards moved 1.8612` |
| N5 | 4 картки на одному куті (`pivot.rotation.y = 0.0`) | `FAIL … facing card 0 → 0 after 180° (want another)` |
| N6 | `RING_CARDS := 3` | `FAIL A1 fixed world: 3 cards (want ≥ 4 …)` |
| N8 | `FRAME_BUDGET := 3000` | `FAIL timeout at stage 141` — іменований таймаут раніше за `--quit-after` |

Зелених немає. Режим перемикається лише в меню (`MainMenu.gd:152`, до `Arena.gd:24 backdrop.apply`), тож кільце, зібране в
`apply()` за `free_move`, посеред бою не зміниться.

## п. 12 — PR #108 (смуга C, крок 0)

- «`get_cost` — параметр `generate_*`»: GREEN. Схема `generate_image` (ToolSearch у цій сесії): `get_cost` — «return the cost …
  without submitting any job».
- 4 рядки «Заплановано» в [[Textures-Registry]] і `fetch_assets.sh`: GREEN. `curl -sI` на 4 URL → `HTTP/2 200`, 4 623 020 /
  5 658 212 / 6 143 117 / 3 909 583 B. Канони `a2913501` і `c5900952` згадані в журналах хвилі 2 до цього PR.
- 0 кредитів у #108: GREEN. `transactions`: між 07:02:29Z і 10:26:32Z витрат нема, а мердж був о 10:25:14Z.
- «Код не змінювався. Змінено лише документи»: YELLOW. `git diff 7cd98c0^1 7cd98c0 -- tools/fetch_assets.sh` → +10/−1 (дві
  нові теки й 4 `fetch`). Скрипт не гра, але тіло PR каже неправду про склад.

## Пропозиції

1. **Гефест:** один PR закриває RED п. 3 — `DuelCamera.SIDE_DIST_PER_M` 0.68, літерал `SmokeTest.gd:672` 0.68, `p1_min` 0.15.
   Негатив — N1 і N4 вище. **Santos:** #111 мерджити разом із цим PR або після нього, інакше в `main` GDD ≠ код без жодного гарда. — п. 2, 5
2. **Гефест:** у рядку `ADR-018 frame` друкувати `%.1f`, а не `%.0f`: 14.84 % не має виглядати як «15». — п. 2
3. **Гефест (#110):** дописати журнал зустрічі з лінком на `2026-10-03-sprint-a1-fixed-world` (клас 7). — п. 10
4. **Дедал:** гейт «GDD 02 ↔ `GDD_*`» (клас 5, пропозиція 4 [[2026-10-03-Launch-2-PR60]]) — #111 знову показав, що число в GDD
   міняється без літерала, і smoke цього не бачить. — п. 5
5. **Аполлон:** у тілі наступного PR смуги C писати склад чесно (скрипти — теж «код»). — п. 12

## Реєстр

Клас 5 → лічильник 7 (#111: GDD 0.68 при літералі 0.7 — зелено). Клас 7 → +1 (`sprint-a1-fixed-world`). Обидва ВІДКРИТО:
механізм — код гейта, Феміда його не мутує. [[recurring_class_register]].

## Related
- [[2026-10-03-Sprint-Arenas-VFX]] · [[2026-10-03-Launch-5-6]] · [[2026-10-03-Launch-2-PR60]] · [[02-Combat-System]] ·
  [[04-Grapple-System]] · [[Textures-Registry]] · [[2026-10-03-Apollon-Sprint-C-Prompts]] · [[recurring_class_register]] ·
  [[2026-10-03-Femida-Sprint-Lane-I]]
