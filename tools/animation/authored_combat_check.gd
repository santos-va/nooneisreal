extends SceneTree
## Actual donor/hero coverage and contact-phase checks for four-limb authored combat.
var checks: int = 0
var failures: int = 0
var Actor: GDScript
var Moves: GDScript
var Motion: GDScript
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("AUTHORED_COMBAT: " + label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	Moves = load("res://scripts/fighter/LimbMoves.gd")
	Motion = load("res://scripts/fighter/AuthoredCombatMotion.gd")
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	for hero: String in ["choko", "skea"]:
		var f: Node3D = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
		f.data = load("res://data/characters/%s.tres" % hero)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		if f.skeletal.sword != null:
			f.skeletal.sword.set_physics_process(false)
		for action: String in Moves.ACTIONS:
			var foot: bool = action.ends_with("leg")
			for form: int in 8:
				var stage: int = mini(form, 2)
				var previous: String = action if form == 1 else ("right_hand" if action.begins_with("left") else "left_hand")
				var sequence: String = "right_leg>left_leg>right_leg" if foot else "right_hand>left_hand>right_hand"
				var move = Moves.resolve(f.data, action, stage, previous, form == 3, form == 4,
					action.trim_suffix("_hand") if form >= 6 and not foot else "", sequence if form == 5 or form == 7 else "")
				f.state = Actor.State.ATTACK
				f.current_move = move
				var source: Dictionary = Motion.resolve(move, hero)
				check(not source.is_empty(), hero + "/" + move.id + " has source")
				if source.is_empty():
					continue
				check(not f.skeletal.clip_name(source.clip).is_empty(), "imported " + source.clip)
				check(source.recovery == "" or not f.skeletal.clip_name(source.recovery).is_empty(), "imported recovery " + source.clip)
				var frames: Array[int] = [0, int(move.startup / 2), move.startup, move.startup + move.active, move.startup + move.active + move.recovery - 1]
				for frame: int in frames:
					f.move_frame = frame
					var before: Array = authority(f)
					tick(f)
					check(authority(f) == before, "no authority writes " + move.id)
					check(not f.skeletal.uses_procedural_motion(), "no capsule fallback " + move.id)
					check(f.skeletal.clip == f.skeletal.clip_name(source.recovery if source.recovery != "" and frame >= move.startup + move.active else source.clip), "actual source plays " + move.id)
					for bone: String in f.skeletal.HERO_AIM:
						check(f.skeletal.aim_error(bone) < 3.0, "hero anatomy retarget " + move.id + "/" + bone)
					if frame == move.startup:
						check(absf(f.skeletal.clip_pos - source.contact) < 0.001, "first active is measured contact " + move.id)
						var hero_rig: Skeleton3D = f.skeletal.hero_skeleton
						var head: Vector3 = hero_rig.get_bone_global_pose(hero_rig.find_bone("Head")).origin
						var face: Vector3 = hero_rig.get_bone_global_pose(hero_rig.find_bone("headfront")).origin
						var gaze: Vector3 = (hero_rig.global_basis * (face - head)).normalized()
						check(gaze.y >= sin(deg_to_rad(-20.1)) and gaze.y <= sin(deg_to_rad(15.1)), "actual face keeps anatomical pitch " + move.id)
						if source.variant in ["lowhand", "lowkick", "lowcut"]:
							var limb_name: String = ("Left" if source.side == "left" else "Right") + ("Foot" if source.limb == "leg" else "Hand")
							var endpoint: Vector3 = hero_rig.global_transform * hero_rig.get_bone_global_pose(hero_rig.find_bone(limb_name)).origin
							check(endpoint.y - f.global_position.y < move.hitbox_offset.y + move.hitbox_size.y * 0.5 + 0.10, "low contact stays in low height band " + move.id)
						var held: Array = poses(f.skeletal.skeleton)
						for field: String in ["hitstop_frames", "frozen_frames"]:
							f.set(field, 2)
							f.skeletal._physics_process(1.0 / 60.0)
							check(poses(f.skeletal.skeleton) == held, "held source " + field)
							f.set(field, 0)
		# Independent left/right endpoint reflection, including world-yaw changes.
		for yaw: float in [0.0, PI / 2.0]:
			f.forward = Vector3.RIGHT.rotated(Vector3.UP, yaw)
			for kind: String in ["hand", "leg"]:
				var points: Array[Vector3] = []
				for side: String in ["left", "right"]:
					f.current_move = Moves.resolve(f.data, side + "_" + kind, 0, "", false, false)
					f.move_frame = f.current_move.startup
					tick(f)
					var skeleton: Skeleton3D = f.skeletal.skeleton
					var endpoint: int = skeleton.find_bone(("hand_" if kind == "hand" else "foot_") + ("l" if side == "left" else "r"))
					var world: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(endpoint).origin - f.global_position
					points.append(Vector3(world.dot(f.forward), world.y, world.dot(f.forward.cross(Vector3.UP))))
				check(absf(points[0].x - points[1].x) < 0.035 and absf(points[0].y - points[1].y) < 0.035 and absf(points[0].z + points[1].z) < 0.035, "mirror correct anatomical limb/yaw " + hero + "/" + kind + "/" + str(points))
		if hero == "choko":
			f.sword_drawn = false
			f.skeletal.sword.stow_weight = 1.0
			var mount: Transform3D
			for low: bool in [false, true]:
				f.current_move = Moves.resolve(f.data, "right_hand", 0, "", low, false)
				f.move_frame = f.current_move.startup
				tick(f)
				f.skeletal.sword.update_pose()
				var body: Skeleton3D = f.skeletal.hero_skeleton
				var torso: Transform3D = body.global_transform * body.get_bone_global_pose(body.find_bone("Spine01"))
				var attached: Transform3D = torso.affine_inverse() * f.skeletal.sword.global_transform
				if not low:
					mount = attached
				else:
					check(attached.origin.distance_to(mount.origin) < 0.001 and attached.basis.is_equal_approx(mount.basis), "sheathed sword stays attached to animated torso")
		f.free()
	print("AUTHORED_COMBAT_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
func tick(f: Node3D) -> void:
	f.animator.tick(1.0 / 60.0, f, false)
	f.skeletal._physics_process(1.0 / 60.0)
	f.skeletal.retarget()
func authority(f: Node3D) -> Array:
	return [f.position, f.velocity, f.state, f.move_frame, f.hp, f._rng.state, f.current_move.damage,
		f.current_move.startup, f.current_move.active, f.current_move.recovery,
		f.current_move.hitbox_offset, f.current_move.hitbox_size]
func poses(skeleton: Skeleton3D) -> Array:
	var out: Array = []
	for bone in skeleton.get_bone_count():
		out.append(skeleton.get_bone_pose(bone))
	return out
