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
var _status_card: PanelContainer
var _objective_title: Label
var _root: Control
var _rope_text: String = ""
var _dash_text: String = ""
var _player: Fighter
var _aim_cue: Label
var _stamina_bar: ProgressBar
var _stamina_text: String = ""


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
	_status_card = card
	card.position = Vector2(18, 18)
	card.custom_minimum_size.x = 390
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)

	_objective_title = _label("CRONSHIFT", 18)
	column.add_child(_objective_title)
	objective_label = _label("", 20)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.x = 380
	column.add_child(objective_label)
	resource_label = _label("", 18)
	resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(resource_label)
	_stamina_bar = ProgressBar.new()
	_stamina_bar.max_value = 1.0
	_stamina_bar.show_percentage = false
	_stamina_bar.custom_minimum_size.y = 5
	_stamina_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_stamina_bar)
	_aim_cue = _label("", 20)
	_aim_cue.add_theme_color_override("font_outline_color", Color("171322"))
	_aim_cue.add_theme_constant_override("outline_size", 6)
	_aim_cue.hide()
	_root.add_child(_aim_cue)
	pause_button = _button("Esc · Help", func(): set_paused(true))
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.add_theme_font_size_override("font_size", 20)
	pause_button.custom_minimum_size.y = 34
	pause_button.position = Vector2(-158, 18)
	pause_button.size = Vector2(140, 34)
	_root.add_child(pause_button)
	hint_label = _label("", 18)
	hint_label.hide()
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
	var help := _label(exploration_help(), 28)
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


func exploration_help() -> String:
	var text := "Move: WASD / left stick · Look: RMB + drag / right stick\n"
	text += "Jump / reel: %s / A · Parkour: tap %s / L3 (or Y + LT)\n" % [InputRouter.binding_label(1, "jump", false), InputRouter.binding_label(1, "grapple_parkour", false)]
	text += "Aim at the next lamp and tap parkour to transfer.\n"
	text += "Detach: %s / B · Dodge: %s / X · Dash skill: %s / Y + X\n" % [InputRouter.binding_label(1, "grapple_detach", false), InputRouter.binding_label(1, "dodge", false), InputRouter.binding_label(1, "dash", false)]
	text += "Hooks are finite. GRAB ROPE reuses a line; PREPARE GRAB reaches for it.\n"
	text += "Strikes: %s; %s; %s; %s\n" % [InputRouter.binding_label(1, "left_hand", false), InputRouter.binding_label(1, "right_hand", false), InputRouter.binding_label(1, "left_leg", false), InputRouter.binding_label(1, "right_leg", false)]
	text += "Sword: %s / R3 · Talk: %s / Y + D-pad Down\n" % [InputRouter.binding_label(1, "weapon_swap", false), InputRouter.binding_label(1, "interact", false)]
	return text + "Battle sites, combat skills, ultimates and enemy hooks are not active yet."


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
	if event.is_action_pressed("ui_pause") or (paused_ui and event.is_action_pressed("ui_cancel")):
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
	_objective_title.text = "CRONSHIFT"
	var prompts := {
		"move": "Walk · WASD / left stick",
		"look": "Look up · RMB + drag / right stick",
		"jump": "Jump · %s / A" % InputRouter.binding_label(1, "jump", false),
		"rope": "Aim at a lamp · %s / L3 to hook" % InputRouter.binding_label(1, "grapple_parkour", false),
		"explore": "",
	}
	objective_label.text = String(prompts[onboarding.current_id()])
	objective_label.visible = not onboarding.is_complete()
	if skip_button != null:
		skip_button.disabled = onboarding.is_complete()


func bind_player(player: Fighter) -> void:
	_player = player
	player.dodge_stamina_changed.connect(_on_stamina)
	_on_stamina(player.dodge_stamina, player.dodge_stamina_max())
	player.grapple_changed.connect(_on_rope)
	player.dash_changed.connect(_on_dash)
	_on_rope(player.grapple.charges, player.grapple.cooldown_left, player.grapple.max_charges)
	_on_dash(player.dash_charges_left, player.dash_recharge_left, player.data.dash_charges)


func _on_rope(charges: int, _cooldown: float, maximum: int) -> void:
	_rope_text = "HOOKS %d / %d" % [charges, maximum]
	if charges == 0:
		_rope_text += " · Reuse rope"
	_refresh_resources()


func _on_dash(charges: int, cooldown: float, maximum: int) -> void:
	_dash_text = "DASH %d / %d" % [charges, maximum]
	if cooldown > 0.0:
		_dash_text += " · %.1fs" % cooldown
	_refresh_resources()


func _refresh_resources() -> void:
	if resource_label != null:
		resource_label.text = _rope_text + " · " + _stamina_text + "\n" + _dash_text


func _on_stamina(value: float, maximum: float) -> void:
	_stamina_text = "STAMINA %d%%" % roundi(value / maxf(maximum, 0.001) * 100.0)
	if _stamina_bar != null:
		_stamina_bar.value = value / maxf(maximum, 0.001)
	_refresh_resources()


func _process(_delta: float) -> void:
	if _aim_cue == null:
		return
	_aim_cue.hide()
	if not is_instance_valid(_player) or paused_ui or InputRouter.ui_suppressed():
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null or not camera.has_meta("harpoon_aim"):
		return
	var helper: HarpoonAim = camera.get_meta("harpoon_aim")
	var intent := helper.capture(_player, false, false)
	var point: Vector3 = intent.point
	if camera.is_position_behind(point) or (intent.target_id.is_empty() and not intent.manual):
		return
	var screen := camera.unproject_position(point)
	if not get_viewport().get_visible_rect().has_point(screen):
		return
	var kind: String = intent.get("candidate_kind", "")
	var verb := "GRAB ROPE" if kind == "rope" else ("TRANSFER" if _player.grapple.busy() else "HOOK")
	if kind == "rope" and not intent.get("reachable", true):
		verb = "PREPARE GRAB"
	_aim_cue.text = "◇ %s · %s · %.1fm" % [InputRouter.binding_label(_player.player_index, "grapple_parkour", helper.last_gamepad), verb, _player.global_position.distance_to(point)]
	_aim_cue.position = _root.get_global_transform_with_canvas().affine_inverse() * screen + Vector2(-18, -32)
	var bounds := get_viewport().get_visible_rect().size
	var extent := _aim_cue.get_minimum_size()
	_aim_cue.position.x = clampf(_aim_cue.position.x, 12.0, maxf(12.0, bounds.x - extent.x - 12.0))
	_aim_cue.position.y = clampf(_aim_cue.position.y, 12.0, maxf(12.0, bounds.y - extent.y - 80.0))
	if _status_card.get_rect().intersects(Rect2(_aim_cue.position, extent)):
		_aim_cue.position.y = _status_card.get_rect().end.y + 8.0
	_aim_cue.show()


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
