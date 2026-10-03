# Fix-журнал — Prototype 0.3: вільний рух (0.3-1), камера дуелі (0.3-2), гарпун у 3D (0.3-3)

**Роль:** T2 Гефест. **План:** [[2026-10-03-Prototype-0.3-Free-Movement]]. **Issue:** santos-va/nooneisreal#27.
**Гілка:** `claude/friendly-ritchie-3ti2sm` (перезапущена від `main` `4dd6c84`, бо PR #21 уже змерджено).

## Звірка плану з репо (до роботи)

- `git log --oneline -1` → `4dd6c84 Merge pull request #28`. `godot --version` → `4.7.stable.official.5b4e0cb0f`.
- Базова лінія: `make check` → `[smoke] ALL OK (36 checks)`, `SMOKE ЗЕЛЕНИЙ`.
- Рядки з § «Що є зараз» перевірено через `sed -n <n>p`, вони збігаються: `Fighter.gd:22, 57, 613–614, 670, 690, 714, 986,
  1038, 1128, 1152–1153`, `FightCamera.gd:17–23`, `InputRouter.gd:130`, `GrappleHook.gd:21, 125–129`, `WaveField.gd:86`,
  `SmokeTest.gd:62`.
- Розбіжності повернуто Дедалу коментарем у #27 (issuecomment-5964184886):
  1. `Arena.tscn` `Ground` має `size = Vector3(60, 1, 12)`, а коло R = 12.5 виходить за підлогу по z.
  2. Площина зашита ще й тут: `Fighter.gd:155, 472–473, 919, 986, 990, 1038, 1129`, `get_pulled(target_x)`,
     `RigAnimator.gd:195, 208, 271`, `GrappleHook.gd:95, 139, 204, 207`, скіли.
  3. Клавіш обходу план не фіксує, а W/S і стік-вниз уже зайняті стрибком і присідом.
  4. #24 (PR #29) ще не змерджено, #25 і #26 не готові, тож усі числа — PLACEHOLDER.

## 0.3-1 Вільний рух за прапорцем

- `GameState.free_move := false`, `set_free_move()` (одразу перебудовує клавіатуру), ключ запуску `-- --free-move` (`Main.gd`).
- `scripts/core/DuelFrame.gd` (новий): `right` показує, куди на екрані «праворуч». Вектор іде вздовж лінії P1→P2,
  оновлюється раз на фізкадр (`InputRouter.frame()`) і зберігає знак, тож при обміні сторонами не перекидається.
  Якщо бійці ближче за 0.05 м, лишається попередній напрям.
- `InputRouter`: дії `up`/`down` (створюються в рантаймі), `move(player) -> Vector2`; у площині y = 0.
  `apply_profile()` при `free_move` переносить W/↑ зі `jump` на `up`, S/↓ з `crouch` на `down` (TODO #26).
- `Fighter.gd`: `forward: Vector3`; `facing` у 3D визначає бік екрана (`forward · duel.right`). Кожна зміна стоїть за `_free()`,
  тож код площини лишився тим самим:
  - рух: уздовж лінії йде на walk/back-walk, впоперек — обхід зі збереженням дистанції (дуга, а не спіраль);
  - стрибок, повітря, деш і flash-step — за вектором стіка;
  - lock-on у `_update_facing`;
  - трекінг: за startup атака доповертає не більше `tracking_deg` сумарно;
  - хітбокс і дебаг-бокс — через базис `yaw()`; відкидання, пушбек блоку, KO-імпульс — по `attacker.forward`;
  - блок: атакувальник у межах `BLOCK_HALF_ANGLE` від `forward`;
  - коло `clamp_arena()`, push-box радіально (у спільній точці — вздовж `-forward`);
  - регдол і KO тримають z.
- `MoveData.tracking_deg = 30.0` (PLACEHOLDER, кут узято з перевірки плану). `RigAnimator`: поворот рига — `f.yaw()`,
  фаза ходьби рахується за `velocity · forward`.
- `Arena.gd`: при `free_move` підлога по z = 2·(R + 1) = 27 м. Режим площини сцену не міняє.
- Предмет: для всіх кадрів у `free_move` боєць у наземних станах дивиться на суперника, обхід тримає дистанцію,
  атака доповертає рівно min(кут, `tracking_deg`), а позиція не виходить за коло R.

## 0.3-2 Камера дуелі

- `scripts/arena/DuelCamera.gd` (новий) і вузол `DuelRig` → `SpringArm3D` (mask 1, margin 0.2) → `Camera3D` в `Arena.tscn`.
  Рамка камери (відстань, підйом, згладжування `pow(0.0015, delta)`) — як у `FightCamera`. Yaw іде за `GameState.duel.right`.
- `Arena.gd`: у `free_move` вимикає `CameraRig` і робить `DuelRig` поточною камерою. У площині `DuelRig` видаляється
  (`queue_free`), тож площина не змінюється. Тряска йде на активну камеру. `FightCamera.gd` не змінено.
- Предмет: для всіх обходів і обмінів сторонами камера повертається не швидше за `MAX_TURN_DEG_PER_FRAME` (6°, PLACEHOLDER)
  і тримає обох бійців у кадрі.

## Перевірка

- `make check` → `[smoke] ALL OK (45 checks) in 3864 frames`, `SMOKE ЗЕЛЕНИЙ`. Перші 36 — старі, з `free_move=false`.
  Нові:
  - `free move: duel camera current; SOLO W/S → sidestep (TODO #26), no key clashes in SOLO/SHARED`
  - `sidestep 90° in 102 frames: forward 0.89° off the opponent, distance 6.000 → 6.000 (arc, not spiral), p1 z -6.00`
  - `tracking: light started 60° off the opponent turned 30.0° and hit (hp 900 → 858)`
  - `tracking negative control: with tracking_deg 0 the same strike turns 0.0° and misses`
  - `arena circle: walked into the edge, max radius 12.500 ≤ 12.50`
  - `duel camera: 360° sidestep in 271 frames, max turn 1.34°/frame ≤ 6.0, at most 13.0° off side-on ≤ 25.0 (both PLACEHOLDER), both fighters in view`
  - `duel camera: side swap without a flip, max turn 1.20°/frame; screen x p1 1208, p2 392`
- `make gates` → `БАТАРЕЯ ЗЕЛЕНА` (GDS 35 файлів).
- Негативні контролі: мутація → smoke → відновлення; результат див. нижче.

Скрипт мутує файл, запускає `godot --headless --path game --quit-after 12000 -- --smoke` і відновлює файл
(`git status` після прогону: лише мої зміни). Кожна мутація має дати `[smoke] FAIL`.

| мутація | що ламає | результат |
|---|---|---|
| T1 `step := ang` | трекінг без межі | `FAIL tracking: … turned 60.0° (want hit, 30.0° = tracking_deg)` |
| T2 `_track()` не викликається | трекінгу немає | `FAIL tracking: 60°-off light hit false, turned 0.0°` |
| T3 `rotated(…, -step)` | трекінг не в той бік | `FAIL tracking: 60°-off light hit false, turned 30.0°` |
| S1 без корекції орбіти | обхід іде спіраллю | спершу **пройшло** (допуск 0.3 м); після посилення до ±0.01 м — `FAIL … distance 6.000 → 6.074` |
| S2 без lock-on | боєць не дивиться на суперника | `FAIL sidestep 90°: forward off by 91.80°` |
| R1 без `clamp_arena` | коло не тримає | `FAIL arena circle: p1 at radius 12.546 > 12.50` |
| C1 `DuelFrame` без збереження знака | камера перекидається | `FAIL duel camera on a side swap: max turn 17.29°/frame` |
| C2 камера сама рахує лінію P1→P2 | те саме, оминаючи `DuelFrame` | `FAIL … side swap: max turn 17.41°/frame` |
| C3 yaw камери зафіксовано | камера не йде за лінією | спершу **пройшло**; після нової перевірки «не далі 25° від положення збоку» — `FAIL … off side-on 90.0° (bound 25.0)` |

Два мутанти (S1, C3) спершу не впіймались. Тести посилено, і після цього обидва дають `FAIL`.
Після посилення `make check` → `ALL OK (45 checks)`: дистанція `6.000 → 6.000`, камера відходить від положення збоку максимум на 13.0°.

## 0.3-3 Гарпун у 3D

**Звірка:**
- Правило — [[04-Grapple-System]] § «Конус вибору в 3D» (Арес, #25, змерджено в `main`). Конус по yaw із напівкутом
  `grapple_cone_deg` = 30° (ДИЗАЙН). Вісь — стік відносно камери, а без стіка — погляд. Оцінка `відстань − 0.6·вперед`, де
  «вперед» — проєкція на вісь конуса. `pull_enemy` тягне вздовж погляду в тому самому конусі ≤ 14 м.
  [[02-Combat-System]]:156 каже те саме: `grapple_cone_deg` у `CharacterData`, 30.
- Код до змін: `GrappleHook.gd:95, 139, 204, 207` рахують лише по x, `drive()` обнуляє `velocity.z`, а п'ять якорів `Arena.tscn`
  стоять на лінії z = 0 (`x = −9.5, −4.5, 0, 4.5, 9.5`).
- Розбіжність, яку повертаю Дедалу: план просить «якорі арен у 3D по колу», але позицій ніде немає. Тимчасово, лише при
  `free_move`, `Arena._anchors_around()` дублює кожен бічний якір, повернутий на 90° навколо центру. Висоти й відстані
  беру наявні, нових чисел немає. Це PLACEHOLDER розкладки.

**Зміни:**
- `CharacterData.grapple_cone_deg = 30.0`. У `.tres` поле не пишу, бо значення там — зона Ареса, а дефолт збігається з його числом.
- `GrappleHook`: `aim_axis()` і `_in_cone()` (yaw, `cos(a) ≥ cos(cone)`); `_best_anchor` відкидає якорі поза конусом.
  Свінг у 3D: кермо — стік відносно камери, `velocity.z` не обнуляється, а при досягненні якоря горизонталь обмежена 8 м/с
  (той самий кламп, що й по x).
- `Fighter.get_pulled_to(target: Vector3, stun)` — версія `get_pulled(target_x)` для 3D.
- **Баг з 0.3-1:** `_friction()` у 3D гальмував x і z окремо, тож по діагоналі рух гас у √2 раз швидше. Тепер `Vector2.move_toward`
  гальмує вектор. Знайшов його тест підтяжки: P2 недолітав на 0.91 м, після виправлення — 0.09 м.
- Предмет: для всіх положень і стіків у `free_move` обраний якір лежить у конусі навколо осі прицілу, зип і свінг доводять
  до якоря в глибині, а підтяжка ставить суперника на 1.25 м перед бійцем незалежно від напрямку.

**Перевірка:** `make check` → `[smoke] ALL OK (48 checks) in 4069 frames`, `SMOKE ЗЕЛЕНИЙ`. Нові:
- `grapple cone 30°: stick up → Anchor2Z, down → Anchor4Z, neutral (gaze) → Anchor4; next to Anchor2 with stick up → Anchor1Z (the lamp beside is outside the cone)`
- `grapple 3D: reeled to the anchor at z -4.50 (closest 1.28 m), p1 now at z -5.07`
- `grapple pull 3D: P2 from (3, 3) to 0.09 m off the spot 1.25 m in front of P1 (z moved 2.05)`

**Негативні контролі 0.3-3** (той самий скрипт: мутація → smoke → відновлення):

| мутація | що ламає | результат |
|---|---|---|
| G1 без перевірки конуса | хапає будь-який якір | спершу **пройшло**: на тій розкладці найкраща оцінка й так була в конусі. Додано позицію поруч із ліхтарем Anchor2, і тепер `FAIL grapple cone (up_near_lamp): Anchor2 is 100.6° off the aim` |
| G2 вісь лише з погляду | стік ігнорується | `FAIL grapple cone: up Anchor4, down Anchor4, neutral Anchor4` |
| G3 вибір як у площині | лише вісь x | `FAIL grapple cone (up): Anchor4 is 90.8° off the aim (cone 30°)` |
| G4 свінг з `velocity.z = 0` | гарпун плаский | `FAIL grapple 3D never attached/released (state 13, attached true)` |
| G5 підтяжка по x | старий `get_pulled(target_x)` | `FAIL grapple pull 3D: … 1.90 m …, z moved 0.00` |
| G6 тертя окремо по x і z | баг 0.3-1 | `FAIL grapple pull 3D: … 0.91 m …` |

Після контролів, без зміни поведінки в тестах: `GrappleHook` читає стік через публічний `Fighter.wish()`, а не через `_wish`.
Кламп швидкості на відпусканні в 3D тепер лише векторний: раніше перед ним ще спрацьовував площинний кламп x.
Підказка HUD у 3D: «(no anchor in cone → pull)» замість «S+E pull». Контролі G1–G6 проганялись до цієї чистки.

Після посилення `make check` → `ALL OK (48 checks) in 4072 frames`; новий рядок конуса:
`… next to Anchor2 with stick up → Anchor1Z (the lamp beside is outside the cone)`.

## Кадри (Xvfb + llvmpipe, `--rendering-driver opengl3 --rendering-method gl_compatibility`)

- Режим площини: `-- --screenshot=DIR` → 4 кадри OK. Вільний рух: `-- --free-move --screenshot=DIR` → 4 кадри OK.
  CPU у 3D поки ходить лише вздовж лінії (це крок 0.3-4), тож кадр за складом той самий, що в площині, — камера
  зблизька читається як бічна. Файли кадрів 230 різняться (`cmp` → differ), бо відрізняється рядок підказки.
- `-- --smoke --shots=DIR` → `ALL OK (45 checks)` плюс кадри `11_free_sidestep_90`, `12_free_duel_camera`, `13_free_side_swap`; після 0.3-3 → `ALL OK (48 checks)` і кадр `14_free_grapple_zip`.

![Площина, 0.2](../assets/screenshots/2026-10-03-0.3-plane-mode.png)
![Обхід 90°](../assets/screenshots/2026-10-03-0.3-free-sidestep-90.png)
![Камера дуелі під кутом](../assets/screenshots/2026-10-03-0.3-free-duel-camera.png)
![Зип у глибину (0.3-3)](../assets/screenshots/2026-10-03-0.3-free-grapple-zip.png)

## Не перевірено / ризики

- **Фон — плаский квад на z = −18** (`Backdrop.gd`): коли камера дуелі повертається, за ареною видно порожнє небо (кадр
  `12_free_duel_camera`). Для 3D потрібне оточення на 360°. Це питання арту й плану (Аполлон, Дедал), не цього кроку.
- Меш води `Water.gd` покриває z від +7 до −18, а коло — ±12.5: на річці в 3D бійці можуть стояти поза мешем (крок 0.3-5).

- Гра на Mac у 3D. Перевірено лише headless і Xvfb/llvmpipe.
- CPU (ходить лише вздовж лінії), вода по z, скіли — кроки 0.3-4, 0.3-5 і #25. Гарпун у 3D — зроблено (0.3-3).
- Розкладка якорів у 3D — PLACEHOLDER (повернуті двійники), чекає Дедала й Ареса. Дрон-якір (ADR-011) — окремий крок #19.
- Підтяжка ворога в 3D з клавіатури SOLO недоступна: S тепер обхід, а присід без клавіші (TODO #26). Лишається фолбек «немає якоря в конусі».
- Детермінізм `free_move` двома прогонами — крок 0.3-6.

## Related
- [[2026-10-03-Prototype-0.3-Free-Movement]] · [[2026-10-03-Free-Movement-0.3-1-2]] · [[state]] · [[ADR-004-Physics-Is-Presentation]] · [[02-Combat-System]]
