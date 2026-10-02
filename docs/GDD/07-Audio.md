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
далі зборку робить скрипт `tools/audio/build_sfx.sh` (фаза 1): бере zip-и з `~/Downloads/nir-audio/`, нарізає,
нормалізує, шарує й кладе в `game/assets/audio/sfx/` + реєструє в [[Textures-Registry]].

**Не з Higgsfield:** моделі SFX/музики там заборонені для окремого аудіо описом інструмента ([[Higgsfield-Pipeline]]).

## Напрям

- Удар ногою по нозі — глухий, короткий транзієнт + низький «саб»; у міксі тримати −10 dBFS SFX, −18 dBFS музика.
- Шарування: whoosh + impact + sub; 3–5 варіантів на удар; `AudioStreamRandomizer` для варіацій.
- Джерела: Sonniss GDC bundles (royalty-free), Kenney Impact Sounds (CC0), Freesound (фільтр CC0),
  OGA Swishes (CC0). Уникати CC-BY-NC/SA і Zapsplat free (атрибуція).
- AI: ElevenLabs SFX (Starter для комерційного) або Higgsfield Seed Audio/Mirelo — пізніше, зі словом Santos.
- Голоси й саундтреки — свої, фаза 5.

## Related
- [[Textures-Registry]] · [[2026-10-02-Animation-Assets-Pipeline]] · [[Roadmap]]
