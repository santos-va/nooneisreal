# План анімацій бою

Santos 2026-10-02: «атаки ножів і анімації бою слабкуваті — потім». Тут — як їх підняти, по черзі.

## Крок 1 — підсилити те, що є (без нових ассетів, фаза 1–2)

Процедурний капсульний риг ([[Architecture]]) отримує принципи анімації:
- **Замах (anticipation):** 2–4 кадри назад перед стартапом; зараз поза просто «доїжджає».
- **Перельот і віддача (overshoot/follow-through):** кінцівка проходить далі цілі й пружинить назад.
- **Крок 12 fps на швидких ударах:** поза оновлюється раз на 2 кадри — «мальований» ритм; хітбокси лишаються 60 Гц.
- **Смір-кадр:** 1 кадр розтягнутої кінцівки + дуга удару (спрайт `vfx-slash-arcs`) на активному кадрі.
- **Реакції на удар за зоною:** удар у голову / корпус / ноги дає різні флінчі (зони вже є — пасивка Skea).
- **Ножі Skea:** окремі дуги для джеба, ліктя й кунай-тички, блиск металу на активному кадрі.

## Крок 2 — справжні моделі (фаза 3)

Лист T-pose → `multi_image_to_3d` з ригом ([[Asset-Manifest]]) → кліпи з бібліотеки Meshy в Higgsfield.
Група Fighting, id звірено 2026-10-02 через `animation_actions`:

| призначення | id · назва |
|---|---|
| Стійка | 89 Combat_Stance |
| Джеб / удари руками | 96 Kung_Fu_Punch · 92 Double_Combo_Attack · 105 Triple_Combo_Attack · 90 Counterstrike |
| Ноги | 103 Simple_Kick · 94 Flying_Fist_Kick |
| Меч (Choko) | 97 Left_Slash · 102 Sword_Judgment · 4 Attack · 147 Sword_Parry |
| Блок | 138–146 Block1…Block10, **`Block7` немає** (143 = Block6, 144 = Block8) — [[2026-10-03-Animation-Sources]] |
| Ухил | 156/157 Stand_Dodge · 158–163 Roll_Dodge |
| Хіт-реакції | 178/179 Hit_Reaction · 174–176 Face_Punch_Reaction · 7 BeHit_FlyUp · 8 Dead |

Плюс CC0-бібліотеки Quaternius UAL і KayKit та безкоштовний Rokoko (справжній бойовий мокап) — [[Library]].
Ретаргет через `SkeletonProfileHumanoid` в Godot; активний регдол на тому ж скелеті ([[Active-Ragdoll]]).

## Related
- [[Architecture]] · [[Asset-Manifest]] · [[VFX-Direction]] · [[Library]] · [[2026-10-03-Production-Plan]]
