# 2026-10-04 — керування та виразний бій

**Хто:** Santos · T1 Дедал · п'ять агентів T2 · незалежний T4.
**Контекст:** пряме доручення аудиту й виправлення руху, мотузки, ривків, комбінацій, мечів, ульт і rematch.

## Що вирішили

План [[Plans/2026-10-04-Combat-Control]] схвалений обсягом прямого запиту. Розділено власність файлів, Fighter має одного автора. Пріоритет — інверсія вводу, потім фізика й ресурсні правила, потім презентація. Нові балансні числа крім явних побажань — PLACEHOLDER. Немає витрат, публікації чи merge main.

## Відкриті межі

Start-Here знайшов T4 у локальній git-історії. До змін гри виконано fast-forward `a0fbffc`→`65435de`, прочитано всі handoff сторінки; агенти повторили аудит актуальної бази. Системний Godot був4.6.3; офіційний4.7 завантажено й розпаковано поза repo, `--version` → `4.7.stable.official.5b4e0cb0f`. Перевірки використовують саме його. Ігрове приймання анімацій/ваги на Mac не підмінюється тестами.

## Перевірений результат

Godot4.7: `make check-playable` → rc0, smoke164/19847кадрів,40сценаріїв/0провалів. T4 власноруч виконав `make gates` → rc0,60GDS/0parse,171/171asset registry. Логи в `/workspace/nooneisreal-env/combat-control/`, результати перенесені у git-документи; ця external тека не є переносимою залежністю.

Native llvmpipe capture після виправлень → rc0,13PNG, sentinel COMBAT_VISUAL_CAPTURE_COMPLETE, без runtime/resource errors (лише unsupported VSync). Оглянуто back/draw/dust, форми, front-side spin/contact/recovery, seated crossed-leg hover і хвилю. Це постановочні кадри реального renderer; не доказ фізичного вводу чи комфортного руху на M3. Headless probes перевіряють live dispatcher/recorded input окремо.

Після зеленого прогону аудит знайшов край переривання довшого dash: flashing має скидатися при виході зDASH уhitstun/pull. Власник додав вузьке виправлення й регресію receive_hit/pull. Остаточний повтор: control549/0, `make check`164/19847кадрів rc0, `make gates`60GDS/0 rc0; логи `control-interrupt-final.log`, `check-interrupt-final.log`, `gates-interrupt-final.log`.

Робота лишається локальною, без commit/push/merge або публікації. Головна наступна дія користувача — playtest ваги/рухів на Mac; технічні тести не замінюють художнього приймання.

## Related

- [[Plans/2026-10-04-Combat-Control]] · [[2026-10-04-Combat-Control-Review]] · [[ADR-022-Combat-Control-And-Match-Resources]] · [[state]] · [[constitution]]
