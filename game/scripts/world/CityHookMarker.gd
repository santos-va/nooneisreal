class_name CityHookMarker
extends Control
## Screen-space hook cue for the traversal target (T8 variant Г, docs/GDD/06-UI-UX.md § «Трос без прицілювання»):
## a thin ring on the selected anchor, a grey hollow ring on an anchor that is too far, and an edge arrow when the
## target is outside the frame. Presentation only: it reads a published packet and never selects anything.
## Sizes, colours and the pulse are PLACEHOLDER until T6/T8 review the frames (T3 grounds the 6" minimum).
enum Mode { HIDDEN, RING, TOO_FAR, ARROW }
const RING_DIAMETER_1080: float = 28.0 # px at 1080p; constant on screen
const RING_WIDTH_1080: float = 3.0
const ARROW_SIZE_1080: float = 28.0
const PULSE_SECONDS: float = 0.1
const PULSE_SCALE: float = 1.15
const ACTIVE_COLOR := Color(0.2, 1.0, 0.75) # the previous cue colour, kept until T6 picks one
const TOO_FAR_COLOR := Color(0.66, 0.66, 0.68)
const OUTLINE_COLOR := Color("171322")
var mode: Mode = Mode.HIDDEN
var at: Vector2 = Vector2.ZERO
var pointing: Vector2 = Vector2.UP
var fill: float = 0.0 # 0 open ring, 1 closed and filled (the windup)
var dimmed: bool = false # the camera's view is blocked; the hand still sees the anchor
var pulse_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func clear() -> void:
	if mode != Mode.HIDDEN:
		mode = Mode.HIDDEN
		queue_redraw()


func ring(screen: Vector2, too_far: bool, closed: float, hidden_from_camera: bool) -> void:
	mode = Mode.TOO_FAR if too_far else Mode.RING
	at = screen
	fill = clampf(closed, 0.0, 1.0)
	dimmed = hidden_from_camera
	queue_redraw()


func arrow(edge: Vector2, direction: Vector2) -> void:
	mode = Mode.ARROW
	at = edge
	pointing = direction.normalized() if direction.length_squared() > 0.000001 else Vector2.UP
	fill = 0.0
	dimmed = false
	queue_redraw()


## One pulse on a target change: up to PULSE_SCALE for PULSE_SECONDS, no flash and no sound (T8).
func pulse() -> void:
	pulse_left = PULSE_SECONDS


func tick(delta: float) -> void:
	if pulse_left > 0.0:
		pulse_left = maxf(0.0, pulse_left - delta)
		queue_redraw()


func scale_factor() -> float:
	return maxf(0.25, get_viewport_rect().size.y / 1080.0)


func diameter() -> float:
	var grow := 1.0 + (PULSE_SCALE - 1.0) * sin(PI * (1.0 - pulse_left / PULSE_SECONDS)) if pulse_left > 0.0 else 1.0
	return RING_DIAMETER_1080 * scale_factor() * grow


func _draw() -> void:
	var unit := scale_factor()
	match mode:
		Mode.RING, Mode.TOO_FAR:
			var color := ACTIVE_COLOR if mode == Mode.RING else TOO_FAR_COLOR
			var alpha := 0.5 if dimmed else 1.0
			var radius := diameter() * 0.5
			var width := RING_WIDTH_1080 * unit
			draw_arc(at, radius, 0.0, TAU, 40, Color(OUTLINE_COLOR, alpha), width + 2.0 * unit, true)
			draw_arc(at, radius, 0.0, TAU, 40, Color(color, alpha), width, true)
			if mode == Mode.RING and fill > 0.0:
				draw_circle(at, maxf(0.0, radius - width) * fill, Color(color, alpha * 0.85))
		Mode.ARROW:
			var size := ARROW_SIZE_1080 * unit
			var side := Vector2(-pointing.y, pointing.x)
			var tip := at + pointing * size * 0.5
			var points := PackedVector2Array([tip, at - pointing * size * 0.5 + side * size * 0.45, at - pointing * size * 0.2, at - pointing * size * 0.5 - side * size * 0.45])
			draw_colored_polygon(points, ACTIVE_COLOR)
			points.append(tip)
			draw_polyline(points, OUTLINE_COLOR, 2.0 * unit, true)
