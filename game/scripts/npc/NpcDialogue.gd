class_name NpcDialogue
extends CanvasLayer
## Modal, controller-focusable choices; closing always releases the gameplay token.
signal choice_selected(action: String)
signal closed
signal local_enabled_changed(value: bool)
var prompt: Label
var panel: PanelContainer
var body: Label
var flavor: Label
var local_toggle: CheckButton
var choices_box: VBoxContainer
var opened: bool = false
var panel_width: float = 540.0

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	prompt = Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-300, -115)
	prompt.size = Vector2(600, 35)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt)
	panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.055, 0.075, 0.98)
	style.border_color = Color(0.62, 0.48, 0.31, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(0, 100)
	body.add_theme_font_size_override("font_size", 20)
	box.add_child(body)
	flavor = Label.new()
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.custom_minimum_size.x = 0
	flavor.add_theme_color_override("font_color", Color("e0c395"))
	box.add_child(flavor)
	local_toggle = CheckButton.new()
	local_toggle.text = "Живі розмови на пристрої"
	local_toggle.clip_text = true
	local_toggle.tooltip_text = "Додаткові репліки від установленої локальної моделі. Гра працює і без неї."
	local_toggle.toggled.connect(func(value: bool) -> void: local_enabled_changed.emit(value))
	box.add_child(local_toggle)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 7)
	box.add_child(choices_box)
	panel.hide()
	get_viewport().size_changed.connect(_layout_panel)
	_layout_panel()

func show_choices(text: String, choices: Array[Dictionary]) -> void:
	body.text = text
	flavor.text = ""
	for old: Node in choices_box.get_children():
		choices_box.remove_child(old)
		old.queue_free()
	var first: Button
	for choice: Dictionary in choices:
		var button := Button.new()
		button.set_meta("full_text", str(choice.label))
		button.text = str(choice.label)
		button.clip_text = true
		button.custom_minimum_size.y = 43
		button.disabled = not bool(choice.get("enabled", true))
		button.pressed.connect(func() -> void: choice_selected.emit(str(choice.id)))
		choices_box.add_child(button)
		if first == null and not button.disabled:
			first = button
	var close_button := Button.new()
	close_button.text = "Завершити розмову · Esc / B"
	close_button.set_meta("full_text", close_button.text)
	close_button.clip_text = true
	close_button.custom_minimum_size.y = 43
	close_button.pressed.connect(close)
	choices_box.add_child(close_button)
	_layout_panel()
	opened = true
	panel.show()
	prompt.hide()
	InputRouter.acquire_ui(self)
	(first if first != null else close_button).grab_focus()

func show_fact(text: String) -> void:
	show_choices(text, [])

func close() -> void:
	opened = false
	panel.hide()
	InputRouter.release_ui(self)
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if opened and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	InputRouter.release_ui(self)

func _process(_delta: float) -> void:
	if get_tree().paused or InputRouter.ui_suppressed():
		prompt.hide()

func _layout_panel() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	panel_width = clampf(viewport_size.x * 0.42, 360.0, 640.0)
	panel.position = Vector2(viewport_size.x - panel_width - 24.0, 40.0)
	panel.size = Vector2(panel_width, maxf(240.0, viewport_size.y - 80.0))
	if choices_box == null:
		return
	for child: Node in choices_box.get_children():
		if child is Button:
			var full_text: String = str(child.get_meta("full_text", child.text))
			var font: Font = child.get_theme_font("font")
			var font_size: int = child.get_theme_font_size("font_size")
			var lines: Array[String] = []
			var line: String = ""
			for word: String in full_text.split(" "):
				var candidate: String = word if line.is_empty() else line + " " + word
				if not line.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > panel_width - 76.0:
					lines.append(line)
					line = word
				else:
					line = candidate
			lines.append(line)
			child.text = "\n".join(lines)
			child.custom_minimum_size.y = maxf(43.0, font.get_height(font_size) * lines.size() + 18.0)
