extends SceneTree
## T8 Гермес: деш у 8 напрямках — перевірка на справжньому InputMap гри (вільний рух, ADR-014).
## Для кожного профілю (SOLO, SHARED) і гравця: «деш + напрям» × 8 напрямків — чи дає InputRouter
## рівно цей напрям і натиснутий деш, і чи жодна клавіша не сидить на двох діях бійця.
## Геймпад: лівий стік під 8 кутами + B. Тач: у грі ще немає — не перевіряється.
## Запуск: make dash8   (або $GODOT_BIN --headless --path game -s $PWD/tools/input/dash8_check.gd)
## Вихід: rc=0 — 0 конфліктів і всі напрямки збіглися; rc=1 — інакше. Docs: docs/GDD/05-Platforms-Input.md

const DIRS := {
	"→": Vector2i(1, 0), "↗": Vector2i(1, 1), "↑": Vector2i(0, 1), "↖": Vector2i(-1, 1),
	"←": Vector2i(-1, 0), "↙": Vector2i(-1, -1), "↓": Vector2i(0, -1), "↘": Vector2i(1, -1),
}
## Клавіші напрямку, як їх задає ADR-014 п. 2: x — праворуч на екрані, y — углиб кадру.
const MOVE_KEYS := {
	1: {"right": KEY_D, "left": KEY_A, "up": KEY_W, "down": KEY_S},
	2: {"right": KEY_RIGHT, "left": KEY_LEFT, "up": KEY_UP, "down": KEY_DOWN},
}

var fails: int = 0
var ir: Node


func _initialize() -> void:
	await process_frame   # автолоади мають пройти _ready (InputRouter додає p*_up / p*_down)
	ir = root.get_node("InputRouter")
	var gs: Node = root.get_node("GameState")
	gs.free_move = true
	for prof in ["solo", "shared"]:
		ir.apply_profile(prof, false)
		print("── профіль %s ──" % prof)
		_clashes(prof)
		for p in [1, 2]:
			if prof == "solo" and p == 2:
				continue   # у SOLO P2 без клавіатури (ADR-009)
			_keyboard_dirs(p, prof)
	_pad_dirs()
	print("dash8: %s (%d помилок)" % ["OK" if fails == 0 else "FAIL", fails])
	quit(0 if fails == 0 else 1)


## Кожна клавіатурна подія — на скількох діях бійця (обидва гравці) вона сидить.
func _clashes(prof: String) -> void:
	var owner := {}
	var n := 0
	for p in [1, 2]:
		for a in ir.ACTIONS:
			for ev in InputMap.action_get_events(ir.action_name(p, a)):
				if not ev is InputEventKey:
					continue
				var k := _key_id(ev)
				owner[k] = owner.get(k, []) + [ir.action_name(p, a)]
				n += 1
	var bad := 0
	for k in owner:
		if owner[k].size() > 1:
			bad += 1
			print("  КОНФЛІКТ %s → %s" % [k, owner[k]])
	fails += bad
	print("  клавіш-подій %d, конфліктів %d" % [n, bad])


## Фізичний keycode + сторона (LShift ≠ RShift).
func _key_id(ev: InputEventKey) -> String:
	var side: String = ["", "L", "R"][ev.location] if ev.location <= 2 else ""
	return side + OS.get_keycode_string(ev.physical_keycode)


## Перша клавіша деша гравця в цьому профілі.
func _dash_key(p: int) -> InputEventKey:
	for ev in InputMap.action_get_events(ir.action_name(p, "dash")):
		if ev is InputEventKey:
			return ev
	return null


func _press(code: int, loc: int, down: bool, shift: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.location = loc
	e.pressed = down
	e.shift_pressed = shift   # LShift (деш SOLO) тримається, поки тиснуться напрямки
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _keyboard_dirs(p: int, prof: String) -> void:
	var dash := _dash_key(p)
	if dash == null:
		fails += 1
		print("  P%d: деш без клавіші" % p)
		return
	var shift := dash.physical_keycode == KEY_SHIFT
	var keys: Dictionary = MOVE_KEYS[p]
	var row := []
	for name in DIRS:
		var d: Vector2i = DIRS[name]
		var held := []
		if d.x > 0: held.append(keys.right)
		if d.x < 0: held.append(keys.left)
		if d.y > 0: held.append(keys.up)
		if d.y < 0: held.append(keys.down)
		_press(dash.physical_keycode, dash.location, true, shift)
		for c in held:
			_press(c, KEY_LOCATION_UNSPECIFIED, true, shift)
		var mv: Vector2 = ir.move(p)
		var got := Vector2i(int(signf(mv.x)), int(signf(mv.y)))
		var dash_on: bool = ir.held(p, "dash")
		var jump_on: bool = ir.held(p, "jump") or ir.held(p, "crouch")
		for c in held:
			_press(c, KEY_LOCATION_UNSPECIFIED, false, shift)
		_press(dash.physical_keycode, dash.location, false, false)
		var ok := got == d and dash_on and not jump_on
		if not ok:
			fails += 1
			print("  P%d %s: move=%s dash=%s jump/crouch=%s — FAIL" % [p, name, mv, dash_on, jump_on])
		row.append("%s%s" % [name, "✓" if ok else "✗"])

	print("  P%d [%s + напрям, клавіш разом ≤ 3]: %s" % [p, _key_id(dash), " ".join(row)])


## Лівий стік під 8 кутами (|v| = 1) + деш на кнопці з project.godot. Пристрій — device гравця.
func _pad_dirs() -> void:
	print("── геймпад ──")
	for p in [1, 2]:
		var dev: int = p - 1
		var btn := -1
		for ev in InputMap.action_get_events(ir.action_name(p, "dash")):
			if ev is InputEventJoypadButton:
				btn = (ev as InputEventJoypadButton).button_index
		var row := []
		for name in DIRS:
			var d: Vector2i = DIRS[name]
			var v := Vector2(d).normalized()
			_axis(dev, JOY_AXIS_LEFT_X, v.x)
			_axis(dev, JOY_AXIS_LEFT_Y, -v.y)   # стік: −1 = вгору
			_button(dev, btn, true)
			var mv: Vector2 = ir.move(p)
			var got := Vector2i(int(signf(snappedf(mv.x, 0.01))), int(signf(snappedf(mv.y, 0.01))))
			var ok: bool = got == d and ir.held(p, "dash") and not ir.held(p, "crouch")
			_button(dev, btn, false)
			_axis(dev, JOY_AXIS_LEFT_X, 0.0)
			_axis(dev, JOY_AXIS_LEFT_Y, 0.0)
			if not ok:
				fails += 1
				print("  P%d %s: move=%s — FAIL" % [p, name, mv])
			row.append("%s%s(%.0f°)" % [name, "✓" if ok else "✗", rad_to_deg(mv.angle())])
		print("  P%d [кнопка %d + стік]: %s" % [p, btn, " ".join(row)])


func _axis(dev: int, ax: int, val: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = dev
	e.axis = ax
	e.axis_value = val
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _button(dev: int, idx: int, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = dev
	e.button_index = idx
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()
