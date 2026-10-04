# Видимі пози семи рухів і напрямки ходи

2026-10-04 · T2 Гефест · bounded реалізація за дозволом Santos, переданим T1.

## Аудит і вибір

Перевірено `SkeletalRig.gd`, `RigAnimator.gd`, обидва character `.tres` та інвентар T3
`/workspace/nooneisreal-env/audit/t3/clips.tsv`: UAL1 Source має 120 записів, UAL2 — 134.
Сім рухів без `anim_clip` раніше малювали stance. Водночас `RigAnimator._attack_pose`
вже містить спеціальні пози цих рухів, які були приховані разом із капсулами.

Варіанти: залишити stance; підставити приблизний UAL attack/spell; перенести наявну
семантичну процедурну позу. Вибрано третій: wristwatch не стає заклинанням, low kick
не стає високим ударом, а grimoire зберігає власний жест. Погляди: новачку потрібна
видима дія; досвідченому — збережені фази; аніматору — чесний намір і силует;
rollback-інженеру — незмінний combat root; слабкому пристрою — обмежена робота з
13 кістками; тілу як механічній істоті — збережені довжини сегментів без розтягування.

## Явна матриця fallback

| Герой / move ID | Джерело руху | Видима дія |
|---|---|---|
| Choko / crouch_light | RigAnimator `crouch_light` | присід і короткий правий удар |
| Choko / record | RigAnimator `watch` | підняте ліве зап'ястя й нахил голови |
| Choko / time_stop | RigAnimator `watch` | той самий мотив годинника, власні бойові фази |
| Skea / low_kick | RigAnimator `low_kick` | низький правий удар ногою, неглибокий присід |
| Skea / shadow_veil | RigAnimator `veil` | асиметричні руки, присід, розворот таза |
| Skea / cursed_grimoire | RigAnimator `book` | дві руки, піднята голова, авторський вертикальний offset |
| Skea / cursed_grimoire_veil | RigAnimator `book` | той самий мотив книги, власні довші бойові фази |

`ProceduralMotionFallback` активний лише в ATTACK, без регдола, для точного character ID
і move ID та лише коли `anim_clip` порожній. Новий явно авторизований кліп автоматично
має пріоритет. Незнайомі рухи не отримують довільної підміни.

Пози капсул уже містять authored anticipation, stepped timing, first-active/recovery
keys і spin. Повні обертання переносяться в систему UAL через rest alignment;
зберігаються довжини UAL, потім працює чинний retarget на героя. Вертикальний offset
масштабується від нейтральної висоти таза капсул 0.95 м (`RigAnimator.setup`).
Горизонтальний root, hitbox, frame data, reach, damage і таймери не записуються.
Чинні UAL атаки та їхні `contact_time` не змінюються. UAL root має повернуту
систему координат; вертикальний offset переводиться в локальний базис батька таза,
а не додається до local Y. Це виправлено після кадру crouch, який показав зависання.

Хода використовує 8 наявних Source кліпів, сектор визначається швидкістю відносно
forward бійця, а не камери. Зміна напрямку в WALK змінює кліп без скидання лічильника
ходи. Choko і Skea зберігають свої idle/dash/getup та Sketch-Cel матеріали.

## Перевірка

Предмет: для всіх семи fallback рухів видима поза відповідає наявному семантичному
джерелу; для всіх явно заданих кліпів зберігається first-active contact та chain parity.

Команда: `$GODOT_BIN --headless --path game -s $PWD/tools/animation/character_motion_check.gd`.
Успіх: 0 failures, код 0. При провалі — виправити bridge/selector, не frame data.
Тест перевіряє 8 секторів у трьох facing, imported clip names, first-active contact
для парних/непарних атак, seven fallback coverage, зміну startup/contact drawing,
відповідність напрямків capsule→UAL, hero aim error <3°, snapshot combat-полів,
freeze/hitstop та зміну напрямку всередині WALK. Три негативні форми selector:
чужий герой, невідомий ID, наявний authored clip замість fallback.

Головний агент послідовно запустив Godot: `CHARACTER MOTION: 818 checks, 0 failures`,
чистий `playable/logs/motion.log` до перевірки стоп. Візуальна проба знайшла помилку
local/global offset таза; її виправлено, додано 42 assertions вертикального offset
та відсутності горизонтального зсуву. Повторний runtime/захват **очікується**. Повні `make check` / `make gates` лишаються його
загальним гейтом. Новий тест не доводить природність руху: потрібні кадри/відео
на обох героях. Зовнішній `playable/render/motion_capture.gd` готує 32 кадри
startup/contact/recovery/idle-return семи рухів і reference idle/light на сухій Bazaar;
боєм/CPU під час діагностичного захвату керує сценарій, файли балансу не змінюються.
Для огляду ніг сценарій ховає геометрію Bazaar поза героями та додає нейтральну
підлогу; світло й риги залишаються арени. Фази прокручуються послідовно, idle-return
знімається після повного recovery. Позначка contact означає перший active frame;
перевірка donor aim не доводить точного фізичного контакту кисті/зброї з ціллю.

## Межі та ризики

Це перенесення наявних procedural drawings, не нові mocap-кліпи. Немає IK, foot planting,
м'язової симуляції або corrective morphs. Rest alignment не виправляє скінінг і хват;
кисті/стопи зберігають rest-відношення до передпліччя/гомілки у fallback, тому потрібна
візуальна перевірка. Нижні кінцівки можуть ковзати через відмінні пропорції героя.
Перехід procedural→UAL лишається різким; загальний smoothing навмисно не додавався
без доказу збереження контактних поз. Directional dash також лишився авторським:
бібліотека має lateral dodge, але назва не доводить потрібний контакт/напрям для
forward/backward flash або roll. Окремий новий reaction layer не додавався; bridge
читає чинні capsule pivots лише під час семи fallback дій.

## Related

- [[2026-10-03-launch-4-mannequin]] · [[2026-10-03-launch-5-heroes]]
- [[02-Combat-System]] · [[ADR-004-Physics-Is-Presentation]] · [[Animation-Plan]]
