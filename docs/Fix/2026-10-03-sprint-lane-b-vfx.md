# Fix-журнал — спринт, смуга B: VFX у грі, крок 1 (процедурні шейдери)

**Роль:** T2·B Гефест, 2026-10-03. **Від `main`** `002f411` (після PR #109). **План** — [[2026-10-03-Sprint-Arenas-VFX]] § Смуги, рядок B.
Кредитів — 0 (арт від смуги D ще не прийшов).

## Звірка плану (до роботи)

| що в плані | що в коді | рішення |
|---|---|---|
| крок 0: межа smoke ×2 до стадій A і B | `git merge-base --is-ancestor f94f0c8 origin/main` → ні; коміт лише на `origin/claude/friendly-ritchie-3ti2sm`, відкритого PR немає (`gh pr list`); у `main` — `_f > 19000`, `--quit-after 20000` | для B не блокер: стадія B іде **в одному кадрі** (ефекти кроку руками), кадрів smoke не їсть — 18843 до і після |
| виклики — у `skills/*Fx.gd` | сліди Chrono Step `Fighter.gd:558`, Flash Step `:590-592`, вуаль `:1205`; приземлення — ефекту немає; електро — ні скіла, ні власника в GDD (лише звук `flash`, [[07-Audio]]) | Santos (опитування в сесії): **«fx/ на місці + новий шейдер»** — переробити вигляд класів у `game/scripts/fx/`, `Fighter.gd` не чіпати. Дим приземлення й електро — крок 2 після слова Дедала |
| «ефекти — лише презентація» | вже порушено до мене: `CpuBrain.gd:27` читає `SmokeCloud.covers()`, `TimeStopFx` сам заморожує суперника | `radius`, життя й `covers()` диму не змінено; у `TimeStopFx` змінено лише рядки вигляду. Дедалу — на розгляд |

## Що зроблено

| файл | що |
|---|---|
| `game/shaders/fx_common.gdshaderinc` | шум (value + 2 октави), палітра [[Style-Guide]]: лінія `#2B2230`, тінь `#B07AA6` — **у лінійних значеннях** |
| `game/shaders/fx_stroke.gdshaderinc`, `fx_ink.gdshader`, `fx_glow.gdshader` | штрих із рваним «паперовим» краєм і ступінчастим шумовим згоранням; на фронті згорання — чорнило (ink) або спалах (glow); `rim` — френелевий контур для привидів |
| `game/shaders/fx_smoke.gdshader` | cel-клуб: шум випинає поверхню, одна межа світло/тінь (тінь = база × `#B07AA6`), тонкий чорнильний обідок, згорання ступенями |
| `game/shaders/fx_spark.gdshader` | зірка удару (білборд): біле ядро + промені нерівної довжини, 4 / 8 на криті — заміна квадратного плейсхолдера ([[VFX-Direction]] § Далі) |
| `game/shaders/fx_chrono_screen.gdshader` | стоп-час Choko на весь екран: картинка стікає в той самий сіро-блакитний, що й `desat` у `toon.gdshader`, сильніше на краях; кільце з 12 рисок-«годинника» біжить від центру |
| `game/scripts/fx/FxShader.gd` (новий) | фабрика матеріалів; зерна — з **власного** RNG, не глобального |
| `Afterimage.gd`, `SmearShards.gd`, `SmokeCloud.gd`, `HitSpark.gd` | ті самі API й виклики, новий вигляд; `HitSpark` більше не бере глобальний `randf_range` |
| `game/scripts/skills/TimeStopFx.gd` | лише вигляд: сфера → френелева бульбашка, `ColorRect` → `fx_chrono_screen` |
| `game/scripts/core/SmokeTest.gd` | стадія `_check_lane_b_fx()` + один рядок виклику в `_ready` |

**Моя помилка, виправлена до коміту:** спершу записав `#2B2230` і `#B07AA6` у шейдер як sRGB-числа. Шейдер рахує в лінійному просторі,
тож «чорнильний» обідок диму вийшов світло-бузковим (видно на знімку з GPU). Переведено формулою sRGB → linear (python):
`#2B2230` → `(0.0242, 0.0160, 0.0296)`, `#B07AA6` → `(0.4342, 0.1946, 0.3813)`.

## Перевірка

| команда | вихід |
|---|---|
| `make check` на `main` `002f411` (база) | `[smoke] ALL OK (133 checks) in 18843 frames`, rc=0 |
| `make check` на гілці | `[smoke] ALL OK (134 checks) in 18843 frames`, rc=0; рядок `lane B: 5 effects spawn without touching the global RNG, draw with fx_* shaders, ghost burns in 4 steps, all free themselves (smoke after 181 frames, covers() contract kept)` |
| хеші реплеїв, база → гілка | `duel replay plane` 1989487740 → 1989487740; `free` 1366043150 → 1366043150; `3b` 2620994242 → 2620994242 — симуляцію не зачеплено |
| `make gates` | `БАТАРЕЯ ЗЕЛЕНА`, rc=0 |
| GPU (Metal, вікно) — тимчасовий скрипт-прев'ю поза комітом, `godot --path game -s …` | 6 шейдерів зібрались, помилок у виводі немає; 4 знімки — привид, чорнильний двійник, шматки, дим, зірка, екран стоп-часу |

`ERROR: 24 resources still in use at exit` (аудіопотоки `Sfx`) — **є й на чистому `main`** (той самий прогін `--smoke-only=cam`
до і після `git stash`), від смуги B не залежить.

**Предмет:** для всіх ефектів E ∈ {Afterimage, SmearShards, SmokeCloud, HitSpark}: створення E не зсуває глобальний RNG, E малюється
шейдером `fx_*`, згорає ступенями й сам себе звільняє, а SmokeCloud тримає контракт `radius` / життя / `covers()`.

| негативний контроль (форма зламу) | вихід |
|---|---|
| NC1 `HitSpark` знову бере глобальний `randf_range` | `FAIL lane B: spawning effects moved the global RNG (3670234259, want 641615738)` |
| NC2 `SmearShards` не викликає `queue_free()` | `FAIL lane B: SmearShards is still alive after 600 frames` |
| NC3 `Afterimage` згасає плавно (без `Fx.stepped`) | `FAIL lane B: Afterimage fades through 18 values — smooth, not drawn in steps` |
| NC4 `SmokeCloud.radius = r * 1.2` | `FAIL lane B: SmokeCloud changed its contract — radius 2.40` |
| NC5 `SmokeCloud` бере зерно з глобального `randi()` | `FAIL lane B: spawning effects moved the global RNG (494098138, …)` |

Не покрито: що шейдер **компілюється** — headless-рендер його не збирає; це перевірено лише прев'ю на GPU в цій сесії, не гардом.

## Далі (крок 2, не в цьому PR)

- Дим приземлення, нові сліди Chrono / Flash Step — потрібні рядки виклику в `Fighter.gd` (слово Дедала про межі смуги).
- Електро — немає власника в GDD (Арес / Дедал).
- Гліф RECORD і флипбуки диму, слідів, іскор — від смуги D ([[VFX-Direction]]); `RecordMarker` поки старий.

## Related
- [[2026-10-03-Sprint-Arenas-VFX]] · [[VFX-Direction]] · [[Style-Guide]] · [[07-Audio]] · [[state]]
