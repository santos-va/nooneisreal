# state — поточна правда

**Оновлено:** 2026-10-02, друга сесія (кіти Skea і Choko, баланс, VFX).
**Фаза:** Prototype 0.2 — обидва кіти реалізовано, `make check` зелений (smoke 20/20), гілка `claude/blissful-clarke-pj15rz`, draft PR #1.

## Зараз важливо

1. Santos: блок B2 в [[2026-10-02-Characters-Interview]] (флеш, невидимість, пасивка Choko, варіант гримуара) + 12 лиходіїв ∞8.
2. Santos на Mac: Godot 4.7, `bash tools/fetch_assets.sh`, `make run` — перший плейтест кітів ([[08-Balance]] § «що міряти»).
3. Аполлон: T-pose листи Choko/Skea для Meshy — **без генерації** до слова Santos (баланс 2.55 кредиту).
4. Гефест (фаза 2): замінити капсульний риг на GLB-скелет, зберігши інтерфейс `RigAnimator` ([[Architecture]]).

## Що працює (виміряно `make check` 2026-10-02)

- `find game -name '*.gd' | wc -l` → 31 скрипт, усі парсяться.
- Smoke 20/20: удари, TIME STOP (заморозка + удар по замороженому), RECORD → перемотка, гарпун, Sword Storm KO,
  Flash Step крізь суперника (привиди, −1 заряд), Kunai Rain (Armor Break), Shadow Veil (невидимість), крит + bleed з вуалі,
  Grimoire → регдол, вставання, KO, раунд 3.
- Рендер під Mesa/llvmpipe: `docs/assets/screenshots/2026-10-02-kits-a.png`, `-kits-b.png`.

## Відкрите / ризики

- Фони й картка Choko не в репо (CDN закритий для контейнера) — `tools/fetch_assets.sh` локально. Картка Skea — у репо.
- Усі числа бою — PLACEHOLDER; регдол і риг — капсульні.
- Консолі — W4 Consoles (~$2k/рік Starter) + статус розробника Sony/MS.

## Related
- [[index]] · [[constitution]] · [[Roadmap]] · [[2026-10-02-Skea-Kit-and-Balance]] · [[2026-10-02-Kickoff]]
