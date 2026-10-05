# Виразні герої та чуйна бойовка

**Дата:** 2026-10-05 · **Роль:** T1 Дедал · **Статус:** `done`
**Виріс з:** прямого доручення Santos поліпшити текстури, міміку й модель героїв та додатково бойовку; [[2026-10-05-Expressive-Heroes-Session]], [[ADR-019-Audit-And-Many-Views-Before-Decision]]. Старіший двигун дозволено розглянути лише за доведеної користі й без втрати гри.

## Аудит і погляди

| Факт | Джерело | Наслідок |
|---|---|---|
| Попередній паркур перевірено 79/0, зміни збережено локально | Checkpoint `94a09a6`, receipt у `responsive-parkour/validation/checkpoint.json`; 764 game/tools тотожні прийнятому manifest | Нова гілка `codex/character-expression-combat`; оригінали не перезаписувати |
| Обидва GLB мають 24 joints, один atlas JPEG 2048², нуль morph targets і окремих eye/lid/jaw bones | Незалежне читання GLB T2/T3 | Статичний вираз не лікується версією Godot; потрібні нові контрольовані facial features |
| Великі білі плями худі Skea запечені в atlas | Витягнуті вихідні байти й огляд T6/T1; shader має specular_disabled | Локальна корекція саме тканини, із захистом шкіри/взуття/волосся/емблем |
| InputRouter тримає натискання 6 ticks, hitstop триває 6–16 | Читання T2/T5 Fighter/InputRouter; actual-hit cancels вже існують | Натискання комбінації на контакті може зникнути; потрібний bounded continuation intent |
| Grounded HITSTUN повертає IDLE попри утриманий block; BLOCKSTUN уже відновлює BLOCK | Аудит T2 | Узгодити перший дозволений tick без скорочення stun |
| Проєкт не має game/addons; готові face controls у вихідних моделях відсутні | Аудит T3 | Downgrade не додає міміку або контент; потрібні конкретні сумісні інструменти, а не припущення |

| Варіант | Виграш і ризик | Вибір |
|---|---|---|
| Лише підсилити колір, блиск і hit FX | Швидко, але статичні обличчя й пропущені натискання лишаються | Відхилено |
| Зберегти героїв, додати виміряні facial surface controls, локально виправити матеріали та бойовий buffer | Видимий і функціональний результат із збереженням rig/UV/бою/паркуру; потребує close render і строгих масок | Обрано |
| Замінити моделі й двигун заради бібліотек | Дороге перенесення rig/LOD/контактів/export; немає доведеної потреби | Не обрано; лише окремий probe за конкретного blocker |

| Погляд | Критерій |
|---|---|
| Santos/автор | Ідентичність Choko/Skea, власний Sketch-Cel, виразні обличчя без аніме-глянцю |
| Новачок | Натискання наступного удару на контакті не губиться, вираз читається |
| Досвідчений гравець | Whiff/block punish, tiers, шкода й frame data залишаються визначеними |
| Суперник | Немає додаткової невразливості, четвертого combo hit чи прихованого автокомбо |
| Художник | Native front/3⁄4/близька й ігрова відстань; маски не зафарбовують захищену анатомію |
| Аніматор | Нейтральна модель збережена; детерміновані blink/focus/hurt, без маскування відсутнього face rig |
| Інженер/Mac-гравець | Контрольний commit, збережені UV/skin/LOD/експорт, одна версія Godot до доведеної вигоди міграції |

## Кроки

| # | Власник і файли | Дія | Ризик | Перевірка |
|---|---|---|---|---|
| 1 | T3 `docs/Research/2026-10-05-Hero-Tools-And-Engine-Compatibility.md` | Зіставити конкретні facial/animation/AI tools і версії з офіційними джерелами | Хибна обіцянка сумісності | Збережені джерела/дати; жодного імпорту старим editor у production |
| 2 | T6 `docs/Art/`; T2 material helper/`hero_garment.gdshader` | Огляд before, bounded cloth de-light та читабельність матеріалів | Зміна шкіри, символів і white accents | Захищені regions, native before/after, gear/mask/camera regressions |
| 3 | T2 `HeroFacePresentation` і вузька інтеграція `SkeletalRig` | Виміряні surface features/вирази: blink, focus, hit/KO; розмовна міміка лише за справжнього semantic event | Наклейки над обличчям, double features, проникнення, stale state | Actual face regions, head-pose attachment, isolation, freeze/reset, повторні callbacks, native close/front/3⁄4 |
| 4 | T5 GDD02; T2 `Fighter`, вузький input reset epoch, tests | Один pending limb intent лише actual-hit NORMAL під attack hitstop; чинне 6-tick вікно, guard після stun, очищення через pause/reset | Липкі натискання, hidden auto-combo, втрата generic recovery buffer | Реальні hitstop/light/heavy/block/whiff/3-hit/menu/reset/rewind сценарії |
| 5 | T4 `docs/Audit/`; T1 план/журнал | Незалежний огляд, регресії, finite negative controls і native-приймання | Хибне GREEN за старим source | `make check`, `make gates`, повний `tools/gates/playable_check.sh`, source hashes, raw sentinels |

## Межі та хендофи

Наявне доручення авторизує реалізацію цих видимих покращень. Paid provider generation не входить у поточний метод; canonical GLB/atlas не видаляються. Стилізовані поверхневі вирази не називаємо анатомічним face rig або audio lip sync. Якщо вони не проходять візуальне приймання, не приховувати це headfront-деформацією чи floating billboard; уточнити метод на реальних кадрах.

T2 animation володіє face helper і `SkeletalRig`; T2 materials узгоджує shader/vertex channels без перетину; T2 combat володіє Fighter/input mechanics; T5 — правила/числа. Godot у спільному checkout запускається послідовно за слотом координатора. Ізольована engine-копія не замінює production cache. Числа нового presentation — PLACEHOLDER до native/ігрового приймання. T1 закриває план тільки після перевірки кінцевого дерева.

## Завершення й докази

План закрито після особистого читання T1 фінальних raw-журналів та native кадрів. На Godot 4.7: `make check` — **112 GDS / 0**, smoke **164 перевірки / 19 847 кадрів**; `make gates` — зелена батарея, **175/175 assets**; повний playable — **81 сценарій / 0 відмов**, включно з усіма попередніми 79. Незалежні T4 mutation controls відхилили обхід input revision, повторний крок міміки на одному serial та перенесення тканини через захищені triangle boundaries.

Докази — `/workspace/nooneisreal-evidence/expressive-heroes/validation/`: `review-check.log`, `review-gates.log`, `playable-final.log`, 81 окремий raw-журнал та `final-raw-scan.json`. Неочікуваних errors/warnings/leaks немає. Після очікуваного створення Godot UID нового outline shader **779** game/tools файлів тотожні між незалежними перевірками й повним прогоном; digest `916816f998abde2b91315cbdf77092b16918c792cae6dfc19942f38e6bd8339b`.

T6 і T1 прийняли кінцеві native вирази й локальну корекцію матеріалів: **156 PNG**, незмінні 280 code/resource hashes до/після capture, 5-секундне демо й порівняння моделей у `/workspace/nooneisreal-evidence/face-combat/`. Це поверхнева міміка зі збереженням вихідної геометрії; частина білих atlas marks грудей/плеча Skea лишається. Відео показує face controller при утриманій позі тіла. Встановлення на Mac, FPS на M3, повноцінний facial rig і перемальовування всього атласу цим планом не заявлені. Godot 4.7 збережено за результатом дослідження сумісності.

## Related

- [[state]] · [[constitution]] · [[2026-10-05-Expressive-Heroes-Session]] · [[2026-10-05-Responsive-Parkour]] · [[Style-Guide]] · [[ADR-019-Audit-And-Many-Views-Before-Decision]]
