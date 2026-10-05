# No One Is Real — вікі проєкту

Хаб. Кожна сторінка має `## Related`; кожен `[[wikilink]]` резолвиться (гейт `make gates`).
Поточна правда — [[state]]. Закон — [[constitution]]. Журнал зустрічей — `docs/Meetings/`.

## English handoff — 2026-10-04

[[Handoff/2026-10-04-Start-Here|Start here]] · [[Handoff/2026-10-04-Delivery-Ledger|Merged delivery ledger]] · [[Handoff/2026-10-04-Remaining-Work|Remaining work]] · [[Handoff/2026-10-04-Decisions-And-Validation|Decisions and validation]] · [[Meetings/2026-10-04-Current-State-Cleanup|Current reconciliation]]. Snapshot: merged main `2c50938` (#170). Historical evidence and unfinished acceptance are separate from current delivery.

## Що це

Стилізований 3D-файтинг із наявними аренами та першим прохідним районом міста. Напрям — спільний світ Cronshift, місця боїв у якому визначатимемо після побудови районів. Малюнок — власний «Sketch-Cel»; чинні еталони — найсвіжіші окремі текстури/вирізки, старі панорами — чернетки. Active ragdoll є презентацією, гарпун має скінченний запас. Персонажі — з власного аніме
Santos і товариша (лідер команди [[Choko]] — контроль часу, другий боєць [[Skea]] — Muay Thai і тіні), місто — [[Cronshift]].
Движок — Godot 4.7, GDScript ([[ADR-001-Engine-Godot]]).

## Карта

| розділ | сторінки |
|---|---|
| Бачення | [[01-Vision]] · [[Roadmap]] · [[Glossary]] |
| Бій | [[02-Combat-System]] · [[03-Skills-Framework]] · [[04-Grapple-System]] · [[08-Balance]] |
| **Поточний старт** | [[state]] · [[Handoff/2026-10-04-Start-Here]] — актуальний зріз і межі приймання |
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
| Світ | [[Cronshift]] · арени [[Stage-River]] · [[Stage-Bazaar]] · [[Stage-Fountain]] · [[Lore]] · [[2026-10-05-Clocktower-Trace]] |
| Арт | [[Style-Guide]] · [[Screenshots]] · [[Textures-Registry]] · [[Backgrounds]] · [[Pipeline-2D-to-3D]] · [[Prompts]] · [[VFX-Direction]] · [[Higgsfield-Pipeline]] · [[Asset-Manifest]] · [[Prompt-Library]] · [[Arenas-360-Prompts]] |
| Техніка | [[Architecture]] · [[Active-Ragdoll]] · [[Cel-Shading]] · [[Build-and-Run]] · [[Export-Platforms]] · [[Testing]] · [[Animation-Plan]] · [[Library]] |
| Рішення | [[ADR-001-Engine-Godot]] · [[ADR-002-2.5D-First]] · [[ADR-003-Docs-As-Wiki]] · [[ADR-004-Physics-Is-Presentation]] · [[ADR-005-Grapple-Charges]] · [[ADR-006-Equal-Kit-Structure]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-008-Audio-Sourcing]] · [[ADR-009-Solo-Keyboard-Layout]] · [[ADR-010-City-Name-Cronshift]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[ADR-012-Menu-As-3D-Diorama]] · [[ADR-013-License-Check-At-Release]] · [[ADR-014-Free-Movement-Layout]] · [[ADR-015-Solo-Camera-Behind-Fighter]] · [[ADR-016-Player-Decides-What-Body-Decides-How]] · [[ADR-017-Post-Ragdoll-Position]] · [[ADR-018-Camera-Frames-Fight-With-Air]] · [[ADR-022-Combat-Control-And-Match-Resources]] · [[ADR-023-City-First-Exploration]] |
| Ресерч | [[2026-10-02-Engine-Physics]] · [[2026-10-02-Animation-Assets-Pipeline]] · [[2026-10-02-Grapple-Input-UI]] |
| Процес | [[constitution]] · [[state]] · [[recurring_class_register]] · [[2026-10-02-Kickoff]] · [[2026-10-02-Prototype-0.1]] · [[2026-10-02-Characters-Interview]] · [[2026-10-02-Skea-Kit-and-Balance]] · [[2026-10-02-Art-Direction-and-Pipeline]] |

## Ролі агентів

T1 Дедал (план) · T2 Гефест (код) · T3 Архімед (факти/числа) · T4 Феміда (аудит) ·
T5 Арес (бій) · T6 Аполлон (арт/звук/Higgsfield) · T7 Кліо (лор/вікі) · T8 Гермес (платформи/UX).
Тіла — `roles/*.md`, аляси — `tools/hooks/roles.map`, `make roles`.

## Related
- [[state]] · [[constitution]] · [[Roadmap]] · [[2026-10-02-Kickoff]]
