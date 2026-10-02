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

## Напрям

- Удар ногою по нозі — глухий, короткий транзієнт + низький «саб»; у міксі тримати −10 dBFS SFX, −18 dBFS музика.
- Шарування: whoosh + impact + sub; 3–5 варіантів на удар; `AudioStreamRandomizer` для варіацій.
- Джерела: Sonniss GDC bundles (royalty-free), Kenney Impact Sounds (CC0), Freesound (фільтр CC0),
  OGA Swishes (CC0). Уникати CC-BY-NC/SA і Zapsplat free (атрибуція).
- AI: ElevenLabs SFX (Starter для комерційного) або Higgsfield Seed Audio/Mirelo — пізніше, зі словом Santos.
- Голоси й саундтреки — свої, фаза 5.

## Related
- [[Textures-Registry]] · [[2026-10-02-Animation-Assets-Pipeline]] · [[Roadmap]]
