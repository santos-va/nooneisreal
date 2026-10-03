# Ресерч — заземлення чисел бою для Ареса (2026-10-03)

**Роль:** T3 Архімед (головна сесія + три суб-агенти T3 лише на читання). Дата доступу до всіх джерел — **2026-10-03**.
**Статус:** усе нижче — **референс, а не наша правда**. Діапазон тут означає «де стоять еталони», а не «яке
число обрати». Вибір лишається за Аресом ([[02-Combat-System]], [[08-Balance]]).

**Питання.**
1. Які кадри мають SF6, Tekken 8, GGST (і що відомо про Storm) для легкого, важкого, присідного й
   повітряного удару: startup/active/recovery, hitstun/blockstun, перевага на блоці, hitstop, вікно скасування?
2. Куди в цих діапазонах лягають рухи `choko.tres` і `skea.tres`?
3. Як працює гарпун у JC, Spider-Man, Titanfall 2 і Apex? Які параметри пружини пасують дрону з [[ADR-011-Diegetic-Grapple-Anchors]]?
4. Таблиця «поле MoveData → діапазон → джерело».

**Перевірено в цій сесії власноруч** (поверх звітів суб-агентів):
- `curl dustloop.com/wiki/api.php?action=parse&page=GGST/Frame_Data` → таблиця Attack Level дослівно як у §1.3.
- `curl wiki.supercombo.gg/api.php?action=parse&page=Street_Fighter_6/Ryu/Data` → Ryu 5LP `startup 4 · active 3 · recovery 7 · hitAdv +4 · blockAdv -1 · hitstun 14 · blockstun 9 · hitstop 9 · hitconfirm 13`, рядок у рядок як у §1.1.
- Код рушія (`git rev-parse HEAD` гілки = `main` `9c27085`): `Fighter.gd`, `InputRouter.gd`, `GrappleHook.gd`, рядки нижче.

---

## 0. Як читати наші числа поруч з еталонними (це важливо, інакше все зсунеться на кадр)

| що | еталони | наш рушій | джерело |
|---|---|---|---|
| startup | **включає** перший активний кадр: «Startup is measured to also include the first Active frame» (SF6). Tekken `i10` означає перший активний кадр 10 | `move_frame = 0` на старті (`Fighter.gd:557`), хіт перевіряється з `move_frame >= m.startup` (`Fighter.gd:595`). Тобто перший активний — це кадр `startup + 1` | SC-GD; wavu Generic movelist; код |
| **переклад** | `startup_ref` | **`MoveData.startup = startup_ref − 1`** | висновок із двох рядків вище. Чи рахується тік натискання — **не заміряно**, ±1 |
| hitstop | у SF6, GGST і DBFZ обидва бійці стоять, stun не тане | так само: `hitstop_frames > 0 → return` до тіку стану (`Fighter.gd:233–236`). На хіт ставиться обом (`_apply_hitstop`, `:835`), на блок — `max(2, hitstop/2)` (`:725`) | код. Чи є у SF6/GGST окремий blockstop — **не досліджено** |
| перевага | SF6: `adv = stun − (active + recovery)` для влучання першим активним. Перевірено на 18 парах SuperCombo, зійшлося 17. Виняток — Ryu 5HK на блоці | у нас, за читанням коду, ймовірно `stun − (active − 1 + recovery)`, тобто +1 до SF6-формули. **Не заміряно**, порядок тіків P1/P2 теж може зсунути | виведено суб-агентом SF6 із рядків SC, явної формули в джерелі немає. Наш варіант — читання коду, не замір |
| скасування | SF6: hitconfirm window «counts from the first frame the attack connects until the final cancelable frame» | на хіт: від кінця active **до кінця recovery** (`Fighter.gd:597–599`, `_try_cancel :638`), плюс буфер вводу 6 кадрів (`InputRouter.gd:7 BUFFER_FRAMES := 6`) | SC Glossary; код |

Нижче всі «наші переваги» пораховано **SF6-формулою**, щоб порівнювати з еталонами одним мірилом. Справжнє число
для нашого рушія замірить Гефест (§5, Відкрите).

---

## 1. Еталони кадрів, 60 fps

### 1.1 Street Fighter 6

Версія: офіційна сторінка не показує дати. Останній патч у списку змін Capcom — **«08.03.2026 update»**
(https://www.streetfighter.com/6/buckler/en/battle_change). SuperCombo-ревізії: Ryu 378774 (2026-09-09), Chun-Li 379195
і Luke 379199 (2026-09-14). Офіційні сторінки й SuperCombo збігаються. FAT (коміт 2026-06-14, старший за патч)
розходиться лише в Luke 5HP, беремо CAP = SC.

Джерела: CAP https://www.streetfighter.com/6/character/{ryu,chunli,luke}/frame ·
SC https://wiki.supercombo.gg/w/Street_Fighter_6/{Ryu,Chun-Li,Luke}/Data

| # | рух | startup | active | recovery | на хіт | на блок | hitstun | blockstun | hitstop | cancel |
|---|---|---|---|---|---|---|---|---|---|---|
| S1 | Ryu 5LP | 4 | 3 | 7 | +4 | −1 | 14 | 9 | 9 | Chn Sp SA |
| S2 | Chun-Li 5LP | 4 | 3 | 7 | +5 | −3 | 15 | 7 | 9 | Chn Sp SA |
| S3 | Luke 5LP | 7 | 2 | 11 | +2 | −3 | 15 | 10 | 11 | Sp SA TC |
| S4 | Ryu 5HP | 10 | 5 | 18 | +4 | −2 | 27 | 21 | 13 | Sp SA TC |
| S5 | Ryu 5HK | 12 | 4 | 20 | +9 | +1 | 33 | 24 | 13 | — |
| S6 | Chun-Li 5HP | 13 | 3 | 20 | +2 | −3 | 25 | 20 | 13 | SS |
| S7 | Chun-Li 5HK | 14 | 3 | 18 | +4 | 0 | 25 | 21 | 13 | SS |
| S8 | Luke 5HP | 10 | 3 | 23 | +1 | −4 | 27 | 21 | 13 | Sp SA |
| S9 | Luke 5HK | 10 | 7 | 16 | +2 | −5 | 25 | 18 | 13 | — |
| S10 | Ryu 2LK | 5 | 2 | 10 | +3 | −1 | 15 | 11 | 9 | Chn |
| S11 | Chun-Li 2LK | 4 | 2 | 10 | 0 | −2 | 12 | 10 | 9 | Chn Sp SA |
| S12 | Luke 2LK | 5 | 3 | 11 | 0 | −3 | 14 | 11 | 9 | Chn |
| S13 | Ryu j.HP | 9 | 6 | 3 після приземлення | +8 (+15) | +4 (+11) | 19 | 15 | 13 | — |
| S14 | Chun-Li j.HP | 9 | 6 | 3 після приземлення | +12 (+16) | +7 (+11) | 20 | 15 | 12 | TC |
| S15 | Luke j.HP | 9 | 6 | 3 після приземлення | +6 (+15) | +2 (+11) | 19 | 15 | 13 | — |

Системні механіки SF6:

| # | механіка | значення | джерело |
|---|---|---|---|
| S16 | hitstop L/M/H як закон гри | **UNGROUNDED**: жодне джерело не формулює його як правило | SC Game Data https://wiki.supercombo.gg/w/Street_Fighter_6/Game_Data (рев. 378588, 2026-09-07) — лише якісно: «Heavier attacks have longer hitstop» |
| S17 | hitstop, емпірична мода наземних нормалів, 30 персонажів | L **9** (119/121) · M **11** (100/120) · H **13** (98/~110). FAT незалежно: 9 / 11 / 13 | вибірка суб-агента з SC API і FAT JSON. Це підрахунок, а не цитата |
| S18 | hitconfirm window 5LP/2LP, уся каста | 13 (37 випадків) · 12 (11) · 14 (3) · 15 (2) · 11 (1) | FAT `hcWinSpCa`, https://raw.githubusercontent.com/D4RKONION/FAT/main/src/js/constants/framedata/SF6FrameData.json (коміт 2026-06-14) |
| S19 | універсальне вікно special-cancel | **UNGROUNDED**: дається окремо для кожного руху | SC Glossary (рев. 367082, 2026-06-20) |
| S20 | кидок | startup 5 · active 3 · whiff total 30, «universally». Офіційно: 5 / 5-7 / 23 | SC Offense https://wiki.supercombo.gg/w/Street_Fighter_6/Offense (рев. 376169, 2026-08-21); CAP |
| S21 | вікно throw tech | «until the 9th frame of being thrown» | SC Defense (рев. 364973, 2026-05-30) |
| S22 | буфер вводу | «buffered up to 4 frames early… 5 frame window»; dash/reversal — 8 | SC Game Data. Одне джерело, офіційного немає |

### 1.2 Guilty Gear -Strive-

Версія: Ver. 2.03 від 24.09.2026 (https://www.guiltygear.com/ggst/en/news/post-5223/). Сторінки даних Dustloop
правлено 2026-09-18/20, тобто під battle version 5.02. Що 5.03 нормалі Sol/Ky не зачепила, суб-агент знає **лише з
переказу** патчнота. Дані взято з Cargo API Dustloop, а не з переказу сторінки: WebFetch спотворив Sol c.S.
Джерела: https://www.dustloop.com/w/GGST/Sol_Badguy · https://www.dustloop.com/w/GGST/Ky_Kiske

| # | рух | startup | active | recovery | на блок | на хіт | рівень |
|---|---|---|---|---|---|---|---|
| G1 | Sol 5P | 5 | 5 | 9 | −2 | +1 | 1 |
| G2 | Ky 5P | 5 | 4 | 7 | −1 | +2 | 0 |
| G3 | Sol 2K | 6 | 3 | 11 | −2 | +1 | 1 |
| G4 | Ky 2K | 6 | 4 | 10 | −2 | +1 | 1 |
| G5 | Sol 5H | 11 | 4 | 20 | −5 | −2 | 4 |
| G6 | Ky 5H | 12 | 6 | 21 | −8 | −5 | 4 |
| G7 | Sol j.H | 11 | 4, 8 | 0 | +7 (IAD) | +10 (IAD) | 2 |
| G8 | Ky j.H | 13 | 4 | 23 | +5 (IAD) | +8 (IAD) | 2 |

**G9 — Attack Level** (https://www.dustloop.com/w/GGST/Frame_Data § Attack Level, правка 2026-05-09; першоджерело в
коментарі вікітексту — твіт kedako_faital/1409213820292067331). **Перевірено власноруч curl.**

| рівень | hitstop | hitstun стоячи | hitstun у присіді | блок на землі |
|---|---|---|---|---|
| 0 | 11 | 12 | 13 | 9 |
| 1 | 12 | 14 | 15 | 11 |
| 2 | 13 | 16 | 17 | 13 |
| 3 | 14 | 19 | 20 | 16 |
| 4 | 15 | 21 | 22 | 18 |

**G10 — скасування** (https://www.dustloop.com/w/GGST/Mechanics, правка 2026-09-25): P- і K-нормалі скасовуються в
спешал **лише в active**. P при цьому гатлінгує в себе й у recovery. Решта нормалів скасовується і в recovery.

### 1.3 Tekken 8 (3D-референс)

Версія: wavu infobox показує 3.02.01 (2026-08-19). EventHubs пише про 3.02.02 (2026-09-10), лише багфікси
(https://www.eventhubs.com/news/2026/sep/09/tekken-8-patch-bug-fixes/). Розходження датоване й на нормалі не впливає;
те, що це лише багфікси, суб-агент знає з переказу пошуку. Джерела: https://wavu.wiki/t/Generic_movelist ·
https://wavu.wiki/t/Jin_movelist · https://wavu.wiki/t/Kazuya_movelist

| # | рух | startup | на блок | на хіт | recovery |
|---|---|---|---|---|---|
| T1 | Generic 1 (джеб) | i10 | +1 | +8 | r19 |
| T2 | Jin df+1 | i13~14 | −3 | +4 | r20 |
| T3 | Jin d+4 (низ) | i16~17 | −12 | −1 | r30 |
| T4 | Jin df+2 | i16~17 | −9 | +6 | r30 |
| T5 | Kazuya df+2 | i14 | −12 | +5 | r32 |

**T6 — пороги** (https://wavu.wiki/t/Punishment → `Frame`, правка 2024-08-05):
- «-10 on block or worse are considered punishable»;
- «-15 … launch punishable»;
- «-9 or better… safe».

### 1.4 DBFZ (2D-аніме-референс)

Dustloop, остання сторінка версії `DBFZ/Version/1.50` (правка 2026-04-21), https://www.dustloop.com/w/DBFZ/Frame_Data.

| # | що | значення |
|---|---|---|
| D1 | Attack Level 0–4: hitstun | 14 / 16 / 18 / 20 / 22 |
| D2 | blockstun | 11 / 11 / 15 / 15 / 15 |
| D3 | hitstop | 6 / 8 / 11 / 14 / 16 |
| D4 | Goku 5L | 6 / 3 / 13, на блок −4 |
| D5 | Goku 2L | 6 / 2 / 14, на блок 0 |
| D6 | Goku 5H | 12 / 4 / 17, на блок −5 |
| D7 | Goku j.H | 13 / 4 / 21 |

### 1.5 Naruto Ultimate Ninja Storm — **UNGROUNDED**

Публічних кадрових даних **не знайдено**. Пошук: WebSearch за п'ятьма формулюваннями (frame data, spreadsheet,
reddit, gamefaqs), патчноти Connections 1.20 і 1.70 (якісні формулювання без чисел), гайд player.one (2016).

Є лише неверифіковані секундні таймери Storm 4 від спільноти:
- substitution «14 Seconds» — Steam https://steamcommunity.com/app/349040/discussions/0/2268069450226419404, 2020-05-05;
- «7-second cooldown» — лише пошуковий витяг. Суперечить 14 с, тому **UNGROUNDED**.

Ще один коментар гравця: «locked at 30fps» (https://steamcommunity.com/app/349040/discussions/0/343786745997490402/,
2016). Якщо це правда, будь-які кадри Storm 4 треба множити ×2. Офіційно не підтверджено.

**Висновок:** для «відчуття Storm» кадрових еталонів немає. Шлях — замір з 60 fps відео або мод-тули
(NSC-Toolbox), окрема задача.

---

## 2. Зведені діапазони еталонів (тільки 2D-рядки S/G/D; Tekken окремо, бо 3D і інша модель hitstun)

Startup подано **в еталонній конвенції** (з першим активним). Колонка «→ MoveData» вже переведена: `−1`.

| клас | startup ref → MoveData | active | recovery | на хіт | на блок | hitstun | blockstun | hitstop | рядки |
|---|---|---|---|---|---|---|---|---|---|
| легкий стоячи | 4–7 → **3–6** | 2–5 | 7–13 | +1…+5 | −4…−1 | 12–16 | 7–11 | 6–12 (SF6 мода 9) | S1–S3, G1–G2, G9 рів. 0–1, D1–D4 |
| важкий стоячи | 10–14 → **9–13** | 3–7 | 16–23 | −5…+9 | −8…+1 | 20–33 | 15–24 | 13–16 | S4–S9, G5–G6, G9 рів. 4, D1–D3 рів. 3–4, D6 |
| легкий у присіді | 4–6 → **3–5** | 2–4 | 10–14 | 0…+3 | −3…0 | 12–15 | 10–11 | 9–12 | S10–S12, G3–G4, G9 рів. 1, D5 |
| повітряний (важкий) | 9–13 → **8–12** | 4–6 | приземлення: 3 кадри (SF6) | залежить від висоти | залежить від висоти | 19–20 | 15 | 12–13 | S13–S15, G7–G8, D7 |

Розкид hitstop між іграми великий (DBFZ L 6 проти GGST L 11). Тому «правильного» hitstop для легкого еталони не дають:
**діапазон 6–12, UNGROUNDED як одне число**.

---

## 3. Рухи Choko і Skea проти еталонів

Наші значення — з `game/data/characters/{choko,skea}.tres` (команда: `grep -nE '^(startup|active|recovery|hitstun|blockstun|hitstop)' …`).
«Перевага» пораховано SF6-формулою (§0). ✓ — у діапазоні §2, ✗ — поза ним.

| рух | наші s/a/r | hitstun / blockstun / hitstop | перевага хіт / блок | проти §2 | діапазон еталона для MoveData | рядки |
|---|---|---|---|---|---|---|
| Choko `light` Shuka Jab | 5/3/9 | 14 / 8 / **4** | +2 / −4 | s ✓ a ✓ r ✓ · hitstun ✓ · blockstun ✓ · блок на межі · **hitstop ✗ (нижче 6)** | startup 3–6, a 2–5, r 7–13, hitstun 12–16, blockstun 7–11, hitstop 6–12 | S1–S3, G1–G2, D4 |
| Skea `light` Jab→Elbow | 4/3/8 | 13 / 7 / **3** | +2 / −4 | s ✓ a ✓ r ✓ · hitstun ✓ · blockstun ✓ · блок на межі · **hitstop ✗** | те саме | S1–S3, G1–G2, D4 |
| Choko `heavy` Emerald Arc | 11/4/17 | 20 / **12** / **7** | −1 / **−9** | s ✓ a ✓ r ✓ · hitstun на нижній межі · **blockstun ✗ (нижче 15)** · **hitstop ✗ (нижче 13)** · **блок ✗ (−9 < −8)** | startup 9–13, a 3–7, r 16–23, hitstun 20–33, blockstun 15–24, hitstop 13–16 | S4–S9, G5–G6, D6, G9 рів. 4 |
| Skea `heavy` Roundhouse | 11/4/18 | 20 / **12** / **7** | −2 / **−10** | як у Choko. −10 — це рівно поріг «punishable» у Tekken (T6) | те саме | S4–S9, G5–G6, T6 |
| Choko `crouch_light` Low Cut | 6/3/11 | 13 / **8** / 4 | **−1** / **−6** | **startup ✗ (6 > 5)** · a ✓ r ✓ · hitstun ✓ · **blockstun ✗ (нижче 10)** · **хіт ✗, блок ✗** · hitstop ✗ | startup 3–5, a 2–4, r 10–14, hitstun 12–15, blockstun 10–11, hitstop 9–12 | S10–S12, G3–G4, D5 |
| Skea `crouch_light` Low Kick | 6/3/11 | 13 / **8** / 4 | **−1** / **−6** | як у Choko | те саме | S10–S12, G3–G4, D5 |
| Choko `air_light` Dive Kick | 7/5/12 | 16 / 9 / 5 | залежить від приземлення | startup ✓ (8–12) · a ✓ · hitstun нижче 19 · blockstun нижче 15 · hitstop нижче 12 | **частковий еталон**: зібрано лише повітряні *важкі* (j.HP/j.H). Еталону повітряного легкого немає | S13–S15, G7–G8, D7 |
| Skea `air_light` Flying Knee | 6/5/12 | 16 / 9 / 6 | залежить від приземлення | startup ✗ (6 < 8, якщо порівнювати з важкими), решта як у Choko | те саме | те саме |
| `throw_move` Hook Pull (обидва) | 8/2/14, hitstun 22 | — | — | **немає порівнянного еталона**: наш кидок — підтягування на 14 м, а не кидок впритул | лише довідково: кидок SF6 5/3/30 total, tech-вікно 9 | S20–S21 |
| скіли й ульти (`record`, `time_stop`, `sword_storm`, `kunai_rain`, `shadow_veil`, `grimoire`) | — | — | — | **UNGROUNDED**: еталон для унікальних ефектів не збирався. Кулдауни й контроль регулює внутрішнє правило [[03-Skills-Framework]] § Балансні рамки, не зовнішнє джерело | — | — |

**Що випадає системно** (факт порівняння, не рекомендація):
1. **hitstop** у всіх нормалей у 1.5–3 рази нижчий за еталонні діапазони (наші 3–7 проти 6–16).
2. **blockstun** важких і присідних нижчий, тому важкі на блоці −9/−10, присідні −6. В еталонах −8…+1 і −3…0.
3. **startup присідного** 6 (ref 7) повільніший за всі 2D-еталони присідного легкого (ref 4–6).

Числа для повітряного легкого, кидка й скілів лишаються відкритими.

---

## 4. Таблиця для перенесення: поле MoveData → діапазон → джерело

Діапазони — з §2, вже в одиницях MoveData. «—» означає, що еталона немає й поле лишається за дизайном Ареса.

| поле `MoveData` | light | heavy | crouch_light | air_light | джерело |
|---|---|---|---|---|---|
| `startup` | 3–6 | 9–13 | 3–5 | 8–12 (з важких j.H) | §0 переклад; S1–S15, G1–G8, D4–D7 |
| `active` | 2–5 | 3–7 | 2–4 | 4–6 | те саме |
| `recovery` | 7–13 | 16–23 | 10–14 | у еталонах — приземлення 3 (SF6); у нас рух обривається на землі (`Fighter.gd:581–585`) | те саме |
| `hitstun` | 12–16 | 20–33 | 12–15 | 19–20 | S-рядки; G9; D1 |
| `blockstun` | 7–11 | 15–24 | 10–11 | 15 | S-рядки; G9; D2 |
| ціль «на блок» (виводить blockstun) | −4…−1 | −8…+1 (3D-поріг: −9 safe, −10 punishable) | −3…0 | — | S, G, D; T6 |
| `hitstop` | 6–12 (одного числа немає, UNGROUNDED) | 13–16 | 9–12 | 12–13 | S17, G9, D3 |
| `cancel_tier` / вікно | SF6: вікно від влучання 11–15, мода 13. GGST: P/K у спешал лише в active. У нас — від кінця active до кінця recovery + буфер 6 | GGST: H скасовується і в recovery | як light | — | S18–S19, G10, код §0 |
| `chip_damage`, `damage`, `knockback`, `hitbox_*`, `meter_*`, `cooldown`, `forward_step`, `ragdoll_impulse` | — | — | — | — | одиниці й шкали ігор несумірні з нашими. Правила відсотків HP — внутрішні, [[03-Skills-Framework]] |
| буфер вводу (`InputRouter.BUFFER_FRAMES` = 6, не MoveData) | SF6: 5-кадрове вікно (4 наперед) | | | | S22 |

**Формула, щоб вивести blockstun/hitstun із цільової переваги** (SF6-конвенція, §0):
`blockstun = adv_блок + active + recovery`, `hitstun = adv_хіт + active + recovery`. Для нашого рушія, можливо, −1.
Поправку дасть замір Гефеста.

---

## 5. Гарпун: що задокументовано публічно

| # | гра · параметр | значення | джерело | версія/дата | статус |
|---|---|---|---|---|---|
| H1 | Apex, Pathfinder: довжина | «21 meters» | https://apexlegends.wiki.gg/wiki/Pathfinder + fandom | рев. 2026-07-06 / 2025-02-18 | **дві вікі збігаються** |
| H2 | Apex: кулдаун | wiki.gg 20 с, 2 заряди; fandom 30 с з масштабуванням за дистанцією | там само | залежить від патча | **UNGROUNDED** (20 проти 30) |
| H3 | Apex: свінг | «disconnect after swinging to a 90° angle, and you will keep your momentum» | обидві вікі | — | момент зберігається |
| H4 | Titanfall 2: довжина | `grapple_maxLength 1100` (од. рушія) | github.com/Syampuuh/Titanfall2 `scripts/weapons/mp_ability_grapple.txt` | коміт `9bfcea43ec`, 2018-01-19 | датамайн. **У метрах — UNGROUNDED** (27.9 м за 1 од.=1″, 20.96 м за 0.75″; масштаб Respawn не підтверджено) |
| H5 | TF2: заряд | power 50 на постріл, регенерація 3/с після затримки 3 с → 50/3 ≈ 16.7 с на заряд | `pilot_base.set`, там само | 2018 | розрахунок із датамайну; патч «one charge and recharges faster» без чисел |
| H6 | TF2: гравітація у свінгу | `grapple_gravityFracMin 0.25` / `Max 0.7` від звичайної | там само | 2018 | — |
| H7 | TF2: відрив | «detach if/when the grapple point leaves the pilot's line of sight» | https://titanfall.fandom.com/wiki/Grapple | вікітекст 2026-10-03 | — |
| H8 | Just Cause 2: дальність | «within 80 meters» | https://justcause.fandom.com/wiki/Grappling_hook | 2026-10-03 | фан-вікі без джерела |
| H9 | JC3/4: швидкість | до 160 м/с з модами, «reportedly» | там само | — | не підтверджено |
| H10 | JC3: 84.5 м | — | лише пошуковий витяг gamefaqs | — | **UNGROUNDED** |
| H11 | Spider-Man 2 (2004): мотузка | desiredLength + currentLength, що «continually tries to approach» desiredLength; тетер як «virtual circle or sphere» | Jamie Fristrom, https://code.tutsplus.com/swinging-physics-for-player-movement-as-seen-in-spider-man-2-and-energy-hook--gamedev-8782t | 2013-06-05 | — |
| H12 | Spider-Man (Insomniac 2018) | лише опис сесії GDC 2019 «Concrete Jungle Gym» (Doug Sheahan): камера підкреслює швидкість | https://gdcvault.com/play/1026422/Concrete-Jungle-Gym-Building-Traversal | 2019 | **чисел немає**, відео не переглянуте |
| H13 | Sekiro | — | fextralife повернув порожню сторінку | — | **UNGROUNDED** |

**Наш гарпун поруч** (`GrappleHook.gd`):

| параметр | значення | рядок |
|---|---|---|
| `range_m` | 14.0 | `:21` |
| заряд | `cooldown` 3.0 с | `:18` |
| `ZIP_FRAMES` | 12 | `:12` |
| `zip_accel` | 70 | `:23` |
| `max_speed` | 26 | `:25` |
| `release_boost` | 1.15 | `:24` |
| `reel_speed` | 9 | `:22` |
| `steer_accel` | 14 | `:26` |
| гравітація у свінгу | `Fighter.GRAVITY` 24 × 0.9 | `:159`; `Fighter.gd:21` |

Для порівняння з еталонами:
- дальність: Apex 21 м (H1);
- частка гравітації у свінгу: TF2 0.25–0.7 (H6);
- час на заряд: TF2 ≈ 16.7 с (H5), Apex 20–30 с (H2).

Ці числа з шутерів/екшенів з одним гравцем, а не з файтингу 1×1. Порівняння довідкове.

**Поправка до попереднього брифу.** Твердження «Spider-Man 2 (2004): гравітація ~10× земної» з
[[2026-10-02-Grapple-Input-UI]] у статті Фрістрома **не знайдено**. Далі на нього не спиратися, доки не знайдеться першоджерело.

## 6. Дрон-якір: пружна реакція на тягу (ADR-011, лише презентація)

Модель «натяг → провис → хитання → повернення» — це затухаюче коливання другого порядку. Параметри й формули:

| # | що | значення / формула | джерело | версія/дата |
|---|---|---|---|---|
| P1 | недодемпфований режим (є хитання) | `0 ≤ ζ < 1` «overshoots it and continues to oscillate»; `α = ω√(1−ζ²)` | Ryan Juckett, https://www.ryanjuckett.com/damped-springs/ | 2012-07-20 |
| P2 | параметризація для дизайнера | частота в Гц + «fraction of oscillation magnitude reduced over a specific duration»; огинаюча `exp(−ζωt)` → `ζ = −ln(p_d)/(ω·t_d)`. Приклад автора: «decrease by 90% every 0.5 second… frequency 2Hz» | Allen Chou, https://allenchou.net/2015/04/game-math-precise-control-over-numeric-springing/ | 2015-04-08 |
| P3 | частота → жорсткість | `stiffness = (2π·f)²`, `damping = ratio·2·√stiffness` | Daniel Holden, https://theorangeduck.com/page/spring-roll-call | 2021-03-04 |
| P4 | f/ζ/r-модель t3ssel8r | `k1 = ζ/(π f)`, `k2 = 1/(2π f)²`, `k3 = r·ζ/(2π f)`; r > 1 — «overshoots target at first», r < 0 — «anticipates»; стабільний крок `sqrt(4·k2 + k1²) − k1` | відео https://www.youtube.com/watch?v=KPoeNZZ6H4s (2022-06-29); формули з порту https://codeberg.org/reinis_games/spring_motion `src/lib.rs` | формули з відео не звірено, приклади значень із відео **не перевірено** |
| P5 | час встановлення 2 % | `Ts = −ln(0.02)/(ζ ωn) ≈ 3.9/(ζ ωn)` | https://en.wikipedia.org/wiki/Settling_time | рев. 2026-09-02 |
| P6 | перерегулювання | `PO = 100·exp(−ζπ/√(1−ζ²))` | https://en.wikipedia.org/wiki/Overshoot_(signal) | рев. 2026-06-26 |
| P7 | Godot `SpringBoneSimulator3D` | є з 4.4. Дефолти 4.7: `stiffness 1.0`, `drag 0.4`. Інтегратор Verlet, drag за крок, тож **це не ζ/ω і залежить від dt**. Лише для кісток `Skeleton3D` | сирці `godot 4.7-stable` `scene/3d/spring_bone_simulator_3d.{h,cpp}` (h:101–104, 132–140; cpp:1834–1835) | 4.7-stable |
| P8 | Godot `Generic6DOFJoint3D` кутова пружина | дефолти 0 / вимкнено. Це фізичний джойнт, а якір за [[ADR-004-Physics-Is-Presentation]] — презентація. Доречність сумнівна | `doc/classes/Generic6DOFJoint3D.xml:193–209` | 4.7-stable |

**Сітка розрахунку за P5–P6** (python суб-агента; це обчислення, **не рекомендація**). Рядки сітки обрано довільно, щоб
показати форму залежності:

| f, Гц | ζ = 0.3 | ζ = 0.4 | ζ = 0.5 |
|---|---|---|---|
| 1.5 | Ts 1.38 с · PO 37 % | 1.04 с · 25 % | 0.83 с · 16 % |
| 2.0 | 1.04 с · 37 % | 0.78 с · 25 % | 0.62 с · 16 % |
| 3.0 | 0.69 с · 37 % | 0.52 с · 25 % | 0.42 с · 16 % |

**Межа нахилу реального мультиротора** (PX4, документація і сирці збігаються; https://docs.px4.io/main/en/advanced_config/parameter_reference.html,
`src/modules/mc_pos_control/multicopter_position_control_limits_params.yaml:48–60`, PX4 main `1ca4506927` від 2026-10-02, реліз v1.17.0):

| параметр | дефолт | діапазон | що означає |
|---|---|---|---|
| `MPC_TILTMAX_AIR` | **45°** | 20–89 | абсолютний максимум для автоматичних режимів |
| `MPC_MAN_TILT_MAX` | 35° | — | ручний режим |
| `MPC_XY_P` | 0.95 | — | «m/s per m position error» |

Для «дрон утримує позицію» візуальний нахил ≤ 45° відповідає реальній техніці. Це межа для звірки, а не вимога.

---

## Відкрите

1. **Замір рушія.** Пересування на ±1 кадр (§0) — читання коду, не замір. Потрібен smoke-кейс Гефеста: light Choko в
   блок → виміряти, через скільки тіків кожен може діяти. Без цього таблиця §4 дає діапазони з точністю ±1.
2. **Naruto Storm** — немає кадрових даних (UNGROUNDED). Замір із відео — окрема задача.
3. **Повітряний легкий, blockstop, кидок-підтягування, скіли/ульти** — еталона не зібрано.
4. **Метри Titanfall 2** (H4) і **кулдаун Apex** (H2) — UNGROUNDED.
5. **Spider-Man**: числа з GDC-доповідей (потрібен транскрипт). Твердження «~10× гравітації» з брифу 2026-10-02 не підтверджене.
6. **Вибір** чисел, f/ζ для дрона і того, чи підтягувати hitstop/blockstun до еталонів, — **Арес**. Реалізація
   пружини дрона — Гефест ([[ADR-011-Diegetic-Grapple-Anchors]] § Наслідки).

## Related
- [[02-Combat-System]] · [[03-Skills-Framework]] · [[04-Grapple-System]] · [[08-Balance]]
- [[ADR-004-Physics-Is-Presentation]] · [[ADR-005-Grapple-Charges]] · [[ADR-011-Diegetic-Grapple-Anchors]] · [[Stage-River]]
- [[2026-10-02-Grapple-Input-UI]] · [[2026-10-02-Engine-Physics]] · [[Choko]] · [[Skea]] · [[state]]
