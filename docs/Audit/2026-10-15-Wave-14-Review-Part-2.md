# Аудит хвилі 14, частина 2 — бочки, манекен, межі кварталу, родини sentinel, перемикач кольорів А / Б3

**Дата:** 2026-10-15 · **Роль:** T4 Феміда (вердикт подано текстом; інструменти лише для читання) ·
**Предмет:** `git log --oneline d912d76..b9d2480` → 6 комітів англійською (`1707caa`, `69b56d1` — документи тросу,
по суті не аудитовано; `407595d`, `bd4ace2`, `69cffac`, `b9d2480`). Дерево detached `b9d2480`. Логи, мутанти, скрипти — scratchpad
`t4-w14b/`. Кейси ганялись тим самим командним рядком, що й у `playable_check.sh`. Вердикт кожного логу виносив `scripts/judge.py`
за правилами батареї (sentinel як цілий рядок, сторонні `ERROR`, `SCRIPT ERROR`). Повну `make check-playable` не запускала.
**Вердикт: YELLOW, RED немає.**

| # | пункт | вердикт | доказ |
|---|---|---|---|
| 0 | базові команди | GREEN | `make check` rc 0 (GDS 144/0, канарка «FAIL як треба», smoke 165/19847). `make gates` rc 0 (549 стор., 9155 лінків, 0 зламаних; реєстр 187/187). `git diff --stat … -- game/assets docs/Art/Textures-Registry.md` → порожньо |
| 1 | геометрія T2-Д | GREEN | див. § 1 |
| 2 | YELLOW 1 / клас 17 | GREEN | мутант T4 (стіна вздовж −x прилавка «Шавлії») при 0,53 / 0,55 / 0,60 м → rc 1, `red=vgrow`. `wedge_more`, `wedge_deeper` → `red=vgrow` |
| 3 | YELLOW 2 / кандидат 18 | YELLOW | для `city-tidy` механізм працює; клас повторився в `city-bounds` і `city-perch` (§ 3) |
| 4 | YELLOW 5 | GREEN | зонд продукту без override: `steam_bus` → `ERROR: CITY_PROPS: … nothing placed`, `null`, 0 вузлів і 0 тіл; `steam_car_tarp` → свій GLB, 4 тіла. `glb_standin`, `glb_silent`, `glb_both`, `glb_swap` → `red=m0` |
| 5 | перемикач кольорів | GREEN | див. § 5 |
| 6 | батарея | GREEN | розбір `cases` обох версій: 377 → 413 (негативи 262 → 294); видалено 0; додано 36; змінено 67, у кожного новий sentinel = старий + суфікс (` red=none` / ` red=…родина…`); логіка раннера — лише 4 нові префікси асертів |
| 7 | документи | YELLOW | `## Related` є в усіх 9 нових сторінках. `06-UI-UX.md:129–130, :147–149` описують `407595d`. Журналу зустрічі за 2026-10-15 немає (лінків з `docs/Meetings` на 9 документів — 0) |
| 8 | рецидиви | YELLOW | клас 17 → ЗАКРИТО; клас 18 → 2 (ВІДКРИТО); клас 15 — 15 позитивних логів: WARNING 0, ERROR 0, leaked 0 |

## 1. Геометрія T2-Д (`407595d`)
- **Бочка на козлах (RED T6 закрито).**
  - `city-rim-exit` → `checks=8 failures=0`.
  - Негативи `old` / `wall` / `near` → rc 1, failures 6 / 6 / 2. Причина: «S:rim>rim, A:rim>rim, D:rim>rim».
  - Лог `city-tidy`: бік −x `TrestleBarrel` — `open 9/9, wedge 0`. Бік −z закріплено виміряним: 1 точка, 0,520 / 0,061.
- **Бочка «Шавлії».** `CityInteriors.gd`: локальні (2,65; 0; 3) → (2,65; 0; 1,45). `BeerBarrel (-23.95, 0.90, 13.45)`: 4 боки, wedge 0.
- **Манекен.**
  - `city-perch` → 19/0.
  - Негативи: `flat` — P1 ×2, P2, P3 ×6; `cone` — P1 ×2, P2, P3 ×2; `edge` — P2, P3 ×2.
  - Обід столу: wedge 2/9, 0,289 під верхом (було 0,281; +8 мм у межах старого допуску 0,02). T6 прийняла «A, D → підлога».
- **Межі.**
  - Шар 64 (`project.godot` `layer_7="district_bound"`, `CityLayout.gd:120`). Маска 0, верх 28 (`:123`). `|=` лише в `CityFighter.gd:36`.
  - `city-bounds` → 75/0. `TowerDomeSupport 21.90 → need 26.50 ≤ 28`. B2: 1696 кидків ×4, skipped 0, крізь 0.
  - Негативи з правильною причиною: `gap` — B1 ×2, B2 North, B5 ×4 (північ); `low` — B1 ×4, B2 ×4, B5 ×9; `world` — B1 ×4, B3 ×4,
    B4 ×4; `mesh` — B1; `hero` — B2 ×4, B3, B5 ×18.
- **Камера, трос і мешканці не зачеплені.**
  - Усі `PhysicsRayQueryParameters3D.create` у `game/scripts` мають маску 1, 1 | 8 | 4 або 8 | 1; камера — `arm.collision_mask = 1`.
  - Мешканці не фізичні тіла: `grep -rln "extends CharacterBody3D" game/scripts` → лише `Fighter.gd`.
  - Повні логи `rope-choice-choko-1`, `rope-choice-skea-1`, `auto-hook` проти голови `3e215c0` різняться лише рядком `frames=`
    (годинник раннера). `city-camera` (440/0) і `parkour-moves` (68/0) — 0 рядків.
  - `anchor-coverage`: `real` 2658/2981 → 2663/2986, як пояснено в журналі (нічия на ребрі `EastRamp`).
- **Відхилення `CityParkourMotor.gd:455–456` обґрунтоване.**
  - План (варіант «а») про мотор не каже нічого.
  - Шар край бачить лише через маску; негатив `world` (край на шарі 1, тобто у видимості мотора) → B4 ×4 червоний.
  - `_clear` (`:531–541`) зберігає повну маску, тож перелізти крізь край не можна.

## 3. Клас 18: родини в sentinel
- **`city-tidy`.**
  - `red=` пишеться лише в `_check` з тега червоної мітки (`city_tidy_check.gd:503`, єдиний запис у `red`), не з імені мутації.
  - Мутант `STREET_SEEN_FLOOR` 2,0 за правилами батареї: `machine_seen_hook` FAIL (`red=mc3`), `machine_seen_float` FAIL, `machine_seen_low`
    FAIL, `machine_seen_street` PASS, позитив PASS → батарея червона.
  - Мутант 3,85: `machine_seen_low` FAIL, тобто ослаблення більше ніж на 0,1 м видно.
- **Повтор класу в тому ж коміті `407595d`.** Негативи `city-bounds`, `city-perch`, `city-rim-exit` мають sentinel `failures=[1-9]` без родини.
  Мутанти T4 за правилами батареї — кожен кейс підбатареї PASS:
  - B2 сканує лише до 6 м — 6/6;
  - B5 лише західні прогони — 6/6;
  - P2 вимкнено — 4/4;
  - P3 дозволяє 120 тиків на манекені й не дивиться на висоту — 4/4.
  
  Ослаблення цих гардів батарея не бачить. Окремо: P4 і `mc7s3` не мають власного негатива.

## 5. Перемикач кольорів (`407595d` + `b9d2480`)
- **Uniform.** `[shader_globals] colour_b3` bool false.
- **Гілка А.** Скрипт `branch_a.py` виймає else-гілку і порівнює з `git show d912d76`: для всіх 5 шейдерів `A==old: True`.
  Інших шейдерів із `light()` немає.
- **Збереження й невідоме значення.** Немає ключа → A. Невідоме → A і `ERR_INVALID_DATA`, файл не перезаписується (`GraphicsSettings.gd`).
  `colour-switch` 146/0; 9 негативів, кожен червоніє у своїй родині.
- **Рядок COMFORT.** `comfort-ui` PASS. 5 нових негативів у своїх родинах: `master_slider`, `master_focus`, `master_title`, `open_top`.
  Старі `footer`, `focus`, `bounds` теж PASS.
- **Кільце фокусу в 3 фікстурах — не послаблено.**
  - `blood_content_check`: літерал кільця +1, `ring.has(null) → false`.
  - `display_auto_check`: +1 ↑, та сама перевірка DISPLAY.
  - `graphics_ui_check`: +1 перевірка.
  - Усі три PASS (74/0, 187/0, 17/0).
- **«Вимкнено = 0 px».** `albedo_ab_capture.sh --switch --ref-shaders=<A = git show d912d76>`, станції `market` і `plaster`: rc 0, `errors=0`.
  Незалежний `pxdiff.py`: OFF = refA 0 px, ON = refB3 0 px, OFF2 = OFF 0 px, ON ≠ OFF 2 073 600 / 1 825 198 px (= таблиця T2).
  Між процесами мій OFF дорівнює кадру A еталона T2 на `54208e1` (0 px).
  Відтворено 2 з 8 станцій, обидві без героя.

## Пропозиції
1. **T2 через T1 (клас 18).**
   - `red=<b1…b5>` і `red=<p1…p4>` у `city_bounds_check` і `city_perch_check`; sentinel 8 негативів вимагають свою родину.
   - Негативи для P4 і `mc7s3`.
   - Правило в раннері `playable_check.sh`: негатив без `red=` поза замороженим списком 164 наявних → `PLAYABLE REFUSED`, rc 2.
     Список може лише скорочуватись. Канарка: вигаданий кейс без `red=` → rc 2.
2. **T8.** `06-UI-UX` § COLOURS (TEST): пункт `A — the game as it is`, без підпису, «Відомий дефект» закрито `b9d2480`, рядки
   `ComfortPanel.gd:30–31, 106–107` (крок 5 ТЗ T8). Стан «помилка збереження» ховає MASTER (журнал T2-З; T4 не відтворювала).
3. **T1.** Журнал зустрічі за 2026-10-15 з лінками на документи обох частин хвилі.
4. **T2, необов'язково.** `push_error` продуктового `_refuse_kind` постійним гардом не захищено (`KindProbe` перекриває без `super`).


## Що зробив T1 (2026-10-15)
- П. 1 (клас 18 у `city-bounds` і `city-perch`, негативи P4 і `mc7s3`, правило раннера) і п. 4 (`push_error` у `_refuse_kind`
  під гардом) — окремий раунд T2.
- П. 2 — T8 оновив `06-UI-UX` § COLOURS (TEST) під `b9d2480` і дописав своє приймання.
- П. 3 — журнал зустрічі на закритті хвилі.
- Рядки 17 і 18 реєстру внесено текстом T4.

## Related
- [[2026-10-15-Wave-14-Review]] · [[2026-10-15-Stall-Wedge-Boundary-Fix]] · [[2026-10-15-Tidy-Sentinel-Families-Fix]]
- [[2026-10-15-Colour-Switch-Fix]] · [[2026-10-15-Comfort-Colour-Row-Fold-Fix]] · [[2026-10-15-Albedo-B3-Fix]]
- [[2026-10-15-T6-Wedge-Bounds-Colour-Switch-Acceptance]] · [[2026-10-15-T8-Colour-Switch-Row-Acceptance]] · [[2026-10-15-T6-Geometry-Fix-Acceptance]]
- [[2026-10-14-T6-Acceptance-Crane-Albedo-AB]] · [[06-UI-UX]] · [[recurring_class_register]] · [[state]]
