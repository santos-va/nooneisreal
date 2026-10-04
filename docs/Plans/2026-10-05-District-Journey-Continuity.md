# Продовження подорожі та зрозуміла ціль

2026-10-05 · T1 · **Статус: реалізовано, локальне приймання GREEN; PR #176 / GitHub CI очікується**. Пряме доручення Santos продовжувати незакриту роботу після [[2026-10-05-Playable-District]].

## Аудит і погляди

PR #175 змерджено в `d9d12ec`; нова гілка `codex/district-journey-continuity`. `CityWorld._ready()` завжди викликає restart_at(spawn), хоча меню пропонує продовження. `CityProgress.summary()` обирає перший active/ready за порядком JSON; журнал у CityHud є Label без вибору цілі. Персональні доручення/дружба/кольори вже збережені; попередні 57 сценаріїв і native докази не починаються заново.

| Варіант | Оцінка |
|---|---|
| Лишити spawn та автоматичну першу ціль | Безпечне, але неповне продовження подорожі |
| Зберігати довільну фізичну позу, мотузки й усе дерево світу | Відновлення в стіні/повітрі, складний та крихкий snapshot |
| Іменовані безпечні checkpoint-и + вибір доручення + орієнтир | Обрано: перевірюване продовження без нової симуляції |

Погляди: гравець повертається до відомого місця; другий герой має власний маршрут; старий save мігрує без втрати; новачок бачить напрямок/назву цілі; дослідник може зняти відстеження; користувач геймпада має доступні кнопки; зіпсований checkpoint не телепортує в довільні координати. Іконка за вибором Santos незмінна; ліцензії/DRM/нові герої не входять.

## Виконання й приймання

1. **CityJourney / CityWorld:** окремий per-hero save лише дозволених імен безпечних місць; checkpoint активується фізично на землі, без rope/airborne. Після reload — назване безпечне місце, очищений runtime руху; restart walk явно повертає на початок. Whitelist, atomic write, пошкоджений файл не перезаписується мовчки. Перевірка: реальний вихід/повторний вхід, hero isolation, old/malformed save, grounding/collision у кожній дозволеній точці.
2. **CityProgress:** явний tracked quest з backward-compatible optional field, вибір лише accepted active/ready, можливість вимкнути; completion не лишає stale marker. `CityQuestTargets` обчислює ціль із фактичних невиконаних goals і CityPlaces. Перевірка: усі шість доручень, повторна опора/мешканець не стають наступною ціллю, ready веде до замовника, save/reload/ізоляція героя.
3. **CityHud / CityQuestGuide:** доступний вибір у журналі з клавіатури/геймпада; назва/відстань/напрям до відстежуваної цілі, без перекриття гарпунної підказки. Орієнтир — напрямок, не обіцянка автоматичного маршруту крізь стіни. При паузі/діалозі і завершенні приховується. Native 1280×720/менше, orbit/front/behind/roof, actual menu focus.
4. **T4:** незалежний native resume у shop/roof, вибір/зміна/закриття tracking, input isolation, malicious save/content; `make check-playable` і `make gates`, релевантні probes, PR без self-merge. Публікацію попереднього main перевірити read-only.

Власність: journey-смуга — CityJourney/CityWorld; progress — CityProgress/CityQuestTargets; UI — CityHud/CityQuestGuide; review — незалежні probes/audit. Shared Godot лише один; агенти використовують ізольовані копії. Комітить координатор. Журнал [[2026-10-05-District-Journey-Session]].

## Related

- [[2026-10-05-Playable-District]] · [[2026-10-05-District-Life]] · [[2026-10-05-District-Delivery]] · [[2026-10-05-District-Journey-Session]] · [[state]]
