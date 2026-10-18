extends SceneTree
## Finite-device traversal, camera candidates, prepared rope catch and latched input.
## The duel's rule stays: a failed transfer keeps the support (lines «same occupied anchor», «empty stock», «out-of-range»,
## «stale target»). The city (ADR-028 п. 5, T5 docs/GDD/2026-10-15-Rope-Climb-Numbers.md § 8, T8
## docs/GDD/2026-10-15-Rope-Climb-Input.md § 2.2) narrows it to «a failed transfer with a target shown in the 15-tick
## window keeps the support» — the hang, its length, the velocity and the stock as they were; with no target shown for
## the window E lets go, the velocity as it is, the old rope deployed, the stock the same; the empty stock lets go too
## (no rope in 0.70 m). Checked on a CityFighter body with real E presses through CityFighter._tick_grapple.
## The window is exactly 15 ticks: a target shown 14 ticks ago keeps the hang, 15 lets go (T5 Е2 asks ≥ 6; T4 audit 15а Y1).
## Every row starts swinging at (3; 0; 1) m/s, so «the velocity as it is» on the let-go compares a real velocity (T4 audit
## 15а RED-2 б: the rows used to start still and compared zero with zero).
##   --break=drop_on_flicker|stay_on_empty|short_window|zero_v — negatives on tools/grapple/rope_climb_fighter.gd (class
##     18: each prints its families on the TRAVERSAL_FAMILIES line and must go red in its own): E lets go though a target
##     was shown 3 ticks ago (`flicker`); E never lets go with no target shown (`empty`); the window 5 ticks (`flicker`);
##     E's let-go stops the swing (`letgo_v`).
## P5 (T8 acceptance 2026-10-15 ТЗ 7): a press inside the window that keeps the hang says why — exactly one
## GrappleHook.denied with a HarpoonAim.REASONS code (the HUD words it) — `denied`; --break=mute_deny (the hook never
## emits denied, rope_climb_mutants.gd) → `denied`.
## The swing every city E row starts with (T4 audit 15а: «наприклад (3; 0; 1)»).
const SWING := Vector3(3.0, 0.0, 1.0)
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var red: Dictionary = {}
var f: Node3D
var first: Node3D
var next: Node3D
var registry: Node3D
var Actor: GDScript
var Hook: GDScript
var helper: Node
var camera: Camera3D

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	run.call_deferred()

func check(ok: bool, label: String, family: String = "") -> void:
	checks += 1
	if not ok:
		failures += 1
		if not family.is_empty():
			red[family] = true
		push_error("TRAVERSAL: " + ("[%s] " % family if not family.is_empty() else "") + label)

func hang() -> void:
	registry.clear_match()
	f.position = Vector3(0, 3, 0)
	f.velocity = Vector3.ZERO
	f._wish = Vector3.ZERO
	f.control_locked = false
	f.state = Actor.State.GRAPPLE
	first.position = Vector3(0, 9.25, 0)
	next.position = Vector3(5, 9.25, 0)
	var token: int = registry.issue(1)
	registry.deploy(token, 1, first.position, f.position + Hook.HAND, 5.0)
	f.grapple.fire(false, "grapple_parkour")

func target_packet() -> Dictionary:
	return {"point": next.position, "target_id": String(next.get_path())}

func run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	Hook = load("res://scripts/grapple/GrappleHook.gd")
	var gs := root.get_node("GameState")
	gs.free_move = true
	gs.skeletal_rig = false
	gs.water = null
	f = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
	f.data = load("res://data/characters/choko.tres")
	root.add_child(f)
	f.set_physics_process(false)
	registry = f.grapple.registry
	registry.set_physics_process(false)
	first = Node3D.new()
	first.name = "FirstAnchor"
	root.add_child(first)
	first.add_to_group("grapple_anchor")
	next = Node3D.new()
	next.name = "NextAnchor"
	root.add_child(next)
	next.add_to_group("grapple_anchor")
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	root.add_child(ground)
	camera = Camera3D.new()
	root.add_child(camera)
	camera.current = true
	helper = load("res://scripts/core/HarpoonAim.gd").new()
	root.add_child(helper)
	helper.setup(camera, true)
	await physics_frame
	hang()
	check(f.grapple.attached, "fixture is attached through real reused rope")
	f.velocity = Vector3(2, 0, 0.5)
	var momentum: Vector3 = f.velocity
	var stock: int = f.grapple.charges
	var old_token: int = f.grapple._deployed_token
	var stale_point := target_packet()
	stale_point.point = Vector3(-100, -100, -100)
	check(f.grapple.retarget(stale_point), "second parkour validates anchor and refreshes stale snapshot point")
	check(f.grapple.phase == Hook.Phase.FLIGHT and f.grapple.chain_throw, "transfer skips windup into swept device flight")
	check(f.velocity.is_equal_approx(momentum), "new device never brakes or manufactures momentum")
	check(f.grapple.charges == stock - 1 and f.grapple.token != 0, "exactly one finite device issued")
	check(registry.records.has(old_token) and registry.records[old_token].users.is_empty(), "previous rope persists without a stale user")
	for frame: int in 40:
		f.grapple.drive(1.0 / 60.0, true)
		if f.grapple.phase != Hook.Phase.FLIGHT:
			break
	check(f.grapple.attached and f.grapple.anchor_point.is_equal_approx(next.position), "new support requires swept contact")
	check(absf(f.grapple.rope_length - (f.position + Hook.HAND).distance_to(next.position)) < 0.001, "only hand-to-anchor distance is deployed")
	check(registry.records.size() == 2 and f.grapple.charges == stock - 1, "contact does not double spend")
	var tokens_before: int = registry.records.size()
	check(not f.grapple.retarget(target_packet()) and registry.records.size() == tokens_before and f.grapple.attached, "same occupied anchor rejected without losing support")
	hang()
	while f.grapple.charges > 0:
		registry.issue(1)
	check(not f.grapple.retarget(target_packet()) and f.grapple.attached, "empty stock keeps old support")
	hang()
	next.position = Vector3(60, 9, 0)
	check(not f.grapple.retarget(target_packet()) and f.grapple.attached, "out-of-range target cannot consume or detach")
	check(not f.grapple.retarget({"target_id": "/root/missing", "point": Vector3.ZERO}) and f.grapple.attached, "stale target cannot detach")
	# Low-level release stays available; gameplay parkour supplies a tap latch.
	hang()
	for frame: int in 15:
		f._tick_grapple({"grapple_held": false, "jump_held": false, "axis": 0.0})
	check(f.grapple.attached and f.state == Actor.State.GRAPPLE, "parkour survives button release at gameplay boundary")
	f.grapple.drive(1.0 / 60.0, false)
	check(not f.grapple.attached, "explicit low-level release still detaches")
	# A deployed span is visible and selectable well before pickup radius.
	registry.clear_match()
	f.position = Vector3(0, 3, 0)
	f.velocity = Vector3(5, 0, 0)
	f._wish = Vector3.RIGHT
	first.position = Vector3(6, 8, 0)
	next.position = Vector3(40, 8, 0)
	var reused: int = registry.issue(1)
	registry.deploy(reused, 1, first.position, Vector3(6, 0, 0), 8.0)
	camera.position = Vector3(0, 4.25, 6)
	camera.look_at(Vector3(6, 4.25, 0))
	var candidate: Dictionary = helper.capture(f, false)
	check(candidate.candidate_kind == "rope" and not candidate.reachable and candidate.rope_token == reused, "camera previews distant existing span as approach cue")
	check(is_equal_approx(candidate.contact_distance, 6.0), "cue distance uses the same physical hand-to-span measure")
	stock = f.grapple.charges
	check(f.grapple.fire(false, "grapple_parkour", candidate) == Hook.Target.NONE and not f.grapple.busy(), "far approach cue cannot prepare or launch")
	check(f.grapple.charges == stock and f.grapple.token == 0, "far approach spends nothing")
	f.position.x = 5.31
	f.grapple.fire(false, "grapple_parkour", candidate)
	check(f.grapple.attached and f.grapple._deployed_token == reused and f.grapple.charges == stock, "current hand within 0.70 m catches without shot")
	# A far cue must leave the ordinary buffered jump available.
	f.grapple.detach()
	f.position = Vector3.ZERO
	f.velocity = Vector3.DOWN
	f._wish = Vector3.ZERO
	await physics_frame
	f._ground_physics(1.0 / 60.0, 0.0)
	check(f.on_ground(), "jump fixture contacts real floor")
	camera.position = Vector3(0, 1.25, 6)
	camera.look_at(Vector3(6, 1.25, 0))
	candidate = helper.capture(f, false)
	f.grapple.fire(false, "grapple_parkour", candidate)
	f.state = Actor.State.IDLE
	var input: Node = root.get_node("InputRouter")
	input.v_press(1, "jump")
	await physics_frame
	f._tick_ground(1.0 / 60.0, f._read_intent())
	input.v_release(1, "jump")
	check(f.velocity.y > 0.0 and f.state == Actor.State.JUMP and not f.grapple.busy(), "Space after distant rope cue remains ordinary jump")
	check(f.grapple.charges == stock, "approach jump does not issue a device")
	# Reachable spans have priority even if an unrelated free anchor was snapshotted.
	f.grapple.detach()
	f.position = Vector3(5.5, 2, 0)
	f.velocity = Vector3.ZERO
	next.position = Vector3(9, 7, 0)
	check(f.grapple.fire(false, "grapple_parkour", target_packet()) == Hook.Target.ANCHOR and f.grapple._deployed_token == reused and f.grapple.charges == stock, "nearby existing rope wins over a new shot")
	input.apply_profile("solo", false)
	var release_key := InputEventKey.new()
	release_key.physical_keycode = KEY_Z
	release_key.pressed = true
	Input.parse_input_event(release_key)
	Input.flush_buffered_events()
	f._tick_grapple(f._read_intent())
	check(not f.grapple.attached and f.state not in [Actor.State.GRAPPLE, Actor.State.CROUCH, Actor.State.BLOCK], "physical Z detaches before crouch or block handling")
	release_key = InputEventKey.new()
	release_key.physical_keycode = KEY_Z
	release_key.pressed = false
	Input.parse_input_event(release_key)
	Input.flush_buffered_events()
	input.apply_profile("solo", false)
	f.position = Vector3.ZERO
	f.velocity = Vector3.DOWN
	f._ground_physics(1.0 / 60.0, 0.0)
	f.state = Actor.State.IDLE
	release_key = InputEventKey.new()
	release_key.physical_keycode = KEY_X
	release_key.pressed = true
	Input.parse_input_event(release_key)
	Input.flush_buffered_events()
	f._tick_ground(1.0 / 60.0, f._read_intent())
	check(f.state == Actor.State.CROUCH and not f.grapple.busy(), "same physical X still crouches outside grapple")
	release_key = InputEventKey.new()
	release_key.physical_keycode = KEY_X
	release_key.pressed = false
	Input.parse_input_event(release_key)
	Input.flush_buffered_events()
	# Pad B has one router action (block); Fighter interprets its grapple context.
	input.apply_profile("solo", false)
	hang()
	var stamina_before: float = f.dodge_stamina
	var dash_before: int = f.dash_charges_left
	var pad_b := InputEventJoypadButton.new()
	pad_b.device = 0
	pad_b.button_index = JOY_BUTTON_B
	pad_b.pressed = true
	Input.parse_input_event(pad_b)
	Input.flush_buffered_events()
	f._tick_grapple(f._read_intent())
	check(not f.grapple.attached and f.state not in [Actor.State.GRAPPLE, Actor.State.BLOCK], "physical pad B releases grapple through block context")
	check(f.dodge_stamina == stamina_before and f.dash_charges_left == dash_before, "pad B detach spends neither stamina nor signature dash")
	pad_b = InputEventJoypadButton.new()
	pad_b.device = 0
	pad_b.button_index = JOY_BUTTON_B
	pad_b.pressed = false
	Input.parse_input_event(pad_b)
	Input.flush_buffered_events()
	input.apply_profile("solo", false)
	f.position = Vector3.ZERO
	f.velocity = Vector3.DOWN
	f._ground_physics(1.0 / 60.0, 0.0)
	f.state = Actor.State.IDLE
	pad_b = InputEventJoypadButton.new()
	pad_b.device = 0
	pad_b.button_index = JOY_BUTTON_B
	pad_b.pressed = true
	Input.parse_input_event(pad_b)
	Input.flush_buffered_events()
	f._tick_ground(1.0 / 60.0, f._read_intent())
	check(f.state == Actor.State.BLOCK and not f.grapple.busy(), "physical pad B keeps ordinary ground block outside grapple")
	pad_b = InputEventJoypadButton.new()
	pad_b.device = 0
	pad_b.button_index = JOY_BUTTON_B
	pad_b.pressed = false
	Input.parse_input_event(pad_b)
	Input.flush_buffered_events()
	await assistance()
	await responsive_profile()
	registry.clear_match()
	check(f.grapple._pending_rope == 0 and not f.grapple.busy(), "match clear removes catch and attachment state")
	await city_transfer()
	f.free()
	registry.free()
	first.free()
	next.free()
	camera.free()
	helper.free()
	ground.free()
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until := Time.get_ticks_msec() + 350
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	var families: Array = red.keys()
	families.sort()
	print("TRAVERSAL_FAMILIES failures=%d mutation=%s red=%s" % [failures, mutation, ",".join(families) if not families.is_empty() else "none"])
	print("TRAVERSAL_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)


func assistance() -> void:
	registry.clear_match()
	f.position = Vector3(0, 3, 0)
	f.velocity = Vector3.ZERO
	f._wish = Vector3.RIGHT
	f.forward = Vector3.RIGHT
	first.position = Vector3(4, 7, 0)
	next.position = Vector3(-4, 7, 0)
	camera.position = Vector3(0, 4.25, 8)
	camera.look_at(Vector3(0, 4.25, 0))
	helper.setup(camera, true)
	await physics_frame
	var candidate: Dictionary = helper.capture(f, false)
	var center_axis: Vector3 = -camera.global_basis.z
	var angle: float = rad_to_deg(acos(center_axis.dot((first.position - camera.position).normalized())))
	check(angle > 10.0 and candidate.target_id == String(first.get_path()), "action assistance selects visible off-center anchor along movement")
	f._wish = Vector3.LEFT
	# T8 Г (P7): a still-valid target may be replaced only 0.25 s after the last change, so each switch waits it out.
	check(helper.capture(f, false).target_id == String(first.get_path()), "a new travel direction does not replace a valid target inside 0.25 s")
	await switch_delay()
	check(helper.capture(f, false).target_id == String(next.get_path()), "changing travel direction replaces opposite-side sticky target")
	f._wish = Vector3.RIGHT
	camera.look_at(next.position)
	helper.apply_look(Vector2(0.001, 0.0))
	await switch_delay()
	check(helper.capture(f, false).target_id == String(next.get_path()), "explicit orbit overrides movement preference")
	helper.reset()
	camera.look_at(first.position)
	next.position = first.position + Vector3(0, 0, 0.05)
	candidate = helper.capture(f, false)
	var remembered: String = candidate.target_id
	first.position.z += 0.03
	next.position.z -= 0.03
	check(helper.capture(f, false, false).target_id == remembered, "small score crossover preserves visible preview target")
	next.position = Vector3(60, 7, 0)
	first.position = Vector3(4, 7, 0)
	# Three separate invalidation classes: hand obstruction, camera obstruction, range.
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 0.8, 0.8)
	shape.shape = box
	wall.add_child(shape)
	root.add_child(wall)
	wall.position = (f.position + Hook.HAND).lerp(first.position, 0.5)
	await physics_frame
	check(helper.capture(f, false).target_id.is_empty(), "solid world hand obstruction immediately invalidates assisted candidate")
	check(not f.grapple.line_clear(f.position + Hook.HAND, first.position), "hook and preview agree on layer-one geometry")
	wall.position = camera.position.lerp(first.position, 0.5)
	await physics_frame
	# T8 Г changes this sign by design (06-UI-UX, P3): the camera line is a weight, the hand line stays a hard filter.
	var hidden: Dictionary = helper.capture(f, false)
	check(hidden.target_id == String(first.get_path()) and hidden.camera_hidden, "camera-hidden anchor stays selectable when the hand sees it (T8 decision, sign changed)")
	wall.position = Vector3(50, 50, 50)
	await physics_frame
	check(helper.capture(f, false).target_id == String(first.get_path()), "removing obstruction restores assisted target")
	first.position = Vector3(40, 7, 0)
	check(helper.capture(f, false).target_id.is_empty(), "sticky assisted target cannot survive range invalidation")
	hang()
	wall.position = (f.position + Hook.HAND).lerp(next.position, 0.5)
	await physics_frame
	var stock: int = f.grapple.charges
	check(not f.grapple.retarget(target_packet()) and f.grapple.attached and f.grapple.charges == stock, "solid wall rejects transfer without dropping support or spending")
	f.grapple.detach()
	f.grapple.fire(false, "grapple_parkour", target_packet())
	f.grapple._launch()
	for frame: int in 40:
		f.grapple._flight(1.0 / 60.0, true)
		if f.grapple.phase != Hook.Phase.FLIGHT:
			break
	check(f.grapple.phase == Hook.Phase.MISS_REWIND and f.grapple.token != 0, "solid world collision stops projectile and keeps its token recoverable")
	wall.free()


## 0.25 s (T8 traversal_switch_delay) plus one tick of physics frames.
func switch_delay() -> void:
	for tick: int in roundi(helper.traversal_switch_delay * Engine.physics_ticks_per_second) + 1:
		await physics_frame


func responsive_profile() -> void:
	# Identical input packets exercise the opt-in city profile and legacy duel profile.
	var launch_ticks: Array[int] = []
	var contact_ticks: Array[int] = []
	for city: bool in [false, true]:
		registry.clear_match()
		f.position = Vector3(0, 3, 0)
		f.velocity = Vector3(5, 0, 0)
		f._wish = Vector3.RIGHT
		f.control_locked = false
		first.position = Vector3(4, 9.25, 0)
		next.position = Vector3(40, 9, 0)
		f.grapple.responsive_parkour = city
		var stock: int = f.grapple.charges
		f.grapple.fire(false, "grapple_parkour", {"point": first.position, "target_id": String(first.get_path())})
		var ticks: int = 0
		while f.grapple.phase == Hook.Phase.WINDUP and ticks < 40:
			f.grapple.drive(1.0 / 60.0, true)
			ticks += 1
		launch_ticks.append(ticks)
		check(f.grapple.phase == Hook.Phase.FLIGHT and not f.grapple.attached, "profile launches without an unconfirmed tether city=%s" % city)
		check(f.grapple.charges == stock - 1 and registry.records.size() == 1, "profile launch spends exactly once city=%s" % city)
		check(is_equal_approx(f.velocity.x, 5.0 if city else 0.0), "only opted-in city windup preserves travel speed city=%s" % city)
		while f.grapple.phase == Hook.Phase.FLIGHT and ticks < 70:
			f.grapple.drive(1.0 / 60.0, true)
			ticks += 1
		contact_ticks.append(ticks)
		check(f.grapple.attached and f.grapple.charges == stock - 1, "profile confirms swept contact without spending twice city=%s" % city)
	check(launch_ticks == [30, 10], "city shot responds in 10 ticks while duel remains 30")
	check(contact_ticks[1] < contact_ticks[0], "city initial support arrives sooner on identical target")
	print("RESPONSIVE_ROPE launch_ticks=%s contact_ticks=%s" % [launch_ticks, contact_ticks])
	# City opt-in cannot accelerate an enemy shot or change its startup commitment.
	registry.clear_match()
	f.position = Vector3(0, 3, 0)
	f.velocity = Vector3(5, 0, 0)
	f.grapple.fire(true, "grapple_enemy", {"point": Vector3(0, 4.25, 10), "target_id": ""})
	for tick: int in 29:
		f.grapple.drive(1.0 / 60.0, true)
	check(f.grapple.phase == Hook.Phase.WINDUP and is_zero_approx(f.velocity.x), "city opt-in preserves enemy startup and braking")
	f.grapple.drive(1.0 / 60.0, true)
	var before: Vector3 = f.grapple.projectile_position
	f.grapple._flight(1.0 / 60.0, true)
	check(is_equal_approx(before.distance_to(f.grapple.projectile_position), 0.6), "city enemy projectile keeps 36 m/s")
	registry.clear_match()
	f.grapple.responsive_parkour = false


## The city's E on the rope (see the header). The packet the player saw is set on the helper as the camera publishes it:
## `shown` ticks ago the last target (HarpoonAim.last_target_tick), this tick's packet with or without one.
func city_transfer() -> void:
	if mutation != "none":
		Engine.set_meta("rope_climb_mutation", mutation)
	var city: Node3D = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
	city.set_script(load((get_script() as Script).resource_path.get_base_dir().path_join("rope_climb_fighter.gd")))
	city.data = load("res://data/characters/choko.tres")
	root.add_child(city)
	city.set_physics_process(false)
	var input: Node = root.get_node("InputRouter")
	input.apply_profile("solo", false)
	# Loaded at run time: naming the class in this script would compile it before the autoloads exist.
	var reasons: Array = (load("res://scripts/core/HarpoonAim.gd") as GDScript).get_script_constant_map()["REASONS"]
	var cases := [
		# [label, family, setup, shown ticks ago (−1: this tick's packet shows it), expect let go]
		["shown target, valid: the transfer", "", "valid", -1, false],
		["shown target, occupied (line 97)", "", "occupied", -1, false],
		["shown target, out of range (line 104)", "", "far", -1, false],
		["shown target, stale (line 105)", "", "stale", -1, false],
		["a target shown 3 ticks ago, none now", "flicker", "none", 3, false],
		["a target shown 14 ticks ago, none now: still inside the 15-tick window", "flicker", "none", 14, false],
		["no target shown for 15 ticks: the window is over", "empty", "none", 15, true],
		["no target shown for 20 ticks", "empty", "none", 20, true],
		["empty stock, no rope in 0.70 m (line 101)", "empty", "stock", 20, true],
	]
	for row: Array in cases:
		registry.clear_match()
		first.position = Vector3(0, 9.25, 0)
		next.position = Vector3(5, 9.25, 0)
		city.position = Vector3(0, 3, 0)
		city.velocity = SWING
		city._wish = Vector3.ZERO
		city.control_locked = false
		city.state = Actor.State.GRAPPLE
		var token: int = registry.issue(1)
		registry.deploy(token, 1, first.position, city.position + Hook.HAND, 6.25)
		city.grapple.fire(false, "grapple_parkour")
		var hook: Node = city.grapple
		await physics_frame
		var tag := "city E, %s: " % row[0]
		check(hook.attached and hook._deployed_token == token and hook.climb_enabled, tag + "the city body hangs on the first rope", "count")
		if String(row[2]) == "stock":
			while hook.charges > 0:
				registry.issue(1)
		var now: int = input.frame()
		var target := {"tick": now - 1, "player": 1, "enemy_mode": false, "origin": city.position + Hook.HAND, "point": next.position,
			"target_id": String(next.get_path()), "candidate_kind": "anchor", "rope_token": 0, "reachable": true, "assist": true, "reason": ""}
		var empty := {"tick": now - 1, "player": 1, "enemy_mode": false, "origin": city.position + Hook.HAND, "point": city.position,
			"target_id": "", "candidate_kind": "", "rope_token": 0, "reachable": false, "assist": true, "reason": "no_harpoons" if String(row[2]) == "stock" else "none"}
		helper.published = target if int(row[3]) < 0 else empty
		helper._published_before = helper.published
		helper.last_target_tick = now - 1 if int(row[3]) < 0 else now - int(row[3])
		match String(row[2]):
			"occupied":
				var other_token: int = registry.issue(1)
				registry.deploy(other_token, 1, next.position, next.position + Vector3.DOWN * 5.0, 5.0)
			"far":
				next.position = Vector3(60, 9.25, 0)
			"stale":
				helper.published.target_id = "/root/MissingAnchor"
				helper._published_before = helper.published
				next.position = Vector3(60, 9.25, 0) # the press re-selects once from the hand (T8 Г): nothing there now
			"none", "stock":
				next.position = Vector3(60, 9.25, 0) # the target that was shown is gone: nothing in reach now
		var length: float = hook.rope_length
		var stock: int = hook.charges
		var velocity: Vector3 = city.velocity
		var denied: Array[String] = []
		var on_denied := func(reason: String) -> void: denied.append(reason)
		hook.denied.connect(on_denied)
		input.v_press(1, "grapple_parkour")
		city._tick_grapple(city._read_intent())
		input.v_release(1, "grapple_parkour")
		hook.denied.disconnect(on_denied)
		if String(row[1]) == "flicker":
			# P5: the press kept the hang inside the window and said why (the HUD words the reason, CityHud.HOOK_REASONS).
			check(denied.size() == 1 and denied[0] in reasons, tag + "P5: the kept hang says why: one denied with a HarpoonAim.REASONS code (%s)" % [denied], "denied")
			print("TRAVERSAL P5 %s: denied %s" % [row[0], denied])
		var still: Dictionary = registry.records.get(token, {})
		if String(row[2]) == "valid":
			check(hook.phase == Hook.Phase.FLIGHT and hook.charges == stock - 1, tag + "a shown, valid target is the transfer as before (phase %d)" % hook.phase, "count")
		elif bool(row[4]):
			check(not hook.attached and city.state == Actor.State.JUMP, tag + "E lets go (attached %s, state %d)" % [hook.attached, city.state], String(row[1]))
			check(city.velocity == velocity and velocity != Vector3.ZERO, tag + "the velocity as it was (%s → %s)" % [velocity, city.velocity], "letgo_v")
			check(not still.is_empty() and bool(still.deployed) and hook.charges == stock, tag + "the old rope stays deployed, the stock %d (now %d)" % [stock, hook.charges], String(row[1]))
		else:
			check(hook.attached and hook._deployed_token == token and hook.phase == Hook.Phase.HANG, tag + "the hero still hangs on the first rope (attached %s, phase %d)" % [hook.attached, hook.phase], String(row[1]) if not String(row[1]).is_empty() else "keep")
			check(absf(hook.rope_length - length) <= 0.000001 and hook.charges == stock and city.velocity.length() <= velocity.length() + 0.001, tag + "the length %.4f → %.4f, the stock %d → %d, the speed %.4f → %.4f" % [length, hook.rope_length, stock, hook.charges, velocity.length(), city.velocity.length()], String(row[1]) if not String(row[1]).is_empty() else "keep")
		hook.detach()
	registry.clear_match()
	city.free()
	if Engine.has_meta("rope_climb_mutation"):
		Engine.remove_meta("rope_climb_mutation")
