# No One Is Real — вікі проєкту

Хаб. Кожна сторінка має `## Related`; кожен `[[wikilink]]` резолвиться (гейт `make gates`).
Поточна правда — [[state]]. Закон — [[constitution]]. Журнал зустрічей — `docs/Meetings/`.

## Що це

3D cel-shaded файтинг на арені (динаміка як у *Naruto Storm*, малюнок — власний «Sketch-Cel», **не аніме**),
з Euphoria-подібним active ragdoll і гарпуном на зарядах. Персонажі — з власного аніме
Santos і товариша (лідер команди [[Choko]] — контроль часу, другий боєць [[Skea]] — Muay Thai і тіні), місто — [[Kronshift]].
Движок — Godot 4.7, GDScript ([[ADR-001-Engine-Godot]]).

## Карта

| розділ | сторінки |
|---|---|
| Бачення | [[01-Vision]] · [[Roadmap]] · [[Glossary]] |
| Бій | [[02-Combat-System]] · [[03-Skills-Framework]] · [[04-Grapple-System]] · [[08-Balance]] |
| **План виробництва** | [[2026-10-03-Production-Plan]] — старт нової сесії |
| **Prototype 0.3** | [[2026-10-03-Prototype-0.3-Free-Movement]] — вільний 3D-рух із lock-on |
| **Меню «погляд з даху»** | [[2026-10-03-Main-Menu-Skyline]] · [[2026-10-03-Character-Select]] — ланцюжок issues у [[state]] |
| Платформи та UI | [[05-Platforms-Input]] · [[06-UI-UX]] · [[07-Audio]] |
| Персонажі | [[Choko]] · [[Skea]] · [[Roster]] |
| Світ | [[Kronshift]] · [[Stage-River]] · [[Lore]] |
| Арт | [[Style-Guide]] · [[Textures-Registry]] · [[Backgrounds]] · [[Pipeline-2D-to-3D]] · [[Prompts]] · [[VFX-Direction]] · [[Higgsfield-Pipeline]] · [[Asset-Manifest]] · [[Prompt-Library]] |
| Техніка | [[Architecture]] · [[Active-Ragdoll]] · [[Cel-Shading]] · [[Build-and-Run]] · [[Export-Platforms]] · [[Testing]] · [[Animation-Plan]] · [[Library]] |
| Рішення | [[ADR-001-Engine-Godot]] · [[ADR-002-2.5D-First]] · [[ADR-003-Docs-As-Wiki]] · [[ADR-004-Physics-Is-Presentation]] · [[ADR-005-Grapple-Charges]] · [[ADR-006-Equal-Kit-Structure]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-008-Audio-Sourcing]] · [[ADR-009-Solo-Keyboard-Layout]] · [[ADR-010-City-Name-Cronshift]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[ADR-012-Menu-As-3D-Diorama]] · [[ADR-013-License-Check-At-Release]] |
| Ресерч | [[2026-10-02-Engine-Physics]] · [[2026-10-02-Animation-Assets-Pipeline]] · [[2026-10-02-Grapple-Input-UI]] |
| Процес | [[constitution]] · [[state]] · [[recurring_class_register]] · [[2026-10-02-Kickoff]] · [[2026-10-02-Prototype-0.1]] · [[2026-10-02-Characters-Interview]] · [[2026-10-02-Skea-Kit-and-Balance]] · [[2026-10-02-Art-Direction-and-Pipeline]] |

## Ролі агентів

T1 Дедал (план) · T2 Гефест (код) · T3 Архімед (факти/числа) · T4 Феміда (аудит) ·
T5 Арес (бій) · T6 Аполлон (арт/звук/Higgsfield) · T7 Кліо (лор/вікі) · T8 Гермес (платформи/UX).
Тіла — `roles/*.md`, аляси — `tools/hooks/roles.map`, `make roles`.

## Related
- [[state]] · [[constitution]] · [[Roadmap]] · [[2026-10-02-Kickoff]]
