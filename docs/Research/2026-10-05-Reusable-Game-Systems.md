# Готові системи для міста, NPC, анімацій і фізики

**Дата доступу:** 2026-10-05. **Роль:** T3 Архімед. **Завдання:** знайти перевірені компоненти, які скорочують рутинну розробку. Це дослідження й передача T1/T2, а не повідомлення про встановлення плагінів.

## Відповідь

Найкоротший шлях у цьому пакеті — використати вже підключені UAL1/UAL2 та Jolt, виправити рух і розміщення NPC, а наступну навігацію будувати на вбудованій системі Godot. Для складніших NPC є перевірені кандидати **Beehave v2.9.3** і **LimboAI v1.8.1**; для розстановки декору — **ProtonScatter**. Знайдений готовий генератор міста потребує іншого стека й окремого ліцензійного рішення, тому швидкою підстановкою не є.

Факти нижче перевірено читанням робочого дерева й публічних GitHub README, LICENSE, release API через GitHub connector. Сумісність, заявлена автором, не означає, що плагін запущено в нашій грі. Жодного зовнішнього пакета цим дослідженням не додано.

## Що вже є в грі

Знімок до змін паралельних агентів, база `66d53536536ef590c97a3d22ee8797611f03fbcb`:

| Компонент | Перевірене місце | Наслідок |
|---|---|---|
| Godot 4.7 і Jolt | `game/project.godot:17`, `:274`: `config/features` містить `4.7`, `3d/physics_engine="Jolt Physics"` | Додатковий фізичний backend для самого факту покращення фізики не потрібен. Потрібно перевіряти конкретні колізії й обмеження мотузки. |
| UAL1 та UAL2 | `game/scripts/fighter/SkeletalRig.gd:25–26`, `:96–106`: GLB завантажуються, друга бібліотека додається в AnimationPlayer | Скелетний програвач і бібліотеки вже інтегровані; основна робота — вибір кліпів, змішування, прив'язка контакту до кадру удару. |
| Реальні кліпи | JSON-чанки `game/assets/animations/ual/UAL1.glb` і `UAL2.glb`: **120 + 134 = 254** записи `animations` | Є `Kick`, `BackFlip`, `Dodge_Left/Right`, `Melee_Knee`, `Sword_Aerial_A/B`, `Sword_UpperCut`, `Sword_Light_A..D`, `Sword_Heavy_A..D`; повторно купувати пак для цих назв не потрібно. Наявність назви не доводить художню якість конкретного удару. |
| Ліцензія поточних UAL | [[Textures-Registry]], рядки `anim-ual1`, `anim-ual2`: записано CC0 1.0 і купівлю Source Santos | Реєстр прочитано зараз; вихідний `License.txt` купленого zip у цьому checkout не знайдено й повторно не прочитано. Нової незалежної перевірки ліцензії придбаного архіву тут немає. |
| NPC | `CityNpcActor.gd` задає домашню точку й синусоїдальне зміщення; `CityNpcDirector.gd` включає рух лише для цілі `гуляє районом` | На цій базі немає повноцінного пошуку маршруту. Саме додавання behavior tree не виправить розміщення, колізії чи порожні маршрути. |
| Набори декору | [[Textures-Registry]] містить KayKit Dungeon і Quaternius Fantasy Props на історичній гілці `textures/santos-pack`; `tools/packs` у checkout відсутня | Не називати ці архіви вже встановленими. Спочатку звірити доступність гілки, самі файли й ліцензії. |

SHA-256 локальних GLB, обчислені Python у цій сесії:

- UAL1: `d1cb4537efa4c06a953ca951e5935062f88c2580ac68e45045592d587bddb43d`.
- UAL2: `ad3ae049c7d3d4846133b59dba6218fdabebe05d3aec646caef6665f6c540684`.

## Перевірені зовнішні кандидати

| Потреба | Джерело, версія та ліцензія | Що дає | Робота та межі |
|---|---|---|---|
| Навігація NPC | Godot `NavigationAgent3D`; [опис API в сирцях](https://github.com/godotengine/godot/blob/master/doc/classes/NavigationAgent3D.xml), [офіційний посібник у репо](https://github.com/godotengine/godot-docs/blob/master/tutorials/navigation/navigation_using_navigationagents.rst), [MIT рушія](https://github.com/godotengine/godot/blob/master/LICENSE.txt). Прочитано `master`, не версійну 4.7-документацію. | Пошук шляху, слідування маршруту, RVO-уникання. Уже частина рушія. | Потрібні навігаційні дані кварталу, коректний spawn, рух тіла й відновлення після застрягання. Повна реалізація для цього кварталу не перевірена; версійний API звірити із встановленим Godot перед міграцією. |
| Дерева поведінки | [Beehave v2.9.3](https://github.com/bitbrain/beehave/releases/tag/v2.9.3), [README](https://github.com/bitbrain/beehave/blob/godot-4.x/README.md), [MIT LICENSE](https://github.com/bitbrain/beehave/blob/godot-4.x/LICENSE) | Дерева в сцені, runtime debugger, монітори; повторне використання поведінки між NPC. | Release notes прямо заявляють Godot 4.7 і фікс конфлікту singleton у 4.7.1. Таблиця поточного README має іншу нумерацію сумісності (`2.10+` для `4.5+`), тому pin саме перевіреного release й локальний import/export тест обов'язкові. Мігрувати один сценарій: ходить → чекає → розмовляє. |
| Складні NPC / HSM | [LimboAI v1.8.1](https://github.com/limbonaut/limboai/releases/tag/v1.8.1), [README](https://github.com/limbonaut/limboai/blob/master/README.md), [MIT LICENSE.md](https://github.com/limbonaut/limboai/blob/master/LICENSE.md) | Behavior trees, hierarchical state machines, blackboard, debugger; custom tasks на GDScript. | C++ module або GDExtension. Release оновлює engine builds до 4.7.2; API assets містить macOS universal editor і export templates. Extension zip названо `gdextension-4.6`; README для 1.8.x заявляє extension 4.6+ / module 4.7. ABI, headless та експорт саме нашого проєкту не перевірені. Вища вартість підтримки бінарних платформ; не ставити одночасно з Beehave. |
| Розстановка декору | [ProtonScatter README](https://github.com/HungryProton/scatter/blob/main/README.md), [`plugin.cfg` 4.2.0](https://github.com/HungryProton/scatter/blob/main/addons/proton_scatter/plugin.cfg), [MIT LICENSE.md](https://github.com/HungryProton/scatter/blob/main/LICENSE.md) | Розкладка предметів за правилами, область Box/Sphere/Path, від'ємні області, проєкція на поверхні. | Версія **плагіна** 4.2.0, README заявляє Godot 4 без окремої гарантії 4.7. Перший пілот — дрібний декор поза шляхами гравця/NPC. Перевірити колізії, seed, export і кількість екземплярів. Демо-текстури мають окремі обмеження Textures.com; MIT коду не покриває їх автоматично. |
| Запасний набір анімацій і NPC-моделей | [KayKit Adventurers 1.0 README](https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/blob/main/README.md), [LICENSE.txt: CC0](https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/blob/main/LICENSE.txt) | README заявляє 4 моделі, 75 анімацій, FBX/glTF, спільний атлас. Файл ліцензії прямо дозволяє комерційні проєкти. | Кількість — за README, не розбір завантажених GLB. Не пряме оновлення наших Meshy/UAL-героїв: потрібні перевірка скелета, ретаргет і стилізація Sketch-Cel. Корисніше як тестовий actor/референс, ніж нова залежність у поточному animation fix. |
| Заміна фізики | [Godot Jolt README](https://github.com/godot-jolt/godot-jolt/blob/master/README.md) | Окремий native extension; автор зазначає інтеграцію Jolt у рушій із 4.4. README заявляє MIT. | Окремий extension у maintenance mode, діапазон підтримки README — 4.3–4.6. У нас Jolt уже активний. Не ставити extension поверх поточного backend. README також не гарантує детермінізм; це не підстава переносити визначення влучань у фізику. |
| Цілий генератор міста | [Procedural City Generator README](https://github.com/Carl0sCheca/Procedural-City-Generator-Godot/blob/main/README.md), [LICENSE: GPL v3](https://github.com/Carl0sCheca/Procedural-City-Generator-Godot/blob/main/LICENSE) | Генерація вуличної структури; README посилається на release v1.0. | Автор перевіряв **Godot Mono 4.2.1**. Наш стек GDScript/4.7; потрібна міграція та розгляд copyleft-умов для похідного коду. Не включати в поточний пакет без окремого рішення; можна вивчати як приклад планування вулиць. |

Оцінки «нижча/вища вартість» — інженерна оцінка обсягу інтеграції, не виміряні години. FPS, економію часу й стабільність цих плагінів на M3 не виміряно.

## Практичний порядок передачі

1. **Поточний пакет:** вибрати готові UAL-кліпи для бойових рухів, перевірити весь цикл startup/contact/recovery та обидві моделі. Рух кореня й шкода залишаються під контролем чинної логіки. Ліцензійні й asset registry записи наявних файлів не змінювати на підставі цього брифа.
2. **Поточний пакет NPC:** виправити унікальні доступні spawn/маршрутні точки, видимий рух, уникання скупчення та взаємодії. Для маленького фіксованого кварталу обмежений маршрутний граф може бути меншим виправленням; це вибір T1/T2 після перевірки геометрії.
3. **Наступний пілот навігації:** NavigationAgent3D на одному actor з робочими навігаційними даними. Перевірити старт після синхронізації map, повторний spawn/streaming, вузький прохід, блокування шляху та повернення до розмови. Пошук маршруту не переносить батьківський Node автоматично — це прямо вказано в посібнику.
4. **Якщо поведінки ростуть:** один із Beehave/LimboAI, зафіксований tag/commit, LICENSE поруч із кодом, smoke-тест завантаження/вивантаження та export. На просту помилку spawn встановлення behavior tree не впливає.
5. **Декор:** ProtonScatter на одній ділянці з власними/перевіреними моделями, без демо-текстур. Тільки після оцінки прохідності й відображення в нашому стилі розширювати район. Для кожного нового файла в `game/assets/` потрібен рядок у [[Textures-Registry]].

## Відкриті питання й межі доказів

- Не встановлено й не запущено жоден кандидат; усі твердження про сумісність зовнішніх пакетів належать їхнім README/releases.
- Godot navigation sources прочитано з `master`. Це підтверджує загальний контракт двома офіційними файлами, але не є незалежним тестом Godot 4.7 у нашому build.
- Первинні архіви куплених UAL і історичних props-паків тут не прочитані; ліцензійні факти про них походять із наявного реєстру, на відміну від щойно відкритих LICENSE зовнішніх кандидатів.
- Немає підтвердженої оцінки retarget якості KayKit на наші Meshy-скелети. Вбудовані UAL вже мають адаптер; змінювати його заради ще однієї бібліотеки до конкретної нестачі кліпів не потрібно.
- Тести коду й інтеграційне приймання виконує T2/T4 для загального PR. Цей бриф перевіряється як документація, а не як реалізована інтеграція.

## Related

- [[2026-10-03-Animation-Sources]] · [[2026-10-03-Animation-Holes-UAL-vs-Meshy]] · [[2026-10-04-Free-Movement-Animation]]
- [[Textures-Registry]] · [[2026-10-03-Pack-Licenses]] · [[ADR-004-Physics-Is-Presentation]] · [[Architecture]]
