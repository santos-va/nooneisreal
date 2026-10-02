# No One Is Real — адаптер Claude Code

**Це не конституція.** Спільний закон живе в `docs/system/constitution.md` — клієнт-
нейтральний, одна копія, читають усі клієнти. Цей файл описує рівно одне: **якими
механізмами Claude Code його виконує**. Тіла правил сюди не копіюються.

Проєкт: 3D cel-shaded аніме-файтинг на арені в стилі Naruto Ultimate Ninja Storm,
Godot 4.7 (GDScript), active ragdoll, гарпун на зарядах. Бійці — Choko і Skeasse,
місто — Kronshift. Арт генерується в Higgsfield, 3D — Meshy через Higgsfield MCP.
Документація — Obsidian-вікі в `docs/` з wikilinks.

## Що вантажиться саме, без твоєї участі

| подія | ядро (спільне) | обгортка Claude | що робить |
|---|---|---|---|
| UserPromptSubmit | `tools/hooks/state_header.sh` | `.claude/hooks/inject-state.sh` | перші 25 рядків `docs/system/state.md` + вік файла в контекст |
| UserPromptSubmit | `tools/hooks/role_posture.sh` | `.claude/hooks/role-posture.sh` | Santos назвав роль → нагад узяти поставу з `roles/` |
| PostToolUse `*.gd` | `tools/hooks/gd_check.sh` | `.claude/hooks/gd-quickcheck.sh` | `godot --headless --check-only` одразу; без бінаря — каже «не дивився» |

**Логіка живе в `tools/hooks/`, обгортка — в `.claude/hooks/`.** Правка поведінки хука
йде в ядро. Хуки fail-open за задумом — вони помічники; межа — гейти і `permissions.deny`
у `.claude/settings.local.json` (не в git).

## Скіли

**Рольові** — `t1-dedal` · `t2-hefest` · `t3-arhimed` · `t4-femida` · `t5-ares` ·
`t6-apollon` · `t7-klio` · `t8-hermes`. Тіло лежить у `roles/<name>.md`; `SKILL.md` —
шим: тригер + вказівник. Аляси активації — `tools/hooks/roles.map` (спільне місце, не
під адаптером). Перейменування ролі — один рядок там.

**Проєктні** — `higgsfield-game-art` (промпти і реєстрація ассетів, Аполлон) ·
`game-ui-design` (меню/HUD на кожному пристрої, Гермес) · `godot-fighting-dev`
(GDScript, сцени, фізика бою, Гефест) · `docs-librarian` (вікі, журнали, wikilinks, Кліо).

## Агенти (Agent tool)

`.claude/agents/<роль>.md` — по одному на роль, кожен першим читає `roles/<роль>.md`.
Інструменти обрізані за роллю: Архімед і Феміда — тільки читання (їхній бриф/вердикт
повертається текстом); Аполлон не має `generate_*` — кредити витрачає лише головна сесія
після слова Santos. Sub-агент — зручність адаптера, не вимога закону: клієнт без них
робить той самий ланцюг послідовно.

## Тон

Українською зі Santos. **Число або шлях подається разом із командою, якою отриманий**:
не «12 скриптів», а «`find game -name '*.gd' | wc -l` → 12». Три рядки за замовчуванням;
розгортаємось, коли Santos питає деталь або коли є RED.

## Старт / закриття сесії

**Старт:** шапка `state.md` прийде хуком; глибше — `Read docs/system/state.md`, потім
`docs/system/constitution.md`, потім `roles/<роль>.md` за префіксом Santos (без
префікса — T1 Дедал).

**Закриття:** записати або оновити `docs/Meetings/<YYYY-MM-DD>-<slug>.md` (що
обговорили · що вирішили · що відкладено) і `docs/system/state.md` у межах повноважень
своєї ролі. Рішення — `docs/Decisions/ADR-NNN-*.md`. Сесія без журналу — не відбулась.

## Тверді правила — коротко, тіла в конституції

- **Кредити Higgsfield** — ніколи без явного слова Santos; перед генерацією `balance`.
- **Кожен ассет** у `game/assets/` — рядок у `docs/Art/Textures-Registry.md` (id, джерело,
  модель, промпт, ліцензія, використання). Гейт `texture_registry_check.py`.
- **Кожна сторінка** `docs/` має `## Related`; кожен wikilink резолвиться. Гейт
  `wikilink_check.py`.
- **Коміти англійською**, наративні документи — українською.
- **Код не «готовий»** без `make check` (godot headless) і `make gates`; `rc=2` блокує.
- **Ніколи не пушити в `main`.** Гілка → Santos мерджить.
- **Red-зона:** кредити, push у `main`, видалення ассетів, публікація збірок.
