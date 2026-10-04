# Пакет функціонального прототипу міста

Це робочий контракт до [[Plans/2026-10-04-City-First]], а не фінальний експорт міста. Джерело геометрії — `game/scripts/world/CityLayout.gd` і `CityDistrict.gd` разом із `CityArchitecture.gd` і `CityMarket.gd`; камера та освітлення — `CityWorld.gd` / `CityCamera.gd`.

`room-brief.json` фіксує габарити й межі прототипу; `openings.json` відрізняє центральний відкритий вхід від бічного критого проходу. `props.json` не містить платних або придбаних ассетів. `milestone-reviews.json` і `final-report.json` залишають художні Function/Form/Runtime approvals непідтвердженими. Технічні тести не заповнюють людське погодження автоматично.

## Відтворення доказів

Godot 4.7, із кореня репозиторію:

```sh
godot --headless --path game --fixed-fps 60 --script ../tools/world/city_geometry_check.gd
godot --headless --path game --fixed-fps 60 --script ../tools/world/city_runtime_check.gd
godot --headless --path game --fixed-fps 60 --script ../tools/world/city_onboarding_check.gd
godot --path game --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 60 --script ../tools/world/city_capture.gd -- --output=/tmp/nooneisreal-city-review
godot --path game --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps 60 --script ../tools/world/city_style_check.gd
make check-playable
make gates
```

Запускати Godot послідовно. Capture потребує графічного дисплея; headless не замінює native кадри. Harness знімає фактичну геометрію з чотирьох кутів, зверху, з вулиці й проходу, а також камеру гравця та паузу. Він записує `plan-metadata.json` із вимірюваннями сцени. Збережена тут копія метаданих описує конкретний перевірений зріз; після зміни геометрії її слід відновити цим самим harness.

Початкові журнали й PNG лежать у `/workspace/nooneisreal-env/city-first/`, актуальний художній прохід — у `/workspace/nooneisreal-env/city-style/`; це зовнішні артефакти середовища, доступність яких наступній сесії не гарантована. Команди й harness збережені в репозиторії. Показники Linux renderer не доводять FPS чи комфорт на MacBook Air M3.

Чинний художній контракт — [[Plans/2026-10-04-City-Style-Match]]: найсвіжіші окремі текстури визначають форми та палітру, старі панорами залишаються чернетками. Метадані містять повний виміряний склад району й фактичні межі видимої геометрії; масив `blocks` описує лише основу маршрутів.

## Related

- [[Plans/2026-10-04-City-First]] · [[2026-10-04-City-First-Review]] · [[2026-10-04-T1-City-First]] · [[ADR-023-City-First-Exploration]]
