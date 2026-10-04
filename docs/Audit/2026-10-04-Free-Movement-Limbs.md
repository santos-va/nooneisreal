# Вільний рух і чотири кінцівки — аудит T4

2026-10-04. Попередній аудит за дорученням T1 після підтвердження Santos: фізичні J/K/M/кома та LB/LT/RB/RT. Це критерії наступного зрізу, не приймання ще не реалізованої поведінки. T4 не змінює гру, GDD або state. Godot запускає послідовно T1; власне читання результатів буде відділене від власного запуску.

## Вердикт

**YELLOW: реалізація й runtime перевірки очікуються.** Наявний код пояснює скаргу на зміну напрямку після перетину: рух P1 залежить від напряму на противника, хоча камера вже зберігає свою сторону. Кількість кліпів сама по собі не доводить природність ходьби чи різноманітність ударів.

## Виміряний стан перед зміною

Команди T4: `cat game/scripts/core/DuelFrame.gd`; `sed -n '1460,1540p' game/scripts/fighter/Fighter.gd`; `sed -n '230,320p' game/scripts/fighter/SkeletalRig.gd`; `sed -n '890,940p' game/scripts/fighter/Fighter.gd`; `sed -n '1,130p' game/scripts/core/InputRouter.gd`; `rg -n 'button_index|axis' game/project.godot`.

- `DuelFrame.to_world`: SOLO P1 використовує `line`, яка обчислюється P1→P2 кожний simulation tick. Перетин може змінити значення тієї самої утриманої клавіші.
- `Fighter._update_facing`: у free_move завжди повертає героя на `opponent`. Це окрема прив'язка від руху та від камери.
- `SkeletalRig.walk_clip`: уже є вісім напрямків ходьби. Циклічний `clip_pos` використовує лише час стану, без швидкості переміщення; коректна назва кліпу не доводить відповідність кроку переміщенню.
- `SkeletalRig` уже має `Crouch_Idle_Loop`; відсутність читабельного присідання треба перевіряти на кінцевому ригу, а не пояснювати відсутністю назви.
- `_try_cancel`: стара light-послідовність має обмежений chain_index та heavy cancel. `_check_hit` пропускає лише `opponent`; зміна руху сама по собі не створює багатоворожий бій.
- SOLO J/K уже зайняті light/heavy. SHARED P2 M зайнята crouch, кома — ultimate. Плечі зайняті block/skills/grapple. Необхідна явна повна розкладка зі збереженням доступу до старих дій.

## Критерії приймання

| контракт | доказ, який потрібен |
|---|---|
| Вільний рух | Утримане W і той самий stick-vector дають той самий world direction до/після перетину й руху ворога навколо; dash використовує цю ж основу. Перевірка не тільки `to_world`, а реальної позиції Fighter. |
| Розділення камери й симуляції | Камера може пріоритетно показувати противника, але smoothing/FPS/тряска не змінюють напрямки, хеш або влучання. Відсутність target не породжує NaN/розворот. |
| Орієнтація героя | Вільний рух не примушує дивитися назад на ворога; правило attack/block/crouch facing явне. Під час committed attack не можна довертати hitbox без контракту. |
| Чотири кінцівки | Реальні keyboard/button/trigger events запускають потрібну кінцівку по одному разу, з правильним device. Фізична кома працює без Shift і незалежно від напису `<`. |
| Розкладка | Жодних випадкових подвійних дій, SHARED P2 не керує P1; skills/guard/grapple/jump/dash залишаються доступними. Довідка показує реальні нові прив'язки. |
| Комфорт після remap | Усі нові дії нейтральні під меню/паузою; утримання через resume потребує відпускання; натискання й відпускання в меню не перетворюється на удар. |
| Послідовності | Визначені пріоритет одночасних подій, довжина та скидання ланцюга, hit/whiff cancel, crouch/air контексти; однакова послідовність вводу дає однакові події бою. |
| Видимі кінцівки | Кадри обох моделей показують заявлену ліву/праву руку/ногу. Чотири назви, що грають той самий удар, не відповідають запиту. |
| Ходьба й присідання | Native серія вперед/назад/вбік, повільний/full stick, суша/вода, старт/стоп, crouch обох героїв. Вимір контактного ковзання стопи або явне обмеження висновку; статичний кадр не доводить відсутність moonwalk. |
| Регресії | `make check-playable`, `make gates`, точні completion sentinels, без runtime/SCRIPT ERROR. Негативні контроли на напрямок і remap ловлять навмисну помилку. |

## Проміжне рев’ю реалізації

**GREEN вузько, статичні контракти.** `git diff` та читання нових `LimbMoves.gd`, `LimbMotion.gd`, `LocomotionCadence.gd` підтвердили: людський базис фіксується на один жест із simulation `right`, нейтраль його скидає; CPU має старий шлях. Людська ходьба більше не проєктується на радіус навколо ворога. Нові normal copies залишають числові поля донора. `_normal_connected` обчислюється приростом `stats.hits`; block-гілка `receive_hit` приросту не робить. Перевірка ланцюга обмежує його трьома та забороняє продовження після leg. Pad маршрут обирається лише на фізичному rising edge, тригери мають hysteresis; UI очищає маршрути й захищає утриманий modifier.

**YELLOW, докази ще неповні.** T4 власною командою прочитав `free-limbs/logs/limb_input_check.log`:124/0, `comfort_input_check.log`:31/0, `gait_check.log`:512/0. Останній показує median toe contact speed Choko1.0173/Skea1.0118m/s; це покращення, не нульове ковзання. `free_movement_check.log`:24/0, але після sentinel є ObjectDB/resource leaks — такий запуск не прийнято як чистий. Початкові `gait.log` і `movement.log` містять failures і не зараховані. Початковий native capture впав на compile error зовнішнього capture script; кадрів для приймання він не дав.

Власникам передані дві прогалини: бойовий тест вручну підставляє `_normal_connected`, тому потрібна реальна пара Fighter для hit/block/invulnerability; руховий тест потребує actual dash після перетину. Finite endpoint assertion не доводить, що глядач бачить потрібну кінцівку. Очікуються native серії, чистий повтор і повна батарея. Engine запускав T1, не T4.

## Повтор і розширення гарпуна

**GREEN для чистих цільових повторів, не всієї батареї.** Повторно прочитано `free_movement_check.log`:26/0 без teardown diagnostics; тепер перевірено actual dash вперед після перетину. `limb_combat_check.log`:2950/0 містить справжній physics hurtbox hit, block, invulnerability та whiff; flag збільшується лише після hit. `gait_check.log`:604/0 після калібрування довжини ніг; median contact toe speed Choko0.3374 проти4.6922m/s, Skea0.3266 проти5.3018m/s у matched старому Walk1x контрольному прогоні. Це вузький forward speed сценарій, не загальна гарантія відсутності ковзання. `foot_contact_check.log`:462/0.

**YELLOW візуального приймання.** T4 переглянув production wide sheets, потім River overview та явно підписані diagnostic closeups. У bazaar старі коричневі пропи перекривали ноги — ці кадри не доводять контакт. На River видно alternating jog, lowered crouch, leg extension. Closeup не видається за gameplay zoom. Right jab у contact кадрі обох героїв виглядає як guard; запрошено вимір плеча/кисті вздовж forward, щоб відрізнити foreshortening від помилки ретаргету. Choko crouch читається як нахилене коліно з рукою позаду; це не підтвердження природної бойової стійки. Перероблені bodyhook/uppercut та повний повтор очікуються.

**YELLOW гарпуна, новий погоджений контракт.** T4 прочитав нові GrappleHook/Fighter та `tools/grapple/harpoon_check.gd`. Є30 simulation frames замаху, витрата на launch, fixed flight ray до14m, own hurtbox exclusion, cover перехоплює, `_confirm_pull` викликається після physics contact; windup/flight скасовуються при виході зі стану. На запит T4 власник додав suspended neutral, tangent steering, explicit reel і cover-cut cases. Початковий24/0 мав resource leaks; не прийнято. Перший широкий smoke зупинився на stage49 після54 успішних перевірок; завершення батареї ще немає. Новий запит на майбутню rope/aim/recovery систему не зараховується до цієї обмеженої реалізації без окремих доказів.

Власні tooling перевірки T4: `git diff --check` чистий; `python3 tools/gates/wikilink_check.py`:4286 links,0 broken. Додавання negative movement cases до runner допускає лише їхній точний assertion prefix, engine/SCRIPT ERROR не дозволені. Runtime запуски залишаються централізованими T1.

## Контрольна точка перед наступною фазою

**GREEN технічного зрізу за останніми завершеними прогонами.** T4 прочитав `logs/check.log`: ALL OK164/19839 frames, `logs/regression-only.log`:27 scenarios/0 failures, `logs/gates.log`:54 GDS/0 parse failures та БАТАРЕЯ ЗЕЛЕНА. `logs/harpoon_check.log`:24/0 без resource errors. Раніші невдалі smoke49/MODE-row і teardown не зараховані; збережені у попередніх логах як діагностика. Нові movement negative controls opponent_frame/orbit/facing відхилені очікуваним rc1, а не пропущені.

**GREEN вузько, правий jab.** `gait_check.log`:628/0, незалежний world-space shoulder→hand forward projection: Choko left0.3484/right0.3376m; Skea left0.3359/right0.3484m. Різниця сторін менша0.013m; початкова підозра на відсутність правого удару не підтвердилася. Видимий guard overlap на цьому ракурсі не є доказом дефекту extension. Нові art-final кадри та gait630 додають сильніший замах гарпуна; grounded foot correction після цього ще очікує повтору, тому візуальний пункт поки YELLOW.

**GREEN actual гарпуна; авторство tooling відокремлене.** За дорученням T1 аудитор написав тільки зовнішній `/workspace/nooneisreal-env/free-limbs/render/actual-hook.gd`; це авторська діагностична допомога, не незалежна перевірка власного tooling. T1 запустив його послідовно, T4 прочитав лог і telemetry та відкрив windup/flight/hang кадри обох героїв. Production Arena/Fighter/InputRouter обробляють реальні фізичні E events; fixture задає лише початкове підвішене положення, окрему anchor та diagnostic camera. Фази не підставляються вручну. Sentinel:8shots/0fail; лише відоме llvmpipe V-Sync warning. Telemetry: windup phase1/3charges/rope hidden → flight phase2/2charges → hang phase3/attached/visible rope → released phase0/detached/rope hidden. Обидва герої мають видимий канат від рук до anchor; suspended hang y≈1.58/1.62m, rope length7.392m. Це підтверджує реальну проводку, а не лише manual pose replay. Не є M3 performance або суб'єктивним playtest.

**YELLOW загалом до завершення нового обсягу.** Після цієї контрольної точки Santos уточнив наступну фазу: Q enemy / E parkour,7Choko/2Skea, persistent ropes, повернення за промах, extraction та hands-busy/kick combos. Цей пункт фіксує нове доручення T1; наведені27 сценаріїв і actual-hook кадри НЕ доводять ці нові функції. Їх не слід оголошувати реалізованими за цим checkpoint.

## Межі висновку

Відсутність доступу до фізичного M3/геймпада не можна заміняти твердженням про перевірку на них. Детермінована процедурна анімація не є анатомічною симуляцією м'язів. Новий sprint, вибір серед багатьох ворогів, довільна генерація анімацій і мережевий бій потребують окремих контрактів; не зараховуються як результат цього diff без реалізації та доказів.

## Related

- [[constitution]] · [[2026-10-04-Comfort-Audit]] · [[05-Platforms-Input]] · [[02-Combat-System]] · [[ADR-004-Physics-Is-Presentation]] · [[ADR-020-Camera-Continuity-And-Impact]]
