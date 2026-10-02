# Cel-shading і контур (Storm-look)

## Зараз

- `shaders/toon.gdshader`: смуги світла (`bands` 3), тінь із тінтом `shadow_tint` (синюватий),
  `shadow_strength` 0.45, rim 0.3, `hit_flash` (біла спалахівка при ударі). `specular_disabled`.
- `shaders/outline.gdshader`: inverted hull (`cull_front`, витискання вздовж нормалі 0.022) як `next_pass`.
- Фон: `backdrop.gdshader` (unshaded + віньєтка) / `backdrop_fallback.gdshader` (процедурний).
- Матеріали створює `RigAnimator._mat()`; у Compatibility-рендері (Mesa/llvmpipe) компілюються.

## Куди йти (фаза 2)

- **Stencil outline (Godot 4.5+)** на StandardMaterial3D — без подвійних ліній на перекриттях.
- Ramp-текстура замість `floor()`; **вершинні кольори** як контроль художника (R — товщина контуру,
  G — зсув тіні на обличчі, B — маска спекуляру) — трюк Guilty Gear Xrd/Storm.
- Внутрішні лінії **малювати в альбедо**, не пост-процесом (дешево на мобільних).
- Штрихування в тіні (triplanar hatch × (1 − NdotL)), speed lines на `ColorRect` при hitstop,
  smear-меші/blend shapes на 1–2 кадри, крок анімації 12–15 fps на швидких ударах.
- Відкриті шейдери: eldskald/godot4-cel-shader (MIT), EMBYRDEV/godot-toon-outline.

## Related
- [[Style-Guide]] · [[Architecture]] · [[2026-10-02-Engine-Physics]]
