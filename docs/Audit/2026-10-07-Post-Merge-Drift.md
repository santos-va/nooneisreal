# Аудит дрейфу: main після merge #183 проти документів

**Дата:** 2026-10-07 · **Роль:** T4 Феміда · **Вердикт: RED.** Загальний вердикт не може бути вищим за найгірший пункт. RED стоїть через п. 3: батарея каже «БАТАРЕЯ ЗЕЛЕНА», хоча `.gd` ніхто не перевіряв. Цього класу помилок немає в реєстрі, і механізму проти нього немає.

> Текст — T4 Феміда (sub-agent з інструментами лише для читання). Записав T1 Дедал-оркестратор без змін змісту, за механізмом адаптера «вердикт повертається текстом» (`CLAUDE.md`, розділ «Агенти»). T1 особисто відтворив ключову пробу п. 3: `GODOT_BIN=/bin/false bash tools/gates/gd_check_all.sh` → «перевірено: 119 · не парсяться: 0», rc0.

**Визнаю першим рядком:** цей клас T4 помітила ще 2026-10-03 (див. [[2026-10-03-Launch-5-6]], розділ «Спостереження»), а у двох раніших аудитах я назвала rc0 «чесним». До [[recurring_class_register]] клас так і не потрапив. Це пропуск ролі T4.

## Від чого відштовхувався аудит (перевірено в цій сесії)

- `git rev-parse HEAD main origin/main` → три рази `f27fd679ccb1…`. `git log --oneline main..HEAD` → порожньо. Гілка `claude/t1-orchestration-2026-10-07` дорівнює main.
- `git rev-parse --is-shallow-repository` → `true`, `git rev-list --count HEAD` → 336. Історія до `799e650` недоступна.
- Godot не запускала. `command -v godot` → rc1, `GODOT_BIN` порожній.

## Підсумок

| № | Пункт | Вердикт |
|---|---|---|
| 1 | Статус доставки #183 | YELLOW: сама доставка GREEN, state.md застарів |
| 2 | Застарілі твердження в state, index, Roadmap і статусах планів | YELLOW |
| 3 | Клас «гейт зелений без вимірювання» | **RED** |
| 4 | Старі відкриті знахідки (14.8348%, ADR-017) | YELLOW: у коді досі відкриті, із поточної правди випали |
| 5 | «Ще не завершено» проти відкритих issues | GREEN, з однією YELLOW-приміткою |

## 1. Статус доставки — YELLOW

Усе, що T1 отримав через MCP, T4 підтвердила сама через git і GitHub REST.

- `git log --merges -3` → `f27fd67 2026-10-05 16:28:43 +0300 Merge pull request #183 from santos-va/codex/parkour-tricks-visual-quality`, далі `abce638` (#182) і `611c85d` (#181).
- `gh api repos/santos-va/nooneisreal/pulls/183` → `"merged":true,"merged_at":"2026-10-05T13:28:44Z","merge_commit_sha":"f27fd679…"`.
- `gh api …/actions/runs?head_sha=f27fd67…`:
  - `37317106289 ci … completed success`;
  - `37317106267 macOS main app … completed success`.
  - Jobs ci: `docs & roles gates`, `macOS updater safety` (ubuntu і macos), `godot smoke + playable regressions` — усі success.
  - Jobs macOS: `build`, `verify-macos`, `publish` — усі success.
- `gh api …/pulls?state=open` → порожньо.
- `git ls-remote --heads origin` і `gh api …/branches` → тільки `main` і `textures/santos-pack`.
- `gh api …/releases` → `macos-f27fd679… draft=false pre=true 2026-10-05T13:46:03Z`. Отже, збірку з merge **опубліковано** як prerelease.

**Що застаріло в state.md.** Файл востаннє змінювався в `3970041` о 13:18:59Z, тобто за 10 хвилин до merge (`git log -2 -- docs/system/state.md`). Конкретно:

- рядок 3 («переходить до draft review… на базі `abce638`»);
- рядок 8 («Нові трюки, анімації та quality settings **ще не змерджені**»);
- рядок 22 («База `abce638`»);
- рядки 44–46 («▶ Хвиля… передається на draft review… merge належить Santos»).

Опублікований prerelease `macos-f27fd67` у state взагалі не згаданий. Фраза «встановлення на Mac не підтверджене» лишається правдою.

**Що T4 перевірити не змогла.** Шлях до доказів T2 `/workspace/nooneisreal-evidence/tricks-quality/final/` у цьому контейнері не існує (`ls` → No such file). Узгоджується тільки число файлів: `find game -name '*.gd' -not -path '*/.godot/*' -not -path '*/addons/*' | wc -l` → 119, як у твердженні «119 GDS».

## 2. Застарілі твердження — YELLOW

- **Профілі якості вже в коді.** `ls game/scripts/core/QualityProfile.gd game/scripts/core/GraphicsSettings.gd` → обидва файли є, прийшли в `3970041`. Ресурс QualityProfile.gd задає `low/medium/high`: scale 0.75/0.85/1, MSAA off/2×/4×, позначка PLACEHOLDER. `game/project.godot:29` реєструє автозавантаження `GraphicsSettings`.
- **Remaining-Work, рядок 32:** «Cloth and graphics quality profiles — planned». Файл — датований снапшот (рядок 5: «Snapshot: 2026-10-04 … not a current assignment»), сам по собі він не порушення. Але **на нього як на чинний досі посилаються:**
  - `docs/Roadmap.md:3`: «незакриті зобов'язання — [[Handoff/2026-10-04-Remaining-Work]]»;
  - `docs/system/state.md:73` (`## Related`) — без позначки, що це історія. Хоча рядок 69 state.md називає handoff «датованими джерелами, не поточною чергою».
- **Roadmap «Чинний напрям — 2026-10-04»** (рядки 3, 10): «після злиття #170». Пункт 4 ставить у майбутнє «сюжетний вступ… збереження… NPC». А state.md:63 каже: «Перший сюжет і NPC saves уже є; їх не ставимо знову в чергу».
- **`docs/index.md:8`:** «#182 … доставляється окремим PR #182. CI … ще очікується». Насправді #182 змерджено (`abce638`), #183 теж, а сам #183 в index не згаданий. `git log -1 -- docs/index.md` → `fe5fde7`, ще до обох merge. Окремо: рядок «Рішення» (index:44) не містить існуючих ADR-019/020/021 (`ls docs/Decisions`).
- **`grep -rn -E "#183|pull/183|f27fd67" docs roles`** → жодного збігу про PR, тільки hex-кольори. Документального запису про merge немає. `ls docs/Meetings | grep 2026-10-0[67]` → rc1.
- **Статуси планів.** `grep -l 'Статус:\*\* \`approved\`' docs/Plans/*.md` → 6 планів. Для чотирьох найсвіжіших реалізація вже в main (`git merge-base --is-ancestor <c> HEAD`):
  - City-Action-Polish — `6f9881c`, PR #174 (`f24d973`);
  - Camera-Foot-Contact — `9129337`;
  - City-First — `1773ac2`;
  - Playable-Water-Slice — `9e96b64`.

  Шаблон (`Plan-Template.md:3`) має статуси `draft/approved/done`, але ці чотири досі `approved`. Parkour-Tricks-And-Quality має `done`, і це збігається з кодом; суперечить йому лише state.

## 3. «Гейт зелений без вимірювання» — RED

**Що каже код:**
- `tools/gates/gd_check_all.sh:11-14`: без бінаря друкує «ПРОПУЩЕНО… Це не «ок», це «ніхто не дивився»» і робить **`exit 0`**. Шапка скрипта прямо описує це як задум: «rc: 0 ok або пропущено без бінаря».
- `tools/gates/run_gates.sh:10-12,39`: шапка обіцяє, що «rc=2 … так само блокує», але rc0 від GDS агрегується як ok, і `finish` друкує «БАТАРЕЯ ЗЕЛЕНА».
- Це суперечить `constitution.md:65-67` (R3: «`rc=2` («не зміг виміряти») блокує»).

**Відтворення:**
- `bash tools/gates/run_gates.sh` → **rc=0**, «GDS … ПРОПУЩЕНО», «БАТАРЕЯ ЗЕЛЕНА». Повністю збігається з логом T1 `t1-gates-baseline.log` (рядки 30–34).
- `GODOT_BIN=/nonexistent bash tools/gates/gd_check_all.sh` → **rc=0**.

**Зламала гард сама.** `GODOT_BIN=/bin/false bash tools/gates/gd_check_all.sh` → «перевірено: 119 · не парсяться: 0», **rc=0**. Причина в рядку 33: файл рахується поганим, лише коли одночасно `RC≠0` **і** є текст «SCRIPT ERROR|Parse Error». Бінар, що падає без виводу (наприклад SIGSEGV, клас 6 реєстру), дає «перевірено, 0 помилок». Усередині `make check` повністю зламаний бінар зловить імпорт; падіння на окремому файлі не зловить ніхто.

**Що тримає межу.** `make check` → «godot не знайдено…», `make: *** … Error 2`, **rc=2**. R3 вимагає `make check` і `make gates` разом, тому код без Godot не можна назвати «готовим». Діра в іншому: `make gates` поодинці подається як «зелено». CI-job `docs & roles gates` (`.github/workflows/ci.yml:12-18`) запускає батарею без Godot. GDS справді виміряний лише в job `godot` через `make check-playable` → `make check` → `gd_check_all.sh` з `GODOT_BIN`. Лог CI-job T4 прочитати не змогла (`gh api …/jobs/111786512821/logs` → blob Forbidden через проксі), тому «у CI-лозі f27fd67 стоїть ПРОПУЩЕНО» лишається не перевіреним; це висновок з `ci.yml`.

**Рецидиви (кожен підтверджено grep по docs):**
- 2026-10-03: [[2026-10-03-Launch-5-6]] рядки 93–98 (там же визнано «чесно» в аудитах Launch-2-PR60 п. 2 і Launch-3 п. 2);
- 2026-10-04: `Meetings/2026-10-04-T1-Codex-Coworker.md:40` («відтворила дефект skip→зелена батарея»);
- 2026-10-04: `Plans/2026-10-04-Codex-Coworker.md:77` («повна батарея без Godot завжди відмовляє») — план у статусі `draft`, не впроваджений;
- 2026-10-07: лог T1.

Прапорця `GDS_SKIP_OK` або аналога немає (`grep -rn GDS_SKIP|SKIP_OK tools Makefile .github` → порожньо). Рядка в реєстрі немає (класи 1–11 прочитані повністю).

**Merge #183 цей гард не послабив.** `git diff --stat abce638 f27fd67 -- tools/gates Makefile .github` → тільки `playable_check.sh` +14: шість позитивних сценаріїв і два негативних контролі `--break=apply` і `--break=budget`. Це посилення, а не fail-open.

## 4. Старі відкриті знахідки — YELLOW

- **14.8348% проти 15%.** `tools/camera/framing_check.gd:86-88` досі містить «Static side@6m baseline is 14.83%, below the written 15%» і перевіряє лише «не гірше за baseline». GDD-вимога: `docs/GDD/02-Combat-System.md:500` (min 15%). `git log -1 -- tools/camera/framing_check.gd game/scripts/arena/DuelCamera.gd` → `9129337` (2026-10-04), відтоді змін немає. Знахідку ніхто не закрив.
- **ADR-017.** Рішення — крок 7.1b, кінематична траєкторія (`ADR-017…md`, «Вибір — 7.1b зараз»). У коді позиція досі береться з таза регдола: `Fighter.gd:1659` `var p := _ragdoll.pelvis_position()`, `:1663` `global_position = _ground_spot(p)`, `:1664` `_ragdoll.settled() or frame_in_state > 170`, `:1740` (KO). Не закрито.
- **Дрейф.** Обидва борги є лише в архіві `Remaining-Work.md:38-39`. `grep -n "ADR-017|14[.,]83" docs/system/state.md docs/Roadmap.md` → 0. В issues їх теж немає.

## 5. «Ще не завершено» проти issues — GREEN

- `gh api …/issues?state=open` → 4, 7, 8, 11, 12, 19, 33, 38, 42.
- `grep -o "issues/[0-9]+" docs/system/state.md` → той самий набір 9/9.
- Issue #12 досі чинний: `grep -rIl -i kronshift game --exclude-dir=.godot | wc -l` → 8.

YELLOW-примітка: #42 востаннє оновлювався `2026-10-05T12:00:12Z`, ще до merge. Про частково доставлені PLACEHOLDER-профілі там коментаря немає.

## Пропозиції (лише пропозиції)

1. **Код гейта — T2 Гефест через Santos.** `gd_check_all.sh`:
   - немає бінаря → `exit 2`;
   - `RC≠0` без розпізнаного виводу → файл рахується відмовою, а не проходом.
   - Негативні контролі в тому ж PR: `GODOT_BIN=/nonexistent` → rc2, `GODOT_BIN=/bin/false` → rc≠0.
2. **CI і процес — T1 Дедал, рішення через ADR.** Розвилка Launch-5-6: (а) поставити Godot у gates-job; (б) явна docs-only ціль, яка друкує «ДОКИ ЗЕЛЕНІ; КОД НЕ ВИМІРЯНО» і ніколи «БАТАРЕЯ ЗЕЛЕНА». Мовчазний skip-прапорець не підходить: це fail-open.
3. **Документи — T1** (state, плани), **T7 Кліо** (index, Roadmap, Related).
   - Переписати шапку state, «Поточна реалізація T2» і «▶ Хвиля» на «#183 змерджено, f27fd67, CI 37317106289/37317106267 success, prerelease macos-f27fd67 опубліковано; встановлення на M3 не підтверджене».
   - Index:8 і Roadmap:3 перевести на state «Ще не завершено» як джерело відкритих зобов'язань.
   - Перевести 4 доставлені плани в `done`.
4. **Борги в поточну правду — T1.** 14.8348%: власники Арес/Гермес вирішують «код чи число GDD», правку робить T2. ADR-017 7.1b: правка T2, кадри вставання дає Арес. Перенести в «Ще не завершено» або в issues.
5. **Реєстр — T4, у сесії з правом запису.** Два нові рядки нижче.

**Пропоновані рядки реєстру.** Цей текст пише T4. Записати його може лише T4 у сесії з правом запису; інша роль, що копіює, має зберегти авторство.

- **Клас 12.** Батарея повертає rc0 і «ЗЕЛЕНА», коли гейт не зміг виміряти (GDS без Godot; бінар, що падає без виводу, дає «перевірено N/0»). Лічильник 4: 2026-10-03 Launch-5-6 разом із Launch-2/3, 2026-10-04 Codex-Coworker, 2026-10-07 T1 baseline і проба T4 з `/bin/false`. Механізм: пропозиції 1–2. Статус ВІДКРИТО: код гейта і CI не належать T4.
- **Клас 13.** Документ, написаний у гілці доставки до merge, стверджує «не змерджено / CI очікується», а після merge Santos його ніхто не оновлює. Лічильник 2: index після #182, state після #183. Механізм (пропозиція T2): `state_anchor_check.py` → rc1, якщо state каже «не змерджен|draft review» про гілку X, а `git log --merges --format=%s` містить «from santos-va/X»; немає merge-історії (shallow) → rc2. Статус ВІДКРИТО.

## Що не перевірено

- Сирі дані T2 та їхні числа (smoke 164/19847, playable 93/0, 119 GDS/0): шлях відсутній у контейнері.
- Лог CI-job (Forbidden).
- Парс `.gd` справжнім Godot (бінаря нема, Godot не запускала за межами доручення).
- Історія `gd_check_all.sh` до `799e650` (shallow clone).
- Червона зона «публікація збірок» для автоматичного `publish` у `macos-main.yml` — поза обсягом цього аудиту.

## Related
- [[state]] · [[constitution]] · [[recurring_class_register]] · [[2026-10-05-Tricks-And-Quality-Review]] · [[2026-10-03-Launch-5-6]]
- [[Audit/2026-10-04-Camera-Foot-Contact]] · [[ADR-017-Post-Ragdoll-Position]] · [[Roadmap]] · [[index]] · [[Handoff/2026-10-04-Remaining-Work]] · [[Plans/2026-10-04-Codex-Coworker]]
