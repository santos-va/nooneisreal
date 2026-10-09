extends SceneTree
## Presentation contract test; real motor collision/eligibility is covered in city parkour checks.
var checks: int = 0
var failures: int = 0
var Actor: GDScript
var Motion: GDScript
var cloth_oracle: RefCounted

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PARKOUR_MOTION: " + message)

func authority(f) -> Array:
	return [f.transform, f.velocity, f.state, f.hp, f.meter, f.grapple.phase, f.grapple.token, f.grapple.charges, f._rng.state, f.sword_drawn, f.sword_hand]

func present(f) -> void:
	var before: Array = authority(f)
	f.animator.tick(1.0 / 60.0, f, false)
	f.skeletal._physics_process(1.0 / 60.0)
	check(before == authority(f), "animation is read-only gameplay")
	var hero: Skeleton3D = f.skeletal.hero_skeleton
	for bone: int in hero.get_bone_count():
		check(hero.get_bone_pose(bone).is_finite(), "finite hero pose")
		check(hero.get_bone_pose_scale(bone).distance_to(Vector3.ONE) < 0.0001, "no scaled limbs")
		if hero.get_bone_parent(bone) >= 0:
			check(hero.get_bone_pose_position(bone).distance_to(hero.get_bone_rest(bone).origin) < 0.001, "real bone lengths retained")

func cloth(f, label: String) -> void:
	check(cloth_oracle.sample(f, label) == 0, "new support pose does not cross cloth " + label)
	check(cloth_oracle.invalid_shapes == 0, "new support pose has valid nonempty pins " + label)
	check(cloth_oracle.pin_margin > 0.0005 and cloth_oracle.pin_margin < 0.004, "new support pose preserves real skin pin clearance " + label)

func shoe_points(f, side: String) -> PackedVector3Array:
	var result := PackedVector3Array()
	var hero: Skeleton3D = f.skeletal.hero_skeleton
	for influences: Array in f.skeletal.foot_contact.samples[side]:
		var point: Vector3 = Vector3.ZERO
		for influence: Array in influences:
			point += (hero.get_bone_global_pose(influence[0]) * influence[1]) * influence[2]
		result.append(hero.global_transform * point)
	return result

func run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	Motion = load("res://scripts/fighter/ParkourMotion.gd")
	cloth_oracle = load("res://../tools/equipment/skinned_cloth_oracle.gd").new()
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	root.get_node("GameState").water = null
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.14, 30.0, 10.0)
	collision.shape = box
	wall.add_child(collision)
	wall.position = Vector3(0.5, 10, 0)
	root.add_child(wall)
	check(not Motion.valid_snapshot({"phase": "wall_run", "wall_point": Vector3.ZERO, "wall_normal": Vector3.ZERO}), "zero normal rejected")
	check(not Motion.valid_snapshot({"phase": "hang", "left_hand": Vector3(NAN, 0, 0), "right_hand": Vector3.ZERO}), "nonfinite grip rejected")
	check(not Motion.valid_snapshot({"phase": "mantle", "left_hand": Vector3.ZERO}), "partial contact rejected")
	check(not Motion.valid_snapshot({"phase": "hang", "left_hand": Vector3.ZERO, "right_hand": Vector3.ZERO, "progress": {}}), "non-numeric progress rejected")
	for id: String in ["choko", "skea"]:
		var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.data = load("res://data/characters/%s.tres" % id)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		f.position = Vector3(0, 3, 0)
		f.forward = Vector3.RIGHT
		f.state = Actor.State.JUMP
		f.velocity = Vector3.ZERO
		present(f)
		if f.skeletal.sword != null:
			f.skeletal.sword.set_physics_process(false)
			f.sword_drawn = true
			f.skeletal.sword.stow_weight = 0.0
		# Match CityParkourProfile: root .43m out / 1.42m below actual edge, hands ±.24m.
		var hanging: Vector3 = f.position
		var grip: Dictionary = {"phase": "hang", "progress": 0.0, "left_hand": f.position + Vector3(0.43, 1.42, -0.24), "right_hand": f.position + Vector3(0.43, 1.42, 0.24)}
		f.set_meta("parkour_presentation", grip)
		for frame: int in 12:
			await physics_frame
			present(f)
		if f.skeletal.sword != null:
			check(f.sword_drawn and f.skeletal.sword.stow_weight > 0.99, "drawn sword stows at back while both hands support the body")
		check(f.skeletal.parkour_motion.source_clip == "Climb_Idle", id + " actual authored hang source")
		check(f.skeletal.parkour_motion.grip_error < 0.08, id + " real ledge contacts within 8cm %.4f" % f.skeletal.parkour_motion.grip_error)
		print("PARKOUR_GRIP ", id, " error_m=", f.skeletal.parkour_motion.grip_error)
		cloth(f, id + "/hang")
		var hero: Skeleton3D = f.skeletal.hero_skeleton
		var first: Array[Transform3D] = []
		for bone: int in hero.get_bone_count():
			first.append(hero.get_bone_pose(bone))
		for sample: int in 4:
			f.skeletal.retarget()
			for bone: int in hero.get_bone_count():
				check(first[bone].is_equal_approx(hero.get_bone_pose(bone)), "repeated render reuses same parkour pose")
		for frame: int in 30:
			grip.phase = "mantle"
			grip.progress = float(frame) / 29.0
			var progress: float = grip.progress
			var apex: Vector3 = hanging + Vector3.UP * 1.455
			var landing: Vector3 = apex + Vector3.RIGHT * 1.08
			f.position = hanging.lerp(apex, minf(progress * 2.0, 1.0)) if progress < 0.5 else apex.lerp(landing, (progress - 0.5) * 2.0)
			f.set_meta("parkour_presentation", grip)
			present(f)
			if frame in [0, 7, 15, 23, 29]:
				cloth(f, id + "/mantle/" + str(frame))
		check(f.skeletal.parkour_motion.source_clip == "ClimbLedge", "mantle uses installed ledge-climb source")
		f.position.x = 0.0
		f.motion_revision += 1
		f.set_meta("parkour_presentation", {"phase": "wall_run", "wall_point": Vector3(0.43, 0, 0), "wall_normal": Vector3.LEFT, "progress": 0.0})
		var advanced: float = 0.0 # the feet cycle, summed over its wraps
		for frame: int in 48:
			if frame >= 24 and (id != "skea" or not f.skeletal.parkour_motion._plants.is_empty()):
				break
			f.position.y += 0.05
			var cycle_before: float = f.skeletal.parkour_motion.cycle
			present(f)
			advanced += fposmod(f.skeletal.parkour_motion.cycle - cycle_before, 1.0)
			if id == "skea" and frame % 6 == 0:
				cloth(f, id + "/wall/" + str(frame))
			if id == "skea":
				# Every planted shoe touches the wall on every frame, not only on the last one. A foot taking or leaving
				# its plant (plan 2026-10-09-Animation-Feel step 5) is not planted yet; the run stops on a planted frame
				# after the last cloth sample, and runs on past 24 frames (at most 48) until one comes, so the strip test
				# below always has a planted foot.
				for side: String in f.skeletal.parkour_motion._plants:
					var points: PackedVector3Array = shoe_points(f, side)
					var nearest: float = -INF
					for point: Vector3 in points:
						nearest = maxf(nearest, point.x)
					check(nearest <= 0.432 and nearest >= 0.41, "actual skinned shoe contacts wall without penetration or floating")
				if frame >= 18 and not f.skeletal.parkour_motion._plants.is_empty():
					break
		if id == "skea":
			check(not f.skeletal.parkour_motion._plants.is_empty(), "wall feet plant only after real solid rays")
			# A thin raised strip intersects the shoe edge while missing its ankle ray.
			var planted: String = f.skeletal.parkour_motion._plants.keys()[0]
			var foot: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(planted + "Foot")).origin
			var edge: float = foot.z
			for point: Vector3 in shoe_points(f, planted):
				edge = maxf(edge, point.z)
			var width: float = edge - foot.z
			check(width > 0.025, "real shoe has a measurable lateral footprint")
			var pillar := StaticBody3D.new()
			var pillar_collision := CollisionShape3D.new()
			var pillar_box := BoxShape3D.new()
			pillar_box.size = Vector3(0.18, 2.0, width)
			pillar_collision.shape = pillar_box
			pillar.add_child(pillar_collision)
			pillar.position = Vector3(0.34, foot.y, foot.z + width * 0.8)
			root.add_child(pillar)
			await physics_frame
			present(f)
			var inside: int = 0
			var bounds := AABB(pillar.position - pillar_box.size * 0.5, pillar_box.size)
			for point: Vector3 in shoe_points(f, planted):
				if bounds.has_point(point):
					inside += 1
			check(inside == 0, "full skinned shoe clears a protruding strip missed by centre ray")
			var wall_pose: Array[Transform3D] = []
			for bone: int in hero.get_bone_count():
				wall_pose.append(hero.get_bone_pose(bone))
			for repeat: int in 3:
				f.skeletal.retarget()
				for bone: int in hero.get_bone_count():
					check(wall_pose[bone].is_equal_approx(hero.get_bone_pose(bone)), "footprint contacts reuse exact cached physics pose")
			pillar.free()
			check(advanced > 0.1, "vertical wall displacement advances quick feet")
			var cycle: float = f.skeletal.parkour_motion.cycle
			for frame: int in 12:
				present(f)
			check(is_equal_approx(cycle, f.skeletal.parkour_motion.cycle), "blocked wall has no treadmill phase")
			wall.position.z = 20.0
			await physics_frame
			for frame: int in 20:
				f.position.y += 0.05
				present(f)
			check(f.skeletal.parkour_motion._plants.is_empty(), "missing foot surface never creates an infinite-plane plant")
		else:
			check(f.skeletal.parkour_motion.phase.is_empty(), "Choko never receives Skea wall pose")
		f.set_meta("parkour_presentation", {})
		present(f)
		check(f.skeletal.parkour_motion.phase.is_empty() and f.skeletal.parkour_motion._plants.is_empty(), "release clears source and wall plants")
		if f.skeletal.sword != null:
			for frame: int in 13:
				await physics_frame
				present(f)
			check(f.sword_drawn and f.skeletal.sword.stow_weight < 0.001, "released hands restore drawn sword without changing gameplay ownership")
		f.forward = Vector3.FORWARD
		f.set_meta("parkour_presentation", {"phase": "hang", "left_hand": f.position + Vector3(-0.24, 1.42, -0.43), "right_hand": f.position + Vector3(0.24, 1.42, -0.43)})
		for frame: int in 12:
			present(f)
		check(f.skeletal.parkour_motion.grip_error < 0.08, id + " rotated ledge uses world contacts")
		cloth(f, id + "/rotated_hang")
		f.set_meta("parkour_presentation", grip)
		f.state = Actor.State.HITSTUN
		present(f)
		check(f.skeletal.parkour_motion.phase.is_empty(), "stale metadata cannot override reaction")
		f.state = Actor.State.JUMP
		f.set_meta("parkour_presentation", [])
		present(f)
		check(f.skeletal.parkour_motion.phase.is_empty(), "wrong metadata container fails closed")
		f.free()
	wall.free()
	await process_frame
	print("PARKOUR_MOTION_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
