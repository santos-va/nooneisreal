class_name LethalHud
extends CanvasLayer
## HUD H2 of a lethal pocket fight (ADR-024; plan 2026-10-07-First-Enemy-Lethal-Fight step 4, T8): one static top band
## (hero health, the fight's frame line, enemy health), the hero's meter and skill cooldowns as in the duel, the round
## announcer and the defeat card. CityHud stays the only pause owner; this layer sits under its pause panel.
## Blood colours and the content card are the next step: nothing here is red.
signal retry_requested
signal return_requested

const INK := Color("#2B2230")
const CREAM := Color("#FAEDD9")
const WELL := Color("#141018")
const HERO_FILL := Color(0.95, 0.88, 0.35)   # the duel's P1 health colour (Hud.gd)
const TRAIL := Color(0.95, 0.75, 0.6, 0.9)
const ROUND_WON := Color(1.0, 0.85, 0.4)

var hero: Fighter
var enemy: Fighter
var flow: MatchFlow
var round_label: Label
var announce_label: Label
var hero_name: Label
var enemy_name: Label
var hero_bar: ProgressBar
var enemy_bar: ProgressBar
var resources_label: Label
var defeat_card: PanelContainer
var defeat_title: Label
var retry_button: Button
var return_button: Button
var _trail: Dictionary = {}
var _pips: Dictionary = {}
var _announce_left: float = 0.0
var _root: Control
## The city's hunger word on the hero's line (T8 06-UI-UX § Шкала голоду → Кишеня; PLACEHOLDER words), set by
## CityLethalFight from CityHunger.pocket_status(). Empty in a sated pocket; there is no bar.
var status_suffix: String = ""


func bind(a: Fighter, b: Fighter, f: MatchFlow) -> void:
	hero = a
	enemy = b
	flow = f
	_build()
	hero.hp_changed.connect(func(hp: float, mx: float) -> void: _on_hp(hero_bar, hp, mx))
	enemy.hp_changed.connect(func(hp: float, mx: float) -> void: _on_hp(enemy_bar, hp, mx))
	hero.meter_changed.connect(func(_m: float, _mx: float) -> void: _refresh_resources())
	hero.cooldowns_changed.connect(func(_cd: Dictionary) -> void: _refresh_resources())
	flow.announce.connect(_on_announce)
	flow.round_started.connect(_on_round_started)
	flow.round_won.connect(_on_round_won)
	flow.match_over.connect(_on_match_over)
	_on_hp(hero_bar, hero.hp, hero.data.max_hp)
	_on_hp(enemy_bar, enemy.hp, enemy.data.max_hp)
	_refresh_resources()
	round_label.text = flow.round_title()


func _build() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 19
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	# Under CityHud's "Esc · Help" button (top-right, 56 px tall from y 18, one layer above): the band stays readable.
	margin.add_theme_constant_override("margin_top", 86)
	_root.add_child(margin)
	var band := HBoxContainer.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_theme_constant_override("separation", 18)
	margin.add_child(band)
	band.add_child(_side(hero, false))
	var center := VBoxContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.custom_minimum_size.x = 220
	round_label = _label("", 20, HORIZONTAL_ALIGNMENT_CENTER)
	round_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	center.add_child(round_label)
	band.add_child(center)
	band.add_child(_side(enemy, true))
	announce_label = _label("", 64, HORIZONTAL_ALIGNMENT_CENTER)
	announce_label.anchor_left = 0.5
	announce_label.anchor_right = 0.5
	announce_label.anchor_top = 0.42
	announce_label.anchor_bottom = 0.42
	announce_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	announce_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.5))
	announce_label.add_theme_constant_override("outline_size", 12)
	announce_label.hide()
	_root.add_child(announce_label)
	defeat_card = PanelContainer.new()
	defeat_card.set_anchors_preset(Control.PRESET_CENTER)
	defeat_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	defeat_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.11, 0.92)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(28)
	style.border_color = CREAM
	style.set_border_width_all(2)
	defeat_card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	defeat_card.add_child(column)
	defeat_title = _label("DEFEATED", 50, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(defeat_title)
	retry_button = _button("RETRY FIGHT", func() -> void: retry_requested.emit())
	column.add_child(retry_button)
	return_button = _button("RETURN TO SAFE POINT", func() -> void: return_requested.emit())
	column.add_child(return_button)
	retry_button.focus_neighbor_bottom = retry_button.get_path_to(return_button)
	return_button.focus_neighbor_top = return_button.get_path_to(retry_button)
	defeat_card.hide()
	_root.add_child(defeat_card)


func _side(f: Fighter, mirrored: bool) -> Control:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _label(f.data.display_name, 26, HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", f.data.primary_color.lightened(0.45))
	var pips := HBoxContainer.new()
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pips.add_theme_constant_override("separation", 6)
	_pips[f] = []
	for i: int in GameState.rounds_to_win:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.color = WELL
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(pip)
		(_pips[f] as Array).append(pip)
	if mirrored:
		row.add_child(pips)
		row.add_child(title)
	else:
		row.add_child(title)
		row.add_child(pips)
	box.add_child(row)
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(0, 20)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var trail := _bar(TRAIL, WELL, mirrored)
	var live := _bar(HERO_FILL if not mirrored else f.data.accent_color.lightened(0.35), Color(0, 0, 0, 0), mirrored)
	for bar: ProgressBar in [trail, live]:
		bar.set_anchors_preset(Control.PRESET_FULL_RECT)
		stack.add_child(bar)
	box.add_child(stack)
	_trail[live] = trail
	if mirrored:
		enemy_name = title
		enemy_bar = live
	else:
		hero_name = title
		hero_bar = live
		resources_label = _label("", 16, HORIZONTAL_ALIGNMENT_LEFT)
		box.add_child(resources_label)
	return box


func _bar(fill: Color, background: Color, mirrored: bool) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = 1.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN if mirrored else ProgressBar.FILL_BEGIN_TO_END
	var back := StyleBoxFlat.new()
	back.bg_color = background
	back.border_color = INK
	back.set_border_width_all(2 if background.a > 0.0 else 0)
	var front := StyleBoxFlat.new()
	front.bg_color = fill
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", front)
	return bar


func _label(text: String, size: int, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.07))
	label.add_theme_constant_override("outline_size", 4 if size <= 26 else 8)
	return label


func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 48)
	button.add_theme_font_size_override("font_size", 30)
	button.pressed.connect(callback)
	return button


## The pocket opened with the city's hp (CityLethalFight entry_hp): the trails start where the bars are, not at full.
func snap_trails() -> void:
	for live: ProgressBar in _trail:
		(_trail[live] as ProgressBar).value = live.value


func _on_hp(bar: ProgressBar, hp: float, max_hp: float) -> void:
	bar.value = clampf(hp / maxf(max_hp, 0.001), 0.0, 1.0)


func _refresh_resources() -> void:
	if resources_label == null or hero == null:
		return
	var s1: float = hero.cooldowns.get("skill1", 0.0)
	var s2: float = hero.cooldowns.get("skill2", 0.0)
	resources_label.text = "METER %d%% · S1 %s · S2 %s" % [roundi(hero.meter / Fighter.MAX_METER * 100.0), "✓" if s1 <= 0.0 else "%.1f" % s1, "✓" if s2 <= 0.0 else "%.1f" % s2]
	if not status_suffix.is_empty():
		resources_label.text += " · " + status_suffix


func _on_announce(text: String, seconds: float) -> void:
	announce_label.text = text
	announce_label.show()
	_announce_left = seconds


func _on_round_started(_round_no: int) -> void:
	round_label.text = flow.round_title()
	hide_defeat()
	_on_round_won(0, flow.wins[1], flow.wins[2])


func _on_round_won(_player: int, wins_hero: int, wins_enemy: int) -> void:
	for pair: Array in [[hero, wins_hero], [enemy, wins_enemy]]:
		var pips: Array = _pips.get(pair[0], [])
		for i: int in pips.size():
			(pips[i] as ColorRect).color = ROUND_WON if i < int(pair[1]) else WELL


## The hero fell on the decisive KO: the defeat card owns UI input with RETRY FIGHT focused (keyboard / pad).
func _on_match_over(winner: int, _p1_name: String, _p2_name: String) -> void:
	if winner == 1:
		return
	defeat_card.show()
	InputRouter.acquire_ui(defeat_card)
	retry_button.grab_focus()


func hide_defeat() -> void:
	if defeat_card == null:
		return
	defeat_card.hide()
	InputRouter.release_ui(defeat_card)


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	for live: ProgressBar in _trail:
		var trail: ProgressBar = _trail[live]
		trail.value = move_toward(trail.value, live.value, delta * 0.45)
	if announce_label.visible:
		_announce_left -= delta
		if _announce_left <= 0.0:
			announce_label.hide()
	if resources_label != null and is_instance_valid(hero):
		_refresh_resources()


func _exit_tree() -> void:
	if defeat_card != null:
		InputRouter.release_ui(defeat_card)
