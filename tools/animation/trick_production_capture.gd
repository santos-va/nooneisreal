extends SceneTree
## Native production CityWorld camera/light/HUD. Normal callbacks own all motion.
## Declared station starts only; actual InputRouter triggers every recorded trick.
var Actor: Script
var folder: String = "/tmp/nir-tricks-production"
var selected: String = ""
var open_station: bool = false
var trace: Array[Dictionary] = []
var routes: Array[Dictionary] = []
var saved: int = 0
var failures: int = 0
var input: Node
var game: Node

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			folder = argument.trim_prefix("--out=")
		elif argument == "--open-station":
			open_station = true
		elif argument.begins_with("--case="):
			selected = argument.trim_prefix("--case=")
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(960, 640)
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	game = root.get_node("GameState")
	input = root.get_node("InputRouter")
	game.skeletal_rig = true
	var graphics: Node = root.get_node("GraphicsSettings")
	var old_profile: String = graphics.get_profile()
	graphics.set_profile("high")
	for hero: String in ["choko", "skea"]:
		for phase: String in ["wall_kick", "landing_roll"]:
			if selected.is_empty() or selected == hero + "_" + phase:
				await route(hero, phase)
	if routes.size() != (4 if selected.is_empty() else 1) or saved == 0:
		failures += 1
		push_error("TRICK_PRODUCTION incomplete nonempty route set")
	var receipt: Dictionary = {
		"fixture":"production CityWorld scene; declared station starts; normal physics/render callbacks",
		"engine":Engine.get_version_info().string,
		"renderer":RenderingServer.get_current_rendering_method(),
		"adapter":RenderingServer.get_video_adapter_name(),
		"quality":"high", "viewport":[root.size.x, root.size.y],
		"camera":"unaltered CityCamera and SpringArm; no forced orbit",
		"lighting":"unaltered CityWorld._build_lighting", "hud":"production CityHud visible",
		"images":saved, "failures":failures, "routes":routes, "trace":trace,
		"limits":"Station starts are not a continuous traversal from spawn; Linux native is not M3 FPS or device acceptance."
	}
	var file := FileAccess.open(folder.path_join("receipt.json"), FileAccess.WRITE)
	if file == null:
		failures += 1
	else:
		file.store_string(JSON.stringify(receipt, "\t") + "\n")
		file.close()
	graphics.set_profile(old_profile)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("TRICK_PRODUCTION_COMPLETE images=%d ticks=%d routes=%d failures=%d" % [saved,trace.size(),routes.size(),failures])
	quit(1 if failures else 0)

func route(hero: String, required: String) -> void:
	var id: String = hero + "_" + required
	var output: String = folder.path_join(id)
	DirAccess.make_dir_recursive_absolute(output)
	game.p1_character = hero
	var world = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	if world.player == null or world.progress == null or world.npc_director == null:
		failures += 1
		push_error("TRICK_PRODUCTION incomplete city initialization " + id)
		world.queue_free()
		await process_frame
		return
	# Suppress persistence only; city simulation, camera, lighting and HUD remain live.
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	var actor = world.player
	var station: Vector3 = Vector3(4,0,31.4) if required == "wall_kick" else Vector3(0,3,20)
	if open_station and required == "wall_kick":
		station = Vector3(12,0,-3.3) # Existing first roof-route step, open street behind camera.
	input.v_clear(1)
	actor.restart_at(station)
	if required == "landing_roll":
		actor._set_state(Actor.State.JUMP)
		actor.velocity = Vector3(4,-2,0)
	world.camera_rig.reset_view()
	var hang_ticks: int = 0
	var observed: bool = false
	var peak_saved: bool = false
	var active_ticks: int = 0
	var end_tick: int = 150
	var images_before: int = saved
	for tick: int in 160:
		await physics_frame
		var previous: Dictionary = actor.parkour_snapshot()
		if str(previous.get("phase", "")) == "hang":
			hang_ticks += 1
		if required == "wall_kick":
			input.v_set(1,"up",tick >= 6 and hang_ticks == 0)
			input.v_set(1,"down",hang_ticks >= 10)
			input.v_set(1,"jump",(tick >= 9 and hang_ticks == 0) or hang_ticks >= 10)
		else:
			input.v_set(1,"right",true)
			input.v_set(1,"crouch",true)
		# Physics-frame signal precedes production node callbacks. Capture after the
		# actual frame has rendered, without calling or bypassing any controller.
		await RenderingServer.frame_post_draw
		var snapshot: Dictionary = actor.parkour_snapshot()
		var phase: String = str(snapshot.get("phase", ""))
		var progress: float = float(snapshot.get("progress",0.0))
		var first_active: bool = not observed and phase == required
		if phase == required:
			observed = true
			active_ticks += 1
			end_tick = tick + 12
		var capture: bool = tick % 3 == 0 or first_active or (phase == required and progress >= 0.45 and not peak_saved)
		var path: String = ""
		if capture:
			path = output.path_join("%04d.png" % tick)
			if root.get_texture().get_image().save_png(path) == OK:
				saved += 1
				peak_saved = peak_saved or (phase == required and progress >= 0.45 and progress <= 0.8)
			else:
				failures += 1
		var camera: Camera3D = world.camera_rig.camera
		trace.append({"case":id,"tick":tick,"physics_frame":input.frame(),"phase":phase,"progress":progress,
			"position":vec(actor.global_position),"velocity":vec(actor.velocity),"grounded":actor.is_on_floor(),
			"camera_position":vec(camera.global_position),"camera_fov":camera.fov,
			"spring_length":world.camera_rig.arm.get_hit_length(),"camera_behind":camera.is_position_behind(actor.global_position),
			"authored_clip":actor.skeletal.parkour_motion.source_clip,"image":path})
		if observed and tick >= end_tick:
			break
	if not observed or not peak_saved:
		failures += 1
		push_error("TRICK_PRODUCTION missing active/peak phase " + id)
	routes.append({"case":id,"station":vec(station),"initial_velocity":[4,-2,0] if required == "landing_roll" else [0,0,0],
		"observed":observed,"peak_saved":peak_saved,"active_ticks":active_ticks,"images":saved-images_before})
	print("TRICK_PRODUCTION_ROUTE case=%s observed=%s peak=%s active_ticks=%d" % [id,observed,peak_saved,active_ticks])
	input.v_clear(1)
	world.queue_free()
	await process_frame
	await physics_frame

func vec(value: Vector3) -> Array:
	return [value.x,value.y,value.z]
