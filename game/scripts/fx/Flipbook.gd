class_name Flipbook
extends MeshInstance3D
## Lane B step 2: plays one of T6·B's painted sheets (docs/Art/Prompts/VFX-Sheets-Prompts.md § Формат аркуша): 4 × 4 cells
## of 512 px, frame 1 top-left, read left to right, 12 fps («on fours», docs/Art/VFX-Direction.md § Принцип). Smoke and dust
## blend MIX with their alpha; sparks, electro and trails may blend ADD. Presentation only: it reads nothing from the fight
## and decides nothing; with Fx.enabled false it spawns nothing (the smoke's same-hash guard).

const FPS := 12.0
const GRID := 4
const PATH := "res://assets/vfx/%s.png"

enum Mode { BILLBOARD, FLOOR }

static var _cache: Dictionary = {}
## id → how many were spawned (the smoke reads it).
static var spawned: Dictionary = {}

var id: String = ""
var first: int = 0
var count: int = 16
var delay: float = 0.0
var life: float = 0.0
var _mat: StandardMaterial3D


## Spawns sheet `id` at `pos` (world), `size_m` metres across. opts: mode (Mode), additive (bool), first (cell 0…15),
## count (cells to play), delay (s before the first cell), tint (Color), flip (bool, mirror left-right).
## FLOOR lies flat (decals seen from above); BILLBOARD faces the camera (side-view sheets: put `pos` at their centre).
static func play(near: Node, sheet: String, pos: Vector3, size_m: float, opts: Dictionary = {}) -> Flipbook:
	if not Fx.enabled or near == null or not near.is_inside_tree():
		return null
	var tex := texture_for(sheet)
	if tex == null:
		return null
	var fb := Flipbook.new()
	fb.id = sheet
	fb.first = clampi(int(opts.get("first", 0)), 0, GRID * GRID - 1)
	fb.count = clampi(int(opts.get("count", GRID * GRID - fb.first)), 1, GRID * GRID - fb.first)
	fb.delay = float(opts.get("delay", 0.0))
	var qm := QuadMesh.new()
	qm.size = Vector2(size_m, size_m)
	fb.mesh = qm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if bool(opts.get("additive", false)) else BaseMaterial3D.BLEND_MODE_MIX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_texture = tex
	m.albedo_color = opts.get("tint", Color.WHITE)
	m.uv1_scale = Vector3(1.0 / GRID, 1.0 / GRID, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var mode: int = int(opts.get("mode", Mode.BILLBOARD))
	if mode == Mode.BILLBOARD:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fb._mat = m
	fb.material_override = m
	fb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Fx.root(near).add_child(fb)
	fb.global_position = pos
	if mode == Mode.FLOOR:
		fb.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	if bool(opts.get("flip", false)):
		fb.scale.x = -1.0
	fb._show(0)
	fb.visible = fb.delay <= 0.0
	spawned[sheet] = int(spawned.get(sheet, 0)) + 1
	return fb


static func texture_for(sheet: String) -> Texture2D:
	if not _cache.has(sheet):
		var p := PATH % sheet
		_cache[sheet] = load(p) as Texture2D if ResourceLoader.exists(p) else null
	return _cache[sheet]


## The cell on screen now (0…count-1 relative to `first`), or -1 before the delay ends.
func cell() -> int:
	if delay > 0.0:
		return -1
	return mini(floori(life * FPS + 1e-6), count - 1)


func _show(k: int) -> void:
	var c := first + k
	_mat.uv1_offset = Vector3(float(c % GRID) / GRID, floorf(float(c) / GRID) / GRID, 0.0)


func _process(dt: float) -> void:
	if delay > 0.0:
		delay -= dt
		if delay > 0.0:
			return
		visible = true
		dt = -delay
		delay = 0.0
	life += dt
	if floori(life * FPS + 1e-6) >= count:
		queue_free()
		return
	_show(cell())
