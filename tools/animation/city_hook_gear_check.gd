extends SceneTree
## Dense actual CityFighter hook phases: fast catch/reel must preserve real cloth contacts.
const DT: float = 1.0 / 60.0
var checks: int = 0
var failures: int = 0
var samples: int = 0
var Actor: Script
var Hook: Script
var oracle: RefCounted

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_HOOK_GEAR: " + label)

func run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	Hook = load("res://scripts/grapple/GrappleHook.gd")
	oracle = load("res://../tools/equipment/skinned_cloth_oracle.gd").new()
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	root.get_node("GameState").water = null
	var fixture := Node3D.new()
	root.add_child(fixture)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	collision.shape = box
	floor_body.add_child(collision)
	floor_body.position.y = -0.5
	fixture.add_child(floor_body)
	var anchor := Node3D.new()
	fixture.add_child(anchor)
	anchor.add_to_group("grapple_anchor")
	var other := Node3D.new()
	fixture.add_child(other)
	other.add_to_group("grapple_anchor")
	for hero: String in ["choko", "skea"]:
		for scenario: String in ["high", "low", "transfer"]:
			var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
			f.set_script(load("res://scripts/world/CityFighter.gd"))
			f.data = load("res://data/characters/" + hero + ".tres")
			fixture.add_child(f)
			f.set_physics_process(false)
			f.skeletal.set_physics_process(false)
			f.grapple.registry.set_physics_process(false)
			f.grapple.registry.clear_match()
			f.control_locked = false
			f.forward = Vector3.FORWARD
			f.state = Actor.State.GRAPPLE
			anchor.position = Vector3(0, 2, -4) if scenario == "low" else Vector3(0, 6, -3)
			other.position = Vector3(4, 7, -2)
			await physics_frame
			if scenario == "transfer":
				f.position.y = 2.0
				anchor.position = Vector3(0, 6, 0)
				var token: int = f.grapple.registry.issue(1)
				f.grapple.registry.deploy(token, 1, anchor.position, f.position + Hook.HAND, (f.position + Hook.HAND).distance_to(anchor.position))
				f.grapple.fire(false, "grapple_parkour")
			else:
				f.grapple.fire(false, "grapple_parkour", {"point": anchor.position, "target_id": str(anchor.get_path())})
			check(f.grapple._responsive_traversal(), "real CityFighter activates the responsive profile")
			var sequence_samples: int = 0
			for frame: int in 80:
				if scenario == "transfer" and frame == 20:
					check(f.grapple.retarget({"point": other.position, "target_id": str(other.get_path())}), "real city transfer accepted")
				f.grapple.tick_regen(DT, true)
				if f.grapple.busy():
					f.grapple.drive(DT, true, frame >= 30 and frame < 70)
				var authority: Array = [f.transform, f.velocity, f.state, f.grapple.phase, f.grapple.rope_length, f.grapple.charges, f._rng.state]
				f.animator.tick(DT, f, false)
				f.skeletal._physics_process(DT)
				check(authority == [f.transform, f.velocity, f.state, f.grapple.phase, f.grapple.rope_length, f.grapple.charges, f._rng.state], "fast hook presentation preserves authority")
				if f.grapple.phase != Hook.Phase.HANG:
					continue
				# Every actual catch/reel tick, plus the fully settled original late frames.
				if frame <= 56 or frame in [60, 75]:
					var label: String = "%s/city_%s/%d" % [hero, scenario, frame]
					var sk: Skeleton3D = f.skeletal.hero_skeleton
					var poses: Array[Transform3D] = []
					for bone: int in sk.get_bone_count():
						poses.append(sk.get_bone_pose(bone))
					var cycle: float = f.skeletal.authored_hook.reel_cycle
					f.skeletal.retarget()
					var identical: bool = cycle == f.skeletal.authored_hook.reel_cycle
					for bone: int in sk.get_bone_count():
						identical = identical and poses[bone] == sk.get_bone_pose(bone)
					check(identical, "repeated render keeps supported pose and cycle " + label)
					for side: String in ["Left", "Right"]:
						for pair: Array in [[side + "Arm", side + "ForeArm"], [side + "ForeArm", side + "Hand"]]:
							var a: int = sk.find_bone(pair[0])
							var b: int = sk.find_bone(pair[1])
							var length: float = sk.get_bone_global_pose(a).origin.distance_to(sk.get_bone_global_pose(b).origin)
							var rest: float = sk.get_bone_global_rest(a).origin.distance_to(sk.get_bone_global_rest(b).origin)
							check(absf(length - rest) < 0.0001, "actual arm length retained " + label + pair[0])
					check(oracle.sample(f, label) == 0, "no cloth/body triangle intersections " + label)
					check(oracle.invalid_shapes == 0, "real nonempty valid cloth pins " + label)
					check(oracle.pin_margin > 0.0005 and oracle.pin_margin < 0.004, "positive actual pin clearance .5..4mm " + label)
					check(f.skeletal.authored_hook.grip_error < 0.04, "actual physical rope grip remains within4cm " + label)
					samples += 1
					sequence_samples += 1
			check(sequence_samples >= 20, "dense catch/reel phase coverage " + hero + scenario)
			f.grapple.registry.clear_match()
			f.free()
	oracle = null
	fixture.free()
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("CITY_HOOK_GEAR_COMPLETE checks=%d failures=%d samples=%d" % [checks, failures, samples])
	quit(1 if failures else 0)
