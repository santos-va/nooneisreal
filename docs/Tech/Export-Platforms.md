# Експорт на платформи

| платформа | шлях | статус |
|---|---|---|
| macOS / Windows / Linux | офіційні експорт-шаблони Godot 4.7; `export_presets.cfg` додати у фазі 4 | ✅ безкоштовно |
| Android / iOS | офіційно; Mobile renderer; `VirtualJoystick` (4.7) для тачу; GDScript (C# на мобільних — експериментально) | ✅ безкоштовно |
| Web | wasm64 у 4.7; корисно для демо | ✅ |
| PS5 / Xbox / Switch | **W4 Consoles** (W4 Games): Starter $800/рік за 1 платформу, $1 500 за 2, $2 000 за 3 (дохід < $300k, ≤ 30 осіб); Pro $4–10k. Потрібен статус зареєстрованого розробника у Sony/Microsoft/Nintendo. Альтернатива — порт-хауси (Pineapple Works, Lone Wolf). | ⏳ фаза 4 |

## Що тримати в голові від початку

- Один мувсет ≤ 9 дій; гліфи за пристроєм; safe area ([[05-Platforms-Input]], [[06-UI-UX]]).
- Мобільний рендер: stencil outline — ок; пост-процес depth/normal edge — дорого.
- Детермінізм: Jolt не обіцяє крос-платформної однаковості → онлайн лише з кінематичним боєм.

## Related
- [[05-Platforms-Input]] · [[ADR-001-Engine-Godot]] · [[Roadmap]] · [[2026-10-02-Engine-Physics]]
