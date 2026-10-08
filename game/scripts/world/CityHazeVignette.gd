class_name CityHazeVignette
extends CanvasLayer
## The static vignette of «Заплутаність» (plan 2026-10-08-City-Events-Stage-1, step 4; T7 § 5.1–5.2; T8 06-UI-UX
## § «Заплутаність» поруч зі шкалою, item 3): a radial shade in the city's shadow tone (#2B2230, not black) that leaves
## a clear middle around the hero. It lies under every HUD (layer 15 < LethalHud 19 < CityHud 20 < NpcDialogue 30), its
## strength is CityHaze.weight() — a ramp in, a plateau, a fade out; never a pulse. Sizes PLACEHOLDER (r_haze, T5/T6).
const LAYER := 15
const SHADE := Color("2b2230")
const CLEAR_RADIUS := 0.36   # r_haze PLACEHOLDER: fraction of the half-height that stays clear
const FULL_RADIUS := 0.98    # where the shade reaches its full strength
const MAX_ALPHA := 0.88      # PLACEHOLDER: the edge is never fully opaque

var haze: CityHaze
var rect: TextureRect


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = TextureRect.new()
	rect.name = "Vignette"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient := Gradient.new()
	gradient.set_color(0, Color(SHADE, 0.0))
	gradient.set_offset(0, CLEAR_RADIUS)
	gradient.set_color(1, Color(SHADE, MAX_ALPHA))
	gradient.set_offset(1, FULL_RADIUS)
	gradient.add_point(lerpf(CLEAR_RADIUS, FULL_RADIUS, 0.45), Color(SHADE, MAX_ALPHA * 0.55))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 256
	texture.height = 256
	rect.texture = texture
	add_child(rect)
	rect.visible = false


func bind(model: CityHaze) -> void:
	haze = model


func strength() -> float:
	return rect.modulate.a if rect.visible else 0.0


func _process(_delta: float) -> void:
	var value: float = haze.weight() if haze != null else 0.0
	rect.visible = value > 0.0
	rect.modulate = Color(1, 1, 1, value)
