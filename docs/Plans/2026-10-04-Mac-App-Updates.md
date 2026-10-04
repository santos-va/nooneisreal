# Застосунок Mac і оновлення після мерджу

Дата: 2026-10-04 · роль: T1 · статус: approved прямим запитом Santos.

## Аудит і погляди

Перевірено: main e27b746 уже містить PR172; export_presets.cfg відсутній,
наявний ci.yml виконує перевірки, але не пакує застосунок. Поточне середовище Linux,
доступ до локального Mac не встановлено. Santos підтвердив MacBook Air M3 та Applications.
Higgsfield: баланс4568.75, оцінка одного зображення0.25; генерація прямо дозволена.

Варіанти: ручний експорт; локальний checkout із редактором; standalone app із CI release
та локальним updater. Обрано третій: гравцеві потрібен звичайний запуск без редактора.
Погляди: гравець отримує один значок; офлайн-гравець зберігає останню збірку;
активна сесія не переривається оновленням; автор бачить походження збірки через commit;
Mac без dev-інструментів потребує системного installer; збереження NPC живуть поза app.

## Кроки

1. T8: game/export_presets.cfg, tools/distribution/, workflow main export/update.
   Ризики: несумісний runtime, пошкоджений download, заміна запущеної гри.
   Перевірка: packaging tests, shell syntax, справжній export доступним runtime;
   make check та make gates. Mac launch позначати неперевіреним без Mac.
2. T6: референс чинного Choko, одна Higgsfield іконка, app_icon.png і реєстр.
   Ризик: інший персонаж/неправильний погляд. Перевірка: огляд картинки й asset gate.
3. T4: незалежний огляд updater, workflow, збережень і доказів.
   Перевірка: adversarial packaging tests, make gates.
4. T1: передача конкретного installer; не називати cloud artifact установленим на Mac.
   Публікація збірок дозволена поточним запитом; main мерджить Santos.

## Стан передачі

Код installer/update/export і незалежний аудит виконані. Реальну фінальну збірку
пакуємо з committed SHA. Ручний перший запуск на Mac, native CI після merge і
отримання PNG для нового значка лишаються відкритими; це не стан installed.

## Related

- [[state]] · [[Build-and-Run]] · [[Export-Platforms]] · [[constitution]] · [[2026-10-04-Mac-App-Session]] · [[2026-10-04-Mac-App-Updates-Review]] · [[2026-10-04-Choko-App-Icon]]
