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
var _graphics: Node
var quality_choice: OptionButton
var quality_help: Label
## 06-UI-UX § DISPLAY (T8): first row on desktops, absent on phones. Both modes keep the monitor's video mode.
var display_choice: OptionButton
var display_help: Label
const DISPLAY_LABELS: Array[String] = ["Fullscreen — whole screen, no borders", "Windowed — window with a frame"]
const QUALITY_LABELS: Array[String] = ["Auto — adapts to your screen", "Low — lighter rendering", "Medium — balanced", "High — full detail"]
const QUALITY_HELP := "Applies immediately. Text and controls stay sharp."
const AUTO_LINE_PERIOD := 1.0   # PLACEHOLDER (T8): the AUTO line refreshes at most once a second, only while open
var _auto_line_age: float = 0.0
## ADR-024 п. 7 (T8): blood in lethal fights and the hit flash, stored by ContentSettings. No new input actions.
var blood_choice: OptionButton
var hit_flash_choice: OptionButton
var _content: Node
var _content_save_error: int = OK   # like graphics: content.cfg is written only when a content choice changes
var _comfort_save_error: int = OK
const BLOOD_LABELS: Array[String] = ["Full — splashes and stains", "Muted — darker, shorter, no pools", "Ink — ink strokes instead of blood", "Off — only hit sparks"]
const HIT_FLASH_LABELS: Array[String] = ["Full", "Reduced — half as bright and short"]
## 06-UI-UX § «Випадки міста: COMFORT і HUD» п. 1 (T8, Д3): the city's five-leaves event and its state, stored by
## ContentSettings (`drugs`). Order as ContentSettings.DRUGS_MODES. Full is a PLACEHOLDER default (Р4, until ratings).
var drugs_choice: OptionButton
## T8 06-UI-UX § «Спрага…» п. 4 (variant Р2): the key, the node and the order stay; the words name alcohol and tobacco too.
const DRUGS_TITLE := "DRUGS, ALCOHOL & TOBACCO · CITY ONLY"
const DRUGS_LABELS: Array[String] = ["Full — may be offered or sold in the city", "Off — never offered or sold, no states"]
const DRUGS_HELP := "Off works at once, even mid-offer or mid-state, with no after-effect. Water and food stay. CAMERA SHAKE at 0 stops the haze zoom; the dark edges stay."
var _syncing := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_settings = get_node("/root/ComfortSettings")
	_graphics = get_node("/root/GraphicsSettings")
	_content = get_node("/root/ContentSettings")
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
	if bool(_graphics.call("display_switchable")):
		content.add_child(_label("DISPLAY", 32))
		display_choice = _choice("DisplayMode", DISPLAY_LABELS)
		content.add_child(display_choice)
		_focus_order.append(display_choice)
		display_choice.item_selected.connect(func(index: int):
			if not _syncing and _graphics.call("set_window_mode", _graphics.WINDOW_MODES[index]):
				_save())
		display_help = _label(display_hint(), 24)
		display_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(display_help)
		_graphics.connect("display_changed", _on_display_changed)
	content.add_child(_label("GRAPHICS QUALITY", 32))
	quality_choice = _choice("GraphicsQuality", QUALITY_LABELS)
	content.add_child(quality_choice)
	_focus_order.append(quality_choice)
	quality_choice.item_selected.connect(func(index: int):
		if not _syncing and _graphics.call("set_profile", _graphics.PROFILES[index]):
			_graphics.call("save_settings")
			_refresh_quality_help()
			_save())
	quality_help = _label(QUALITY_HELP, 24)
	quality_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(quality_help)
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
	# Between CAMERA SHAKE and RESTORE: the established MASTER ↔ GRAPHICS and RESTORE → help steps stay as they were.
	# T8 Д3: two groups — sensation (HIT FLASH right after CAMERA SHAKE), then content (BLOOD, DRUGS side by side).
	content.add_child(_label("HIT FLASH", 32))
	hit_flash_choice = _choice("HitFlash", HIT_FLASH_LABELS)
	content.add_child(hit_flash_choice)
	_focus_order.append(hit_flash_choice)
	hit_flash_choice.item_selected.connect(func(index: int):
		if not _syncing and _content.call("set_hit_flash", _content.HIT_FLASH_MODES[index]):
			_content_save_error = _content.call("save_settings")
			_save())
	content.add_child(_label("BLOOD · LETHAL FIGHTS ONLY", 32))
	blood_choice = _choice("BloodMode", BLOOD_LABELS)
	content.add_child(blood_choice)
	_focus_order.append(blood_choice)
	blood_choice.item_selected.connect(func(index: int):
		if not _syncing and _content.call("set_blood_mode", _content.BLOOD_MODES[index]):
			_content_save_error = _content.call("save_settings")
			_save())
	var blood_help := _label("Sparring between Choko and Skea never shows blood.", 24)
	blood_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(blood_help)
	# Applies at once (the city's director drops the offer and the state on Off); RESTORE never resets it.
	content.add_child(_label(DRUGS_TITLE, 32))
	drugs_choice = _choice("DrugsMode", DRUGS_LABELS)
	content.add_child(drugs_choice)
	_focus_order.append(drugs_choice)
	drugs_choice.item_selected.connect(func(index: int):
		if not _syncing and _content.call("set_drugs_mode", _content.DRUGS_MODES[index]):
			_content_save_error = _content.call("save_settings")
			_save())
	var drugs_help := _label(DRUGS_HELP, 24)
	drugs_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(drugs_help)
	restore_button = _button("RESTORE SOUND & SHAKE DEFAULTS", func():
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
	controls_label.text += "\n\nHARPOON\nEnemy hook pulls on contact; parkour hook attaches to anchors.\nParkour is latched: tap to attach, follow the highlighted anchor and tap again to transfer.\nHold jump to reel in; move sideways to steer.\nGet closer beneath an anchor for lift; distant ropes pull toward it.\nDetach: Z / B, or dodge. Enemy grapple still uses hold / release.\nA rope cue means grab the deployed rope; no new hook is spent.\n\nChoko carries 7 hooks; Skea carries 2. Returning a hook restores its slot; there is no timer refill.\nDeployed parkour ropes remain in the match and either fighter can reuse them.\nMisses rewind automatically. During recovery, hands are busy; use light movement and kicks.\nAfter hooking an enemy, extraction returns the hook. A kick helps extract it during the strike.\n".replace("Detach: Z", "Detach: " + InputRouter.binding_label(1, "grapple_detach", false))
	controls_label.text += "\nAIM (solo)\nVisible parkour anchors are suggested along your movement; precise center aiming is optional.\nHold the right mouse button and drag, or use the right stick, to choose with the camera.\nCity orbit stays in place; the duel view returns smoothly. The cue suggests a target; the hook must still reach it.\n"
	controls_label.text += "\nCHOKO SWORD\nWeapon swap first draws the sword from the back; later swaps reform it in the other hand.\nUse it while standing or walking.\nThe armed hand cuts; the free hand punches. A kick or dash interrupts the transfer.\n"
	controls_label.text += _gamepad_help()
	if display_choice != null:
		controls_label.text += "\n\nWINDOW\n" + display_hint().replace(" · ", "\n") + "\nGamepad: the DISPLAY line above."
	# The green macOS button or OS keys may have changed the window while the panel was closed.
	_graphics.call("sync_from_window")
	_sync_values()
	_status.text = _status_text()
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
	for choice: OptionButton in _choices():
		choice.get_popup().hide()
	hide()
	InputRouter.release_ui(self)
	if is_instance_valid(_invoker) and _invoker.is_visible_in_tree():
		_invoker.grab_focus()
	closed.emit()

func _sync_values() -> void:
	_syncing = true
	if display_choice != null:
		display_choice.select(_graphics.WINDOW_MODES.find(_graphics.call("get_window_mode")))
	quality_choice.select(_graphics.PROFILES.find(_graphics.call("get_profile")))
	_refresh_quality_help()
	blood_choice.select(_content.BLOOD_MODES.find(_content.call("blood_mode")))
	hit_flash_choice.select(_content.HIT_FLASH_MODES.find(_content.call("hit_flash")))
	drugs_choice.select(_content.DRUGS_MODES.find(_content.call("drugs_mode")))
	for key: String in sliders:
		(sliders[key] as HSlider).value = float(_settings.call("get_value", key)) * 100
	_syncing = false

func _save() -> void:
	if _status == null:
		return
	_comfort_save_error = _settings.call("save_settings")
	_status.text = _status_text()


## The graphics owner remembers its last failed write, including one made by the fullscreen key while closed.
func _status_text() -> String:
	var graphics_error: int = _graphics.get("save_error")
	return "Could not save preferences; changes apply for this session." if _comfort_save_error != OK or graphics_error != OK or _content_save_error != OK else ""


func _choices() -> Array[OptionButton]:
	var result: Array[OptionButton] = []
	for choice: OptionButton in [display_choice, quality_choice, hit_flash_choice, blood_choice, drugs_choice]:
		if choice != null:
			result.append(choice)
	return result


## T8 hint under DISPLAY: the macOS line names the Mac keys; F11 is not promised there.
static func display_hint() -> String:
	if OS.get_name() == "macOS":
		return "Ctrl+Cmd+F in menus and pause · or the green window button"
	return "F11 anytime · Alt+Enter in menus and pause"


func _on_display_changed(_mode: String) -> void:
	if display_choice == null:
		return
	_syncing = true
	display_choice.select(_graphics.WINDOW_MODES.find(_graphics.call("get_window_mode")))
	_syncing = false
	_refresh_quality_help()
	if visible:
		_status.text = _status_text()


func _refresh_quality_help() -> void:
	_auto_line_age = 0.0
	if quality_help != null:
		quality_help.text = _graphics.call("auto_summary") if _graphics.call("get_profile") == "auto" else QUALITY_HELP


func _process(delta: float) -> void:
	if not visible or _graphics.call("get_profile") != "auto":
		return
	_auto_line_age += delta
	if _auto_line_age >= AUTO_LINE_PERIOD:
		_refresh_quality_help()

func _keep_focus(control: Control) -> void:
	if visible and control != null and not is_ancestor_of(control):
		back_button.grab_focus.call_deferred()

func _input(event: InputEvent) -> void:
	for choice: OptionButton in _choices():
		if choice.get_popup().visible:
			return
	if visible and not event.is_echo() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause")):
		get_viewport().set_input_as_handled()
		close_panel()

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86))
	return label

func _choice(node_name: String, labels: Array[String]) -> OptionButton:
	var choice := OptionButton.new()
	choice.name = node_name
	choice.custom_minimum_size.y = 48
	choice.add_theme_font_size_override("font_size", 32)
	choice.get_popup().add_theme_font_size_override("font_size", 32)
	for label: String in labels:
		choice.add_item(label)
	return choice

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
