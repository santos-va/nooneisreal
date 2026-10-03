# 2026-10-03 — Кліо: місто Kronshift → Cronshift у вікі (#12, крок 1)

**Хто:** Santos · T7 Кліо
**Контекст:** Santos: «Беремо #12 Cronshift зараз». Рішення про назву ухвалено раніше — [[ADR-010-City-Name-Cronshift]]; залежність #9 закрита. Обсяг кроку 1 за issue #12: `docs/` і `roles/`.

## Що зроблено

- Сторінку `docs/World/Kronshift.md` перейменовано на [[Cronshift]] (`git mv`). Заголовок «Cronshift (Кроншифт)», і в першому абзаці пояснено, що «Kronshift» — помилкове написання.
- Усі `[[Kronshift]]` → `[[Cronshift]]`, у тексті слово `Kronshift` → `Cronshift`: 24 файли в `docs/` і `roles/`, зокрема [[index]], [[Glossary]], [[Lore]], [[PROPOSAL-Story-Arc]], `roles/t7-klio.md` і `roles/t6-apollon.md`.
- Перевірка: `python3 tools/gates/wikilink_check.py` → 0 зламаних; `bash tools/gates/run_gates.sh` → rc=0, «БАТАРЕЯ ЗЕЛЕНА».

## Що свідомо лишилось «Kronshift»

`grep -rnI Kronshift docs roles` після правки:
- **Історія й свідчення:** [[ADR-010-City-Name-Cronshift]] (саме рішення), рядок #12 у [[state]], [[2026-10-03-Main-Menu-and-Chain]]:17, [[2026-10-03-Klio-Lore-Canon-Skea-Choko]]:49, [[2026-10-03-Generation-Waves]]:37. Grep-команди в [[2026-10-03-Generation-Waves]]:135, [[2026-10-03-Wave-1-Style-Probe]]:13 і [[2026-10-03-Choko-Outfit-and-Review]]:24 теж лишились: це команди перевірки, і після зміни вони б шукали інше.
- **Шляхи ассетів** `bg_kronshift_*` і id `bg-kronshift-river`, зокрема весь [[Textures-Registry]]: файли ще звуться по-старому, тож це крок 2 Гефеста.
- **`KRONSHIFT` великими** — у журналах 2026-10-02 і 2026-10-03 як запис того, що було сказано тоді. Канон неону — CRONSHIFT ([[ADR-010-City-Name-Cronshift]]).

## Що вирішили

- Нового рішення немає, це виконання [[ADR-010-City-Name-Cronshift]].

## Відкрите / хто далі

- **T2 Гефест, крок 2 #12:** код (`GameState.gd`, `MainMenu.gd`, `Backdrop.gd`, `backdrop_fallback.gdshader`, `project.godot`), файли `bg_kronshift_*` разом із `.import`, [[Textures-Registry]], `tools/fetch_assets.sh`, промпти в `.claude/skills/higgsfield-game-art` і `game-ui-design`. Після цього Кліо оновить шляхи `bg_kronshift_*` у вікі.
- **Поза issue:** `README.md` і `CLAUDE.md` — по одному «Kronshift». Santos: «Виправ README і CLAUDE.md сама», тож Кліо виправила обидва (`grep -c Kronshift README.md CLAUDE.md` → 0 і 0).

## Related
- [[ADR-010-City-Name-Cronshift]] · [[Cronshift]] · [[Glossary]] · [[state]] · [[index]]
