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
		for tick in 180:
			sk._physics_process(1.0 / 60.0)
			sk.retarget()
			if id == "choko":
				for side: String in ["Left", "Right"]:
					var hero: Skeleton3D = sk.hero_skeleton
					var shoulder: Vector3 = hero.get_bone_global_pose(hero.find_bone(side + "Arm")).origin
					var wrist: Vector3 = hero.get_bone_global_pose(hero.find_bone(side + "Hand")).origin
					var guard: Vector3 = hero.global_basis * (wrist - shoulder)
					check(guard.y > 0.02 and guard.y < 0.30, "actual hero wrist above shoulder in bounded guard " + side)
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
		# Negative state controls: authored attack, walk and block contain no residual idle offset.
		for state: int in [fighter_script.State.ATTACK, fighter_script.State.WALK, fighter_script.State.BLOCK]:
			f.state = state
			f.current_move = f.data.light
			f.move_frame = 0
			sk._physics_process(1.0 / 60.0)
			var pose: Array = bones(source)
			sk.player.seek(sk.clip_pos, true)
			check(bones(source) == pose and sk.idle_presence.phase == phase, id + " non-idle clean baseline")
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
