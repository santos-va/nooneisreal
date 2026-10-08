# Алкоголь, тютюн, трава, вода й «корисна» їжа: вікові рейтинги та правила сторів

**Дата:** 2026-10-08 · **Роль:** T3 Архімед (sub-agent, лише читання)

> Текст написав T3 Архімед, файл записує T1 без зміни змісту (`CLAUDE.md`, розділ «Агенти»). Рівні: **P** — першоджерело відкрито й прочитано в цій сесії. **S** — пошукова видача або вторинне джерело, сторінку не відкрито (403). **UNGROUNDED** — першоджерела немає або джерела розходяться. Бриф продовжує [[2026-10-07-Drug-And-Street-Crime-Rating]]. Цитати Apple звідти (1.4.3, 2.3.8, таблиці) у цій сесії перевірено заново.

## Питання
Слово Santos (2026-10-08): у грі будуть намальовані косяки, бонги, алкоголь, сигарети, вода, а також корисні продукти з «вітамінами» й «протеїном для м'язів». Ефекти речовин — без бонусів: `grep -n "жодних бонусів" docs/Decisions/ADR-025-Street-Scuffle-And-City-Events.md` → `26: - жодних бонусів, відмова без покарання;`.
1. Apple (схема 4+/9+/13+/16+/18+): як рахується рядок про речовини; чи змінює рівень атрибутика без показу вживання; чи важить те, що гравець «вживає» сам.
2. Steam: що декларувати.
3. PEGI і ESRB: reference / use / encourage / glamorise.
4. Google Play (IARC).
5. Чи підвищує рейтинг ігровий бонус від речовини.
6. Прецеденти без бонусів.
7. Чи потрібен окремий перемикач.
8. «Протеїн для м'язів» як харчова чи медична заява.

## Доступ до джерел (2026-10-08, 07:54–08:06 UTC)
Команда: `curl -sS -o /dev/null -w '%{http_code}' --max-time 25 <url>`.

| URL | результат |
|---|---|
| developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions | **200**, дати версії на сторінці немає |
| developer.apple.com/app-store/review/guidelines/ | **200**, «Last Updated: June 8, 2026» |
| developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating | **200** |
| pegi.info · www.esrb.org · esrb.org · www.globalratings.com · support.google.com (9898843, 188189) · partner.steamgames.com (contentsurvey, content_descriptors) · store.steampowered.com · usk.de · en.wikipedia.org · classification.gov.au · legislation.gov.au/F2023L01424 (посилання дає сама сторінка Apple) · legislation.gov.uk · eur-lex.europa.eu · asa.org.uk · apps.apple.com · play.google.com · xbox.com (сюди редиректять сторінки microsoft.com/p/…) | `curl: (56) CONNECT tunnel failed, response 403` → `000` |

- WebFetch на www.esrb.org, pegi.info і partner.steamgames.com → `EGRESS_BLOCKED`.
- Статус проксі показує `connect_rejected`, «gateway answered 403 to CONNECT (policy denial or upstream failure)», наприклад `www.cap.org.uk:443` о 08:02:58Z.
- Архіви й дзеркала не пробував: README проксі каже «do not retry or route around it».

Сторінки Apple збережено в scratchpad сесії (не в репо) і перетворено на текст: прибрано теги, по рядку на абзац. Номери рядків нижче (`ages.txt`, `guide.txt`, `set.txt`) відносяться до цих копій. Хеші: `sha256sum` → ages `bda1d733d13f3423…`, guidelines `52fa01176a114271…`, set `9dcd0007b2182b68…`.

## 1. Apple (P)

**Визначення** (ages.txt:979): «Alcohol, Tobacco, or Drug Use or References: References to or depictions of the consumption of alcohol, tobacco products, or other licit or illicit substances. May include: drunken behavior, cigarette smoking, or the taking of illegal drugs.»

**Пороги:**
- ОС ≥ 26 (ages.txt:1035, 1058): «Infrequent alcohol, tobacco, or drug use or references» стоїть у **13+**, «Frequent …» — у **18+**. Рівня 16+ для цього рядка немає: з 13+ одразу 18+.
- ОС < 26 (ages.txt:1307, 1322): «Infrequent or mild references…» — **12+**, «Frequent or intense references…» — **17+**.
- Регіони, ОС ≥ 26 (рядки 1142/1151, 1197/1220, 1250/1282, звірено із заголовками таблиць): Бразилія A14 / A16, Корея 12+ / 19+, В'єтнам 12+ / 18+.

**(а) Рідко чи часто.** Визначення немає.
- `grep -c -i infrequent set.txt` → `0`. На сторінці рейтингів ці слова є лише в назвах рядків таблиць.
- Частоту декларує розробник в анкеті («specify the frequency of each content type», set.txt:956). Відповідати чесно вимагає 2.3.6.
- Де межа — **UNGROUNDED**. Для гри це головна розвилка: 13+ проти 18+. Постійні пропси (пляшки на ятці, перехожі з цигаркою по всьому місту) за буденним прочитанням ближчі до «frequent». Але Apple цього не визначає.

**(б) Атрибутика без вживання (бонг, пляшка на полиці).**
- Рядок один і на вживання, і на згадку («use or references»). Окремого пункту «лише атрибутика» в таблицях немає. Тож пропс не переносить гру в інший рядок, важить тільки частота.
- Чи вважає рецензент намальований бонг без дії згадкою про вживання («reference to the consumption»): буквально так, бо це знаряддя вживання. Практика — **UNGROUNDED**.

**(в) Інтерактивність.**
- `grep -c -i interactiv ages.txt` → `0`. `grep -c -i incentive` по трьох сторінках → `0 0 0`. Слово «reward» є лише в рядку Contests (ages.txt:995).
- Таблиця Apple не розрізняє, хто вживає — гравець чи NPC.
- Єдиний важіль — 1.4.3 (guide.txt:189): «Apps that encourage consumption of tobacco and vape products, illegal drugs, or excessive amounts of alcohol are not permitted. Apps that encourage minors to consume any of these substances will be rejected.»
- Межа «encourage» в тексті не визначена → **UNGROUNDED**.

**(г) Вода, вітаміни, протеїн.**
- У визначенні є «other licit or illicit substances», але приклади — лише алкоголь, куріння й нелегальні наркотики.
- Чи підпадає під рядок їжа з «вітамінами» — **UNGROUNDED**. Прочитання «будь-яка законна речовина» охопило б і хліб, тож навряд чи так задумано. Це мій висновок, не джерело.

**(д) Метадані.**
- 2.3.8 (guide.txt:215): іконки, скриншоти й прев'ю мають відповідати 4+.
- У блоці 4+ (ages.txt:1002–1012) немає жодного рядка про речовини. Пляшка, сигарета чи бонг у кадрі сторінки стору конфліктують із 4+ так само, як листки (бриф 2026-10-07, § 3).
- Наскільки суворо це застосовують — **UNGROUNDED**.

**(е) Австралія через Apple.**
- Австралійська таблиця відрізняється від глобальної лише соцмережами, loot boxes і simulated gambling.
- Далі (ages.txt:1088): «If we're notified by the regulator that your app doesn't meet their guidelines or requires a region-specific rating, you'll receive a message from App Review.»
- Сама Apple посилається на «Australia's guidelines for the classification of computer games» (legislation.gov.au/F2023L01424 — 403).

## 2. Steam — UNGROUNDED (403 / EGRESS_BLOCKED)
S (сторінки не відкрито): partner.steamgames.com/doc/gettingstarted/contentsurvey і …/contentsurvey/germany, gamingonlinux.com (2024/10, «from november 15 all steam games sold in germany will need an age rating»), steamcommunity.com/discussions/forum/0/4337599680247610574.
- Анкета має три частини: General Content, Mature Content, Generative AI. General Content «will generate ratings for several regional rating boards».
- З 2024-11-15 Steam не показує в Німеччині гру без рейтингу. Власний рейтинг Valve рахує з цієї анкети.
- «You must disclose all the adult content you've uploaded in your builds, even if it's not accessible or presented in your product.»
- Фільтри покупця: General Mature Content, Frequent Violence or Gore, Some Nudity or Sexual Content, Frequent Nudity or Sexual Content, Adult Only Sexual Content. Окремої категорії для речовин у фільтрі немає (форумна копія, S).
- Точні питання про алкоголь, тютюн і наркотики публічно не опубліковані, їх видно лише в акаунті Steamworks → **UNGROUNDED**.

Наслідок: декларувати все наявне, включно з тим, що вимикає перемикач. Чи дасть це мітку General Mature Content — **UNGROUNDED**.

## 3. ESRB і PEGI — UNGROUNDED (403 / EGRESS_BLOCKED, повторна спроба 2026-10-08)

**ESRB** (S: strategywiki.org/wiki/ESRB, pluggedin.com, images10.newegg.com/…/esrb-ratings.pdf; формулювання збігаються в кількох вторинних джерелах):
- Reference-дескриптори: «Alcohol Reference / Tobacco Reference / Drug Reference — Reference to and/or images of …». Тобто зображення пляшки, сигарети чи бонгу без вживання — це «Reference».
- Use-дескриптори: «Use of Alcohol / Use of Tobacco — The consumption of …», «Use of Drugs — The consumption or use of illegal drugs».
- Дескриптора на кшталт «encourage» чи «glamorize» в ESRB не знайдено.
- Офіційної прив'язки дескрипторів до вікових рівнів ESRB не публікує. Таблиці на кшталт «Use of Drugs → T, M» є лише у фан-вікі → **UNGROUNDED**.

**PEGI** (S: en.wikipedia.org/wiki/PEGI, askaboutgames.com/need-to-know/what-are-content-descriptors, parentzone.org.uk/article/pegi-games-ratings, localization.it 2013):
- Дескриптор: «Drugs: The game refers to or depicts the use of illegal drugs, alcohol or tobacco. Games with this content descriptor are always PEGI 16 or PEGI 18.»
- PEGI 18 — за «glamorisation of the use of illegal drugs».
- Джерела розходяться щодо PEGI 16. Одні: «the use of tobacco, alcohol or illegal drugs can also be present». Інші (2013, parentzone): «encouragement of the use of tobacco or alcohol». Яке формулювання чинне — **UNGROUNDED**.
- Чи ставлять дескриптор Drugs за самий пропс без згадки про вживання (бонг на полиці) — **UNGROUNDED**. Текст дескриптора говорить про «use».

Наслідок, якщо S підтвердиться: будь-яке показане вживання алкоголю, тютюну чи трави дає PEGI ≥ 16 незалежно від частоти. Apple тут м'якша: 13+, якщо вживання рідкісне.

## 4. Google Play / IARC — UNGROUNDED (403)
S: support.google.com/googleplay/android-developer/topic/6181287, …/answer/9878810, …/answer/9878877, globalratings.com/faq.
- Довідка анкети має окремі теми: «Alcohol», «Illegal or recreational drugs», «Incentives for illegal drugs». Окремої теми про тютюн у видачі немає.
- Анкета IARC доступна лише через консоль стору, публічного тексту питань немає. Точне формулювання — **UNGROUNDED**.
- Політика Illegal Activities: «Depicting or encouraging the use or sale of drugs, alcohol, or tobacco by minors.»
- Політика Tobacco and Alcohol: «Portraying excessive drinking favorably, including the favorable portrayal of excessive, binge or competition drinking is not allowed.»

Наслідок: вік героїв стає вхідними даними. Skea — `grep -n "20 років" docs/Characters/Skea.md` → `25: **≈ 20 років**`. Вік Choko не визначено (`docs/World/PROPOSAL-Substances-And-Healthy-Food.md:319`, П7).

## 5. Чи підвищує рейтинг ігровий бонус від речовини

| система | що знайдено | рівень |
|---|---|---|
| Австралія (Classification Board; на Google Play — через IARC, на Apple — через повідомлення регулятора, ages.txt:1088) | Вживання нелегального наркотику, пов'язане із заохоченням чи нагородою («illicit or proscribed drug use related to incentives or rewards»), не допускається на жодному рівні, навіть R18+. Наслідок — відмова в класифікації (RC), тобто заборона продажу. Рада посилається на Guidelines for the Classification of Computer Games 2023 (classification.gov.au/about-us/media-and-news/news/statement-halloween-game); старіші джерела цитують Guidelines 2012 | S — найчіткіше правило з усіх |
| Google Play / IARC | окрема тема «Incentives for illegal drugs» в анкеті | S; як саме вона впливає — UNGROUNDED |
| PEGI | «glamorisation» нелегальних наркотиків → 18 | S; чи вважається бонус «гламуризацією» — UNGROUNDED |
| ESRB | правила про бонус не знайдено | UNGROUNDED |
| Apple | у тексті рейтингу немає «incentive» чи «reward» щодо речовин (grep → 0); є лише «encourage» в 1.4.3 | текст — P; чи є бонус «encourage» — UNGROUNDED |

Що рада вважала нагородою (S):
- **Fallout 3, 2008:** морфін «enabling the character to ignore limb pain, and this ability to progress more easily is the incentive» (theregister.com/2008/07/15/oz_bans_fallout_3).
- **We Happy Few, 2018:** наркотик Joy знижує складність (gamespot, techraptor).
- **Halloween: The Game, 2026:** затяжка ненадовго показує ворога на мапі (dexerto, godisageek.com/2026/08).

Отже, «бонус» тут — будь-яка ігрова перевага, а не лише цифра в статах. Правило у видачі сформульоване як «illicit or proscribed drug». Чи поширюється воно на алкоголь і тютюн — **UNGROUNDED**.

## 6. Прецеденти (S, сторінки не відкрито)

| гра | що є | рішення |
|---|---|---|
| Disco Elysium: The Final Cut (2021) | наркотики й алкоголь; регулярне вживання шкодить прогресу | AU: RC у березні → R18+ після перегляду 11.05.2021, бо вживання має «disincentives» (classification.gov.au/about-us/media-and-news/news/disco-elysium-final-cut-classified-r-18; press-start.com.au 2021/05/14) |
| Fallout 3 (2008) | вигадані «chems» і морфін із перевагою | AU: RC → MA15+ після того, як «reward and incentive» було «significantly toned down»; морфін перейменовано на Med-X (bit-tech; gamespot 1100-6195752) |
| We Happy Few (2018) | наркотик Joy | AU: RC → R18+ без змін у грі, з поясненням для покупця «fantasy violence and interactive drug use» (gamespot 1100-6460180) |
| Night in the Woods (2017) | герої п'ють і курять за сюжетом | ESRB T; серед дескрипторів Use of Alcohol and Tobacco, Drug Reference (сторінка esrb.org/ratings/37295 у видачі). Чи справді вживання не дає бонусу — не перевірено |

Протилежний бік (бонус → RC): Saints Row IV і State of Decay (2013), RimWorld, Halloween: The Game (2026).

## 7. Чи потрібен окремий перемикач
Жодної вимоги не знайдено.
- **Apple (P):** «In-App Controls» (Parental Controls, Age Assurance, ages.txt:967) — це декларація, а не вимога. Вони стоять у блоці 4+ і рейтингу не знижують. Змінити рейтинг можна лише вгору: «Override to Higher Age Rating» (set.txt:978). Знизити його перемикачем не можна.
- **Steam (S):** декларувати треба навіть недоступний вміст, тож перемикач рейтингу не знижує.
- **PEGI, ESRB, IARC — UNGROUNDED (403).** У видачі про перемикачі нічого.

Отже, перемикач `drugs` — це комфорт гравця, а не засіб рейтингу:
- `git show HEAD:game/scripts/core/ContentSettings.gd | grep -n DRUGS_MODES` → `17: const DRUGS_MODES: Array[String] = ["full", "off"]`;
- рядок у COMFORT поки лише в робочому дереві: `git show HEAD:game/scripts/ui/ComfortPanel.gd | grep -c DRUGS` → `0`, у файлі на диску → `9`.

## 8. «Протеїн для м'язів» і «вітаміни» як заява
- **Apple (P).** Є окремий рядок (ages.txt:982): «Health or Wellness Topics: Content that provides self-care or lifestyle recommendations. May include: calorie tracking, dieting advice, or exercise recommendations». У таблиці він стоїть у **9+** (ages.txt:1019). Предмет у вигаданому світі, що діє на героя, буквально не є порадою гравцеві. Чи прочитає рецензент підпис «протеїн для м'язів» як «dieting advice» — **UNGROUNDED**.
- **1.4.1** (guide.txt:184) стосується медичних застосунків, тобто не гри.
- **ЄС.** За видачею (S; legislation.gov.uk — 403), регламент ЄС 1924/2006 про nutrition and health claims покриває «commercial communications» про харчові продукти, що постачаються споживачу. Вигаданий предмет без зв'язку зі справжнім брендом, судячи з цього, поза сферою дії. Але рішення чи настанови саме про ігрові предмети не знайдено → **UNGROUNDED**.
- **Вигляд (S, Fallout 3).** Австралійська рада зважала й на реалістичний вигляд наркотику та способу його введення. Таблетки чи шприц із бонусом можуть читатися як наркотик із нагородою, навіть якщо в грі це «вітаміни». Це лінза для T6, не правило.

## Зведена таблиця

| рейтингова система | що декларувати | наслідок для гри |
|---|---|---|
| Apple, ОС ≥ 26 (P) | «Alcohol, Tobacco, or Drug Use or References»: Infrequent або Frequent. Пропси й вживання — той самий рядок | Рідко → 13+, часто → 18+ (16+ немає). Межа частоти не визначена (UNGROUNDED). Скриншоти — на рівні 4+, без речовин у кадрі. 1.4.3 забороняє «encourage» |
| Apple, ОС < 26 і регіони (P) | те саме | 12+ / 17+; Бразилія A14 / A16; Корея 12+ / 19+; В'єтнам 12+ / 18+ |
| Apple, «Health or Wellness Topics» (P) | лише якщо підписи їжі читаються як порада гравцеві (UNGROUNDED) | 9+, нижче за рядок речовин; на підсумковий рівень не впливає |
| Steam (S, UNGROUNDED) | усе в General Content і Mature Content, включно з вимкненим перемикачем | регіональні рейтинги з анкети (Німеччина — з 2024-11-15); точні питання видно лише в Steamworks |
| ESRB (S, UNGROUNDED) | Alcohol / Tobacco / Drug Reference — за зображення; Use of … — за вживання | вікові рівні за дескрипторами офіційно не опубліковані; прецедент Night in the Woods — T |
| PEGI (S, UNGROUNDED) | Drugs — за згадку чи показ вживання алкоголю, тютюну, наркотиків | ≥ 16; гламуризація наркотиків → 18; чи дає Drugs самий пропс — UNGROUNDED |
| Google Play / IARC (S, UNGROUNDED) | Alcohol · Illegal or recreational drugs · Incentives for illegal drugs | бонус від трави — окреме питання анкети; політика забороняє показ вживання неповнолітніми й прихильний показ пияцтва |
| Австралія (через IARC і Apple; S) | — | бонус від нелегального наркотику → RC (заборона продажу) на будь-якому рівні; без бонусу — MA15+ або R18+ |

## Висновки для T1
1. **Apple (P):** уся атрибутика й вживання — один рядок: рідко 13+, часто 18+, рівня 16+ немає. Межу частоти Apple не визначає. Тож рішення «скільки пляшок і цигарок у місті» напряму вибирає між 13+ і 18+.
2. **PEGI (S):** будь-яке показане вживання алкоголю, тютюну чи трави дає ≥ 16. Отже, для Європи нижня межа, найімовірніше, 16 незалежно від частоти. Перевірити, коли pegi.info стане доступним.
3. **«Без бонусів» (ADR-025)** збігається з найжорсткішим знайденим правилом (Австралія, S: бонус від наркотику → RC). «Бонус» там — будь-яка ігрова перевага: легший прогрес, нижча складність, підказка про ворога. Аудит має перевірити й непрямі переваги «Заплутаності» та алкоголю, наприклад ситість від пива на шкалі голоду.
4. **Перемикач** не вимагає жоден знайдений текст, і рейтингу він не знижує: Apple дозволяє змінювати рейтинг лише вгору (P), Steam вимагає декларувати й недоступний вміст (S). `drugs` у `ContentSettings` — комфорт, а не інструмент рейтингу.
5. **Вітаміни й протеїн** із бонусом проблем із рейтингом за знайденими текстами не створюють: рядок про речовини їх не називає, щодо ЄС 1924/2006 — UNGROUNDED. Ризик з'являється, якщо намалювати їх як таблетки чи шприц або якщо герой неповнолітній. Вік Choko не визначено, а Google (S) забороняє показувати вживання неповнолітніми.

## Відкрите
- Відкрити з машини з доступом (Mac Santos) і перевести S → P: pegi.info, esrb.org, globalratings.com, support.google.com, partner.steamgames.com, classification.gov.au, legislation.gov.au/F2023L01424.
- Межа Infrequent / Frequent — лише в анкеті App Store Connect, потрібен вхід.
- Точні питання анкет Steam і IARC — лише в консолях сторів.
- Чи поширюється австралійське правило про заохочення чи нагороду («incentives or rewards») на алкоголь і тютюн.
- Вік Choko (П7 у [[PROPOSAL-Substances-And-Healthy-Food]]).
- USK, GRAC, ClassInd і консольні сертифікації Sony / Microsoft не досліджувались.

**Примітка T1 (2026-10-08):** рівні P/S/UNGROUNDED — оцінка T3; T1 не відкривав джерел повторно. Рядок «у файлі на диску → 9» про `ComfortPanel.gd` описує незакомічену роботу T2 на момент запису. Після запису брифу Santos визначив вік: Choko ≈ 20, дорослий ([[ADR-026-Substances-Nutrition-And-Thirst]] п. 5, [[Choko]]) — пункти «вік Choko не визначено» вище вже закриті.

## Related
- [[2026-10-07-Drug-And-Street-Crime-Rating]] · [[2026-10-07-Blood-And-Lethal-Rating]] · [[2026-10-07-Rating-Rows-Verification]]
- [[ADR-025-Street-Scuffle-And-City-Events]] · [[PROPOSAL-Substances-And-Healthy-Food]] · [[2026-10-08-Hunger-Numbers]] · [[06-UI-UX]]
- [[05-Platforms-Input]] · [[Export-Platforms]] · [[state]] · [[constitution]]
