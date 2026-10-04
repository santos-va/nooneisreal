# Аудит керування, бою й мотузок — 2026-10-04

T4 Феміда. Межі: read-only аудит реалізації та вимог Santos; код, GDD і `state.md` не змінюю. База після синхронізації координатором: `65435de` (PR169). Попередній checkout `a0fbffc` не містив PR167–168; тому висновки про старий checkout не видаються за стан нової бази.

**Підсумок:** технічний GREEN; фінальне художнє/пристроєве приймання YELLOW. Відкритих технічних блокерів у перевіреному diff немає. Початкові RED нижче — історія усунених причин, не поточний вердикт.

## Початковий аудит — RED (до виправлень)

| Пункт | Вердикт / доказ | Наслідок і необхідна перевірка |
|---|---|---|
| Доступність handoff | GREEN: `git log --all --oneline -- docs/Handoff/2026-10-04-Start-Here.md` → `dad5d3b`; `git show dad5d3b:docs/Handoff/2026-10-04-Start-Here.md` читається. `git merge-base a0fbffc dad5d3b` → `a0fbffc`. | Спочатку взято новішу локальну базу; неприпустимо перевинаходити вже змерджені finite inventory, manual aim і one-sword. |
| Напрям руху | YELLOW: `DuelFrame.human_to_world` у базі зберігає `_human_axes[player]` до нейтралі; `InputRouter.view_basis` споживається тільки на початку жесту. `DuelCamera` при цьому змінює орієнтацію. | Узгоджено з попереднім handoff, але після повороту камери поточне W може рухати назад відносно кадру. Потрібні фактичні тести W під час crossing, auto/manual orbit, pause/resume і записаного input packet; не називати це випадковістю без виміру. |
| Стрибок і деш Skea | RED: `Fighter._aim_flash` звужує напрям до осі суперника ±`FLASH_SIDE_DEG`; `_start_flash` обнуляє velocity; `_tick_flash` лінійно інтерполює до точки за чотири кадри. | Відсутній запитаний повноцінний похилий/боковий arc зі збереженням стрибкового імпульсу. Перевірити simultaneous jump+dash, dash після takeoff, падіння, краї, cover, hitstop і кількість зарядів. |
| Ліміт Choko | RED: звичайний `_start_dash` не перевіряє/не витрачає запас; recharge у базі не залежить від числа витрачених поспіль. | Потрібні п'ять ривків Choko, три Skea, довший відпочинок після серії; exhausted dash не має випадково з'їдати іншу дію або Spring. |
| Повторний anchor | RED: `MatchRopes.deploy` у базі перевіряє token/owner, але не зайнятість місця. | Атомарно відхиляти duplicate під час contact, зокрема два польоти до одного anchor; зберегти reuse існуючої мотузки без нової витрати. |
| Rematch | RED: `git grep -n clear_match -- game` → тільки декларація `MatchRopes.gd:103`; `Hud.gd:166` викликає `flow.rematch`, який скидає fatigue/wins/round_no, але не ropes. | Реальна кнопка залишає попередній матчовий запас/мотузки. Тестувати саме `MatchFlow.rematch`, збереження між раундами та відновлення на новий матч. |
| Вага підвісу | YELLOW: `GrappleHook.drive` у базі має reel9 м/с, steer14, gravity×0.9, release×1.15; ввід до anchor одночасно стягує мотузку. | Space має явно керувати підтягуванням. Обмеження energy/speed і згасання треба перевірити на довгій/короткій мотузці; проста змінна mass у кінематичному constraint не дає людської ваги. |
| Комбінації | YELLOW: `LimbMoves.resolve` знає index і previous, hand third → uppercut, foot third → spin. Гілки попереднього коду завершують chain ногою. | Для LRL/RLR і ніг потрібен явний контракт order/side/finisher, hit-confirm, whiff/block reset, cap3; візуальний spin не доводить доступність трьох послідовних ударів ногами. |
| Ульти / хвилі | YELLOW: Skea `GrimoireFx` б'є радіусом3.6 м і породжує spectral pages; це не limb-origin wave. Choko вже має crystal blast/rain з детермінованими hit frames. | Зберегти чинний combat contract, додати читаємий переходовий рух. Для нової хвилі: bounded reach ≈1 м, одноразовий контакт, guard/height/hitstop, clean round/reset lifetime. |

Команди читання: `git show origin/main:<path>`, `rg -n -C 4`, `git grep -n`. Це статичні висновки, не новий runtime-вимір і не приймання відчуття гри на M3.

## Контракти, які не можна втратити

- Один authoritative token на гарпун; `available + active/recovering + deployed = capacity`. Відмова duplicate не краде гарпун, refund не дублюється.
- Ropes живуть усі раунди одного best-of-three (до двох перемог), rematch очищає їх. Перший переможець2:0 закінчує матч після двох раундів, а не примусового третього.
- Новий матч/раунд, удар, KO, pause та time stop не залишають sword dissolve, arc чи wave активними поза їхнім lifetime.
- Фізика й декоративні частинки не вирішують влучання. Детермінізм однакового input stream важливіший за фізичний блиск.
- Початковий меч за спиною і V draw відрізняються від звичайного transfer. Усі підказки мають говорити актуальну дію; skill/ult/normal мають зрозумілий armed/unarmed стан.
- Однакові правила для keyboard, gamepad та shared; camera-basis change не повинен тихо міняти replay contract.

## Повторне читання diff

Під час незалежного читання знайдено й передано власникам:

1. Новий `rematch()` guard лише для MATCH_END ламав чинний restart API і fatigue smoke. Власник зберіг restart API; UI доступний на результаті. Result-overlay має окремого InputRouter owner, тож його release не знімає pause owner.
2. Повне розширення hitbox на першому active разом із хвилею, яка лише летить до нового краю, давало влучання раніше картинки. Власник додав зовнішній contact crest одразу й рухомий внутрішній echo; combat залишається єдиним `_check_hit`.
3. Новий ліміт дешів відкривав безкоштовне переривання SWAP: IDLE ставився перед перевіркою запасу. Власник переніс перехід у успішний `_start_dash`; exhausted input залишає SWAP.
4. Перевірка зайнятості лише на contact дозволяла зайвий windup для явно зайнятого manual target. Додані відмови до windup/launch; late race все ще коректно переходить у recoverable rewind.
5. У focused wave fixture `_start_move` автоматично повертав бійця до цілі, роблячи rear/side negatives передніми. Fixture фіксує committed direction після startup. Це виправлення тестової постановки, не зміна правил удару.

`git diff --check` на цьому checkpoint → rc0. Повторно прочитані `fire → _launch → _flight → MatchRopes.deploy`, відмова duplicate не втрачає token; reuse відбувається до occupation reject. У gameplay-дописах не знайдено нового необмеженого списання ресурсів чи перенесення damage у декоративну хвилю.

## Native-перегляд — YELLOW для фінального художнього приймання

T4 відкрив через image viewer staged кадри `render/01_choko_back.png`, `03_choko_draw.png`, `05_choko_form.png`, `06_skea_kick_2.png`, `07_skea_levitate.png`, `09_skea_wave.png` у `/workspace/nooneisreal-env/combat-control/`. Sword back mount і thinner наступна форма читаються, подвійного меча не видно. Фіолетовий зовнішній crest читається. Levitation показує зігнуті коліна та перехрещені щиколотки, але не виразну сидячу позу зі схрещеними ногами. Задній кадр third kick приховує атакуючу ногу; сам собою не доводить читабельний удар. Запитані додаткові phase/angle кадри. Власнику хвилі передано потребу visual emitter від actual limb до authoritative crest, щоб піднята pose не виглядала відірваною від хвилі.

Повтор `native-final.log` має `COMBAT_VISUAL_CAPTURE_COMPLETE`, без SCRIPT ERROR/resource ERROR, лише очікуване unsupported-VSync попередження llvmpipe. T4 відкрив фінальні `render-final/07_skea_levitate.png`, `06b_skea_spin_active_front.png`, `06c_skea_spin_recovery.png`, `09_skea_wave.png`: ударна стопа тепер виразно читається спереду-збоку, recovery повертає guard; коліна в левітації підняті вище, ноги складені й перехрещені. Це достатній native proof зміненої пози, але книга/сторінки все ще частково закривають коліна. Фіолетовий crest читається, art refinement емітера від кінцівки до нього залишається рекомендацією, не новою бойовою вимогою.

Це постановочні стани з native renderer, не actual-input відео і не M3 playtest. Чистий фінальний native-log замінює перший прогін із resource leak.

## Фінальний diff і виконані перевірки

**Технічний вердикт: GREEN на перевіреному checkpoint. Візуальне/пристроєве приймання: YELLOW.** Загальне художнє приймання не підмінюється технічним GREEN.

| Перевірка | Результат / межа |
|---|---|
| `make check-playable` координатором; T4 незалежно прочитав raw `playable-final.log` | rc0; `ALL OK (164 checks)` у19847 кадрах; `PLAYABLE CHECK: 40 scenarios, 0 failures`. |
| T4 script читання всіх `regression-final/*.log` | 40 файлів, 0 несподіваних SCRIPT ERROR/ERROR у positive; named negatives мають лише очікувані scoped assertions. |
| Нові focused sentinels | combat-control549/0 після late fix; combat-presentation71/0; weighted-swing19/0; ultimate-wave77/0; match-lifecycle29/0. |
| Збережені основи | sword-state804/0, sword-presentation228/0, limb-combat2962/0, free-movement54/0; input/foot/gait/rope/camera suites включені в40. |
| Негативні контроли | UI3, comfortUI3, movement3, match lifecycle3; deliberate rc1 приймається лише зі своїм sentinel/error-prefix, parser/resource errors не пропускаються. |
| **T4 виконав** `source /workspace/nooneisreal-env/activate.sh; make gates > /workspace/nooneisreal-env/combat-control/gates-final.log 2>&1` | rc0; БАТАРЕЯ ЗЕЛЕНА; GDS60/0, assets171/171, wikilinks4678/0 broken, R8/roles/state gates green. |
| `git diff --check` | rc0. |
| `git log --oneline origin/main..HEAD`; `git diff --stat origin/main -- game/assets docs/Art/Textures-Registry.md` | Обидва без виводу: нових комітів/ассетів немає, робочі зміни ще не закомічено. Локального ref `main` немає, тож використано перевірений `origin/main`. |

У прогоні виявлено справжню регресію нового flash: displacement velocity залишалася після travel й переносила Skea вдруге під час recovery, через що long ult у smoke влучала лише3/8. Власник обнулив горизонтальну швидкість після досягнення authored endpoint і додав обидва endpoint regression — звичайний dash та scripted beat. T4 повторно прочитав travel/recovery/beat/water-floor code; фінальний smoke зберіг жорсткі8imprints/273damage і пройшов. Зміни старих frame5/frame8/45degree assertions відображають явний новий travel/input contract, не послаблюють hit/charge перевірку.

Пізня перевірка власника виявила ще один lifecycle дефект: grounded `receive_hit`/`get_pulled_to` під час DASH залишали `flashing=true`, і pushbox залишався вимкненим. Додано спільне очищення `flashing/dash_frames_left` при виході зі State.DASH та2 production interruption probes. T4 прочитав state-exit diff та всі3 остаточні логи: `control-interrupt-final.log` →549/0; `check-interrupt-final.log` →164/19847, SMOKE ЗЕЛЕНИЙ; `gates-interrupt-final.log` →БАТАРЕЯ ЗЕЛЕНА, GDS60/0. Пошук SCRIPT ERROR/ERROR у цих логах →0 збігів. Координатор підтвердив rc0 кожної команди. Це остаточний технічний checkpoint; повну40-scenario suite пройдено перед вузьким late fix, після нього повторено залежні control/smoke/gates.

Попередні `*-first.log`, `check-second.log` і `regression-second/combat-control.log` — діагностика, не acceptance: resource teardown, старий timing, fixture facing та помилковий Fx-autoload були виправлені, повтори green. Final evidence зберігається у `/workspace/nooneisreal-env/combat-control/`; це зовнішня workspace-папка, не git-артефакт. Команди й probes у репозиторії дозволяють повторити виміри.

Залишкова межа: headless/native Linux не підтверджують M3 FPS, фізичний геймпад, feel/debt balance чи фінальний рівень художньої анімації. PLACEHOLDER reel/arc/cooldown не стали фізичними вимірами людського тіла. V — явний draw; атака має погоджений auto-draw fallback, форми меча косметичні, нові бойові бонуси не заявляються.

## Related

- [[Plans/2026-10-04-Combat-Control]] · [[Meetings/2026-10-04-T1-Combat-Control]]
- [[Handoff/2026-10-04-Start-Here]] · [[Handoff/2026-10-04-Decisions-And-Validation]]
- [[system/constitution]] · [[system/recurring_class_register]]
