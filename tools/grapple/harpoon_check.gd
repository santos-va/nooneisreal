extends SceneTree
## Real physics-space sweeps; no graphical pose is used as hit authority.
var checks: int = 0
var failures: int = 0
var f: Node3D
var victim: Node3D
var anchor: Node3D
var cover: StaticBody3D
var actor: GDScript
var hook: GDScript
var layout: GDScript
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HARPOON: " + label)
func fixture() -> void:
	f.grapple.registry.clear_match()
	f.grapple.reset()
	f.position = Vector3.ZERO
	f.velocity = Vector3.ZERO
	f.forward = Vector3.RIGHT
	f.facing = 1
	f.state = actor.State.GRAPPLE
	f.control_locked = true
	f._wish = Vector3.ZERO
	victim.position = Vector3(6, 0, 0)
	victim.velocity = Vector3.ZERO
	victim.state = actor.State.IDLE
	victim.invulnerable_frames = 0
	anchor.position = Vector3(50, 5, 0)
	cover.position = Vector3(50, 1, 0)
func launch(enemy: bool = true) -> void:
	f.grapple.fire(enemy)
	for n: int in 30:
		f.grapple.drive(1.0 / 60.0, true)
func flight(held: bool = true) -> void:
	for n: int in 35:
		await physics_frame
		f.grapple.drive(1.0 / 60.0, held)
		if f.grapple.phase != hook.Phase.FLIGHT:
			break
func _run() -> void:
	await process_frame
	actor = load("res://scripts/fighter/Fighter.gd")
	hook = load("res://scripts/grapple/GrappleHook.gd")
	layout = load("res://scripts/arena/ArenaLayout.gd")
	root.get_node("GameState").free_move = true
	root.get_node("GameState").skeletal_rig = false
	var scene := load("res://scenes/fighter/Fighter.tscn") as PackedScene
	f = scene.instantiate()
	f.data = load("res://data/characters/choko.tres")
	root.add_child(f)
	f.set_physics_process(false)
	victim = scene.instantiate()
	victim.data = f.data
	victim.player_index = 2
	root.add_child(victim)
	victim.set_physics_process(false)
	f.opponent = victim
	victim.opponent = f
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position.y = -0.5
	root.add_child(floor_body)
	cover = StaticBody3D.new()
	cover.collision_layer = layout.COVER_LAYER
	var cover_shape := CollisionShape3D.new()
	var wall := BoxShape3D.new()
	wall.size = Vector3(0.3, 4, 4)
	cover_shape.shape = wall
	cover.add_child(cover_shape)
	root.add_child(cover)
	anchor = Node3D.new()
	root.add_child(anchor)
	anchor.add_to_group("grapple_anchor")
	fixture()
	await physics_frame
	f.grapple.fire(true)
	for n: int in 29:
		f.grapple.drive(1.0 / 60.0, true)
	check(f.grapple.phase == hook.Phase.WINDUP and f.grapple.charges == f.grapple.max_charges, "29 frames neither launch nor spend")
	f._set_state(actor.State.HITSTUN)
	check(not f.grapple.busy() and f.grapple.charges == f.grapple.max_charges, "interruption cancels without spending")
	fixture()
	await physics_frame
	launch()
	check(f.grapple.phase == hook.Phase.FLIGHT and f.grapple.charges == f.grapple.max_charges - 1, "frame 30 launches and spends once")
	await flight()
	check(victim.state == actor.State.HITSTUN and victim.velocity.x < 0, "actual hurtbox hit starts kinematic pull")
	fixture()
	await physics_frame
	launch()
	victim.position.z = 3
	await physics_frame
	await flight()
	check(victim.state == actor.State.IDLE and f.grapple.charges == f.grapple.max_charges - 1, "dodge after launch misses and spends")
	check(f.grapple.phase == hook.Phase.MISS_REWIND and f.grapple._flight_distance <= f.grapple.range_m, "miss enters rewind at maximum range")
	fixture()
	cover.position = Vector3(3, 1, 0)
	await physics_frame
	launch()
	await flight()
	check(victim.state == actor.State.IDLE and f.grapple.recovering(), "first cover intercepts before victim")
	fixture()
	victim.position.x = 16
	await physics_frame
	launch()
	await flight()
	check(victim.state == actor.State.IDLE, "out of range cannot pull")
	fixture()
	victim.invulnerable_frames = 60
	await physics_frame
	launch()
	await flight()
	check(victim.state == actor.State.IDLE, "invulnerable hurtbox cannot pull")
	fixture()
	anchor.position = Vector3(4, 5, 0)
	victim.position.z = 10
	await physics_frame
	launch(false)
	await flight()
	check(f.grapple.attached, "anchor requires projectile arrival")
	var length_before: float = f.grapple.rope_length
	for n: int in 40:
		f.grapple.drive(1.0 / 60.0, true)
	check(f.grapple.attached and is_equal_approx(length_before, f.grapple.rope_length), "neutral hold stays attached without reeling on ground")
	# Move the real attached fixture into the air and measure the constraint.
	f.position = Vector3(1, 2, 0)
	f.velocity = Vector3.ZERO
	f.grapple.rope_length = (f.grapple.anchor_point - (f.position + hook.HAND)).length()
	f.grapple._hang_start_length = f.grapple.rope_length
	length_before = f.grapple.rope_length
	for n: int in 20:
		f.grapple.drive(1.0 / 60.0, true)
	check(f.grapple.attached and is_equal_approx(length_before, f.grapple.rope_length), "suspended neutral hold preserves length")
	check((f.grapple.anchor_point - (f.position + hook.HAND)).length() <= length_before + 0.03, "suspended body respects rope constraint")
	f.control_locked = false
	f._wish = Vector3.BACK
	var old_z: float = f.velocity.z
	f.grapple.drive(1.0 / 60.0, true)
	check(f.velocity.z > old_z and is_equal_approx(length_before, f.grapple.rope_length), "sideways input accelerates tangent without reeling")
	var toward: Vector3 = f.grapple.anchor_point - (f.position + hook.HAND)
	f._wish = Vector3(toward.x, 0, toward.z).normalized()
	f.grapple.drive(1.0 / 60.0, true)
	check(is_equal_approx(f.grapple.rope_length, length_before), "toward-anchor movement does not silently reel")
	f.grapple.drive(1.0 / 60.0, true, true)
	check(f.grapple.rope_length < length_before, "Space explicitly reels")
	f.grapple.drive(1.0 / 60.0, false)
	check(not f.grapple.busy(), "button release detaches")
	fixture()
	anchor.position = Vector3(4, 5, 0)
	victim.position.z = 10
	await physics_frame
	launch(false)
	await flight()
	cover.position = (f.position + hook.HAND + anchor.position) * 0.5
	await physics_frame
	f.grapple.drive(1.0 / 60.0, true)
	check(not f.grapple.busy(), "cover cutting an attached rope detaches")
	fixture()
	anchor.position = Vector3(4, 5, 0)
	await physics_frame
	launch(false)
	await flight(false)
	check(not f.grapple.attached and not f.grapple.busy(), "tap released before arrival creates no hidden tether")
	fixture()
	var ir: Node = root.get_node("InputRouter")
	f.control_locked = false
	f.state = actor.State.IDLE
	ir.v_clear(1)
	ir.v_press(1, "grapple")
	check(f._try_grapple(true) and f.state == actor.State.GRAPPLE, "real buffered action enters windup")
	for n: int in 29:
		f._tick_grapple(f._read_intent())
	check(f.grapple.phase == hook.Phase.WINDUP and f.grapple.charges == f.grapple.max_charges, "Fighter dispatch preserves 30 frame windup")
	f._tick_grapple(f._read_intent())
	check(f.grapple.phase == hook.Phase.FLIGHT, "Fighter dispatch launches on frame 30")
	f._set_state(actor.State.HITSTUN)
	check(f.grapple.phase == hook.Phase.MISS_REWIND, "post-launch hitstun retains recoverable token")
	ir.v_clear(1)
	fixture()
	f.grapple.fire(true)
	f.freeze(10)
	check(not f.grapple.busy() and f.grapple.charges == f.grapple.max_charges, "freeze cancels windup")
	f.frozen_frames = 0
	f.grapple.reset()
	check(f.grapple.charges == f.grapple.max_charges and not f.grapple.busy() and not f.grapple._tip.visible, "reset removes projectile and state")
	# Match inventory: real parkour contact deploys one immutable owner token.
	fixture()
	anchor.position = Vector3(4, 5, 0)
	victim.position.z = 10
	await physics_frame
	launch(false)
	await flight()
	var registry: Node = f.grapple.registry
	var deployed: int = f.grapple._deployed_token
	check(deployed != 0 and registry.records[deployed].deployed, "parkour contact creates match-owned deployment")
	registry._physics_process(1.0 / 60.0)
	check(not registry.records[deployed].visual.visible, "held rope has no duplicate persistent visual")
	check(registry.records[deployed].tail.y < registry.records[deployed].anchor.y, "released endpoint hangs below anchor")
	check(f.grapple.charges + registry.owned(1) == f.grapple.max_charges, "deployment conserves owner inventory")
	f.reset_for_round(0.0, 1)
	check(registry.records.has(deployed) and f.grapple.charges == f.grapple.max_charges - 1, "actual Fighter round reset preserves deployment and spent inventory")
	f.position = registry.records[deployed].tail - hook.HAND
	var manual_front := {"point": f.position + hook.HAND + Vector3.RIGHT * 8, "target_id": "", "manual": true}
	check(f.grapple.fire(false, "grapple_parkour", manual_front) == hook.Target.ANCHOR and f.grapple.phase == hook.Phase.HANG and f.grapple._deployed_token == deployed, "nearby existing rope has priority over an unbound shot")
	f.grapple.reset()
	f.position = registry.records[deployed].anchor + Vector3.DOWN * (registry.records[deployed].length + 0.5) - hook.HAND
	check(f.grapple.reusable_rope() == 0, "reuse rejects reach beyond original rope length")
	victim.position = registry.records[deployed].tail - hook.HAND
	victim.state = actor.State.IDLE
	var foreign_before: int = victim.grapple.charges
	check(victim.grapple.fire(false, "grapple_parkour") == hook.Target.ANCHOR and victim.grapple.attached, "other player reattaches nearby existing rope")
	check(victim.grapple.charges == foreign_before and registry.records.size() == 1, "foreign reattach creates no token and costs nothing")
	check(not registry.refund(deployed, 2) and not registry.refund(deployed, 1), "neither user nor owner can refund a deployed rope")
	for n: int in f.grapple.charges:
		registry.issue(1)
	f.position = registry.records[deployed].tail - hook.HAND
	check(f.grapple.charges == 0 and f.grapple.fire(false, "grapple_parkour") == hook.Target.ANCHOR, "empty inventory still permits nearby rope reuse")
	check(victim.grapple.attached and f.grapple.attached, "both users may share one deployed rope without ownership transfer")
	registry.clear_match()
	check(registry.records.is_empty() and f.grapple.charges == f.grapple.max_charges and not victim.grapple.busy(), "new match clears registry and all users")
	# Length-based miss rewind survives hit/dodge and refunds exactly once.
	fixture()
	victim.position.z = 10
	await physics_frame
	launch()
	await flight()
	var remaining: float = f.grapple.recovery_remaining
	f.state = actor.State.DASH
	for n: int in 20:
		f.grapple.tick_regen(1.0 / 60.0, false)
	check(is_equal_approx(remaining, f.grapple.recovery_remaining), "dodge preserves remaining rewind length")
	f.state = actor.State.HITSTUN
	for n: int in 20:
		f.grapple.tick_regen(1.0 / 60.0, false)
	check(is_equal_approx(remaining, f.grapple.recovery_remaining), "hitstun preserves remaining rewind length")
	for incapacitated: int in [actor.State.STUMBLE, actor.State.WALL_SPLAT]:
		f.state = incapacitated
		f.grapple.tick_regen(1.0 / 60.0, false)
		check(is_equal_approx(remaining, f.grapple.recovery_remaining), "incapacitation preserves remaining rewind length " + str(incapacitated))
	f.state = actor.State.IDLE
	for n: int in 140:
		f.grapple.tick_regen(1.0 / 60.0, false)
	check(not f.grapple.busy() and f.grapple.charges == f.grapple.max_charges and registry.records.is_empty(), "rewind completes and returns its unique token")
	f.grapple._return_token()
	check(f.grapple.charges == f.grapple.max_charges, "duplicate return cannot increase capacity")
	# Enemy recovery allows a real kick and blocks/consumes hand intent.
	fixture()
	await physics_frame
	launch()
	await flight()
	check(f.grapple.phase == hook.Phase.ENEMY_EXTRACT, "confirmed enemy hit enters extraction")
	f.state = actor.State.IDLE
	f.control_locked = false
	ir.v_clear(1)
	ir.v_press(1, "left_hand")
	check(not f._try_limb_attack(false), "extraction blocks hands")
	ir.v_clear(1)
	ir.v_press(1, "right_leg")
	f.grapple._extract_frames = f.grapple.extract_duration_frames - 1
	check(f._try_limb_attack(false), "extraction permits a real leg attack")
	f.grapple.tick_regen(1.0 / 60.0, false)
	check(f.grapple.phase == hook.Phase.ENEMY_EXTRACT and f.grapple.charges == f.grapple.max_charges - 1, "late kick startup prevents ordinary timer refund before contact")
	f.move_frame = f.current_move.startup
	f._tick_attack(1.0 / 60.0)
	check(f.grapple.charges == f.grapple.max_charges and f.grapple.extract_flash > 0.0, "first active kick frame extracts and refunds once")
	f.grapple.extract_on_kick()
	check(f.grapple.charges == f.grapple.max_charges, "repeat kick event cannot duplicate inventory")
	fixture()
	await physics_frame
	launch()
	check(f.grapple.charges == f.grapple.max_charges - 1, "unfinished flight owns one token")
	f.reset_for_round(0.0, 1)
	f.reset_for_round(0.0, 1)
	check(registry.records.is_empty() and f.grapple.charges == f.grapple.max_charges, "repeated actual round reset refunds unfinished flight once")
	fixture()
	await physics_frame
	launch()
	var replacement: Node = scene.instantiate()
	replacement.data = f.data
	replacement.player_index = 1
	root.add_child(replacement)
	replacement.set_physics_process(false)
	check(not f.grapple.busy() and f.grapple.token == 0 and registry.records.is_empty(), "fighter replacement invalidates old live hook and its issued token")
	check(replacement.grapple.charges == replacement.grapple.max_charges, "replacement receives conserved recovered inventory")
	replacement.queue_free()
	registry.register_hook(f.grapple, 1, f.grapple.max_charges)
	# Replay intent is sufficient without a camera and cannot retarget mid-flight.
	fixture()
	await physics_frame
	var replay := {"point": Vector3(0, 1.25, 10), "target_id": "", "manual": true}
	f.grapple.fire(true, "grapple_enemy", replay)
	for n: int in 30:
		f.grapple.drive(1.0 / 60.0, true)
	check(f.grapple._flight_direction.z > 0.99, "recorded aim launches identically without decorative camera")
	check(f.grapple.charges + registry.owned(1) == f.grapple.max_charges, "recorded launch conserves inventory")
	f.grapple.registry.queue_free()
	f.queue_free()
	victim.queue_free()
	anchor.queue_free()
	cover.queue_free()
	floor_body.queue_free()
	await process_frame
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("HARPOON_CHECK checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
