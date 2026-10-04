# 2026-10-05 — продовження подорожі кварталом

Santos: «Все зробив? давай уперед якщо є ще робота». PR #175 перевірено змердженим у `d9d12ecddd06462a62af74c9503a4a881266cfc1`; нова гілка `codex/district-journey-continuity` від актуального origin/main.

## CP0

План [[2026-10-05-District-Journey-Continuity]] закриває конкретні прогалини: spawn замість продовження біля останнього відомого місця, відсутність вибору tracked quest, нечітке орієнтування до поточної цілі. Попередній пакет не оголошено всією завершеною грою; Mac та художнє приймання Santos відкриті. Оригінальна іконка чекає потрібний PNG за явним вибором користувача.

## CP1 — реалізація та доставка бази

`CityJourney` зберігає дозволені назви місць окремо для Choko/Skea; native перевіряється справжнє стояння на підлозі й вихід/повторний вхід. `CityProgress` підтримує явний вибір/вимкнення доручення; `CityQuestTargets` обчислює решту умов усіх шести завдань. Журнал має focusable кнопки, HUD — напрямок/відстань і назву безпечної точки. Версія наступного зрізу — 0.4.1. [[2026-10-05-City-Journey]] · [[2026-10-05-Quest-Tracking]].

Read-only перевірка доставки попереднього main: [macOS run 37243292345](https://github.com/santos-va/nooneisreal/actions/runs/37243292345) має success у build, verify-macos і publish. Публічний `macos-main/manifest.json` реально повернув revision `d9d12ecddd06462a62af74c9503a4a881266cfc1`, size 266007830, schema/incremental_schema 1. Це підтверджує опублікований канал, але не встановлений SHA на Mac Santos. Іконка навмисно незмінна й не є індикатором оновлення.

Перший інтеграційний `make check`: 90 GDS/0, smoke 164 checks/19847 frames, rc 0; import у restricted sandbox друкував socket-помилки середовища. Подальший `make gates` із доступом до socket завершився чисто: 90 GDS/0, батарея зелена. Playable запускається окремо як друга частина `make check-playable`: усі 57 попередніх сценаріїв плюс три нових, унікальний профіль кожного тесту. Native/загальний фінальний вердикт ще очікується.

## CP2 — інтегрований зріз

Production commit `e6f13c8e0566819c694686f8748398df43d54140`; [PR #176](https://github.com/santos-va/nooneisreal/pull/176) відкрито до main без self-merge. Повний playable завершився **60 сценаріїв / 0 помилок**, включно з усіма попередніми 57. Нові sentinels: journey **122/0**, quest tracking **44/0**, journal **32/0**. `make check` + окремий playable є тим самим послідовним прийманням, що `make check-playable`; gates — зелена батарея, **90 GDS/0**.

Незалежний T4 перевірив native scene/menu/disk цикл **44/0**, додаткові input/dialogue/behind/completion edges **12/0**, пошкоджені checkpoint-и **19/0** й quest tracking **44/0**. Навмисне вимкнення фільтра вже використаних опор у disposable копії спричинило 8 відмов: тест розрізняє регресію. Повний вердикт — [[2026-10-05-District-Journey-Review]].

Журнали інтеграції: `/tmp/nir-journey-make-check.log`, `/tmp/nir-journey-gates.log`, `/tmp/nir-journey-playable.log`, per-scenario `/tmp/nir-journey-playable/`. Native докази та незалежні probes — `/workspace/nooneisreal-evidence/district-journey-continuity/`; вибрані кадри зберігаються в репозиторії. Mac/M3, фізичний геймпад, встановлений SHA користувача, FPS і суб'єктивне 30-хвилинне проходження не підтверджені цими вимірами. Safe checkpoint — назване місце, не точний snapshot бою/позиції.

## Передача

Контрольна точка для наступної сесії — [[2026-10-05-District-Journey-Checkpoint]]. Перший draft CI помітив два wikilinks до ще не закоміченого audit; фінальний documentation commit додає сам audit і native докази, не приховує або вимикає перевірку.

## Related

- [[2026-10-05-District-Journey-Continuity]] · [[2026-10-05-Playable-District-Session]] · [[state]]
