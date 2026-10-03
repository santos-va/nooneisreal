# 2026-10-03 — звукова бібліотека на Mac: розкладка і перші справжні звуки

**Хто:** Santos · T1 Дедал (Claude Code на Mac; паралельно в хмарі працює інша сесія T1)
**Контекст:** Santos завантажив Sonniss GDC 2024 (частини 1–2) і Kenney Interface Sounds і попросив навести
лад: розкласти всі звуки, вдало підібрати й завантажити в гру; пушити пізніше, разом із хмарною роботою.

## Що обговорили
- Бібліотека лежала двічі: `~/Downloads/nir-audio/` і `tools/audio/nir-audio/` — по 6.8 ГБ (`du -sh`),
  вміст однаковий (`diff -rq` → порожньо). Репо публічний (`gh repo view` → `PUBLIC`).
- Збирач фази 1 ([[2026-10-03-phase1-controls-audio-water]], PR #18) чекав zip-ів і `libvorbis` у ffmpeg;
  паки розпаковані, а Homebrew-ffmpeg 9.0.2 без `libvorbis` (`ffmpeg -encoders`).
- Вісім картинок для PR #17 Santos закомітив і запушив сам о 03:58 (`9e884b2`) — у цю сесію не входили.
- Роль: виконання — не робота Дедала ([[constitution]] § Ролі). Зроблено за прямим словом Santos у цій сесії;
  записано тут, щоб Гефест і Аполлон бачили, що змінено в їхніх зонах (`tools/audio/`, реєстр, звуки).

## Що вирішили / зроблено
- Сирі паки — тільки локально: `tools/audio/nir-audio/` у `.gitignore` (ліцензія Sonniss забороняє віддавати
  звуки «як є», репо публічний). Сортування — вид із посилань `_by-category/<полиця>/<пак>`, бандли не рухали.
- `tools/audio/catalog.py` + `library_categories.tsv` → `library_catalog.tsv`: 406 звуків, 92 паки, 11 полиць,
  моменти ударів у кожному дублі до 30 с.
- `build_sfx.py`: розпаковані теки як паки; 8-ма колонка `start_ms` (кілька ударів з одного дубля = варіанти);
  9-та `fade_in_ms`; довгі хвости згасають на 30 % довжини замість обрізу; `.ogg` через `oggenc`, якщо у ffmpeg
  немає `libvorbis`. Ліцензії Sonniss і Kenney вписано в `sfx_sources.tsv` із цитатою з файлів паків.
- Рецепти на всі 22 події → 40 `.ogg` (таблиця — [[07-Audio]] § Бібліотека на Mac), рядки в [[Textures-Registry]].
- На хост поставлено `ffmpeg` 9.0.2 і `vorbis-tools` 1.4.3 (`oggenc`) через дрон PkgAgent.
- Перевірка (гілка `claude/mac-sfx-library`; після мержу #18/#20/#21 перебазована на `main` `9c27085`):
  `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot make check` → `[smoke] ALL OK (36 checks)`,
  `hit_light 4 variants, hit_heavy 4, whoosh 4`; `make gates` → `БАТАРЕЯ ЗЕЛЕНА`, РЕЄ 74/74, GDS 33.
  Піки всіх 40 файлів −1.4…−2.4 dBFS (`build_sfx.sh`), разом 480 КБ (`du -ch`).

## Що відклали / відкриті питання
- **Слух.** Добір — за огинаючою і назвою, не на слух. Santos: `bash tools/audio/audition.sh`,
  `AB=1 bash tools/audio/audition.sh hit_` (синтетика → бібліотека), потім `make run`.
- Синтетичні `.wav` лишились (видалення ассетів — Red); прибрати — лише словом Santos після прослуховування.
- Ембієнти арен (річка: `ambience-nature`, Cronshift: `ambience-city`) — у каталозі є, у грі для них ще немає
  програвача; це крок Гефеста.
- Копія в `~/Downloads/nir-audio/` — дублікат на 6.8 ГБ; збирач тепер бере `tools/audio/nir-audio/` першим.
  Прибрати її — рішення Santos.
- Пуш: гілка лише локальна, за домовленістю пушимо разом із хмарною роботою; база — `main`.

## Дії
- [ ] Santos · прослухати: `cd ../nooneisreal-sfx && bash tools/audio/audition.sh`, далі `make run`
- [ ] Santos · пуш `claude/mac-sfx-library` разом із хмарними гілками → PR у `main`
- [ ] T2 Гефест · ембієнт-програвач для арен

## Related
- [[state]] · [[07-Audio]] · [[Textures-Registry]] · [[ADR-008-Audio-Sourcing]] · [[2026-10-03-Phase1-Execution]] · [[2026-10-03-phase1-controls-audio-water]]
