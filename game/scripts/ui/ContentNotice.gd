class_name ContentNotice
extends CanvasLayer
## The blood card before ROUND 1 of the first lethal fight (ADR-024 п. 7; plan step 4, T8): "This fight shows blood"
## and the four BLOOD modes, focus on the current one. Enter / A on a mode keeps it, marks the card seen and saves;
## Esc / B steps back to the city without a fight. It owns UI input while shown; no new input action. Never red
## (Style-Guide: blood colours are not for UI).
signal confirmed(mode: String)
signal cancelled

const LABELS := {"full": "FULL — splashes and stains", "muted": "MUTED — darker, shorter, no pools", "ink": "INK — ink strokes instead of blood", "off": "OFF — only hit sparks"}
var buttons: Dictionary = {}
var title: Label
var body: Label
var panel: PanelContainer
var _root: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 21
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.02, 0.035, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.075, 0.11)
	style.border_color = Color("FAEDD9")
	style.set_border_width_all(2)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	title = _label("THIS FIGHT SHOWS BLOOD", 44)
	column.add_child(title)
	body = _label("Choose how blood looks. You can change it any time in COMFORT & CONTROLS.", 26)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 640
	column.add_child(body)
	var order: Array[Button] = []
	for mode: String in ContentSettings.BLOOD_MODES:
		var button := Button.new()
		button.name = mode.capitalize() + "Blood"
		button.text = LABELS[mode]
		button.custom_minimum_size = Vector2(640, 48)
		button.add_theme_font_size_override("font_size", 30)
		var picked := mode
		button.pressed.connect(func() -> void: _confirm(picked))
		column.add_child(button)
		buttons[mode] = button
		order.append(button)
	for i: int in order.size():
		order[i].focus_neighbor_top = order[i].get_path_to(order[posmod(i - 1, order.size())])
		order[i].focus_neighbor_bottom = order[i].get_path_to(order[(i + 1) % order.size()])
	hide()


func open() -> void:
	show()
	InputRouter.acquire_ui(self)
	var current: String = ContentSettings.blood_mode()
	(buttons.get(current, buttons["full"]) as Button).grab_focus()


func _confirm(mode: String) -> void:
	ContentSettings.set_blood_mode(mode)
	ContentSettings.mark_notice_seen()
	ContentSettings.save_settings()   # a damaged file stays untouched; the choice holds for this session
	_close()
	confirmed.emit(mode)


func _input(event: InputEvent) -> void:
	if visible and not event.is_echo() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause")):
		get_viewport().set_input_as_handled()
		_close()
		cancelled.emit()


func _close() -> void:
	hide()
	InputRouter.release_ui(self)
	get_viewport().gui_release_focus()


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86))
	return label


func _exit_tree() -> void:
	InputRouter.release_ui(self)
