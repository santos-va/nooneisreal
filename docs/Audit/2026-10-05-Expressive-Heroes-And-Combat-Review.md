# Незалежний аудит виразів героїв, матеріалів і бойових намірів

2026-10-05 · T4 Феміда. **Візуальний GREEN очей відкликано після відхилення Santos на `fda6983`: «Очі на лоба лізуть».** Нижче збережено датований технічний результат: власні check/gates та три незалежні негативні форми пройшли; особисте читання повного playable підтвердило **81 сценарій / 0 failures**, rc0, на незмінних 779 source files. Ці тести не довели анатомічне розташування повіки, тому не перекривають відхилення. Вузький повторний аудит — [[2026-10-05-Eyelid-Anchoring-Review]]. Попередні 79/0 належать checkpoint `94a09a6`, а не цьому заходу. Цей аудит не змінює `game/`, GDD або `state.md`.

## Межа й вихідний зріз

На початку аудиту особисто виконано `git branch --show-current`, `git log -1 --oneline`, `git status --short`: гілка `codex/character-expression-combat` від `94a09a6 Implement responsive city grappling and bounded parkour`, тоді нові зміни ще не закомічено. Прочитано план [[2026-10-05-Expressive-Heroes-And-Combat]], новий контракт [[02-Combat-System]], Fighter/InputRouter/CombatIntent, SkeletalRig, HeroGarmentMask, hero_garment shader та helper/shader міміки. План містить три альтернативи й сім поглядів; попередній completed parkour не означає приймання нових матеріалів або input.

Особисто відкрито через `view_image` native `skea_front.png`, `skea_front_no_outline.png`, `skea_body.png`, `choko_front.png` з `/workspace/nooneisreal-evidence/face-combat/baseline/`. Чорні розриви біля волосся, щік і коміра видимі; без outline вони зникають. Білі ділянки рукавів Skea залишаються без outline. Це підтверджує окремі причини дефектів, але не фінальну якість майбутнього виправлення. Дані двигуна й інструментів у [[2026-10-05-Hero-Tools-And-Engine-Compatibility]] прочитано; незалежного тесту стороннього addon або старішого Godot цей аудит поки не робив.

## Знайдені межі й передача власникам

| Пункт | Статус | Доказ і потрібна перевірка |
|---|---|---|
| Released pad tap після disconnect | GREEN у focused | У першому diff `_pad_connection_changed` збільшував revision, але стирав `_pressed_at` лише для досі активних `_pad_routes`. Tap із вже відпущеною кнопкою міг знову ввійти в protected continuation. Прочитаний final diff використовує `clear_player_presses(device + 1)`; actual routed tap/release/disconnect проходить у final intent160/0. |
| Вік і власність бойового наміру | GREEN у scoped перевірках | Final intent160/0 використовує реальні InputRouter/Fighter ticks, hitboxes і hitstop. Власний epoch-only mutant валить саме UI між physics ticks — 160/1, без сторонніх помилок. |
| Маска тканини | GREEN у scoped перевірках | Початкове додавання sleeve weights у спільний `cloth` розширювало COLOR.g shader domain; final G/B eligibility розділено. `_skin_pin` прямо не читає shader mask, тому первинна підозра на physical attachment не підтвердилася. Actual protected neck/chest/hand geometry та native ROI перевірені нижче; власний corner-guard mutant ловить обидва герої на реальних base/LOD triangles. |
| Власність міміки | GREEN у scoped перевірках | Helper керує shader-параметрами оригінального atlas surface, не вершинами/bones. Прочитано face1734/0; власний actual-hero контроль4/0 стає4/2 після вимкнення serial guard. Native доводить фактичну зміну surface; це не анатомічний facial rig. |
| Закриття обох очей | ВІДКЛИКАНО | Ранні `eyes-first/*closed.png` із залишковими aperture відхилили, head-domain і hero-only outline прибрали UV/LOD дірки та внутрішні hull fragments. Проте T4 помилково прийняв світлу закриту форму як коректну повіку: не перевірив її верхню межу відносно початкової очної щілини. Santos відхилив `fda6983`; T6 підтвердив світлий овал вище original Skea aperture. Старий native/state GREEN не є доказом placement. |

## Незалежні негативні форми

Підготовлені вимоги до freeze; фактичні результати трьох обмежених копій у `/tmp` наведено нижче. Production не мутовано:

- Прибрати revision guard із protected intent: pending після підтвердженого normal hit → відкриття й закриття UI між physics ticks → continuation мусить відхилитися. Окремо released routed tap → disconnect. Мутант має впасти на змістовній перевірці, без parse errors або teardown leaks.
- У focused combat перевірити вік 6→7, заміну й однакові timestamps, блок/whiff/iframe, неможливість четвертого кроку, пріоритет скілів/ухилу, freeze/control lock, reset/rewind лише власного гравця, held guard без синтетичного edge і точну межу grounded/airborne stun.
- Для матеріалів спробувати локально вимкнути захист de-light: тест має побачити зміну захищеної шкіри/взуття, а не лише підрахувати mask vertices. Одночасно перевірити, що нова маска не змінює чинний cloth pin contract і всі imported LOD.
- Для міміки перевірити повторний render callback без просування фізики, дві окремі інстанції одного героя, reset/rewind/freeze/hitstop, KO/hurt priority, відсутність записів у gameplay/RNG/bones. Семантичне мовлення не підміняти випадковою анімацією атаки. Негативна форма має вимірювати ownership або фактичні face pixels, залежно від фінального helper API.

## Прочитані focused докази

Виконано Python-читання всіх `*.log` у `/workspace/nooneisreal-evidence/expressive-heroes/combat/`: фінальний intent **160/0**, limb **2962/0**, comfort-input **31/0**, combat-control **549/0**, city-parkour **73/0**, усі з banner Godot 4.7 і без ERROR/WARNING/leak. Це незалежне читання raw-результатів T2, не власний запуск T4 й не приймання незавершеної графіки.

Ранні `intent-first/key/diag.log` мають **159/1** і не приймаються. Diagnostic явно показує `pre pressed=false`, тоді як після reset доставляється нова фізична подія. Прочитаний фінальний fixture додає `Input.flush_buffered_events()` і позитивний assert утриманої клавіші **до** reset; перевірка stale edge лишається. Це виправляє недостовірну передумову, не прибирає негативну вимогу. Epoch-only мутант і копію actual-contact fixture підготовлено в `/tmp/nir-t4-intent-epoch-bypass.gd` та `/tmp/nir-t4-intent-negative.gd`; їхні фактичні результати наведено у фінальній таблиці.

Межа контракту control lock/freeze — очищення вже захищеного pending. Старий загальний InputRouter buffer не перепроєктовано: новий raw tap, який з'являється під коротким lock, може лишатися свіжим у межах чинних шести тактів. T1 підтвердив цей scoped контракт; аудит не заявляє відкидання всіх фізичних подій за будь-якого короткого lock. Reset/rewind і UI мають окремі явні правила очищення історії.

Окремою власною Python-командою розібрано buffers/accessors оригінальних GLB (із byteStride): `/workspace/nooneisreal-evidence/expressive-heroes/validation/review-eye-weights.json` зберігає SHA256 джерел і конкретні vertices. Skea eye `(226,292)` у радіусі 30 atlas pixels має 62 vertices; мінімум combined Head/headfront/head_end **0.931803226** на vertex **4784**, UV `(0.098828,0.142019)`. Решта — **RightShoulder 0.064174205** і **neck 0.004022582**, а не лише neck. Тому початковий новий face support threshold 0.98 відкидав реальну eye surface; поріг 0.90 має виміряну причину. Фінальний R використовує неперервну head-domain admission для усунення UV/LOD дірок; зміни кольору лишаються всередині точних shader feature envelopes, а hero-only outline прибирає внутрішні head hull fragments. Це не дозвіл довільно змінювати shoulder або шкіру поза feature envelopes. Choko обидва eye neighborhoods мають combined head 1.0 (50/70 vertices); Skea інше око `(1009,271)` — 26 vertices, head 1.0. Native перевірку фінального результату наведено нижче.

Власна Python-перевірка `/face-combat/materials/mesh-refined.json` повторно обчислила шість позитивних protected наборів: **1938** physical hands, **7382** head/neck/feet, **4845** upper chest, **195** zipper, **2394** back torso, **1900** pink-color candidates. У кожного **0** touching triangles з ненульовим B на base і всіх трьох LOD. Окреме читання original PNG підтвердило **29 159 незмінених pixels** у восьми записаних on/off ROI. Результат — `validation/review-protected-proof.json`. Godot geometry witness прочитано й перераховано, не регенеровано T4; pink є color proxy, не універсальним semantic skin detector; ROI доводять лише свої області й позу. Ширший backpack ROI із шістьма зміненими boundary pixels явно не прийнятий як незмінний.

Особистий огляд `materials/refined-ab/skea_{front,body,back_body}_on.png` підтвердив помітне приглушення рукавів та збереження шиї, рук, білого взуття й емблеми. Частина верхніх front білих baked patches лишається в консервативно захищеній зоні; твердження «прибрано всі відблиски» не доведене. На час перевірки mask/material/outline source hashes відповідали witness, але FacePresentation вже змінювався для очей — це не фінальний whole-source freeze.

## Власні фінальні перевірки T4

Офіційний `/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`, XDG data/cache/config у `/tmp/nir-review-*`. Власні команди `python3 /tmp/nir-t4-expressive-review.py check`, `... gates`, `python3 /tmp/nir-t4-expressive-negatives.py`:

| Команда / контроль | Фактичний результат |
|---|---|
| `make check` | rc0; **112 GDS / 0** parse errors; smoke **164 / 19847 frames**, ALL OK; 0 ERROR/WARNING/leak у виводі. Makefile фільтрує import stdout, але не містив жодного matched error/warning і перевірив rc. |
| `make gates` | rc0, **БАТАРЕЯ ЗЕЛЕНА**; **175/175 assets**, **0 broken wikilinks**, 8 попередніх ambiguity notices, 112 GDS/0. |
| Actual-contact UI epoch mutant | rc1, **160 / 1**; єдина помилка — pending після UI cycle без fighter tick. |
| Face serial control → mutant | control rc0 **4/0**; mutant rc1 **4/2**, рівно по одному повторному physical serial для кожного реального героя. |
| Actual anatomy/LOD corner control → mutant | control rc0 **4/0**; mutant rc1 **4/2**. Choko: **751** mixed triangles, **1134** unblocked corner violations; Skea: **2128 / 3167**. Base і всі 3 imported LOD; позитивні фактичні counterexample counts. |

Повні журнали, rc і `review-negatives.json` лежать у `/workspace/nooneisreal-evidence/expressive-heroes/validation/`. Власне читання всіх цих raw logs не виявило parse/runtime warnings або leaks; п'ять ERROR рядків належать рівно запланованим негативним assertions. Копії семи fixture/mutant/runner sources з SHA256 збережено в `negative-sources/`, щоб `/tmp` не був єдиним доказом.

Перед import manifest мав **778 files**, digest `c95589b1160aacbb2296402cccd2256fd7d801e1354ec6b942bf81ca32c75431`. Єдина import-дельта — новий `game/shaders/hero_outline.gdshader.uid`; змінених/видалених source files **0**. Post-import та після всіх перевірок: **779 files**, byte-identical digest **`916816f998abde2b91315cbdf77092b16918c792cae6dfc19942f38e6bd8339b`** (`review-source-imported.json`, `review-source-after.json`). Власна Python equality-перевірка підтвердила той самий files map і digest у `playable-source-before.json` та `playable-source-after.json`.

Повний runner T1 завершився **81 сценарієм / 0 failures**, rc0. Особисто прочитано `playable-final.log`, rc та всі **81** case logs. Власний `review-final-playable-scan.json`: **0 unexpected errors/warnings/leaks**; **76** ERROR рядків належать лише очікуваним legacy негативним UI/movement/lifecycle assertions, які strict runner перевіряє окремо. Серед позитивних сценаріїв: **hero-face1734/0**, **hero-gear7946/0**, **combat-intent160/0**, **city-parkour73/0**, **parkour-motion15466/0**. Вихідний паркур і канати не випали з батареї; нові дві permanent регресії збільшили її з79 до81.

Окремо особисто прочитано `head-domain/focused.log` **1734/0**, 20-state native log та `final-sequence/receipt.json`: **156 PNG / rc0**, 280 captured code sources незмінні. Native має лише відоме llvmpipe VSync warning. Особисто відкрито фінальні `hero-face-sequence-sheet.png` і `hero-materials-before-after.png`; вони підписані як fixed-body face fixture та порівняння матеріалів, а не реальний запис бою. Апаратні FPS, фізичний геймпад, слухове приймання й встановлений macOS застосунок не перевірено цим Linux/headless/native зрізом. Пониження Godot не виконували: відсутній виміряний blocker, який його виправляє.

## Related

- [[2026-10-05-Expressive-Heroes-And-Combat]] · [[2026-10-05-Expressive-Heroes-Session]] · [[2026-10-05-Hero-Face-And-Material-Audit]] · [[2026-10-05-Hero-Tools-And-Engine-Compatibility]] · [[2026-10-05-Combat-Intent-And-Guard]] · [[2026-10-05-Responsive-Parkour-Review]] · [[02-Combat-System]] · [[ADR-004-Physics-Is-Presentation]]
