# Аудит: смертельний бій, кров, ContentSettings і камера ітерації 2 (PR #185)

**Дата:** 2026-10-07 · **Роль:** T4 Феміда · **Вердикт: YELLOW.** RED не знайшла. Батарея на official Godot 4.7 зелена. Усі 26 нових негативів червоніють саме на тому, що ламають. З 17 мутацій продакшн-коду 16 червоні. YELLOW стоїть через чотири речі:
- (1) ADR-024 п. 6 «skill2 і ульта відкриті в кишені» нічим не захищено: мутація P15 лишається зеленою;
- (2) режим Ink зсуває спільний `FxShader.rng()`;
- (3) твердження «`bound()` = `clamp_arena()` біт у біт» хибне для −0.0, хоча за значенням вони рівні;
- (4) `state.md` і Fix-журнали відстають від комітів і merge — це клас 13, уже втретє.

> Записав T1 Дедал зі звіту T4 (sub-agent, лише читання) без зміни змісту. Аудит ішов на `69036a4`; Santos змерджив PR #185 о 16:47:39 UTC (GitHub MCP `merged_at`), паралельно з аудитом. T1 у цій сесії переперевірив: `sed -n 18p game/scripts/fx/SmearShards.gd` → `_rng.seed = FxShader.rng().randi()`; `CityFighter.gd:12` → `POCKET_SEALED_ACTIONS … ["grapple_enemy"]`; у `lethal_fight_check.gd` у кишені натискається лише `KEY_U` (рядки 375, 389); `state.md:54` → «(draft PR #184)».

**Визнаю першим:**
- Мій перший варіант мутації P12 мав хибний відступ і не застосувався (`PATTERN COUNT 0 — skipped`). Я перезапустила його як P12b.
- Логи `<scratchpad>/t4/make_check.log` і `make_gates.log` попередньої сесії T4 я перезаписала своїми прогонами.

## Від чого відштовхувався аудит (усе виміряно в цій сесії)

- **PR і гілка.** `gh api repos/santos-va/nooneisreal/pulls/185` → `state open, draft false, head 69036a4, base main 96368c1`. `pulls/184` → `merged true, merged_at 2026-10-07T11:08:41Z, merge 96368c1`.
- **Коміти.** `git log --format=%an origin/main..HEAD | sort | uniq -c` → `16 Claude`, повідомлення англійською. `git log --first-parent origin/main` → у `main` лише merge-коміти.
- **Godot.** `sha512sum <бінар>` → `d925fbe1…` (так само, як в офіційно звіреному аудиті [[2026-10-07-Camera-And-Gate-Review]]). `--version` → `4.7.stable.official.5b4e0cb0f`.
- **Де робила мутації.** Лише в копії `cp -a game <scratchpad>/t4b/mirror/game`. Після кожної мутації файл відновлено, у кінці `diff -rq game/scripts mirror/game/scripts` → тотожні. `git status --porcelain | wc -l` → `0`.
- **Як запускала фікстури.** Так само, як їх кличе `playable_check.sh`: `--headless --audio-driver Dummy --path game --fixed-fps 60 --quit-after 12000 --script <abs> -- --break=X`, з окремим `XDG_DATA_HOME`. Скрипт — `<scratchpad>/t4b/run_fixture.sh`.
- **Сирі логи.** `<scratchpad>/t4b/`: `neg/` — негативи, `mut/` — мутації, `sel/` — вибіркова батарея, `native-open-head/` — нативні кадри. Логи `make` лежать у `<scratchpad>/t4/`.

## Батарея

| команда | вихід |
|---|---|
| `make check` | rc0 · GDS `перевірено: 126 · не парсяться: 0 · канарка: FAIL як треба` · `[smoke] ALL OK (165 checks) in 19847 frames` · `SMOKE ЗЕЛЕНИЙ` · Jolt 0 |
| `make gates` | rc0 · `БАТАРЕЯ ЗЕЛЕНА`: wikilinks 468 сторінок / 6903 лінки / 0 зламаних; реєстр 176/176; ролі 8/0; якорі state ок; R8 у 35 планах; GDS 126/0 |
| вибіркова батарея: відфільтрована копія `playable_check.sh` з тими самими критеріями PASS, 27 сценаріїв | `PLAYABLE CHECK: 27 scenarios, 0 failures`, rc0. Сюди входять tight-station і 8 його негативів, city-camera (440/0), hero-gear (7950/0), free-movement, match-lifecycle, comfort-ui, graphics-ui, ui, district-ui, camera, impact, combat-control, dodge-stamina, ultimate-wave, npc, conversation-camera, city-controls, lethal-fight, blood-content |
| 26 нових негативів окремо | див. п. 5 |
| `git diff --stat origin/main..HEAD -- game/assets docs/Art/Textures-Registry.md` | 1 GLB, його `.import` і 1 рядок реєстру. `sha256sum lamplighter_m0.glb` → `d2a7aacb…` = хеш у реєстрі |

**Не переміряно:** 78 зі 131 сценарію playable. Повну цифру 131/0 дав T1. Склад батареї я рахувала, виконавши список `cases` з файла: гілка → `cases 131 negatives 48`, `main` → `98 / 18`.

## Підсумок

| № | Пункт | Вердикт |
|---|---|---|
| 1 | Смертельний бій проти ADR-024 п. 3 і п. 6; `bound()` проти `clamp_arena()` | **YELLOW** |
| 2 | Кров проти ADR-024 п. 4 і ADR-004 | **YELLOW** |
| 3 | ContentSettings / ContentNotice / ComfortPanel, HIT FLASH Reduced | **GREEN** |
| 4 | Камера, ітерація 2 | **GREEN** |
| 5 | Гейти: негативи, клас «зелено без виміру» | **YELLOW** |
| 6 | Доки проти коду | **YELLOW** |

## 1. Смертельний бій — YELLOW

**Базовий прогін.** `lethal_fight_check.gd` → `LETHAL_FIGHT_COMPLETE checks=118 failures=0 mutation=none`. CPU поводиться так само, як у журналі: `punished 4/6, 29 moves, 7 series, 3 low hooks, 4 SNUFF at 2.27/2.62/2.54/2.53, chain 3, gap 20`.

**ADR-024 п. 3 тримається:**
- Best-of-3. `grep -rn rounds_to_win game/scripts` → єдине присвоєння `GameState.gd:43 = 2`.
- Годинника немає. Мутація P10 (повернути таймер у lethal) → 7 червоних, серед них `no clock in a lethal round (99.00 → 98.00)`.
- HP переноситься з k = 0,35. P6 (k = 0,30) → `enemy 300.0 (want 350.0)`, `hero 609.0 (want 640.5)`.
- Ворог гине лише на вирішальному KO. P13 (`rematch` після вирішального KO) → `the dead enemy stays down` червоне.
- Поразка героя: RETRY = `rematch` з повним HP, RETURN — на безпечну точку. Негатив `retry_carry` червоний. Це збігається з GDD 02 § Поразка героя.

**ADR-024 п. 6:**
- skill1 відкритий у кишені: негатив `skills` червоний.
- Поза кишенею навички запечатані: негатив `outside` червоний; P16 (ульта відкрита в місті) → city-controls 4 червоних.
- Ворожий гак запечатаний: P3 (`POCKET_SEALED_ACTIONS = []`) → `the enemy hook stays sealed` червоне.
- Printer вимкнений: P4 (увімкнути Printer у кишені) → `Choko's Printer stays off` червоне.
- **Розрив:** P15 запечатує в кишені `skill2` і `ultimate` → `LETHAL_FIGHT_COMPLETE checks=118 failures=0`, тобто зелено. Фікстура тисне лише U (skill1). Обіцянка ADR-024 п. 6 і рядок `state.md:26` «skill1/skill2/ульта відкриті» гарда не мають. Це клас 5.

**`bound()` проти `clamp_arena()`.** Мій зонд `<scratchpad>/t4b/bound_probe.gd`, 200 011 точок:
- `free_move=true`: `byte_diffs=2 value_diffs(!=)=0`. Обидві різниці — у знаку нуля: вхід `(-0.0, 1, 3)` дає `bound` → +0.0, а `clamp` → −0.0. Те саме з `(3, 0, -0.0)`.
- `free_move=false`: `0/0`.

Отже, за значенням `bound()` дорівнює `clamp_arena()`, і регресії дуелі за значенням немає. Smoke 165/19847 і free-movement PASS. Але коментар `Fighter.gd:1889-1890` і журнал Core Fix («`x − 0` і `0 + x` дають ті самі float») формально хибні: `0 + (−0) = +0`. P7 (`bound()` бере `ARENA_RADIUS` замість `arena_radius`) → `pocket wall holds the hero at 7 m (7.600)` червоне.

## 2. Кров — YELLOW

**Код.**
- `BloodFx` / `BloodSplash` пишуть лише у власні вузли.
- Блок і чіп дають `hit_landed(..., true)` (`Fighter.gd:1313`), а `BloodFx._on_hit` на `blocked` повертає одразу.
- DoT (`Fighter.gd:506`) не емітить `hit_landed`. `grep "receive_hit|hit_landed" GrappleHook.gd` → 0, тобто підтяжка теж ні.

**Фікстура.** `blood_content_check.gd` → `checks=52 failures=0`. Трасування: `700 ticks, 14 splashes with Full, 0 with Off, first difference -1`.

**Мутації:**

| мутація | результат |
|---|---|
| P5: кров на блоці | `a blocked hit draws no blood` червоне |
| P8: прибрати `flow.lethal` | `a sparring shows no blood … (splashes 4, floor 7)` червоне |
| P12b: кров додає атакувальнику 1 кадр hitstop | `first difference: 149` червоне |

Отже, трасування бачить вплив крові на бій.

**RNG.** Мій зонд `rng_probe.gd`:
- `BloodSplash.burst` зі своїм RNG → `shared FxShader.rng state moved=false; global RNG moved=false`.
- Шлях Ink, тобто `SmearShards.burst` → `moved=true`. Причина — `SmearShards.gd:18`: `_rng.seed = FxShader.rng().randi()`.

У бій це не проходить: `FxShader.rng()` — RNG презентації, з `randomize()`. Але для Ink не справджуються ні «власний RNG» з ADR-024 п. 4, ні коментар `BloodFx.gd:5` «draws from its own RNG».

**Покриття трасування.** Порівнюються лише Full і Off на High, з одним героєм Choko. Ink, Muted і профілі Medium/Low не трасуються. GDD 02 обіцяє, що «перемикач BLOOD і профіль якості не змінюють хеш реплею». Це покрито лише частково.

**Не перевірено (лише прочитано код).** `decisive` у `BloodFx.gd:86` не перевіряє `flow.phase`. Якщо після першого KO в ROUND_END прилетить ще один смертельний удар, може з'явитись калюжа без зарахованої перемоги. Це лише презентація.

## 3. ContentSettings / ContentNotice / ComfortPanel — GREEN

| мутація | результат |
|---|---|
| P1: прибрано заборону `save_settings` | 4 червоних (`damaged/unknown file refuses to be saved over`, `keeps its bytes`) |
| P14: пошкоджений файл вважається OK | 6 червоних |
| P2: Esc позначає картку баченою | 6 червоних (`esc/pad_b steps back … card stays unseen`) |
| P17: картка показується щоразу | 3 червоних (`a seen card never shows again`) |
| P9: світло удару лишається Full у Reduced | `Reduced halves the hit light (4.00)` червоне |

**Значення HIT FLASH Reduced** (`RigAnimator.flash()`, `HitSpark.gd`, `REDUCED_FLASH_SCALE 0.5`):
- спалах 0,09 × 0,5 = 0,045 с;
- білизна 0,5;
- світло удару 4,0 → 2,0, на блоці 1,5 → 0,75.

RESTORE контенту не чіпає: кнопка викликає лише `_settings.reset_defaults`.

`fx_chrono_screen.gdshader` — це знебарвлення й кільце, а не спалах. Тож твердження «повноекранного спалаху немає» тримається.

**Відкрите:** підтвердження картки кнопкою A геймпада фікстура не перевіряє. T2 це визнав.

## 4. Камера, ітерація 2 — GREEN

- **Код.** На повній заливці `_apply_masks(false)` повертає точний hull. Шейдери `hero_outline`/`outline` після винесення в include текстуально тотожні старим. Нові гілки спрацьовують лише при `visibility < 1.0`.
- **Нативна перевірка.** Мій рендер HEAD `69036a4`: `xvfb-run … gl_compatibility … tight_station_probe.gd -- --station=open --transition=kick --sample-every=6 --keep-all`, rc0, 0 ERROR. Далі `identity.py` проти базових кадрів T2 на `15aea6a` → `compared=43 identical=43 worst_diff_px=0`. Базові кадри зробив T2; мій кадр HEAD незалежний.
- **S4 у headless виконується.** `tight-station --check` → `checks=31 failures=0`. Негатив mask → `depth mask iff fill < 1 … t0 fill 0.4305 chain hull`; restore → `t53 fill 1.0 chain other:ShaderMaterial`; resident → `fill 1.000 <= 0.25`; lane → `51/52 consecutive ticks <= 30`. Усі 8 негативів PASS з rc1.

## 5. Гейти — YELLOW

- **Fail-open рухів немає.** Раннер змінився лише додаванням префіксів. Справ стало 98 → 131, негативів 18 → 48. Зміни в `city_camera_check.gd` і `hero_gear_check.gd` посилюють перевірки: з'явились перевірки точного відновлення hull. Smoke `_gdd_slots` пропускає `ultimate`/`throw` лише для `cpu_only`, на це є ADR-024 п. 9 і три негативні випадки. Для наявних героїв вердикт не змінився.
- **Кожен новий негатив червоніє саме на своєму предметі.** Усі rc1, лише рядки з префіксом своєї фікстури, `SCRIPT ERROR` 0, Jolt 0. Мітки failures я перевірила по логах.
  - lethal: sparring 8 · carry 3 · carry_none 2 · retry_carry 1 · death 3 · early_death 1 · clock 6 · npc 7 · npc_return 3 · skills 1 · outside 1 · exit 1 · edge 1.
  - blood: sparring 1/1 · cfg 21/2 · flash 21/2 · notice 26/1 · back 26/6 · block 26/1 · mode 26/1 · ink 26/1 · state 4/1.
  - city: signal 3 · interval 2 · comfort 10 · focus 5.

  Усі числа збігаються з журналами. У sparring червоніють і поведінкові перевірки (годинник, HP, TIME UP), не лише тавтологічна `MatchFlow.lethal is off`.
- **Слабше місце.** Частина негативів підставляє готовий стан, а не ламає код: carry_none, retry_carry, npc_return, exit, cfg, notice, back. Вони доводять лише те, що перевірка читає правильне значення. Цю прогалину закривають мутації P1, P2, P6, P11, P13 і P14.
- **Класу 12 у трьох нових фікстурах немає.** Перед кожним раннім `return` стоїть зарахована червона перевірка. Цикл перевірки смуги SNUFF підкріплений `snuffs.size() >= 1`. **Але** `tight_station_probe` у headless мовчки пропускає S5 (чорнило ≤ 10 % кадру). У виході є лише `checks=31 failures=0` і нічого про S5, а пропуск описано тільки в коментарі заголовка.
- **Мутації:** з 17 червоні 16. Зелена лише P15 (див. п. 1).

## 6. Доки — YELLOW

**Збігається з кодом і виміром:**
- 118 перевірок і 13 негативів lethal-fight, кількості failures у кожному негативі, статистика CPU;
- 52 перевірки й 9 негативів blood-content, краплі 8/4/2, «16 of 37», калюжа 0,45/0,8/1,2;
- 131 сценарій і 48 негативів, smoke 165/19847, GDS 126/0;
- межі коміту крові: `git diff --name-only e2cfda9 69036a4 -- game tools` без `Fighter.gd`, `MatchFlow.gd`, `CharacterData`, `.tres`; `project.godot` +1 рядок autoload;
- кольори: `#A3243B × #B07AA6 = #711126`, `#711126 × #B07AA6 = #4E0819`.

**Не збігається:**
- `state.md:22` і `:24` кажуть «робоче дерево … без коміту», хоча вже є коміти `6141232` і `6018936`.
- `state.md:54` каже «(draft PR #184)», хоча #184 змерджено о 11:08:41Z. Це суперечить `state.md:3` того ж файла. **Клас 13, третій випадок.**
- `state.md:3` каже «PR #185 (draft)», а API дає `draft false`.
- `state.md:60-63` каже «Зараз T2 — ядро … Далі — кров», хоча обидва кроки вже готові (рядки 26 і 28).
- `state.md:83` каже, що класи 12/13 «внести може лише T4», але рядки 12–14 уже в реєстрі.
- Рядки «Статус» у Core Fix:3 («Коміт робить T1»), Blood Fix:3 («без коміту») і Camera Fix:3 застаріли.
- Core Fix:42 твердить «біт у біт» — це хибно для −0.0.
- Blood Fix:51 і `BloodFx.gd:5` кажуть «власний RNG», але шлях Ink використовує `FxShader.rng()`.
- `docs/Meetings/2026-10-07-T1-Orchestration-Session.md:29` відкладає кредити «лише зі словом Santos», а `:25` записує витрату 54,25.

## Інше

- **Кредити.** 54,25 витрачено за фразою Santos «все дозволено» (`Meeting:22`, `:25`). Конституція R5 вимагає слова Santos у цій сесії. Фраза з датою є, тому це не RED. Але питання до Santos/Дедала лишається: чи є загальне «все дозволено» дозволом на кредити?
- **Ліцензія GLB** у реєстрі: «Higgsfield ToS — підтвердити». Вона вказана, але не підтверджена.

## Реєстр рецидивів (пропозиція для T1; у цій сесії T4 права запису не має)

- **Клас 5** (обіцянка без гарда): +1. ADR-024 п. 6, skill2 і ульта в кишені, мутація P15.
- **Клас 13** (документ гілки після merge): лічильник 2 → 3, `state.md:54`. Механізму досі немає, тож статус ВІДКРИТО з вищим пріоритетом.
- **Кандидат у клас 12:** S5 у headless пропускається мовчки. Рахувати його поки не пропоную, бо пропуск задокументовано.

## Пропозиції

1. `lethal_fight_check`: натискати в кишені I (skill2) і ульту так само, як U, і розширити негатив `skills` до P15.
2. Трасування крові: усі 4 режими (щонайменше Ink) і Medium/Low, два герої. Порівнювати також `Fighter._rng.state` і `CpuBrain._rng.state`.
3. Ink: сіяти `SmearShards` з `BloodFx.rng` або явно задокументувати, що це спільний RNG презентації. Виправити коментар у `BloodFx.gd:5`.
4. `bound()`: виправити коментар і журнал на «рівні за `==`, знак нуля може відрізнятися». Або повертати `clamp_arena(p)` при дефолтних центрі й радіусі — тоді тотожність буде буквальною.
5. `tight_station_probe`: друкувати в сентинелі чи receipt `S5=NOT MEASURED (headless)`.
6. Smoke: явно перевіряти `choko/skea.cpu_only == false`. Зараз випадок «hero without ultimate» покриває лише p1.
7. `BloodFx.decisive`: додати умову `flow.phase == FIGHT`.
8. Закріпити у lethal `rounds_to_win = 2` незалежно від глобального значення. Необов'язково.
9. T8: підказка паузи й рядок запечатаних навичок кажуть, що ворожий гак працює «in fights only». У смертельному бою він запечатаний — потрібне уточнення формулювання.
10. T1: почистити `state.md` (рядки 3, 22, 24, 54, 60–63, 83) і рядки «Статус» трьох Fix. Зробити гейт `state_anchor_check.py` для класу 13.
11. T6: додати `#4E0819` (тінь Muted) у Style-Guide.

## Відкрите після аудиту

- 78 зі 131 сценарію playable я не переміряла;
- вигляд крові на справжньому GPU;
- підтвердження картки кнопкою A;
- крайовий випадок калюжі (лише прочитано код);
- M3 і Forward+.

## Related

- [[ADR-024-Lethal-Fights-And-First-Enemy]] · [[2026-10-07-First-Enemy-Lethal-Fight]] · [[2026-10-07-Lethal-Fight-Core-Fix]] · [[2026-10-07-Blood-And-Content-Settings-Fix]] · [[2026-10-07-Camera-Readability-Iteration-2-Fix]] · [[2026-10-07-City-Skill-Hint-And-Comfort-Fix]] · [[ADR-004-Physics-Is-Presentation]] · [[recurring_class_register]] · [[2026-10-07-Camera-And-Gate-Review]] · [[2026-10-07-T1-Orchestration-Session]] · [[state]]
