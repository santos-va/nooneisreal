# Експорт на платформи

## macOS — самостійний застосунок

`game/export_presets.cfg`, пресет **macOS**, збирає `No One Is Real.app` з
Godot **4.7-stable**. Універсальний Mach-O містить arm64 (Apple Silicon/M3)
та x86_64; мінімальний macOS у пресеті — 12.0. Це мінімум пакування й системних
інструментів updater, не твердження про перевірену продуктивність усіх Mac.
Стабільний bundle identifier — `com.santos.nooneisreal`, назва проєкту не змінена.

Поточний експорт **ad-hoc підписаний**, але **не Apple-notarized**: це не Developer
ID і не схвалений App Store реліз. Встановлення не вимикає Gatekeeper, SIP,
перевірку підпису й не запускає рекурсивне зняття quarantine. Якщо macOS блокує
запуск, скористайтесь штатним підтвердженням у Privacy & Security для перевіреної
збірки; апаратне приймання на Mac ще потрібне.

Іконка береться з `game/assets/ui/app_icon.png`, якщо файл існує в вихідному
дереві; інакше пресет явно використовує чинний `game/icon.svg`. Згенерований,
але недоступний для завантаження арт не вважається інтегрованим.

## Збірка

На build-хості потрібні Godot 4.7 stable, офіційний `macos.zip` у каталозі
`export_templates/4.7.stable`, Python 3, tar та zip. На комп’ютері гравця Godot,
Python, git або Xcode не потрібні.

```bash
GODOT_BIN=/path/to/godot tools/distribution/export-macos.sh /absolute/output "$(git rev-parse HEAD)"
```

Скрипт копіює `game/` в тимчасовий каталог без `.godot`, додає SHA джерел у
`NIRBuildRevision` **до підпису**, імпортує й експортує. `ERROR` у журналі блокує
пакування навіть за нульового коду виходу Godot. Перевіряються структура ZIP,
bundle id, SHA у plist, arm64+x86_64 та наявність PCK. `data/audio/*.cfg`
включено явно, бо Music читає звуковий manifest через ConfigFile.

Вихід: `NoOneIsReal-macos.zip`, `manifest.json`, `NoOneIsReal-Installer.zip`,
`import.log`, `export.log`. Installer містить застосунок і manifest для першого
офлайн-встановлення; без вкладеної збірки він завантажує чинний main release.
Фінальна поставка має бути з чистого committed SHA, а не з брудного дерева.

## Оновлення після main

`.github/workflows/macos-main.yml` працює для push у main та ручного retry з main.
Спочатку перевіряє SHA-512 офіційного Godot і шаблонів, `make check-playable`,
`make gates` та adversarial тести updater. Потім експортує застосунок. Окремий
`macos-latest` job перевіряє ZIP, справжній `codesign --verify --deep --strict`,
arm64 та metadata; запускає smoke експортованого застосунку. Лише після цього
publish job має `contents: write`.

Кожен SHA публікується як незмінний prerelease `macos-<40-character SHA>`.
Незавершений draft можна дозавантажити повторно; опублікований архів не
перезаписується. `macos-main/manifest.json` вказує на вже готовий архів із SHA-256
і розміром. Перед публікацією каналу ще раз перевіряється поточний main:
застарілий workflow не відкочує канал. Це конфігурація автоматизації; сам факт
наявності YAML не означає, що GitHub job уже виконався.

## Встановлення та захист даних

Розпакувати installer і відкрити **Install.command**. Він ставить застосунок у
`/Applications/No One Is Real.app`, відкриває його та реєструє per-user LaunchAgent
`com.santos.nooneisreal.update`. Перший інсталятор використовує Terminal для
видимого результату; звичайний запуск `.app` не відкриває термінал.

Застосунок оновлюється при вході й кожні 15 хвилин, лише коли він закритий.
Перевірка імені процесу консервативна: інший процес з точним іменем
`No One Is Real` також відкладе оновлення. Немає доступу запису в `/Applications`
— інсталятор зупиняється з поясненням, не підвищує права мовчки. Автоматичний
updater не запитує пароль адміністратора у фоні.

Завантаження має timeout, curl-ліміт та системний ліміт розміру файла. Updater
перевіряє SHA-256, розмір, metadata, підпис та arm64 до заміни. ZIP із виходом
за app root, traversal, symlinks, спеціальними файлами або керівними символами
відкидається перед ditto. Stage лежить у тому самому `/Applications`; старий
app зберігається в `.No One Is Real.previous.app`. Помилка/сигнал між rename
відновлює попередній app; наступний запуск відновлює backup після kill -9.
Якщо відновлення не вдалося, backup і verified stage зберігаються для ремонту.

Godot `user://` залишається у
`~/Library/Application Support/Godot/app_userdata/No One Is Real/`.
Updater не читає й не змінює ці налаштування, збереження NPC чи інші saves.
Його власні логи: `~/Library/Application Support/No One Is Real/Updater/`.
Вимкнення автооновлень:

```bash
launchctl bootout "gui/$(id -u)/com.santos.nooneisreal.update"
rm "$HOME/Library/LaunchAgents/com.santos.nooneisreal.update.plist"
```

## Відкрите приймання та інші платформи

Локально виміряно Godot 4.7 export та updater tests на Linux. Apple Silicon
запуск, Gatekeeper, LaunchAgent після login, геймпад, FPS/нагрів і слухове
приймання — не підтверджені Linux-експортом. Запуск macOS CI також не замінює M3.

Windows/Linux окремих release-пресетів поки не мають. Android/iOS/Web і консолі
залишаються дорожньою картою; старі твердження про конкретні API, ціни W4 Games
та завершені порти не є поточним прийманням. Один мувсет і чинні дії —
[[05-Platforms-Input]], а не історичне обмеження «не більше дев’яти».

Джерело ключів пресету: Godot 4.7 `platform/macos/export/export_plugin.cpp`
([офіційний код](https://github.com/godotengine/godot/blob/4.7-stable/platform/macos/export/export_plugin.cpp)),
звірено 2026-10-04; `binary_format/architecture`, `application/icon`,
`application/bundle_identifier`, `codesign/codesign=1` — builtin ad-hoc.

## Related

- [[Build-and-Run]] · [[Testing]] · [[05-Platforms-Input]] · [[06-UI-UX]]
- [[ADR-001-Engine-Godot]] · [[Roadmap]] · [[2026-10-02-Engine-Physics]]
