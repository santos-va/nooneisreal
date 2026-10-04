# Ульти: межа раунду й хвиля Skea

**Дата:** 2026-10-04 · **Виконавець:** T2·D Гефест · **План:** [[Plans/2026-10-04-Combat-Control]].

## Звірка

Прочитано state, constitution, T2 і Start-Here з трьома handoff-сторінками після оновлення checkout до `65435de`. У SwordStormFx не було захисту першого кадру, межі KO та явного скасування на reset; frozen effect міг пережити зміну раунду. Grimoire завершував симуляцію, але залишав хвіст сторінок. FxDirector знав старі ID нормалей і не знаходив нові ID від LimbMoves.

## Реалізація

- SkeaWave повертає геометрію штатного normal hitbox: передня грань + `ultimate_wave_reach`, задня, висота й ширина збережені. Значення Skea 1 м — пряме доручення Santos; налаштування додає власник Fighter. Умова — активний Grimoire, а не видимість ефектів. Шкоду вирішує лише існуючий Fighter `_check_hit` із його has_hit, блоком і hitstop.
- Фіолетовий гребінь з'являється на першому активному кадрі на дальній межі; другий слід рухається від руки/ноги назовні в межах active. Це не окремий projectile й не другий hit. Fx.enabled вимикає тільки картинку.
- SwordStorm має birth-frame guard, завершується при KO будь-якого бійця до перевірки freeze. Обидві ульти мають синхронний cancel_owner для reset; Grimoire також прибирає свої хвилі. Beat frames, damage та порядок кристального дощу не змінено.
- Grimoire віддає presentation_frame для пози й повертає книгу слідом за бійцем; висота 1.75 м і bob узгоджені з піднятими руками левітації T2·C. Це presentation PLACEHOLDER, collider не підіймається.
- FxDirector показує наявні slash sheets для sword/limb ID з нової системи кінцівок. Нових ассетів чи витрат немає.

Коротка ульта зберігає чинну фіксовану послідовність. Нормалі з дальніми хвилями доступні у довгій ульті з диму, де `free_after_startup` уже повертає контроль гравцю.

## Перевірка

Предмет: для всіх нормалей Skea додаткова дальність діє тільки під час живої ульти, не створює другого влучання й не переживає reset.

Команда координатору: `"$GODOT_BIN" --headless --path game --script ../tools/skills/ultimate_wave_check.gd`. Умова: exit 0, `ULTIMATE_WAVE_COMPLETE checks=… failures=0`, без runtime/parser помилок. На провалі — виправити й повторити focused test; загальний прийом вимагає `make check` і `make gates`.

Тест охоплює чотири кінцівки в трьох стійках, незмінну задню грань/висоту/ширину, Fx off, відсутність бонусу для skill/ult/throw, реальний shape-query у двох напрямках, одне влучання, пропуск позаду/збоку/над/поза дальністю, завершену ульту та reset під freeze/KO. Три форми негативів — геометрична межа, неправильний клас атаки, недійсний lifecycle.

Координатор виконав focused regression: `ULTIMATE_WAVE_COMPLETE checks=77 failures=0`, лог `/workspace/nooneisreal-env/combat-control/regression-second/ultimate-wave.log` прочитано T2·D. Перший прогін мав чотири помилкові негативи fixture: `_start_move` повертав бійця до поставленої збоку/позаду цілі. Fixture тепер явно фіксує напрям уже активного удару після startup; collision-код задля проходження тесту не змінювали. Parser-конфлікт локального `target` у SwordStorm також виправлено.

Native кадри `07_skea_levitate.png` та `09_skea_wave.png` оглянуто: схрещені ноги, підняті руки біля книги й ліловий гребінь видно. Capture не встановлює якість у русі, M3-продуктивність чи фінальне арт-приймання. Загальні check/gates на момент запису ще не закриті: full smoke виявив зайвий горизонтальний рух після нового flash, який зміщував Skea з дальності довгої ульти; діагноз передано власнику Fighter. Beat data і перевірку восьми влучань не послаблювали.

## Related

- [[Plans/2026-10-04-Combat-Control]] · [[Handoff/2026-10-04-Start-Here]] · [[GDD/03-Skills-Framework]] · [[ADR-004-Physics-Is-Presentation]]
