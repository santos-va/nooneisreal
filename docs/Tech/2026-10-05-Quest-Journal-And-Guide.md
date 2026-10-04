# Журнал із вибором цілі та напрямок подорожі

2026-10-05 · T8 Гермес · версія 0.4.1 · реалізація [[2026-10-05-District-Journey-Continuity]].

Прийняте доручення тепер можна вибрати в журналі паузи або вимкнути його орієнтир. Верхня бурштинова картка показує назву місця, відстань та напрямок відносно камери; стан прогресу лишається праворуч. Це напрямок на фактичну ціль, не маршрут обходу стін чи автоматична навігація.

## Поведінка та керування

Раніше журнал був лише текстом. `CityHud` тепер створює кнопки для accepted active/ready доручень; `TRACK` змінює вибір, `✓ TRACKING` позначає чинний, `TURN OFF QUEST GUIDE` зберігає вимкнення через `CityProgress.track_quest("")`. Доступні й завершені доручення лишаються текстом. Кнопки повторно використовуються за quest id, тому сигнал `changed` не знищує сфокусовану кнопку посеред натискання.

Клавіатура: стрілки або Tab переходять між елементами, Enter вибирає, Esc закриває паузу. Геймпад: D-pad, A, B. Журнал має прокручування та `follow_focus`; коли рядків більше за видиму область, перехід фокуса прокручує вибраний рядок у видиму частину. Текстові записи також доступні стрілками. Початковий фокус — `RESUME`; після закриття застосовується наявний захист `InputRouter` від перенесення натискання у рух/бій.

`CityQuestGuide.gd` із власним UID обчислює підпис у горизонтальному базисі камери: Ahead / Left / Right / Behind, відстань у метрах, Higher / Lower для перепаду висоти. Ціль позаду не проєктується як точка попереду. Напрямок і дальність вимірюються від героя. Картка має окремий колір і префікс `QUEST`; гарпунна підказка обходить її прямокутник. Пауза, відкритий діалог, явне вимкнення чи відсутність чинної цілі приховують картку. Оновлення напрямку — кожні 0,1 с, зміна прогресу оновлює його одразу.

У паузі `Continue from: … · safe checkpoint` називає місце наступного входу, а не обіцяє точні поточні координати. `Return point not saved` окремо показує помилку `CityJourney.save_ok`; успішне збереження доручень не приховує цю помилку. Модель місць описана в [[2026-10-05-City-Journey]], модель вибору — у [[2026-10-05-Quest-Tracking]].

Версія береться з єдиного `application/config/version` у `project.godot`: 0.4.1. Наявний `BuildInfo` зберігає реальний SHA для експортованих збірок; незастампована робоча копія чесно показує `development checkout`. Іконку не змінено згідно з рішенням Santos чекати саме новий PNG.

## Перевірка

Ізольований Godot 4.7; production HUD і реальна модель `CityProgress`, справжні viewport keyboard/controller events:

| Перевірка | Результат |
|---|---|
| `tools/ui/quest_journal_check.gd` | 32/0: вибір, вимкнення, збереження фокуса й ідентичності кнопки, B-close, незалежна помилка checkpoint, front/behind/left/right/height/orbit, порожня ціль |
| `tools/ui/district_ui_check.gd` | 33/0: чинні меню, журнал і читабельність |
| `tools/world/city_onboarding_check.gd` | 56/0: чинне навчання та pause flow |
| `tools/ui/quest_journal_capture.gd` | `QUEST_JOURNAL_CAPTURE_COMPLETE views=6`, rc 0; native OpenGL compatibility / Xvfb :97 / llvmpipe |

Журнали локального приймання: `/tmp/nir-continuity-ui/{quest-ui,existing-ui,onboarding,capture}.log`. Native screenshots зняті з реального `CityWorld`, реальних цілей та HUD у 1280×720 і 960×540. Це перевірка Linux software rendering, не вимірювання продуктивності macOS/M3. Для напрямків fixture повертає справжню камеру до цілі та від неї; задній ракурс може дивитися на сусідню стіну. Ізольована копія не пише progression/NPC/journey saves під час захоплення. Підсумковий спільний suite й незалежні edge cases належать [[2026-10-05-District-Journey-Review]].

## Native докази

- [Ціль попереду, 1280×720](../assets/screenshots/2026-10-05-district-journey/quest_front_720.png)
- [Ціль позаду, 1280×720](../assets/screenshots/2026-10-05-district-journey/quest_behind_720.png)
- [Ціль на даху, 1280×720](../assets/screenshots/2026-10-05-district-journey/quest_roof_720.png)
- [Вибране доручення у журналі, 1280×720](../assets/screenshots/2026-10-05-district-journey/quest_journal_720.png)
- [Журнал і checkpoint, 960×540](../assets/screenshots/2026-10-05-district-journey/quest_journal_540.png)
- [Напрямок на дах, 960×540](../assets/screenshots/2026-10-05-district-journey/quest_roof_540.png)

## Related

- [[2026-10-05-District-Journey-Continuity]] · [[2026-10-05-District-Journey-Session]] · [[2026-10-05-Quest-Tracking]] · [[2026-10-05-City-Journey]] · [[2026-10-05-District-Journey-Review]] · [[2026-10-05-District-Delivery]] · [[state]]
