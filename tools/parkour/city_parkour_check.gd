extends SceneTree
## Actual city motor/body collision plus InputRouter lifecycle checks. No render dependency.
const DT: float = 1.0 / 60.0
var checks: int = 0
var failures: int = 0
var f: Node3D
var input: Node
var solids: Node3D
var actor_script: Script

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_PARKOUR: " + label)

func box(point: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var geometry := BoxShape3D.new()
	geometry.size = size
	shape.shape = geometry
	body.add_child(shape)
	solids.add_child(body)
	body.position = point
	return body

func setup_air(point: Vector3) -> void:
	input.v_clear(1)
	f.restart_at(point)
	f.position = point
	f._set_state(actor_script.State.JUMP)
	f.velocity = Vector3.UP
	f._wish = Vector3.FORWARD

func tick(held: bool = true, block: bool = false) -> bool:
	return f.parkour.tick(f, DT, {"axis":0.0,"jump_held":held,"block":block,"crouch":false})

func run() -> void:
	await process_frame
	actor_script = load("res://scripts/fighter/Fighter.gd")
	var game: Node = root.get_node("GameState")
	game.skeletal_rig = false
	game.free_move = true
	game.water = null
	input = root.get_node("InputRouter")
	solids = Node3D.new()
	root.add_child(solids)
	box(Vector3(0,-0.5,0), Vector3(60,1,60))
	var ledge: StaticBody3D = box(Vector3(0,1,0), Vector3(4,2,4))
	var wall: StaticBody3D = box(Vector3(10,6,0), Vector3(4,12,4))
	box(Vector3(-10,1,0), Vector3(0.3,2,4))
	box(Vector3(-15,1,0), Vector3(4,2,0.4))
	await physics_frame
	for hero: String in ["choko", "skea"]:
		f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.set_script(load("res://scripts/world/CityFighter.gd"))
		f.data = load("res://data/characters/" + hero + ".tres")
		root.add_child(f)
		f.set_physics_process(false)
		setup_air(Vector3(0,0.5,2.7))
		check(not tick(false), hero + " no opt-in means no grab")
		check(tick() and f.parkour.phase == "hang", hero + " catches real broad ledge")
		check(f.position.y > 0.3 and f.position.z > 2.35, hero + " hang keeps capsule outside solid")
		check(f.parkour_snapshot().get("phase", "") == "hang", hero + " snapshot published")
		check(float(f.parkour_snapshot().get("hold_remaining",0.0)) > 2.9, hero + " finite grip reports remaining time")
		input.v_press(1,"jump")
		tick()
		check(f.parkour.phase == "hang", hero + " held initial press never auto-mantles")
		input.v_release(1,"jump")
		tick(false)
		input.v_press(1,"jump")
		tick()
		check(f.parkour.phase == "mantle", hero + " release and fresh press start mantle")
		for index: int in 32:
			await physics_frame
			tick()
		check(f.parkour.phase.is_empty() and f.position.y >= 2.0 and f.position.z < 2.0, hero + " full swept mantle reaches top")
		# Overhead, too-thin grips and late inserted obstacles are distinct clearance failures.
		setup_air(Vector3(0,0.5,2.7))
		var ceiling: StaticBody3D = box(Vector3(0,3.6,1.4),Vector3(4,0.2,4))
		await physics_frame
		tick()
		check(f.parkour.phase != "hang", hero + " low ceiling rejects mantle path")
		ceiling.queue_free()
		await physics_frame
		setup_air(Vector3(-10,0.5,2.7))
		tick()
		check(f.parkour.phase != "hang", hero + " narrow surface cannot support both grips")
		setup_air(Vector3(-15,0.5,0.9))
		tick()
		check(f.parkour.phase != "hang", hero + " shallow surface cannot support landing")
		setup_air(Vector3(0,0.5,2.7))
		check(tick() and f.parkour.phase == "hang", hero + " clear ceiling restores catch")
		ceiling = box(Vector3(0,3.6,1.4),Vector3(4,0.2,4))
		await physics_frame
		tick(false)
		input.v_press(1,"jump")
		tick()
		check(f.parkour.phase == "hang", hero + " late ceiling blocks mantle")
		ceiling.queue_free()
		await physics_frame
		check(not tick(true,true) and f.parkour.phase.is_empty(), hero + " block releases hang")
		check(not tick() or f.parkour.phase != "hang", hero + " release cannot regrab without touchdown")
		setup_air(Vector3(0,0.5,2.7))
		tick()
		ledge.collision_layer = 0
		await physics_frame
		tick()
		check(f.parkour.phase.is_empty(), hero + " disabled support never suspends body")
		ledge.collision_layer = 1
		await physics_frame
		setup_air(Vector3(0,0.5,2.7))
		tick()
		ledge.position.x += 1.0
		await physics_frame
		tick()
		check(f.parkour.phase.is_empty(), hero + " moved support drops")
		ledge.position.x -= 1.0
		await physics_frame
		setup_air(Vector3(0,0.5,2.7))
		tick()
		f.set_control(false)
		f.parkour.prepare(f)
		check(f.parkour.phase.is_empty() and f.parkour_snapshot().is_empty(), hero + " control lock clears support")
		setup_air(Vector3(0,0.5,2.7))
		tick()
		f.motion_revision += 1
		f.parkour.prepare(f)
		check(f.parkour.phase.is_empty(), hero + " rewind revision invalidates support")
		setup_air(Vector3(0,0.5,2.7))
		tick()
		for index: int in 182:
			tick()
		check(f.parkour.phase != "hang" and f.parkour.grip_spent, hero + " finite hang cannot immediately reattach")
		setup_air(Vector3(10,0.2,2.7))
		tick()
		check((f.parkour.phase == "wall_run") == (hero == "skea"), hero + " wall steps character boundary")
		if hero == "skea":
			var bottom: float = f.position.y
			for index: int in 45:
				await physics_frame
				tick()
			check(f.position.y > bottom + 2.0 and f.position.y < bottom + 3.6, "Skea bounded vertical gain")
			check(f.parkour.phase.is_empty() and f.parkour.wall_spent, "Skea effort expires")
			f.velocity.y = 10.0
			tick()
			check(f.parkour.phase.is_empty(), "repeated jump cannot reset wall budget")
			f.restart_at(Vector3(10,0.2,2.7))
			check(not f.parkour.wall_spent, "checkpoint reset clears wall effort")
		f.queue_free()
		await process_frame
	# Actual InputRouter -> Fighter physics on the shipped practice ledge.
	solids.queue_free()
	await physics_frame
	var district: Node3D = load("res://scenes/world/CityDistrict.tscn").instantiate()
	root.add_child(district)
	f = load("res://scenes/fighter/Fighter.tscn").instantiate()
	f.set_script(load("res://scripts/world/CityFighter.gd"))
	f.data = load("res://data/characters/choko.tres")
	root.add_child(f)
	f.set_physics_process(false)
	input.v_clear(1)
	f.restart_at(Vector3(4,0,18.2))
	for index: int in 12:
		await physics_frame
		f._physics_process(DT)
	input.v_set(1,"up",true)
	input.v_press(1,"jump")
	var caught: bool = false
	for index: int in 50:
		await physics_frame
		f._physics_process(DT)
		if f.parkour.phase == "hang":
			caught = true
			break
	check(caught, "real input catches shipped practice ledge")
	input.v_release(1,"jump")
	await physics_frame
	f._physics_process(DT)
	input.v_press(1,"jump")
	for index: int in 34:
		await physics_frame
		f._physics_process(DT)
	check(f.position.y >= 2.8 and f.position.z < 17.0, "real input climbs shipped practice ledge")
	for route: Dictionary in [
		{"start":Vector3(12,0,-3.3),"top":2.0,"front":-4.4},
		{"start":Vector3(12,2,-6.65),"top":4.0,"front":-7.2},
	]:
		input.v_clear(1)
		f.restart_at(route.start)
		for index: int in 12:
			await physics_frame
			f._physics_process(DT)
		input.v_set(1,"up",true)
		input.v_press(1,"jump")
		caught = false
		for index: int in 50:
			await physics_frame
			f._physics_process(DT)
			if f.parkour.phase == "hang":
				caught = true
				break
		check(caught, "real input catches roof route top %.1f" % float(route.top))
		input.v_release(1,"jump")
		await physics_frame
		f._physics_process(DT)
		input.v_press(1,"jump")
		for index: int in 34:
			await physics_frame
			f._physics_process(DT)
		check(f.position.y >= float(route.top) and f.position.z < float(route.front), "real input climbs roof route top %.1f" % float(route.top))
	# The actual building trim is collision, not an invisible visual penetration allowance.
	var trim_query := PhysicsRayQueryParameters3D.create(Vector3(14,1.5,31),Vector3(14,1.5,29.5),1)
	trim_query.exclude = [f.get_rid()]
	var trim: Dictionary = district.get_world_3d().direct_space_state.intersect_ray(trim_query)
	check(not trim.is_empty() and float(trim.position.z) >= 30.19, "real pilaster collision matches outward visible plane")
	f.queue_free()
	await process_frame
	f = load("res://scenes/fighter/Fighter.tscn").instantiate()
	f.set_script(load("res://scripts/world/CityFighter.gd"))
	f.data = load("res://data/characters/skea.tres")
	root.add_child(f)
	f.set_physics_process(false)
	input.v_clear(1)
	input.set_view_basis(1,Vector3.FORWARD)
	f.restart_at(Vector3(14,0,31.25))
	for index: int in 8:
		await physics_frame
		f._physics_process(DT)
	input.v_set(1,"up",true)
	input.v_press(1,"jump")
	var wall_frames: int = 0
	for index: int in 65:
		await physics_frame
		f._physics_process(DT)
		if f.parkour.phase == "wall_run":
			wall_frames += 1
			check(f.position.z >= 30.54, "wall-run capsule remains outside pilaster")
	check(wall_frames > 0, "real input runs on shipped protruding pilaster")
	check(wall_frames <= 40, "real trim support cannot recharge effort in air")
	input.v_clear(1)
	f.queue_free()
	district.queue_free()
	for singleton: String in ["Sfx","UltMusic","Music"]:
		root.get_node(singleton).queue_free()
	# Ogg playback retires on audio-mixer wall time, not accelerated --fixed-fps ticks.
	# Keep normal teardown and real playback; give the mixer time to release its references.
	var drain_until_ms: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < drain_until_ms:
		await process_frame
		OS.delay_msec(1)
	print("CITY_PARKOUR_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
