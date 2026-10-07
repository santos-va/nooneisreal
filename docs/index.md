# No One Is Real — вікі проєкту

Хаб. Кожна сторінка має `## Related`; кожен `[[wikilink]]` резолвиться (гейт `make gates`).
Поточна правда — [[state]]. Закон — [[constitution]]. Журнал зустрічей — `docs/Meetings/`.

## Поточний маршрут і історичний handoff

**Доставка, звірено 2026-10-07:** у main змерджені PR #181 «Нижня позначка» (`611c85d`), [PR #182](https://github.com/santos-va/nooneisreal/pull/182) з документальною звіркою (`abce638`) і [PR #183](https://github.com/santos-va/nooneisreal/pull/183) з трюками та профілями якості (`f27fd67`, merged 2026-10-05T13:28:44Z). CI на `f27fd67` — success ([ci](https://github.com/santos-va/nooneisreal/actions/runs/37317106289), [macOS main app](https://github.com/santos-va/nooneisreal/actions/runs/37317106267)); [prerelease `macos-f27fd67…`](https://github.com/santos-va/nooneisreal/releases/tag/macos-f27fd679ccb1def97290c9c5cc261801cedbcbc6) опубліковано 2026-10-05T13:46:03Z. Встановлення на M3 не підтверджене. Де документи після merge застаріли — [[Audit/2026-10-07-Post-Merge-Drift]]. Датовані попередні статуси збережені в журналі.

[[state]] · [[Meetings/2026-10-07-T1-Orchestration-Session]] — поточний стан і остання сесія (аудит після merge #183, хвиля ролей); [[2026-10-05-Repository-Reconciliation-Session]] — звірка репозиторію; [[Plans/2026-10-05-Repository-Reconciliation]] та [[Audit/2026-10-05-Repository-Reconciliation]] — план і перевірені підстави cleanup. [[Handoff/2026-10-05-State-Before-Reconciliation]] — незмінний архів state перед скороченням.

**English handoff — historical snapshot, 2026-10-04.**

[[Handoff/2026-10-04-Start-Here|Start here]] · [[Handoff/2026-10-04-Delivery-Ledger|Merged delivery ledger]] · [[Handoff/2026-10-04-Remaining-Work|Remaining work]] · [[Handoff/2026-10-04-Decisions-And-Validation|Decisions and validation]] · [[Meetings/2026-10-04-Current-State-Cleanup|Reconciliation at the snapshot date]]. Snapshot: merged main `2c50938` (#170). Historical evidence and unfinished acceptance are separate from current delivery.

## Що це

Стилізований 3D-файтинг із наявними аренами та першим прохідним районом міста. Напрям — спільний світ Cronshift, місця боїв у якому визначатимемо після побудови районів. Малюнок — власний «Sketch-Cel»; чинні еталони — найсвіжіші окремі текстури/вирізки, старі панорами — чернетки. Active ragdoll є презентацією, гарпун має скінченний запас. Персонажі — з власного аніме
Santos і товариша (лідер команди [[Choko]] — контроль часу, другий боєць [[Skea]] — Muay Thai і тіні), місто — [[Cronshift]].
Движок — Godot 4.7, GDScript ([[ADR-001-Engine-Godot]]).

## Карта

| розділ | сторінки |
|---|---|
| Бачення | [[01-Vision]] · [[Roadmap]] · [[Glossary]] |
| Бій | [[02-Combat-System]] · [[03-Skills-Framework]] · [[04-Grapple-System]] · [[08-Balance]] |
| **Поточний старт** | [[state]] · [[Meetings/2026-10-07-T1-Orchestration-Session]] · [[2026-10-05-Repository-Reconciliation-Session]] — актуальний зріз і межі приймання; [[Handoff/2026-10-04-Start-Here]] — історичний англомовний маршрут |
| **Камера біля тісних опор — 2026-10-07** | Ітерація 1: [[Plans/2026-10-07-Tight-Support-Camera]] (`approved`, виконано) · [[Research/2026-10-07-Tight-Support-Camera-Research]] (бриф T3) · [[Art/2026-10-07-Tight-Station-Readability-Criteria]] (мірила T6) · [[Fix/2026-10-07-Tight-Station-Camera-Baseline]] (T2, базовий замір) · [[Fix/2026-10-07-Tight-Support-Camera-Fix]] (T2, кроки 1–4) · [[Art/2026-10-07-Tight-Station-Fix-Review]] (T6, YELLOW) · [[Audit/2026-10-07-Camera-And-Gate-Review]] (T4, YELLOW). Ітерація 2: [[Plans/2026-10-07-Camera-Readability-Iteration-2]] (`approved` для T2) · [[Research/2026-10-07-Stencil-And-Line-Of-Sight]] (бриф T3) · [[2026-10-07-Camera-Readability-Iteration-2-Fix]] (T2, кроки 2–4; `262ea88`) |
| **Чесний гейт GDS — 2026-10-07** | [[Audit/2026-10-07-Post-Merge-Drift]] (T4, RED п. 3) · [[Plans/2026-10-07-Gate-Honesty]] (`approved` для T2) · [[Fix/2026-10-07-Gate-Honesty]] (T2, виконання) · [[Audit/2026-10-07-Camera-And-Gate-Review]] (T4, YELLOW) |
| **Перший ворог і смертельний бій — 2026-10-07** | [[ADR-024-Lethal-Fights-And-First-Enemy]] (прийнято) · [[Plans/2026-10-07-First-Enemy-Lethal-Fight]] (`approved`) · [[Plans/2026-10-07-City-Encounter-Options]] (варіанти першого бою; напрям «ворог» обрав Santos) · [[PROPOSAL-First-Enemy]] (T7; Q1–Q5 у каноні, [[Lore]]) · [[Research/2026-10-07-Blood-And-Lethal-Rating]] (бриф T3) · [[Art/2026-10-07-Blood-Visual-Language]] (T6, `draft`) |
| **Чекають Santos — 2026-10-07** | [[Tech/2026-10-07-M3-Acceptance-Checklist]] (T8, порядок приймання `f27fd67` на M3) |
| **Змерджений пакет #183** | [[Plans/2026-10-05-Parkour-Tricks-And-Quality]] · [[2026-10-05-City-Parkour-Tricks]] · [[2026-10-05-Trick-Motion]] · [[2026-10-05-Graphics-Quality-And-Surface-Filtering]] · [[2026-10-05-Tricks-And-Quality-Review]] · [[2026-10-05-Traversal-And-Surface-Review]] — wall kick, landing roll, профілі Low/Medium/High |
| **Змерджений пакет #170** | [[Plans/2026-10-04-Combat-Control]] · [[Plans/2026-10-04-City-First]] · [[Plans/2026-10-04-City-Style-Match]] — керування, прохідний квартал і його стиль |
| **Історичний план виробництва** | [[2026-10-03-Production-Plan]] — початкові етапи; не поточне призначення |
| **Історичний спринт арен** | [[2026-10-03-Sprint-Arenas-VFX]] — тверда арена, три карти день/ніч, VFX, меню (смуги A–I) |
| **Зріз UI та живої води** | [[2026-10-04-T1-Playable-Water-Slice|Рішення й перевірки 2026-10-04]] — план реалізації, живі стійки, сліди героїв, вода та власний голос |
| **Камера й контакт стоп** | [[Meetings/2026-10-04-T1-Camera-Foot-Contact|Продовження 2026-10-04]] — читабельність суперника, опора ніг і межі перевірки |
| **Комфорт гри** | [[Meetings/2026-10-04-T1-Comfort|Наступний зріз 2026-10-04]] — гучність, тряска, читабельна довідка та ізоляція вводу меню |
| **Вільний рух і кінцівки** | [[Meetings/2026-10-04-T1-Free-Movement-Limbs|Рішення 2026-10-04]] — основа руху й ударів перевірена; розширення гарпуна, запасу та залишених мотузок має технічний GREEN; [PR #167](https://github.com/santos-va/nooneisreal/pull/167), змерджено |
| **Стійка й меч Choko** | [[Meetings/2026-10-04-T1-Choko-Stance-Sword|Рішення 2026-10-04]] — один меч, видима передача між руками й зібрана поза; [PR #168](https://github.com/santos-va/nooneisreal/pull/168), технічний GREEN, змерджено |
| **Prototype 0.3** | [[2026-10-03-Prototype-0.3-Free-Movement]] — вільний 3D-рух із lock-on |
| **Меню «погляд з даху»** | [[2026-10-03-Main-Menu-Skyline]] · [[2026-10-03-Character-Select]] — історія меню |
| Платформи та UI | [[05-Platforms-Input]] · [[06-UI-UX]] · [[07-Audio]] |
| Персонажі | [[Choko]] · [[Skea]] · [[Roster]] |
| Світ | [[Cronshift]] · арени [[Stage-River]] · [[Stage-Bazaar]] · [[Stage-Fountain]] · [[Lore]] · [[2026-10-05-Clocktower-Trace]] · [[2026-10-05-Lower-Mark]] · пропозиції Кліо [[PROPOSAL-Story-Arc]] · [[PROPOSAL-First-Enemy]] · [[PROPOSAL-Quests-And-City-Events]] |
| Арт | [[Style-Guide]] · [[Screenshots]] · [[Textures-Registry]] · [[Backgrounds]] · [[Pipeline-2D-to-3D]] · [[Prompts]] · [[VFX-Direction]] · [[Higgsfield-Pipeline]] · [[Asset-Manifest]] · [[Prompt-Library]] · [[Arenas-360-Prompts]] |
| Техніка | [[Architecture]] · [[Active-Ragdoll]] · [[Cel-Shading]] · [[Build-and-Run]] · [[Export-Platforms]] · [[Testing]] · [[Animation-Plan]] · [[Library]] |
| Рішення | [[ADR-001-Engine-Godot]] · [[ADR-002-2.5D-First]] · [[ADR-003-Docs-As-Wiki]] · [[ADR-004-Physics-Is-Presentation]] · [[ADR-005-Grapple-Charges]] · [[ADR-006-Equal-Kit-Structure]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-008-Audio-Sourcing]] · [[ADR-009-Solo-Keyboard-Layout]] · [[ADR-010-City-Name-Cronshift]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[ADR-012-Menu-As-3D-Diorama]] · [[ADR-013-License-Check-At-Release]] · [[ADR-014-Free-Movement-Layout]] · [[ADR-015-Solo-Camera-Behind-Fighter]] · [[ADR-016-Player-Decides-What-Body-Decides-How]] · [[ADR-017-Post-Ragdoll-Position]] · [[ADR-018-Camera-Frames-Fight-With-Air]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]] · [[ADR-020-Camera-Continuity-And-Impact]] · [[ADR-021-Codex-Coworker-Adapter]] (запропоновано) · [[ADR-022-Combat-Control-And-Match-Resources]] · [[ADR-023-City-First-Exploration]] · [[ADR-024-Lethal-Fights-And-First-Enemy]] |
| Ресерч | [[2026-10-02-Engine-Physics]] · [[2026-10-02-Animation-Assets-Pipeline]] · [[2026-10-02-Grapple-Input-UI]] |
| Процес | [[constitution]] · [[state]] · [[recurring_class_register]] · [[2026-10-02-Kickoff]] · [[2026-10-02-Prototype-0.1]] · [[2026-10-02-Characters-Interview]] · [[2026-10-02-Skea-Kit-and-Balance]] · [[2026-10-02-Art-Direction-and-Pipeline]] |

## Ролі агентів

T1 Дедал (план) · T2 Гефест (код) · T3 Архімед (факти/числа) · T4 Феміда (аудит) ·
T5 Арес (бій) · T6 Аполлон (арт/звук/Higgsfield) · T7 Кліо (лор/вікі) · T8 Гермес (платформи/UX).
Тіла — `roles/*.md`, аляси — `tools/hooks/roles.map`, `make roles`.

## Related
- [[state]] · [[constitution]] · [[Roadmap]] · [[2026-10-02-Kickoff]] · [[Meetings/2026-10-07-T1-Orchestration-Session]]
