# Fix-журнал — фаза 1: керування, звук, арена на воді

**Роль:** T2 Гефест. **План:** [[2026-10-03-Production-Plan]] § Фаза 1. **Гілка:** `claude/friendly-ritchie-3ti2sm`.

## Звірка плану з репо (до роботи)

- Godot у контейнері не було (`which godot` → порожньо). Поставлено `Godot_v4.7-stable_linux.x86_64` з GitHub
  Releases у `/opt/godot`; `godot --version` → `4.7.stable.official.5b4e0cb0f`.
- Базова лінія: `make check` → `SMOKE ЗЕЛЕНИЙ`, 20 перевірок; `make gates` → `БАТАРЕЯ ЗЕЛЕНА`
  (wikilinks 0 зламаних, реєстр 24/24, ролі 8, GDS 31 файл).
- Усі шляхи з таблиці фази 1 існують (`InputRouter.gd`, `MainMenu.gd`, `Hud.gd`, `Sfx.gd`, `Backdrop.gd`,
  `GameState.gd`, `Fighter.gd`, `RigAnimator.gd`, `HitSpark.gd`, `CharacterData.gd`); нові (`WaveField.gd`,
  `water_toon.gdshader`, `tools/audio/build_sfx.sh`) — створюються.
- Дрібні розбіжності, не блокують: план 1.2 каже `.ogg`, а наявні SFX — `.wav` і `Sfx.gd` вантажить лише
  `.wav` → `Sfx` вчиться обом розширенням. `~/Downloads/nir-audio/` у хмарі немає → `build_sfx.sh`
  перевіряю на синтетичних zip-ах, реальний прогін — на Mac у Santos.
- `water_balance` — число бою (зона Ареса), але значення 0.85 дав Santos ([[Stage-River]]); пишу з
  позначкою PLACEHOLDER.

## 1.1 Профілі клавіатури SOLO / SHARED

- `InputRouter.gd`: при старті знімає клавіатурні події кожної `p1_/p2_` дії з `project.godot` (це SHARED),
  `apply_profile()` перебудовує лише клавіатурну половину `InputMap`; геймпад не чіпається. SOLO: P1
  `A D W/Space S LShift(dash) E(grapple) · J K L U I O`, P2 без клавіш. Профіль у `user://settings.cfg`
  (`[input] keyboard_profile`), дефолт SOLO.
- `_input()` теж пише натиски в буфер — тап коротший за фізкадр не губиться.
- Меню: кнопка `KEYBOARD: ◂ SOLO / SHARED ▸`, футер і HUD-підказка беруться з `InputRouter.hint_text()`.
- Smoke: інваріант профілів + справжні `InputEventKey` через `Input.parse_input_event`:
  SOLO `J` → P1 `light`, SHARED `K` → P2 `jab_elbow`. `make check` → 23 перевірки, зелений.
- Предмет: для всіх профілів P і всіх клавіш k: k веде рівно до однієї дії, і в SOLO жодна дія P2 не має клавіші.
- Негативний контроль (3 форми, кожна → `[smoke] FAIL`, файл відновлено):
  A) `J` віддано `p2_light` → «P2 has key J in SOLO»; B) `apply_profile` не стирає старі клавіші →
  «key E in both p1_skill2 and p1_grapple»; C) SOLO light на `F` → «J did not start a P1 attack».

## Related
- [[2026-10-03-Production-Plan]] · [[ADR-009-Solo-Keyboard-Layout]] · [[05-Platforms-Input]] · [[07-Audio]] · [[Stage-River]] · [[state]]
