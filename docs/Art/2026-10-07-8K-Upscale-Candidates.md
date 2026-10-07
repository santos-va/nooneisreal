# 8K-апскейл 2D: кандидати, ціна, критерії приймання

**Дата:** 2026-10-07 · **Роль:** T6 Аполлон · **Крок 3** плану [[2026-10-07-Auto-Display-And-Quality]] ·
**Статус:** бриф. Генерацій не запускав, кредити не витрачав. Генерацію запускає лише головна сесія.

## Головне

1. Більше пікселів, ніж є в джерелі, з показаних на екрані 2D-ассетів (меню, портрети, HUD) потребує лише **фон меню
   `menu-skyline-plate-v1`**: на 4K він збільшений 1,31×, на 8K — 2,62×. Портретам і HUD-іконкам вистачає пікселів
   навіть на 8K. Листи героїв зараз не показуються ніде.
2. До 8K у Higgsfield доводить лише **`topaz_image`** (довільні `output_width` / `output_height`). `upscale_image` і
   `bytedance_image_upscale` дають щонайбільше 4K, а плита вже має 3840 px завширшки.
3. Ціни `models_explore` не показує → **get_cost зробить T1**. `balance` 2026-10-07 → `{"credits":3913,"subscription_plan_type":"ultra"}`.

## Чим виміряно

| що | команда | вихід |
|---|---|---|
| Розміри всіх зображень | `python3 -I` + PIL: `os.walk('game/assets')`, `Image.open(p).size` для `.png/.jpg/.webp` | `TOTAL 85`; рядки нижче в таблиці |
| Що реально підключено в коді | `grep -rhoE 'res://assets/[A-Za-z0-9_/%.-]+\.(png\|jpg\|webp\|svg)' --include=*.gd --include=*.tscn --include=*.tres game` | 2D у UI: `menu_skyline_plate_v1`, `portrait_choko/skea`, 4 × `icon_*` (без `*_ult`), `card_choko_v3`, `card_skea_v1`, фони арен, `vfx/%s.png` |
| Базове полотно UI | `grep -n "viewport_\|stretch" game/project.godot` | `1600×900`, `canvas_items`, `aspect="expand"` → масштаб 1,2 / 2,4 / 4,8 на 1080p / 4K / 8K |
| Частка кадру | розрахунок із констант коду (`MainMenu.gd`, `Hud.gd`, `DuelCamera.gd`, `Flipbook.gd`), скрипт у scratchpad T6 | вихід — у колонках таблиці; бінаря Godot у контейнері немає (`which godot` → порожньо), тож **це розрахунок, не кадр** |
| Імпорт кандидатів | `grep -E "^compress/mode\|^mipmaps/generate" <файл>.import` | плита, портрети, іконки, фон річки: `compress/mode=0`, `mipmaps/generate=false`; `ko_burst`: `mipmaps/generate=true` |

Формула збільшення: пікселі на екрані ÷ пікселі джерела. Більше 1× — джерело розтягнуте, тут 8K-джерело дасть різкість.
Менше 1× — джерела вже досить.

## Кандидати

| # | id | шлях | розмір, px | де видно (код) | частка кадру | на екрані 4K / 8K | апскейл |
|---|---|---|---|---|---|---|---|
| 1 | `menu-skyline-plate-v1` | `game/assets/menu/menu_skyline_plate_v1.png` | 3840×1648 RGB | `MainMenu.gd:33-37`: фон `PRESET_FULL_RECT`, `STRETCH_KEEP_ASPECT_COVERED`; видимий шматок джерела 2930×1648 | 100 % кадру, але під затемненням α 0,76 (`MainMenu.gd:41`), а на 63,4 % площі — ще й під панелями α 0,91 (`MainMenu.gd:176`) | **1,31× / 2,62×** | **так**, ×2 → 7680×3296 (на 8K стане 1,31×) |
| 2 | `ui-portrait-choko` | `game/assets/ui/portraits/portrait_choko.png` | 1024×1024 RGBA | `MainMenu.gd:75-82, 262`: велика ілюстрація в колонці YOUR JOURNEY (`_card1`, ≈ 216 од.), мала 44 од. біля HERO | ≈ 24 % висоти, 3,2 % площі | 518 / 1037 px → 0,51× / **1,01×** | ні |
| 3 | `ui-portrait-skea` | `game/assets/ui/portraits/portrait_skea.png` | 1024×1024 RGBA | те саме, коли Skea обрана P1; мала — біля OPPONENT | те саме | те саме | ні |
| 4 | `ui-icon-choko-record` · `ui-icon-choko-timestop` · `ui-icon-skea-kunai` · `ui-icon-skea-veil` | `game/assets/ui/icons/icon_*.png` | 512×512 RGBA | `Hud.gd:28-31, 297-306`: `skill_icon_size` = 28 од. | 0,05 % площі кожна | 67 / 134 px → **0,13× / 0,26×** (на 1080p 34 px, у 15,2 раза менше за джерело) | ні; потрібні mipmaps — див. «Хендофи» |
| 5 | `ui-icon-choko-ult` · `ui-icon-skea-ult` | `game/assets/ui/icons/icon_*_ult.png` | 512×512 RGBA | не підключені: `grep -rn "icon_choko_ult\|icon_skea_ult" game` → порожньо | 0 | — | ні |
| 6 | `card-choko-v3` | `game/assets/characters/cards/card_choko_v3.png` | 2688×1520 RGB | не показується: `_card2` ніде не присвоюється (`MainMenu.gd:22, 263`), `portrait_path` код не читає | 0 | — | ні: старий аніме-лист на жовтій плашці, за [[Style-Guide]] це архів |
| 7 | `card-skea-v1` | `game/assets/characters/cards/card_skea_v1.jpg` | 1500×848 RGB | так само не показується | 0 | — | ні: одяг v1 застарів ([[Textures-Registry]]) |
| 8 | `vfx-ko-burst` · `vfx-choko-timestop` · `vfx-choko-rewind` · `vfx-speed-lines` | `game/assets/vfx/{ko_burst,choko_timestop,choko_rewind,speed_lines}.png` | 2048×2048 RGBA, атлас 4×4 (`Flipbook.gd:9`) → кадр 512 px | `FxDirector.gd:105, 144, 192, 196`: квади у світі 4 / 2,2 / 2,4 / 7 м, 16 кадрів по 12 FPS ≈ 1,3 с | `ko_burst` займає ≈ 43–49 % висоти (FOV 60°, 7–8 м) | 1,8–2,1× / **3,7–4,2×** | **умовно, не зараз**: див. «Варіанти» В6 |
| — | повноекранний TIME STOP | `TimeStopFx.gd:51-56` → `shaders/fx_chrono_screen.gdshader` | — | `ColorRect` на весь екран, шейдер читає тільки `hint_screen_texture` | 100 % | процедурний, від роздільності не залежить | не потрібно |
| 9 | Поза списком задачі, але займають багато кадру: `bg-kronshift-river` · `bg-market` · `bg-alley` · `bg-main` | `game/assets/backgrounds/bg_kronshift_{river.jpg,market_street,back_alley,main_street}.webp` | 1500×848 (river) · 2688×1520 | `Backdrop.gd:20-21`: «painted cards that already fill a 16:9 view»; ротація `GameState.gd:32` | до 100 % кадру за боєм | 1520 px: 1,42× / 2,84×; 848 px: 2,55× / 5,09× | ні: це PLACEHOLDER старого стилю (`GameState.gd:24-25`), ліцензія river не підтверджена; нові арени смуги C — одразу 4K |

Отже, апскейл потрібен **одному** ассету: плиті меню (№ 1). Ще чотири VFX-атласи (№ 8) — умовні кандидати на потім.

## Інструмент апскейлу в Higgsfield

`models_explore` 2026-10-07: `search "upscale image"` (type image) → `[]`; `search "upscale"` → `bytedance_image_upscale`,
`bytedance_video_upscale`, `video_upscale`; `recommend` → `related_tools`: `upscale_image` — «2K or 4K… call upscale_image
with image_id, width, height»; `list type=image` → `topaz_image`, `topaz_image_generative`.

| інструмент | що дає | до 8K? | ціна | чи тримає Sketch-Cel |
|---|---|---|---|---|
| **`topaz_image`** | неґенеративний апскейл; `output_width`, `output_height` (обов'язкові, `min 1`, верхньої межі схема не показує); `variant`: Standard V2 · Low Resolution V2 · **CGI** · **High Fidelity V2** · Text Refine; `sharpen` 0–1 (типово 0), `denoise` 0–1 (типово 0), `face_enhancement` (типово false) | схема не забороняє; чи пройде 7680 — **не перевірено** | не показана → **get_cost зробить T1** | у схемі заяв про стиль немає — **не перевірено**. Неґенеративний режим без sharpen і denoise має найменший шанс домалювати деталі, але це очікування, не факт |
| `topaz_image_generative` | Redefine / Recovery, `creativity` 1–6 («higher adds more detail»), `autoprompt` | — | — | **відкинуто**: сам заявляє, що додає деталь |
| `upscale_image` (окремий інструмент, не модель каталогу) | 2K або 4K | ні | історично 4k = **2 кр.** (`get_cost` T6 2026-10-03, [[Arenas-360-Prompts]] § Кошторис v2); на сьогодні не перевірено | — |
| `bytedance_image_upscale` | `resolution` 2k / 4k, `remove_bg` | ні | не показана | — |
| `seedream_v4_5` `quality: high` | генерація «up to ~6K» | майже | — | **відкинуто**: це перемальовування, а не апскейл |

## ТЗ виклику для головної сесії (лише після `balance` і `get_cost`)

- **Вхід:** переможець M2-A, job `73ee9806-ca24-4dcc-965f-848941e01fe7` (`grep -n 73ee9806 docs/Art/Prompts/Menu-Skyline-Prompts.md` → рядок 177, 3840×1648).
- **Виклик:** `topaz_image`, `output_width 7680`, `output_height 3296` (рівно ×2, без зміни пропорцій), `sharpen 0`,
  `denoise 0`, `face_enhancement false`.
- **Скільки:** **2 виклики** — `variant "CGI"` і `variant "High Fidelity V2"`. Обрати 1 за критеріями нижче, другий у репо
  не заходить. Мінімальний варіант — 1 виклик `CGI`.
- **Куди:** новий файл `game/assets/menu/menu_skyline_plate_v1_8k.png`. Старий не видаляти: видалення ассета — Red. T2 міняє
  один шлях у `MainMenu.gd:34` і вмикає mipmaps в імпорті (див. «Хендофи»). Відкат — той самий рядок.
- **Рядок реєстру** (T1 додає в [[Textures-Registry]] у тому ж заході, коли файл з'явиться на диску):
  `| menu-skyline-plate-v1-8k | game/assets/menu/menu_skyline_plate_v1_8k.png | Higgsfield CDN <url>, job <id>, 7680×3296 RGB, апскейл із job 73ee9806-…, <дата> (слово Santos «так» на план 2026-10-07) | Higgsfield topaz_image <variant>, sharpen 0, denoise 0 ([[2026-10-07-8K-Upscale-Candidates]]) | Higgsfield ToS — до релізу (ADR-013) | фон головного меню на 4K/8K |`

## Підсумкова ціна

| набір | викликів | ціна |
|---|---|---|
| Обов'язковий: плита меню, 2 варіанти | 2 × `topaz_image` 7680×3296 | **невідомо — get_cost зробить T1** |
| Мінімум | 1 × `topaz_image` | невідомо |
| Умовний, не зараз: 4 VFX-атласи → 4096×4096 | 4 × `topaz_image` | невідомо; і так не заплановано |

Залишок: 3913 кр. Історичні 2 кр. за `upscale_image` 4k до `topaz_image` не застосовні.

## Ризики стилю

1. **Розмита або «воскова» лінія.** Denoise з'їдає графітову зернистість і розриви штриха. Тому `denoise 0`.
2. **Ореоли.** Sharpen або ringing дають світлу обвідку навколо лінії `#2B2230`. Тому `sharpen 0`.
3. **Домальовані деталі.** На щільному місті ризик найбільший: нові вікна, цегла, черепиця, вивіски з текстом, фігури у вікнах.
4. **Зсув палітри.** Маджента-тіні сіріють, лінія чорніє, у небі з'являється бандинг або нові градієнти.
5. **«Пластик».** Глянець, бліки, гладкі градієнти замість пласкої заливки ([[ADR-007-Art-Style-Sketch-Cel]]).
6. **Геометрія.** Кроп, зсув, інші пропорції.
7. **Альфа** (для VFX та іконок у майбутньому). Чи зберігає `topaz_image` прозорість — не перевірено.

## Критерії приймання

Порівнюємо з чесною базою: оригінал, збільшений Lanczos 2×. Він сам проходить усі пороги. Пороги — PLACEHOLDER: їх
відкалібровано на синтетичних негативах, а не на справжньому виході Topaz.

| критерій | що міряємо | поріг | Lanczos 2× (база) | негатив |
|---|---|---|---|---|
| Розмір і режим | `size`, `mode` | рівно 7680×3296 (2,0×2,0), RGB, без кропу | 2,0×2,0 | — |
| **Лінія не розмита** | середня енергія країв (FIND_EDGES) на лініях ÷ та сама в Lanczos | 0,9–1,5 | 1,00 | розмиття σ 2 → **0,23**; nearest (сходинки) → 1,78 |
| **Немає нової деталі** | після зменшення назад до 3840×1648: макс. зсув середнього кольору в блоці 16×16; p99,9 \|Δ\|; шум у пласких зонах ÷ Lanczos | блок ≤ 8; p99,9 ≤ 20; пласкі зони ≤ 1,5 | 1,6; 11,0; 1,00 | 72 домальовані «вікна» → блок **50,7**, p99,9 **42**; nearest → пласкі **3,28** |
| **Палітра та сама** | середнє \|Δ\| по каналах після зменшення; PSNR | ≤ 2,0 на канал; PSNR ≥ 38 дБ | 0,89 / 0,76 / 0,63; 44,1 дБ | R ×1,06, B ×0,95 → **5,09 / 0,76 / 4,36**, 34,8 дБ |
| Очима, 100 % | три кропи: вежі з годинниками, дахи з димарями, передній бак і парапет; A/B з Lanczos | нових вікон, тексту, фігур немає; лінія графітова, не чорна; тінь маджента; заливка пласка | — | — |
| У грі | нативні кадри меню 4K і 8K (крок 4 T2, приймання — крок 6) | на 4K/8K різкіше за 4K-джерело; на 1080p немає аліасингу (потрібні mipmaps) | — | — |

Перевірка (самоперевірена в scratchpad T6: Lanczos — прохід, три негативи — провал за порогами вище). Запуск:
`python3 -I upcheck.py game/assets/menu/menu_skyline_plate_v1.png <апскейл>.png`

```python
import sys, numpy as np
from PIL import Image, ImageFilter
o = Image.open(sys.argv[1]).convert("RGB"); u = Image.open(sys.argv[2]); print("mode", u.mode, "size", u.size)
u = u.convert("RGB"); k = (u.size[0] / o.size[0], u.size[1] / o.size[1]); print("scale", k)
O = np.asarray(o, np.float32); D = np.asarray(u.resize(o.size, Image.LANCZOS), np.float32); d = np.abs(D - O)
print("mean|d| per ch", d.mean((0, 1)).round(2), "p99.9", round(float(np.percentile(d, 99.9)), 1),
      "PSNR", round(float(10 * np.log10(255**2 / ((D - O)**2).mean())), 2))
B = lambda A: A[:A.shape[0]//16*16, :A.shape[1]//16*16].reshape(A.shape[0]//16, 16, A.shape[1]//16, 16, 3).mean((1, 3))
print("block16 colour shift max", round(float(np.abs(B(D) - B(O)).max()), 1))
L = Image.open(sys.argv[1]).convert("RGB").resize(u.size, Image.LANCZOS)
hf = lambda im: np.asarray(im.convert("L").filter(ImageFilter.FIND_EDGES), np.float32)
flat = np.asarray(o.convert("L").filter(ImageFilter.FIND_EDGES).resize(u.size, Image.NEAREST), np.float32) < 4
print("flat-area HF ratio (upscale/lanczos)", round(float(hf(u)[flat].mean() / max(hf(L)[flat].mean(), 1e-6)), 2),
      "edge HF ratio", round(float(hf(u)[~flat].mean() / max(hf(L)[~flat].mean(), 1e-6)), 2))
```

## Аудит і погляди

| варіант | що дає | що коштує | вердикт |
|---|---|---|---|
| В1. `topaz_image` ×2 лише для плити меню, 2 варіанти, відбір за критеріями | 8K-джерело для єдиного 2D, яке на 4K/8K справді розтягнуте | 2 виклики (ціна невідома); +~22 МБ PNG у репо (Lanczos 2× PNG = 21,6 МБ, `ls -l`); 96,6 МіБ VRAM без стиснення проти 24,1 зараз | **Рекомендовано**, якщо `get_cost` прийнятний |
| В2. Апскейл усього списку плану: меню, листи, HUD, портрети | Нібито «все 8K» | Листи не показуються і в старому стилі; іконкам і портретам пікселів уже досить | Відкинуто |
| В3. Нуль кредитів зараз: чекати живу меню-діораму (#4, #7, #8) і арени смуги C та генерувати нове одразу в 4K | Не платимо за ассет, який замінять | Плита на 8K лишається 2,62× | Запасний: якщо `get_cost` дорогий або Santos скаже «не зараз» |
| В4. `upscale_image` / `bytedance_image_upscale` 4k | Дешево (історично 2 кр.) | Стеля — 4K, а плита вже 3840 px завширшки: виграшу нуль | Відкинуто |
| В5. Ґенеративний апскейл (`topaz_image_generative`, Seedream 4.5 ~6K) | Найбільше «деталей» | Домальовує те, чого не було, — порушує критерій «немає нової деталі» | Відкинуто |
| В6. VFX-атласи ×2 (кадр 512 → 1024) | На 8K вибух KO стане різкішим (зараз 3,7–4,2×) | 4 виклики; альфа в Topaz не перевірена; атлас 4096² = 64 МіБ RGBA8 | Умовно: після кадрів 4K/8K кроку 6, якщо T6 побачить м'якість |

| погляд | що виграє / що втрачає | що це змінило |
|---|---|---|
| Santos («текстури… 8К») | Отримує чесний перелік: що варто збільшувати і чому решта вже готова до 8K | Один кандидат замість п'яти категорій |
| Гравець із 8K-телевізором | Фон меню 2,62× → 1,31×; але фон затемнений на 76 % і на 63 % площі закритий панелями, тож виграш помірний | Пріоритет низький, бюджет — 2 виклики, не більше |
| Santos на MacBook M3 (якщо це 14″ з 3024×1964 — модель не перевірена) | Плита зараз 1,19× (`max(3024/3840, 1964/1648)`), після ×2 — 0,6×: без mipmaps це аліасинг | Mipmaps для плити — обов'язкова умова хендофу T2 |
| Художник Sketch-Cel | Ризик воскової лінії, ореолів і домальованих вікон на щільному місті | `sharpen 0`, `denoise 0`, неґенеративний режим, пороги + 3 кропи |
| GPU / пам'ять | 7680×3296 RGBA8 = 96,6 МіБ без стиснення (зараз `compress/mode=0`) | Формат стиснення для 2D — питання кроку 1(в) T3 і кроку 4 T2 |
| Тестер / CI | Новий файл потребує рядка реєстру, інакше `texture_registry_check.py` дасть rc≠0; старий файл лишається | Окремий id `-8k`, рядок-чернетка вище |

Мірила ([[ADR-019-Audit-And-Many-Views-Before-Decision]]): кредити — лише там, де різницю видно; лінія, палітра й
пласка заливка Sketch-Cel не змінюються; пам'ять GPU; нічого не видаляємо.

## Хендофи

- **T1:** `balance` → `get_cost` на обидва варіанти `topaz_image` 7680×3296 (заразом стане видно, чи пропускає він 7680) →
  генерація → `upcheck.py` → відбір 1 → файл і рядок у [[Textures-Registry]] → `balance` після.
- **T2 (крок 4), 0 кредитів:** (а) новий шлях плити в `MainMenu.gd:34` і `mipmaps/generate=true` в її `.import`, фільтр
  `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` на `TextureRect` фону; (б) **знахідка поза апскейлом:** іконки HUD 512 px показуються
  на 34 px (1080p) і портрети 1024 px — на 53 px. Це стиснення в 15–19 разів без mipmaps (`mipmaps/generate=false`, у
  `Hud.gd` і `MainMenu.gd` немає `texture_filter`), отже, ризик аліасингу лінії. Вмикати mipmaps для `game/assets/ui/**`.
  На кадрі не виміряно.
- **T3 (крок 1в):** формат стиснення для великого 2D (Lossless чи VRAM) і чи потрібна межа розміру текстури в профілі.
- **T6 (крок 6):** приймання апскейлу на кадрах меню 4K/8K і рішення щодо В6 (VFX).

## Що відкрите

- Ціна `topaz_image` за одиницю — get_cost зробить T1. Чи приймає він вихід 7680×3296 — не перевірено.
- Як `topaz_image` поводиться з Sketch-Cel (лінія, палітра) — не перевірено, перевіряє критерій після генерації.
- Частки кадру — розрахунок із констант коду. Висота ілюстрації в колонці меню (≈ 216 од.) — оцінка з висоти шрифтів
  ±30 од., не кадр. Бінаря Godot у контейнері немає.
- Чи зберігає `topaz_image` альфу — не перевірено (важливо для В6).

## Результат запуску (T1, головна сесія, 2026-10-07)

- `balance` перед запуском → 3832. `get_cost` для `topaz_image` сервер не підтримує: `422 … job_type 'topaz_image' does not support alpha v2 cost estimation`. Тому ціну виміряно першим викликом: `transactions` → «Topaz Image −3», 18:35:00 UTC.
- Вхід: `media_import_url` з CDN-оригіналу `hf_20261003_005204_73ee9806-ca24-4dcc-965f-848941e01fe7.png`, sha256 `0be4f96c…` = файл у репо. Прямий upload на `upload.higgsfield.ai` проксі відхилив (403).
- Виклики: `topaz_image`, 7680×3296, `sharpen 0`, `denoise 0`, `face_enhancement false`. Поле `prompt` обов'язкове: «Upscale 2x without adding detail; keep line art, grain and palette exactly as in the source.»

| варіант | job | палітра mean\|Δ\| | p99,9 | PSNR | блок 16 | пласкі HF | лінія HF | вердикт |
|---|---|---|---|---|---|---|---|---|
| CGI | `d3578285-cd28-4591-ac27-3e808f447357` | 2,6 / 2,0 / 2,2 | 27 | 36,39 | 9,0 | **6,69** | 1,38 | ✗ |
| High Fidelity V2 | `105c4acc-7b33-4de3-87ad-7362d667b3bc` | 2,75 / 2,08 / 2,21 | 30 | 35,66 | 4,6 | **9,51** | 1,41 | ✗ |

Пороги взято з таблиці вище (`upcheck.py`, задані до генерації). Обидва варіанти падають на палітрі, PSNR, p99,9 і найсильніше на «пласкі HF»: Topaz додає текстуру там, де її не було. Огляд очима на кропах 480×320 (Lanczos | CGI | HF V2; неба і щільної вулиці):
- CGI робить лінію чорнішою й товстішою, а це суперечить «лінія графітова, не чорна»;
- HF V2 ближчий до джерела, але домальовує дрібні значки, схожі на текст.

**Рішення T1:** обидва відкинуто, у репо нічого не додано, рядка реєстру немає. Фон меню лишається 3840×1648 з mipmaps (крок 4 T2). Витрачено 6 кредитів, баланс після — 3826. Наступна спроба, якщо колись буде: `topaz_image` з іншим варіантом (`Standard V2`) або чесний Lanczos 2× без кредитів — це вирішує T6.

## Related
- [[2026-10-07-Auto-Display-And-Quality]] · [[Textures-Registry]] · [[Style-Guide]] · [[Higgsfield-Pipeline]] · [[Menu-Skyline-Prompts]] · [[Arenas-360-Prompts]] · [[VFX-Direction]] · [[ADR-007-Art-Style-Sketch-Cel]] · [[ADR-013-License-Check-At-Release]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]] · [[06-UI-UX]] · [[state]]
