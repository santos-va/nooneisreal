# Архівна галерея та справжнє оглядове світло

**Дата:** 2026-10-05 · **Роль:** T2 Гефест · **Статус:** реалізація, scoped native та фінальні інтеграційні перевірки завершені.

Предмет: для обох героїв архівна галерея доступна без стрибків зі старого міського маршруту; копіювання дозволяється лише за фактичного напрямку й незатуленого променя до плити, а видима копія не перекриває майстерню.

## Звірка плану

[[2026-10-05-Lower-Mark-Expansion]] звірено з CityLayout, CityArchitecture, CityMaintenance та CityInteriors. Галерея стоїть на суцільному NW даху y4 у межах x−14,8…−10,8, z−17,2…−11,2. Це верхня тераса, а не нове підземелля. Вільний коридор x−16 з попереднього real-walk fixture збережено; current route_points не змінюються. Всі просторові й світлові числа — PLACEHOLDER.

## Реалізація й межі

CityDistrict створює CityLowerGallery. lower_points повертає lamp/plate Marker3D; set_lamp_aligned повертає видимий корпус ліхтаря разом зі справжнім SpotLight між двома фіксованими напрямками. Схема має три постійні фізичні знаки: двір, сходи, вежа. Вона не зникає в стані away і не є активними дверима. Plate shader/material, energy та експозиція не перемикаються під сюжет.

Чинний city_surface.light додає painted shaded term навіть за нульової ATTENUATION. Тому локальна плита та темні знаки використовують StandardMaterial3D зі справжнім attenuation на окремому visual layer8; SpotLight cull mask8 обмежує його плитою й blank receiver. Спільний shader міста не змінено. plate_is_lit перевіряє actual direction/range/cone/layers і фізичний ray до RoutePlate; це механічний guard, не вимір піксельної яскравості. Художнє приймання підтверджене окремою native away/toward парою нижче.

set_record_delivered показує або ховає паперову копію з тими самими трьома геометричними знаками у майстерні Лади. Позиція обчислена від CityPlaces.shops()[2].door +(1,55;1,8;7,73), справа від полиці та нижче настінного годинника. Копія не має collision. Ефективне завершення поточного сеансу передає сюжетна смуга; геометрія нічого не зберігає і не видає фактів. Немає нового asset, входу до катакомб чи зміни старого story save.

## Перевірки

tools/world/city_lower_gallery_check.gd веде Choko і Skea від штатного входу через східну рампу та міст до арки, ліхтаря й плити, потім до старого checkpoint вежі та західного спуску. Waypoint teleport немає. Окремі перевірки: actual beam→plate collider, однакові material/energy, back-wall LOS, copy persistence при away та hide при suppressed successor. Негативні форми: фізично повернутий light при старому aligned flag, disconnected receiver mask, вставлений справжній occluder. Попередні maintenance та full geometry fixtures також запускаються незмінними.

Godot **4.7.stable.official.5b4e0cb0f**: `lower-final.log` — **78/0**, `maintenance.log` — **74/0**, `old-geometry.log` — **1750/0**, усі rc0. T2 особисто прочитав повні logs: banner і completion sentinel, без warnings/errors/leaks. Перший lower fixture дав66/0; після додавання actual-light guards і трьох негативних форм —78/0. Glyphs копії орієнтовано під її справжню північну поверхню; фінальний78/0 повторено після цієї суто візуальної правки.

Evidence: `/workspace/nooneisreal-evidence/lower-mark/geometry/`; `.rc` і `receipt.json` містять фактичні completed process returncodes та SHA256 трьох файлів. Команди: official Godot `--headless --path game --fixed-fps 60 --script ../tools/world/<fixture>.gd`, кожна під timeout180. Новий fixture доводить механічний напрям променя та доступ, не GPU-читабельність плити: остання лишається native-прийманням T6.

## Вузька native-корекція стрілок

T6 та T1 відхилили напрям геометричних наконечників у `native/plate_toward.png`: на плиті вони розходилися вправо, хоча текст позначав ДВІР→СХОДИ→ВЕЖА. T2 особисто переглянув кадр. Відхилений CityLowerGallery SHA256 `9db9826b69e30644031341ed409caa6968b614bc49fc9337529b66d69a3cd53d`; після явного завершення capture поміняно лише знаки двох `arrow.rotation.x`. Collision, route, light/material/energy, UI та story незмінні. У копії немає таких mesh-arrowheads: три glyphs супроводжуються чинними текстовими →; T6 підтвердив правильний напрям.

Прийнятий T6/T1 SHA256 `195e62ca116c27c6101e99b684c91ae567ef7bd8c9af62fbf9dfd9c007a0ea22`; повторне native-приймання завершене. Доказ вузькості: `geometry/arrow-correction.diff` та `arrow-correction.json`, зворотна реконструкція двох знаків byte-exact відтворює SHA попереднього перевіреного source. Focused78 не повторювався для двох noncolliding rotations; фінальна повна батарея T1 перевірить інтегроване джерело.

## Фінальне scoped native-приймання

T2 особисто відкрив `native-final/plate_toward.png`, `plate_away.png` та `gallery_overview.png`: дві геометричні стрілки тепер спрямовані вправо за текстом, три знаки читаються при спрямованому світлі, вхід і новий простір видимі. Away має темну плиту; геометричні знаки та матеріал залишаються тими самими. T6/T1 прийняли цей обмежений художній результат.

T2 особисто прочитав raw: `native-final/native.log/.rc` — **21 frames / 0 failures**, rc0; `orphan-native/native.log/.rc` — **1 frame / 0 failures**, rc0. Обидва Compatibility llvmpipe журнали мають лише відоме VSync warning. До/після кожного capture byte-equal manifests із **793 sources**, які містять саме прийнятий195e62ca hash. Двознаковий delta повторно звірено реконструкцією попереднього9db9826b hash; інших змін geometry source під цим прийманням немає.

`native-final/light-and-copy-proof.json` фіксує однакові camera/material/energy й незалежну blank-patch ROI1140pixels: sRGB8 luma **0→136,618** при повороті actual forward **+Z→+X**. Visible copy false→true у майстерні, retained після away, усі story saves у цьому success fixture save_ok. Це підтверджує конкретний native fixture, не наскрізне ручне проходження чи M3 FPS. Фінальний runner85 T1 перевірено окремо нижче.

## Фінальна інтеграційна звірка

T2 особисто прочитав `/workspace/nooneisreal-evidence/lower-mark/validation/review-playable.log/.rc`: **85 сценаріїв / 0 failures**, rc0. Його фінальні case logs містять **city-lower-gallery78/0**, **city-maintenance74/0**, **city-geometry1750/0**, без warnings/errors/leaks у цих трьох позитивних випадках. Очікувані негативні сценарії runner мають навмисний rc1 і прийняті окремими assertions.

Особисто звірені check/gates logs і rc: smoke **164 checks / 19847 frames**, **116 GDS / 0 parse failures**, зелена батарея, обидва rc0. `review-source-native-final.json`, `review-source-before.json` та `review-source-after.json` byte-equal: **793 sources**, digest **`0beea2abbfde9b603487a1c8aa3084f0337d3e842ab0d772d701789e09b6b32c`**. Отже фінальний runner охоплює і прийнятий двознаковий glyph delta. Geometry Fix завершено; native/software та ручні/апаратні межі вище зберігаються.

## Related

- [[2026-10-05-Lower-Mark-Expansion]] · [[2026-10-05-Clocktower-Service-Court]] · [[2026-10-05-Lower-Mark-Visual]] · [[state]]
