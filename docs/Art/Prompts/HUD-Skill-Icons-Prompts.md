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

## Іконки ульт і портрети вибору бійця (Santos 2026-10-03: «давай все інше, що вже готове й точно буде»)

Звідки «точно буде»: [[06-UI-UX]] § Вибір персонажа — картка P1 має **3 панелі: скіл 1 · скіл 2 · ульта** (іконки S1/S2 вже є,
ульт бракує) і **сітку портретів** 112×112 од.; [[2026-10-03-Production-Plan]] фаза 2.8 «Іконки скілів, портрети HUD».

**Іконки ульт** — ті самі ICON_STYLE / NEG_ICON, `gpt_image_2_5` high 1k transparent, 2 × 2 варіанти:

| id | скіл | опис (слот) |
|---|---|---|
| `ui-icon-choko-ult` | SWORD STORM (кристальна ульта, меч № 1) | `Subject: a single straight sword pointing upward with five small pointed crystal shards fanned like wings around its crossguard.` |
| `ui-icon-skea-ult` | CURSED GRIMOIRE ∞8 | `Subject: a thick closed old grimoire book standing upright, iron corner caps, a plain infinity-eight shape on its cover, no face, no eyes.` |

**Портрети** — `gpt_image_2_5` high 2k 1:1 transparent, 2 × 2 варіанти. Погруддя в 3/4 обличчям **праворуч** (P2 дзеркалить код).
Блоки `{STYLE}`, `{NEG}`, `{NEG_CHOKO}`, `{NEG_SKEA}`, IDENTITY — з [[Prompt-Library]] байт-у-байт (Choko — IDENTITY v5.2 § 1,
Skea — IDENTITY v3 § 14a).

```
{STYLE} Head-and-shoulders character portrait for a fighting game character-select card: three-quarter view facing to the right, from the top of the hair down to mid-chest, centered with a small empty margin, {MOOD}, fully transparent background, no frame, no border. {REFS} Identity: {IDENTITY}. {NEG} {NEG_CH}
```

| id | референси | `{MOOD}` · `{REFS}` |
|---|---|---|
| `ui-portrait-choko` | лист Choko `f21298f4` (обличчя, манера) + картка куртки v5 N-2 `a2bf79a1` | `calm, focused, slightly cocky half-smile` · `Match the face, drawing style, line and shading of the first reference image exactly; take the jacket and collar from the second reference image.` |
| `ui-portrait-skea` | лист Skea v3 S-1 `dcdef91d` (обличчя, пропорції, манера) + обличчя S-5 `36ace5cf` | `his base smile, the eyes cold and not smiling, head slightly tilted` · `Match the face, drawing style, line and shading of the first reference image exactly; the face must match the second reference image.` |

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
| іконки ульт 2 × 2 (1k, 1.5) + портрети 2 × 2 (2k, 2 референси, 2.75) | ульта Choko `af93bfb4` / `bb91ec57` (b) · ульта Skea `722cfeec` / `ad336ee9` (b) · портрет Choko `b7032ada` (a) / `718e6d21` · портрет Skea `6992a087` (a) / `ae54ef62` | у гру — ульти b, портрети a. Звірено з каноном: кольчуга на плечах Choko є на картці куртки `a2bf79a1`; «окуляроподібні» очі Skea — як на листі облич `36ace5cf`. Портрет Skea b відкинуто: ∞8 видно на боці рюкзака (канон — лише задня панель) | 5236 → **5219** (−17, як у кошторисі) |

## Related
- [[06-UI-UX]] · [[03-Skills-Framework]] · [[Style-Guide]] · [[Textures-Registry]] · [[VFX-Sheets-Prompts]] · [[2026-10-03-Production-Plan]] · [[Choko]] · [[Skea]]
