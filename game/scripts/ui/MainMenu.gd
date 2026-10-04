extends Control
## Main menu (prototype, code-built). Keyboard/gamepad navigation via focus; left/right cycles options.
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
var _foot: Label
var _card1: TextureRect
var _card2: TextureRect
var _portrait1: TextureRect
var _portrait2: TextureRect
## Select-screen portraits (Textures-Registry ui-portrait-*; no CharacterSelect.tscn yet — [[2026-10-03-Character-Select]]
## В3 — so they sit next to the P1/P2 picker here until that screen exists).
const PORTRAITS := {"choko": "res://assets/ui/portraits/portrait_choko.png", "skea": "res://assets/ui/portraits/portrait_skea.png"}


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# slanted accent band (Kronshift terracotta)
	var band := ColorRect.new()
	band.color = Color(0.78, 0.4, 0.24, 0.9)
	band.size = Vector2(2600, 170)
	band.position = Vector2(-300, 190)
	band.rotation = -0.09
	add_child(band)
	var band2 := ColorRect.new()
	band2.color = Color(0.12, 0.3, 0.36, 0.9)
	band2.size = Vector2(2600, 40)
	band2.position = Vector2(-300, 380)
	band2.rotation = -0.09
	add_child(band2)
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	center.add_theme_constant_override("separation", 10)
	add_child(center)
	var title := Label.new()
	title.text = "NO ONE IS REAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.98, 0.93, 0.85))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.08))
	title.add_theme_constant_override("outline_size", 10)
	center.add_child(title)
	var sub := Label.new()
	sub.text = "KRONSHIFT ARENA  ·  prototype 0.1"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.9, 0.8, 0.65))
	center.add_child(sub)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	center.add_child(spacer)
	var fight := _add(center, "FIGHT  ·  P1 vs CPU", func(): GameState.p2_is_cpu = true; GameState.training_mode = false; _go())
	var versus := _add(center, "VERSUS  ·  P1 vs P2", func(): GameState.p2_is_cpu = false; GameState.training_mode = false; _go())
	var training := _add(center, "TRAINING", func(): GameState.p2_is_cpu = true; GameState.training_mode = true; _go())
	fight.focus_entered.connect(_set_hint.bind(true))
	training.focus_entered.connect(_set_hint.bind(true))
	versus.focus_entered.connect(_set_hint.bind(false))
	var p1_row := HBoxContainer.new()
	p1_row.add_theme_constant_override("separation", 10)
	p1_row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(p1_row)
	_portrait1 = _portrait_rect()
	p1_row.add_child(_portrait1)
	_p1_btn = _add(p1_row, "", func(): GameState.cycle_character(1, 1); _refresh())
	var p2_row := HBoxContainer.new()
	p2_row.add_theme_constant_override("separation", 10)
	p2_row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(p2_row)
	_p2_btn = _add(p2_row, "", func(): GameState.cycle_character(2, 1); _refresh())
	_portrait2 = _portrait_rect()
	p2_row.add_child(_portrait2)
	stage_btn = _add(center, "", func(): step_stage(1))
	time_btn = _add(center, "", func(): toggle_time())
	_keys_btn = _add(center, "", func(): InputRouter.cycle_profile(); _refresh())
	mode_btn = _add(center, "", toggle_mode)
	_add(center, "QUIT", func(): get_tree().quit())
	for b in [_p1_btn, _p2_btn, stage_btn, time_btn, _keys_btn, mode_btn]:
		b.gui_input.connect(_cycle_input.bind(b))
	_card1 = _card_rect(Vector2(24, 470))
	_card2 = _card_rect(Vector2(-504, 470))
	_card2.anchor_left = 1.0
	_card2.anchor_right = 1.0
	var foot := Label.new()
	_foot = foot
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 15)
	foot.add_theme_color_override("font_color", Color(0.75, 0.72, 0.7))
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.anchor_top = 1.0
	foot.offset_top = -40
	add_child(foot)
	_refresh()
	_buttons[0].grab_focus()


func _add(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(460, 48)
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
	_p1_btn.text = "P1:  ◂ %s ▸" % (c1.display_name if c1 else GameState.p1_character)
	_p2_btn.text = "P2:  ◂ %s ▸" % (c2.display_name if c2 else GameState.p2_character)
	stage_btn.text = "STAGE:  ◂ %s ▸" % GameState.stage().get("label", GameState.stage().name)
	time_btn.text = "TIME:  ◂ %s ▸" % ("NIGHT" if GameState.night else "DAY")
	var solo := InputRouter.profile == InputRouter.PROFILE_SOLO
	_keys_btn.text = "KEYBOARD:  ◂ %s ▸" % ("SOLO (P2 on gamepad)" if solo else "SHARED (two on one keyboard)")
	mode_btn.text = "MODE:  ◂ %s ▸" % ("3D (free move)" if GameState.free_move else "2.5D (plane)")
	if _foot:
		_foot.text = InputRouter.hint_text(hint_vs_cpu)
	if _card1:
		_card1.texture = _card_tex(c1)
		_card2.texture = _card_tex(c2)
	_set_portrait(_portrait1, c1)
	_set_portrait(_portrait2, c2)


func _set_hint(vs_cpu: bool) -> void:
	hint_vs_cpu = vs_cpu
	if _foot:
		_foot.text = InputRouter.hint_text(hint_vs_cpu)


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
