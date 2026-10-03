# 2026-10-03 — T6 Аполлон: CDN відкрито, канон хвилі 2 — у гру

**Роль:** T6 Аполлон (смуга C) · **Гілка:** `claude/sweet-bell-ftofst` · **Кредити Higgsfield:** 0, генерацій не було.

## Що обговорили

- Santos відкрив контейнеру T6 доступ до CDN Higgsfield (`d8j0ntlcm91z4.cloudfront.net`) і сказав: подивитись, що лишилось у
  смузі, обрати й завантажити. Досі все завантаження з CDN робилось на Mac (`tools/fetch_assets.sh`).
- Перевірка доступу: корінь CDN → `403 AccessDenied` (S3 без ключа — нормально); відомий PNG `f21298f4` → `200 image/png 4206288`.

## Що зроблено (команда → вихід)

- `bash tools/fetch_assets.sh` → 14 нових файлів, `file` — розміри збігаються з таблицями [[Menu-Skyline-Prompts]]:
  - заплановані в [[Textures-Registry]] (смуга C, [[Arenas-360-Prompts]]): плита річки `a2913501` 2688×1152, вода піна `b0a9189d` і
    брижі `bb5e3e44` 2048×2048 RGBA, лист якорів `c5900952` 2688×1520;
  - решта канону хвилі 2 з [[2026-10-03-Picks-to-Game-and-Animation]] § B1: меню-панорама `73ee9806` 3840×1648, край даху `f500c1cf`,
    картки глибини `08c09625`, машини `4603954f`, пара `bd9797c1`, перехожі `cc4637e4` / `b4cc96ad` / `76fac42d` / `ccc3ca6e`, дрон `e9fd9e33`.
- Нові теки: `game/assets/menu/`, `game/assets/sprites/`, `game/assets/vfx/`, `game/assets/textures/`, `game/assets/props/`.
- Відбір: усі 14 — канон Santos («переможець» / «так» / «залишаємо» в [[Menu-Skyline-Prompts]]); переглянуто прев'ю, підміни немає.
- `show_generation_by_ids` для шарів decompose `bc9d78b2` і `9fe905f1` → `completed`, але в `params` лише вхідне зображення, URL шарів немає.
- `python3 tools/gates/texture_registry_check.py` → `на диску: 102 · у реєстрі: 102 · незареєстрованих: 0 · неіснуючих: 0`.
- `make gates` → `БАТАРЕЯ ЗЕЛЕНА` (GDS пропущено: Godot не на PATH); `GODOT_BIN=…/Godot_v4.7.2-stable_linux.x86_64 make check` →
  `[smoke] ALL OK (148 checks)`, `SMOKE ЗЕЛЕНИЙ`, rc=0 (бінар узято з GitHub releases у scratchpad; `.import` згенеровано).
- `balance` → 5457 (ultra).

## Що знайшли (передача)

- **Тайл піни `tex_water_foam.png` з вадою:** на прев'ю приблизно 55–87 % висоти — розмазана смуга з відблисками міста замість піни;
  тайл не безшовний по вертикалі. Варіанти: (а) Гефест бере лише верхні ≈ 55 % як тайл; (б) перегенерація ≈ 2 кр. — тільки зі слова Santos.
- **Ореол на прозорих спрайтах:** `sprite_pedestrian_worker_walk.png` — альфа > 1 % у 14.4 % пікселів, > 99 % — лише 6.3 %
  (`convert … -alpha extract -threshold`); край даху 29.3 % / 19.7 %. Тобто м'яке світіння навколо фігур. Гефесту: alpha scissor
  ≈ 0.5 або поріг альфи в шейдері, інакше в діорамі буде темний або світлий німб.
- Шари decompose — URL дістати лише з галереї Higgsfield вручну (Santos) або розкласти в рушії; рядок у таблиці «Заплановано».

## Доповнення: піна v2 (Santos «go», 2026-10-03, пізніше)

- `balance` 4714.75 → `get_cost` `nano_banana_pro` 2k 1:1 → 2 → генерація ×1 `3e04a378` → `balance` **4712.75 (−2)**.
- Без референсу (гіпотеза: смугу міста в v1 протягнула плита річки), кольори hex із тайла брижів. Шов — `convert -roll` на 50 %: стиків
  немає; кілька плям на старих краях трохи розмиті.
- Файл `game/assets/textures/tex_water_foam_v2.png`; v1 **не видалено** (видалення ассетів — Red), позначено вадним у [[Textures-Registry]].
  Промпт — [[Prompt-Library]] § 5a. У коді гри `tex_water_foam` не використовується (`grep -rln tex_water_foam game/scripts game/scenes` → 0).

## Що вирішили

- `tools/fetch_assets.sh` більше не «тільки Mac»: коментар оновлено, новий блок рядків канону хвилі 2.
- Шляхи: меню — `menu/`, ходьба й машини — `sprites/`, пара — `vfx/`, дрон — `props/` поруч із якорями.

## Що відкладено

- Генерація смуги C (арени 360°, 155 кр.) і D (VFX, 76.25 кр.) — слово Santos на конкретний пакет; `balance` 5457.
- Арт у сцени (річка, якорі, дрон, діорама меню) — Гефест, план [[2026-10-03-Picks-to-Game-and-Animation]] § B2.

## Related
- [[Textures-Registry]] · [[Menu-Skyline-Prompts]] · [[Arenas-360-Prompts]] · [[2026-10-03-Picks-to-Game-and-Animation]] · [[2026-10-03-Apollon-Sprint-C-Prompts]] · [[state]]
