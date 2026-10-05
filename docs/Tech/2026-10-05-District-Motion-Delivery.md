# Доставка пакета руху й читабельності

2026-10-05 · T8 Гермес · [[2026-10-05-District-Motion-And-Readability]].

## Версія та межі

Наступна версія у єдиному джерелі `game/project.godot` — **0.4.2**. Меню, пауза та macOS export читають цю версію через чинний `BuildInfo`/export staging; механізм stamped revision не змінено. Ця версія позначає локальний кандидат, доки PR, CI та publish не підтвердять конкретний SHA. Нових UI-функцій чи зміни іконки немає.

## Регресійний runner

Runner `tools/gates/playable_check.sh` тепер містить **62 сценарії**: усі попередні 60, включно з 12 негативними контролями, плюс `authored-evasion` (`AUTHORED_EVASION_COMPLETE checks=… failures=0`) та `city-camera` (`CITY_CAMERA_COMPLETE checks=… failures=0`). Обидва очікують exit 0; точні контракти погоджено з авторами. World-background перевірки входять у наявний `city-geometry`. Умови приймання лишаються спільними: очікуваний exit code, повний anchored sentinel, відсутність неочікуваних ERROR/SCRIPT ERROR, timeout 180 с. До негативних контролів належать лише чинні дозволені scoped assertion errors.

AST-порівняння з HEAD підтвердило наявність усіх старих case tuples, 62 унікальні назви, незмінні 12 negatives; код ізоляції saves й виконання/аналізу результатів побайтово незмінний. `bash -n` проходить. Це перевірка реєстрації, не заміна фактичного запуску 62 сценаріїв; його результат внесе координатор після freeze.

Окремий крок `.github/workflows/ci.yml` після `make check-playable` тепер запускає `city_camera_renderer_check.gd` у Xvfb із Mesa llvmpipe та явним `gl_compatibility`. CI встановлює й перевіряє `xvfb`, `xauth` та Mesa libraries; відсутній renderer не пропускається. Профіль XDG тимчасовий, process timeout 180 с із kill через додаткові 10 с, step timeout 5 хв. Потрібні rc 0, точний рядок `CITY_CAMERA_RENDERER_COMPLETE checks=4 failures=0`, trace потрібного renderer і відсутність `SHADER ERROR`, `SCRIPT ERROR`, `ERROR`. Журнал зберігається CI artifact навіть при відмові. Headless runner лишився без змін: native pixels — окрема обов'язкова перевірка.

YAML та shell синтаксис перевірені локально. Вісім контрольних журналів перевірили validator: чистий 4/0 приймається; відсутній/неповний sentinel, інший renderer, кожен із трьох типів помилки та зайвий суфікс completion відхиляються (**8/0**). Реальний запуск цього нового CI кроку потрібно підтвердити після фінального commit; локальний native pixel proof 4/0 описано в [[2026-10-05-District-Motion-Review]].

## Попередній main: live delivery checkpoint

Read-only перевірка 2026-10-05 для merged PR #176, main `6d929f8`, [macOS run 37245037969](https://github.com/santos-va/nooneisreal/actions/runs/37245037969): усі три jobs **build / verify-macos / publish — completed success**. Публікацію підтверджено також читанням фактичного manifest після завершення publish.

Сам [macos-main manifest](https://github.com/santos-va/nooneisreal/releases/download/macos-main/manifest.json), прочитаний через HTTPS, містить SHA `6d929f8f938686c2803de9aa47eeca40e85fb852`, архів **266022946 B**, SHA-256 `40bb99da97b4c43041ee061ab5bf6c22a6747c53e035d4b77dc8e62eaffa0a25`, Godot `4.7-stable`, signing `ad-hoc; not notarized`. Incremental index — **14962 B**, SHA-256 `c6be2c5bdee37d7fce218b20e58a856e73f930f84ec69435aa77443e555ca068`. Канал дійсно перейшов із попереднього `d9d12ec` на `6d929f8`. Це доставка версії 0.4.1; кандидат 0.4.2 ще не публікувався. Доступу до Applications чи LaunchAgent на Mac Santos немає; їхній фактичний стан тут не заявляється.

## Локальний PCK proof фінального code SHA

Виконано після codefreeze **`9685dfaa7d75829066ca54faf5c56c3fd820d91c`**: джерело — `git archive` саме цього commit у `/workspace/nooneisreal-evidence/district-motion/pck-9685dfa/source`, окремі XDG data/config/cache, Godot 4.7 stable. У staged копії додано лише `build_info.cfg` з повним SHA та його include filter разом із чинними JSON/audio filters. Незакомічений native renderer probe та пізніші working-tree зміни до pack не потрапили. Shared Godot/cache не використовувалися.

| Перевірка | Фактичний результат |
|---|---|
| Fresh import + `--export-pack macOS` | rc 0 / rc 0, без ERROR / SCRIPT ERROR / Parse Error |
| Порожній verifier + `pck_content_check.gd` | `PCK_CONTENT_COMPLETE quests=6 marker=verified audio=present`, rc 0 |
| Native `--main-pack` із порожнього verifier directory | `PCK_MOTION_COMPLETE checks=19 failures=0 version=0.4.2 revision=9685dfaa7d75829066ca54faf5c56c3fd820d91c`, rc 0 |

Native probe перевірив `ResourceLoader.exists/load` для `AuthoredDodgeMotion`, `AuthoredLandingMotion`, `CityCameraProximity`, `CityBackdrop` і `camera_proximity.gdshaderinc`. Матеріали `toon`, `outline`, `sword_dissolve`, `camera_cloth` реально відрендерено з pack при `camera_visibility=0.5`; компіляція include не видала помилок. Renderer — OpenGL Compatibility, Mesa llvmpipe, Xvfb :97. Це доказ включення ресурсів і native компіляції на Linux; не FPS/M3-приймання й не новий macOS publish. Незалежна перевірка пікселів, shadow guard та ігрових сцен належить [[2026-10-05-District-Motion-Review]].

Артефакт `/workspace/nooneisreal-evidence/district-motion/pck-9685dfa/district-motion.pck`: **208643364 B**, SHA-256 **`a4b3fc8a50260c88b1acd1371dba16596f373570c99d17218fe4e1b09775828d`**. District JSON SHA-256 — `7425712a66a223457a9e65a4ea7c611c75db7a76610a5343bc2788b43974c537`. У тій самій теці збережені `evidence.json`, `import.log`, `export.log`, `content.log`, `native.log`; зовнішній verifier — `/workspace/nooneisreal-evidence/district-motion/pck-preparation/motion_pack_check.gd`. Усі чотири журнали перевірені на ERROR/SCRIPT ERROR; є лише очікуване попередження VSync від Xvfb.

## Related

- [[2026-10-05-District-Motion-And-Readability]] · [[2026-10-05-District-Motion-Session]] · [[2026-10-05-District-Motion-Review]] · [[2026-10-05-District-Journey-Checkpoint]] · [[2026-10-05-District-Delivery]] · [[2026-10-05-Quest-Journal-And-Guide]] · [[state]]
