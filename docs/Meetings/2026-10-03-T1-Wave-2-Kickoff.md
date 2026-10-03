# 2026-10-03 — T1: що є в грі, огляд у хмарі замість гри Santos, хендофи хвилі 2

**Хто:** Santos (з телефону, не вдома) · T1 Дедал (хмара)
**Контекст:** Santos попросив коротко розказати, що є в грі, які останні оновлення, що далі й коли буде перший
нормальний матч «як уявляв». Потім — «подивись сам, запустившись» і хендофи терміналам, «щоб закінчили якомога швидше».

## Що обговорили
- Запуски 1–6 плану [[2026-10-03-Path-to-First-Fight]] — у `main` (`git log -1 origin/main` → `f45c2cb`); за планом це
  «нормальний файт». Хвиля 2 (запуски 7–11, [[2026-10-03-Living-Combat]]) у коді не почата:
  `git log origin/main | grep -ciE "launch (7|8|9|10|11)"` → 0.
- Відгук у santos-va/nooneisreal#52 є лише на запуск 1 (2 коментарі). Запуски 2–6 Santos ще не грав.
- Дати хвилі 2 в планах немає; T1 її не називав.
- Відкриті PR: santos-va/nooneisreal#144, santos-va/nooneisreal#145, santos-va/nooneisreal#146; коміт #144 (`db92406`)
  уже в гілці #146 (`git merge-base --is-ancestor db92406 HEAD` → так).

## Що зроблено
- Godot у хмарі: `Godot_v4.7.2-stable_linux.x86_64 --version` → `4.7.2.stable.official.ed1daf0bf`.
- `make check` → `[smoke] ALL OK (161 checks) in 19712 frames`, rc=0; `make gates` → `БАТАРЕЯ ЗЕЛЕНА`, rc=0.
- Кадри CPU проти CPU (`-- --screenshot=<dir> --stage <id> [--night]`): 3 арени × день/ніч × 4 + 92 с бою на `river` →
  ![що працює і що ні](../assets/screenshots/2026-10-03-t1-wave2-look.jpg) ·
  ![92 с бою](../assets/screenshots/2026-10-03-t1-river-92s.jpg). Тимчасову правку `_shots` у `Screenshot.gd` для
  довгого бою відкочено (`git checkout -- game/scripts/core/Screenshot.gd`).
- Що не так (Н1–Н8) і хендофи на 9 терміналів — план [[2026-10-03-Wave-2-Kickoff]].

## Що вирішили
- Гейт «код хвилі 2 — після гри Santos» знято словом Santos; замість гри — огляд T1 у хмарі.
- Три паралельні термінали T2 з різними файлами: T2·A — бій (`fighter/*`, `grapple/*`, `DuelCamera.gd`), T2·B — картинка
  (`fx/*`, `ui/*`), T2·C — арени з паків (`tools/art/*`, `arena/*`).
- Рішення Дедала за смугою B спринту («виклики живуть у `Fighter.gd`»): `FxDirector` читає стан; якщо події нема — T2·A
  додає один `emit` без логіки.
- Кожен PR з видимою зміною несе 2–4 кадри з хмари, поки Santos не вдома.

## Що відклали / відкриті питання
- [[ADR-017-Post-Ragdoll-Position]] — чекає «так» Santos; без нього T2·A робить регдол на скелеті без кінематики.
- T6-1 (≈ 16.5 кр. за планом паків) — слово Santos.
- Н7 (165 попереджень Jolt про масштаб тіл регдола) — причину перевіряє Феміда; здогадка T1 про присід із
  santos-va/nooneisreal#141 не перевірена.
- Звук, клавіатуру й FPS на Mac хмара не бачить — закриває відгук Santos у #52.

## Дії
- [ ] Santos · мерж santos-va/nooneisreal#146 і #145; «так»/«ні» на ADR-017; відкрити T2·B і T2·C · план § Що від Santos
- [ ] T2·A · запуск 7.1 · `make check` → `ALL OK`, `grep -c "not supported by Jolt"` → 0
- [ ] T2·B · іконки, портрети, `.import`, 6 флипбуків · `git status --short` після `make import` → порожньо
- [ ] T2·C · Ф0.3 контакт-лист → Ф4.3 · `ls docs/assets/screenshots/packs_*.png`
- [ ] T3 · R4 у `docs/Research/2026-10-03-Fight-Craft-A.md` · `bash tools/gates/run_gates.sh` → rc=0
- [ ] T5 · правила 7, 8, 10, Ф4.1 · `bash tools/gates/run_gates.sh` → rc=0
- [ ] T6 · ефекти поверхонь для 9 (0 кр.) · `texture_registry_check.py` → N/N
- [ ] T8 · ухили в 8 напрямках · конфліктів клавіш 0
- [ ] T7 · глосарій хвилі 2 · `bash tools/gates/run_gates.sh` → rc=0
- [ ] T4 · Н7 + PR #129–#132, #141, #120 · вердикти в `docs/Audit/`
- [ ] T1 · план «Арена живе» (запуск 11) · після запуску 8

## Related
- [[state]] · [[2026-10-03-Wave-2-Kickoff]] · [[2026-10-03-Living-Combat]] · [[2026-10-03-Path-to-First-Fight]] ·
  [[2026-10-03-Santos-Packs-Arenas]] · [[ADR-017-Post-Ragdoll-Position]]
