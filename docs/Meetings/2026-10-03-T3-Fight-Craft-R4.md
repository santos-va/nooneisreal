# 2026-10-03 — T3 Архімед: R4 «живе тіло в Godot 4.7» (запуск 7)

**Роль:** T3 Архімед · **Запит Santos:** «читай `docs/Plans/2026-10-03-Wave-2-Kickoff.md` § Хендофи → T3. Першим — R4 для запуску 7».

## Що обговорили
- План хвилі 2 у `main` не знайдено: `git ls-tree -r origin/main | grep Wave-2-Kickoff` → порожньо; він лежить на гілці
  `claude/dreamy-turing-7rsxo9` (`b0967b2`), читав звідти.
- `docs.godotengine.org` із хмари закритий (`curl` → `000`). Джерело API — сам рушій: бінар 4.7.2, `--dump-extension-api`,
  сирці тегу `4.7.2-stable` (`ed1daf0b`), `doc/classes/*.xml` на тегах 4.2…4.7 для версії появи класу.
- `make check` на `main` `7dc1d90` у хмарі → `ALL OK (161 checks)`, rc=0; `grep -c "not supported by Jolt"` → 165.

## Що вирішили (в межах T3 — лише висновок, без вибору)
- Бриф [[2026-10-03-Fight-Craft-A]], розділ R4: 22 `SkeletonModifier3D` у 4.7.2; IK — `TwoBoneIK3D` (з 4.6), погляд —
  `LookAtModifier3D` (з 4.4), spring bones — `SpringBoneSimulator3D` (з 4.4); частковий регдол — штатно
  (`physical_bones_start_simulation([кістки])` + `influence`).
- Розходження з [[Active-Ragdoll]]: у `PhysicalBone3D` на Jolt **є** кутові пружини 6DOF (експеримент 18.5° → 0.0°), моторів немає.
- Вартість у хмарі: 4 кінцівки IK + погляд ≈ +46 мкс на бійця на кадр (медіана, розкид 31–77). M3 і телефон — UNGROUNDED.
- Н7: 165 = 15 регдолів × 11 тіл; масштаб — **сплющення від удару** (`Fighter.gd:1018` → `:1026`, `Ragdoll.gd:54`), не присід.
  Для 7.1: `PhysicalBone3D` під масштабованим скелетом лаються щокадру навіть без симуляції (експеримент: 10 кадрів → 10 рядків).

## Що відкладено
- R4: прогін `bench.gd` на Mac і телефоні; демо-проєкти з ліцензією; вартість `PhysicalBoneSimulator3D`.
- R1, R2, R8 — наступні розділи брифу; потім Ф2.1 (різкість імпорту).
- Виправлення [[Active-Ragdoll]] § Jolt — власнику документа. `state.md` не чіпав (не мій) — перенос висновку за Дедалом.

## Related
- [[2026-10-03-Fight-Craft-A]] · [[2026-10-03-Fight-Craft-Research]] · [[2026-10-03-Living-Combat]] · [[Active-Ragdoll]] · [[state]]
