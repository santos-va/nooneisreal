class_name Backdrop
extends Node3D
## Painted stage backdrop (Higgsfield illustration on a big quad) with light parallax.
## Falls back to a procedural Kronshift dusk when the texture has not been fetched yet.

const BACKDROP_SHADER := preload("res://shaders/backdrop.gdshader")
const FALLBACK_SHADER := preload("res://shaders/backdrop_fallback.gdshader")

var quad: MeshInstance3D            # the first card (the only one in the plane)
var cards: Array[MeshInstance3D] = []
var neon: Label3D = null           # Fountain Square at night only
const NEON_COLOR := Color(1.0, 0.36, 0.78)
const NEON_GLOW := Color(0.62, 0.12, 0.52)
## Free movement: cards in the ring. Each card is wider than 2 × its distance, so neighbours meet at the corners.
const RING_CARDS := 4
var floor_fade: MeshInstance3D
var using_texture: bool = false


## Default framing (painted cards that already fill a 16:9 view).
const DEFAULT_FRAME := {"size": Vector2(54.0, 30.4), "pos": Vector3(0.0, 12.0, -18.0), "mirror_x": 1.0, "img_top": 0.0}


func apply(stage: Dictionary) -> void:
	var frame: Dictionary = DEFAULT_FRAME.duplicate()
	frame.merge(stage.get("backdrop", {}), true)
	if GameState.free_move:
		# launch 6: the 20 m circle and the ADR-018 camera (arm up to 24 m, fov 60) would reach past an 18 m card or
		# see its edges; push it out beyond circle + arm, scaled so it keeps the same size seen from the centre
		var k := free_scale()
		frame.size = (frame.size as Vector2) * k
		frame.pos = (frame.pos as Vector3) * k
	var mat := ShaderMaterial.new()
	var path: String = stage.get("texture", "")
	if path != "" and ResourceLoader.exists(path):
		mat.shader = BACKDROP_SHADER
		mat.set_shader_parameter("tex", load(path))
		mat.set_shader_parameter("mirror_x", float(frame.mirror_x))
		mat.set_shader_parameter("img_top", float(frame.img_top))
		mat.set_shader_parameter("sky_top", stage.get("sky_top", Color(0.3, 0.3, 0.42)))
		mat.set_shader_parameter("tint", stage.get("tint", Color.WHITE))   # A2: night darkens and cools the painted card
		using_texture = true
	else:
		mat.shader = FALLBACK_SHADER
		mat.set_shader_parameter("sky_top", stage.get("sky_top", Color(0.16, 0.22, 0.32)))
		mat.set_shader_parameter("sky_bottom", stage.get("sky_bottom", Color(0.78, 0.42, 0.26)))
		using_texture = false
	# plane: one card behind the fight. Free movement (sprint A1, docs/Plans/2026-10-03-Sprint-Arenas-VFX.md): a fixed
	# ring of RING_CARDS cards around the circle, each facing the centre — the world stands still while the fighters
	# circle; parallax comes only from where the camera is. Same art on every card until the 360° art (R11, band C).
	var count := RING_CARDS if GameState.free_move else 1
	for i in count:
		var pivot := Node3D.new()
		pivot.name = "Card%d" % i
		pivot.rotation.y = TAU * float(i) / float(count)
		add_child(pivot)
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = frame.size
		q.mesh = qm
		q.position = frame.pos
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		q.material_override = mat
		pivot.add_child(q)
		cards.append(q)
	quad = cards[0]
	# sprint A2: the CRONSHIFT neon on the far tower of Fountain Square — night only (docs/World/Cronshift.md § Нові арени).
	# PLACEHOLDER sign in front of the first card until band C paints the tower.
	var neon_text: String = stage.get("neon", "")
	if neon_text != "":
		neon = Label3D.new()
		neon.name = "Neon"
		neon.text = neon_text
		neon.shaded = false
		neon.double_sided = false
		neon.modulate = NEON_COLOR
		neon.outline_modulate = NEON_GLOW
		neon.outline_size = 24
		neon.font_size = 256
		var fp: Vector3 = frame.pos
		neon.pixel_size = 0.02 * absf(fp.z) / 18.0   # same apparent size at any card distance
		neon.position = Vector3(0.0, fp.y + absf(fp.z) * 0.45, fp.z * 0.97)
		add_child(neon)


func _process(_delta: float) -> void:
	if GameState.free_move:
		return   # A1: the ring is fixed in the world
	var cam := get_viewport().get_camera_3d()
	if cam and quad:
		quad.position.x = cam.global_position.x * 0.2


## Free movement: how much farther the card stands than in the plane — beyond the circle plus the longest camera arm.
static func free_scale() -> float:
	return (Fighter.ARENA_RADIUS + DuelCamera.SIDE_DIST_MAX + 4.0) / absf(float(DEFAULT_FRAME.pos.z))


## Angle (degrees) between where the camera looks and the nearest card's facing: < 90° = a card is in view.
func view_angle(cam: Camera3D) -> float:
	return rad_to_deg((-cam.global_basis.z).angle_to(-cards[facing_card(cam)].global_basis.z))


## Index of the card the camera looks at most squarely.
func facing_card(cam: Camera3D) -> int:
	var best := 0
	var best_dot := -INF
	for i in cards.size():
		var d := (-cam.global_basis.z).dot(-cards[i].global_basis.z)
		if d > best_dot:
			best_dot = d
			best = i
	return best
