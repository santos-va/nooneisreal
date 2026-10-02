class_name Hud
extends CanvasLayer
## Battle HUD built in code (prototype). All per-player resources sit on one fixed horizontal band:
## HP bar, round pips, meter, grapple pips, skill cooldowns. Nothing moves while the player polls it.
## Visual direction + per-device adaptation: docs/GDD/06-UI-UX.md (T8 Гермес).

const FONT_BIG := 64
const FONT_MID := 26
const FONT_SMALL := 16

var p1: Fighter
var p2: Fighter
var flow: MatchFlow

var _root: Control
var _hp: Dictionary = {}
var _hp_trail: Dictionary = {}
var _meter: Dictionary = {}
var _pips: Dictionary = {}
var _charges: Dictionary = {}
var _cool: Dictionary = {}
var _names: Dictionary = {}
var _timer: Label
var _announce: Label
var _announce_left: float = 0.0
var _hint: Label
var _result: PanelContainer
var _result_label: Label
var _pause: PanelContainer
var _paused: bool = false


func bind(a: Fighter, b: Fighter, f: MatchFlow) -> void:
	p1 = a
	p2 = b
	flow = f
	_build()
	for pl in [p1, p2]:
		var idx: int = pl.player_index
		pl.hp_changed.connect(func(hp: float, mx: float): _on_hp(idx, hp, mx))
		pl.meter_changed.connect(func(m: float, mx: float): _on_meter(idx, m, mx))
		pl.grapple_changed.connect(func(c: int, cd: float, mc: int): _on_grapple(idx, c, cd, mc))
		pl.cooldowns_changed.connect(func(cd: Dictionary): _on_cooldowns(idx, cd))
		_on_hp(idx, pl.hp, pl.data.max_hp)
		_on_meter(idx, pl.meter, Fighter.MAX_METER)
		_on_grapple(idx, pl.grapple.charges, pl.grapple.cooldown_left, pl.grapple.max_charges)
		_on_cooldowns(idx, pl.cooldowns)
	flow.announce.connect(_on_announce)
	flow.timer_changed.connect(_on_timer)
	flow.round_won.connect(_on_round_won)
	flow.match_over.connect(_on_match_over)
	flow.round_started.connect(func(_n: int): _result.visible = false)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	# top band
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	vbox.add_child(top)
	top.add_child(_player_panel(p1, false))
	var center := VBoxContainer.new()
	center.custom_minimum_size = Vector2(150, 0)
	center.alignment = BoxContainer.ALIGNMENT_BEGIN
	_timer = _label("99", FONT_BIG - 10, HORIZONTAL_ALIGNMENT_CENTER)
	_timer.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	center.add_child(_timer)
	top.add_child(center)
	top.add_child(_player_panel(p2, true))
	# announcer
	_announce = _label("", FONT_BIG, HORIZONTAL_ALIGNMENT_CENTER)
	_announce.set_anchors_preset(Control.PRESET_CENTER)
	_announce.anchor_left = 0.5
	_announce.anchor_right = 0.5
	_announce.anchor_top = 0.42
	_announce.anchor_bottom = 0.42
	_announce.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_announce.add_theme_color_override("font_color", Color(1.0, 0.86, 0.5))
	_announce.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.1))
	_announce.add_theme_constant_override("outline_size", 12)
	_announce.visible = false
	_root.add_child(_announce)
	# hint
	_hint = _label(_hint_text(), FONT_SMALL, HORIZONTAL_ALIGNMENT_CENTER)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.anchor_top = 1.0
	_hint.offset_top = -46
	_hint.offset_bottom = -12
	_hint.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78, 0.75))
	_root.add_child(_hint)
	# result overlay
	_result = _overlay()
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 14)
	_result.add_child(rv)
	_result_label = _label("", FONT_BIG - 14, HORIZONTAL_ALIGNMENT_CENTER)
	rv.add_child(_result_label)
	var again := _button("REMATCH", func(): _result.visible = false; flow.rematch())
	rv.add_child(again)
	rv.add_child(_button("MAIN MENU", func(): Engine.time_scale = 1.0; get_tree().paused = false; GameState.to_menu()))
	_result.visible = false
	_root.add_child(_result)
	# pause overlay
	_pause = _overlay()
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 14)
	_pause.add_child(pv)
	pv.add_child(_label("PAUSED", FONT_BIG - 14, HORIZONTAL_ALIGNMENT_CENTER))
	pv.add_child(_button("RESUME", toggle_pause))
	pv.add_child(_button("RESET POSITIONS", func(): toggle_pause(); flow.reset_positions()))
	pv.add_child(_button("MAIN MENU", func(): get_tree().paused = false; Engine.time_scale = 1.0; GameState.to_menu()))
	_pause.visible = false
	_pause.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_root.add_child(_pause)


func _player_panel(f: Fighter, mirrored: bool) -> Control:
	var idx := f.player_index
	var col := f.data.primary_color
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	var name_row := HBoxContainer.new()
	var nm := _label(f.data.display_name, FONT_MID, HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.add_theme_color_override("font_color", col.lightened(0.45))
	_names[idx] = nm
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 6)
	_pips[idx] = []
	for i in GameState.rounds_to_win:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(18, 18)
		pip.color = Color(0.25, 0.22, 0.28)
		pip.rotation = 0.0
		pips.add_child(pip)
		_pips[idx].append(pip)
	if mirrored:
		name_row.add_child(pips)
		name_row.add_child(nm)
	else:
		name_row.add_child(nm)
		name_row.add_child(pips)
	box.add_child(name_row)
	# HP: trail bar (pale) behind the live bar
	var hp_stack := Control.new()
	hp_stack.custom_minimum_size = Vector2(0, 26)
	var trail := _bar(Color(0.95, 0.75, 0.6, 0.9), Color(0.12, 0.1, 0.14), mirrored)
	trail.set_anchors_preset(Control.PRESET_FULL_RECT)
	var live := _bar(Color(0.95, 0.88, 0.35) if idx == 1 else Color(0.5, 0.95, 0.75), Color(0, 0, 0, 0), mirrored)
	live.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_stack.add_child(trail)
	hp_stack.add_child(live)
	box.add_child(hp_stack)
	_hp[idx] = live
	_hp_trail[idx] = trail
	# resources row: meter + grapple pips + cooldowns
	var res := HBoxContainer.new()
	res.add_theme_constant_override("separation", 10)
	var meter := _bar(f.data.accent_color, Color(0.12, 0.1, 0.14), mirrored)
	meter.custom_minimum_size = Vector2(220, 12)
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_meter[idx] = meter
	var charges := HBoxContainer.new()
	charges.add_theme_constant_override("separation", 4)
	_charges[idx] = []
	for i in f.data.grapple_charges:
		var c := ColorRect.new()
		c.custom_minimum_size = Vector2(14, 14)
		c.color = f.data.accent_color
		charges.add_child(c)
		_charges[idx].append(c)
	var cool := _label("S1 ✓  S2 ✓", FONT_SMALL, HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT)
	cool.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.85))
	_cool[idx] = cool
	if mirrored:
		res.add_child(cool)
		res.add_child(charges)
		res.add_child(meter)
	else:
		res.add_child(meter)
		res.add_child(charges)
		res.add_child(cool)
	box.add_child(res)
	return box


func _bar(fill: Color, bg: Color, mirrored: bool) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 1.0
	b.value = 1.0
	b.show_percentage = false
	b.fill_mode = ProgressBar.FILL_END_TO_BEGIN if mirrored else ProgressBar.FILL_BEGIN_TO_END
	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color = bg
	sb_bg.set_corner_radius_all(3)
	var sb_fill := StyleBoxFlat.new()
	sb_fill.bg_color = fill
	sb_fill.set_corner_radius_all(3)
	sb_fill.skew = Vector2(-0.25 if mirrored else 0.25, 0.0)
	b.add_theme_stylebox_override("background", sb_bg)
	b.add_theme_stylebox_override("fill", sb_fill)
	return b


func _label(text: String, size: int, align: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align as HorizontalAlignment
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.07))
	l.add_theme_constant_override("outline_size", 4 if size <= FONT_MID else 8)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 44)
	b.add_theme_font_size_override("font_size", FONT_MID - 4)
	b.pressed.connect(cb)
	return b


func _overlay() -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.11, 0.92)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(28)
	sb.border_color = Color(0.85, 0.5, 0.3)
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _hint_text() -> String:
	if GameState.p2_is_cpu:
		return "P1  A/D move · W/Space jump · S crouch · F light · G heavy · LShift guard · Q/E skills · R grapple (S+R = pull enemy) · C dash · V ultimate   |   Tab hitboxes · Esc pause"
	return "P1  A/D · W · F light · G heavy · LShift guard · Q/E · R grapple · C dash · V ult        P2  ←/→ · ↑ · K light · L heavy · RShift guard · ; ' · I grapple · . dash · , ult"


# --- updates --------------------------------------------------------------------------------
func _on_hp(idx: int, hp: float, mx: float) -> void:
	(_hp[idx] as ProgressBar).value = clampf(hp / mx, 0.0, 1.0)


func _on_meter(idx: int, m: float, mx: float) -> void:
	(_meter[idx] as ProgressBar).value = clampf(m / mx, 0.0, 1.0)
	var full := m >= mx
	var sb := (_meter[idx] as ProgressBar).get_theme_stylebox("fill") as StyleBoxFlat
	if sb:
		sb.bg_color = Color(1.0, 0.95, 0.6) if full else (p1 if idx == 1 else p2).data.accent_color


func _on_grapple(idx: int, c: int, cd: float, mc: int) -> void:
	var pips: Array = _charges[idx]
	var accent: Color = (p1 if idx == 1 else p2).data.accent_color
	for i in pips.size():
		var pip := pips[i] as ColorRect
		if i < c:
			pip.color = accent
		elif i == c and cd > 0.0:
			pip.color = accent.darkened(0.55)
		else:
			pip.color = Color(0.22, 0.2, 0.26)


func _on_cooldowns(idx: int, cd: Dictionary) -> void:
	var s1: float = cd.get("skill1", 0.0)
	var s2: float = cd.get("skill2", 0.0)
	var t1 := "✓" if s1 <= 0.0 else "%.1f" % s1
	var t2 := "✓" if s2 <= 0.0 else "%.1f" % s2
	(_cool[idx] as Label).text = "S1 %s  S2 %s" % [t1, t2]


func _on_timer(t: int) -> void:
	_timer.text = "∞" if GameState.training_mode else str(t)


func _on_announce(text: String, seconds: float) -> void:
	_announce.text = text
	_announce.visible = true
	_announce_left = seconds
	_announce.scale = Vector2(1.25, 1.25)


func _on_round_won(player: int, w1: int, w2: int) -> void:
	for i in (_pips[1] as Array).size():
		(_pips[1][i] as ColorRect).color = Color(1.0, 0.85, 0.4) if i < w1 else Color(0.25, 0.22, 0.28)
	for i in (_pips[2] as Array).size():
		(_pips[2][i] as ColorRect).color = Color(1.0, 0.85, 0.4) if i < w2 else Color(0.25, 0.22, 0.28)


func _on_match_over(winner: int, n1: String, n2: String) -> void:
	_result_label.text = "%s WINS" % (n1 if winner == 1 else n2)
	_result.visible = true
	var first := _result.get_child(0).get_child(1) as Button
	if first:
		first.grab_focus()


func toggle_pause() -> void:
	if flow.phase == MatchFlow.Phase.MATCH_END:
		return
	_paused = not _paused
	get_tree().paused = _paused
	_pause.visible = _paused
	if _paused:
		(_pause.get_child(0).get_child(1) as Button).grab_focus()


func _process(delta: float) -> void:
	# hp trail lags behind the live bar
	for idx in [1, 2]:
		var live := _hp[idx] as ProgressBar
		var trail := _hp_trail[idx] as ProgressBar
		trail.value = move_toward(trail.value, live.value, delta * 0.45)
	if _announce.visible:
		_announce_left -= delta
		_announce.scale = _announce.scale.lerp(Vector2.ONE, minf(1.0, 12.0 * delta))
		if _announce_left <= 0.0:
			_announce.visible = false
