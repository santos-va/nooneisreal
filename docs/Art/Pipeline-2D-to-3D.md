# Пайплайн: від картки до бійця в Godot

Джерело: [[2026-10-02-Animation-Assets-Pipeline]]. Два шляхи — швидкий і якісний.

## Швидкий (1–2 тижні ассет-роботи)

1. **Лист T-pose** з картки в Higgsfield (Nano Banana Pro / FLUX 3 Image, мультиреференс): одна
   фігура, білий фон, без тіні, T/A-pose, кінцівки окремо від тулуба, 3/4 ізометрія для 3D-референсу.
   Промпт за скілом `higgsfield-game-art` (slot-архітектура, anime-2d пресет).
2. **VRoid Studio** (безкоштовно, Mac): зібрати Choko/Skeasse за листом, намалювати текстури
   одягу з картки → VRM 1.0 (Reduce Polygons/Materials/Bones). Імпорт `godot-vrm` (MToon = cel
   одразу), outline з `godot4-cel-shader`.
3. **Анімації (CC0/безкоштовно):** Quaternius Universal Animation Library (GLB), KayKit Adventurers
   (GLB, 1H/2H melee, Block, Dodge, Hit, Death), Rokoko free fight packs (акаунт), Mixamo (сайт нестабільний,
   є bulk-скрипт). Бон-мапа `SkeletonProfileHumanoid` → спільна `AnimationLibrary`.
4. **Фони:** outpaint → upscale → Image Decompose → паралакс.

## Якісний (точна подоба)

1. Нарізати лист на однопозові панелі → Higgsfield `generate_3d` (`multi_image_to_3d`, Meshy 7,
   `pose_mode: t-pose`, `topology: quad`, ~20k трикутників, `enable_pbr: false`,
   `texture_prompt: "flat cel-shaded colors, no shadows"`). Орієнтовно ~38 кредитів на ригованого
   персонажа + ~8 за кліп (внутрішній док Higgsfield; підтвердити `get_cost`).
2. Blender: сплющити запечене світло до пласких заливок, додати лупи на ліктях/колінах.
3. Риг: Meshy auto-rig (шаблон Mixamo), AccuRig 2.0 (безкоштовно) або UniRig (MIT, розуміє VRM).
4. Бібліотека Meshy: 678 кліпів, група Fighting — Attack, Left_Slash, Sword_Judgment, Kung_Fu_Punch,
   Flying_Fist_Kick, Block1–10, Sword_Parry, Roll_Dodge, Hit_Reaction, BeHit_FlyUp, Dead
   (`animation_actions`); один кліп на джоб → злити локально.
5. Спеціальні удари — Cascadeur Indie ($19/міс, FBX) або власний мокап Rokoko Vision.

## Обмеження, які треба знати

- Image-to-3D запікає світло в альбедо і дає рівномірну топологію без лупів — лікті гнуться погано.
- Tripo free — некомерційна; Epic «UE-Only» анімації — лише для Unreal. Логуємо ліцензії в реєстрі.

## Related
- [[Style-Guide]] · [[Textures-Registry]] · [[Cel-Shading]] · [[Active-Ragdoll]] · [[Prompts]]
