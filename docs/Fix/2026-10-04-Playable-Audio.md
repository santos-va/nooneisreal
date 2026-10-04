# Ігрове аудіо: вода, незалежний RNG і завершення

T2 Гефест, смуга AUDIO, 2026-10-04. Реалізація за дорученням Santos через головний термінал.

## Звірка

`Sfx.gd` мав 12 голосів, кеш `AudioStreamRandomizer` і глобальний `randf_range` для pitch.
На початку звірки у `game/assets/audio/sfx/` не було `water_*`. Каталог і таблиця джерел містять Sonniss water,
але `tools/audio/nir-audio/` та стандартна бібліотека Downloads тут відсутні; пошук у
`/workspace/library-files`, `/workspace/shared`, `/workspace/scratch` не дав водних сирців.
Підміна сплеску ударом не виконана. Після цієї звірки головний термінал доручив T6 окремий
оригінальний процедурний шар `water_step`, `water_land`, `water_dash`, `water_skid` по два WAV.
Це дозволена тимчасова синтетика, не запис справжньої води й не джерело Sonniss.
Після інтеграції перевірено: усі 8 WAV є, у [[Textures-Registry]] є 8 рядків із джерелом
`tools/audio/synth_water.py` та власними seed. Сторонніх матеріалів немає, CC0 не оголошено.
Слухова якість залишається на перевірку Santos; деталі — [[Procedural-Water-Audio]].

## Зміна

- `Sfx.play_surface_water(event, actor_slot)` приймає `step`, `land`, `dash`, `skid` і слот 0/1.
  Повертає `false` для невідомої події, слота, відсутнього файла або повтору до завершення інтервалу.
  Вода визначається викликачем. Таблиця throttle обмежена 4 подіями × 2 слотами.
- Імена ресурсів — `water_<event>` з наявною підтримкою `.ogg` / `.wav`, до 8 варіантів.
  Гучності та інтервали позначено як презентаційні PLACEHOLDER; потрібне прослуховування.
- Pitch усіх SFX і вибір варіанта використовують власний `RandomNumberGenerator`.
  `AudioStreamRandomizer` збережений лише як контейнер для сумісності `variant_count`;
  у голос передається обраний дочірній потік. Без негайного повтору варіанта.
- `_exit_tree` зупиняє валідні голоси, від'єднує потоки, очищає пул і кеші.
  Ізольований аудіотест підтвердив очищення без попереджень; повний smoke ще має окремі
  попередження завершення, причина не встановлена.
- Інструкція власного VO — [[Character-Voice-Recording]]. Голоси персонажів ще не записано й не підключено.

## Перевірка

Предмет: для всіх подій SFX презентаційна випадковість не змінює глобальний gameplay RNG;
для всіх допустимих водних подій відсутній ресурс дає тишу без впливу на бій.

`tools/audio/sfx_check.gd` додано для runtime regression: seed 4242 cold/warm, 32 вибори без
негайного повтору, справжні water-ресурси, незалежність слотів і подій, invalid inputs, missing
stream через інжекцію `null`, повтор після інтервалу, очищення голосів при виході.
Тест очікує по два імпортовані файли на water-подію; відсутність цих файлів — FAIL.
Запуск: `$GODOT_BIN --headless --path game -s "$PWD/tools/audio/sfx_check.gd"`.

Godot запускав головний термінал послідовно. Результати прочитано у поточній сесії:

- `/workspace/nooneisreal-env/playable/logs/audio-verbose.log`: `sfx-check: OK (42 checks, 0 failures)`,
  без WARNING / ERROR / leaked. Після явного звільнення локальних посилань тест чекає
  кадри дерева для завершення відкладеної роботи AudioServer. Подальший інтеграційний
  запуск із `--fixed-fps 60 --audio-driver Dummy` (`playable/regression/audio.log`) дав
  42/42, але 99 leaked objects / 18 resources: симуляційний таймер не гарантував часу
  аудіопотоку. Drain змінено на 200 мс монотонного реального часу з обробкою кадрів
  і коротким yield CPU. Повтор саме цього режиму підтверджено у
  `playable/logs/audio-fixed-verbose.log`: 42/42, без warning/error/leak.
- `/workspace/nooneisreal-env/playable/logs/check.log`: `[smoke] ALL OK (164 checks)`.
  При завершенні лишається `16 resources still in use at exit`.
  Це не зараховано як чисте завершення повного smoke; ізольований аудіотест не відтворює проблему.
  За окремим дорученням головного термінала у `SmokeTest._finish` додано завершення поза
  physics callback: пауза дерева, stop/від’єднання потоків AudioStreamPlayer і такий самий
  drain реального часу перед quit. Перевірки бою й лічильники не змінено; повтор smoke очікується.
- Wikilink-гейт: 0 зламаних; `git diff --check` для власних файлів чистий.

| команда / сценарій | умова проходження | дія на провалі |
|---|---|---|
| `python3 tools/gates/wikilink_check.py` | 0 битих посилань | виправити власні посилання |
| `make check` | smoke зелений, парсер без помилок | виправити Sfx і повторити |
| `make gates` | усі гейти зелені | виправити власну причину |
| seed 4242, пара `randi` з/без `Sfx.play` між ними | однакова друга величина, cold і warm cache | перевірити pitch і вибір варіантів |
| невідома water event, слот −1/2, інжектований missing stream | `false`, немає голосу/зміни RNG | перевірити ранній вихід |
| тестові water streams у кеші: два повтори одного слота, потім другий слот | true/false/true; інша подія незалежна | перевірити ключ throttle |
| завершення після активного звуку | немає нових leaked audio resource warnings | перевірити lifecycle; не приховувати попередження |

## Related

- [[Character-Voice-Recording]] · [[07-Audio]] · [[ADR-008-Audio-Sourcing]] · [[2026-10-03-phase1-controls-audio-water]]
