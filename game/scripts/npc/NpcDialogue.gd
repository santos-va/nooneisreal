class_name NpcDialogue
extends CanvasLayer
## Modal, controller-focusable choices; closing always releases the gameplay token.
signal choice_selected(action: String)
var prompt: Label
var panel: PanelContainer
var body: Label
var choices_box: VBoxContainer
var opened: bool = false

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
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-340, -285)
	panel.size = Vector2(680, 570)
	add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(600, 100)
	body.add_theme_font_size_override("font_size", 20)
	box.add_child(body)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 7)
	box.add_child(choices_box)
	panel.hide()

func show_choices(text: String, choices: Array[Dictionary]) -> void:
	body.text = text
	for old: Node in choices_box.get_children():
		choices_box.remove_child(old)
		old.queue_free()
	var first: Button
	for choice: Dictionary in choices:
		var button := Button.new()
		button.text = choice.label
		button.custom_minimum_size.y = 43
		button.disabled = not bool(choice.get("enabled", true))
		button.pressed.connect(func() -> void: choice_selected.emit(str(choice.id)))
		choices_box.add_child(button)
		if first == null and not button.disabled:
			first = button
	var close_button := Button.new()
	close_button.text = "Завершити розмову · Esc / B"
	close_button.custom_minimum_size.y = 43
	close_button.pressed.connect(close)
	choices_box.add_child(close_button)
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

func _unhandled_input(event: InputEvent) -> void:
	if opened and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	InputRouter.release_ui(self)

func _process(_delta: float) -> void:
	if get_tree().paused or InputRouter.ui_suppressed():
		prompt.hide()
