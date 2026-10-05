# 2026-10-05 — звірка стану, issues і гілок

**Хто:** Santos · T1 Дедал · T2 Гефест · T4 Феміда · T7 Кліо.
**Контекст:** Santos доручив звірити поточний стан і прибрати підтверджено застарілі issues/гілки. Issues звірено, state скорочено зі збереженням незмінного архіву. Під час доставки виявлено паралельний merge PR #181; документальні зміни перенесено на окрему гілку від нового main. Завершальні refs та окремий PR #182 підтверджені; CI нового документального head очікується.

## Що перевірили

T7 прочитала поточні [[state]], [[Handoff/2026-10-04-Start-Here]], [[index]] та `/workspace/nooneisreal-evidence/repo-cleanup/github-inventory.json`. Інвентар містить 13 issues для звірки, один запис у `open_prs` — [PR #181](https://github.com/santos-va/nooneisreal/pull/181) з «Нижньою позначкою» — і 35 записів у вибірці merged PRs. Це знімок на початку cleanup, не твердження про стан після наступних дій. Поля `state` у цьому export не заповнені; належність до open/merged береться з відповідної вибірки, остаточні мутації потребують свого receipt.

Сторінка Start-Here датована 2026-10-04 і містила заголовки Current для тодішньої PR #172 та раннього міського зрізу. Історичні факти не переписані: додано явний датований покажчик до поточного state й позначено старі секції як знімок на їхню дату. index тепер відрізняє чинний маршрут від історичного англомовного handoff.

## Що вирішили

- Перед скороченням state T7 створила [[Handoff/2026-10-05-State-Before-Reconciliation]] **байт у байт**, без доданого заголовка чи переписаної історії. Розмір **55752 bytes**, SHA-256 `184d9cde905b69e751111b5792a4589f0e765dc0398ff9dfa4fdb8cfd4c2ee25`. `Path.read_bytes()` і пряме порівняння вихідного та нового файла дали true; архів після цього не редагується.
- T2 повідомлено про готовий архів до скорочення execution-частини state. Шапка, фаза й поточний маршрут лишаються смугою T1; T7 state не змінює.
- Датовані докази й попередні приймання зберігаються. Наявність старого незакритого чекбокса сама по собі не доводить незавершений код; наявність коміту сама по собі не доводить виконання всіх вимог issue.
- На початку PR #181 обліковували як відкритий за тодішнім інвентарем. Самі локальні перевірки не означають merge; фактичний паралельний merge Santos, виявлений під час доставки, записано окремо нижче. Cleanup не означає встановлення Mac або зміну gameplay.

## Результати віддаленого cleanup

Координатор повідомив про видалення remote `claude/practical-hopper-rmfgi4` з exact-old lease на `eb8e7cd83a28378158fe1e362f35eba6c6efbc5c`. T7 окремо виконала read-only `git ls-remote --heads origin claude/practical-hopper-rmfgi4`: команда завершилась rc0 без рядків, remote ref відсутній. `branches-before.json` підтверджує, що вершина була предком main й не мала власних невлитих комітів.

`local-deletions.json` та фактичний `git branch -vv` підтверджують три видалені локальні гілки:

| Гілка | Збережена в історії вершина | Підстава |
|---|---|---|
| `codex/character-expression-combat` | `246927b7a88237761edba9594cd3efadfe5013dc` | Предок main |
| `codex/city-story-expansion` | `9f6418b5a843e84a767284cad661840378776bfe` | Предок main |
| `work` | `94a09a6f80cbeba48e96e80915d1e13ddb237275` | Предок main |

Після первинного прибирання worktree залишався на `codex/city-lower-route` (`055b1d8`), яку тоді обліковували як активний PR #181. `git worktree list --porcelain` показував один worktree. Пізніший перенос після виявленого merge описано нижче. Збережено remote main та `textures/santos-pack` (`6bd36a2`): інвентар показує **два невлиті коміти** у textures-гілці, тому вона не є безпечним кандидатом на видалення як уже інтегрована історія.

T7 особисто прочитала `issues-after.json`: повторний fetch усіх **13 issues** підтвердив **4 закриття й 9 відкритих пунктів**. Для кожного `body_exact=true` і `original_preserved=true`: авторські bodies залишені незмінним суфіксом, додана датована актуалізація з посиланнями на джерела.

| Результат | Issues | Підстава й збережена межа |
|---|---|---|
| Закриті `completed` | [#6](https://github.com/santos-va/nooneisreal/issues/6), [#14](https://github.com/santos-va/nooneisreal/issues/14), [#36](https://github.com/santos-va/nooneisreal/issues/36) | Завершені вузькі промпти/кошторис, style-проба та T1/T5 передача рухів; це не приймання всього арту/меню |
| Закритий `not_planned` | [#52](https://github.com/santos-va/nooneisreal/issues/52) | Старий чекліст замінений пізнішими хвилями; не оголошено, що всі запуски особисто прийняв Santos |
| Лишені відкритими | [#4](https://github.com/santos-va/nooneisreal/issues/4), [#7](https://github.com/santos-va/nooneisreal/issues/7), [#8](https://github.com/santos-va/nooneisreal/issues/8), [#11](https://github.com/santos-va/nooneisreal/issues/11) | Живе меню-діорама, runtime інтеграція й окремий rooftop-вибір героя |
| Лишені відкритими | [#12](https://github.com/santos-va/nooneisreal/issues/12), [#19](https://github.com/santos-va/nooneisreal/issues/19) | Залишкові runtime/asset references Kronshift та декоративні дрони-якорі |
| Лишені відкритими | [#33](https://github.com/santos-va/nooneisreal/issues/33), [#38](https://github.com/santos-va/nooneisreal/issues/38), [#42](https://github.com/santos-va/nooneisreal/issues/42) | Уточнені залишки арту героїв, motion-only сигіл, лист поз/декаль та runtime quality/platform вимоги |

Точні докази для кожного рішення — [[Audit/2026-10-05-Repository-Reconciliation]]. Закриття вузького історичного issue не переносить його невиконаний ширший результат у completed.

Для gameplay-коміту PR #181 T1 окремо звірив GitHub API: [CI run 37305132448](https://github.com/santos-va/nooneisreal/actions/runs/37305132448), запуск №806, completed SUCCESS для `055b1d8`. Це результат gameplay-коміту до cleanup; новий документальний commit не названо перевіреним цим запуском.

## Паралельний merge і перенесення доставки

Після первинного cleanup push T1 виявив, що Santos уже змерджив [PR #181](https://github.com/santos-va/nooneisreal/pull/181) **2026-10-05 о 11:54:27 UTC**: merge `611c85d26defdaf1d58ba03b0c2149931158eaa7`. T7 особисто прочитала `git show --format=fuller` цього merge та `origin/main`; обидва підтверджують нову базу. Старий запис «PR відкритий» був застарілим станом перед цією повторною звіркою, не фактом про чинний main.

За звітом T1, cleanup commit `2df1a1c` запушили після автоматичного видалення head-гілки PR #181, тож push відтворив remote `codex/city-lower-route`. Щоб не доставляти документацію через вже закритий PR, T1 створив `codex/repository-reconciliation` від `611c85d` і переніс документальний commit як `499e156`. T7 перевірила `git rev-parse 2df1a1c^{tree} 499e156^{tree}`: обидва дерева мають SHA `b628659533203262b5c44526132303a24d8f84be`. Перенесення зберегло вміст; наступні правки лише виправляють датований стан доставки.

Фінальний cleanup доставляється окремим [PR #182](https://github.com/santos-va/nooneisreal/pull/182) із `codex/repository-reconciliation`. T1 створив його draft на час фінальних документальних правок; після їх доставки переводить на review. CI остаточного документального head ще очікується, успішний запуск #806 не приписується цьому PR.

T7 особисто прочитала `branches-final.json` та повторила `git branch -vv` і `git ls-remote --heads origin codex/city-lower-route`: локально тільки cleanup-гілка, відтворений старий remote ref відсутній. Receipt фіксує push `499e156` на нову гілку, видалення старої local після тотожності дерев і три збережені remote heads: `main` (`611c85d`), `codex/repository-reconciliation`, `textures/santos-pack` (`6bd36a2`). За виконаним T1 exact-old lease видалено тільки очікувану вершину старої гілки. Фінальний docs commit змінить вершину cleanup-гілки, не склад збережених гілок.

`issues-final-after-merge.json` T7 прочитала й перевірила програмно: усі **13** повторних результатів мають `body_exact=true`, `original_preserved=true`, `merged_181_acknowledged=true`. Notes тепер визнають фактичний merge #181; початкові bodies залишені незмінними. Рішення збережені: **4 closed / 9 open** з тими самими state_reason.

## Дії

- [x] T7 · незмінний архів state з перевіреним хешем; T2 повідомлено перед редагуванням.
- [x] T7 · навігація index/Start-Here відокремлює поточну правду від датованої історії.
- [x] T1/T7 · завершені видалення гілок зі збереженими вершинами й незалежною read-only перевіркою.
- [x] T1/T4 · остаточна звірка issues/PRs, підтверджені рішення й receipts cleanup; T7 прочитала повторний fetch усіх 13 результатів.
- [x] T2/T1 · компактний актуальний state зі збереженими посиланнями на історію й межі приймання; T7 прочитала новий зміст.
- [x] T7 · первинний перелік дій та повторна перевірка архівного хешу.
- [x] T1/T7 · PR #182, остаточні refs і повторний issue-note receipt після виявленого merge; локальну звірку завершено.
- [ ] GitHub · CI остаточного документального head PR #182; merge лишається за Santos.

## Межі cleanup і перевірок

T7 повторно обчислила SHA-256 архіву: ті самі 55752 bytes і `184d9cde905b69e751111b5792a4589f0e765dc0398ff9dfa4fdb8cfd4c2ee25`. `git diff --name-only HEAD -- game tools` не повернув жодного файла: ця звірка не додає gameplay. Локальні 85/0 належать попередній «Нижній позначці», не новому прогону в cleanup. T7 перевірила wikilinks і `git diff --check`; власноруч прочитала первинний `gates.log/.rc` — зелена батарея, rc0. Це перевірка попереднього cleanup-кандидата; після виправлення доставки T1 повторює документальні гейти. Merge main, платна генерація, видалення assets і встановлення Mac не виконувалися цією смугою.

## Related

- [[state]] · [[index]] · [[constitution]] · [[Handoff/2026-10-05-State-Before-Reconciliation]] · [[Handoff/2026-10-04-Start-Here]] · [[2026-10-05-Lower-Mark-Session]] · [[Plans/2026-10-05-Repository-Reconciliation]] · [[Audit/2026-10-05-Repository-Reconciliation]]
