class_name Hud
extends CanvasLayer
## Battle HUD built in code (prototype). All per-player resources sit on one fixed horizontal band:
## HP bar, round pips, meter, grapple pips, skill cooldowns. Nothing moves while the player polls it.
## Visual direction + per-device adaptation: docs/GDD/06-UI-UX.md (T8 Гермес).

const FONT_BIG := 64
const FONT_MID := 26
const FONT_SMALL := 16
## Contrast on day and night arenas (06-UI-UX § Контраст HUD, Santos's variant 2): no plate behind the HUD; every
## non-text element wears a double outline — an ink ring outside, a cream ring inside — so one of the two rings stands
## out on any background. Bars keep a dark well; pips, charges and dash are clear inside and fill from the bottom.
const INK := Color("#2B2230")
const CREAM := Color("#FAEDD9")
const WELL := Color("#141018")
const RING_INK := 2
const RING_CREAM := 1
## On a small window the canvas shrinks (`canvas_items` stretch from 1600×900; 844×390 → ×0.43), and a 1-unit cream ring
## turns into half a pixel and breaks up (06-UI-UX § Контраст HUD, п. 7). So each ring is never thinner on screen than its
## unit width is at ×1: ink ≥ 2 px, cream ≥ 1 px. At ×1 and above the widths stay exactly RING_INK / RING_CREAM.
const RING_MIN_PX := Vector2(RING_INK, RING_CREAM)
## Widening stops below this scale (a 400×225 window; the smallest target, a phone at 844×390, is ×0.43). A headless run's
## 64×36 window would otherwise ask for 50-unit rings.
const RING_MIN_SCALE := 0.25
const SKEW := 0.25
const ROUND_WON := Color(1.0, 0.85, 0.4)
## S1 / S2 cooldown icons by character id (Textures-Registry ui-icon-*; Hud.gd was their planned landing spot).
const SKILL_ICONS := {
	"choko": ["res://assets/ui/icons/icon_choko_record.png", "res://assets/ui/icons/icon_choko_timestop.png"],
	"skea": ["res://assets/ui/icons/icon_skea_kunai.png", "res://assets/ui/icons/icon_skea_veil.png"],
}

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
var _cool_icons: Dictionary = {}
var _dash: Dictionary = {}
var _status: Dictionary = {}
var _names: Dictionary = {}
var _timer: Label
var _announce: Label
var _announce_left: float = 0.0
var _hint: Label
var _result: PanelContainer
var _result_label: Label
var _pause: PanelContainer
var _paused: bool = false
## Every ink ring the HUD built (the smoke reads them).
var outlines: Array[PanelContainer] = []
## Ring widths in canvas units for the current window (`ring_widths`): x = ink, y = cream.
var ring_units := Vector2i(RING_INK, RING_CREAM)


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
		pl.dash_changed.connect(func(c: int, r: float, mc: int): _on_dash(idx, c, r, mc))
		pl.status_changed.connect(func(t: String): (_status[idx] as Label).text = t)
		_on_hp(idx, pl.hp, pl.data.max_hp)
		_on_meter(idx, pl.meter, Fighter.MAX_METER)
		_on_grapple(idx, pl.grapple.charges, pl.grapple.cooldown_left, pl.grapple.max_charges)
		_on_cooldowns(idx, pl.cooldowns)
		_on_dash(idx, pl.dash_charges_left, 0.0, pl.data.dash_charges)
	flow.announce.connect(_on_announce)
	flow.timer_changed.connect(_on_timer)
	flow.round_won.connect(_on_round_won)
	flow.match_over.connect(_on_match_over)
	flow.round_started.connect(func(_n: int): _result.visible = false)


func _build() -> void:
	ring_units = ring_widths(canvas_scale())
	get_viewport().size_changed.connect(_on_viewport_resized)
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
		pips.add_child(_cell(Vector2(14, 14), ROUND_WON, _pips[idx]))
	if mirrored:
		name_row.add_child(pips)
		name_row.add_child(nm)
	else:
		name_row.add_child(nm)
		name_row.add_child(pips)
	box.add_child(name_row)
	# HP: trail bar (pale) behind the live bar
	var hp_stack := Control.new()
	hp_stack.custom_minimum_size = Vector2(0, 20)
	var trail := _bar(Color(0.95, 0.75, 0.6, 0.9), WELL, mirrored)
	trail.set_anchors_preset(Control.PRESET_FULL_RECT)
	var live := _bar(Color(0.95, 0.88, 0.35) if idx == 1 else Color(0.5, 0.95, 0.75), Color(0, 0, 0, 0), mirrored)
	live.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_stack.add_child(trail)
	hp_stack.add_child(live)
	box.add_child(_outlined(hp_stack, -SKEW if mirrored else SKEW))
	_hp[idx] = live
	_hp_trail[idx] = trail
	# resources row: meter + grapple pips + cooldowns
	var res := HBoxContainer.new()
	res.add_theme_constant_override("separation", 10)
	var meter := _bar(f.data.accent_color, WELL, mirrored)
	meter.custom_minimum_size = Vector2(214, 8)
	_meter[idx] = meter
	var meter_ring := _outlined(meter, -SKEW if mirrored else SKEW)
	meter_ring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter_ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var charges := HBoxContainer.new()
	charges.add_theme_constant_override("separation", 4)
	_charges[idx] = []
	for i in f.data.grapple_charges:
		charges.add_child(_cell(Vector2(10, 10), f.data.accent_color, _charges[idx]))
	var icons: Array = SKILL_ICONS.get(f.data.id, [])
	var cool := HBoxContainer.new()
	cool.add_theme_constant_override("separation", 10)
	var s1 := _skill_slot(icons[0] if icons.size() > 0 else "")
	var s2 := _skill_slot(icons[1] if icons.size() > 1 else "")
	cool.add_child(s1.box)
	cool.add_child(s2.box)
	_cool[idx] = [s1.label, s2.label]
	if mirrored:
		res.add_child(cool)
		res.add_child(charges)
		res.add_child(meter_ring)
	else:
		res.add_child(meter_ring)
		res.add_child(charges)
		res.add_child(cool)
	box.add_child(res)
	# second resource row: signature-movement charges (Skea's flash) + status effects
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	var dash := HBoxContainer.new()
	dash.add_theme_constant_override("separation", 3)
	_dash[idx] = []
	for i in f.data.dash_charges:
		dash.add_child(_cell(Vector2(18, 5), dash_color(f.data), _dash[idx]))
	var st := _label("", FONT_SMALL, HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT)
	st.add_theme_color_override("font_color", f.data.vfx_primary.lightened(0.35))
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status[idx] = st
	if mirrored:
		row2.add_child(st)
		row2.add_child(dash)
	else:
		row2.add_child(dash)
		row2.add_child(st)
	box.add_child(row2)
	return box


## One S1/S2 cooldown slot: the skill icon (missing → no icon, text only) and its countdown label.
func _skill_slot(icon_path: String) -> Dictionary:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.texture = load(icon_path) as Texture2D
		icon.custom_minimum_size = Vector2(18, 18)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
	var lbl := _label("✓", FONT_SMALL, HORIZONTAL_ALIGNMENT_LEFT)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.85))
	box.add_child(lbl)
	return {"box": box, "label": lbl}


func _bar(fill: Color, bg: Color, mirrored: bool) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 1.0
	b.value = 1.0
	b.show_percentage = false
	b.fill_mode = ProgressBar.FILL_END_TO_BEGIN if mirrored else ProgressBar.FILL_BEGIN_TO_END
	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color = bg
	sb_bg.skew = Vector2(-SKEW if mirrored else SKEW, 0.0)
	var sb_fill := StyleBoxFlat.new()
	sb_fill.bg_color = fill
	sb_fill.skew = Vector2(-SKEW if mirrored else SKEW, 0.0)
	b.add_theme_stylebox_override("background", sb_bg)
	b.add_theme_stylebox_override("fill", sb_fill)
	return b


## The double outline around `inner`: ink ring RING_INK outside, cream ring RING_CREAM inside, both clear in the middle
## (no plate) and slanted alike (`skew`). Returns the outer ring; add it where `inner` would go.
func _outlined(inner: Control, skew: float = 0.0) -> PanelContainer:
	var ink := PanelContainer.new()
	ink.name = "Ink"
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink.add_theme_stylebox_override("panel", _ring(INK, ring_units.x, skew))
	var cream := PanelContainer.new()
	cream.name = "Cream"
	cream.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cream.add_theme_stylebox_override("panel", _ring(CREAM, ring_units.y, skew))
	ink.add_child(cream)
	cream.add_child(inner)
	outlines.append(ink)
	return ink


## How many screen pixels one HUD canvas unit covers in this window (1.0 at 1600×900, ≈ 0.43 at 844×390).
func canvas_scale() -> float:
	var w := get_viewport() as Window
	if w == null or w.content_scale_size.x <= 0 or w.content_scale_size.y <= 0:
		return 1.0
	var base := Vector2(w.content_scale_size)
	return minf(w.size.x / base.x, w.size.y / base.y) * w.content_scale_factor


## Ring widths (ink, cream) in canvas units at canvas scale `s`: the ×1 widths, widened so neither ring drops below
## RING_MIN_PX on screen.
static func ring_widths(s: float) -> Vector2i:
	s = maxf(s, RING_MIN_SCALE)
	return Vector2i(maxi(RING_INK, ceili(RING_MIN_PX.x / s - 0.001)), maxi(RING_CREAM, ceili(RING_MIN_PX.y / s - 0.001)))


func _on_viewport_resized() -> void:
	set_ring_units(ring_widths(canvas_scale()))


## Re-width every ring already built (window resized, or the smoke checking a phone-sized scale).
func set_ring_units(u: Vector2i) -> void:
	if u == ring_units:
		return
	ring_units = u
	for ink in outlines:
		_rewidth(ink.get_theme_stylebox("panel") as StyleBoxFlat, u.x)
		_rewidth((ink.get_child(0) as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat, u.y)


static func _rewidth(sb: StyleBoxFlat, width: int) -> void:
	sb.set_border_width_all(width)
	sb.set_content_margin_all(width)


func _ring(col: Color, width: int, skew: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = col
	sb.set_border_width_all(width)
	sb.set_content_margin_all(width)
	sb.skew = Vector2(skew, 0.0)
	return sb


## A round pip / grapple charge / dash cell: clear inside its outline; its Fill rises from the bottom (_fill_cell).
## The Fill goes into `into`; the outlined cell is returned.
func _cell(size: Vector2, col: Color, into: Array) -> PanelContainer:
	var inner := Control.new()
	inner.custom_minimum_size = size
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(fill)
	_fill_cell(fill, 0.0, col)
	into.append(fill)
	return _outlined(inner)


## 0 = empty (clear), 1 = full; in between = a cooldown filling up from the bottom.
static func _fill_cell(fill: ColorRect, frac: float, col: Color) -> void:
	frac = clampf(frac, 0.0, 1.0)
	fill.color = col
	fill.visible = frac > 0.0
	fill.anchor_left = 0.0
	fill.anchor_right = 1.0
	fill.anchor_bottom = 1.0
	fill.anchor_top = 1.0 - frac
	fill.offset_left = 0.0
	fill.offset_right = 0.0
	fill.offset_top = 0.0
	fill.offset_bottom = 0.0


## How full a Fill is (the smoke reads it).
static func cell_frac(fill: ColorRect) -> float:
	return 1.0 - fill.anchor_top if fill.visible else 0.0


## The dash cells' colour: vfx_primary lightened 0.25 (Skea `#9E4CF2` → `#B679F5`, 06-UI-UX § Рішення Santos п. 5).
static func dash_color(d: CharacterData) -> Color:
	return d.vfx_primary.lightened(0.25)


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
	return InputRouter.hint_text(GameState.p2_is_cpu)


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
	var d: CharacterData = (p1 if idx == 1 else p2).data
	for i in pips.size():
		var frac := 0.0
		if i < c:
			frac = 1.0
		elif i == c and cd > 0.0:
			frac = 1.0 - cd / maxf((p1 if idx == 1 else p2).grapple.cooldown_total, 0.001)
		_fill_cell(pips[i] as ColorRect, frac, d.accent_color)


func _on_cooldowns(idx: int, cd: Dictionary) -> void:
	var s1: float = cd.get("skill1", 0.0)
	var s2: float = cd.get("skill2", 0.0)
	var labels: Array = _cool[idx]
	(labels[0] as Label).text = "✓" if s1 <= 0.0 else "%.1f" % s1
	(labels[1] as Label).text = "✓" if s2 <= 0.0 else "%.1f" % s2


func _on_dash(idx: int, c: int, r: float, _mc: int) -> void:
	var pips: Array = _dash[idx]
	var d: CharacterData = (p1 if idx == 1 else p2).data
	# all spent charges return together dash_recharge s after the last use, so they fill together
	var back := 1.0 - r / maxf((p1 if idx == 1 else p2).dash_recharge_total, 0.001) if r > 0.0 else 0.0
	for i in pips.size():
		_fill_cell(pips[i] as ColorRect, 1.0 if i < c else back, dash_color(d))


func _on_timer(t: int) -> void:
	_timer.text = "∞" if GameState.training_mode else str(t)


func _on_announce(text: String, seconds: float) -> void:
	_announce.text = text
	_announce.visible = true
	_announce_left = seconds
	_announce.scale = Vector2(1.25, 1.25)


func _on_round_won(player: int, w1: int, w2: int) -> void:
	for i in (_pips[1] as Array).size():
		_fill_cell(_pips[1][i] as ColorRect, 1.0 if i < w1 else 0.0, ROUND_WON)
	for i in (_pips[2] as Array).size():
		_fill_cell(_pips[2][i] as ColorRect, 1.0 if i < w2 else 0.0, ROUND_WON)


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
