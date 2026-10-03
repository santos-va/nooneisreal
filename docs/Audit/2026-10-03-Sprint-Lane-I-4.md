# Аудит спринту, смуга I, частина 4 — #121 (HUD варіант 2)

**Дата:** 2026-10-03 · **Роль:** T4 Феміда · **Запит Santos:** «Перевіряй далі по історії» — іду хронологічно PR,
яких ще не бачила. План [[2026-10-03-Sprint-Arenas-VFX]] § I; попередні частини — [[2026-10-03-Sprint-Lane-I]],
[[2026-10-03-Sprint-Lane-I-2]], [[2026-10-03-Sprint-Lane-I-3]]. Міряно на голові
santos-va/nooneisreal#121 (`d0195e38`, worktree поза iCloud). Godot `4.7.2.stable.official.ed1daf0bf`.

## Вердикт: **GREEN**

| # | що | вердикт | команда → вихід |
|---|---|---|---|
| 1 | батарея | GREEN | `make check` → `[smoke] ALL OK (156 checks) in 19190 frames`, rc=0; `run_gates.sh` → `БАТАРЕЯ ЗЕЛЕНА`, rc=0 |
| 2 | `_outlined()`: кільця без плити (`draw_center = false`) | GREEN | `game/scripts/ui/Hud.gd:265` `sb.draw_center = false` — прочитано напряму, не з опису PR |
| 3 | свій тест `_check_hud` звіряє точні значення (ширина, колір, `skew`), а не «є кільце» | GREEN | `SmokeTest.gd:665-669` |
| 4 | **мої 3 негативи** (не з тих 5, що вже назвав автор) | GREEN | § нижче — усі 3 червоні |
| 5 | журнал зустрічі (клас 7) | GREEN — закрито тим самим PR #124 | на момент самого #121 лінку не було; на `main` `2026-10-03-Hefest-Sprint-Lane-A.md` лінкує `sprint-hud-double-outline` |
| 6 | кредити | GREEN | 0 — лише код, жодного `generate_*` |
| 7 | відкрита розвилка (телефон, п. 7 HUD-спеки) | GREEN — чесно назвав | «код не має прапорця "телефон"» — не прикрито, передано Гермесу/Santos |

## Мої негативні контролі (окрім 5, які вже дав автор)

`--smoke-only=cam`, python-заміна з `assert count == 1`, файл повернено з `.bak`, `git status --short game` → чисто.

| # | злам | вихід |
|---|---|---|
| N1 | кремове кільце теж 2 px (замість 1) | `FAIL HUD: … is not an ink 2 + cream 1 ring …` |
| N2 | `skew` крему відрізняється від чорнила на 0.1 | `FAIL HUD: … is not an ink 2 + cream 1 ring, clear inside, slanted alike …` |
| N3 | заповнення зупиняється на 90 % замість 100 % (`frac * 0.9`) | `FAIL HUD: grapple [charge ¼ into cooldown, …] = [0.675, 0.0, …] (want [0.75, 0, …])` |

## Related
- [[2026-10-03-Sprint-Lane-I-3]] · [[06-UI-UX]] · [[2026-10-03-Hefest-Sprint-Lane-A]] · [[2026-10-03-Sprint-Arenas-VFX]] · [[state]]
