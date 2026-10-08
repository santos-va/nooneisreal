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
## The close button's words. A menu whose Esc / B means something else names it (the alley trap: «Тікати · Esc / B»).
const CLOSE_LABEL := "Завершити розмову · Esc / B"
## T8 06-UI-UX § «Випадки міста: COMFORT і HUD» п. 3, GAP 2: a menu that opened without the player's press (the world
## opened it) takes no ui_accept / ui_cancel for `guard_seconds` and until a button held at that moment is let go, so a
## jump (Space / A are also ui_accept) never picks an option. Up / down work at once; nothing blinks. PLACEHOLDER 0.35 s
## (T8; a source is T3's).
var guard_seconds: float = 0.35
var _guard_left: float = 0.0
var _guard_hold: bool = false
## Item icons in a counter row (plan 2026-10-08-Thirst-Substances-Icons step 3; T8 06-UI-UX § «Спрага…» п. 5): a choice
## may name `icon` (a slug of game/assets/ui/icons/items/icon_item_<slug>.png). In a list where at least one row has an
## icon, every button carries one 32 × 32 logical px left of its text (`icon_max_width` 32, `expand_icon` off, 10 px gap,
## the text aligned left); a row without an item icon gets a transparent one of the same size, so all the text starts in
## one column — never a «?» placeholder. The wrap width loses the icon's 42 px. Mipmapped filtering: a 512 px picture
## shown 20× smaller does not shimmer.
const ITEM_ICON_PATH := "res://assets/ui/icons/items/icon_item_%s.png"
const ICON_SIZE := 32
const ICON_GAP := 10
var icon_list: bool = false
static var _blank_icon: ImageTexture

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

func show_choices(text: String, choices: Array[Dictionary], close_label: String = CLOSE_LABEL, guard: bool = false) -> void:
	_guard_left = guard_seconds if guard else 0.0
	_guard_hold = guard
	body.text = text
	flavor.text = ""
	for old: Node in choices_box.get_children():
		choices_box.remove_child(old)
		old.queue_free()
	icon_list = false
	for choice: Dictionary in choices:
		if not String(choice.get("icon", "")).is_empty():
			icon_list = true
	var first: Button
	for choice: Dictionary in choices:
		var button := Button.new()
		button.set_meta("full_text", str(choice.label))
		button.set_meta("id", str(choice.id))
		button.text = str(choice.label)
		button.clip_text = true
		button.custom_minimum_size.y = 43
		button.disabled = not bool(choice.get("enabled", true))
		button.pressed.connect(func() -> void: choice_selected.emit(str(choice.id)))
		_dress_icon(button, String(choice.get("icon", "")))
		choices_box.add_child(button)
		if first == null and not button.disabled:
			first = button
	var close_button := Button.new()
	close_button.text = close_label
	close_button.set_meta("full_text", close_button.text)
	close_button.set_meta("close", true)
	close_button.clip_text = true
	close_button.custom_minimum_size.y = 43
	close_button.pressed.connect(close)
	_dress_icon(close_button, "")
	choices_box.add_child(close_button)
	_layout_panel()
	opened = true
	panel.show()
	prompt.hide()
	InputRouter.acquire_ui(self)
	(first if first != null else close_button).grab_focus()

## The item icon (or the transparent stand-in) left of the text, only in a list that has icons.
func _dress_icon(button: Button, slug: String) -> void:
	if not icon_list:
		return
	var path: String = ITEM_ICON_PATH % slug
	var texture: Texture2D = load(path) as Texture2D if not slug.is_empty() and ResourceLoader.exists(path) else null
	button.icon = texture if texture != null else blank_icon()
	button.set_meta("item_icon", slug if texture != null else "")
	button.expand_icon = false
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("icon_max_width", ICON_SIZE)
	button.add_theme_constant_override("h_separation", ICON_GAP)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


static func blank_icon() -> ImageTexture:
	if _blank_icon == null:
		_blank_icon = ImageTexture.create_from_image(Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8))
	return _blank_icon


func show_fact(text: String, guard: bool = false) -> void:
	show_choices(text, [], CLOSE_LABEL, guard)

## True while a world-opened menu still refuses accept / cancel (see guard_seconds).
func guarding() -> bool:
	return opened and (_guard_left > 0.0 or _guard_hold)

func close() -> void:
	opened = false
	_guard_left = 0.0
	_guard_hold = false
	panel.hide()
	InputRouter.release_ui(self)
	closed.emit()

func _input(event: InputEvent) -> void:
	# Before the GUI: a guarded menu never lets an accept / cancel (press or release) reach its buttons.
	if guarding() and (event.is_action("ui_accept") or event.is_action("ui_cancel")):
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if opened and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	InputRouter.release_ui(self)

func _process(delta: float) -> void:
	if _guard_left > 0.0:
		_guard_left = maxf(0.0, _guard_left - delta)
	if _guard_left <= 0.0 and _guard_hold and not (Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_cancel")):
		_guard_hold = false
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
				if not line.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > panel_width - 76.0 - (float(ICON_SIZE + ICON_GAP) if icon_list else 0.0):
					lines.append(line)
					line = word
				else:
					line = candidate
			lines.append(line)
			child.text = "\n".join(lines)
			child.custom_minimum_size.y = maxf(43.0, font.get_height(font_size) * lines.size() + 18.0)
