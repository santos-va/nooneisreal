extends SceneTree
## Colour test switch A / B3 (plan docs/Plans/2026-10-14-T6-Acceptance-Crane-Albedo-AB.md step 8, variant V1;
## docs/Fix/2026-10-15-Colour-Switch-Fix.md). A fixture: player preferences are never touched (own user:// files).
## Subject: for every way the choice is made — GraphicsSettings API, graphics.cfg, the COLOURS (TEST) row by keyboard and
## gamepad — exactly the chosen value plays, is saved and is handed to RenderingServer as the global uniform colour_b3
## that the five shaders branch on; a fresh profile plays A; an unknown or damaged file plays A and its bytes are never
## written over.
## Families (a red check names its family in the final line):
##   global   — project.godot [shader_globals] colour_b3 is a bool, false (A)
##   shader   — each of the five shaders declares `global uniform bool colour_b3;` and its light() branches on it: the
##              B3 part has no ALBEDO, the A part still has it
##   default  — a fresh profile (no file) plays A; loading writes nothing
##   persist  — save → read round-trip next to the profile; unowned keys and sections survive; a profile save keeps it
##   unknown  — an unknown saved or runtime value → A (ERR_INVALID_DATA for a file), the readable profile still applies
##   cfg      — unknown or malformed bytes are never written over; the failed write is reported to the panel
##   row      — the row sits right under GRAPHICS QUALITY, in the focus ring between it and MASTER; keyboard and gamepad
##              pick, the pick applies at once; RESTORE leaves it alone; a reopened panel shows the value
##   row_save — the row's pick is saved to graphics.cfg
##   apply    — after every change the value handed to RenderingServer equals the chosen one (GraphicsSettings
##              .colours_applied: the engine reads global uniforms back only in the editor; headless keeps none)
##   rs       — native only: a probe of the five shaders renders a different frame on B3 for each shader and the same
##              frame back on A. Headless has no pixels: the final line says rs=not-measured-headless.
## --break=<m> negative controls, each must go red in its own family:
##   default  — a load path that starts a fresh profile on B3
##   persist  — a load path that forgets the saved key (plays A over a saved B3)
##   unknown  — a reader that plays B3 for any value but "a"
##   cfg      — a save path that forgets the _load_error guard
##   row      — a row that never calls set_colours
##   row_save — a row that applies but never saves
##   global   — project.godot shipping colour_b3 = true
##   shader   — hero_garment without its branch (`if (false)`; natively its probe sphere draws with that code too)
##   apply    — a row that changes the value without handing it to RenderingServer (natively also: the uniform put
##              back to A right after the switch)
const MUTATIONS := ["default", "persist", "unknown", "cfg", "row", "row_save", "global", "shader", "apply"]
const SHADERS := ["city_surface", "toon", "sword_dissolve", "gear_surface", "hero_garment"]
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var red: Dictionary = {}
var graphics: Node
var _paths: Array[String] = []


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func check(family: String, ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		red[family] = true
		push_error("COLOUR_SWITCH: [%s] %s" % [family, label])


func _settle() -> void:
	for frame: int in 4:
		await process_frame


func _key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await physics_frame
		await _settle()


func _pad(button: JoyButton) -> void:
	for down: bool in [true, false]:
		var event := InputEventJoypadButton.new()
		event.device = 0
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await physics_frame
		await _settle()


func _path(tag: String) -> String:
	var path := "user://colour_switch_%s_%d.cfg" % [tag, OS.get_process_id()]
	_paths.append(path)
	for suffix: String in ["", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	return path


func _bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _cfg(path: String) -> ConfigFile:
	var config := ConfigFile.new()
	config.load(path)
	return config


## Every value check is paired with the apply check: what RenderingServer was handed equals the chosen value.
func _value(family: String, want: String, label: String) -> void:
	check(family, graphics.get_colours() == want, "%s (want %s, got %s)" % [label, want, graphics.get_colours()])
	check("apply", graphics.colours_applied == graphics.get_colours(), "%s: RenderingServer was handed %s, the setting is %s" % [label, graphics.colours_applied, graphics.get_colours()])


func _run() -> void:
	await process_frame
	if mutation != "none" and not MUTATIONS.has(mutation):
		push_error("COLOUR_SWITCH: unknown --break=%s" % mutation)
		quit(2)
		return
	graphics = root.get_node("GraphicsSettings")
	var old_path: String = graphics.storage_path
	var comfort: Node = root.get_node("ComfortSettings")
	var old_comfort: String = comfort.storage_path
	root.gui_embed_subwindows = true
	# The autoload applied its value at boot (the runner's profile has no graphics.cfg: A).
	check("default", graphics.get_colours() == "a", "boot plays A (got %s)" % graphics.get_colours())
	check("apply", graphics.colours_applied == graphics.get_colours(), "boot handed %s to RenderingServer, the setting is %s" % [graphics.colours_applied, graphics.get_colours()])
	_project_and_shaders()
	_fresh()
	_persistence()
	_hostile()
	comfort.load_settings(_path("comfort"))
	await _row()
	var rs: String = "not-measured-headless"
	if DisplayServer.get_name() != "headless":
		rs = await _pixels()
	graphics.load_settings(old_path)
	comfort.load_settings(old_comfort)
	for path: String in _paths:
		for suffix: String in ["", ".tmp"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	await _settle()
	var families: Array = red.keys()
	families.sort()
	print("COLOUR_SWITCH_COMPLETE checks=%d failures=%d mutation=%s red=%s rs=%s" % [checks, failures, mutation,
		",".join(PackedStringArray(families)) if not families.is_empty() else "none", rs])
	quit(1 if failures else 0)


# --- project.godot and the five shaders ------------------------------------------------------------------------

func _project_and_shaders() -> void:
	if mutation == "global":
		ProjectSettings.set_setting("shader_globals/colour_b3", {"type": "bool", "value": true})
	var entry: Variant = ProjectSettings.get_setting("shader_globals/colour_b3")
	check("global", entry is Dictionary and entry.get("type") == "bool" and entry.get("value") == false,
		"project.godot [shader_globals] colour_b3 is a bool that defaults to false / A (got %s)" % str(entry))
	check("global", graphics.COLOUR_GLOBAL == &"colour_b3", "GraphicsSettings sets the same global (%s)" % graphics.COLOUR_GLOBAL)
	for name: String in SHADERS:
		var shader: Shader = load("res://shaders/%s.gdshader" % name)
		var code: String = shader.code if shader != null else ""
		if mutation == "shader" and name == "hero_garment":
			code = code.replace("if (colour_b3)", "if (false)")
		var parts: Dictionary = _light_branch(code)
		check("shader", code.count("global uniform bool colour_b3;") == 1, "%s declares global uniform bool colour_b3 once" % name)
		check("shader", bool(parts.found), "%s: light() branches on colour_b3" % name)
		check("shader", int(parts.b3_albedo) == 0 and int(parts.a_albedo) >= 1,
			"%s: in light() the B3 part has no ALBEDO (%d) and the A part keeps it (%d)" % [name, int(parts.b3_albedo), int(parts.a_albedo)])


## The `if (colour_b3) { … } else { … }` inside light(): ALBEDO tokens in each part.
static func _light_branch(code: String) -> Dictionary:
	var result := {"found": false, "b3_albedo": -1, "a_albedo": -1}
	var head: int = code.find("void light()")
	if head < 0:
		return result
	var body: String = _block(code, code.find("{", head))
	var at: int = body.find("if (colour_b3) {")
	if at < 0:
		return result
	var b3: String = _block(body, body.find("{", at))
	var rest: String = body.substr(body.find("{", at) + b3.length())
	if not rest.strip_edges().begins_with("else {"):
		return result
	var a: String = _block(rest, rest.find("{"))
	var comment := RegEx.create_from_string("//[^\\n]*")
	var token := RegEx.create_from_string("\\bALBEDO\\b")
	return {"found": true, "b3_albedo": token.search_all(comment.sub(b3, "", true)).size(),
		"a_albedo": token.search_all(comment.sub(a, "", true)).size()}


## The text from the brace at `open` to its matching brace, both included ("" when unmatched).
static func _block(text: String, open: int) -> String:
	if open < 0:
		return ""
	var depth: int = 0
	for index: int in range(open, text.length()):
		if text[index] == "{":
			depth += 1
		elif text[index] == "}":
			depth -= 1
			if depth == 0:
				return text.substr(open, index - open + 1)
	return ""


# --- persistence -----------------------------------------------------------------------------------------------

func _fresh() -> void:
	var fresh := _path("fresh")
	graphics.set_colours("b3") # the session was on B3 before a fresh profile is read
	var rc: Error = graphics.load_settings(fresh)
	if mutation == "default":
		graphics.set_colours("b3")
	check("default", rc == OK, "a missing file loads OK (%d)" % rc)
	_value("default", "a", "a fresh profile plays A")
	check("default", not FileAccess.file_exists(fresh), "loading a fresh profile writes no file")


func _persistence() -> void:
	var path := _path("persist")
	graphics.load_settings(path)
	check("persist", graphics.set_colours("b3"), "set_colours accepts b3")
	_value("persist", "b3", "set_colours(b3) applies at once")
	check("persist", graphics.save_colours() == OK and graphics.save_error == OK, "save_colours writes graphics.cfg")
	check("persist", _cfg(path).get_value("graphics", "colours", "") == "b3", "graphics.cfg holds [graphics] colours=\"b3\"")
	graphics.set_colours("a") # a session change that is not saved
	var rc: Error = graphics.load_settings(path)
	if mutation == "persist":
		graphics.set_colours("a")
	check("persist", rc == OK, "the saved file loads OK (%d)" % rc)
	_value("persist", "b3", "a saved B3 reads back and plays at load")
	# Next to the profile: unowned keys and sections survive, the profile's own save keeps the colours key.
	var shared := _path("shared")
	_write(shared, "[graphics]\n\nprofile=\"low\"\ncolours=\"b3\"\nfuture=\"keep\"\n\n[other]\n\npreserve=42\n")
	check("persist", graphics.load_settings(shared) == OK and graphics.get_profile() == "low", "profile and colours load side by side")
	_value("persist", "b3", "colours read next to profile=low")
	graphics.set_colours("a")
	graphics.save_colours()
	var kept := _cfg(shared)
	check("persist", kept.get_value("graphics", "colours", "") == "a" and kept.get_value("graphics", "profile", "") == "low"
		and kept.get_value("graphics", "future", "") == "keep" and kept.get_value("other", "preserve", 0) == 42,
		"a colours save keeps profile, unowned keys and sections")
	graphics.set_profile("medium")
	graphics.save_settings()
	kept = _cfg(shared)
	check("persist", kept.get_value("graphics", "colours", "") == "a" and kept.get_value("graphics", "profile", "") == "medium",
		"a profile save keeps the colours key")


func _hostile() -> void:
	graphics.load_settings(_path("runtime"))
	graphics.set_colours("b3")
	for bad: Variant in [null, 0, 1, true, 0.5, "B3", "b1", "A", "", ["b3"], {"colours": "b3"}]:
		check("unknown", not graphics.set_colours(bad), "runtime value rejected: %s" % str(bad))
		_value("unknown", "b3", "a rejected runtime value leaves the session as it was (%s)" % str(bad))
	# Unknown values with valid syntax: A plays, the readable profile applies, the bytes stay.
	for hostile: String in ["\"b1\"", "\"B3\"", "\"\"", "1", "true", "[\"b3\"]", "{\n\"colours\": \"b3\"\n}"]:
		var file := _path("hostile")
		_write(file, "[graphics]\n\nprofile=\"low\"\ncolours=%s\n" % hostile)
		var before := _bytes(file)
		graphics.set_colours("b3") # the session was on B3 before reading the file
		var rc: Error = graphics.load_settings(file)
		if mutation == "unknown":
			graphics.set_colours("b3")
		if mutation == "cfg":
			graphics.set("_load_error", OK)
		check("unknown", rc == ERR_INVALID_DATA, "unknown colours rejected: %s (%d)" % [hostile, rc])
		_value("unknown", "a", "unknown colours %s play A" % hostile)
		check("unknown", graphics.get_profile() == "low", "the readable profile still applies next to colours=%s" % hostile)
		graphics.set_colours("b3")
		graphics.save_colours()
		check("cfg", graphics.save_error != OK, "the refused write is reported to the panel (colours=%s)" % hostile)
		check("cfg", _bytes(file) == before, "unknown colours bytes preserved after a colour change (colours=%s)" % hostile)
	# A malformed file: A plays, the session can still switch, nothing is written over.
	var damaged := _path("damaged")
	_write(damaged, "[graphics\ncolours = = b3\n[[")
	var damaged_bytes := _bytes(damaged)
	graphics.set_colours("b3")
	var previous_errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	var parse_error: Error = graphics.load_settings(damaged)
	Engine.print_error_messages = previous_errors
	if mutation == "cfg":
		graphics.set("_load_error", OK)
	check("cfg", parse_error != OK, "a malformed file is reported (%d)" % parse_error)
	_value("cfg", "a", "a malformed file plays A")
	check("cfg", graphics.set_colours("b3"), "a damaged file still lets the session switch")
	_value("cfg", "b3", "the session switch on a damaged file applies")
	graphics.save_colours()
	check("cfg", graphics.save_error != OK, "the refused write on a malformed file is reported to the panel")
	graphics.set_profile("low")
	graphics.save_settings()
	check("cfg", _bytes(damaged) == damaged_bytes, "malformed bytes preserved after colour and profile changes")


# --- the COLOURS (TEST) row ------------------------------------------------------------------------------------

func _row() -> void:
	var ui_path := _path("ui")
	graphics.load_settings(ui_path)
	var launcher := Button.new()
	launcher.text = "LAUNCHER"
	root.add_child(launcher)
	var panel: Control = load("res://scripts/ui/ComfortPanel.gd").new()
	root.add_child(panel)
	await _settle()
	var choice: OptionButton = panel.get("colour_choice")
	check("row", choice != null, "the panel has a COLOURS (TEST) row")
	if choice == null:
		panel.queue_free()
		launcher.queue_free()
		return
	if mutation in ["row", "row_save", "apply"]:
		for connection: Dictionary in choice.item_selected.get_connections():
			choice.item_selected.disconnect(connection.callable)
		if mutation == "row_save":
			choice.item_selected.connect(func(index: int): graphics.set_colours(graphics.COLOURS[index]))
		elif mutation == "apply":
			choice.item_selected.connect(func(index: int):
				graphics.set("_colours", graphics.COLOURS[index])
				graphics.save_colours())
	panel.show_panel(launcher, "help")
	await _settle()
	# Placement: right under GRAPHICS QUALITY (its help line between), in the ring between it and MASTER.
	var quality: OptionButton = panel.quality_choice
	var master: Control = panel.sliders["master"]
	var column: Node = quality.get_parent()
	var title_at: int = choice.get_index() - 1
	check("row", choice.get_parent() == column and choice.get_index() == quality.get_index() + 3
		and (column.get_child(title_at) as Label).text == "COLOURS (TEST)",
		"the row sits right under GRAPHICS QUALITY and its help line, titled COLOURS (TEST)")
	var labels: PackedStringArray = []
	for item: int in choice.item_count:
		labels.append(choice.get_item_text(item))
	check("row", labels.size() == 2 and labels[0].begins_with("A ") and labels[1].begins_with("B3 "),
		"two items, A then B3, in GraphicsSettings.COLOURS order (%s)" % " | ".join(labels))
	# T8 2026-10-15 (docs/Audit/2026-10-15-T8-Colour-Switch-Row-Acceptance.md, spec steps 1–2): the words T8 accepted, and
	# no help line between the row and MASTER — item A says what the help line used to.
	check("row", labels == PackedStringArray(["A — the game as it is", "B3 — palette-true light"]),
		"the items read «A — the game as it is» and «B3 — palette-true light» (%s)" % " | ".join(labels))
	check("row", choice.get_index() + 1 < column.get_child_count() and column.get_child(choice.get_index() + 1) == master.get_parent(),
		"MASTER comes right after the row, with no help line between")
	check("row", choice.selected == 0, "an unsaved profile shows A selected (%d)" % choice.selected)
	var order: Array = panel.get("_focus_order")
	var at: int = order.find(quality)
	check("row", at >= 0 and at + 2 < order.size() and order[at + 1] == choice and order[at + 2] == master,
		"focus order: GRAPHICS QUALITY → COLOURS (TEST) → MASTER")
	check("row", choice.focus_neighbor_top == choice.get_path_to(quality) and choice.focus_neighbor_bottom == choice.get_path_to(master)
		and quality.focus_neighbor_bottom == quality.get_path_to(choice) and master.focus_neighbor_top == master.get_path_to(choice),
		"focus neighbours: GRAPHICS QUALITY ↕ COLOURS (TEST) ↕ MASTER")
	check("row", choice.custom_minimum_size.y == quality.custom_minimum_size.y and choice.focus_mode == quality.focus_mode,
		"the row has the quality row's height and focus mode")
	# Keyboard: the panel opens on MASTER; Up reaches the row; Enter, Down, Enter picks B3.
	check("row", master.has_focus(), "the panel opens on MASTER")
	await _key(KEY_UP)
	check("row", choice.has_focus(), "Up from MASTER reaches COLOURS (TEST)")
	await _key(KEY_ENTER)
	var popup: PopupMenu = choice.get_popup()
	check("row", popup.visible, "Enter opens the COLOURS choices")
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	check("row", choice.selected == 1 and not popup.visible, "keyboard selects B3 (%d)" % choice.selected)
	_value("row", "b3", "the keyboard pick plays at once")
	check("row_save", _cfg(ui_path).get_value("graphics", "colours", "") == "b3", "the keyboard pick is saved to graphics.cfg")
	# Gamepad: A opens, D-pad Up, A picks A; B on an open list closes only the list.
	choice.grab_focus()
	await _pad(JOY_BUTTON_A)
	check("row", popup.visible, "gamepad A opens the COLOURS choices")
	await _pad(JOY_BUTTON_DPAD_UP)
	await _pad(JOY_BUTTON_A)
	check("row", choice.selected == 0, "gamepad selects A (%d)" % choice.selected)
	_value("row", "a", "the gamepad pick plays at once")
	check("row_save", _cfg(ui_path).get_value("graphics", "colours", "") == "a", "the gamepad pick is saved to graphics.cfg")
	choice.grab_focus()
	await _pad(JOY_BUTTON_A)
	await _pad(JOY_BUTTON_B)
	check("row", panel.visible and not popup.visible and graphics.get_colours() == "a", "gamepad B closes the list only, the value stays")
	choice.grab_focus()
	await _key(KEY_UP)
	check("row", quality.has_focus(), "Up from COLOURS (TEST) reaches GRAPHICS QUALITY")
	# RESTORE SOUND & SHAKE DEFAULTS leaves it alone; a reopened panel shows the saved value.
	choice.select(1)
	choice.item_selected.emit(1)
	await _settle()
	panel.restore_button.pressed.emit()
	await _settle()
	check("row", graphics.get_colours() == "b3" and choice.selected == 1, "RESTORE SOUND & SHAKE DEFAULTS leaves COLOURS alone")
	panel.close_panel()
	await _settle()
	graphics.set_colours("a") # an unsaved session change while the panel is closed
	graphics.load_settings(ui_path)
	panel.show_panel(launcher, "help")
	await _settle()
	check("row", choice.selected == graphics.COLOURS.find(graphics.get_colours()), "a reopened panel shows the current value")
	check("row_save", graphics.get_colours() == "b3", "the row's last pick (B3) is what graphics.cfg reads back")
	panel.close_panel()
	panel.queue_free()
	launcher.queue_free()
	await _settle()
	# A phone has the row too, in the same place of its ring.
	var old_mobile: int = graphics.mobile_override
	graphics.mobile_override = 1
	var phone: Control = load("res://scripts/ui/ComfortPanel.gd").new()
	root.add_child(phone)
	await _settle()
	var phone_order: Array = phone.get("_focus_order")
	check("row", phone.get("display_choice") == null and phone_order.size() >= 3 and phone_order[0] == phone.quality_choice
		and phone_order[1] == phone.get("colour_choice") and phone_order[2] == phone.sliders["master"],
		"a phone ring: GRAPHICS QUALITY → COLOURS (TEST) → MASTER")
	phone.queue_free()
	graphics.mobile_override = old_mobile
	await _settle()


# --- native pixels -----------------------------------------------------------------------------------------------

func _grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _pixels() -> String:
	graphics.load_settings(_path("pixels"))
	var stage := Node3D.new()
	root.add_child(stage)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.0, 6.5)
	camera.fov = 50.0
	stage.add_child(camera)
	camera.make_current()
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-44, -28, 0) # CityWorld.gd sun
	stage.add_child(sun)
	for index: int in SHADERS.size():
		var mesh := MeshInstance3D.new()
		mesh.mesh = SphereMesh.new()
		var material := ShaderMaterial.new()
		material.shader = load("res://shaders/%s.gdshader" % SHADERS[index])
		if mutation == "shader" and SHADERS[index] == "hero_garment":
			var twin := Shader.new()
			twin.code = material.shader.code.replace("if (colour_b3)", "if (false)")
			material.shader = twin
		mesh.material_override = material
		mesh.position = Vector3(index * 1.25 - 2.5, 1.0, 0)
		stage.add_child(mesh)
	for frame: int in 6:
		await process_frame
	graphics.set_colours("a")
	await _settle()
	var off: Image = await _grab()
	graphics.set_colours("b3")
	if mutation == "apply":
		RenderingServer.global_shader_parameter_set(&"colour_b3", false) # the value changed, the renderer never saw it
	await _settle()
	var on: Image = await _grab()
	graphics.set_colours("a")
	await _settle()
	var off_again: Image = await _grab()
	check("rs", off.get_data() == off_again.get_data(), "back to A renders the A frame byte for byte")
	# Each sphere's band: sphere i is centred at x = i·1.25 − 2.5 m on the plane z = 0, 6.5 m from the lens (vertical fov).
	var size: Vector2i = off.get_size()
	var half_width: float = 6.5 * tan(deg_to_rad(camera.fov * 0.5)) * float(size.x) / float(size.y)
	for index: int in SHADERS.size():
		var centre: float = index * 1.25 - 2.5
		var x0: int = int(size.x * (0.5 + (centre - 0.625) / (2.0 * half_width)))
		var x1: int = int(size.x * (0.5 + (centre + 0.625) / (2.0 * half_width)))
		var changed: int = 0
		for x: int in range(maxi(x0, 0), mini(x1, size.x), 2):
			for y: int in range(0, size.y, 2):
				if off.get_pixel(x, y) != on.get_pixel(x, y):
					changed += 1
		print("COLOUR_SWITCH_RS %s band_x=%d..%d changed_sampled_px=%d" % [SHADERS[index], x0, x1, changed])
		check("rs", changed > 0, "%s: B3 changes its band of the frame (%d sampled px)" % [SHADERS[index], changed])
	stage.queue_free()
	await _settle()
	return "measured-pixels-" + RenderingServer.get_current_rendering_method()
