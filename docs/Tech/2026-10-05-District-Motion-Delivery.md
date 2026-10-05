# Доставка пакета руху й читабельності

2026-10-05 · T8 Гермес · [[2026-10-05-District-Motion-And-Readability]].

## Версія та межі

Наступна версія у єдиному джерелі `game/project.godot` — **0.4.2**. Меню, пауза та macOS export читають цю версію через чинний `BuildInfo`/export staging; механізм stamped revision не змінено. Ця версія позначає локальний кандидат, доки PR, CI та publish не підтвердять конкретний SHA. Нових UI-функцій чи зміни іконки немає.

## Регресійний runner

Runner `tools/gates/playable_check.sh` тепер містить **62 сценарії**: усі попередні 60, включно з 12 негативними контролями, плюс `authored-evasion` (`AUTHORED_EVASION_COMPLETE checks=… failures=0`) та `city-camera` (`CITY_CAMERA_COMPLETE checks=… failures=0`). Обидва очікують exit 0; точні контракти погоджено з авторами. World-background перевірки входять у наявний `city-geometry`. Умови приймання лишаються спільними: очікуваний exit code, повний anchored sentinel, відсутність неочікуваних ERROR/SCRIPT ERROR, timeout 180 с. До негативних контролів належать лише чинні дозволені scoped assertion errors.

AST-порівняння з HEAD підтвердило наявність усіх старих case tuples, 62 унікальні назви, незмінні 12 negatives; код ізоляції saves й виконання/аналізу результатів побайтово незмінний. `bash -n` проходить. Це перевірка реєстрації, не заміна фактичного запуску 62 сценаріїв; його результат внесе координатор після freeze.

## Попередній main: live delivery checkpoint

Read-only перевірка 2026-10-05 для merged PR #176, main `6d929f8`, [macOS run 37245037969](https://github.com/santos-va/nooneisreal/actions/runs/37245037969): усі три jobs **build / verify-macos / publish — completed success**. Публікацію підтверджено також читанням фактичного manifest після завершення publish.

Сам [macos-main manifest](https://github.com/santos-va/nooneisreal/releases/download/macos-main/manifest.json), прочитаний через HTTPS, містить SHA `6d929f8f938686c2803de9aa47eeca40e85fb852`, архів **266022946 B**, SHA-256 `40bb99da97b4c43041ee061ab5bf6c22a6747c53e035d4b77dc8e62eaffa0a25`, Godot `4.7-stable`, signing `ad-hoc; not notarized`. Incremental index — **14962 B**, SHA-256 `c6be2c5bdee37d7fce218b20e58a856e73f930f84ec69435aa77443e555ca068`. Канал дійсно перейшов із попереднього `d9d12ec` на `6d929f8`. Це доставка версії 0.4.1; кандидат 0.4.2 ще не публікувався. Доступу до Applications чи LaunchAgent на Mac Santos немає; їхній фактичний стан тут не заявляється.

## Наступний локальний PCK proof

Після фінального code SHA координатор дозволить ізольоване `git archive` саме цього commit у `/workspace/nooneisreal-evidence/district-motion`, окремі XDG data/config/cache та staged `build_info.cfg` з повним SHA. Далі — import/export-pack, порожній verifier для JSON/audio/marker, окремий `--main-pack` probe для версії, authored helpers, camera include й залежних shaders. Native Compatibility rendering перевірить компіляцію shader include з pack; це локальний доказ ресурсів, не публікація macOS release. До отримання SHA жодного export/runtime запуску цієї процедури немає.

## Related

- [[2026-10-05-District-Motion-And-Readability]] · [[2026-10-05-District-Motion-Session]] · [[2026-10-05-District-Journey-Checkpoint]] · [[2026-10-05-District-Delivery]] · [[2026-10-05-Quest-Journal-And-Guide]] · [[state]]
