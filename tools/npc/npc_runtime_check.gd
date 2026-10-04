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
	await ticks(5)
	check(director.actors.size() > 0 and director.actors.size() <= 12, "bounded nearby population")
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.7
	for index: int in director.actors:
		var actor: Node3D = director.actors[index]
		for offset: float in [-1.6, 0.0, 1.6]:
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.collision_mask = 1
			query.exclude = [city.player.get_rid()]
			query.transform.origin = actor.home + Vector3(0, 0.9, offset)
			check(city.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "pedestrian route clear %d/%s" % [index, offset])
	var first: Node3D = director.actors[0]
	city.player.global_position = first.global_position + Vector3(0, 0, 1.5)
	await ticks(2)
	check(director.find_nearest() == 0, "nearby resident selectable")
	director.dialogue.show_fact(director.population.meet(0))
	check(root.get_node("InputRouter").ui_suppressed(), "conversation owns gameplay input")
	director.dialogue.close()
	check(not root.get_node("InputRouter").ui_suppressed(), "closing releases gameplay input")
	var seed_before: int = director.population.people[0].appearance_seed
	city.player.global_position = Vector3(30, 4, -25)
	director._refresh_actors()
	await ticks(2)
	check(director.actors.is_empty(), "distant actor chunks unload")
	city.player.global_position = Vector3(0, 0, 10)
	director._refresh_actors()
	check(director.actors.has(0) and director.population.people[0].appearance_seed == seed_before, "reload keeps identity")
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
