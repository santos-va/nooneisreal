extends Control
## District-first menu. Keyboard/gamepad navigation via focus; left/right cycles options.
## Visual direction for the real menu: docs/GDD/06-UI-UX.md.

var _buttons: Array[Button] = []
var _p1_btn: Button
var _p2_btn: Button
var stage_btn: Button   # STAGE / TIME rows (06-UI-UX § Арена й час доби в меню); the smoke presses them
var time_btn: Button
## Where STAGE/TIME are remembered; the smoke points it at a temp file so the player's settings.cfg is never written.
var settings_path: String = InputRouter.SETTINGS_PATH
var _keys_btn: Button
## Bottom hint follows the focus (06-UI-UX § Кнопка «РЕЖИМ», «підказка внизу меню», T8): FIGHT/TRAINING → solo vs
## CPU, VERSUS → two players; every other row keeps the last of the three. Starts on FIGHT.
var hint_vs_cpu: bool = true
var mode_btn: Button   # MODE 2.5D / 3D (docs/GDD/06-UI-UX.md § Кнопка «РЕЖИМ 2.5D / 3D»); the smoke presses it
var _comfort: ComfortPanel
var _comfort_button: Button
var city_button: Button
var _foot: Label
var _card1: TextureRect
var _card2: TextureRect
var _portrait1: TextureRect
var _portrait2: TextureRect
## Select-screen portraits (Textures-Registry ui-portrait-*; no CharacterSelect.tscn yet — [[2026-10-03-Character-Select]]
## В3 — so they sit next to the P1/P2 picker here until that screen exists).
const PORTRAITS := {"choko": "res://assets/ui/portraits/portrait_choko.png", "skea": "res://assets/ui/portraits/portrait_skea.png"}


func _ready() -> void:
	Music.play_menu()
	InputRouter.acquire_ui(self)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/menu/menu_skyline_plate_v1.png")
	# Imported with mipmaps (T6 brief 8K-Upscale-Candidates § Хендофи): 3840 px shrunk on 1080p screens stays clean.
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.055, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 64)
	frame.add_theme_constant_override("margin_right", 64)
	frame.add_theme_constant_override("margin_top", 32)
	frame.add_theme_constant_override("margin_bottom", 100)
	add_child(frame)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 16)
	frame.add_child(page)
	var heading := HBoxContainer.new()
	page.add_child(heading)
	var title := _text("NO ONE IS REAL", 54)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	_comfort_button = Button.new()
	_comfort_button.text = "COMFORT & CONTROLS"
	_comfort_button.add_theme_font_size_override("font_size", 24)
	_style_button(_comfort_button)
	heading.add_child(_comfort_button)
	page.add_child(_text("CRONSHIFT  /  THE FIRST DISTRICT", 22, Color("e5a875")))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(columns)
	var journey := _panel_column(columns)
	journey.add_child(_text("YOUR JOURNEY", 20, Color("7bc9c6")))
	journey.add_child(_text("A city worth getting lost in.", 32))
	var description := _text("Meet the residents. Find your way over the rooftops.\nTake on the district at your own pace.", 22)
	journey.add_child(description)
	var artwork := TextureRect.new()
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.custom_minimum_size = Vector2(0, 170)
	artwork.size_flags_vertical = Control.SIZE_EXPAND_FILL
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	journey.add_child(artwork)
	_card1 = artwork
	var p1_row := HBoxContainer.new()
	p1_row.add_theme_constant_override("separation", 12)
	journey.add_child(p1_row)
	_portrait1 = _portrait_rect()
	p1_row.add_child(_portrait1)
	_p1_btn = _add(p1_row, "", func(): GameState.cycle_character(1, 1); _refresh())
	_p1_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journey.add_child(_text("Choko + Skea  ·  2 playable heroes", 20, Color("aebfca")))
	city_button = _add(journey, "ENTER DISTRICT", _enter_city)
	city_button.custom_minimum_size.y = 58
	city_button.focus_entered.connect(_update_footer)
	city_button.focus_exited.connect(func(): _foot.text = compact_hint_text())
	city_button.add_theme_color_override("font_color", Color("ffe9c7"))
	_style_button(city_button, true)
	journey.add_child(_text("Your district progress is saved for each hero.", 20, Color("aebfca")))
	var arena := _panel_column(columns)
	arena.add_child(_text("THE ARENA", 20, Color("e5a875")))
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 8)
	arena.add_child(modes)
	var fight := _add(modes, "FIGHT", func(): GameState.p2_is_cpu = true; GameState.training_mode = false; _go())
	var versus := _add(modes, "VERSUS", func(): GameState.p2_is_cpu = false; GameState.training_mode = false; _go())
	var training := _add(modes, "TRAINING", func(): GameState.p2_is_cpu = true; GameState.training_mode = true; _go())
	fight.name = "FightButton"
	versus.name = "VersusButton"
	training.name = "TrainingButton"
	for button: Button in [fight, versus, training]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fight.focus_entered.connect(_set_hint.bind(true))
	training.focus_entered.connect(_set_hint.bind(true))
	versus.focus_entered.connect(_set_hint.bind(false))
	var p2_row := HBoxContainer.new()
	p2_row.add_theme_constant_override("separation", 12)
	arena.add_child(p2_row)
	_portrait2 = _portrait_rect()
	p2_row.add_child(_portrait2)
	_p2_btn = _add(p2_row, "", func(): GameState.cycle_character(2, 1); _refresh())
	_p2_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_btn = _add(arena, "", func(): step_stage(1))
	time_btn = _add(arena, "", func(): toggle_time())
	_keys_btn = _add(arena, "", func(): InputRouter.cycle_profile(); _refresh())
	mode_btn = _add(arena, "", toggle_mode)
	var spring := Control.new()
	spring.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_child(spring)
	_add(arena, "QUIT GAME", func(): get_tree().quit())
	for button: Button in [_p1_btn, _p2_btn, stage_btn, time_btn, _keys_btn, mode_btn]:
		button.gui_input.connect(_cycle_input.bind(button))
	_foot = _text("", 32, Color("d0d9da"))
	_foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_foot.offset_top = -84
	_foot.offset_bottom = -42
	add_child(_foot)
	var build := _text(BuildInfo.label(), 18, Color("99b0bc"))
	build.name = "BuildLabel"
	build.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	build.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	build.offset_top = -32
	build.offset_bottom = -8
	add_child(build)
	_comfort = ComfortPanel.new()
	add_child(_comfort)
	_comfort_button.pressed.connect(func(): _comfort.show_panel(_comfort_button, InputRouter.hint_text(hint_vs_cpu)))
	var focus_order: Array[Button] = [city_button, _p1_btn, fight, versus, training, _p2_btn, stage_btn, time_btn, _keys_btn, mode_btn, _buttons[-1], _comfort_button]
	for i: int in focus_order.size():
		var button := focus_order[i]
		button.focus_neighbor_top = button.get_path_to(focus_order[posmod(i - 1, focus_order.size())])
		button.focus_neighbor_bottom = button.get_path_to(focus_order[(i + 1) % focus_order.size()])
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom
	_refresh()
	city_button.grab_focus()


func _enter_city() -> void:
	Sfx.play("ui_confirm", -6)
	GameState.start_city()


func _text(value: String, font_size: int, color: Color = Color("f5eadb")) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _panel_column(parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.07, 0.09, 0.91)
	style.border_color = Color("40565e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	return column


func _style_button(button: Button, primary: bool = false) -> void:
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("285456") if primary else Color("152931")
		if state == "hover" or state == "pressed":
			style.bg_color = style.bg_color.lightened(0.15)
		style.border_color = Color("e5b178") if state == "focus" else Color("527478")
		style.set_border_width_all(3 if state == "focus" else 1)
		style.set_corner_radius_all(5)
		style.content_margin_left = 14
		style.content_margin_right = 14
		button.add_theme_stylebox_override(state, style)


func _add(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	_style_button(b)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	parent.add_child(b)
	_buttons.append(b)
	return b


func _cycle_input(event: InputEvent, b: Button) -> void:
	if not b.has_focus():
		return
	var dir := 0
	if event.is_action_pressed("ui_left"):
		dir = -1
	elif event.is_action_pressed("ui_right"):
		dir = 1
	if dir == 0:
		return
	if b == _p1_btn:
		GameState.cycle_character(1, dir)
	elif b == _p2_btn:
		GameState.cycle_character(2, dir)
	elif b == _keys_btn:
		InputRouter.cycle_profile()
	elif b == mode_btn:
		toggle_mode()
		return
	elif b == time_btn:
		toggle_time()
		return
	else:
		step_stage(dir)
		return
	Sfx.play("ui_move", -10)
	_refresh()
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	var c1 := GameState.load_character(GameState.p1_character)
	var c2 := GameState.load_character(GameState.p2_character)
	city_button.text = "CONTINUE DISTRICT" if CityProgress.has_saved_hero(GameState.p1_character) else "ENTER DISTRICT"
	# `‹ ›` (covered by the built-in font) instead of `◂ ▸` (rendered as an empty box).
	_p1_btn.text = "HERO:  ‹ %s ›" % (c1.display_name if c1 else GameState.p1_character)
	_p2_btn.text = "OPPONENT:  ‹ %s ›" % (c2.display_name if c2 else GameState.p2_character)
	stage_btn.text = "STAGE:  ‹ %s ›" % GameState.stage().get("label", GameState.stage().name)
	time_btn.text = "TIME:  ‹ %s ›" % ("NIGHT" if GameState.night else "DAY")
	var solo := InputRouter.profile == InputRouter.PROFILE_SOLO
	_keys_btn.text = "KEYBOARD:  ‹ %s ›" % ("SOLO" if solo else "SHARED")
	mode_btn.text = "MODE:  ‹ %s ›" % ("3D (free move)" if GameState.free_move else "2.5D (plane)")
	if _foot:
		_update_footer()
	if _card1:
		_set_portrait(_card1, c1)
		if _card2 != null:
			_card2.texture = _card_tex(c2)
	_set_portrait(_portrait1, c1)
	_set_portrait(_portrait2, c2)


func _set_hint(vs_cpu: bool) -> void:
	hint_vs_cpu = vs_cpu
	if _foot:
		_update_footer()


func _update_footer() -> void:
	if _foot != null:
		_foot.text = "District journey · Auto-save · Comfort & controls ›" if city_button.has_focus() else compact_hint_text()


## STAGE row: the next rotation arena, remembered in settings.cfg [gameplay] stage (id, not index).
func step_stage(dir: int) -> void:
	GameState.cycle_stage(dir)
	GameState.save_stage_time(settings_path)
	Sfx.play("ui_move", -10)
	_refresh()
	if is_inside_tree():
		get_viewport().set_input_as_handled()


## TIME row: day ↔ night, remembered in settings.cfg [gameplay] time_of_day.
func toggle_time() -> void:
	GameState.night = not GameState.night
	GameState.save_stage_time(settings_path)
	Sfx.play("ui_move", -10)
	_refresh()
	if is_inside_tree():
		get_viewport().set_input_as_handled()


## MODE row: 2.5D ↔ 3D, remembered in user://settings.cfg; the keyboard re-binds and the hint updates at once.
func toggle_mode() -> void:
	GameState.save_free_move(not GameState.free_move)
	Sfx.play("ui_move", -10)
	_refresh()
	get_viewport().set_input_as_handled()


func _card_rect(pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.size = Vector2(480, 272)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t


func _card_tex(c: CharacterData) -> Texture2D:
	if c != null and c.card_path != "" and ResourceLoader.exists(c.card_path):
		return load(c.card_path) as Texture2D
	return null


func _portrait_rect() -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.custom_minimum_size = Vector2(44, 44)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS   # 1024 px portrait drawn at 44 units
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _set_portrait(rect: TextureRect, c: CharacterData) -> void:
	if rect == null:
		return
	var p: String = PORTRAITS.get(c.id, "") if c != null else ""
	rect.texture = load(p) as Texture2D if p != "" and ResourceLoader.exists(p) else null


func _go() -> void:
	Sfx.play("ui_confirm", -6)
	GameState.start_match()


func compact_hint_text() -> String:
	return "%s · %s · %s · Comfort & controls ›" % ["P1 vs CPU" if hint_vs_cpu else "P1 vs P2", "3D" if GameState.free_move else "2.5D", "SOLO" if InputRouter.profile == InputRouter.PROFILE_SOLO else "SHARED"]


func _exit_tree() -> void:
	InputRouter.release_ui(self)
