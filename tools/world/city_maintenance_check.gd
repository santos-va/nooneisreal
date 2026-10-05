extends SceneTree
## Real InputRouter -> CityFighter walking over shipped geometry, never waypoint teleports.
var checks: int = 0
var failures: int = 0
var input: Node
var fighter: Node3D
var district: CityDistrict

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_MAINTENANCE: " + label)

func tick() -> void:
	await physics_frame
	fighter._physics_process(1.0 / 60.0)

func walk(target: Vector3, label: String, limit: int = 500) -> bool:
	var reached: bool = false
	for frame: int in limit:
		var delta: Vector3 = target - fighter.position
		delta.y = 0
		if delta.length() <= 0.13:
			reached = true
			break
		input.set_view_basis(1, delta.normalized())
		input.v_set(1, "up", true)
		await tick()
	input.v_set(1, "up", false)
	for frame: int in 10:
		await tick()
	check(reached and absf(fighter.position.y-target.y) < 0.16, label + " reached actual floor at " + str(fighter.position))
	return reached

func ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.exclude = [fighter.get_rid()]
	return district.get_world_3d().direct_space_state.intersect_ray(query)

func run() -> void:
	await process_frame
	var game: Node = root.get_node("GameState")
	game.skeletal_rig = false
	game.free_move = true
	game.water = null
	input = root.get_node("InputRouter")
	district = load("res://scenes/world/CityDistrict.tscn").instantiate()
	root.add_child(district)
	for hero: String in ["choko", "skea"]:
		var base: Node3D = load("res://scenes/fighter/Fighter.tscn").instantiate()
		base.set_script(load("res://scripts/world/CityFighter.gd"))
		fighter = base
		fighter.data = load("res://data/characters/" + hero + ".tres")
		root.add_child(fighter)
		fighter.set_physics_process(false)
		fighter.restart_at(CityLayout.spawn_position())
		input.v_clear(1)
		district.maintenance.set_story_shortcut_open(false)
		for frame: int in 12:
			await tick()
		# Start at the shipped entrance and walk the complete original east approach.
		for point: Vector3 in [Vector3.ZERO, Vector3(18,0,10), Vector3(18,0,8),
			Vector3(18,4,-10), Vector3(20,4,-20), Vector3(0,4,-20), Vector3(-20,4,-20),
			Vector3(-24,4,-19), Vector3(-29,4,-19), Vector3(-29,4,-13.95)]:
			if not await walk(point, hero + " original roof route"):
				break
		check(not ray(Vector3(-29,5.1,-13.95),Vector3(-26.4,5.1,-13.95)).is_empty(), hero + " closed gate blocks eye ray")
		input.set_view_basis(1, Vector3.RIGHT)
		input.v_set(1,"up",true)
		for frame: int in 70:
			await tick()
		input.v_set(1,"up",false)
		check(fighter.position.x < -27.75, hero + " actual capsule cannot cross closed leaf")
		# Retreat on the roof, approach the service ramp from its low end, no jumps.
		for point: Vector3 in [Vector3(-29,4,-13.95), Vector3(-29,4,-19.5), Vector3(-16,4,-20),
			Vector3(-16,4,-10.55), Vector3(-19,4,-10.55)]:
			if not await walk(point, hero + " bypass approach"):
				break
		for point: Vector3 in CityMaintenance.bypass_route():
			if not await walk(point, hero + " closed-gate bypass"):
				break
		check(not district.maintenance.story_shortcut_open(), hero + " walking never awards gate state")
		for id: String in ["clue_b", "mechanism"]:
			var marker: Node3D = district.maintenance.story_points()[id]
			await walk(Vector3(-26.35,4,marker.position.z), hero + " reach " + id)
			check(ray(fighter.position + Vector3.UP*1.1, marker.global_position).is_empty(), hero + " real close evidence LOS " + id)
		await walk(Vector3(-26.4,4,-13.95), hero + " inside leaf")
		district.maintenance.set_story_shortcut_open(true)
		await tick()
		check(ray(Vector3(-29,5.1,-13.95),Vector3(-26.4,5.1,-13.95)).is_empty(), hero + " open gate removes actual eye obstruction")
		check(district.maintenance.get_node("ServiceGate").position.y > 7, hero + " visible leaf stays raised in world")
		await walk(Vector3(-29,4,-13.95), hero + " open shortcut crosses real capsule")
		await walk(CityMaintenance.safe_checkpoint_position(), hero + " independent safe checkpoint")
		# Closed again, the old west descent remains usable as well.
		district.maintenance.set_story_shortcut_open(false)
		for point: Vector3 in [Vector3(-29,4,-10), Vector3(-29,0,8), Vector3(-29,0,10)]:
			await walk(point, hero + " old west exit")
		input.v_clear(1)
		fighter.queue_free()
		await process_frame
	district.queue_free()
	for singleton: String in ["Sfx","UltMusic","Music"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("CITY_MAINTENANCE_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
