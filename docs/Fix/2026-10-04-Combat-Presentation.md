# Бойові пози й перетворення меча

T2·C Гефест, 2026-10-04. План: [[Plans/2026-10-04-Combat-Control]].

## Звірка й реалізація

Початковий аудит старого checkout був відкликаний після fast-forward до `65435de`. Прочитано [[Handoff/2026-10-04-Start-Here]], [[Handoff/2026-10-04-Decisions-And-Validation]]: збережено чотири окремі кінцівки, SwordMotion/SwordPresentation, V/H/P/R3 і явний SWAP contact. Новий вузол зброї не створювався.

- SwordPresentation використовує існуючий меч: на старті за спиною, витягування за SWAP, автоматична поява в руці до contact бойового удару. Наступна зміна руки/форми — просторове розчинення матеріалу й детерміновані частинки. Три силуети процедурні, `PLACEHOLDER`; це не фінальний арт. Золотий меч ульти й повернення теж проходять через пил. Нових платних чи імпортованих ассетів немає.
- SwordMotion додає діставання зі спини й спадний `cleave`; LimbMotion додає спадний `hammer` та іншу траєкторію `hookspin`. Вибір варіантів залишається в LimbMoves/Fighter, власник T2·A. Оберт ноги залежить від фаз удару й доходить до повного оберту без зворотного розкручування на recovery.
- RigAnimator/SkeletalRig передають схрещені ноги, підйом корпусу й жест читання/письма Skea на видимого героя протягом активної ульти. Під час удару бойова кінцівка виконує удар; висота collider не змінюється. Час гойдання узгоджений із Grimoire.presentation_frame.

## Перевірка

Предмет: для всіх станів зброї та фаз удару презентація має скінченні координати, поважає pause/hitstop, не пише бойову позицію, а завершений оберт не повертається назад на recovery.

Команди координатору: `tools/animation/combat_presentation_check.gd` → `COMBAT_PRESENTATION_COMPLETE ... failures=0`; старий `sword_presentation_check.gd` з явною витягнутою зброєю для старих grip/transfer cases; native `combat_visual_capture.gd -- --out=/tmp/nir-combat-visuals` → PNG і `COMBAT_VISUAL_CAPTURE_COMPLETE`. За провалу — виправити конкретний шлях і повторити тест. Загальні `make check`/`make gates` запускає координатор послідовно; до результатів код не називається готовим. Native кадри — огляд постановки, не доказ керування фізичним контролером чи FPS на M3.

Перечитані журнали координатора `combat-control/regression-second`: `combat_presentation_check` **71/0**, `sword_presentation_check` **228/0**, Godot 4.7 stable. Перші 11 native PNG переглянуто: back mount, draw, dust, інша форма та хвиля читаються; критика T4 про приховану ногу і схрещені лише щиколотки призвела до корекції оберту на contact і більш сидячої пози. Повторний `native-final.log` завершився sentinel без помилок/витоків: 13 PNG у `combat-control/render-final`, лишилося очікуване попередження драйвера про VSync. T2·C особисто переглянув `07_skea_levitate`, `06b_skea_spin_active_front`, `06c_skea_spin_recovery`: сидяча поза читається краще, атакуюча нога видима, наприкінці повернення в гард без зворотного оберту. Координатор також оглянув ці кадри. `regression-final`: presentation **71/0**, sword **228/0**; `playable-final.log`: **40 сценаріїв, 0 провалів**; `gates-final.log`: **БАТАРЕЯ ЗЕЛЕНА**, GDS **60/0**. Ці журнали прочитані в цій сесії. Подальша стороння правка переривання дешу потребує свого повторного прогону; її результат тут не приписується.

## Related

- [[Plans/2026-10-04-Combat-Control]] · [[Handoff/2026-10-04-Start-Here]] · [[Handoff/2026-10-04-Decisions-And-Validation]] · [[2026-10-04-Choko-Sword-Presentation]] · [[2026-10-04-Sword-Input-State]]
