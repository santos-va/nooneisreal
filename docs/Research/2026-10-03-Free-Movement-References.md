# Ресерч — референси вільного 3D-руху й камери дуелі (2026-10-03)

**Роль:** T3 Архімед (головна сесія + два суб-агенти T3 лише на читання). Дата доступу до всіх джерел — **2026-10-03**.
**Задача:** друга половина 0.3-A ([[2026-10-03-Prototype-0.3-Free-Movement]], issue santos-va/nooneisreal#24). Перша половина —
[[2026-10-03-Combat-Numbers-Grounding]].
**Статус:** усе нижче — **референс чужих ігор і рушія, не наша правда**. Вибір чисел — Арес (#25) і Гефест (#27).

**Питання.** Чим заземлити PLACEHOLDER-и з [[02-Combat-System]] § Вільний 3D-рух (гілка Ареса
`claude/ares-0.3-b-free-move`, `docs/Meetings/2026-10-03-Ares-Free-Movement-Rules.md` — ще не на `main`)? Їх сім:
- `tracking_deg`
- `circle_speed_mult`
- `block_arc_deg`
- `backhit_hitstun_bonus`
- `arena_radius`
- `wall_splat_frames`
- `grapple_cone_deg`

Окремо — що є для N° у smoke-тесті камери (0.3-2) і що саме роблять `SpringArm3D` і `Camera3D` у Godot 4.7.

**Перевірено в цій сесії власноруч** (поверх звітів суб-агентів):
- `curl wavu.wiki/w/api.php?action=parse&page=Sidestep` → дослівно «There is no hard-coded "crush" mechanic involving sidesteps»
  і «most moves are stepped by about 8–12 frames of step».
- `curl virtuafighter.com/wiki/hit-types/` → дослівно «Up to 14 pts +2 frame bonus · Between 15 and 24 pts +3 frame bonus ·
  25pts or more +6 frame bonus»; Back Hit — «No damage bonuses… the same frame advantage bonuses apply as per Side Hits».
- `curl …/needle-mirror/com.unity.xr.interaction.toolkit/master/…/ContinuousTurnProvider.cs` → `22: float m_TurnSpeed = 60f;`,
  `package.json` → `3.7.0-pre.1`.
- Сирці Godot `4.7-stable` (тег → коміт `5b4e0cb0fd`): `doc/classes/SpringArm3D.xml`, `Camera3D.xml`, `ProjectSettings.xml`,
  `@GlobalScope.xml`, `scene/3d/physics/spring_arm_3d.cpp` — рядки нижче.
- Проєкт: `git show origin/main:game/project.godot` → `18: run/max_fps=120`, `224: common/physics_ticks_per_second=60`,
  `physics_interpolation` не задано.

---

## 1. Відповідь по кожному PLACEHOLDER Ареса

| поле (02 § Вільний 3D-рух) | PLACEHOLDER | що кажуть еталони | статус | рядки |
|---|---|---|---|---|
| `tracking_deg` light 30 / heavy 15 / crouch 20 / air 10 / ult 45 | градуси | **Публічних градусів немає ні в одній грі.** Tekken 8 міряє трекінг **кадрами sidestep**: «number of frames the character can sidestep for and still be hit», шкала від +8 до −17; «most moves are stepped by about 8–12 frames of step». SC6 і VF5 ділять удари на класи: горизонталь/вертикаль; linear / half-circular / full-circular | **UNGROUNDED** як число. Найближча модель — клас трекінгу або «скільки кадрів обходу ухиляє» | M4–M8 |
| `circle_speed_mult` 0.8 | × `walk_speed` | Швидкості sidewalk/8WR у числах не знайдено. Є лише «Forwards movement is faster than backwards» (T8) і «differs for every character» (VF5) | **UNGROUNDED** | M3, M9 |
| sidestep **без i-кадрів** (рішення Ареса) | — | **Збігається з T8**: «no hard-coded "crush" mechanic involving sidesteps… everything is determined by… hitboxes and hurtboxes». SC6: step 10 f, guard з 13-го f | **референс є** (T8 дослівно перевірено) | M1, M2 |
| `block_arc_deg` ±70 | половина кута | **Жодна гра не документує guard, обмежений кутом.** Модель еталонів інша: стан «спиною/боком» + час розвороту в guard (T8 6–7 f, VF5 side 3 f / BT 5 f). Єдине кутове число — T8 «very safely encompasses the 180° behind the character's front», але воно про втрату CH-властивостей, а не про блок | **UNGROUNDED** | M10–M12 |
| `backhit_hitstun_bonus` 4 | кадри | **VF5 Side/Back Hit: +2 (шкода ≤ 14) / +3 (15–24) / +6 (≥ 25) кадрів переваги, без бонусу шкоди** (перевірено дослівно). T8: по спині CH-властивості не діють, лишається тільки множник шкоди ×1.2 | **референс є** — діапазон 2–6, залежить від сили удару | M13, M14 |
| `arena_radius` 12.5 м | метри | T8: типова стадія «24x24», діапазон від 16x24 до 80x120; VF5: 10x10 – 16x16. **Одиниці не визначені** на жодній сторінці | **UNGROUNDED** у метрах (пропорції — довідково) | M18, M19 |
| `wall_splat_frames` 10 | кадри | Прямого відповідника немає. Поруч: T8 wall slump **6 f** до tech roll; T8 wall crush у прикладі Azucena uf+1 — +7 у відкритому просторі проти +15g біля стіни (різниця 8); VF5 wall side stun гарантує атаки до **23 f**; SC6 — макс. **2** splat на комбо, VF5 — 1 | **UNGROUNDED** як одне число | M15–M17 |
| `grapple_cone_deg` 60 (половина) | градуси | Первинного числа немає. Техніка — найменший кут між вектором прицілу й вектором до цілі, `cos(a) >= cos(cone)` (спільнота). **Конфлікт усередині проєкту:** бриф [[2026-10-02-Grapple-Input-UI]] пропонує «конус 30°», а 02 — 60° | **UNGROUNDED** + внутрішня розбіжність 30 ↔ 60 → Арес | C14 |

---

## 2. Еталони 3D-руху (Tekken 8, SoulCalibur VI, Virtua Fighter 5)

Вікі читались через MediaWiki API (`action=parse&prop=wikitext`), а не через переказ WebFetch.

| # | що | значення | джерело | ревізія |
|---|---|---|---|---|
| M1 | T8 sidestep: i-кадри | «no hard-coded "crush" mechanic involving sidesteps» | https://wavu.wiki/t/Sidestep | revid 37870, 2025-03-11 |
| M2 | SC6 step | 10 f; guard з 13-го f; backstep 15 f; горизонталь у вразливе вікно step дає counter hit | https://wiki.supercombo.gg/w/Soulcalibur_VI/System § Step | 2026-07-22 |
| M3 | T8 sidewalk | u~n~U, «indefinitely», евазивність «reduces the longer it is held»; швидкості в числах немає | wavu Sidestep § Sidewalk | 2025-03-11 |
| M4 | T8 tracking | ширина хітбокса, зсув убік і «realigning towards the opponent during startup» | https://wavu.wiki/t/Tracking | revid 30179, 2024-06-08 |
| M5 | T8 tracking score | startup + test = «number of frames the character can sidestep for and still be hit»; тести від +8 до −17; вище +6 не міряють, бо атакувальник вирівнюється | wavu Tracking § Measurement, § Limitations | 2024-06-08 |
| M6 | T8 «step» удару | «most moves are stepped by about 8–12 frames of step»; step із нейтралі гірший на 1–3 f | wavu Sidestep § Buffering | 2025-03-11 |
| M7 | T8 homing | бінарна властивість, «cannot be sidestepped (under normal circumstances)» | wavu Tracking § Homing | 2024-06-08 |
| M8 | SC6 / VF5 класи | SC6: горизонталь трекає step, вертикаль — ні. VF5: linear / half-circular / full-circular; «Attacks do not hold any special tracking properties» | SC6/System; https://virtuafighter.com/wiki/movement/ (Last Modified 2026-09-01), /wiki/attacks/ (2025-10-25) | — |
| M9 | VF5 ходьба | «differs for every character», вперед / назад / спиною — різні | VF movement § Walking | 2026-09-01 |
| M10 | T8 спиною (BT) | «During BT it isn't possible to guard»; розворот у guard 6–7 f | https://wavu.wiki/t/Back_turned | 2025-03-06 |
| M11 | T8 зона «спини» | «very safely encompasses the 180° behind the character's front»; точну межу вікі називає «hard to determine» | https://wavu.wiki/t/Attack § Counter Hit | 2026-01-18 |
| M12 | VF5 розворот | side turned — 3 f до guard/evade; BT — 5 f | https://virtuafighter.com/wiki/positions/ | 2019-04-20 |
| M13 | VF5 Side Hit / Back Hit | +2 / +3 / +6 f за шкодою ≤ 14 / 15–24 / ≥ 25; без бонусу шкоди. **Перевірено дослівно** | https://virtuafighter.com/wiki/hit-types/ | Last Modified 2025-11-17 (сайт описує FS, згадує Ultimate Showdown) |
| M14 | T8 удар у спину/бік | CH-властивості не діють, діє лише ×1.2 шкоди. Патч 2.03.01: «Behavior on side hits and back hits has been modified» — без чисел | wavu Attack § Counter Hit; https://wavu.wiki/t/Version_2.03.01 | 2026-01-18; 2025-12-22 |
| M15 | T8 стіна | після splat — intangible, потім **6 f** wall slump до tech roll (спиною після жонглю — 2 f); «several (2-4) hits»; скейлінг у slump 50 → 30 %; wall bounce «currently not present in Tekken 8» | https://wavu.wiki/t/Wall, /t/Combo, /t/Attack | revid 59937, 2026-05-30; 2026-01-18 |
| M16 | T8 wall crush | приклад Azucena uf+1: +7 у відкритому просторі, **+15g** біля стіни | wavu Attack § Wall Crush | 2026-01-18 |
| M17 | SC6 / VF5 стіна | SC6: макс. 2 wall splat на комбо. VF5: шкода < 21 → wall hit, ≥ 21 → wall stagger; wall side stun гарантує атаки до 23 f; 1 splat на комбо | SC6/System § Wall Splats; https://virtuafighter.com/wiki/stages/ (2021-02-19) | — |
| M18 | T8 стадії | типово **24x24** (Arena, Urban Square, Genmaji…), від 16x24 до 58x70 (Coliseum of Fate, коло) і 80x120; нескінченних у T8 немає (у T7 були) | https://wavu.wiki/t/Stage | revid 53254, 2025-10-28 |
| M19 | VF5 стадії | Full Fence 10x10 · Half Fence 12x12 · Open 16x16 · Rectangle 6x16 | VF stages | 2021-02-19 |

**Не відкрились:** wavu `Back_hit`, `Side_hit`, `Wall_splat`, `Walk`, `Distance` (`missingtitle`); `wiki.supercombo.gg/w/api.php`
(бот-стіна; працює `/api.php`); `virtuafighter.com/wiki/evade/` (404). VF5 REVO окремо не перевірено, усі сторінки — про FS.

---

## 3. Арена-файтинги: lock-on, камера, самонаведення

**Чисел немає в жодному з трьох — лише якісний опис.**

| # | гра | що задокументовано | джерело | дата |
|---|---|---|---|---|
| C1 | Naruto Storm (1) | камера «covers a majority of angles that also can centre behind either character»; Chakra Dash — «lock-on high speed dash that travels a set distance»; наземний деш довший за повітряний | naruto-ultimate-ninja-storm.fandom.com, `Naruto:_Ultimate_Ninja_Storm` (MediaWiki API) | revid 3146, 2024-10-30 |
| C2 | Storm 4 | Chakra Dash двох ступенів: тап і утримання («a lot faster and covers more distance») | https://steamcommunity.com/app/349040/discussions/0/133256240727229110/ | спільнота, дата не з'ясована |
| C3 | BT3 (2007) | Lock On — L1; «If you are not locked onto your opponent, press the R3 button to switch to Free Look mode»; три відстані камери A/B/C без чисел | мануал PS2 (Atari), archive.org `DragonballZBudokaiTenkaichi3Manual` | 2007 — **первинне** |
| C4 | BT3, спільнота | «permanently on… cannot be lifted» | GameFAQs Q&A 225106 | **розходиться з мануалом C3** → вірити мануалу |
| C5 | Sparking! Zero (2024) | Dragon Dash — «rush at high speed towards the direction the stick is oriented»; Z-Burst Dash — за спину; Step — «✖ to go forward or sideways»; Sonic Sway — ухилення в останній момент | https://en.bandainamcoent.eu/dragon-ball/news/dragon-ball-sparking-zero-combos-and-features | 2024-08-27 — **первинне** |
| C6 | Sparking! Zero, антиприклад | персонаж закриває суперника на дистанції; камера проходить крізь рельєф; lock-on «не бачить» суперника поруч | Steam-обговорення 1790600 (…/4702412445071535724/, …/4852156862423705921/) | 2024, спільнота |

Висновок: у Storm і в DBZ-аренниках lock-on тримає суперника, а деш наводиться на нього. Скільки градусів і метрів — ніде не
публічно. Мануал Storm 4 / Connections не знайдено (manua.ls — лише обгортка).

---

## 4. Камера дуелі: межа повороту (N° для smoke 0.3-2)

### 4.1 Що кажуть джерела

| # | джерело | що | числа? |
|---|---|---|---|
| C7 | Mark Haigh-Hutchinson, GDC 2005, «Fundamentals of Real-Time Camera Design», слайди https://media.gdcvault.com/gdc05/slides/GD_Haigh-Hutchinson_FundamentalsReal-TimeCameraDesign2.pdf | §4.7 «Limit the reorientation speed of the camera»; миттєва переорієнтація — лише як явний кат, «never in quick succession»; «always move in the shortest angular direction». §5.5 Fighting: «Focal point between enemies rather than one specific character» | **немає** |
| C8 | John Nesky, GDC 2014, «50 Game Camera Mistakes» (https://www.youtube.com/watch?v=C7307qRmlMI; список — shermanrose.uk) | #20 «Violating the 180 degree rule», #31 «Rotating excessively to look at nearby targets», #46 «Rapidly transitioning to a new camera position». За транскриптом третьої сторони (videohighlight.com): на близькій цілі краще відсунути камеру, ніж крутити | **немає**; відео не переглянуто, лише транскрипт |
| C9 | Unity XR Interaction Toolkit 3.7.0-pre.1, `ContinuousTurnProvider.cs:22` | `m_TurnSpeed = 60f` (°/с, дефолт). **Перевірено власноруч** | 60°/с — VR-дефолт, не поріг |
| C10 | Meta IWSDK, smooth turn (https://developers.meta.com/horizon/documentation/web/iwsdk-concept-locomotion-turn/, оновлено 2026-03-11) | `180, // degrees/second for smooth mode`; snap 45 | 180°/с — VR-дефолт прикладу, не поріг |
| C11 | Hu, Stern, Vasey, Koch, Aviat Space Environ Med 1989;60(5):411-4, PMID 2730483 | оптокінетичний барабан 15/30/60/90 °/с: «symptoms increased as drum speed increased up to 60 degrees.s-1; symptoms decreased at 90» | пік нудоти — 60°/с; повнопольове тривале обертання, не екран ТВ |
| C12 | Xbox Accessibility Guideline 117 (https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117, оновлено 2026-06-17) | можливість вимкнути автоматичний рух камери; приклад Sea of Thieves «auto centre speed is set to 180» **без одиниці** | не використовувати як °/с |
| C13 | Перемикання сторін | T7: віддзеркалення площин для двох шаф (Siliconera, 2015-01-05) — не оберт камери. Прийом спільноти UE (forums.unrealengine.com, 2014-08-23): бульове «хто правіше в екранному просторі» + оберт проміжного вузла. Офіційно для T8/SC6 **не знайдено** | — |
| C14 | Конус цілі (гарпун) | `cos(a) >= cos(cone)`, найменший кут до вектора прицілу — https://gamedev.net/forums/topic/696638-implementing-a-grappling-hook-targeting-system/5378345/ | техніка, без числа |

**N° — UNGROUNDED.** Для камери файтингу числа немає. Найближчі VR-дефолти розходяться втричі:

| референс | °/с | °/тік @ 60 Гц | °/кадр @ 120 FPS |
|---|---|---|---|
| Unity XRI (C9) | 60 | 1.0 | 0.5 |
| Meta IWSDK (C10) | 180 | 3.0 | 1.5 |

### 4.2 Скільки повороту вимагає наш рух (розрахунок, не референс)

Лінія між бійцями при обході нерухомого суперника обертається з `ω = v / d`. Вхід — PLACEHOLDER і `.tres`:
- `circle_speed = 0.8 × walk_speed` (02);
- `walk_speed`: Choko 5.6, Skea 6.2;
- `dash_speed`: Choko 13.5, Skea 15.0;
- `MIN_SEPARATION` 0.95 м (`Fighter.gd:23`);
- `FLASH_TRAVEL := 4` (`Fighter.gd:30`).

Команда: `python3 -c "…ω=v/d…"` у цій сесії.

| рух | d = 0.95 м | d = 2 м | d = 4 м | d = 8 м |
|---|---|---|---|---|
| обхід Choko, 4.48 м/с | 270°/с · **4.50°/тік** | 128°/с · 2.14 | 64°/с · 1.07 | 32°/с · 0.53 |
| обхід Skea, 4.96 м/с | 299°/с · **4.99°/тік** | 142°/с · 2.37 | 71°/с · 1.18 | 36°/с · 0.59 |
| деш Choko убік, 13.5 м/с | 814°/с · **13.6°/тік** | 387°/с · 6.45 | 193°/с · 3.22 | 97°/с · 1.61 |
| Flash Step Skea крізь суперника | лінія перекидається на ~180° за 4 тіки → **~45°/тік** | | | |

**Що з цього випливає (факт, не рекомендація):**
- Камера, жорстко прив'язана до лінії між бійцями, на близькій дистанції обертається швидше за обидва VR-дефолти.
- На Flash Step така камера дає майже миттєвий розворот, а це саме те, від чого застерігають C7 і C8.
- Тому N — це **кламп кутової швидкості в коді `DuelCamera`**, а smoke перевіряє, що кламп діє. Сам рух меншого N не дасть.
- Що робити, коли кламп відстає: відсунути камеру (C8) чи зробити явний кат (C7)? Це дизайн, рішення Ареса.

**Одиниця «за кадр» для тесту.** `run/max_fps=120`, фізика 60 Гц, `physics_interpolation` вимкнена. «За кадр» треба
зафіксувати явно: за physics tick (якщо камера в `_physics_process`) або за кадр рендеру (`_process`, до 120 FPS, межа вдвічі менша).

---

## 5. Godot 4.7: `SpringArm3D`, `Camera3D` і інструменти кута

| # | факт | місце |
|---|---|---|
| G1 | `SpringArm3D` — «casts a ray or a shape along its Z axis and moves all its direct children to the collision point». Члени: `collision_mask` = 1, `margin` = 0.01, `shape`, `spring_length` = 1.0. **Немає жодного параметра згладжування, демпфування чи кута** | `doc/classes/SpringArm3D.xml` @ 4.7-stable |
| G2 | Оновлення — щотіку фізики: `case NOTIFICATION_INTERNAL_PHYSICS_PROCESS: { process_spring();` | `scene/3d/physics/spring_arm_3d.cpp:53–54` |
| G3 | **Ставить дитину миттєво**, без пружини: `current_spring_length = spring_length * motion_delta;` → `child->set_global_transform(child_transform)`. Обертання (`basis`) дитини зберігається, змінюється лише позиція. Назва «spring» оманлива: плавність треба писати самим | `spring_arm_3d.cpp:194–203` |
| G4 | Якщо дитина — `Camera3D` і `shape` не задано, кидається **піраміда фрустума камери** (`camera->get_pyramid_shape_rid()`) з поворотом камери і позицією руки | `spring_arm_3d.cpp:147–167` |
| G5 | **Розбіжність документації з кодом:** документація каже, що `margin` корисний саме з дитиною `Camera3D`. Але в коді `dist -= margin` є **лише** в гілці променя (немає дитини-камери і немає `shape`). У гілках `cast_motion` (з камерою або з `shape`) `margin` не віднімається | `SpringArm3D.xml` (`margin`) проти `spring_arm_3d.cpp:176–181` і `:167`, `:191` |
| G6 | `Camera3D.fov` = 75.0 — **вертикальний** при `keep_aspect` = 1 (KEEP_HEIGHT); у 16:9 це «~107.51 degrees» по горизонталі. Також є `h_offset`/`v_offset` (зараз ними трясе `FightCamera.gd`) і `near` = 0.05 | `doc/classes/Camera3D.xml:186–213` |
| G7 | `rotate_toward(from, to, delta)` — «Will not go past to», коректно через перехід TAU. Готовий кламп кута за тік | `@GlobalScope.xml:1121–1128` |
| G8 | `angle_difference(from, to)` → у `[-PI, +PI]`; для протилежних кутів повертає −PI або PI. Це місце перекидання на 180° (C13) | `@GlobalScope.xml:88–94` |
| G9 | `lerp_angle` — «interpolates correctly when the angles wrap around TAU» | `@GlobalScope.xml:633–640` |
| G10 | `physics/common/physics_interpolation` default `false`; вмикається лише при старті проєкту; телепорт вузла — `reset_physics_interpolation()` після переміщення | `ProjectSettings.xml:2689–2692`; `Node.xml:1061–1066` |
| G11 | Нинішня камера `FightCamera.gd` — у `_process`, позиція `lerp(t, 1.0 - pow(0.0015, delta))`, далі `look_at`. Кламп кута там не потрібен, бо камера бічна й не обертається навколо пари | `game/scripts/arena/FightCamera.gd:26–33` |

---

## Відкрите

1. **Градуси трекінгу, швидкість обходу, кут блоку, радіус арени в метрах, wall splat, конус гарпуна, N° камери** —
   публічного числа немає (UNGROUNDED). Перевірене є лише для back hit (VF5 +2/+3/+6) і для «sidestep без i-кадрів»
   (T8). Решту дає плейтест на Mac.
2. Як перевести T8 tracking score у кадрах на наш `tracking_deg`: потрібен замір у сцені. Скільки градусів обходу
   проходить за 8–12 кадрів при `circle_speed` на дистанції удару — це геометрія (§4.2), але дистанцію удару обирає Арес.
3. Внутрішній конфлікт конуса гарпуна 30° ([[2026-10-02-Grapple-Input-UI]]) ↔ 60° ([[02-Combat-System]]) — до Ареса.
4. Не отримано: мануал Storm 4 / Connections; GDC 2019 Motomura (DBFZ); книгу Haigh-Hutchinson «Real-Time Cameras»;
   відео Nesky (лише транскрипт третьої сторони); вимір дистанції sidestep T8 з відео.
5. G5 (`margin`) — варто перевірити в сцені, перш ніж Гефест на нього покладеться.

## Related
- [[2026-10-03-Prototype-0.3-Free-Movement]] · [[2026-10-03-Combat-Numbers-Grounding]] · [[02-Combat-System]] · [[04-Grapple-System]]
- [[2026-10-02-Grapple-Input-UI]] · [[ADR-002-2.5D-First]] · [[ADR-004-Physics-Is-Presentation]] · [[state]]
