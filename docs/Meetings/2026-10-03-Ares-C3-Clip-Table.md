# 2026-10-03 — Арес: C3, таблиця кліп → удар (#36)

## Що обговорили
Santos дав команду «C3 #36» у сесії T5. Обсяг задачі взято з черги `state.md` (рядок T5): таблиця кліп → удар для Choko
і Skea, кандидати з [[2026-10-03-Animation-Sources]] §8 п. 2, чесні описи в `choko.tres`, без нових полів.

## Що вирішили
- Таблиця — у [[02-Combat-System]] § Кліп → удар. 19 рухів і станів мають кліп зі Standard (CC0). У 7 рухів кліпа немає,
  це дірки: Choko — `crouch_light`, `air_light`, `sword_up`, сальто; Skea — `roundhouse`, `low_kick`, `flying_knee`.
- `watch`, `veil` і `book` лишаються позами RigAnimator, кліп їм не потрібен.
- Прискорення Standard-кліпів до наших кадрів — ×3…×7, бо кліпи довші за удари. Це ризик «смикано», Гефест
  показує кадр у C1. Кадри ударів **не** подовжуємо під кліпи, бо вони заземлені (CN §3–4).
- 8 поз для листа Choko v5 записано там же. Лист генерується лише після слова Santos (RED).
- `choko.tres`: 8 описів замість «PLACEHOLDER frame data». Тепер кожен опис каже, які числа в межах еталона, а які
  PLACEHOLDER або UNGROUNDED, і який кліп грає. Числа не мінялись.

## Що відкладено
- Вибір Santos щодо дір: UAL2 Source $14.99 (за переглядачем закриває 5 із 7) · UAL1 Pro $9.99 (`Kick`, `BackFlip`) · Meshy (RED).
- Описи в `skea.tres` — у черзі був лише `choko.tres`.
- `contact_time` і тривалість `OverhandThrow`, `Idle_Loop` — замір Гефеста в редакторі.

## Related
- [[02-Combat-System]] · [[2026-10-03-Animation-Sources]] · [[2026-10-03-Picks-to-Game-and-Animation]] · [[2026-10-03-Path-to-First-Fight]] · [[Choko]] · [[Skea]]
