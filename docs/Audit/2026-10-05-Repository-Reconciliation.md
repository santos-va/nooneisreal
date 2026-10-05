# Звірка відкритих задач із main

2026-10-05 · T4 Феміда · **GREEN для звірки й виконаного облікового cleanup; не нове художнє або платформне приймання гри.** Доручення Santos — звірити стан і прибрати зайві issues/branches. Ця смуга перевірила всі **13 відкритих issues**; state, gameplay і remote не змінювала, Godot не запускала. Гілки та виконання remote операцій належать ROOT.

## Джерела й межа версій

Прочитано всі issue bodies з `/workspace/nooneisreal-evidence/repo-cleanup/github-inventory.json` та всі сторінки comments через `github_fetch_issue_comments` для #4, #6, #7, #8, #11, #12, #14, #19, #33, #36, #38, #42, #52. Нормалізовані comments з точними URL збережено у `t4-issue-comments.json` поруч. Коментарі розширюють scope: зокрема #33 містить runtime слід заднього сигілу, а #7 уточнений ADR-012 до 3D-діорами.

Особисті `git rev-parse origin/main HEAD` дали main **6c083286d600aa3de834411d2c55773c77fe2543**, candidate **055b1d81a826b21f9f2790afe9dd64ce286d3cb5**. PR #181 ще відкритий. `git diff --name-only origin/main HEAD` відносить candidate до «Нижньої позначки»; жодна рекомендація нижче не залежить від його майбутнього merge. Для кожного посилання зі structured рекомендацій виконано `git show 6c08328:<path>` і SHA256-порівняння: всі доказові файли byte-identical у main та робочому дереві.

## Рекомендації

| Issue | Дія | Конкретний доказ і незакрита межа |
|---|---|---|
| #6 | **Закрити completed** | Вузьке М2 — промпти та кошторис — є в `Menu-Skyline-Prompts` §§ Кошторис, A–H; коментар [5963636354](https://github.com/santos-va/nooneisreal/issues/6#issuecomment-5963636354) прямо звітує про готовність/PR #13. Історичні ціни не новий замір; pending flyby assets і їх інтеграція лишаються #4/#8. |
| #14 | **Закрити completed** | X1 style acceptance прямо зафіксоване словом Santos «стиль так», з трьома переможцями: [5964001141](https://github.com/santos-va/nooneisreal/issues/14#issuecomment-5964001141). Журнал [[2026-10-03-Style-Yes-Wave-2]] і активні prompts підтверджують X0/X1. Наступні X2/X3 не треба тримати всередині завершеної style-проби. |
| #36 | **Закрити completed як T1/T5 передачу** | C3/moveset і clip mapping змерджені; [[2026-10-03-Ares-C3-Clip-Table]]. Особисте `git show a8fa3c3:docs/GDD/02-Combat-System.md` показало вісім поз у рядках185–189, `git merge-base --is-ancestor a8fa3c3 origin/main` rc0. Поточна таблиця перейшла на UAL Source, `AuthoredCombatMotion` має sword/aircut. Генерація листа й його вибір лишаються #38; закриття передачі не є естетичним прийманням усіх рухів. |
| #52 | **Закрити not_planned: замінений чекліст** | `GameState.free_move=true`, Printer, SkeletalRig/GLB, MainMenu mode та [[2026-10-03-Launch-5-6]] доводять, що початкова черга вже історична. Не писати «всі запуски прийняв Santos»: усіх особистих Mac/playtest відповідей тут немає. Подальші хвилі замінили цей спосіб обліку. |
| #4 | **Залишити** | Epic живого rooftop меню не виконано: `MainMenu._ready()` створює статичний TextureRect. Немає натовпу/машин та flyby20–50с. Реальний CityWorld не є меню-діорамою. |
| #7 | **Залишити** | `git ls-tree` main і `rg` source не знаходять MenuBackdrop/CrowdLane/SteamCar/GrappleFlyby; нема 300с seeded timing oracle. ADR-012 змінює техніку, не скасовує чергування/reduced-motion/input вимоги. |
| #8 | **Залишити** | Assets у реєстрі й panorama в меню не доводять M4 live integration. M5 потребує timing/читаності/ліцензій та виміряного Mac FPS саме цього меню; такого приймання немає. |
| #11 | **Залишити** | MainMenu ряд25 прямо каже `no CharacterSelect.tscn yet`; окремої сцени немає. Поточний P1/P2 picker не замінює rooftop heroes, три skill panels і повний input UX Б1. |
| #12 | **Залишити** | `rg -n -i kronshift game/scripts tools/fetch_assets.sh docs/Art/Textures-Registry.md` знаходить GameState stage names, bg_kronshift_* і fetch/registry paths. Це production посилання, не лише історичний ADR. |
| #19 | **Залишити** | Drone card зареєстрована, GDD написаний; `Arena._anchors_around/_layout_anchors` залишає river Marker3D/lantern anchors. Spring drone, rope-to-visual endpoint і тихе навантажувальне аудіо не знайдені. Printer helper — інша механіка. |
| #33 | **Залишити, звузити до S5** | Explicit Santos acceptance усіх5 S3 views є в [5964817509](https://github.com/santos-va/nooneisreal/issues/33#issuecomment-5964817509), M-1 — у [[2026-10-03-C2-3D-Heroes]]. `HeroGearPresentation._build_book` і `grimoire_sigil` дають задній ∞8 зі сталим emission без TIME/pulse. Motion-only dispersing trail з comment/S5 не знайдено; flash-step Afterimage його не доводить. |
| #38 | **Залишити, звузити залишок** | Asset-Manifest підтверджує пізніші K-0/F-0/G-0/Z-1 і готовий M-0. Окремий лист поз v5 досі без доказу generation/acceptance; actual shoe C decal також не доведений. Картка Choko з ранніми V-1/кремовою смугою потребує звірки з пізнішим вибором, а не нової генерації вже прийнятого одягу. |
| #42 | **Залишити, звузити до quality/runtime/platform** | План і [[2026-10-03-Toon-Quality-Cloth]] вже є, поведінка/одяг/VFX частково в runtime. QualityProfile і Low/Medium/High/Ultra перемикач не знайдені; ComfortSettings цього не реалізує. Mac/mobile performance та visual acceptance відсутні. |

## Передача ROOT

`/workspace/nooneisreal-evidence/repo-cleanup/t4-issue-recommendations.json` містить всі13 записів: `status`, `action`, `state_reason`, `proposed_state`, український dated prepend, точний `proposed_body` **з незміненим original body**, main source links, candidate scope та незакриті вимоги. SHA256 source proofs включені. ROOT виконав **4 закриття і 9 актуалізацій** через update_issue, потім повторно отримав усі13 issues. T4 особисто прочитав `issues-after.json` та власним Python-порівнянням звірив кожний receipt із рекомендацією:13/13 state/state_reason збігаються, #52 закрито not_planned, #6/#14/#36 completed, решта9 open. Для кожного receipt `body_exact=true` і `original_preserved=true`. Власний результат — `t4-issues-after-check.json`. Це перевірка ROOT remote reread receipts; T4 повторного GitHub fetch після mutation не робив і сам issue не закривав/не коментував.

Особисто прочитано компактний `docs/system/state.md`: merged main6c08328 і незмерджений PR181 розділені; 85/0 не видано за доставку на M3; реалізовані сюжет/NPC saves не повернуті в чергу як відсутні;9 open issues описують реальні залишки. Первісно знайдене несвіже «CI ще виконується» ROOT виправив; повторний особистий `rg` підтвердив точний CI806 success для055b1d8 і окрему вимогу майбутнього CI для docs commit. CI статус не є доказом merge. Також прочитано `root-source-proof.json`: старий state архівовано byte-exact (55752 bytes), усі793 game/tools файли незмінні з digest0beea2…; це ROOT proof, runtime повторно не запускали. Гілки прибирає ROOT; T4 не заявляє окремого branch-deletion audit.

Відсутність знайденого renderer/runtime не означає відсутності арт-джерел у каталозі; наявність арт-джерела не означає runtime або суб’єктивне приймання. Старі витрати/дозволи не використані як дозвіл на нові платні роботи. Це read-only reconciliation, тому повторна runtime батарея не потрібна.

## Related

- [[Plans/2026-10-05-Repository-Reconciliation]] · [[state]] · [[recurring_class_register]] · [[2026-10-05-Lower-Mark-Review]] · [[2026-10-03-Main-Menu-Skyline]]
