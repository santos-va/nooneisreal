# Матеріальні карти спорядження: Higgsfield production

2026-10-05 · T1 запускає paid provider, T6 перевіряє художню придатність і provenance. Santos прямо дозволив витратити кредити Higgsfield на якісні runtime текстури в цій сесії. Це окреме продовження [[2026-10-05-Equipment-And-Cloth]], не зміна історичного дозволу початкового безкоштовного аудиту.

Модель `gpt_image_2_5`, variant `flare`, quality `max`, resolution `2k`, `count=1`, opaque, `use_unlim=false`. Sword aspect 2:3, решта 1:1. Баланс перед submit: **4568.5**; provider quote **9/image × 6 = 54**. Фактичне списання та terminal receipt підтверджує T1; quote не видається за фінальний invoice. Root надіслав 6 jobs, нижче exact prompts без зміни provider payload. Перший batch terminal: **5 completed / 1 failed**. Баланс після нього **4523.5**, підтверджена різниця **45 кредитів**. Невдалий початковий Skea job не має result URL; один retry з тими самими параметрами, job `30db9a22-4f6a-42c3-8e48-516e929360c6`, **completed**. Усі 6 карт створено. Перевірений баланс після першого повного набору **4514.5**, загальна різниця **54 кредити** від4568.5; failed первинний job не додав окремої витрати за фактичним балансом. [Retry terminal receipt](../assets/provenance/equipment-20261005/skea-retry-completion.json).

Після прямої корекції Santos «не кислотний меч» T1 замовив одну muted revision, job `581e7a06-428e-4394-bfe3-75798f99fa5f`, **completed**. Quote й фактична додаткова витрата — **9 кредитів**; баланс **4505.5**, загалом **63 кредити** від 4568.5. Створено 7 успішних карт (одна стара sword map superseded), поточний набір — 6: п’ять інших матеріалів плюс muted sword. Початковий `f2667187` **не підключати**; runtime очікує `sword_inlay_muted_20261005.png`. [Revision request](../assets/provenance/equipment-20261005/sword-muted-request.json), [submission](../assets/provenance/equipment-20261005/sword-muted-submission.json), [completion](../assets/provenance/equipment-20261005/sword-muted-completion.json), [balance](../assets/provenance/equipment-20261005/sword-muted-balance.json).

**Admission заблокований отриманням оригіналів:** download із `d8j0ntlcm91z4.cloudfront.net` повернув CONNECT403 destination policy. T1 запросив дозволену зміну конфігурації; обхід не виконується. Локальних PNG/SHA немає, provider maps не інтегровані. Галерею provider root показав у чаті; вона не замінює незалежний огляд локальних bytes і runtime UV. [Requests](../assets/provenance/equipment-20261005/requests.json), [terminal receipt](../assets/provenance/equipment-20261005/completion.json), [retry receipt](../assets/provenance/equipment-20261005/skea-retry.json).

Runtime destinations: sword UV inlay; strict hero garment mask без заміни оригінального atlas; окремі GearSurface cloth/leather; окремий book cover UV. Neutral maps — multipliers; cover/blade — кольорові карти, тому повторний tint не має затемнювати їх удвічі. Текстура не підмінює виправлення напряму меча або фізику тканини. Нових нормалей/roughness карт provider не запитували; плоске зображення не оголошується PBR-пакетом.

## Exact prompts і jobs

### 1. sword_inlay

Job `f2667187-a897-493e-a964-164b7f48a851`. Aspect `2:3`. **SUPERSEDED за прямою художньою корекцією Santos; історичний prompt, не поточний runtime asset.**

```text
Create a production-ready flat 2D game material texture, NOT a product render or concept sheet. Fill every pixel edge-to-edge with the specified material. Orthographic surface only, zero perspective, no folds, no cast shadows, no lighting gradient, no glossy highlight, no ambient occlusion, no background, no labels, no text, no watermark. Original restrained hand-inked Sketch-Cel game art: flat local colors, refined quiet craftsmanship, subtly irregular graphite detail, never photorealistic noise. A rectangular emerald blade-inlay albedo map. Entire canvas is deep emerald green #218657 with subtly differentiated broad green longitudinal facet bands, NOT a sword silhouette. A single extremely fine muted warm-gold ornamental filament runs vertically at exactly the center U=0.5, with elegant small angular curls close to this filament and one tiny elongated gold diamond near the lower 12 percent of image height. Keep ornament within central 16 percent width; outermost 25 percent on each side stays quiet emerald. Delicate graphite artisan etching, sparse, precise, expensive craftsmanship. The image will stretch along a narrow sword blade; ornament must remain slender and legible. No guard, handle, border frame, or object outline.
```

### 2. choko_fabric

Job `ffbbdc35-0d7e-4f09-981b-b94a98b06a64`. Aspect `1:1`.

```text
Create a production-ready flat 2D game material texture, NOT a product render or concept sheet. Fill every pixel edge-to-edge with the specified material. Orthographic surface only, zero perspective, no folds, no cast shadows, no lighting gradient, no glossy highlight, no ambient occlusion, no background, no labels, no text, no watermark. Original restrained hand-inked Sketch-Cel game art: flat local colors, refined quiet craftsmanship, subtly irregular graphite detail, never photorealistic noise. Seamlessly tileable in both axes neutral warm-white fine tightly woven cotton canvas/twill, intended to modulate an existing orange jacket's color. Restrained broad diagonal twill with tiny graphite fiber interruptions; average very pale neutral warm grey, contrast under eight percent. Fairly large readable weave at close game-camera distance, smooth at distance. Uniform distribution, no directional illumination, no seams, no patches, no logos, no large stains. A tactile matte fabric flat albedo map, not fabric draped in a scene.
```

### 3. skea_fabric

Job `2899b255-657c-4e6d-bb32-205ee046461a`. Aspect `1:1`.

```text
Create a production-ready flat 2D game material texture, NOT a product render or concept sheet. Fill every pixel edge-to-edge with the specified material. Orthographic surface only, zero perspective, no folds, no cast shadows, no lighting gradient, no glossy highlight, no ambient occlusion, no background, no labels, no text, no watermark. Original restrained hand-inked Sketch-Cel game art: flat local colors, refined quiet craftsmanship, subtly irregular graphite detail, never photorealistic noise. Seamlessly tileable in both axes neutral light-grey dense soft hoodie knit, intended to modulate an existing violet hoodie color. Small restrained interlocking fiber loops with broad soft graphite strokes, visibly distinct from diagonal canvas, tonal contrast under ten percent. Smooth, comfortable dense cloth. Uniform distribution, no directional illumination, no seams, no sigils, no letters, no logos, no patches. Matte flat knit albedo map, not a knitted garment render.
```

### 4. dark_leather

Job `5c6ca169-245a-4bcf-aa0f-4a48926a583e`. Aspect `1:1`.

```text
Create a production-ready flat 2D game material texture, NOT a product render or concept sheet. Fill every pixel edge-to-edge with the specified material. Orthographic surface only, zero perspective, no folds, no cast shadows, no lighting gradient, no glossy highlight, no ambient occlusion, no background, no labels, no text, no watermark. Original restrained hand-inked Sketch-Cel game art: flat local colors, refined quiet craftsmanship, subtly irregular graphite detail, never photorealistic noise. Seamlessly tileable in both axes neutral medium-light grey worked leather grain. Fine restrained pebbled grain with two or three sparse short artisan handling marks, tonal contrast under ten percent. Neutral grey so game shader can tint dark green grips, brown straps, charcoal sheaths. Fine natural irregularity rather than synthetic repeating dots. No stitched border or stitching across the tile, no gloss, no dramatic scratch, no wrinkles, no object edges. Matte flat leather albedo.
```

### 5. grimoire_cover

Job `590d9dd1-1509-4733-a42e-f665b584ec3e`. Aspect `1:1`.

```text
Create a production-ready flat 2D game material texture, NOT a product render or concept sheet. Fill every pixel edge-to-edge with the specified material. Orthographic surface only, zero perspective, no folds, no cast shadows, no lighting gradient, no glossy highlight, no ambient occlusion, no background, no labels, no text, no watermark. Original restrained hand-inked Sketch-Cel game art: flat local colors, refined quiet craftsmanship, subtly irregular graphite detail, never photorealistic noise. A single full square flat grimoire cover albedo design, charcoal-plum leather base. Refined thin worn-silver rectangular border inset six percent, delicate restrained angular corner flourishes with individually hand-inked lines. Central fifty percent of the cover must be quiet completely empty leather for a separate in-game infinity emblem. Fine subdued leather grain, dark muted plum and graphite colors, pale silver craftsmanship. No text, lettering, runes, symbols, skulls, infinity symbol, spine, pages, book thickness, perspective, drop shadow or background. This is the flat texture of one cover face filling the entire square, NOT a rendering of a book.
```

### 6. npc_workwear

Job `c57f41ad-1df8-40e0-9b5b-dc1dad162ba3`. Aspect `1:1`.

```text
Create a production-ready flat 2D game material texture, NOT a product render or concept sheet. Fill every pixel edge-to-edge with the specified material. Orthographic surface only, zero perspective, no folds, no cast shadows, no lighting gradient, no glossy highlight, no ambient occlusion, no background, no labels, no text, no watermark. Original restrained hand-inked Sketch-Cel game art: flat local colors, refined quiet craftsmanship, subtly irregular graphite detail, never photorealistic noise. Seamlessly tileable in both axes neutral pale ecru coarse linen/canvas workwear. Restrained uneven warp-and-weft visible as lightly hand-inked squared weave, contrast under ten percent. A few irregular thicker threads, clean well-used artisan fabric. Neutral enough for varied colored shopkeepers' aprons and coats, distinct from fine diagonal twill and hoodie knit. No seams, patches, pockets, logos, embroidery, large stains, object edges or folds. Matte flat woven linen albedo map.
```

## Muted sword revision — поточний кандидат

Job `581e7a06-428e-4394-bfe3-75798f99fa5f`, ті самі GPT Image 2.5 flare/max/2k, aspect2:3. Provider reference — byte-identical canonical sword за public GitHub URL exact commit4c68473 (повний payload у request receipt). [Підписаний оригінал і palette contract](2026-10-05-Equipment-Canonical-References.md).

```text
Create one production-ready flat 2D albedo texture for a narrow fantasy sword blade, NOT a sword illustration, concept sheet, photograph or product render. Fill the whole rectangular canvas edge-to-edge with material. Orthographic flat surface only: no perspective, object silhouette, guard, handle, background, cast shadow, ambient occlusion, lighting gradient, bloom, labels, text or watermark. Use the attached canonical sword reference ONLY for its restrained hand-inked Sketch-Cel craftsmanship, broad quiet faceted material and aged brass ornament; do not reproduce its sword silhouette or bright white background. Match muted orange clothing and graphite/violet shadows. Dominant blade body is desaturated forest-teal emerald #315D52; broad longitudinal shadow facets #183C36, a few narrow sage facet highlights #91A78A. Sage highlights are sparse matte facets, not bright continuous neon edges. Graphite ink #2B2230 defines a few precise long facet boundaries, never noisy dense scratches. ONE extremely fine muted aged-brass ornamental filament #9A8960 runs vertically at exactly center U=0.5; occasional tiny highlight #B8AA7B. Keep all restrained filament curls within the central 16 percent of width. Add ONE tiny elongated brass diamond centered at U=0.5 and image Y=0.88, near the lower 12 percent of image height, where the blade meets the guard in the runtime UV mapping. Outermost 25 percent on either side stays quiet forest-teal. The rectangle will be UV-mapped onto a long thin blade, so all ornament must stay slender, coherent and uncluttered. Fine original artisan inlay, dark leather-and-cloth palette harmony. Absolutely no acid green, lime, fluorescent chartreuse, bright yellow edges, glow, emission, glossy plastic, chrome, sparkle, photorealistic grain, border frame, giant runes or repeating diamonds. Do not include leather, a hilt or any separate object. Flat albedo only; shading is performed by the game.
```

Terminal URL збережено в completion receipt, але bytes не завантажені; SHA/admission/native UV quality не перевірені. Тихий violet ∞ для книги реалізується окремою геометрією за чинним reference, не перемальовується цією текстурою.

## Перевірка перед admission

Перевірити реальний файл, dimensions/format/SHA, відсутність labels/mockup/зайвого lighting, neutral palette і tile-edge для тканин/шкіри. Native acceptance — той самий frozen baseline, close та gameplay камери; один горизонтальний ∞ додається виправленою геометрією лише на задній обкладинці книги. У меча guard=V0 у поточному mesh, а ромб запитаний унизу картинки: sampling має явно врахувати V-напрям, не перевертати original PNG через Python. Непридатну карту не підключати лише тому, що job оплачено. Прийняті assets отримують окремий рядок [[Textures-Registry]] із job/source URL і чинними provider terms, без оголошення CC0.

## Related

- [[2026-10-05-Equipment-And-Cloth]] · [[2026-10-05-Equipment-Visual-Audit]] · [[Textures-Registry]] · [[Style-Guide]] · [[ADR-013-License-Check-At-Release]]
