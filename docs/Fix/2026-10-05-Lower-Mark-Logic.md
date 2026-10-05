# Нижня позначка — стан і взаємодія

Дата: 2026-10-05 · T2 Гефест · план [[2026-10-05-Lower-Mark-Expansion]].

Окремий `CityLowerStory` продовжує завершений «Слід під годинником»: прийняти пропозицію Лади, спрямувати реальний оглядовий ліхтар на плиту, зняти відбиток біля освітленої схеми та повернутися в майстерню. Текст — [[2026-10-05-Lower-Mark]], геометрія — [[2026-10-05-Lower-Gallery]]. Це архів на верхній терасі; нижні сходи поки лише на схемі.

## Реалізація

- Новий per-hero save `city_lower_story_v1.json` містить accepted/lamp_aligned/copied/completed/guide_selected. Старі CityStory JSON, скрипт і schema не змінені. Завершений старий selected flag не очищається новим HUD, тому його файл лишається побайтово незмінним.
- Admission вимагає того самого героя та збереженого completed попередника. Missing/corrupt/incomplete/disabled/failed predecessor призупиняє orphan successor без переписування його байтів; історичні факти приховані з поточного журналу/світу. Після відновлення попередника вони повертаються.
- Typed content і save validators відхиляють неповний/невідомий payload атомарно. Копія є історичним фактом: copied=true та lamp_aligned=false допустимі. Пошкоджений новий файл не перезаписується; поточний сеанс може завершити справу в пам’яті, але NPC memory не створюється без save_enabled/save_ok. Видима дошка відображає ефективне завершення поточного сеансу, а не окремий доказ успішного запису диска.
- Один World arbiter перевіряє NPC priority, рух/землю/UI, дальність, висоту й mask1 LOS. Перше копіювання додатково читає `plate_is_lit()`: справжні напрямок, кут, дальність, energy/cull і відсутність перешкоди. Повторний огляд уже отриманої копії не вимагає світла.
- Lada callbacks перевіряють справжню offer page, героя, фізичний контакт і єдиного UI owner. Новий NPC bond є once-only; при призупиненні «Наші знайомства» позначають стару пам’ять як збережену історію та пояснюють поточний стан.
- Один active episode живить заголовок, guide і tick. Для lower episode збережений manual/OFF має пріоритет над orphan guide flag; явний TRACK STORY викликає вузький `CityProgress.track_automatically()` без зміни schema/економіки. Перший сюжет зберіг попередню поведінку.

## Перевірка в роботі

Official Godot 4.7, окремі XDG каталоги. Новий `city_lower_story_check.gd`: **86 checks / 0 failures**, rc0, чистий raw `/workspace/nooneisreal-evidence/lower-mark/logic/focused-second.log`. Це production commands/physical handler fixture з переставлянням героя до контрольних точок; не запис повної ходьби. Перевірено strict prerequisite matrix, orphan byte preservation/repair, atomic malformed input, copy+away roundtrip, actual wrong-angle/blocked light rejection, near Lada accept/return, foreign UI, stale offer, один guide та незмінні старі байти. Початковий запуск fixture мав eager compile залежності Director до появи autoload; test-local typed reference прибрано, production для цього не змінювався. Початковий raw збережений.

Додано permanent runner cases `city-lower-story` і `city-lower-gallery`. Legacy raw особисто прочитані: story **63/0**, quest-journal **32/0**, district-life **25/0**, rc0 і чиста консоль. T2 також особисто прочитав geometry **78/0**, old maintenance **74/0**, old geometry **1750/0** та незалежні T4 save-pairs **34/0**, actual-input/world boundaries **20/0**, rc0 clean. Останній перевіряє справжню held key через modal, repair після scene reload, фізичне перекриття променя та збережену NPC історію. Фінальні ROOT raw особисто прочитані T2: `make check` smoke **164 checks / 19847 frames**, `make gates` **116 GDS/0**, **175 assets**, обидва rc0; `make check-playable` **85 сценаріїв / 0 failures**, rc0. Нові cases у повній батареї повторно дали **86/0** і **78/0**. Власний скан 85 case logs не знайшов warnings, script errors чи leak markers; очікувані негативні assertions прийняті strict runner. Raw: `lower-mark/validation/review-{check,gates,playable}.log/.rc`.

## Native-приймання

Фінальні native **21 PNG/0 failures** плюс окремий orphan **1 PNG/0**, rc0, у `lower-mark/native-final/` та `lower-mark/orphan-native/`. T2 особисто прочитав raw і переглянув фінальну освітлену плиту, прокручений висновок журналу на 540p та orphan повідомлення без копії на стіні. Однак orphan fixture напряму викликає lower:hint, якого немає в поточному NPC меню за відсутнього попередника: це handler diagnostic, не доказ доступного меню. Окремий фінальний `orphan-journal/orphan_journal_540.png` пройшов через реальні Escape/Shift-Tab/Up: **1 кадр/0**, rc0. T2 особисто переглянув повністю читабельне повідомлення; trace підтверджує copied/delivered/plate_lit=false та однаковий SHA збереженого successor до/після. Це доступний journal шлях, а початковий `orphan-native` лишається тільки handler diagnostic. До виправлення напрямків знаків була відхилена перша серія, збережена в `native-rejected-arrows/`: fork-like стрілки суперечили тексту. Остаточні стрілки ведуть двір → сходи → вежа. Однакова камера та матеріали пари away/toward показують реальне світло. Fixture проходить production handlers, переміщує героя між review stations; повну пішу подорож доводить окрема геометрична перевірка, не ці кадри. Є лише відомий VSync warning драйвера llvmpipe; shader/script errors немає. Linux native не підтверджує M3 FPS.

Фінальна source база після вузького geometry glyph delta: **793 files**, digest `0beea2abbfde9b603487a1c8aa3084f0337d3e842ab0d772d701789e09b6b32c`. Повний runner перевірив саме цю базу, manifests before/after побайтово однакові. Попередній focused receipt стосується незмінної integration смуги до цієї visual-only правки.

Другий локальний епізод та його інтеграцію завершено в межах approved плану. Повна кампанія, фізичний нижній маршрут і Mac-перевірка не заявляються.

## Related

- [[2026-10-05-Lower-Mark-Expansion]] · [[2026-10-05-Lower-Mark]] · [[2026-10-05-Lower-Gallery]] · [[state]]
