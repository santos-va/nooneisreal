---
name: higgsfield-game-art
description: Промпт-інженерія для Higgsfield у цьому проєкті — листи персонажів (T-pose/turnaround/emotions), фони Kronshift, безшовні текстури, спрайт-шити, image-to-3D через Meshy, реєстрація ассетів. Активується на «промпт для Higgsfield», «лист персонажа», «згенеруй текстуру/фон», «T-pose», «Meshy», «3D з картки». Генерація — лише після balance і явного слова Santos.
---

# Higgsfield для гри (T6 Аполлон)

## Нульове правило
`balance` → число в чат → **слово Santos на конкретне ТЗ** → генерація. Без слова — промпт у
`docs/Art/Prompts/`, нуль викликів `generate_*`. Батч — тільки з явним «скільки».

## Стильова формула проєкту (вставляється байт-у-байт у кожен промпт)
> Match the exact art style, line art, colors and flat cel shading of the first reference image.
> Clean anime illustration, crisp lineart, cel-shaded flat color, bold ink outlines, Arcane-like mood,
> not cyberpunk. Muted dusk palette: terracotta, dusty orange, slate blue, deep teal shadows.
> Hands only in fists or gripping an object with exactly five clearly outlined fingers.
> No text, no letters, no logos, no infinity symbol.

Референс №1 завжди — лист на кислотно-жовтій плашці (`hf_20260927_120107_b35646c4…`); для персонажа —
його остання затверджена картка. Фіксований перелік відмінностей: «keep EVERYTHING identical … change ONLY …».

## Шаблони

**Turnaround для Meshy (3D):** одна фігура, білий безшовний фон, без тіні й землі, T-pose (або A-pose),
кінцівки окремо від тулуба, 3/4 ізометрія для одного з ракурсів; 16:9 → потім нарізати на 4 однопозові
панелі. `generate_3d`: `multi_image_to_3d`, `pose_mode: t-pose`, `topology: quad`, `target_polycount ~20000`,
`should_texture: true`, `enable_pbr: false`, `texture_prompt: "flat cel-shaded colors, no baked shadows"`,
`enable_rigging: true`; кліп — з `animation_actions` (група Fighting). Перед сабмітом — `get_cost: true`.

**Лист емоцій:** 4×2 голова-плечі, однакові пропорції, маленькі номери, title `<NAME> EMOTIONS`.
**Руки:** 6 панелей, кулаки/хвати, виріз по рукаву, пальці не зливаються з металом.
**Предмети/зброя:** білий фон, повний вид по діагоналі + 3 вставки, «no hands, no characters».
**Фон арени:** «game background of <scene>, wide establishing view 16:9 (or 21:9), no characters, no UI,
slightly muted detail, soft depth layering» + формула Kronshift. Потім Image Decompose → шари.
**Безшовна текстура:** «seamless tileable surface texture of <material>, perfectly seamless edges, flat even
lighting, no perspective, no objects»; перевірка швів — `pipeline.py` з Texture Tile Factory.
**Спрайт-шит (2D UI/портрети):** AutoSprite `kind`, `frame_count`, `frame_size ≤ 512`, `remove_bg`.
**UI-іконки:** Recraft V4.1 `utility_vector`, палітра з [[Style-Guide]].

## Моделі
Персонажі/картки — GPT Image 2.5 (як у Santos) або Nano Banana Pro (мультиреференс, 2k/4k); FLUX 3 Image — до 10
референсів; прозорий фон — GPT Image 2.5 `background: transparent` або Background Remover.

## Після генерації
1 результат на слот → `game/assets/<розділ>/<snake_name>.<ext>` → рядок у `docs/Art/Textures-Registry.md`
(id, шлях, URL, модель, промпт-лінк, ліцензія, використання) → промпт у `docs/Art/Prompts/` → `make gates`.
