extends SceneTree
## Progression is event-driven; real UI exercises pause ownership and neutral release.
var checks: int = 0
var failures: int = 0
var viewport: SubViewport
var restart_requests: int = 0
var exit_requests: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var model := CityOnboarding.new()
	_check(model.current_id() == "move", "fresh guidance starts on movement")
	for event: String in ["jump", "rope", "look", "unknown"]:
		model.record_event(event, 20.0)
	_check(model.current_id() == "move", "unrelated and future events cannot complete movement")
	for invalid: float in [-1.0, 0.0, NAN, INF]:
		model.record_event("move", invalid)
	_check(is_zero_approx(model.progress), "invalid observations never poison progression")
	model.record_event("move", 2.0)
	_check(model.current_id() == "move", "partial movement is not completion")
	model.suspended = true
	model.record_event("move", 9.0)
	_check(model.current_id() == "move", "paused observations cannot complete guidance")
	model.suspended = false
	model.record_event("move", 1.0)
	_check(model.current_id() == "look", "actual cumulative movement advances once")
	model.record_event("look", 0.1)
	_check(model.current_id() == "look", "tiny camera motion does not complete look")
	model.record_event("look", 0.3)
	_check(model.current_id() == "jump", "actual turn advances to jump")
	model.record_event("jump")
	_check(model.current_id() == "rope", "actual jump unlocks parkour guidance")
	model.record_event("rope")
	_check(model.is_complete() and not model.skipped, "all observed actions reach free exploration")
	model.record_event("move", 100.0)
	_check(model.current_id() == "explore", "completion never wraps back to forced tutorial")
	model.restart()
	_check(model.current_id() == "move" and model.progress == 0.0, "restart clears tutorial progress")
	model.skip()
	_check(model.is_complete() and model.skipped, "skip explicitly reaches free exploration")
	model.restart()
	var router: Node = root.get_node("InputRouter")
	root.get_node("GameState").set_free_move(true)
	router.apply_profile("solo", false)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var hud: Node = load("res://scripts/world/CityHud.gd").new()
	hud.setup(model)
	viewport.add_child(hud)
	hud.restart_requested.connect(func(): restart_requests += 1; model.restart())
	hud.exit_requested.connect(func(): exit_requests += 1)
	await _settle()
	await _key(KEY_ESCAPE)
	_check(paused and hud.paused_ui and router.ui_suppressed(), "Escape pauses simulation and owns gameplay input")
	_check(model.suspended and hud.resume_button.has_focus(), "pause suspends guidance and focuses resume")
	for dimensions: Vector2i in [Vector2i(1600, 900), Vector2i(1600, 1200), Vector2i(2134, 900)]:
		viewport.size = dimensions
		await _settle()
		for control: Control in [hud.resume_button, hud.skip_button, hud.restart_button, hud.exit_button, hud.objective_label, hud.hint_label]:
			_check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(control.get_global_rect()), "city control fits logical viewport")
	for action: String in ["jump", "dash", "left_hand", "grapple_parkour"]:
		Input.action_press("p1_" + action)
	hud.resume_button.pressed.emit()
	_check(not paused and not router.ui_suppressed(), "resume releases simulation and its input owner")
	for action: String in ["jump", "dash", "left_hand", "grapple_parkour"]:
		_check(not router.held(1, action), "held " + action + " requires neutral after resume")
		Input.action_release("p1_" + action)
		router.held(1, action)
	hud.set_paused(true)
	hud.skip_button.pressed.emit()
	_check(model.skipped and not paused and not router.ui_suppressed(), "skip button resumes free exploration")
	hud.set_paused(true)
	hud.restart_button.pressed.emit()
	_check(restart_requests == 1 and model.current_id() == "move" and not paused, "restart button dispatches reset after closing pause")
	hud.set_paused(true)
	hud.exit_button.pressed.emit()
	_check(exit_requests == 1 and not paused and not router.ui_suppressed(), "menu exit releases pause before scene routing")
	hud.set_paused(true)
	hud.queue_free()
	await _settle()
	_check(not paused and not router.ui_suppressed(), "scene disposal cannot leak pause or input owner")
	viewport.queue_free()
	await process_frame
	# Exercise the real menu signal and scene replacement, including a non-city input profile.
	var state: Node = root.get_node("GameState")
	state.set_free_move(false)
	router.apply_profile("shared", false)
	state.p1_character = "skea"
	state.training_mode = true
	state.p2_is_cpu = false
	state.set_stage("fountain")
	state.night = true
	var original_stage: int = state.stage_index
	change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	await _settle()
	var menu: Control = current_scene as Control
	_check(router.ui_suppressed(), "real menu owns input before city entry")
	(menu.get("city_button") as Button).pressed.emit()
	await _settle()
	var world: Node = current_scene
	_check(world != null and world.player.data.id == "skea", "actual city menu action opens selected hero")
	_check(state.free_move and router.profile == "solo", "city installs temporary exploration controls")
	_check(state.stage_index == original_stage and state.night and state.training_mode and not state.p2_is_cpu, "city entry preserves arena configuration")
	world.player.grapple_changed.emit(0, 0.0, 2)
	world.player.dash_changed.emit(0, 4.5, 3)
	_check("HOOKS 0 / 2" in world.hud.resource_label.text and "Reuse" in world.hud.resource_label.text, "empty hooks disclose usable recovery choices")
	_check("DASH 0 / 3" in world.hud.resource_label.text and "4.5s" in world.hud.resource_label.text, "dash stock and recovery are visible")
	world.hud.set_paused(true)
	world.hud.exit_button.pressed.emit()
	await _settle()
	_check(current_scene is Control and not paused, "actual city menu exit returns to unpaused menu")
	_check(not state.free_move and router.profile == "shared", "city exit restores previous controls")
	_check(state.stage_index == original_stage and state.night and state.training_mode and not state.p2_is_cpu, "city exit retains previous arena configuration")
	current_scene.queue_free()
	await _settle()
	_check(not router.ui_suppressed(), "menu disposal releases final scene input owner")
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("CITY_ONBOARDING_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = down
		viewport.push_input(event, true)
		await _settle()


func _settle() -> void:
	for i: int in 4:
		await process_frame


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_ONBOARDING: " + message)
