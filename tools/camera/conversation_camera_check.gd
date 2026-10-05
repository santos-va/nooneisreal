extends SceneTree
## Real dialogue signals, shop solids, screen composition and restored manual orbit.
var checks: int = 0
var failures: int = 0
var folder: String = ""
var rows: Array[Dictionary] = []
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CONVERSATION_CAMERA: " + label)
func ticks(count: int) -> void:
	for frame: int in count:
		await physics_frame
		await process_frame
func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			folder = argument.trim_prefix("--capture-dir=")
	if not folder.is_empty():
		DirAccess.make_dir_recursive_absolute(folder)
	var city: Node3D = load("res://scenes/world/CityWorld.tscn").instantiate()
	city.journey_save_enabled = false
	root.add_child(city)
	current_scene = city
	city.progress.save_enabled = false
	var director: Node = city.npc_director
	director.save_enabled = false
	director.active_radius = 80
	director._refresh_actors()
	city.player.set_physics_process(false)
	var places: Script = load("res://scripts/world/CityPlaces.gd")
	var input: Node = root.get_node("InputRouter")
	var cases: Array = places.shops()
	cases.append({"id": "street", "npc_index": 3, "service": Vector3(0,0,-1.8)})
	for height: int in [720,900]:
		root.size = Vector2i(height * 16 / 9,height)
		for item: Dictionary in cases:
			var actor: Node3D = director.actors[item.npc_index]
			if item.id == "street":
				actor.global_position = Vector3(0,0,-3)
				actor.pause_left = 60
			city.player.global_position = item.service
			city.camera_rig.reset_view()
			city.camera_rig.aim.yaw_offset = 1.1
			city.camera_rig.aim.pitch_offset = 0.15
			await ticks(24)
			var original_yaw: float = city.camera_rig.aim.yaw_offset
			var original_pitch: float = city.camera_rig.aim.pitch_offset
			var original_basis: Vector3 = input.view_basis(1)
			var hero_position: Vector3 = city.player.global_position
			var actor_position: Vector3 = actor.global_position
			check(director.open_conversation(item.npc_index), "real conversation opens " + item.id)
			await ticks(24)
			var camera: Camera3D = city.camera_rig.camera
			var point: Vector3 = actor.visual.global_transform * Vector3(0,1.68,0)
			var screen: Vector2 = camera.unproject_position(point)
			var bounds: Vector2 = root.get_visible_rect().size
			var ray := PhysicsRayQueryParameters3D.create(camera.global_position,point,1)
			ray.exclude = [city.player.get_rid()]
			var space := city.get_world_3d().direct_space_state
			var clear: bool = space.intersect_ray(ray).is_empty()
			check(clear, "NPC head visible through shop solids " + item.id)
			check(not camera.is_position_behind(point) and screen.x > bounds.x * .05 and screen.x < bounds.x * .55 and screen.y > 0 and screen.y < bounds.y, "NPC face left of dialogue " + item.id)
			var query := PhysicsShapeQueryParameters3D.new()
			var sphere := SphereShape3D.new()
			sphere.radius = 0.1
			query.shape = sphere
			query.transform.origin = camera.global_position
			query.collision_mask = 1
			query.exclude = [city.player.get_rid()]
			check(space.intersect_shape(query).is_empty(), "lens remains outside solids " + item.id)
			check(city.player.global_position == hero_position and actor.global_position == actor_position, "framing never moves either actor " + item.id)
			city.camera_rig.aim.apply_look(Vector2(.4,.2))
			check(city.camera_rig.aim.yaw_offset == original_yaw and city.camera_rig.aim.pitch_offset == original_pitch, "dialogue preserves manual orbit values")
			rows.append({"case": item.id, "height": height, "head_screen": [screen.x / bounds.x,screen.y / bounds.y], "clear": clear, "arm": city.camera_rig.arm.get_hit_length(), "camera": [camera.global_position.x,camera.global_position.y,camera.global_position.z]})
			if not folder.is_empty() and DisplayServer.get_name() != "headless":
				# Also supports --disable-render-loop: simulate every physics tick,
				# then render the actual final UI/world frame on demand.
				RenderingServer.force_draw()
				root.get_texture().get_image().save_png(folder.path_join("%s_%d.png" % [item.id,height]))
			director.dialogue.close()
			await ticks(24)
			check(is_zero_approx(city.camera_rig._conversation_weight), "close finishes presentation transition")
			check(input.view_basis(1).is_equal_approx(original_basis), "close restores original movement basis")
			check(is_zero_approx(city.camera_rig.arm.rotation.y) and is_zero_approx(city.camera_rig.arm.rotation.z), "close restores local orbit without stale conversation yaw")
			check(director.open_conversation(item.npc_index), "same actor can reopen")
			await ticks(18)
			director.dialogue.close()
			await ticks(18)
	if not folder.is_empty():
		var file := FileAccess.open(folder.path_join("trace.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify(rows,"\t"))
	city.queue_free()
	await ticks(2)
	check(input.view_basis(1) == Vector3.ZERO, "scene exit clears view basis")
	print("CONVERSATION_CAMERA_COMPLETE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
