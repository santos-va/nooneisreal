# Кров і смертельні раунди: вікові рейтинги, референси, перемикач

**Дата:** 2026-10-07 · **Роль:** T3 Архімед

> Текст — T3 Архімед (sub-agent з інструментами лише для читання). Записав T1 Дедал-оркестратор без змін змісту, за механізмом адаптера «бриф повертається текстом» (`CLAUDE.md`, розділ «Агенти»). T1 особисто звірив локальні цитати: `sed -n 64p docs/World/Lore.md` → «одинадцять тіней-сторінок у вкрадених тілах»; `sed -n 20p docs/system/constitution.md` → цільові платформи до Android/iOS. Рядки рівня S T1 не перевіряв.

**Обмеження цієї сесії (читати першим).** WebFetch повернув `EGRESS_BLOCKED` для pegi.info, www.esrb.org, www.globalratings.com, usk.de, www.cero.gr.jp, support.google.com, play.google.com, partner.steamgames.com, learn.microsoft.com, www.askaboutgames.com. Повністю відкрилося лише першоджерело **developer.apple.com**. Тому рядки мають рівні:
- **P** — сторінку першоджерела відкрито й прочитано в цій сесії.
- **S** — URL сторінки рейтингового органу знайдено через WebSearch, але відкрити її не вдалося. Текст узято з пошукового сніпета, тож він **не перевірений першоджерелом**. Перед ADR рядок треба звірити з машини, де є доступ до цих сайтів.
- **UNGROUNDED** — першоджерела немає або сніпети суперечать одне одному.

## Питання
1. Що з «крові», «реалістичного чи нереалістичного насильства» і «смерті» піднімає рейтинг у PEGI, ESRB, IARC, USK, CERO і Apple.
2. Які рейтинги й подачу крові мають Naruto Storm та 2–3 стилізовані файтинги.
3. Чи знижує рейтинг опція «вимкнути кров» і чи вимагають її регіони.
4. Що з цього випливає для нас: варіант подачі → рейтинг → ризик для мобільних магазинів.

## Джерела (доступ 2026-10-07)
| # | орган | URL | рівень |
|---|---|---|---|
| 1 | Apple App Store Connect | https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions/ | **P** |
| 2 | ESRB, ratings guide | https://www.esrb.org/ratings-guide/ | S |
| 3 | ESRB, ratings process | https://www.esrb.org/ratings/ratings-process/ | S |
| 4 | ESRB, блог про IARC | https://www.esrb.org/blog/esrb-ratings-expand-to-mobile-via-new-global-rating-system/ | S |
| 5 | ESRB, Parent's Guide: Marvel's Wolverine | https://www.esrb.org/blog/a-parents-guide-to-marvels-wolverine/ | S |
| 6 | ESRB, сторінки ігор | …/ratings/32770 (Storm 3) · 33480 (Revolution) · 34249 (Storm 4) · 39306 (Connections) · 37488 (GG Strive) · 37795 (Demon Slayer HC) · 39503 (MK1) | S |
| 7 | PEGI, значення міток | https://pegi.info/what-do-the-labels-mean | S |
| 8 | PEGI, how we rate | https://pegi.info/page/how-we-rate-games | S |
| 9 | PEGI, пошук у базі | https://pegi.info/search-pegi | S |
| 10 | IARC | https://globalratings.com/how-iarc-works/ | S |
| 11 | USK, Leitkriterien 2024 EN | https://usk.de/wp-content/uploads/2019/06/USK-Leitkriterien-2024-EN.pdf | S |
| 12 | CERO | https://www.cero.gr.jp/en/publics/index/17/ | S |
| 13 | Steamworks, Німеччина | https://partner.steamgames.com/doc/gettingstarted/contentsurvey/germany | S |
| 14 | Google, блог Android Developers (2015) | https://android-developers.googleblog.com/2015/03/creating-better-user-experiences-on.html | S |
| 15 | Google Play, Inappropriate Content | https://support.google.com/googleplay/android-developer/answer/9878810 | S |

## 1. Що піднімає рейтинг
**Apple, P (#1).** Цитати зі сторінки:
- Рейтинг генерує Apple: «Apple generates appropriate ratings based on your answer to the age rating questionnaire». IARC, PEGI і ESRB на сторінці не згадані.
- Шкала 4+/9+/13+/16+/18+ діє для пристроїв «running a minimum of iOS 26 … macOS Tahoe 26». Для старших ОС діє 4+/9+/12+/17+ (розділ «Age ratings on OS versions earlier than 26»).
- **Cartoon or Fantasy Violence**: «exaggerated or fantastical nature that can easily be distinguished from real life». Infrequent → 9+, Frequent → 13+.
- **Realistic Violence**: «humans in lifelike situations. May include: a bloody nose from being punched … combat between characters». Infrequent → 13+, Frequent → 18+ (на ОС < 26 — 17+).
- **Prolonged Graphic or Sadistic Realistic Violence**: «realistic and/or extreme depictions of gore, human injury, or death» → **Unrated**, тобто «can't be published on the App Store».

**ESRB, S (#2).**
- T: «violence … minimal blood». M: «intense violence, blood and gore».
- Дескриптори: **Animated Blood** — «discolored and/or unrealistic depictions of blood». **Blood** — «depictions of blood». **Blood and Gore** — «blood or the mutilation of body parts». **Fantasy Violence** — «easily distinguishable from real life». **Violence** — «may contain bloodless dismemberment». **Intense Violence** — «graphic and realistic-looking … realistic blood, gore … human injury and death». Префікс «Mild» означає низьку частоту чи інтенсивність.

**PEGI, S (#7).**
- 12: «violence in a fantasy environment or non-realistic violence towards human-like characters».
- 16: насильство «looks the same as would be expected in real life».
- 18: «gross violence, apparently motiveless killing, or violence towards defenceless characters».

**USK, S (#11).** Насильство оцінюють суворіше, коли воно «credible, detailed and/or realistic». До уваги беруть детальну кров, наслідки поранень і можливість відсікати кінцівки.

**CERO, S (#12).** Рейтинги A / B12 / C15 / D17 / Z18. Значок насильства охоплює зокрема «animated blood», «mutilation/body-cutting», «corpse», «killing/wounding» і «versus fighting». Для Z ключове формулювання — «extremely cruel impression».

**IARC, S (#4, #10).** Одна анкета видає рейтинги для кожного регіону. Анкета доступна лише в порталі вітрини. IARC використовують Microsoft Store (Windows/Xbox), Nintendo eShop, PlayStation Store і Google Play. Застосунок без анкети в Google Play стає «Unrated» і може бути заблокований (#14).

**«Смерть персонажа».** Пряме слово «death» є лише в Apple: у категорії Unrated (графічно) і в Horror/Fear. У ESRB воно є в Intense Violence (S). Чи вважається KO у файтингу без gore «смертю», жодне джерело не каже: **UNGROUNDED**.

**Збіжність.** Усі п'ять органів (Apple — P, решта — S) піднімають рейтинг за реалістичність крові, а не за саму її наявність. Порогу, який можна наперед застосувати до нашого Sketch-Cel, немає: рейтинг видає анкета або рейтер.

## 2. Референси (рейтинг з бази органу)
| гра | ESRB (S, #6) | як показано кров (резюме ESRB) | PEGI (S, #9) |
|---|---|---|---|
| Naruto Storm 3 | T · Blood, Violence | малі сплески крові від ударів клинком; у кат-сцені персонаж настромлений на кіготь | UNGROUNDED |
| Storm Revolution | T · Mild Blood, Violence … | малі сплески від клинка одного персонажа | UNGROUNDED |
| Storm 4 | T · Blood, Language, Suggestive Themes, Violence | сплески, коли перемагають ніндзя або б'ють гігантів мечем | UNGROUNDED: сніпети суперечать (12 для Road to Boruto на Switch проти «18») |
| Storm Connections | T · Mild Blood, Mild Language, Suggestive Themes, Violence | чорна або червона кров на обличчі й одязі в кат-сценах і на стоп-кадрах | UNGROUNDED |
| Guilty Gear Strive (cel) | T · Blood, Language, Mild Suggestive Themes, Violence | сплески в бою; кат-сцена зі шипом | 16 (S) |
| Demon Slayer Hinokami (cel) | T · **Blood and Gore**, Language, Violence | сплески з шиї на фінішах; кат-сцена з відрубаною головою демона | 16 (S): бій нереалістичний, але в кат-сценах реалістичне насильство до людей із видимою кров'ю |
| Mortal Kombat 1 (контраст) | **M** · Blood and Gore, Intense Violence, Strong Language | великі сплески, рентген переломів, розчленування, органи | 18 (S): gross violence, насильство над беззахисними |

**Що видно з цих рядків (спостереження, а не правило органу).**
- В ESRB аніме-файтинги зі сплесками крові тримаються на T, навіть із дескриптором «Blood and Gore» (Demon Slayer).
- M з'являється разом з Intense Violence і графічним розчленуванням (MK1).
- У PEGI той самий Demon Slayer піднявся до 16 через кат-сцени з людьми, тож кат-сцени важать.

## 3. Перемикач крові
- **ESRB, S (#3).** Відео для рейтингу має містити «the most "extreme" content». Заблокований контент теж треба розкрити, «if it is pertinent to a rating». За нерозкриття штраф до $1M. Marvel's Wolverine має налаштування, що зменшують кров і розчленування, і все одно отримав M з Blood and Gore (#5). Висновок, що перемикач не знижує рейтинг, — узагальнення T3 з одного випадку; як правило ESRB **UNGROUNDED**.
- **PEGI, S (#8).** Анкету заповнюють «for every version». Правила для перемикача крові не знайдено: **UNGROUNDED**.
- **Apple, P (#1).** Розробник вказує «frequency or presence of each in your app». Чи враховують вміст, який можна вимкнути, сторінка не каже: **UNGROUNDED**.
- **Німеччина, S (#13).** З 2024-11-15 Steam не показує в Німеччині гру без чинного вікового рейтингу. Рейтинг дає USK або самооцінка Valve через content survey. Вимогу USK мати перемикач крові **не знайдено**.
- **Китай.** Першоджерела NPPA не знайдено, є лише преса (TechCrunch, 2019-04-21) про заборону крові й трупів, зокрема перефарбованих. **UNGROUNDED**. Китаю немає серед цільових платформ (`docs/system/constitution.md:20`).

## 4. Наслідки для нас
| варіант подачі | очікуваний рейтинг за джерелами | ризик для мобільних магазинів |
|---|---|---|
| V1. Без крові: іскри, чорнильні клапті «сторінок» | Apple: cartoon/fantasy → 9+ (рідко) або 13+ (часто), P. ESRB: Fantasy Violence / Violence (S), категорія UNGROUNDED | низький |
| V2. Стилізована кров: неприродний колір або штрих, короткі сплески, без розчленування | ESRB: є дескриптор Animated Blood (S); Storm і GG Strive мають T (S). PEGI: 12 чи 16 — UNGROUNDED (GG Strive 16, S). Apple: 13+, якщо це cartoon/fantasy; якщо це realistic — 13+ (рідко) або 18+ (часто), P | середній: класифікацію робить анкета чи рецензент, не ми |
| V3. Червоні сплески як у Storm 4 / Demon Slayer, з пораненнями людей у кат-сценах | ESRB T (S). PEGI 16 за прикладом Demon Slayer (S). Apple: якщо realistic і frequent — 18+ (на ОС < 26 — 17+), P | помірний: 18+ звужує аудиторію iOS; поріг Google за регіонами IARC не відкрито |
| V4. Реалістична кров, розчленування, фатальності (MK1) | ESRB M, PEGI 18 (S). Apple: «gore, human injury, or death» → **Unrated, у App Store не публікується**, P. Політика Google (S, #15) забороняє «graphic depictions … of realistic violence», але дозволяє вигадане ігрове насильство | **високий: iOS закритий** |
| V5. V3 або V4 за замовчуванням плюс перемикач «вимкнути кров» | ESRB рейтингує за найекстремальнішим вмістом (S, #3; приклад Wolverine, #5). Для PEGI, Apple та IARC — UNGROUNDED | за наявними даними перемикач рейтингу не рятує |

**Факт канону для класифікації.** Вороги — «одинадцять тіней-сторінок у вкрадених тілах» (`docs/World/Lore.md:64`), тобто людські тіла. PEGI 12 розмежовує fantasy і human-like персонажів (S), тож це може важити. Остаточну класифікацію робить рейтинговий орган, а не цей бриф.

## Відкрите
- Звірити всі рядки S, коли буде доступ до pegi.info, esrb.org, usk.de, cero.gr.jp, globalratings.com, support.google.com і partner.steamgames.com. До цього S — не підстава для ADR.
- Реальні питання анкети IARC: доступні лише в Play Console або Partner Center.
- Вимоги до рейтингу для PS5/Xbox через W4 і дискові видання: не досліджувалось.
- Чи вважають органи KO-«смерть» у файтингу без gore тим самим, що смерть у кат-сцені: UNGROUNDED.
- Рейтинги PEGI для лінійки Storm: UNGROUNDED.

**Підсумок T3 для T1.** Межу задає Apple (P): реалістичне «gore, human injury, or death» означає Unrated — iOS закритий; часта реалістична кров — 18+; cartoon/fantasy — не більше 13+. Тому V4 (стиль MK1) несумісний з Android/iOS з конституції. Референси (S): Storm, GG Strive і Demon Slayer мають ESRB T зі сплесками крові; PEGI для стилізованих файтингів — 16. Перемикач крові за наявними даними рейтинг не знижує.

## Related
- [[state]] · [[constitution]] · [[Style-Guide]] · [[05-Platforms-Input]] · [[Export-Platforms]]
- [[2026-10-07-City-Encounter-Options]] · [[Lore]] · [[2026-10-07-Rating-Rows-Verification]] (звірка S-рядків, 2026-10-07)
