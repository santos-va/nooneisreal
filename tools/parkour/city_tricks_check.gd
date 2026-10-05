extends SceneTree
## Exercise the shipped controller and InputRouter against actual static collisions.
const DT: float = 1.0 / 60.0
var checks: int = 0
var failures: int = 0
var actor: Node3D
var input: Node
var solids: Node3D
var floor_body: StaticBody3D
var FighterScript: Script

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_TRICKS: " + label)

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

func step(count: int = 1) -> void:
	for index: int in count:
		await physics_frame
		actor._physics_process(DT)

func air(point: Vector3, velocity: Vector3 = Vector3(0, 1, 0)) -> void:
	input.v_clear(1)
	actor.restart_at(point)
	actor.position = point
	actor._set_state(FighterScript.State.JUMP)
	actor.velocity = velocity
	input.set_view_basis(1, Vector3.FORWARD)

func roll_start(point: Vector3 = Vector3(0, 0.16, 8)) -> bool:
	air(point, Vector3(0, -9, -5))
	input.v_set(1, "up", true)
	input.v_set(1, "crouch", true)
	await step(3)
	return actor.parkour.phase == "landing_roll"

func run() -> void:
	await process_frame
	FighterScript = load("res://scripts/fighter/Fighter.gd")
	var game: Node = root.get_node("GameState")
	game.skeletal_rig = false
	game.free_move = true
	game.water = null
	input = root.get_node("InputRouter")
	solids = Node3D.new()
	root.add_child(solids)
	floor_body = box(Vector3(0,-0.5,5),Vector3(30,1,30))
	box(Vector3(0,4,0),Vector3(8,8,1))
	box(Vector3(-10,1,0),Vector3(4,2,4))
	box(Vector3(10,2,0),Vector3(.35,.3,4))
	var slope: StaticBody3D = box(Vector3(10,2,8),Vector3(5,.5,5))
	slope.rotation.x = 0.4
	await physics_frame
	for hero: String in ["choko", "skea"]:
		actor = load("res://scenes/fighter/Fighter.tscn").instantiate()
		actor.set_script(load("res://scripts/world/CityFighter.gd"))
		actor.data = load("res://data/characters/" + hero + ".tres")
		root.add_child(actor)
		actor.set_physics_process(false)
		air(Vector3(0,2,1.0))
		input.v_set(1,"down",true)
		input.v_press(1,"jump")
		await step()
		check(not actor.parkour.kick_spent, hero + " initial held jump cannot kick")
		input.v_release(1,"jump")
		await step()
		input.v_press(1,"jump")
		await step()
		check(actor.parkour.phase == "wall_kick" and actor.parkour.kick_spent, hero + " fresh away jump kicks real wall")
		check(actor.velocity.z > 5 and actor.velocity.y > 6, hero + " bounded kick impulse points away and up")
		check(actor.parkour.wall_spent and actor.parkour.grip_spent, hero + " kick cannot recharge climbing effort")
		check(actor.parkour_snapshot().get("speed",0.0) > 1, hero + " kick metadata reports physical displacement")
		var invulnerability: int = actor.invulnerable_frames
		input.v_release(1,"jump")
		await step()
		input.v_press(1,"jump")
		await step()
		check(actor.velocity.y < 7.4 and actor.invulnerable_frames == invulnerability, hero + " repeated kick adds no second impulse or invulnerability")
		actor.set_control(false)
		check(actor.parkour.phase.is_empty() and actor.parkour_snapshot().is_empty(), hero + " lock clears kick immediately")
		air(Vector3(0,2,8))
		input.v_set(1,"down",true)
		await step()
		input.v_press(1,"jump")
		await step()
		check(not actor.parkour.kick_spent, hero + " empty air is not a kick surface")
		air(Vector3(0,2,1))
		input.v_set(1,"up",true)
		await step()
		input.v_press(1,"jump")
		await step()
		check(not actor.parkour.kick_spent, hero + " pushing into wall does not kick away unexpectedly")
		air(Vector3(-10,.5,2.7))
		input.v_set(1,"up",true)
		input.v_press(1,"jump")
		await step()
		check(actor.parkour.phase == "hang", hero + " ledge hang kick fixture")
		input.v_release(1,"jump")
		await step()
		input.v_set(1,"up",false)
		input.v_set(1,"down",true)
		var backstop: StaticBody3D = box(Vector3(-10,2,2.93),Vector3(4,4,.1))
		await physics_frame
		input.v_press(1,"jump")
		await step()
		check(actor.parkour.phase == "hang" and not actor.parkour.kick_spent, hero + " obstructed away kick stays hanging instead of mantling")
		backstop.queue_free()
		await physics_frame
		input.v_release(1,"jump")
		await step()
		input.v_press(1,"jump")
		await step()
		check(actor.parkour.phase == "wall_kick" and actor.velocity.z > 5, hero + " fresh away jump exits hang as kick")
		if hero == "skea":
			air(Vector3(0,2,1))
			input.v_set(1,"up",true)
			input.v_press(1,"jump")
			await step()
			check(actor.parkour.phase == "wall_run", "Skea wall-run kick fixture")
			input.v_release(1,"jump")
			await step()
			input.v_set(1,"up",false)
			input.v_set(1,"down",true)
			input.v_press(1,"jump")
			await step()
			check(actor.parkour.phase == "wall_kick", "Skea kick accepts fresh press immediately after release ends wall run")
		air(Vector3(0,2,1))
		input.v_set(1,"down",true)
		await step()
		var ceiling: StaticBody3D = box(Vector3(0,3.88,1.4),Vector3(3,0.1,2))
		await physics_frame
		input.v_press(1,"jump")
		await step()
		check(not actor.parkour.kick_spent, hero + " blocked launch capsule rejects kick")
		ceiling.queue_free()
		await physics_frame
		check(await roll_start(), hero + " crouch on actual fast touchdown starts roll")
		check(actor.invulnerable_frames == 0 and not actor.dodging, hero + " roll is not combat dodge")
		var speed_before: float = Vector2(actor.velocity.x,actor.velocity.z).length()
		var point_before: Vector3 = actor.position
		await step(10)
		check(actor.position.distance_to(point_before) > 0.2, hero + " roll carries real horizontal momentum")
		check(Vector2(actor.velocity.x,actor.velocity.z).length() < speed_before, hero + " roll only decelerates")
		check(actor.parkour_snapshot().get("floor_normal",Vector3.ZERO).dot(Vector3.UP) > .95, hero + " roll metadata reports real flat support")
		input.v_release(1,"crouch")
		await step()
		check(actor.parkour.phase != "landing_roll", hero + " crouch release cancels roll")
		check(await roll_start(), hero + " roll can start in new supported cycle")
		actor.motion_revision += 1
		actor.parkour.prepare(actor)
		check(actor.parkour.phase.is_empty(), hero + " motion revision clears roll")
		check(await roll_start(), hero + " roll reset fixture")
		actor.set_control(false)
		check(actor.parkour_snapshot().is_empty(), hero + " control lock clears roll")
		check(await roll_start(), hero + " modal interruption roll fixture")
		input.acquire_ui(solids)
		actor.parkour.prepare(actor)
		check(actor.parkour.phase.is_empty(), hero + " modal input owner clears roll")
		input.release_ui(solids)
		check(await roll_start(), hero + " rope interruption roll fixture")
		# Recovery coexists with ground state; WINDUP is correctly detached by Fighter
		# unless State.GRAPPLE owns it, which would already clear the roll.
		actor.grapple.phase = 4 # MISS_REWIND
		actor.grapple.recovery_remaining = 2.0
		actor.grapple._recovery_total = 2.0
		actor.grapple.projectile_position = actor.position + Vector3.UP * 2.0
		await step()
		check(actor.parkour.phase.is_empty(), hero + " busy hook prevents simultaneous roll")
		actor.grapple.phase = 0
		air(Vector3(0,.12,8),Vector3(0,-1,-5))
		input.v_set(1,"up",true)
		input.v_set(1,"crouch",true)
		await step(5)
		check(actor.parkour.phase != "landing_roll", hero + " small step never starts roll")
		air(Vector3(0,.12,8),Vector3(0,-9,0))
		input.v_set(1,"crouch",true)
		await step(3)
		check(actor.parkour.phase != "landing_roll", hero + " stationary drop does not invent momentum")
		check(not await roll_start(Vector3(10,2.31,0)), hero + " narrow support cannot carry full roll footprint")
		check(not await roll_start(Vector3(10,2.43,8)), hero + " steep floor rejects authored roll")
		check(await roll_start(Vector3(0,.16,1.3)), hero + " wall collision roll fixture")
		await step(25)
		check(actor.position.z >= .84 and actor.parkour.phase != "landing_roll", hero + " roll capsule cannot pass wall")
		check(await roll_start(), hero + " removed support roll fixture")
		floor_body.collision_layer = 0
		await step(3)
		check(actor.parkour.phase.is_empty(), hero + " removed support aborts roll")
		floor_body.collision_layer = 1
		await physics_frame
		check(await roll_start(Vector3(10,.16,-9.25)), hero + " supported edge approach begins roll")
		await step(10)
		check(actor.parkour.phase != "landing_roll", hero + " incomplete destination footprint exits roll before roof edge")
		check(await roll_start(), hero + " finite roll duration fixture")
		await step(40)
		check(actor.parkour.phase != "landing_roll", hero + " hold cannot extend roll duration")
		check(await roll_start(), hero + " jump interruption roll fixture")
		input.v_press(1,"jump")
		await step()
		check(actor.state == FighterScript.State.JUMP and actor.parkour.phase.is_empty(), hero + " queued jump interrupts roll and preserves normal action")
		actor.queue_free()
		await process_frame
	input.v_clear(1)
	solids.queue_free()
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	var drain_until_ms: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < drain_until_ms:
		await process_frame
		OS.delay_msec(1)
	print("CITY_TRICKS_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
