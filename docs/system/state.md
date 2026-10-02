# state — поточна правда

**Оновлено:** 2026-10-02 (сесія кікоф, T1/T2 у одній сесії за дорученням Santos)
**Фаза:** Prototype 0.1 — зібрано, headless smoke-тест зелений, гілка `claude/blissful-clarke-pj15rz`, draft PR.

## Зараз важливо

1. Santos відповідає на [[2026-10-02-Characters-Interview]] → Арес заповнює скіли Choko і Skeasse.
2. Santos на Mac: встановити Godot 4.7, `make fetch-assets`, `make run` — перший погляд на арену.
3. Знайти справжню картку Skeasse (у повідомленні обидві URL однакові) → реєстр, портрет.
4. Аполлон: промпт листа персонажа для Meshy (T-pose, білий фон) — **без генерації** до слова Santos (баланс 2.55 кредиту, план Ultra).

## Що працює (виміряно `make check` 2026-10-02)

- 19 `.gd` парсяться; smoke-тест: 11 перевірок (удари, запуск у регдол, вставання, гарпун, ультимейт → KO, раунд 2).
- Рендер під Mesa/llvmpipe (Xvfb) піднімається: toon-шейдер + outline компілюються в Compatibility. Кадри: `docs/assets/screenshots/2026-10-02-prototype-0.1-a.png`, `-b.png`.

## Відкрите / ризики

- Фони та картки не завантажені в репо (CDN закритий для хмарного агента) — `tools/fetch_assets.sh` на локальній машині.
- Усі числа бою — `PLACEHOLDER` (див. [[02-Combat-System]]); регдол — капсульний плейсхолдер.
- Консолі — лише через W4 Consoles (~$2k/рік Starter) і статус розробника Sony/MS.

## Related
- [[index]] · [[constitution]] · [[Roadmap]] · [[2026-10-02-Prototype-0.1]] · [[2026-10-02-Kickoff]]
