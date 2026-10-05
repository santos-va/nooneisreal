# Натискання на контакті та своєчасний захист

2026-10-05 · T2 Гефест · реалізацію та вузькі регресії перевірено; загальна інтеграція очікується.

Предмет: для всіх підтверджених кінцівкових нормалей: коротке натискання під власним hitstop може виконати рівно одне дозволене продовження після active, без збільшення віку понад чинні шість незупинених тактів та без перенесення через lifecycle boundaries.

План [[2026-10-05-Expressive-Heroes-And-Combat]] і правила T5 у [[02-Combat-System]] звірено з Fighter/InputRouter/LimbMoves. Попередній six-tick глобальний buffer продовжував старіти протягом раннього повернення Fighter під hitstop; у важкого удару це 13 тактів плюс решта active. Наявний limb-combat тест перевіряв прямий `_try_cancel`, тому не перевіряв цей шлях часу. Окремо grounded HITSTUN повертав IDLE попри утриманий block; BLOCKSTUN вже відновлював BLOCK. Training reset_positions відразу повертав control після reset_for_round, не прибираючи queued raw presses.

`CombatIntent` тримає один намір лише для actual-hit NORMAL, обраної кінцівки та доступного наступного кроку серії. Початковий вік читається з InputRouter; власний hitstop його зупиняє. Нові натискання замінюють намір, рівні timestamps розв'язує чинний порядок LimbMoves.ACTIONS. Конкуруючі raw entries споживаються один раз. Немає нової черги для whiff/block; звичайний late-recovery буфер збережений. Скіли/ухил/ульта/Flash перевіряються раніше як і до зміни.

InputRouter має revision історії для кожного гравця. Menu cycle між фізичними тактами, профіль керування, disconnect або очищення історії інвалідують pending. Reset/rewind стирають queued edges відповідного гравця без перетворення held руху/блока на нове натискання. Freeze, control lock і перехід з ATTACK очищають захищений намір. Grounded HITSTUN завершується BLOCK при дозволеному held block на першому доступному такті, без скорочення stun або зміни guard arc.

## Перевірки

Новий сценарій `tools/combat/intent_check.gd` має пройти через реальні input ticks, hitboxes і hitstop легких/важких атак. Негативні форми: блок/промах/невразливість; застаріле натискання; меню між ticks; переривання, freeze, reset/rewind; третій удар без четвертого. Guard перевіряється на межі stun та зі спини/у повітрі. Дані damage/frame/hitbox і звичайний InputRouter.BUFFER_FRAMES не змінюються.

Команда: Godot 4.7 headless `--fixed-fps 60 --script ../tools/combat/intent_check.gd`. Умова: повний sentinel, rc0, 0 failures, чистий raw log. На провалі — виправлення й повтор вузького сценарію; загальні check/gates/playable запускає координатор після інтеграції.

Офіційний Godot 4.7 stable, `--fixed-fps 60`: **COMBAT_INTENT 160/0**, rc0, чистий raw `expressive-heroes/combat/intent-final.log`. Існуючі регресії після зміни: **limb-combat 2962/0**, **comfort-input 31/0**, **combat-control 549/0**, **city-parkour 73/0**; журнали в тій самій evidence-директорії, без ERROR/WARNING. Новий сценарій зареєстровано у playable runner; повна батарея лишається за координатором.

Початковий physical-reset fixture мав 159 перевірок / 1 відмову. Діагностика довела, що `Input.parse_input_event` ще не доставив подію: перед reset `Input.is_action_pressed` був false; подія прийшла після reset і коректно почала нову атаку. Fixture тепер використовує незайняту F12, викликає `Input.flush_buffered_events` та вимагає позитивний held-before-reset guard. Production не послаблювався заради тесту; попередні raw журнали збережені.

Негативні форми перевірено реальними input ticks: блок/промах/невразливість не захищають намір; первісний raw вік6 протухає на першому незупиненому tick; меню між ticks, disconnect released pad tap, freeze/interrupt/lock/reset/rewind знищують pending. Інший гравець зберігає власну queued edge. Реальна серія доходить до трьох контактів, четвертий не відкривається; held key не повторюється. Skill cancel зберігає пріоритет. Guard не скорочує stun, блокує фронтальне влучання на першому дозволеному tick, не захищає спину й не створює grounded BLOCK у повітрі.

## Related

- [[2026-10-05-Expressive-Heroes-And-Combat]] · [[2026-10-05-Expressive-Heroes-Session]] · [[02-Combat-System]] · [[ADR-004-Physics-Is-Presentation]]
