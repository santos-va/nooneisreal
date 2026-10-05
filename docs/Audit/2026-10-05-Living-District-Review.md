# Живий квартал — незалежне приймання

2026-10-05 · T4 Феміда. **GREEN: native, незалежні probes й інтегрована батарея 70/0.** План CP0 `d5f523d` і погоджений CP1 охоплено. BEFORE — незмінний `git archive f4defd5`; AFTER — ізольована копія production-кандидата. Усі12 NPC/world/camera файлів exact SHA256 збігаються з shared freeze (`native-source-manifest.json`), hook6files — з `hook-final-v2/provenance.json`. Аудитор не запускав shared Godot, не змінював production/state й не робив commit.

## Результат для гравця

Мотузка береться в межах 0.70 м від поточної руки до доступного фізичного відрізка. Дальня підказка просить підійти; натискання не витрачає гак. До працівників усіх трьох крамниць можна фізично підійти правим проходом і почати близьку розмову. Бічна панель залишає обличчя й руки NPC видимими; камера повертає попередній ручний огляд після закриття.

Три фантазійні силуети, предмети роботи й невербальні жести перевірено у native renderer. У двох героїв переглянуто всі 1080 кадрів фінальних hook-послідовностей: підготовка/кидок до високої й низької опори, близький хват, перенесення опори, підтягування, відпускання та обмежений у часі фрагмент змотування після промаху. У межах цих ракурсів нового анатомічного блокера немає.

## Перевірки

Durable root для незалежних доказів: `/workspace/nooneisreal-evidence/district-close/`. У таблиці числа — assertions/failures; raw logs перевіряються окремо від exit code і sentinel.

| Напрям | Доказ та результат |
|---|---|
| Rope contact | `contact-independent.log`: **92/0** — owner61 + незалежні31: .699/.700/.701, current/live span, обидва LOS, stale/far без витрати, HANG transfer збереження опори/velocity/довжини, повторні inputs. Мутація threshold назад до2.0 дала31 очікуваних failures. Додаткові checks перенесено в `tools/grapple/contact_check.gd`. |
| Доступ до працівників | `worker-fit-accepted.log`: **58/0**, справжній BodyShape обох героїв, рух approach→door→visit→service усіх3крамниць, clearance/LOS, surface gap і .699/.700/.701, vertical та distant-open negatives. Між крамницями fixture переносить до approach; проходи долаються фізично. |
| UI/камера | Особисто переглянуто **12 фінальних native кадрів** `dialogue-final/`:2герої×3крамниці×720/900. NPC відкритий ліворуч, панель праворуч, колишня віконна перекладина не перекриває сцену. Owner `conversation_camera_check.gd` **81/0** додатково перевіряє реальні сигнали, solid lens/head LOS, reopen, незмінні позиції actor/player, manual yaw/pitch та movement basis після close/exit. |
| Typed save | `save-negative-after.log`: **272/0**, malformed JSON типи/identity/memory, atomic rejection, v1/v2 roundtrip і hero isolation. На baseline той самий probe мав272/0 sentinel **разом із19 SCRIPT ERROR** — це був RED. Typed guards усунули помилки; постійний `npc_save_negative_check.gd` включено в strict runner. |
| Optional local API | `llm-http.log`: **34/0** на справжньому loopback HTTP з контрольованим сервером: default OFF, malformed/oversize/empty/500/redirect/8s timeout, cancel/late callbacks, cooldown/cache. `llm-director.log`: **17/0** — справжній guarded Director, synchronous token race, close/new NPC/hero/exit, ворожа команда у відповіді не змінює progress/population. Постійний wrapper повторив обидва чисті логи у `permanent-http/`. |
| NPC presentation | BEFORE/AFTER однакові12seeds, close-ups трьох типів; особисто переглянуто **всі250 фінальних gesture кадрів** (3мешканці одночасно,5подій) у `after/gestures-final/`. Незалежний actual Director probe виявив стрибок руки2.210rad; після повного scheduler та interrupt/work-return blend максимум **0.337734rad**, `gesture-transition-final.log`. |
| Audio lifecycle | `audio-lifecycle-final.log`: **46/0** — actual head listener, camera2/6/20м, orientation/ownership, старий listener відновлюється, новий не перехоплюється,12PCM buffers/3timbres/ліміти. `living-residents/mix2.log`: AudioEffectCapture RMS **0.038121** при camera2/6/20м, дальній NPC12м дає0. Це engine-mix доказ, не прослуховування обладнання. |
| Hook animation | `living-district/hook-final-v2/`:1080PNG, production hash manifest; усі30послідовних contact sheets переглянуто T4 (`hook-review-final/`). Незалежне порівняння **1080CSV рядків:0відмінностей** фізичної authority до/після, включно з216перезнятими miss рядками. `hook-completion-final.log`: **11498/0**, runtime завершення змотування/refund і14presentation ticks доidle перевірено за межами native108frame capture. |

Усі незалежні фінальні логи з таблиці чисті від SCRIPT ERROR/resource leaks. Окремий mutation-run є навмисно негативним; його failures не видаються за успішний запуск.

## Закриті блокери

1. Save-loader порівнював JSON Variant до перевірки типів:272assertions не зупиняли19runtime errors. Додано typed guards і постійний негативний probe; strict runner читає raw log.
2. Центрована opaque розмова й поперечина вікна приховували нові NPC. CP1 sidepanel + swept conversation framing перевірено в12реальних фінальних кадрах.
3. Scheduler переривав greeting раніше завершення; rapid topics/work return також скидали позу. Повна тривалість, current-pose blend та work-return blend прибрали виміряний2.21rad стрибок.
4. Listener стояв біля далекої камери; teardown міг забрати ownership у нового listener. Тепер джерело слухається від голови героя, а відновлення виконується лише за власного current listener.
5. Hook wrist міг виходити за досяжну ділянку мотузки, а WINDUP читав ще не призначену anchor point. Reach sphere/span intersection і recorded aim усунули це; final native/provenance стосується виправленого `AuthoredHookMotion` SHA256 `26289c995b6f72a620683061d64e703617b763c76b2e6b0108240f4f5b8a8457`.

Перший integrated run мав69PASS/1FAIL: аудіотест із `--fixed-fps60` читав буфер раніше реального AudioServer callback. Runtime production не змінювався; fixture тепер обмежено чекає реальний буфер. Повторний `validation/playable/npc-chatter-mix.log` чистий: 28672 frames для кожної camera distance, RMS0.038121, far energy0.

Фінальний `validation/check-playable.log`: **70 сценаріїв / 0 failures**, smoke **164 checks / 19847 frames**. `validation/gates.log`: **БАТАРЕЯ ЗЕЛЕНА**, **99 GDS / 0 parse failures**. T4 особисто прочитав підсумки та raw logs, включно з final authored-hook11498/0, save272/0, close107/0, presentation1076/0 і camera81/0. Intentional negative controls мають очікуваний rc1; positive logs чисті. Native renderer CI та exact-SHA package перевіряє координатор окремо; вони не підміняються цими числами.

## Відтворення й provenance

Постійні probes запускає `make check-playable`; HTTP перевірка окрема: `GODOT_BIN=/path/to/Godot tools/npc/local_http_check.sh`. Wrapper не зупиняє чужий процес на11434 й відмовляється, якщо порт зайнятий. Джерело відповіді — fixed loopback Ollama API, fixed local tag `qwen3:0.6b`, redirects0, timeout8s, body16KiB, enabled=false за замовчуванням. Generated text не є командою рушію або saved trusted facts.

Native hook capture: `Godot --path ISOLATE/game --rendering-method gl_compatibility --audio-driver Dummy --fixed-fps60 --script ../tools/animation/authored_hook_check.gd -- --capture=OUT`; baseline додає `--baseline`. Miss retake використовує `--scenario=miss`, бо перша fixture помилково не просувала `tick_regen` у busy rewind. Фінальні PNG/CSV зібрані з правильного повтору; це виправлення доказу, не gameplay.

Огляд motion проводився через послідовні native contact sheets без пропуску кадрів, не через заявлене ручне програвання відео. Порівняльний файл `/workspace/nooneisreal-evidence/living-district/hook-before-after.mp4` має21.2s; основні фрагменти60fps, уповільнення окремо позначене. Важкі native/MP4 лишаються поза git; представницькі PNG збережено в `docs/assets/screenshots/2026-10-05-living-residents/` та пов'язано з art/fix docs.

## Приймання пакета

Фінальний production commit — `2a72f9da976d01331c487f131431ee6c116cb692`, версія **0.5.0**, draft PR **#178**. Native source manifest незалежно звірено саме з цим git commit. Після повної батареї координатор повторив HTTP wrapper: **51/0**, `validation/http-wrapper.log`; native Compatibility renderer: **4/0**, `validation/native-renderer.log`, hide delta0.007507 і збережена тінь delta0.006035. T4 особисто прочитав обидва чисті raw logs.

Пакет `/workspace/nooneisreal-evidence/district-close/pck-2a72f9d/living-district.pck`: **208683020 bytes**, SHA256 `26bfc234200c66591af3fc0bafc7c68282f4f24e910f91459caee949cd4ad0df` — незалежно повторно обчислено. `source/game/build_info.cfg` вказує той самий full commit. Import/export logs без engine errors; запуск із окремого порожнього verifier дав **PCK_LIVING_COMPLETE64/0**, version0.5.0, exact revision, renderer=gl_compatibility (`native.log`, `evidence.json`). Це приймання зібраного PCK, не твердження про встановлення його на Mac.

**CI run37250732359 ще виконувався на момент цього доповнення; CI GREEN тут не заявлено.** Останній docs-only commit координатора може мати інший SHA; перевірений gameplay/package SHA наведено вище.

## Межі

Godot4.7 Linux/Mesa llvmpipe/Xvfb — не M3/FPS benchmark. Santos повідомив про прийнятну роботу гри на M3, але installed SHA в тому повідомленні не визначений. Тут немає заяви про30хв ручної гри, hardware audio listening або числовий FPS на Mac.

Actual LLM weights та Reddit заблоковані network allowlist. HTTP51checks доводять протокол/таймаути/ізоляцію, **не якість чи швидкість справжнього inference**. Локальна модель не потрібна для гри й не завантажується автоматично. NPC voice — синтетичне невербальне бурмотіння, не озвучений текст. Багатокористувацька мережа цим пакетом не реалізується.

## Related

- [[2026-10-05-Living-District-Characters]] · [[2026-10-05-Living-District-Session]] · [[2026-10-05-District-Motion-Review]]
- [[2026-10-05-Rope-Contact-Range]] · [[2026-10-05-Close-NPC-Conversations]] · [[2026-10-05-Conversation-Camera]] · [[2026-10-05-Authored-Hook-Motion]]
- [[2026-10-05-Fantasy-Residents-And-Chatter]] · [[2026-10-05-Local-NPC-Models-And-Physics-Reuse]] · [[ADR-004-Physics-Is-Presentation]] · [[recurring_class_register]]
