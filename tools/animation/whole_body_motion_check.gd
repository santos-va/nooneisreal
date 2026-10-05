extends SceneTree
## Whole-body acceptance: actual inputs, head/spine transitions and authored contact poses.
var checks: int = 0
var failures: int = 0
var actor: GDScript
var limbs: GDScript
var hook_script: GDScript
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("WHOLE_BODY: " + message)
func world_rotation(rig: Skeleton3D, name: String) -> Quaternion:
	return (rig.global_basis.orthonormalized() * rig.get_bone_global_pose(rig.find_bone(name)).basis.orthonormalized()).get_rotation_quaternion()
func pitch(rig: Skeleton3D) -> float:
	var direction: Vector3 = rig.global_basis * (rig.get_bone_global_pose(rig.find_bone("headfront")).origin - rig.get_bone_global_pose(rig.find_bone("Head")).origin)
	return rad_to_deg(asin(clampf(direction.normalized().y, -1.0, 1.0)))
func authority(f) -> Array:
	return [f.transform, f.velocity, f.state, f.move_frame, f.hp, f.meter, f.grapple.phase, f.grapple.token, f.grapple.rope_length, f._rng.state]
func present(f) -> void:
	var before: Array = authority(f)
	f.skeletal._physics_process(1.0 / 60.0)
	check(authority(f) == before, "presentation preserves gameplay authority")
func anatomy(rig: Skeleton3D) -> void:
	for name: String in ["neck", "Head", "LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand", "LeftUpLeg", "LeftLeg", "LeftFoot", "RightUpLeg", "RightLeg", "RightFoot"]:
		var bone: int = rig.find_bone(name)
		var rest_length: float = rig.get_bone_rest(bone).origin.length()
		check(absf(rig.get_bone_pose_position(bone).length() - rest_length) <= maxf(0.0001, rest_length * 0.005), "actual hero chain length " + name)
		check(rig.get_bone_pose_scale(bone).distance_to(Vector3.ONE) < 0.0001, "actual hero bone scale " + name)
func hanging_balance(f) -> void:
	# Controlled presentation snapshot: hold the authored phase and change only
	# physical support direction. Actual hook-drive authority is covered separately.
	f.position.y = 3.0
	f.velocity = Vector3.ZERO
	f.move_and_slide()
	f.motion_revision += 1
	f.state = actor.State.GRAPPLE
	f.current_move = null
	f.grapple.attached = true
	f.grapple.phase = hook_script.Phase.HANG
	f.grapple.anchor_point = f.position + Vector3(0, 5, 0)
	var rig: Skeleton3D = f.skeletal.hero_skeleton
	for frame: int in 20:
		f.skeletal._state_frames = 17
		present(f)
	var initial_hips: Quaternion = world_rotation(rig, "Hips")
	var initial_spine: Quaternion = world_rotation(rig, "Spine")
	f.grapple.anchor_point = f.position + Vector3(4, 5, 0)
	for frame: int in 20:
		f.skeletal._state_frames = 17
		present(f)
		anatomy(rig)
		for side: String in ["Left", "Right"]:
			var hip: Vector3 = rig.global_transform * rig.get_bone_global_pose(rig.find_bone(side + "UpLeg")).origin
			var knee: Vector3 = rig.global_transform * rig.get_bone_global_pose(rig.find_bone(side + "Leg")).origin
			var foot: Vector3 = rig.global_transform * rig.get_bone_global_pose(rig.find_bone(side + "Foot")).origin
			var length: float = hip.distance_to(knee) + knee.distance_to(foot)
			check(hip.y - foot.y > length * 0.85, "hanging leg follows gravity instead of curled Jump_Loop knee")
	check(rad_to_deg(initial_hips.angle_to(world_rotation(rig, "Hips"))) > 2.0, "rope support turns pelvis at held authored phase")
	check(rad_to_deg(initial_spine.angle_to(world_rotation(rig, "Spine"))) > 1.0, "rope load is shared by torso")
	f.grapple.attached = false
	f.grapple.phase = hook_script.Phase.IDLE
	f.state = actor.State.JUMP
	for frame: int in 20:
		present(f)
	check(f.skeletal.body_motion.balance_weight == 0.0, "release clears hanging balance")
func run() -> void:
	await process_frame
	actor = load("res://scripts/fighter/Fighter.gd")
	limbs = load("res://scripts/fighter/LimbMoves.gd")
	hook_script = load("res://scripts/grapple/GrappleHook.gd")
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	root.get_node("GameState").water = null
	root.get_node("Sfx")._players.clear()
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -0.5
	root.add_child(floor_body)
	var input: Node = root.get_node("InputRouter")
	input.apply_profile("solo", false)
	input.set_view_basis(1, Vector3.FORWARD)
	for hero: String in ["choko", "skea"]:
		var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.data = load("res://data/characters/%s.tres" % hero)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		f.control_locked = false
		f.state = actor.State.IDLE
		f.forward = Vector3.RIGHT
		var sk = f.skeletal
		var rig: Skeleton3D = sk.hero_skeleton
		var last_head := Quaternion.IDENTITY
		var last_spine := Quaternion.IDENTITY
		var maximum_head: float = 0.0
		var maximum_spine: float = 0.0
		for frame: int in 480:
			await physics_frame
			input.v_set(1, "right", frame >= 60 and frame < 200)
			input.v_set(1, "up", frame >= 200 and frame < 260)
			input.v_set(1, "crouch", frame >= 330 and frame < 390)
			input.v_set(1, "block", frame >= 420 and frame < 450)
			f._physics_process(1.0 / 60.0)
			present(f)
			var head: Quaternion = world_rotation(rig, "Head")
			var spine: Quaternion = world_rotation(rig, "Spine")
			if frame > 0:
				var head_step: float = rad_to_deg(head.angle_to(last_head))
				var spine_step: float = rad_to_deg(spine.angle_to(last_spine))
				maximum_head = maxf(maximum_head, head_step)
				maximum_spine = maxf(maximum_spine, spine_step)
				check(head_step <= 10.1, "%s frame%d neutral head step %.3fdeg" % [hero, frame, head_step])
				check(spine_step <= 12.1, "%s frame%d neutral spine step %.3fdeg" % [hero, frame, spine_step])
			last_head = head
			last_spine = spine
			if frame >= 110 and frame < 195:
				check(pitch(rig) > -20.0 and pitch(rig) < 12.0, hero + " moving face sees ahead instead of floor")
			if frame % 30 == 0:
				var poses: Array[Transform3D] = []
				for bone: int in rig.get_bone_count():
					poses.append(rig.get_bone_pose(bone))
				var serial: int = sk.body_motion.serial
				var feet = sk.ground_contact
				var foot_history: Array = [feet._serial, feet.query_count, feet.target_captures, feet.history_updates, feet._state.duplicate(true)]
				sk._on_mannequin_updated()
				check(sk.body_motion.serial == serial, "callback does not advance simulation presentation clock")
				for bone: int in rig.get_bone_count():
					var difference: float = poses[bone].origin.distance_to(rig.get_bone_pose(bone).origin)
					check(difference < 0.001, "repeat retarget keeps local bone positions")
					var now: Transform3D = rig.get_bone_pose(bone)
					var angle: float = poses[bone].basis.orthonormalized().get_rotation_quaternion().angle_to(now.basis.orthonormalized().get_rotation_quaternion())
					check(rad_to_deg(angle) < 0.1, "repeat retarget keeps bone rotations")
					check(poses[bone].basis.get_scale().distance_to(now.basis.get_scale()) < 0.0001, "repeat retarget keeps bone scales")
				check([feet._serial, feet.query_count, feet.target_captures, feet.history_updates, feet._state] == foot_history, "repeat retarget preserves plant anchors, queries and history")
				anatomy(rig)
				f.frozen_frames = 2
				sk._physics_process(1.0 / 60.0)
				check(sk.body_motion.serial == serial, "freeze keeps whole-body clock")
				f.frozen_frames = 0
		print("WHOLE_BODY_TRANSITIONS %s head_max=%.5f spine_max=%.5f" % [hero, maximum_head, maximum_spine])
		input.v_clear(1)
		for variant: String in ["jab", "lowhand", "hammer", "frontkick"]:
			f.current_move = limbs.resolve(f.data, "left_leg" if variant == "frontkick" else ("right_hand" if variant == "hammer" else "left_hand"), 2 if variant == "hammer" else 0, "", variant == "lowhand", false, "", "right_hand>left_hand>right_hand" if variant == "hammer" else "")
			f.state = actor.State.ATTACK
			f.velocity = Vector3.ZERO
			var low: float = INF
			var high: float = -INF
			for frame: int in f.current_move.startup + f.current_move.active + f.current_move.recovery:
				f.move_frame = frame
				f.animator.tick(1.0 / 60.0, f, false)
				present(f)
				anatomy(rig)
				var face_pitch: float = pitch(rig)
				low = minf(low, face_pitch)
				high = maxf(high, face_pitch)
				check(face_pitch > -20.1 and face_pitch < 15.1, "authored attack keeps anatomical gaze")
			check(high - low > 0.25, "%s %s authored head arc remains visible %.3fdeg" % [hero, variant, high-low])
			print("WHOLE_BODY_GAZE %s %s %.6f..%.6f" % [hero, variant, low, high])
		hanging_balance(f)
		f.free()
	floor_body.free()
	await process_frame
	print("WHOLE_BODY_MOTION_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
