# Ресерч — вільні cartoon/stylized текстури й пропи для арен (2026-10-03)

**Роль:** T3 Архімед (суб-агент лише на читання; файл записує головна сесія без зміни змісту). Дата доступу до всіх джерел — **2026-10-03**.
**Запит Santos:** «закинути мені сайти з паками текстур 3D в нашому cartoon стилі, які можна вільно взяти й використати, а потім ще й доробити з хігсфілд свої».
**Статус:** список джерел і ліцензій. Що з цього пасує стилю, вирішує Аполлон ([[Style-Guide]], [[ADR-007-Art-Style-Sketch-Cel]]); кредити витрачаються тільки після слова Santos.

## Питання

1. Де взяти безкоштовні текстури (бруківка, дошки, цегла, метал) і пропи (ятки, ящики, ліхтарі, лавки) у stylized / toon / hand-painted / low-poly стилі для [[Stage-Bazaar]], [[Stage-Fountain]], [[Stage-River]], щоб їх можна було використати в комерційній грі?
2. Що кожна ліцензія каже про комерційне використання, модифікацію, проганяння через генеративний ШІ, атрибуцію й перепродаж?
3. Якими інструментами Higgsfield це доробляти в наш стиль?

## Як перевірялось — і чого НЕ вдалось (читати першим)

- **Офіційних сторінок ліцензій у цій сесії не відкрито жодної.** `curl -sSL https://kenney.nl/support` → `curl: (56) CONNECT tunnel failed, response 403`. Те саме для quaternius.com, polyhaven.com, ambientcg.com, opengameart.org, poly.pizza, sketchfab.com, textures.com, kaylousberg.com, itch.io. `WebFetch` на kenney.nl, polyhaven.com, quaternius.com, docs.ambientcg.com, creativecommons.org, itch.io, sketchfab.com, higgsfield.ai → `EGRESS_BLOCKED`.
- **Єдиний робочий канал — `WebSearch`.** Він повертає URL офіційної сторінки та переказ її змісту, а не текст сторінки. Тому всі «цитати» нижче — **переказ пошукової видачі**, а не дослівний текст ліцензії. Вимога «ліцензія ДОСЛІВНО» у цій сесії **не виконана** для жодного джерела.
- **Що підтверджено з першої руки раніше** (не в цій сесії): `License.txt` → CC0 у zip Kenney, KayKit і Quaternius UAL. Звідти ж: [[2026-10-03-Animation-Sources]] § «Перевірено власноруч», `tools/audio/sfx_sources.tsv:18`. Це паки анімацій і звуку, **не** паки пропів/текстур нижче.
- Zip-и UAL у scratchpad (`ualtest/dl/*.zip`) — тестові фікстури на 3,3 КБ (`ls -la` → 3303–3306 байт), а не справжні паки. Як доказ їх не використано.
- Позначки у стовпці «рівень доказу»:
  - **S** — лише переказ WebSearch з URL офіційної сторінки;
  - **S+R** — плюс давніша перевірка `License.txt` у репо (для інших паків того самого автора).
- Перед імпортом у `game/assets/` треба відкрити сторінку ліцензії (або `License.txt` у завантаженому zip) і вписати її в [[Textures-Registry]]. Ворота — реліз, за [[ADR-013-License-Check-At-Release]].

## Таблиця джерел

| # | джерело · URL | що там | ліцензія (за видачею) · сторінка ліцензії | комерційно | модифікація / ШІ | атрибуція | обмеження | стиль під нас | доказ |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Kenney** — https://kenney.nl/assets/category:3D/ ; паки Fantasy Town Kit (160), City Kit Commercial / Roads / Suburban, Survival Kit (80) | моделі (низькополі, пласкі кольори, атлас) | CC0 — https://kenney.nl/support: «all game assets … are public domain licensed (CC0) … free to use, even in commercial projects» (переказ) | так | так; CC0 не має заборони на ШІ (за видачею — окремого пункту про ШІ немає) | не потрібна («Kenney» — за бажанням) | — | пропи придатні як блокінг/база; надто «іграшкові», без контуру — потрібен наш toon-шейдер | S+R |
| 2 | **Quaternius** — Fantasy Props MegaKit (200+ пропів: ятки ринку, скрині, меблі; 4 текстурні сети), Medieval Village MegaKit (300+ модульних шматків), Stylized Nature MegaKit (110+, «ghibli style»), Downtown City MegaKit — https://quaternius.com/packs/fantasypropsmegakit.html та ін. | моделі (stylized low-poly) | CC0 — «free to use in personal, educational and commercial projects (CC0 License)» (переказ сторінок паків); окремої сторінки FAQ відкрити не вдалось | так | так; про ШІ окремого пункту не знайдено | не потрібна | безкоштовна лише частина паку (Standard), решта — Pro/Source за гроші | **найкращий кандидат на пропи базару** (ятки, ящики, бочки); фактура пласка — лягає під cel | S+R |
| 3 | **KayKit (Kay Lousberg)** — City Builder Bits (32+ моделі, атлас-градієнт 1024²), Resource Bits та ін. — https://kaylousberg.com/game-assets/city-builder-bits · https://github.com/KayKit-Game-Assets/KayKit-City-Builder-Bits-1.0 · Godot Asset Library #2123 | моделі (low-poly, градієнтний атлас) | CC0 — «free for personal and commercial use with no attribution required … CC0» (переказ) | так | так | не потрібна | — | атлас-градієнт легко перефарбувати в нашу палітру; сучасне місто — не всі пропи пасують | S+R |
| 4 | **Poly Pizza** — https://poly.pizza (бандли, напр. Stylized Nature MegaKit, City Pack) | моделі (агрегатор low-poly) | **змішана**: кожна модель — CC0 або CC-BY 4.0; формат кредиту для CC-BY — «"[Title]" by [Username] (poly.pizza) CC-BY 4.0» (переказ). Окремої сторінки ліцензії не знайдено | так (обидві) | так (CC0/CC-BY дозволяють похідні) | **CC-BY — обов'язкова**, CC0 — ні | ліцензію перевіряти **на кожній моделі** | low-poly, різні автори → різнобій стилю | S |
| 5 | **StylizedTextures.com** — https://stylizedtextures.com · terms: https://stylizedtextures.com/terms.html · FAQ: https://stylizedtextures.com/faq | **текстури**, stylized PBR, 4K, безшовні (BaseColor/Normal/Roughness/Metallic/AO/Height) | CC0 (переказ terms/FAQ і BlenderNation 2025-11-04) | так | так; за видачею, сайт прямо пише, що контент «available for AI training» | не потрібна | вихідники — лише Patreon | **прямо наш профіль** — stylized бруківка/цегла/дошки; PBR-карти для cel не потрібні, беремо BaseColor | S |
| 6 | **Lynocs Stylized Texture Pack** — https://lynocs.itch.io/texture-pack | **текстури**, 536 (464 унікальні + 72 варіації кольору): дошки, бруківка, метал; diffuse/AO/normal/smoothness | CC0 (переказ сторінки itch) | так | так | не потрібна («credit is nice») | «should not be sold as-is» — не перепродавати як ассет | stylized, пласкі — добрий кандидат на підлогу базару й набережну | S |
| 7 | **Kalponic Studio — Painterly Textures Vol. 3 (Freemium)** — https://kalponic-studio.itch.io/painterly-textures-vol-3 ; також https://kalponic-studio.itch.io/free-stylized-textures | **текстури**, hand-painted, тайлові; безкоштовно 20 шт., лише BaseColor | free-версія — CC0 (переказ); повна (400 шт., $24.99) — ліцензія **не перевірена** | так (free) | так (free) | не потрібна (free) | — | painterly/«Ghibli» — ближче до живопису, ніж до cel; як основа під Higgsfield-перемальовку годиться | S |
| 8 | **3DTextures.me** — https://3dtextures.me/category/stylized-textures/ · ліцензія: https://3dtextures.me/about/ | текстури; є категорія Stylized (напр. Stylized Wood Planks), основна маса — реалістичні | CC0: «use … for any purpose, including commercial … do not need to give credit … can redistribute» (переказ) | так | так | не потрібна | — | частково: лише розділ Stylized | S |
| 9 | **FreeStylized.com** — https://freestylized.com · умови: https://freestylized.com/disclaimer/ | текстури stylized (Cobblestone 01, Bricks Wall 12, Metal 01, Roof Tiles 09…), скайбокси | **«custom CC0»** (переказ): комерційне без дозволу, але заборонено перепоширювати з чужою атрибуцією й викладати на маркетплейси без «key modifications»; Patreon-контент — не CC0 | так | модифікація так; **про ШІ — UNGROUNDED** (у видачі нічого) | не потрібна | не CC0 у чистому вигляді — див. ліворуч | дуже близько до stylized-гри; перевірити disclaimer дослівно | S |
| 10 | **OpenGameArt** — https://opengameart.org · FAQ: https://opengameart.org/content/faq ; підбірки: «Assets: Stylized Hand-Painted», «handpainted brick texture pack», «CC0 Textures» | обидва, різні автори | **на кожному ассеті своя**: CC0 / OGA-BY / CC-BY / CC-BY-SA / GPL. За FAQ (переказ): усі можна в комерційній грі; CC0 і OGA-BY — найбезпечніші для закритого коду; GPL — лише якщо готові відкрити проєкт | так (крім застережень GPL/SA) | CC0 — без обмежень; CC-BY має пункт проти DRM (за FAQ OGA) | CC-BY / OGA-BY / SA — **обов'язкова** | фільтрувати лише CC0 / OGA-BY; уникати GPL і CC-BY-SA | різнобій якості; брати поштучно | S |
| 11 | **Sketchfab** (фільтр Downloadable + CC0 / CC-BY) — https://sketchfab.com/licenses ; блог: https://sketchfab.com/blogs/community/restricting-generative-ai-use-of-free-models/ | моделі, є stylized/hand-painted (напр. «Free brick hand painted stylized texture» від Scritta) | CC0 або CC-BY на кожній моделі (переказ) | так | CC дозволяє похідні. **Тег NoAI**: Sketchfab прямо пише, що на CC-моделях він «may not be enforceable outside of the Sketchfab platform» — **моделі з NoAI у Higgsfield не завантажувати** (наш конс. вибір, не вимога ліцензії) | CC-BY — **обов'язкова** | Standard License (не CC) — не вільна, не брати | змішано; є гарні hand-painted | S |
| 12 | **Poly Haven** — https://polyhaven.com · https://polyhaven.com/license | текстури, HDRI, моделі | CC0 — «all licensed as CC0, which is effectively Public Domain» (переказ); «no warranty or indemnification» | так | так; за видачею, Poly Haven прямо згадує використання AI-дослідниками | не потрібна | — | **фото-скан, не stylized** (вимога до контриб'юторів — фотограмметрія). Хіба що як вхід для Higgsfield-стилізації | S |
| 13 | **ambientCG** — https://ambientcg.com · https://docs.ambientcg.com/license/ | текстури PBR, HDRI, моделі | CC0 1.0: «copy, modify, distribute and perform … even for commercial purposes, all without asking permission» (переказ) | так | модифікація так; про ШІ на docs.ambientcg.com у видачі **нічого** → лише загальний CC0 | не потрібна | — | **фото / процедурне, не stylized** — як Poly Haven | S |
| 14 | **Godot Asset Library / Asset Store** — https://store.godotengine.org (Quaternius Fantasy Props / Medieval Village / Stylized Nature MegaKit; «Lowpoly Street Props» від polybuild — **MIT**, онов. 2026-06-06) · https://godotengine.org/asset-library/asset/2123 (KayKit City Builder Bits) | моделі, вже під Godot | ліцензія — на картці кожного ассету (CC0 для Quaternius/KayKit, MIT для Lowpoly Street Props — за видачею) | так | так (MIT: зберегти текст ліцензії) | MIT — **текст ліцензії в збірці** | дзеркало тих самих паків | зручно ставити прямо в проєкт | S |
| 15 | **Textures.com** — https://www.textures.com/support/faq-license · ToS: https://www.textures.com/static/terms/TexturesCom%20-%20Terms%20of%20Service%20Rev3-21.pdf | текстури (фото) | **не CC0, власна ліцензія.** У грі використовувати можна, перепродавати/віддавати як ассети — ні. ToS забороняє використання Контенту «in connection with deep learning, machine learning … or other artificial intelligence technologies» (переказ видачі) | так (у грі) | **ШІ — заборонено** → з Higgsfield несумісне | — | перепоширення заборонене | **НЕ ПІДХОДИТЬ**: фото + заборона ШІ | S |

## Що з цього брати під арени (лише факти для вибору Аполлона)

- **Текстури підлоги, бруківки, цегли й дощок, уже stylized і CC0:** №5 StylizedTextures, №6 Lynocs, №7 Kalponic (free), №8 3DTextures (розділ Stylized). №9 FreeStylized — після дослівного читання disclaimer.
- **Пропи базару й площі** (ятки, ящики, бочки, лавки, ліхтарі): №2 Quaternius Fantasy Props + Medieval Village, №1 Kenney Fantasy Town Kit, №3 KayKit.
- **Тільки як сировина для стилізації:** №12 Poly Haven, №13 ambientCG (фото).
- **Не брати:** №15 Textures.com; моделі Sketchfab із тегом NoAI; ассети OGA під GPL і CC-BY-SA.
- **З атрибуцією** (за кожен — рядок у титрах і в [[Textures-Registry]]): CC-BY з Poly Pizza, Sketchfab, OGA; MIT з Asset Store.

## Як поєднати з Higgsfield

Що підтверджено **в репо** (першоджерело — попередні сесії, тут не перевиконувалось):
- Безшовну текстуру Higgsfield уже робив промптом: `tex_water_foam.png` і `tex_water_ripple.png`, `nano_banana_pro`, 2048×2048 ([[Textures-Registry]] рядки 100–101, `grep -n tex-water docs/Art/Textures-Registry.md`).
- Готового workflow «Texture Tile Factory» у каталозі **немає**. Безшовність — звичайним промптом плюс перевірка шва локально ([[Higgsfield-Pipeline]] рядок 68).
- Інструменти доробки, доступні з каталогу ([[Higgsfield-Pipeline]] рядки 61–62):
  - генерація й редагування з референсом: `gpt_image_2_5`, `nano_banana_pro`, `flux_3_image` (до 10 референсів);
  - outpaint: `outpaint`, `flux_2_pro_outpaint`; рядок 52 — сабміт `flux_2_pro_outpaint` → `422` п'ять разів;
  - апскейл: `topaz_image`, `bytedance_image_upscale`.
- `nano_banana_2` має роль `mask` і параметр `is_inpaint` ([[Higgsfield-Pipeline]] рядок 54). Це локальне перемальовування ділянки текстури.
- Пропи: `multi_image_to_3d` / `image_to_3d` (Meshy) — 3D з картинки ([[Higgsfield-Pipeline]] рядки 27, 38).

Що каже **відкритий веб** (лише WebSearch, сторінки не відкрито):
- Higgsfield Help Center «Who owns my generations…» — https://higgsfield.ai/creator-hub/help-center/account/who-owns-my-generations-and-can-i-use-them-commercially. Переказ: Higgsfield не претендує на inputs і outputs і не обмежує комерційне використання outputs. Хто завантажує референси, відповідає за права на них.
- **Free plan: «no commercial use»** — так пишуть сторонні блоги (krea.ai, creatify.ai), не офіційна сторінка → **UNGROUNDED**, поки не прочитано ToS.
- Nano Banana Pro Inpaint — https://higgsfield.ai/blog/Top-Editing-Tool-in-2025-Nano-Banana-Pro-Inpaint: перемальовує лише замасковану ділянку.

Ланцюжок, що випливає з фактів вище (рішення — за Аполлоном):
1. CC0 stylized-текстура (№5–8) або фото CC0 (№12–13) як референс.
2. `nano_banana_pro` / `gpt_image_2_5` з промптом стилю з [[Style-Guide]] / [[Prompt-Library]]: пласка заливка, одна тінь у маджента, контур `#2B2230`.
3. Перевірка шва локально.
4. Апскейл `topaz_image`.
5. Рядок у [[Textures-Registry]] з **обома** джерелами: вихідний пак + модель Higgsfield.

CC0 дозволяє такий вхід без умов. CC-BY дозволяє похідну, але атрибуцію автора доведеться зберегти й на похідній. Textures.com і моделі з NoAI — не вхід.

## UNGROUNDED / відкрите

1. **Дослівний текст ліцензії — ні для одного джерела.** Офіційні сторінки заблоковані egress-проксі (див. вище). Усі формулювання — переказ WebSearch.
2. FreeStylized.com — «custom CC0»: точний текст обмежень і чи дозволено ШІ — невідомо.
3. ambientCG, Quaternius, Kenney, KayKit — прямого пункту про генеративний ШІ у видачі немає. Висновок «можна» спирається на загальну природу CC0, а не на їхні сторінки.
4. Kalponic Painterly Vol. 3, повна платна версія — ліцензія не перевірена.
5. Poly Pizza — окремої сторінки ліцензії сайту не знайдено. Ліцензію видно лише на картці моделі.
6. Higgsfield free plan «no commercial use» — лише сторонні джерела; офіційні ToS не відкривались.
7. Textures.com — заборона ШІ взята з видачі по PDF ToS Rev3-21. Чинність саме цієї ревізії на 2026-10-03 не перевірена.

**Наступний крок (для того, хто має доступ до мережі, напр. Mac Santos):** відкрити сторінки ліцензій №1–3, 5–9 і `License.txt` у кожному завантаженому zip і вписати цитату й дату в [[Textures-Registry]].

## Related
- [[Style-Guide]] · [[VFX-Direction]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[Prompt-Library]]
- [[Higgsfield-Pipeline]] · [[Pipeline-2D-to-3D]] · [[Textures-Registry]] · [[ADR-013-License-Check-At-Release]] · [[Library]]
- [[Stage-Bazaar]] · [[Stage-Fountain]] · [[Stage-River]] · [[2026-10-03-Sprint-Arenas-VFX]]
- [[2026-10-03-Animation-Sources]] · [[state]]
