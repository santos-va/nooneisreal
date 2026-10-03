# Higgsfield — аудит акаунта і конвеєр генерації

Аудит 2026-10-02, кожен рядок перевірено викликом інструмента в сесії (R0). Повторюй аудит на старті кожної
сесії генерації: `balance` → `list_workspaces` → `models_explore` для потрібного типу → `get_cost` на кожен запуск.

## Стан акаунта (перевірено)

| факт | значення | як перевірено |
|---|---|---|
| План / кредити | Ultra, **6010 кредитів** | `balance` |
| Робочий простір | один приватний `bf32c161-…`; був **не вибраний** → вибрано | `list_workspaces`, `select_workspace` |
| Історія генерацій | **порожня** в цьому акаунті | `show_generations` (усі стани) |
| Старі картки й фони (2026-09-26…10-02) | лежать на CDN попереднього акаунта, **імпорт за URL працює** | `media_import_url` на city reference → `media_id 8b5f2c67-…` |
| Проєкти | автостворення вимкнено (`auto_create_project:false`) | `get_preferences` |

Висновок: зараз підключено **інший акаунт Higgsfield**, ніж той, де генерувались картки (там було 2.55 кредиту).
Старі job-id тут не працюють як референси — спершу `media_import_url` з CDN-адреси з [[Textures-Registry]] / [[Prompts]].

## Ціни (перевірено `get_cost`, без списання)

| що | модель і параметри | кредитів |
|---|---|---|
| Лист / картка 16:9, якість | `gpt_image_2_5`, quality high, 2k | **2.75** |
| Лист / картка 16:9 | `nano_banana_pro`, 2k | **2** |
| Мульти-референс (до 10 референсів) | `flux_3_image`, 2k | **3** |
| Розкласти фон на шари (паралакс) | `image_decompose` | **2** |
| 3D з 1–4 ракурсів, текстура + риг, T-pose, quad, 20k | `multi_image_to_3d` | **35** |
| 3D з 1 ракурсу + риг + 1 анімаційний кліп | `image_to_3d` + `animation_action_id` | **38** |
| Спрайт-анімація | `autosprite` | **не вдалося оцінити** (помилка оцінювача двічі) — перевірити в наступній сесії |
| Відео-референс руху | `kling3_0` 3–15 с, `sound:"off"` дешевше | оцінити `get_cost` перед запуском |

## Ціни 3D і анімацій (Х3a, `get_cost` 2026-10-03, нічого не списано)

Вхід — 4 T-pose Choko хвилі 2 (`c280d939`, `822b889d`, `f0763795`, `cbaf6f58`); кліп — `87 Boxing_Practice` з `animation_actions` (група Fighting).

| що | модель і параметри | кредитів |
|---|---|---|
| 3D з 4 ракурсів, текстура, **без рига** | `multi_image_to_3d`, `should_texture`, `enable_pbr:false`, t-pose, quad 20k | **30** |
| те саме **+ риг** | `enable_rigging:true` | **35** |
| те саме + риг **+ 1 кліп** | `enable_animation:true`, `animation_action_id:87` | **38** |
| 3D з 1 кадру + риг + 1 кліп | `image_to_3d` | **38** |
| риг готової GLB | `3d_rigging` (виміряно на публічній `Fox.glb` Khronos — ціна для нашої моделі **не перевірена**) | **5** |
| риг готової GLB + 1 кліп | `3d_rigging`, `enable_animation`, кліп 0 або 87 | **8** |

Висновок для розвилки 3c: кожен додатковий кліп на вже готовій моделі = новий виклик `3d_rigging` + кліп = **8**
(а не 38). 6–10 кліпів на героя ≈ 48–80 кр. замість 228–380 з [[Asset-Manifest]] § A. Що повертає `3d_rigging` —
нову GLB з одним кліпом чи кліп окремо — **не перевірено** (без запуску не видно).

## Що зламалось у хвилі 2

- `flux_2_pro_outpaint`: `get_cost` працює (вимагає `input_width/height`), сабміт → `422` на кожному варіанті параметрів (5 спроб). Обхід — не знайдено.
- `image_decompose`: сабміт вимагає `prompt` і приймає `mode` (`standard`/`granular`); результат `completed`, але URL шарів не повертає жоден інструмент MCP.
- `nano_banana_pro` у результатах записаний як `nano_banana_2` (ціна 2 = `get_cost`).
- `autosprite`: у хвилі 2 не пробувався (план 2g — на gpt_image_2_5).

## Що можна і що не можна брати з Higgsfield

| задача | інструмент | статус |
|---|---|---|
| Листи персонажів, картки предметів, іконки, фони | `gpt_image_2_5`, `nano_banana_pro`, `flux_3_image`, `recraft_v4_1` (вектор/іконки) | ✅ |
| Розширити фон / шари / апскейл | `flux_2_pro_outpaint`, `outpaint`, `image_decompose`, `topaz_image`, `bytedance_image_upscale` | ✅ |
| 3D-модель з листа, авториг, кліпи з бібліотеки 678 дій | `multi_image_to_3d`, `image_to_3d`, `3d_rigging`, `animation_actions` | ✅ |
| Спрайт-шити (VFX, UI-анімації) | `autosprite` | ✅ ціну перевірити |
| Відео як референс анімації/хвиль | `kling3_0`, `seedance_2_0`, `veo3_1`, Genjutsu (`hf_mult_motion_control`) | ✅ для референсу, не в гру |
| Голоси персонажів (TTS) | `seed_audio`, `elevenlabs_v4`, `text2speech_v2` | ✅ пізніше |
| **Звукові ефекти і музика** | `mirelo_text_to_audio`, `sonilo_music` | ❌ **заборонено** описом інструмента: «тільки для game-pipeline сайтів Higgsfield», не для окремого аудіо → звук беремо з бібліотек ([[07-Audio]], [[ADR-008-Audio-Sourcing]]) |
| Workflow «Texture Tile Factory» (зі старого ресерчу) | — | ❌ **у каталозі workflow його немає** (перевірено `get_workflow_instructions`); безшовні текстури — звичайним промптом + перевірка шва локально |
| Workflow `character-sheet` | slot-архітектура листа | ✅ використовуємо як каркас промпта, але з нашим стилем замість «anime-2d» |

## Конвеєр (кожен ассет)

1. **ТЗ** — рядок у [[Asset-Manifest]]: id, що, для чого, модель, кількість, бюджет.
2. **Референси** — `media_import_url` старої картки (ідентичність) → `media_id` у таблицю.
3. **Промпт** — з [[Prompt-Library]]: стильова формула байт-у-байт + слоти.
4. **Ціна** — `get_cost:true`, число в чат.
5. **Слово Santos** на конкретну партію (R5). Без слова — стоп на кроці 4.
6. **Генерація** — `generate_image_batch` для незалежних, `count` 2–4 лише для варіантів одного промпта; `jobs_wait`; `show_generation_by_ids`.
7. **Відбір** — 1 результат на слот; Santos підтверджує канон.
8. **В репо** — `game/assets/<розділ>/<id>.<ext>` (на Mac через `tools/fetch_assets.sh`, бо CDN закритий для хмари) + рядок у [[Textures-Registry]] з job-id і промптом.
9. **Журнал** — запис у `docs/Meetings/` або `docs/Fix/`; `make gates` зелений.

Пропозиція організації в Higgsfield (створити лише зі слова Santos): проєкт «No One Is Real», папки `choko/`,
`skea/`, `stage-river/`, `ui/`, `vfx/`, `archive-anime/`.

## Related
- [[Asset-Manifest]] · [[Prompt-Library]] · [[Style-Guide]] · [[Textures-Registry]] · [[Pipeline-2D-to-3D]]
