extends SceneTree
## Real imported shoe vertices, world surfaces, authority and excluded-state contracts.
var Actor: GDScript
var checks: int = 0
var failures: int = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FOOT_CONTACT: " + label)
func _initialize() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	var gs = root.get_node("GameState")
	gs.skeletal_rig = true
	gs.free_move = true
	for id: String in ["choko", "skea"]:
		var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.data = load("res://data/characters/%s.tres" % id)
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		var sk = f.skeletal
		var contact = sk.foot_contact
		check(contact.samples.Left.size() > 0 and contact.samples.Right.size() > 0, id + " real shoe geometry")
		print("shoe samples ", id, " ", contact.samples.Left.size(), " / ", contact.samples.Right.size())
		for wet: bool in [false, true]:
			gs.water = load("res://scripts/core/WaveField.gd").new() if wet else null
			if wet:
				gs.water.use_z = true
				gs.water.frame = 137
			for transform_case: int in 4:
				f.rotation.y = 1.2 if transform_case % 2 else 0.0
				f.scale = Vector3(1.1, 0.9, 1.2) if transform_case >= 2 else Vector3.ONE
				f.position = Vector3(2.0, 0.0, -0.7)
				f.position.y = f.floor_y()
				for attack: bool in [false, true]:
					if attack and id != "choko":
						continue
					f.state = Actor.State.ATTACK if attack else Actor.State.CROUCH
					f.current_move = f.data.crouch_light if attack else null
					for frame: int in [0, 5, 8]:
						f.move_frame = frame
						f.animator.tick(1.0 / 60.0, f, false)
						sk._physics_process(1.0 / 60.0)
						sk.retarget()
						var hips: Transform3D = sk.hero_skeleton.get_bone_global_pose(sk.hero_skeleton.find_bone("Hips"))
						var authority: Array = [f.transform, f.velocity, f.hp, f.state, f.move_frame]
						var before: Dictionary = {}
						for side: String in ["Left", "Right"]:
							before[side] = contact.penetration(side, gs.water)
						contact.apply(f, null)
						check(authority == [f.transform, f.velocity, f.hp, f.state, f.move_frame], "authority untouched")
						check(hips == sk.hero_skeleton.get_bone_global_pose(sk.hero_skeleton.find_bone("Hips")), "hips untouched")
						for side: String in ["Left", "Right"]:
							var after: float = independent_penetration(sk, side, gs.water)
							check(absf(after - contact.penetration(side, gs.water)) < 0.00001, "cached geometry agrees with full mesh")
							print("sole ", id, " ", wet, " ", attack, " ", frame, " ", side, " ", before[side], " -> ", after)
							check(after < 0.002, id + " shoe above sampled surface " + side)
		# Grounded throwing anticipation uses the same bounded shoe solve as a crouch.
		var Hook: GDScript = load("res://scripts/grapple/GrappleHook.gd")
		f.rotation = Vector3.ZERO
		f.scale = Vector3.ONE
		f.velocity = Vector3.ZERO
		f.state = Actor.State.GRAPPLE
		for wet: bool in [false, true]:
			gs.water = load("res://scripts/core/WaveField.gd").new() if wet else null
			if wet:
				gs.water.use_z = true
				gs.water.frame = 137
			f.position = Vector3(2.0, 0.0, -0.7)
			f.position.y = f.floor_y()
			f.state = Actor.State.IDLE
			for settling: int in 60:
				f.animator.tick(1.0 / 60.0, f, false)
				sk._physics_process(1.0 / 60.0)
			f.state = Actor.State.GRAPPLE
			f.grapple.anchor_point = f.position + Vector3(4.0, 6.0, 0.0)
			f.grapple.phase = Hook.Phase.WINDUP
			check(contact.permitted(f, null), id + " grounded windup permitted")
			for frame: int in 31:
				f.grapple.windup_progress = float(frame) / 30.0
				f.animator.tick(1.0 / 60.0, f, false)
				sk._physics_process(1.0 / 60.0)
				sk.retarget()
				var authority: Array = [f.transform, f.velocity, f.hp, f.state, f.grapple.phase, f.grapple.anchor_point]
				var hips: Transform3D = sk.hero_skeleton.get_bone_global_pose(sk.hero_skeleton.find_bone("Hips"))
				contact.apply(f, null)
				check(authority == [f.transform, f.velocity, f.hp, f.state, f.grapple.phase, f.grapple.anchor_point], "windup authority unchanged")
				check(hips == sk.hero_skeleton.get_bone_global_pose(sk.hero_skeleton.find_bone("Hips")), "windup pelvis unchanged")
				if frame % 6 == 0:
					for side: String in ["Left", "Right"]:
						var depth: float = independent_penetration(sk, side, gs.water)
						print("windup sole ", id, " wet=", wet, " frame=", frame, " ", side, " depth=", depth)
						check(depth < 0.002, id + " windup shoes clear real sampled surface")
			for phase: int in [Hook.Phase.FLIGHT, Hook.Phase.HANG]:
				f.grapple.phase = phase
				check(not contact.permitted(f, null), "flight and hang never foot-locked even near ground")
			f.grapple.phase = Hook.Phase.WINDUP
			f.position.y += 1.0
			check(not contact.permitted(f, null), "airborne windup excluded")
		f.grapple.phase = Hook.Phase.IDLE
		gs.water = null
		f.position = Vector3.ZERO
		for state: int in [Actor.State.IDLE, Actor.State.WALK, Actor.State.JUMP, Actor.State.LAUNCHED, Actor.State.ATTACK]:
			f.state = state
			f.current_move = f.data.ultimate
			var held: Array = poses(sk.hero_skeleton)
			contact.apply(f, null)
			check(poses(sk.hero_skeleton) == held, "excluded state " + str(state))
		f.state = Actor.State.CROUCH
		var ragdoll = load("res://scripts/fighter/BoneRagdoll.gd").new()
		check(not contact.permitted(f, ragdoll), "ragdoll excluded")
		ragdoll.free()
		var prior: Array = poses(sk.hero_skeleton)
		check(not contact._solve("Left", 5.0), "unreachable target rejected")
		check(poses(sk.hero_skeleton) == prior, "unreachable solve does not mutate")
		f.position.y = 1.0
		check(not contact.permitted(f, null), "airborne crouch excluded")
		f.position.y = 0.0
		f.airborne_attack = true
		check(not contact.permitted(f, null), "airborne attack excluded")
		f.airborne_attack = false
		var hip: int = sk.hero_skeleton.find_bone("Hips")
		var hip_position: Vector3 = sk.hero_skeleton.get_bone_pose_position(hip)
		sk.hero_skeleton.set_bone_pose_position(hip, hip_position + sk.hero_skeleton.global_basis.inverse() * Vector3(0.0, -0.8, 0.0))
		var too_deep: Array = poses(sk.hero_skeleton)
		check(contact.penetration("Left", null) > contact.MAX_LIFT, "over-cap fixture is deep")
		contact.apply(f, null)
		check(poses(sk.hero_skeleton) == too_deep, "over-cap corruption left visible")
		sk.hero_skeleton.set_bone_pose_position(hip, hip_position)
		f.frozen_frames = 3
		var held: Array = poses(sk.hero_skeleton)
		sk._on_mannequin_updated()
		check(poses(sk.hero_skeleton) == held, "freeze retains corrected drawing")
		f.frozen_frames = 0
		root.remove_child(f)
		sk._on_mannequin_updated()
		check(poses(sk.hero_skeleton) == held, "late skeleton update after tree removal is inert")
		f.free()
	gs.water = null
	print("FOOT CONTACT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func poses(skeleton: Skeleton3D) -> Array:
	var out: Array = []
	for i: int in skeleton.get_bone_count():
		out.append(skeleton.get_bone_pose(i))
	return out

func independent_penetration(sk, side: String, field) -> float:
	var mesh: MeshInstance3D = sk.hero_mesh
	var skeleton: Skeleton3D = sk.hero_skeleton
	var foot: int = skeleton.find_bone(side + "Foot")
	var toe: int = skeleton.find_bone(side + "ToeBase")
	var depth: float = -INF
	for surface: int in mesh.mesh.get_surface_count():
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride: int = indices.size() / vertices.size()
		for vertex: int in vertices.size():
			var point: Vector3 = Vector3.ZERO
			var shoe_weight: float = 0.0
			for i: int in stride:
				var index: int = vertex * stride + i
				var bind: int = indices[index]
				var bone: int = skeleton.find_bone(mesh.skin.get_bind_name(bind)) if mesh.skin.get_bind_name(bind) != &"" else mesh.skin.get_bind_bone(bind)
				if weights[index] <= 0.0 or bone < 0:
					continue
				point += skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(bind) * vertices[vertex] * weights[index]
				if bone == foot or bone == toe:
					shoe_weight += weights[index]
			if shoe_weight >= 0.5:
				point = skeleton.global_transform * point
				depth = maxf(depth, (field.height(point.x, point.z) if field != null else 0.0) - point.y)
	return depth
