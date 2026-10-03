# Fix-журнал — смуга B, крок 2: мальовані флипбуки T6·B у бою

**Роль:** T2 Гефест, 2026-10-03. Santos: «Так, давай» — у відповідь на «беру смугу B?». **План:** [[2026-10-03-Sprint-Arenas-VFX]] рядок B.
**ТЗ:**
- [[VFX-Sheets-Prompts]] § Формат аркуша: 4 × 4 по 512 px, 12 fps, MIX для диму й пилу, ADD для світних;
- [[VFX-Direction]] § Принцип;
- аудит [[2026-10-03-Sprint-Lane-I-2]] пропозиція 2: гард «ефекти — лише картинка».

## Звірка

- `game/assets/vfx/`: 34 аркуші 2048 × 2048 RGBA. Окремо лежить `vfx_steam_puff_v1.png` (2688 × 1520, референс стилю, у гру не йде).
  Звірено через Pillow: `Image.open(f).size`.
- Жоден скрипт аркушів не вантажив: `grep -rln "assets/vfx/" game/scripts` → порожньо.
- Відкритих PR смуги B немає (`list_pull_requests state=open` → `[]`).
- `state.md`: крок 2 смуги B «чекає Дедала, бо виклики живуть у `Fighter.gd`». Тому `Fighter.gd` **не чіпав**. Директор
  ефектів лише читає сигнали й стан бійців.

## Що зроблено

- `game/scripts/fx/Flipbook.gd` (новий) — один завантажувач на всі аркуші:
  - `QuadMesh` + `StandardMaterial3D` з `uv1_scale` ¼ і зсувом на клітинку;
  - 12 fps, тобто одна клітинка на 5 кадрів фізики;
  - `first` / `count` — рядок чи частина аркуша; `delay`;
  - MIX або ADD; біллборд або декаль на підлозі; дзеркало;
  - сам себе прибирає;
  - лічильник `Flipbook.spawned` для smoke.
- `game/scripts/fx/FxDirector.gd` (новий) — вузол в `Arena`. Слухає `move_started` і `knocked_out`, а кожен кадр фізики
  порівнює знімок стану бійця з попереднім. У бій нічого не пише.

  | подія | аркуш |
  |---|---|
  | легкий / важкий / повітряний удар Choko, з першого активного кадру | `slash_choko` / `slash_heavy_choko` / `slash_air_choko` |
  | влучання (`Arena._on_hit`) | `spark_hit`, рядок: звичайне / крит / Choko / блок |
  | K.O. | `ko_burst` |
  | Chrono Step / Flash Step | `trail_chrono` / `trail_flash` |
  | постріл гарпуна | `grapple_launch` |
  | приземлення зі стрибка | `dust_land`, на річці — `water_splash` |
  | регдол ліг (LAUNCHED → GETUP або KNOCKDOWN) | `dust_land` + декаль `ground_crack` |
  | SHADOW VEIL | `smoke_veil` |
  | armor break | `armor_break` |
  | TIME STOP | `choko_timestop` — декаль під Choko |

- `HitSpark`: якщо аркуш є, процедурний квадрат-зірка ховається, а спалах світла й чорнильні лінії лишаються.
  Іскри — **MIX**: у ADD разом зі світлом удару зірка вигоряла в біле й губила контур (видно на знімку).
- `Fx.enabled`: якщо `false`, флипбуки, директор і іскра арени нічого не спавнять.
- `.import` для 34 аркушів: `mipmaps/generate=true` (аркуш 2048 px на 1–3 м інакше мерехтить) і
  `detect_3d/compress_to=0` (без автоматичного VRAM-стиснення мальованої альфи).

**Предмет:**
- кожна подія бою з таблиці малює свій аркуш у темпі 12 fps;
- ефекти не змінюють бій.

## Перевірка

| команда | результат |
|---|---|
| `make check` | `[smoke] OK  lane B flipbook: 14 sheets are 2048 × 2048; cells 0…15 at 12 fps, then freed; a delayed row-2 spark waits 0.25 s; Fx off spawns nothing` |
| те саме, вільна дуель | `lane B flipbooks in the free duel: { "dust_land": 4, "slash_choko": 3, "spark_hit": 20, "grapple_launch": 1, "trail_flash": 1, "armor_break": 2, "ground_crack": 1, "slash_heavy_choko": 2, "slash_air_choko": 1 }` |
| гард Феміди | `duel replay free: deterministic — same input twice, same hash 2124425716 …; run 1 with the painted effects, run 2 without (Fx.enabled false) — effects change nothing` |
| підсумок | `ALL OK (159 checks) in 19374 frames`, `budget used 19374 / 38000 (51 %)` |
| `make gates` | `БАТАРЕЯ ЗЕЛЕНА` |
| `xvfb-run … -- --screenshot=<scratchpad> --stage bazaar\|fountain\|river` | змах Choko — смарагдовий серп із прозорим тлом; зірка влучання з контуром; пара від гарпуна (не в git) |

**Негатив** — червоні:
- директор штовхає бійця, лише коли ефекти увімкнені → `duel replay free: runs differ, first at frame 60`;
- `Flipbook` ігнорує `Fx.enabled` → `Fx.enabled false still spawned {…}`;
- 24 fps і 8 fps → `cells per step … (want …)`;
- аркуші не знайдено → `the free duel drew no 'spark_hit'`;
- директор не підключено → `drew no 'slash_choko'`.

Перша версія перевірки темпу пропускала 24 fps: дивилась лише на порядок 0…15. Тепер звіряє клітинку на кожному кроці. Перша
версія події «регдол ліг» не спрацьовувала: тіло бійця стоїть на підлозі, поки летить регдол, тож `on_ground()` не перемикається.
Тепер подія — перехід стану LAUNCHED → GETUP / KNOCKDOWN. Обидва місця виправлено до коміту.

## Відомо / не перевірено

- Ще не в грі (наступний PR, бо міняє процедурні частини в чужих скриптах):
  - стікери Printer, `patch_heal`, `seen_mark`, `spring_jump` — `Printer.gd`;
  - кунаї (`KunaiRain.gd`);
  - сторінки гримуара й сигіли ульти Skea (`GrimoireFx.gd`);
  - `weak_mark` (`WeakMarks.gd`);
  - `choko_rewind` (`Fighter.rewind`);
  - `smoke_puff`, `skid_dust`, `speed_lines`, `spark_metal`, `electro_arc*`, `slash_skea`.
- Розміри в метрах і кількість кадрів змахів (8 з 16) — PLACEHOLDER. Тюнінг — на Mac, оком.
- Кути аркушів не повертаю за напрямом руху в 3D: сліди й змахи — біллборди, дзеркалені за `forward.x`. У кадрі «за спиною»
  слід може дивитись не туди. Перевірка оком у «Що перевірити».
- `Afterimage`, `SmearShards`, `SmokeCloud` спавняться з `Fighter.gd` і `Fx.enabled` не слухають. Гард покриває лише нове.

## Що перевірити (Santos)

`make run`, бій проти CPU на Bazaar:
- змах меча Choko малює смарагдовий серп;
- влучання — мальована зірка з контуром;
- деш Skea лишає фіолетовий рваний слід, постріл гарпуна — клуб пари;
- регдол лягає з пилом і тріщиною на підлозі.

## Related
- [[VFX-Direction]] · [[VFX-Sheets-Prompts]] · [[2026-10-03-Sprint-Arenas-VFX]] · [[2026-10-03-sprint-lane-b-vfx]] · [[2026-10-03-Sprint-Lane-I-2]] · [[Textures-Registry]] · [[state]]
