# Чуйна міська мотузка

**Дата:** 2026-10-05 · **Роль:** T2 Гефест · **Статус:** фінальна інтеграція Godot 4.7 перевірена, 79 сценаріїв / 0 failures.

План [[2026-10-05-Responsive-Parkour]] звірено з `GrappleHook.gd`,
`CityFighter.gd`, `MatchRopes.gd`, grapple GDD та трьома наявними regression
скриптами. Причина сповільнення в коді: загальний 30-tick замах гасив
горизонтальний рух з 30 м/с²; міський рух використовував той самий профіль.

## Зміна

`GrappleHook.responsive_parkour` вимкнено за замовчуванням; міський адаптер
вмикає його явно. Профіль діє тільки для `grapple_parkour`, не ворожого
пострілу. Замах 10 ticks зберігає горизонтальну швидкість; політ 48 м/с,
reel 3.6 м/с, pump 9 м/с², drag 0.30 с⁻¹. Ці нові числа — **PLACEHOLDER**.
Змінено exports, не дані бойових кадрів. Додано `reel_remaining()` для HUD.

Збережено bounded reel 1.2 м, minimum 2 м, speed cap 11 м/с, speed ratio .85,
досяжність руки .70 м, справжній swept контакт, solid collision, атомарний
deploy та запас кінцевих token. Скорочення мотузки не переходить у радіальний
імпульс. MatchRopes не змінено.

## Перевірка

Предмет: для всіх профілів міського й дуельного зачеплення прискорений відгук
не дозволяє безконтактну опору, безмежне моторне піднімання або створення
швидкості/запасу при відчепленні.

Команди: `godot --headless --path game --fixed-fps 60 --script
../tools/grapple/{traversal_check,weighted_swing_check,harpoon_check,contact_check}.gd`.
Умова: завершальний sentinel з нулем failures та чистий runtime журнал;
провал блокує передачу й вимагає виправлення.

Три форми негативного контролю: перешкода/вихід із reach; довге утримання
мотора й підкачування короткої/довгої мотузки; default duel та city enemy
постріли, що не мають успадковувати швидкий профіль.

Перший запуск runtime зупинився до сценарію через недоступний стандартний
user data каталог і engine crash. Повтор використовує окремі writable XDG
каталоги в `/tmp`. Доступний binary — Godot 4.6.3, ціль проєкту 4.7;
це явна межа цього локального доказу. Автоматичні зміни чотирьох tracked
`.glb.import` від старішого імпортера відновлено.

Focused результати цієї сесії (усі exit 0, без `ERROR`/`WARNING`):

| Сценарій | Перевірки / failures | Доказ |
|---|---|---|
| Traversal | 53 / 0 | `responsive-parkour/rope/traversal.log` |
| Weighted swing | 37 / 0 | `responsive-parkour/rope/weighted-swing.log` |
| Harpoon | 56 / 0 | `responsive-parkour/rope/harpoon.log` |
| Rope contact | 92 / 0 | `responsive-parkour/rope/contact.log` |

Абсолютний корінь raw-доказів — `/workspace/nooneisreal-evidence/`.
На однаковій мішені та початковій швидкості 5 м/с замах дуель/місто склав
30/10 ticks, підтверджений контакт — 45/18 ticks. Це вимір сценарію,
не універсальна гарантія часу до будь-якого якоря. Міський stroke 1.2 м
завершується за 20 ticks без наступного вертикального імпульсу; тривале
утримання не скорочує мотузку далі. `git diff --check` також чистий.

CityFighter окремої смуги фактично вмикає flag після `super._ready()`;
цей зв’язок прочитано в поточному файлі. Анімаційне приймання, повні
`make check`/`make gates`/playable та цільовий Godot 4.7 не зараховано
цими focused журналами. Godot слот передано T8 після закінчення всіх процесів.

## Постійна інтеграційна батарея

За окремим дорученням координатора до `tools/gates/playable_check.sh`
додано `tools/parkour/city_parkour_check.gd` та
`tools/animation/parkour_motion_check.gd`. Власники обох смуг підтвердили
шляхи, стандартний exit 0 і sentinels `CITY_PARKOUR_COMPLETE` /
`PARKOUR_MOTION_COMPLETE`; ці рядки також звірено у файлах. Кожен запис
вимагає ненульової кількості перевірок, нуля failures та відсутності runtime
errors через чинний серійний runner. Frame cap сам по собі не є успіхом.

`bash -n` і Python AST parse пройдено; всі 66 базових script paths існують.
Разом із 12 чинними mutation cases батарея тепер містить 78 сценаріїв.
Це статична перевірка проводки, не заява про виконання нових сценаріїв.
На цій передачі `git diff --name-only -- '*.import'` порожній.

## Фінальна інтеграція на цільовому Godot 4.7

Після початкової передачі додано ще `city-hook-gear`: чинна серійна батарея
має **79 сценаріїв**. T2 особисто перечитав фінальні raw-журнали в
`/workspace/nooneisreal-evidence/responsive-parkour/validation/`:

- `review-check.log/.rc`: rc0, smoke **164 / 19 847 кадрів**, 109 скриптів без parse failures.
- `review-gates.log/.rc`: rc0, зелена батарея, **175/175 assets**.
- `playable-final.log/.rc`: rc0, **79 сценаріїв / 0 failures**; окремі 79 logs
  без WARNING/SCRIPT ERROR та неочікуваних runtime errors. Навмисні assertions
  у mutation-сценаріях лишаються частиною перевірки їхніх guards.

У фінальній батареї rope traversal **53/0**, weighted swing **37/0**,
harpoon **56/0**, contact **92/0**. Повтор підтверджує попередній вимір
launch **30→10 ticks** та contact **45→18 ticks** вже на цільовому движку.
Нові механіка/анімація також пройшли: city parkour **73/0**, parkour motion
**15 466/0**, city hook gear **2 978/0, 276 poses**, hero gear **7 930/0**.

Перший aggregate **78/2** збережено в `playable.log`; він не зарахований.
Після виявлення контакту Skea forearm із тканиною та витоку audio teardown
fixture відповідні власники виправили причини й виконали повний повтор.
Деталі — [[2026-10-05-Parkour-Motion]] та [[2026-10-05-City-Parkour]].
T4 before/after та фінальний source manifest мають однаковий digest
`ff65c07d15eae5b17b236c29ff981577de44edf6b6d110e36488cf4574f1e444`.
Змін `.import` у фінальному diff немає. Native scope й обмеження —
[[2026-10-05-Parkour-Visual-Audit]]; M3 feel/FPS тут не заявлені.

## Related

- [[2026-10-05-Responsive-Parkour]] · [[2026-10-05-Responsive-Parkour-Session]] · [[04-Grapple-System]] · [[2026-10-05-Rope-Contact-Range]]
