# Fix-журнал — фаза 1: керування, звук, арена на воді

**Роль:** T2 Гефест. **План:** [[2026-10-03-Production-Plan]] § Фаза 1. **Гілка:** `claude/friendly-ritchie-3ti2sm`.

## Звірка плану з репо (до роботи)

- Godot у контейнері не було (`which godot` → порожньо). Поставлено `Godot_v4.7-stable_linux.x86_64` з GitHub
  Releases у `/opt/godot`; `godot --version` → `4.7.stable.official.5b4e0cb0f`.
- Базова лінія: `make check` → `SMOKE ЗЕЛЕНИЙ`, 20 перевірок; `make gates` → `БАТАРЕЯ ЗЕЛЕНА`
  (wikilinks 0 зламаних, реєстр 24/24, ролі 8, GDS 31 файл).
- Усі шляхи з таблиці фази 1 існують (`InputRouter.gd`, `MainMenu.gd`, `Hud.gd`, `Sfx.gd`, `Backdrop.gd`,
  `GameState.gd`, `Fighter.gd`, `RigAnimator.gd`, `HitSpark.gd`, `CharacterData.gd`); нові (`WaveField.gd`,
  `water_toon.gdshader`, `tools/audio/build_sfx.sh`) — створюються.
- Дрібні розбіжності, не блокують: план 1.2 каже `.ogg`, а наявні SFX — `.wav` і `Sfx.gd` вантажить лише
  `.wav` → `Sfx` вчиться обом розширенням. `~/Downloads/nir-audio/` у хмарі немає → `build_sfx.sh`
  перевіряю на синтетичних zip-ах, реальний прогін — на Mac у Santos.
- `water_balance` — число бою (зона Ареса), але значення 0.85 дав Santos ([[Stage-River]]); пишу з
  позначкою PLACEHOLDER.

## 1.1 Профілі клавіатури SOLO / SHARED

- `InputRouter.gd`: при старті знімає клавіатурні події кожної `p1_/p2_` дії з `project.godot` (це SHARED),
  `apply_profile()` перебудовує лише клавіатурну половину `InputMap`; геймпад не чіпається. SOLO: P1
  `A D W/Space S LShift(dash) E(grapple) · J K L U I O`, P2 без клавіш. Профіль у `user://settings.cfg`
  (`[input] keyboard_profile`), дефолт SOLO.
- `_input()` теж пише натиски в буфер — тап коротший за фізкадр не губиться.
- Меню: кнопка `KEYBOARD: ◂ SOLO / SHARED ▸`, футер і HUD-підказка беруться з `InputRouter.hint_text()`.
- Smoke: інваріант профілів + справжні `InputEventKey` через `Input.parse_input_event`:
  SOLO `J` → P1 `light`, SHARED `K` → P2 `jab_elbow`. `make check` → 23 перевірки, зелений.
- Предмет: для всіх профілів P і всіх клавіш k: k веде рівно до однієї дії, і в SOLO жодна дія P2 не має клавіші.
- Негативний контроль (3 форми, кожна → `[smoke] FAIL`, файл відновлено):
  A) `J` віддано `p2_light` → «P2 has key J in SOLO»; B) `apply_profile` не стирає старі клавіші →
  «key E in both p1_skill2 and p1_grapple»; C) SOLO light на `F` → «J did not start a P1 attack».

## 1.3 Перешарувати синтетичні удари

- `tools/audio/synth_hits.py` (stdlib, сіди фіксовані → той самий результат): рецепт [[07-Audio]] —
  транзієнт 2–6 кГц + тіло 100–400 Гц + саб 40–70 Гц, компресор (1 мс, 4:1) → tanh soft clip → пік −1 dBFS.
  Перезаписано 7 файлів, додано 10 варіантів (`hit_light_2/3`, `hit_heavy_2/3`, `block_2/3`, `whoosh_2/3`,
  `kunai_2`, `sword_2`). Усі 17 у реєстрі (`make gates` → РЕЄ 34/34).
- Виміряно `ffmpeg -af volumedetect` (mean / max dBFS, до → після):
  `hit_light` −17.5/−6.0 → −18.7/−1.0 · `hit_heavy` −12.1/0.0 → −16.7/−1.0 · `block` −9.2/0.0 → −23.2/−1.0 ·
  `whoosh` −55.2/−46.2 → −18.9/−6.0 · `kunai` −15.5/0.0 → −19.9/−1.0 · `sword` −18.9/−4.7 → −11.8/−1.0 ·
  `crit` −17.3/−0.4 → −18.4/−1.0. Пік ≤ −1 dBFS — виконано. Старі `hit_*`/`block`/`kunai` кліпували (пік 0.0),
  тому їхній mean був вищим; whoosh раніше був майже нечутний (−46 dBFS).
- Чесно: це все ще синтетика. «Соковитість» перевіряє лише слух Santos; старі версії — у
  `git show 0c2f86c:game/assets/audio/sfx/<name>.wav`.

## 1.2 Бібліотеки звуків → гра

- `tools/audio/build_sfx.sh` (обгортка) → `build_sfx.py`: zip-и з `~/Downloads/nir-audio/` (або `NIR_AUDIO`) →
  розпаковка → для кожного рецепта (`sfx_recipes.tsv`) і варіанта: шар = файл за глобом, обрізка тиші,
  `max_ms`, фейд, моно 44.1 кГц, gain, затримка → `amix` → `acompressor` (1 мс, 4:1) → `alimiter` −1 dBFS →
  пік-нормалізація −1.5 dBFS → `.ogg` (libvorbis q6) → перевірка піку → рядок у [[Textures-Registry]].
- Zip без рядка ліцензії в `sfx_sources.tsv` → **відмова**, rc=1. Старі `.wav` скрипт не видаляє (видалення
  ассетів — Red-зона); `Sfx.gd` бере `.ogg` раніше за `.wav`.
- `Sfx.gd`: `.ogg|.wav`, `<name>_2…_8` → `AudioStreamRandomizer` (без повторів), шина `SFX`:
  `AudioEffectCompressor` (−12 dB, 4:1, 1 мс) → `AudioEffectLimiter` (стеля −1 dB); pitch ±6 %.
- Перевірено на синтетичному zip у scratch (не в репо): без ліцензії → «ВІДМОВА», rc=1; з ліцензією → 14 `.ogg`,
  піки −1.2…−2.2 dBFS, rc=0; повторний прогін → у реєстрі ті ж 14 рядків (ідемпотентно); порожня тека → rc=2.
- **Не перевірено:** реальні паки (Kenney/Sonniss/OGA) — у хмарі їх немає; глоби в `sfx_recipes.tsv` —
  заготовка, після першого `--list` на Mac їх треба підігнати під справжні імена файлів.
- Smoke: шина SFX з 2 ефектами; `hit_light` 3 варіанти, `hit_heavy` 3, `whoosh` 3.

## 1.4a Фон річки — вежі в кадрі

- Кадр «до» (`xvfb-run … --screenshot`): видно лише набережну, вежі обрізані. Підтверджено.
- `GameState.STAGES[river].backdrop`: квад 50.9×20 м, центр y 7.62, `mirror_x` 2.4, `img_top` 0.4;
  `backdrop.gdshader` — дзеркальний повтор по x і небо над картинкою з верхнього рядка зображення.
  Кадр «після»: обидві вежі з куполами в кадрі. Ціна: по краях дзеркальна копія міста — до outpaint у фазі 2 (2.6).

## 1.4 Арена «Річка» на воді

- `scripts/core/WaveField.gd` (Resource; **не** `scripts/arena/`, як у плані: його читає `Fighter`, а
  fighter/ і arena/ не імпортують одне одного) — 3 біжучі синусоїди + вал; час = власний лічильник фізкадрів/60.
  Параметри — `data/stages/river_water.tres`, усі PLACEHOLDER. Чесно: план каже «хвилі Герстнера»; тут
  лише їхня висотна складова (синуси), без горизонтального зсуву.
- `shaders/water_toon.gdshader` рахує ту ж формулу з uniforms; `scripts/arena/Water.gd` тикає поле
  (пріоритет −50: після `InputRouter`, до бійців), оновлює шейдер, малює кільця тримання (пульс, тьмяніють на валі).
- `Fighter`: `floor_y()`/`on_ground()` замість `is_on_floor()` (усі 12 місць + `GrappleHook`), «прилипання» до
  поверхні в `_post_move`, хода × (0.85 + 0.15 × balance), STUMBLE (новий стан у кінці enum) на першому кадрі
  валу, якщо не в блоці і balance < сили валу; у STUMBLE не атакує, блок знімає STUMBLE; вставання +6 кадрів.
  Кам'яна підлога опускається нижче найглибшої западини (ловить регдоли), її меш ховається.
- `CharacterData.water_balance` 0.85 для обох (слово Santos, PLACEHOLDER). `RigAnimator`: нахил таза =
  atan(нахил хвилі) × (1.6 − balance) + імпульс у флінч на старті валу.
- Smoke (стадія `river`, двічі з однаковим скриптом вводу): ніхто не провалюється (мін. зазор −0.017 м при
  допуску −0.05), обидва прогони однакові на кадрі 600 (Σ|Δ| 0.000000), вал 0.7 валить balance 0.55 і не
  валить того, хто в блоці; у STUMBLE удар не стартує; balance 0.85 на валу 0.7 стоїть.
- Предмет: для всіх кадрів t і бійців f на воді: y(f,t) ≥ h(x,t) − 0.05; для всіх валів s: STUMBLE ⇔
  (не в блоці ∧ balance < s); для всіх прогонів з однаковим вводом: стан на кадрі t однаковий.
- Негативний контроль (кожен → `FAIL`, файл відновлено): A) без «підлоги з води» → «P2 sank (y 0.000,
  surface 0.069)»; B) вал ігнорує блок → «P1 stumbled while guarding (stumbles 0 → 1)» — **перша версія тесту
  це пропускала** (STUMBLE і вихід у BLOCK в одному кадрі), виправлено на лічильник `stats.stumbles`;
  C) час хвиль від `Time.get_ticks_usec()` → «two runs differ at frame 600 (Σ|Δ| 0.265814)».
- Не зроблено з [[Stage-River]] (не в рядку 1.4 плану): бризки, плавучість регдола, слід за флешем Skea.

## 1.5 Удари сильніші на вигляд

- `RigAnimator.attack_ext()`: замах −0.35 за спокоєм (45 % startup) → різкий вихід → перельот 1.22 на
  першому активному кадрі → осідання. Пози атаки тримаються кроками 12 fps (кожні 5 кадрів) + ключові
  кадри startup/active/recovery. Кадрові дані (`.tres`) не змінено.
- Смір (`SmearShards`) уздовж удару на першому активному кадрі; у `HitSpark` — чорнильні лінії удару
  (5 / 8 / +3 на криті). Флінч за зоною з `_zone_for`: high — голова назад, mid — згинається в корпусі,
  low — підгинаються коліна.
- Smoke: крива (−0.35 / 1.22 / 0 у кінці) і «поза атаки ніколи не змінюється 3+ кадри поспіль»
  (чистий прогін: 7 змін, найдовша серія 2).
- Предмет: для всіх кадрів атаки: поза змінюється лише на кроці 12 fps або на ключовому кадрі.
- Негативний контроль: A) без степінгу → «26 changes, longest run 10»; B) `STEP_FRAMES=1` → те саме; **перша
  метрика (кількість змін ≤ кадри/5+6) цей злам пропускала** — замінено на найдовшу серію;
  C) `ANTICIPATION=0` → «wind-up 0.00».
- Кадри для огляду: `--smoke --shots=DIR` під `xvfb-run` → `00a_strike_windup`, `00b_strike_impact`,
  `09_river_swell_stumble`, `10_river_fight`.

## Підсумок фази 1

- `make check` → `SMOKE ЗЕЛЕНИЙ`, `[smoke] ALL OK (36 checks)` (було 20). `make gates` → `БАТАРЕЯ ЗЕЛЕНА`
  (РЕЄ 34/34, GDS 33 файли). Makefile: `--quit-after` 4000 → 12000 (smoke тепер вантажить арену тричі).
- Залишок `ERROR: N resources still in use at exit` був і до фази (базова лінія), не блокує rc.

## Related
- [[2026-10-03-Production-Plan]] · [[ADR-009-Solo-Keyboard-Layout]] · [[05-Platforms-Input]] · [[07-Audio]] · [[Stage-River]] · [[state]]
