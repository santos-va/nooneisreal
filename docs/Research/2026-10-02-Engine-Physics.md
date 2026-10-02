# Ресерч — движок, active ragdoll, cel-shading, архітектура файтингу (2026-10-02)

**Роль:** T3 Архімед (суб-агент). Частина першоджерел (godotengine.org, docs, w4games) закрита
проксі контейнера — факти з GitHub raw-доків і вторинних джерел; UNGROUNDED позначено.

## 1. Версії станом на 2 жовтня 2026

| движок | stable | примітки |
|---|---|---|
| Godot | **4.7.2** (18.08.2026); 4.7 — 18.06.2026; 4.8 у feature freeze (dev7, 29.09) | 4.4: Jolt opt-in, Metal на Apple Silicon; 4.5: stencil (Outline/X-Ray), shader baker, visionOS; 4.6: Jolt за замовчуванням, IK (`SkeletonModifier3D`, TwoBoneIK/FABRIK/CCDIK), node IDs, LibGodot; 4.7: HDR, AreaLight3D, DrawableTexture, C# hot reload, wasm64; 4.8: Trail3D, mip streaming, non-allocating physics queries |
| Unity | 6.6 (01.09.2026); 6.3 LTS | Runtime Fee скасовано; Personal до $200k; Pro $2 310/місце/рік; консолі — Pro або ключ платформи |
| Unreal | 5.8 (17.06.2026) — останній UE5; UE6 EA кінець 2027 | 5 % роялті після $1M; Physical Animation Component; бінарні Blueprints/uasset |

**Консолі для Godot:** W4 Consoles (Switch, Xbox Series, PS5 — early access; Godot ≥ 4.3): Starter $800/1 500/2 000
на рік за 1/2/3 платформи (дохід < $300k, ≤ 30 осіб), Pro $4 000/7 500/10 000; потрібен dev-статус у
платформодержця. Порт-хауси: Pineapple Works, Lone Wolf, Olde Sküül.

**Вердикт:** Godot 4.7.x; GDScript; тримати Unity як фолбек; Unreal виключити (бінарні ассети для
двох людей + агентів без GPU). → [[ADR-001-Engine-Godot]].

## 2. Active ragdoll у Godot 4

- Примітиви: `Skeleton3D` → Create Physical Skeleton → `PhysicalBone3D` під `PhysicalBoneSimulator3D`
  (`SkeletonModifier3D` з 4.3; має `influence` 0..1 — блендер симуляції з анімацією; `physical_bones_start_simulation(bones)` — частковий регдол).
- `PhysicalBone3D` — лише ліміти (без моторів/пружин). `Generic6DOFJoint3D` — мотори й кутові пружини є; під Jolt
  **не** працюють `*_limit_softness`, `restitution`, `damping`, `erp`.
- Підхід A: PD-момент до анімованої кістки в `_integrate_forces` (`τ = Kp·θ·axis − Kd·ω`) —
  репо cberry22/active-ragdoll---physics-animations-in-godot-4.0 (MIT).
- Підхід B: `RigidBody3D` + 6DOF-сервопружини (equilibrium = кут анімації) — R3X-G1L6AME5H/Godot-Active-Ragdolls,
  PRS-Organization/godot-jolt-physics-joint (4.6 + Jolt). Саме так зроблено `Ragdoll.gd` у 0.1.
- Стадії: KO-регдол → запуск з відновленням → часткові реакції кінцівок → м'яка вторинна анімація. → [[Active-Ragdoll]]
- Еквіваленти: Unity PuppetMaster v1.5 (~$90), Unreal PAC — та сама PD-петля, куплене — UI тюнінгу й get-up.

## 3. Cel-shading

- Шейдери: eldskald/godot4-cel-shader (MIT, ramp, rim, outline `next_pass`), EXPWorlds, mujtaba-io/godot-toon-shader;
  пост-контур: jocamar/Godot-Post-Process-Outlines, EMBYRDEV/godot-toon-outline (не дружить із TAA).
- Контур: inverted hull (дешево, мобільно) · stencil Outline (4.5+, без подвійних ліній) · depth/normal Sobel (дорого на мобільних).
- Storm: CyberConnect2 — «super toon», контур двома функціями, вершинний червоний = товщина лінії (мод Storm Connections);
  рецепт Xrd: 2–3 смуги з ramp, ручні нормалі, вершинні кольори як контроль, штрихування в тіні, smear-меші, крок 12–15 fps. → [[Cel-Shading]]

## 4. Архітектура файтингу в Godot

- 60 Гц `_physics_process`, цілі кадри, дані в `.tres`; хітбокси — `PhysicsDirectSpaceState3D.intersect_shape` на такті
  (сигнали Area3D — на кадр пізніше, недетермінований порядок); `CharacterBody3D` без фізичних зіткнень між бійцями.
- Rollback: snopek-games/godot-rollback-netcode (GDScript), Delta Rollback, Klotho (C#, fixed-point, 07.2026). Jolt не обіцяє
  крос-платформного детермінізму → авторитетний бій без фізики.
- Шаблони: Castagne (Godot 3; Godot 4-версія — WIP без бети), FightCore (MIT, 4.7, 2D, гарна модель даних), Fray (MIT, 4.2+,
  стейт-машини, буфер, `FrayHitbox3D`). Грапл: ivan-resetnikov/grappling-hook-3d, mujtaba-io/godot-grappling-hook (2D насправді).
- Storm-арена: lock-on (`look_at` yaw), ввід у базисі до суперника, камера на `SpringArm3D` від середини пари.

## Оцінки трудомісткості

Active ragdoll стадії 1–3 ≈ 3–5 тижнів одного розробника; Storm-шейдинг ≈ 1–2 тижні + арт на персонажа;
ядро бою «відчувається як файтинг» ≈ 2–3 місяці; порт на W4 — тижні після dev-статусу.

## Джерела (вибірка)

godotengine.org/releases/4.4|4.5|4.6, godotengine.org/download/archive/4.7-stable, github.com/godotengine/godot-docs
(ragdoll_system.rst, using_jolt_physics.rst), doc/classes/PhysicalBone3D.xml, PhysicalBoneSimulator3D.xml,
github.com/godot-jolt/godot-jolt/issues/110, w4games.com/w4consoles, unity.com/products/pricing-updates,
forums.unrealengine.com (5.8 released), github.com/eldskald/godot4-cel-shader, github.com/panthavma/castagne,
github.com/vitorrenansd/fightcore-godot, github.com/Pyxus/fray, snopekgames.com (rollback), gamedeveloper.com (CyberConnect2 Q&A).

## Related
- [[ADR-001-Engine-Godot]] · [[Active-Ragdoll]] · [[Cel-Shading]] · [[Architecture]] · [[Export-Platforms]]
