extends SceneTree
## Actual retargeted hero grip/contact checks; the weapon never writes gameplay state.
var checks := 0
var failures := 0
var actor: GDScript
var limbs: GDScript
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("SWORD_PRESENTATION: " + label)
func pose(f: Node3D) -> void:
	f.animator.tick(1.0 / 60.0, f, false)
	f.skeletal._physics_process(1.0 / 60.0)
	f.skeletal._on_mannequin_updated()
func run() -> void:
	await process_frame
	actor = load("res://scripts/fighter/Fighter.gd")
	limbs = load("res://scripts/fighter/LimbMoves.gd")
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	var scene := load("res://scenes/fighter/Fighter.tscn") as PackedScene
	for id: String in ["choko", "skea"]:
		var f: Node3D = scene.instantiate()
		f.data = load("res://data/characters/%s.tres" % id)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		if id == "skea":
			check(f.skeletal.sword == null, "Skea never inherits sword")
			f.free()
			continue
		f.sword_drawn = true
		var weapon: Node3D = f.skeletal.sword
		weapon.stow_weight = 0.0
		check(weapon != null and weapon.visible, "one sword presentation created")
		weapon.set_physics_process(false)
		check(weapon.blade.mesh.get_aabb().size.y > 0.8 and weapon.blade.mesh.get_aabb().size.y < 1.2, "blade modeled in world metres")
		var geometry: Array = weapon.blade.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = geometry[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = geometry[Mesh.ARRAY_NORMAL]
		var outward := true
		for index in vertices.size():
			var radial := Vector3(vertices[index].x, 0, vertices[index].z)
			if radial.length_squared() > 0.000001:
				outward = outward and radial.dot(normals[index]) > 0.0
		check(outward, "blade facets have outward normals with Godot clockwise winding")
		for mesh: MeshInstance3D in f.animator.find_children("*", "MeshInstance3D", true, false):
			check(not mesh.visible, "hidden proxy cannot duplicate sword")
		for side: String in ["right", "left"]:
			f.state = actor.State.IDLE
			f.sword_hand = side
			pose(f)
			check(weapon.global_transform.is_equal_approx(weapon.hand_grip(side)), "idle follows actual hero " + side + " grip")
			var authority := [f.position, f.velocity, f.hp, f.sword_hand]
			f.sword_swap_from = side
			f.sword_swap_to = "left" if side == "right" else "right"
			f.state = actor.State.SWAP
			var previous := weapon.global_position
			for frame in range(25):
				f.sword_swap_frame = frame
				if frame == 12:
					f.sword_hand = f.sword_swap_to
				pose(f)
				check(weapon.global_transform.origin.is_finite() and weapon.global_basis.is_finite(), "finite transfer transform")
				if frame >= 10 and frame <= 14:
					var source: Transform3D = weapon.hand_grip(f.sword_swap_from)
					var destination: Transform3D = weapon.hand_grip(f.sword_swap_to)
					if source.origin.distance_to(destination.origin) > 0.065:
						print("SWORD_CONTACT side=", side, " frame=", frame, " distance=", source.origin.distance_to(destination.origin), " source=", source.origin, " destination=", destination.origin)
					check(source.origin.distance_to(destination.origin) <= 0.065, "both real palms share contact window")
					check(previous.distance_to(weapon.global_position) < 0.08, "ownership contact does not teleport sword")
					check(weapon.global_basis.y.dot(f.forward) > 0.7, "transfer blade points into clear space ahead of torso")
					var hero: Skeleton3D = f.skeletal.hero_skeleton
					for arm: String in ["Left", "Right"]:
						var shoulder_point: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(arm + "Arm")).origin
						var elbow_point: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(arm + "ForeArm")).origin
						var wrist_point: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(arm + "Hand")).origin
						if elbow_point.y >= shoulder_point.y or elbow_point.y >= wrist_point.y:
							print("SWORD_ELBOW side=", side, " frame=", frame, " arm=", arm, " shoulder=", shoulder_point, " elbow=", elbow_point, " wrist=", wrist_point)
						check(elbow_point.y < shoulder_point.y and elbow_point.y < wrist_point.y, "transfer elbow remains below shoulder and hand " + arm)

				var hero_rig: Skeleton3D = f.skeletal.hero_skeleton
				var hips: Vector3 = hero_rig.global_transform * hero_rig.get_bone_global_pose(hero_rig.find_bone("Hips")).origin
				var chest: Vector3 = hero_rig.global_transform * hero_rig.get_bone_global_pose(hero_rig.find_bone("Spine")).origin
				var head: Vector3 = hero_rig.global_transform * hero_rig.get_bone_global_pose(hero_rig.find_bone("Head")).origin + Vector3.UP * 0.10
				var clear := true
				for sample in 21:
					var blade_point: Vector3 = weapon.global_transform * Vector3(0, lerpf(0.17, 1.08, sample / 20.0), 0)
					clear = clear and segment_distance(blade_point, hips, chest) > 0.13 and blade_point.distance_to(head) > 0.13
				check(clear, "blade centerline stays outside torso/head core throughout transfer")
				previous = weapon.global_position
			check(f.position == authority[0] and f.velocity == authority[1] and f.hp == authority[2], "transfer pose cannot alter physics/damage")
			f.state = actor.State.IDLE
			pose(f)
			check(weapon.global_transform.is_equal_approx(weapon.hand_grip(f.sword_hand)), "finished handoff follows destination")
		for side: String in ["left", "right"]:
			f.sword_hand = side
			f.attack_sword_hand = side
			f.state = actor.State.ATTACK
			f.current_move = limbs.resolve(f.data, side + "_hand", 0, "", false, false, side)
			f.move_frame = f.current_move.startup
			pose(f)
			var armed: Array = f.animator.part_snapshot()
			check(not f.skeletal.uses_procedural_motion(), "armed normal uses authored source")
			var source: Dictionary = load("res://scripts/fighter/AuthoredCombatMotion.gd").resolve(f.current_move, f.data.id)
			check(not source.is_empty() and f.skeletal.clip == f.skeletal.clip_name(source.clip), "armed normal plays its declared UAL clip")
			check(weapon.global_transform.is_equal_approx(weapon.hand_grip(side)), "attack keeps snapshot grip")
			weapon.stow_weight = 0.9
			weapon.update_pose()
			check(weapon.stow_weight == 0.0 and weapon.global_transform.is_equal_approx(weapon.hand_grip(side)), "armed first active frame finishes unstow at actual grip")
			f.current_move = limbs.resolve(f.data, side + "_hand", 0, "", false, false, "left" if side == "right" else "right")
			f.animator._step_frame = -1
			pose(f)
			check(f.animator.part_snapshot() != armed, "cut differs from same-side fist drawing")
		f.current_move = f.data.ultimate
		pose(f)
		for frame in weapon.ULT_MORPH_FRAMES + 1:
			await physics_frame
			pose(f)
		check(weapon.blade_material.get_shader_parameter("albedo") == weapon.GOLD, "ultimate uses gold variant")
		f.state = actor.State.IDLE
		pose(f)
		for frame in weapon.ULT_MORPH_FRAMES + 1:
			await physics_frame
			pose(f)
		check(weapon.blade_material.get_shader_parameter("albedo") == weapon.EMERALD, "ultimate restores emerald variant")
		# Mirrored authored attacks must not accumulate changes on importer-removed constant tracks.
		for move in [f.data.light, f.data.heavy, f.data.air_light, f.data.ultimate]:
			f.state = actor.State.ATTACK
			f.current_move = move
			f.move_frame = move.startup
			f.attack_sword_hand = "right"
			pose(f)
			var source: Skeleton3D = f.skeletal.skeleton
			var hero: Skeleton3D = f.skeletal.hero_skeleton
			var right_blade: Basis = weapon.global_basis
			var right_source := arm_vector(source, "upperarm_r", "hand_r")
			var right_hero := arm_vector(hero, "RightArm", "RightHand")
			var lower_before: Array = []
			for bone_name: String in ["pelvis", "thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r"]:
				lower_before.append(source.get_bone_global_pose(source.find_bone(bone_name)))
			f.attack_sword_hand = "left"
			f.sword_hand = "left"
			pose(f)
			var normal: Vector3 = f.forward.cross(Vector3.UP).normalized()
			var expected_source := right_source - 2.0 * normal * right_source.dot(normal)
			var expected_hero := right_hero - 2.0 * normal * right_hero.dot(normal)
			var left_source := arm_vector(source, "upperarm_l", "hand_l")
			var left_hero := arm_vector(hero, "LeftArm", "LeftHand")
			check(weapon.global_basis.y.dot(right_blade.y - 2.0 * normal * right_blade.y.dot(normal)) > 0.999, "left blade direction mirrors right authored grip")
			check(weapon.global_basis.z.dot(right_blade.z - 2.0 * normal * right_blade.z.dot(normal)) > 0.999, "left blade face mirrors right authored grip")
			var hand_point: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone("LeftHand")).origin
			check(weapon.global_position.distance_to(hand_point) < 0.056 and weapon.global_basis.determinant() > 0.99, "left grip stays on actual hand with proper unscaled basis")
			check(left_source.distance_to(expected_source) < 0.01, "left authored arm endpoint mirrors right donor")
			check(left_hero.normalized().dot(expected_hero.normalized()) > 0.94, "actual hero left wrist follows mirrored attack direction")
			var lower_after: Array = []
			for bone_name: String in ["pelvis", "thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r"]:
				lower_after.append(source.get_bone_global_pose(source.find_bone(bone_name)))
			check(lower_before == lower_after, "authored weapon mirror preserves pelvis and legs")
			var first: Array[Quaternion] = []
			for bone in source.get_bone_count():
				first.append(source.get_bone_pose_rotation(bone))
			check(not f.skeletal._sword_mirror_base.is_empty(), "left authored sword clip has a sided visual override")
			for repeat in 12:
				pose(f)
			var stable := true
			for bone in source.get_bone_count():
				stable = stable and first[bone].angle_to(source.get_bone_pose_rotation(bone)) < 0.001
			check(stable, "repeated left authored pose has no unkeyed-bone mirror drift")
			f.attack_sword_hand = "right"
			pose(f)
			check(f.skeletal._sword_mirror_base.is_empty(), "right owner restores original authored pose")
			check(weapon.global_transform.is_equal_approx(weapon.hand_grip("right")), "right authored grip after left clip")
		f.state = actor.State.IDLE
		f.sword_hand = "right"
		pose(f)
		var held: Transform3D = weapon.global_transform
		for field: String in ["hitstop_frames", "frozen_frames"]:
			f.set(field, 3)
			weapon.update_pose()
			check(weapon.global_transform == held, "full weapon transform holds " + field)
			f.set(field, 0)
		paused = true
		weapon.update_pose()
		check(weapon.global_transform == held, "pause holds full weapon transform")
		paused = false
		weapon.stow_weight = 0.8
		f.sword_hand = "left"
		f.reset_for_round(0, 1)
		check(weapon.stow_weight == 1.0 and weapon.handoff_blend == 0.0 and weapon.dissolve_weight == 0.0, "round reset clears transition into stored blade")
		check(not weapon.global_position.is_equal_approx(weapon.hand_grip("right").origin) and not f.sword_drawn, "round reset restores canonical back mount")
		f.free()
	print("SWORD_PRESENTATION_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func segment_distance(point: Vector3, a: Vector3, b: Vector3) -> float:
	var line := b - a
	var fraction := clampf((point - a).dot(line) / maxf(line.length_squared(), 0.000001), 0.0, 1.0)
	return point.distance_to(a + line * fraction)

func arm_vector(rig: Skeleton3D, shoulder: String, hand: String) -> Vector3:
	return rig.global_basis * (rig.get_bone_global_pose(rig.find_bone(hand)).origin - rig.get_bone_global_pose(rig.find_bone(shoulder)).origin)
