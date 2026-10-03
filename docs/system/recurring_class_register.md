# Реєстр рецидивних класів помилок

Веде T4 Феміда. Один рядок = один клас із лічильником. Клас, що повторився вдруге, народжує
механізм (гейт, хук, deny) у тому ж заході.

| № | клас | лічильник | механізм | статус |
|---|---|---|---|---|
| 1 | Назва методу в GDScript збігається з віртуальним методом `Object` (`_set`, `_get`) → парс-еррор у залежних скриптах | 2 (2026-10-02: RigAnimator `_set`, Sfx `_get`) | `make check` ловить при парсі; правило в `godot-fighting-dev`: приватні методи не починати з імен віртуалів `_get/_set/_init/_ready/_process/_notification` | ВІДКРИТО (гейт є, лінта-правила немає) |
| 2 | `godot --check-only` не бачить autoload-синглтонів → хибні «Identifier not found» | 1 | `gd_check_all.sh` фільтрує імена з `[autoload]`; авторитетна перевірка — smoke-тест | ЗАКРИТО |
| 3 | Запуск гри зі свіжого клону без імпорту: `game/.godot/global_script_class_cache.cfg` відсутній → класи `class_name` невідомі, автолоади падають | 1 (2026-10-02, Santos на Mac, `make run`) | `make run`/`make editor` викликають `make import`, якщо кешу немає; гайд у [[Build-and-Run]] | ЗАКРИТО |

## Related
- [[constitution]] · [[Testing]] · [[Build-and-Run]]
