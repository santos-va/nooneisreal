# 07 — Аудіо

## Зараз (Prototype 0.1)

22 WAV-плейсхолдери (14 — кікоф, 8 — кіти 2026-10-02) синтезовано ffmpeg (lavfi: шум + синуси + огинаючі) у
`game/assets/audio/sfx/`; авторство — проєкт, ліцензія CC0. Усі в [[Textures-Registry]].
Відтворення — автолоад `Sfx` (пул 12 голосів, джитер pitch ±8 %). Відсутній файл = тиша, не краш.

| файл | подія |
|---|---|
| hit_light / hit_heavy | влучання легкого / важкого |
| block | блок |
| whoosh | старт активних кадрів, деш |
| grapple_fire / grapple_hit / grapple_release / grapple_denied | гарпун |
| ko · round_start · ultimate · land · ui_move · ui_confirm | решта |
| flash · kunai · smoke · book · crit | Skea |
| rewind · time_stop · sword | Choko |

## Звук ударів — «соковитий» (запит Santos 2026-10-02)

**Стан 2026-10-03 (фаза 1):** синтетичні удари перешаровані за рецептом нижче (`tools/audio/synth_hits.py`,
3 варіанти на `hit_light`/`hit_heavy`/`block`/`whoosh`, пік −1 dBFS); `Sfx` грає варіанти через
`AudioStreamRandomizer` на шині `SFX` з компресором і лімітером; бібліотеки збирає `tools/audio/build_sfx.sh`
(див. [[2026-10-03-phase1-controls-audio-water]]). Прослуховування — за Santos.

Зараз звуки синтезовані з шуму й синусів, вони тонкі й слабкі. План ([[ADR-008-Audio-Sourcing]]):

**Рецепт одного удару ножем/кунаєм (4 шари, зводяться за 1–2 мс):**
1. **Свіст** до удару, 60–120 мс перед контактом: повітряний «вжух» (запускається на старті активних кадрів).
2. **Транзієнт:** металевий «цок/дзинь» 2–6 кГц, 20–40 мс, різкий.
3. **Тіло:** глухий удар по тканині/тілу 100–400 Гц, 80–150 мс (м'ясо, шкіра, хрускіт).
4. **Саб:** 40–70 Гц, 100–200 мс. Відчувається в навушниках, «вага».
Плюс 3–5 варіантів кожного шару і випадкове поєднання; pitch ±6 %; синхрон із hitstop.
Обробка: компресор (attack 1 мс, ratio 4:1) → лімітер −1 dBFS; SFX ≈ −10 dBFS, музика ≈ −18 dBFS.
У Godot: `AudioStreamRandomizer` на кожен шар + шина `SFX` з `AudioEffectCompressor` і `AudioEffectLimiter`.

**Звідки брати (безкоштовно, перевірити ліцензію на сторінці перед завантаженням):**

| джерело | ліцензія (за ресерчем 2026-10-02) | що там |
|---|---|---|
| Sonniss GDC Game Audio Bundle (gdc.sonniss.com) | royalty-free, комерційно, без атрибуції; не можна перепродавати як бібліотеку, не для навчання AI | сотні ГБ професійних ударів, металу, свистів |
| Kenney Impact Sounds (kenney.nl) | CC0 | 130 ударів |
| Freesound (фільтр License → CC0) | CC0 | будь-які удари ножем, metal hit, sword swish |
| OpenGameArt «Swishes Sound Pack» | CC0 | 13 свистів |

Ці сайти **закриті для хмарного агента** (egress), тому прямі посилання не перевірені. Завантажує Santos на Mac,
далі зборку робить скрипт `tools/audio/build_sfx.sh`: бере паки (zip або розпаковані теки) з `tools/audio/nir-audio/`
(інакше `~/Downloads/nir-audio/`), нарізає, нормалізує, шарує й кладе в `game/assets/audio/sfx/` + реєструє в
[[Textures-Registry]]. Стан на Mac — розділ нижче.

**Не з Higgsfield:** моделі SFX/музики там заборонені для окремого аудіо описом інструмента ([[Higgsfield-Pipeline]]).

## Бібліотека на Mac (2026-10-03)

**Що лежить.** `tools/audio/nir-audio/` (у `.gitignore`, ~6.8 ГБ): Sonniss GDC 2024 частини 1–2 і Kenney
Interface Sounds — 406 звуків у 92 паках (`python3 tools/audio/catalog.py`). Ліцензії прочитано у файлах паків:
Sonniss `License - GDC Game Audio.pdf` — комерційно, з правками, без атрибуції; не продавати «як є»; **жодного
використання для AI** (сирі звуки не вантажимо в генератори); Kenney `License.txt` — CC0. Сирі файли в цей
публічний репо не потрапляють — лише зібрані з них ігрові звуки.

**Як розкладено.** Бандли лежать як завантажені (ліцензія їде з бандлом); сортування — вид поверх:
`tools/audio/nir-audio/_by-category/<полиця>/<пак>` (посилання). Полиці — `tools/audio/library_categories.tsv`:
combat 9 паків · destruction 3 · energy 7 · cinematic 7 · ui 7 · mechanisms 7 · foley 6 · voices 6 ·
ambience-city 19 · ambience-nature 11 · vehicles-guns 10. Каталог `tools/audio/library_catalog.tsv` (у git) —
полиця, пак, файл, тривалість, пік і моменти окремих ударів у дублях до 30 с: з нього хмарні сесії пишуть рецепти,
не бачачи бібліотеки.

**Що зібрано.** 40 `.ogg` на всі 22 події `Sfx` (рецепти — `tools/audio/sfx_recipes.tsv`; `.wav`-синтетика лишилась,
`Sfx` бере `.ogg` першим):

| подія | варіанти | з чого |
|---|---|---|
| hit_light | 4 | картонний удар (класичний фолі-панч) + аніме «noise punch» + мокрий шльопок + трохи сабу |
| hit_heavy | 4 | дворучна сокира в плоть (4 дублі) + аніме-панч + кам'яний тріск + кінематографічний саб |
| block | 4 | металевий щит під ударом (4 дублі) + глухе тіло |
| whoosh | 4 | розриви бавовни (форма «вжуху») + шматок важкого sci-fi свисту знизу |
| kunai | 3 | рикошети металу (3 дублі) + дзенькіт сталевого прута |
| sword | 3 | «шінг» ножиць по металу + скрегіт клинка + тіло сокири |
| crit | 2 | хрускіт кістки + удар по склу + тихий дзвін |
| land | 2 | картонний удар + саб |
| grapple_fire / _hit / _release / _denied | 1 | пневмопостріл + пара · металевий удар + брязкіт ланцюга · важіль + натяг кабелю · сухий клац + Kenney error |
| flash | 1 | sci-fi «зап» + електричне потріскування + повітря |
| smoke | 1 | викид пари + «чорний дим» хімзброї + глухий хлопок |
| book | 1 | важка сторінка книги + темний скляний тон |
| rewind | 1 | реверс металу + реверс годинникових тиків |
| time_stop | 1 | тік годинника + металевий дзвін + бум |
| ko · ultimate · round_start | 1 | металевий трейлерний бум + сокира + хрускіт · трейлерний удар + аніме power-up · гонг |
| ui_move · ui_confirm | 1 | Kenney select / confirmation |

Добір — за огинаючою, яскравістю й назвою, **не на слух**: `start_ms` у рецептах стоїть за ~10 мс до піку кожного
удару, щоб контакт звучав на t=0. Слух — за Santos: `bash tools/audio/audition.sh` (усі), `AB=1 bash
tools/audio/audition.sh hit_` (синтетика → бібліотека). Вердикт — правка рядка рецепта і `bash tools/audio/build_sfx.sh`.
Енкодер: у Homebrew-ffmpeg немає libvorbis, тому `.ogg` кодує `oggenc` (`brew install vorbis-tools`).
Деталі сесії — [[2026-10-03-Sound-Library]].

## Напрям

- Удар ногою по нозі — глухий, короткий транзієнт + низький «саб»; у міксі тримати −10 dBFS SFX, −18 dBFS музика.
- Шарування: whoosh + impact + sub; 3–5 варіантів на удар; `AudioStreamRandomizer` для варіацій.
- Джерела: Sonniss GDC bundles (royalty-free), Kenney Impact Sounds (CC0), Freesound (фільтр CC0),
  OGA Swishes (CC0). Уникати CC-BY-NC/SA і Zapsplat free (атрибуція).
- AI: ElevenLabs SFX (Starter для комерційного) або Higgsfield Seed Audio/Mirelo — пізніше, зі словом Santos.
- Голоси й саундтреки — свої, фаза 5.

## Related
- [[Textures-Registry]] · [[2026-10-02-Animation-Assets-Pipeline]] · [[Roadmap]] · [[2026-10-03-Sound-Library]]
