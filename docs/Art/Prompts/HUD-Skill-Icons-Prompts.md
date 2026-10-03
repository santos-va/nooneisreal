# Іконки скілів HUD — промпти й ціна (4 іконки)

**Роль:** T6 Аполлон, 2026-10-03 · **Запит Santos:** «T6 готує промпти і рахує ціну на 4 іконки. Генерація — тільки після
твого слова» · **ТЗ:** [[06-UI-UX]] § Варіант 2, «Чому це відкриває скіли в HUD» (T8 Гермес) · **Стиль:** [[Style-Guide]].
**Статус:** згенеровано (Santos «Давай генерувати», 12 кр.); 4 іконки в `game/assets/ui/icons/`, рядки в [[Textures-Registry]]. Підключення в `Hud.gd` — Гефест за ТЗ Гермеса.

## Які 4 іконки і навіщо

Зараз кулдауни скілів у HUD — текст `S1 ✓  S2 ✓` (`game/scripts/ui/Hud.gd:208`, оновлення — `:430`). За [[06-UI-UX]] він
стає двома **контурними іконками**, які **заливаються знизу вгору**, поки скіл перезаряджається, — та сама мова, що в зарядів
гарпуна й деша. Скіли — [[03-Skills-Framework]] § таблиця китів:

| id | боєць · слот | скіл | що на іконці |
|---|---|---|---|
| `ui-icon-choko-record` | Choko · S1 | RECORD (маркер → перемотка) | циферблат із двома стрілками і крапкою запису вгорі — той самий образ, що стікер RECORD у грі |
| `ui-icon-choko-timestop` | Choko · S2 | TIME STOP (заморозка 1.2 с) | пісочний годинник із тріщиною навскіс — час зупинено |
| `ui-icon-skea-kunai` | Skea · S1 | KUNAI RAIN (AoE + Armor Break) | три кунаї вістрям донизу, віялом |
| `ui-icon-skea-veil` | Skea · S2 | SHADOW VEIL (невидимість + крит) | клубчаста хмара диму з гострим серпоподібним вирізом посередині |

## Вимоги до файлу — щоб іконка працювала як маска заливки

- **Одна пласка заливка кремом `#FAEDD9`** + товстий чорнильний контур `#2B2230` — ті самі два кольори, що подвійний контур
  HUD ([[06-UI-UX]] § Специфікація, п. 2). Колір бійця дає код (`modulate` / шейдер), а не PNG — тому іконка одноколірна.
- Прозоре тло, без кола-підкладки, без рамки: рамку й «лунку» малює `Hud.gd`, як для зарядів.
- Читається на **48 px** (розмір на екрані — рішення Гермеса; джерело 1024 px з запасом). Деталей усередині — максимум 2–3 лінії.
- Заливку «знизу вгору» робить код: шейдер обрізає альфу іконки за висотою. Тому силует має бути суцільним, без дрібних
  відірваних шматків, інакше на 30 % заряду видно порожнечу замість частини іконки.

## Блоки (англійською, байт-у-байт)

**ICON_STYLE:**

```
A single bold game HUD skill icon, a flat pictogram that stays readable at 48 pixels, hand-drawn in a loose expressive western animation sketch style, NOT anime: one solid flat cream fill (#FAEDD9) silhouette with a thick plum-graphite (#2B2230) outer outline with small line breaks, and at most two or three thin inner lines in the same plum-graphite. One compact solid shape, no small detached pieces. No shading, no second color, no gradient, no glow, no highlights. Centered with an empty margin on all sides, fully transparent background.
```

**NEG_ICON:**

```
No circle or square background, no frame, no border, no badge, no text, no letters, no numbers, no characters, no hands, no faces, no logos, no watermark, no 3D render look.
```

Промпт = `{ICON_STYLE} ` + рядок «опис» + ` {NEG_ICON}`.

| id | опис (слот, англійською) |
|---|---|
| `ui-icon-choko-record` | `Subject: a round watch face with two clock hands pointing to ten past ten and a small solid round dot at the top of the rim, like a recording light.` |
| `ui-icon-choko-timestop` | `Subject: an hourglass standing upright with sand frozen mid-fall and one sharp crack running diagonally across the glass.` |
| `ui-icon-skea-kunai` | `Subject: three kunai knives falling point down in a tight fan, each with a ring pommel, the middle one slightly lower.` |
| `ui-icon-skea-veil` | `Subject: a compact billowing cloud of smoke clumps with one sharp crescent-shaped cut-out in the middle, like a veil hiding something.` |

## Модель і ціна (`get_cost` 2026-10-03, кредитів не списує; `balance` → 5281)

| варіант | `get_cost` за 1 зображення | 4 іконки × 2 варіанти | за і проти |
|---|---|---|---|
| **`gpt_image_2_5` high 1k transparent** — **рекомендація T6** | **1.5** | **12** | той самий стиль, що 34 VFX-файли й стікери; прозоре тло з коробки; 1024 px досить для 48 px |
| `gpt_image_2_5` high 2k transparent | 2.75 | 22 | запас під 4K-екрани; для іконки 48 px зайве |
| `recraft_v4_1` `vector` / `utility_vector` 1k | 2.5 | 20 | скіл радить Recraft для UI-іконок; але параметра прозорого тла немає (лише `background_color`), лінія «векторна» — ризик, що вийде чистий флет-іконпак, а не Sketch-Cel. Чи віддає SVG — **не перевірено** |
| `recraft_v4_1` 2k (`vector` / `utility_vector`) | 10 | 80 | не має сенсу для іконок |

**Пропозиція:** 4 × 2 варіанти на `gpt_image_2_5` high 1k transparent = **12 кр.** Після відбору — 1 на слот, решта в репо
не йде; файли в `game/assets/ui/icons/`, рядки в [[Textures-Registry]]. Підключення в `Hud.gd` — Гефест за ТЗ Гермеса.

## Журнал запусків

| пакет | job-id | результат | `balance` до → після |
|---|---|---|---|
| 4 × 2 (`generate_image_batch`, `gpt_image_2_5` high 1k transparent) | RECORD `40370239` (a) / `e3ac701b` · TIME STOP `ca9face2` (a) / `fa7d17cd` · KUNAI `a09e17c5` (a) / `cb73794e` · VEIL `b807998c` / `0927bd84` (b) | у гру — RECORD a, TIME STOP a, KUNAI a, VEIL b (серпоподібний виріз — справжній отвір, на 48 px читається найкраще). Усі 8 читаються на 48 px (огляд зменшених копій). Обрізано по силуету + поле 8 % → 512×512, щоб заливка знизу вгору мала однакову висоту. Зауваження: крапка «запису» на RECORD в одному кольорі читається як коронка кишенькового годинника — образ «годинник» лишається | 5281 → **5269** (−12, як у кошторисі) |

## Related
- [[06-UI-UX]] · [[03-Skills-Framework]] · [[Style-Guide]] · [[Textures-Registry]] · [[VFX-Sheets-Prompts]] · [[2026-10-03-Production-Plan]] · [[Choko]] · [[Skea]]
