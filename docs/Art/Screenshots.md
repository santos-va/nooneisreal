# Кадри гри — що на кожному скриншоті

Тут зібрано всі кадри з `docs/assets/screenshots/`: що на кадрі, з якого коміту він узявся і на якій сторінці його
обговорюють. Сторінка потрібна, щоб жоден кадр не лишився без підпису, а з кадру можна було перейти до розмови про
нього. Кадри знято під Xvfb з llvmpipe (див. [[2026-10-03-Wave-2-Kickoff]] § Godot у хмарі), тому звуку й керування
з клавіатури на них не видно.

**Правило для нових кадрів.** Ім'я файлу — `YYYY-MM-DD-<тема>.<png|jpg>`. Хто додає кадр у PR, той дописує рядок у
таблицю нижче: що на кадрі та посилання на сторінку, де він вбудований. Кліо звіряє таблицю з командою:

```
for f in docs/assets/screenshots/*; do n=$(basename "$f"); grep -q -F "$n" docs/Art/Screenshots.md || echo "без рядка: $n"; done
```

Підписи бувають двох видів. Позначка «зі сторінки» означає, що підпис узято з alt-тексту сторінки-джерела. Позначка
«Кліо» означає, що кадр переглянуто очима в сесії 2026-10-03; «Кліо, 2026-10-16» — у сесії 2026-10-16 (кадри, які
жодна сторінка не описує). Позначка роллю (T2-И, T6 тощо) — підпис автора кадру. Кадри в теках (`2026-10-05-*/`,
`2026-10-07-*/`) мають по рядку на файл; «не вбудований» у колонці «обговорено» — кадр не згадує жодна сторінка.

## Хвиля 2 — огляд `main` у хмарі (T1, 2026-10-03)

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-03-t1-wave2-look.jpg](../assets/screenshots/2026-10-03-t1-wave2-look.jpg) | 6 плиток 3×2, на кожній напис T1. ✓ гарпун до якоря, бризки й дим дешу на `river`; ✓ змах Choko і влучання на `bazaar`; ✓ великий ефект скіла (T1: «чий — не визначив»); ✗ шов і повтор веж на фоні, якорі — жовті кулі (`river`); ✗ сірі коробки й гола підлога (`bazaar`); ✗ циліндр і фон-вулиця стіною (`fountain`) | Кліо | `b0967b2` | [[2026-10-03-Wave-2-Kickoff]] Н1–Н3 · [[2026-10-03-T1-Wave-2-Kickoff]] |
| [2026-10-03-t1-river-92s.jpg](../assets/screenshots/2026-10-03-t1-river-92s.jpg) | 9 плиток 3×3: CPU проти CPU на `river`, з 12-ї по 92-гу секунду кожні 10 с (кадри фізики 700…5500). Видно фіолетових привидів (схоже на Flash Step, не звірено), великий фіолетовий ефект, зірку влучання, бірюзовий циліндр навколо бійця, знак з оком на підлозі. HP обох падає, на 92 с таймер раунду знову 96 | Кліо | `b0967b2` | [[2026-10-03-Wave-2-Kickoff]] · [[2026-10-03-T1-Wave-2-Kickoff]] |

## Запуск 4 — манекен на скелеті (T2)

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-03-launch-4-mannequin.png](../assets/screenshots/2026-10-03-launch-4-mannequin.png) | «два манекени на річці, капсул немає», кадр 230, `--skeletal-rig` | зі сторінки | `1b1decf` | [[2026-10-03-launch-4-mannequin]] |
| [2026-10-03-launch-4-mannequin-attack.png](../assets/screenshots/2026-10-03-launch-4-mannequin-attack.png) | кадр з ударом, кадр 330; «куди дивиться Skea — з кадру не певен» (T2) | зі сторінки | `e2f0b6c` | [[2026-10-03-launch-4-mannequin]] |

## Прототип 0.3 — вільний рух (T2)

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-03-0.3-plane-mode.png](../assets/screenshots/2026-10-03-0.3-plane-mode.png) | «Площина, 0.2» | зі сторінки | `108e24c` | [[2026-10-03-free-movement-0.3]] § Кадри |
| [2026-10-03-0.3-free-sidestep-90.png](../assets/screenshots/2026-10-03-0.3-free-sidestep-90.png) | «Обхід 90°» | зі сторінки | `108e24c` | [[2026-10-03-free-movement-0.3]] § Кадри |
| [2026-10-03-0.3-free-duel-camera.png](../assets/screenshots/2026-10-03-0.3-free-duel-camera.png) | «Камера дуелі під кутом» | зі сторінки | `108e24c` | [[2026-10-03-free-movement-0.3]] § Кадри |
| [2026-10-03-0.3-free-grapple-zip.png](../assets/screenshots/2026-10-03-0.3-free-grapple-zip.png) | «Зип у глибину (0.3-3)» | зі сторінки | `26e0c0f` | [[2026-10-03-free-movement-0.3]] § Кадри |
| [2026-10-03-0.3-5-river-free-move.png](../assets/screenshots/2026-10-03-0.3-5-river-free-move.png) | «Річка у вільному русі (0.3-5)» | зі сторінки | `e7540ee` | [[2026-10-03-free-movement-0.3]] |
| [2026-10-03-0.3-wall-splat.png](../assets/screenshots/2026-10-03-0.3-wall-splat.png) | «Wall splat, кадр 4 з 10 — не читається» | зі сторінки | `f01d1b7` | [[2026-10-03-free-movement-0.3]] · [[2026-10-03-Launch-2-PR60]] п. 19 |

## Фон річки в грі (2026-10-03)

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-03-river-stage-preview.png](../assets/screenshots/2026-10-03-river-stage-preview.png) | Перший мальований фон `river` у грі: набережна з ліхтарями й кораблик. Бійці ще на капсульному ризі: Choko помаранчевий із зеленим мечем, Skea фіолетовий. Підлога пласка, бордова; у HUD текст `S1✓ S2✓`; таймер 97 | Кліо | `cee6384` | [[Stage-River]] · [[Backgrounds]] |

## Запуск 7.1 — регдол на скелеті (T2, 2026-10-03)

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-03-launch-7-1-ragdoll-before-after.jpg](../assets/screenshots/2026-10-03-launch-7-1-ragdoll-before-after.jpg) | «до/після»: P2 у регдолі на `river`, кадр 160. Верхній ряд — капсули («до», `main` `7dc1d90`); нижній — Skea падає власною моделлю і лежить на воді (f192, f215) | зі сторінки | `df8b3c6` | [[2026-10-03-launch-7-1-skeleton-ragdoll]] § Кадри з хмари |

## Паки Santos — палітра і MegaKit очима (T6, 2026-10-03)

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-03-palette-remap-kaykit.png](../assets/screenshots/2026-10-03-palette-remap-kaykit.png) | Дошка «було / стало» для KayKit Dungeon: ліворуч у кожній парі — плашка паку, праворуч — наша, на м'ятній плашці `#B8CBB1` | зі сторінки | `2f5b1fc` | [[Palette-Remap]] § Як прогнати (шлях у тексті, картинкою не вбудований) |
| [2026-10-03-t6-megakit-a.jpg](../assets/screenshots/2026-10-03-t6-megakit-a.jpg) | «MegaKit, 1–50»: моделі паку, відрендерені T6 у Godot 4.7.2 headless, вид 3/4, плашка `#B8CBB1` | зі сторінки | `24e58d9` | [[Pack-Review]] § MegaKit [Standard] — вердикт |
| [2026-10-03-t6-megakit-b.jpg](../assets/screenshots/2026-10-03-t6-megakit-b.jpg) | «MegaKit, 51–94», той самий спосіб | зі сторінки | `24e58d9` | [[Pack-Review]] § MegaKit [Standard] — вердикт |
| [2026-10-03-t6-kaykit-compare.jpg](../assets/screenshots/2026-10-03-t6-kaykit-compare.jpg) | «KayKit, ті самі предмети»: 6 відповідників KayKit, відрендерені тим самим способом для порівняння масштабу | зі сторінки | `24e58d9` | [[Pack-Review]] § MegaKit [Standard] — вердикт |

## Прототип 0.1 і кіти (2026-10-02)

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-02-prototype-0.1-a.png](../assets/screenshots/2026-10-02-prototype-0.1-a.png) | Прототип 0.1: капсульні бійці зчепились мечем, фон — коробки-будинки з вогниками вікон. У HUD ще старе ім'я `SKEASSE`, таймер 99 | Кліо | `5c5bb76` | [[2026-10-02-Prototype-0.1]] · [[2026-10-02-prototype-build]] |
| [2026-10-02-prototype-0.1-b.png](../assets/screenshots/2026-10-02-prototype-0.1-b.png) | Те саме за 3 с: таймер 96, у Skea перезаряджається S1 (`S1 4.9`) | Кліо | `5c5bb76` | [[2026-10-02-Prototype-0.1]] · [[2026-10-02-prototype-build]] |
| [2026-10-02-kits-a.png](../assets/screenshots/2026-10-02-kits-a.png) | «Flash, time stop, rewind» | зі сторінки | `612e6b4` | [[Skea]] § VFX-напрям |
| [2026-10-02-kits-b.png](../assets/screenshots/2026-10-02-kits-b.png) | «Kunai, veil, grimoire, sword storm» | зі сторінки | `612e6b4` | [[Skea]] § VFX-напрям |

## Прохідний квартал — крамниці, мешканці, бій, меню (пакет `codex/playable-district`, 2026-10-05)

Кадри лежать у теці `2026-10-05-playable-district/`; два окремі кадри — поруч у корені. Native capture, Xvfb, OpenGL Compatibility / Mesa llvmpipe.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-05-district-friendship.png](../assets/screenshots/2026-10-05-district-friendship.png) | «Дружба з працівником крамниці після фактичних доручень»: дружба 6/10 після виконаних доручень і нової теми; майже непрозорий діалог — виправлення після зауваження T4 про накладення написів крамниці | зі сторінки | `a5df5e0` | [[2026-10-05-Playable-District-Review]] § Видимі свідчення |
| [2026-10-05-district-locomotion.png](../assets/screenshots/2026-10-05-district-locomotion.png) | «Реальна послідовність руху Skea»: вибірки з fixed-clock послідовності — змотування під час ходи, рух і гальмування | зі сторінки | `a5df5e0` | [[2026-10-05-Playable-District-Review]] § Видимі свідчення |
| [authored-combat-contact-proof.png](../assets/screenshots/2026-10-05-playable-district/authored-combat-contact-proof.png) | «Контакт lowhand і hammer на двох справжніх моделях»: сітка 3×4 — рядки Choko lowhand / hammer, Skea lowhand / hammer; колонки windup / contact / recovery; кадри 960×720 зменшено до 480×360 | зі сторінки | `a5df5e0` | [[2026-10-05-Authored-Combat]] · [[2026-10-05-Playable-District-Review]] |
| [grocer_dialogue.png](../assets/screenshots/2026-10-05-playable-district/grocer_dialogue.png) | «Розмова у крамниці після прийняття завдання» | зі сторінки | `a5df5e0` | [[2026-10-05-District-Life]] |
| [tailor_choices.png](../assets/screenshots/2026-10-05-playable-district/tailor_choices.png) | «Справжні варіанти перев'язі у кравця» | зі сторінки | `a5df5e0` | [[2026-10-05-District-Life]] |
| [hero_cloth_style.png](../assets/screenshots/2026-10-05-playable-district/hero_cloth_style.png) | «Перев'язь і пояс на герої; мешканці поза колишньою сіткою»: передня й задня смуги та пояс | зі сторінки | `a5df5e0` | [[2026-10-05-District-Life]] |
| [shop_fronts.jpg](../assets/screenshots/2026-10-05-playable-district/shop_fronts.jpg) | «Три прохідні фасади» | зі сторінки | `0af967f` | [[2026-10-05-Playable-District-Art]] § Кадри цього проходу |
| [grocer_inside.jpg](../assets/screenshots/2026-10-05-playable-district/grocer_inside.jpg) | «Крамниця: хліб, трави та припаси» | зі сторінки | `0af967f` | [[2026-10-05-Playable-District-Art]] § Кадри цього проходу |
| [tailor_inside.jpg](../assets/screenshots/2026-10-05-playable-district/tailor_inside.jpg) | «Ательє: розкрійний стіл і тканини» | зі сторінки | `0af967f` | [[2026-10-05-Playable-District-Art]] § Кадри цього проходу |
| [workshop_inside.jpg](../assets/screenshots/2026-10-05-playable-district/workshop_inside.jpg) | «Майстерня: верстак і механізми» | зі сторінки | `0af967f` | [[2026-10-05-Playable-District-Art]] § Кадри цього проходу |
| [shop_street.jpg](../assets/screenshots/2026-10-05-playable-district/shop_street.jpg) | Вулиця вздовж крамниць: рожевий будинок з арковими вікнами, зелений навіс із вивіскою «Майс… «Мідна година»» (частково затулена), відкриті вітрини, дві лавки з кашпо на бруківці, праворуч — вода за парапетом. На передньому плані дві чорні лінії; що це — з кадру не видно | Кліо, 2026-10-16 | `0af967f` «Checkpoint playable district systems and native review blockers» | не вбудований |
| [district_menu.png](../assets/screenshots/2026-10-05-playable-district/district_menu.png) | «Головне меню» | зі сторінки | `0af967f` | [[2026-10-05-District-Delivery]] |
| [district_hud.png](../assets/screenshots/2026-10-05-playable-district/district_hud.png) | «Журнал у HUD» | зі сторінки | `0af967f` | [[2026-10-05-District-Delivery]] |
| [district_pause.png](../assets/screenshots/2026-10-05-playable-district/district_pause.png) | «Пауза й журнал» | зі сторінки | `0af967f` | [[2026-10-05-District-Delivery]] |

## Продовження подорожі — журнал доручень і напрямок (T8 · T4, 2026-10-05)

Тека `2026-10-05-district-journey/`. Native кадри з реального `CityWorld`, цілей і HUD, 1280×720 і 960×540.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [quest_front_720.png](../assets/screenshots/2026-10-05-district-journey/quest_front_720.png) | «Ціль попереду, 1280×720» | зі сторінки | `9d959f9` | [[2026-10-05-Quest-Journal-And-Guide]] § Native докази (посилання, не картинка) |
| [quest_behind_720.png](../assets/screenshots/2026-10-05-district-journey/quest_behind_720.png) | «Ціль позаду, 1280×720»; сторінка попереджає, що задній ракурс може дивитися на сусідню стіну | зі сторінки | `9d959f9` | [[2026-10-05-Quest-Journal-And-Guide]] § Native докази (посилання, не картинка) |
| [quest_roof_720.png](../assets/screenshots/2026-10-05-district-journey/quest_roof_720.png) | «Ціль на даху, 1280×720» | зі сторінки | `9d959f9` | [[2026-10-05-Quest-Journal-And-Guide]] § Native докази (посилання, не картинка) |
| [quest_journal_720.png](../assets/screenshots/2026-10-05-district-journey/quest_journal_720.png) | «Вибране доручення у журналі, 1280×720»; фінальний кадр UI-смуги з версією 0.4.1, переглянутий T4 | зі сторінки | `9d959f9` | [[2026-10-05-Quest-Journal-And-Guide]] · [[2026-10-05-District-Journey-Review]] § Видимий результат |
| [quest_journal_540.png](../assets/screenshots/2026-10-05-district-journey/quest_journal_540.png) | «Журнал і checkpoint, 960×540» | зі сторінки | `9d959f9` | [[2026-10-05-Quest-Journal-And-Guide]] § Native докази (посилання, не картинка) |
| [quest_roof_540.png](../assets/screenshots/2026-10-05-district-journey/quest_roof_540.png) | «Напрямок на дах, 960×540» | зі сторінки | `9d959f9` | [[2026-10-05-Quest-Journal-And-Guide]] § Native докази (посилання, не картинка) |
| [resume_roof_t4.png](../assets/screenshots/2026-10-05-district-journey/resume_roof_t4.png) | «Повернення на міст після меню та завантаження»: повторний вхід після menu/disk loop повертає Choko на міст дахів | зі сторінки | `9d959f9` | [[2026-10-05-District-Journey-Review]] § Видимий результат |

## Рух і читабельність кварталу (T2 · T6 · T4, 2026-10-05)

Теки `2026-10-05-district-motion/` і `2026-10-05-district-readability/`. Повні журнали й відео — поза репо, див. [[2026-10-05-District-Motion-Checkpoint]].

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [motion-contact-proof.png](../assets/screenshots/2026-10-05-district-motion/motion-contact-proof.png) | «Ухилення й рухомий контакт»: native contact sheet — Choko dodge, Skea dodge, Choko moving landing, Skea moving landing; у кожному рядку початок / контакт / повернення | зі сторінки | `9685dfa` | [[2026-10-05-Authored-Evasion-And-Landing]] · [[2026-10-05-District-Motion-Review]] |
| [moving-landing-before-after.png](../assets/screenshots/2026-10-05-district-motion/moving-landing-before-after.png) | «Рухоме приземлення до й після»: м'якше згинання колін біля контакту з продовженням кроку | зі сторінки | `4d1b954` | [[2026-10-05-District-Motion-Review]] |
| [bridge-before-after.png](../assets/screenshots/2026-10-05-district-motion/bridge-before-after.png) | «Міст до й після»: крізь відкриті перила видно ноги, дальні будинки додають глибини | зі сторінки | `4d1b954` | [[2026-10-05-District-Motion-Review]] |
| [market.png](../assets/screenshots/2026-10-05-district-motion/market.png) | «Ринок» — один із 12 фінальних world-ракурсів | зі сторінки | `4d1b954` | [[2026-10-05-District-Motion-Review]] |
| [tailor_in.png](../assets/screenshots/2026-10-05-district-motion/tailor_in.png) | «Ательє»: впізнаваний одяг | зі сторінки | `4d1b954` | [[2026-10-05-District-Motion-Review]] |
| [workshop_in.png](../assets/screenshots/2026-10-05-district-motion/workshop_in.png) | «Майстерня»: годинник та інструменти | зі сторінки | `4d1b954` | [[2026-10-05-District-Motion-Review]] |
| [near-camera-before-after.png](../assets/screenshots/2026-10-05-district-motion/near-camera-before-after.png) | «Камера у крамниці до й після»: до — обрізана голова героя на передньому плані за прилавком; після — камера вище, близький герой прибраний матеріалом, видно вихід і прилавок | зі сторінки | `4d1b954` | [[2026-10-05-District-Motion-Review]] |
| [bridge_before.jpg](../assets/screenshots/2026-10-05-district-readability/bridge_before.jpg) | «Міст: суцільний парапет і порожній горизонт» (до) | зі сторінки | `9685dfa` | [[2026-10-05-District-Silhouette-And-Readability]] |
| [bridge_after.jpg](../assets/screenshots/2026-10-05-district-readability/bridge_after.jpg) | «Міст: відкриті перила й дальня забудова» (після) | зі сторінки | `9685dfa` | [[2026-10-05-District-Silhouette-And-Readability]] |
| [tailor.jpg](../assets/screenshots/2026-10-05-district-readability/tailor.jpg) | «Ательє: підвішений одяг» | зі сторінки | `9685dfa` | [[2026-10-05-District-Silhouette-And-Readability]] |
| [workshop.jpg](../assets/screenshots/2026-10-05-district-readability/workshop.jpg) | «Майстерня: годинник і дошка інструментів» | зі сторінки | `9685dfa` | [[2026-10-05-District-Silhouette-And-Readability]] |

## Живий квартал — гак у руках і фантазійні мешканці (T2 · T6 · T4, 2026-10-05)

Теки `2026-10-05-living-district/` і `2026-10-05-living-residents/`. Важкі native-кадри й MP4 — поза git ([[2026-10-05-Living-District-Review]]).

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [authored-hook-proof.jpg](../assets/screenshots/2026-10-05-living-district/authored-hook-proof.jpg) | «Choko та Skea: замах, підтягування й перенесення до та після»: незмінений рендер Godot з приймальних послідовностей, лише crop / scale / підписи | зі сторінки | `2a72f9d` | [[2026-10-05-Authored-Hook-Motion]] |
| [lineup_before.png](../assets/screenshots/2026-10-05-living-residents/lineup_before.png) | «До: незалежна baseline копія f4defd5, ті самі seeds і камера» | зі сторінки | `2a72f9d` | [[2026-10-05-Fantasy-Residents-And-Chatter]] |
| [lineup_front.png](../assets/screenshots/2026-10-05-living-residents/lineup_front.png) | «Після: дванадцять фіксованих seed, той самий native renderer» | зі сторінки | `2a72f9d` | [[2026-10-05-Fantasy-Residents-And-Chatter]] |
| [lineup_back.png](../assets/screenshots/2026-10-05-living-residents/lineup_back.png) | «Складені крила, хвости та спини» | зі сторінки | `2a72f9d` | [[2026-10-05-Fantasy-Residents-And-Chatter]] |
| [worker_1.png](../assets/screenshots/2026-10-05-living-residents/worker_1.png) | «Кам'яний мешканець, фартух і предмет роботи» | зі сторінки | `2a72f9d` | [[2026-10-05-Fantasy-Residents-And-Chatter]] |
| [grocer_conversation.png](../assets/screenshots/2026-10-05-living-residents/grocer_conversation.png) | «Крамниця: лисоподібна співрозмовниця та панель праворуч» | зі сторінки | `2a72f9d` | [[2026-10-05-Fantasy-Residents-And-Chatter]] § Інтегрована production-камера після CP1 |
| [tailor_conversation.png](../assets/screenshots/2026-10-05-living-residents/tailor_conversation.png) | «Ательє: молеподібний кравець у реальній сцені» | зі сторінки | `2a72f9d` | [[2026-10-05-Fantasy-Residents-And-Chatter]] § Інтегрована production-камера після CP1 |
| [workshop_conversation.png](../assets/screenshots/2026-10-05-living-residents/workshop_conversation.png) | «Майстерня: співрозмовниця, годинник і відкриті кисті» | зі сторінки | `2a72f9d` | [[2026-10-05-Fantasy-Residents-And-Chatter]] § Інтегрована production-камера після CP1 |
| [city_crowd.png](../assets/screenshots/2026-10-05-living-residents/city_crowd.png) | «Різні силуети в натовпі на production-камері» | зі сторінки | `2a72f9d` | [[2026-10-05-Fantasy-Residents-And-Chatter]] § Інтегрована production-камера після CP1 |
| [greet_2.png](../assets/screenshots/2026-10-05-living-residents/greet_2.png) | Один мешканець на сірій плашці: лисоподібний, у зеленій сорочці з поясом і торбою, з хвостом; одна рука піднята біля голови — за ім'ям файлу, жест вітання (greet). Сторінка згадує greet-кадри `appearance_capture.gd`, але цей не вбудовує | Кліо, 2026-10-16 | `2a72f9d` «Add close rope contact and expressive living district residents» | не вбудований |

## Все тіло — анатомія руху (T6 · T2, 2026-10-05)

Тека `2026-10-05-whole-body/`. Baseline — `3df43a5`; повні послідовності й відео — поза репо ([[2026-10-05-Whole-Body-Checkpoint]]).

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [choko_side.jpg](../assets/screenshots/2026-10-05-whole-body/choko_side.jpg) | «Choko: ранній baseline, дванадцять фаз із бокового ракурсу» | зі сторінки | `4c68473` | [[2026-10-05-Whole-Body-Visual-Audit]] |
| [skea_side.jpg](../assets/screenshots/2026-10-05-whole-body/skea_side.jpg) | «Skea: та сама послідовність і камера» | зі сторінки | `4c68473` | [[2026-10-05-Whole-Body-Visual-Audit]] |
| [hook_side_choko_moving.jpg](../assets/screenshots/2026-10-05-whole-body/hook_side_choko_moving.jpg) | «Реальний moving cast, windup → підхоплення → reel» | зі сторінки | `4c68473` | [[2026-10-05-Whole-Body-Visual-Audit]] |
| [motion-comparison.jpg](../assets/screenshots/2026-10-05-whole-body/motion-comparison.jpg) | «Однакові фази руху: baseline ліворуч, CP5 праворуч» | зі сторінки | `4c68473` | [[2026-10-05-Whole-Body-Visual-Audit]] |
| [hook-comparison.jpg](../assets/screenshots/2026-10-05-whole-body/hook-comparison.jpg) | «Однаковий moving reel frame60: baseline ліворуч, CP5 праворуч» | зі сторінки | `4c68473` | [[2026-10-05-Whole-Body-Visual-Audit]] |
| [city-contact-comparison.jpg](../assets/screenshots/2026-10-05-whole-body/city-contact-comparison.jpg) | «Actual CityWorld: baseline дах, final дах, final рампа; обидва герої» | зі сторінки | `4c68473` | [[2026-10-05-Whole-Body-Visual-Audit]] |
| [combat-anatomy.jpg](../assets/screenshots/2026-10-05-whole-body/combat-anatomy.jpg) | «Контактні кадри Choko та Skea до та після»: native кадри першого active frame, лише resize / компонування й підписи | зі сторінки | `4c68473` | [[2026-10-05-Whole-Body-Presentation]] |

## Спорядження, меч і одяг (T6 · T2, 2026-10-05)

Тека `2026-10-05-equipment/`. Frozen baseline — `4c68473`. Кадри з відхиленою кислотною поверхнею сторінка позначає як історичні.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [baseline-overview.jpg](../assets/screenshots/2026-10-05-equipment/baseline-overview.jpg) | «Frozen baseline: Choko back/right hand/left attack; Skea front/side/back» | зі сторінки | `f6d31fa` | [[2026-10-05-Equipment-Visual-Audit]] |
| [sword-candidate-review.jpg](../assets/screenshots/2026-10-05-equipment/sword-candidate-review.jpg) | «Ранній thin sword candidate, не фінальний provider texture pass» | зі сторінки | `f6d31fa` | [[2026-10-05-Equipment-Visual-Audit]] |
| [npc-fit-fallback.jpg](../assets/screenshots/2026-10-05-equipment/npc-fit-fallback.jpg) | «NPC seams and garment fitting, provider maps absent»: ліворуч baseline `4c68473`, праворуч чинна геометрія з локальним fallback; surface pass цього кадру відхилено | зі сторінки | `f6d31fa` | [[2026-10-05-Equipment-Visual-Audit]] |
| [npc-detail-restored.jpg](../assets/screenshots/2026-10-05-equipment/npc-detail-restored.jpg) | «Baseline macro-detail restored; new panels retain fallback materials» | зі сторінки | `f6d31fa` | [[2026-10-05-Equipment-Visual-Audit]] |
| [gear-checkpoint.jpg](../assets/screenshots/2026-10-05-equipment/gear-checkpoint.jpg) | «Matched geometry checkpoint: back sword, right hand, Skea book» | зі сторінки | `f6d31fa` | [[2026-10-05-Equipment-Visual-Audit]] |
| [final-close-skea_idle_side.png](../assets/screenshots/2026-10-05-equipment/final-close-skea_idle_side.png) | «Skea book side: page thickness visible, cover material pending» | зі сторінки | `f6d31fa` | [[2026-10-05-Equipment-Visual-Audit]] |
| [reference-correction.jpg](../assets/screenshots/2026-10-05-equipment/reference-correction.jpg) | «Rejected acid-green and rings on left; corrected reference-based palette and single infinity on right» | зі сторінки | `f6d31fa` | [[2026-10-05-Equipment-Visual-Audit]] · [[2026-10-05-Equipment-Sword-Craft]] (шлях у тексті) |
| [final-close-choko_stowed_side.png](../assets/screenshots/2026-10-05-equipment/final-close-choko_stowed_side.png) | Choko збоку, меч у піхвах на спині (зелене лезо, обмотка з латунню), напис на кадрі `choko \| stowed \| side \| FIT CANDIDATE - NO PROVIDER MAP` | Кліо, 2026-10-16 | `f6d31fa` «Refine sword handling, tailored gear, and canonical equipment surfaces» | не вбудований |
| [final-close-skea_idle_back.png](../assets/screenshots/2026-10-05-equipment/final-close-skea_idle_back.png) | Skea зі спини: темна книга на спині з одним ліловим знаком ∞, напис на кадрі `skea \| idle \| back \| REFERENCE CORRECTION - FALLBACK`. Перезаписаний у `5f32deb` | Кліо, 2026-10-16 | `f6d31fa` «Refine sword handling, tailored gear, and canonical equipment surfaces» | не вбудований |
| [corrected-sigil-close.png](../assets/screenshots/2026-10-05-equipment/corrected-sigil-close.png) | Байт у байт той самий кадр, що `final-close-skea_idle_back.png` (`sha256sum` → `4e8575c074fb485f…` в обох) | Кліо, 2026-10-16 | `5f32deb` «Document verified equipment package and pending texture admission» | не вбудований |

## Трюки в місті й якість картинки (T6, 2026-10-05)

Тека `2026-10-05-tricks-quality/`. Рівно три компактні sheets з native PNG, нічого не домальовано; повні кадри — в evidence-каталогах поза репо.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [city-quality-profiles.png](../assets/screenshots/2026-10-05-tricks-quality/city-quality-profiles.png) | «Місто: однакові production пози у High та Low»: High краще тримає край героя, дроти й діагоналі дахів; Low має видимі сходинки, HUD різкий в обох | зі сторінки | `3970041` | [[2026-10-05-Traversal-And-Surface-Review]] |
| [landing-roll-sequences.png](../assets/screenshots/2026-10-05-tricks-quality/landing-roll-sequences.png) | «Перекат Choko та Skea: початок, середина й вихід у двох ракурсах» | зі сторінки | `3970041` | [[2026-10-05-Traversal-And-Surface-Review]] |
| [production-tricks-and-camera-limit.png](../assets/screenshots/2026-10-05-tricks-quality/production-tricks-and-camera-limit.png) | «Production трюки та явно збережений проблемний ракурс камери»: шість панелей, 960 × 1032; угорі — відкритий wall kick і перекат обох героїв, унизу — тісна станція `[4, 0, 31.4]`, де Choko майже зникає в dither (T6 не приймає) | зі сторінки | `3970041` | [[2026-10-05-Traversal-And-Surface-Review]] · [[2026-10-07-Tight-Station-Readability-Criteria]] (шлях у тексті) |

## Тісна станція — камера біля опори (T2 · T6 · T3, 2026-10-07)

Тека `2026-10-07-tight-station/`. Повні кадри — у scratchpad сесій, не в репо.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [tight-station-overview.png](../assets/screenshots/2026-10-07-tight-station/tight-station-overview.png) | «Тісна станція: стоячи, hang, drop, kick, перескок через стіну, після kick; контроль і ручний yaw»: A–F — тісна станція, G — відкрита, H — тісна з ручним поворотом на +90°; підписи з `receipt.json` | зі сторінки | `d205370` | [[2026-10-07-Tight-Station-Camera-Baseline]] |
| [choko-tight-kick-strip-t64-88.jpg](../assets/screenshots/2026-10-07-tight-station/choko-tight-kick-strip-t64-88.jpg) | «Choko, тісний kick, тіки 64–88 підряд: тіло в лінзі, далі arm 6,0 ↔ 0,2–0,4 м через межову стіну» | зі сторінки | `d205370` | [[2026-10-07-Tight-Station-Camera-Baseline]] |
| [fix-before-after.jpg](../assets/screenshots/2026-10-07-tight-station/fix-before-after.jpg) | «До: тіло в лінзі й лінза за межею; після на тій самій геометрії: силует із контуром і м'якший перескок; після на новій опорі: arm 6 м» | зі сторінки | `b5f10d2` | [[2026-10-07-Tight-Support-Camera-Fix]] |
| [t6-fix-review-evidence.jpg](../assets/screenshots/2026-10-07-tight-station/t6-fix-review-evidence.jpg) | «Нова опора K3–K4 з мешканцем; фікстура: мерехтіння t72–t75 і темна фігура при заливці 0,34–0,60–0,25» | зі сторінки | `ff9fcda` | [[2026-10-07-Tight-Station-Fix-Review]] |
| [t3-stencil-variants.png](../assets/screenshots/2026-10-07-tight-station/t3-stencil-variants.png) | Зведений кадр вимірів T3 (сфера, vis 0,25): V0 / V1 — темна маса; V2 / V3 — сцена крізь заливку, контур зовні; на парі сфер V2 втрачає внутрішній контур, V3 зберігає. Опис — T1, що відкрив кадр | зі сторінки | `15aea6a` | [[2026-10-07-Stencil-And-Line-Of-Sight]] · [[2026-10-07-Camera-Readability-Iteration-2]] § Рішення після кроку 1 (шлях у тексті) |
| [t2-iteration2-before-after.jpg](../assets/screenshots/2026-10-07-tight-station/t2-iteration2-before-after.jpg) | Зведений кадр ітерації 2: ряди «до» з `after-strips` (ітерація 1), «після» з `it2-final-art`; крізь дірки заливки видно край опори, вулицю й місце приземлення | зі сторінки | `6141232` | [[2026-10-07-Camera-Readability-Iteration-2-Fix]] (посилання, не картинка) |

## Перший ворог — Ліхтарник, смертельний бій, запечатані навички (T1 · T2, 2026-10-07)

Тека `2026-10-07-lamplighter/` — прев'ю генерацій Higgsfield (головна сесія T1, слово Santos «все дозволено»); у `game/assets/` вони не йдуть. Кадри гри — нативні, Compatibility / llvmpipe, 1600 × 900, художньо не прийняті.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [lamplighter-sheet-v1-a.jpg](../assets/screenshots/2026-10-07-lamplighter/lamplighter-sheet-v1-a.jpg) | Лист поз A (обрано T1): одне обличчя й одна жердина у 8 позах, гак вище голови в позах 1 / 2 / 7 / 8, без червоного, помаранчу й фіолету | зі сторінки | `b8a615d` | [[Prompt-Library]] § 19e (шлях до теки в тексті) |
| [lamplighter-sheet-v1-b.jpg](../assets/screenshots/2026-10-07-lamplighter/lamplighter-sheet-v1-b.jpg) | Лист поз B (відхилено): фіолетова підкладка в розрізах, у позах 2 і 5 — два ліхтарі | зі сторінки | `b8a615d` | [[Prompt-Library]] § 19e (шлях до теки в тексті) |
| [lamplighter-tposes-v1.jpg](../assets/screenshots/2026-10-07-lamplighter/lamplighter-tposes-v1.jpg) | T-пози front / ¾ v2 / back в один ряд: шинель, кашкет, пояс, ліхтар на лівому стегні (праворуч у кадрі) | зі сторінки; ряд звірила Кліо, 2026-10-16 | `b8a615d` | [[Prompt-Library]] § 19e (шлях до теки в тексті) |
| [lamplighter-item-pole-v1.jpg](../assets/screenshots/2026-10-07-lamplighter/lamplighter-item-pole-v1.jpg) | Картка жердини: 4 види й 2 вставки; гасильник читається як дзвіночок-конус | зі сторінки | `b8a615d` | [[Prompt-Library]] § 19e (шлях до теки в тексті) |
| [2026-10-07-lethal-fight-core.jpg](../assets/screenshots/2026-10-07-lethal-fight-core.jpg) | «Вхід на безпечній точці, раунд 1, телеграф SNUFF, LAMPLIGHTER FALLS»: кільце входу й підказка `G · FACE THE LAMPLIGHTER`; смуга H2 з `ROUND 1 — TO THE DEATH`; Ліхтарник із жердиною; SNUFF — жердина над головою обома руками; після вирішального KO — тіло на землі | зі сторінки | `13fd6ac` | [[2026-10-07-Lethal-Fight-Core-Fix]] |
| [2026-10-07-city-skill-hint-and-comfort.jpg](../assets/screenshots/2026-10-07-city-skill-hint-and-comfort.jpg) | «Підказка біля героя, пауза міста, COMFORT & CONTROLS над нею» | зі сторінки | `6018936` | [[2026-10-07-City-Skill-Hint-And-Comfort-Fix]] |

## Трос без прицілювання (T2, 2026-10-07)

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-07-aim-free-rope.jpg](../assets/screenshots/2026-10-07-aim-free-rope.jpg) | «Кільце на ліхтарі з безпечної точки; стрілка на верхньому краї під ліхтарем; сіре кільце TOO FAR і рядок відмови на старті з базовими 4 якорями; кронштейн на фасаді ринку». Нативний Compatibility, 1280 × 720 | зі сторінки | `aa51881` | [[2026-10-07-Aim-Free-Rope-Fix]] § Кадри |

## Відтінок чавуну — A/B (T6, 2026-10-09)

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-09-iron-paint-ab.jpg](../assets/screenshots/2026-10-09-iron-paint-ab.jpg) | Аркуш порівняння відтінку чавуну, стовпці: зараз · A · B · C. На кандидата чотири кадри: колонка з точки `pump.png` камерою гри, колонка зблизька поперек сонця, стовп-якір (−9; 0; 8) камерою гри за героєм, той самий стовп зблизька. Обрано B — `#577368` | зі сторінки | `41ed842` | [[2026-10-08-City-Modern-Realism-Props]] § Кадри A/B · [[ADR-027-City-Modern-Props-Style-And-Path]] (шлях у тексті) |

## Приймання T6 — тент, сходинки, паромобілі, анімації (T6, 2026-10-14)

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-14-t6-awning.jpg](../assets/screenshots/2026-10-14-t6-awning.jpg) | «Згорнутий тент: вулиця, порівняння з кравцем, звис на якорі 16, вигляд знизу»; вердикт YELLOW | зі сторінки | `31f7c59` | [[2026-10-14-T6-Acceptance]] § 1 |
| [2026-10-14-t6-steps.jpg](../assets/screenshots/2026-10-14-t6-steps.jpg) | «Сходинки: бочки дьогтю в куті, Skea на рампі, Choko на ободі, бочка «Шавлії» → полиця» | зі сторінки | `31f7c59` | [[2026-10-14-T6-Acceptance]] § 2 |
| [2026-10-14-t6-vehicles-iron.jpg](../assets/screenshots/2026-10-14-t6-vehicles-iron.jpg) | «Паромобілі й чавун»; вердикт GREEN | зі сторінки | `31f7c59` | [[2026-10-14-T6-Acceptance]] § 3 |
| [2026-10-14-t6-anim-landing.jpg](../assets/screenshots/2026-10-14-t6-anim-landing.jpg) | «Посадка з місця, Choko: до (main 595490d) і після (e6379ed)» | зі сторінки | `31f7c59` | [[2026-10-14-T6-Acceptance]] § 4 |
| [2026-10-14-t6-anim-rope.jpg](../assets/screenshots/2026-10-14-t6-anim-rope.jpg) | «Трос, Choko: тяга й гойдання D/A» | зі сторінки | `31f7c59` | [[2026-10-14-T6-Acceptance]] § 4 |
| [2026-10-14-t6-anim-wall.jpg](../assets/screenshots/2026-10-14-t6-anim-wall.jpg) | «Відштовхування від стіни, Choko: кік і посадка після нього» | зі сторінки | `31f7c59` | [[2026-10-14-T6-Acceptance]] § 4 |

## Паровий кран № 10 і лебідка № 11 (T2-А, 2026-10-14)

Кадри для приймання T6, стиснені з сирих PNG (`crane_frames.gd`, rc 0). T2 кадрів не приймає.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-14-crane-s2.jpg](../assets/screenshots/2026-10-14-crane-s2.jpg) | Південь вулиці (S2): лінзу на 2,90 м зупиняє корпус SE, кран — угорі праворуч на тлі цегляного фасаду з вікнами | зі сторінки | `a4b542a` | [[2026-10-14-Steam-Crane-Winch-Fix]] § 6 |
| [2026-10-14-crane-s3.jpg](../assets/screenshots/2026-10-14-crane-s3.jpg) | Під стрілою (S3): колона над краєм тераси у верхній частині кадру — пункт A5 «на S3 його в кадрі немає» не виконується | зі сторінки | `a4b542a` | [[2026-10-14-Steam-Crane-Winch-Fix]] § 0 п. 11, § 6 |
| [2026-10-14-crane-s6.jpg](../assets/screenshots/2026-10-14-crane-s6.jpg) | Східний вихід мосту (S6): увесь кран — цоколь, колона, кабіна, стріла, тяги, гак; ліворуч лебідка з маховиком | зі сторінки | `a4b542a` | [[2026-10-14-Steam-Crane-Winch-Fix]] § 6 |
| [2026-10-14-crane-grey-s1-s2-s5-s6.jpg](../assets/screenshots/2026-10-14-crane-grey-s1-s2-s5-s6.jpg) | Сірі кадри S1, S2, S5, S6 для К1 і С-6 | зі сторінки | `a4b542a` | [[2026-10-14-Steam-Crane-Winch-Fix]] § 6 · [[2026-10-14-T6-Crane-Winch-Acceptance]] § 2 (шлях у тексті) |
| [2026-10-14-crane-silhouette.jpg](../assets/screenshots/2026-10-14-crane-silhouette.jpg) | Силует Blender: кран збоку, лебідка в 3/4 (A4) | зі сторінки | `a4b542a` | [[2026-10-14-Steam-Crane-Winch-Fix]] § 6 · [[2026-10-14-T6-Crane-Winch-Acceptance]] § 2 (шлях у тексті) |

## A/B темних кольорів — альбедо в `light()` (T2-Б, 2026-10-14)

Аркуші A | Б1, підписані, ≤ 300 КБ. Сира серія PNG 1920 × 1080 — у scratchpad, не в репо.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-14-albedo-ab-street.jpg](../assets/screenshots/2026-10-14-albedo-ab-street.jpg) | Колонка, лавки. Б1: бруківка на світлі майже біла (А `#907c6d` → Б1 `#eae3d6`), теракота фасаду з червоної стає персиковою; колонка й лавки світлішають до сіро-зеленого | зі сторінки | `da35f19` | [[2026-10-14-Albedo-AB-Fix]] § Що видно на кадрах |
| [2026-10-14-albedo-ab-market.jpg](../assets/screenshots/2026-10-14-albedo-ab-market.jpg) | Ринок. У А стіна теракоти яскраво-червона (лампи крамниць), у Б1 — кремово-персикова; тканини ятки бліднуть | зі сторінки | `da35f19` | [[2026-10-14-Albedo-AB-Fix]] § Що видно на кадрах |
| [2026-10-14-albedo-ab-plaster.jpg](../assets/screenshots/2026-10-14-albedo-ab-plaster.jpg) | Фасад зі штукатуркою. А: штукатурка тепло-жовта, сланцевий фасад темно-синій; Б1: штукатурка майже біла, сланець у тіні сіро-блакитний (`slate` тінь ΔE 22,5 → 6,6) | зі сторінки | `da35f19` | [[2026-10-14-Albedo-AB-Fix]] § Що видно на кадрах |
| [2026-10-14-albedo-ab-vehicles.jpg](../assets/screenshots/2026-10-14-albedo-ab-vehicles.jpg) | Паровантажівка, паролегковик. Б1: брезент і борти світлішають, бруківка біля рампи пересвічена; силуети машин читаються в обох | зі сторінки | `da35f19` | [[2026-10-14-Albedo-AB-Fix]] § Що видно на кадрах |
| [2026-10-14-albedo-ab-hero.jpg](../assets/screenshots/2026-10-14-albedo-ab-hero.jpg) | Крупний план Choko і Skea. Б1: куртка Choko жовтіє, фіолетові штани стають лавандовими (L* 55,6 → 80,5); фіолет Skea світліший (L* 44,4 → 59,4); тіні на тілі лишаються | зі сторінки | `da35f19` | [[2026-10-14-Albedo-AB-Fix]] § Що видно на кадрах |
| [2026-10-14-albedo-ab-sun.jpg](../assets/screenshots/2026-10-14-albedo-ab-sun.jpg) | Ринок, лавки — діагностика `--only-sun`: без ламп теракота в А приглушено-рожева, у Б1 — світло-рожева (на M3 не перевірено) | зі сторінки | `da35f19` | [[2026-10-14-Albedo-AB-Fix]] § Що видно на кадрах |

## Приймання T6 — кран і лебідка; правка тенту (T6 · T2-В, 2026-10-14)

Кадри з іменем 2026-10-14 закомічені вже 2026-10-15 о 04:02 UTC (`git log -1 --format=%ci 87a85dc`).

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-14-t6-crane-street.jpg](../assets/screenshots/2026-10-14-t6-crane-street.jpg) | «Вулиця: S1–S4, кран — пурпурова маска, лебідка — блакитна» | зі сторінки | `87a85dc` | [[2026-10-14-T6-Crane-Winch-Acceptance]] § Підсумок |
| [2026-10-14-t6-crane-terrace.jpg](../assets/screenshots/2026-10-14-t6-crane-terrace.jpg) | «Тераса й міст: S5, S6, S7 і S6 у сірому» | зі сторінки | `87a85dc` | [[2026-10-14-T6-Crane-Winch-Acceptance]] § Підсумок |
| [2026-10-14-t6-crane-zoom.jpg](../assets/screenshots/2026-10-14-t6-crane-zoom.jpg) | «Зум 200 %: кран з S6, лебідка з S7» | зі сторінки | `87a85dc` | [[2026-10-14-T6-Crane-Winch-Acceptance]] § 1 |
| [2026-10-14-t6-crane-low-pan.jpg](../assets/screenshots/2026-10-14-t6-crane-low-pan.jpg) | «Low, панорама: стріла з S1 і з S6, по 4 сусідні кадри, 3×» | зі сторінки | `87a85dc` | [[2026-10-14-T6-Crane-Winch-Acceptance]] § 1 |
| [2026-10-14-t6-crane-edge.jpg](../assets/screenshots/2026-10-14-t6-crane-edge.jpg) | «Край: смуга x 30…32 і розбіг через лебідку» | зі сторінки | `87a85dc` | [[2026-10-14-T6-Crane-Winch-Acceptance]] § 4 |
| [2026-10-14-t6-crane-hud.jpg](../assets/screenshots/2026-10-14-t6-crane-hud.jpg) | «HUD: кільце троса й картка QUEST, h1 · h3 · h7 · h8» — картка QUEST закриває верхню третину | зі сторінки | `87a85dc` | [[2026-10-14-T6-Crane-Winch-Acceptance]] § 5 |
| [2026-10-14-t6fix-awning.jpg](../assets/screenshots/2026-10-14-t6fix-awning.jpg) | «Згорнутий тент «Шавлії»: до (ліворуч) і після (праворуч), aw1–aw4»; кран на тлі «після» — з `a4b542a`; `aw1` обрізано до тенту | зі сторінки | `87a85dc` | [[2026-10-14-T6-Acceptance-Geometry-Fix]] § 7 |

## Приймання T6 — правки геометрії: тент, бочка дьогтю, верстак, глечики, 9 OPEN (T6, 2026-10-15)

Дерево — detached `87a85dc`; T6 записала лише сторінку приймання й ці 5 кадрів.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-15-t6-awning.jpg](../assets/screenshots/2026-10-15-t6-awning.jpg) | «Рулон тенту з камери міста: aw1 у кольорі й сірому, aw2, aw5»; вердикт GREEN | зі сторінки | `e3b127b` | [[2026-10-15-T6-Geometry-Fix-Acceptance]] § 1 |
| [2026-10-15-t6-tar-yard.jpg](../assets/screenshots/2026-10-15-t6-tar-yard.jpg) | «Бочки дьогтю й верстак у куті двору: st11, st12, yd2»; Choko більше не на ободі | зі сторінки | `e3b127b` | [[2026-10-15-T6-Geometry-Fix-Acceptance]] § 2 |
| [2026-10-15-t6-crest.jpg](../assets/screenshots/2026-10-15-t6-crest.jpg) | «Choko з верстака на гребінь SouthWall: К7 t036 і t054, гребінь з камери міста й з вулиці» | зі сторінки | `e3b127b` | [[2026-10-15-T6-Geometry-Fix-Acceptance]] § 3 |
| [2026-10-15-t6-grocer.jpg](../assets/screenshots/2026-10-15-t6-grocer.jpg) | «Бочка «Шавлії» під полицею з травами: герой на бочці, кадр гри, К7 t060 і t072»; вердикт YELLOW | зі сторінки | `e3b127b` | [[2026-10-15-T6-Geometry-Fix-Acceptance]] § 4 |
| [2026-10-15-t6-open.jpg](../assets/screenshots/2026-10-15-t6-open.jpg) | «Бочка на козлах ятки W z25: герой висить між бочкою і фасадом; манекен кравця як висота 1,96 м» | зі сторінки | `e3b127b` | [[2026-10-15-T6-Geometry-Fix-Acceptance]] § 5 |

## Варіант Б3 для кольорів (T2-Г, 2026-10-15)

Аркуші А | Б3, підписані, кожен ≤ 300 000 B. Кадри зняті на Linux у Compatibility: тіні на них світліші й сіріші, ніж будуть на M3.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-15-albedo-b3-street.jpg](../assets/screenshots/2026-10-15-albedo-b3-street.jpg) | Колонка, лавки (серія «як є»): бруківка на світлі сіро-бежева, як палітра; тінь бузково-рожева; теракота біля крамниць у Б3 рожевіша, ніж в А | зі сторінки | `3e215c0` | [[2026-10-15-Albedo-B3-Fix]] § Кадри |
| [2026-10-15-albedo-b3-market.jpg](../assets/screenshots/2026-10-15-albedo-b3-market.jpg) | Ринок: ятки й тканини зберігають відтінок; тіньова стіна теракоти рожева, а не червона | зі сторінки | `3e215c0` | [[2026-10-15-Albedo-B3-Fix]] § Кадри |
| [2026-10-15-albedo-b3-plaster.jpg](../assets/screenshots/2026-10-15-albedo-b3-plaster.jpg) | Фасад зі штукатуркою: штукатурка на світлі — сіро-беж палітри (в А жовта); сланець у тіні сіро-бузковий замість темно-синього | зі сторінки | `3e215c0` | [[2026-10-15-Albedo-B3-Fix]] § Кадри |
| [2026-10-15-albedo-b3-vehicles.jpg](../assets/screenshots/2026-10-15-albedo-b3-vehicles.jpg) | Паровантажівка, паролегковик: брезент і борти — кольори палітри; чавун на світлі зелений, у тіні сіро-бузковий, не чорний | зі сторінки | `3e215c0` | [[2026-10-15-Albedo-B3-Fix]] § Кадри |
| [2026-10-15-albedo-b3-hero.jpg](../assets/screenshots/2026-10-15-albedo-b3-hero.jpg) | Крупний план Choko і Skea: герої майже як в А; тінь на одязі трохи світліша й бузковіша | зі сторінки | `3e215c0` | [[2026-10-15-Albedo-B3-Fix]] § Кадри |
| [2026-10-15-albedo-b3-sun.jpg](../assets/screenshots/2026-10-15-albedo-b3-sun.jpg) | Ринок, лавки — діагностика `--only-sun`: без ламп світло — палітра, тінь — рівна бузкова плівка | зі сторінки | `3e215c0` | [[2026-10-15-Albedo-B3-Fix]] § Кадри |
| [2026-10-15-albedo-b3-swatches.jpg](../assets/screenshots/2026-10-15-albedo-b3-swatches.jpg) | Не кадр гри — зразки за формулою Forward+: палітра, тінь за гайдом, А і Б3 на світлі й у тіні з ΔE; тінь Б3 темна, насичено-бузкова. Розрахунок для Mac, не знімок з M3 | зі сторінки | `3e215c0` | [[2026-10-15-Albedo-B3-Fix]] § Кадри · § Для Santos |

## Трос — кліпи UAL для лазіння, звису, стрибка, змотування (T6, 2026-10-15)

Крок 3 плану [[2026-10-15-Rope-Climb-Perch-Release]]: рекомендація T6 для T1, ще до коду 15а. У героїв 0 пальцевих кісток, тож хват читається з положення кистей.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-15-rope-anim-up-choko.jpg](../assets/screenshots/2026-10-15-rope-anim-up-choko.jpg) | «Choko, угору: A — сирий Climb_Up, Б — як зараз, В — повне тіло з IK рук, Г — верх Climb_Up і затиск ніг, Г збоку» | зі сторінки | `69b56d1` | [[2026-10-15-Rope-Climb-Animation]] § 1 |
| [2026-10-15-rope-anim-up-skea.jpg](../assets/screenshots/2026-10-15-rope-anim-up-skea.jpg) | «Skea, угору: ті самі ряди А–Г» | зі сторінки | `69b56d1` | [[2026-10-15-Rope-Climb-Animation]] § 1 |
| [2026-10-15-rope-anim-down-choko.jpg](../assets/screenshots/2026-10-15-rope-anim-down-choko.jpg) | «Choko, униз: A — сирий Climb_Down_Loop, Б — верх Climb_Down і затиск, В — ковзання, В збоку» | зі сторінки | `69b56d1` | [[2026-10-15-Rope-Climb-Animation]] § 2 |
| [2026-10-15-rope-anim-down-skea.jpg](../assets/screenshots/2026-10-15-rope-anim-down-skea.jpg) | «Skea, униз: ті самі ряди» | зі сторінки | `69b56d1` | [[2026-10-15-Rope-Climb-Animation]] § 2 |
| [2026-10-15-rope-anim-hang.jpg](../assets/screenshots/2026-10-15-rope-anim-hang.jpg) | «Звис на чотирьох типах опори: ряди а — Climb_Idle повне тіло, б — руки Climb_Idle і ноги Jump, в — руки Climb_Idle і ноги Idle (Choko), в — те саме Skea» | зі сторінки | `69b56d1` | [[2026-10-15-Rope-Climb-Animation]] § 3 |
| [2026-10-15-rope-anim-hang-grey.jpg](../assets/screenshots/2026-10-15-rope-anim-hang-grey.jpg) | «Силует у сірому: ліхтар вулиці й кронштейн, ззаду і збоку, Choko і Skea» | зі сторінки | `69b56d1` | [[2026-10-15-Rope-Climb-Animation]] § 3 |
| [2026-10-15-rope-anim-top-transition.jpg](../assets/screenshots/2026-10-15-rope-anim-top-transition.jpg) | «Нагорі: 1 — руки на мотузці під якорем, 2 — підтягнувся, права рука на плечі, 3 — звис, мотузка йде вгору, 4 — звис, мотузку підібрано» | зі сторінки | `69b56d1` | [[2026-10-15-Rope-Climb-Animation]] § 3 |
| [2026-10-15-rope-anim-exit.jpg](../assets/screenshots/2026-10-15-rope-anim-exit.jpg) | «Кандидати: GetOffWall_2m, WallRun_Jump_L, Climb_Exit, NinjaJump_Start (Choko), WallRun_Jump_L (Skea)»; обрано `WallRun_Jump_L` / `_R` | зі сторінки | `69b56d1` | [[2026-10-15-Rope-Climb-Animation]] § 4 |
| [2026-10-15-rope-anim-exit-arc.jpg](../assets/screenshots/2026-10-15-rope-anim-exit-arc.jpg) | «Розкадровка з ліхтаря збоку: звис, мах ногами, відпустив, політ» | зі сторінки | `69b56d1` | [[2026-10-15-Rope-Climb-Animation]] § 4 |
| [2026-10-15-rope-anim-mantles.jpg](../assets/screenshots/2026-10-15-rope-anim-mantles.jpg) | «ClimbUp_1m і ClimbUp_2m на Choko і Skea: вилазка на виступ, не цикл по мотузці» — відкинуто | зі сторінки | `69b56d1` | [[2026-10-15-Rope-Climb-Animation]] § 4 |
| [2026-10-15-rope-anim-reel.jpg](../assets/screenshots/2026-10-15-rope-anim-reel.jpg) | «Змотування: Interact (як зараз), руки Climb_Up на ногах Idle з мотузкою вгору (Choko, Skea), Fish_Reel з мотузкою вдалину (Choko, Skea)» | зі сторінки | `69b56d1` | [[2026-10-15-Rope-Climb-Animation]] § 5 |

## Бочка на козлах, манекен, межі кварталу; перемикач кольорів А / Б3 (T2-Д · T2-Е, 2026-10-15)

Кадри для приймання T6, обидві смуги в одному коміті. Аркуші перемикача — «вимкнено | увімкнено», підписані: справжня гра, перемикання через `GraphicsSettings.set_colours()`.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-15-t2e-trestle.jpg](../assets/screenshots/2026-10-15-t2e-trestle.jpg) | «Бочка на козлах: до (герой на ободі) і після (на підлозі)»: до — y 0,69, після — стоїть за бочкою, y 0,00 | зі сторінки | `407595d` | [[2026-10-15-Stall-Wedge-Boundary-Fix]] § 7 |
| [2026-10-15-t2e-grocer.jpg](../assets/screenshots/2026-10-15-t2e-grocer.jpg) | «Бочка «Шавлії» біля вітринної скрині: g3 до і після, g2 і g1 після»: герой на бочці біля скрині з фруктами; у g1 камера впирається в стіну (плече 0,39) | зі сторінки | `407595d` | [[2026-10-15-Stall-Wedge-Boundary-Fix]] § 7 · [[2026-10-15-T6-Wedge-Bounds-Colour-Switch-Acceptance]] § 2 |
| [2026-10-15-t2e-dressform.jpg](../assets/screenshots/2026-10-15-t2e-dressform.jpg) | «Манекен: поставлений на верх — до стоїть на 1,96, після на підлозі» (на 24-му тику біля вікна) | зі сторінки | `407595d` | [[2026-10-15-Stall-Wedge-Boundary-Fix]] § 7 |
| [2026-10-15-t2e-bounds.jpg](../assets/screenshots/2026-10-15-t2e-bounds.jpg) | «Межі: тераси й галерея з камери гри, маска змінених пікселів»: до й після різняться на 0,08–1,5 % пікселів, усе поза краєм; невидимий край у кадрі не з'являється | зі сторінки | `407595d` | [[2026-10-15-Stall-Wedge-Boundary-Fix]] § 7 · [[2026-10-15-T6-Wedge-Bounds-Colour-Switch-Acceptance]] § 4 |
| [2026-10-15-colour-switch-street.jpg](../assets/screenshots/2026-10-15-colour-switch-street.jpg) | Перемикач вимкнено / увімкнено: колонка, лавки; на аркуші Compatibility Б3 світліший (T8) | зі сторінки | `407595d` | [[2026-10-15-Colour-Switch-Fix]] § Кадри · [[2026-10-15-T8-Colour-Switch-Row-Acceptance]] (шлях у тексті) |
| [2026-10-15-colour-switch-market.jpg](../assets/screenshots/2026-10-15-colour-switch-market.jpg) | Перемикач вимкнено / увімкнено: ринок | зі сторінки | `407595d` | [[2026-10-15-Colour-Switch-Fix]] § Кадри (шлях у тексті) |
| [2026-10-15-colour-switch-plaster.jpg](../assets/screenshots/2026-10-15-colour-switch-plaster.jpg) | Перемикач вимкнено / увімкнено: фасад, штукатурка | зі сторінки | `407595d` | [[2026-10-15-Colour-Switch-Fix]] § Кадри (шлях у тексті) |
| [2026-10-15-colour-switch-vehicles.jpg](../assets/screenshots/2026-10-15-colour-switch-vehicles.jpg) | Перемикач вимкнено / увімкнено: паровантажівка, паролегковик | зі сторінки | `407595d` | [[2026-10-15-Colour-Switch-Fix]] § Кадри (шлях у тексті) |
| [2026-10-15-colour-switch-hero.jpg](../assets/screenshots/2026-10-15-colour-switch-hero.jpg) | «Перемикач: крупний план Choko і Skea, вимкнено / увімкнено — аркуш T2» | зі сторінки | `407595d` | [[2026-10-15-Colour-Switch-Fix]] § Кадри · [[2026-10-15-T6-Wedge-Bounds-Colour-Switch-Acceptance]] § 5–7 |

## Рядок COLOURS (TEST) у COMFORT (T2-З · T8, 2026-10-15)

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-15-comfort-colours-row.jpg](../assets/screenshots/2026-10-15-comfort-colours-row.jpg) | Панель COMFORT, 1280 × 720: DISPLAY угорі, GRAPHICS QUALITY з рядком AUTO, `COLOURS (TEST)` з пунктом `A — the game as it is`, заголовок `MASTER 80%` і повзунок цілком, BACK унизу. Фокус на MASTER — лише слабка підсвітка повзунка. T8 кадр приймає | зі сторінки | `b9d2480` | [[2026-10-15-Comfort-Colour-Row-Fold-Fix]] · [[2026-10-15-T8-Colour-Switch-Row-Acceptance]] (шлях у тексті) |

## Трос у місті — лазіння, спуск, звис, змотування (T2-И, 2026-10-15)

Справжній `CityWorld`, справжні клавіші, Compatibility / llvmpipe під Xvfb, 1280 × 720, кожен аркуш — дві плитки 800 × 450: камера гри | бічна камера на замороженому кадрі. Скрипт зйомки — у scratchpad сесії, не в репо. Для приймання T6 (крок 8 плану).

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-15-rope-climb-up-choko.jpg](../assets/screenshots/2026-10-15-rope-climb-up-choko.jpg) | Choko, лазіння вгору по тросу на ліхтарі 3 (Space утримано, 22-й тик лазіння): ліворуч — камера гри з рядком `ROPE · Hold Space: climb …`, праворуч — збоку; хвіст мотузки висить до бруківки | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |
| [2026-10-15-rope-climb-up-skea.jpg](../assets/screenshots/2026-10-15-rope-climb-up-skea.jpg) | Skea, лазіння вгору по тросу на ліхтарі 3 (Space утримано, 22-й тик лазіння): ліворуч — камера гри з рядком `ROPE · Hold Space: climb …`, праворуч — збоку; хвіст мотузки висить до бруківки | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |
| [2026-10-15-rope-climb-down-choko.jpg](../assets/screenshots/2026-10-15-rope-climb-down-choko.jpg) | Choko, спуск (Shift утримано, 9-й тик): ковзання, руки одна над одною | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |
| [2026-10-15-rope-climb-down-skea.jpg](../assets/screenshots/2026-10-15-rope-climb-down-skea.jpg) | Skea, спуск (Shift утримано, 9-й тик): ковзання, руки одна над одною | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |
| [2026-10-15-rope-climb-perch-lamp-choko.jpg](../assets/screenshots/2026-10-15-rope-climb-perch-lamp-choko.jpg) | Choko, звис на плечі ліхтаря 3: руки на плечі, ступні на 1,32 м під точкою якоря, рядок `ANCHOR · Grip 2.8s · Release Space, then press it to leap · Z: drop` | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |
| [2026-10-15-rope-climb-perch-lamp-skea.jpg](../assets/screenshots/2026-10-15-rope-climb-perch-lamp-skea.jpg) | Skea, звис на плечі ліхтаря 3: руки на плечі, ступні на 1,32 м під точкою якоря, рядок `ANCHOR · Grip 2.8s · Release Space, then press it to leap · Z: drop` | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |
| [2026-10-15-rope-climb-perch-bracket-choko.jpg](../assets/screenshots/2026-10-15-rope-climb-perch-bracket-choko.jpg) | Choko, звис на кронштейні 16 (західна вулиця): боком до стіни, вид збоку — від стіни | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |
| [2026-10-15-rope-climb-perch-bracket-skea.jpg](../assets/screenshots/2026-10-15-rope-climb-perch-bracket-skea.jpg) | Skea, звис на кронштейні 16 (західна вулиця): боком до стіни, вид збоку — від стіни | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |
| [2026-10-15-rope-climb-leap-choko.jpg](../assets/screenshots/2026-10-15-rope-climb-leap-choko.jpg) | Choko, стрибок зі звису (Space + A), 7-й тик польоту; малюнок — фаза `wall_kick` | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |
| [2026-10-15-rope-climb-leap-skea.jpg](../assets/screenshots/2026-10-15-rope-climb-leap-skea.jpg) | Skea, стрибок зі звису (Space + A), 7-й тик польоту; малюнок — фаза `wall_kick` | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |
| [2026-10-15-rope-climb-reel-choko.jpg](../assets/screenshots/2026-10-15-rope-climb-reel-choko.jpg) | Choko, змотування G мотузки, що лишилась після спуску, 14-й тик (`Fish_Reel`) | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |
| [2026-10-15-rope-climb-reel-skea.jpg](../assets/screenshots/2026-10-15-rope-climb-reel-skea.jpg) | Skea, змотування G мотузки, що лишилась після спуску, 14-й тик (`Fish_Reel`) | T2-И | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Climb-City-Fix]] |

## Трос у місті — повторне приймання T6: вхід у звис, голова, лазіння, змотування, повернення, постріл і стрибок (T2-М, 2026-10-15)

Зонд T6 (`accept.gd`, копія в scratchpad сесії T2-М), справжній `CityWorld` і клавіші, Compatibility / llvmpipe під Xvfb, 1280 × 720, ближні камери на замороженому кадрі; аркуші з підписом кожної плитки. Ті самі стани й якорі 3, 22, 16, що в [[2026-10-15-T6-Rope-Climb-Acceptance]].

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-15-rope-perch-entry-lamp-choko.jpg](../assets/screenshots/2026-10-15-rope-perch-entry-lamp-choko.jpg) | Choko, «до опори» на ліхтарі 3 у профіль, тики 1 / 8 / 15 / 22 / 29 і тик хвату ззаду: тіло вертикальне (до — до 72° «прапором»), на хваті гак летить назад | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-entry-lamp-skea.jpg](../assets/screenshots/2026-10-15-rope-perch-entry-lamp-skea.jpg) | Skea, «до опори» на ліхтарі 3 у профіль, тики 1 / 8 / 15 / 22 / 29 і тик хвату ззаду: тіло вертикальне (до — до 72° «прапором»), на хваті гак летить назад | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-entry-bracket-choko.jpg](../assets/screenshots/2026-10-15-rope-perch-entry-bracket-choko.jpg) | Choko, «до опори» на кронштейнах 22 і 16: 20-й тик і тик хвату ззаду, тіло вертикальне, на хваті гак зіскакує з кераміки | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-entry-bracket-skea.jpg](../assets/screenshots/2026-10-15-rope-perch-entry-bracket-skea.jpg) | Skea, «до опори» на кронштейнах 22 і 16: 20-й тик і тик хвату ззаду, тіло вертикальне, на хваті гак зіскакує з кераміки | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-hang-lamp-choko.jpg](../assets/screenshots/2026-10-15-rope-perch-hang-lamp-choko.jpg) | Choko, звис на ліхтарі 3: ззаду, кисті зблизька, спереду, профіль | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-hang-lamp-skea.jpg](../assets/screenshots/2026-10-15-rope-perch-hang-lamp-skea.jpg) | Skea, звис на ліхтарі 3: ззаду, кисті зблизька, спереду, профіль | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-hang-bracket-choko.jpg](../assets/screenshots/2026-10-15-rope-perch-hang-bracket-choko.jpg) | Choko, звис на кронштейнах 22 і 16: ззаду і кисті зблизька | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-hang-bracket-skea.jpg](../assets/screenshots/2026-10-15-rope-perch-hang-bracket-skea.jpg) | Skea, звис на кронштейнах 22 і 16: ззаду і кисті зблизька | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-head-choko.jpg](../assets/screenshots/2026-10-15-rope-perch-head-choko.jpg) | Choko, маківка й брус у профіль на якорях 3, 22, 16: голова відкинута на 15° | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-head-skea.jpg](../assets/screenshots/2026-10-15-rope-perch-head-skea.jpg) | Skea, маківка й брус у профіль на якорях 3, 22, 16: голова відкинута на 15° | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-climb-choko.jpg](../assets/screenshots/2026-10-15-rope-perch-climb-choko.jpg) | Choko, лазіння вгору (ліхтар 3): збоку на 12 / 14 / 16 / 18-му тику (кисті по черзі, стопи разом), ззаду й спереду в три чверті | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-climb-skea.jpg](../assets/screenshots/2026-10-15-rope-perch-climb-skea.jpg) | Skea, лазіння вгору (ліхтар 3): збоку на 12 / 14 / 16 / 18-му тику (кисті по черзі, стопи разом), ззаду й спереду в три чверті | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-reel-choko.jpg](../assets/screenshots/2026-10-15-rope-perch-reel-choko.jpg) | Choko, змотування G: збоку на 8 / 14 / 24-му тику і камера гри — мотузка входить між кистями | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-reel-skea.jpg](../assets/screenshots/2026-10-15-rope-perch-reel-skea.jpg) | Skea, змотування G: збоку на 8 / 14 / 24-му тику і камера гри — мотузка входить між кистями | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-shot-choko.jpg](../assets/screenshots/2026-10-15-rope-perch-shot-choko.jpg) | Choko, постріл зі звису E: збоку на 4 / 8 / 11-му тику (кидає кисть з боку цілі, мотузка з неї) і ззаду | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-shot-skea.jpg](../assets/screenshots/2026-10-15-rope-perch-shot-skea.jpg) | Skea, постріл зі звису E: збоку на 4 / 8 / 11-му тику (кидає кисть з боку цілі, мотузка з неї) і ззаду | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-leap-choko.jpg](../assets/screenshots/2026-10-15-rope-perch-leap-choko.jpg) | Choko, стрибок зі звису (стік A), широкий план на 0 / 3 / 6 / 10-му тику | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |
| [2026-10-15-rope-perch-leap-skea.jpg](../assets/screenshots/2026-10-15-rope-perch-leap-skea.jpg) | Skea, стрибок зі звису (стік A), широкий план на 0 / 3 / 6 / 10-му тику | T2-М | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Entry-Fix]] |

## Трос у місті — поверхня моделі повз брус, ковпак і підкіс (T2-Р, 2026-10-15)

Зонд T6 (`accept.gd`, частина `frames3`, копія в scratchpad сесії T2-Р), справжній `CityWorld` і клавіші, Compatibility / llvmpipe під Xvfb, 1280 × 720, ті самі ракурси, що в [[2026-10-15-T6-Rope-Climb-Acceptance]] (N1 і голова). Аркуш: ліворуч — кадр T6 до правок, праворуч — після; плитка 640 × 360 з підписом.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-15-rope-mesh-head-choko.jpg](../assets/screenshots/2026-10-15-rope-mesh-head-choko.jpg) | Choko, звис: голова спереду на ліхтарі 3 і в профіль на ліхтарі 3, кронштейнах 16, 6 (спереду маківку ховає брус, у профіль — частково ковпак): до — чуб у брусі на 0,014–0,019 м, після — голова 25°, зазор ≥ 0,017 м | T2-Р | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Mesh-Clearance-Fix]] |
| [2026-10-15-rope-mesh-head-skea.jpg](../assets/screenshots/2026-10-15-rope-mesh-head-skea.jpg) | Skea, ті самі ракурси: до — волосся в брусі на 0,037–0,043 м, після — звис на 0,19 і голова 25°, зазор ≥ 0,015 м | T2-Р | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Mesh-Clearance-Fix]] |
| [2026-10-15-rope-mesh-pull-choko.jpg](../assets/screenshots/2026-10-15-rope-mesh-pull-choko.jpg) | Choko, «до опори»: кронштейн 6 (тик 23), 22 з гойдання (тик 23), 9 (тик 18): до — голова в ковпаку, після — під ковпаком | T2-Р | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Mesh-Clearance-Fix]] |
| [2026-10-15-rope-mesh-pull-skea.jpg](../assets/screenshots/2026-10-15-rope-mesh-pull-skea.jpg) | Skea, ті самі тики | T2-Р | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Mesh-Clearance-Fix]] |
| [2026-10-15-rope-mesh-strut-choko.jpg](../assets/screenshots/2026-10-15-rope-mesh-strut-choko.jpg) | Choko, звис: підкіс 6 знизу, 16 ззаду, 9 знизу; дальня кисть 0,66 → 0,56 | T2-Р | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Mesh-Clearance-Fix]] |
| [2026-10-15-rope-mesh-strut-skea.jpg](../assets/screenshots/2026-10-15-rope-mesh-strut-skea.jpg) | Skea, ті самі ракурси: до — рукав на верху підкосу (до 0,018 м, на кадрі не видно), після — 0 вершин | T2-Р | дерево від `93ba633`, не закомічено | [[2026-10-15-Rope-Perch-Mesh-Clearance-Fix]] |

## Трос у місті — третє приймання T6 після T2-Р і T2-С (2026-10-16)

Зонд T6 (`accept.gd`, частина `v3frames`, scratchpad сесії T6), справжній `CityWorld` і клавіші, Compatibility / llvmpipe під Xvfb, 1280 × 720, ближні камери на замороженому кадрі. Фінальний код 15а (джерела = батарея T1 488 / 0). Аркуші з підписом кожної плитки англійською.

| кадр | що на ньому | підпис | коміт | обговорено |
|---|---|---|---|---|
| [2026-10-16-rope-perch-head.jpg](../assets/screenshots/2026-10-16-rope-perch-head.jpg) | Choko і Skea на звисі спереду, ліхтар 3 і кронштейн 6: голова відкинута на 25°, обличчя під брусом, вершин голови в брусі й ковпаку 0 | T6 | у гілці | [[2026-10-15-T6-Rope-Climb-Acceptance]] |
| [2026-10-16-rope-pull-cap.jpg](../assets/screenshots/2026-10-16-rope-pull-cap.jpg) | «До опори» на кронштейні 6, обидва герої: спереду на 20-му і 26-му тику, збоку на 29-му. Голова проходить під ковпаком, ковпак її не ховає | T6 | у гілці | [[2026-10-15-T6-Rope-Climb-Acceptance]] |
| [2026-10-16-rope-sleeve-cap-strut.jpg](../assets/screenshots/2026-10-16-rope-sleeve-cap-strut.jpg) | Звис: підкіс 6 і 16 знизу (Skea, зазор рукава 0,023 і 0,034 м), підкіс 6 у Choko (0,125 м); ковпак 6 у Skea — ближнє зап'ястя ховається в ковпаку (N4, 96–99 вершин на 0,033 м) | T6 | у гілці | [[2026-10-15-T6-Rope-Climb-Acceptance]] |
| [2026-10-16-rope-leap-along.jpg](../assets/screenshots/2026-10-16-rope-leap-along.jpg) | Skea, стрибок зі звису: кронштейн 16 до кріплення, ззаду, тики 0–3 (плече в брусі до 0,063 м, тіло затуляє брус); ліхтар 3 до вільного кінця з торця, тики 1–3, і без стіка, тик 2 — руки йдуть угору-вперед повз брус | T6 | у гілці | [[2026-10-15-T6-Rope-Climb-Acceptance]] |

## Related
- [[index]] · [[Style-Guide]] · [[VFX-Direction]] · [[Glossary]] · [[2026-10-03-Wave-2-Kickoff]] · [[Textures-Registry]]
- [[2026-10-15-Rope-Climb-City-Fix]] · [[2026-10-15-Rope-Perch-Entry-Fix]] · [[2026-10-15-Rope-Perch-Mesh-Clearance-Fix]]
- [[2026-10-15-T6-Rope-Climb-Acceptance]]
