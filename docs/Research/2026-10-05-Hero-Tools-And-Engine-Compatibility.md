# Інструменти обличчя, бою та сумісність рушія

**Дата доступу до джерел:** 2026-10-05. **Роль:** T3 Архімед.
**Питання:** чи дасть старший рушій потрібні інструменти для виразних героїв і кращої бойовки без пошкодження чинної гри?

## Відповідь

Досліджені джерела **не показали необхідного інструмента, заради якого треба знижувати Godot 4.7**. Рекомендація для рішення T1 — працювати з обличчям, матеріалом і бойовою презентацією на чинній версії. Умовний тест 4.6.3 має сенс лише після появи конкретної залежності, яка справді не працює на 4.7. Сумісність усіх сторонніх доповнень не перевірена; обіцянка «велика купа доповнень після відкату» — **UNGROUNDED**.

## Що виміряно в проєкті

До початку нових правок T1 зберіг попередню роботу в локальному commit `94a09a6` — `Implement responsive city grappling and bounded parkour`; поточна гілка `codex/character-expression-combat`. Commit перевірено через `git log`/`git show`. Це локальна точка відновлення, не підтвердження віддаленої резервної копії чи оновлення встановленого застосунку.

Пряме читання JSON/BIN усередині GLB, без імпорту рушієм:

| Модель | Вершини primitive POSITION | Joints | Morph targets | Вбудоване зображення |
|---|---:|---:|---:|---|
| `game/assets/characters/models/choko_m0.glb` | 28520 | 24 | 0 | JPEG 2048×2048 |
| `game/assets/characters/models/skea_m1.glb` | 33108 | 24 | 0 | JPEG 2048×2048 |

У списках кісток обох моделей є `Head`, `head_end`, `headfront`, але немає окремих контролів щелепи, повік, очей чи брів. Нуль morph targets означає, що просте викликання blend-shape API не створить міміку. Текстура 2048×2048 сама по собі не доводить достатньої деталізації обличчя: вона покриває всю модель, а вираз потребує авторських форм/контролів. `SkeletalRig.gd:57` також явно залишає `head_end`/`headfront` у rest; `SkeletalRig.gd:203` переносить albedo у toon-матеріал. Це обмеження поточних ассетів і презентації, а не встановлений дефект версії рушія.

Каталогу `game/addons`, `plugin.cfg`, `.gdextension` та секції `editor_plugins` у поточній грі не знайдено. `game/project.godot:17` задає `4.7`, `game/project.godot:274` — вбудований `Jolt Physics`. Через `--version` без запуску проєкту підтверджено локальні бінарі:

- `/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`: `4.7.stable.official.5b4e0cb0f`.
- `/usr/local/bin/godot`: `4.6.3.stable.official.7d41c59c4`.

## Потрібні засоби та реальна користь доповнень

| Потреба | Перевірене джерело / наявний засіб | Чи потрібен відкат |
|---|---|---|
| Моргання, брови, рот, реакція на біль/напруження | Godot 4.7 має `MeshInstance3D.set_blend_shape_value`; XML API та реалізація C++ узгоджені. Потрібні самі форми в mesh або окремо авторські поверхні/контроли. | Ні, для цього API. Чужий facial plugin без форм не виправить поточні GLB. |
| Авторські пози й перенесення анімації | Офіційний retargeting tutorial 4.7 описує `BoneMap`, `SkeletonProfileHumanoid`, rest alignment. У грі вже є `SkeletalRig` і `AuthoredCombatMotion`, останній зіставляє реальний кадр атаки з моментом контакту донорської анімації. | Не виявлено підстав. Час/контакт удару й читабельність треба авторувати та перевіряти. |
| Розумніші супротивники, дерева поведінки | LimboAI README: таблиця для `1.8.x` вказує GDExtension `Godot 4.6 or higher`, module `Godot 4.7`. | Немає підтвердженої ексклюзивної переваги 4.6. Реальний binary на наших Linux/macOS не тестувався. |
| Фізика, троси, ragdoll | Godot Jolt README: extension підтримує лише 4.3–4.6, але перебуває в maintenance mode після появи вбудованого модуля в Godot 4.4. Проєкт уже використовує модуль. | Сам факт старішої підтримки extension не є причиною міняти чинну фізику. Перевага його додаткових joint API для поточної задачі не продемонстрована. |

LimboAI README має неузгодженість: верхній короткий напис каже «Supported Godot Engine: 4.6», докладна таблиця вже містить module 4.7. Тут наведено обидва факти, а не оголошено неперевірену runtime-сумісність. Нативні доповнення також потребують окремих binary/експорту для цільових платформ. Жодного доповнення не встановлено, платних ассетів не згенеровано.

## Три варіанти

| Варіант | Результат і ціна | Умова вибору |
|---|---|---|
| Зберегти Godot 4.7; покращити наявні моделі/презентацію/бій | Зберігає чинну перевірену базу й Mac pipeline; робота йде прямо на скарги користувача. Не створює готового лицевого rig автоматично. | Рекомендований зараз: необхідного version blocker не знайдено. |
| Ізольована перевірка Godot 4.6.3 з конкретним addon | Дає порівняння конкретної функції, без зміни основного checkout. Вимагає окремого імпорту й регресій фізики/рендера/експорту. | Лише коли названий addon, точна версія/ліцензія і відтворюваний збій на 4.7 доводять користь. |
| Перехід на інший рушій або стару основну версію | Потребує перенесення GDScript, сцен, shader, hit-authority, importer і пакування. Наявність чужого marketplace не є доказом сумісного готового рішення для цих героїв. | Немає виміряного виграшу, який виправдовує таку міграцію в цій хвилі. |

Офіційна release policy у прочитаному зрізі гілки 4.7 позначає 4.7 і 4.6 як підтримувані, 4.8 — development. Вона рекомендує оцінювати зміну minor окремо, зберігати backup і перевіряти поведінку: виправлення фізики теж можуть її змінити. **Найновіший patch у кожній гілці не встановлено цим дослідженням**: GitHub releases API повернув network-policy 403; натомість читались офіційні raw-файли тегів `4.7-stable` та `4.6.3-stable`. Датовані оцінки roadmap не використано як обіцянку релізу.

## Залежності Mac і безпечний умовний тест

Рушій закріплено не лише в `project.godot`: `.github/workflows/ci.yml:9`, `.github/workflows/macos-main.yml:16`, `tools/distribution/install-local-macos.sh:55`, `tools/distribution/export-macos.sh:11`, metadata `tools/distribution/package-macos.py:47` та distribution tests. Installer завантажує саме editor/templates 4.7 і звіряє SHA512; export helper відхиляє іншу версію. `game/export_presets.cfg` задає macOS universal, обидві архітектури, мінімум macOS 12.0. Підміна одного executable не є завершеним відкатом або перевіреним Mac-пакетом.

Якщо з'явиться конкретна потреба, зворотний шлях такий:

1. Взяти погоджений commit і окрему копію/гілку, зберігши поточні незакомічені зміни. Не відкривати основний `game/` старішим редактором.
2. Окремі `.godot`, XDG/user data та сейви; окремий binary з перевіреним офіційним hash. Не використовувати реальні користувацькі сейви для запису.
3. Спершу мінімальна сцена конкретного addon на обох версіях; фіксувати версію/ліцензію/platform binary та однаковий сценарій. Без виграшу зупинити probe.
4. Тільки за наявності виграшу — ізольований імпорт гри, `make check`, `make gates`, playable, native обличчя/контакти/мотузка/cloth, окремий Mac universal export і backward save reading. Порівняти однакові сценарії та ресурси; успішний parse не доводить однакової фізики чи вигляду.
5. Узгоджено міняти всі pins лише після приймання. Відкат probe — повернутись до untouched основної копії та її 4.7; не намагатися «лікувати» спільний кеш повторними імпортами.

Цей probe не запускався: необхідної залежності не виявлено. Така перевірка зараз відволікала б від відсутніх facial controls і бойової читабельності.

## Джерела та відтворення

Зовнішні джерела прочитано 2026-10-05:

- [Godot 4.7 release policy](https://raw.githubusercontent.com/godotengine/godot-docs/4.7/about/release_policy.rst) — supported branches, minor/patch risk та backup.
- [Офіційний тег Godot 4.7](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/version.py) і [4.6.3](https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/version.py) — версії джерел; локальні executable перевірені окремо.
- [MeshInstance3D API, 4.7-stable](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/doc/classes/MeshInstance3D.xml) та [реалізація, 4.7-stable](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/scene/3d/mesh_instance_3d.cpp) — get/set blend shapes.
- [Retargeting, Godot docs 4.7](https://raw.githubusercontent.com/godotengine/godot-docs/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.rst) — bone rests, importer та застереження для аксесуарів.
- [LimboAI README](https://raw.githubusercontent.com/limbonaut/limboai/master/README.md) — версійна таблиця, GDExtension/module, MIT code та окрема CC BY 4.0 demo art.
- [Godot Jolt README](https://raw.githubusercontent.com/godot-jolt/godot-jolt/master/README.md) — extension 4.3–4.6, built-in з 4.4, maintenance та відсутність гарантії детермінізму.

Raw-знімки, SHA256 і статус кожного запиту: `/workspace/nooneisreal-evidence/hero-combat/engine-research/sources.json`. Структура GLB, SHA256 моделей, усі joint names та розміри JPEG: `hero-glb-audit.json` у тій самій теці. Файли `master` можуть змінитись після цієї дати; висновок стосується збереженого зрізу. Недоступні/404 джерела з manifest не використовуються для тверджень.

**Відкрито:** остаточна якість виразів у native close-up, приймання художнього напряму, Mac/M3 performance нових змін; runtime-сумісність будь-якого майбутнього addon; повноцінний авторський facial rig із morph targets. Дослідження не замінює ці перевірки.

## Related

- [[ADR-001-Engine-Godot]] · [[Architecture]] · [[Style-Guide]] · [[02-Combat-System]] · [[2026-10-05-Responsive-Parkour]] · [[state]]
