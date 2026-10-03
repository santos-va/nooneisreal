# Реєстр текстур і ассетів

Правило R1: кожен файл у `game/assets/` має рядок тут; кожен рядок тут існує на диску
(гейт `tools/gates/texture_registry_check.py`). Шлях пишеться як `game/assets/...`.
Ассети, які ще **не на диску**, живуть у таблиці «Заплановано» без префікса `game/assets/`.

## На диску

| id | файл | джерело | автор/модель | ліцензія | де використано |
|---|---|---|---|---|---|
| sfx-hit-light | `game/assets/audio/sfx/hit_light.wav` | синтез ffmpeg lavfi (pink noise + lowpass) | проєкт, 2026-10-02 | CC0 (наше) | `Sfx.play("hit_light")`, легкі удари |
| sfx-hit-heavy | `game/assets/audio/sfx/hit_heavy.wav` | ffmpeg: brown noise + sine 62 Hz | проєкт | CC0 | важкі удари, скіли |
| sfx-block | `game/assets/audio/sfx/block.wav` | ffmpeg: white noise highpass + 1.9/3.1 kHz | проєкт | CC0 | блок |
| sfx-whoosh | `game/assets/audio/sfx/whoosh.wav` | ffmpeg: pink noise bandpass | проєкт | CC0 | старт активних кадрів, деш |
| sfx-grapple-fire | `game/assets/audio/sfx/grapple_fire.wav` | ffmpeg: aevalsrc chirp 1400→… | проєкт | CC0 | постріл гарпуна |
| sfx-grapple-hit | `game/assets/audio/sfx/grapple_hit.wav` | ffmpeg: 2.4 kHz + 640 Hz decay | проєкт | CC0 | підтягування ворога, TIME STOP |
| sfx-grapple-release | `game/assets/audio/sfx/grapple_release.wav` | ffmpeg: pink noise bandpass 1.4 kHz | проєкт | CC0 | відпускання мотузки |
| sfx-grapple-denied | `game/assets/audio/sfx/grapple_denied.wav` | ffmpeg: 140 Hz click | проєкт | CC0 | немає зарядів |
| sfx-ko | `game/assets/audio/sfx/ko.wav` | ffmpeg: brown noise + 48/96 Hz | проєкт | CC0 | K.O. |
| sfx-round-start | `game/assets/audio/sfx/round_start.wav` | ffmpeg: 660→990 Hz chime | проєкт | CC0 | старт раунду |
| sfx-ui-move | `game/assets/audio/sfx/ui_move.wav` | ffmpeg: 880 Hz blip | проєкт | CC0 | меню, повернення заряду |
| sfx-ui-confirm | `game/assets/audio/sfx/ui_confirm.wav` | ffmpeg: 660→1046 Hz | проєкт | CC0 | підтвердження в меню |
| sfx-ultimate | `game/assets/audio/sfx/ultimate.wav` | ffmpeg: sweep 180→1080 Hz + 55 Hz | проєкт | CC0 | старт ультимейту |
| sfx-land | `game/assets/audio/sfx/land.wav` | ffmpeg: brown noise lowpass 500 | проєкт | CC0 | приземлення |
| sfx-flash | `game/assets/audio/sfx/flash.wav` | ffmpeg: chirp 300→5500 Hz + white noise highpass | проєкт, 2026-10-02 | CC0 | Flash Step Skea |
| sfx-kunai | `game/assets/audio/sfx/kunai.wav` | ffmpeg: 3.2/4.7/2.1 kHz metallic decay | проєкт | CC0 | Kunai Rain (кидок і тіки) |
| sfx-smoke | `game/assets/audio/sfx/smoke.wav` | ffmpeg: pink noise bandpass 1.8 kHz, 0.9 s | проєкт | CC0 | Shadow Veil |
| sfx-rewind | `game/assets/audio/sfx/rewind.wav` | ffmpeg: зворотні свіпи 1500→200 Hz | проєкт | CC0 | RECORD: маркер і перемотка |
| sfx-time-stop | `game/assets/audio/sfx/time_stop.wav` | ffmpeg: 80 Hz удар + дзвін 1320/1980 Hz | проєкт | CC0 | TIME STOP, Chrono Guard |
| sfx-crit | `game/assets/audio/sfx/crit.wav` | ffmpeg: 2.6/3.9/5.2 kHz дзвін | проєкт | CC0 | крит по слабкій точці |
| sfx-sword | `game/assets/audio/sfx/sword.wav` | ffmpeg: свіп 4.2 kHz + 6.1 kHz «шінг» | проєкт | CC0 | Sword Storm |
| sfx-book | `game/assets/audio/sfx/book.wav` | ffmpeg: 55/82.5/110 Hz дрон | проєкт | CC0 | Cursed Grimoire |
| bg-kronshift-river | `game/assets/backgrounds/bg_kronshift_river.jpg` | надіслав Santos у чаті 2026-10-03 (1500×848 JPEG, ймовірно Higgsfield, оригінальна URL невідома) | Santos | підтвердити (Архімед) | стадія `river` (дефолтна), джерело для [[Stage-River]] |
| card-skea-v1 | `game/assets/characters/cards/card_skea_v1.jpg` | надіслав Santos у чаті 2026-10-02 (1500×848 JPEG; згенеровано в Higgsfield, оригінальна URL невідома) | Santos / Higgsfield | Higgsfield ToS (підтвердити, Архімед) | картка Skea в меню; референс для 3D |
| bg-market | `game/assets/backgrounds/bg_kronshift_market_street.webp` | Higgsfield CDN `hf_20261002_131105_0b5c85b7-…_min.webp`, завантажено `tools/fetch_assets.sh` на Mac Santos 2026-10-03 | Higgsfield, GPT Image 2.5 ([[Prompts]] § Фони) | Higgsfield ToS (комерційне на платних планах — підтвердити, Архімед) | stage `market_street` |
| bg-alley | `game/assets/backgrounds/bg_kronshift_back_alley.webp` | Higgsfield CDN `hf_20261002_131105_a479d377-…_min.webp`, завантажено `tools/fetch_assets.sh` на Mac Santos 2026-10-03 | Higgsfield, GPT Image 2.5 ([[Prompts]] § Фони) | Higgsfield ToS (комерційне на платних планах — підтвердити, Архімед) | stage `back_alley` |
| bg-main | `game/assets/backgrounds/bg_kronshift_main_street.webp` | Higgsfield CDN `hf_20261002_131104_8510a1fc-…_min.webp`, завантажено `tools/fetch_assets.sh` на Mac Santos 2026-10-03 | Higgsfield, GPT Image 2.5 ([[Prompts]] § Фони) | Higgsfield ToS (комерційне на платних планах — підтвердити, Архімед) | stage `main_street` |
| bg-city-ref | `game/assets/backgrounds/bg_kronshift_city_reference.webp` | Higgsfield CDN `hf_20261002_102352_6c5c895d-…_min.webp`, завантажено `tools/fetch_assets.sh` на Mac Santos 2026-10-03 | Higgsfield, GPT Image 2.5 (референс міста) | Higgsfield ToS (комерційне на платних планах — підтвердити, Архімед) | stage `city_reference`, еталон стилю |
| card-choko-v3 | `game/assets/characters/cards/card_choko_v3.png` | Higgsfield CDN `hf_20261002_111512_bcddbbc6-…png`, завантажено `tools/fetch_assets.sh` на Mac Santos 2026-10-03 | Higgsfield ([[Prompts]] § Choko v3) | Higgsfield ToS (комерційне на платних планах — підтвердити, Архімед) | портрет/картка Choko |
| weapon-choko-main | `game/assets/characters/cards/weapon_choko_main_sword.png` | Higgsfield CDN `hf_20261002_111511_9652a5b1-…png`, завантажено `tools/fetch_assets.sh` на Mac Santos 2026-10-03 | Higgsfield ([[Prompts]] § Зброя) | Higgsfield ToS (комерційне на платних планах — підтвердити, Архімед) | референс меча для 3D |
| weapons-choko-ult | `game/assets/characters/cards/weapons_choko_ultimate.png` | Higgsfield CDN `hf_20261002_102352_f00d0272-…png`, завантажено `tools/fetch_assets.sh` на Mac Santos 2026-10-03 | Higgsfield ([[Prompts]] § Зброя) | Higgsfield ToS (комерційне на платних планах — підтвердити, Архімед) | референс ульт-мечів |
| hands-choko | `game/assets/characters/cards/hands_choko.png` | Higgsfield CDN `hf_20261002_110646_b776f4f8-…png`, завантажено `tools/fetch_assets.sh` на Mac Santos 2026-10-03 | Higgsfield ([[Prompts]] § Руки) | Higgsfield ToS (комерційне на платних планах — підтвердити, Архімед) | референс рук/рукавичок |

Іконка проєкту `game/icon.svg` — намальована в сесії (SVG, CC0), поза `game/assets/`.

## Заплановано (завантажує `tools/fetch_assets.sh`; після цього перенести рядок угору з префіксом `game/assets/`)

Порожньо: 8 рядків перенесено вгору 2026-10-03 — файли завантажено `tools/fetch_assets.sh` на Mac Santos (зі слова Santos).

## Related
- [[Style-Guide]] · [[Backgrounds]] · [[Prompts]] · [[07-Audio]] · [[constitution]]
