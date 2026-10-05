# Локальні репліки NPC і повторне використання легкої фізики

2026-10-05 · T3 Архімед · джерела прочитано 2026-10-05. Доручення Santos після PR #177: GitHub/Reddit research, локальні NPC без cloud/paid inference; жодної залежності чи моделі в production цим дослідженням не додано.

## Висновок для найближчого пілота

Рекомендується **optional Ollama + Qwen3 0.6B у non-thinking mode** для першого вимірювання; **Qwen3 1.7B** — наступний кандидат якості після перевірки RAM конкретного M3. Це кандидати, а не вже прийняті українські діалогові моделі. LLM створює лише коротку атмосферну репліку з фактів гри. Доручення, винагороди, доступ до місць і зміни світу залишаються детермінованими командами рушія. Гра має негайний змістовний fallback без встановленого backend.

Модель не завантажується автоматично разом із грою і не запускається як прихований сервіс. Локальна мережа не означає автоматично локальну модель: Ollama нині має cloud-функції; для цього режиму потрібні локальний model tag, loopback endpoint і налаштування `OLLAMA_NO_CLOUD=1` у самому backend. Публікацію чи встановлення на Mac Santos не виконано.

## Перевірені джерела та ліцензії

| Компонент | Перевірено | Практичний висновок |
|---|---|---|
| [Qwen3 official README](https://github.com/QwenLM/Qwen3/blob/main/README.md), [офіційний launch post у GitHub](https://github.com/QwenLM/qwenlm.github.io/blob/main/content/blog/qwen3/index.md) | Є dense 0.6B/1.7B, 28 layers, native context32K; Apache2.0. Launch post явно перелічує **Ukrainian** серед119 мов/діалектів. Для ранніх Qwen3 thinking увімкнено за замовчуванням, доступний non-thinking. | Українська підтримка заявлена автором, але якість наших діалогів ще не виміряна. Ліцензію конкретного завантаженого artifact і квантовані ваги ще треба перевірити; мовний перелік не є українським benchmark. |
| [Ollama LICENSE](https://github.com/ollama/ollama/blob/main/LICENSE) | MIT | Ліцензія runtime не підміняє ліцензію ваг. |
| [Ollama API](https://github.com/ollama/ollama/blob/main/docs/api.md) | `/api/chat`: `stream`, `think`, JSON/schema `format`, `keep_alive`; `/api/tags` локальні моделі; `/api/show` metadata/license; `/api/ps` завантажені моделі | Мінімальний власний HTTP-клієнт достатній, великий Godot-LLM plugin не потрібен. `stream:false`, `think:false` спрощують bounded відповідь. |
| [Ollama macOS](https://github.com/ollama/ollama/blob/main/docs/macos.mdx) | Sonoma 14+, Apple M series CPU/GPU; x86 CPU only | M3 підтримується runtime, але RAM/latency разом із грою ще не виміряні. |
| [Ollama FAQ](https://github.com/ollama/ollama/blob/main/docs/faq.mdx) | Default `127.0.0.1:11434`; `OLLAMA_NO_CLOUD=1`; RAM росте з context × parallel requests; `OLLAMA_NUM_PARALLEL` default1; `keep_alive` default5m | Одна активна генерація на гру, короткий контекст; не тримати окрему завантажену модель для кожного NPC. |
| [llama.cpp b11146](https://github.com/ggml-org/llama.cpp/releases/tag/b11146), [LICENSE](https://github.com/ggml-org/llama.cpp/blob/b11146/LICENSE), [README](https://github.com/ggml-org/llama.cpp/blob/b11146/README.md) | MIT; Apple Silicon через ARM NEON/Accelerate/Metal; CPU backend; release v0.5.0 посилається на nightly b11146 | Прозорий standalone варіант для developer proof або майбутнього bundled runtime. Для поточного optional UX Ollama простіший. |
| [llama-server b11146 API](https://github.com/ggml-org/llama.cpp/blob/b11146/tools/server/README.md) | Loopback default, обмеження threads/context/parallel, OpenAI-compatible chat | `/v1/chat/completions` не є `/api/chat`; тест llama.cpp не видавати за end-to-end перевірку Ollama-клієнта. Не потрібні tools/agent/MCP/file access для NPC. |

На поточному етапі **точний розмір ваг та пікова RAM не підтверджені**: доступ до Hugging Face й Ollama library заблокований мережевою політикою цієї cloud-сесії. Назва «0.6B» описує кількість параметрів, а не мегабайти RAM. Не слід перетворювати її на обіцянку «працює в 0.3 GB»: ваги, tokenizer, KV cache, buffers, runtime й гра використовують додаткову спільну пам'ять. Відповідь Santos про RAM/Ollama на M3 очікується через координатора.

## Неблокувальний контракт Godot

API звірено з [HTTPRequest Godot 4.7](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/HTTPRequest.xml), а не довільним addon. `request()` починає запит; відповідь приходить через `request_completed`, `OK` при старті не означає HTTP success. Є `use_threads`, `timeout`, `body_size_limit`, `cancel_request`; timeout за замовчуванням 0 означає нескінченне очікування.

Рекомендація NPC-смузі:

1. Фіксований `http://127.0.0.1:11434/api/chat`, явний opt-in, жодного cloud fallback чи automatic pull. Перевіряти model availability; missing backend/model → чинний authored fallback.
2. `HTTPRequest.use_threads=true`, одна in-flight відповідь, finite timeout, bounded body, заборона redirects; generation token відкидає відповідь після закриття/заміни NPC. Пауза scene tree не має блокувати завершення UI-запиту.
3. `stream:false`, `think:false`, `format` schema `{line: string}`; перевірка JSON/type/довжини після отримання. Контекст містить тільки дозволені факти героя/NPC/доручень. Вивід — plain text, ніколи BBCode/команда/ресурсний шлях.
4. `num_ctx=2048`, `num_predict=96`, line≤240 chars, timeout8s, cooldown2s, cache32 — **початкові tuning assumptions**, запропоновані смугами, не виміри M3. Cold-load може перевищити8s: це fallback, не зависання гри. Окремо виміряти warm і cold latency.
5. Cache key включає героя, NPC, тему, trust і quest digest. Зміна змістовних фактів інвалідує стару відповідь. LLM не приймає/здає quest і не додає credits.

Вбудовувати llama.cpp через GDExtension зараз дорожче: universal macOS binaries/signing, ABI й runtime lifecycle додаються до відповідальності гри. HTTP до керованого користувачем optional процесу відокремлює crash/пам'ять моделі від game loop; сам факт HTTP ще не гарантує добрих відповідей чи відсутності CPU contention.

## Фактична підготовка CPU proof

Поза репозиторієм у `/workspace/nooneisreal-evidence/local-npc-research` завантажено офіційний [Linux CPU archive b11146](https://github.com/ggml-org/llama.cpp/releases/download/b11146/llama-b11146-bin-ubuntu-x64.tar.gz): **16998357 B**, SHA-256 `c150306eb16b5ab696f76a8bdf810c35fd98a24e82158742e6fa28f420ff8410`, збіг із GitHub release asset digest. Розпаковано лише у workspace. Реально виконаний `llama-server --version`: `0.5.0-dev (build 11146, commit 7fe450e19)`, GNU11.4.0 Linux x86_64, rc0. Це доказ працездатності runtime binary, **не inference**: ваги ще не отримано. System/global install не виконувався.

Після доступу до ваг: зафіксувати model revision/quantization/license/hash/bytes; loopback server, context2048, parallel1, обмежені CPU threads; 3–5 коротких українських NPC-сценаріїв, warm/cold wall time, token count, RSS, валідність JSON і ручна оцінка мови/фактів. Окремо перевірити timeout, backend unavailable та пізню відповідь у реальному Godot. Linux CPU заміри не називати M3 benchmark.

## Легка фізика: що справді зменшує роботу

| Кандидат | Факт із джерела | Рішення |
|---|---|---|
| Вбудований Jolt | `game/project.godot` уже має `3d/physics_engine="Jolt Physics"`; [godot-jolt README](https://github.com/godot-jolt/godot-jolt/blob/master/README.md) каже integrated since4.4, extension maintenance mode, MIT | Не додавати другу фізику. Виправлення форми колізій/підвісу не вирішуються заміною пакета. |
| [SpringBoneSimulator3D 4.7](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/SpringBoneSimulator3D.xml) | Вбудований `SkeletonModifier3D`: inertial hair/cloth/tail motion, stiffness/drag/gravity; повертається до authored pose; Y-branched chain не підтримує | Найменша залежність для декоративних кіс/хвостів/смуг тканини, коли модель має потрібні bones. Пілот після перевірки skeleton; не бойова фізика і не заміна анімацій тулуба. |
| [Tshmofen/verlet-rope-4](https://github.com/Tshmofen/verlet-rope-4), [MIT LICENSE](https://github.com/Tshmofen/verlet-rope-4/blob/master/LICENSE) | README прямо Godot4.4 **.NET**, visual simulated rope та rigidbody rope nodes | Не швидка підстановка в наш стандартний GDScript export: вимагатиме .NET stack/нового export-приймання. Відкласти. |
| [PseudoCablePhysics](https://github.com/Elij4hMartin/PseudoCablePhysics-For-Godot), [LICENSE](https://github.com/Elij4hMartin/PseudoCablePhysics-For-Godot/blob/main/LICENSE) | Pure GDScript simple approximation, README4.3+ / demo4.5; zlib-style license text дозволяє commercial use, вимагає не прибирати notice й позначати зміни; Kenney demo assets позначені CC0 | Малий референс для декоративних кабелів. Тестувати поза traversal; не підміняти чинну механіку гарпуна без parity перевірок. На4.7 локально не імпортовано. |

Анімаційні бібліотеки досліджує окрема motion-смуга; уже наявні UAL/Jolt описані в [[2026-10-05-Reusable-Game-Systems]]. Нові physical impulses не мають впливати на правила влучання всупереч [[ADR-004-Physics-Is-Presentation]].

## Reddit і межі доказів

Виконано спробу читання `https://www.reddit.com/r/LocalLLaMA/search.json?q=Qwen3%200.6B&restrict_sr=on&limit=5&sort=relevance`; proxy повернув403. Так само недоступні Hugging Face та Ollama web/docs домени. Runtime environment status підтвердив `restricted/enforced`, preset `package_managers`, без додаткових allowed hosts. GitHub connector дозволив перевірити першоджерела, але не є доступом до Reddit. Жодного вигаданого Reddit-коментаря/треду чи «спільнота підтвердила M3 latency» тут немає. Потрібне штатне оновлення network configuration; proxy не обходився.

Коли Reddit стане доступним, анекдот про M3/0.6B є лише кандидатом для повторення: потрібні точна модель/quant/context, RAM, backend version, cold/warm режим і одночасне навантаження гри. Ці відгуки не заміняють виміру.

## Мінімальний запит до network configuration

У доступних інструментах є лише читання `environment_status`, а не підтриманий засіб зміни policy. Потрібен перегляд користувачем конфігурації cloud environment; редагування локального JSON або зміна proxy не надасть дозволу. Запит розділяється за реальною потребою:

| Робота | Початкові HTTPS hosts для allowlist |
|---|---|
| Model card/API та канонічні Qwen GGUF weights | `huggingface.co` |
| Ollama library/API registry metadata та pull | `ollama.com`, `registry.ollama.ai`; default registry підтверджений у [types/model/name.go](https://github.com/ollama/ollama/blob/main/types/model/name.go) |
| Reddit source reading | `www.reddit.com`, `reddit.com` |
| Web-версія Ollama docs, якщо потрібна | `docs.ollama.com` — необов'язково, бо GitHub docs уже прочитано |

Для ваг цього списку може бути недостатньо: Hugging Face/Ollama віддають large blobs через redirect на CDN/storage. Точні redirect hosts у цій сесії **не спостерігалися**, бо primary CONNECT уже відхилений. Після дозволу primary domains треба прочитати реальні redirect locations і окремо погодити лише потрібні hosts; wildcard «увесь інтернет» та сторонні mirrors не пропонуються. GitHub binary/download уже доступний, тож для мінімального llama.cpp CPU proof достатньо почати з Hugging Face та його фактично виявлених storage redirects. Reddit потрібен для окремого research, не для запуску NPC.

## Відтворюваний локальний тест пізніше

Нижче — **інструкція для майбутнього запуску**, а не звіт про виконаний inference. Вона потребує встановленого користувачем Ollama, достатнього місця/RAM і дозволу завантажити обрану модель. Не виконує cloud inference. Якщо Ollama app уже обслуговує11434, не запускати другий server поверх нього: використати чинний local-only server або окремо узгодити його конфігурацію.

У власній робочій теці, лише якщо11434 вільний, server в окремому терміналі:

```sh
OLLAMA_NO_CLOUD=1 OLLAMA_HOST=127.0.0.1:11434 OLLAMA_MODELS="$PWD/npc-models" ollama serve
```

Другий термінал — явно ініційований download, потім metadata:

```sh
ollama --version
ollama pull qwen3:0.6b
curl --fail --max-time 10 http://127.0.0.1:11434/api/tags > npc-model-tags.json
curl --fail --max-time 10 http://127.0.0.1:11434/api/show \
  -H 'Content-Type: application/json' -d '{"model":"qwen3:0.6b"}' > npc-model-show.json
```

`qwen3:0.6b` — запропонований registry tag; його наявність і точний digest треба підтвердити успішним pull/tags на машині, адже library сторінка тут недоступна. Зберегти `size`, `digest`, `quantization_level`, model license й runtime version. Якщо tag відсутній або license не відповідає очікуваній — не підміняти неперевіреною моделлю мовчки. `/api/tags.size` описує artifact, `/api/ps` — завантажену модель; жоден не є піком RAM усього Mac разом із грою.

Один короткий запит з контрольованими фактами:

```sh
curl --fail-with-body --max-time 15 http://127.0.0.1:11434/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:0.6b","stream":false,"think":false,"keep_alive":"2m","options":{"num_ctx":2048,"num_predict":96,"temperature":0.4},"format":{"type":"object","properties":{"line":{"type":"string"}},"required":["line"],"additionalProperties":false},"messages":[{"role":"system","content":"Ти місцева кравчиня у кварталі Кроншифт. Відповідай українською одним коротким реченням до 240 символів у JSON line. Герой Чоко допоміг сусідам. Не вигадуй нагород чи завершених доручень."},{"role":"user","content":"Добрий день! Як сьогодні живе квартал?"}]}' \
  > npc-reply.json
curl --fail --max-time 10 http://127.0.0.1:11434/api/ps > npc-loaded-models.json
```

Перевірити зовнішній JSON, потім JSON у `message.content`; саме строку `line`, українську мову, довжину й відповідність фактам. Schema обмежує форму, не правдивість. Повторити три рази з різним NPC/context; зберегти cold/warm `total_duration`, `load_duration`, `prompt_eval_count`, `eval_count`, `eval_duration` (Ollama durations у наносекундах за API). Для warm token rate використати `eval_count / eval_duration × 10^9`, а не називати повну wall latency швидкістю генерації. Обмеження15s тут — deadline тесту, не обіцянка latency; у грі може діяти суворіший8s fallback.

Для окремого **llama.cpp**, після легального отримання й перевірки GGUF з канонічного Qwen repo, CPU server b11146 можна запустити так:

```sh
./llama-server -m /absolute/path/to/verified-model.gguf \
  --host 127.0.0.1 --port 8088 -c 2048 -np 1 -t 2 -ngl 0 \
  --jinja --chat-template-kwargs '{"enable_thinking":false}'
```

Шлях GGUF навмисно placeholder: filename/hash не перевірені й не вигадуються. Тут endpoint `/v1/chat/completions`, інший request/response envelope. Для end-to-end Godot acceptance потрібен саме обраний Ollama-контракт або явний окремо протестований adapter; вдавати, що відповіді llama.cpp перевіряють `/api/chat`, не можна.

## Godot 4.7: native audio, cache й межі роботи

Додатковий аудит зроблено за versioned engine API і чинним source, без нових залежностей:

| Джерело | Перевірений факт | Застосування у кварталі |
|---|---|---|
| [Resource 4.7](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/Resource.xml), [ResourceLoader 4.7](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/ResourceLoader.xml) | Повторний load того самого path повертає cached reference, доки він утримується. `load_threaded_get()` блокує, якщо статус ще не `THREAD_LOAD_LOADED`. | Малі спільні текстури preloaded/cached; великі ресурси — request/status/get у правильному порядку. Сам напис «threaded» не усуває stall, якщо негайно зробити get. |
| Чинний `NpcAppearance.gd` до цієї хвилі | `_shape()` створює новий однаковий SphereMesh для кожної частини; `_material()` новий ShaderMaterial для кольору; shape варіація переважно через Node scale | Власний bounded cache immutable procedural Mesh за topology key, material за palette/texture/shader key. Godot path cache не об'єднує довільні `SphereMesh.new()`. Shared material не мутувати для одного NPC; відмінності задавати key або окремою local копією. |
| [MultiMesh 4.7](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/MultiMesh.xml) | Багато mesh instances у спільному об'єкті; спільна видимість/AABB і per-object light limit | Підходить повторюваному статичному декору, але не є автоматичною заміною незалежних articulated NPC. Спільний Mesh зменшує geometry allocation, **не обіцяє один draw call** для всіх MeshInstance3D. |
| [AudioStreamWAV 4.7](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/AudioStreamWAV.xml) | Може містити динамічно згенерований PCM; format/mix_rate/stereo/data — штатні API | Короткий власний chatter генерувати один раз на timbre/варіант і утримувати AudioStreamWAV у cache. Не потрібні TTS, voice cloning чи декодування щокадру. |
| [AudioStreamPlayer3D 4.7](https://github.com/godotengine/godot/blob/4.7-stable/doc/classes/AudioStreamPlayer3D.xml) | `max_polyphony` — **на один node**; `max_distance>0` припиняє непотрібне mixing далеко; hide() не вимикає audio | Глобальна межа2 voices потребує спільного pool/admission control, а не `max_polyphony=2` на кожному з12NPC. Despawn/mute має stop/reset; cooldown і spatial range перевіряються до play. |
| Чинний `Sfx.gd` | Уже є pool12, cached streams, приватний RNG, SFX bus, явне stop/stream=null у cleanup | Повторно використати принципи та чинні audio settings, але не переносити pool12 у новий max2 spatial chatter без власного budget. Presentation randomness не змінює gameplay RNG. |

Contextual dialogue також не потребує щокадрового JSON/prompt: snapshot формується на open/topic/change фактичного state, cache ключ не включає безперервно мінливий час. Рух/анімація NPC й короткий authored fallback не чекають backend. Прийняття performance тут — bounded counts/allocations/voices і відсутність блокувального I/O; реальний FPS M3 потрібно виміряти на пристрої, ці API-факти його не замінюють. Рекомендації передані NPC та art смугам; реалізацію й виміри вони перевіряють окремо.

## Related

- [[2026-10-05-Living-District-Characters]] · [[2026-10-05-Living-District-Session]] · [[2026-10-05-Reusable-Game-Systems]] · [[2026-10-05-District-Motion-Delivery]] · [[2026-10-05-District-Life]] · [[ADR-004-Physics-Is-Presentation]] · [[state]]
