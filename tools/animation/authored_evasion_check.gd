extends SceneTree
## Whole dodge trajectories, actual hero anatomy and moving-contact cadence.
var checks: int = 0
var failures: int = 0
var Actor: GDScript
var f: Node3D
var ir: Node
var baseline: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("AUTHORED_EVASION: " + label)

func authority() -> Array:
	return [f.position, f.velocity, f.state, f.dash_frames_left, f.dodging, f.dodge_stamina, f.invulnerable_frames, f._rng.state, f.grapple.phase, f.grapple.token, f.hp]

func render_tick() -> void:
	var before: Array = authority()
	f.skeletal._physics_process(1.0 / 60.0)
	f.skeletal._on_mannequin_updated()
	check(before == authority(), "presentation leaves trajectory/timers/stamina/RNG/rope unchanged")

func create_fighter(hero: String) -> void:
	f = load("res://scenes/fighter/Fighter.tscn").instantiate()
	f.data = load("res://data/characters/%s.tres" % hero)
	root.add_child(f)
	f.set_physics_process(false)
	f.skeletal.set_physics_process(false)
	f.control_locked = false
	f.state = Actor.State.IDLE
	f._rng.seed = 128
	ir.v_clear(1)

func run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	var gs: Node = root.get_node("GameState")
	gs.skeletal_rig = true
	gs.free_move = true
	gs.water = null
	ir = root.get_node("InputRouter")
	ir.apply_profile("solo", false)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	shape.shape = box
	ground.position.y = -0.5
	ground.add_child(shape)
	root.add_child(ground)
	for hero: String in ["choko", "skea"]:
		for yaw: float in [0.0, PI * 0.5]:
			for air: bool in [false, true]:
				for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
					for present: bool in [false, true]:
						create_fighter(hero)
						f._set_forward(Vector3.RIGHT.rotated(Vector3.UP, yaw))
						for frame: int in 12:
							await physics_frame
							f._physics_process(1.0 / 60.0)
							if present:
								render_tick()
						if air:
							f.position.y = 2.0
							f.velocity.y = -1.0
							f.state = Actor.State.JUMP
							f.move_and_slide()
						f._wish = f.forward * direction.x + f.forward.cross(Vector3.UP) * direction.y
						check(f._start_dodge(1.0), hero + " real dodge accepted")
						var key: String = "%s_%s_%s_%s" % [hero, yaw, air, direction]
						var rows: Array = []
						for frame: int in f.dodge_profile().frames + 18:
							await physics_frame
							f._physics_process(1.0 / 60.0)
							if present:
								render_tick()
								var sk = f.skeletal
								if f.dodging:
									check(sk.clip in [sk.clip_name("Dodge_Left"), sk.clip_name("Dodge_Right")] and not sk.uses_procedural_motion(), "real authored dodge replaces idle capsule fallback")
									check(sk.clip_pos >= 0.0 and sk.clip_pos <= 0.70, "sample is bounded active source segment")
								for side: String in ["Left", "Right"]:
									for pair: Array in [["UpLeg", "Leg"], ["Leg", "Foot"], ["Arm", "ForeArm"], ["ForeArm", "Hand"]]:
										var a: int = sk.hero_skeleton.find_bone(side + pair[0])
										var b: int = sk.hero_skeleton.find_bone(side + pair[1])
										var rest: float = sk.hero_skeleton.get_bone_global_rest(a).origin.distance_to(sk.hero_skeleton.get_bone_global_rest(b).origin)
										var posed: float = sk.hero_skeleton.get_bone_global_pose(a).origin.distance_to(sk.hero_skeleton.get_bone_global_pose(b).origin)
										check(absf(posed - rest) < 0.01, "actual hero limbs retain length")
								if frame == 5:
									var held: Array[Transform3D] = sk._bone_poses()
									var held_time: float = sk.clip_pos
									for field: String in ["frozen_frames", "hitstop_frames"]:
										f.set(field, 3)
										sk._physics_process(1.0 / 60.0)
										sk._on_mannequin_updated()
										check(held == sk._bone_poses() and held_time == sk.clip_pos, "freeze and hitstop preserve authored pose/time exactly")
										f.set(field, 0)
								var pose: Transform3D = sk.hero_skeleton.get_bone_global_pose(sk.hero_skeleton.find_bone("Hips"))
								sk.retarget()
								check(pose.is_equal_approx(sk.hero_skeleton.get_bone_global_pose(sk.hero_skeleton.find_bone("Hips"))), "retarget same frame idempotent")
							rows.append(authority())
						if present:
							check(rows == baseline[key], hero + " entire physics trajectory equals no-presentation control " + key)
						else:
							baseline[key] = rows
						f.free()
		create_fighter(hero)
		f.state = Actor.State.GRAPPLE
		f.position.y = 2.0
		f.grapple.attached = true
		f.grapple.phase = f.grapple.Phase.HANG
		f.grapple.anchor_point = Vector3(0, 5, 0)
		render_tick()
		check(f._start_dodge(1.0), "rope release accepts actual dodge")
		check(not f.grapple.attached, "existing authority detaches rope before authored dodge")
		render_tick()
		f.dash_frames_left = f.dodge_profile().frames / 2
		render_tick()
		f._set_state(Actor.State.HITSTUN)
		render_tick()
		check(f.skeletal.authored_dodge._return.is_empty() and not f.skeletal.clip.contains("Dodge"), "reaction interrupts dodge settle immediately")
		f.free()
		# Moving landing on physical ground retains the moving authored gait ankles.
		create_fighter(hero)
		f.state = Actor.State.JUMP
		f.position = Vector3(0, 1.3, 0)
		f.velocity = Vector3(4, -2, 0)
		var saw_contact: bool = false
		var saw_drop: bool = false
		for frame: int in 70:
			await physics_frame
			if f.state == Actor.State.JUMP:
				f._physics_process(1.0 / 60.0)
			else:
				# Keep genuine ground displacement while observing the presentation window.
				f.state = Actor.State.WALK
				f.velocity = Vector3(4, 0, 0)
				f.move_and_slide()
			render_tick()
			var sk = f.skeletal
			if sk.locomotion.moving_landing_phase() >= 0.0:
				saw_contact = true
				check(f.is_on_floor() and sk.locomotion.moving(), "landing only overlays physically grounded moving gait")
				check(sk.authored_landing.last_foot_error < 0.001, "contact preserves this frame's moving actual hero ankles under 1mm")
				check(sk.authored_landing.last_drop <= 0.1001, "hip contact stays within bounded compression")
				saw_drop = saw_drop or sk.authored_landing.last_drop > 0.02
		check(saw_contact and saw_drop, hero + " real moving contact has a visible authored compression")
		check(f.skeletal.authored_landing.last_drop == 0.0, "landing finishes cleanly into gait")
		f.free()
	ground.queue_free()
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("AUTHORED_EVASION_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
