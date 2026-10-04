extends SceneTree
## Run from repository root: godot --headless --path game -s "$PWD/tools/fx/water_contact_check.gd"
## Real arena + virtual-input jump, then isolated director event boundary controls.
var fails: int = 0
var gs: Node
var ir: Node
var burst: Script
var director: Script
var fighter: Script
var flipbook: Script

func check(ok: bool, label: String) -> void:
	print("contact: %s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		fails += 1

func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	ir = root.get_node("InputRouter")
	burst = load("res://scripts/fx/WaterBurst3D.gd")
	director = load("res://scripts/fx/FxDirector.gd")
	fighter = load("res://scripts/fighter/Fighter.gd")
	flipbook = load("res://scripts/fx/Flipbook.gd")
	gs.p2_is_cpu = false
	gs.skeletal_rig = false
	gs.training_mode = true
	gs.free_move = true
	for stage_id in ["river", "bazaar"]:
		for index in gs.STAGES.size():
			if gs.STAGES[index].id == stage_id:
				gs.stage_index = index
		var packed: PackedScene = load("res://scenes/arena/Arena.tscn")
		var arena = packed.instantiate()
		root.add_child(arena)
		current_scene = arena
		arena.flow.set_physics_process(false)
		arena.p1.set_control(true)
		arena.p2.set_control(true)
		# Settle contact before input, then exercise the real Fighter physics and director.
		for i in 5:
			await physics_frame
		var splash_before := int(flipbook.spawned.get("water_splash", 0))
		var dust_before := int(flipbook.spawned.get("dust_land", 0))
		ir.v_press(1, "jump")
		var airborne := false
		var landed := false
		var saw_burst := false
		for i in 180:
			await physics_frame
			if i == 2:
				ir.v_release(1, "jump")
			if not arena.p1.on_ground():
				airborne = true
			if not get_nodes_in_group(burst.GROUP).is_empty():
				saw_burst = true
			if airborne and arena.p1.on_ground():
				landed = true
				# Director may run later in this physics tick.
				await physics_frame
				saw_burst = saw_burst or not get_nodes_in_group(burst.GROUP).is_empty()
				break
		check(airborne and landed, stage_id + " real jump returns to floor")
		check(saw_burst == (stage_id == "river"), stage_id + " landing selects correct water geometry")
		if stage_id == "bazaar":
			check(int(flipbook.spawned.get("water_splash", 0)) == splash_before and int(flipbook.spawned.get("dust_land", 0)) > dust_before, "dry landing retains dust without water sheet")
		else:
			arena.process_mode = Node.PROCESS_MODE_DISABLED
			_event_boundaries(arena)
		ir.v_clear(1)
		arena.queue_free()
		arena = null
		packed = null
		await process_frame
	gs.water = null
	current_scene = null
	# Retire audio playback before quitting; AudioServer releases voices asynchronously.
	var sfx: Node = root.get_node("Sfx")
	root.remove_child(sfx)
	sfx.free()
	sfx = null
	flipbook._cache.clear()
	burst = null
	director = null
	fighter = null
	flipbook = null
	# Fixed-fps advances simulation timers faster than the audio mixer thread.
	var drain_until_ms: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < drain_until_ms:
		await process_frame
		OS.delay_msec(1)
	print("WATER CONTACT CHECK: %d failures" % fails)
	quit(0 if fails == 0 else 1)

func _event_boundaries(arena: Node) -> void:
	var f = arena.p1
	var fx = arena.get_node("FxDirector")
	var base: Array = director._snap(f)
	base[0] = fighter.State.IDLE
	base[1] = false
	var air_dash := base.duplicate()
	air_dash[0] = fighter.State.DASH
	var count_before := get_nodes_in_group(burst.GROUP).size()
	fx._events(f, base, air_dash)
	check(get_nodes_in_group(burst.GROUP).size() == count_before, "air dash creates no surface contact")
	var sheets_before := int(flipbook.spawned.get("water_splash", 0))
	var landing := base.duplicate()
	landing[0] = fighter.State.IDLE
	landing[1] = true
	base[0] = fighter.State.JUMP
	base[11] = Vector3(0.0, -2.0, 0.0)
	for i in 3:
		fx._events(f, base, landing)
	check(int(flipbook.spawned.get("water_splash", 0)) == sheets_before and get_nodes_in_group(burst.GROUP).size() == count_before + 3, "repeated light landings create 3D only")
	base[11] = Vector3(0.0, -5.0, 0.0)
	fx._events(f, base, landing)
	base[11] = Vector3(0.0, -10.0, 0.0)
	fx._events(f, base, landing)
	check(int(flipbook.spawned.get("water_splash", 0)) == sheets_before + 2, "medium and heavy events preserve painted splash accents")
