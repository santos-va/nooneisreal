# Тестування без GPU

Хмарний агент не має GPU, тому все, що вирішує «готово», має працювати headless.

| рівень | команда | що ловить |
|---|---|---|
| Парс | `godot --headless --path game --check-only --script res://…` (гейт `gd_check_all.sh`) | синтаксис, типи, сигнатури; фільтр autoload-ідентифікаторів |
| Імпорт | `godot --headless --path game --import` | биті ресурси, `.import` |
| Smoke бою | `godot --headless --path game -- --smoke` (`scripts/core/SmokeTest.gd`) | 11 перевірок: арена, старт раунду, підхід, удари → HP/метр, лаунчер → регдол, вставання, гарпун attach/release, приземлення, ульт → KO, раунд 2 |
| Рендер | `xvfb-run godot --path game --rendering-driver opengl3 --rendering-method gl_compatibility -- --screenshot=DIR` | компіляція шейдерів у Compatibility, PNG-кадри |
| Докі | `make gates` | wikilinks, реєстр, парність ролей |

Smoke-тест керує P1 через `InputRouter.v_*` — той самий шлях, що в CPU і гравця. Додаючи механіку,
додай стадію в `SmokeTest._physics_process`.

## Далі

gdUnit4 для юніт-тестів `MoveData`/`InputRouter`; CI у `.github/workflows/ci.yml` (Godot з GitHub Releases).

## Related
- [[Build-and-Run]] · [[Architecture]] · [[recurring_class_register]]
