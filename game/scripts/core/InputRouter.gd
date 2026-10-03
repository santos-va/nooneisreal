extends Node
## Autoload: per-player action lookup + a small input buffer (in physics frames) so a button
## pressed a few frames early still produces the intended move. Also hosts the "virtual input"
## layer used by the CPU brain and the smoke test, so AI and tests go through the same path
## as a human player. Docs: docs/GDD/05-Platforms-Input.md

const BUFFER_FRAMES := 6
const ACTIONS := ["left", "right", "jump", "crouch", "light", "heavy", "block", "skill1", "skill2", "ultimate", "grapple", "dash"]
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
var profile: String = PROFILE_SOLO


func _ready() -> void:
	process_physics_priority = -100  # record input before any fighter ticks
	for p in [1, 2]:
		for a in ACTIONS:
			var n := action_name(p, a)
			var keys: Array = []
			for ev in InputMap.action_get_events(n):
				if ev is InputEventKey:
					keys.append(ev)
			_shared_keys[n] = keys
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
	_pressed_at.clear()
	if save:
		var cfg := ConfigFile.new()
		cfg.load(SETTINGS_PATH)   # keep other sections if the file exists
		cfg.set_value("input", "keyboard_profile", prof)
		cfg.save(SETTINGS_PATH)


func cycle_profile() -> void:
	apply_profile(PROFILES[wrapi(PROFILES.find(profile) + 1, 0, PROFILES.size())])


## One-line control hint for the HUD / menu, matching the active profile.
func hint_text(vs_cpu: bool) -> String:
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
