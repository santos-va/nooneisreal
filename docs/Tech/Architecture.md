# Архітектура Godot-проєкту

`game/` — Godot 4.7, GDScript, Forward+ (desktop) / Mobile (мобільні), Jolt, 60 Гц.

```
game/
  project.godot            автолоади, інпут-мапа, фізика, рендер
  scenes/main/Main.tscn    бут → меню або --smoke / --screenshot
  scenes/ui/MainMenu.tscn  меню (код у scripts/ui/MainMenu.gd)
  scenes/arena/Arena.tscn  арена: env, сонце, підлога, стіни, фон, якорі-ліхтарі, камера, HUD, MatchFlow
  scenes/fighter/Fighter.tscn  CharacterBody3D + Rig(RigAnimator) + Hurtbox + HitboxDebug + GrappleHook
  scripts/core/            GameState · InputRouter · Sfx · Main · SmokeTest · Screenshot
  scripts/fighter/         Fighter (стейт-машина) · RigAnimator (процедурний риг) · Ragdoll · CpuBrain · MoveData · CharacterData
  scripts/grapple/         GrappleHook
  scripts/arena/           Arena · FightCamera · Backdrop · MatchFlow
  scripts/ui/              Hud · MainMenu
  scripts/fx/              HitSpark
  shaders/                 toon · outline · backdrop · backdrop_fallback
  data/characters/*.tres   Choko, Skeasse (MoveData як саб-ресурси)
  assets/                  audio/sfx (є) · backgrounds, characters/cards (fetch_assets.sh)
```

## Потік кадру (60 Гц)

`InputRouter` (пріоритет −100) фіксує just_pressed у буфер 6 кадрів → кожен `Fighter` читає
наміри (`buffered()` споживає натискання лише коли може діяти) → стейт-машина → `move_and_slide`
→ `_post_move` (межі арени, push-box) → `RigAnimator.tick` (пози + спринг-флінч). Хітбокс —
`intersect_shape` на активних кадрах; `receive_hit` на жертві; `hit_landed` → камера, HitSpark.

## Автолоади

- `GameState` — конфіг матчу (персонажі, стадія, CPU, тренування), реєстр стадій, роутинг сцен.
- `InputRouter` — дії `p{1,2}_*`, буфер, віртуальний ввід для CPU і тестів.
- `Sfx` — пул плеєрів, кеш, без-файлу = тиша.

## Дані

`CharacterData` (`.tres`): статі, кольори плейсхолдера, мувсет (8 `MoveData`), гарпун, пасивка.
Редагується в інспекторі Godot або текстом. Числа `PLACEHOLDER` — див. [[02-Combat-System]].

## Що замінити у фазі 2

`RigAnimator` (капсули) → `Skeleton3D` з GLB + `AnimationTree`; `Ragdoll` → `PhysicalBoneSimulator3D`
на тому ж скелеті ([[Active-Ragdoll]]). Інтерфейс для `Fighter` лишається: `tick`, `flinch`,
`flash`, `part_snapshot`.

## Related
- [[Build-and-Run]] · [[Testing]] · [[02-Combat-System]] · [[04-Grapple-System]] · [[Cel-Shading]]
