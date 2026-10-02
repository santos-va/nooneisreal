# 05 — Платформи та інпут

Власник: T8 Гермес. Джерело мапи: `game/project.godot` (`[input]`), згенеровано скриптом у
сесії кікоф. Дії: `p{1,2}_{left,right,jump,crouch,light,heavy,block,skill1,skill2,ultimate,grapple,dash}`.

## Клавіатура — двоє на одному Mac

Обмеження Apple-клавіатур ≈ 6-key rollover; WASD і стрілки — у різних зонах матриці; Shift на
окремій лінії, тому утримуваний блок — на Shift. Не чіпаємо ⌘ (⌘Q/⌘W), Ctrl+стрілки (Mission
Control), F-клавіші (медіа), Caps Lock.

| дія | P1 | P2 |
|---|---|---|
| Рух | A / D | ← / → |
| Стрибок | W, Space | ↑, / |
| Присід | S | ↓ |
| Легкий | F | K |
| Важкий | G | L |
| Блок (утримання) | LShift | RShift |
| Скіл 1 / Скіл 2 | Q / E | ; / ' |
| Гарпун | R | I |
| Деш | C | . |
| Ультимейт | V | , |
| Пауза | Esc | Esc |
| Дебаг | Tab хітбокси · Backspace скинути позиції (тренування) | |

## Геймпад (device 0 = P1, device 1 = P2)

| дія | Xbox | PS |
|---|---|---|
| Легкий / Важкий | X / Y | □ / △ |
| Стрибок / Деш | A / B | ✕ / ○ |
| Блок | RB | R1 |
| Скіл 1 / Скіл 2 | LB / LT | L1 / L2 |
| Гарпун | RT | R2 |
| Ультимейт | D-pad ↑ | D-pad ↑ |
| Пауза | Menu | Options |

## Тач (план, фаза 4)

Godot 4.7 `VirtualJoystick` зліва; справа: Легкий 64 dp, Важкий/Блок/Стрибок/Гарпун 56 dp,
скіли 44–48 dp угорі справа, відступи 8 dp; деш = флік стіка; ульт — контекстна кнопка при
повному метрі. Редактор лейауту (позиція/масштаб/прозорість) — як у Brawlhalla.

## Гліфи та safe area

Останній пристрій, що дав ввід, визначає гліфи (deadzone, щоб дрейф стіка не мигав).
Пакети: Kenney Input Prompts (CC0), Xelu (CC0). Safe area — `DisplayServer.get_display_safe_area()`
з перерахунком під `canvas_items` stretch.

## Related
- [[06-UI-UX]] · [[Export-Platforms]] · [[2026-10-02-Grapple-Input-UI]] · [[02-Combat-System]]
