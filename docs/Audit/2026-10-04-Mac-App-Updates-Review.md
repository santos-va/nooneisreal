# macOS app updater — незалежний T4 review

**GREEN — перевірена реалізація updater/export; YELLOW — приймання на справжньому Mac ще відкрите.** Загальний вердикт YELLOW обмежений платформною перевіркою, а не запитом нового дозволу. Аудитор не змінював production, workflow чи state.

## Що перевірено власноруч

| Статус | Команда / джерело | Доказ |
|---|---|---|
| GREEN | GitHub connector `github_get_repo(repository_full_name="santos-va/nooneisreal")` | `visibility=public`, `default_branch=main`, `archived=false`; installer не потребує секретів |
| GREEN | `bash -n tools/distribution/{update-macos.sh,export-macos.sh,Install.command}` | rc0 |
| GREEN | `python3 tools/distribution/test_distribution.py` | **14 tests / OK**: archive guards, checksum/size/revision, running app, transaction recovery, stale lock |
| GREEN | `python3 /tmp/nir-update-review/review_mock.py` | **8/8** незалежних сценаріїв на фактичній updater-функції з реальними тимчасовими файлами й mock macOS API |
| GREEN | Shell validator на 10 незалежних ZIP fixtures у `/tmp/nir-update-review/` | Правильний ZIP прийнято; parent/absolute/symlink/FIFO/backslash/colon/newline/sibling і великий symlink ZIP відхилено |
| GREEN | `package-macos.validate` на `/workspace/scratch/mac-app-build/NoOneIsReal-macos.zip`, потім shell validator | Реальний export **265941783 bytes**; metadata, SHA256, arm64+x86_64, PCK відповідають manifest; обидва валідатори прийняли |
| YELLOW | Native macOS codesign/lipo/LaunchAgent/Gatekeeper, запуск на M3 | У цьому Linux-середовищі не виконувалися; CI job налаштований, його успішне виконання ще не підтверджено |

Незалежні 8 сценаріїв використовували шляхи з пробілами: успішне встановлення; хибний checksum; гра працює до завантаження; гра запускається під час завантаження; невдалий другий rename; TERM між rename; застарілий порожній lock; відновлення backup після попереднього обриву, за яким новий download не проходить checksum. Попередній app збережено в усіх відмовах; lock очищено. `codesign`, `lipo`, `PlistBuddy`, `ditto` та інші macOS API були mock/еквівалентами — це **не** доказ native приймання.

Перевірений реальний ZIP мав revision `e27b746c63fe2ec6ac363b843cd33e41c44888ef` і був проміжним export до фінального коміту та іконки. Його перевірка не підтверджує SHA або байти майбутнього фінального installer.

## Виправлені findings

**P1 — великий ZIP приховував symlink через SIGPIPE.** Початкове `zipinfo -l | grep -Eq` під `pipefail` повертало false після раннього виходу grep і SIGPIPE виробника; validator помилково приймав архів. Власний `/tmp/nir-update-review/many-link.zip`: 20001 запис, перший — symlink, початковий rc0. Виконавець зберіг повний listing перед grep; той самий ZIP тепер rc1. До штатної батареї додано regression на великий symlink archive. Нові рядки/контрольні символи в іменах також відхиляються з урахуванням caret-екранування zipinfo.

**P2 — переривання між двома rename.** Початковий cleanup не повертав backup, якщо процес отримав TERM після переміщення старого app. Фінальний cleanup має rollback; невдале відновлення залишає backup і stage, наступний запуск відновлює app після некерованого обриву. Власний injected TERM дав exit130 зі збереженим старим app. Це recoverable transaction із коротким проміжком між rename, **не** атомарний filesystem exchange.

## Огляд довіри й життєвого циклу

- Отримання тільки HTTPS; розмір обмежено curl і file-size limit; перевірено SHA256 і розмір до розпакування. Revision — 40 hex, а URL формується кодом, не береться довільно з manifest.
- Спочатку перевіряються archive paths/types, потім bundle identifier, executable, revision, codesign і arm64. Єдина app root; зовнішні шляхи та symlinks не допускаються.
- Stage і app лежать на одному volume `/Applications`; старий bundle лишається backup. Окреме Godot `user://` зі збереженнями/налаштуваннями не змінюється.
- Запущена гра перевіряється перед download та перед replacement. `pgrep` за назвою консервативний: інший процес із тією самою назвою теж відкладе update. Між фінальною перевіркою процесу й rename лишається мале race-вікно; механізм не є OS-level блокуванням запуску.
- Installer/updater потребують лише штатних macOS shell tools; Python — залежність build/tests, не користувацького installer. Шляхи HOME/XML передаються через `plutil`, а не текстову інтерполяцію plist.
- Workflow: main-only, build із `contents: read`, publish із окремим `contents: write`. Офіційні Godot downloads перевіряються SHA512. Publication чекає game checks, updater tests і native macOS verify/exported-smoke job.
- Архів має окремий tag `macos-<SHA>`; опубліковані build assets workflow не перезаписує. Mutable `macos-main` містить manifest-покажчик; перед його зміною двічі перевіряється актуальний main. GitHub repository/release admin залишається довіреною стороною — це не криптографічно незмінне сховище.

## Межі передачі

Немає доказу встановлення в Applications користувача, запуску LaunchAgent, Gatekeeper-проходження, Apple notarization або перевірки фінальної іконки. Build ad-hoc signed, не Apple-notarized; системні захисти скрипт не вимикає. Безуспішний native CI зупинить автоматичну публікацію. Фінальні bytes/SHA перевіряються після фінального export; root запускає гейти після завершення документації.

## Related
- [[2026-10-04-Mac-App-Updates]] · [[2026-10-04-Mac-App-Session]] · [[Build-and-Run]] · [[Export-Platforms]] · [[constitution]]
