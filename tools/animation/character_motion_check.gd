extends SceneTree
## $GODOT_BIN --headless --path game -s $PWD/tools/animation/character_motion_check.gd
var Rig: GDScript
var Fallback: GDScript
var FighterScript: GDScript
var failures: int = 0
var checks: int = 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	await process_frame
	Rig = load("res://scripts/fighter/SkeletalRig.gd")
	Fallback = load("res://scripts/fighter/ProceduralMotionFallback.gd")
	FighterScript = load("res://scripts/fighter/Fighter.gd")
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	var invalid = load("res://scripts/fighter/MoveData.gd").new()
	invalid.id = "record"
	check(not Fallback.supports("skea", invalid), "foreign character rejected")
	invalid.id = "unknown"
	check(not Fallback.supports("choko", invalid), "unknown move rejected")
	invalid.id = "record"
	invalid.anim_clip = "OverhandThrow"
	check(not Fallback.supports("choko", invalid), "authored override rejected by fallback")
	var expected: Array[String] = ["Walk_Loop", "Walk_Fwd_R_Loop", "Walk_R_Loop", "Walk_Bwd_R_Loop", "Walk_Bwd_Loop", "Walk_Bwd_L_Loop", "Walk_L_Loop", "Walk_Fwd_L_Loop"]
	for yaw: float in [0.0, PI / 2.0, PI]:
		var forward = Vector3.RIGHT.rotated(Vector3.UP, yaw)
		for sector in 8:
			var angle: float = sector * PI / 4.0
			var velocity: Vector3 = forward * cos(angle) + forward.cross(Vector3.UP) * sin(angle)
			check(Rig.walk_clip(velocity, forward) == expected[sector], "walk yaw/sector %s/%s" % [yaw, sector])
	for id: String in ["choko", "skea"]:
		var f = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
		f.data = load("res://data/characters/%s.tres" % id)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		var sk = f.skeletal
		for name: String in expected:
			check(not sk.clip_name(name).is_empty(), "imported " + name)
		var fallback_count: int = 0
		for slot: String in ["light", "heavy", "crouch_light", "air_light", "skill1", "skill2", "ultimate", "ultimate_veil", "throw_move"]:
			var move = f.data.get(slot)
			if move == null:
				continue
			f.state = FighterScript.State.ATTACK
			f.current_move = move
			if Fallback.supports(id, move):
				fallback_count += 1
				var first: Array = []
				for frame: int in [0, move.startup, move.startup + move.active]:
					f.move_frame = frame
					var before: Array = authority(f)
					f.animator.tick(1.0 / 60.0, f, false)
					sk._physics_process(1.0 / 60.0)
					sk.retarget()
					check(authority(f) == before, "presentation invariance " + move.id)
					check(sk.uses_procedural_motion(), "fallback selected " + move.id)
					# UAL root is rotated, so local-Y displacement is not a vertical crouch.
					var pelvis_index: int = sk.skeleton.find_bone("pelvis")
					var rest_hips: Vector3 = sk.skeleton.get_bone_global_rest(pelvis_index).origin
					var hip_delta: Vector3 = sk.skeleton.get_bone_global_pose(pelvis_index).origin - rest_hips
					var expected_height: float = f.animator.root_offset.y * rest_hips.y / 0.95
					check(absf(hip_delta.y - expected_height) < 0.0001, "vertical donor offset " + move.id)
					check(Vector2(hip_delta.x, hip_delta.z).length() < 0.0001, "no horizontal donor offset " + move.id)
					var pose: Array = bones(sk.skeleton)
					if frame == 0:
						first = pose
					elif frame == move.startup:
						check(pose != first, "startup/contact drawing differs " + move.id)
					for bone_name: String in Fallback.PARTS:
						var mapping: Array = Fallback.PARTS[bone_name]
						var bi: int = sk.skeleton.find_bone(bone_name)
						var ci: int = sk.skeleton.find_bone(mapping[1])
						var direction: Vector3 = (sk.skeleton.get_bone_global_pose(ci).origin - sk.skeleton.get_bone_global_pose(bi).origin).normalized()
						var pivot: Node3D = f.animator.parts[mapping[0]]["pivot"]
						var axis: Vector3 = Vector3.UP if mapping[0] in ["pelvis", "torso", "head"] else Vector3.DOWN
						var target: Vector3 = (sk.skeleton.global_basis.inverse() * pivot.global_basis * axis).normalized()
						check(direction.angle_to(target) < deg_to_rad(0.1), "capsule direction transfer " + move.id + "/" + bone_name)
					for key: String in Rig.HERO_AIM:
						check(sk.aim_error(key) < 3.0, "fallback retarget direction " + move.id + "/" + key)
			else:
				for chain in 2:
					f.chain_index = chain
					var clips: Array = Rig.attack_clips(move, chain)
					check(not sk.clip_name(clips[0]).is_empty(), "attack imported " + move.id)
					f.move_frame = move.startup
					sk._physics_process(1.0 / 60.0)
					check(not sk.uses_procedural_motion(), "authored clip wins " + move.id)
					if clips[2] > 0.0:
						check(is_equal_approx(sk.clip_pos, clips[2]), "first active contact " + move.id)
			var held: Array = bones(sk.skeleton)
			var held_time: float = sk.clip_pos
			for field: String in ["hitstop_frames", "frozen_frames"]:
				f.set(field, 2)
				f.move_frame += 1
				sk._physics_process(1.0 / 60.0)
				check(bones(sk.skeleton) == held and sk.clip_pos == held_time, "freeze holds " + field + "/" + move.id)
				f.set(field, 0)
		check(fallback_count == (3 if id == "choko" else 4), "seven explicit fallbacks " + id)
		# Direction changes inside WALK must select another clip without resetting phase.
		f.state = FighterScript.State.WALK
		f.velocity = f.forward
		sk._physics_process(1.0 / 60.0)
		f.velocity = -f.forward
		sk._physics_process(1.0 / 60.0)
		check(sk.clip == sk.clip_name("Walk_Bwd_Loop") and sk.clip_pos > 0.0, "walk reversal phase")
		f.free()
	print("CHARACTER MOTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func bones(skeleton: Skeleton3D) -> Array:
	var out: Array = []
	for i in skeleton.get_bone_count():
		out.append(skeleton.get_bone_pose(i))
	return out

func authority(f) -> Array:
	return [f.position, f.velocity, f.state, f.move_frame, f.hp, f.meter, f.current_move.startup,
		f.current_move.active, f.current_move.recovery, f.current_move.damage,
		f.current_move.hitbox_offset, f.current_move.hitbox_size]
