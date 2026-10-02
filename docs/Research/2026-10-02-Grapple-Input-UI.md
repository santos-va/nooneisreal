# Ресерч — фізика свінгу, заряди, контролери, UI файтингу (2026-10-02)

**Роль:** T3 Архімед (суб-агент). Проксі закрив gamedeveloper.com, dustloop, Steam, Wikipedia; частина
фактів — із пошукових витягів. Три Godot-репо грапла прочитано в коді.

## 1. Spider-Man → гарпун

- Insomniac, GDC 2019 «Concrete Jungle Gym: Building Traversal in Marvel's Spider-Man» (Doug Sheahan): павутина чіпляється
  лише до геометрії (теговані якорі), вибір якоря за збереженням моменту; маятник + камера/FOV/анімація продають швидкість.
  Дієслова: hold R2 = свінг, відпускання внизу = швидкість, угорі = висота; X = Web Zip; L2+R2 = Point Launch. SM2 (2023): Swing Steering Assist 0–10.
- Treyarch, Spider-Man 2 (2004): raycast-якорі на будівлях, гравітація ~10× земної. Туторіал Фрістрома: тетер як невидима сфера-стіна.
- Математика (60 Гц, детерміновано): `L = clamp(|p−a|, 3, 25)`; `v += g·dt` (2–3×g); якщо `|p'−a| > L`: `p' = a + n·L`, `v −= max(0, v·n)·n`;
  реел `L −= reel·dt`; стік `v += steer·a·dt`; відпускання `v *= 1.10–1.20` (+2 м/с угору біля низу дуги).
- Для файтингу: якорі-маркери + raycast-фолбек; конус 30°, 6–25 м; свінг — якір ≥ 3 м вище; тап = зип 25–30 м/с, утримання = свінг,
  тап з ворогом у конусі = підтягування (кидок: не блокується, течиться, карається на вісі).
- Godot-репо: ivan-resetnikov/grappling-hook-3d (чистий зип), mujtaba-io/godot-grappling-hook (2D), Skyquakers/godot-rope3d (PinJoint — Jolt не підтримує
  bias/damping). **Рекомендація — кінематичний дистанс-констрейнт на `CharacterBody3D`** (зроблено в `GrappleHook.gd`).

## 2. Заряди

Tracer Blink 3×3 с послідовно; Pathfinder 10–35 с за дистанцією; Genshin Xiao 2×10 с; LoL ammo; Jett 1 + за кіли.
**Рекомендація:** 3 заряди, 3 с (180 кадрів) послідовно, пауза під час тетера, без локауту на нулі; піпси 12×12 dp під HP,
відновлюваний піп із радіальною розгорткою, відмова — тряска 4 кадри + глухий клік. → [[ADR-005-Grapple-Charges]]

## 3. Контролери

| гра | входів (без стіка) |
|---|---|
| Naruto Storm 4 | 13 (атака, чакра, сюрікен, стрибок, гард, заміна, 2 підтримки, R3, D-pad ×4) |
| DBFZ | 6 кнопок + акорди |
| Sparking! Zero | ~14 |
| Smash Ultimate | 5 |
| Brawlhalla (ПК/консолі/**мобільні**, один мувсет) | 5 (light, heavy, jump, dodge, throw) |
| Shadow Fight 3/4 | 4–5 |
| MK Mobile | 0 (тапи/свайпи) |

**Стеля — 8–9 дій.** Mac-клавіатура ≈ 6KRO, WASD і стрілки в різних зонах; блок на Shift; не чіпати ⌘, Ctrl+стрілки, F-клавіші, Caps.
Запропоновані мапи (прийняті в `project.godot`): P1 WASD/Space · F G · V · LShift · R · Q E · C; P2 стрілки// · K L · , · RShift · I · ; ' · . ;
пад: X/Y атаки, A стрибок, B деш, RB гард, RT гарпун, LB/LT скіли, D-pad ↑ ульт. Тач: Godot 4.7 `VirtualJoystick` + 5–6 кнопок 44–64 dp. → [[05-Platforms-Input]]

## 4. UI/UX

SF6: eye-tracking, усі ресурси внизу/на одній лінії; Strive: прості плашки на деталізованому фоні, критика рухомих індикаторів
і «сердець» як піпсів; P4A: SP 0–100 з числом; DBFZ: сітка 7×3. Тренування: frame meter, хітбокси, запис/відтворення, скидання.
Адаптація: текст ≥ 20–22 px @1080p, тач 44–48 dp + 8 dp, safe area (`DisplayServer.get_display_safe_area()` з перерахунком під stretch),
гліфи last-input-wins з deadzone. Ресурси: Kenney Input Prompts (CC0, Asset Library #2655), Xelu (CC0), Mr. Breakfast (CC0), Godot Input Prompts,
G.U.I.D.E, Kenney UI Theme, Godot-GameGUI, Virtual Joystick DX. → [[06-UI-UX]]

## Джерела (вибірка)

schedule2019.gdconf.com (Concrete Jungle Gym), code.tutsplus.com (Fristrom, Swinging Physics), thumbsticks.com (SM2 2004),
kitguru.net / mp1st.com (SM2 assist), overwatch.fandom.com (Tracer), dexerto.com (Pathfinder), genshin-impact.fandom.com (Charge),
gamefaqs (Storm 4 controls), dustloop.com (DBFZ, P4AU HUD), gamepressure.com (Sparking Zero), steamcommunity.com (Brawlhalla),
tcrf.net (SF6 UI design), eventhubs.com (Strive UI, DBFZ select), docs.godotengine.org (Jolt), github.com/godotengine/godot/issues/74835,
godotengine.org/releases/4.7 (VirtualJoystick), godotengine.org/asset-library/asset/2655.

## Related
- [[04-Grapple-System]] · [[05-Platforms-Input]] · [[06-UI-UX]] · [[ADR-005-Grapple-Charges]]
