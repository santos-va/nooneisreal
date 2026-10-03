# План — Choko, одяг v5: кросівки і чиста спина куртки

**Дата:** 2026-10-03 · **Роль:** T1 Дедал · **Статус:** draft (чекає слова Santos на кредити, крок 2+)
**Виріс із:** [[2026-10-03-Choko-Outfit-and-Review]] (зустріч) · `docs/Meetings/2026-10-03-Picks-and-Outfits.md` (одяг v4, T6; поки лише на гілці `claude/practical-hopper-rmfgi4`) ·
santos-va/nooneisreal#36 (Choko — мечник-акробат) · issue santos-va/nooneisreal#38.

## Що хоче Santos (2026-10-03, сесія T1)

1. Взуття Choko — **схоже на Nike «5000», сірі з помаранчевими вставками, без лого**.
2. На картці Choko куртка **без кольчуги на спині** — Аполлон кілька разів не зміг цього отримати.

## Діагноз: чому кольчуга лізе на спину

Промпти трьох робіт одягу v4 я витягнув через `show_generation_by_ids` (`80480e9f` і `d6841a7a`: лист, `a2bf79a1`: картка куртки).
Самих картинок **не бачив**: CDN із хмари → `curl` 403 (`connect_rejected`). Тому нижче — причини з промптів, а не з пікселів.

| # | причина | доказ |
|---|---|---|
| 1 | **Референс-картинка перебиває текст.** Усі три роботи несуть референс `f21298f4` — старий лист Choko, який промптився з **повною** кольчугою ([[Prompt-Library]] § 13 «Було (v3)» — на гілці T6, крок 0). Навіть картка куртки, де людини немає взагалі, отримала цей референс. Фраза «redraw the outfit exactly as described here» слабша за пікселі: модель бере матеріал із картинки. | `params.medias[0].data.id = f21298f4-…` у всіх трьох |
| 2 | **Слово «chainmail» звучить і прямо, і через заперечення.** У листі воно двічі («chainmail rings only on the shoulders», «no full chainmail coat»), у картці — тричі (разом із вставкою «chainmail shoulder panel»). Заперечення в позитивному промпті підказує моделі той самий предмет. | текст `params.prompt` |
| 3 | **Ніде не сказано, яка спина.** Поза 6 («back view») і вид 3 картки («back view») нічим не описані, тож модель заповнює спину найпомітнішим матеріалом, тобто кільцями з референсу. | текст `params.prompt` |
| 4 | **Взуття в IDENTITY немає взагалі** (ні у v3, ні у v4), тому кожна картка малює своє. | [[Prompt-Library]] § 1 (main) і § 13 (гілка T6) |

Це рецидивний клас: *референс несе старий одяг, текст просить новий*. Через нього кольчугу вже малювали на
`1fa22c1b`, `c280d939`, `822b889d`, `f0763795`, `cbaf6f58`, `4b792412` і на трьох роботах v4. Пропоную Феміді внести його в реєстр рецидивів.

## Модель «Nike 5000»: що знайдено

Пошук моделі з такою назвою не знайшов (`WebSearch "Nike 5000 sneaker grey orange"`). Найближчі ретро-ранери в
результатах — **P-6000** і **Zoom Vomero 5**: низький верх, сітка з шаруватими сріблясто-сірими накладками, масивна
ребриста підошва, каркас на п'яті. Бренд у промпті все одно **не називаємо** (правило Аполлона, [[Prompt-Library]] § 14 на гілці T6),
тому форма описується словами. Якщо Santos мав на увазі іншу модель — правиться один рядок кроку 1.

## Кроки

### 0. Гілка Аполлона в `main` (T6, 0 кредитів)

- **Що змінюємо:** `claude/practical-hopper-rmfgi4` (2 коміти: `6c4423c`, `738e447`) — злити `origin/main`, розв'язати
  конфлікт у `docs/system/state.md`, відкрити PR. Без цього IDENTITY v4 і вибір Santos живуть поза `main`.
- **Ризик:** якщо зробити крок 1 до злиття, отримаємо дві гілки з різними § 13, і хтось перезапише вибір Santos.
- **Перевірка:** `git merge-tree --write-tree origin/main origin/claude/practical-hopper-rmfgi4` → без `CONFLICT`;
  `bash tools/gates/run_gates.sh` → rc=0.

### 1. Канон і промпти v5 (Кліо + Аполлон, 0 кредитів)

- **Що змінюємо:**
  - Кліо: `docs/Characters/Choko.md` § Зовнішність. Зараз там «Кольчужна куртка», тобто v3. Треба v5: легка
    куртка, кільця лише на плечах і передпліччях, **гладка спина**, кросівки. Заодно глянути таблицю кіта: там P1 — F/G,
    а SOLO-дефолт — J/K (`game/scripts/core/InputRouter.gd:22`).
  - Аполлон: `docs/Art/Prompts/Prompt-Library.md` § 1 IDENTITY Choko → **v5**, новий § 15, `{NEG_CHOKO}`. Вимоги до тексту:
    1. **Спину описати прямо і першою:** `the whole back of the jacket is one smooth plain dusty-orange cloth panel
       with a single vertical cream stripe down the spine, no metal on the back`.
    2. Слово «chainmail» з IDENTITY прибрати. Вставки описати одним місцем: `small sewn-on patches of fine gunmetal
       ring mesh on the shoulder caps and the outer forearms only`.
    3. Заперечення перенести в окремий хвіст `{NEG_CHOKO}`: `no chain mail or metal rings on the back, chest or torso,
       no mail shirt, no armor vest`.
    4. Взуття (пропозиція Дедала, остаточне слово за Santos): `low-top 2000s retro running sneakers, breathable mesh
       base with layered silver-grey synthetic overlays, chunky segmented light-grey midsole with a visible heel cage,
       light grey with muted orange accent panels on the heel tab, around the lace eyelets and on the outsole, the same
       dusty orange as the jacket, no logos, no brand marks, plain side panels`.
- **Ризик:** якщо § 1 і Choko.md розійдуться, наступна картка знову змішає версії.
- **Перевірка:** `grep -A2 "IDENTITY — Choko" docs/Art/Prompts/Prompt-Library.md | grep -ci chainmail` → `0`;
  `grep -c "NEG_CHOKO" docs/Art/Prompts/Prompt-Library.md` → ≥ 2; `grep -ci "кольчужна куртка" docs/Characters/Choko.md` → `0`;
  `bash tools/gates/run_gates.sh` → rc=0.

### 2. Картки предметів **без референсу** — RED: потребує слова Santos (≈ 11 кр.)

- **Що змінюємо:** Аполлон генерує `choko-item-jacket-v5` ×2 і `choko-item-sneakers-v1` ×2 за § 4 (4 види, вид 3 — спина)
  **без жодної картинки-референсу**: картка предмета обличчя не потребує, а стиль задає `{STYLE}`. Ціна: 4 × 2.75
  (`get_cost` gpt_image_2_5 high 2k 16:9 = 2.75 — замір Аполлона, `2026-10-03-Picks-and-Outfits`; перед партією
  переміряти, спершу `balance`).
- **Ризик:** найдешевша точка, де видно, чи текст сам тримає чисту спину. Якщо не тримає — далі не йдемо, причина в тексті.
- **Перевірка:** Santos дивиться вид 3 (спина) обох курток: **рівна тканина, кілець немає**. Номери робіт і вердикт —
  у [[Menu-Skyline-Prompts]] § Журнал запусків. Без «так» Santos крок 3 не починається.

### 3. Поворот із двома референсами — RED: потребує слова Santos (≈ 5.5 кр.)

- **Що змінюємо:** `choko-turn-v5` ×2 за § 2. Перший референс — переможець кроку 2 (куртка), другий — `f21298f4`, але
  **лише для обличчя й манери** (як у Skea S-1, § 12): `take the jacket and shoes exactly from the first reference image;
  take only the face, hair and drawing style from the second reference image, not its clothing`.
- **Ризик:** поворот стає джерелом для T-поз і 3D. Кільця на спині тут означали б, що вони переїдуть у Meshy.
- **Перевірка:** Santos дивиться вид «back»: спина гладка, кросівки сірі з помаранчевим, лого немає.

### 4. T-пози ×4 з поворотом-референсом — RED: потребує слова Santos (≈ 11 кр.)

- **Що змінюємо:** `choko-tpose-<view>` ×4 за § 3, референс — переможець кроку 3. Замінює Choko-половину «кроку 2» Аполлона з
  `2026-10-03-Picks-and-Outfits` (той крок брав референсом лист v4 з кільцями).
- **Ризик:** Х2-8…11 (`c280d939` та інші) промптились з повною кольчугою. 3D з них не робити, як і для Skea.
- **Перевірка:** Santos — спина на `back`-позі гладка; [[Asset-Manifest]] § E оновлено.

### 5. Лист поз v5 — після пози від Ареса (#36) — RED (≈ 5.5 кр.)

- **Що змінюємо:** спершу Арес у santos-va/nooneisreal#36 дає 8 поз мечника-акробата для листа (сальто, перекат, удар у
  повітрі, фехтувальна стійка шуки) і рядок мувсету в `docs/GDD/03-Skills-Framework.md`. Потім Аполлон генерує `choko-sheet-v5` ×2
  з тими ж двома референсами, що в кроці 3.
- **Ризик:** якщо намалювати лист зі старими 8 позами зараз, після #36 його доведеться перегенеровувати.
- **Перевірка:** Арес: `bash tools/gates/run_gates.sh` → rc=0 на своїй гілці. Аполлон: Santos обирає лист, поза 6 зі спиною чиста.

**Разом RED:** ≈ 33 кр. (11 + 5.5 + 11 + 5.5), із них ≈ 13.75 і так стояли в «кроці 2» Аполлона. Стеля фаз 2–3 — 600
([[2026-10-03-Production-Plan]]). Від старту 6010 до `balance` 5806.75 (виміряно в цій сесії) витрачено 203.25 разом із меню.

## Хто що

| крок | роль | кредити | залежить від |
|---|---|---|---|
| 0 | T6 Аполлон | 0 | — |
| 1 | T7 Кліо (канон) → T6 (промпти) | 0 | 0 |
| 2–4 | T6 Аполлон, головна сесія | ≈ 27.5, слово Santos | 1, «так» Santos на кожен крок |
| 5 | T5 Арес → T6 | ≈ 5.5, слово Santos | #36, 3 |

## Related
- [[2026-10-03-Choko-Outfit-and-Review]] · `2026-10-03-Picks-and-Outfits` · [[Prompt-Library]] · [[Menu-Skyline-Prompts]] · [[Asset-Manifest]] · [[Choko]] · [[2026-10-03-Skea-Redesign]] · [[2026-10-03-Production-Plan]] · [[state]]
