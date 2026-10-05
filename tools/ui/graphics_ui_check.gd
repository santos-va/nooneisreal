extends SceneTree
## Actual focus/input selection and persistence through the shared modal.
var failures: int = 0
var checks: int = 0
var viewport: Window

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("GRAPHICS_UI: " + label)

func settle() -> void:
	for frame: int in 4:
		await process_frame

func key(code: Key, _target: Viewport) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await settle()

func pad(button: JoyButton, _target: Viewport) -> void:
	for down: bool in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		await settle()

func _run() -> void:
	await process_frame
	var graphics: Node = root.get_node("GraphicsSettings")
	var comfort: Node = root.get_node("ComfortSettings")
	var old_graphics: String = graphics.storage_path
	var old_comfort: String = comfort.storage_path
	var graphics_path: String = "user://graphics_ui_%d.cfg" % OS.get_process_id()
	var comfort_path: String = "user://graphics_ui_comfort_%d.cfg" % OS.get_process_id()
	graphics.load_settings(graphics_path)
	comfort.load_settings(comfort_path)
	viewport = root
	viewport.size = Vector2i(1600, 900)
	viewport.gui_embed_subwindows = true
	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	viewport.add_child(menu)
	await settle()
	var launcher: Button = menu.get("_comfort_button")
	launcher.grab_focus()
	await key(KEY_ENTER, viewport)
	var modal: Control = menu.get("_comfort")
	check(modal.visible, "keyboard opens modal")
	# Master is the established initial focus; up reaches the new first option.
	await key(KEY_UP, viewport)
	check(modal.quality_choice.has_focus(), "keyboard reaches graphics through focus order")
	await key(KEY_ENTER, viewport)
	var popup: PopupMenu = modal.quality_choice.get_popup()
	check(popup.visible, "keyboard opens quality choices")
	await key(KEY_UP, popup)
	await key(KEY_UP, popup)
	await key(KEY_ENTER, popup)
	check(graphics.get_profile() == "low" and modal.quality_choice.selected == 0, "keyboard selects Low")
	check(is_equal_approx(root.scaling_3d_scale, 0.75) and root.msaa_3d == Viewport.MSAA_DISABLED, "keyboard selection changes real viewport")
	var saved := ConfigFile.new()
	check(saved.load(graphics_path) == OK and saved.get_value("graphics", "profile", "") == "low", "keyboard selection persists")
	modal.quality_choice.grab_focus()
	await pad(JOY_BUTTON_A, viewport)
	check(popup.visible, "controller opens quality choices")
	await pad(JOY_BUTTON_DPAD_DOWN, popup)
	await pad(JOY_BUTTON_A, popup)
	check(graphics.get_profile() == "medium" and modal.quality_choice.selected == 1, "controller selects Medium")
	check(is_equal_approx(root.scaling_3d_scale, 0.85) and root.msaa_3d == Viewport.MSAA_2X, "controller selection changes real viewport")
	saved.load(graphics_path)
	check(saved.get_value("graphics", "profile", "") == "medium", "controller selection persists")
	modal.quality_choice.grab_focus()
	await pad(JOY_BUTTON_A, viewport)
	await pad(JOY_BUTTON_B, popup)
	check(modal.visible and not popup.visible, "first controller cancel closes popup only")
	check(graphics.get_profile() == "medium", "cancel does not change selection")
	await key(KEY_ESCAPE, viewport)
	check(not modal.visible and launcher.has_focus(), "modal closes and returns focus")
	await key(KEY_ENTER, viewport)
	check(modal.visible and modal.quality_choice.selected == 1, "reopen retains selected quality")
	modal.restore_button.grab_focus()
	await key(KEY_ENTER, viewport)
	check(graphics.get_profile() == "medium" and "SOUND & SHAKE" in modal.restore_button.text, "sound/shake reset explicitly preserves graphics")
	modal.close_panel()
	menu.queue_free()
	await settle()
	graphics.load_settings(old_graphics)
	comfort.load_settings(old_comfort)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(graphics_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(comfort_path))
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	await settle()
	print("GRAPHICS_UI_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
