class_name CityHud
extends CanvasLayer
## Exploration overlay with its own pause/input owner; no combat HUD state is reused.
signal restart_requested
signal exit_requested

var onboarding: CityOnboarding
var paused_ui: bool = false
var pause_panel: Control
var resume_button: Button
var skip_button: Button
var restart_button: Button
var exit_button: Button
var pause_button: Button
var objective_label: Label
var hint_label: Label
var resource_label: Label
var _objective_title: Label
var _root: Control
var _rope_text: String = ""
var _dash_text: String = ""


func setup(model: CityOnboarding) -> void:
	if onboarding != null and onboarding.changed.is_connected(_refresh):
		onboarding.changed.disconnect(_refresh)
	onboarding = model
	onboarding.changed.connect(_refresh)
	_refresh()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var card := PanelContainer.new()
	card.position = Vector2(24, 24)
	card.custom_minimum_size.x = 780
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	column.add_child(_label("CITY EXPLORATION · PROTOTYPE", 32))
	column.add_child(_label("Opening sketch · Find your bearings beneath the clocktower.", 24))
	_objective_title = _label("", 32)
	column.add_child(_objective_title)
	objective_label = _label("", 32)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.x = 750
	column.add_child(objective_label)
	resource_label = _label("", 32)
	resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(resource_label)
	pause_button = _button("PAUSE / HELP · Esc", func(): set_paused(true))
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.position = Vector2(-400, 24)
	pause_button.size = Vector2(376, 56)
	_root.add_child(pause_button)
	hint_label = _label("Movement / parkour preview. Encounters and skills come later.", 32)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_left = 24
	hint_label.offset_right = -24
	hint_label.offset_top = -58
	hint_label.offset_bottom = -14
	_root.add_child(hint_label)
	_build_pause()
	_refresh()


func _build_pause() -> void:
	pause_panel = Control.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(pause_panel)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.035, 0.055, 0.96)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 850
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)
	column.add_child(_label("EXPLORATION PAUSED", 40))
	var help := _label("Move: WASD / left stick · Look: hold RMB + drag / right stick\nJump: Space / A · Parkour: hold E / Y + LT\nHold jump to reel. Release parkour and jump to detach.\nMove closer beneath an anchor for lift; distant ropes pull you toward it.\nHooks are finite: reuse ropes or restart exploration.\nDash: Shift / B (Circle) · Strikes: J K M , · Sword: V / R3\nCombat skills, ultimates and enemy hooks are unavailable.\nBattle sites and portals are not active yet.", 30)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(help)
	resume_button = _button("RESUME", func(): set_paused(false))
	skip_button = _button("SKIP GUIDANCE · EXPLORE FREELY", _skip)
	restart_button = _button("RESTART EXPLORATION & GUIDANCE", _restart)
	exit_button = _button("RETURN TO MAIN MENU", _exit)
	var buttons: Array[Button] = [resume_button, skip_button, restart_button, exit_button]
	for button: Button in buttons:
		column.add_child(button)
	for i: int in buttons.size():
		buttons[i].focus_neighbor_top = buttons[i].get_path_to(buttons[posmod(i - 1, buttons.size())])
		buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(buttons[(i + 1) % buttons.size()])
		buttons[i].focus_previous = buttons[i].focus_neighbor_top
		buttons[i].focus_next = buttons[i].focus_neighbor_bottom
	pause_panel.hide()


func set_paused(value: bool) -> void:
	if paused_ui == value:
		return
	paused_ui = value
	if onboarding != null:
		onboarding.suspended = value
	if value:
		InputRouter.acquire_ui(self)
		get_tree().paused = true
		pause_panel.show()
		pause_button.disabled = true
		resume_button.grab_focus()
	else:
		pause_panel.hide()
		pause_button.disabled = false
		get_tree().paused = false
		InputRouter.release_ui(self)
		get_viewport().gui_release_focus()


func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("ui_pause") or event.is_action_pressed("ui_cancel"):
		if not paused_ui and InputRouter.ui_suppressed():
			return
		get_viewport().set_input_as_handled()
		set_paused(not paused_ui)


func _skip() -> void:
	if onboarding != null:
		onboarding.skip()
	set_paused(false)


func _restart() -> void:
	set_paused(false)
	restart_requested.emit()


func _exit() -> void:
	set_paused(false)
	exit_requested.emit()


func _refresh() -> void:
	if onboarding == null or objective_label == null:
		return
	_objective_title.text = onboarding.title()
	var prompts := {
		"move": "Walk along the street. WASD / left stick.",
		"look": "Look toward the upper route. Hold RMB + drag / right stick.",
		"jump": "Jump from the ground. Space / A.",
		"rope": "Hold E / Y + LT at a visible anchor. Move closer beneath it; hold jump to reel and lift.",
		"explore": "Cronshift is yours to explore. Battle sites come later.",
	}
	objective_label.text = String(prompts[onboarding.current_id()])
	if skip_button != null:
		skip_button.disabled = onboarding.is_complete()


func bind_player(player: Fighter) -> void:
	player.grapple_changed.connect(_on_rope)
	player.dash_changed.connect(_on_dash)
	_on_rope(player.grapple.charges, player.grapple.cooldown_left, player.grapple.max_charges)
	_on_dash(player.dash_charges_left, player.dash_recharge_left, player.data.dash_charges)


func _on_rope(charges: int, _cooldown: float, maximum: int) -> void:
	_rope_text = "HOOKS %d / %d" % [charges, maximum]
	if charges == 0:
		_rope_text += " · Reuse a hanging rope, or restart from pause."
	_refresh_resources()


func _on_dash(charges: int, cooldown: float, maximum: int) -> void:
	_dash_text = "DASH %d / %d" % [charges, maximum]
	if cooldown > 0.0:
		_dash_text += " · Rest %.1fs" % cooldown
	_refresh_resources()


func _refresh_resources() -> void:
	if resource_label != null:
		resource_label.text = _rope_text + "\n" + _dash_text


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86))
	return label


func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 56
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(callback)
	return button


func _exit_tree() -> void:
	if paused_ui:
		get_tree().paused = false
	InputRouter.release_ui(self)
	if onboarding != null:
		onboarding.suspended = false
