# Запуск на Mac (і не тільки)

## Один раз

1. Godot 4.7-stable (Universal, Apple Silicon/Metal): https://godotengine.org/download/macos/ → у `/Applications`.
2. У корені репо: `git clone …`, потім `bash tools/fetch_assets.sh` (фони й картки з CDN Higgsfield;
   агент у хмарі їх завантажити не може).
3. `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot make check` — імпорт, парс, smoke-тест.

## Грати

- `GODOT_BIN=… make run` — запускає `scenes/main/Main.tscn` → меню → «FIGHT · P1 vs CPU».
- Або відкрити `game/project.godot` у редакторі й натиснути ▶.
- Клавіші — [[05-Platforms-Input]]. Tab — хітбокси, Esc — пауза, Backspace — скинути позиції (тренування).

## Перевірки

- `make check` — authoritative: `--headless --import` → `--check-only` на кожен `.gd` → `-- --smoke` (11 перевірок бою).
- `make gates` — wikilinks, реєстр ассетів, парність ролей, парс .gd.
- Скриншоти без GPU: `godot --path game --rendering-driver opengl3 --rendering-method gl_compatibility -- --screenshot=/tmp/shots`
  (у контейнері — через `xvfb-run` і Mesa llvmpipe).

## Типові проблеми

- «Identifier not found: GameState» у `--check-only` — норма (автолоади не реєструються); дивись smoke.
- Фон сірий/процедурний — не запущено `fetch_assets.sh`.
- Немає звуку в headless — так і має бути (dummy driver).

## Related
- [[Testing]] · [[Architecture]] · [[Export-Platforms]] · [[state]]
