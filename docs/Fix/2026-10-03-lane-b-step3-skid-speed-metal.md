# Fix-журнал — смуга B, крок 3: пил ковзання, лінії швидкості, іскри блоку

**Роль:** T2·B Гефест, 2026-10-03. Santos: «T2·B». **План:** [[2026-10-03-Sprint-Arenas-VFX]] рядок B (approved).
**Хендоф T1:** [[2026-10-03-T1-Arena-Depth-Audit]] — Н4 → Н5 → Ф0.3. Цей крок — частина Н5 (3 з 6 аркушів). **Помилка
порядку:** журнал аудиту прочитав уже після коду — Н5 зроблено раніше за Н4. Н4 — наступний PR.
**Попереднє:** [[2026-10-03-lane-b-flipbooks]] (частини 1 і 2 — у `main`: #129, `2767a87`).

## Звірка

- Гілку `claude/friendly-ritchie-3ti2sm` (PR #153 змерджено) перезапущено від `origin/main` `9ec5571`.
- Поза грою лишались 6 аркушів (`docs/Fix/2026-10-03-lane-b-flipbooks.md` § Не перевірено). Для кожного — чи є подія в бою:

  | аркуш | призначення в реєстрі | подія | беру? |
  |---|---|---|---|
  | `skid_dust` | «гальмування і ковзання вздовж стіни арени» | `Fighter._soft_wall()` знімає радіальну швидкість, бієць ковзає по колу `ARENA_RADIUS` | так |
  | `speed_lines` | «швидкий рух, прольот гарпуна» | вхід у `State.GRAPPLE` (зіп до якоря, `GrappleHook.drive`) | так |
  | `spark_metal` | «блок, удар меча об меч» | `Arena._on_hit(..., blocked=true)` | так |
  | `slash_skea` | «хрест кунаїв Skea (легкі/важкі)» | звичайні Skea — `jab_elbow`, `roundhouse`, `low_kick`, `flying_knee` (`grep 'id = ' game/data/characters/skea.tres`): лікоть і кіки, не кунаї | ні — розвилка Аполлон/Арес |
  | `electro_arc*` | «електро (С4 Santos)» | у бою електро немає | ні — розвилка Santos |
  | `smoke_puff` | приземлення, деш | приземлення вже `dust_land`; поверхні — запуск 9 (`surface` стадій — Арес) | ні — запуск 9 |

- `Fighter.gd` не чіпаю: директор лише читає стан (як у кроці 2).

## Що зроблено

`game/scripts/fx/FxDirector.gd` (лише читає стан; `Fighter.gd` не чіпав):

| подія | як розпізнаю | аркуш |
|---|---|---|
| ковзання вздовж м'якої стіни | `wall_slide_speed()`: вільний рух, на землі, `|xz| ≥ ARENA_RADIUS − 0.05`, дотична швидкість ≥ `SKID_SPEED` 2.5 м/с | `skid_dust` 1.6 м біля ніг, раз на `SKID_EVERY` 20 кадрів, дзеркало за `velocity.x` |
| зіп до якоря | вхід у `State.GRAPPLE` | `speed_lines` 2.2 м, дитина бійця (летить разом), дзеркало, якщо якір лівіше |
| заблокований удар | `hit_spark(..., blocked=true)` | `spark_metal` 1.4 м, MIX, поверх синього ряду `spark_hit` |

`SKID_SPEED`, `SKID_EVERY`, розміри — PLACEHOLDER (тюнінг оком). У знімок `_snap` додано `velocity` (індекс 11).

## Перевірка

- `make check` → `[smoke] OK  lane B step 3: skid dust only when grounded on the wall circle and sliding along it (6 cases), twice in 20 frames; speed lines ride a zip once; spark_metal on the blocked hit only`; `ALL OK (164 checks) in 19944 frames`.
- Гард «лише картинка»: `duel replay free run 1/2` → той самий хеш `945147940`; у вільній дуелі тепер `"speed_lines": 1`.
- `make gates` → `БАТАРЕЯ ЗЕЛЕНА`.
- `ERROR: 26 resources still in use at exit` — є і на `main` без моїх змін (`git stash` → `make check`), не з цього кроку.

**Предмет:** для всіх бійців і кадрів: `skid_dust` ⇔ на землі ∧ на колі ∧ дотична швидкість ≥ поріг; `speed_lines` — один раз
на вхід у GRAPPLE; `spark_metal` ⇔ удар заблоковано.

**Негатив** — 6/6 червоні (злам → `make check`):
- без умови «на землі» → `skid 'air' = true`;
- повна швидкість замість дотичної → `skid 'into the wall' = true`;
- без умови кола → `skid 'inside' = true`;
- `spark_metal` на кожен удар → `spark_metal drawn 2 times (want 1)`;
- `speed_lines` щокадру в GRAPPLE → `drawn 2 times`;
- без кулдауну → `skid_dust drawn 3 times (want 2)`.

**Не перевірено.** На екрані не бачив: ковзання вздовж стіни й блок у дуелі smoke не трапились (`skid_dust`, `spark_metal`
у лічильнику дуелі — 0); перевірено лише прямим викликом `_events` / `hit_spark`.

## Лишилось у Н5 — розвилки, не мої

- `slash_skea` (кунаї X) — звичайні Skea без кунаїв: Аполлон/Арес — на що його класти.
- `electro_arc*` — електро в бою немає (С4 Santos).
- `smoke_puff` — приземлення вже `dust_land`; поверхні — запуск 9 після `surface` стадій Ареса.

## Що перевірити (Santos)

`make run`, вільний рух, Bazaar: добігти до краю кола й бігти вздовж — пил біля ніг; гарпун на якір — лінії швидкості
летять разом; затиснути блок під ударами — жовті металеві іскри.

## Related
- [[2026-10-03-Sprint-Arenas-VFX]] · [[2026-10-03-lane-b-flipbooks]] · [[VFX-Sheets-Prompts]] · [[Textures-Registry]] · [[state]]
