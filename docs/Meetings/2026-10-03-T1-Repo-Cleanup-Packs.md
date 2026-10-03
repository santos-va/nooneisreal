# 2026-10-03 — T1: прибирання гілок і worktree, MegaKit на гілку паків, план паків approved

**Хто:** Santos · T1 Дедал (Mac, локально)
**Контекст:** Santos побачив купу тек `nooneisreal-*` у `~/Documents` і попросив звірити, чи нічого з текстур не загубилось дорогою на GitHub.

## Що обговорили
- Теки `~/Documents/nooneisreal-*` — не дзеркала GitHub, а git worktree локальних сесій: `ls ~/Documents | grep -c nooneisreal-` → 11, ще ~11 у `/private/tmp`. Їхні гілки вже були в `main` (`git rev-list --count origin/main..<гілка>` → 0 у кожної). `.gitignore` їх не прибере — теки лежать поруч із репо, а не в ньому.
- `~/Documents` синхронізується з iCloud (xattr `com.apple.file-provider-domain-id`) → `git status --porcelain | grep -c ' 2'` → 59 дублікатів « 2» (клас 4 у [[recurring_class_register]]).
- GitHub уже зносить гілку після мержу: `gh api repos/santos-va/nooneisreal -q .delete_branch_on_merge` → `true`. Хвости лишаються лише від гілок, допушених після мержу.
- MegaKit `[Standard]` — за власним `License_Standard.txt` безкоштовна версія, CC0 1.0. Santos: «випадково задонатив, все нормально».
- Creative Trio ×9 FBX лежать на публічному репо (`gh repo view --json visibility` → `PUBLIC`) без ліцензії й без палітр.
- T6 на момент перевірки ще нічого не закомітив (`claude/apollon-packs-wave0` = `origin/main`); реєстр на `main` чистий: `python3 tools/gates/texture_registry_check.py` → 144/144, незареєстрованих 0.

## Що зроблено
- Santos руками (команди T1): 11 тек `~/Documents/nooneisreal-*`, worktree у `/private/tmp` і `~/dev/nir-fx` знесено (крім живого T6); `main` підтягнуто (`git rev-list --count main..origin/main` 123 → 0); локальні гілки 53 → 2 (`main` + T6); на GitHub знесено `claude/apollon-vfx-lane-d` (PR #112 змерджено). `git ls-remote --heads origin` → 3 гілки: `main`, `textures/santos-pack`, `claude/practical-hopper-rmfgi4`.
- T1 за словом Santos «сам зроби все»: MegaKit Standard на `textures/santos-pack` → `6210890`, тека `tools/packs/Fantasy_Props_MegaKit_Standard/`: лише `Exports/glTF` (94 `.gltf` + 94 `.bin` + 13 `.png`, 43 МБ) і `License_Standard.txt`. Архів 150 МБ цілим не проходить ліміт GitHub 100 МБ; FBX, OBJ і нормалі UE не взято. Усі 546 зовнішніх посилань у `.gltf` резолвляться (`python3`). Тимчасовий worktree у scratchpad знесено.

## Що вирішили
- План [[2026-10-03-Santos-Packs-Arenas]] → `approved`: Р1 = A, Р2 = A, Р3 = A (Santos «ааа»).
- За Р2 = A гілка `textures/santos-pack` — склад сирців паків: у `main` не мерджиться і живе довше за робочі гілки.

## Що відклали / відкриті питання
- Репо поза iCloud (`~/dev/nooneisreal`) і правило «worktree — лише в scratchpad, знести після пушу» — пропозиція ADR, чекає слова Santos.
- `claude/practical-hopper-rmfgi4` — 5 комітів смуги C поза `main` (`git rev-list --count origin/main..origin/claude/practical-hopper-rmfgi4` → 5), PR немає.
- На Mac не в git: 4 SFX дрона `game/assets/audio/sfx/drone_*.ogg` (рядків у реєстрі — 0), `tools/audio/soundtracks by Santos/`; копії 9 FBX і KayKit-zip у корені `tools/` — дублі гілки паків.

## Дії
- [ ] Santos · палітри `CT_Pallete.png`, `EK_Pallete.png`, `CT_Rocks_Palette.png` і `License.txt` кожного паку Creative Trio — у `~/Downloads` (зараз `mdfind -name CT_Pallete` → 0) · план § Ф0.1
- [ ] T6 Аполлон · PR з `claude/practical-hopper-rmfgi4`; дрони в [[Textures-Registry]]; хвиля T6-0 · `git rev-list --count origin/main..origin/claude/practical-hopper-rmfgi4` → 0
- [ ] T3 Архімед · ліцензії Creative Trio і MegaKit · план § Ф0.2
- [ ] T2 Гефест · контакт-лист паків (Ф0.3), далі Ф1–Ф4 · план

## Related
- [[state]] · [[2026-10-03-Santos-Packs-Arenas]] · [[2026-10-03-T1-Santos-Packs]] · [[recurring_class_register]] · [[Textures-Registry]]
