# Аудит епізоду «Слід під годинником»

2026-10-05 · T4 Феміда. **Фінальний вердикт: GREEN у межах одного епізоду.** State/save/input, фізичний маршрут, native наслідок, check/gates і full83 підтверджені нижче. База `246927b` особисто звірена командами `git log -2 --oneline` та `git status --short` до початку змін. Scope — один авторський міський епізод, новий службовий двір і фізичний короткий шлях; не завершення основного розслідування чи всієї гри.

## Вихідні контракти

Особисто прочитано `CityProgress.gd`, `NpcPopulation.gd`, `CityNpcDirector.gd`, `NpcDialogue.gd`, `CityWorld.gd`, `CityJourney.gd`, `CityOnboarding.gd`, `CityQuestTargets.gd`, `CityFighter.gd`, UI ownership у `InputRouter.gd`, чинний `district.json`, journey/onboarding/quest checks та approved [[2026-10-05-Clocktower-Story-Expansion]]. План містить три варіанти й погляди різних гравців; [[2026-10-05-Clocktower-Trace]] розділяє спостереження та невідому причину.

- Старі district events ретроактивні та ізольовані за героєм; NPC save вимагає точні 12 канонічних identities, district save — відомі quest/event IDs. Новий `CityStory` має окремий документ, тому старі meet/visit факти не повинні автоматично виконувати новий епізод.
- NPC пам'ять і сюжет зберігаються різними файлами. Завершення епізоду має одне джерело істини; одноразова пам'ять не може вимагати атомарного запису обох файлів. Перерва між записами потребує безпечного повторного відновлення пам'яті.
- `InputRouter.just_pressed` не споживає edge. Новий world interaction мусить мати явну арбітрацію з NPC, range/height/LOS і UI ownership. Виклик API стану сам по собі не доводить правильну межу взаємодії.
- Journey відновлює лише дозволені назви місць. Новий checkpoint мусить бути безпечним і до, і після відкриття; напрямна HUD є bearing, а не доказом прохідного маршруту.

## Обмежене приймання

1. Обидва герої реально проходять обхід рампами до внутрішнього механізму при зачиненій хвіртці. Після відкриття проходять коротким шляхом; старі roof bridge/clock tower маршрути лишаються досяжними. Телепорт у контрольну точку не зараховується як доказ повного шляху.
2. Реальна послідовність: пропозиція Лади → явне прийняття → два різні огляди в обох порядках → відкриття → повернення до Лади. До прийняття, з одним оглядом, повторно або в іншого NPC немає дострокового прогресу.
3. Відновлення кожного змістовного стану та ізоляція Choko/Skea. Пошкоджений файл лишається незмінним; session із `disk=false` не пише. Старі district/NPC/journey документи не мігрують випадково і не втрачають дані.
4. Справжні input boundaries: надто далеко, інша висота, стіна в LOS, pause/dialogue UI, утримання кнопки та stale callback не зараховують нову дію. Один edge не запускає одночасно NPC і предмет.
5. Native окремо доводить видимі засув/напрямну/важіль, закритий і відкритий прохід, зрозуміле поточне завдання та читабельний HUD/журнал. Фінальний текст не заявляє розкриття зникнень, катакомб чи особи винуватця.

## Ранні зауваження

Перший read-only review `CityStory.gd` підтвердив строгі залежності accepted/clues/opened/completed, атомарний restore, вимкнення запису для `disk=false`, перевірку помилки запису перед rename. Виявлено занадто слабку валідацію content: документ лише з правильним `id` приймався, хоча обов'язкові підказки відсутні. Повторне читання підтвердило виправлення: `valid_content` вимагає точний набір текстових ключів (фінально 28, включно з підказками для одного лишеного огляду), непорожні рядки та верхню межу довжини. Фінальні negatives наведені нижче.

Статично виявлено перетин старого `CityLayout.route_points` відрізка `(-20,4,-20) → (-29,4,-14)` з новою `NorthWall` приблизно в `(-24.05,4,-17.3)` та західною стіною. Після узгодження T1 власник додав явну точку `(-29,4,-20)` північного обходу зі збереженням старих destinations. Diff особисто прочитаний; подальші clean raw 74/0 movement і 1750/0 geometry, наведені нижче, закрили цей ризик. Це навмисна зміна маршруту, а не твердження про незмінність старого відрізка.

Read-only review інтеграції підтвердив stage guard та фізичний `can_talk` для stale сюжетних callbacks, перевірку єдиного UI owner, відновлення одноразової NPC пам'яті з authoritative completed story. `can_inspect_story` перевіряє ground/state/grapple/control/UI/range/height/LOS; NPC має пріоритет, а огляд відкриває modal, що очищає input edge. HUD зберігає manual/off errand preference, доки гравець явно не вибирає сюжет; після зауваження T4/T8 прочитаний diff прибрав подвійний tracking tick та уточнив, що 0/6 — district tasks.

T1 окремо виявив durable-memory межу: після невдалого story persist сигнал `changed` усе одно створював NPC пам'ять про завершення. T4 особисто підтвердив source path `_changed → _sync_story_memory → persist`; оригінальний метод і SHA збережено в `clocktower/review/unsaved-memory-source.json`. Це могло залишити NPC факт про майбутнє щодо збереженого story stage. Повторне читання підтвердило narrow guard `story.save_enabled && story.save_ok` перед створенням bond; завершення в пам'яті й безпечний стан світу лишаються можливими. Особисто прочитаний `city-story/validation/story-durable-final.log`: **61/0**, clean raw. Незалежний runtime negative нижче також пройшов.

Особисто прочитані повні `clocktower/geometry/maintenance-third.log` та `old-geometry.log`: Godot 4.7, **74/0** real walking та **1750/0** geometry checks, без додаткових errors/warnings. Source fixture справді виконує рух обох героїв від entrance через старі destinations, closed leaf, bypass і open leaf; `skeletal_rig=false`, тому це фізичний, не художній доказ. Доданий authored waypoint явно відрізняється від старої діагоналі. T4 цих Godot запусків не виконував.

## Незалежні input/save boundaries

T4 особисто виконав `python3 /workspace/nooneisreal-evidence/clocktower/review/run_review.py boundaries-first`: **20 checks / 0 failures, rc0**, Godot 4.7, raw містить тільки engine banner та `T4_CLOCKTOWER_COMPLETE`. Fixture використовує Skea й реальний `InputEventKey`, взятий із чинного `p1_interact` mapping; priority −50 подає подію після InputRouter і перед consumers. Перевірено:

- stale accept поза NPC range, вкладений foreign UI owner і позитивне sole-owner прийняття;
- overlapping actual NPC отримує один mapped key edge без одночасного clue; foreign modal та реальна mask1 стіна блокують огляд;
- закриття modal не переносить утримувану клавішу на наступну досяжну clue; свіжі edges виконують обидва огляди й відкривають фізичну хвіртку;
- destroy/re-enter повного CityWorld відновлює відкриту хвіртку Skea без перезапису story bytes, Choko лишається доступним із зачиненою хвірткою;
- malformed restore атомарний, disk=false не створює файл, corrupt source не переписується після завершення in-memory, NPC не отримує пам'яті про незбережене завершення.

Файли `clocktower/review/boundaries-first.{log,rc}`, `boundaries-first-source-{before,after}.json` та `review_boundaries.gd` збережені зовні repo. **786 game/tools files** до/після тотожні; digest `06bcc7dc8aaae3e12593bc33e07de4998a34fa52ed142af259caf766482020fa`, fixture SHA `974f77641944d1e97ff7fefced6071fc220fddbcfbb173a912d07e22433d6b01`. Позиціонування гравця тут є fixture setup для меж; цей тест не називається повним walkthrough. Route доводить окремий movement fixture. Після завершення слот явно передано T6.

Самоперевірка T4 виявила confound саме held-key пункту: початкове позиціонування другої clue через `restart_at` також викликає `clear_player_presses`. Цей вузький результат не приймається як доказ modal-only fence. Початковий fixture збережено як `review_boundaries_before_held_isolation.gd`; посилений варіант переміщує персонажа без reset і вимагає фізично утримувану клавішу до/після закриття modal. Після root aggregate T4 виконав `run_review.py boundaries-held-isolated`: **20/0, rc0, clean raw**. Фізична клавіша лишається натиснутою, другий огляд не зараховується, а fresh release/press працює. Source digest той самий фінальний `b62803f…`; fixture SHA **`23f96e93542a8c3a0233eb52bd179a6d2efe5aaa1cb0c95c3b6f2e790684826b`**. Саме цей посилений run є прийнятим held-key доказом.

Пізніша static перевірка виявила типізований Variant дефект у `valid_content`: equality id зі String перед перевіркою String type, якщо неправильний id має правильну кількість сусідніх ключів. Оригінальна функція з SHA збережена в `content-variant-before.json`. Особисто прочитаний owner raw `city-story/validation/content-variant-before.log` містить два **SCRIPT ERROR Invalid operands Array/Dictionary and String in operator !=**, хоча функція повертає false. Отже сам boolean assert міг би помилково зарахувати negative. Це четвертий підтверджений loader у класі 9 [[recurring_class_register]].

Виправлення додає `not data.get("id") is String` перед equality та дві постійні exact-size negatives у `city_story_check.gd`; strict runner відхиляє SCRIPT ERROR незалежно від false/sentinel. Особисто прочитаний `story-content-final.log`: **63/0**, clean raw. T4 повторно виконав `run_review.py boundaries-final` і `run_review.py content-ids-final .../review_content_ids.gd`: **20/0 + 3/0, обидва rc0, clean raw**. Новий tiny fixture позитивно приймає справжній content і відхиляє ті самі два типи без exceptions.

Обидва фінальні T4 runs мають **786 незмінних game/tools sources**, digest **`b62803f98b11509c69dbccf05634aef3af61b99e81bb5647eea9d7b0edcd9b69`**. Особисте порівняння першого й фінального manifests показує тільки `CityStory.gd` та `city_story_check.gd`. Production delta після native capture — лише String guard для невалідного content; geometry/HUD/valid content незмінні. `post-native-validator-delta.json` підтверджує точні hashes. Native не називається тотожним усім фінальним source bytes.

## Native і межі доказу

T4 особисто відкрив вісім фінальних PNG у `clocktower-story/native-final`: `court_closed`, `court_open`, `counterweight_after`, `latch_hud_540`, `both_clues_fact`, `lada_complete`, `journal_540`, `journal_story_middle_540`. Видно реальний прохід під піднятою хвірткою, нижче положення важка, доступну галерею, G-підказку засуву й напрям до наступної дії. Репліка Лади лишає причину невідомою. Журнал прокручується; показані top/middle є різними scroll positions, а не обіцянкою вмістити всі факти одночасно.

Особисто прочитані raw `native.log` і `trace.json`: **20 PNG / 0 failures**, усі `story_save_ok=true`, є лише відоме llvmpipe VSync warning, немає runtime/shader errors або leaks. Фізичні captures 960×540/720 відповідають logical 1600×900/1200. Це staged visual fixture з Choko (`capture-fixture.gd`), не запис безперервного проходження; реальний рух обох героїв та Skea actual key interactions доведені окремими фізичними тестами.

T4 незалежно порівняв **290 captured paths** із поточними: відрізняються лише `CityStory.gd` та test. Видалення в пам'яті тільки ` or not data.get("id") is String` із фінального CityStory відтворює captured SHA **`d6d93a78ed253765c3472ebd1291cc96e7e94511abfbd28e521efc4475b85fbd`**. Отже parser-only delta точно підтверджена, незмінність visual paths не взята на віру з чужого звіту. Апаратне FPS/feel, фізичний геймпад, усі ракурси й безперервний human playthrough цими evidence не доведені.

## Фінальна батарея

T1 виконав фінальні `make check`, `make gates` і serial playable runner; T4 особисто прочитав їхні `.rc`/raw logs у `clocktower-story/validation` та незалежно просканував усі **83 case logs**. `review-check.log`: **114 GDS / 0 parse failures**, smoke **164 checks / 19847 frames**, rc0. `review-gates.log`: **175/175 assets**, 0 broken wikilinks, зелена батарея, rc0. `review-playable.log`: **83 scenarios / 0 failures**, rc0. Немає SCRIPT ERROR, WARNING або leaks; **76 ERROR lines** належать лише передбаченим negative assertions чотирьох старих fixture families, кожна звірена з дозволеним префіксом. Unexpected errors — **0**; власний receipt `clocktower/review/final-raw-scan.json`.

Фінальні permanent cases: story **63/0**, maintenance **74/0**, geometry **1750/0**, city runtime **68/0**, onboarding **64/0**, journey **122/0**, quest tracking **44/0**, NPC save negatives **272/0**, district save negatives **23/0**. `review-source-before.json` та `review-source-after.json` тотожні й збігаються з обома фінальними незалежними T4 runs: **786 files**, digest **`b62803f98b11509c69dbccf05634aef3af61b99e81bb5647eea9d7b0edcd9b69`**. Після тестів були лише docs/evidence правки.

| Межа | Вердикт | Доказ |
|---|---|---|
| Сюжетний стан і старі saves | GREEN | 63/0 permanent + 20/0 independent, строгі malformed/disabled/corrupt cases, окремий per-hero документ |
| Input/range/LOS/UI ownership | GREEN | mapped-key Skea fixture 20/0, посилений held-only repeat, NPC arbitration і реальна стіна |
| Прохідність і фізична хвіртка | GREEN | обидва герої real walking 74/0, geometry1750/0, scene reload open/closed |
| Видимий наслідок і пояснення | GREEN scoped | native20, особистий огляд ключових8 PNG, точна parser-only post-capture delta |
| Регресійна батарея й source freeze | GREEN | check/gates rc0, full83/0, усі raw logs і тотожні manifests |

Gameplay source T4 не змінював; власні правки — audit/register та зовнішні fixtures. Попередні 81/0 й eyelid checks не підміняють свіжу батарею. Висновок не поширюється на цілу кампанію, нові платформи чи нездійснене апаратне приймання.

## Related

- [[2026-10-05-Clocktower-Story-Expansion]] · [[2026-10-05-Clocktower-Story-Session]] · [[2026-10-05-Clocktower-Trace]] · [[2026-10-05-Eyelid-Anchoring-Review]] · [[ADR-023-City-First-Exploration]]
