# Наркотики й вуличний злочин у міських подіях: вікові рейтинги та правила стору

**Дата:** 2026-10-07 · **Роль:** T3 Архімед (sub-agent, лише читання)

> Текст написав T3 Архімед, файл записує T1 без зміни змісту (механізм «бриф повертається текстом», `CLAUDE.md`, розділ «Агенти»). Рівні: **P** — першоджерело відкрито й прочитано цієї сесії. **S** — пошуковий сніпет, сторінку не відкрито. **UNGROUNDED** — першоджерела немає.
>
> T1 переперевірив у цій сесії на завантажених копіях сторінок Apple: цитата 1.4.3 («Apps that encourage consumption of tobacco and vape products, illegal drugs, or excessive amounts of alcohol are not permitted. Apps that encourage minors to consume any of these substances will be re…») і розділ 5 («solicit, promote, or encourage criminal or clearly reckless behavior will be rejected») — збігаються; визначення «Alcohol, Tobacco, or Drug Use or References … the taking of illegal drugs» і рядки «Infrequent/Frequent alcohol, tobacco, or drug use or references» — є (`ages.txt:977, 1033, 1056`).

## Питання
Santos хоче дві випадкові події в місті:
- (1) NPC заводить героя в провулок і погрожує ножем, вимагаючи гроші;
- (2) персонаж, над головою якого кружляють 5 листків марихуани, пропонує затягнутись. Якщо гравець погоджується, отримує ефекти: мале поле зору, «голод», забуті репліки.

Що кажуть першоджерела:
1. App Review Guidelines про наркотики (1.4.3) і чи стосується пункт гри, де вживання — вибір персонажа з негативними наслідками.
2. Apple Age ratings: «Alcohol, Tobacco, or Drug Use or References» (рідко/часто, ОС ≥ 26 і < 26), «Violence» і погроза ножем без смерті.
3. Чи стосується пункт 2.3.8 (метадані 4+) листків над головою на скриншотах.
4. PEGI, ESRB, IARC, Google.
5. Чи знімає ризик формулювання «вигадана рослина, без реальної назви».

## Доступ до джерел (2026-10-07, 19:09–19:11 UTC)
| URL | код |
|---|---|
| https://developer.apple.com/app-store/review/guidelines/ | **200**, на сторінці «Last Updated: June 8, 2026» |
| https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions/ | редирект на `…/reference/app-information/age-ratings-values-and-definitions` → **200**; дати версії на сторінці немає |
| https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating | **200** |
| https://pegi.info/what-do-the-labels-mean · https://pegi.info/page/pegi-age-ratings | `curl: (56) CONNECT tunnel failed, response 403` → `000` |
| https://www.esrb.org/ratings-guide/ | 403 → `000` |
| https://www.globalratings.com/how-iarc-works.aspx · https://globalratings.com/ | 403 → `000` |
| https://support.google.com/googleplay/android-developer/answer/9878810 · …/answer/188189 · https://play.google.com/about/restricted-content/inappropriate-content/ | 403 → `000` |
| вторинні копії: xbox.com/en-GB/games/gameratings, nintendo.co.uk (Software Rating Information), en.wikipedia.org/wiki/PEGI, gamesdenmark.dk, askaboutgames.com | 403 → `000` |

Команда: `curl -sS -o /dev/null -w '%{http_code}' --max-time 25 <url>`. WebFetch на pegi.info і www.esrb.org повернув `EGRESS_BLOCKED`. `curl -sS "$HTTPS_PROXY/__agentproxy/status"` показав `connect_rejected`, «gateway answered 403 to CONNECT», для pegi.info о 19:11:13Z. Архівні копії не відкривались: README проксі забороняє обходити 403.

## 1. App Review Guidelines (P; https://developer.apple.com/app-store/review/guidelines/, June 8, 2026, доступ 2026-10-07)

**1.4 Physical Harm**, вступ: «If your app behaves in a way that risks physical harm, we may reject it.»

**1.4.3**, точна цитата перших двох речень: «Apps that encourage consumption of tobacco and vape products, illegal drugs, or excessive amounts of alcohol are not permitted. Apps that encourage minors to consume any of these substances will be rejected.» Третє речення стосується продажу речовин і до гри не відноситься.

**5. Legal**: «And of course, apps that solicit, promote, or encourage criminal or clearly reckless behavior will be rejected.»

**1.1.3**: «Depictions that encourage illegal or reckless use of weapons and dangerous objects, or facilitate the purchase of firearms or ammunition.»

**1.1.2** (уже в [[2026-10-07-Rating-Rows-Verification]]): «Realistic portrayals of people or animals being killed, maimed, tortured, or abused, or content that encourages violence.»

**2.3.6**: «Answer the age rating questions in App Store Connect honestly so that your app aligns properly with parental controls.»

**Чи стосується 1.4.3 гри, де вживання — вибір із негативними наслідками.**
- У 1.4.3, 1.1.3 і в розділі 5 ключове слово — «encourage», а не «depict». Значення «encourage» в Guidelines не визначене. Про художній контекст, ігровий вигаданий світ чи наслідки вживання текст нічого не каже: `grep -n -i "fiction\|fantasy\|real-world"` знаходить лише 2.3.9 про «fictional account information».
- Та сама система Apple має окремий **рейтинговий** рядок для зображення вживання, з прикладом «the taking of illegal drugs» (див. § 2). У списку Unrated його **немає**: там тільки графічний сексуальний контент і «prolonged graphic or sadistic realistic violence». Отже, за текстом Apple зображення вживання отримує рейтинг, а не автоматично закриває стор.
- Де проходить межа між зображенням (рейтинг) і заохоченням (відмова за 1.4.3), і чи зараховує App Review негативні наслідки на користь гри: **UNGROUNDED**, першоджерело цього не визначає.
- Друге речення 1.4.3 стосується неповнолітніх. При рейтингу 13+ (див. § 2) аудиторія за визначенням включає 13–17 років. Якщо App Review визнає сцену заохоченням, це речення діє: «will be rejected». Чи визнає — **UNGROUNDED**.

## 2. Age ratings values and definitions (P; https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions, доступ 2026-10-07)

**Визначення категорій:**
- **Alcohol, Tobacco, or Drug Use or References:** «References to or depictions of the consumption of alcohol, tobacco products, or other licit or illicit substances. May include: drunken behavior, cigarette smoking, or the taking of illegal drugs.»
- **Guns or Other Weapons:** «References to or depictions of guns, weapons, or objects that may cause bodily harm. May include: guns, swords, or knives.»
- **Realistic Violence:** «Aggressive physical conflict or harm involving humans in lifelike situations.»
- **Cartoon or Fantasy Violence:** «Physical conflict or harm of an exaggerated or fantastical nature that can easily be distinguished from real life.»
- **Mature or Suggestive Themes**, перелік прикладів: «May include: sexual innuendo, sensual or suggestive imagery, censored or implied nudity, real-world crimes, psychological trauma or abuse, moral or ethical dilemmas, or war or political strife.»

**Пороги.** Глобальні таблиці; «рідко» = Infrequent, «часто» = Frequent:

| рядок | ОС ≥ 26: рідко → часто | ОС < 26 |
|---|---|---|
| Alcohol, tobacco, or drug use or references | **13+ → 18+** | «Infrequent or mild references to alcohol, tobacco, or drug use» **12+** · «Frequent or intense references…» **17+** |
| Guns or other weapons | **9+ → 13+** | окремого рядка в таблиці немає |
| Realistic violence | 13+ → 18+ | рідко/м'яко 12+ · часто/інтенсивно 17+ |
| Cartoon or fantasy violence | 9+ → 13+ | рідко/м'яко 9+ · часто/інтенсивно 12+ |
| Mature or suggestive themes | **9+ → 16+** | «Infrequent or mild mature, suggestive, or horror or fear themed» 9+ · «Frequent or intense mature or suggestive content» **17+** |
| Prolonged graphic or sadistic realistic violence | Unrated («can't be published on the App Store») | Unrated |

**Регіональні таблиці** на тій самій сторінці, ОС ≥ 26, рядок про наркотики рідко → часто:
- Бразилія: A14 → A16;
- Корея: 12+ → 19+;
- В'єтнам: 12+ → 18+. Там же «Infrequent realistic violence» дає 16+.

У бразильській таблиці «Infrequent guns or other weapons» стоїть і в A10, і в A16. Сторінка сама собі суперечить, тому поріг для ножа в Бразилії — **UNGROUNDED**.

Для ОС < 26 Франція показує глобальний 17+ як 18+ («apps with a 17+ Apple global age rating will display an additional regional rating of 18+ on the App Store in France»).

**Межа між «рідко» і «часто».** Визначення немає ні на сторінці рейтингів, ні на «Set an app age rating»: `grep -c -i "infrequent" set.txt` → `0`. Частоту задекларує розробник в анкеті («specify the frequency of each content type in your app»), чесність вимагає 2.3.6. Чи випадкова подія, що повторюється, — це «рідко»: **UNGROUNDED**.

**Подія (1), погроза ножем без смерті, порядково:**
- Ніж підпадає під Guns or Other Weapons: рідко 9+, часто 13+ (ОС ≥ 26). Гра вже має меч: `grep -n "блок, меч" docs/system/state.md` → рядок 38. Тож цей рядок, імовірно, вже зачеплений.
- Погроза без удару. Визначення Realistic і Cartoon Violence вимагають «physical conflict or harm». Погроза без контакту під жодне з них буквально не підпадає. Як її класифікує рецензент — **UNGROUNDED**.
- Якщо погроза переходить у бій, це той самий рядок насильства, що вже відкритий у [[2026-10-07-Blood-And-Lethal-Rating]]: cartoon/fantasy чи realistic.
- Пограбування — це «real-world crimes» у Mature or Suggestive Themes: рідко 9+, часто 16+ (ОС ≥ 26) і 9+ / 17+ (ОС < 26). Чи має Apple на увазі тип злочину чи справжні події, сторінка не уточнює: **UNGROUNDED**.
- Смерті в сцені немає, тому рядок Unrated («gore, human injury, or death») за визначенням не зачеплений.

**Подія (2), затяжка:** рядок «drug use or references», рідко 13+ / часто 18+ (ОС ≥ 26), 12+ / 17+ (ОС < 26). Рядок «Frequent alcohol, tobacco, or drug use or references» стоїть лише в 18+.

## 3. Пункт 2.3.8 і листки над головою на скриншотах (P)

«Metadata should be appropriate for all audiences, so make sure your app and in-app purchase icons, screenshots, and previews adhere to a 4+ age rating even if your app is rated higher. For example, if your app is a game that includes violence, select images that don't depict a gruesome death or a gun pointed at a specific character.» (https://developer.apple.com/app-store/review/guidelines/, June 8, 2026, доступ 2026-10-07.)

- Таблиця 4+ (ОС ≥ 26) не містить жодного рядка з Mature Themes чи Violence. Там лише in-app controls, capabilities і «Infrequent contests».
- Категорія наркотиків покриває не лише вживання, а й «References to or depictions». Її найнижчий поріг — 13+. Отже, кадр, у якому листки читаються як посилання на наркотик, за таблицею не є вмістом рівня 4+, навіть без самої затяжки.
- Ніж, наставлений на героя, — найближчий аналог прикладу «a gun pointed at a specific character». Але приклад називає лише вогнепальну зброю.
- Наскільки суворо Apple застосовує таблицю 4+ до одного кадру метаданих: **UNGROUNDED**. Буквальне прочитання відсіяло б і меч на скриншоті, а приклад 2.3.8 говорить про зброю, наставлену на персонажа, а не про її присутність. Чи вважає рецензент стилізоване коло з п'яти листків посиланням на наркотик, теж **UNGROUNDED**.

## 4. PEGI / ESRB / IARC / Google

| орган | статус | неперевірений сигнал (S, джерело теж 403) |
|---|---|---|
| PEGI | **UNGROUNDED**: pegi.info 403 → `000` | Дескриптор «Drugs» ставлять, коли гра «refers to or depicts the use of illegal drugs, alcohol or tobacco». Ігри з ним «always PEGI 16 or PEGI 18». PEGI 18 — за «glamorisation of the use of illegal drugs» і «detailed descriptions of criminal techniques» (сніпети wikipedia, gamesdenmark.dk, askaboutgames.com) |
| ESRB | **UNGROUNDED**: www.esrb.org 403 → `000` | «Drug Reference: Reference to and/or images of illegal drugs» · «Use of Drugs: The consumption or use of illegal drugs» (сніпет xbox.com, newegg PDF) |
| IARC | **UNGROUNDED**: globalratings.com 403 → `000` | — |
| Google Play | **UNGROUNDED**: support.google.com і play.google.com 403 → `000` | За сніпетом support.google.com/…/9878810, гру можуть зняти, якщо вона «portrays smoking as an attractive trait» (сніпет вторинний, gummicube.com) |

Якщо сигнал PEGI підтвердиться, подія (2) у регіонах PEGI дає щонайменше 16 незалежно від частоти. Першоджерелом це не перевірено.

## 5. Що з цього випливає (лише факти)
1. Apple (P) не забороняє зображувати вживання як таке. Рядок «drug use or references» має значення 13+ / 18+ (ОС ≥ 26) і 12+ / 17+ (ОС < 26) і не входить у список Unrated. Заборона 1.4.3 прив'язана до слова «encourage».
2. Межу між зображенням і заохоченням та вагу негативних наслідків Apple не визначає: **UNGROUNDED**.
3. Подія (2) підіймає нижню межу рейтингу до 13+ (ОС ≥ 26) / 12+ (ОС < 26) при рідкій частоті й до 18+ / 17+ при частій. Для ОС < 26 у Франції 17+ показується як 18+.
4. Подія (1) за текстом Apple не зачіпає рядка Unrated. Найвищий новий рядок — часті «real-world crimes»: 16+ (ОС ≥ 26) / 17+ (ОС < 26). Ніж — 9+ / 13+. Чи є погроза без контакту насильством — **UNGROUNDED**.
5. За таблицею 4+ і пунктом 2.3.8 кадри з листками, затяжкою чи ножем, наставленим на героя, не відповідають рівню 4+ для іконок, скриншотів і прев'ю. Наскільки суворо це застосовують — **UNGROUNDED**.
6. При рейтингу 13+ аудиторія включає неповнолітніх. Друге речення 1.4.3 («encourage minors … will be rejected») тоді діє, якщо сцену визнають заохоченням.
7. Android/iOS — цільові платформи (`sed -n 20p docs/system/constitution.md`), тож ці рядки стосуються проєкту. PEGI, ESRB, IARC і Google — **UNGROUNDED (403)**.

## 6. Чи прибирає ризик формулювання «вигадана рослина, без реальної назви»
**За текстом Apple — ні, не повністю.**
- **Віковий рейтинг.** Визначення охоплює «other licit or illicit substances» і «References to or depictions». Тобто воно не залежить від того, чи речовина справжня, чи має назву і чи заборонена законом. Для насильства Apple має окремий «fantasy»-підрядок (Cartoon or Fantasy Violence), для речовин такого підрядка немає. Перейменування не змінює ні дії (споживання), ні зображення.
- **1.4.3.** Пункт перелічує реальні категорії: «tobacco and vape products, illegal drugs, or excessive amounts of alcohol». Вигадана рослина буквально не є «illegal drugs». Але в задачі листки описано як «листки марихуани». Якщо зображення лишається впізнаваним, назва не змінює того, що бачить рецензент. Як App Review оцінює впізнаваний замінник: **UNGROUNDED**.
- **PEGI / ESRB (S, 403).** Сніпети говорять про «illegal drugs, alcohol or tobacco». Статус вигаданої речовини там **UNGROUNDED**.

Ознаки, до яких прив'язаний текст Apple: (а) споживання речовини, (б) посилання або зображення, (в) заохочення. Формулювання змінює лише назву і не прибирає жодної з них. Нижче — лінза для порівняння, а не рекомендація. Вибір за T1, Аполлоном і Аресом разом із Santos.

| варіант | рядок Apple (P), що буквально застосовується | 1.4.3 / 2.3.8 |
|---|---|---|
| A. Листки марихуани й затяжка, як у задумі | drug use: 13+ / 18+ (ОС ≥ 26) | 1.4.3 «illegal drugs» — питання лише «encourage», **UNGROUNDED**. Кадр із листками конфліктує з 4+ |
| B. Вигадана назва, той самий образ і затяжка | той самий рядок: визначення не залежить від назви | ризик за 1.4.3 той самий, бо образ упізнаваний (**UNGROUNDED**); 2.3.8 — як в A |
| C. Вигадана й невпізнавана рослина, але все одно споживання заради ефекту | той самий рядок («licit or illicit substances») | буквально не «illegal drugs». Оцінка рецензента — **UNGROUNDED** |
| D. Ефект без споживання речовини | визначення «consumption of … substances» буквально не виконується. Інші рядки — **UNGROUNDED** | 1.4.3 буквально не застосовується |

## Відкрите
- Відкрити з машини з доступом (наприклад, з Mac Santos): pegi.info/what-do-the-labels-mean, www.esrb.org/ratings-guide/, globalratings.com, support.google.com/googleplay/android-developer/answer/9878810.
- Визначення «Infrequent/Frequent» може бути лише в анкеті App Store Connect, яка потребує входу; не відкрито.
- Чи визнає App Review вибір вживання з негативними наслідками заохоченням: першоджерела немає.
- Чи пов'язаний вибір «затягнутись» із нагородою, досягненням чи прогресом: це вхідні дані дизайну, вони потрібні для оцінки «encourage»; поки не задані.
- Консольні стори (PS5, Xbox, Nintendo через IARC/ESRB/PEGI), USK і закони окремих країн про зображення наркотиків у іграх не досліджувались.

## Related
- [[2026-10-07-Blood-And-Lethal-Rating]] · [[2026-10-07-Rating-Rows-Verification]] · [[ADR-024-Lethal-Fights-And-First-Enemy]]
- [[2026-10-07-City-Encounter-Options]] · [[2026-10-05-District-Life]] · [[05-Platforms-Input]] · [[Export-Platforms]] · [[state]] · [[constitution]]
