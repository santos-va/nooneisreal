# 2026-10-03 — T3 Архімед: ліцензії паків (Ф0.2)

**Роль:** T3 Архімед · **Запит Santos:** «ліцензії Creative Trio і MegaKit, крок Ф0.2 плану» ([[2026-10-03-Santos-Packs-Arenas]]).

## Що обговорили
- Сайти ліцензій (quaternius.com, creativetrio.art, itch.io, fab.com, OGA, Asset Store, web.archive.org) закриті
  egress-проксі: `curl` → `403`, `WebFetch` → `EGRESS_BLOCKED`. Працював лише `WebSearch` (переказ, не текст).
- На гілці `textures/santos-pack` немає жодного `License*`; у 9 FBX — лише шляхи автора, без ліцензії (`strings`).

## Що вирішили (в межах T3 — лише висновок, без вибору)
- Бриф [[2026-10-03-Pack-Licenses]]: MegaKit — усі канали кажуть CC0, UNGROUNDED лише за формою (немає дослівного
  тексту). Creative Trio — UNGROUNDED по суті: ті самі паки роздаються під CC0 на сайті й продаються в сторах під
  ліцензією стору; канал завантаження Santos невідомий. CC0 у видачі прямо — 2 з 9 (Stone Bridges, Potions).

## Що відкладено
- Santos: звідки 9 FBX (сайт чи стор) + `License*.txt` із кожного zip і з MegaKit (Ф0.1). Після цього — цитати
  в бриф і [[Textures-Registry]].
- Чи не ганяти Creative Trio через Higgsfield до з'ясування каналу — рішення Дедала / Santos. `state.md` не чіпав (не мій).

## Related
- [[2026-10-03-Pack-Licenses]] · [[2026-10-03-Santos-Packs-Arenas]] · [[2026-10-03-T1-Santos-Packs]] · [[state]]
