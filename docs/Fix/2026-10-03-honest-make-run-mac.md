# Fix-журнал — «чесний `make run`» (T2·Mac)

**Роль:** T2 Гефест, сесія T2·Mac (розподіл — PR santos-va/nooneisreal#94). **План:** [[2026-10-03-Path-to-First-Fight]]
§ Godot падає, поки агент працює, пункт 2 (а) і (б). Не запуск, 4/5 не блокує.

## Звірка (до роботи)

- `Makefile` на `origin/main` `3686972`: `run` / `run-plane` / `run-rig` / `editor` імпортують лише за `[ -f $(CLASS_CACHE) ]`,
  тож після `pull`/`checkout` кеш класів лишається старий. `check` не дивиться на інші процеси Godot.
- План називає `run`, `run-plane`, `editor`. У `main` є ще `run-rig` (запуск 4), його покрито так само.
- Форма `pgrep -f -- "--path $(realpath game)"` з плану на macOS **не працює**: `make run` запускає Godot з відносним
  `--path game`. А Godot робить chdir у теку проєкту: `lsof -a -p PID -d cwd -Fn` → `n…/t2r/game`, тому `game` від cwd
  розв'язується в `game/game`. Збіг шукаю за cwd процесу або за абсолютним `--path`.

## Що зроблено

- `tools/run/godot_guard.sh`:
  - `busy <game_dir>` → rc=3 і текст відмови, якщо інший процес Godot уже працює на цю теку. Процесом Godot вважається
    рядок, де перше слово називається `godot*`. Вимикається `NIR_GUARD_OFF=1`. Godot без `--path` (Project Manager) не ловиться.
  - `need-import` → імпорт потрібен, якщо кешу нема або HEAD ≠ штамп `game/.godot/nir_import_head`.
  - `stamp` → пише штамп після імпорту.
- `Makefile`: `run`, `run-plane`, `run-rig`, `editor` → `$(PREP)` (busy + імпорт за потреби). `import` і імпорт усередині
  `check` пишуть штамп. `check` на старті кличе `busy`. `update` іде через `import`, тож теж ставить штамп.

## Перевірка (Mac, Godot `4.7.2.stable.official.ed1daf0bf`)

GUI не відкривав: `GODOT="…/Godot --headless --quit-after 300"`.

- Сценарій плану: тимчасова гілка = `28deba3` + цей `Makefile` → `rm -rf game/.godot && make import` → checkout на цю гілку → `make run`.
  Перед грою з'явився рядок «── імпорт проєкту», `grep -c "Could not find type"` → 0. Другий `make run` → рядків імпорту 0.
- Негатив (стара поведінка): той самий застарілий кеш, Godot напряму без переімпорту → `grep -c "Could not find type"` → 5
  (`"SkeletalRig"`).
- Другий Godot у фоні на ту саму теку (`--path game`) → `make check` rc=2 (`make: *** [check] Error 3`, «ВІДМОВА: … уже працює Godot (pid …)»),
  `make run` теж відмовляє. `NIR_GUARD_OFF=1` → rc=0. Та сама перевірка на іншу копію (`~/Documents/nooneisreal/game`) → rc=0.
  Після `kill` → rc=0.
- Перша версія скрипта цю відмову **пропускала**: шукала тільки за відносним `--path` і писала `basename: missing operand`.
  Виправлено, перевірка вище — вже на виправленій версії.
- `GODOT_BIN=…/Godot make check` → `[smoke] ALL OK (112 checks)`, штамп = `git rev-parse HEAD`. `bash tools/gates/run_gates.sh` → rc=0.

**Не перевірено:** справжній GUI-запуск на Mac і Linux (`/proc`-гілка скрипта).

## Related

- [[2026-10-03-Path-to-First-Fight]]
- [[2026-10-03-T1-Godot-Crash-Fresh-Build]]
