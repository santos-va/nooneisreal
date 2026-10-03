---
name: higgsfield-game-art
description: Промпт-інженерія для Higgsfield у цьому проєкті — листи персонажів (T-pose/turnaround/emotions), фони Kronshift, безшовні текстури, спрайт-шити, image-to-3D через Meshy, реєстрація ассетів. Активується на «промпт для Higgsfield», «лист персонажа», «згенеруй текстуру/фон», «T-pose», «Meshy», «3D з картки». Генерація — лише після balance і явного слова Santos.
---

# Higgsfield для гри (T6 Аполлон)

## Нульове правило
`balance` → число в чат → **слово Santos на конкретне ТЗ** → генерація. Без слова — промпт у
`docs/Art/Prompts/`, нуль викликів `generate_*`. Батч — тільки з явним «скільки».

## Стильова формула проєкту — «Sketch-Cel», НЕ аніме (з 2026-10-02)

Брати байт-у-байт із `docs/Art/Prompts/Prompt-Library.md` (блоки STYLE і NEG). Коротко: ескізна графітово-
сливова лінія, пласка заливка, одна маджента-лілова тінь, західно-мультиплікаційні пропорції, м'ятна плашка
`#B8CBB1`. Референси манери Santos — чужий фан-арт: **не завантажувати в Higgsfield, не називати художницю**.

## Факти акаунта (перевірено 2026-10-02 — переперевіряй на старті сесії, R0)
- Ultra, 6010 кредитів; один приватний workspace (перевір `list_workspaces` → `is_selected`).
- Історія порожня: старі картки — з CDN через `media_import_url` (працює, кредитів не бере).
- Ціни: gpt_image_2_5 high 2k = 2.75; nano_banana_pro 2k = 2; flux_3_image 2k = 3; image_decompose = 2;
  multi_image_to_3d (текстура+риг) = 35; image_to_3d + кліп = 38; autosprite — оцінювач падав.
- **SFX/музика (`mirelo_text_to_audio`, `sonilo_music`) — заборонені** описом інструмента; звук — з бібліотек.
- Workflow «Texture Tile Factory» у каталозі відсутній.

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

**Флипбуки (VFX, спрайт-шити):** модель малює сітку на око → кожен аркуш через
`python3 tools/art/repack_flipbook.py in.png out.png` (рівні клітинки 512 px, один масштаб; `FAIL` → перегенерувати).
Формат і блоки — `docs/Art/Prompts/VFX-Sheets-Prompts.md`. Іконку (око, пружина) описувати лініями, а не словом «stylized».
Референс у `medias` — **повний UUID**, короткий id відхиляється. Відео з альфою в каталозі немає: Kling лише для світних
ефектів на чорному під `BLEND_MODE_ADD`.

**Перед кожним пушем у гілку з PR:** `gh pr view <N> --json state`. MERGED → нова гілка від `origin/main` і новий PR
(2026-10-03: коміти, запушені в уже змерджену гілку, у `main` не потрапили).
