# Playable district — checkpoint, не реліз

2026-10-05 · T1. **Статус: [draft PR #175](https://github.com/santos-va/nooneisreal/pull/175), implementation commit `0af967f`; мердж заблокований незавершеним візуальним прийманням.**

## Контекст і виконане

Santos просить довести квартал до відчутно кращого playable стану, а не починати нові системи без завершення. Гілка `codex/playable-district`, база `f24d973` (PR #174); постановка `85a3e67`. Оригінальну нову іконку не отримано; Santos прямо обрав залишити стару до появи саме потрібного PNG.

У робочому дереві зведено authored UAL удари й locomotion на Choko/Skea, три прохідні крамниці, працівників і маршрути мешканців, шість JSON-доручень, персистентний прогрес/дружбу окремо для героя, кольорову перев'язь, меню/HUD/журнал, версію 0.4.0 і build SHA. Останнє виправлення кріпить прибраний меч до actual torso замість нерухомого root. Це реалізація, а не твердження про остаточний художній результат.

Усі активні агенти отримали service usage-limit error. Перед зупинкою production-зміни залишились на спільному диску; координатор зберігає checkpoint і draft PR, а не позначає роботу завершеною.

## Докази

- `validation/check-second.log`: Godot 4.7, 87 GDS / 0 parse errors; smoke 164 checks / 19847 frames.
- `validation/playable-second.log`: 55 scenarios / 0 failures. Після останнього sword-attachment change запущено окремий checkpoint-прогін; його результат у журналі сесії.
- `validation/distribution-checkpoint.log`: 25 tests OK; експорт зберігає custom include filters та додає JSON/marker.
- `validation/pck-content.log`: `PCK_CONTENT_COMPLETE quests=6 marker=verified audio=present`. Справжній exported PCK змонтовано в порожньому verifier-проєкті; JSON SHA збігається з checkout, marker — тестова ревізія `eeee…`, а не релізний SHA. У незавершеному probe виправлено неправильну назву audio manifest на фактичну `soundtracks.cfg`.
- `after/quest-final.log`: незалежний native цикл 26/0 — розмови справжніми кнопками, два виконані доручення, нагорода, повтор без фарму, дружба, перев'язь, disk reload, ізоляція Skea.
- `after/shops/`: незалежний physical route — дев'ять відрізків входу/прилавка/виходу успішні для трьох крамниць.
- `locomotion/{before,after}/trace.csv`: 240 fixed-clock ticks; усі speed/x траєкторії збігаються. На frame50 при 2.17 м/с старий Jog_Fwd замінений Walk; на frame184 при гальмуванні 5.26667 м/с старий Idle замінений Jog_Fwd. Ранні variable-render-delta кадри відхилені.

Усі шляхи вище відносні до `/workspace/nooneisreal-evidence/playable-district/`. Невеликі native screenshots збережені в репозиторії; raw motion sequences/MP4 — поза git. Linux software render не є Mac/M3-прийманням.

## Що обов'язково завершити наступним

1. **Combat visual blockers:** T4 на `authored-combat-v2/{choko,skea}-contacts.png` знайшов lowhand із кистю біля власного коліна та hammer із руками біля обличчя на першому active frame; виразний рух униз припадає на recovery. Звірити actual hand endpoint/forward з contact в `AuthoredCombatMotion.gd`, виправити mapping/композицію, додати змістовні assertions і повторити native sequence. Зелені тести джерела кліпу не закривають цей дефект.
2. **Sheathed sword:** останній `SwordPresentation.gd` torso-mount change потребує нового native crouch/hammer огляду; попередні 72 кадри показують старе кріплення. Не вважати його прийнятим за старими кадрами.
3. **Locomotion:** переглянути нову fixed-clock послідовність повністю, закрити native висновок і оновити `2026-10-05-Locomotion-States` (старе 304 змінено до 306 assertions). Скріншот сам по собі не доводить хороший рух.
4. **Незалежний audit:** завершити negative content/save review і фінальний вердикт у `2026-10-05-Playable-District-Review`. Незалежний T4 не встиг завершити документ; не підписувати GREEN від його імені.
5. **Документація реалізації:** бойова та NPC-смуги не встигли написати власні підсумкові сторінки й оновити implementation section state. Перевірити actual files/tests, не покладатись лише на повідомлення агентів.
6. Після виправлень — потрібні `make check-playable`, `make gates`, цільові distribution/PCK checks, оновлені кадри, review; лише тоді перевести draft PR у ready. Santos мерджить сам. Не публікувати збірку з незакомічених файлів.

## Межі

Немає claim про завершені всі рухи, 30 хвилин ручної гри, фінальну графіку, M3 FPS, вісім готових героїв чи mod SDK. Rope/dodge/specials частково лишаються semantic procedural, low/spin — композиції authored джерел. Ліцензії, repository visibility, DRM не змінені. Майбутня комерційна модель — окремий план.

## Related

- [[2026-10-05-Playable-District]] · [[2026-10-05-Playable-District-Session]] · [[2026-10-05-Playable-District-Review]] · [[2026-10-05-Playable-District-Art]] · [[2026-10-05-Locomotion-States]] · [[2026-10-05-District-Delivery]] · [[2026-10-05-Modding-And-Ownership]]
