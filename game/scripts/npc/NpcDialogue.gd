class_name NpcDialogue
extends CanvasLayer
## A small optional overlay. InputRouter token isolates gameplay while open.
var prompt: Label
var panel: PanelContainer
var body: Label
var opened: bool = false

func _ready() -> void:
	layer = 30
	prompt = Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-250, -115)
	prompt.size = Vector2(500, 35)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-270, -360)
	panel.custom_minimum_size = Vector2(540, 230)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(510, 170)
	box.add_child(body)
	var button := Button.new()
	button.text = "Завершити розмову · Esc / B"
	button.pressed.connect(close)
	box.add_child(button)
	panel.hide()

func show_fact(text: String) -> void:
	body.text = text
	opened = true
	panel.show()
	prompt.hide()
	InputRouter.acquire_ui(self)
	panel.get_child(0).get_child(1).grab_focus()

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
