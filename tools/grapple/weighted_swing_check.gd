extends SceneTree
## Behavioural regression: motor budget, pendulum energy and shared attachment ownership.
var checks: int = 0
var failures: int = 0
var f: Node3D
var other: Node3D
var anchor: Node3D
var Hook: GDScript
var Actor: GDScript
var registry: Node3D

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("WEIGHTED_SWING: " + label)

func hang(length: float) -> void:
	registry.clear_match()
	f.position = Vector3(0, 3, 0)
	f.velocity = Vector3.ZERO
	f._wish = Vector3.ZERO
	f.control_locked = false
	f.state = Actor.State.GRAPPLE
	anchor.position = f.position + Hook.HAND + Vector3.UP * length
	var token: int = registry.issue(1)
	registry.deploy(token, 1, anchor.position, f.position + Hook.HAND, length)
	f.grapple.fire(false)

func energy() -> float:
	var bottom: float = f.grapple.anchor_point.y - f.grapple.rope_length
	return 0.5 * f.velocity.length_squared() + Actor.GRAVITY * (f.position.y + Hook.HAND.y - bottom)

func _run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	Hook = load("res://scripts/grapple/GrappleHook.gd")
	var state: Node = root.get_node("GameState")
	state.free_move = true
	state.skeletal_rig = false
	state.water = null
	var scene := load("res://scenes/fighter/Fighter.tscn") as PackedScene
	f = scene.instantiate()
	f.data = load("res://data/characters/choko.tres")
	root.add_child(f)
	f.set_physics_process(false)
	other = scene.instantiate()
	other.data = load("res://data/characters/skea.tres")
	other.player_index = 2
	root.add_child(other)
	other.set_physics_process(false)
	other.position = Vector3(50, 0, 0)
	registry = f.grapple.registry
	registry.set_physics_process(false)
	anchor = Node3D.new()
	root.add_child(anchor)
	anchor.add_to_group("grapple_anchor")
	await physics_frame
	hang(6.0)
	var start_y: float = f.position.y
	var input: Node = root.get_node("InputRouter")
	input.v_set(1, "jump", true)
	for frame: int in 120:
		f._tick_grapple(f._read_intent())
	input.v_clear(1)
	check(f.grapple.attached, "Space alone keeps the attached rope")
	check(f.position.y > start_y + 1.0 and f.position.y < start_y + 1.25, "Space lifts from rest without movement, bounded to 1.2 m")
	var held_length: float = f.grapple.rope_length
	for frame: int in 180:
		f.grapple.drive(1.0 / 60.0, false, true)
	check(is_equal_approx(held_length, f.grapple.rope_length), "continued Space cannot reel indefinitely")
	check(absf(f.velocity.y) < 0.02, "reel correction does not become inward spring momentum")
	f.grapple.drive(1.0 / 60.0, false, false)
	check(not f.grapple.attached, "both released detaches")
	for length: float in [2.2, 8.0]:
		hang(length)
		f.velocity = Vector3(3.0, 0, 0)
		var previous_energy: float = energy()
		var passive_ok: bool = true
		for frame: int in 240:
			f.grapple.drive(1.0 / 60.0, true)
			var measured: float = energy()
			passive_ok = passive_ok and measured <= previous_energy + 0.03
			previous_energy = measured
		check(passive_ok, "unpowered short/long pendulum dissipates energy %.1f" % length)
		hang(length)
		var below_anchor: bool = true
		var bounded: bool = true
		var constrained: bool = true
		for frame: int in 600:
			f._wish = Vector3.RIGHT if f.velocity.x >= 0 else Vector3.LEFT
			f.grapple.drive(1.0 / 60.0, true, true)
			below_anchor = below_anchor and f.position.y + Hook.HAND.y < anchor.position.y
			bounded = bounded and f.velocity.length() <= 11.001
			constrained = constrained and (f.position + Hook.HAND).distance_to(anchor.position) <= f.grapple.rope_length + 0.03
		check(below_anchor and bounded and constrained, "sustained pumping plus Space cannot orbit/run away %.1f" % length)
		var speed: float = f.velocity.length()
		f.grapple.drive(1.0 / 60.0, false)
		check(f.velocity.length() <= speed + 0.001, "release cannot manufacture speed %.1f" % length)
	# Render attachment offsets must not turn physical tension into spare cable.
	hang(6.0)
	var hand_rig = load("res://scripts/fighter/SkeletalRig.gd").new()
	f.add_child(hand_rig)
	var hand_skeleton := Skeleton3D.new()
	hand_skeleton.add_bone("RightHand")
	hand_rig.add_child(hand_skeleton)
	hand_rig.hero_skeleton = hand_skeleton
	f.skeletal = hand_rig
	for offset: Vector3 in [Vector3(0, 2.1, 0), Vector3(0.6, 0.9, 0.3), Vector3(-0.5, 1.8, -0.4)]:
		hand_rig.position = offset
		f.grapple._draw_rope(f.position + Hook.HAND, anchor.position)
		var cable = f.grapple._rope_visual
		check(cable.points[0].is_equal_approx(hand_rig.global_position), "render line follows actual hand")
		var straight: bool = true
		for i: int in cable.points.size():
			straight = straight and cable.points[i].distance_to(hand_rig.global_position.lerp(anchor.position, float(i) / (cable.points.size() - 1))) < 0.0001
		check(straight, "animated hand offset cannot invent slack under load")
	# Moving toward the anchor really does create slack; it must still fall.
	f.position.y += 1.0
	for frame: int in 60:
		f.grapple._draw_rope(f.position + Hook.HAND, anchor.position)
	var loose = f.grapple._rope_visual
	var sag: float = 0.0
	for i: int in loose.points.size():
		sag = maxf(sag, loose.points[i].distance_to(hand_rig.global_position.lerp(anchor.position, float(i) / (loose.points.size() - 1))))
	check(sag > 0.01, "physical slack remains deformable")
	f.skeletal = null
	hand_rig.free()
	# Occupancy is shared across players, checked at contact, and leaves a recoverable token.
	hang(6.0)
	var second: int = registry.issue(2)
	check(not registry.deploy(second, 2, anchor.position, other.position, 6.0), "second owner cannot deploy at occupied point")
	check(not registry.deploy(second, 2, anchor.position + Vector3(0.02, 0, 0), other.position, 6.0), "coincident marker does not bypass occupancy")
	check(not registry.records[second].deployed and registry.refund(second, 2) and not registry.refund(second, 2), "rejected deploy refunds exactly once")
	f.grapple.reset()
	check(registry.occupied(anchor.position) and f.grapple.best_anchor() == null, "round reset preserves occupied anchor; automatic new aim excludes it")
	var available: int = f.grapple.charges
	var intent := {"point": anchor.position, "target_id": String(anchor.get_path())}
	f.position = Vector3(5, 3, 0)
	check(f.grapple.fire(false, "grapple_parkour", intent) == Hook.Target.NONE and f.grapple.charges == available, "stale recorded occupied aim is refused before spending")
	# A shot launched earlier than the competing deployment must rewind after arrival.
	other.position = Vector3(0, 3, 0)
	var racing: int = registry.issue(2)
	other.grapple.token = racing
	other.grapple._selected_anchor = anchor
	other.grapple._flight_direction = Vector3.UP
	other.grapple.projectile_position = anchor.position + Vector3.DOWN * 0.2
	other.grapple.phase = Hook.Phase.FLIGHT
	other.grapple._flight_distance = 0.0
	other.grapple._flight(1.0 / 60.0, true)
	check(other.grapple.phase == Hook.Phase.MISS_REWIND and registry.records.has(racing) and not registry.records[racing].deployed, "in-flight race enters visible recoverable rewind")
	other.grapple.reset()
	other.position = registry.records.values()[0].tail - Hook.HAND
	var stock: int = other.grapple.charges
	other.grapple.fire(false)
	check(other.grapple.attached and other.grapple.charges == stock and registry.records.size() == 1, "foreign reuse retains stock and one shared rope")
	registry.clear_match()
	check(registry.records.is_empty() and not other.grapple.attached and not registry.occupied(anchor.position), "new match clears users, stock and occupancy")
	anchor.free()
	f.free()
	other.free()
	registry.free()
	await process_frame
	# Release the audio servers' streaming decoders before the tree exits.
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("WEIGHTED_SWING_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
