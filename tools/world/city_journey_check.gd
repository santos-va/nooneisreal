extends SceneTree
## Real floor/clearance, named-save adversaries and full scene re-entry for both heroes.
const SAVE := "user://journey_probe.json"
var checks: int = 0
var failures: int = 0
var Journey: GDScript
var gs: Node

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_JOURNEY: " + label)

func ticks(count: int) -> void:
	for frame: int in count:
		await physics_frame
		await process_frame

func write_raw(raw: String) -> void:
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(raw)
	file.close()

func enter(hero: String) -> Node3D:
	gs.p1_character = hero
	var city: Node3D = load("res://scenes/world/CityWorld.tscn").instantiate()
	city.journey_save_path = SAVE
	root.add_child(city)
	current_scene = city
	return city

func leave(city: Node3D) -> void:
	current_scene = null
	city.queue_free()
	await ticks(2)

func _run() -> void:
	await process_frame
	gs = root.get_node("GameState")
	Journey = load("res://scripts/world/CityJourney.gd")
	gs.skeletal_rig = false
	DirAccess.remove_absolute(SAVE)
	var model: Node = Journey.new()
	model.setup("choko", false)
	check(model.checkpoint_id() == "spawn", "old save with no journey starts at entrance")
	check(model.restore({"version": 1, "heroes": {"choko": "grocer", "skea": "roof_bridge"}}), "valid two hero snapshot")
	var good: Dictionary = model.snapshot()
	for bad: Variant in [null, [], {"version": true, "heroes": {}}, {"version": "1", "heroes": {}}, {"version": 1.5, "heroes": {}}, {"version": 2, "heroes": {}}, {"version": 1, "heroes": {"other": "spawn"}}, {"version": 1, "heroes": {"choko": "../../bad"}}, {"version": 1, "heroes": {"choko": [0, 99, 0]}}, {"version": 1, "heroes": {"choko": "spawn"}, "position": [0, 99, 0]}, {"version": 1, "heroes": {"choko": "spawn", "skea": 5}}]:
		check(not model.restore(bad), "reject unsafe schema " + str(bad))
		check(model.snapshot() == good, "invalid restore is all-or-nothing")
	model.free()
	for raw: String in ["{broken", JSON.stringify({"version": 1, "heroes": {"choko": "missing"}}), "x".repeat(4097)]:
		write_raw(raw)
		model = Journey.new()
		model.setup("choko", true, SAVE)
		check(not model.save_ok and not model.save_enabled and model.checkpoint_id() == "spawn", "malformed uses safe runtime default")
		model.restart_walk()
		check(FileAccess.get_file_as_string(SAVE) == raw, "malformed bytes survive restart and save attempt")
		model.free()
	DirAccess.remove_absolute(SAVE)
	for hero: String in Journey.HEROES:
		var city: Node3D = enter(hero)
		await ticks(12)
		check(city.player.on_ground(), hero + " initial support")
		for place: Dictionary in Journey.checkpoints():
			city.player.restart_at(place.position)
			await ticks(45)
			var p: CharacterBody3D = city.player
			check(p.is_on_floor() and absf(p.position.y - float(place.position.y)) < 0.08, hero + " actual grounded " + place.id)
			check(Vector2(p.position.x - float(place.position.x), p.position.z - float(place.position.z)).length() < 0.05, hero + " no lateral penetration correction " + place.id)
			var body: CollisionShape3D = p.get_node("BodyShape")
			var shape: Shape3D = body.shape
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.transform = body.global_transform
			query.transform.origin.y += 0.01 # Avoid the supporting floor contact itself.
			query.collision_mask = 1
			query.exclude = [p.get_rid()]
			check(p.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), hero + " body clearance " + place.id)
			check(city.journey.checkpoint_id() == place.id, hero + " dwell activates " + place.id)
			print("JOURNEY_SUPPORT hero=%s id=%s position=%s" % [hero, place.id, p.position])
		# Under the roof is grounded, but must not activate the checkpoint above it.
		city.player.restart_at(Vector3(0, 0, -20))
		await ticks(45)
		check(city.journey.checkpoint_id() == "workshop", hero + " roof rejects same XZ at street height")
		city.player.restart_at(Vector3(0, 7, -20))
		await ticks(2)
		check(city.journey.checkpoint_id() == "workshop", hero + " airborne cannot activate roof")
		# Attached, busy and transient grounded visits do not replace a prior safe place.
		city.player.restart_at(Journey.place("grocer").position)
		await ticks(10)
		check(city.journey.checkpoint_id() == "workshop", hero + " short grounded visit does not activate")
		city.set_physics_process(false)
		city.player.set_physics_process(false)
		city.player.grapple.attached = true
		city.journey.observe(city.player, 1.0)
		check(city.journey.checkpoint_id() == "workshop", hero + " attached rejects activation")
		city.player.grapple.attached = false
		city.player.grapple.phase = city.player.grapple.Phase.MISS_REWIND
		city.journey.observe(city.player, 1.0)
		check(city.journey.checkpoint_id() == "workshop", hero + " winding rejects activation")
		city.player.grapple.reset()
		city.player.set_physics_process(true)
		city.set_physics_process(true)
		# Separate scene objects prove return/re-entry, not just in-memory serialization.
		for destination: String in ["grocer", "roof_bridge"]:
			city.player.restart_at(Journey.place(destination).position)
			await ticks(45)
			check(city.journey.checkpoint_id() == destination and city.journey.save_ok, hero + " saved destination " + destination)
			var saved_bytes: String = FileAccess.get_file_as_string(SAVE)
			await ticks(35)
			check(FileAccess.get_file_as_string(SAVE) == saved_bytes and not FileAccess.file_exists(SAVE + ".tmp"), hero + " stable snapshot/no leftover temp")
			city.player.velocity = Vector3(4, 8, 2)
			city.player.grapple.attached = true
			await leave(city)
			city = enter(hero)
			await ticks(12)
			check(city.player.global_position.distance_to(Journey.place(destination).position) < 0.1, hero + " re-enter resumes " + destination)
			check(city.player.is_on_floor() and city.player.velocity.length() < 0.1 and not city.player.grapple.busy() and not city.player.grapple.attached, hero + " re-enter clears runtime motion")
			city.player.global_position.y = -20
			await ticks(12)
			check(city.journey.checkpoint_id() == destination and city.player.position.distance_to(Journey.place(destination).position) < 0.1, hero + " fall keeps last safe destination")
		city.restart_exploration()
		await ticks(45)
		check(city.journey.checkpoint_id() == "spawn" and city.player.position.distance_to(Vector3(0, 0, 23)) < 0.1, hero + " explicit restart resets entrance")
		# Leave distinct hero positions to check isolation after the loop.
		city.player.restart_at(Journey.place("grocer" if hero == "choko" else "roof_bridge").position)
		await ticks(45)
		await leave(city)
	for hero: String in Journey.HEROES:
		var city: Node3D = enter(hero)
		await ticks(12)
		check(city.journey.checkpoint_id() == ("grocer" if hero == "choko" else "roof_bridge"), hero + " separate saved journey")
		await leave(city)
	DirAccess.remove_absolute(SAVE)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("CITY_JOURNEY_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
