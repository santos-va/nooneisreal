extends SceneTree
## Run serially: Godot --headless --path game -s $PWD/tools/animation/idle_presence_check.gd
var failures: int = 0
var checks: int = 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	await process_frame
	root.get_node("GameState").skeletal_rig = true
	var fighter_script: GDScript = load("res://scripts/fighter/Fighter.gd")
	for id: String in ["choko", "skea"]:
		var f = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
		f.data = load("res://data/characters/%s.tres" % id)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		f.state = fighter_script.State.IDLE
		var sk = f.skeletal
		var source: Skeleton3D = sk.skeleton
		var initial: Array = authority(f)
		var first: Array = []
		var lifts: int = 0
		seed(123456)
		var expected_random: int = randi()
		seed(123456)
		for tick in 720:
			sk._physics_process(1.0 / 60.0)
			sk.retarget()
			if id == "choko":
				for side: String in ["Left", "Right"]:
					var hero: Skeleton3D = sk.hero_skeleton
					var shoulder: Vector3 = hero.get_bone_global_pose(hero.find_bone(side + "Arm")).origin
					var wrist: Vector3 = hero.get_bone_global_pose(hero.find_bone(side + "Hand")).origin
					var guard: Vector3 = hero.global_basis * (wrist - shoulder)
					check(guard.y > -0.22 and guard.y < -0.01, "actual hero wrist below shoulder in collected guard " + side)
					var elbow: Vector3 = hero.get_bone_global_pose(hero.find_bone(side + "ForeArm")).origin
					var elbow_drop: Vector3 = hero.global_basis * (elbow - shoulder)
					check(elbow_drop.y < guard.y - 0.04, "elbow remains below wrist " + side)
					var angle: float = rad_to_deg((shoulder - elbow).angle_to(wrist - elbow))
					check(angle > 35.0 and angle < 135.0, "bounded bent elbow " + side)
					var donor_hand: int = source.find_bone("hand_" + ("l" if side == "Left" else "r"))
					var neutral: Quaternion = source.get_bone_rest(donor_hand).basis.orthonormalized().get_rotation_quaternion()
					check(source.get_bone_pose_rotation(donor_hand).angle_to(neutral) < 0.001, "neutral anatomical wrist " + side)
			if id == "choko":
				var hero: Skeleton3D = sk.hero_skeleton
				var head: Vector3 = hero.get_bone_global_pose(hero.find_bone("Head")).origin
				var front: Vector3 = hero.get_bone_global_pose(hero.find_bone("headfront")).origin
				var gaze: Vector3 = (hero.global_basis * (front - head)).normalized()
				var pitch: float = rad_to_deg(asin(clampf(gaze.y, -1.0, 1.0)))
				check(pitch > -16.0 and pitch < -4.0, "actual hero gaze stays alert with tucked chin")
				check(gaze.dot(f.forward) > 0.9, "actual hero looks forward")
				if tick in [0, 30, 179, 719]:
					print("IDLE_GAZE tick=", tick, " pitch=", pitch, " forward=", gaze.dot(f.forward))
			var actual: Array = bones(source)
			if tick == 0:
				first = actual
			if tick == 60 or tick == 120:
				check(actual != first, id + " spaced stance poses differ")
			check(authority(f) == initial, id + " authority/root/RNG unchanged")
			var feet: Array[Vector3] = []
			for side: String in ["l", "r"]:
				feet.append(source.get_bone_global_pose(source.find_bone("foot_" + side)).origin)
			sk.player.seek(sk.clip_pos, true)
			var base: Array = bones(source)
			check(actual[source.find_bone("pelvis")] == base[source.find_bone("pelvis")], id + " pelvis unchanged")
			var moved: int = 0
			for side_index in 2:
				var side: String = ["l", "r"][side_index]
				var foot: int = source.find_bone("foot_" + side)
				var offset: Vector3 = source.global_basis * (feet[side_index] - source.get_bone_global_pose(foot).origin)
				check(Vector2(offset.x, offset.z).length() < 0.0001, id + " no horizontal foot slide")
				check(offset.y >= -0.0001 and offset.y < 0.02, id + " bounded upward foot lift")
				if offset.length() > 0.0001:
					moved += 1
			check(moved <= 1, id + " at least one authored support foot")
			lifts += moved
		check(randi() == expected_random, id + " global RNG unchanged")
		check(lifts > 0 if id == "choko" else lifts == 0, id + " character specific footwork")
		sk._physics_process(1.0 / 60.0)
		var held: Array = bones(source)
		var phase: float = sk.idle_presence.phase
		for field: String in ["frozen_frames", "hitstop_frames"]:
			f.set(field, 3)
			sk._physics_process(1.0 / 60.0)
			check(bones(source) == held and sk.idle_presence.phase == phase, id + " hold " + field)
			f.set(field, 0)
		paused = true
		sk._physics_process(1.0 / 60.0)
		check(bones(source) == held and sk.idle_presence.phase == phase, id + " pause holds")
		paused = false
		# Re-evaluate the same authored instant and additive phase repeatedly. A constant/unkeyed
		# source bone must not accumulate offsets even though AnimationPlayer never writes it.
		var repeated: Array = []
		for repetition: int in 90:
			sk._last_state = fighter_script.State.IDLE
			sk._state_frames = 44
			sk.idle_presence.phase = 0.8 - 1.0 / 60.0
			sk._physics_process(1.0 / 60.0)
			if repetition == 0:
				repeated = bones(source)
			else:
				check(poses_close(bones(source), repeated), id + " fixed phase is idempotent on unkeyed bones")
		phase = sk.idle_presence.phase
		# Transfer keeps Choko's collected torso without idle-time advance or a foot tap.
		f.state = fighter_script.State.SWAP
		var transfer_authority: Array = authority(f)
		for transfer_frame: int in 30:
			sk._physics_process(1.0 / 60.0)
			sk.retarget()
			check(sk.idle_presence.phase == phase, id + " transfer does not advance idle clock")
			check(authority(f) == transfer_authority, id + " transfer posture has no authority")
			var transfer_pose: Array = bones(source)
			if id == "choko":
				var hero: Skeleton3D = sk.hero_skeleton
				var head: Vector3 = hero.get_bone_global_pose(hero.find_bone("Head")).origin
				var front: Vector3 = hero.get_bone_global_pose(hero.find_bone("headfront")).origin
				var gaze: Vector3 = (hero.global_basis * (front - head)).normalized()
				var pitch: float = rad_to_deg(asin(clampf(gaze.y, -1.0, 1.0)))
				check(pitch > -16.0 and pitch < -4.0, "transfer retains collected actual hero gaze")
				check(gaze.dot(f.forward) > 0.9, "transfer retains forward gaze")
			sk.idle_presence.restore_base(source)
			var raw_transfer: Array = bones(source)
			for bone_name: String in ["pelvis", "thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r"]:
				var bone: int = source.find_bone(bone_name)
				check((transfer_pose[bone] as Transform3D).is_equal_approx(raw_transfer[bone]), id + " transfer retains authored lower body " + bone_name)
			if id == "skea":
				check(poses_close(transfer_pose, raw_transfer), "Skea transfer has no Choko posture")
		# Negative state controls: authored attack, walk and block contain no residual idle offset.
		for state: int in [fighter_script.State.ATTACK, fighter_script.State.WALK, fighter_script.State.BLOCK]:
			f.state = state
			f.current_move = f.data.light
			f.move_frame = 0
			sk._physics_process(1.0 / 60.0)
			var pose: Array = bones(source)
			sk.player.seek(sk.clip_pos, true)
			check(bones(source) == pose and sk.idle_presence.phase == phase, id + " non-idle clean baseline")
			# An independent fresh mannequin, with no IdlePresence history, supplies the raw target.
			var reference: Transform3D = fresh_clip_spine(sk)
			check(source.get_bone_pose(source.find_bone("spine_01")).is_equal_approx(reference), id + " non-idle spine equals independently sampled fresh rig")
		f.free()
	print("IDLE PRESENCE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func bones(skeleton: Skeleton3D) -> Array:
	var result: Array = []
	for i in skeleton.get_bone_count():
		result.append(skeleton.get_bone_pose(i))
	return result

func authority(f) -> Array:
	return [f.position, f.velocity, f.state, f.move_frame, f.hp, f.meter, f._rng.state]

func poses_close(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i: int in a.size():
		if not (a[i] as Transform3D).is_equal_approx(b[i]):
			return false
	return true

func fresh_clip_spine(rig) -> Transform3D:
	var reference: Node = (load(rig.MANNEQUIN) as PackedScene).instantiate()
	root.add_child(reference)
	reference.process_mode = Node.PROCESS_MODE_DISABLED
	var player: AnimationPlayer = reference.get_node("AnimationPlayer")
	var skeleton: Skeleton3D = reference.get_node("Armature/Skeleton3D")
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var library := AnimationLibrary.new()
	library.add_animation("pose", rig.player.get_animation(rig.clip))
	player.add_animation_library("probe", library)
	skeleton.reset_bone_poses()
	player.play("probe/pose")
	player.seek(rig.clip_pos, true)
	var result: Transform3D = skeleton.get_bone_pose(skeleton.find_bone("spine_01"))
	reference.free()
	return result
