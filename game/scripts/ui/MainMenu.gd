extends Control
## Main menu (prototype, code-built). Keyboard/gamepad navigation via focus; left/right cycles options.
## Visual direction for the real menu: docs/GDD/06-UI-UX.md.

var _buttons: Array[Button] = []
var _p1_btn: Button
var _p2_btn: Button
var _stage_btn: Button
var _card1: TextureRect
var _card2: TextureRect


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
	_add(center, "FIGHT  ·  P1 vs CPU", func(): GameState.p2_is_cpu = true; GameState.training_mode = false; _go())
	_add(center, "VERSUS  ·  P1 vs P2 (one keyboard)", func(): GameState.p2_is_cpu = false; GameState.training_mode = false; _go())
	_add(center, "TRAINING", func(): GameState.p2_is_cpu = true; GameState.training_mode = true; _go())
	_p1_btn = _add(center, "", func(): GameState.cycle_character(1, 1); _refresh())
	_p2_btn = _add(center, "", func(): GameState.cycle_character(2, 1); _refresh())
	_stage_btn = _add(center, "", func(): GameState.cycle_stage(1); _refresh())
	_add(center, "QUIT", func(): get_tree().quit())
	for b in [_p1_btn, _p2_btn, _stage_btn]:
		b.gui_input.connect(_cycle_input.bind(b))
	_card1 = _card_rect(Vector2(24, 470))
	_card2 = _card_rect(Vector2(-504, 470))
	_card2.anchor_left = 1.0
	_card2.anchor_right = 1.0
	_refresh()
	_buttons[0].grab_focus()
	var foot := Label.new()
	foot.text = "P1: WASD · F/G attacks · LShift guard · Q/E skills · R grapple · C dash · V ultimate      P2: arrows · K/L · RShift · ; ' · I · . · ,"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 15)
	foot.add_theme_color_override("font_color", Color(0.75, 0.72, 0.7))
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.anchor_top = 1.0
	foot.offset_top = -40
	add_child(foot)


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
	else:
		GameState.cycle_stage(dir)
	Sfx.play("ui_move", -10)
	_refresh()
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	var c1 := GameState.load_character(GameState.p1_character)
	var c2 := GameState.load_character(GameState.p2_character)
	_p1_btn.text = "P1:  ◂ %s ▸" % (c1.display_name if c1 else GameState.p1_character)
	_p2_btn.text = "P2:  ◂ %s ▸" % (c2.display_name if c2 else GameState.p2_character)
	_stage_btn.text = "STAGE:  ◂ %s ▸" % GameState.stage().name
	if _card1:
		_card1.texture = _card_tex(c1)
		_card2.texture = _card_tex(c2)


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


func _go() -> void:
	Sfx.play("ui_confirm", -6)
	GameState.start_match()
