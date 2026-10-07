# Смертельний бій: правки після аудиту T4

**Дата:** 2026-10-07 · **Роль:** T2 Гефест · **Статус:** виконано в робочому дереві гілки `claude/t1-orchestration-2026-10-07` (PR #186, база `main` `e580497`, HEAD на старті `6f805b0`). Це крок 8 (8a–8f) [[2026-10-07-First-Enemy-Lethal-Fight]] за пропозиціями №1–7 аудиту [[2026-10-07-Lethal-Fight-Blood-Review]]. Коміт і push робить T1.

## Звірка плану з реальністю

1. **Усі посилання плану на місці.** `sed -n 18p game/scripts/fx/SmearShards.gd` → `_rng.seed = FxShader.rng().randi()`; `sed -n 5p game/scripts/fx/BloodFx.gd` → «draws from its own RNG»; `sed -n 1889,1890p game/scripts/fighter/Fighter.gd` → «clamp_arena() exactly: x − 0 and 0 + x are the same floats»; `sed -n 12p game/scripts/world/CityFighter.gd` → `POCKET_SEALED_ACTIONS … ["grapple_enemy"]`; у `lethal_fight_check.gd` у кишені натискається лише `KEY_U` (рядки 375, 389).
2. **План 8b не називає другого споживача.** `FxShader.stroke()` сам бере `rng().randf()` для `seed` шейдера (`FxShader.gd:32`), а `SmearShards._emit` кличе `stroke` на кожен шматок. Тож лише пересіяти `_rng` недосить: умова плану «стан `FxShader.rng()` не зсувається» вимагає, щоб і `stroke` брав той самий RNG. Це деталь виконання тієї самої умови, не нова розвилка.
3. **Клавіші SOLO:** `InputRouter.gd:37` → skill1 `U/R`, skill2 `I/T`, ulti `O/C`. Ульта стартує лише з повною шкалою (`Fighter.gd:583`: `meter >= MAX_METER`), тож фікстура ставить шкалу як передумову.
4. **Ульта Choko б'є до 6,8 м** (`SwordStormFx.REACH`), TIME STOP — 4,2 м (`choko.tres` skill2). Щоб натиск не міняв HP ворога й подальшу CPU-частину, на час натисків бійці стоять за 10 м.
5. **Регулярка playable для `tight-station` закріплена на кінці рядка** (`playable_check.sh:50`: `…mode=none` під `^…$`). Тому `S5=NOT MEASURED (headless)` — окремий рядок, не хвіст сентинела.
6. **Порядок подій на вирішальному KO:** `Fighter.receive_hit` емітить `hit_landed` до `_die` (`Fighter.gd:1330-1332`), а `MatchFlow._end_round` ставить `ROUND_END` уже після. Отже, на справжньому вирішальному ударі `flow.phase == FIGHT`, і умова 8f його не відсікає.
7. **`godot` на PATH немає** (`which godot` → порожньо). Усі прогони — official Godot 4.7 через `GODOT_BIN`: `--version` → `4.7.stable.official.5b4e0cb0f`, `sha512sum | cut -c1-16` → `d925fbe1cb4afd9a` (той самий, що в аудиті).

## «До» — відтворення на `6f805b0`

Зонди T4 скопійовані в `<scratchpad>/audit-fixes/probes/`, мутації — у дзеркалі `<scratchpad>/audit-fixes/mirror/game` (репозиторій не мутується).

| що | команда | вихід |
|---|---|---|
| P15 | `python3 mutate.py before P15-ult-sealed-in-pocket` | `rc=0 … LETHAL_FIGHT_COMPLETE checks=118 failures=0` — зелено, дефект відтворено |
| −0.0 | `bound_probe.gd` | `free_move=true … byte_diffs=2 value_diffs(!=)=0`; `free_move=false … 0/0` |
| RNG | `rng_probe.gd` | `full/muted … moved=false`; `ink SmearShards.burst … moved=true` |
| час | `run_fixture.sh` | blood-content 31,5 с (`checks=52`), lethal-fight 37,1 с (`checks=118`) |

## Що зроблено

| # | файли | що |
|---|---|---|
| 8a | `tools/match/lethal_fight_check.gd`, `tools/gates/playable_check.sh` | У кишені по черзі справжні клавіші U, I, O; кожна має запустити свій рух і не потрапити в `sealed`. Для O шкала ставиться повною (передумова). Для I і O бійці стоять за 10 м, після ульти — перевірка «ворог неушкоджений» (hp 1000, не HITSTUN/LAUNCHED). Друге натискання U одразу відкатує RECORD, щоб 4-секундний таймер не обривав ульту і не зсував CPU-частину. Негатив `skills` тепер запечатує всі три натиски; новий негатив `skills_late` — лише I і O після відкритого U (форма P15 з боку фікстури) |
| 8b | `game/scripts/fx/FxShader.gd`, `SmearShards.gd`, `BloodFx.gd` | `FxShader.stroke(…, seed_rng = null)` і `SmearShards.burst(…, rng = null)` — необов'язкові параметри. Без них поводяться як раніше: сіють із `FxShader.rng()` у тому самому порядку. `BloodFx` у режимі Ink передає свій `rng`. Коментар `BloodFx.gd:5-9` тепер описує саме це |
| 8c | `tools/fx/blood_content_check.gd` | Трасування — 5 боїв по 700 тіків: Choko Off/High (еталон), Choko Full/High, Choko Ink/High, Skea Off/High (еталон), Skea Muted/Low. Кожен варіант порівнюється з еталоном того самого героя. У рядку тіку додано `hero._rng.state`, `enemy._rng.state`, `enemy._brain._rng.state`. Повного перехресного добутку немає: Ink не читає профіль якості, Full/Muted читають, тож Low стоїть у парі з Muted. `TRACE_TICKS` позначено PLACEHOLDER. Новий негатив `rng_state`: кров у Ink тягне одне число з `hero._rng` |
| 8b-гард | `tools/fx/blood_content_check.gd` | У кишені: для full / muted / ink / off сам `BloodFx._on_hit` (без HitSpark, який за задумом бере спільний RNG) не зсуває `FxShader.rng().state` і глобальний RNG. Вимога «кров намалювалась» захищає від порожнього проходу. Новий негатив `rng`: `blood.rng = FxShader.rng()` |
| 8d | `game/scripts/fighter/Fighter.gd`, Core Fix | `bound()` при `arena_center == Vector3.ZERO and arena_radius == ARENA_RADIUS` повертає сам `clamp_arena(p)`. Коментар `Fighter.gd:1889-1891` і рядок Core Fix (таблиця файлів) виправлено: «за значенням, але не біт у біт, `0 + (−0.0) = +0.0`» |
| 8e | `tools/camera/tight_station_probe.gd`, `playable_check.sh` | Перед сентинелом `--check` друкує окремий рядок `TIGHT_STATION S5=NOT MEASURED (headless)` (нативний прогін — `S5=MEASURED (N routes)` або `NOT MEASURED (no ink samples)`). Те саме йде в `receipt.json` як `s5`. Основний кейс playable `tight-station` тепер вимагає цього рядка безпосередньо перед сентинелом |
| 8f | `game/scripts/fx/BloodFx.gd`, `blood_content_check.gd`, `game/scripts/core/SmokeTest.gd` | `decisive` додатково вимагає `flow.phase == MatchFlow.Phase.FIGHT`. Перевірка: одразу після KO раунду 1 (`ROUND_END`, герою лишається одна перемога) пізній смертельний `_on_hit` калюжі не планує. Новий негатив `late`: фікстура на мить ставить фазу FIGHT. Smoke: `_hero_not_cpu_only` на `choko.tres` і `skea.tres`, а копія Choko з `cpu_only = true` мусить бути відхилена |
| журнали | `docs/Fix/2026-10-07-Blood-And-Content-Settings-Fix.md` | Біля «власний RNG `0x0B100D`» дописано, що в тому коміті шлях Ink ще сіяв `SmearShards` із `FxShader.rng()` |

Бойових чисел, `.tres` героїв і ворога, input map і `project.godot` не чіпано: `git diff --stat -- game/data game/project.godot` → порожньо.

**Предмети гардів:**
- Предмет 8a: для всіх дій A ∈ {skill1, skill2, ultimate}: свіжий натиск A у смертельній кишені запускає рух A і не повідомляється як запечатаний.
- Предмет 8b: для всіх режимів M ∈ {full, muted, ink, off}: удар крові в M не зсуває ні `FxShader.rng()`, ні глобальний RNG.
- Предмет 8c: для всіх героїв H і режимів/профілів (M, Q) зі списку: бій H з кров'ю (M, Q) тотожний бою H з Off/High у кожному тіку, включно зі станами RNG бійців і CPU.
- Предмет 8d: для всіх p при дефолтних центрі й радіусі: `bound(p)` побайтово дорівнює `clamp_arena(p)`.
- Предмет 8f: для всіх смертельних ударів по ворогу: калюжа з'являється лише від удару, що виграє матч, поки раунд іще триває (FIGHT).

## Перевірка

Окремі прогони — тим самим способом, яким фікстури кличе `playable_check.sh` (`<scratchpad>/audit-fixes/run_fixture.sh`). Мутації — лише в дзеркалах `mirror/` і `mirror2/`; після кожної файл повертається, у кінці `diff -rq --exclude=.godot game mirror/game` → тотожні.

**Визнаю:**
- Перший варіант 8a повертав ворога на `(0,0,-4)` ще до кінця ульти, тож Sword Storm його зачепив і CPU-перевірка стіни почервоніла. Це знайшов тимчасовий друк у копії фікстури: `enemy (1.455313, 0.0, -4.047243) … enemy_state 10`. Тепер позиція повертається лише після `hero.is_actionable()`, і є перевірка «ворог неушкоджений».
- Перший прогін мутацій 8b я запустив двома процесами на одному дзеркалі, тож мутації змішались: M8b2 почервонів на full/muted. Ці результати відкинуто, усе перезапущено на двох окремих дзеркалах (`MIRROR=…`).

| що | команда | вихід |
|---|---|---|
| lethal-fight | `run_fixture.sh … lethal_fight_check.gd` | `checks=121 failures=0`; CPU `punished 4/6, 29 moves, 7 series, 3 low hooks, 4 SNUFF at 2.27/2.62/2.54/2.53, chain 3, gap 20` — тотожно базі аудиту T4 |
| blood-content | `run_fixture.sh … blood_content_check.gd` | `checks=66 failures=0`, 52,4 с (було 31,5 с); трасування: `choko full/high 14 splashes … first difference -1`, `choko ink/high 0 splashes 14 ink … -1`, `skea muted/low 14 splashes … -1` |
| tight-station | `run_fixture.sh … tight_station_probe.gd --check` | `TIGHT_STATION S5=NOT MEASURED (headless)` і `TIGHT_STATION_COMPLETE checks=31 failures=0 mode=none` |
| −0.0 після | `bound_probe.gd` | `free_move=true … byte_diffs=0 value_diffs(!=)=0`; `free_move=false … 0/0` |
| RNG після | `rng_probe_after.gd` | `full/muted … moved=false`; Ink з `BloodFx.rng` → `moved=false; global RNG moved=false`; старий виклик без `rng` → `moved=true` (за задумом, як і раніше) |
| старі виклики | `smear_compat_probe.gd`, репо проти дзеркала старого коду | обидва `items=39 md5=686bf9c3dd45876f503e7a359d93a818 shared_state_after=4820231844326530272` |
| регулярка S5 | python, регулярка кейсу на справжньому лозі і на лозі без рядка S5 | `real log match`, `S5 line removed NO MATCH` |

### Негативи (фікстурні, у батареї)

| негатив | вихід | мітки |
|---|---|---|
| lethal `skills` | `checks=94 failures=3` | skill1, skill2, ultimate `opens in the pocket` |
| lethal `skills_late` | `checks=94 failures=2` | skill2, ultimate |
| blood `rng` | `checks=31 failures=3` | full, muted, ink `… shared moved true` |
| blood `late` | `checks=31 failures=1` | `a late lethal blow after round 1 is decided pools nothing (phase 2, hero wins 1, puddle scheduled true)` |
| blood `rng_state` | `checks=13 failures=1` | `choko ink/high … first difference: 149, column 14` (колонка 14 = `hero._rng.state`) |
| blood `state` (наявний) | `checks=13 failures=1` | `choko full/high … first difference: 149, column 6` |

Решта наявних негативів blood-content дали ті самі кількості failures, що в аудиті: sparring 1, cfg 2, flash 2, notice 1, back 6, block 1, mode 1, ink 1. Число checks у частині L зросло з 26 до 31 (+4 RNG, +1 late).

### Мутації продакшн-коду (дзеркало)

| мутація | що ламає | вихід |
|---|---|---|
| P15 | `POCKET_SEALED_ACTIONS += ["ultimate", "skill2"]` | до: `checks=118 failures=0`; після: `checks=121 failures=2` (skill2, ultimate) |
| P15a / P15b | лише skill2 / лише ульта | `failures=1` (skill2) / `failures=1` (ultimate) |
| M8b1 | `SmearShards` знову сіється з `FxShader.rng()` | `failures=1`: ink |
| M8b2 | `stroke` ігнорує `seed_rng` | `failures=1`: ink |
| M8b3 | `BloodFx` Ink не передає `rng` | `failures=1`: ink |
| M8b4 | `BloodSplash` бере seed зі спільного RNG | `failures=2`: full, muted |
| P12b (T4) | кров додає атакувальнику 1 кадр hitstop | `failures=2`: `choko full/high … 149, column 5`, `skea muted/low … 148, column 5` |
| M8d1 | ярлик `bound()` без умови радіуса | `failures=2`: `pocket wall holds the hero/enemy at 7 m (7.600)` |
| P7 (T4) | `bound()` бере `ARENA_RADIUS` | `failures=2`: те саме |
| M8f1 | калюжа в будь-якій фазі | `failures=3`: late, `a round-1 KO leaves no puddle`, кроки калюжі |
| M8f2 | калюжа лише в ROUND_END | `failures=4`: late, round-1, `decisive blow bleeds one level more`, кроки |
| MS1 / MS3 | `choko.tres` / `skea.tres` з `cpu_only = true` | smoke `rc=1`: `FAIL ADR-024 п. 9 slot contract: choko.tres / skea.tres is marked cpu_only` |
| MS2 | `_hero_not_cpu_only` сліпий | smoke `rc=1`: `a Choko copy marked cpu_only passed the hero rule, must fail` |

### Батарея (official Godot 4.7, сирі логи — `<scratchpad>/audit-fixes/`)

| команда | вихід |
|---|---|
| `GODOT_BIN=… PLAYABLE_LOG_DIR=… make check-playable` | `MAKE_CHECK_PLAYABLE_RC=0`, 23 хв 37 с · імпорт без error/warning · GDS `перевірено: 126 · не парсяться: 0 · канарка: FAIL як треба` · `[smoke] ALL OK (165 checks) in 19847 frames` · `SMOKE ЗЕЛЕНИЙ` · `PLAYABLE CHECK: 135 scenarios, 0 failures` (було 131: +`lethal-fight-negative-skills_late`, +`blood-content-negative-rng`, `-late`, `-rng_state`) |
| у тій самій батареї | `LETHAL_FIGHT_COMPLETE checks=121 failures=0`, `BLOOD_CONTENT_COMPLETE checks=66 failures=0`, `TIGHT_STATION S5=NOT MEASURED (headless)` + `TIGHT_STATION_COMPLETE checks=31 failures=0 mode=none` |
| скан 135 логів | `grep -lE '^\s*(SCRIPT ERROR\|ERROR):'` → лише 52 логи `*-negative-*` (усі 52 негативи), у жодному кейсі без негативу — 0; `SCRIPT ERROR` — 0 |
| `GODOT_BIN=… make gates` | `MAKE_GATES_RC=0` · `БАТАРЕЯ ЗЕЛЕНА`: wikilinks 473 сторінки / 6975 лінків / 0 зламаних; реєстр 176/176; ролі 8/0; GDS 126/0 |

## Що лишилось відкритим

- **Час blood-content** зріс з 31,5 до 52,4 с (5 трасувань замість 2). До ліміту кейсу 180 с далеко; якщо стане тісно, Medium і Full/Low можна додати лише ціною часу — зараз вони не трасуються.
- **Ink на вигляд змінився:** насіння тепер із `BloodFx.rng` (`0x0B100D`), а не з випадкового `FxShader.rng()`. Між боями Ink тепер детермінований, як Full/Muted. Це лише презентація; кадрів на GPU я не дивився (огляд крові — T6).
- **У кишені пізній смертельний удар по ворогу в `ROUND_END` усе ще можливий** (наприклад, хвіст ульти героя після того, як ворог виграв раунд). Тепер він не дає калюжі, але `_die` ворога тоді настає, а `MatchFlow._on_ko` його ігнорує (`phase != FIGHT`). Як це має виглядати в бою — питання до T5, не до цього кроку; код я лише прочитав, не відтворював.
- **S5 на нативному прогоні** я не запускав. Рядок `S5=MEASURED (N routes)` перевірено лише читанням коду; headless-гілку — прогоном.
- Пропозиції аудиту №8–11 (закріпити `rounds_to_win` у lethal, формулювання T8 про ворожий гак, чистка `state.md` і гейт класу 13, `#4E0819` у Style-Guide) — не цей крок. `state.md` не чіпав; коміт і push — T1.

## Related

- [[2026-10-07-First-Enemy-Lethal-Fight]] · [[2026-10-07-Lethal-Fight-Blood-Review]] · [[ADR-024-Lethal-Fights-And-First-Enemy]] · [[2026-10-07-Lethal-Fight-Core-Fix]] · [[2026-10-07-Blood-And-Content-Settings-Fix]] · [[2026-10-07-Camera-Readability-Iteration-2-Fix]] · [[ADR-004-Physics-Is-Presentation]] · [[state]]
