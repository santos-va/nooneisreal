# Ресерч — дірки анімацій: UAL1 Pro · UAL2 Source · Meshy (2026-10-03)

**Роль:** T3 Архімед. Дата доступу до всіх джерел — **2026-10-03**.
**Задача:** Santos — «дірки анімацій — порівняй UAL Pro, Source і Meshy». Продовження [[2026-10-03-Animation-Sources]] §8 п. 3 і відкритих пунктів 4 і 6 звідти.
**Статус:** порівняння без рекомендації. Гроші й кредити обирає Santos; який кліп грає який удар — Арес (#36).

## Питання

1. Які дірки лишаються після безкоштовних UAL1 + UAL2 Standard?
2. Що з них закриває UAL1 Pro ($9.99), UAL2 Source ($14.99), Meshy через Higgsfield?
3. Скільки це коштує і що отримуємо: формат, ліцензія, скелет?

## Джерела і що перевірено саме в цій сесії

- **Каталог Higgsfield `animation_actions`** (Meshy, лише читання, кредити не списуються). Запити `backflip` → 8 збігів, `flip` → 13, `kick` → 19, `knee` → 3, `uppercut` → 2, `crouch` → 29, `jump attack` → 0, категорія `GettingHit` → 11. Опис інструмента: «678 actions».
- **Модель `3d_rigging`** — `models_explore(action:get)`. `animation_action_id` — «integer, 0–696», **одне число на виклик**. Параметра для кількох кліпів немає.
- **Ціна** — `generate_3d` з `get_cost:true`, нічого не списано. `3d_rigging` + `enable_animation` на публічній `Fox.glb` (Khronos glTF-Sample-Assets): кліп 452 → **8**, кліп 207 → **8** кредитів. Це збігається з [[Higgsfield-Pipeline]]:43.
- **Quaternius — сайти недоступні з цієї сесії.** `curl` на `quaternius.itch.io` і `quaternius.com` повертає `CONNECT tunnel failed, response 403`. WebFetch на itch, `store.godotengine.org`, `digitalproduction.com` і `web.archive.org` теж заблоковано. Звідси:
  - імена кліпів Pro/Source — **з брифу C0** ([[2026-10-03-Animation-Sources]] §3; там вони прочитані з `index.pck` переглядача `quaternius.com/animviewer.html`). У цій сесії **не перечитано**;
  - ціни й ліцензія — **лише з витягів WebSearch**: «Pro version is available at $9.99 USD, … Source version … $14.99 USD. The Standard version is free»; «free to use in personal, educational and commercial projects under a CC0 License». Для UAL2: «The Source version is available if you pay $14.99 USD or more. Two versions of the library are offered» — це підтверджує C0: у UAL2 тиру Pro немає. Сторінки: https://quaternius.itch.io/universal-animation-library · https://quaternius.itch.io/universal-animation-library-2 · https://jettelly.com/blog/universal-animation-library-2-a-cross-engine-animation-pack-with-a-universal-humanoid-rig.

## 1. Дірки, які треба закрити

За [[2026-10-03-Animation-Sources]] §8 п. 3: **сальто**, Skea `roundhouse` і `low_kick`, `flying_knee`, `air_light`, `crouch_light`, Choko `sword_up`, **реакція ніг** (HITSTUN `low`).

## 2. Таблиця «дірка × джерело»

**UAL** — назви з переглядача (C0). **Meshy** — `id Назва` з каталогу Higgsfield цієї сесії; `_inplace` означає «без руху кореня», а саме такі кліпи нам потрібні (рух тіла задає код, C0 §5).

| дірка | UAL1 Pro $9.99 | UAL2 Source $14.99 | Meshy, 8 кр. за кліп |
|---|---|---|---|
| **сальто** | `BackFlip` | `JogToFlip` (`KipUp` — це підйом із землі, не сальто) | 452 Backflip · **601 Backflip_inplace** · 462 Backflip_Jump · 413 Backflip_and_Rise · 453 / **604** Backflip_Sweep_Kick(_inplace) · 375 Handstand_Flip |
| `roundhouse` | `Kick` (один кліп, тип удару за назвою невідомий) | — | 207 Roundhouse_Kick · 208 / **649** Lunge_Roundhouse_Kick(_inplace) · 216 Lunge_Spin_Kick · 215 High_Kick |
| `low_kick` | той самий `Kick` | — | 217 Sweeping_Kick · 455 Sweep_Kick · 103 Simple_Kick |
| `flying_knee` | — | `Melee_Knee` (з землі, не в стрибку) | 211 Boxing_Guard_Step_Knee_Strike (з землі); **у стрибку — немає** |
| `air_light` | — | `Sword_Aerial_A/B/Combo` (з мечем) | 94 Flying_Fist_Kick · 422 Rising_Flying_Kick (без меча); «jump attack» → 0 |
| `crouch_light` | — | — | **немає**: з 29 збігів на `crouch` атак нема, лише кидки 239 і 398 |
| `sword_up` | — | `Sword_UpperCut_RM` (у переглядачі лише варіант `_RM`) | 194 / 196 Uppercut — **кулаком, не мечем** |
| реакція ніг | — | — | **немає**: у `GettingHit` 11 кліпів, жоден не про ноги |

**Підсумок таблиці.**
- **Жодне джерело не закриває всі дірки.** `crouch_light` і реакції ніг немає ніде. `flying_knee` у стрибку теж немає ніде.
- **UAL1 Pro** закриває сальто і дає **один** `Kick` на два удари Skea.
- **UAL2 Source** закриває удари з мечем: `air_light`, `sword_up`, а також коліно з землі і сальто з бігу. Ударів ногою не має.
- **Meshy** закриває сальто й обидва удари ногою окремими кліпами, удари з мечем — ні.

## 3. Ціна, формат, ліцензія, скелет

| | UAL1 Pro | UAL2 Source | Meshy через Higgsfield |
|---|---|---|---|
| ціна | **$9.99** одноразово (витяг пошуку) | **$14.99** одноразово (витяг пошуку) | **8 кр. за кліп** (`get_cost` у цій сесії) — один виклик `3d_rigging` = один кліп |
| що вистачить на наші дірки | один пак | один пак | сальто + roundhouse + low_kick = 3 × 8 = **24 кр.** (див. нижче, чому не на кожного героя) |
| формат | FBX/GLB, «exported and optimized for game engines» (витяг пошуку) | **.blend** з ригом і кліпами. Чи є в zip готові GLB — **UNGROUNDED**: витяг UAL2 каже «full library along with the original .blend», витяг UAL1 — лише «.blend file». Якщо GLB немає, кліпи доведеться експортувати в Blender | GLB з ригом Meshy і одним кліпом на модель, яку передали в `model_url` |
| скелет | той самий 65-кістковий, що в Standard (сторінка: «same rig»; файли не відкривались) | той самий | 24 кістки без пальців (звірено на M-0/M-1 у C0 §6.1). Чи дає **кожен новий** виклик `3d_rigging` ту саму ієрархію — **не перевірено** |
| ретаргет у Godot 4.7 | як Standard: усі обов'язкові кістки `SkeletonProfileHumanoid` мапляться (C0 §4, за сирцями) | так само | так само (C0 §6.1, за сирцями) |
| ліцензія | CC0 — витяг пошуку зі сторінки, `License.txt` платного zip **не читано** | так само | умови Higgsfield/Meshy на згенероване — **не читано**; глибоко — на воротах релізу ([[ADR-013-License-Check-At-Release]]) |
| дія | купівля — гроші Santos | купівля — гроші Santos | **RED**: кредити, `balance` перед запуском, слово Santos |

**Чому 24 кр., а не 48.** Кліп Meshy приходить на скелет моделі з `model_url`. Через `SkeletonProfileHumanoid` його можна ретаргетити і на іншого героя, і на манекен UAL (C0 §4, §6.1 — за сирцями, не в редакторі). Отже, **один** набір кліпів на одній моделі обслуговує обох героїв. Поки ретаргет не підтверджено в редакторі, чесна стеля — 48 кр. (3 кліпи × 2 героя).

**Ціна виміряна на `Fox.glb`, а не на M-0/M-1.** [[Higgsfield-Pipeline]]:42 уже позначав це як неперевірене. Оцінка не залежала від id кліпу (452 і 207 дали однаково 8). Від моделі — не перевірено.

## 4. Комбінації (числа, без вибору)

| набір | закрито | не закрито | вартість |
|---|---|---|---|
| UAL1 Pro | сальто, один `Kick` | окремий `low_kick`, удари з мечем, коліно, `crouch_light`, ноги | $9.99 |
| UAL2 Source | `air_light`, `sword_up`, коліно (з землі), сальто з бігу | удари ногою, `crouch_light`, ноги; можливо, експорт із Blender | $14.99 |
| UAL1 Pro + UAL2 Source | усе зі стовпців UAL | окремий `low_kick`, `crouch_light`, ноги | $24.98 |
| Meshy ×3 (601, 207/649, 217) | сальто, `roundhouse`, `low_kick` | удари з мечем, коліно, `crouch_light`, ноги | 24 кр. (стеля 48) |
| UAL2 Source + Meshy ×3 | найширше покриття | `crouch_light`, коліно в стрибку, ноги | $14.99 + 24 кр. |

Що лишається за будь-якого вибору (`crouch_light`, реакція ніг, коліно в стрибку): процедурно або пружиною флінчу `RigAnimator` (`low` — «knees buckle», C0 §8 п. 3) чи змінений кліп. Вирішують Арес і Гефест.

## 5. Побічні знахідки

- **«678 проти 656» (C0, відкритий п. 4) — це два різні джерела, а не помилка.** 678 — це каталог Higgsfield (опис `animation_actions`: «678-action library»), 656 — публічна таблиця Meshy з C0. Діапазон id в обох однаковий: 0–696. Для Кліо: вікі можна виправити на «678 у каталозі Higgsfield».
- **Сальто й удари ногою є в каталозі Higgsfield** (C0 лишав це UNGROUNDED). Закрито: 452, 601, 207, 217 та інші — знайдено пошуком.
- **Higgsfield не приймає кілька кліпів за раз**: `animation_action_id` — одне число (`models_explore get 3d_rigging`). Публічні `action_ids` Meshy через Higgsfield недоступні.
- Є варіанти `_inplace` (601, 604, 608, 649…), тобто без руху кореня. Для нас вони кращі за звичайні.

## Відкрите

1. Склад zip UAL1 Pro і UAL2 Source (готові GLB у Source?), їхній `License.txt` — сайти Quaternius заблоковані в цій сесії. Перевірка — з Mac після купівлі або в сесії з доступом.
2. Ціна `3d_rigging` на M-0/M-1 (виміряно на `Fox.glb`).
3. Чи однакова ієрархія кісток у різних викликах `3d_rigging` — лише з першого запуску.
4. Ретаргет кліпу Meshy з однієї моделі на другу — підтвердити в редакторі (як і весь BoneMap із C0).
5. Чим насправді є `Kick` в UAL1 Pro (фронт? розворот?) — подивитися превʼю в переглядачі.

## Related
- [[2026-10-03-Animation-Sources]] · [[Higgsfield-Pipeline]] · [[ADR-013-License-Check-At-Release]] · [[Textures-Registry]]
- [[2026-10-03-Path-to-First-Fight]] · [[Skea]] · [[Choko]] · [[state]]
