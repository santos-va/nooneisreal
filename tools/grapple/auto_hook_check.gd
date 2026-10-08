extends SceneTree
## Plan docs/Plans/2026-10-07-Aim-Free-Rope.md step 1; T8 spec docs/GDD/06-UI-UX.md § «Трос без прицілювання», variant Г.
## Subject: for every human P1 traversal press the hero either hooks the anchor that was marked, or nothing is issued
## (no windup, slot or fatigue) and a sound and a reason answer; the enemy hook, CPU, the side camera and SHARED P2
## select bit for bit as the base (frozen oracle tools/grapple/harpoon_aim_base.gd).
##   A. Synthetic floor, both heroes, test anchors and walls, a Camera3D + HarpoonAim: P1-P10, N2-N9.
##   B. Production CityWorld, both heroes, real keyboard E, pad L3 and the left stick: P11 (safe point, both south
##      anchors → HANG; presses along the district route never rewind), N1 on the base anchor set at the start (deny,
##      TOO FAR, grey ring), HUD ring / edge arrow / windup fill / reason line / rate limit / tutorial / help.
## Thresholds are the spec's literals: switch 0.25 s, behind −0.2, TOO FAR ≤ 1.5 × range, reason 1.5 s, sound gap 0.3 s.
## --break=base|empty_shot|no_recheck|lock are negative controls (N10): the base selection, a press that fires into
## empty air (no T8 flag), a launch without the re-check, and no 0.25 s switch delay must each go red.
## Sentinel: AUTO_HOOK_COMPLETE checks=N failures=M mutation=<m>; failures print "AUTO_HOOK: ...".
const SWITCH_SECONDS: float = 0.25
const REASON_SECONDS: float = 1.5
const SOUND_GAP_TICKS: int = 18
const SAFE_POINT := Vector3(0, 0, 9.5)
const SOUTH_ANCHORS: Array[Vector3] = [Vector3(-8, 6.5, 8), Vector3(8, 6.5, 8)]
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var Hook: GDScript
var Base: GDScript
var Actor: GDScript
var Layout: GDScript
var Marker: GDScript
var sfx: Node
var router: Node
var helper: Node
var oracle: Node
var camera: Camera3D
var f: Node3D
## Part A lives in its own 16:9 world: the headless root window is square (100 × 100 → 1600 × 1600), and the T8
## numbers (half-width 48.6° at fov 65°) are for 16:9.
var stage: SubViewport
var props: Array[Node] = []
var denials: Array[String] = []


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("AUTO_HOOK: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	_send(event)


func _pad(button: JoyButton, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = down
	_send(event)


func _stick(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = JOY_AXIS_LEFT_Y
	event.axis_value = value
	_send(event)


func _run() -> void:
	await process_frame
	Hook = load("res://scripts/grapple/GrappleHook.gd")
	Actor = load("res://scripts/fighter/Fighter.gd")
	Layout = load("res://scripts/world/CityLayout.gd")
	Marker = load("res://scripts/world/CityHookMarker.gd")
	Base = load((get_script() as Script).resource_path.get_base_dir().path_join("harpoon_aim_base.gd"))
	sfx = root.get_node("Sfx")
	router = root.get_node("InputRouter")
	var state: Node = root.get_node("GameState")
	state.set_free_move(true)
	state.skeletal_rig = false
	state.water = null
	for hero: String in ["choko", "skea"]:
		await _synthetic(hero)
	for hero: String in ["choko", "skea"]:
		await _district(hero)
	# Same teardown as city_controls_check.gd: Ogg playback (the last grapple_fire voices) retires on audio-mixer wall
	# time, not on accelerated --fixed-fps frames; a voice still live at quit() left «2 resources still in use at exit».
	# The old 300 ms busy wait also spent hundreds to thousands of frames of the harness's --quit-after 12000.
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		var node := root.get_node_or_null(singleton)
		if node != null:
			node.queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("AUTO_HOOK frames=%d (the playable harness quits after 12000)" % Engine.get_process_frames())
	print("AUTO_HOOK_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)


# --- A. synthetic floor ------------------------------------------------------------------------------------------

func _anchor(id: String, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = id
	stage.add_child(node)
	node.global_position = at
	node.add_to_group("grapple_anchor")
	props.append(node)
	return node


func _wall(center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	stage.add_child(body)
	body.global_position = center
	props.append(body)
	return body


func _clear() -> void:
	for node: Node in props:
		if is_instance_valid(node):
			node.free()
	props.clear()
	f.grapple.registry.clear_match()
	f.grapple.detach()
	f.velocity = Vector3.ZERO
	f._wish = Vector3.ZERO
	f.control_locked = false
	helper.setup(camera, true)
	helper.traversal_switch_delay = 0.0 if mutation == "lock" else SWITCH_SECONDS
	await physics_frame


## The selection under test: the production adapter, or the frozen base for --break=base.
func _select(remember: bool = true) -> Dictionary:
	if mutation == "base":
		oracle.camera = camera
		oracle.solo = true
		return oracle.capture(f, false, remember)
	return helper.capture(f, false, remember)


## A press the way the fighter makes it (no recorded aim: HarpoonAim.press_packet). --break=empty_shot replays the
## same selection without its T8 flag, i.e. the pre-Г behaviour that fires into empty air.
func _press() -> int:
	if mutation == "empty_shot":
		var packet: Dictionary = helper.capture(f, false, false)
		packet.erase("assist")
		return f.grapple.fire(false, "grapple_parkour", packet)
	return f.grapple.fire(false, "grapple_parkour")


func _look(at: Vector3, from: Vector3) -> void:
	camera.global_position = from
	camera.look_at(at, Vector3.UP)


func _drive_until_settled(limit: int = 60) -> Array[int]:
	var phases: Array[int] = []
	for tick: int in limit:
		f.grapple.drive(1.0 / 60.0, true)
		phases.append(f.grapple.phase)
		if f.grapple.phase in [Hook.Phase.HANG, Hook.Phase.IDLE, Hook.Phase.MISS_REWIND]:
			break
	return phases


func _synthetic(hero: String) -> void:
	stage = SubViewport.new()
	stage.size = Vector2i(1600, 900)
	stage.own_world_3d = true
	root.add_child(stage)
	f = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
	f.data = load("res://data/characters/%s.tres" % hero)
	stage.add_child(f)
	f.set_physics_process(false)
	f.grapple.registry.set_physics_process(false)
	f.grapple.responsive_parkour = true # the city profile: 10-tick windup, run kept
	f.grapple.denied.connect(func(reason: String) -> void: denials.append(reason))
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(200, 1, 200)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	stage.add_child(floor_body)
	floor_body.position.y = -0.5
	camera = Camera3D.new()
	camera.fov = 65.0
	stage.add_child(camera)
	camera.current = true
	helper = load("res://scripts/core/HarpoonAim.gd").new()
	stage.add_child(helper)
	oracle = Base.new()
	stage.add_child(oracle)
	oracle.process_mode = Node.PROCESS_MODE_DISABLED
	await physics_frame
	await _selection_cases(hero)
	await _press_cases(hero)
	await _base_identity(hero)
	await _clear()
	stage.free()
	await physics_frame


func _selection_cases(hero: String) -> void:
	var tag := "[%s] " % hero
	# P1: inside the frame but outside the old 42° cone, ahead of travel.
	await _clear()
	f.position = Vector3(0, 3, 0)
	f._wish = Vector3.RIGHT
	f.forward = Vector3.RIGHT
	_look(Vector3(0, 4.25, 0), Vector3(0, 4.25, 8))
	var a := _anchor("P1Anchor", Vector3(7, 7, 0))
	await physics_frame
	var angle := rad_to_deg(acos((-camera.global_basis.z).dot((a.global_position - camera.global_position).normalized())))
	_check(angle > 42.0 and camera.get_viewport().get_visible_rect().has_point(camera.unproject_position(a.global_position)), tag + "P1 precondition: %.1f° off-centre, inside the frame (screen %s of %s)" % [angle, camera.unproject_position(a.global_position), camera.get_viewport().get_visible_rect()])
	var packet := _select()
	_check(packet.target_id == String(a.get_path()) and packet.get("in_frame", false), tag + "P1 a framed anchor outside 42° ahead of travel is selected")
	# P2: above the frame (standing under a lamp) and past the side edge, ahead of travel; the packet says off-frame.
	await _clear()
	f.position = Vector3(0, 0, 0)
	f.forward = Vector3.FORWARD
	_look(Vector3(0, 1.5, -6), Vector3(0, 3.0, 6))
	var above := _anchor("P2Above", Vector3(0.5, 8.5, -1.0))
	await physics_frame
	packet = _select()
	_check(packet.target_id == String(above.get_path()) and not packet.get("in_frame", true), tag + "P2 an anchor above the frame is selected and marked off-frame (edge arrow)")
	await _clear()
	f.position = Vector3(0, 3, 0)
	f._wish = Vector3.RIGHT
	f.forward = Vector3.RIGHT
	_look(Vector3(0, 4.25, 0), Vector3(0, 4.25, 8))
	var side := _anchor("P2Side", Vector3(8, 6, 2))
	await physics_frame
	packet = _select()
	_check(packet.target_id == String(side.get_path()) and not packet.get("in_frame", true), tag + "P2 an anchor past the side edge, ahead of travel, is selected off-frame")
	# P3: a wall between the camera and the anchor; the hand sees it.
	await _clear()
	f.position = Vector3(0, 3, 0)
	f._wish = Vector3.RIGHT
	f.forward = Vector3.RIGHT
	_look(Vector3(0, 4.25, 0), Vector3(0, 4.25, 8))
	a = _anchor("P3Anchor", Vector3(4, 7, 0))
	_wall(camera.global_position.lerp(a.global_position, 0.5), Vector3(0.5, 0.8, 0.8))
	await physics_frame
	_check(f.grapple.line_clear(f.position + Hook.HAND, a.global_position), tag + "P3 precondition: the hand line is clear")
	packet = _select()
	_check(packet.target_id == String(a.get_path()) and packet.get("camera_hidden", false), tag + "P3 a camera-hidden anchor the hand sees is selected, drawn dimmed")
	# P4: two framed anchors ahead at 6 m and 12 m, the same elevation from the hand.
	await _clear()
	f.position = Vector3(0, 3, 0)
	f._wish = Vector3.FORWARD
	f.forward = Vector3.FORWARD
	_look(Vector3(0, 4.25, 0), Vector3(0, 4.25, 8))
	var elevation := deg_to_rad(40.0)
	var near := _anchor("P4Near", Vector3(0, 4.25 + 6.0 * sin(elevation), -6.0 * cos(elevation)))
	_anchor("P4Far", Vector3(0, 4.25 + 12.0 * sin(elevation), -12.0 * cos(elevation)))
	await physics_frame
	_check(_select().target_id == String(near.get_path()), tag + "P4 of two framed anchors ahead the nearer wins")
	# P5: running; an anchor ahead at 10 m and one behind, in the frame, at 6 m.
	await _clear()
	f.position = Vector3(0, 3, 0)
	f._wish = Vector3.RIGHT
	f.forward = Vector3.RIGHT
	_look(Vector3(0, 4.25, 0), Vector3(0, 4.25, 14))
	var ahead := _anchor("P5Ahead", Vector3(9, 4.25 + sqrt(100.0 - 81.0), 0))
	var behind := _anchor("P5Behind", Vector3(-5.5, 4.25 + sqrt(36.0 - 30.25 - 1.0), -1))
	await physics_frame
	_check(camera.get_viewport().get_visible_rect().has_point(camera.unproject_position(behind.global_position)), tag + "P5 precondition: the anchor behind is in the frame")
	_check(_select().target_id == String(ahead.get_path()), tag + "P5 running: the anchor ahead beats a nearer one behind")
	# P6: an explicit look at the framed anchor behind holds it for the look's 2 s.
	camera.look_at(behind.global_position, Vector3.UP)
	helper.apply_look(Vector2(0.001, 0.0))
	await _wait_switch()
	_check(_select().target_id == String(behind.get_path()), tag + "P6 a look at the anchor behind selects it")
	for tick: int in 150:
		helper.step(1.0 / 60.0)
	camera.look_at(Vector3(0, 4.25, 0), Vector3.UP)
	await _wait_switch()
	_check(not helper.is_manual() and _select().target_id == String(ahead.get_path()), tag + "P6 after the look's 2 s travel decides again")
	# P7: a small crossover keeps the target; a clearly better one waits 0.25 s after the last change.
	await _clear()
	f.position = Vector3(0, 3, 0)
	f._wish = Vector3.FORWARD
	f.forward = Vector3.FORWARD
	_look(Vector3(0, 6, -6), Vector3(0, 4.25, 8))
	var left := _anchor("P7Left", Vector3(-1.0, 8, -6))
	var right := _anchor("P7Right", Vector3(1.0, 8, -6.05))
	await physics_frame
	var first := String(_select().target_id)
	left.global_position.z -= 0.03
	right.global_position.z += 0.03
	_check(_select().target_id == first, tag + "P7 a small score crossover keeps the target")
	var winner := left if first == String(left.get_path()) else right
	var loser := right if winner == left else left
	winner.global_position = Vector3(winner.global_position.x, 9.5, -12) # the target gets clearly worse but stays valid
	loser.global_position = Vector3(0, 7, -2)
	await _ticks_physics(roundi(SWITCH_SECONDS * 60.0) - 6)
	_check(_select().target_id == first, tag + "P7 a clearly better anchor does not replace the target inside 0.25 s")
	await _ticks_physics(8)
	_check(_select().target_id == String(loser.get_path()), tag + "P7 after 0.25 s the better anchor replaces it")
	# P9: keyboard without looking — yaw fixed, the hero turns toward an anchor outside the initial frame.
	await _clear()
	f.position = Vector3(0, 3, 0)
	_look(Vector3(0, 4.25, 0), Vector3(0, 4.25, 8))
	var turned := _anchor("P9Anchor", Vector3(7, 7.5, 7))
	await physics_frame
	f._wish = Vector3.FORWARD
	f.forward = Vector3.FORWARD
	_check(_select().target_id.is_empty(), tag + "P9 precondition: behind and outside the frame while moving away")
	f._wish = Vector3(1, 0, 1).normalized()
	f.forward = f._wish
	await _wait_switch()
	packet = _select()
	_check(packet.target_id == String(turned.get_path()) and not packet.get("in_frame", true), tag + "P9 turning toward an off-frame anchor selects it without any look input")
	# N2: an anchor behind a wall from the hand — never marked, NO ANCHOR IN REACH.
	await _clear()
	f.position = Vector3(0, 3, 0)
	f._wish = Vector3.RIGHT
	f.forward = Vector3.RIGHT
	_look(Vector3(0, 4.25, 0), Vector3(0, 4.25, 8))
	a = _anchor("N2Anchor", Vector3(4, 7, 0))
	_wall((f.position + Hook.HAND).lerp(a.global_position, 0.5), Vector3(0.5, 0.8, 0.8))
	await physics_frame
	packet = _select()
	_check(packet.target_id.is_empty() and packet.get("reason", "") == "none", tag + "N2 an anchor hidden from the hand is no target (reason %s)" % packet.get("reason", "?"))
	# N3: running, an anchor behind and outside the frame — ANCHOR BEHIND.
	await _clear()
	f.position = Vector3(0, 3, 0)
	f._wish = Vector3.FORWARD
	f.forward = Vector3.FORWARD
	_look(Vector3(0, 4.25, 0), Vector3(0, 4.25, 8))
	_anchor("N3Anchor", Vector3(0, 7, 6))
	await physics_frame
	packet = _select()
	_check(packet.target_id.is_empty() and packet.get("reason", "") == "behind", tag + "N3 an anchor behind and off-frame is no target, reason behind (%s)" % packet.get("reason", "?"))
	# N4: on a roof at y 4 with 6.5 m anchors (the district's old roofs) — NO ANCHOR ABOVE.
	await _clear()
	_wall(Vector3(0, 2, 0), Vector3(12, 4, 12))
	f.position = Vector3(0, 4, 0)
	f.forward = Vector3.FORWARD
	_look(Vector3(0, 5.25, -4), Vector3(0, 6.5, 6))
	_anchor("N4AnchorA", Vector3(-3, 6.5, -3))
	_anchor("N4AnchorB", Vector3(3, 6.5, -3))
	await physics_frame
	packet = _select()
	_check(packet.target_id.is_empty() and packet.get("reason", "") == "above", tag + "N4 roof: anchors below 1.5 m over the hand are no target, reason above (%s)" % packet.get("reason", "?"))


func _wait_switch() -> void:
	await _ticks_physics(roundi(SWITCH_SECONDS * 60.0) + 1)


func _ticks_physics(count: int) -> void:
	for tick: int in count:
		await physics_frame


func _press_cases(hero: String) -> void:
	var tag := "[%s] " % hero
	# N1 geometry on the synthetic floor: the old start (0, 0, 23) and the four old anchors, 17.79 m away.
	await _clear()
	f.position = Vector3(0, 0, 23)
	f.forward = Vector3.FORWARD
	_look(Vector3(0, 1.4, 17), Vector3(0, 2.8, 29))
	for x: float in [-8.0, 8.0]:
		for z: float in [-8.0, 8.0]:
			_anchor("N1Anchor%d%d" % [int(x), int(z)], Vector3(x, 6.5, z))
	await physics_frame
	var packet := _select()
	_check(packet.target_id.is_empty() and packet.get("reason", "") == "too_far" and absf(float(packet.get("far_distance", 0.0)) - 17.79) < 0.01, tag + "N1 the old start: no target, too far, grey ring at %.2f m" % float(packet.get("far_distance", 0.0)))
	await _check_denied(tag + "N1 press at the old start", "too_far")
	# N5: no stock and no rope — NO HARPOONS.
	await _clear()
	f.position = Vector3(0, 3, 0)
	f._wish = Vector3.RIGHT
	f.forward = Vector3.RIGHT
	_look(Vector3(0, 4.25, 0), Vector3(0, 4.25, 8))
	_anchor("N5Anchor", Vector3(4, 7, 0))
	await physics_frame
	while f.grapple.charges > 0:
		f.grapple.registry.issue(f.player_index)
	await _check_denied(tag + "N5 press with an empty stock", "no_harpoons")
	# P8: the press fires at the packet published on the tick before; a stick twitch in the press tick changes nothing.
	await _clear()
	helper.traversal_switch_delay = 0.0 # isolate the one-tick hand-over from the 0.25 s switch delay
	f.position = Vector3(0, 3, 0)
	f.forward = Vector3.FORWARD
	_look(Vector3(0, 6, -6), Vector3(0, 4.25, 8))
	var east := _anchor("P8East", Vector3(4, 8, -6))
	var west := _anchor("P8West", Vector3(-4, 8, -6))
	await physics_frame
	f._wish = Vector3(1, 0, -1).normalized()
	helper.publish(f)
	_check(helper.published.target_id == String(east.get_path()), tag + "P8 precondition: tick N marks the east anchor")
	await physics_frame
	f._wish = Vector3(-1, 0, -1).normalized() # the L3 click twitches the stick in the press tick
	helper.publish(f)
	_check(helper.published.target_id == String(west.get_path()), tag + "P8 precondition: tick N+1 alone would mark the west anchor")
	var outcome: int = f.grapple.fire(false, "grapple_parkour")
	_check(outcome == Hook.Target.ANCHOR and f.grapple.aim_intent.get("target_id", "") == String(east.get_path()), tag + "P8 the press on tick N+1 takes tick N's marked anchor")
	var fixed: Dictionary = f.grapple.aim_intent.duplicate(true)
	f.grapple.fire(false, "grapple_parkour")
	_check(f.grapple.aim_intent == fixed, tag + "P8 a second press during the windup changes nothing")
	var phases := _drive_until_settled()
	_check(f.grapple.phase == Hook.Phase.HANG and f.grapple.anchor_point.is_equal_approx(east.global_position), tag + "P8 the marked anchor is the one hooked")
	_check(Hook.Phase.MISS_REWIND not in phases, tag + "P8 no rewind")
	# P10: a transfer in the swing follows the swing's speed; one device, FLIGHT → HANG.
	await _clear()
	var from_anchor := _anchor("P10From", Vector3(0, 9.25, 0))
	var to_anchor := _anchor("P10To", Vector3(6, 9.25, 0))
	_anchor("P10Back", Vector3(-6, 9.25, 0))
	f.position = Vector3(0, 3, 0)
	f.forward = Vector3.RIGHT
	_look(Vector3(0, 6, 0), Vector3(0, 5, 9))
	await physics_frame
	var token: int = f.grapple.registry.issue(f.player_index)
	f.grapple.registry.deploy(token, f.player_index, from_anchor.global_position, f.position + Hook.HAND, 5.0)
	f.grapple.fire(false, "grapple_parkour", {"target_id": "", "point": from_anchor.global_position})
	_check(f.grapple.attached, tag + "P10 precondition: hanging from a deployed rope")
	f.velocity = Vector3(5, 0, 0)
	helper.publish(f)
	await physics_frame
	var stock: int = f.grapple.charges
	_check(f.grapple.retarget() and f.grapple.phase == Hook.Phase.FLIGHT and f.grapple.aim_intent.get("target_id", "") == String(to_anchor.get_path()), tag + "P10 transfer at the swing's speed goes to the anchor ahead")
	_drive_until_settled()
	_check(f.grapple.phase == Hook.Phase.HANG and f.grapple.anchor_point.is_equal_approx(to_anchor.global_position) and f.grapple.charges == stock - 1, tag + "P10 FLIGHT → HANG with exactly one device")
	# N6: running away from a framed anchor; for 10…14 m either no target (too far) or a hang — never a rewind.
	for metres: float in [10.0, 11.0, 12.0, 12.5, 13.0, 13.6, 14.0]:
		await _clear()
		f.position = Vector3(0, 0, 0)
		f.forward = Vector3.FORWARD
		_look(Vector3(0, 3, -6), Vector3(0, 2.8, 6))
		var rise := 5.0
		var far := _anchor("N6Anchor", Vector3(0, 1.25 + rise, -sqrt(metres * metres - rise * rise)))
		await physics_frame
		f.velocity = Vector3(0, 0, f.data.walk_speed)
		f._wish = Vector3.BACK
		packet = _select()
		var rewound := false
		if not packet.target_id.is_empty():
			if mutation == "no_recheck":
				packet.erase("assist")
			f.grapple.fire(false, "grapple_parkour", packet)
			rewound = Hook.Phase.MISS_REWIND in _drive_until_settled(80)
		_check(not rewound and (not packet.target_id.is_empty() or packet.get("reason", "") == "too_far"), tag + "N6 running away from %.1f m: target=%s reason=%s, no rewind" % [metres, not packet.target_id.is_empty(), packet.get("reason", "")])
		props.erase(far)
		far.free()
	# N6 at launch: a target valid at the press drifts out of reach during the windup — cancelled, nothing spent.
	await _clear()
	f.position = Vector3(0, 0, 0)
	f.forward = Vector3.FORWARD
	_look(Vector3(0, 3, -6), Vector3(0, 2.8, 6))
	var edge := _anchor("N6Edge", Vector3(0, 6.25, -12.9))
	await _ticks_physics(SOUND_GAP_TICKS)
	packet = _select()
	stock = f.grapple.charges
	var fatigue: float = f.fatigue
	var frame := Engine.get_physics_frames()
	if mutation == "no_recheck":
		packet.erase("assist")
	f.grapple.fire(false, "grapple_parkour", packet)
	_check(packet.target_id == String(edge.get_path()) and f.grapple.phase == Hook.Phase.WINDUP, tag + "N6 precondition: the edge anchor is pressed")
	f.position = Vector3(0, 0, 2.5) # the hero is carried 2.5 m away during the windup
	phases = _drive_until_settled(80)
	_check(Hook.Phase.MISS_REWIND not in phases and f.grapple.phase == Hook.Phase.IDLE and f.grapple.charges == stock and is_equal_approx(f.fatigue, fatigue), tag + "N6 a target out of reach at launch is cancelled without spending")
	_check(int(sfx.last_frame.get("grapple_denied", -1)) >= frame, tag + "N6 the cancelled launch is answered by the denied sound")
	# N7: the target is taken between the press and the launch — re-selected, or cancelled without spending.
	for spare: bool in [true, false]:
		await _clear()
		f.position = Vector3(0, 3, 0)
		f._wish = Vector3.RIGHT
		f.forward = Vector3.RIGHT
		_look(Vector3(0, 4.25, 0), Vector3(0, 4.25, 8))
		var taken := _anchor("N7Taken", Vector3(4, 7.5, 0))
		var other: Node3D = _anchor("N7Spare", Vector3(5, 7.5, -3)) if spare else null
		await physics_frame
		helper.publish(f)
		await physics_frame
		stock = f.grapple.charges
		_press()
		_check(f.grapple.aim_intent.get("target_id", "") == String(taken.get_path()), tag + "N7 precondition: the press took the near anchor (spare=%s)" % spare)
		f.grapple.registry.capacities[2] = 3 # a second owner without a fighter takes the point
		var thief: int = f.grapple.registry.issue(2)
		f.grapple.registry.deploy(thief, 2, taken.global_position, taken.global_position + Vector3.DOWN * 3.0, 3.0)
		phases = _drive_until_settled(80)
		if spare:
			_check(f.grapple.phase == Hook.Phase.HANG and f.grapple.anchor_point.is_equal_approx(other.global_position) and f.grapple.charges == stock - 1, tag + "N7 a taken target is re-selected at launch")
		else:
			_check(f.grapple.phase == Hook.Phase.IDLE and f.grapple.charges == stock, tag + "N7 a taken target with no other is cancelled without spending")
		_check(Hook.Phase.MISS_REWIND not in phases, tag + "N7 no rewind (spare=%s)" % spare)
	helper.traversal_switch_delay = 0.0 if mutation == "lock" else SWITCH_SECONDS


## A press that must issue nothing: IDLE, same stock and fatigue, the denied sound on this tick, no fire sound, the
## reason reported once, no rewind.
func _check_denied(label: String, reason: String) -> void:
	await _ticks_physics(SOUND_GAP_TICKS) # the denied sound of an earlier case must not mute this one
	helper.publish(f)
	await physics_frame
	var stock: int = f.grapple.charges
	var fatigue: float = f.fatigue
	denials.clear()
	var frame := Engine.get_physics_frames()
	var outcome := _press()
	var phases := _drive_until_settled(40)
	_check(outcome == Hook.Target.NONE and f.grapple.phase == Hook.Phase.IDLE and f.grapple.charges == stock and is_equal_approx(f.fatigue, fatigue), label + ": nothing issued (outcome %d, phase %d)" % [outcome, f.grapple.phase])
	_check(int(sfx.last_frame.get("grapple_denied", -1)) == frame and int(sfx.last_frame.get("grapple_fire", -1)) < frame, label + ": the denied sound on the press tick, no fire sound")
	_check(denials == [reason], label + ": the reason %s is reported once (%s)" % [reason, denials])
	_check(Hook.Phase.MISS_REWIND not in phases, label + ": no rewind")


## N8 / N9: the enemy hook, CPU, the side camera and SHARED P2 select bit for bit as the base on a fixed set of poses.
func _base_identity(hero: String) -> void:
	var tag := "[%s] " % hero
	await _clear()
	var enemy: Node3D = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
	enemy.data = load("res://data/characters/%s.tres" % ("skea" if hero == "choko" else "choko"))
	enemy.player_index = 2
	stage.add_child(enemy)
	enemy.set_physics_process(false)
	for at: Vector3 in [Vector3(3, 7, -2), Vector3(-5, 6.5, -6), Vector3(9, 8, 4), Vector3(0, 9, -11)]:
		_anchor("BaseAnchor%d" % props.size(), at)
	await physics_frame
	var poses: Array[Dictionary] = [
		{"at": Vector3(0, 0, 0), "forward": Vector3.FORWARD, "wish": Vector3.ZERO, "enemy": Vector3(0, 0, -4), "eye": Vector3(0, 2.6, 6)},
		{"at": Vector3(2, 0, 1), "forward": Vector3.RIGHT, "wish": Vector3.RIGHT, "enemy": Vector3(6, 0, 0), "eye": Vector3(-3, 2.0, 5)},
		{"at": Vector3(-1, 3, 0), "forward": Vector3.LEFT, "wish": Vector3(-1, 0, -1).normalized(), "enemy": Vector3(-4, 0, -3), "eye": Vector3(1, 4.5, 6)},
		{"at": Vector3(0, 0, 3), "forward": Vector3.BACK, "wish": Vector3.ZERO, "enemy": Vector3(0, 0, 8), "eye": Vector3(0, 3, -3)},
	]
	var same := 0
	var total := 0
	for mode: String in ["enemy", "enemy_manual", "cpu", "side", "shared_p2"]:
		helper.setup(camera, mode != "side")
		oracle.setup(camera, mode != "side")
		for pose: Dictionary in poses:
			f.position = pose.at
			f.forward = pose.forward
			f._wish = pose.wish
			enemy.position = pose.enemy
			_look(pose.at + Vector3(0, 1.4, 0), pose.eye)
			f.is_cpu = mode == "cpu"
			f.player_index = 2 if mode == "shared_p2" else 1
			if mode == "enemy_manual":
				helper.apply_look(Vector2(0.002, 0.0))
				oracle.apply_look(Vector2(0.002, 0.0))
			await physics_frame
			var enemy_mode := mode in ["enemy", "enemy_manual"]
			var ours: Dictionary = helper.capture(f, enemy_mode)
			var theirs: Dictionary = oracle.capture(f, enemy_mode)
			total += 1
			if var_to_bytes(ours) == var_to_bytes(theirs):
				same += 1
			else:
				_check(false, tag + "N8/N9 %s pose %s differs from the base: %s vs %s" % [mode, pose.at, ours, theirs])
	f.is_cpu = false
	f.player_index = 1
	camera.set_meta("harpoon_aim", helper)
	_check(same == total and total == 20, tag + "N8/N9 enemy, manual enemy, CPU, side camera and SHARED P2: %d / %d packets bit for bit as the base" % [same, total])
	enemy.free()
	await physics_frame


# --- B. production CityWorld -------------------------------------------------------------------------------------

func _district(hero: String) -> void:
	var tag := "[%s city] " % hero
	var state: Node = root.get_node("GameState")
	state.p1_character = hero
	router.apply_profile("solo", false)
	var world: Node = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	var hero_node: Node3D = world.player
	var hud: Node = world.hud
	var rig: Node3D = world.camera_rig
	var aim: Node = rig.aim
	var city_denials: Array[String] = []
	hero_node.grapple.denied.connect(func(reason: String) -> void: city_denials.append(reason))
	await _ticks(40)
	# Tutorial and help name the new rule.
	world.onboarding.step_index = 3
	world.onboarding.changed.emit()
	_check(hud.objective_label.text.begins_with("Move toward a lamp"), tag + "the rope step says 'Move toward a lamp' (%s)" % hud.objective_label.text)
	_check("marked anchor only" in hud.exploration_help(), tag + "the help says 'marked anchor only'")
	world.onboarding.skip()
	# P11: from the safe point both south anchors hook, by keyboard E and by pad L3.
	var input_kind := 0
	for south: Vector3 in SOUTH_ANCHORS:
		await _reset_hero(world, SAFE_POINT, south - SAFE_POINT, south - SAFE_POINT)
		var marked: Dictionary = aim.published
		_check(marked.get("target_id", "").ends_with(_anchor_name(world, south)), tag + "P11 the safe point marks the south anchor %s (%s)" % [south, marked.get("target_id", "")])
		_check(hud._hook_marker.mode == Marker.Mode.RING and hud._aim_cue.visible and "HOOK" in hud._aim_cue.text, tag + "P11 a ring and '%s' mark it" % hud._aim_cue.text)
		_check(hud._hook_marker.get_index() > hud._quest_guide.get_index() and hud._hook_marker.get_index() > hud._quest_card.get_index() and hud._hook_marker.get_index() > hud._status_card.get_index(), tag + "the ring draws above the HUD cards")
		var stock: int = hero_node.grapple.charges
		await _real_press(input_kind)
		var saw_fill := false
		var phases: Array[int] = []
		for tick: int in 40:
			await _ticks(1)
			phases.append(hero_node.grapple.phase)
			if hero_node.grapple.phase == Hook.Phase.WINDUP and hud._hook_marker.fill > 0.0 and hud._hook_marker.mode == Marker.Mode.RING:
				saw_fill = true
			if hero_node.grapple.phase == Hook.Phase.HANG:
				break
		_check(hero_node.grapple.phase == Hook.Phase.HANG and hero_node.grapple.anchor_point.is_equal_approx(south) and hero_node.grapple.charges == stock - 1, tag + "P11 %s → HANG on %s" % ["E" if input_kind == 0 else "L3", south])
		_check(saw_fill, tag + "P11 the ring closes and fills during the windup")
		_check(Hook.Phase.MISS_REWIND not in phases, tag + "P11 no rewind")
		input_kind = 1 - input_kind
	# Edge arrow: standing under an anchor, the target is above the frame.
	await _reset_hero(world, Vector3(7.5, 0, 8.5), Vector3.FORWARD, Vector3.FORWARD)
	var overhead: Dictionary = aim.published
	var bounds: Vector2 = hud._root.size
	_check(overhead.get("target_id", "").ends_with(_anchor_name(world, Vector3(8, 6.5, 8))) and not overhead.get("in_frame", true), tag + "under a lamp the overhead anchor is the off-frame target")
	_check(hud._hook_marker.mode == Marker.Mode.ARROW and Rect2(Vector2(12, 12), bounds - Vector2(24, 92)).has_point(hud._hook_marker.at) and hud._hook_marker.pointing.y < -0.5, tag + "an edge arrow at %s points up toward it" % hud._hook_marker.at)
	_check(hud._aim_cue.visible and hud._aim_cue.position.y > hud._hook_marker.at.y and "HOOK" in hud._aim_cue.text, tag + "the arrow's label sits on its inner side (%s under %s)" % [hud._aim_cue.position, hud._hook_marker.at])
	# N1 on the base anchor set (the four street lamps) at the start: denied, TOO FAR, grey ring.
	var appended: Array[Node] = []
	for node: Node in get_nodes_in_group("grapple_anchor"):
		if Layout.anchors().find((node as Node3D).global_position) >= 4:
			appended.append(node)
			node.remove_from_group("grapple_anchor")
	await _reset_hero(world, Layout.spawn_position(), Vector3.FORWARD, Vector3.FORWARD)
	var start: Dictionary = aim.published
	_check(start.get("target_id", "x") == "" and start.get("reason", "") == "too_far" and absf(float(start.get("far_distance", 0.0)) - 17.79) < 0.05, tag + "N1 the base start: no target, too far at %.2f m" % float(start.get("far_distance", 0.0)))
	_check(hud._hook_marker.mode == Marker.Mode.TOO_FAR and "TOO FAR · 17.8m" in hud._aim_cue.text, tag + "N1 a grey ring says '%s'" % hud._aim_cue.text)
	var stock_before: int = hero_node.grapple.charges
	var fatigue_before: float = hero_node.fatigue
	var frame := Engine.get_physics_frames()
	city_denials.clear()
	await _real_press(0)
	await _ticks(3)
	_check(hero_node.grapple.phase == Hook.Phase.IDLE and hero_node.grapple.charges == stock_before and hero_node.fatigue - fatigue_before < Actor.FATIGUE_GRAPPLE_S / hero_node.data.fatigue_seconds * 0.5 and hero_node.state != Actor.State.GRAPPLE, tag + "N1 E at the base start issues nothing (no windup, slot or fatigue)")
	var denied_at: int = int(sfx.last_frame.get("grapple_denied", -1))
	_check(denied_at > frame and int(sfx.last_frame.get("grapple_fire", -1)) <= frame and city_denials == ["too_far"], tag + "N1 the denied sound and the reason, no fire sound")
	_check(hud.hint_label.visible and hud.hint_label.text == "ANCHOR TOO FAR · get closer", tag + "N1 the hint line says '%s'" % hud.hint_label.text)
	# The sound is rate-limited, the line is refreshed by a repeat press and leaves after 1.5 s.
	await _ticks(4)
	await _real_press(1)
	await _ticks(2)
	_check(int(sfx.last_frame.get("grapple_denied", -1)) == denied_at and city_denials.size() == 2, tag + "a second press within 0.3 s refreshes the reason without a second sound")
	await _ticks(roundi(REASON_SECONDS * 60.0) - 12)
	_check(hud.hint_label.visible and hud.hint_label.text.begins_with("ANCHOR TOO FAR"), tag + "the refreshed reason is still shown before 1.5 s")
	await _ticks(16)
	_check(not (hud.hint_label.visible and hud.hint_label.text.begins_with("ANCHOR TOO FAR")), tag + "the reason line leaves after 1.5 s")
	await _real_press(0)
	await _ticks(2)
	_check(int(sfx.last_frame.get("grapple_denied", -1)) > denied_at, tag + "after 0.3 s the denied sound plays again")
	for node: Node in appended:
		node.add_to_group("grapple_anchor")
	# P11 route: running presses along the district route never rewind; each press hangs or is refused with a reason.
	# Residents stand still for the route: a body that walks across a 0.29 s flight is the spec's own exception.
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	var presses := 0
	var hangs := 0
	var refusals := 0
	var rewinds := 0
	var route: Array[Vector3] = Layout.route_points()
	for leg: int in route.size() - 1:
		var from: Vector3 = route[leg]
		var to: Vector3 = route[leg + 1]
		var length := Vector2(to.x - from.x, to.z - from.z).length()
		if length < 1.0:
			continue
		var direction := Vector3(to.x - from.x, 0, to.z - from.z).normalized()
		var samples := maxi(1, floori(length / 8.0))
		for sample: int in samples:
			var at := from.lerp(to, (float(sample) + 0.5) / float(samples))
			await _reset_hero(world, at, direction, direction)
			_stick(-1.0)
			await _ticks(12)
			city_denials.clear()
			var stock: int = hero_node.grapple.charges
			await _real_press(presses % 2)
			presses += 1
			var phases: Array[int] = []
			for tick: int in 50:
				await _ticks(1)
				phases.append(hero_node.grapple.phase)
				if hero_node.grapple.phase == Hook.Phase.HANG or (tick > 2 and hero_node.grapple.phase == Hook.Phase.IDLE):
					break
			_stick(0.0)
			if Hook.Phase.MISS_REWIND in phases:
				rewinds += 1
				_check(false, tag + "P11 route press at %s rewound" % at)
			elif hero_node.grapple.phase == Hook.Phase.HANG:
				hangs += 1
			elif city_denials.size() == 1 and hero_node.grapple.charges == stock:
				refusals += 1
			else:
				_check(false, tag + "P11 route press at %s neither hung nor was refused once (%s, phase %d)" % [at, city_denials, hero_node.grapple.phase])
	print("AUTO_HOOK route %s presses=%d hangs=%d refusals=%d rewinds=%d" % [hero, presses, hangs, refusals, rewinds])
	_check(presses >= 10 and rewinds == 0 and hangs > presses / 2, tag + "P11 route: %d presses, %d hangs, %d refusals, %d rewinds" % [presses, hangs, refusals, rewinds])
	world.queue_free()
	current_scene = null
	await _ticks(3)


func _anchor_name(world: Node, point: Vector3) -> String:
	return "StreetAnchor%d" % Layout.anchors().find(point)


## Put the hero at `at` with a fresh stock, facing `facing`, the camera looking along `view`, and let it settle.
func _reset_hero(world: Node, at: Vector3, facing: Vector3, view: Vector3) -> void:
	var hero_node: Node3D = world.player
	_stick(0.0)
	hero_node.grapple.detach()
	world.ropes.clear_match()
	await _ticks(1)
	hero_node.restart_at(at)
	hero_node._set_forward(Vector3(facing.x, 0, facing.z))
	var rig: Node3D = world.camera_rig
	rig.reset_view()
	rig.aim.yaw_offset = atan2(-view.x, -view.z)
	await _ticks(14)


## One real press of the parkour hook: 0 = keyboard E, 1 = pad L3.
func _real_press(kind: int) -> void:
	if kind == 0:
		_key(KEY_E, true)
		await _ticks(1)
		_key(KEY_E, false)
	else:
		_pad(JOY_BUTTON_LEFT_STICK, true)
		await _ticks(1)
		_pad(JOY_BUTTON_LEFT_STICK, false)
