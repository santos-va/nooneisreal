extends SceneTree
## Real menu focus, per-hero read-only resume lookup and live quest HUD updates.
var checks := 0
var failures := 0

class ProgressFixture extends Node:
	signal changed
	var completed := 0
	func summary() -> Dictionary:
		return {"active_title": "Find the tailor", "active_hint": "Follow the market street.", "completed": completed, "total": 6, "credits": 4, "save_ok": true}
	func journal() -> Array[Dictionary]:
		return [{"title": "Meet your neighbours", "status": "active", "progress": completed, "target": 3}]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	var marker := ConfigFile.new()
	var path := "user://district-build-test.cfg"
	marker.set_value("build", "revision", "b".repeat(40))
	marker.save(path)
	_check(BuildInfo.revision(path) == "b".repeat(40), "export marker retains full revision")
	marker.set_value("build", "revision", "not-a-build")
	marker.save(path)
	_check(BuildInfo.revision(path).is_empty(), "invalid marker cannot masquerade as build")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	viewport.add_child(menu)
	await _settle()
	_check(menu.get("city_button").has_focus(), "journey is the initial keyboard/controller action")
	_check(not menu.get_node("BuildLabel").text.is_empty(), "build identity is visible")
	var button: Button = menu.get("city_button")
	var visited: Array[Control] = []
	for i in 12:
		_check(not button in visited, "focus ring visits each menu control once")
		visited.append(button)
		var next: Button = button.get_node(button.focus_neighbor_bottom)
		_check(next.is_visible_in_tree() and not next.disabled, "focus target is usable")
		button = next
	_check(button == menu.get("city_button"), "focus ring returns to journey")
	var state: Node = root.get_node("GameState")
	(menu.get("_p1_btn") as Button).grab_focus()
	var previous: String = state.p1_character
	for down in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_A
		event.pressed = down
		viewport.push_input(event, true)
		await _settle()
	_check(state.p1_character != previous and state.p1_character in ["choko", "skea"], "controller selects a real second hero")
	menu.queue_free()
	await _settle()
	var progress := ProgressFixture.new()
	viewport.add_child(progress)
	var hud: Node = load("res://scripts/world/CityHud.gd").new()
	viewport.add_child(hud)
	hud.setup(CityOnboarding.new())
	hud.bind_progress(progress)
	await _settle()
	_check(hud.get("_quest_card").visible and "Find the tailor" in hud.get("_quest_title").text, "journal binds live objective")
	progress.completed = 2
	progress.changed.emit()
	_check("2 / 6" in hud.get("_quest_totals").text and "2 / 3" in hud.get("_journal").text, "HUD and pause journal react to actual progress")
	hud.set_paused(true)
	_check(hud.resume_button.has_focus(), "pause starts with safe resume action")
	hud.set_paused(false)
	viewport.queue_free()
	await _settle()
	for singleton in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	await create_timer(0.2).timeout
	print("DISTRICT_UI_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _settle() -> void:
	for frame in 4:
		await process_frame

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("DISTRICT_UI: " + message)
