# Перевірка гри

Headless-тести перевіряють логіку й життєвий цикл. Пікселі, звук, комфорт керування
та продуктивність потребують окремих перевірок із рендерером і на цільовому пристрої.
Використовуйте Godot **4.7-stable** через `GODOT_BIN`; запускайте його послідовно на одному checkout.

| рівень | команда | що перевіряє |
|---|---|---|
| Імпорт, парсинг, smoke | `make check` | ресурси, GDScript, бойова симуляція; потрібні rc=0, `[smoke] ALL OK` та відсутність runtime ERROR |
| Повна регресія | `make check-playable` | включає `make check`; керування, комбінації, камера, мотузки, матч, UI, геометрія/рух/навчання міста та негативні контролі |
| Документація й контракти | `make gates` | wikilinks, реєстр ассетів, парність ролей, якорі state, R8 у планах і парсинг GDScript |
| Міські матеріали | native-команда нижче | реальні пікселі: масштаб матеріалу, вплив ambient, згасання далеких деталей і палітра |
| Кадри міста | native-команда нижче | геометрія та production-камера; PNG і metadata для ручного огляду |

Строгий runner — `tools/gates/playable_check.sh`. Зберігайте raw-журнали, наприклад:

```bash
PLAYABLE_LOG_DIR=/tmp/nooneisreal-regression make check-playable
make gates
```

Негативний сценарій може навмисно завершитися ненульовим кодом: runner перевіряє
очікуваний тип збою. Сам rc=0 без completion-маркера не означає успіх. Кількість
сценаріїв беріть із журналу поточного запуску, а не зі старої таблиці. CI вже виконує
`make check-playable` у Godot job; конфігурація — `.github/workflows/ci.yml`.

## Native-перевірка

Після імпорту, у терміналі з доступним віконним дисплеєм:

```bash
"$GODOT_BIN" --path game --audio-driver Dummy --rendering-method gl_compatibility --fixed-fps 60 --script ../tools/world/city_style_check.gd
"$GODOT_BIN" --path game --audio-driver Dummy --rendering-method gl_compatibility --fixed-fps 60 --script ../tools/world/city_capture.gd -- --output=/tmp/nooneisreal-city-captures
```

На Linux без апаратного GPU потрібен робочий X-дисплей і Mesa llvmpipe (наприклад,
`DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1` у підготовленому середовищі). Це справжній
програмний рендер; він не вимірює FPS на Mac. `city_style_check.gd` навмисно відмовляє
в headless, де немає потрібних пікселів. Кадри оглядайте на пропущені поверхні,
перекриття маршрутів, читабельність героя й відповідність чинним арт-референсам.

## Межі доказів

Позитивний технічний прогін не підтверджує остаточні анімації, баланс, слухове
приймання, фізичний геймпад або M3. Поточні відкриті критерії —
[[Handoff/2026-10-04-Remaining-Work]]. Локальні журнали поза репозиторієм не є
довічним артефактом: у новому середовищі перевірки потрібно відтворити.

## Related
- [[Build-and-Run]] · [[Architecture]] · [[recurring_class_register]] · [[Handoff/2026-10-04-Remaining-Work]]
