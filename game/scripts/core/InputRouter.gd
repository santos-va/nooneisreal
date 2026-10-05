extends Node
## Autoload: per-player action lookup + a small input buffer (in physics frames) so a button
## pressed a few frames early still produces the intended move. Also hosts the "virtual input"
## layer used by the CPU brain and the smoke test, so AI and tests go through the same path
## as a human player. Docs: docs/GDD/05-Platforms-Input.md

const BUFFER_FRAMES := 6
const ACTIONS := ["left", "right", "jump", "crouch", "light", "heavy", "left_hand", "right_hand", "left_leg", "right_leg", "block", "skill1", "skill2", "ultimate", "grapple_enemy", "grapple_parkour", "grapple", "grapple_detach", "dodge", "dash", "interact", "weapon_swap", "up", "down"]
## Free movement (GameState.free_move) — docs/Decisions/ADR-014-Free-Movement-Layout.md: W/↑ and S/↓ move
## off `jump` / `crouch` onto `up` / `down` (camera-relative movement); jump is Space (P1) and `/` (P2) only;
## crouch is X (P1) and M (P2, SHARED). Gamepad: left stick ↑/↓ drives up/down and leaves crouch, which is
## D-pad ↓ only. The plane mode keeps project.godot's layout (ADR-009) untouched.
const FREE_MOVE_UP_KEYS := [KEY_W, KEY_UP]
const FREE_MOVE_DOWN_KEYS := [KEY_S, KEY_DOWN]
const FREE_MOVE_CROUCH_KEYS := {1: KEY_X, 2: KEY_M}
## Gamepad left stick, vertical axis (JOY_AXIS_LEFT_Y): −1 = up, +1 = down.
const STICK_Y := JOY_AXIS_LEFT_Y
const SETTINGS_PATH := "user://settings.cfg"
const UI_PAD_BUTTONS := {
	"ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B,
	"ui_left": JOY_BUTTON_DPAD_LEFT, "ui_right": JOY_BUTTON_DPAD_RIGHT,
	"ui_up": JOY_BUTTON_DPAD_UP, "ui_down": JOY_BUTTON_DPAD_DOWN,
}

## Keyboard profiles (docs/Decisions/ADR-009-Solo-Keyboard-Layout.md). Only keyboard events are
## rewritten at runtime; gamepad events from project.godot stay untouched.
## SHARED = the layout baked into project.godot (two players on one keyboard).
## SOLO   = P1 moves with WASD; J/K/M/comma select the four limbs;
##          P2 has no keyboard keys (gamepad or CPU) to avoid profile collisions.
const PROFILE_SOLO := "solo"
const PROFILE_SHARED := "shared"
const PROFILES := [PROFILE_SOLO, PROFILE_SHARED]
const SOLO_KEYS := {
	"p1_left": [KEY_A], "p1_right": [KEY_D], "p1_jump": [KEY_W, KEY_SPACE], "p1_crouch": [KEY_S],
	"p1_dash": [KEY_ALT], "p1_dodge": [KEY_SHIFT], "p1_grapple_detach": [KEY_Z], "p1_interact": [KEY_G], "p1_grapple_enemy": [KEY_Q], "p1_grapple_parkour": [KEY_E],
	"p1_left_hand": [KEY_J], "p1_right_hand": [KEY_K], "p1_left_leg": [KEY_M], "p1_right_leg": [KEY_COMMA], "p1_block": [KEY_L, KEY_F],
	"p1_weapon_swap": [KEY_V], "p1_skill1": [KEY_U, KEY_R], "p1_skill2": [KEY_I, KEY_T], "p1_ultimate": [KEY_O, KEY_C],
}

const SOLO_MOUSE := {"left_hand": MOUSE_BUTTON_LEFT, "right_hand": MOUSE_BUTTON_MIDDLE, "left_leg": MOUSE_BUTTON_XBUTTON1, "right_leg": MOUSE_BUTTON_XBUTTON2}

const LIMBS := ["left_hand", "right_hand", "left_leg", "right_leg"]
const PAD_CHORDS := ["skill1", "skill2", "grapple_parkour", "grapple_enemy"]
const PAD_LIMB_LABELS := ["LB / L1", "RB / R1", "LT / L2", "RT / R2"]
## Hysteresis rejects trigger noise until a deliberate release.
const TRIGGER_PRESS := 0.55
const TRIGGER_RELEASE := 0.35
var _pad_down: Dictionary = {}
var _pad_routes: Dictionary = {}
var _pad_modifier: Dictionary = {}
var _pad_modifier_blocked: Dictionary = {}
var _routed_just: Dictionary = {}
var _look_neutral_pending: Dictionary = {}
var _view_bases: Dictionary = {}
var _recorded_view_bases: Dictionary = {}
const LOOK_DEADZONE := 0.2

var _frame: int = 0
var _pressed_at: Dictionary = {}    # "p1_light" -> physics frame of the last just_pressed
var _virtual_held: Dictionary = {}  # "p2_light" -> bool   (CPU / tests)
var _virtual_just: Dictionary = {}  # "p2_light" -> frame
var _shared_keys: Dictionary = {}   # action -> Array[InputEventKey] captured from project.godot
var _pad_events: Dictionary = {}    # action -> Array of gamepad events captured from project.godot
var _ui_owners: Dictionary = {}  # instance id -> WeakRef; nested overlays own separate tokens
var _neutral_pending: Dictionary = {}  # physical actions held across a UI boundary
var _ui_consumed: Dictionary = {}  # stale just_pressed flags need a fresh device press
var _press_revisions: Dictionary = {1: 0, 2: 0}
var profile: String = PROFILE_SOLO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_pad_connection_changed)
	ensure_ui_gamepad_bindings()
	process_physics_priority = -100  # record input before any fighter ticks
	for p in [1, 2]:
		for a in ACTIONS:
			var n := action_name(p, a)
			if not InputMap.has_action(n):
				InputMap.add_action(n)   # up/down exist only for free movement
			var keys: Array = []
			var pads: Array = []
			for ev in InputMap.action_get_events(n):
				if ev is InputEventKey:
					keys.append(ev)
				else:
					pads.append(ev)
			_shared_keys[n] = keys
			_pad_events[n] = pads
	var cfg := ConfigFile.new()
	var saved: String = PROFILE_SOLO
	if cfg.load(SETTINGS_PATH) == OK:
		saved = str(cfg.get_value("input", "keyboard_profile", PROFILE_SOLO))
	apply_profile(saved, false)


## Menus accept either controller. Keep built-in keyboard events and all combat maps.
func ensure_ui_gamepad_bindings() -> void:
	for action: String in UI_PAD_BUTTONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var found := false
		for existing in InputMap.action_get_events(action):
			if existing is InputEventJoypadButton and existing.device == -1 and existing.button_index == UI_PAD_BUTTONS[action]:
				found = true
		if not found:
			var event := InputEventJoypadButton.new()
			event.device = -1
			event.button_index = UI_PAD_BUTTONS[action]
			InputMap.action_add_event(action, event)


## Rebuilds the keyboard half of every p1_/p2_ action for `prof` and optionally persists it.
func apply_profile(prof: String, save: bool = true) -> void:
	if not prof in PROFILES:
		prof = PROFILE_SOLO
	profile = prof
	for p in [1, 2]:
		for a in ACTIONS:
			var n := action_name(p, a)
			for ev in InputMap.action_get_events(n):
				if ev is InputEventKey:
					InputMap.action_erase_event(n, ev)
			if prof == PROFILE_SHARED:
				if a in ["dash", "dodge", "grapple_detach", "interact"]:
					var key := InputEventKey.new()
					key.physical_keycode = {"dash": KEY_ALT, "dodge": KEY_C if p == 1 else KEY_PERIOD, "grapple_detach": KEY_CTRL, "interact": KEY_Y if p == 1 else KEY_BACKSLASH}[a]
					if a in ["dash", "grapple_detach"]:
						key.location = KEY_LOCATION_LEFT if p == 1 else KEY_LOCATION_RIGHT
					InputMap.action_add_event(n, key)
				else:
					for ev in _shared_keys.get(n, []):
						InputMap.action_add_event(n, ev)
			else:
				for code in SOLO_KEYS.get(n, []):
					var k := InputEventKey.new()
					k.physical_keycode = code
					if code == KEY_SHIFT or code == KEY_ALT:
						k.location = KEY_LOCATION_LEFT   # RShift stays free
					InputMap.action_add_event(n, k)
		_apply_pad(p)
		if prof == PROFILE_SOLO and p == 1:
			for action: String in SOLO_MOUSE:
				var mouse := InputEventMouseButton.new()
				mouse.button_index = SOLO_MOUSE[action]
				InputMap.action_add_event(action_name(p, action), mouse)
		if GameState.free_move:
			_move_keys(action_name(p, "jump"), action_name(p, "up"), FREE_MOVE_UP_KEYS)
			_move_keys(action_name(p, "crouch"), action_name(p, "down"), FREE_MOVE_DOWN_KEYS)
			if prof == PROFILE_SHARED or p == 1:
				var k := InputEventKey.new()
				k.physical_keycode = FREE_MOVE_CROUCH_KEYS[p]
				InputMap.action_add_event(action_name(p, "crouch"), k)
	_clear_ui_history()
	if save:
		var cfg := ConfigFile.new()
		cfg.load(SETTINGS_PATH)   # keep other sections if the file exists
		cfg.set_value("input", "keyboard_profile", prof)
		cfg.save(SETTINGS_PATH)


## Gamepad half for player `p`: project.godot's events, and in free movement the left stick's vertical axis
## moves from crouch onto up/down (ADR-014 п. 4). Device = the one project.godot gives this player.
func _apply_pad(p: int) -> void:
	for a in ACTIONS:
		var n := action_name(p, a)
		for ev in InputMap.action_get_events(n):
			if not ev is InputEventKey:
				InputMap.action_erase_event(n, ev)
		for ev in _pad_events.get(n, []):
			if a in ["dash", "block"]:
				continue # X is routed to dodge or Y+X dash on its rising edge.
			if GameState.free_move and a == "crouch" and ev is InputEventJoypadMotion and (ev as InputEventJoypadMotion).axis == STICK_Y:
				continue
			InputMap.action_add_event(n, ev)
	# Direct parkour keeps the right thumb available for aiming; legacy Y + LT remains.
	var parkour := InputEventJoypadButton.new()
	parkour.device = p - 1
	parkour.button_index = JOY_BUTTON_LEFT_STICK
	InputMap.action_add_event(action_name(p, "grapple_parkour"), parkour)
	var detach := InputEventJoypadButton.new()
	detach.device = p - 1
	detach.button_index = JOY_BUTTON_B
	InputMap.action_add_event(action_name(p, "block"), detach)
	if GameState.free_move:
		for pair in [["up", -1.0], ["down", 1.0]]:
			var m := InputEventJoypadMotion.new()
			m.device = p - 1
			m.axis = STICK_Y
			m.axis_value = pair[1]
			InputMap.action_add_event(action_name(p, pair[0]), m)


func _move_keys(from: String, to: String, codes: Array) -> void:
	for ev in InputMap.action_get_events(from):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode in codes:
			InputMap.action_erase_event(from, ev)
			InputMap.action_add_event(to, ev)


func cycle_profile() -> void:
	apply_profile(PROFILES[wrapi(PROFILES.find(profile) + 1, 0, PROFILES.size())])


## One-line control hint for the HUD / menu, matching the active profile.
func hint_text(vs_cpu: bool) -> String:
	if GameState.free_move:
		return _hint_free(vs_cpu)
	return _hint_profile(vs_cpu)


## Readable keyboard help follows the current action map, including physical comma.
func _hint_free(vs_cpu: bool) -> String:
	return _hint_profile(vs_cpu)


func _hint_profile(vs_cpu: bool) -> String:
	var text := ""
	for p in ([1] if vs_cpu or profile == PROFILE_SOLO else [1, 2]):
		text += "P%d\n" % p
		for action in ["left", "right", "up", "down", "jump", "crouch", "left_hand", "right_hand", "left_leg", "right_leg", "block", "skill1", "skill2", "grapple_enemy", "grapple_parkour", "grapple_detach", "dodge", "dash", "weapon_swap", "ultimate", "interact"]:
			var label := binding_label(p, action, false)
			if not label.is_empty():
				text += action.capitalize() + ": " + label + " · "
		text += "\n"
	return text + "Hold jump while tethered: lift · Weapon swap: draw / reform · Tab hitboxes · Esc pause"


## A single source for physical key labels and routed controller chords.
func binding_label(player: int, action: String, gamepad: bool) -> String:
	if gamepad:
		if action == "grapple_detach":
			return "B / Circle (while hanging)"
		if action == "dodge":
			return "X / Square"
		if action == "dash":
			return "Y / Triangle + X / Square"
		if action == "interact":
			return "Y / Triangle + D-pad Down"
		if action in LIMBS:
			return PAD_LIMB_LABELS[LIMBS.find(action)]
		if action in PAD_CHORDS and not action.is_empty():
			return "Y / Triangle + " + PAD_LIMB_LABELS[PAD_CHORDS.find(action)] + (" / L3" if action == "grapple_parkour" else "")
	var labels: PackedStringArray = []
	for event in InputMap.action_get_events(action_name(player, action)):
		if not gamepad and event is InputEventKey:
			var prefix := "Left " if event.location == KEY_LOCATION_LEFT else ("Right " if event.location == KEY_LOCATION_RIGHT else "")
			labels.append(prefix + ("Comma (<)" if event.physical_keycode == KEY_COMMA else OS.get_keycode_string(event.physical_keycode)))
		elif not gamepad and event is InputEventMouseButton:
			labels.append(str({MOUSE_BUTTON_LEFT: "LMB", MOUSE_BUTTON_MIDDLE: "MMB", MOUSE_BUTTON_XBUTTON1: "Mouse 4", MOUSE_BUTTON_XBUTTON2: "Mouse 5"}.get(event.button_index, "Mouse")))
		elif gamepad and event is InputEventJoypadButton:
			var names := {JOY_BUTTON_A: "A / Cross", JOY_BUTTON_B: "B / Circle", JOY_BUTTON_X: "X / Square", JOY_BUTTON_DPAD_UP: "D-pad Up", JOY_BUTTON_DPAD_DOWN: "D-pad Down", JOY_BUTTON_RIGHT_STICK: "R3 / Right stick click"}
			labels.append(str(names.get(event.button_index, "D-pad")))
		elif gamepad and event is InputEventJoypadMotion:
			labels.append("Left stick")
	return " / ".join(labels)


## Idempotent owner tokens let a pause screen and its child settings panel overlap.
## Releasing one overlay never re-enables input owned by another overlay.
func acquire_ui(owner: Object) -> void:
	if not is_instance_valid(owner):
		return
	_ui_owners[owner.get_instance_id()] = weakref(owner)
	_clear_ui_history()


func release_ui(owner: Object) -> void:
	if not is_instance_valid(owner) or not _ui_owners.has(owner.get_instance_id()):
		return
	_ui_owners.erase(owner.get_instance_id())
	_clear_ui_history()


func ui_suppressed() -> bool:
	for id in _ui_owners.keys():
		if _ui_owners[id].get_ref() == null:
			_ui_owners.erase(id)
			_clear_ui_history()
	return not _ui_owners.is_empty()


func _clear_ui_history() -> void:
	for player: int in [1, 2]:
		_press_revisions[player] = press_history_revision(player) + 1
	GameState.duel.clear_human_gestures()
	_view_bases.clear()
	_recorded_view_bases.clear()
	_pressed_at.clear()
	_virtual_just.clear()
	_virtual_held.clear()
	_routed_just.clear()
	_pad_routes.clear()
	for device in _pad_modifier:
		if _pad_modifier[device]:
			_pad_modifier_blocked[device] = true
	for p in [1, 2]:
		if _raw_look(p).length() > LOOK_DEADZONE:
			_look_neutral_pending[p] = true
		for a in ACTIONS:
			var n := action_name(p, a)
			_ui_consumed[n] = true
			if Input.is_action_pressed(n):
				_neutral_pending[n] = true
			else:
				_neutral_pending.erase(n)


## A held movement key, stick, guard or attack must return to neutral after UI.
## Polling also handles disconnected controllers and releases consumed by Controls.
func _physical_allowed(n: String) -> bool:
	if ui_suppressed():
		return false
	if n.ends_with("_crouch") and _pad_routes.values().has(n.replace("_crouch", "_interact")):
		return false
	if _neutral_pending.has(n):
		if not Input.is_action_pressed(n):
			_neutral_pending.erase(n)
		return false
	return true


## Godot exposes just_pressed separately in render/physics contexts. A released UI tap
## may still be just_pressed on the first resumed physics tick. Only a fresh device
## press removes this fence; the UI event can never recreate its cleared buffer.
func _just_allowed(n: String) -> bool:
	return _physical_allowed(n) and not _ui_consumed.has(n)


func _strength(player: int, action: String) -> float:
	var n := action_name(player, action)
	return Input.get_action_strength(n) if _physical_allowed(n) else 0.0


## Events can arrive between physics ticks (or from Input.parse_input_event in tests); record
## them here as well so a tap shorter than one physics frame still lands in the buffer.
func _input(event: InputEvent) -> void:
	_route_pad(event)
	if ui_suppressed():
		_clear_ui_history()
		return
	if not (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	for p in [1, 2]:
		for a in ACTIONS:
			var n := "p%d_%s" % [p, a]
			if _physical_allowed(n) and event.is_action_pressed(n):
				_ui_consumed.erase(n)
				_pressed_at[n] = _frame


func _physics_process(_delta: float) -> void:
	_frame += 1
	if ui_suppressed():
		_clear_ui_history()
		return
	for p in [1, 2]:
		for a in ACTIONS:
			var n := "p%d_%s" % [p, a]
			if _just_allowed(n) and Input.is_action_just_pressed(n):
				_pressed_at[n] = _frame


func frame() -> int:
	return _frame


func action_name(player: int, action: String) -> String:
	return "p%d_%s" % [player, action]


func held(player: int, action: String) -> bool:
	var n := action_name(player, action)
	return not ui_suppressed() and ((_physical_allowed(n) and Input.is_action_pressed(n)) or _pad_routes.values().has(n) or bool(_virtual_held.get(n, false)))


func axis(player: int) -> float:
	if ui_suppressed():
		return 0.0
	var x := _strength(player, "right") - _strength(player, "left")
	if _virtual_held.get(action_name(player, "right"), false):
		x += 1.0
	if _virtual_held.get(action_name(player, "left"), false):
		x -= 1.0
	return clampf(x, -1.0, 1.0)


## Free movement: camera-relative stick, x = screen right, y = screen up (into the picture).
## In the plane mode y is always 0, so callers can use move() in both modes.
func move(player: int) -> Vector2:
	if ui_suppressed():
		return Vector2.ZERO
	if not GameState.free_move:
		return Vector2(axis(player), 0.0)
	var y := _strength(player, "up") - _strength(player, "down")
	if _virtual_held.get(action_name(player, "up"), false):
		y += 1.0
	if _virtual_held.get(action_name(player, "down"), false):
		y -= 1.0
	var v := Vector2(axis(player), clampf(y, -1.0, 1.0))
	return v.normalized() if v.length() > 1.0 else v


func just_pressed(player: int, action: String) -> bool:
	var n := action_name(player, action)
	return not ui_suppressed() and ((_just_allowed(n) and Input.is_action_just_pressed(n)) or int(_routed_just.get(n, -999)) == _frame or int(_virtual_just.get(n, -999)) == _frame)


## Buffered press: true if the action was pressed within the last `window` physics frames.
## Consumes the entry so one press triggers exactly one move.
func buffered(player: int, action: String, window: int = BUFFER_FRAMES) -> bool:
	if ui_suppressed():
		return false
	var n := action_name(player, action)
	var at: int = maxi(int(_pressed_at.get(n, -999)), int(_virtual_just.get(n, -999)))
	if at >= 0 and _frame - at <= window:
		_pressed_at.erase(n)
		_virtual_just.erase(n)
		return true
	return false


## The original age is preserved when a fighter retains one confirmed-hit continuation.
func buffered_age(player: int, action: String) -> int:
	if ui_suppressed():
		return -1
	var n: String = action_name(player, action)
	var at: int = maxi(int(_pressed_at.get(n, -999)), int(_virtual_just.get(n, -999)))
	return _frame - at if at >= 0 else -1


func press_history_revision(player: int) -> int:
	return int(_press_revisions.get(player, 0))


## Reset queued edges for one player; physically held movement/guard remain current.
func clear_player_presses(player: int) -> void:
	_press_revisions[player] = press_history_revision(player) + 1
	for action: String in ACTIONS:
		var n: String = action_name(player, action)
		_pressed_at.erase(n)
		_virtual_just.erase(n)
		_routed_just.erase(n)
		_ui_consumed[n] = true # A stale physical just_pressed cannot rehydrate after reset.


# --- virtual input (CPU brain, smoke test) --------------------------------------------------
func v_press(player: int, action: String) -> void:
	if ui_suppressed():
		return
	var n := action_name(player, action)
	_virtual_just[n] = _frame
	_virtual_held[n] = true


func v_release(player: int, action: String) -> void:
	_virtual_held[action_name(player, action)] = false


func v_set(player: int, action: String, down: bool) -> void:
	if ui_suppressed():
		return
	var n := action_name(player, action)
	var was: bool = bool(_virtual_held.get(n, false))
	if down and not was:
		_virtual_just[n] = _frame
	_virtual_held[n] = down


func v_clear(player: int) -> void:
	for a in ACTIONS:
		_virtual_held[action_name(player, a)] = false


## Non-consuming: was the action pressed within the last `window` frames? (perfect block etc.)
func pressed_within(player: int, action: String, window: int) -> bool:
	if ui_suppressed():
		return false
	var n := action_name(player, action)
	var at: int = maxi(int(_pressed_at.get(n, -999)), int(_virtual_just.get(n, -999)))
	return at >= 0 and _frame - at <= window


## Route on the physical rising edge, never on modifier changes or polling.
## Keyboard actions do not inspect this per-device modifier state.
func _route_pad(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	var device := event.device
	if device not in [0, 1]:
		return
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_Y:
		_pad_modifier[device] = event.pressed
		if not event.pressed:
			_pad_modifier_blocked.erase(device)
		elif ui_suppressed():
			_pad_modifier_blocked[device] = true
		return
	var slot := -1
	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			slot = 0
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			slot = 1
		elif event.button_index == JOY_BUTTON_X:
			slot = 4
		elif event.button_index == JOY_BUTTON_DPAD_DOWN and (_pad_modifier.get(device, false) or _pad_down.get("%d:5" % device, false)):
			slot = 5
	elif event.axis == JOY_AXIS_TRIGGER_LEFT:
		slot = 2
	elif event.axis == JOY_AXIS_TRIGGER_RIGHT:
		slot = 3
	if slot < 0:
		return
	var source := "%d:%d" % [device, slot]
	var was: bool = _pad_down.get(source, false)
	var down: bool = event.pressed if event is InputEventJoypadButton else event.axis_value > (TRIGGER_RELEASE if was else TRIGGER_PRESS)
	_pad_down[source] = down
	if not down:
		_pad_routes.erase(source)
		return
	if was or ui_suppressed() or _pad_modifier_blocked.has(device):
		return
	var action: String
	if slot == 4:
		action = "dash" if _pad_modifier.get(device, false) else "dodge"
	elif slot == 5:
		action = "interact"
	else:
		action = PAD_CHORDS[slot] if _pad_modifier.get(device, false) else LIMBS[slot]
	if action.is_empty():
		return
	var name := action_name(device + 1, action)
	_pad_routes[source] = name
	_pressed_at[name] = _frame
	_routed_just[name] = _frame


func _pad_connection_changed(device: int, connected: bool) -> void:
	if connected:
		return
	clear_player_presses(device + 1)
	_pad_modifier.erase(device)
	_look_neutral_pending[device + 1] = true
	clear_recorded_view_basis(device + 1)
	GameState.duel.clear_human_gestures(device + 1)
	_pad_modifier_blocked.erase(device)
	for slot in range(6):
		var source := "%d:%d" % [device, slot]
		_pad_down.erase(source)
		var name: String = _pad_routes.get(source, "")
		_pad_routes.erase(source)
		if not name.is_empty():
			_pressed_at.erase(name)
			_routed_just.erase(name)


## Presentation look input; x right, y down. The aim helper captures its resulting world
## ray at shot request so replay never depends on later camera smoothing.
func _raw_look(player: int) -> Vector2:
	if player not in [1, 2]:
		return Vector2.ZERO
	return Vector2(Input.get_joy_axis(player - 1, JOY_AXIS_RIGHT_X), Input.get_joy_axis(player - 1, JOY_AXIS_RIGHT_Y))


func look_axis(player: int) -> Vector2:
	var raw := _raw_look(player)
	if ui_suppressed():
		return Vector2.ZERO
	if _look_neutral_pending.has(player):
		if raw.length() <= LOOK_DEADZONE:
			_look_neutral_pending.erase(player)
		return Vector2.ZERO
	if raw.length() <= LOOK_DEADZONE:
		return Vector2.ZERO
	return raw.normalized() * clampf((raw.length() - LOOK_DEADZONE) / (1.0 - LOOK_DEADZONE), 0.0, 1.0)


## Input-adapter packet, not a simulation read of a rendered camera. Each physics tick
## consumes the current basis. Recorded playback overrides live adapters until explicitly ended.
func set_view_basis(player: int, ground_forward: Vector3) -> bool:
	if player not in [1, 2] or ui_suppressed() or _recorded_view_bases.has(player):
		return false
	var flat := Vector3(ground_forward.x, 0.0, ground_forward.z)
	if not ground_forward.is_finite() or flat.length_squared() < 0.000001:
		return false
	_view_bases[player] = flat.normalized()
	return true


func clear_view_basis(player: int) -> void:
	if not _recorded_view_bases.has(player):
		_view_bases.erase(player)


func view_basis(player: int) -> Vector3:
	return Vector3.ZERO if ui_suppressed() else _view_bases.get(player, Vector3.ZERO)


func view_basis_packet(player: int) -> Dictionary:
	var forward := view_basis(player)
	return {} if forward == Vector3.ZERO else {"forward": forward}


func apply_view_basis_packet(player: int, packet: Dictionary) -> bool:
	if player not in [1, 2] or ui_suppressed():
		return false
	_recorded_view_bases.erase(player)
	_view_bases.erase(player)
	var valid := packet.is_empty()
	if packet.get("forward") is Vector3:
		valid = set_view_basis(player, packet.forward)
	_recorded_view_bases[player] = true
	return valid


func clear_recorded_view_basis(player: int) -> void:
	_recorded_view_bases.erase(player)
	_view_bases.erase(player)
