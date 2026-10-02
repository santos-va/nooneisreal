extends Node
## Autoload: per-player action lookup + a small input buffer (in physics frames) so a button
## pressed a few frames early still produces the intended move. Also hosts the "virtual input"
## layer used by the CPU brain and the smoke test, so AI and tests go through the same path
## as a human player. Docs: docs/GDD/05-Platforms-Input.md

const BUFFER_FRAMES := 6
const ACTIONS := ["left", "right", "jump", "crouch", "light", "heavy", "block", "skill1", "skill2", "ultimate", "grapple", "dash"]

var _frame: int = 0
var _pressed_at: Dictionary = {}    # "p1_light" -> physics frame of the last just_pressed
var _virtual_held: Dictionary = {}  # "p2_light" -> bool   (CPU / tests)
var _virtual_just: Dictionary = {}  # "p2_light" -> frame


func _ready() -> void:
	process_physics_priority = -100  # record input before any fighter ticks


func _physics_process(_delta: float) -> void:
	_frame += 1
	for p in [1, 2]:
		for a in ACTIONS:
			var n := "p%d_%s" % [p, a]
			if Input.is_action_just_pressed(n):
				_pressed_at[n] = _frame


func frame() -> int:
	return _frame


func action_name(player: int, action: String) -> String:
	return "p%d_%s" % [player, action]


func held(player: int, action: String) -> bool:
	var n := action_name(player, action)
	return Input.is_action_pressed(n) or bool(_virtual_held.get(n, false))


func axis(player: int) -> float:
	var x := Input.get_action_strength(action_name(player, "right")) - Input.get_action_strength(action_name(player, "left"))
	if _virtual_held.get(action_name(player, "right"), false):
		x += 1.0
	if _virtual_held.get(action_name(player, "left"), false):
		x -= 1.0
	return clampf(x, -1.0, 1.0)


func just_pressed(player: int, action: String) -> bool:
	var n := action_name(player, action)
	return Input.is_action_just_pressed(n) or int(_virtual_just.get(n, -999)) == _frame


## Buffered press: true if the action was pressed within the last `window` physics frames.
## Consumes the entry so one press triggers exactly one move.
func buffered(player: int, action: String, window: int = BUFFER_FRAMES) -> bool:
	var n := action_name(player, action)
	var at: int = maxi(int(_pressed_at.get(n, -999)), int(_virtual_just.get(n, -999)))
	if at >= 0 and _frame - at <= window:
		_pressed_at.erase(n)
		_virtual_just.erase(n)
		return true
	return false


# --- virtual input (CPU brain, smoke test) --------------------------------------------------
func v_press(player: int, action: String) -> void:
	var n := action_name(player, action)
	_virtual_just[n] = _frame
	_virtual_held[n] = true


func v_release(player: int, action: String) -> void:
	_virtual_held[action_name(player, action)] = false


func v_set(player: int, action: String, down: bool) -> void:
	var n := action_name(player, action)
	var was: bool = bool(_virtual_held.get(n, false))
	if down and not was:
		_virtual_just[n] = _frame
	_virtual_held[n] = down


func v_clear(player: int) -> void:
	for a in ACTIONS:
		_virtual_held[action_name(player, a)] = false
