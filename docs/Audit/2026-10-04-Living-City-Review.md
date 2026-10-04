# Living city — незалежний T4 review, 2026-10-04

**GREEN — технічний зріз.** Відтворений дефект підготовленого захвату виправлено та повторно перевірено. Фінальні smoke, 50 playable сценаріїв і гейти зелені. Це не приймання повної гри, художнього результату чи цільових пристроїв. Production/state аудитор не редагував.

## Докази фінального пакета

Власноруч прочитано AGENTS, constitution, T4, production diff і сирі журнали координатора командами `cat`, `rg`, `tail`. Перевірка виконувалася на Linux, Godot **4.6.3**. Після production smoke змінено лише teardown аудіотесту; повний playable runner повторено, production smoke не дублювався.

| Статус | Команда / сирий журнал | Фактичний результат |
|---|---|---|
| GREEN | `make check`, `/tmp/nir-living-complete.log` | 80 GDS / 0 помилок парсингу; smoke **164 / 19847 кадрів**, `SMOKE ЗЕЛЕНИЙ` |
| GREEN | `make check-playable`, `/tmp/nir-living-pass.log` | `PLAYABLE CHECK: 50 scenarios, 0 failures`; включно з негативними контролями |
| GREEN | `make gates`, `/tmp/nir-living-gates.log` | 80 GDS; `БАТАРЕЯ ЗЕЛЕНА` |
| GREEN | `/tmp/nir-living-pass/traversal.log` | **29 / 0**, без teardown помилок |
| GREEN | `/tmp/nir-living-pass/dodge-stamina.log` | **198 / 0**, без teardown помилок |
| GREEN | `/tmp/nir-living-pass/music.log` | `failures=0`, без ObjectDB/resource помилок |

Крім незалежного читання повної батареї, T4 самостійно виконав focused тести через `XDG_DATA_HOME=/tmp/review-data XDG_CACHE_HOME=/tmp/review-cache godot --headless --path game --script ../<файл>`; для physics-сценаріїв — `--fixed-fps 60`:

| Файл | Власний вимір T4 |
|---|---|
| `tools/npc/npc_check.gd` | 19 / 0 |
| `tools/npc/npc_runtime_check.gd` | 43 / 0 |
| `tools/input/limb_input_check.gd` | фінальний повтор 227 / 0 |
| `tools/grapple/traversal_check.gd` | 26 / 0 до додаткових трьох pad-перевірок; фінальні 29 / 0 прочитано вище |
| `tools/world/city_runtime_check.gd` | 68 / 0 |
| `tools/world/city_onboarding_check.gd` | 56 / 0 |
| `tools/audio/music_check.gd` | фінальний повтор із fixed-fps: failures=0, чистий вихід |
| `tools/combat/dodge_stamina_check.gd` | 194 / 0 до фінальних animation-перевірок; фінальні 198 / 0 прочитано вище |

## Закриті findings і строгість перевірок

**GREEN · виправлено P2: рання готовність ловити мотузку блокувала стрибок із землі.** До виправлення ROPE_REACH виконував лише ходьбу, а `Fighter._tick_grapple` не запускав звичайний jump. Власний repro: існуюча мотузка на x=6, герой на землі поза 2 м захвату; parkour по мотузці, потім jump. Тимчасова копія traversal у `/tmp/living_city_review.gd` викликала справжній `v_press(1, "jump")` і `_tick_grapple`: `REVIEW_REACH_JUMP grounded=true phase=6 velocity_y=0.0`.

Після bridge у Fighter той самий repro з `--fixed-fps 60` дав `grounded=false phase=6 velocity_y=10.6000003814697`. Фінальна штатна перевірка також містить grounded jump без витрати пристрою. Логи власного repro: `/tmp/living-city-review.log`, `/tmp/living-city-review-fixed.log`.

**GREEN · фізичні кнопки не дублюються.** Smoke знайшов дублювання X між crouch/detach і B між block/detach. Фінальне рішення: SOLO Z, SHARED лівий/правий Ctrl; B має один фізичний binding `block`, який Fighter у стані GRAPPLE трактує як release. Окремий gamepad label показує `B / Circle (while hanging)`. Власноруч звірено diff `SmokeTest.gd`: `_key_clash` і `_pad_clash` не послаблені; змінено лише help-твердження зі старого hold-контракту на санкціонований tap latch. Реальні Z/X і pad-події перевіряють окремі шляхи.

**GREEN · B не відкриває паузу під час gameplay.** CityHud реагує на `ui_cancel` лише у відкритій паузі; viewport B regression пройшов у власному запуску onboarding56/0. Camera fixture runtime справді наводить камеру на street anchor та перевіряє кандидата до пострілу; gameplay guard не обходиться.

**GREEN · ранні невдалі прогони не приховані.** Перший dodge-прогін без передбаченого `--fixed-fps 60` мав 66 failures; підтриманий runner дав 0. Початковий music-тест мав успішні assertions, але resource ERROR на виході: строгий runner правильно відхилив його. Teardown звільнив аудіосервіси й дочекався реального mixer часу; після цього власний повтор і повна батарея чисті.

## Візуальний огляд і межі

Власноруч переглянуто `/tmp/nir-traversal-shoulder/city_anchor_cue.png`: маркер ліхтаря та `E · HOOK · 8.4m` видно праворуч від торса Choko; компактна картка не перекриває центр. Прочитано lateral collision sweep камери; основний SpringArm sweep збережено. Один кадр не є перевіркою всіх ракурсів або FPS.

- `soundtracks.cfg` має порожні три слоти: перевірено wiring/fallback і нормалізатор як підготовлений інструмент, **не** слухову інтеграцію реальних Santos Soundtracks. Реальні файли T4 не отримував і loudness їх не вимірював.
- NPC — 12 постійних логічних мешканців, збережений seed, до 12 фактів та актори за радіусом. Локальна LLM не встановлена й не підключена; gateway — обмежений інтерфейс, не готовий мислячий агент.
- Replay перевіряє fixed-step стан. Повного запису/відтворення людської камери й усіх parkour ланцюжків аудит не підтверджує.
- Фізичний геймпад, Mac/Godot 4.7, комфорт пальців, фінальний художній вигляд і продуктивність не виміряні. Це межі технічного GREEN, не нові approval blockers.

## Related
- [[2026-10-04-Living-City-Traversal]] · [[2026-10-04-Living-Npc-Slice]] · [[2026-10-04-Santos-Soundtracks]] · [[2026-10-04-Dodge-Stamina]] · [[constitution]]
