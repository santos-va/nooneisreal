class_name SmokeTest
extends Node
## Headless end-to-end check (no GPU): drives both fighters through InputRouter's virtual-input
## layer — the same path a human uses. Round 1 = Choko's kit, round 2 = Skea's kit.
## Run: godot --headless --path game -- --smoke   (make check)

var _f: int = 0
var _f0: int = 0
var _stage: int = 0
var _x0: float = 0.0
var _n0: int = 0
var arena: Node3D
var p1: Fighter
var p2: Fighter
var flow: MatchFlow
var _oks: Array[String] = []
var _done: bool = false
var _shots_dir: String = ""
var _profile0: String = ""
var _old_arena: Node = null
var _river_runs: Array = []
var _river_min_gap: float = 99.0
var _river3d_runs: Array = []
const DUEL_FRAMES := 1110   # the last ultimate (t 820) must ragdoll, land and get up inside the trace
var _duel_runs: Array = []
var _splat_phase: int = 0
var _prints: Array = []
var _y0: float = 0.0
var _picks_p: Dictionary = {}

## Design numbers as written in docs/GDD/02-Combat-System.md § «Поле → значення → джерело» (T5 Арес).
## Literals on purpose (T4 Феміда, audit 0.3-7 п. 8): the smoke must not compare the code with its own
## constants, or a number drifting away from the GDD would never turn it red.
const GDD_ARENA_RADIUS := 12.5
const GDD_YAW_CLAMP_DEG := 3.0
const GDD_PULLBACK_LAG_DEG := 15.0
const GDD_PULLBACK_MAX := 0.3
const GDD_BLOCK_ARC_DEG := 70.0
const GDD_CIRCLE_SPEED_MULT := 0.8
const GDD_GRAPPLE_CONE_DEG := 30.0
const GDD_WALL_SPLAT_FRAMES := 10
## slot → [tracking_deg, backhit_hitstun_bonus]; skills follow 03 § Як у 3D and are not in this table
const GDD_MOVES := {"light": [30.0, 2], "crouch_light": [20.0, 3], "heavy": [15.0, 3], "air_light": [10.0, 2], "ultimate": [45.0, 6], "throw": [0.0, 0]}
var _duel_trace: Array = []
var _duel_first_trace: Array = []
var _zdiff: float = 0.0
var _zmax: float = 0.0
var _atk_frames: int = 0
var _pose_changes: int = 0
var _last_pose: Array = []
var _run: int = 0
var _max_run: int = 0
# free movement (Prototype 0.3)
var _swept: float = 0.0
var _ang0: float = 0.0
var _d0: float = 0.0
var _hp0: float = 0.0
var _turn_max: float = 0.0
var _yaw_prev: float = 0.0
var _rmax: float = 0.0
var _data0: CharacterData = null
var _rotated: bool = false
var _picks: Dictionary = {}
var _v0: Vector3 = Vector3.ZERO
var _pull_max: float = 0.0
var _rig_only: bool = false
var _bone0: Vector3 = Vector3.ZERO
var _rig_hit: int = -1               # launch 4: physics frame Skea took the mannequin's light (-1 = not yet)
var _rig_swung: bool = false


func _ready() -> void:
	print("[smoke] start, godot %s" % Engine.get_version_info().string)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			_shots_dir = a.trim_prefix("--shots=")
			Engine.max_physics_steps_per_frame = 1   # one sim step per rendered frame → captures are exact
	GameState.p2_is_cpu = false
	GameState.training_mode = false
	GameState.p1_character = "choko"
	GameState.p2_character = "skea"
	GameState.stage_index = 2   # back_alley (river is index 0)
	if not _check_boot():
		return
	# free movement is the game's default now; the smoke starts with the 0.2 plane stages and switches
	# to free movement itself at stage 40 (T4 audit 0.3-7 item 7)
	GameState.set_free_move(false)
	for a in OS.get_cmdline_user_args():
		if a == "--smoke-only=rig":
			# dev / negative controls: only the launch 4 mannequin stages
			_rig_only = true
		if a == "--smoke-only=duel":
			# dev / negative controls: only the 0.3-6 duel replay (plane, then free movement)
			GameState.set_free_move(false)
			_stage = 70
	if _rig_only:
		_start_rig_stages()
		return
	get_tree().change_scene_to_file.call_deferred("res://scenes/arena/Arena.tscn")


## Checks that need no arena: the shipped defaults and launch flags (T4 audit Launch 2, proposals 2 and 3)
## and that the hero GLBs keep their texture inside (launch 4-0). false = already failed.
func _check_boot() -> bool:
	# Santos's word 2026-10-03: free movement is the default. Read it from a fresh, never-added copy of the
	# autoload, not the live value — Main may already have applied `--plane`. (get_property_default_value
	# returns null outside editor builds.)
	var fresh: Node = GameState.get_script().new()
	var def: Variant = fresh.free_move
	fresh.free()
	if def != true:
		_fail("GameState.free_move defaults to %s — Santos's word is free movement by default (true)" % def)
		return false
	var main_script: GDScript = load("res://scripts/core/Main.gd")
	# …and the boot path keeps it: after Main._ready the live value is what the flags say, else the default
	var want: bool = main_script.free_move_arg(OS.get_cmdline_user_args()) != 0
	if GameState.free_move != want:
		_fail("GameState.free_move is %s at boot, launch flags %s ask for %s" % [GameState.free_move, OS.get_cmdline_user_args(), want])
		return false
	_ok("free_move defaults to true (Santos 2026-10-03), live at boot %s" % GameState.free_move)
	var cases := [[["--plane"], 0], [["--free-move"], 1], [[], -1], [["--smoke", "--plane", "--free-move"], 0], [["--plane-off"], -1]]
	for c in cases:
		var got: int = main_script.free_move_arg(PackedStringArray(c[0]))
		if got != c[1]:
			_fail("Main.free_move_arg(%s) → %d, expected %d" % [c[0], got, c[1]])
			return false
	# the wiring Main._ready runs, on fresh copies: a flipped or dropped set_free_move shows up here
	for c in [[["--plane"], false], [["--free-move"], true], [[], true]]:
		var gs: Node = GameState.get_script().new()
		main_script.apply_launch_args(PackedStringArray(c[0]), gs)
		var on: bool = gs.free_move
		gs.free()
		if on != c[1]:
			_fail("Main.apply_launch_args(%s) left free_move %s, expected %s" % [c[0], on, c[1]])
			return false
	for c in [[["--skeletal-rig"], true], [["--plane"], false], [[], false]]:
		var gs: Node = GameState.get_script().new()
		main_script.apply_launch_args(PackedStringArray(c[0]), gs)
		var rig: bool = gs.skeletal_rig
		gs.free()
		if rig != c[1]:
			_fail("Main.apply_launch_args(%s) left skeletal_rig %s, expected %s (off by default)" % [c[0], rig, c[1]])
			return false
	_ok("launch flags: --plane → plane, --free-move → free, --skeletal-rig → mannequin, none → defaults (%d parse + 6 wiring cases)" % cases.size())
	# Import with gltf/embedded_image_handling = embed: extracting writes *_Image_0.jpg next to the GLB
	# (unregistered → `make gates` red), discarding loses the texture silently.
	var heroes := ["res://assets/characters/models/choko_m0.glb", "res://assets/characters/models/skea_m1.glb"]
	for path in heroes:
		var root: Node = (load(path) as PackedScene).instantiate()
		var meshes := root.find_children("*", "MeshInstance3D", true, false)
		var bad := "no MeshInstance3D" if meshes.is_empty() else ""
		for m in meshes:
			var mat := (m as MeshInstance3D).mesh.surface_get_material(0) as BaseMaterial3D
			var tex: Texture2D = mat.albedo_texture if mat != null else null
			if tex == null:
				bad = "%s has no albedo texture (discarded on import?)" % m.name
			elif not tex.resource_path.begins_with(path + "::"):
				bad = "%s texture is a separate file %s (extracted on import?)" % [m.name, tex.resource_path]
		root.free()
		if bad != "":
			_fail("%s: %s" % [path.get_file(), bad])
			return false
	_ok("hero GLBs keep their textures embedded (%d models)" % heroes.size())
	return true


func _ok(msg: String) -> void:
	_oks.append(msg)
	print("[smoke] OK  ", msg)


func _fail(msg: String) -> void:
	if _done:
		return
	_done = true
	printerr("[smoke] FAIL ", msg)
	print("[smoke] passed before failure: ", _oks.size())
	get_tree().quit(1)


func _on_rig_hit(_attacker: Fighter, _victim: Fighter, _m: MoveData, _blocked: bool) -> void:
	_rig_hit = Engine.get_physics_frames()


## Launch 4 (C1): the same fight again with the UAL mannequin drawing the fighters (GameState.skeletal_rig).
func _start_rig_stages() -> void:
	GameState.set_free_move(true)
	GameState.skeletal_rig = true
	if _rig_only:
		GameState.stage_index = 2
		_stage = 110
		_f0 = _f
		get_tree().change_scene_to_file.call_deferred("res://scenes/arena/Arena.tscn")
	else:
		_load_arena(2, 110)


func _finish() -> void:
	if _done:
		return
	_done = true
	GameState.set_free_move(false)
	GameState.skeletal_rig = false
	print("[smoke] ALL OK (%d checks) in %d frames" % [_oks.size(), _f])
	get_tree().quit(0)


## Saves a frame when run with a renderer and `--shots=DIR` (no-op headless).
func _shot(tag: String) -> void:
	if _shots_dir == "" or DisplayServer.get_name() == "headless":
		return
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(_shots_dir.path_join("%s.png" % tag))
		print("[smoke] shot ", tag)


## "" when every physical key of `prof` belongs to exactly one p1_/p2_ action (and SOLO gives P2
## no keys at all); otherwise a description of the first clash.
func _key_clash(prof: String) -> String:
	InputRouter.apply_profile(prof, false)
	var owner: Dictionary = {}
	for p in [1, 2]:
		for a in InputRouter.ACTIONS:
			var n := InputRouter.action_name(p, a)
			for ev in InputMap.action_get_events(n):
				if not ev is InputEventKey:
					continue
				var k := ev as InputEventKey
				if prof == InputRouter.PROFILE_SOLO and p == 2:
					return "P2 has key %s in SOLO" % OS.get_keycode_string(k.physical_keycode)
				var id := "%d@%d" % [k.physical_keycode, k.location]
				if owner.has(id):
					return "key %s in both %s and %s" % [OS.get_keycode_string(k.physical_keycode), owner[id], n]
				owner[id] = n
	if owner.is_empty():
		return "no keys at all"
	return ""


## Injects a real keyboard event (physical keycode) through the engine's input pipeline.
func _key(code: Key, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = down
	Input.parse_input_event(ev)


## (Re)loads the arena on the river stage; the main loop re-acquires it and resumes at stage 30.
func _load_river() -> void:
	_load_arena(0, 30)   # river


## (Re)loads the arena on `stage_idx`; the main loop re-acquires it and resumes at `next_stage`.
func _load_arena(stage_idx: int, next_stage: int) -> void:
	_old_arena = arena
	arena = null
	InputRouter.v_clear(1)
	InputRouter.v_clear(2)
	GameState.stage_index = stage_idx
	_stage = next_stage
	_f0 = _f
	get_tree().change_scene_to_file.call_deferred("res://scenes/arena/Arena.tscn")


## 0.3-6: one scripted duel for both modes (t = frames from FIGHT): walk in, strings, heavy, skills,
## dash/flash, jump-in, grapple, sidesteps (free movement only), and both ultimates (one ragdolls).
func _duel_script(t: int) -> void:
	InputRouter.v_set(1, "right", t < 45 or (t > 400 and t < 430))
	InputRouter.v_set(2, "left", t < 25)
	InputRouter.v_set(2, "block", (t > 120 and t < 150) or (t > 600 and t < 640))
	if GameState.free_move:
		InputRouter.v_set(1, "up", t > 300 and t < 340)
		InputRouter.v_set(2, "down", t > 460 and t < 500)
	for at in [50, 62, 74]:
		if t == at:
			InputRouter.v_press(1, "light")
	if t in [100, 520]:
		InputRouter.v_press(1, "heavy")
	if t in [160, 172, 560]:
		InputRouter.v_press(2, "light")
	if t == 200:
		InputRouter.v_press(2, "skill1")
	if t == 260:
		InputRouter.v_press(1, "skill2")
	if t == 360:
		InputRouter.v_press(2, "dash")
	if t == 440:
		InputRouter.v_press(1, "jump")
	if t == 452:
		InputRouter.v_press(1, "light")
	if t == 600:
		InputRouter.v_press(1, "grapple")
	if t == 610:
		InputRouter.v_release(1, "grapple")
	if t >= 600 and t < 680:
		_close_in(p2, p1, 1.4)
	if t == 680:
		p2.meter = Fighter.MAX_METER   # the script spends meter on skills; refill so the ultimate fires
		InputRouter.v_clear(2)
		InputRouter.v_press(2, "ultimate")
	if t >= 730 and t < 820:
		_close_in(p1, p2, 1.4)
	if t == 820:
		p1.meter = Fighter.MAX_METER
		InputRouter.v_clear(1)
		InputRouter.v_press(1, "ultimate")


## Walk `who` toward `target` until `dist` m apart, by screen side (duel frame in free movement), so
## the same call works in both modes. Pure function of the state → still deterministic.
func _close_in(who: Fighter, target: Fighter, dist: float) -> void:
	var d := target.global_position - who.global_position
	var dx := d.x
	var gap := absf(d.x)
	if GameState.free_move:
		dx = Vector3(d.x, 0.0, d.z).dot(GameState.duel.right)
		gap = Vector3(d.x, 0.0, d.z).length()
	var p := who.player_index
	InputRouter.v_set(p, "right", dx > 0.0 and gap > dist)
	InputRouter.v_set(p, "left", dx <= 0.0 and gap > dist)


## Everything the fight decides, for both fighters: body, facing, HP, meter, state, combo, statuses.
func _duel_state() -> String:
	var parts: Array[String] = []
	for f: Fighter in [p1, p2]:
		parts.append("%.5f,%.5f,%.5f|%.4f,%.4f|%.3f|%.3f|%d|%d|%d|%d|%d" % [f.global_position.x, f.global_position.y, f.global_position.z, f.forward.x, f.forward.z, f.hp, f.meter, f.state, f.combo_count, f.dot_frames, f.armor_break_frames, f.stats.hits])
	return "/".join(parts)


## 0.3-5: the same scripted inputs on every river run in free movement (t = frames from FIGHT).
## Sidesteps take both fighters off the z = 0 line so the depth term of the waves is exercised.
func _river3d_script(t: int) -> void:
	InputRouter.v_set(1, "up", t < 70 or (t > 300 and t < 360))
	InputRouter.v_set(1, "right", t > 90 and t < 130)
	InputRouter.v_set(2, "down", t > 20 and t < 110)
	InputRouter.v_set(2, "left", t > 150 and t < 190)
	InputRouter.v_set(2, "block", t > 400 and t < 450)
	if t in [140, 380]:
		InputRouter.v_press(1, "jump")
	if t in [200, 214, 470]:
		InputRouter.v_press(1, "light")
	if t in [250, 520]:
		InputRouter.v_press(2, "light")
	if t == 330:
		InputRouter.v_press(2, "dash")


## Hash of everything the water and the fighters decide at this frame: both bodies and HP, plus a
## 9×9 grid of surface heights over the arena circle (rounded to 1e-6 so it is a value, not a float bit pattern).
func _river3d_hash() -> int:
	var w := GameState.water
	var parts: Array[String] = []
	for f: Fighter in [p1, p2]:
		parts.append("%.6f,%.6f,%.6f,%.3f" % [f.global_position.x, f.global_position.y, f.global_position.z, f.hp])
	for i in 9:
		for j in 9:
			parts.append("%.6f" % w.height(-12.0 + 3.0 * i, -12.0 + 3.0 * j))
	return ";".join(parts).hash()


# --- free movement helpers (Prototype 0.3) ------------------------------------------------------
static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## Angle of `who` around `center` on the ground plane (radians).
static func _bearing(who: Fighter, center: Fighter) -> float:
	var d := _flat(who.global_position - center.global_position)
	return atan2(d.z, d.x)


## Free-movement approach: press toward the target in the duel's screen frame.
func _approach3d(who: Fighter, target: Fighter, dist: float) -> bool:
	var d := _flat(target.global_position - who.global_position)
	var p := who.player_index
	var toward_right := d.dot(GameState.duel.right) > 0.0
	InputRouter.v_set(p, "right", toward_right)
	InputRouter.v_set(p, "left", not toward_right)
	if d.length() < dist:
		InputRouter.v_set(p, "right", false)
		InputRouter.v_set(p, "left", false)
		return true
	return false


## Duel camera turn this physics frame (degrees), tracked into _turn_max; also how far the view is
## from side-on to the line between the fighters (90° = side-on), tracked into _rmax.
func _track_camera_turn() -> void:
	var y: float = arena.duel_camera.view_yaw()
	_turn_max = maxf(_turn_max, rad_to_deg(absf(angle_difference(_yaw_prev, y))))
	_yaw_prev = y
	var line := _flat(p2.global_position - p1.global_position)
	if line.length() > 0.5:
		var z: Vector3 = _flat(arena.duel_camera.cam.global_basis.z).normalized()
		_rmax = maxf(_rmax, absf(90.0 - rad_to_deg(z.angle_to(line.normalized()))))


## Puts `who` on the ground plane `dist` m from `center`, at `deg` around it from world +X (y kept),
## and lets both look at each other (lock-on would do the same on their next ground tick).
func _place(who: Fighter, center: Fighter, dist: float, deg: float) -> void:
	var d := Vector3(cos(deg_to_rad(deg)), 0.0, sin(deg_to_rad(deg))) * dist
	who.global_position = Vector3(center.global_position.x + d.x, who.global_position.y, center.global_position.z + d.z)
	who.forward = -d.normalized()
	center.forward = d.normalized()


## Records which anchor P1's grapple would pick with the current stick, and checks it is inside the
## yaw cone around the aim axis (stick, or forward when neutral).
func _cone_pick(tag: String) -> void:
	var a: Node3D = p1.grapple.best_anchor()
	if a == null:
		_fail("grapple cone (%s): no anchor picked" % tag)
		return
	var axis: Vector3 = p1.grapple.aim_axis()
	var to := _flat(a.global_position - p1.global_position)
	var ang := rad_to_deg(axis.angle_to(to.normalized()))
	if ang > p1.grapple.cone_deg + 0.01:
		_fail("grapple cone (%s): %s is %.1f° off the aim (cone %.0f°)" % [tag, a.name, ang, p1.grapple.cone_deg])
		return
	_picks[tag] = a


func _both_in_view() -> bool:
	var cam: Camera3D = arena.duel_camera.cam
	return cam.is_position_in_frustum(p1.global_position + Vector3.UP) and cam.is_position_in_frustum(p2.global_position + Vector3.UP)


## The same scripted inputs on every river run (frame t from FIGHT start), so runs can be compared.
func _river_script(t: int) -> void:
	InputRouter.v_set(1, "right", t < 50 or (t > 420 and t < 470))
	InputRouter.v_set(2, "left", t < 30)
	InputRouter.v_set(2, "block", t > 200 and t < 260)
	InputRouter.v_set(1, "crouch", t > 500 and t < 530)
	if t in [80, 300]:
		InputRouter.v_press(1, "jump")
	if t in [140, 152, 400]:
		InputRouter.v_press(1, "light")
	if t in [180, 350]:
		InputRouter.v_press(2, "light")
	if t == 240:
		InputRouter.v_press(1, "heavy")
	if t == 320:
		InputRouter.v_press(2, "dash")
	if t == 460:
		InputRouter.v_press(2, "jump")


## "" when the code's design numbers equal the GDD literals above; else the first mismatch.
func _gdd_mismatch() -> String:
	var got := {"Fighter.ARENA_RADIUS": [Fighter.ARENA_RADIUS, GDD_ARENA_RADIUS], "DuelCamera.YAW_CLAMP_DEG": [DuelCamera.YAW_CLAMP_DEG, GDD_YAW_CLAMP_DEG], "DuelCamera.PULLBACK_LAG_DEG": [DuelCamera.PULLBACK_LAG_DEG, GDD_PULLBACK_LAG_DEG], "DuelCamera.PULLBACK_MAX": [DuelCamera.PULLBACK_MAX, GDD_PULLBACK_MAX], "Fighter.WALL_SPLAT_FRAMES": [float(Fighter.WALL_SPLAT_FRAMES), float(GDD_WALL_SPLAT_FRAMES)]}
	for f: Fighter in [p1, p2]:
		var d := f.data
		got["%s.block_arc_deg" % d.id] = [d.block_arc_deg, GDD_BLOCK_ARC_DEG]
		got["%s.circle_speed_mult" % d.id] = [d.circle_speed_mult, GDD_CIRCLE_SPEED_MULT]
		got["%s.grapple_cone_deg" % d.id] = [d.grapple_cone_deg, GDD_GRAPPLE_CONE_DEG]
		var mv := d.moves()
		for slot in GDD_MOVES:
			var m: MoveData = mv.get(slot)
			if m == null:
				return "%s has no move in slot %s" % [d.id, slot]
			got["%s.%s.tracking_deg" % [d.id, slot]] = [m.tracking_deg, float(GDD_MOVES[slot][0])]
			got["%s.%s.backhit_hitstun_bonus" % [d.id, slot]] = [float(m.backhit_hitstun_bonus), float(GDD_MOVES[slot][1])]
	for k in got:
		if absf(float(got[k][0]) - float(got[k][1])) > 0.0001:
			return "%s = %s, GDD says %s" % [k, got[k][0], got[k][1]]
	return ""


## Jump to stage `st` (resets the stage clock and virtual input, like _next()).
func _next_to(st: int) -> void:
	_stage = st - 1
	_next()


func _next() -> void:
	_stage += 1
	_f0 = _f
	InputRouter.v_clear(1)
	InputRouter.v_clear(2)


func _approach(who: Fighter, target: Fighter, dist: float) -> bool:
	var dx := target.global_position.x - who.global_position.x
	var p := who.player_index
	InputRouter.v_set(p, "right", dx > 0.0)
	InputRouter.v_set(p, "left", dx <= 0.0)
	if absf(dx) < dist:
		InputRouter.v_set(p, "right", false)
		InputRouter.v_set(p, "left", false)
		return true
	return false


func _physics_process(_delta: float) -> void:
	if _done:
		return
	_f += 1
	if _f > 15000:
		_fail("timeout at stage %d (p1 %d, p2 %d)" % [_stage, p1.state if p1 else -1, p2.state if p2 else -1])
		return
	if arena == null:
		var cs := get_tree().current_scene
		if cs == null or cs.name != "Arena" or cs == _old_arena or not cs.is_inside_tree():
			return
		arena = cs
		p1 = arena.p1
		p2 = arena.p2
		flow = arena.flow
		_ok("arena loaded: %s vs %s, stage %s" % [p1.data.display_name, p2.data.display_name, GameState.stage().id])
		if not GameState.skeletal_rig and (p1.skeletal != null or p1.get_node_or_null("SkeletalRig") != null):
			_fail("capsule mode built a SkeletalRig — skeletal_rig is off by default")
			return
		if _stage == 0 and GameState.free_move:
			_fail("plane stages started under free_move — SmokeTest._ready must set_free_move(false)")
			return
		var bus := AudioServer.get_bus_index(Sfx.BUS)
		var vh := Sfx.variant_count("hit_light")
		if bus == -1 or AudioServer.get_bus_effect_count(bus) < 2 or vh < 3 or Sfx.variant_count("no_such_sfx") != 0:
			_fail("SFX: bus %d (effects %d), hit_light variants %d" % [bus, AudioServer.get_bus_effect_count(bus) if bus != -1 else 0, vh])
			return
		_ok("SFX bus with %d effects; hit_light %d variants, hit_heavy %d, whoosh %d" % [AudioServer.get_bus_effect_count(bus), vh, Sfx.variant_count("hit_heavy"), Sfx.variant_count("whoosh")])
		return
	match _stage:
		# ---------------- round 1: Choko ----------------
		0:
			if flow.phase == MatchFlow.Phase.FIGHT:
				_ok("round 1 started at frame %d" % _f)
				_next()
		1:
			if _approach(p1, p2, 1.7):
				_ok("walked into range")
				_next()
		2:
			if _f == _f0 + 2 or _f == _f0 + 14:
				InputRouter.v_press(1, "light")
			if p1.state == Fighter.State.ATTACK and p1.current_move != null and p1.chain_index == 0:
				if p1.move_frame == 2:
					_shot("00a_strike_windup")
				elif p1.move_frame == p1.current_move.startup + 1:
					_shot("00b_strike_impact")
			if p1.state == Fighter.State.ATTACK:
				_atk_frames += 1
				var snap: Array = p1.animator.pose.values()
				if snap != _last_pose:
					_pose_changes += 1
					_run += 1
					_max_run = maxi(_max_run, _run)
				else:
					_run = 0
				_last_pose = snap
			else:
				_run = 0
			if _f > _f0 + 50:
				if p2.hp < p2.data.max_hp:
					_ok("light string hit: p2 hp %.0f/%.0f" % [p2.hp, p2.data.max_hp])
					# 12 fps stepping: the arm may change only on step/key frames, never every frame
					# held drawings: a pose may change on two adjacent frames at most (a key frame next to
					# a step), never in a longer run — a run ≥ 3 means per-frame (60 fps) motion
					if _pose_changes < 2 or _max_run > 2:
						_fail("attack pose stepping: %d changes, longest run of changing frames %d (want ≤ 2)" % [_pose_changes, _max_run])
						return
					var wind := RigAnimator.attack_ext(0.45)
					var over := RigAnimator.attack_ext(1.0)
					if wind >= 0.0 or over <= 1.0 or absf(RigAnimator.attack_ext(3.0)) > 0.001:
						_fail("attack curve: wind-up %.2f, overshoot %.2f" % [wind, over])
						return
					_ok("strike readability: pose changed %d× over %d attack frames, longest run %d (12 fps steps), wind-up %.2f, overshoot %.2f, flinch zone '%s'" % [_pose_changes, _atk_frames, _max_run, wind, over, p2.animator.flinch_zone])
					_next()
				else:
					_fail("light did not connect")
		3:
			if p1.is_actionable() and _f > _f0 + 4 and _f0 > 0 and _x0 == 0.0:
				_x0 = 1.0
				InputRouter.v_press(1, "skill2")
			if p2.frozen_frames > 0:
				_ok("TIME STOP froze Skea (%d frames left, status '%s')" % [p2.frozen_frames, p2._status_text])
				_x0 = p2.hp
				_next()
			elif _f > _f0 + 90:
				_fail("time stop did not freeze (p1 state %d, dist %.2f)" % [p1.state, absf(p1.global_position.x - p2.global_position.x)])
		4:
			if _f == _f0 + 12:
				_shot("01_choko_time_stop")
			if p2.frozen_frames > 0 and p1.is_actionable() and _approach(p1, p2, 1.6) and _n0 == 0:
				_n0 = 1
				InputRouter.v_press(1, "light")
			if p2.frozen_frames == 0 and _f > _f0 + 4:
				if p2.hp < _x0:
					_ok("hit landed during frozen time, released on resume (hp %.0f → %.0f)" % [_x0, p2.hp])
					_next()
				else:
					_fail("no damage during time stop")
		5:
			_n0 = 0
			if p1.is_actionable() and p1.cooldowns.skill1 <= 0.0:
				_x0 = p1.global_position.x
				InputRouter.v_press(1, "skill1")
				_next()
		6:
			if p1.record_marker != null and _f < _f0 + 40:
				InputRouter.v_set(1, "left" if _x0 > 0.0 else "right", true)
			if _f == _f0 + 40:
				InputRouter.v_clear(1)
				if p1.record_marker == null:
					_fail("record marker was not placed")
					return
				_ok("RECORD marker placed; walked %.2f m away" % absf(p1.global_position.x - _x0))
				InputRouter.v_press(1, "skill1")
			if _f == _f0 + 30:
				_shot("02_choko_record_marker")
			if _f == _f0 + 43:
				_shot("03_choko_rewind_trail")
			if _f > _f0 + 44:
				if p1.record_marker == null and absf(p1.global_position.x - _x0) < 0.35:
					_ok("REWIND snapped Choko back (x %.2f ≈ %.2f), skill1 cd %.1f s" % [p1.global_position.x, _x0, p1.cooldowns.skill1])
					_next()
				elif _f > _f0 + 70:
					_fail("rewind failed (x %.2f vs %.2f, marker %s)" % [p1.global_position.x, _x0, p1.record_marker])
		7:
			if p1.is_actionable():
				InputRouter.v_set(1, "grapple", true)
				_next()
		8:
			InputRouter.v_set(1, "grapple", true)
			if p1.state == Fighter.State.GRAPPLE:
				_ok("grapple attached (charges left %d)" % p1.grapple.charges)
				_next()
			elif _f > _f0 + 30:
				_fail("grapple did not attach")
		9:
			InputRouter.v_set(1, "grapple", _f < _f0 + 40)
			if _f > _f0 + 50 and p1.state != Fighter.State.GRAPPLE:
				_ok("grapple released")
				_next()
			elif _f > _f0 + 200:
				_fail("grapple never released")
		10:
			if p1.is_actionable() and _approach(p1, p2, 1.8):
				p2.hp = 150.0
				p1.meter = Fighter.MAX_METER
				_next()
		11:
			if _f == _f0 + 3:
				InputRouter.v_press(1, "ultimate")
			if _f == _f0 + 30 or _f == _f0 + 62:
				_shot("04_choko_sword_storm_%d" % (_f - _f0))
			if p2.state == Fighter.State.KO:
				_ok("SWORD STORM KO'd Skea (ragdolls so far %d)" % p2.stats.ragdolls)
				_next()
			elif _f > _f0 + 150:
				_fail("sword storm did not KO (p2 hp %.0f state %d, p1 state %d)" % [p2.hp, p2.state, p1.state])
		# ---------------- round 2: Skea ----------------
		12:
			if flow.round_no == 2 and flow.phase == MatchFlow.Phase.FIGHT:
				_ok("round 2 started; driving Skea now")
				_next()
		13:
			if _approach(p2, p1, 1.5):
				_x0 = signf(p2.global_position.x - p1.global_position.x)
				_n0 = get_tree().get_nodes_in_group("afterimage").size()
				var toward := "left" if _x0 > 0.0 else "right"
				InputRouter.v_set(2, toward, true)
				InputRouter.v_press(2, "dash")
				_next()
		14:
			if _f == _f0 + 2 or _f == _f0 + 4:
				_shot("05_skea_flash_step_%d" % (_f - _f0))
			if _f == _f0 + 5:
				var ghosts := get_tree().get_nodes_in_group("afterimage").size()
				var side := signf(p2.global_position.x - p1.global_position.x)
				if side != _x0 and p2.dash_charges_left == 2 and ghosts > _n0:
					_ok("FLASH-STEP passed through Choko (side %+d → %+d), %d ghosts, charges %d" % [_x0, side, ghosts, p2.dash_charges_left])
					_next()
				else:
					_fail("flash failed (side %s→%s, charges %d, ghosts %d)" % [_x0, side, p2.dash_charges_left, ghosts])
		15:
			if p2.is_actionable() and _f > _f0 + 6:
				InputRouter.v_press(2, "skill1")
				_next()
		16:
			if _f == _f0 + 30:
				_shot("06_skea_kunai_rain")
			if _f > _f0 + 80:
				if p1.hp < p1.data.max_hp and (p1.armor_break_frames > 0 or p1.state == Fighter.State.LAUNCHED):
					_ok("KUNAI RAIN hit: Choko hp %.0f, armor break %d f" % [p1.hp, p1.armor_break_frames])
					_next()
				else:
					_fail("kunai rain missed (p1 hp %.0f, armor %d, dist %.2f)" % [p1.hp, p1.armor_break_frames, absf(p1.global_position.x - p2.global_position.x)])
		17:
			if p2.is_actionable():
				InputRouter.v_press(2, "skill2")
				_next()
		18:
			if _f == _f0 + 11:
				_shot("07_skea_shadow_veil")
			if _f == _f0 + 12:
				if p2.veil_frames > 0 and not p2.animator.visible:
					_ok("SHADOW VEIL: invisible %d f, smoke clouds %d" % [p2.veil_frames, get_tree().get_nodes_in_group("smoke").size()])
					_next()
				else:
					_fail("veil not active (frames %d, visible %s)" % [p2.veil_frames, p2.animator.visible])
		19:
			if p1.is_actionable() or p1.state == Fighter.State.IDLE:
				if _approach(p2, p1, 1.5):
					InputRouter.v_press(2, "light")
					_next()
			elif _f > _f0 + 200:
				_fail("p1 never became actionable for the veil strike")
		20:
			if p1.last_hit_crit and p1.dot_frames > 0:
				_ok("veil strike CRIT + bleed (%d f), Skea crits %d" % [p1.dot_frames, p2.stats.crits])
				_next()
			elif _f > _f0 + 40:
				_fail("no crit from veil (crit %s, dot %d, p1 state %d)" % [p1.last_hit_crit, p1.dot_frames, p1.state])
		21:
			if p2.is_actionable() and (p1.is_actionable() or p1.state == Fighter.State.IDLE or p1.state == Fighter.State.HITSTUN):
				if _approach(p2, p1, 2.2):
					p1.hp = 1000.0
					p2.meter = Fighter.MAX_METER
					_n0 = p1.stats.ragdolls
					InputRouter.v_press(2, "ultimate")
					_next()
		22:
			if _f == _f0 + 30 or _f == _f0 + 50:
				_shot("08_skea_grimoire_%d" % (_f - _f0))
			if p1.stats.ragdolls > _n0:
				_ok("CURSED GRIMOIRE: Choko ragdolled, hp %.0f, poison %d f" % [p1.hp, p1.dot_frames])
				_next()
			elif _f > _f0 + 160:
				_fail("grimoire did not ragdoll (p1 hp %.0f, state %d)" % [p1.hp, p1.state])
		23:
			if p1.state == Fighter.State.IDLE or p1.is_actionable():
				_ok("Choko got up after the ragdoll")
				p1.hp = 30.0
				_next()
			elif _f > _f0 + 260:
				_fail("Choko never got up")
		24:
			if p2.is_actionable() and _approach(p2, p1, 1.5):
				InputRouter.v_press(2, "light")
			if p1.state == Fighter.State.KO:
				_ok("Skea KO'd Choko; wins p1=%d p2=%d" % [flow.wins[1], flow.wins[2]])
				_next()
			elif _f > _f0 + 300:
				_fail("could not KO Choko (hp %.0f, state %d)" % [p1.hp, p1.state])
		25:
			if flow.round_no == 3 and flow.phase == MatchFlow.Phase.INTRO:
				_ok("round 3 started (1-1)")
				_next()
		# ---------------- keyboard profiles (ADR-009): real key events, not virtual input -------
		26:
			if flow.phase == MatchFlow.Phase.FIGHT and p1.is_actionable() and p2.is_actionable():
				_profile0 = InputRouter.profile
				for prof in InputRouter.PROFILES:
					var clash := _key_clash(prof)
					if clash != "":
						_fail("profile %s: %s" % [prof, clash])
						return
				_ok("profiles SOLO/SHARED: every key drives one action; SOLO leaves P2 keyless")
				InputRouter.apply_profile(InputRouter.PROFILE_SOLO, false)
				_key(KEY_J, true)
				_next()
		27:
			if _f == _f0 + 2:
				_key(KEY_J, false)
			if p1.state == Fighter.State.ATTACK and p2.state != Fighter.State.ATTACK:
				_ok("SOLO: key J → P1 %s (P2 idle)" % p1.current_move.id)
				_next()
			elif _f > _f0 + 20:
				_fail("SOLO: J did not start a P1 attack (p1 state %d, p2 state %d)" % [p1.state, p2.state])
		28:
			if p1.is_actionable() and p2.is_actionable() and _f > _f0 + 30:
				InputRouter.apply_profile(InputRouter.PROFILE_SHARED, false)
				_key(KEY_K, true)
				_next()
		29:
			if _f == _f0 + 2:
				_key(KEY_K, false)
			if p2.state == Fighter.State.ATTACK and p1.state != Fighter.State.ATTACK:
				_ok("SHARED: key K → P2 %s (P1 idle)" % p2.current_move.id)
				InputRouter.apply_profile(_profile0, false)
				_load_river()
			elif _f > _f0 + 20:
				_fail("SHARED: K did not start a P2 attack (p1 state %d, p2 state %d)" % [p1.state, p2.state])
		# ---------------- river stage (docs/World/Stage-River.md § Перевірка) -------------------
		30:
			if flow.phase == MatchFlow.Phase.FIGHT and GameState.water != null:
				_ok("river run %d: water stage live (stage %s, swell every %.0f–%.0f s)" % [_river_runs.size() + 1, GameState.stage().id, GameState.water.swell_every_min, GameState.water.swell_every_max])
				_river_min_gap = 99.0
				_next()
		31:
			var t := _f - _f0
			_river_script(t)
			for f: Fighter in [p1, p2]:
				var gap := f.global_position.y - GameState.water.height(f.global_position.x)
				_river_min_gap = minf(_river_min_gap, gap)
				if gap < -0.05:
					_fail("river: P%d sank (y %.3f, surface %.3f, frame %d, state %d)" % [f.player_index, f.global_position.y, f.global_position.y - gap, t, f.state])
					return
			if t == 200 and _river_runs.is_empty():
				_shot("10_river_fight")
			if t == 600:
				_river_runs.append([p1.global_position, p2.global_position, p1.hp, p2.hp, GameState.water.height(0.0)])
				_ok("river run %d: nobody sank in 600 frames (min gap %.3f m); p1 x %.4f y %.4f, p2 x %.4f y %.4f" % [_river_runs.size(), _river_min_gap, p1.global_position.x, p1.global_position.y, p2.global_position.x, p2.global_position.y])
				if _river_runs.size() == 1:
					_load_river()
				else:
					var a: Array = _river_runs[0]
					var b: Array = _river_runs[1]
					var d: float = (a[0] as Vector3).distance_to(b[0]) + (a[1] as Vector3).distance_to(b[1]) + absf(a[2] - b[2]) + absf(a[3] - b[3]) + absf(a[4] - b[4])
					if d > 1e-5:
						_fail("river: two runs differ at frame 600 (Σ|Δ| %.6f): %s vs %s" % [d, str(a), str(b)])
						return
					_ok("river: deterministic — both runs identical at frame 600 (Σ|Δ| %.6f)" % d)
					_next()
		32:
			# both made unsteady; P1 guards, P2 stands idle; a 0.7 swell must topple only P2
			if p1.is_actionable() and p2.is_actionable() and p1.on_ground() and p2.on_ground():
				p1.data = p1.data.duplicate()
				p2.data = p2.data.duplicate()
				p1.data.water_balance = 0.55
				p2.data.water_balance = 0.55
				_next()
		33:
			InputRouter.v_set(1, "block", _f < _f0 + 9 + GameState.water.stumble_frames + 4)   # _next() clears virtual input
			if _f == _f0 + 6:
				_n0 = int(p1.stats.get("stumbles", 0))
				GameState.water.force_swell_next(0.7)
			if _f == _f0 + 9:
				if p2.state != Fighter.State.STUMBLE:
					_fail("swell 0.7 did not topple P2 with balance 0.55 (state %d)" % p2.state)
					return
				if p1.state == Fighter.State.STUMBLE or int(p1.stats.get("stumbles", 0)) != _n0:
					_fail("P1 stumbled while guarding (held %s, stumbles %s → %s)" % [InputRouter.held(1, "block"), _n0, p1.stats.get("stumbles", 0)])
					return
				InputRouter.v_press(2, "light")
				_shot("09_river_swell_stumble")
			if _f == _f0 + 12:
				if p2.state == Fighter.State.ATTACK:
					_fail("P2 attacked out of a stumble")
					return
				_ok("swell 0.7: P2 (balance 0.55) STUMBLE, can't attack; P1 guarding stays %d (BLOCK)" % p1.state)
			if _f == _f0 + 9 + GameState.water.stumble_frames + 4:
				if p2.state == Fighter.State.STUMBLE:
					_fail("stumble did not end after %d frames" % GameState.water.stumble_frames)
					return
				InputRouter.v_clear(1)
				p1.data.water_balance = 0.85
				p2.data.water_balance = 0.85
				_next()
		34:
			if _f == _f0 + 6:
				GameState.water.force_swell_next(0.7)
			if _f == _f0 + 10:
				if p1.state == Fighter.State.STUMBLE or p2.state == Fighter.State.STUMBLE:
					_fail("balance 0.85 stumbled on a 0.7 swell")
					return
				_ok("swell 0.7 vs balance 0.85: both stay up")
				GameState.set_free_move(true)
				_load_arena(2, 40)   # back_alley, free movement
			elif _f > _f0 + 400:
				_fail("round 3 never started")
		# ---------------- free movement, GameState.free_move (Prototype 0.3-1, 0.3-2) -------------
		40:
			if flow.phase == MatchFlow.Phase.FIGHT and p1.is_actionable() and p2.is_actionable():
				_profile0 = InputRouter.profile
				for prof in InputRouter.PROFILES:
					var clash := _key_clash(prof)
					if clash != "":
						_fail("free move, profile %s: %s" % [prof, clash])
						return
				InputRouter.apply_profile(InputRouter.PROFILE_SOLO, false)
				var w_up := false
				for ev in InputMap.action_get_events("p1_up"):
					w_up = w_up or (ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_W)
				var w_jump := false
				for ev in InputMap.action_get_events("p1_jump"):
					w_jump = w_jump or (ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_W)
				InputRouter.apply_profile(_profile0, false)
				if not w_up or w_jump:
					_fail("free move SOLO: W on up %s, W on jump %s (want true, false)" % [w_up, w_jump])
					return
				if get_viewport().get_camera_3d() != arena.duel_camera.cam:
					_fail("free move: duel camera is not the current camera")
					return
				_ok("free move: duel camera current; SOLO W/S → sidestep (TODO #26), no key clashes in SOLO/SHARED")
				var gdd := _gdd_mismatch()
				if gdd != "":
					_fail("design numbers drifted from docs/GDD/02: " + gdd)
					return
				_ok("design numbers = GDD 02 literals: radius 12.5, yaw clamp 3°, pull-back 15°/30 %, block arc 70°, circling 0.8, cone 30°, wall splat 10 f, tracking and back-hit per move class")
				_ang0 = _bearing(p1, p2)
				_d0 = _flat(p1.global_position - p2.global_position).length()
				_swept = 0.0
				_next()
		41:
			# 0.3-1: sidestep 90° around the opponent; lock-on keeps facing them
			InputRouter.v_set(1, "up", true)
			var a := _bearing(p1, p2)
			_swept += angle_difference(_ang0, a)
			_ang0 = a
			if absf(_swept) >= PI * 0.5:
				InputRouter.v_clear(1)
				var to := _flat(p2.global_position - p1.global_position).normalized()
				var off := rad_to_deg(p1.forward.angle_to(to))
				var d := _flat(p1.global_position - p2.global_position).length()
				# circling speed = circle_speed_mult × walk_speed (T5 Арес): a quarter circle of radius d takes
				# (π/2 · d) / v seconds
				var want_f := (PI * 0.5 * _d0) / (GDD_CIRCLE_SPEED_MULT * p1.data.walk_speed) * 60.0
				if absf(float(_f - _f0) - want_f) > want_f * 0.05:
					_fail("sidestep speed: 90° took %d frames, want %.0f ± 5 %% (circle_speed_mult %.2f × walk %.1f)" % [_f - _f0, want_f, GDD_CIRCLE_SPEED_MULT, p1.data.walk_speed])
					return
				if off >= 5.0 or absf(d - _d0) > 0.01 or absf(p1.global_position.z) < 0.5:
					_fail("sidestep 90°: forward off by %.2f° (want < 5), distance %.3f → %.3f (want ±0.01), z %.2f" % [off, _d0, d, p1.global_position.z])
					return
				_shot("11_free_sidestep_90")
				_ok("sidestep 90° in %d frames (want %.0f at %.1f × walk): forward %.2f° off the opponent, distance %.3f → %.3f (arc, not spiral), p1 z %.2f" % [_f - _f0, want_f, GDD_CIRCLE_SPEED_MULT, off, _d0, d, p1.global_position.z])
				_n0 = 0
				_data0 = p1.data
				_next()
			elif _f > _f0 + 400:
				_fail("sidestep never reached 90° (swept %.1f°)" % rad_to_deg(_swept))
		42:
			if p1.is_actionable() and p2.is_actionable() and _approach3d(p1, p2, 1.5):
				_hp0 = p2.hp
				_rotated = false
				_ang0 = 0.0
				InputRouter.v_press(1, "light")
				_next()
		43:
			# 0.3-1: the opponent steps 60° around the attacker at the start of a light; tracking
			# (light: 30°, T5 Арес) turns the strike so it still lands. 60° − 30° = 30° stays inside the
			# hitbox at 1.5 m; 60° without tracking does not (negative control, attempt 2).
			if p1.state == Fighter.State.ATTACK and not _rotated:
				_rotated = true
				_ang0 = atan2(-p1.forward.z, p1.forward.x)
				var rel := _flat(p2.global_position - p1.global_position).normalized() * 1.5
				p2.global_position = p1.global_position + rel.rotated(Vector3.UP, deg_to_rad(60.0)) + Vector3(0.0, p2.global_position.y - p1.global_position.y, 0.0)
			if _rotated and p1.state == Fighter.State.ATTACK and p1.move_frame == p1.current_move.startup:
				# turn measured on the first active frame — after the attack lock-on turns the fighter anyway
				_d0 = rad_to_deg(absf(angle_difference(_ang0, atan2(-p1.forward.z, p1.forward.x))))
			if _f == _f0 + 30:
				var turned := _d0
				var hit := p2.hp < _hp0
				if _n0 == 0:
					var budget: float = GDD_MOVES["light"][0]
					if not hit or absf(turned - budget) > 0.5:
						_fail("tracking: 60°-off light hit %s, turned %.1f° (want hit, %.1f° = tracking_deg)" % [hit, turned, budget])
						return
					_ok("tracking: light started 60° off the opponent turned %.1f° and hit (hp %.0f → %.0f)" % [turned, _hp0, p2.hp])
					p1.data = _data0.duplicate(true)
					p1.data.light.tracking_deg = 0.0
					_n0 = 1
					_stage = 42
					_f0 = _f
					InputRouter.v_clear(1)
				else:
					p1.data = _data0
					if hit or turned > 0.5:
						_fail("tracking negative control: tracking 0° still hit %s, turned %.1f°" % [hit, turned])
						return
					_ok("tracking negative control: with tracking_deg 0 the same strike turns %.1f° and misses" % turned)
					_rmax = 0.0
					_next()
		44:
			# 0.3-1: walk straight away from the opponent into the arena edge; never past the circle
			if not p1.is_actionable() and _f < _f0 + 60:
				return
			var away_right := _flat(p1.global_position - p2.global_position).dot(GameState.duel.right) > 0.0
			InputRouter.v_set(1, "right", away_right)
			InputRouter.v_set(1, "left", not away_right)
			_rmax = maxf(_rmax, _flat(p1.global_position).length())
			if _rmax > GDD_ARENA_RADIUS + 0.001:
				_fail("arena circle: p1 at radius %.3f > %.2f" % [_rmax, GDD_ARENA_RADIUS])
				return
			if _f > _f0 + 420:
				if _rmax < GDD_ARENA_RADIUS - 0.05:
					_fail("arena circle: never reached the edge (max radius %.2f)" % _rmax)
					return
				_ok("arena circle: walked into the edge, max radius %.3f ≤ %.2f" % [_rmax, GDD_ARENA_RADIUS])
				_next()
		45:
			if _f == _f0 + 1:
				# back to a duel distance in the middle, then a full circle around the opponent
				p1.global_position = Vector3(-2.0, p1.global_position.y, 0.0)
				p2.global_position = Vector3(2.0, p2.global_position.y, 0.0)
			if _f == _f0 + 20:
				_yaw_prev = arena.duel_camera.view_yaw()
				_turn_max = 0.0
				_rmax = 0.0
				_pull_max = 0.0
				_ang0 = _bearing(p1, p2)
				_swept = 0.0
			if _f > _f0 + 20:
				InputRouter.v_set(1, "up", true)
				_track_camera_turn()
				_pull_max = maxf(_pull_max, arena.backdrop.view_angle(arena.duel_camera.cam))
				var a := _bearing(p1, p2)
				_swept += angle_difference(_ang0, a)
				_ang0 = a
				if _f == _f0 + 120:
					_shot("12_free_duel_camera")
				if absf(_swept) >= TAU:
					InputRouter.v_clear(1)
					if _turn_max > (GDD_YAW_CLAMP_DEG + 0.001) or not _both_in_view() or _rmax > DuelCamera.MAX_SIDE_OFF_DEG or _pull_max >= 90.0:
						_fail("duel camera on a 360° sidestep: max turn %.2f°/frame (bound %.1f), off side-on %.1f° (bound %.1f), both in view %s, backdrop at %.1f° (want < 90)" % [_turn_max, (GDD_YAW_CLAMP_DEG + 0.001), _rmax, DuelCamera.MAX_SIDE_OFF_DEG, _both_in_view(), _pull_max])
						return
					_ok("duel camera: 360° sidestep in %d frames, max turn %.2f°/frame ≤ clamp %.3f, at most %.1f° off side-on ≤ %.1f, both fighters in view, backdrop at most %.1f° off the view (< 90)" % [_f - _f0 - 20, _turn_max, (GDD_YAW_CLAMP_DEG + 0.001), _rmax, DuelCamera.MAX_SIDE_OFF_DEG, _pull_max])
					_next()
				elif _f > _f0 + 900:
					_fail("360° sidestep not finished (swept %.1f°)" % rad_to_deg(_swept))
		46:
			# 0.3-2: the fighters swap sides in one frame (flash-step through, jump over): the camera
			# must not flip 180°, the fighters swap sides on screen instead
			if _f == _f0 + 1:
				_yaw_prev = arena.duel_camera.view_yaw()
				_turn_max = 0.0
				var a := p1.global_position
				p1.global_position = Vector3(p2.global_position.x, a.y, p2.global_position.z)
				p2.global_position = Vector3(a.x, p2.global_position.y, a.z)
			elif _f > _f0 + 1:
				_track_camera_turn()
			if _f == _f0 + 40:
				var cam: Camera3D = arena.duel_camera.cam
				var s1 := cam.unproject_position(p1.global_position + Vector3.UP).x
				var s2 := cam.unproject_position(p2.global_position + Vector3.UP).x
				if _turn_max > (GDD_YAW_CLAMP_DEG + 0.001) or not _both_in_view():
					_fail("duel camera on a side swap: max turn %.2f°/frame, both in view %s" % [_turn_max, _both_in_view()])
					return
				_shot("13_free_side_swap")
				_ok("duel camera: side swap without a flip, max turn %.2f°/frame; screen x p1 %.0f, p2 %.0f" % [_turn_max, s1, s2])
				# the line jumps 90° in one frame: the yaw clamp must hold and the arm must pull back
				_yaw_prev = arena.duel_camera.view_yaw()
				_turn_max = 0.0
				_pull_max = 0.0
				var r := _flat(p2.global_position - p1.global_position).length()
				p2.global_position = Vector3(p1.global_position.x, p2.global_position.y, p1.global_position.z - r)
			elif _f > _f0 + 40 and _f <= _f0 + 120:
				_pull_max = maxf(_pull_max, arena.duel_camera.pullback())
			if _f == _f0 + 120:
				var lag := rad_to_deg(absf(angle_difference(arena.duel_camera.view_yaw(), arena.duel_camera._target_yaw())))
				if _turn_max > GDD_YAW_CLAMP_DEG + 0.001 or _pull_max < 0.2 or lag > 1.0 or not _both_in_view():
					_fail("duel camera on a 90° jump: max turn %.2f°/tick (clamp %.1f), max pull-back %.2f (want > 0.2), lag after 80 ticks %.1f°, both in view %s" % [_turn_max, GDD_YAW_CLAMP_DEG, _pull_max, lag, _both_in_view()])
					return
				_ok("duel camera on a 90° jump: max turn %.2f°/tick ≤ %.1f, arm pulled back to +%.0f %%, caught up (lag %.2f°)" % [_turn_max, GDD_YAW_CLAMP_DEG, _pull_max * 100.0, lag])
				_next()
		47:
			# 0.3-3: the anchor is chosen inside the aim cone — of the stick when deflected, else of the
			# gaze; the same spot gives a different anchor for stick up / down / neutral
			if _f == _f0 + 1:
				p1.global_position = Vector3(-2.0, p1.global_position.y, 0.0)
				p2.global_position = Vector3(2.0, p2.global_position.y, 0.0)
			if _f == _f0 + 10:
				InputRouter.v_set(1, "up", true)
			if _f == _f0 + 11:
				_cone_pick("up")
				InputRouter.v_set(1, "up", false)
				InputRouter.v_set(1, "down", true)
			if _f == _f0 + 12:
				_cone_pick("down")
				InputRouter.v_set(1, "down", false)
			if _f == _f0 + 13:
				_cone_pick("neutral")
				if _done:
					return
				var up: Node3D = _picks["up"]
				var down: Node3D = _picks["down"]
				var neutral: Node3D = _picks["neutral"]
				if up == down or up == neutral or down == neutral or signf(up.global_position.z) == signf(down.global_position.z):
					_fail("grapple cone: up %s, down %s, neutral %s — want three different anchors, up/down on opposite sides" % [up.name, down.name, neutral.name])
					return
				# next to a lamp: the nearest anchor (Anchor2 at x −4.5) is 90° off a stick-up aim and must lose
				p1.global_position = Vector3(-4.0, p1.global_position.y, 0.0)
			if _f == _f0 + 15:
				InputRouter.v_set(1, "up", true)
			if _f == _f0 + 16:
				_cone_pick("up_near_lamp")
				InputRouter.v_set(1, "up", false)
				if _done:
					return
				var near: Node3D = _picks["up_near_lamp"]
				_ok("grapple cone %.0f°: stick up → %s, down → %s, neutral (gaze) → %s; next to %s with stick up → %s (the lamp beside is outside the cone)" % [p1.grapple.cone_deg, (_picks["up"] as Node3D).name, (_picks["down"] as Node3D).name, (_picks["neutral"] as Node3D).name, "Anchor2", near.name])
				p1.global_position = Vector3(-2.0, p1.global_position.y, 0.0)
				p2.global_position = Vector3(2.0, p2.global_position.y, 0.0)
				_next()
		48:
			# 0.3-3: zip/reel into the depth: hold up + hold grapple until the hook reaches the anchor
			if _f == _f0 + 3:
				InputRouter.v_set(1, "up", true)
				_x0 = 0.0
				_rmax = 99.0
				InputRouter.v_set(1, "grapple", true)
			if _f > _f0 + 3:
				if _x0 > 0.0 or p1.state == Fighter.State.GRAPPLE:
					# measured on the release frame too (the hook lets go the frame it reaches the anchor)
					_d0 = p1.grapple.anchor_point.z
					_rmax = minf(_rmax, (p1.grapple.anchor_point - (p1.global_position + GrappleHook.HAND)).length())
				if p1.state == Fighter.State.GRAPPLE:
					_x0 = 1.0
					if p1.grapple._frames == 10:
						_shot("14_free_grapple_zip")
				elif _x0 > 0.0:
					if _rmax > 1.4 or absf(_d0) < 1.0 or signf(p1.global_position.z) != signf(_d0):
						_fail("grapple 3D: closest to anchor %.2f m (want < 1.4), anchor z %.2f, p1 z %.2f" % [_rmax, _d0, p1.global_position.z])
						return
					_ok("grapple 3D: reeled to the anchor at z %.2f (closest %.2f m), p1 now at z %.2f" % [_d0, _rmax, p1.global_position.z])
					_next()
				if _f > _f0 + 200:
					_fail("grapple 3D never attached/released (state %d, attached %s)" % [p1.state, _x0 > 0.0])
		49:
			# 0.3-3: pull the enemy along the gaze when they stand off the X line
			if not (p1.is_actionable() and p2.is_actionable()) and _f < _f0 + 200:
				return
			if _n0 != 49:
				_n0 = 49
				p1.global_position = Vector3(0.0, p1.global_position.y, 0.0)
				p2.global_position = Vector3(3.0, p2.global_position.y, 3.0)
				_f0 = _f
				return
			if _f == _f0 + 3:
				InputRouter.v_set(1, "crouch", true)
				InputRouter.v_press(1, "grapple")
			if _f == _f0 + 60:
				var want := p1.global_position + p1.forward * 1.25
				var miss := _flat(p2.global_position - want).length()
				var z_moved := absf(p2.global_position.z - 3.0)
				if p1.stats.grapples < 1 or miss > 0.6 or z_moved < 1.0:
					_fail("grapple pull 3D: grapples %d, P2 %.2f m from 1.25 m in front of P1 (want ≤ 0.6), z moved %.2f" % [p1.stats.grapples, miss, z_moved])
					return
				_ok("grapple pull 3D: P2 from (3, 3) to %.2f m off the spot 1.25 m in front of P1 (z moved %.2f)" % [miss, z_moved])
				_n0 = 0
				_next()
		50:
			# Ares numbers: guard arc ±block_arc_deg; side/back hits get +backhit_hitstun_bonus
			if not (p1.is_actionable() and p2.is_actionable()) and _f < _f0 + 300:
				return
			# fixed angles from the plan (T1 answer, item 4): 65° is blocked, 75° goes through (Ares: ±70°)
			var arc: float = GDD_BLOCK_ARC_DEG
			var res := []
			for deg in [65.0, 75.0]:
				_place(p2, p1, 2.0, 0.0)
				var to := _flat(p1.global_position - p2.global_position).normalized()
				p2.forward = to.rotated(Vector3.UP, deg_to_rad(deg))
				res.append(p2._guards_against(p1))
			if res[0] != true or res[1] != false:
				_fail("block arc ±%.0f°: guards at 65° %s, at 75° %s (want true, false)" % [arc, res[0], res[1]])
				return
			var lm: MoveData = p1.data.light
			_place(p2, p1, 1.5, 0.0)
			p2.forward = _flat(p2.global_position - p1.global_position).normalized()   # back to the attacker
			p2.receive_hit(p1, lm)
			var back := p2.stun_frames
			if back != lm.hitstun + int(GDD_MOVES["light"][1]):
				_fail("backhit: stun %d, want %d + %d" % [back, lm.hitstun, lm.backhit_hitstun_bonus])
				return
			# soft wall: past the circle, the outward part of the velocity goes, the tangential part stays
			var n := Vector3(cos(0.7), 0.0, sin(0.7))
			var t := Vector3.UP.cross(n)
			p1.global_position = n * (GDD_ARENA_RADIUS + 0.2) + Vector3(0.0, p1.global_position.y, 0.0)
			p1.velocity = n * 5.0 + t * 3.0
			p1._soft_wall()
			var out := p1.velocity.dot(n)
			var tan := p1.velocity.dot(t)
			var rad := _flat(p1.global_position).length()
			if absf(out) > 0.001 or absf(tan - 3.0) > 0.001 or absf(rad - GDD_ARENA_RADIUS) > 0.001:
				_fail("soft wall: outward %.3f (want 0), tangential %.3f (want 3), radius %.3f" % [out, tan, rad])
				return
			p1.velocity = Vector3.ZERO
			p1.global_position = Vector3(-2.0, p1.global_position.y, 0.0)
			_ok("block arc ±%.0f°: attacker at 65° blocked, at 75° not; back hit stun %d = hitstun %d + %d; soft wall keeps tangential 3.0 m/s, outward → 0" % [arc, back, lm.hitstun, lm.backhit_hitstun_bonus])
			_next()
		51:
			# TIME STOP is a circle in 3D: P2 off the X line inside it freezes; at |dx| = 1 but 5 m deep it does not
			if (_n0 == 0 or _n0 == 2) and not (p1.is_actionable() and p2.is_actionable()):
				if _f > _f0 + 400:
					_fail("time stop 3D: never ready (p1 %d, p2 %d, cd %.1f)" % [p1.state, p2.state, p1.cooldowns.skill2])
				return
			if _n0 == 0:
				p1.cooldowns.skill2 = 0.0
				_n0 = 1
				p1.global_position = Vector3(0.0, p1.global_position.y, 0.0)
				p2.global_position = Vector3(1.0, p2.global_position.y, 5.0)   # |dx| 1 ≤ 4.2, distance 5.1 > 4.2
				InputRouter.v_press(1, "skill2")
				_f0 = _f
				return
			if _n0 == 1 and _f == _f0 + 20:
				if p2.frozen_frames > 0:
					_fail("time stop 3D: froze P2 5.1 m away (only |dx| = 1)")
					return
				_n0 = 2
				p1.cooldowns.skill2 = 0.0
			if _n0 == 2 and p1.is_actionable() and p2.is_actionable():
				p1.cooldowns.skill2 = 0.0
				_n0 = 3
				_place(p2, p1, 3.0, 50.0)
				InputRouter.v_press(1, "skill2")
				_f0 = _f
			if _n0 == 3 and _f == _f0 + 20:
				if p2.frozen_frames <= 0:
					_fail("time stop 3D: P2 3 m away at 50° not frozen (p1 state %d move %s cd %.1f, dist %.2f, p2 state %d inv %d)" % [p1.state, p1.current_move.id if p1.current_move else "-", p1.cooldowns.skill2, _flat(p2.global_position - p1.global_position).length(), p2.state, p2.invulnerable_frames])
					return
				_ok("TIME STOP 3D: P2 3 m away at 50° frozen; P2 at |dx| 1 but 5.1 m away untouched")
				_n0 = 0
				_next()
		52:
			# SWORD STORM: a 5.4 × 1.2 m band along the gaze. P2 at 40° off the X axis is hit; moved 2 m
			# to the side of the band after the first tick, the rest of the storm misses
			if _n0 == 0:
				if p2.frozen_frames > 0 or not (p1.is_actionable() and p2.is_actionable()):
					if _f > _f0 + 400:
						_fail("sword storm 3D: never ready")
					return
				_n0 = 1
				p2.hp = p2.data.max_hp
				p1.meter = Fighter.MAX_METER
				_place(p2, p1, 3.0, 40.0)
				_hp0 = p2.hp
				_rotated = false
				InputRouter.v_press(1, "ultimate")
				_f0 = _f
				return
			if not _rotated and p2.hp < _hp0:
				_rotated = true
				var fwd := p1.forward
				var side := Vector3.UP.cross(fwd)
				p2.global_position = p1.global_position + fwd * 3.0 + side * 2.0 + Vector3(0.0, p2.global_position.y - p1.global_position.y, 0.0)
				_x0 = p2.hp
			if _rotated and _f == _f0 + 110:
				if p2.hp != _x0:
					_fail("sword storm 3D: hit P2 2 m beside the band (hp %.0f → %.0f)" % [_x0, p2.hp])
					return
				_ok("SWORD STORM 3D: band along the gaze hit P2 at 40° (hp %.0f → %.0f); 2 m beside the band — no more hits" % [_hp0, _x0])
				_n0 = 0
				_next()
			elif _f > _f0 + 120:
				_fail("sword storm 3D: P2 at 40° never hit (hp %.0f)" % p2.hp)
		53:
			# KUNAI RAIN lands on P1's spot (off the X line) at the throw
			if _n0 == 0:
				if not (p1.is_actionable() and p2.is_actionable()) or p2.cooldowns.skill1 > 0.0:
					if _f > _f0 + 600:
						_fail("kunai 3D: never ready (p1 %d, p2 %d)" % [p1.state, p2.state])
					return
				_n0 = 1
				p1.hp = p1.data.max_hp
				p1.armor_break_frames = 0
				_place(p1, p2, 4.0, -60.0)
				_hp0 = p1.hp
				InputRouter.v_press(2, "skill1")
				_f0 = _f
				return
			if _f == _f0 + 80:
				if p1.hp >= _hp0 or p1.armor_break_frames <= 0:
					_fail("kunai 3D: P1 4 m away at -60° not hit (hp %.0f, armor %d)" % [p1.hp, p1.armor_break_frames])
					return
				_ok("KUNAI RAIN 3D: P1 4 m away at -60° hit (hp %.0f → %.0f), armor break %d f" % [_hp0, p1.hp, p1.armor_break_frames])
				_n0 = 0
				_next()
		54:
			# CURSED GRIMOIRE is a circle: P1 at |dx| 1 but 5 m deep is untouched; P1 2.5 m away at 60° is hit
			if _n0 == 0 or _n0 == 2:
				if not (p1.is_actionable() and p2.is_actionable()):
					if _f > _f0 + 600:
						_fail("grimoire 3D: never ready (p1 %d, p2 %d)" % [p1.state, p2.state])
					return
				p1.hp = p1.data.max_hp
				p2.meter = Fighter.MAX_METER
				if _n0 == 0:
					p2.global_position = Vector3(0.0, p2.global_position.y, 0.0)
					p1.global_position = Vector3(1.0, p1.global_position.y, 5.0)
				else:
					_place(p1, p2, 2.5, 60.0)
				_hp0 = p1.hp
				_x0 = float(p1.stats.ragdolls)
				InputRouter.v_press(2, "ultimate")
				_n0 += 1
				_f0 = _f
				return
			if _n0 == 1 and _f == _f0 + 100:
				if p1.hp < _hp0:
					_fail("grimoire 3D: hit P1 5.1 m away (|dx| 1): hp %.0f → %.0f" % [_hp0, p1.hp])
					return
				_n0 = 2
				_f0 = _f
			if _n0 == 3 and _f == _f0 + 100:
				if p1.hp >= _hp0 or float(p1.stats.ragdolls) <= _x0:
					_fail("grimoire 3D: P1 2.5 m away at 60° not hit (hp %.0f, ragdolls %d)" % [p1.hp, p1.stats.ragdolls])
					return
				_ok("CURSED GRIMOIRE 3D: P1 2.5 m away at 60° hit and ragdolled (hp %.0f → %.0f); at |dx| 1 but 5.1 m away untouched" % [_hp0, p1.hp])
				_n0 = 0
				_next()
		55:
			# FLASH STEP goes through the opponent along the line; a sideways stick turns the exit by 45°
			if _n0 == 0 or _n0 == 2:
				if not (p1.is_actionable() and p2.is_actionable()) or p2.dash_charges_left <= 0:
					if _f > _f0 + 900:
						_fail("flash 3D: never ready (p1 %d, p2 %d, charges %d)" % [p1.state, p2.state, p2.dash_charges_left])
					return
				_place(p2, p1, 1.5, 135.0)
				_v0 = p2.global_position
				if _n0 == 2:
					InputRouter.v_set(2, "up", true)
				InputRouter.v_press(2, "dash")
				_n0 += 1
				_f0 = _f
				return
			if (_n0 == 1 or _n0 == 3) and _f == _f0 + 8:
				InputRouter.v_clear(2)
				var line := _flat(p1.global_position - _v0).normalized()
				var went := _flat(p2.global_position - _v0)
				var ang := rad_to_deg(line.angle_to(went.normalized()))
				if _n0 == 1:
					var through := _flat(p2.global_position - p1.global_position).dot(_flat(_v0 - p1.global_position)) < 0.0
					if not through or ang > 1.0:
						_fail("flash 3D: neutral flash from 135° — through %s, %.1f° off the line" % [through, ang])
						return
					_ok("FLASH STEP 3D: from 135° straight through P2's line (%.1f° off), %.2f m travelled" % [ang, went.length()])
					_n0 = 2
				else:
					if absf(ang - Fighter.FLASH_SIDE_DEG) > 1.0:
						_fail("flash 3D: sideways stick turned the exit %.1f° (want %.0f°)" % [ang, Fighter.FLASH_SIDE_DEG])
						return
					_ok("FLASH STEP 3D: sideways stick turned the exit %.1f° off the line (rule %.0f°)" % [ang, Fighter.FLASH_SIDE_DEG])
					_n0 = 0
					_next()
		56:
			# 0.3-4: a CPU P2 in 3D circles at least once and lands at least one hit within 10 s (600 f)
			if _n0 == 0:
				if not (p1.is_actionable() and p2.is_actionable()):
					if _f > _f0 + 600:
						_fail("cpu 3D: fighters never ready")
					return
				_n0 = 1
				p1.hp = p1.data.max_hp
				p2.hp = p2.data.max_hp
				p1.global_position = Vector3(-2.5, p1.global_position.y, 0.0)
				p2.global_position = Vector3(2.5, p2.global_position.y, 0.0)
				var b := CpuBrain.new()
				b.fighter = p2
				p2.add_child(b)
				p2._brain = b
				_x0 = float(p2.stats.hits)
				_ang0 = _bearing(p2, p1)
				_swept = 0.0
				_rmax = 0.0
				_f0 = _f
				return
			var a := _bearing(p2, p1)
			var da := angle_difference(_ang0, a)
			_ang0 = a
			if absf(da) < deg_to_rad(30.0):   # passing through / over the opponent flips the bearing — not circling
				_swept += da
			_rmax = maxf(_rmax, absf(_swept))
			if _f == _f0 + 600:
				var b: CpuBrain = p2._brain
				var hits := float(p2.stats.hits) - _x0
				var steps := b.sidesteps
				b.queue_free()
				p2._brain = null
				InputRouter.v_clear(2)
				if steps < 1 or rad_to_deg(_rmax) < 20.0 or hits < 1.0:
					_fail("cpu 3D in 10 s: sidesteps %d, swept around P1 %.0f° (want ≥ 20), hits %.0f (want ≥ 1)" % [steps, rad_to_deg(_rmax), hits])
					return
				_ok("CPU 3D in 10 s: %d sidesteps, swept %.0f° around P1, %.0f hits landed" % [steps, rad_to_deg(_rmax), hits])
				_load_arena(0, 60)   # 0.3-5: river in free movement
		# ---------------- 0.3-5: river in free movement (two runs, same input → same hash) ----------
		60:
			if flow.phase == MatchFlow.Phase.FIGHT and GameState.water != null and p1.is_actionable() and p2.is_actionable():
				if not GameState.water.use_z:
					_fail("river 3D: WaveField.use_z is off under free_move")
					return
				_river_min_gap = 99.0
				_zdiff = 0.0
				_zmax = 0.0
				_f0 = _f
				_next()
			elif _f > _f0 + 600:
				_fail("river 3D: fight never started")
		61:
			var t := _f - _f0
			_river3d_script(t)
			var w := GameState.water
			for f: Fighter in [p1, p2]:
				var fx := f.global_position.x
				var fz := f.global_position.z
				var gap := f.global_position.y - w.height(fx, fz)
				_river_min_gap = minf(_river_min_gap, gap)
				_zmax = maxf(_zmax, absf(fz))
				_zdiff = maxf(_zdiff, absf(w.height(fx, fz) - w.height(fx, 0.0)))
				if gap < -0.05:
					_fail("river 3D: P%d sank (y %.3f, surface %.3f at x %.2f z %.2f, frame %d, state %d)" % [f.player_index, f.global_position.y, f.global_position.y - gap, fx, fz, t, f.state])
					return
			if t == 600:
				var h := _river3d_hash()
				_river3d_runs.append(h)
				_ok("river 3D run %d: nobody sank in 600 frames (min gap %.3f m), |z| up to %.2f m, surface differs from z=0 by up to %.3f m; hash %d" % [_river3d_runs.size(), _river_min_gap, _zmax, _zdiff, h])
				if _zmax < 1.0 or _zdiff < 0.01:
					_fail("river 3D: the run never tested depth (|z| max %.2f m, height(x,z) − height(x,0) max %.3f m)" % [_zmax, _zdiff])
					return
				if _river3d_runs.size() == 1:
					_load_arena(0, 60)
				elif _river3d_runs[0] != _river3d_runs[1]:
					_fail("river 3D: two runs differ at frame 600 (hash %d vs %d)" % [_river3d_runs[0], _river3d_runs[1]])
				else:
					_ok("river 3D: deterministic — both runs hash %d at frame 600" % h)
					GameState.set_free_move(false)
					_duel_runs.clear()
					_load_arena(2, 70)   # 0.3-6: full duel replay, plane first
		# ---------------- 0.3-6: same input twice → same hash, in both modes ----------------------
		70:
			if flow.phase == MatchFlow.Phase.FIGHT and p1.is_actionable() and p2.is_actionable():
				_duel_trace = []
				_f0 = _f
				_next()
			elif _f > _f0 + 600:
				_fail("duel replay: fight never started")
		71:
			var t := _f - _f0
			_duel_script(t)
			if t % 30 == 0:
				_duel_trace.append(_duel_state())
			if t == DUEL_FRAMES:
				var mode := "free" if GameState.free_move else "plane"
				var h := ";".join(_duel_trace).hash()
				_duel_runs.append(h)
				var used := "hits %d/%d, ragdolls %d/%d, grapples %d/%d, hp %.0f/%.0f" % [p1.stats.hits, p2.stats.hits, p1.stats.ragdolls, p2.stats.ragdolls, p1.stats.grapples, p2.stats.grapples, p1.hp, p2.hp]
				_ok("duel replay %s run %d: %d frames, hash %d (%s)" % [mode, _duel_runs.size() % 2 if _duel_runs.size() % 2 == 1 else 2, DUEL_FRAMES, h, used])
				if p1.state == Fighter.State.LAUNCHED or p2.state == Fighter.State.LAUNCHED:
					_fail("duel replay %s: a fighter is still in the ragdoll at the end — its outcome is not in the hash" % mode)
					return
				if p1.stats.hits + p2.stats.hits < 3 or p1.stats.ragdolls + p2.stats.ragdolls < 1:
					_fail("duel replay %s: the script did not exercise combat (%s)" % [mode, used])
					return
				if _duel_runs.size() % 2 == 1:
					_duel_first_trace = _duel_trace.duplicate()
					_load_arena(2, 70)
					return
				if _duel_runs[-1] != _duel_runs[-2]:
					var at := 0
					while at < _duel_trace.size() and _duel_trace[at] == _duel_first_trace[at]:
						at += 1
					_fail("duel replay %s: runs differ, first at frame %d:\n  %s\n  %s" % [mode, at * 30, _duel_first_trace[at], _duel_trace[at]])
					return
				_ok("duel replay %s: deterministic — same input twice, same hash %d (%d checkpoints)" % [mode, h, _duel_trace.size()])
				if not GameState.free_move:
					GameState.set_free_move(true)
					_load_arena(2, 70)
				else:
					_splat_phase = 0
					_next_to(80)
		# ---------------- Launch 3: Choko's passive Printer (03 § Пасивка Choko — Printer) ---------
		# numbers are the GDD literals (8 s, 15 s, 1.5 m, 8 s, max 1, +30 HP, 4 s, 6 s), not the code's constants
		90:
			if flow.phase == MatchFlow.Phase.FIGHT and p1.printer != null and not p1.control_locked:
				_prints.clear()
				p1.printer.printed.connect(func(kind: String, at: Vector3) -> void:
					_prints.append({"kind": kind, "at": at, "t": p1.printer.fight_frames, "from": p1.global_position, "fwd": p1.forward}))
				p1.printer.picked.connect(func(kind: String) -> void:
					_picks_p = {"kind": kind, "spring": p1.spring_frames, "revealed": p2.revealed_frames, "hp": p1.hp})
				_x0 = p1.hp
				_next()
			elif _f > _f0 + 600:
				_fail("printer: Choko has no Printer (passive_id %s) or the fight never started" % p1.data.passive_id)
		91:
			if _prints.size() >= 1:
				var pr: Dictionary = _prints[0]
				var off: Vector3 = pr.at - pr.from
				var flat := Vector2(off.x, off.z).length()
				var behind: float = Vector3(off.x, 0.0, off.z).dot(pr.fwd)
				if pr.kind != "patch" or pr.t != 8 * 60 or absf(flat - 1.5) > 0.05 or behind > -1.45:
					_fail("printer first sticker: %s at fight frame %d (want patch at 480), %.2f m from Choko (want 1.5), along the gaze %.2f (want -1.5)" % [pr.kind, pr.t, flat, behind])
					return
				_ok("printer: first sticker (patch) at 8.0 s, %.2f m straight behind Choko" % flat)
				_next()
			elif p1.printer.fight_frames > 8 * 60 + 5:
				_fail("printer: nothing printed by 8 s (fight frame %d)" % p1.printer.fight_frames)
		92:
			if p1.printer.sticker_kind == "":
				var t: int = p1.printer.fight_frames
				if p1.printer.stats.crumbled != 1 or t != 8 * 60 + 8 * 60 or p1.hp != _x0:
					_fail("printer: sticker gone at fight frame %d (want 960 = lived 8 s), crumbled %d, hp %.0f → %.0f (want unchanged)" % [t, p1.printer.stats.crumbled, _x0, p1.hp])
					return
				_ok("printer: an untouched sticker lives 8 s and crumbles with no effect")
				_next()
		93:
			if _prints.size() >= 2 and p1.printer.sticker_kind != "":
				var pr: Dictionary = _prints[1]
				if pr.kind != "seen" or pr.t != 8 * 60 + 15 * 60:
					_fail("printer second sticker: %s at fight frame %d (want seen at 1380 = 8 s + 15 s)" % [pr.kind, pr.t])
					return
				var at: Vector3 = p1.printer.sticker_position()
				p2.global_position = Vector3(at.x, p2.global_position.y, at.z)   # the opponent steps on it
				_n0 = p1.printer.stats.torn
				_next()
			elif p1.printer.fight_frames > 8 * 60 + 15 * 60 + 5:
				_fail("printer: no second sticker by 23 s (prints %d)" % _prints.size())
		94:
			if _f == _f0 + 3:
				if p1.printer.stats.torn != _n0 + 1 or p1.printer.sticker_kind != "" or p2.revealed_frames != 0 or p1.printer.stats.picked != 0:
					_fail("printer: opponent on the sticker → torn %d (want +1), sticker %s, p2 revealed %d (want 0), picked %d (want 0)" % [p1.printer.stats.torn - _n0, p1.printer.sticker_kind, p2.revealed_frames, p1.printer.stats.picked])
					return
				_ok("printer: second sticker (seen) at 23.0 s; the opponent stepping on it tears it — no effect for anyone")
				# Spring: pick, then one extra jump in the air, and only one
				p1.printer.print_now()
				if p1.printer.sticker_kind != "spring":
					_fail("printer queue: third sticker %s (want spring)" % p1.printer.sticker_kind)
					return
				var at: Vector3 = p1.printer.sticker_position()
				p1.global_position = Vector3(at.x, p1.global_position.y, at.z)
			if _f == _f0 + 6:
				if _picks_p.get("kind") != "spring" or _picks_p.get("spring") != 6 * 60:
					_fail("printer spring: picked %s → spring %s frames at pickup (want spring, 360)" % [_picks_p.get("kind"), _picks_p.get("spring")])
					return
				InputRouter.v_press(1, "jump")
			if _f == _f0 + 22:
				_y0 = p1.velocity.y
				InputRouter.v_press(1, "jump")
			if _f == _f0 + 24:
				if p1.on_ground() or p1.spring_frames != 0 or p1.velocity.y < p1.data.jump_velocity - 1.0 or _y0 > p1.data.jump_velocity - 3.0:
					_fail("printer spring: second jump in the air — vy before %.1f, after %.1f (want ≈ %.1f), spring left %d (want 0)" % [_y0, p1.velocity.y, p1.data.jump_velocity, p1.spring_frames])
					return
			if _f == _f0 + 38:
				_y0 = p1.velocity.y
				InputRouter.v_press(1, "jump")
			if _f == _f0 + 40:
				if p1.velocity.y > _y0:
					_fail("printer spring: a third jump in the air worked (vy %.1f → %.1f) — Spring is one use" % [_y0, p1.velocity.y])
					return
				_ok("printer: third sticker (spring) picked → 6 s window, one extra air jump, the next one does nothing")
				_next()
		95:
			if p1.is_actionable() and p1.on_ground() and _f > _f0 + 10:
				# fourth = patch; at most one on the floor: a second print is skipped and the queue waits
				p1.printer.print_now()
				var qi: int = p1.printer.queue_index
				var sk: int = p1.printer.stats.skipped
				var again := p1.printer.print_now()
				if p1.printer.sticker_kind != "patch" or again or p1.printer.queue_index != qi or p1.printer.stats.skipped != sk + 1:
					_fail("printer max 1: sticker %s (want patch), second print %s (want false), queue %d → %d (want same)" % [p1.printer.sticker_kind, again, qi, p1.printer.queue_index])
					return
				p1.hp = p1.data.max_hp - 100.0
				var at: Vector3 = p1.printer.sticker_position()
				p1.global_position = Vector3(at.x, p1.global_position.y, at.z)
				_next()
		96:
			if _f == _f0 + 3:
				if absf(p1.hp - (p1.data.max_hp - 70.0)) > 0.01:
					_fail("printer patch: hp %.1f (want max − 100 + 30 = %.1f)" % [p1.hp, p1.data.max_hp - 70.0])
					return
				_ok("printer: max one sticker on the floor (second print skipped, queue waits); patch heals +30")
				p1.printer.print_now()   # fifth = seen, picked by Choko this time
				var at: Vector3 = p1.printer.sticker_position()
				p1.global_position = Vector3(at.x, p1.global_position.y, at.z)
			if _f == _f0 + 6:
				if _picks_p.get("kind") != "seen" or _picks_p.get("revealed") != 4 * 60:
					_fail("printer seen: picked %s → Skea revealed %s frames at pickup (want seen, 240)" % [_picks_p.get("kind"), _picks_p.get("revealed")])
					return
				p2.begin_veil()
			if _f == _f0 + 9:
				if p2.veil_frames <= 0 or not p2.animator.visible:
					_fail("printer seen: Skea under Shadow Veil while seen — veil %d f, visible %s (want visible)" % [p2.veil_frames, p2.animator.visible])
					return
				p2.revealed_frames = 0
			if _f == _f0 + 12:
				if p2.animator.visible:
					_fail("printer seen: with «seen» over, Skea under the veil is still visible")
					return
				p2.end_veil()
				_ok("printer: seen → Skea shows through Shadow Veil for 4 s, and hides again when it ends")
				_next()
		97:
			if p1.is_actionable() and p1.on_ground() and _f > _f0 + 10:
				p1.printer.print_now()   # sixth = spring: a hit in the air spends it
				var at: Vector3 = p1.printer.sticker_position()
				p1.global_position = Vector3(at.x, p1.global_position.y, at.z)
				_next()
		98:
			if _f == _f0 + 3:
				_place(p2, p1, 1.2, 0.0)
				InputRouter.v_press(1, "jump")
			if _f == _f0 + 5:
				InputRouter.v_press(1, "light")   # early in the jump, so the dive kick meets Skea's body
			if _f > _f0 + 5 and p2.state == Fighter.State.HITSTUN and not p1.on_ground():
				if p1.spring_frames != 0:
					_fail("printer spring: an air hit on Skea left the Spring (%d frames) — it must not extend a juggle" % p1.spring_frames)
					return
				_ok("printer: an air hit with Spring active spends it (no juggle extension)")
				_next()
			elif _f > _f0 + 60:
				_fail("printer spring burn: the air attack never hit (p1 state %d, p2 state %d)" % [p1.state, p2.state])
		99:
			if p1.is_actionable() and p1.on_ground() and _f > _f0 + 10:
				p1.printer.print_now()   # seventh = patch at almost full HP: capped at max
				p1.hp = p1.data.max_hp - 10.0
				var at: Vector3 = p1.printer.sticker_position()
				p1.global_position = Vector3(at.x, p1.global_position.y, at.z)
				_next()
		100:
			if _f == _f0 + 3:
				if p1.hp != p1.data.max_hp or p1.printer.queue_index != 7:
					_fail("printer patch cap: hp %.1f (want max %.1f), queue %d (want 7)" % [p1.hp, p1.data.max_hp, p1.printer.queue_index])
					return
				_ok("printer: patch never heals above max HP; queue patch → seen → spring repeats (7 prints)")
				_next()
		101:
			# Spring's other use: one air dash (Choko's Chrono Step in the air); pickup itself is tested above
			if _f == _f0 + 10 and p1.is_actionable():
				p1.spring_frames = 6 * 60
				InputRouter.v_press(1, "jump")
			if _f == _f0 + 18:
				InputRouter.v_press(1, "dash")
			if _f == _f0 + 20:
				if p1.state != Fighter.State.DASH or p1.on_ground() or p1.spring_frames != 0:
					_fail("printer spring air dash: state %d (want DASH), on ground %s, spring %d (want 0)" % [p1.state, p1.on_ground(), p1.spring_frames])
					return
			if _f == _f0 + 20 + p1.data.dash_frames + 2:
				if p1.state != Fighter.State.JUMP and not p1.on_ground():
					_fail("printer spring air dash ended in state %d in the air (want JUMP)" % p1.state)
					return
				InputRouter.v_press(1, "dash")
			if _f == _f0 + 20 + p1.data.dash_frames + 4:
				if p1.state == Fighter.State.DASH and not p1.on_ground():
					_fail("printer spring: a second air dash worked — Spring is one use")
					return
				_ok("printer: Spring also gives one air dash (ends falling), and only one")
				_start_rig_stages()
		# ---------------- launch 4 (C1): UAL mannequin, GameState.skeletal_rig -------------------------
		110:
			if flow.phase == MatchFlow.Phase.FIGHT and p1.is_actionable() and p2.is_actionable() and _f > _f0 + 10:
				var sk: SkeletalRig = p1.skeletal
				if sk == null or sk.skeleton == null or p2.skeletal == null:
					_fail("skeletal_rig on but the fighters have no SkeletalRig (p1 %s, p2 %s)" % [p1.skeletal, p2.skeletal])
					return
				var drawn := 0
				for m in p1.animator.find_children("*", "MeshInstance3D", true, false):
					drawn += int((m as MeshInstance3D).visible)
				if drawn != 0 or not sk.visible or p1.animator.parts.is_empty():
					_fail("mannequin: %d capsule meshes still drawn, mannequin visible %s, capsule parts %d (want 0, true, > 0)" % [drawn, sk.visible, p1.animator.parts.size()])
					return
				if sk.clip != sk.clip_name(p1.data.idle_clip) or sk.clip == "":
					_fail("mannequin idle: clip '%s', want '%s' (%s)" % [sk.clip, sk.clip_name(p1.data.idle_clip), p1.data.idle_clip])
					return
				var ok_names := 0
				for k in SkeletalRig.STATE_CLIPS:
					ok_names += int(sk.clip_name(SkeletalRig.STATE_CLIPS[k]) != "")
				if ok_names != SkeletalRig.STATE_CLIPS.size() or sk.clip_name("No_Such_Clip") != "":
					_fail("mannequin: %d of %d state clips found in UAL1+UAL2" % [ok_names, SkeletalRig.STATE_CLIPS.size()])
					return
				# attack_clip_time: contact pose on the first active frame, clip end at the end of its span
				var at := [SkeletalRig.attack_clip_time(0, 8, 11, 1.0, 0.25), SkeletalRig.attack_clip_time(8, 8, 11, 1.0, 0.25),
					SkeletalRig.attack_clip_time(11, 8, 11, 1.0, 0.25), SkeletalRig.attack_clip_time(10, 8, 20, 1.0, 0.0)]
				if absf(at[0]) > 1e-6 or absf(at[1] - 0.25) > 1e-6 or absf(at[2] - 1.0) > 1e-6 or absf(at[3] - 0.5) > 1e-6:
					_fail("attack_clip_time: frame 0 → %.3f, first active → %.3f, span end → %.3f, unmeasured half span → %.3f (want 0, 0.25, 1, 0.5)" % at)
					return
				# every clip the .tres files name exists in UAL1+UAL2 (GDD 02 § Кліп → удар, table 4a)
				for fx in [p1, p2]:
					var names: Array = [fx.data.idle_clip, fx.data.dash_clip, fx.data.getup_clip]
					for mv in [fx.data.light, fx.data.heavy, fx.data.crouch_light, fx.data.air_light, fx.data.skill1, fx.data.skill2, fx.data.ultimate, fx.data.throw_move]:
						if mv == null:
							continue
						for n in [mv.anim_clip, mv.anim_clip_rec, mv.anim_clip_chain, mv.anim_clip_chain_rec]:
							if n != "":
								names.append(n)
						for ct in [[mv.anim_clip, mv.contact_time], [mv.anim_clip_chain, mv.contact_time_chain]]:
							if ct[0] != "" and ct[1] > 0.0 and sk.clip_name(ct[0]) != "" and ct[1] >= sk.player.get_animation(sk.clip_name(ct[0])).length:
								_fail("%s %s: contact_time %.3f past the end of '%s'" % [fx.data.id, mv.id, ct[1], ct[0]])
								return
					for n in names:
						if sk.clip_name(n) == "":
							_fail("%s: clip '%s' from the .tres is not in UAL1/UAL2" % [fx.data.id, n])
							return
				_bone0 = sk.skeleton.get_bone_pose_rotation(sk.skeleton.find_bone("spine_02")).get_euler()
				_ok("mannequin: UAL1+UAL2 on one player (%d state clips), capsules hidden but ticking, idle '%s'" % [ok_names, sk.clip])
				_next()
			elif _f > _f0 + 400:
				_fail("mannequin round never started")
		111:
			var sk: SkeletalRig = p1.skeletal
			if _f == _f0 + 40:
				var b: Vector3 = sk.skeleton.get_bone_pose_rotation(sk.skeleton.find_bone("spine_02")).get_euler()
				if b.distance_to(_bone0) < 1e-4:
					_fail("mannequin idle is frozen: spine_02 unchanged over 40 frames (clip '%s' at %.2f s)" % [sk.clip, sk.clip_pos])
					return
				_ok("mannequin idle animates (spine_02 moved %.4f rad in 40 frames)" % b.distance_to(_bone0))
				# Skea right in front, so the light connects: contact pose, then the hit sound on the hit frame
				p2.global_position = p1.global_position + p1.forward * 1.0
				_rig_hit = -1
				_rig_swung = false
				if not p2.hit_landed.is_connected(_on_rig_hit):
					p2.hit_landed.connect(_on_rig_hit)
				InputRouter.v_press(1, "light")
			if _f > _f0 + 40 and p1.state == Fighter.State.ATTACK and p1.current_move != null:
				var m := p1.current_move
				if p1.move_frame == m.startup:
					if m.anim_clip == "" or sk.clip != sk.clip_name(m.anim_clip) or absf(sk.clip_pos - m.contact_time) > 1.0 / 60.0:
						_fail("mannequin attack: first active frame plays '%s' at %.3f s, want '%s' at contact %.3f s ±1 frame" % [sk.clip, sk.clip_pos, m.anim_clip, m.contact_time])
						return
					_x0 = sk.clip_pos
					_rig_swung = true
				if p1.move_frame == m.startup + m.active + 1 and m.anim_clip_rec != "":
					if sk.clip != sk.clip_name(m.anim_clip_rec):
						_fail("mannequin attack recovery plays '%s', want '%s'" % [sk.clip, m.anim_clip_rec])
						return
			if _rig_swung and p1.state != Fighter.State.ATTACK:
				var hit_sfx := p1.data.light.sfx_hit
				if _rig_hit < 0:
					_fail("mannequin attack: the light never hit Skea standing 1 m in front")
					return
				if int(Sfx.last_frame.get(hit_sfx, -1)) != _rig_hit:
					_fail("mannequin hit sound: '%s' last played on frame %d, the hit landed on %d" % [hit_sfx, Sfx.last_frame.get(hit_sfx, -1), _rig_hit])
					return
				_ok("mannequin attack: '%s' contact pose (%.2f s) on the first active frame %d, then '%s'; hit sound on the hit frame %d" % [p1.data.light.anim_clip, _x0, p1.data.light.startup, p1.data.light.anim_clip_rec, _rig_hit])
				_next()
			elif _f > _f0 + 200:
				_fail("mannequin attack never reached its first active frame (state %d)" % p1.state)
		112:
			# hit reactions on Skea by zone, then the ragdoll hides the mannequin with the capsule rig
			var s2: SkeletalRig = p2.skeletal
			if _f == _f0 + 30:
				p2.hitstop_frames = 0
				p2.animator.flinch_zone = "high"
				p2.stun_frames = 20
				p2._set_state(Fighter.State.HITSTUN)
			if _f == _f0 + 31:
				var high := s2.clip
				if high != s2.clip_name(SkeletalRig.STATE_CLIPS["hit_high"]):
					_fail("mannequin hit high: clip '%s', want '%s'" % [high, SkeletalRig.STATE_CLIPS["hit_high"]])
					return
				p2.animator.flinch_zone = "mid"
				p2.stun_frames = 20
			if _f == _f0 + 32:
				if s2.clip != s2.clip_name(SkeletalRig.STATE_CLIPS["hit_mid"]):
					_fail("mannequin hit mid: clip '%s', want '%s'" % [s2.clip, SkeletalRig.STATE_CLIPS["hit_mid"]])
					return
				p2.animator.flinch_zone = "low"
				p2.stun_frames = 20
			if _f == _f0 + 33:
				var three := {}
				for z in ["high", "mid", "low"]:
					three[s2.clip_name(SkeletalRig.STATE_CLIPS["hit_" + z])] = true
				if s2.clip != s2.clip_name(SkeletalRig.STATE_CLIPS["hit_low"]) or three.size() != 3:
					_fail("mannequin hit low: clip '%s', want '%s'; %d different reactions (want 3)" % [s2.clip, SkeletalRig.STATE_CLIPS["hit_low"], three.size()])
					return
				p2._enter_ragdoll(Vector3(4.0, 3.0, 0.0))
			if _f == _f0 + 35:
				if s2.visible or p2.animator.visible:
					_fail("mannequin during ragdoll: visible %s (capsule rig visible %s) — want both hidden" % [s2.visible, p2.animator.visible])
					return
				_ok("mannequin reactions: head '%s', chest '%s', stomach '%s' — three different; hidden while the capsule ragdoll flies" % [s2.clip_name(SkeletalRig.STATE_CLIPS["hit_high"]), s2.clip_name(SkeletalRig.STATE_CLIPS["hit_mid"]), s2.clip_name(SkeletalRig.STATE_CLIPS["hit_low"])])
				_finish()
		# ---------------- wall splat (02 § Коло арени: 10 f, no damage, once per combo) -----------
		80:
			# phase 0: first combo → splat; phase 1: next combo → splat again, then a second launch in that
			# same combo must not splat
			if p1.is_actionable() and p2.is_actionable() and _f > _f0 + 20:
				InputRouter.v_clear(1)
				InputRouter.v_clear(2)
				var n := Vector3(1.0, 0.0, 0.0)
				p2.global_position = n * (12.5 - 1.0)
				p1.global_position = n * (12.5 - 4.0)
				p2.hp = p2.data.max_hp
				_x0 = p2.hp
				_n0 = int(p2.stats.get("splats", 0))
				_run = 0
				p2._enter_ragdoll(Vector3(16.0, 4.0, 0.0))
				_next()
			elif _f > _f0 + 600:
				_fail("wall splat: fighters never actionable (p1 %d, p2 %d)" % [p1.state, p2.state])
		81:
			if p2.state == Fighter.State.WALL_SPLAT:
				_run += 1
				if _run == 1:
					var r := _flat(p2.global_position).length()
					var face := p2.forward.dot(-_flat(p2.global_position).normalized())
					# the splat drawing is on screen from its first frame (no smoothing): arm thrown wide
					var arm: Vector3 = p2.animator.pose["upper_arm_l"]
					if absf(arm.z - (-1.9)) > 0.01:
						_fail("wall splat pose not on screen at its first frame: upper_arm_l z %.2f (want -1.90)" % arm.z)
						return
					# GDD 02 § Коло арени (Арес, 4a): the hurtbox stays on during the splat — the attacker may follow up
					if p2.hurt_shape.disabled:
						_fail("wall splat: hurtbox disabled during the splat (GDD 02: it stays on, the attacker can follow up)")
						return
					if p2.hp != _x0 or r < 12.5 - 0.05 or face < 0.9 or int(p2.stats.get("splats", 0)) != _n0 + 1:
						_fail("wall splat: hp %.1f → %.1f (want no damage), radius %.2f (want 12.5), facing the centre %.2f, splats %d → %d" % [_x0, p2.hp, r, face, _n0, p2.stats.get("splats", 0)])
						return
				if _splat_phase == 0 and _run == 4:
					_shot("15_free_wall_splat")
				if _splat_phase == 1 and _run == 3:
					# same combo, follow-up launcher into the same wall while splatted
					p2._enter_ragdoll(Vector3(16.0, 4.0, 0.0))
					_next_to(82)
			elif _run > 0:
				if _run != 10 or p2.state != Fighter.State.KNOCKDOWN:
					_fail("wall splat lasted %d frames then state %d (want 10, then KNOCKDOWN)" % [_run, p2.state])
					return
				_ok("wall splat: ragdoll at the edge stuck to the wall for %d frames, no damage (hp %.0f), facing the centre, then knockdown" % [_run, p2.hp])
				_splat_phase = 1
				_next_to(80)
			elif _f > _f0 + 200:
				_fail("wall splat: the launched fighter never splatted (state %d, at radius %.2f)" % [p2.state, _flat(p2.global_position).length()])
		82:
			# the second launch of the same combo flies into the wall again but must not splat
			if p2.state == Fighter.State.WALL_SPLAT:
				_fail("wall splat twice in one combo (splats %d → %d)" % [_n0, p2.stats.get("splats", 0)])
				return
			if p2.state == Fighter.State.GETUP or p2.is_actionable():
				var got := int(p2.stats.get("splats", 0)) - _n0
				if got != 1:
					_fail("wall splat: %d splats in the second combo (want 1)" % got)
					return
				_ok("wall splat once per combo: the next combo splatted again, a second launch into the wall in that combo did not (%d ragdoll frames, splats +%d)" % [_f - _f0, got])
				_load_arena(2, 90)   # Launch 3: Choko's passive Printer, fresh round
			elif _f > _f0 + 400:
				_fail("wall splat: second launch never settled (state %d)" % p2.state)
