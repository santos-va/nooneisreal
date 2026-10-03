# Фони арен

Фони стадій у грі зараз (`ls game/assets/backgrounds/*.{jpg,webp}` → 5 файлів): чотири ілюстрації Cronshift
(Higgsfield, GPT Image 2.5 «flare», 16:9, 2688×1520) і фон річки від Santos ([[Stage-River]]). У грі — квад
54×30 м на z = −18 з шейдером `backdrop.gdshader` (віньєтка, паралакс 0.2 від камери). Без файлу —
процедурний фолбек `backdrop_fallback.gdshader` (градієнт присмерку + силуети + вікна).

| stage | sun | ambient | sky top → bottom (фолбек) |
|---|---|---|---|
| river (дефолт, з 2026-10-03) | `(1.0, 0.72, 0.5)` | `(0.32, 0.3, 0.4)` | `(0.3,0.3,0.42)` → `(0.9,0.55,0.35)` |
| market_street | `(1.0, 0.78, 0.55)` | `(0.38, 0.34, 0.42)` | `(0.16,0.22,0.32)` → `(0.78,0.42,0.26)` |
| back_alley | `(0.55, 0.72, 0.95)` | `(0.12, 0.17, 0.26)` | `(0.04,0.06,0.12)` → `(0.12,0.30,0.36)` |
| main_street | `(1.0, 0.7, 0.45)` | `(0.3, 0.27, 0.36)` | `(0.2,0.2,0.34)` → `(0.9,0.5,0.3)` |
| city_reference | `(1.0, 0.8, 0.6)` | `(0.3, 0.3, 0.38)` | `(0.18,0.24,0.34)` → `(0.7,0.4,0.28)` |

Освітлення сцени (`Sun`, `WorldEnvironment`) підлаштовується під стадію в `Arena.gd`.

**Ротація зі спринту 2026-10-03:** `river` · `bazaar` · `fountain`, кожна вдень і вночі ([[Cronshift]] § Ротація арен). Сторінки
арен — [[Stage-River]] · [[Stage-Bazaar]] · [[Stage-Fountain]]. `market_street`, `back_alley`, `main_street` і
`city_reference` поза ротацією; нове оточення 360° — [[Arenas-360-Prompts]].

## Плани

- Outpaint до 21:9, щоб камера на відстані 15 м не бачила країв.
- Image Decompose → шари; ближній шар із ліхтарями стає якорями гарпуна.

## Related
- [[Cronshift]] · [[Stage-River]] · [[Stage-Bazaar]] · [[Stage-Fountain]] · [[Arenas-360-Prompts]] · [[Textures-Registry]] · [[Style-Guide]] · [[Architecture]] · [[index]]
