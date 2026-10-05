# 2026-10-05 — живий квартал і близький контакт

Santos повідомив: «Приймаю на М3», уже оглянув гру й доручив різноманітні анімації, NPC, голоси, локальні мовні моделі, дослідження GitHub/Reddit та меншу дистанцію pre-grab — приблизно 0,70 м. Це людське приймання попередньої версії; встановлений SHA, FPS та обсяг RAM не названі. PR #177 перевірено як merged у `f4defd52213caaa62faf12eb2a1458505146fabc`; нова гілка — `codex/living-district-characters`.

## CP0 — аудит і розподіл

План [[2026-10-05-Living-District-Characters]] затверджений прямим дорученням; commit `d5f523d`. Шість смуг: контакт із мотузкою, анімації героя, NPC/діалоги/локальний текст, зовнішність/звуки, зовнішнє дослідження та незалежний аудит. Підтверджені source/runtime помилки й межі описані у плані. Питання про RAM/Ollama і мережеву або локальну гру з друзями поставлені асинхронно; поточні виправлення від відповідей не залежать.

Незалежна негативна проба збережень показала 19 SCRIPT ERROR попри позитивний лічильник assertions. Це помилка порівняння identity-полів до перевірки типів, а не валідне проходження тесту. У прийманні обов’язкове читання повного журналу.

Стан середовища: revision 11, enforced restricted network, preset `package_managers`; Hugging Face/Ollama/Reddit повертають відмову. GitHub connector доступний. Proxy не обходиться. Без ваг не оголошуємо реальний LLM inference; інтеграція має працювати з fallback без моделі. Дослідження — [[2026-10-05-Local-NPC-Models-And-Physics-Reuse]]. Оригінальний PNG іконки лишається відкладеним за попереднім рішенням.

## Доставка попереднього зрізу

Read-only GitHub перевірка цієї сесії: для merge `f4defd5` [CI 37247205459](https://github.com/santos-va/nooneisreal/actions/runs/37247205459) та [macOS main app 37247205418](https://github.com/santos-va/nooneisreal/actions/runs/37247205418) мають `completed/success`. Це стан workflow, не підтвердження конкретного встановленого SHA на Mac Santos.

## CP1 — нативний огляд

Перші actual city frames показали перекриття NPC центральною панеллю й віконною рамою. T4 та art незалежно підтвердили проблему. План доповнено боковою панеллю й безпечним кадруванням розмови; до повторного native огляду visual acceptance відкритий. Аудит звуку також виявив різні точки виміру: гра рахувала близькість від героя, а рушій слухав із камери. Art вирівнює цей контракт через scene-owned AudioListener3D.

## CP2 — приймання source

T4 завершив незалежний огляд: [[2026-10-05-Living-District-Review]] GREEN. Root повторив повний runner після виправлення audio fixture: 70/0, smoke164/19847, gates99/0. Усі попередні 62 сценарії й 12 negative controls залишені. Новий checkpoint і межі — [[2026-10-05-Living-District-Checkpoint]]. Код і тести заморожені; exact-SHA export/CI/PR наступні, не оголошені виконаними наперед.

## Related

- [[2026-10-05-Living-District-Characters]] · [[2026-10-05-District-Motion-Session]] · [[2026-10-05-Local-NPC-Models-And-Physics-Reuse]] · [[state]]
