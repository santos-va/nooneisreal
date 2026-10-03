# Fix-журнал — гард «Побачено» ламає броню ульти (T2·Mac)

**Роль:** T2 Гефест, сесія T2·Mac (розподіл двох T2 — PR santos-va/nooneisreal#94). **Джерело:** пропозиція 1 Феміди,
`docs/Audit/2026-10-03-Launch-3b.md` (PR #91, змерджено) — NC1: прибрати `revealed_frames > 0` з `ult_armored()` → smoke зелений.
**Дизайн:** [[03-Skills-Framework]] § Ульта Skea під бас (слово Santos: броню ламають DoT, armor break, «Побачено», time stop).

## Звірка (до роботи)

- `git log --oneline -1 origin/main` → `3686972` (мердж #91). Заявок T2·хмара в `origin/main` немає: `git grep "T2·хмара" origin/main` → порожньо.
- Код уже є: `Fighter.gd` `ult_armored()` → `if dot_frames > 0 or armor_break_frames > 0 or revealed_frames > 0 or frozen_frames > 0: return false`.
  `Fighter.gd` не змінював — бракувало лише гарда.
- Godot: `which godot` → порожньо; `/Applications/Godot.app/Contents/MacOS/Godot --version` → `4.7.2.stable.official.ed1daf0bf`, через `GODOT=…`.

## Що зроблено

- `SmokeTest.gd`: нова функція `_check_3b_seen_breaks_armor()` і стадія `126` між Poison (122) і довгою ультою (123).
  Свіжа арена, звичайна ульта, на кадрі руху 30 Skea отримує лише «Побачено» (`revealed_frames = 60`), інших заклять немає (стадія це перевіряє).
  Далі heavy Choko → `HITSTUN`, ульта закінчується того самого кадру (затухання + стінгер), `ult_fx` прибрано.
  У стадії 122 змінено один рядок: `_load_arena(2, 123)` → `_load_arena(2, 126)`.

## Перевірка

- `GODOT=/Applications/Godot.app/Contents/MacOS/Godot make check` → `[smoke] ALL OK (115 checks)`, rc=0. На `main` 112 checks.
  +3 = новий рядок «3b armor break: «Seen» on Skea …» + «arena loaded» і «SFX bus» від ще одного `_load_arena`.
- **NC1** (негатив Феміди): прибрав `revealed_frames > 0` з `ult_armored()` → rc=2,
  `FAIL 3b Seen: revealed Skea hit → state 6 (want HITSTUN), ult running true, fade on -1`. Код повернуто, `git status` → лише `SmokeTest.gd` + цей журнал.
- `bash tools/gates/run_gates.sh` → rc=0, `БАТАРЕЯ ЗЕЛЕНА`.

## Related

- [[03-Skills-Framework]]
- [[2026-10-03-launch-3b-ult-bass]]
- [[recurring_class_register]]
