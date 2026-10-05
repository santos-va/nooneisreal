extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("NPC_RUNTIME: " + label)
func ticks(count: int) -> void:
	for frame: int in count:
		await physics_frame
		await process_frame
func _run() -> void:
	await process_frame
	root.get_node("GameState").skeletal_rig = false
	var city: Node3D = load("res://scenes/world/CityWorld.tscn").instantiate()
	root.add_child(city)
	current_scene = city
	var director = city.npc_director
	director.save_enabled = false
	city.progress.save_enabled = false
	director.active_radius = 45.0
	director.population.initialize(123456)
	city.player.global_position = Vector3(0, 0, 5)
	director._refresh_actors()
	await ticks(5)
	check(director.actors.size() > 0 and director.actors.size() <= 12, "bounded nearby population")
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.7
	for index: int in director.actors:
		var actor: Node3D = director.actors[index]
		for point: Vector3 in actor.route:
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.collision_mask = 1
			query.exclude = [city.player.get_rid()]
			query.transform.origin = point + Vector3(0, 0.9, 0)
			check(city.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "pedestrian route clear %d/%s" % [index, point])
	var starts: Dictionary = {}
	var excursions: Dictionary = {}
	for index: int in director.actors:
		starts[index] = director.actors[index].position
		excursions[index] = 0.0
	var minimum_gap: float = INF
	var routes_clear: bool = true
	for sample: int in 24:
		await ticks(30)
		for index: int in director.actors:
			excursions[index] = maxf(excursions[index], director.actors[index].position.distance_to(starts[index]))
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.collision_mask = 1
			query.exclude = [city.player.get_rid()]
			query.transform.origin = director.actors[index].global_position + Vector3(0, 0.9, 0)
			routes_clear = routes_clear and city.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
			for other: int in director.actors:
				if other > index:
					minimum_gap = minf(minimum_gap, director.actors[index].position.distance_to(director.actors[other].position))
	check(minimum_gap > 1.5, "residents retain personal space across route and greetings")
	check(routes_clear, "moving residents remain outside district collision")
	for index: int in starts:
		check(excursions[index] > 0.5 if index >= 3 else excursions[index] < 0.01, "wanderers move and workers retain their station %d" % index)
	check(director.population.people.any(func(p: Dictionary) -> bool: return p.memory.any(func(fact: Dictionary) -> bool: return fact.kind == "neighbour")), "nearby residents exchange grounded memories")
	var social_snapshot: Dictionary = director.population.snapshot()
	director._update_conversations()
	check(director.population.snapshot() == social_snapshot, "social cooldown prevents greeting spam")
	var first: Node3D = director.actors[3]
	city.player.global_position = first.global_position + Vector3(0, 0, 1.0)
	await ticks(2)
	check(director.find_nearest() == 3, "nearby resident selectable")
	director.dialogue.show_fact(director.population.meet(0))
	check(root.get_node("InputRouter").ui_suppressed(), "conversation owns gameplay input")
	director.dialogue.close()
	check(not root.get_node("InputRouter").ui_suppressed(), "closing releases gameplay input")
	var seed_before: int = director.population.people[3].appearance_seed
	var position_before: Vector3 = first.position
	city.player.global_position = Vector3(30, 4, -25)
	director.active_radius = 12.0
	director._refresh_actors()
	await ticks(2)
	check(not director.actors.has(3), "distant actor chunk unloads")
	city.player.global_position = Vector3(0, 0, 10)
	director.active_radius = 45.0
	director._refresh_actors()
	check(director.actors.has(3) and director.population.people[3].appearance_seed == seed_before, "reload keeps identity")
	check(director.actors[3].position.is_equal_approx(position_before), "reload resumes position instead of respawning at home")
	if "--capture" in OS.get_cmdline_user_args():
		var camera := Camera3D.new()
		city.add_child(camera)
		camera.position = Vector3(2, 3, 23)
		camera.look_at(Vector3(0, 1, 8))
		camera.make_current()
		root.size = Vector2i(1280, 720)
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("/tmp/npc-city.png") == OK, "native capture")
	city.queue_free()
	await ticks(90)
	check(not root.get_node("InputRouter").ui_suppressed(), "scene exit leaves no UI token")
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("[npc-runtime] %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)
