extends SceneTree
## Real controller/keyboard journal selection, stable focus and geometric guide bearings.
var checks := 0
var failures := 0
var viewport: SubViewport

class JourneyFixture extends Node:
	signal changed
	var save_ok := true
	func title() -> String:
		return "Market entrance"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	viewport = SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var progress: Node = load("res://scripts/npc/CityProgress.gd").new()
	viewport.add_child(progress)
	progress.setup("choko", false)
	progress.save_enabled = false
	_check(progress.accept_quest("introductions") and progress.accept_quest("roof_walk"), "real independent district quests are accepted")
	var hud: Node = load("res://scripts/world/CityHud.gd").new()
	viewport.add_child(hud)
	hud.setup(CityOnboarding.new())
	hud.bind_progress(progress)
	var journey := JourneyFixture.new()
	viewport.add_child(journey)
	hud.bind_journey(journey)
	_check("Market entrance" in hud.resume_location_label.text, "pause discloses the named checkpoint")
	journey.save_ok = false
	journey.changed.emit()
	_check("not saved" in hud.resume_location_label.text, "checkpoint save error is independent of quest-save status")
	hud.set_paused(true)
	await _settle()
	_check(hud.resume_button.has_focus(), "pause starts with resume")
	var target: Button = hud.quest_buttons["roof_walk"]
	for step in 12:
		if target.has_focus():
			break
		await _pad(JOY_BUTTON_DPAD_DOWN)
	_check(target.has_focus(), "controller focus traverses from resume to the roof quest")
	var same_button: Button = target
	await _pad(JOY_BUTTON_A)
	_check(progress.tracked_quest_id() == "roof_walk", "controller accept selects the real quest")
	_check(target.has_focus() and hud.quest_buttons["roof_walk"] == same_button, "selection refresh preserves button identity and focus")
	_check(target.get_global_rect().intersects(hud.get("_journal_scroll").get_global_rect()), "focused quest scrolls into the visible journal")
	hud.quest_buttons["introductions"].grab_focus()
	await _key(KEY_ENTER)
	_check(progress.tracked_quest_id() == "introductions", "keyboard can change the selected quest")
	hud.untrack_button.grab_focus()
	await _pad(JOY_BUTTON_A)
	_check(progress.tracked_quest_id().is_empty() and progress.tracking_mode() == "off", "controller opt-out does not silently reselect a quest")
	_check(hud.untrack_button.has_focus(), "turning guidance off preserves focus")
	await _pad(JOY_BUTTON_B)
	_check(not paused and not hud.paused_ui and not root.get_node("InputRouter").ui_suppressed(), "cancel resumes without retaining the journal input owner")
	var guide: Control = load("res://scripts/world/CityQuestGuide.gd").new()
	viewport.add_child(guide)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.current = true
	var cases := [
		[Vector3(0, 0, -20), "Ahead"], [Vector3(0, 0, 20), "Behind"],
		[Vector3(20, 0, 0), "Right"], [Vector3(-20, 0, 0), "Left"],
		[Vector3(0, 8, -20), "Higher"], [Vector3(0, -8, -20), "Lower"],
	]
	for row: Array in cases:
		guide.show_target({"title": "A real destination", "position": row[0]}, Vector3.ZERO, camera, Vector2(1600, 900))
		_check(guide.visible and row[1] in guide.bearing_label.text, "camera-relative bearing " + str(row[1]))
		_check("QUEST" in guide.title_label.text and not "HOOK" in guide.title_label.text, "quest guidance is distinct from a grapple action")
		_check(Rect2(Vector2.ZERO, Vector2(1600, 900)).encloses(guide.get_rect()), "bearing remains within logical viewport")
	camera.rotation.y = PI
	guide.show_target({"title": "Roof", "position": Vector3(0, 8, -20)}, Vector3.ZERO, camera, Vector2(1600, 900))
	_check("Behind" in guide.bearing_label.text and "Higher" in guide.bearing_label.text, "camera orbit preserves behind and roof height instead of mirrored projection")
	guide.show_target({}, Vector3.ZERO, camera, Vector2(1600, 900))
	_check(not guide.visible, "missing or cleared target immediately hides the guide")
	viewport.queue_free()
	await _settle()
	for singleton in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	await create_timer(0.2).timeout
	print("QUEST_JOURNAL_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _settle() -> void:
	for frame in 5:
		await process_frame

func _pad(button: JoyButton) -> void:
	for down in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = down
		viewport.push_input(event, true)
		await _settle()

func _key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = down
		viewport.push_input(event, true)
		await _settle()

func _check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("QUEST_JOURNAL: " + text)
