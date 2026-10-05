# Спорядження й тканина: фактичні межі та легкі варіанти

2026-10-05 · T3 Архімед · read-only audit бази `4c68473ce88e167828c3425fa1ecbe3062dc96ca`. Питання: як зробити тонке індивідуальне спорядження, кращу фактуру одягу і переконливі вільні краї без нової важкої бібліотеки чи повної cloth simulation? План: [[Plans/2026-10-05-Equipment-And-Cloth]]. Production, imported assets і залежності цим аудитом не змінювалися; сторонні assets не завантажувалися. Game-dev CLI недоступний за повідомленою координатором перевіркою; його receipts або performance results тут не заявлено.

## Відповідь

Для цього зрізу найменше втручання — **окреме unit-scale спорядження/вільні краї з кількома Node3D pivots**, закріплені на вже готовій позі героя або NPC. Матеріали й геометрію повторно використовувати; індивідуальність задавати силуетом, локальними деталями та кількома параметрами. На hero mesh немає готової garment segmentation: загальний fabric shader зачепить також шкіру/обличчя. Native SpringBone4.7 корисний для майбутньої спеціально підготовленої accessory chain, але не є drop-in для поточного cm-scale Meshy skeleton. Нижче — перевірені факти та межі, не художнє приймання кандидата.

## Що фактично є у моделях

GLB JSON/accessors/images перечитані з поточного checkout; це свіжий source inventory, а не переказ попереднього аудиту. Raw результат: `/workspace/nooneisreal-evidence/equipment-cloth/glb-inventory.json`.

| Властивість | Choko `choko_m0.glb` | Skea `skea_m1.glb` |
|---|---:|---:|
| Mesh nodes / primitives / materials | 1 / 1 / 1 | 1 / 1 / 1 |
| Vertices / triangles | 28520 / 37448 | 33108 / 37138 |
| Skin joints | 24 | 24 |
| Morph targets | 0 | 0 |
| Embedded base-color image | один JPEG2048×2048 | один JPEG2048×2048 |
| UV/tangent/skin attributes | TEXCOORD_0, TANGENT, JOINTS_0, WEIGHTS_0 | ті самі |
| Armature node scale | 0.01 / 0.01 / 0.01 | 0.01 / 0.01 / 0.01 |
| SHA256 | `ae01fdbce41bdaa4603e2a08e92868c8c9d0f4d2f33fc0d0bb40c59b7ef7d13a` | `c7b562e8b64e23434e4002db1eaed3e5532d9448f37e3ef722ed37c54e08aa8f` |

У joint list є Hips, три Spine, neck/Head/headfront/head_end, плечі/руки/кисті та ноги/стопи/toes. **Немає cloth/hair chains або finger chains.** Одяг, тіло й волосся не відокремлені scene mesh nodes чи material slots. Це не доказ відсутності будь-яких disconnected triangle islands: connected-component segmentation тут не виконувалась. Доведена практична межа — runtime не отримує готового garment object/mask для окремої фізики або tint.

Матеріал кожного GLB має тільки baseColorTexture, metallic0 і roughness≈0.8, doubleSided=true. Окремих normal/roughness/metallic textures у GLB немає. `SkeletalRig._cel_material()` бере лише albedo texture першого material і ставить **один material_override на весь hero mesh**; чинний `toon.gdshader` читає UV albedo й задає roughness1/metallic0. Tangents присутні, але це не означає, що normal detail уже відображається. Додавання normal map потребує shader contract і правильних UV/маски; збільшення JPEG саме не створить шви чи окремий рух тканини.

`CityCosmetics.gd` називає sash «physical», але на цій базі це дві BoxMesh стрічки і TorusMesh пояс, єдиний StandardMaterial, орієнтація за hips/neck. Симулятора тканини, вільного кінця, stretch/penetration solver там немає. Це реальне геометричне доповнення з palette reward, не фізична тканина.

`NpcAppearance.gd` — Node3D hierarchy з окремими primitive meshes, **без Skeleton3D/skin**. Torso, coat skirt, apron, scarf tail, belt, wings/tail і робочі речі можна змінювати окремо. Уже існують static `_meshes` для sphere/box/prism і `_materials`, keyed за color+texture. Три чинні оригінальні128×128 SVG — knit stripes, workwear seams, skin marks; додатковий atlas не є обов'язковою умовою кращої геометрії. Розтягнутий primitive UV не є індивідуальним garment unwrap: seam layout слід перевірити на кожній новій формі.

## Спорядження: поточні обмеження

`SwordPresentation.gd` має окремий процедурний Choko sword на rendered hand/torso, grip calibration, handoff/stow/dissolve. Базова diamond blade доходить до1.08m; найбільша ширина0.23m, товщина0.066m — чинні PLACEHOLDER art dimensions, **не gameplay reach**. `_blade_mesh()` не записує UV. Текстурний орнамент на ньому потребуватиме UV або локальних координат у shader; нині латунні рейки — окрема геометрія.

Source setup створює18 постійних weapon pieces і40 прихованих до dissolve dust meshes. Це арифметичний Node count із коду, не вимір draw calls: visibility, shadow passes і outline змінюють GPU роботу. Material.next_pass додає ink outline шириною0.004m, rail radius0.005m. Така outline товщина порівнянна з тонкою filigree; після звуження blade/rails її треба оцінити окремо, інакше дрібна деталь лишиться візуально грубою. Додавати десятки окремих mesh nodes для насічок без потреби недоцільно: спочатку shared atlas/UV або зібрані surfaces і native замір.

`RigAnimator` має діагностичні kunai/backpack primitives Skea, але `SkeletalRig._hide_capsules()` приховує всі descendant MeshInstance3D капсульного rig. Окрема `SwordPresentation` створюється тільки для `weapon_kind==sword`. Отже наявність Skea gear коду в capsule branch не є доказом його видимості на hero GLB; новий equipment layer має кріпитися до rendered hero. Відсутність finger bones також означає, що thinner handle сам не створює articulated grasp — потрібна перевірка mesh hand landmarks/grip offset.

## Варіанти й джерела Godot4.7

Усі зовнішні джерела нижче реально прочитані через GitHub2026-10-05; engine tag `4.7-stable`, docs branch `4.7`. Джерельний код рушія має перевірену [MIT license](https://github.com/godotengine/godot/blob/4.7-stable/LICENSE.txt). Це ліцензія engine/API, не перекласифікація наших assets.

| Варіант | Що повторно використовує | Межі й ціна | Оцінка для цього плану |
|---|---|---|---|
| A. Окремий rigid mount + короткий Node3D pivot chain | Чинний rendered pose, NPC pivots, original procedural meshes; [BoneAttachment3D](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/BoneAttachment3D.xml) як optional pose-copy mount | Кілька bounded secondary transforms, власний physics serial/velocity lag. Це не деформація всього пальта; потрібні safe offsets/bend limits, reset і visibility policy. Вартість треба заміряти, а не називати нульовою. | Рекомендований bounded pilot для straps, apron/scarf ends, tassels. Mount не має override-ити hero bone. |
| B. Native SpringBoneSimulator3D на спеціальній accessory rig | [SpringBoneSimulator3D](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/SpringBoneSimulator3D.xml), вбудований MIT, без plugin | Потрібна підготовлена unbranched root→end bone chain та skinned accessory; Y-branch не підтримується. Docs прямо попереджають про scaled skeleton/bones. Власні SpringBoneCollision children не пов'язані з PhysicsServer3D. | Реальний наступний варіант для unit-scale accessory rig; не підключати автоматично до Meshy armature0.01. |
| C. Pinned vertex deformation на окремій mesh strip | Shared spatial shader, UV/vertex-color pin mask; [spatial shader4.7](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/shaders/shader_reference/spatial_shader.rst) | Потрібні достатні segments, нормалі та conservative cull bounds. Вітер/інерційний вигин можна показати дешево, але world collision/self-collision самі не з'являються. Shadow й outline мають повторювати deformation. | Прийнятний decorative far-detail варіант після A; не використовувати весь hero mesh без точної garment mask. |
| D. SoftBody3D | [Вбудований soft body](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/SoftBody3D.xml); project уже має Jolt Physics | Реальна deformable mesh, pinning/collision configuration і більший state/solver scope. Docs рекомендують Jolt як швидший/надійніший backend, але це не гарантія нашого cloth budget. Потрібні garment topology/quality gates. | Відкласти за межі цієї хвилі; full hero mesh не є готовою cloth surface. |

[SpringBone engine implementation](https://github.com/godotengine/godot/blob/4.7-stable/scene/3d/spring_bone_simulator_3d.cpp) підтверджує окремий modification pass: обробка списку collisions, потім joints кожного setting; є `reset()`. [SpringBoneCollision3D](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/SpringBoneCollision3D.xml) діє лише як child simulator, може слідувати bone й також має застереження щодо scale. Це не автоматичний collision із кожним міським об'єктом. [Capsule variant](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/SpringBoneCollisionCapsule3D.xml) має height циліндричної частини **без** hemispheres: не підміняти ним повну висоту тіла.

## Shared матеріали й текстури

- Чинний NPC cache варто зберегти. [Resource](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/Resource.xml) кешує завантажений path і повертає shared reference. [ShaderMaterial.set_shader_parameter](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/ShaderMaterial.xml) змінює всіх користувачів цього ресурсу: анімаційний fade/tint одного персонажа не можна записувати у shared palette material.
- [GeometryInstance3D.set_instance_shader_parameter](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/GeometryInstance3D.xml) із `instance uniform` підходить для індивідуального color/phase/UV offset. [Shader-language4.7](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/shaders/shader_reference/shading_language.rst#per-instance-uniforms) обмежує це scalar/vector types: texture/array не є per-instance uniform; practical limit16. Один shared atlas + UV transform простіший для невеликого набору gear, ніж окрема texture кожному NPC.
- Та сама документація попереджає: Compatibility/GLSL3.3 не допускає довільного dynamic indexing sampler arrays. Atlas або явний bounded switch — перевірювані варіанти. Основний project — Forward+, але Compatibility є чинною acceptance lane, отже її не пропускати.
- [MultiMesh](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/MultiMesh.xml) справді інстансить повторений mesh одним GPU об'єктом, але culling спільний для всього MultiMesh. Для12 індивідуально рухомих NPC з різними деталями це окреме групування/оновлення transforms, а не обов'язковий rewrite. Спочатку shared resources і bounded node/material count; draw-call виграш тут ще не виміряний.
- Hero albedo треба зберегти: нові seam/cloth detail materials застосовуються до окремих overlays. Для редагування оригінального outfit потрібен authored UV mask або asset segmentation; color threshold по JPEG не є надійною класифікацією skin/cloth.

## Вторинний рух і приймання

Вільний край слідує **готовому rendered mount**, а clock/velocity/acceleration history просуваються один раз за physics serial. Повторні skeleton callbacks можуть лише відтворювати обчислений стан. Pause/hitstop/rewind/teleport потрібні явні hold/reset; аксесуар не змінює Fighter velocity, hitboxes, gameplay RNG або save identity. Під час conversation NPC зупиняє locomotion, але має плавно віддати інерцію cloth без нового випадкового phase.

Shader builtin `TIME` за прочитаними docs залежить від time_scale, але **не від pause**. Тому decorative cloth із raw TIME не виконає freeze contract; потрібний явно керований presentation clock. Vertex shader deformation потребує перевірки shadow/outline й `extra_cull_margin`/bounds; великий AABB на весь світ просто приховає culling проблему ціною зайвого render.

Перевіряти pinned anchor, bounded free-end displacement/stretch, torso/hand/weapon clearance, скромний рух у спокої й реакцію на прискорення/гальмування. Числа limits — PLACEHOLDER, їх заморожує виконавець до candidate. Потрібні30/60/120 same-physics comparison, pause/hitstop/rewind/teleport та native кадри близько/на ігровій дистанції. CPU перевіряти для обох героїв і поточної population; видимі meshes/materials/shadow/outline passes рахувати окремо. Нові вузькі resource/CPU результати наведені нижче; попередні body/foot benchmarks не вимірюють cloth.

## Ліцензії та що не встановлено

Godot API/engine — MIT із чинним copyright notice. Procedural NPC meshes/SVG та sword code — original project за [[Textures-Registry]], не оголошені CC0. Hero Meshy GLBs і weapon reference мають існуючий запис Higgsfield provenance; реєстр прямо лишає підтвердження комерційних умов до release за [[ADR-013-License-Check-At-Release]]. Цей аудит не змінює статус ліцензій і не стверджує нової перевірки облікового плану. Нових libraries, plugin binaries, assets, paid requests чи system installs немає.

Відкриті питання: native якість тонкого силуету/орнаменту, фактична вартість нових overlays, clothing penetration в усіх authored позах, контракти camera proximity для вкладених/пізніх meshes. Відповідь на них дають implementation lanes і незалежне приймання, не сама наявність SpringBone/SoftBody API.

## Підготовка resource/CPU приймання після CP1

Власники запропонували `NpcClothMotion.step(owner, delta)` та `HeroGearPresentation.advance(delta)` / `update_pose()`. Підготовлені зовнішні timing fixtures у `/workspace/nooneisreal-evidence/equipment-cloth/budget/`: `npc_budget.gd` для12 NPC, двох сценаріїв,30 warmup+240 measured frames і трьох respawn/cache/lifecycle циклів; `hero_budget.gd` для доданих gear mesh/material/vertex counts, mask buffer/LOD inventory, cold/warm setup та окремого helper time. Body/foot simulation і render не входять до цих timers. Кожний результат нижче прив’язаний до власного stable source snapshot і погодженого quiet window.

Read-only metadata probe вже виявив суттєву межу prototype `HeroGarmentMask`: новий ArrayMesh із `lods={}` втрачає **три реальні imported LOD levels кожного героя**. Це перевірено на Godot4.7 у власній старій ізольованій game копії; поточні GLB **і їхні .import settings byte-identical**, підтверджено новим порівнянням. Shadow mesh відсутній у обох. Журнал `/workspace/nooneisreal-evidence/equipment-cloth/lod_inventory-final.log`, script поруч. Перший fixture мав помилковий Dictionary type для raw LODs; цей невдалий запуск не зарахований, виправлений inventory пройшов rc0 без ERROR.

`RenderingServer.mesh_get_surface(...).lods` фактично повертає **Array of dictionaries `{edge_length, index_data:PackedByteArray}`**. Це не той формат, що аргумент [ArrayMesh.add_surface_from_arrays](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/ArrayMesh.xml): він приймає Dictionary<float, PackedInt32Array>. Choko має raw LOD index buffers112344/56172/28080bytes, Skea111408/55704/38652bytes; це **байти**, не кількість triangles/indices. Правильне збереження потребує перевірки encoded index width. Власнику передано доказ до freeze. Пізніший helper df196da8 зберігає всі три LOD buffers; це повторно перевіряється у resource inventory нижче.

Prototype маски також створював ArrayMesh кожного setup, утримуючи original_mesh: це не додатковий rendered torso, але окреме allocation replacement buffers. Owner реалізував shared immutable cache за original mesh+hero ID. Приймання має окремо порахувати додані rendered vertices та mask buffer/cache lifetime; phrase «без дубльованого torso draw» не означає «без додаткової пам'яті». Остаточні числа з'являться після runtime inventory стабільного кандидата.

## Додатковий запит про актуальні Higgsfield terms

Після окремого дозволу Santos на кредити координатор попросив перевірити commercial-output умови для нових material maps. Цей дозвіл на генерацію не є джерелом ліцензійних умов. На2026-10-05 прямий read-only HTTPS запит до `higgsfield.ai` не дістався origin: proxy повернув `CONNECT tunnel failed, response403`, header `server: envoy`, timestamp03:17UTC. Спробуваний `/terms-of-service` endpoint не підтверджений як чинна canonical legal сторінка, її текст **не прочитаний**. Raw headers: `/workspace/nooneisreal-evidence/equipment-cloth/license/response-headers.txt`.

Доступні Higgsfield connector tools не містять legal/terms reader, general web-search/fetch tool також не знайдено. Policy не обходилася. Тому поточні output ownership, paid-plan commercial entitlement, upstream GPT Image умови й attribution/exclusivity **не підтверджені цим аудитом**; джерела URLs/цитати не вигадані. Для нових generated assets слід фіксувати provider/model/job/date/prompt/cost provenance, а license field лишати «provider terms; commercial entitlement unverified2026-10-05» до доступного офіційного тексту. CC0 або повний commercial clearance не оголошувати. Реєстр та його чинні license записи T3 не змінював.

## Вимір stable NPC helper/resource subset

Після окремого owner freeze виконано вузький NPC fixture у погодженому quiet window: T1/T2/T4/T6/rope не запускали Godot, перед вікном `/proc` не показував стороннього процесу. Власний snapshot — baseline`4c68473` плюс рівно5 source overrides; manifest `/workspace/nooneisreal-evidence/equipment-cloth/budget/npc-stable/source-manifest.json`. Hashes: NpcAppearance`4b8a1461bdcc8ff66f985b16b818b8695acdb421c7ef7d5b80c1e1c0cfeb445d`, NpcClothMotion`3be689c5ace586b05d4f054a34bb9a28ef3ce56ce9f7ea4f69fbc778c1cd3d72`, CityNpcActor`4d9615177f0c2cf0beacf451fccdf76ca975d2632adc895aba99e26893840835`; GearSurface/shader hashes також у manifest. Це **stable NPC CPU subset**, не приймання ще змінюваних material maps або hero gear.

Godot4.7 headless, Linux runner;12 visual profiles із seeds40…51 і grocer/tailor/workshop props. Кожний сценарій30 warmup+240 measured physics frames. Timer охоплює лише12 послідовних `step_clothing(1/60)`; задана trajectory і `set_motion()` виконуються поза timer. Import, geometry/setup, director/AI, body/foot simulation та rendering виключені. `npc_budget.gd` SHA256`6a0a5f641d80d511931bc0f5657f87d17583b7295569a65faa1e5e7ffe2907a3`.

| 12 NPC ensemble | Median / p95 / max, µs |
|---|---:|
| Idle |104 /149 /201|
| Move, stop, turn |108 /170 /1378|

Окремий tail1378µs не прихований; ці480 samples не гарантують повного frame time або M3 FPS. Джерело helper не містить raycasts чи per-vertex cloth simulation; у перевіреній population21 hinges, максимум3 на NPC.

| Ресурс у12 профілів | Фактичне значення |
|---|---:|
| MeshInstance nodes |502 сумарно; максимум45/NPC|
| Referenced full-LOD vertices / triangles |22968 /29616 сумарно; максимум2752triangles/NPC|
| Unique shared mesh resources |11|
| Unique shared material resources |27|
| Cache після трьох однакових respawn cycles |11meshes /27materials, без зростання|

Node/vertex counts — обсяг referenced geometry, не draw-call або GPU-memory вимір; resources shared, тому ці вершини не є сумою унікальних allocations. Обидві чинні per-NPC межі48meshes/8000triangles виконані. Owner result47meshes на100seeds має інший sample set і не підміняється нашим max45 на12seeds.

Setup median одного visual із props:258µs першого cycle,224/220µs наступних; перший cold outlier2518µs. Три cycles перевірили повторне використання тих самих resource identities і нульове зростання кешу під час stepping. Після `free()` weakrefs усіх visual nodes та helper RefCounted стали null; cache resources навмисно залишаються для reuse. `NPC_BUDGET_COMPLETE failures=0`, rc0, без SCRIPT ERROR/ERROR та shutdown leak повідомлень. Raw `budget.log` і `resource-summary.json` збережені у snapshot directory. Hero equipment виміряно окремо нижче. Geometry-driven combat orientation timing ще чекає виправлення actual blade-edge clearance; NPC числа його не включають.

## Hero equipment: isolated resource/helper proof

Owner підтвердив вузький resource snapshot після видалення rigid hem boxes і додавання full-UV GrimoireCoverFace; фінальне actual-triangle/native приймання на цей момент ще триває. Власна копія `/workspace/nooneisreal-evidence/equipment-cloth/budget/hero-focused/` містить `source-manifest.json`, `budget.log`, `resource-summary.json`. HeroGearPresentation SHA256 `c415970d14f36e3636d42242f1e2bac5aad4b26ea22200f85b9883fc699af0ca`; HeroGarmentMask `df196da89f141409a64ac1614df840b5aff6a83015d76fbbc521e127961f4624`. Shader/source hashes та fixture SHA також записані в manifest. Призначені provider material maps у цей snapshot ще не підключені; їх texture-memory/GPU вартість цими числами не перевірена.

| Додане HeroGearPresentation | Choko | Skea |
|---|---:|---:|
| MeshInstance / surfaces / unique meshes |23 /23 /23|36 /36 /36|
| Referenced full-LOD vertices / triangles |844 /732|1644 /1910|
| Unique materials / shaders |5 /1|7 /1|
| Spring-driven free tabs |2, по3 hinges|2, по3 hinges|
| Mask selected / protected vertices |2790 /25730|7758 /25350|

Це gear descendants, без sword/dissolve, старих city cosmetics, body mesh і його outline. Mesh/resources для дрібних hero props створюються на кожного героя; на відміну від NPC, вони не заявлені shared. Materials мають індивідуальний hit/fade state. Body vertex/index counts залишилися 28520/112344 та33108/111414; **другий skinned torso draw не доданий**. У source і replacement по3 LODs; обидва respawn використовують той самий replacement mesh ID.

Replacement raw vertex/attribute/skin/index/LOD buffers: Choko **1790244 B**, Skea **2017776 B**. Source buffers при цьому також залишаються в cache:1676164 B та1885344 B. Різниця114080/132432 B — доданий COLOR channel, але фактичне збереження окремого replacement означає додаткові повні buffers, а не тільки ці кольори. Є також CPU packed mask/rest arrays (16 B color +12 B Vector3 на vertex:798560/927024 B), GDScript/resource overhead і driver allocations. Це inventory raw buffers, **не точний RAM/VRAM profiler**. Shared cache має2 hero keys і навмисно переживає free персонажа; mutable node/helper weakrefs після teardown стали null.

Linux/Godot4.7 headless; fixed already-posed hero skeleton, actual helper із sinusoidal acceleration,30 warmup+240 measured physics frames на героя. Таймер охоплює `advance(1/60)` + `update_pose()` + повторний `update_pose()`. Пози/skin input setup, body/feet, бойова корекція, rendering поза timer. Повторний pose call не просуває serial і не перебудовує mask. Інші lanes призупинили Godot; перед стартом live Godot/ffmpeg у `/proc` не було (окрім старого zombie). Під час очікування короткий combat singlecase завершився до вимірюваного вікна.

| CPU, µs median / p95 / max | Choko | Skea |
|---|---:|---:|
| Advance |25 /42 /224|31 /55 /377|
| First pose application |36 /52 /253|42 /84 /192|
| Repeat pose application |17 /19 /77|16 /21 /198|
| Total of three calls |77 /119 /359|90 /184 /521|

Whole Fighter setup у двох spawn cycles:399304→196238µs Choko,384799→220227µs Skea. Це **не mask-only** benchmark: includes skeletal/body/gear setup та resource initialization; дві одиничні samples не є статистикою setup latency. Helper raw log завершився `HERO_BUDGET_COMPLETE failures=0`, rc0 без ERROR чи shutdown leaks. Жодних whole-frame/M3 FPS висновків. Бойову geometry correction буде виміряно лише після edge-correct source freeze; rejected centerline candidate не використовується як performance acceptance.

## Додатковий local UAL audit: семантика уколу мечем

Після native знахідки «thrust виглядає як downward cut» виконано read-only inventory **встановлених** UAL1/2, без downloads. UAL1 SHA256 `d1cb4537efa4c06a953ca951e5935062f88c2580ac68e45045592d587bddb43d`; UAL2 `ad3ae049c7d3d4846133b59dba6218fdabebe05d3aec646caef6665f6c540684`. Усього36 sword clips: UAL1 `Sword_Attack`, `Sword_Attack_Standing`, `Sword_Enter`, `Sword_Exit`, `Sword_Idle`; UAL2 `Sword_Light_A/B/C/D`, `Sword_Regular_A/B/C`, `Sword_Heavy_A/B/C/D`, їх наявні recovery/combo variants, Aerial A/B/Combo/Idle, Block, Dash, GroundPound, UpperCut. Жодного clip з назвою Thrust/Stab/Spear немає. Registry/license — уже vendored CC0 UAL, без нового asset admission.

Probe `/workspace/nooneisreal-evidence/equipment-cloth/budget/sword_source_inventory.gd` програє всі36 imported clips на60Hz у власній `hero-focused` копії. Використовує справжній Choko retarget і `SwordPresentation.hand_grip("right")`; `+X` — fighter forward. Wrist/bone координати відносно hero Hips, тому root travel не видається за arm extension. `sword-source-inventory.json` містить усі samples, log завершився `SWORD_SOURCE_INVENTORY_COMPLETE clips=36`, rc0 без ERROR. Поля `bone_*` — naked RightHand joint; legacy `wrist_*` у fixture — calibrated grip origin із5.5cm offset. Body/legs donor лишаються authored; final move source overlays, mirror та blade clearance correction у цьому direct scan не застосовані.

| Donor option | Виміряне | Рекомендація |
|---|---|---|
| **Sword_Light_D**,1.667s, без окремого Rec |0.200→0.300s wrist forward−0.2606→+0.5096m (+0.7702m), lateral.0918→.0825m, height.4209→.2963m.0.300→0.433s blade forward dot.8427→.8115, up−.4591→−.4864; wrist залишається+.51m.|Найкращий installed thrust donor: виразне forward arm extension із малим lateral drift. Перевірити source contact.300/follow.433 у final move, обидві руки й native silhouette; calibration ще нахиляє лезо вниз приблизно27–29°.|
| Sword_Attack_Standing,1.533s |На.450s blade forward.95, але wrist далі швидко опускається/йде вбік; forward орієнтація є короткою частиною sweep.|Можливий composited fallback лише з окремим авторським доопрацюванням; не називати готовим thrust.|
| Sword_Heavy_D,2.333s |Forward dot.877 на.633s, але wrist уже нижче hips у завершенні vertical cleave.|Не підходить як простий thrust remap; залишити семантику cleave.|

Чинний на момент аудиту `AuthoredCombatMotion.SOURCES["thrust"]` посилався на `Sword_Light_B`, contact.233/follow.433. Direct sample на.300s має forward dot.02/up−.75; через mapping, bone calibration та різні overlay phases це не числовий duplicate root actual-move probe, але незалежно підтверджує неправильну для уколу траєкторію. Рекомендація передана combat owner; жодної production mapping зміни T3 не вносив, damage/startup/active/recovery не змінював. Final acceptance має перевіряти реальний move й не підміняти forward-distance regression пошуком «красивого» окремого source frame.

## Edge-correct sword orientation: bounded helper CPU

Після owner5942/0 і незалежного actual-skinned36/0 geometry приймання (їхні lanes; не підміна цим timing) знято новий isolated snapshot актуального tapered-edge solver. Evidence `/workspace/nooneisreal-evidence/equipment-cloth/budget/combat-stable/{source-manifest.json,budget.log,rows.json}`. SwordMotion SHA256 `434dc3554daebbbc9fe91b8d5daca40d4b4b114e7aa5eec576849f8c51b1fce8`, SwordPresentation `b5f9bd73a909e089b4bae3cd70cfdc4c782bec9ec56c60206ca720be4fb9ca19`, AuthoredCombatMotion `aaaba25331cd3f231312db2a4eaa83220a38b6bdf75e5d3fb9208f48307b4934`; shader та fixture SHA у manifest. Містить новий Light_D thrust mapping. Це mathematical-helper snapshot до можливих наступних art/shader правок, без зміни production з боку T3.

Fixture відновлює всі24 raw retarget bone transforms **перед кожним** прямим викликом production `_clear_body_grip`; restore поза timer. Інакше повторний solver на вже виправленій позі штучно занижує ціну. Обидві руки Choko,6 attack variants, старт/перший/останній active і додаткові lowcut6/7/8; найбільша form2 (`sword_form` та `attack_sword_form`).30 warmup+120 measured calls на case:40 cases/4800 measured samples, **38 unique poses**, бо lowcut last-active7 навмисно також є серед додаткових frames. Skea не має цього sword helper. Setup, source animation, raw-pose restore, gear/feet й rendering виключені.

| Case | Median / p95 / max, µs |
|---|---:|
| Right lowcut6 |319 /458 /595|
| Left lowcut0 |299 /459 /1929|
| Right lowcut7, перший case |161 /228 /372|
| Right thrust, first-active5 |46 /63 /261|
| Left thrust, first-active5 |46 /94 /140|
| Left aircut0, видимий wall-time outlier |46 /119 /34616|

Більшість safe sampled poses має median45–50µs. **34.616ms maximum не приховано**: таймер `Time.get_ticks_usec()` вимірює elapsed wall time і не розрізняє виконання helper та descheduling; причинність цього одиничного outlier не встановлена. Попередні medians не дають гарантії worst-case frame budget. Combat/art підтвердили quiet lane, проте це Linux shared runner, не hardware-isolated benchmark чи M3 FPS. Короткий замір завершився `COMBAT_BUDGET_COMPLETE poses=40 samples=4800`, rc0 без ERROR/leaks; після нього native lanes одразу відпущені.

Source bound: максимум8 projection iterations; кожна перевіряє cached actual tapered profile проти6 anatomical segments (torso/head/обидва thigh+shin). Для29-edge wide profile це до1392 `Geometry3D.get_closest_points_between_segments` викликів; safe first iteration174. Це **structural upper bound**, не інструментований query count у кожному sample. Bone-roll/wrist caps50°/45°/45° залишаються; helper не просуває gameplay state/clock і не перебудовує mesh. На повторний callback новий retarget знову потребує solver: наведені числа — **на один helper call**, не автоматично на весь physics tick.

Пізніше owner hero gear виправив chest pin eligibility й додав Spine01 до garment whitelist: reported selected vertices2898/8103, geometry/buffer counts незмінні. Hero CPU/resource таблиця вище лишається чесно прив’язаною до c415970d/df196da8 candidate; вона не є final chest-fit acceptance або виміром зміненого cold setup. Повторний широкий game benchmark не запускався.

## Related

- [[Plans/2026-10-05-Equipment-And-Cloth]] · [[2026-10-05-Equipment-Session]] · [[2026-10-05-Whole-Body-Retarget-Research]] · [[2026-10-05-Local-NPC-Models-And-Physics-Reuse]] · [[Textures-Registry]] · [[Style-Guide]] · [[Characters/Choko]] · [[Characters/Skea]] · [[ADR-004-Physics-Is-Presentation]] · [[ADR-013-License-Check-At-Release]]
