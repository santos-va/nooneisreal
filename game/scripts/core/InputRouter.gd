extends Node
## Autoload: per-player action lookup + a small input buffer (in physics frames) so a button
## pressed a few frames early still produces the intended move. Also hosts the "virtual input"
## layer used by the CPU brain and the smoke test, so AI and tests go through the same path
## as a human player. Docs: docs/GDD/05-Platforms-Input.md

const BUFFER_FRAMES := 6
const ACTIONS := ["left", "right", "jump", "crouch", "light", "heavy", "block", "skill1", "skill2", "ultimate", "grapple", "dash", "up", "down"]
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

## Keyboard profiles (docs/Decisions/ADR-009-Solo-Keyboard-Layout.md). Only keyboard events are
## rewritten at runtime; gamepad events from project.godot stay untouched.
## SHARED = the layout baked into project.godot (two players on one keyboard).
## SOLO   = P1 left hand moves (A D W S Space LShift E), right hand acts (J K L U I O);
##          P2 has no keyboard keys (gamepad or CPU), because K/L/I would collide.
const PROFILE_SOLO := "solo"
const PROFILE_SHARED := "shared"
const PROFILES := [PROFILE_SOLO, PROFILE_SHARED]
const SOLO_KEYS := {
	"p1_left": [KEY_A], "p1_right": [KEY_D], "p1_jump": [KEY_W, KEY_SPACE], "p1_crouch": [KEY_S],
	"p1_dash": [KEY_SHIFT], "p1_grapple": [KEY_E],
	"p1_light": [KEY_J], "p1_heavy": [KEY_K], "p1_block": [KEY_L],
	"p1_skill1": [KEY_U], "p1_skill2": [KEY_I], "p1_ultimate": [KEY_O],
}

var _frame: int = 0
var _pressed_at: Dictionary = {}    # "p1_light" -> physics frame of the last just_pressed
var _virtual_held: Dictionary = {}  # "p2_light" -> bool   (CPU / tests)
var _virtual_just: Dictionary = {}  # "p2_light" -> frame
var _shared_keys: Dictionary = {}   # action -> Array[InputEventKey] captured from project.godot
var _pad_events: Dictionary = {}    # action -> Array of gamepad events captured from project.godot
var profile: String = PROFILE_SOLO


func _ready() -> void:
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
				for ev in _shared_keys.get(n, []):
					InputMap.action_add_event(n, ev)
			else:
				for code in SOLO_KEYS.get(n, []):
					var k := InputEventKey.new()
					k.physical_keycode = code
					if code == KEY_SHIFT:
						k.location = KEY_LOCATION_LEFT   # RShift stays free
					InputMap.action_add_event(n, k)
		_apply_pad(p)
		if GameState.free_move:
			_move_keys(action_name(p, "jump"), action_name(p, "up"), FREE_MOVE_UP_KEYS)
			_move_keys(action_name(p, "crouch"), action_name(p, "down"), FREE_MOVE_DOWN_KEYS)
			if prof == PROFILE_SHARED or p == 1:
				var k := InputEventKey.new()
				k.physical_keycode = FREE_MOVE_CROUCH_KEYS[p]
				InputMap.action_add_event(action_name(p, "crouch"), k)
	_pressed_at.clear()
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
			if GameState.free_move and a == "crouch" and ev is InputEventJoypadMotion and (ev as InputEventJoypadMotion).axis == STICK_Y:
				continue
			InputMap.action_add_event(n, ev)
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


## Free movement hint (ADR-014, ADR-015 п. 6): solo vs CPU the camera is behind P1, so W/S go to / from the
## opponent and A/D circle; in VERSUS the camera is side-on, so A/D go to / from and W/S circle.
func _hint_free(vs_cpu: bool) -> String:
	var walk := "W/S to·from foe · A/D circle" if vs_cpu else "A/D to·from foe · W/S circle"
	if profile == PROFILE_SOLO:
		var p1 := "P1  %s · Space jump · X crouch · LShift dash · E grapple   J light · K heavy · L guard · U/I skills · O ultimate" % walk
		return p1 + ("   |   Tab hitboxes · Esc pause" if vs_cpu else "      P2  gamepad (SOLO keyboard)")
	if vs_cpu:
		return "P1  %s · Space jump · X crouch · F light · G heavy · LShift guard · Q/E skills · R grapple · C dash · V ultimate   |   Tab hitboxes · Esc pause" % walk
	return "P1  WASD · Space · X · F light · G heavy · LShift guard · Q/E · R grapple · C dash · V ult        P2  arrows · / · M · K light · L heavy · RShift guard · ; ' · I grapple · . dash · , ult"


func _hint_profile(vs_cpu: bool) -> String:
	if profile == PROFILE_SOLO:
		var p1 := "P1  A/D move · W/Space jump · S crouch · LShift dash · E grapple (S+E pull)   J light · K heavy · L guard · U/I skills · O ultimate"
		return p1 + ("   |   Tab hitboxes · Esc pause" if vs_cpu else "      P2  gamepad (SOLO keyboard)")
	if vs_cpu:
		return "P1  A/D move · W/Space jump · S crouch · F light · G heavy · LShift guard · Q/E skills · R grapple (S+R pull) · C dash/flash · V ultimate   |   Tab hitboxes · Esc pause"
	return "P1  A/D · W · F light · G heavy · LShift guard · Q/E · R grapple · C dash · V ult        P2  ←/→ · ↑ · K light · L heavy · RShift guard · ; ' · I grapple · . dash · , ult"


## Events can arrive between physics ticks (or from Input.parse_input_event in tests); record
## them here as well so a tap shorter than one physics frame still lands in the buffer.
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	for p in [1, 2]:
		for a in ACTIONS:
			var n := "p%d_%s" % [p, a]
			if event.is_action_pressed(n):
				_pressed_at[n] = _frame


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


## Free movement: camera-relative stick, x = screen right, y = screen up (into the picture).
## In the plane mode y is always 0, so callers can use move() in both modes.
func move(player: int) -> Vector2:
	if not GameState.free_move:
		return Vector2(axis(player), 0.0)
	var y := Input.get_action_strength(action_name(player, "up")) - Input.get_action_strength(action_name(player, "down"))
	if _virtual_held.get(action_name(player, "up"), false):
		y += 1.0
	if _virtual_held.get(action_name(player, "down"), false):
		y -= 1.0
	var v := Vector2(axis(player), clampf(y, -1.0, 1.0))
	return v.normalized() if v.length() > 1.0 else v


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


## Non-consuming: was the action pressed within the last `window` frames? (perfect block etc.)
func pressed_within(player: int, action: String, window: int) -> bool:
	var n := action_name(player, action)
	var at: int = maxi(int(_pressed_at.get(n, -999)), int(_virtual_just.get(n, -999)))
	return at >= 0 and _frame - at <= window
