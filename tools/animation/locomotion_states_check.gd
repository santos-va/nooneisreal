extends SceneTree
## Grounded selection, authored sprint/jump phases, recovery isolation and braking invariants.
var checks: int = 0
var failures: int = 0
var Actor: GDScript
var Hook: GDScript
var f: Node3D
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("LOCOMOTION: " + label)
func _initialize() -> void:
	run.call_deferred()
func step(speed: float, state: int) -> void:
	f.state = state
	f.velocity = Vector3(speed, 0, 0)
	f.position.x += speed / 60.0
	var authority: Array = [f.transform, f.velocity, f.state, f.hp, f.grapple.phase, f.grapple.token]
	f.animator.tick(1.0 / 60.0, f, false)
	f.skeletal._physics_process(1.0 / 60.0)
	f.skeletal.retarget()
	check(authority == [f.transform, f.velocity, f.state, f.hp, f.grapple.phase, f.grapple.token], "animation never changes authority")
func run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	Hook = load("res://scripts/grapple/GrappleHook.gd")
	var gs: Node = root.get_node("GameState")
	gs.skeletal_rig = true
	gs.free_move = true
	gs.water = null
	var ground := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(300, 1, 30)
	collision.shape = box
	ground.add_child(collision)
	ground.position.y = -0.5
	root.add_child(ground)
	for id: String in ["choko", "skea"]:
		f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.data = load("res://data/characters/%s.tres" % id)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		f.forward = Vector3.RIGHT
		var sk = f.skeletal
		for source: String in ["Walk_Loop", "Jog_Fwd_Loop", "Sprint_Enter", "Sprint_Loop", "Sprint_Exit", "Jump_Start", "Jump_Loop", "Jump_Land"]:
			check(not sk.clip_name(source).is_empty(), source + " is a real installed source")
		step(0.0, Actor.State.IDLE)
		for frame: int in 20:
			step(1.5, Actor.State.WALK)
		check(sk.clip == sk.clip_name("Walk_Loop"), id + " slow movement uses authored Walk")
		f.grapple.phase = Hook.Phase.MISS_REWIND
		f.grapple.recovery_remaining = 10.0
		f.grapple.projectile_position = f.position + Vector3(5, 1, 0)
		for frame: int in 30:
			f.grapple.recovery_progress = frame / 30.0
			step(f.data.walk_speed * f.grapple.recovery_move_scale, Actor.State.WALK)
		check(sk.clip == sk.clip_name("Walk_Loop"), id + " full recovery speed never becomes slowed Jog")
		check(is_equal_approx(sk.player.speed_scale, 1.0), id + " winding never scales global playback")
		var leg: int = sk.skeleton.find_bone("thigh_l")
		var arm: int = sk.skeleton.find_bone("lowerarm_r")
		var winding_leg: Transform3D = sk.skeleton.get_bone_pose(leg)
		var winding_arm: Transform3D = sk.skeleton.get_bone_pose(arm)
		sk.player.seek(sk.clip_pos, true)
		check(winding_leg.is_equal_approx(sk.skeleton.get_bone_pose(leg)), id + " recovery preserves authored walking legs")
		check(not winding_arm.is_equal_approx(sk.skeleton.get_bone_pose(arm)), id + " independent upper-body winding is visible")
		f.grapple.phase = Hook.Phase.IDLE
		for frame: int in 20:
			step(f.data.walk_speed, Actor.State.WALK)
		check(sk.clip == sk.clip_name("Jog_Fwd_Loop"), id + " ordinary combat speed uses Jog")
		step(10.0, Actor.State.WALK)
		check(sk.clip == sk.clip_name("Sprint_Enter"), id + " acceleration enters authored Sprint")
		for frame: int in 20:
			step(10.0, Actor.State.WALK)
		check(sk.clip == sk.clip_name("Sprint_Loop"), id + " fast movement has distinct authored Sprint")
		step(5.0, Actor.State.IDLE)
		check(sk.clip == sk.clip_name("Sprint_Exit"), id + " braking enters authored Sprint exit")
		for frame: int in 15:
			step(1.2, Actor.State.IDLE)
		check(sk.clip == sk.clip_name("Walk_Loop") and sk.locomotion.moving(), id + " IDLE braking still walks while body travels")
		for frame: int in 20:
			step(0.0, Actor.State.IDLE)
		check(not sk.locomotion.moving() and sk.clip == sk.clip_name(f.data.idle_clip), id + " stationary body settles into stance")
		var phase: float = sk.cadence.phase
		f.velocity = Vector3(5, 0, 0)
		f.state = Actor.State.WALK
		for frame: int in 12:
			sk._physics_process(1.0 / 60.0)
		check(is_equal_approx(sk.cadence.phase, phase), id + " blocked body has no treadmill cadence")
		check(sk.clip == sk.clip_name(f.data.idle_clip), id + " blocked WALK cannot fall back to time-driven Jog")
		f.state = Actor.State.JUMP
		f.velocity = Vector3(0, 5, 0)
		sk._physics_process(1.0 / 60.0)
		check(sk.clip == sk.clip_name("Jump_Start"), id + " takeoff uses authored start")
		for frame: int in 10:
			sk._physics_process(1.0 / 60.0)
		check(sk.clip == sk.clip_name("Jump_Loop"), id + " ascent transitions into airborne loop")
		f.position.y = 0.0
		f.velocity = Vector3.DOWN
		await physics_frame
		f.move_and_slide()
		f.state = Actor.State.IDLE
		f.velocity = Vector3.ZERO
		sk._physics_process(1.0 / 60.0)
		check(f.on_ground() and sk.clip == sk.clip_name("Jump_Land"), id + " actual ground contact triggers authored landing")
		for frame: int in 20:
			sk._physics_process(1.0 / 60.0)
		check(sk.clip == sk.clip_name(f.data.idle_clip), id + " landing finishes back in stance")
		f.free()
	ground.free()
	print("LOCOMOTION_STATES_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
