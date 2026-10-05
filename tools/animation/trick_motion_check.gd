extends SceneTree
## Authored trick presentation: real hero skin, floor, equipment and immutable authority.
var checks: int = 0
var failures: int = 0
var skin_cache: Dictionary = {}
var cloth_oracle: RefCounted
var Actor: GDScript

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("TRICK_MOTION: " + label)

func authority(f) -> Array:
	return [f.transform, f.velocity, f.state, f.hp, f.meter, f.grapple.phase, f.grapple.token, f.grapple.charges, f._rng.state, f.sword_drawn, f.sword_hand]

func skin_points(f) -> PackedVector3Array:
	var mesh: MeshInstance3D = f.skeletal.hero_mesh
	var sk: Skeleton3D = f.skeletal.hero_skeleton
	if not skin_cache.has(f.get_instance_id()):
		var vertices: Array = []
		for surface: int in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			check(not points.is_empty() and bones.size() == weights.size() and bones.size() % points.size() == 0, "nonempty complete skin arrays")
			var stride: int = bones.size() / points.size()
			for vertex: int in points.size():
				var influences: Array = []
				var total: float = 0.0
				for index: int in stride:
					var offset: int = vertex * stride + index
					if weights[offset] <= 0.0:
						continue
					var bind: int = bones[offset]
					var bone: int = sk.find_bone(mesh.skin.get_bind_name(bind)) if mesh.skin.get_bind_name(bind) != &"" else mesh.skin.get_bind_bone(bind)
					check(bone >= 0 and is_finite(weights[offset]), "valid skin influence")
					influences.append([bone, mesh.skin.get_bind_pose(bind) * points[vertex], weights[offset]])
					total += weights[offset]
				check(absf(total - 1.0) < 0.001, "nonzero normalized vertex weights")
				vertices.append(influences)
		skin_cache[f.get_instance_id()] = vertices
	var poses: Array[Transform3D] = []
	for bone: int in sk.get_bone_count():
		poses.append(sk.global_transform * sk.get_bone_global_pose(bone))
	var result := PackedVector3Array()
	for influences: Array in skin_cache[f.get_instance_id()]:
		var point := Vector3.ZERO
		for influence: Array in influences:
			point += (poses[influence[0]] * influence[1]) * influence[2]
		result.append(point)
	return result

func present(f) -> void:
	var before: Array = authority(f)
	f.animator.tick(1.0 / 60.0, f, false)
	f.skeletal._physics_process(1.0 / 60.0)
	check(before == authority(f), "presentation never changes physics, resources or sword authority")
	var sk: Skeleton3D = f.skeletal.hero_skeleton
	for bone: int in sk.get_bone_count():
		check(sk.get_bone_pose(bone).is_finite() and sk.get_bone_pose_scale(bone).distance_to(Vector3.ONE) < 0.0001, "finite unscaled pose")
		if sk.get_bone_parent(bone) >= 0:
			check(sk.get_bone_pose_position(bone).distance_to(sk.get_bone_rest(bone).origin) < 0.001, "real limb lengths")
	var first: Array[Transform3D] = []
	for bone: int in sk.get_bone_count():
		first.append(sk.get_bone_pose(bone))
	var serial: int = f.skeletal.parkour_motion._serial
	for repeat: int in 2:
		f.skeletal._on_mannequin_updated()
		check(f.skeletal.parkour_motion._serial == serial, "render callback never advances trick clock")
		for bone: int in sk.get_bone_count():
			check(first[bone].is_equal_approx(sk.get_bone_pose(bone)), "repeated full callback gives identical pose")

func run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	cloth_oracle = load("res://../tools/equipment/skinned_cloth_oracle.gd").new()
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	root.get_node("GameState").water = null
	var floor := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 1, 30)
	collision.shape = box
	floor.position.y = -0.5
	floor.add_child(collision)
	root.add_child(floor)
	await physics_frame
	for id: String in ["choko", "skea"]:
		var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.data = load("res://data/characters/%s.tres" % id)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		f.position = Vector3(0, 0.03, 0)
		f.velocity = Vector3.DOWN * 4.0
		f.move_and_slide()
		f.state = Actor.State.WALK
		f.forward = Vector3.RIGHT
		f.velocity = Vector3.RIGHT * 3.0
		if f.skeletal.sword != null:
			f.sword_drawn = true
			f.skeletal.sword.set_physics_process(false)
		check(f.is_on_floor(), "actual grounded fixture")
		for phase: String in ["landing_roll", "wall_kick"]:
			f.state = Actor.State.WALK if phase == "landing_roll" else Actor.State.JUMP
			f.position.y = 0.0 if phase == "landing_roll" else 2.0
			f.motion_revision += 1
			var minimum: float = INF
			var maximum_gap: float = -INF
			var support_usec: int = 0
			var support_times: Array[int] = []
			for tick: int in 49:
				await physics_frame
				f.position.x += 0.035
				var progress: float = float(tick) / 48.0
				f.set_meta("parkour_presentation", {"phase": phase, "progress": progress, "direction": Vector3.RIGHT, "wall_point": Vector3(0, 0, -0.4), "wall_normal": Vector3.BACK, "floor_point": Vector3.ZERO, "floor_normal": Vector3.UP})
				if id == "choko":
					f.sword_hand = "left" if tick >= 24 else "right"
				present(f)
				check(f.skeletal.parkour_motion.phase == phase, id + " accepts valid " + phase)
				if phase == "landing_roll":
					var points: PackedVector3Array = skin_points(f)
					check(not points.is_empty(), "whole-body skin is measured")
					var tick_min: float = INF
					for point: Vector3 in points:
						check(point.is_finite(), "finite skinned point")
						tick_min = minf(tick_min, point.y)
					minimum = minf(minimum, tick_min)
					maximum_gap = maxf(maximum_gap, tick_min)
					support_usec = maxi(support_usec, f.skeletal.parkour_motion.roll_support.solve_usec)
					support_times.append(f.skeletal.parkour_motion.roll_support.solve_usec)
					var gear_min: float = accessories_minimum(f)
					check(minf(tick_min, gear_min) < 0.04, "%s roll body/equipment remains near actual floor tick%d %.6f" % [id, tick, minf(tick_min, gear_min)])
					check(gear_min >= -0.006, "%s accessories floor clearance tick%d %.6f" % [id, tick, gear_min])
					check(tick_min >= -0.006, "%s roll whole-body floor clearance tick%d %.6f" % [id, tick, tick_min])
				if tick in [8, 16, 24, 32, 40]:
					check(cloth_oracle.sample(f, id + "/" + phase + "/" + str(tick)) == 0, "trick does not cross real skinned cloth")
					check(cloth_oracle.invalid_shapes == 0, "positive nonempty equipment geometry")
					check(cloth_oracle.pin_margin > 0.0005 and cloth_oracle.pin_margin < 0.004, "unchanged pin margins")
			support_times.sort()
			if not support_times.is_empty():
				print("TRICK_SUPPORT_CPU hero=%s median_us=%d p95_us=%d max_us=%d vertices=%d influences=%d setup_us=%d" % [id, support_times[support_times.size()/2], support_times[int(float(support_times.size()-1)*0.95)], support_usec, f.skeletal.parkour_motion.roll_support.sample_count, f.skeletal.parkour_motion.roll_support.influence_count, f.skeletal.parkour_motion.roll_support.setup_usec])
			print("TRICK_MOTION_SAMPLE hero=%s phase=%s minimum_y=%f maximum_gap=%f support_max_us=%d" % [id, phase, minimum, maximum_gap, support_usec])
		f.state = Actor.State.HITSTUN
		present(f)
		check(f.skeletal.parkour_motion.phase.is_empty(), "reaction rejects stale trick")
		f.state = Actor.State.JUMP
		f.set_meta("parkour_presentation", {"phase": "landing_roll", "progress": 0.5, "direction": Vector3.RIGHT, "floor_normal": Vector3.UP, "floor_point": Vector3.ZERO})
		present(f)
		check(f.skeletal.parkour_motion.phase.is_empty(), "airborne state rejects stale roll")
		f.set_meta("parkour_presentation", {})
		present(f)
		check(f.skeletal.parkour_motion.source_clip.is_empty(), "release clears authored source")
		f.free()
	var Motion = load("res://scripts/fighter/ParkourMotion.gd")
	check(not Motion.valid_snapshot({"phase": "wall_kick", "wall_point": Vector3.ZERO, "wall_normal": Vector3.ZERO}), "zero kick normal fails closed")
	check(not Motion.valid_snapshot({"phase": "landing_roll", "floor_point": Vector3.ZERO, "floor_normal": Vector3.UP, "direction": Vector3(NAN, 0, 0)}), "nonfinite roll direction fails closed")
	check(not Motion.valid_snapshot({"phase": "landing_roll", "floor_point": Vector3.ZERO, "floor_normal": Vector3.RIGHT, "direction": Vector3.RIGHT}), "wall is not rolling floor")
	floor.free()
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).free()
	await process_frame
	print("TRICK_MOTION_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func accessories_minimum(f) -> float:
	var minimum: float = INF
	var count: int = 0
	var holders: Array = [f.skeletal.gear]
	if f.skeletal.sword != null:
		holders.append(f.skeletal.sword)
	for holder: Node3D in holders:
		for mesh: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
			if not mesh.is_visible_in_tree() or mesh.mesh == null:
				continue
			check(mesh.global_transform.is_finite() and absf(mesh.global_basis.determinant()) > 0.00000001, "visible accessory nonsingular transform")
			for point: Vector3 in mesh.mesh.get_faces():
				minimum = minf(minimum, (mesh.global_transform * point).y)
				count += 1
	check(count > 0, "visible accessory triangles measured")
	return minimum
