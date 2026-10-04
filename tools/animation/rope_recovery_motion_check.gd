extends SceneTree
## Recovery changes upper-body drawings, never normal leg cadence or recovery authority.
var failures: int = 0
var checks: int = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ROPE_RECOVERY_MOTION: " + label)
func leg_poses(skeleton: Skeleton3D) -> Array:
	var result: Array = []
	for name: String in ["pelvis", "thigh_l", "calf_l", "foot_l", "ball_l", "thigh_r", "calf_r", "foot_r", "ball_r"]:
		result.append(skeleton.get_bone_pose(skeleton.find_bone(name)))
	return result
func authority(f) -> Array:
	return [f.transform, f.velocity, f.hp, f.meter, f.state, f.grapple.phase,
		f.grapple.token, f.grapple.recovery_remaining, f.grapple.recovery_progress]
func _initialize() -> void:
	await process_frame
	var Actor: GDScript = load("res://scripts/fighter/Fighter.gd")
	var Hook: GDScript = load("res://scripts/grapple/GrappleHook.gd")
	var Motion: GDScript = load("res://scripts/fighter/GrappleMotion.gd")
	var Moves: GDScript = load("res://scripts/fighter/LimbMoves.gd")
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	for id: String in ["choko", "skea"]:
		var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.data = load("res://data/characters/%s.tres" % id)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		var sk = f.skeletal
		f.state = Actor.State.WALK
		f.forward = Vector3.RIGHT
		f.velocity = Vector3.RIGHT * 1.5
		for phase: int in [Hook.Phase.MISS_REWIND, Hook.Phase.ENEMY_EXTRACT]:
			f.grapple.phase = phase
			f.grapple.recovery_remaining = 6.0
			f.grapple.projectile_position = f.position + Vector3(5.0, 0.0, 0.0)
			var drawings: Array[int] = []
			for progress: float in [0.1, 0.3, 0.6]:
				f.grapple.recovery_progress = progress
				for frame: int in 20:
					f.position += f.velocity / 60.0
					var before: Array = authority(f)
					f.animator.tick(1.0 / 60.0, f, false)
					sk._physics_process(1.0 / 60.0)
					check(before == authority(f), id + " recovery authority unchanged")
				var legs: Array = leg_poses(sk.skeleton)
				sk.player.seek(sk.clip_pos, true)
				check(legs == leg_poses(sk.skeleton), id + " original locomotion legs preserved")
				var drawing: int = hash([f.animator.target_pose["upper_arm_r"], f.animator.target_pose["forearm_r"]])
				check(drawing not in drawings, id + " progress changes reeling arms")
				drawings.append(drawing)
			f.grapple.recovery_paused = true
			var before: Array = authority(f)
			f.animator.tick(1.0 / 60.0, f, false)
			check(not Motion.recovery_active(f), "paused recovery yields to dodge/stun drawing")
			check(before == authority(f), "pause cannot consume remaining rope")
			f.grapple.recovery_paused = false
		f.grapple.phase = Hook.Phase.IDLE
		for action: String in ["left_leg", "right_leg"]:
			f.current_move = Moves.resolve(f.data, action, 0, "", false, false)
			f.state = Actor.State.ATTACK
			f.move_frame = f.current_move.startup
			f.grapple.extract_flash = 0.0
			f.animator.tick(1.0 / 60.0, f, false)
			sk._physics_process(1.0 / 60.0)
			var baseline: Array = leg_poses(sk.skeleton)
			f.grapple.extract_side = action
			f.grapple.extract_flash = 0.2
			var before: Array = authority(f)
			f.animator.tick(1.0 / 60.0, f, false)
			sk._physics_process(1.0 / 60.0)
			check(before == authority(f), "kick overlay never refunds inventory")
			check(leg_poses(sk.skeleton) == baseline, action + " normal kicking leg/hips preserved")
			var pull_side: String = "r" if action == "left_leg" else "l"
			var guide_side: String = "l" if pull_side == "r" else "r"
			check(f.animator.target_pose["forearm_" + pull_side].z > f.animator.target_pose["forearm_" + guide_side].z + 0.5, action + " opposite hand pulls")
		f.grapple.extract_flash = 0.0
		f.grapple.phase = Hook.Phase.IDLE
		f.free()
	print("ROPE_RECOVERY_MOTION_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
