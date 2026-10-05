# Співрозмовник видимий поруч із панеллю

T2 Гефест · доповнення CP1 до [[2026-10-05-Living-District-Characters]]. Native приймання виявило два накладені дефекти: центральна панель закривала мешканця, а огляд ззовні крамниці проходив через віконну раму. NPC-смуга перемістила адаптивну панель праворуч; цей документ описує камеру.

## Реалізація

Director повідомляє `conversation_started(actor)` / `conversation_ended`; CityWorld підключає їх до `CityCamera.begin_conversation(actor)` / `end_conversation()`. `CityConversationFrame` перевіряє вісім близьких напрямів від співрозмовника у бік гравця. Сфера перевіряє шлях лінзи й зміщення pivot; промені — голову/торс NPC і голову гравця. Додатковий штраф відсікає ракурс, де торс гравця закриває обличчя NPC. Обраний ракурс лишається стабільним під час розмови.

NPC розміщується приблизно на 35% ширини екрана, панель — праворуч. Базова дистанція 2.8 м і перехід 0.25 с позначені презентаційним **PLACEHOLDER**. Під час входу/виходу інтерполюється лише presentation transform руки камери. Pivot також проходить sphere sweep, остаточне положення камери продовжує визначати чинний SpringArm3D. Геометрія вікон, колізії та позиції обох акторів не змінюються.

Поля ручного yaw/pitch у HarpoonAim не переписуються. Нормальний локальний offset зберігається окремо; після закриття зникають conversation yaw/roll і повертається звичайний огляд. InputRouter отримує ту саму горизонтальну основу; під час діалогу керування, як і раніше, приглушене UI. Reset скидає presentation, вихід зі сцени відновлює матеріали близької камери та очищає view basis. Попередня політика близької камери з [[2026-10-05-Camera-Proximity]] збережена.

## Перевірка

Предмет: для всіх перевірених близьких розмов камера робить обличчя доступним ліворуч від панелі, зберігаючи solid collision, actor positions та ручний огляд після закриття.

`tools/camera/conversation_camera_check.gd`: **81/0 headless** і **81/0 native Compatibility**. Реальні `open_conversation`/close signals, усі три працівники й вуличний мешканець, 1280×720 та 1600×900. Перевірено head LOS, screen bounds, sphere overlap лінзи, незмінні позиції, приглушене orbit input, close/reopen, відновлення локального yaw/roll і рухової основи, exit cleanup. Новий scenario доданий до загального runner без зміни його execution logic чи старих негативних контролів.

Native кадри особисто переглянуті: працівник, голова й жест видимі; камера крамниці стоїть усередині приблизно на z=15.306 м, а не дивиться через фронтальне вікно. `head_screen.x≈0.35`, всі перевірені solid LOS чисті. Докази: `/workspace/nooneisreal-evidence/living-district/conversation-camera/`, вісім PNG і `trace.json`. У цьому capture фізичні кадри виконані послідовно, native рендер викликається через `RenderingServer.force_draw()` для кінцевого кадру кожного випадку; це не відеодоказ усього переходу. Незалежний прохід гравця, повні рухомі кадри й відчуття переходу перевіряє T4/арт-смуга.

Пакетний verifier `tools/distribution/living_district_pck_check.gd` також вимагає нового `CityConversationFrame.gd` з фактичного PCK, разом із новими hook/NPC скриптами та попередніми camera shaders. Версія/revision/JSON/audio й native shader compilation перевіряються з порожнього verifier directory; autoloads надходять лише з packed project. Позитивний exact-SHA export запускає координатор після source commit, окремо від checkout-перевірок.

## Related

- [[2026-10-05-Living-District-Characters]] · [[2026-10-05-Living-District-Session]] · [[2026-10-05-Living-District-Review]] · [[2026-10-05-Camera-Proximity]] · [[2026-10-05-Rope-Contact-Range]] · [[Build-and-Run]]
