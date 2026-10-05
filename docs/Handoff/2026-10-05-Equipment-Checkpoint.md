# Спорядження й одяг — checkpoint інтеграції

2026-10-05 · T1. Продовження [PR #178](https://github.com/santos-va/nooneisreal/pull/178), **draft до admission нових матеріалів**. Цей checkpoint не стверджує оновлення встановленого macOS застосунку. Попередня база — [[2026-10-05-Whole-Body-Checkpoint]].

## Що змінено

Меч перевернуто на спині й у кожній руці; вузький профіль має UV, обмотку й тонкий орнамент. Reachable socket і переходи draw/handoff узгоджені з реальними кистями. Bounded forearm/wrist correction використовує actual blade profile, не переносить хитбокс чи контактну точку. Укол використовує наявний UAL Sword_Light_D; lowcut contact зсунуто на один source frame у тому самому кліпі, щоб ACTIVE клинок проходив через declared hitband. [[2026-10-05-Equipment-Sword-Craft]].

Після прямого native feedback Santos кислотний sword material замінено приглушеним forest/aged-brass, а набір кілець — однією горизонтальною фіолетовою ∞ на rear panel. Збережені підписані originals і точні SHA — [[2026-10-05-Equipment-Canonical-References]].

Choko отримав читабельний годинник, Skea — зовнішній grimoire зі сторінками/корінцем та hip kunai; чинні rope/projectile surfaces уточнено. Garment mask у COLOR.g зберігає atlas, skin, geometry та три imported LOD, захищає обличчя/волосся/шкіру. Короткі пришиті краї (Choko60мм, Skea25мм) реагують на фізичні сигнали з обмеженою пружиною; це не повна симуляція одягу. Camera proximity охоплює вкладені/пізні речі, відновлює material pointers і не змінює shared NPC materials. [[2026-10-05-Hero-Equipment-And-Cloth]].

NPC мають tailored panels, шви й кишені, обмежений рух тканини/шкіряних деталей. Старі графічні folds torso/sleeves/wings збережені: native аудит виявив і закрив їхню втрату при зміні shader. Geometry budget не збільшено. [[2026-10-05-NPC-Tailoring-And-Cloth]].

## Перевірки

Owner results, прочитані T1 у raw logs: weapon10950/0, hero7930/0, NPC142747/0. Незалежний T4:36 final blade-edge/full-skin poses без перетинів; hero54 actual body/hook poses без перетинів або invalid geometry. Natural render30/60/120 має482 common callbacks із точним збігом body/bones/cloth. Чинні ground/body helper source hashes залишились незмінними. [[2026-10-05-Gear-And-Cloth-Review]].

Root smoke:164 перевірки /19847 кадрів,106 GDScript без parse failures. Перший broad runner дав75/76 через помилку нового NPC sentinel regex: числові mesh/triangle/hinge counters у кінці успішного рядка не були передбачені. Raw NPC test був142747/0; regex виправлено без зміни production чи старих73 tuples. Повтор corrected runner завершився76/0, rc0; gates зелені,106 GDScript/175assets. Наступні user surface corrections перевіряються окремо: hero7930/0, muted sword230/0; їхні зміни не приписуються заднім числом старому aggregate. Native Compatibility camera поточного production4/0. Exact-commit PCK пройшов нижче; current-head CI відстежується в PR і тут не припускається зеленим.

Matched native й межі видимості — [[2026-10-05-Equipment-Visual-Audit]]. Linux helper CPU/resource measurements — [[2026-10-05-Equipment-And-Cloth-Research]]; це не full-frame FPS/M3 сертифікація.

## Точна збірка

Source **`08b443dcbfe544a1624ed48569a4089eb31a71be`**, версія0.5.0. Fresh import/export, native Compatibility із порожньої теки через `--main-pack`, новий OS profile: **137/0**, rc0, без runtime/script/shader errors. PCK **208767116B**, SHA-256 **`aade8b44a80061f298418bd201a366b19e78fa15fa04f95d42d0ef50da0ac8d9`**; розмір/hash окремо звірено `stat`/`sha256sum`. Докази `/workspace/nooneisreal-evidence/district-close/pck-08b443d/`: evidence.json, import/export/native.log, native.png.

Перша package перевірка f6d31fa дала137/2: native lazy shader getter повертав `null` до компіляції й `1.0` після неї. Actual clone/fade/reset pointer працювали правильно; source material не змінювався. Verifier тепер порівнює effective default і явно вибирає NPC owner; негативний контроль зі справжньою мутацією джерела лишається137/2, rc1. Production game tree f6→08 незмінне; виправлений лише verifier. Перший невдалий прогін не підмінено успішним. [[2026-10-05-Gear-And-Cloth-Review]].

## Матеріали: конкретний blocker

За прямим дозволом Santos створено **шість Higgsfield 2K maps**, GPT Image2.5/max; перший набір коштував **54 кредити**. Після прямої корекції Santos створено ще одну muted blade revision за9; **разом63 кредити**,7 успішних jobs, актуальний набір6 maps. Старий sword job superseded; точний поточний список — `docs/assets/provenance/equipment-20261005/download-list-v2.json`. Існують terminal receipts, prompts, job IDs та URLs, але **original PNG bytes не отримано й maps не інтегровано**: CONNECT403 destination policy для `d8j0ntlcm91z4.cloudfront.net`. Потрібен дозволений domain у налаштуваннях середовища. Повторні успішні generations не потрібні. [[2026-10-05-Equipment-Texture-Production]].

Після відкриття доступу: завантажити originals із збережених URLs; перевірити SHA/dimensions/tiles/кольори; узгодити UV і neutral mean-centered modulation; зареєструвати кожен admitted asset; переглянути near/play-distance native результат; scoped shader/material/PCK/CI verification. До цього plain book/apron і fallback fabric не називаються завершеною художньою якістю. Terms gate [[ADR-013-License-Check-At-Release]] збережено; немає твердження CC0 для provider maps.

Іконка лишається попередньою за прямим рішенням Santos до отримання оригінального нового PNG. Merge виконує Santos; main/release не змінювались. Чинний updater отримує main-channel збірку після merge й успішного release workflow, не з локальної робочої копії.

## Related

- [[2026-10-05-Equipment-And-Cloth]] · [[2026-10-05-Equipment-Session]] · [[state]] · [[Build-and-Run]] · [[Export-Platforms]] · [[Textures-Registry]]
