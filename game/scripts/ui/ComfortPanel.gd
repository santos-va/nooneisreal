class_name ComfortPanel
extends Control
## Shared modal: presentation preferences only. The caller retains pause ownership.
signal closed
var sliders: Dictionary = {}
var controls_label: Label
var back_button: Button
var restore_button: Button
var panel: PanelContainer
var scroll: ScrollContainer
var _invoker: Control
var _focus_order: Array[Control] = []
var _status: Label
var _settings: Node
var _syncing := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_settings = get_node("/root/ComfortSettings")
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.02, 0.035, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	panel = PanelContainer.new()
	add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.075, 0.11)
	style.border_color = Color(0.85, 0.5, 0.3)
	style.set_border_width_all(2)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	column.add_child(_label("COMFORT & CONTROLS", 32))
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	scroll.add_child(content)
	var labels := {"master": "MASTER", "sfx": "SOUND EFFECTS", "music": "MUSIC", "shake": "CAMERA SHAKE"}
	for key: String in labels:
		var row := VBoxContainer.new()
		content.add_child(row)
		var title := _label("", 32)
		row.add_child(title)
		var slider := HSlider.new()
		slider.name = key.capitalize() + "Slider"
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 5
		slider.custom_minimum_size.y = 40
		slider.value = float(_settings.call("get_value", key)) * 100
		sliders[key] = slider
		row.add_child(slider)
		_focus_order.append(slider)
		slider.value_changed.connect(func(value: float):
			title.text = "%s  %d%%%s" % [labels[key], roundi(value), " · OFF" if value == 0 else ""]
			if not _syncing:
				_settings.call("set_value", key, value / 100.0)
				_save())
		slider.value_changed.emit(slider.value)
	restore_button = _button("RESTORE COMFORT DEFAULTS", func():
		_settings.call("reset_defaults")
		_sync_values()
		_save())
	content.add_child(restore_button)
	_focus_order.append(restore_button)
	controls_label = _label("", 32)
	controls_label.focus_mode = Control.FOCUS_ALL
	controls_label.gui_input.connect(_scroll_help)
	_focus_order.append(controls_label)
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(controls_label)
	_status = _label("", 32)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	back_button = _button("BACK", close_panel)
	column.add_child(back_button)
	_focus_order.append(back_button)
	for i in _focus_order.size():
		var item := _focus_order[i]
		item.focus_neighbor_top = item.get_path_to(_focus_order[posmod(i - 1, _focus_order.size())])
		item.focus_neighbor_bottom = item.get_path_to(_focus_order[(i + 1) % _focus_order.size()])
		item.focus_previous = item.focus_neighbor_top
		item.focus_next = item.focus_neighbor_bottom
	get_viewport().gui_focus_changed.connect(_keep_focus)
	resized.connect(_layout)
	_layout()
	_syncing = false
	hide()

func _layout() -> void:
	if panel == null:
		return
	panel.size = Vector2(minf(940, size.x - 48), maxf(200, size.y - 48))
	panel.position = (size - panel.size) * 0.5

func show_panel(invoker: Control, controls: String) -> void:
	InputRouter.acquire_ui(self)
	_invoker = invoker
	controls_label.text = "CONTROLS — %s / %s\n\n" % ["3D" if GameState.free_move else "2.5D", InputRouter.profile.to_upper()] + controls.replace(" · ", "\n").replace("      P2", "\n\nP2").replace("   |   ", "\n\n")
	controls_label.text += "\n\nHARPOON\nEnemy hook pulls on contact; parkour hook attaches to anchors.\nParkour is latched: tap to attach, aim at the next anchor and tap again to transfer.\nHold jump to reel in; move sideways to steer.\nGet closer beneath an anchor for lift; distant ropes pull toward it.\nDetach: Z / B, or dodge. Enemy grapple still uses hold / release.\nA rope cue means grab the deployed rope; no new hook is spent.\n\nChoko carries 7 hooks; Skea carries 2. Returning a hook restores its slot; there is no timer refill.\nDeployed parkour ropes remain in the match and either fighter can reuse them.\nMisses rewind automatically. During recovery, hands are busy; use light movement and kicks.\nAfter hooking an enemy, extraction returns the hook. A kick helps extract it during the strike.\n".replace("Detach: Z", "Detach: " + InputRouter.binding_label(1, "grapple_detach", false))
	controls_label.text += "\nAIM (solo)\nHold the right mouse button and drag, or use the right stick, to aim the view.\nThe view returns smoothly when released; the target cue is a suggestion, not a guaranteed hit.\n"
	controls_label.text += "\nCHOKO SWORD\nWeapon swap first draws the sword from the back; later swaps reform it in the other hand.\nUse it while standing or walking.\nThe armed hand cuts; the free hand punches. A kick or dash interrupts the transfer.\n"
	controls_label.text += _gamepad_help()
	_sync_values()
	show()
	_layout()
	scroll.scroll_vertical = 0
	(sliders["master"] as HSlider).grab_focus()
	# Follow-focus ensures the slider but can hide its preceding label.
	await get_tree().process_frame
	if visible:
		scroll.scroll_vertical = 0

func close_panel() -> void:
	_save()
	hide()
	InputRouter.release_ui(self)
	if is_instance_valid(_invoker) and _invoker.is_visible_in_tree():
		_invoker.grab_focus()
	closed.emit()

func _sync_values() -> void:
	_syncing = true
	for key: String in sliders:
		(sliders[key] as HSlider).value = float(_settings.call("get_value", key)) * 100
	_syncing = false

func _save() -> void:
	if _status == null:
		return
	var result: int = _settings.call("save_settings")
	_status.text = "Could not save preferences; changes apply for this session." if result != OK else ""

func _keep_focus(control: Control) -> void:
	if visible and control != null and not is_ancestor_of(control):
		back_button.grab_focus.call_deferred()

func _input(event: InputEvent) -> void:
	if visible and not event.is_echo() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause")):
		get_viewport().set_input_as_handled()
		close_panel()

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86))
	return label

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(action)
	return button


func _exit_tree() -> void:
	InputRouter.release_ui(self)

func _scroll_help(event: InputEvent) -> void:
	var direction := 0
	if event.is_action_pressed("ui_down"):
		direction = 1
	elif event.is_action_pressed("ui_up"):
		direction = -1
	if direction == 0:
		return
	var before := scroll.scroll_vertical
	scroll.scroll_vertical += direction * 72
	if scroll.scroll_vertical == before:
		(back_button if direction > 0 else restore_button).grab_focus()
	accept_event()


func _gamepad_help() -> String:
	var text := "\n\nGAMEPAD · Left stick moves freely\n"
	for action in ["jump", "crouch", "left_hand", "right_hand", "left_leg", "right_leg", "block", "skill1", "skill2", "grapple_enemy", "grapple_parkour", "grapple_detach", "dodge", "dash", "interact", "weapon_swap", "ultimate"]:
		text += action.capitalize() + ": " + InputRouter.binding_label(1, action, true) + "\n"
	return text + "L3: direct parkour grab, leaving the right thumb free to aim.\nHold Y before pressing a shoulder / trigger.\nRelease the shoulder / trigger before changing its action.\n\nUp / Down: scroll controls · Tab: next · Esc / B: back"
