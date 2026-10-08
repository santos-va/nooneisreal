class_name CityMeterBar
extends Control
## A flat bar for the city's status card (T8 06-UI-UX § «Шкала голоду в HUD міста»): a well, a fill from the left,
## threshold notches 2 px wide that stand 2 px above and below the bar, and an optional 2 px frame (FAINT: a change of
## shape, never colour alone). Static: no pulse, no shake. Colours are PLACEHOLDER until T6's palette.
const NOTCH_WIDTH := 2.0
const NOTCH_OVERHANG := 2.0

var value: float = 1.0                 # 0…1, what is drawn
var notches: Array[float] = []         # 0…1 positions
var fill_color: Color = Color(0.96, 0.94, 0.86)
var well_color: Color = Color(0.09, 0.08, 0.12, 0.95)
var notch_color: Color = Color(0.96, 0.94, 0.86)
var frame_color: Color = Color(0.96, 0.94, 0.86)
var framed: bool = false


func _init(height: float = 8.0) -> void:
	custom_minimum_size.y = height + NOTCH_OVERHANG * 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_value(next: float) -> void:
	next = clampf(next, 0.0, 1.0)
	if not is_equal_approx(next, value):
		value = next
		queue_redraw()


func _draw() -> void:
	var bar := Rect2(Vector2(0.0, NOTCH_OVERHANG), Vector2(size.x, size.y - NOTCH_OVERHANG * 2.0))
	draw_rect(bar, well_color)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * value, bar.size.y)), fill_color)
	if framed:
		draw_rect(bar, frame_color, false, 2.0)
	for at: float in notches:
		var x: float = roundf(bar.size.x * at - NOTCH_WIDTH * 0.5)
		draw_rect(Rect2(Vector2(x, 0.0), Vector2(NOTCH_WIDTH, size.y)), notch_color)
		if at < value:   # over the fill the notch takes the well's tone, so it reads on both
			draw_rect(Rect2(Vector2(x, bar.position.y), Vector2(NOTCH_WIDTH, bar.size.y)), well_color)
