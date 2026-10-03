# Запуск на Mac (і не тільки)

## Один раз

1. Godot 4.7-stable (Universal, Apple Silicon/Metal): https://godotengine.org/download/macos/ → у `/Applications`.
2. У корені репо: `git clone …`, потім `bash tools/fetch_assets.sh` (фони й картки з CDN Higgsfield;
   агент у хмарі їх завантажити не може).
3. `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot make check` — імпорт, парс, smoke-тест.

## Оновити гру

- `GODOT_BIN=… make update` — `git fetch` → fast-forward поточної гілки → примусовий `--import` (нові `class_name`
  без нього не видно) → «готово: make run». Показує нові коміти.
- `make update BRANCH=<гілка>` — спершу перейти на гілку (наприклад, гілку PR, щоб спробувати до мержу).
- Відмовляє й нічого не стирає, якщо є незакомічені зміни або гілка розійшлася з `origin`.

## Грати

- `GODOT_BIN=… make run` — при першому запуску сам імпортує проєкт (до хвилини), далі запускає `scenes/main/Main.tscn` → меню → «FIGHT · P1 vs CPU».
  З 0.3 (слово Santos) бій за замовчуванням — **вільний 3D-рух**. Бій 0.2 у площині: `make run-plane` (`-- --plane`).
- Або відкрити `game/project.godot` у редакторі й натиснути ▶.
- Клавіші — [[05-Platforms-Input]]. Tab — хітбокси, Esc — пауза, Backspace — скинути позиції (тренування).

## Перевірки

- `make check` — authoritative: `--headless --import` → `--check-only` на кожен `.gd` → `-- --smoke` (36 перевірок, 2026-10-03).
- `make gates` — wikilinks, реєстр ассетів, парність ролей, парс .gd.
- Скриншоти без GPU: `godot --path game --rendering-driver opengl3 --rendering-method gl_compatibility -- --screenshot=/tmp/shots`
  (у контейнері — через `xvfb-run` і Mesa llvmpipe).

## Типові проблеми

- **«Could not find type "CharacterData"» / «Identifier "SmokeTest" not declared» при першому запуску** — свіжий клон без
  імпорту: папка `game/.godot/` (реєстр `class_name`) не в git. `make run`/`make editor` тепер імпортують самі; вручну —
  `make import` або `"$GODOT_BIN" --headless --path game --import`. Виявлено Santos на Mac 2026-10-02; клас №3 у [[recurring_class_register]].

- «Identifier not found: GameState» у `--check-only` — норма (автолоади не реєструються); дивись smoke.
- Фон сірий/процедурний — не запущено `fetch_assets.sh`.
- Немає звуку в headless — так і має бути (dummy driver).

## Related
- [[Testing]] · [[Architecture]] · [[Export-Platforms]] · [[state]]
