extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HARPOON_AIM: " + message)
func mouse_button(down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func motion() -> void:
	var event := InputEventMouseMotion.new()
	event.relative = Vector2(80, 20)
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func _run() -> void:
	await process_frame
	var camera := Camera3D.new()
	root.add_child(camera)
	var helper: Node = load("res://scripts/core/HarpoonAim.gd").new()
	root.add_child(helper)
	helper.setup(camera, true)
	motion()
	expect(is_zero_approx(helper.yaw_offset), "unheld pointer never rotates")
	mouse_button(true)
	motion()
	expect(helper.is_manual() and helper.yaw_offset < -0.1, "RMB motion takes manual priority")
	mouse_button(false)
	var before: float = helper.yaw_offset
	helper.step(0.1)
	expect(is_equal_approx(before, helper.yaw_offset), "manual hold survives release")
	for i in 300:
		helper.step(1.0 / 60.0)
	expect(absf(helper.yaw_offset) < 0.01 and not helper.is_manual(), "automatic view returns smoothly")
	var router := root.get_node("InputRouter")
	router.acquire_ui(camera)
	mouse_button(true)
	motion()
	expect(not helper.is_manual(), "UI blocks mouse orbit")
	router.release_ui(camera)
	motion()
	expect(not helper.is_manual(), "UI held RMB needs fresh press")
	mouse_button(false)
	helper.setup(camera, false)
	mouse_button(true)
	motion()
	expect(is_zero_approx(helper.yaw_offset), "shared camera rejects solo orbit")
	mouse_button(false)
	helper.setup(camera, true)
	var stick := InputEventJoypadMotion.new()
	stick.device = 0
	stick.axis = JOY_AXIS_RIGHT_X
	stick.axis_value = 0.8
	Input.parse_input_event(stick)
	Input.flush_buffered_events()
	helper.step(1.0 / 60.0)
	expect(helper.is_manual() and helper.yaw_offset < 0.0, "physical right stick drives manual helper")
	var release := InputEventJoypadMotion.new()
	release.device = 0
	release.axis = JOY_AXIS_RIGHT_X
	release.axis_value = 0.0
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	expect(router.view_basis(1).is_zero_approx(), "manual helper leaves physics view publication to duel camera")
	helper.reset()
	expect(router.view_basis(1).is_zero_approx(), "reset clears live view input basis")
	var hud: Node = load("res://scripts/ui/Hud.gd").new()
	router.apply_profile("shared", false)
	expect(hud.aim_binding(0, false) == "T" and hud.aim_binding(1, false) == "R", "shared cue uses actual enemy and parkour keys")
	expect(hud.aim_binding(0, true).contains("RT") and hud.aim_binding(1, true).contains("LT"), "controller cue follows harpoon chord routes")
	router.apply_profile("solo", false)
	expect(hud.aim_binding(0, false) == "Q" and hud.aim_binding(1, false) == "E", "solo cue restores actual Q and E bindings")
	hud.free()
	await _selection(helper, camera)
	helper.queue_free()
	camera.queue_free()
	await process_frame
	print("HARPOON_AIM_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _selection(helper: Node, camera: Camera3D) -> void:
	root.get_node("GameState").skeletal_rig = false
	var scene := load("res://scenes/fighter/Fighter.tscn") as PackedScene
	var f: Node3D = scene.instantiate()
	f.data = load("res://data/characters/choko.tres")
	root.add_child(f)
	f.set_physics_process(false)
	f.forward = Vector3.RIGHT
	f._wish = Vector3.ZERO
	var near := Node3D.new()
	near.name = "AimNear"
	root.add_child(near)
	near.position = Vector3(4, 4, 0)
	near.add_to_group("grapple_anchor")
	var far := Node3D.new()
	far.name = "AimFar"
	root.add_child(far)
	far.position = Vector3(7, 4, 0)
	far.add_to_group("grapple_anchor")
	await physics_frame
	helper.setup(camera, false)
	var intent: Dictionary = helper.capture(f, false)
	expect(intent.target_id == String(near.get_path()), "nearest usable candidate wins")
	near.remove_from_group("grapple_anchor")
	near.add_to_group("grapple_anchor")
	expect(helper.capture(f, false).target_id == intent.target_id, "candidate enumeration does not change selection")
	var blocker := StaticBody3D.new()
	blocker.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 1.0, 1.0)
	shape.shape = box
	blocker.add_child(shape)
	root.add_child(blocker)
	blocker.position = Vector3(2, 2.625, 0)
	await physics_frame
	expect(helper.capture(f, false).target_id != intent.target_id, "new hand obstruction invalidates previous candidate immediately")
	near.position = Vector3(40, 4, 0)
	far.position = Vector3(45, 4, 0)
	expect(helper.capture(f, false).target_id.is_empty(), "out of range never remains selected")
	# Aim a real perspective camera at a point target, with a distinct hand origin.
	blocker.position = Vector3(50, 50, 50)
	near.position = Vector3(5, 4, 0)
	camera.position = Vector3(-5, 4, 0)
	camera.look_at(near.position, Vector3.UP)
	helper.setup(camera, true)
	await physics_frame
	var settled: Dictionary = helper.capture(f, false)
	expect(not settled.manual and settled.camera_aim and settled.target_id == String(near.get_path()), "settled solo camera retains distant anchor selection")
	helper.apply_look(Vector2(0.001, 0.0))
	await physics_frame
	var aimed: Dictionary = helper.capture(f, false)
	expect(aimed.manual and aimed.target_id == String(near.get_path()), "manual camera ray selects actual candidate")
	var hand_direction: Vector3 = (near.position - Vector3(0, 1.25, 0)).normalized()
	expect(aimed.direction.distance_to(hand_direction) < 0.001, "manual ray resolves hand parallax instead of parallel camera ray")
	blocker.position = Vector3(2, 2.35, 0)
	await physics_frame
	expect(helper.capture(f, false).target_id.is_empty(), "camera-visible target blocked from hand is rejected")
	var recorded := intent.duplicate(true)
	camera.rotation.y += 1.0
	expect(recorded == intent, "captured world intent is value snapshot")
	blocker.queue_free()
	near.queue_free()
	far.queue_free()
	f.queue_free()
	await process_frame
