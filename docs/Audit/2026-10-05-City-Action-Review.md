# Місто й екшен — незалежний огляд

2026-10-05 · T4 Феміда. База `origin/main` / `66d5353`; перевірено незакомічений пакет гілки `codex/city-action-polish`. Production-код і `state.md` аудитор не змінював.

**Вердикт: YELLOW загалом; технічні зміни придатні до PR.** Блокувальних дефектів у переглянутому diff не знайдено. Іконку ще не інтегровано, живе приймання керування, анімації й Mac/M3 лишається відкритим. Це не твердження про завершення всього доручення Santos.

## Перевірка поведінки

Незалежна копія: `/tmp/nir-review-20261005`; бінар `/tmp/nir-godot47/Godot_v4.7-stable_linux.x86_64`. Команда тестів: бінар з `--headless --fixed-fps 60 --path /tmp/nir-review-20261005/game --script <script>`. XDG data/cache/config спрямовано у цю тимчасову теку. Зміни негативних контролів існують тільки там.

| Пункт | Вердикт | Особисто перевірений доказ |
|---|---|---|
| Зачепи поза центром, рух/ручний огляд, сталі заряди й transfer | GREEN | `tools/grapple/traversal_check.gd`: **40/0**, `traversal.log`; повтор з камерою, яка не дивиться прямо на закритий стіною зачеп: **40/0**, `traversal-offcenter.log`. |
| Чутливість гарда camera LOS | GREEN | У тимчасовому HarpoonAim вимкнено саме `_clear(f, ray_origin, position)`: **40/1**, rc1, `camera-hidden anchor is not advertised through walls`, `traversal-negative.log`; повернення справжнього коду відновлює **40/0**. Новий assist не ігнорує стіну заради широкого конуса. |
| Повернення після удару, hitstop/freeze, реакція й новий удар | GREEN | `tools/animation/combat_presentation_check.gd`: **167/0**, `combat.log`. Diff обмежує overlay IDLE/WALK/CROUCH; атака, реакція, dash, ragdoll і hook recovery його скасовують. Damage/frame data не змінені. |
| Відсутність залишкової idle-пози після переходу | GREEN | `tools/animation/idle_presence_check.gd`: **18120/0**, `idle-settled.log`. Початкові два провали виникали в ATTACK→WALK під час нового 0.10 с overlay. Виправлений гард обмежено чекає завершення, вимагає порожні source/base і зберігає стару точну звірку з raw seek та незалежним mannequin. Це не видалення перевірки чистоти пози. |
| Рознесення й рух NPC протягом повного маршруту | GREEN | Незалежний `npc_runtime_check.gd` подовжено з 24 до **240** вибірок по 30 physics ticks: **72/0**, мінімальна відстань **2.601509 м**, `routes_clear=true`, `npc-extended.log`. Перевіряються капсули вздовж руху, вітання/cooldown, unload/reload позиції та input діалогу. |
| Ідентичність і пам'ять NPC | GREEN | Перечитано `NpcPopulation.gd` validation нового `neighbour`; raw integrated `playable-final/npc.log`: **23/0**, runtime **72/0**. Позиція маршруту зберігається тільки при streaming у поточній сесії; між запусками зберігаються ідентичність і пам'ять. Повна навігація/динамічні зіткнення не заявляються. |
| Процедурні матеріали | GREEN технічно / YELLOW художньо | Переглянуто shader diff і raw `/tmp/nir-art-style.log`: **26/0**, Mesa llvmpipe Compatibility, `near_edges=0.006091`, `far_edges=0`, `palette_peak=0.741176`. Це software-render доказ, не FPS M3. Нових texture-файлів немає. |

## Загальні гейти й межі

Особисто прочитано `/tmp/nir-validation/check-playable-final.log`: `make check-playable` на інтегрованому пакеті — **80 GDS / 0 помилок парсингу**, smoke **164 перевірки / 19847 кадрів**, **50 сценаріїв / 0 провалів**. Runtime негативні контроли враховані окремо; очікуваний rc1 у них є успіхом виявлення навмисного дефекту.

Особистий `make check` в ізольованій копії завершився `SMOKE ЗЕЛЕНИЙ`, **164/19847**, `make-check-final.log`; його import-обмеження наведено нижче. Фінальний integrated `/tmp/nir-validation/gates-final.log` також особисто перечитано: **БАТАРЕЯ ЗЕЛЕНА, 80/0**.

Особисто виконано в ізольованій копії `bash tools/gates/run_gates.sh`: `gates-final.log` — **БАТАРЕЯ ЗЕЛЕНА**, 80 GDS/0, реєстр 174/174, wikilinks 0 битих, парність 8 ролей/0 проблем. Перша неповна копія без `.claude` правильно дала 16 missing-shim/agent помилок; після копіювання незмінених контрольованих файлів парність пройшла. Перші isolated запуски також виявили недоступні стандартні XDG-каталоги; вони перенаправлені в `/tmp`. Headless editor у sandbox друкує `_sock`/`ERR_CANT_CREATE`; чистий інтегрований import координатора прочитано окремо, тому ці повідомлення не приховано як нібито безпомилковий isolated import.

Команди `git log --oneline origin/main..HEAD` та `git diff --stat origin/main -- game/assets docs/Art/Textures-Registry.md` дали порожній вихід на момент review: пакет ще не закомічений, нових ассетів/змін ліцензій немає. `git branch --show-current` → `codex/city-action-polish`; main не змінювався цим оглядом. Остаточні docs/gates і commit/PR належать координатору.

**YELLOW: іконка.** Перевірено відсутність `game/assets/ui/app_icon.png` і автоматичний вибір цього шляху в `tools/distribution/export-macos.sh`. Нового зображення в пакеті немає; встановлений застосунок користувача не змінено цією Linux-сесією. Арт-смуга зафіксувала HTTP403 оригіналу; аудитор мережеве завантаження не повторював. Потрібні доступні байти схваленого PNG, реєстрація й окреме приймання bundle/Finder. Живе відчуття assist, фізичний геймпад, остаточний арт і M3 лишаються поза цим технічним вердиктом.

## Related

- [[2026-10-05-City-Action-Polish]] · [[2026-10-05-City-Action-Session]] · [[2026-10-05-Npc-Crowding]] · [[2026-10-05-Rope-Assistance]] · [[2026-10-05-Combat-Animation]] · [[2026-10-05-City-Texture-And-Icon]] · [[2026-10-05-Reusable-Game-Systems]] · [[recurring_class_register]]
