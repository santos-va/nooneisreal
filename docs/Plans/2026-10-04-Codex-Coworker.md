# План — Codex і Claude як співробітники, T1 як головне крісло

**Дата:** 2026-10-04 · **Роль:** T1 Дедал · **Статус:** `draft` (технічний спосіб інтеграції ще не прийнятий).
**Виріс з:** handoff Santos у цій сесії · [[2026-10-04-T1-Codex-Coworker]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]] · [[ADR-021-Codex-Coworker-Adapter]] (пропозиція).

## Що хоче Santos (його словами)

> «цей чат у нас буде як головне крісло … для тільки сильних і важливих рішень … для планування масштабних послідовностей … на декілька сесій інших агентів, субагентів навіть».

T1 тримає пріоритети, залежності та приймання стислих звітів. Спільна пам'ять — файли репозиторію; приватні розмови Claude не передаються автоматично. Рівні можливості означають можливості в межах призначеної ролі. Цей план — окремий процесний трек; бойова черга й комфорт на Mac не переставляються.

## Аудит і погляди

- [x] Аудит актуального main, повний state, constitution, AGENTS, роль T1, карта ролей.
- [x] Звірено попередні плани: Wave-2-Kickoff, Arena-Depth-Life, Living-Combat, Comfort; ADR-019. Ігрові рішення не змінюються.
- [x] Сусіди: відкриті PR та CI перевірено; приватні/незапушені дерева інших працівників недоступні.
- [x] Три варіанти, шість поглядів, рекомендація за мірилами гри.

### Докази цієї сесії

База після `git fetch origin main`: `1440344b6efe4eb581e84a1905cc4a9eebcbecbf`. Початковий handoff був на `c3736a8`; це вже не поточна база.

| що | джерело / команда | виміряне |
|---|---|---|
| поточний checkout | `git log -1 --format='%H %s' origin/main`; `git status --short` перед правками | `1440344`, merge PR #165; дерево чисте |
| черга PR | `gh pr list --state open --json number,title,headRefName` | `[]`; не доказ відсутності незапушеної роботи |
| свіжість state | `git log -1 --format='%h %s' -- docs/system/state.md` | `5368b25`; шапка все ще каже «передано в PR165»; не переписуємо виконавчий статус T2 |
| CLI у цьому executor | `codex --version`; `codex --help` | `codex-cli 0.159.0-alpha.3`; це не доводить версію UI цього чату чи встановлення на Mac |
| рушій у цьому executor | `godot --version` | `4.6.3.stable.official.7d41c59c4`; не цільовий 4.7 |
| старт і discovery | `AGENTS.md`; `rg --files --hidden -g AGENTS.md -g '*codex*' -g '*Codex*' -g '!.git/**'` | лише root AGENTS; адаптер Codex не підключений; ефективні hooks, trust і discovery в окремій сесії ще не перевірено |
| спільне ядро | `tools/hooks/role_posture.sh`, `roles.map`, `state_header.sh` | клієнт `codex`, 8 назв `nir-*`, stdout з rc=10; вік state за mtime не дорівнює віку змісту |
| парність | `tools/gates/role_parity_check.py` | перевіряє Claude skills/agents; Codex перевіряється лише за префіксом назви в мапі |
| пропуск GDS | `tools/gates/gd_check_all.sh:10-15` | відсутність Godot повертає 0; це суперечить R3 |
| CI на базі | `gh run view 37204095786 --json jobs`; GitHub connector logs jobs `111441565722`, `111441565491` | обидва jobs success; docs job: «ПРОПУЩЕНО: godot не знайдено» і «БАТАРЕЯ ЗЕЛЕНА»; godot job: `[smoke] ALL OK (164 checks) in 19944 frames` |
| обмеження CI | `.github/workflows/ci.yml` | gates job без інсталяції Godot; окремий godot job завантажує `4.7-stable` і виконує `make check-playable`; CI загалом не оголошуємо зламаним |
| GitHub | успішні clone/fetch, PR list, connector fetch_file та job logs | читання підтверджене в цій сесії; майбутній CLI має перевірити свою автентифікацію |
| Higgsfield | `list_workspaces`, `balance` | обрано `bf32c161-1feb-43c3-9d97-cd7bbc83357e`, private/owner, Ultra, 4568.75 кр.; unlimited недоступний; генерацій 0 |
| рецидиви | [[recurring_class_register]] | класи 4–7 відкриті; цей план не оголошує їх виправленими |

`gh run view --log` повернув порожній файл; наведені маркери CI взято з успішного читання логів через конектор. Читання Higgsfield у чаті не доводить доступ із локального Codex CLI. Версії, довіра, права на запис і discovery на Mac — не перевірено.

### Три варіанти

| варіант | перевага | ціна / ризик | рекомендація |
|---|---|---|---|
| A — ручний boot і команди ядра | працює без автоматичних подій | залежить від дисципліни; shell/patch можуть лишитись без quickcheck | обов'язковий fallback |
| B — тонкий Codex adapter над спільними ядрами | одна конституція, спільні ролі, відтворюване приймання | спочатку доказ підтримки подій і discovery на конкретному runtime | рекомендовано умовно: лише підтримані механізми |
| C — installable plugin | переносимість між поверхнями | пакування, довіра, релізи; все одно потрібен checkout | відкласти до потреби розповсюдження |

| погляд | A | B | C | вплив на план |
|---|---|---|---|---|
| Santos | простий старт, більше нагадувань | менше ручного відновлення | просте встановлення після складного пакування | короткий звіт тут, докази у файлах |
| нова сесія без пам'яті | легко пропустити крок | root route веде до джерел | plugin не дає checkout сам | fresh-session тест, не тест у старому контексті |
| Гефест | немає wiring, більше ручної роботи | мала зона змін | додатковий дистрибутив | runtime inventory до config, окремі PR |
| Феміда | важко довести сталість | перевірювані негативні контроли | більше поверхонь аудиту | вердикт на точному SHA |
| Аполлон / бюджет | ручний контроль витрат | однакові межі Red | ризик зайвих інтеграцій | 0 кредитів для всього треку |
| працівник Claude | його адаптер стабільний | спільні ядра можуть регресувати | більше залежностей | Claude adapter не змінювати; перевірити сумісність |

Вибір B + A зберігає чесний бій та ввід: `game/` поза scope; Sketch-Cel і реєстр лишаються спільними; вартість 0 кредитів; тонкий працездатний старт перед пакуванням. C зараз не прискорює іграбельний прототип.

## Розвилки для Santos

Рекомендація B + A зафіксована як пропозиція в ADR-021. Модель «цей чат — T1, виконавці — окремі рольові сесії» прямо доручена Santos. Конкретну схему hooks не обрано: її визначає доказ підтримки в сесії C1, а не припущення. Ціль першого приймання — доступна хмарна сесія Codex із checkout; Mac та Claude-машина потребують власного приймання.

## Кроки

| # / сесія | хто | що / файли | ризик | перевірка → очікування |
|---|---|---|---|---|
| C0 — зараз | T1 | цей план, ADR-021, Meeting, свій розділ state; окрема гілка від main | дубль закону, затертий чужий статус | `git diff --check`; `bash tools/gates/run_gates.sh` із цільовим Godot → rc=0; без нього записати неповну валідацію |
| C1 — inventory | T2, окрема сесія | звіт у `docs/Fix/2026-10-04-Codex-Runtime.md` або з фактичною датою; версія, surface, офіційні docs, skills discovery, events, trust, edit tools, MCP reads | CLI і чат помилково визнані одним runtime | `codex --version`, `codex --help`; harmless GitHub/Higgsfield reads; таблиця «підтримано / fallback / не перевірено» з URL, датою та результатами; `python3 tools/gates/wikilink_check.py` → rc=0 |
| C2 — adapter | T2 після C1 | root `AGENTS.md` → `.codex/AGENTS.md`; 8 тонких `nir-*` shims у підтвердженому C1 discovery path; документований ручний boot | вигадана схема, копії ролей, shim поза discovery | нова root-сесія: state повністю, constitution, routed adapter, роль T1 без префікса; кожен alias → правильне shared body; `make hooks-check` → rc=0 |
| C3 — reminders і parity | той самий T2, після C2 | лише підтриманий native wire; `role_posture.sh <prompt> codex`; rc=10 як контекст; `tools/gates/role_parity_check.py`, regression controls, за потреби Makefile hooks-check | shell writes або patches обходять quickcheck; Claude регресує | `python3 tools/gates/role_parity_check.py` → rc=0; тимчасово відсутній кожен shim → rc=1; неправильні name/body, дубль alias → nonzero; invalid `.gd` через кожен реальний edit tool → diagnostic; Claude regression controls PASS |
| C4 — строгі gates + CI | окрема T2-сесія після мержу C3 | `tools/gates/gd_check_all.sh`, `.github/workflows/ci.yml`, потрібні guards у Makefile; окремий PR | відмова через missing Godot ламає docs job; послаблення smoke | missing/non-executable binary → gate rc=2 і батарея nonzero; valid Godot 4.7 → повна батарея; `make check` і `make check-playable` → completion markers без ERROR; обидва CI jobs перевірені за логами |
| C5 — приймання | T4, окрема сесія | `docs/Audit/<date>-Codex-Coworker.md`, Meeting; state не змінювати | позитивний тест приховує непрацюючий guard | повтор C2–C4 на PR SHA, негативні контроли в ізольованій копії, fresh root session, вердикт із межами перевірки |
| C6 — маршрут далі | T1; Santos мерджить | прийняти стислий звіт, зіставити SHA/CI/аудит, свій delta state | результат старої бази видано за актуальний | `git fetch origin main`; `gh pr view <N> --json headRefOid,baseRefOid,state,statusCheckRollup`; SHA має відповідати перевіреному |

C2–C3 — один реалізаційний PR; C4 — окремий, C5 повторюється на кожному. Гейти й CI C4 змінюються атомарно: варіант інсталяції Godot в gates job або явного docs-only job + повної батареї в godot job порівнює T2; повна батарея без Godot завжди відмовляє. Порожній `GODOT_BIN=` дозволяє fallback на PATH, тому сам по собі не є негативним тестом відсутності Godot.

Перед написанням config T2 перечитує офіційні runtime docs, починаючи з посилань handoff: https://learn.chatgpt.com/docs/agent-configuration/agents-md і https://learn.chatgpt.com/docs/build-skills . Ці URL — старт дослідження, не підтвердження підтримки hooks. За відсутності автоматичних подій чесно залишається A: повний boot, ручні state/role reminders на початку ходу, quickcheck кожного зміненого `.gd` після patch і shell, авторитетні import + smoke перед здачею. Немає auto hooks ≠ повна автоматична парність.

Фінальні команди реалізації: `make hooks-check`, `GODOT_BIN= make check`, `GODOT_BIN= make gates`, додатково `GODOT_BIN= make check-playable` для CI регресій. Перед ними `godot --version` має показати цільовий 4.7; якщо потрібен окремий бінар — явний абсолютний `GODOT_BIN` у журналі. Зберегти точні команди, stdout/stderr, rc, версію і SHA. Skip не є завершеною перевіркою.

Кредити: **0**. Генерації, asset deletion, main push, публікація, ліцензійні зміни поза треком. Токени Claude не копіюються; unrestricted права цього executor не є рекомендованою конфігурацією Codex.

## Хендофи

### C1–C3 → T2

> T2 Гефест, інтеграція Codex. Прочитай state → constitution → root AGENTS → roles/t2-hefest.md → цей план. Почни C1 на свіжому origin/main в окремій гілці/worktree. До доказу event/discovery не пиши hook schema. Реалізуй C2–C3 за підтвердженим runtime, з явним fallback, спільними bodies і Codex parity. Claude adapter та game/ не змінюй. Fighter.gd належить T2·A. Звіт — точний SHA, PR, файли, перевірки й неперевірене; Meeting і власний статус state. Звичайний PR із «Що перевірити», мерджить Santos.

### C4 → окрема T2-сесія

> T2 Гефест, після C3 в main виконай C4 цього плану. Порівняй варіанти CI за R8 до правок. Missing Godot → refusal, без послаблення parser/import/smoke; справжній Godot 4.7 у full-validation job. Негативні контроли відсутнього бінаря та invalid .gd, повні checks на submitted SHA. Окремий звичайний PR, Fix + Meeting + лише власний delta state.

### C5 → T4

> T4 Феміда, незалежне приймання PR C2–C3 або C4 цього плану. Перевір конкретний head SHA, fresh root boot/discovery, rc=10, patch і shell writes, missing shim/Godot, Claude regression, реальні CI logs. Відокремлюй статичну парність від встановленої та runtime-перевіреної. Не змінюй state чи реалізацію. Audit + Meeting, вердикт, blockers і команди відтворення.

### Що передавати кожному виконавцю

Роль; одна мета; base SHA; plan/ADR paths; owned і заборонені файли; залежності; критерій завершення; перевірки; права Red; місце звіту. Повна історія чату не потрібна. Спільні state/law кожен читає сам. Новий агент стартує лише з готовим пакетом, не з «розберися».

Субагенти можливі за дорученням Santos, але кожен має окрему рольову сесію та обмежену смугу. Ця T1-сесія не реалізує за T2. Локальні CLI-сесії Claude/Codex не вважаються керованими звідси без перевіреного каналу. Паралельні write-задачі — в окремих worktree; в одному checkout лише непересічні owned files. Godot не запускати паралельно на одному game/.godot. State-дельти інтегрувати послідовно, зберігаючи обидва боки.

### Формат стислого повернення до T1

До 12 рядків, повні логи — за посиланням:

1. Роль, мета, статус: виконано / частково / заблоковано.
2. Base SHA → head SHA, гілка та PR.
3. Що змінилось, owned files.
4. Команди, rc і ключові маркери, runtime versions.
5. Негативні контроли та їх результат.
6. Неперевірене й ризики.
7. Посилання на Fix/Research/Audit і Meeting.
8. Конфлікти / залежності, delta state.
9. Одне потрібне рішення T1/Santos або «немає».
10. Наступний дозволений крок.

T1 повертає звіт без доказів на уточнення; не ставить за виконавця «зроблено». Для відновлення після втрати контексту: state → constitution → роль → план → останній Meeting → PR/head SHA. Цей чат зручний для рішень, але не є єдиним сховищем домовленостей.

## Приймання інтеграції

- Нова root-сесія фактично читає спільні джерела й правильну роль; усі 8 shims знайдені runtime.
- Reminders автоматичні лише на доведених подіях; кожен непокритий шлях має позначений ручний крок.
- Invalid `.gd` помічений після patch і shell; missing shim валить parity; missing Godot блокує readiness.
- Claude adapters працездатні; GitHub/Higgsfield reads виконані на цільовій поверхні; права Red збережені.
- make check/gates і CI на поданому стані без пропусків; T4 відтворив докази; Santos мерджить.
- Доти статус — часткова інтеграція або план, а не «повна парність».

## Related
- [[state]] · [[constitution]] · [[Plan-Template]] · [[2026-10-04-T1-Codex-Coworker]] · [[ADR-021-Codex-Coworker-Adapter]]
- [[ADR-019-Audit-And-Many-Views-Before-Decision]] · [[recurring_class_register]] · [[2026-10-03-Wave-2-Kickoff]] · [[2026-10-03-Arena-Depth-Life]] · [[2026-10-03-Living-Combat]] · [[Plans/2026-10-04-Comfort]]
