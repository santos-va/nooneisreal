# Fix-журнал — збірка Prototype 0.1

**Роль:** T2 Гефест. **План:** [[2026-10-02-Prototype-0.1]].

- Godot 4.7-stable завантажено в контейнер з GitHub Releases (`Godot_v4.7-stable_linux.x86_64`), версія підтверджена `--version`.
- Парс-еррори при першому прогоні: `RigAnimator._set` і `Sfx._get` збігалися з віртуалами `Object` → перейменовано на `_pose_set` / `_stream`. Клас №1 у [[recurring_class_register]].
- `--check-only` без autoload-глобалів дає хибні помилки → фільтр у `gd_check_all.sh`, smoke-тест як авторитет. Клас №2.
- Smoke-тест (`-- --smoke`) 11/11; `make check` зелений. Рендер під llvmpipe/Xvfb стартує (OpenGL 4.5 Compatibility).
- Фони/картки не завантажено: CDN cloudfront закритий для контейнера → `tools/fetch_assets.sh` для локальної машини; фолбек-шейдер фону в грі.

## Related
- [[state]] · [[Testing]] · [[Build-and-Run]]
