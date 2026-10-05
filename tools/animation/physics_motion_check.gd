extends SceneTree
## Real CityFighter displacement drives presentation; snapshots never drive physics.
const DT: float = 1.0 / 60.0
var checks: int = 0
var failures: int = 0
var rows: Array[Dictionary] = []
var Actor: Script
var Hook: Script
var f: Node3D

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PHYSICS_MOTION: " + label)

func authority() -> Array:
	return [f.global_transform, f.velocity, f.state, f.hp, f.meter, f.grapple.phase,
		f.grapple.token, f.grapple.rope_length, f.grapple.recovery_remaining, f._rng.state]

func visual() -> void:
	var before: Array = authority()
	f.animator.tick(DT, f, false)
	f.skeletal._physics_process(DT)
	f.skeletal.retarget()
	check(before == authority(), f.data.id + " presentation preserves physics/inventory/RNG")

func sample(label: String, before: Vector3) -> void:
	var step: Vector3 = f.global_position - before
	rows.append({"hero":f.data.id,"case":label,"state":f.state,"phase":f.grapple.phase,
		"speed":f.velocity.length(),"stored_y":f.velocity.y,"real_y":f.get_real_velocity().y,
		"step_xz":Vector2(step.x,step.z).length(),"step_xyz":step.length(),
		"on_ground":f.on_ground(),"floor_normal":[f.get_floor_normal().x,f.get_floor_normal().y,f.get_floor_normal().z],
		"clip":f.skeletal.clip,"gait_speed":f.skeletal.locomotion.speed,"gait_active":f.skeletal.locomotion.active,
		"surface_distance":f.skeletal.motion_signals.distance})

func run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	Hook = load("res://scripts/grapple/GrappleHook.gd")
	var game: Node = root.get_node("GameState")
	game.skeletal_rig = true
	game.free_move = true
	game.water = null
	var input: Node = root.get_node("InputRouter")
	var district: Node3D = load("res://scenes/world/CityDistrict.tscn").instantiate()
	root.add_child(district)
	for hero: String in ["choko", "skea"]:
		f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.set_script(load("res://scripts/world/CityFighter.gd"))
		f.data = load("res://data/characters/" + hero + ".tres")
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		f.restart_at(Vector3.ZERO)
		f.forward = Vector3.RIGHT
		for i: int in 20:
			await physics_frame
			f.state = Actor.State.WALK
			f._walk_physics(DT, f.data.walk_speed, 0)
			visual()
		f.grapple.fire(false, "grapple_parkour", {"target_id":"", "point":f.position + Vector3(0,8,0)})
		f.state = Actor.State.GRAPPLE
		var moving_frames: int = 0
		for i: int in 16:
			await physics_frame
			var before: Vector3 = f.position
			f.grapple.drive(DT, true)
			visual()
			sample("moving_windup", before)
			if f.position.distance_to(before) > 0.003 and f.on_ground():
				moving_frames += 1
				check(f.skeletal.locomotion.moving(), hero + " real windup deceleration keeps moving legs")
				check(not f.skeletal.clip.ends_with("Idle"), hero + " windup lower body is authored travel")
		check(moving_frames >= 8, hero + " windup exercised actual sliding body")
		f.grapple.reset()
		f.restart_at(Vector3.ZERO)
		visual()
		visual()
		var before: Vector3 = f.position
		f.restart_at(Vector3(10,0,0))
		visual()
		sample("checkpoint_teleport", before)
		check(f.skeletal.motion_signals.discontinuous, hero + " real restart marks discontinuity")
		check(f.skeletal.locomotion.speed == 0.0 and f.skeletal.cadence.phase == 0.0, hero + " restart never becomes 600m/s sprint")
		check(f.skeletal.motion_signals.acceleration == Vector3.ZERO, hero + " restart has no inertial impulse")
		check(f.skeletal.clip == f.skeletal.clip_name(f.data.idle_clip), hero + " restart clears sprint entry")
		f.restart_at(Vector3(18,0,8))
		f.forward = Vector3.FORWARD
		var ramp_xyz: float = 0.0
		var ramp_surface: float = 0.0
		var ramp_xz: float = 0.0
		for i: int in 120:
			await physics_frame
			f.state = Actor.State.WALK
			before = f.position
			f._walk_physics(DT, 0, -f.data.walk_speed)
			visual()
			if i > 25 and i < 100:
				sample("ramp_up", before)
				var step: Vector3 = f.position - before
				ramp_xyz += step.length()
				ramp_xz += Vector2(step.x,step.z).length()
				ramp_surface += f.skeletal.motion_signals.distance
				check(f.on_ground(), hero + " ramp sample actually supported")
		check(ramp_xyz > ramp_xz * 1.02, hero + " real ramp distinguishes flattened cadence")
		check(absf(ramp_surface-ramp_xyz) < 0.002, hero + " cadence follows supported slope distance")
		# Production InputRouter -> CityFighter path: accelerate, stop, jump, land.
		f.restart_at(Vector3.ZERO)
		visual()
		input.v_set(1, "right", true)
		for i: int in 24:
			await physics_frame
			f._physics_process(DT)
			visual()
		check(f.skeletal.locomotion.speed > 3.0, hero + " real input accelerates gait")
		# Lifecycle reset while a moving gait is active must also clear its state.
		var moving_position: Vector3 = f.position
		f.restart_at(moving_position)
		visual()
		check(f.skeletal.locomotion.speed == 0.0 and f.skeletal.cadence.phase == 0.0, hero + " restart clears active moving gait")
		input.v_set(1, "right", false)
		for i: int in 30:
			await physics_frame
			f._physics_process(DT)
			visual()
		check(f.skeletal.locomotion.speed < 0.01, hero + " real release stops cadence")
		input.v_press(1, "jump")
		f._physics_process(DT)
		input.v_release(1, "jump")
		var air_frames: int = 0
		for i: int in 90:
			await physics_frame
			f._physics_process(DT)
			visual()
			if f.state == Actor.State.JUMP:
				air_frames += 1
				check(f.skeletal.motion_signals.distance < 0.0001, hero + " vertical air travel never counts as stride")
		check(air_frames > 10 and f.on_ground(), hero + " real input jump and landing exercised")
		if hero == "choko":
			f.place_record()
			var recorded_position: Vector3 = f.record_marker.global_position
			input.v_set(1,"right",true)
			for i: int in 20:
				await physics_frame
				f._physics_process(DT)
				visual()
			input.v_set(1,"right",false)
			check(f.position.distance_to(recorded_position) > 0.5, "rewind fixture has actual travelled distance")
			f.rewind()
			visual()
			check(f.skeletal.motion_signals.discontinuous and f.skeletal.motion_signals.actual_velocity == Vector3.ZERO, "actual Choko rewind discards teleport impulse")
			check(f.skeletal.cadence.phase == 0.0, "actual Choko rewind clears gait history")
		# A real solid blocks held input: intent must not treadmill in place.
		var wall := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.2,4,4)
		shape.shape = box
		wall.add_child(shape)
		district.add_child(wall)
		wall.position = Vector3(2,2,0)
		f.restart_at(Vector3.ZERO)
		visual()
		input.v_set(1,"right",true)
		for i: int in 60:
			await physics_frame
			f._physics_process(DT)
			visual()
			if i > 45:
				check(f.skeletal.locomotion.speed < 0.01, hero + " wall blocks gait despite held input")
		input.v_set(1,"right",false)
		wall.queue_free()
		await physics_frame
		# Miss return uses actual slowed movement and distinct Walk while winding.
		f.restart_at(Vector3.ZERO)
		visual()
		f.grapple.fire(false,"grapple_parkour",{"target_id":"","point":Vector3(0,8,0)})
		f.grapple.projectile_position = Vector3(0,14,0)
		f.grapple._begin_rewind()
		input.v_set(1,"right",true)
		for i: int in 12:
			await physics_frame
			f._physics_process(DT)
			visual()
			if i > 5:
				check(f.grapple.recovering(), hero + " physical miss still winding")
				check(f.skeletal.locomotion.source_clip.begins_with("Walk"), hero + " recovery actual gait is Walk")
		input.v_set(1,"right",false)
		f.queue_free()
		await process_frame
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			var file := FileAccess.open(arg.trim_prefix("--output="),FileAccess.WRITE)
			file.store_string(JSON.stringify(rows,"\t"))
	district.queue_free()
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	# Actual rewind plays an Ogg stream. The mixer retires stopped playback on
	# wall time, even when --fixed-fps accelerates all simulation/timer ticks.
	# Drain after normal audio teardown, as in the existing audio regressions.
	var drain_until_ms: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < drain_until_ms:
		await process_frame
		OS.delay_msec(1)
	print("PHYSICS_MOTION_COMPLETE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
