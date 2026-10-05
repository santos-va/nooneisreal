extends SceneTree
var output := OS.get_environment("NPC_CAPTURE_DIR")
func _initialize() -> void: run.call_deferred()
func ticks(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))
func run() -> void:
	if output.is_empty(): output = "/tmp/npc-city"
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280,800)
	var city = load("res://scenes/world/CityWorld.tscn").instantiate()
	city.journey_save_enabled = false
	root.add_child(city)
	current_scene = city
	city.progress.save_enabled = false
	var director = city.npc_director
	director.save_enabled = false
	director.population.initialize(12345)
	for actor in director.actors.values(): actor.free()
	director.actors.clear()
	director.active_radius = 80
	director._refresh_actors()
	for shop in CityPlaces.shops():
		city.player.restart_at(shop.service)
		city.camera_rig.reset_view()
		city.camera_rig.aim.yaw_offset = PI
		await ticks(20)
		await shot(shop.id + "_work")
		var opened: bool = director.open_conversation(shop.npc_index)
		print("CITY_RESIDENT conversation ",shop.id," opened=",opened," gap=",director.surface_gap(shop.npc_index))
		await ticks(20)
		await shot(shop.id + "_conversation")
		director.dialogue.close()
		await create_timer(1.7).timeout
		await ticks(3)
		await shot(shop.id + "_return")
	city.player.restart_at(Vector3(0,0,-4))
	city.camera_rig.reset_view()
	await ticks(15)
	await shot("city_crowd")
	city.queue_free()
	await ticks(3)
	for singleton in ["Sfx","Music","UltMusic"]: root.get_node(singleton).queue_free()
	await ticks(3)
	print("NPC_CITY_CAPTURE_COMPLETE")
	quit()
