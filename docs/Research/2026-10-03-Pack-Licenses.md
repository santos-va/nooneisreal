# Ресерч — ліцензії паків Creative Trio і Quaternius Fantasy Props MegaKit (Ф0.2)

**Роль:** T3 Архімед · **Дата доступу до всіх джерел:** 2026-10-03 · **Крок:** Ф0.2 плану [[2026-10-03-Santos-Packs-Arenas]].
**Вердикт одним рядком:** обидва паки — **UNGROUNDED** за мірилом плану («цитата + URL + дата»). Для MegaKit усі
джерела збігаються на CC0, бракує лише дослівного тексту. Для Creative Trio джерела **розходяться за каналом
завантаження**: на сайті автора — безкоштовно під CC0, у сторах — платно під ліцензією стору. З якого каналу
Santos узяв свої 9 FBX — невідомо.

## Питання

1. Під якою ліцензією 9 FBX Creative Trio на гілці `textures/santos-pack` і пак Quaternius Fantasy Props MegaKit [Standard]?
2. Чи можна їх у комерційному релізі, чи потрібна атрибуція (рядок у титрах), чи можна ганяти через Higgsfield (NoAI)?

## Як перевірялось — і чого не вдалось (читати першим)

| що | команда / інструмент | вихід |
|---|---|---|
| сайти ліцензій | `curl -sS -m 15 <url>` для quaternius.com, quaternius.itch.io, itch.io, creativetrio.itch.io, fab.com, web.archive.org, store.godotengine.org | `curl: (56) CONNECT tunnel failed, response 403` на кожен |
| те саме через `WebFetch` | quaternius.com, creativetrio.art, opengameart.org, store.godotengine.org | `EGRESS_BLOCKED` на кожен |
| файл ліцензії в паках | `git ls-tree -r origin/textures/santos-pack tools/packs` | 10 файлів: 9 `.fbx` + `KayKit_Dungeon_Pack_1.1_EXTRA.zip`; **жодного `License*`** |
| ліцензія всередині FBX | `strings -n 6 <fbx> \| grep -iE "licen\|cc0\|http\|copyright\|patreon\|itch"` по 9 файлах | нічого, крім шляхів автора: `G:\Creative Trio\A_UPLOADED\<пак>\…blend`, `C:\Users\gendo\Desktop\Creative Trio\…` |
| MegaKit у репо | `git ls-tree -r --name-only origin/textures/santos-pack \| grep -i mega` | порожньо — пак ще не завантажено (Ф0.1) |

Отже, єдиний робочий канал — `WebSearch`: він повертає URL офіційної сторінки і **переказ** її змісту, не текст.
Усе в стовпці «що каже джерело» нижче — переказ видачі, а не цитата. Мірило Ф0.2 («цитата») цим не виконане.

## Quaternius Fantasy Props MegaKit [Standard]

| джерело (URL) | рівень | що каже джерело (переказ видачі, 2026-10-03) |
|---|---|---|
| https://quaternius.com/packs/fantasypropsmegakit.html | S | 200+ середньовічних пропів (зброя, інструменти, овочі, зілля, **ятки ринку**, скрині, меблі); Standard — **94 моделі**, CC0; «free to use in personal, educational and commercial projects (CC0 License)»; FBX, OBJ, glTF; 4 текстурні сети на всі 200 |
| https://quaternius.itch.io/fantasy-props-megakit | S | дзеркало сторінки; є Pro і Source за гроші |
| https://store.godotengine.org/asset/quaternius/fantasy-props-megakit/ · https://opengameart.org/content/fantasy-props-megakit | S | дзеркала; ліцензію в картках не відкрито |
| https://x.com/quaternius/status/1559299393177747456 | S | автор: «I make free asset packs with a CC0 license. You can even modify them or use them on your commercial projects!» (за видачею) |
| `License.txt` у zip UAL1/UAL2 того самого автора | R | CC0 — відкрито власноруч раніше, [[2026-10-03-Animation-Sources]] рядки 47–48, 164. Це **інший пак**, лише підтверджує звичку автора класти `License.txt` |

- Рівні: **S** — переказ WebSearch з URL офіційної сторінки; **R** — файл, відкритий у репо раніше.
- **Збіжність:** 4 незалежні канали (сайт, itch, Asset Store, OGA) + твіт автора + `License.txt` іншого паку — усі CC0. Розбіжностей не знайдено.
- **Комерційно:** так (CC0). **Атрибуція:** не потрібна. **Модифікація:** так. **ШІ / Higgsfield:** окремого пункту про ШІ у видачі **немає**; CC0 сам по собі такої заборони не містить. «Можна» спирається на природу CC0, а не на сторінку автора.
- **Статус:** `UNGROUNDED` лише за формою (немає дослівного тексту). Закривається одним кроком: `License.txt` із zip, який завантажить Santos (Ф0.1).

## Creative Trio — 9 FBX

### Що відомо про автора

| джерело (URL) | рівень | що каже джерело (переказ видачі) |
|---|---|---|
| https://creativetrio.art/ | S | stylized low-poly моделі для ігор, VR, Roblox; Patreon — ранній доступ і `.blend` |
| https://creativetrio.art/2021/03/11/stone-bridges-pack-01/ | S | Blend + FBX, «CC0 license … use in games without copyright concerns» |
| https://poly.pizza/bundle/Architecture-Pack-001-ntWKh7113q | S | інший пак того самого автора на Poly Pizza — CC0; «згадка сайту бажана, не обов'язкова» |
| https://sketchfab.com/3d-models/low-poly-stylized-stone-bridges-pack-01-ca9749a8af194b3bb880b3a79529d2a6 | S | **той самий** Stone Bridges Pack 01 у **Sketchfab Store** — «Buy Royalty Free», тобто платно під ліцензією стору, не CC0 |
| https://www.artstation.com/marketplace/p/OkOr2/stylized-low-poly-stone-bridges-pack-01 | S | той самий пак на ArtStation Marketplace (платно) |

### Пак за паком

Канали: **сайт** — сторінка на creativetrio.art; **стор** — платна сторінка (Sketchfab Store / ArtStation / Fab). «CC0 на
сайті» — лише там, де видача прямо так каже.

| наш файл | пак (з шляху в FBX) | сайт (URL) | CC0 на сайті | стор (URL) |
|---|---|---|---|---|
| `Stone_Bridges_01.fbx` | Stone Bridges Pack 01 | https://creativetrio.art/2021/03/11/stone-bridges-pack-01/ | **так** (видача) | Sketchfab Store, ArtStation (вище) |
| `Potions_Final_CT.fbx` | Potions 01 | https://creativetrio.art/2021/09/13/stylized-low-poly-potions-pack-01/ | **так** (видача: «free (CC0) download») | не знайдено |
| `Doors_Pack.fbx` | Doors | https://creativetrio.art/2021/03/25/stylized-low-poly-doors-pack-01/ | видача: «free», слова CC0 немає | не знайдено |
| `Wooden_Fences_01.fbx` | Wooden Fences Pack 01 | https://creativetrio.art/2021/02/25/wooden-fences-pack-01/ | не сказано | https://sketchfab.com/3d-models/stylized-low-poly-wooden-fences-pack-01-22113f7d6476462ca79d6006dc810ceb |
| `Trees_Pack_02.fbx` | Stylized Lowpoly Trees Pack 02 | https://creativetrio.art/2024/04/22/stylized-low-poly-trees-pack-02/ | не сказано | https://sketchfab.com/3d-models/stylized-low-poly-trees-pack-02-14ad2a6191bf4d79b0d84eb7ad389b25 |
| `Food_01_CT.fbx` | Food 01 | https://creativetrio.art/2022/08/15/stylized-low-poly-food-pack-01/ | не сказано | https://www.artstation.com/marketplace/p/WgRng/stylized-low-poly-food-pack-01 |
| `Wooden_Bridges_001.fbx` | Wooden Bridges Pack 01 | не знайдено | — | https://www.artstation.com/marketplace/p/9p76x/stylized-low-poly-wooden-bridges-pack-01 · https://www.fab.com/listings/83ace84d-8920-437d-a4b3-7dfaf07c5368 |
| `Rocks_01.fbx` | Rocks_01 | https://creativetrio.art/2025/05/18/stylized-low-poly-rocks-pack-01/ (чи це той самий пак — не перевірено) | не сказано | не знайдено |
| `Tables_Chairs_01.fbx` | Wooden Tables and Chairs 01 | не знайдено | — | не знайдено |

### Розбіжність — чому UNGROUNDED

1. **Два канали з різними ліцензіями.** Автор роздає паки безкоштовно під CC0 на сайті і продає ті самі паки в
   сторах. Ліцензія Sketchfab Store / ArtStation / Fab — не CC0: вона прив'язана до покупця. Файли Santos не несуть
   ознак каналу (немає `License`, немає URL у FBX).
2. **CC0 прямо підтверджено видачею лише для 2 з 9** (Stone Bridges, Potions). Для Doors — «free» без назви ліцензії;
   для решти 6 — нічого.
3. **ШІ / Higgsfield.** Для CC0-каналу окремого пункту про ШІ не знайдено. Для стор-каналу умови стору щодо ШІ
   (Sketchfab NoAI, Fab, ArtStation) **не перевірено**; для Sketchfab див. [[2026-10-03-Free-Cartoon-Texture-Sources]] № 11.
4. **Атрибуція.** Для CC0 — не обов'язкова («згадка бажана», переказ Poly Pizza). Для стор-ліцензій — не перевірено.

Що з цього випливає для плану, **без вибору** (вибір — Дедал і Santos):

| якщо Santos качав… | комерційно | титри | Higgsfield |
|---|---|---|---|
| з creativetrio.art безкоштовно і в zip лежить CC0 | так | не обов'язково | окремої заборони немає (природа CC0) |
| зі стору (купував) | за ліцензією стору, лише для покупця | не перевірено | **не перевірено** — до перевірки не ганяти |
| не пам'ятає, а `License` немає | UNGROUNDED | UNGROUNDED | не ганяти |

## Що лишилось відкрите і хто закриває

1. **Santos (Ф0.1, 2 хв):** сказати, звідки 9 FBX Creative Trio — сайт creativetrio.art (безкоштовно) чи стор
   (Sketchfab/ArtStation/Fab, купівля) — і докласти `License*.txt` з кожного zip під своїм іменем
   (`tools/packs/License_<пак>.txt`, як у плані § Як закинути пак). Те саме — `License.txt` із zip MegaKit.
2. **Будь-який термінал після п. 1:** `git show origin/textures/santos-pack:tools/packs/License_<пак>.txt` → цитата
   в цей бриф і в [[Textures-Registry]] (розділ «Паки-джерела», черга T6 0a). Тоді UNGROUNDED → GROUNDED.
3. До того — за [[ADR-013-License-Check-At-Release]] пак може зайти в `game/assets/` з рядком реєстру «до релізу
   (ADR-013)». **Окремо від ADR-013:** у Higgsfield файли Creative Trio не завантажувати, поки не відомо, що канал — CC0.
   Це обережність, а не вимога ліцензії; рішення — за Дедалом / Santos.
4. Pro / Source MegaKit не розглядались — у плані лише Standard.

## Доповнення — MegaKit закрито (T1 Дедал, 2026-10-03, за п. 2 «Що лишилось»)

Після завантаження Santos (`6210890`; після переписування гілки 2026-10-03 — `6bd36a2`) файл ліцензії є на гілці:
`git show origin/textures/santos-pack:tools/packs/Fantasy_Props_MegaKit_Standard/License_Standard.txt` →
«This is the standard FREE version of the Fantasy Props MegaKit … License: CC0 1.0 Universal (CC0 1.0) Public Domain
Dedication https://creativecommons.org/publicdomain/zero/1.0/». MegaKit [Standard] → **GROUNDED, CC0 1.0**.
Creative Trio — без змін, **UNGROUNDED**; за словом Santos 9 FBX **прибрано з гілки** разом з історією ([[2026-10-03-Santos-Packs-Arenas]] § Ліцензії паків).

## Related
- [[2026-10-03-Santos-Packs-Arenas]] · [[2026-10-03-T1-Santos-Packs]] · [[2026-10-03-Free-Cartoon-Texture-Sources]]
- [[2026-10-03-Animation-Sources]] · [[Textures-Registry]] · [[ADR-013-License-Check-At-Release]] · [[state]]
