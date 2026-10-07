# Звірка рядків S рейтингового брифу з першоджерелами

**Дата:** 2026-10-07 · **Роль:** T3 Архімед (sub-agent, лише читання) · **Крок 7** плану [[2026-10-07-First-Enemy-Lethal-Fight]]

> Записав T1 Дедал зі звіту T3 без зміни змісту; змінено лише особу («я» → «T3»/безособово) і в п. 3.2 додано «на момент звірки». T1 переміряв у цій сесії: `curl -sS -o /dev/null -w '%{http_code}'` → `000` для pegi.info/what-do-the-labels-mean, www.esrb.org/ratings-guide/, www.globalratings.com/how-iarc-works.aspx; `200` для developer.apple.com/app-store/review/guidelines/; у тексті сторінки Apple знайдено «Last Updated: June 8, 2026», цитату 1.1.2 і «gruesome death» з 2.3.8.

## Питання
1. Кожен рядок рівня S у [[2026-10-07-Blood-And-Lethal-Rating]] → P або UNGROUNDED.
2. Як органи класифікують таку подачу: стилізована червона кров із чорнильним обідком на чистому влучанні, смерть ворога-людини на вирішальному KO, без розчленування. Окремо PEGI 12/16, ESRB T/M, IARC.
3. Чи змінює рейтинг перемикач BLOOD (Full/Muted/Ink/Off), якщо типове значення Full.

## Доступ до першоджерел (2026-10-07, ~15:36 UTC)
`curl -sS -o /dev/null -w '%{http_code}' --max-time 25 <url>`:

| URL | код |
|---|---|
| https://pegi.info/what-do-the-labels-mean · /page/how-we-rate-games · /search-pegi | `curl: (56) CONNECT tunnel failed, response 403` → `000` |
| https://www.esrb.org/ratings-guide/ · /ratings/ratings-process/ · /blog/a-parents-guide-to-marvels-wolverine/ · /blog/esrb-ratings-expand-to-mobile-via-new-global-rating-system/ | 403 → `000` |
| https://www.globalratings.com/how-iarc-works.aspx · https://globalratings.com/how-iarc-works/ | 403 → `000` |
| https://support.google.com/googleplay/android-developer/answer/9878810 · https://play.google.com/about/restricted-content/inappropriate-content/ | 403 → `000` |
| https://android-developers.googleblog.com/2015/03/… · usk.de PDF · cero.gr.jp · partner.steamgames.com | 403 → `000` |
| https://developer.apple.com/app-store/review/guidelines/ | **200** |
| https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions/ | **302** → `…/reference/app-information/age-ratings-values-and-definitions` → 200 |

`curl -sS "$HTTPS_PROXY/__agentproxy/status"` → `recentRelayFailures`: `"gateway answered 403 to CONNECT (policy denial or upstream failure)"` для pegi.info, www.esrb.org, www.globalratings.com, globalratings.com, support.google.com, play.google.com.
WebFetch на pegi.info, www.esrb.org, www.globalratings.com, support.google.com → `{"error_type":"EGRESS_BLOCKED"}`.

README проксі велить не обходити 403, тому архівні копії (web.archive.org тощо) T3 не відкривав.

## 1. Рядки брифу: було → стало

| рядок брифу | було | стало | цитата (≤ 2 речень) |
|---|---|---|---|
| :45–47 ESRB: T/M і дескриптори Animated Blood / Blood / Blood and Gore / Violence / Intense Violence (#2) | S | **UNGROUNDED**: www.esrb.org 403. Повторний пошук дав те саме формулювання, але з вторинних сайтів (strategywiki.org, pluggedin.com), тобто знову S | сніпет S: «Animated Blood: Discolored and/or unrealistic depictions of blood» |
| :49–52 PEGI 12 / 16 / 18 (#7) | S | **UNGROUNDED**: pegi.info 403. Пошук дав **новий S-сніпет, якого в брифі немає** (askaboutgames.com, хост теж блокований) | сніпет S: «PEGI 12 … there must not be any sight of blood or injuries, or an emphasis on pain, during violence towards humans» |
| :54 USK (#11) | S | **UNGROUNDED**: usk.de 403 (поза межами задачі) | — |
| :56 CERO (#12) | S | **UNGROUNDED**: cero.gr.jp 403 (поза межами задачі) | — |
| :58 IARC: одна анкета видає рейтинги регіонів, анкета лише в порталі вітрини, вітрини-учасники (#4, #10) | S | **UNGROUNDED**: globalratings.com і www.esrb.org 403. Сніпет Google (support.google.com/…/188189, 9859655, хост блокований) з цим збігається, але це S | сніпет S: «Content ratings on Google Play are provided by the International Age Rating Coalition (IARC)» |
| :58 «без анкети Google Play → Unrated, може бути заблокований» (#14) | S | **UNGROUNDED**: android-developers.googleblog.com 403 | — |
| :60 «death» у ESRB Intense Violence | S | **UNGROUNDED**: www.esrb.org 403 | — |
| :62 «усі п'ять органів піднімають рейтинг за реалістичність» | Apple P + 4×S | Збіжності немає: заземлений тільки Apple (P, див. нижче), решта UNGROUNDED | — |
| :67–73 ESRB-рейтинги Storm 3/Rev/4/Connections, GG Strive, Demon Slayer, MK1 (#6); PEGI GG Strive 16, Demon Slayer 16, MK1 18 (#9) | S | **UNGROUNDED** для всіх: esrb.org і pegi.info 403 | — |
| :81 ESRB: відео з «most extreme», розкриття заблокованого контенту, штраф $1M (#3); Wolverine M (#5) | S | **UNGROUNDED**: 403. Сніпет повторного пошуку з самого esrb.org/ratings/ratings-process з брифом збігається, але сторінку не відкрито, тож це S | сніпет S: «Unplayable content (i.e., "locked out"), if it is pertinent to a rating, must also be disclosed» |
| :82 PEGI: анкета «for every version» (#8) | S | **UNGROUNDED**: pegi.info 403. Вторинний сніпет (localization.it) у тому ж дусі | сніпет S: «Prior to release of each version of a game, the publisher completes an online form» |
| :84 Steam Німеччина (#13) | S | **UNGROUNDED**: partner.steamgames.com 403 (поза межами задачі) | — |
| :93 Google Play Inappropriate Content (#15) | S | **UNGROUNDED**: support.google.com і play.google.com 403 | — |
| :90–94 ESRB/PEGI-частини матриці V1–V5 | S | **UNGROUNDED**: успадковують статус рядків вище | — |
| :38–43, :90–94 Apple-частини (#1) | P | **P, перечитано**. URL після редиректу: `https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions`, дата доступу 2026-10-07; дати версії на сторінці немає | «Prolonged Graphic or Sadistic Realistic Violence: Prolonged detailed or realistic-looking depictions of physical conflict. May include: realistic and/or extreme depictions of gore, human injury, or death.» |

Підтверджені Apple-пороги (та сама сторінка, P). Для ОС ≥ 26: Frequent cartoon/fantasy → 13+; Infrequent realistic → 13+; Frequent realistic → 18+; prolonged graphic/sadistic realistic → Unrated («can't be published on the App Store»). Для ОС < 26: «Frequent or intense cartoon or fantasy violence» і «Infrequent or mild occurrences of realistic violence» → 12+, «Frequent or intense realistic violence» → 17+.

### Нові P-факти (Apple, у брифі їх не було)
- **App Review Guidelines 1.1.2**, https://developer.apple.com/app-store/review/guidelines/, «Last Updated: June 8, 2026»: «Realistic portrayals of people or animals being killed, maimed, tortured, or abused, or content that encourages violence.» Пункт входить у 1.1 «Objectionable Content».
- **Guidelines 2.3.8**, та сама сторінка: «make sure your app and in-app purchase icons, screenshots, and previews adhere to a 4+ age rating even if your app is rated higher. For example, if your app is a game that includes violence, select images that don't depict a gruesome death…»
- **Set an app age rating**, https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating (200, дата версії не вказана): «This questionnaire includes a list of content descriptors, in-app controls, and capabilities that allow you to specify the frequency of each content type in your app.» Про in-app controls: «select any that your app includes that can restrict content». Що вибір такого контролю знижує рейтинг, сторінка не каже. У таблиці 4+ «Parental controls» лише перелічено як допустимий елемент.
- **Франція**, сторінка вікових рейтингів, розділ для ОС < 26: «apps with a 17+ Apple global age rating will display an additional regional rating of 18+ on the App Store in France».

Команди: `curl -sS -L -o guidelines.html https://developer.apple.com/app-store/review/guidelines/` → 200; HTML переведено в текст (`python3 -I`); `grep -n "1.1.2\|Last Updated"` → рядки 179–180, 808–809.

## 2. Відповідь щодо нашої подачі
- **PEGI 12 чи 16, дескриптори:** UNGROUNDED, бо pegi.info 403. Сніпети різняться. У брифі PEGI 12 — «non-realistic violence towards human-like characters». Новий сніпет каже, що в PEGI 12 «no sight of blood or injuries … during violence towards humans». Якщо другий правильний, червона кров на людському тілі ворога (`Lore.md:64`) веде до 16. Першоджерелом не перевірено.
- **ESRB T чи M, «Blood» чи «Blood and Gore», «Violence» чи «Intense Violence»:** UNGROUNDED, www.esrb.org 403. За S-визначеннями «Animated Blood» означає «discolored and/or unrealistic», а наш `#A3243B` червоний. Який дескриптор дасть рейтер, джерела не кажуть.
- **IARC:** UNGROUNDED, globalratings.com 403. Відповідь видає лише анкета в Play Console або Partner Center (S).
- **Apple (P):** категорію Cartoon/Fantasy чи Realistic декларує розробник в анкеті, перевіряє App Review. Межі стилізації ні Apple-сторінка, ні 1.1.2 не визначають. Unrated означає тільки «prolonged graphic or sadistic realistic». Чи підпадає cel-смерть ворога на KO під «realistic portrayals of people … being killed» (1.1.2), джерело не каже: **UNGROUNDED**.
- **Перемикач BLOOD при типовому Full:** ESRB — у S-рядку рейтинг дають за найекстремальнішим контентом, разом із заблокованим, якщо той «pertinent», але першоджерело не відкрито. PEGI та IARC — UNGROUNDED. Apple (P) — анкета питає про частоту контенту «in your app»; правила, за яким вимикний чи нетиповий контент знижує рейтинг, не знайдено: **UNGROUNDED**.

## 3. Що з цього стосується ADR-024 п. 7 (лише факти; рішення за T1/Santos)
1. Перевірка кроку 7 («кожен рядок S → P або UNGROUNDED») формально закрита: усі рядки PEGI/ESRB/IARC/Google стали **UNGROUNDED через 403**, а не через суперечність. Наслідок ADR-024 «звірити до будь-якої публікації на консолях/мобільних» лишається **відкритим**.
2. Код уже має типове Full. Файл `game/scripts/core/ContentSettings.gd`, рядки 14–15: `## Santos's word (ADR-024 п. 7): Full by default — PLACEHOLDER until the rating rows are grounded (plan step 7).` і `const DEFAULT_BLOOD := "full"`. Отримано через `sed -n '1,40p' … | grep -n`. Файл на момент звірки не закомічений: `git status --short` → `??`. Умову «до звірки» з коментаря ця сесія не зняла.
3. Apple (P): у текстах немає ознаки, що типове значення (Full чи Ink) або сам перемикач впливають на рейтинг. Рейтинг визначає задекларована частота контенту в застосунку.
4. Apple 2.3.8 (P), незалежно від типового значення: іконки, скриншоти й прев'ю мають відповідати 4+, без «gruesome death». Кадри крові чи KO-смерті в метаданих стору з цим конфліктують.
5. Неперевірений, але суттєвий сигнал (S): правило PEGI 12 «без видимої крові під час насильства над людьми». Якщо його підтвердять, Full на людському тілі в PEGI-регіонах тягне до 16. Чи рейтингує PEGI за типовим чи за найгіршим режимом — UNGROUNDED.
6. Франція (P): глобальний 17+ (ОС < 26) показується там як 18+.

## Відкрите
- Відкрити з машини з доступом (наприклад, Mac Santos) такі сторінки: pegi.info/what-do-the-labels-mean, pegi.info/page/how-we-rate-games, www.esrb.org/ratings-guide/, www.esrb.org/ratings/ratings-process/, globalratings.com/how-iarc-works, support.google.com/googleplay/android-developer/answer/9878810 і 188189, а також ESRB/PEGI-сторінки ігор із #6/#9.
- Найточніша відповідь щодо IARC і перемикача — пробна анкета IARC у Play Console або Partner Center. Відповідь «чи можна вимкнути» там не перевірена.
- Чи вважає PEGI/ESRB KO-смерть без gore «смертю» — UNGROUNDED.
- Чи вважає Apple гравцеві налаштування BLOOD «in-app control», що «can restrict content», і чи це щось змінює — UNGROUNDED.

## Related
- [[2026-10-07-Blood-And-Lethal-Rating]] · [[ADR-024-Lethal-Fights-And-First-Enemy]] · [[2026-10-07-First-Enemy-Lethal-Fight]]
- [[2026-10-07-Blood-Visual-Language]] · [[05-Platforms-Input]] · [[Export-Platforms]] · [[state]] · [[constitution]]
