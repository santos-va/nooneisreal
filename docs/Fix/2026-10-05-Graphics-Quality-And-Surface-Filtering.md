# Якість картинки та фільтрація міських візерунків

**Дата:** 2026-10-05 · **Роль:** T2 Гефест · **Статус:** виконано в обмеженій quality-смузі; локальні native та фінальні інтеграційні перевірки пройдено.

За [[2026-10-05-Parkour-Tricks-And-Quality]] додано `QualityProfile` та окремий `GraphicsSettings`. Застосовується лише `Viewport.scaling_3d_scale` і `msaa_3d` кореневого viewport; профіль глобально зберігається між меню, містом і дуеллю. Renderer не перемикається, фізичні об'єкти/частота симуляції/тіні/палітра не змінюються.

| Профіль | Масштаб 3D | MSAA | Задана частка пікселів 3D від High |
|---|---:|---:|---:|
| Low | 0,75 | вимкнено | 0,5625 |
| Medium | 0,85 | 2× | 0,7225 |
| High, типовий | 1,0 | 4× | 1,0 |

Це **PLACEHOLDER** налаштування навантаження, не FPS або пропорційне прискорення. UI рендериться у вихідній роздільності. High зберігає попередні налаштування проєкту. Значення `QualityProfile` повертаються незалежними ресурсами; немає автоматичного вгадування класу пристрою.

`user://graphics.cfg` приймає лише явні String IDs. Відсутній файл дає High без запису; нерозпізнаний ID, неправильний тип або синтаксично пошкоджений файл дає сесійний High, блокує перезапис і зберігає первісні байти. Невідомі поля коректного файла зберігаються. Меню повідомляє про помилку збереження; вибір діє одразу. Кнопка `RESTORE SOUND & SHAKE DEFAULTS` явно відновлює тільки попередні налаштування звуку/струсу.

`city_surface.gdshader` фільтрує фактичну екранну частоту wood grain і двох діагональних складових cloth weave. Амплітуда візерунку згасає від π/2 до π rad/pixel на кожній осі екрана, до межі Найквіста. Старі world-metre fades збережені. Нових текстур, material passes, palette/light/water змін немає.

Предмет: для всіх дозволених профілів перемикання змінює лише презентацію, відповідає фактичним параметрам viewport і не знищує невідновлювані налаштування.

## Перевірки

Власноруч прочитані raw logs і native receipt із `/workspace/nooneisreal-evidence/parkour-quality/quality/`:

| Доказ | Результат | Межа |
|---|---|---|
| `graphics.log` / `tools/settings/graphics_check.gd` | **63/0**, Godot 4.7 | Schema, повторні зміни реального root viewport, незалежні profile resources, atomic save, corrupt-byte preservation. |
| `graphics-ui-04.log/.rc` / `tools/ui/graphics_ui_check.gd` | **15/0**, rc0 | Реальні `Input.parse_input_event` клавіатура та синтетичні joypad events: focus, popup selection, apply/save, cancel, reopen, sound/shake restore. Не фізичний контролер. |
| `native-01.log/.rc`, `native/receipt.json` | **44 PNG/0**, rc0 | Godot 4.7, Compatibility, Mesa llvmpipe. Тільки відоме попередження про unsupported VSync; shader/script errors немає. |
| `city-style-01.log/.rc` | **26/0**, rc0 | Near joints, world-scale density, ambient isolation, far fading, material identity. Near edge energy **0,006091**, far **0**, peak palette **0,741176**. |

Рання UI спроба із nested SubViewport не проходила joypad navigation. Godot 4.7 `PopupMenu::_input_from_window_internal` перевіряє focused window та `Input.is_action_just_pressed_by_event`; `SubViewport.push_input` не є повним маршрутом глобальної події. Остаточний fixture використовує реальний кореневий Window і лише `Input.parse_input_event`. Production D-pad override не додано. `graphics-ui-03.log` зберігає невдалий 15/6 результат; це не evidence приймання.

У всіх трьох `street_entry` кадрах receipt фіксує **527 draw calls / 515 visible objects / 87550 primitives**, output image **1280×960**. Відрізняються реально застосовані scale/MSAA: **0,75/0**, **0,85/1**, **1/2**. У frozen production player pair — **1860/1848/136506** в обох профілях. Таким чином зміна профілю не прибирає геометрію сцени; **0,5625/0,7225/1** — задані частки pixel workload за масштабом, а не виміряний розмір внутрішнього render target, час GPU чи FPS.

`native/pixel-delta.json` зіставляє однакові native камери до/після shader filtering у вихідних 8-bit PNG:

| Вигляд | Змінені пікселі | Найбільша різниця каналу |
|---|---:|---:|
| Wood, близько | 0 | 0/255 |
| Cloth, близько | 31 | 1/255 |
| Wood, grazing | 4006 | 2/255 |
| Cloth, grazing | 37811 | 6/255 |
| Canopy underneath | 45106 | 4/255 |

Це обмежена зміна дрібного візерунку, не доказ FPS чи повного усунення temporal aliasing. Є вісім baseline/candidate pan-пар із фактичним пересуванням камери. Автор особисто переглянув `high_canopy_underneath`, `high_cloth_grazing`, `high_production_player_camera`; незалежний художній висновок належить [[2026-10-05-Traversal-And-Surface-Review]]. Палiтра та локальна близька фактура збережені. `quality-source-manifest.json` фіксує SHA256 восьми файлів смуги після локальних запусків; загальний manifest координатора визначає фінальний інтеграційний зріз.

Фінальні `review-check.log/.rc` і `review-gates.log/.rc` у `/workspace/nooneisreal-evidence/tricks-quality/final/` особисто прочитані T2: **smoke 164/19847**, **119 GDS/0**, **175/175 assets**, **0 broken wikilinks**, обидва **rc0**. Власне порівняння `review-source-before.json`/`review-source-after.json` підтвердило незмінні **808 sources**, aggregate SHA256 `c5b5d42190c355cb4b416914bed8f5941d1b57a9a7def29e8311734865b7f024`. Усі вісім файлів локального quality manifest точно збігаються з цим фінальним зрізом.

Незалежний T6 висновок прочитаний у [[2026-10-05-Traversal-And-Surface-Review]]: на оглянутих High/Low кадрах нових quality-blockers немає; Medium окремо художньо не приймався. Low має видимі сходинки й м'якшу 3D-картинку, HUD лишається різким. Значного візуального поліпшення або виміряного прискорення не заявлено.

Фінальний `make check-playable` завершений: особисто прочитані `check-playable.log/.rc` підтверджують **93 сценарії / 0 failures**, **rc0**. У нефільтрованих `engine-raw/` logs власноруч прочитано graphics **63/0**, actual-input UI **15/0**, independent graphics **62/0**; deliberate `--break=apply` має рівно **2 очікувані відмови** для live Low/Medium та **rc1**, як і вимагає runner. Це підтверджує, що перевірка бачить фактичне застосування viewport, а не лише збережений ID.

Власний скан усіх **95 raw logs** не знайшов error/warning/leak markers або ненульових rc у позитивних запусках; **14** deliberate negative runs мають очікуваний **rc1**. Прочитаний `full-raw-scan.json` координатора фіксує **0 unexpected** із врахуванням конкретних negative assertions. `playable-source-before.json`/`playable-source-after.json` повторно власноруч порівняні: ті самі **808 sources**, той самий aggregate hash. Інтеграцію quality-смуги завершено.

Встановлений macOS застосунок, Forward+/M3 frame-time та фізичний контролер цими Linux результатами не перевірені. Виявлений тісний camera corner паркурної смуги описано окремо у [[2026-10-05-Traversal-And-Surface-Review]]; quality-профілі не оголошуються його виправленням.

## Related

- [[2026-10-05-Parkour-Tricks-And-Quality]] · [[2026-10-05-Parkour-Tricks-Session]] · [[2026-10-05-Traversal-And-Surface-Review]] · [[2026-10-03-Behaviour-Cloth-VFX-Shaders]] · [[state]]
