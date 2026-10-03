# Ефекти поверхонь — промпти для запуску 9

**Роль:** T6 Аполлон, 2026-10-03 · **План:** [[2026-10-03-Wave-2-Kickoff]] § Хендофи → T6 · запуск 9 — [[2026-10-03-Living-Combat]] · формат — [[VFX-Sheets-Prompts]] ·
напрям — [[VFX-Direction]] · стиль — [[Style-Guide]].
**Статус:** згенеровано всі чотири (Santos «B» −22 кр., потім «Go» на повтор асфальту −5.5 кр.): `game/assets/vfx/surface_{water,gravel,sand,asphalt}.png`. У піску й асфальті ряд 2 — шлейф, а не приземлення (§ Журнал запусків).

## Навіщо

Запуск 9: матеріал підлоги в даних стадії → ефект свого матеріалу на крок, приземлення й ковзання. Матеріали за планом —
вода, асфальт, щебінь, пісок. Які з них на якій арені — вирішує Арес (у плані він перший у ланцюгу); нижче лише що є в арті.

## Що вже є в `game/assets/vfx/` (перевірено в цій сесії)

Команди: `ls game/assets/vfx/` · `grep -n "dust_land\|water_splash\|ground_crack" game/scripts/fx/FxDirector.gd` · огляд аркушів
на плашці `#B8CBB1` (кадр зібрано `ffmpeg … overlay,hstack`, у репо не кладу).

| поверхня | крок | приземлення | ковзання |
|---|---|---|---|
| **вода** | ✗ | ✓ `water_splash` — повний сплеск, 16 кадрів; у грі: `FxDirector.gd:98` (приземлення на `river`) | ✗ |
| **асфальт** | ✗ | ≈ `smoke_puff` — бузково-сірий клуб; колір підходить, але це великий круглий дим, не пил з-під ноги | ✗ (`skid_dust` теракотовий — колір не той) |
| **щебінь** | ✗ | ≈ `dust_land` — лише пил, каменів нема; `ground_crack` — тріщина від важкого падіння, не щебінь | ✗ |
| **пісок** | ✗ | ✓ `dust_land` — теплий сіро-теракотовий пил, хвилі в боки; у грі: `FxDirector.gd:93`, `:100` | ✓ `skid_dust` — пил ковзання, 16 кадрів; у грі ще не викликається |

Разом із 12 клітинок: ✓ 3, ≈ 2, ✗ 7. Повністю бракує **кроку** на всіх чотирьох, **ковзання** по воді, асфальту, щебеню.
Інші сусіди: `spark_metal` (іскри меча об меч, не підлога), `vfx_steam_puff_v1` (пара машин, 6 кадрів, не 4 × 4).

## Рішення — 4 аркуші, один на поверхню, однакова розкладка

Ціна рахується за зображення, не за кадри, тож одна поверхня = один аркуш. Розкладка рядами — як у `spark_hit` (4 ряди
варіантів, ліг на сітку рівно, 0 px на лініях — [[VFX-Sheets-Prompts]] § Журнал запусків). Завантажувачу Гефеста змін не
треба: `Flipbook.play` уже має `first` і `count` (`game/scripts/fx/Flipbook.gd:29-32`).

| ряд | кадри | подія | `Flipbook.play` |
|---|---|---|---|
| 1 | 1–4 | крок | `first: 0, count: 4` |
| 2 | 5–8 | легке приземлення (малий стрибок; повне — наявні `water_splash` / `dust_land`) | `first: 4, count: 4` |
| 3–4 | 9–16 | ковзання вправо (дзеркало — `flip`) | `first: 8, count: 8` |

Шлях — `game/assets/vfx/surface_<матеріал>.png`; кожен аркуш проходить `python3 tools/art/repack_flipbook.py` і отримує рядок
у [[Textures-Registry]] тим самим заходом.

## Промпти

Модель і параметри — як у смузі D: `gpt_image_2_5`, `quality: high`, `resolution: 2k`, `aspect_ratio: 1:1`,
`background: transparent`, один референс стилю (`image_references`, повний UUID job). Промпт =
`{VFX_STYLE} {SHEET} ` + опис + ` {NEG_VFX}`; блоки — байт-у-байт з [[VFX-Sheets-Prompts]] § Блоки.

Кольори тіні — колір основи × `#B07AA6` ([[Style-Guide]]), пораховано python: асфальт `#8A8794` → `#5F4160`, пил щебеню
`#A89C9C` → `#744B66`, пісок `#D9B98A` → `#96595A`. Вода й камінь щебеню — ті самі, що в `water_splash` і `ground_crack`.

| # | id | референс | опис (англійською) |
|---|---|---|---|
| П1 | `vfx-surface-water` | `water_splash` `784aa775-1103-4d42-9f62-7ec04416a65e` | `Four rows of footwork effects on shallow river water, side view from a low angle: deep teal water (#1F4D5A base, #2E3A5C magenta-indigo shadow) with flat cream foam (#EFEED4) edges. Row 1, frames 1-4, a single footstep: a small flat ripple ring opens at the bottom center with two or three tiny droplets, then flattens into a thin foam ring. Row 2, frames 5-8, a light hop landing: a short low crown of water with a few droplets, clearly smaller than a full splash, falling back into a foam ring. Rows 3-4, frames 9-16, a skid sliding to the right: frames 9-12 a low fan of spray and a foam wake are thrown up behind the sliding point and stretch out to the left, frames 13-16 the spray falls back as droplets and the wake breaks into small foam rings. The bottom edge of every frame is a straight invisible water line. Match the drawing style and line of the reference water splash.` |
| П2 | `vfx-surface-asphalt` | `skid_dust` `bec0aa44-1f97-4c88-88d6-30d053cb3728` | `Four rows of footwork effects on dry asphalt, side view: cool grey road dust (#8A8794 base, #5F4160 magenta-violet shadow) in small chunky clumps with inked outlines, and a few tiny dark grit specks (#4A4756). Row 1, frames 1-4, a single footstep: a tiny flat dust puff at the bottom center that breaks into two or three specks. Row 2, frames 5-8, a light landing: a low flat ring of dust clumps squashes out to both sides and breaks into specks. Rows 3-4, frames 9-16, a shoe skid sliding to the right: frames 9-12 a thin low streak of grey dust and grit is scraped out behind the sliding point and stretches to the left, with one short dark scuff line on the invisible floor, frames 13-16 the streak breaks into small dust balls and specks and the scuff line breaks into dashes. A hard dry surface: less dust than sand, flatter and thinner. The bottom edge of every frame is a straight invisible floor line. Match the drawing style and line of the reference dust.` |
| П3 | `vfx-surface-gravel` | `dust_land` `66c1ff6b-9cfb-4347-ba6b-6cc2cfa69ef8` | `Four rows of footwork effects on loose gravel, side view: small angular stone chips (#7A6A73 base, #4E3E52 magenta-violet shadow) with inked outlines and a little pale stone dust (#A89C9C base, #744B66 shadow). Row 1, frames 1-4, a single footstep: three or four small chips hop up from the bottom center and drop back. Row 2, frames 5-8, a light landing: a ring of chips pops up to both sides with a small dust puff and falls back. Rows 3-4, frames 9-16, a skid sliding to the right: frames 9-12 a spray of chips is kicked up behind the sliding point and flies to the left in low arcs over a low dust streak, frames 13-16 the chips bounce and settle on the invisible floor and the dust breaks into specks. The chips stay sharp and angular, never round blobs. The bottom edge of every frame is a straight invisible floor line. Match the drawing style and line of the reference dust.` |
| П4 | `vfx-surface-sand` | `skid_dust` `bec0aa44-1f97-4c88-88d6-30d053cb3728` | `Four rows of footwork effects on dry pale sand, side view: warm sand (#D9B98A base, #96595A magenta-violet shadow) in soft round grainy clumps with inked outlines and fine grain dots. Row 1, frames 1-4, a single footstep: a small soft puff of sand and a scatter of fine grains kicked up from the bottom center, settling. Row 2, frames 5-8, a light landing: a low wide sand splash squashes out to both sides as two small crescents and falls back as grains. Rows 3-4, frames 9-16, a skid sliding to the right: frames 9-12 a thick low wave of sand ploughs up behind the sliding point and rolls out to the left as a long trail, frames 13-16 it collapses into soft clumps and fine grain dots that settle. Heavier than dust: more volume, falls quickly. The bottom edge of every frame is a straight invisible floor line. Match the drawing style and line of the reference dust.` |

## Кошторис (`get_cost`, 2026-10-03, кредитів не списує)

Кожен із чотирьох викликів — з повним промптом, референсом і параметрами вище, `get_cost: true`.

| що | вихід |
|---|---|
| `balance` до | **4904.25** (ultra) |
| `get_cost` П1 вода · П2 асфальт · П3 щебінь · П4 пісок | **2.75** · **2.75** · **2.75** · **2.75** |
| `balance` після | **4904.25** — нічого не списано |

| пакет | розрахунок | кредитів |
|---|---|---|
| **A — мінімум:** 4 аркуші по 1 варіанту | 4 × 2.75 | **11** |
| **B — як у смузі D:** 4 аркуші по 2 варіанти (a/b), у гру — один | 8 × 2.75 | **22** |
| запас на перегенерацію одного аркуша, що не ріжеться на 4 × 4 | 2 × 2.75 | 5.5 |

`get_cost` повертає ціну одного зображення; у D1 батч списав 2.75 за **кожне** ([[VFX-Sheets-Prompts]] § Кошторис). Пропозиція
T6 — пакет **B** (22): у смузі D варіант b перемагав у 8 з 10 аркушів D2 (партія 1 — 6 з 6, партія 2 — 2 з 4), тобто другий варіант окупався.

## Без кредитів — що Гефест може поставити вже зараз

Поки нема слова Santos, запуск 9 не стоїть: приземлення на воді — `water_splash`, на піску — `dust_land`, ковзання на піску —
`skid_dust`, приземлення на асфальті — `smoke_puff` з `tint` (лише темнішає: `albedo_color` множить, `Flipbook.gd:57`) і
малим `size_m`. Крок і ковзання по воді / асфальту / щебеню — лише з аркушів П1–П3.

## Журнал запусків

| пакет | job-id | результат | `balance` до → після |
|---|---|---|---|
| `get_cost` (без генерації) | — | 4 × 2.75 | 4904.25 → 4904.25 |
| B (`generate_image_batch`, 8 × 2.75; Santos «B») | П1 вода `0ed42a9c` (a) / `d9c5a901` (b) · П2 асфальт `93aa0de2` / `f006cd20` · П3 щебінь `a781a128` / `90f65e0b` · П4 пісок `47396712` / `a6ce718a` | у гру — вода **b**, щебінь **b**, пісок **a**; асфальт — жоден (див. нижче) | 4904.25 → **4882.25** (−22, як у кошторисі) |

**Відбір** (огляд пар на плашці `#B8CBB1` + `python3 tools/art/repack_flipbook.py --check`):

| аркуш | a | b | у гру |
|---|---|---|---|
| П1 вода | `OK`, масштаб 0.816; ковзання симетричне, як друга корона | `OK`, 0.922; бризки ковзання летять уліво | **b** |
| П2 асфальт | `FAIL`: 3 ряди (крок, ковзання, осідання), ряд 1 порожній, приземлення нема | `FAIL`: 3 ряди, той самий пропуск | — |
| П3 щебінь | `OK`, 0.639; крок — великі камені, як приземлення | `OK`, 0.835; крок — 3–4 дрібні камінці, як просили | **b** |
| П4 пісок | `OK`, 0.705; ряд 2 — початок шлейфу, а не приземлення в боки | `FAIL`: 3 ряди | **a** |

Після перепаковки всі три — `--check` → `16 frames (nominal grid), scale 1.000`. Для Гефеста: пісок — крок `first: 0, count: 4`,
ковзання `first: 4, count: 12`, приземлення — наявний `dust_land`. Вода й щебінь — за розкладкою вище.

**Урок (асфальт).** Тонкий пил «менше, ніж на піску» модель малює дрібно й пропускає ряд: у двох з двох варіантів приземлення
злилось із кроком. Перед повтором промпт П2 міняється так (решта байт-у-байт): після `A hard dry surface: less dust than sand,
flatter and thinner.` додати `All four rows are filled with drawings, no row is empty; row 2 is clearly different from row 1:
wider, symmetrical to the left and right.` Ціна повтору — 2 × 2.75 = **5.5** (`get_cost` тієї ж моделі й параметрів — 2.75, перевірено
вище). Без слова Santos — не генерую; до того асфальт у грі — `smoke_puff` з `tint` (§ Без кредитів).

**Повтор П2** (Santos «Go», 2026-10-03; `get_cost` → 2.75; `generate_image_batch` 2 × 2.75): c `08413b26`, d `c9170c58`;
`balance` 4720.25 → **4714.75** (−5.5). Між 4882.25 після пакета B і 4720.25 перед повтором списано 162 кр. — не цією сесією, джерело
не перевірено. `--check`: c — `OK` (масштаб 0.693), d — `FAIL` (3 ряди). У гру — **c**. Але ряд 2 і тут шлейф ковзання: додане речення
не допомогло. Висновок: для пилових поверхонь модель стабільно ставить у ряд 2 продовження ковзання (пісок a, асфальт c), а
приземлення в боки малює лише там, де воно є в референсі (вода — `water_splash`, щебінь — `dust_land`). Тому розкладка для Гефеста:

| аркуш | крок | приземлення | ковзання |
|---|---|---|---|
| `surface_water`, `surface_gravel` | `first: 0, count: 4` | `first: 4, count: 4` | `first: 8, count: 8` |
| `surface_sand`, `surface_asphalt` | `first: 0, count: 4` | наявні `dust_land` / `smoke_puff` (`tint`) | `first: 4, count: 12` |

Окремий аркуш приземлення для пилу — якщо Santos захоче — з референсом `dust_land` (`66c1ff6b`), а не `skid_dust`; ціна та сама 2.75.

## Related
- [[2026-10-03-Wave-2-Kickoff]] · [[VFX-Sheets-Prompts]] · [[VFX-Direction]] · [[Style-Guide]] · [[Textures-Registry]] · [[2026-10-03-Living-Combat]] ·
  [[Stage-River]] · [[Stage-Bazaar]] · [[Stage-Fountain]] · [[2026-10-03-Apollon-Surface-FX]]
