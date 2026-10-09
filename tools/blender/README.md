# tools/blender — пропи міста скриптами Blender

Парові машини та інші пропи Cronshift будуються детермінованими скриптами Blender. Кредитів вони не потребують
(`docs/Decisions/ADR-027-City-Modern-Props-Style-And-Path.md`, поправка «Blender замість Meshy»). Blender — лише
інструмент розробника: **у збірку гри він не входить**. Гра бачить тільки готовий `.glb` у `game/assets/props/city/`.

## Ліцензія

Скрипти цієї теки імпортують `bpy` (Blender, `pip show bpy` → `License: GPL-3.0`), тому вони поширюються під
**GPL-3.0-or-later** — рядок `SPDX-License-Identifier` на початку кожного файла (рішення Santos 2026-10-09,
аудит T4 `docs/Audit/2026-10-09-Rope-Jump-Momentum-Tidy-Steamcars-Review.md` п. 6). Готові `.glb` — результат роботи
інструмента, а не похідний код; їхня ліцензія в реєстрі ассетів не змінюється. Решта репозиторію цим не зачеплена.

## Встановлення (один раз, ~1 ГБ)

Blender ставиться як модуль Python у віртуальне середовище. Колесо `bpy` прив'язане до версії Python, з якою
зібраний Blender: `bpy 5.2.2` встановилось під Python **3.13** (перевірено 2026-10-09:
`bpyvenv/bin/python --version` → `Python 3.13.16`). Каталог середовища важить
`du -sh bpyvenv` → 1008M. Тримайте його поза репозиторієм (scratchpad або `~/.venvs`).

```bash
python3.13 -m venv ~/.venvs/bpy
~/.venvs/bpy/bin/pip install bpy==5.2.2
~/.venvs/bpy/bin/python -c "import bpy; print(bpy.app.version_string)"   # → 5.2.2 LTS
```

У контейнері без `libEGL.so.1` рушії Workbench і Eevee не стартують. Превʼю тому рендерить Cycles на CPU.
Експорт GLB від цього не залежить.

## Запуск

```bash
~/.venvs/bpy/bin/python tools/blender/steam_truck.py          # → game/assets/props/city/prop_steam_truck_v1.glb
~/.venvs/bpy/bin/python tools/blender/steam_car_tarp.py       # → game/assets/props/city/prop_steam_car_tarp_v1.glb
# опції: --out ІНШИЙ.glb (наприклад у scratchpad), --preview ТЕКА (PNG Cycles: 3/4, бік, фронт, силует)
```

Скрипт друкує рядки `PROP_OK`, `PROP_SIZE`, `PROP_MESH`, `PROP_MATERIAL` і `PROP_COLLIDER`: sha256 файлу, розміри,
трикутники, матеріали й колайдери. Рядок `ERROR MeshOptimizer is not available` іде від експортера glTF. Він стосується
лише стиснення meshopt, яке ми не вмикаємо, і на файл не впливає.

Після нового GLB: `make check`. Його крок `--import` створює `.glb.import`. Потім рядок у
`docs/Art/Textures-Registry.md`, далі `make gates`.

## Правила скриптів

- **Детермінізм.** Жодних випадкових чисел, часу чи налаштувань користувача: сцена стартує з factory settings, геометрія
  пишеться `bmesh` у явних координатах. Два прогони дають той самий sha256 (журнал
  `docs/Fix/2026-10-09-Blender-Steam-Vehicles-Fix.md`).
- **Осі й масштаб.** У Blender +X праворуч, +Y — перед пропу, +Z угору, а початок координат лежить на землі під центром
  сліду. Експортер glTF перетворює +Y на Godot −Z (forward `Node3D`). Метри реальні, трансформи застосовані:
  у Godot масштаб об'єктів 1, тож Jolt не скаржиться на масштабовані тіла.
- **Матеріали.** Імена — ключі `game/scripts/world/CityMaterials.gd`, hex береться з того самого файлу
  (`prop_kit.city_palette()`). Гра може замінити кожну поверхню міським шейдером `city_surface` за `resource_name`.
  `iron_paint` = `#577368` (фарбований чавун ADR-027) — ключ `CityMaterials.gd` з 2026-10-09; `prop_kit.EXTRA_KEYS` порожній.
- **Колізія.** Окремі об'єкти `<Name>-convcolonly`. Імпортер сцен Godot 4.7 робить з кожного `StaticBody3D` з одним
  `ConvexPolygonShape3D` і прибирає видимий меш (`editor/import/3d/resource_importer_scene.cpp`,
  `_teststr(name, "convcolonly")`). Шар тіла — типовий 1. Шар міста ставить код розміщення.
- **Нормалі.** Усе згладжено, гострі ребра — від 40° (`AUTO_SMOOTH_DEG`). Циліндри з 10 і більше сегментами та
  тканина виходять гладкими, ребра коробок лишаються пласкими: одна чиста межа світла й тіні шейдера міста.
- **Стиль** — каталог T6 `docs/Art/2026-10-08-City-Modern-Realism-Props.md`: П1–П8, К1–К11, заборони. Літер і цифр
  немає, орнаменту на машинах немає, латунь — лише там, де можна торкатись.

## Файли

| файл | що |
|---|---|
| `prop_kit.py` | спільне: палітра з `CityMaterials.gd`, `Builder` (коробки, циліндри, кільця, лофт, спицеве колесо), колайдери, експорт, превʼю |
| `steam_truck.py` | № 9 «Паромобіль-вантажівка», канон `sprite-steamcars-v1` (права машина) і текст картки V1 (`docs/Art/Prompts/City-Props-Prompts.md`) |
| `steam_car_tarp.py` | № 29 «Легковик-паровик під брезентом», канон `sprite-steamcars-v1` (ліва машина), бриф T7 О9 |
