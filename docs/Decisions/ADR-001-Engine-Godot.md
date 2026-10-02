# ADR-001 — Движок: Godot 4.7 (GDScript)

**Статус:** прийнято 2026-10-02. **Контекст:** [[2026-10-02-Engine-Physics]].

## Рішення

Godot 4.7.x (апгрейд на 4.8 після stable), GDScript для геймплею. Unity — запасний варіант, Unreal — ні.

## Чому

- 100 % проєкту — текст (`.tscn/.tres/.gd/.gdshader`): агенти в хмарі без GPU читають, пишуть, діффають
  і перевіряють headless (`--import`, `--check-only`, smoke). Unreal — бінарні Blueprints/uasset.
- Редактор легкий на Mac (нативний Metal з 4.4). Мобільні експорти безкоштовні.
- Jolt за замовчуванням (4.6), IK-фреймворк (4.6), stencil outline і shader baker (4.5), HDR (4.7), Trail3D (4.8).
- Консолі — передбачувана ціна W4 Consoles (~$2k/рік Starter) замість ліцензійних воріт.

## Чим платимо

- Active ragdoll і toon-пайплайн робимо самі (Unity має PuppetMaster, Unreal — Physical Animation Component).
- PS5 у W4 — найменш зрілий; потрібен статус розробника.
- C# на мобільних — експериментально → GDScript.

## Related
- [[Architecture]] · [[Export-Platforms]] · [[Active-Ragdoll]] · [[constitution]]
