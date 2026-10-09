class_name CitySteamVent
extends Node3D
## № 15 of the T6 catalog: a puff of white steam rises from a paving grate now and then. The painted sheet
## vfx_steam_puff_v1 (6 frames; its chimney stack under the steam is cut off) on an upright billboard, picture only:
## no collider, no light, no randomness — the puffs follow this node's own clock and `phase`.
## Safety (T6 К6 and «Заборони»; plan 2026-10-09 «Доступність»): the puff is small (≈ 1 × 1.4 m), changes frame
## under 3 times a second, fades in and out over ≥ 0.3 s and never covers a hero — it fades away while a fighter is
## within `hero_clear` metres, or the camera within `lens_clear`. PLACEHOLDER timings, T6 accepts the look.
const SHEET: Texture2D = preload("res://assets/vfx/vfx_steam_puff_v1.png")
const CELL := Vector2(448.0, 650.0)   # one frame: a sixth of the 2688 px sheet, the steam above the stack (y 360–1010)
const CELL_TOP: float = 360.0
const FRAMES: int = 6
@export var period: float = 7.5          # seconds from one puff to the next
@export var frame_seconds: float = 0.36  # 2.8 frames a second
@export var fade_in: float = 0.35
@export var fade_out: float = 0.6
@export var peak_alpha: float = 0.8
@export var hero_clear: float = 1.6
@export var lens_clear: float = 1.4
var phase: float = 0.0
var clock: float = 0.0
var sprite: Sprite3D
var _atlas: AtlasTexture
var _suppress: float = 1.0   # 1 = free to show, 0 = held off (a hero or the lens is close)


func _ready() -> void:
	_atlas = AtlasTexture.new()
	_atlas.atlas = SHEET
	sprite = Sprite3D.new()
	sprite.name = "Puff"
	sprite.texture = _atlas
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.shaded = false
	sprite.double_sided = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.pixel_size = 1.4 / CELL.y
	sprite.position = Vector3(0, 0.7 + 0.03, 0)
	add_child(sprite)
	clock = phase
	_apply()


func _process(delta: float) -> void:
	step(delta)


## Advances the puff by `delta` seconds (fixtures call it directly).
func step(delta: float) -> void:
	clock += delta
	var held: bool = _hero_near() or _lens_near()
	_suppress = move_toward(_suppress, 0.0 if held else 1.0, delta * 4.0)
	_apply()


## The puff's opacity now, 0…peak_alpha.
func puff_alpha() -> float:
	return sprite.modulate.a if sprite != null else 0.0


func puff_frame() -> int:
	return clampi(floori(fmod(clock, period) / frame_seconds), 0, FRAMES - 1)


func _apply() -> void:
	if sprite == null:
		return
	var t: float = fmod(clock, period)
	var life: float = frame_seconds * float(FRAMES)
	var alpha: float = 0.0
	if t < life:
		alpha = peak_alpha * minf(1.0, t / fade_in) * minf(1.0, (life - t) / fade_out)
	alpha *= _suppress
	_atlas.region = Rect2(float(puff_frame()) * CELL.x, CELL_TOP, CELL.x, CELL.y)
	sprite.modulate = Color(1, 1, 1, alpha)
	sprite.visible = alpha > 0.002


func _hero_near() -> bool:
	if not is_inside_tree():
		return false
	for node: Node in get_tree().get_nodes_in_group("fighters"):
		var body := node as Node3D
		if body == null or not body.is_inside_tree():
			continue
		var offset: Vector3 = body.global_position - global_position
		if Vector2(offset.x, offset.z).length() < hero_clear and absf(offset.y) < 2.5:
			return true
	return false


func _lens_near() -> bool:
	if not is_inside_tree() or get_viewport() == null:
		return false
	var camera: Camera3D = get_viewport().get_camera_3d()
	return camera != null and camera.global_position.distance_to(sprite.global_position) < lens_clear
