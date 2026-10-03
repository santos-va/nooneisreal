class_name Backdrop
extends Node3D
## Painted stage backdrop (Higgsfield illustration on a big quad) with light parallax.
## Falls back to a procedural Kronshift dusk when the texture has not been fetched yet.

const BACKDROP_SHADER := preload("res://shaders/backdrop.gdshader")
const FALLBACK_SHADER := preload("res://shaders/backdrop_fallback.gdshader")

var quad: MeshInstance3D
var floor_fade: MeshInstance3D
var using_texture: bool = false


## Default framing (painted cards that already fill a 16:9 view).
const DEFAULT_FRAME := {"size": Vector2(54.0, 30.4), "pos": Vector3(0.0, 12.0, -18.0), "mirror_x": 1.0, "img_top": 0.0}


func apply(stage: Dictionary) -> void:
	var frame: Dictionary = DEFAULT_FRAME.duplicate()
	frame.merge(stage.get("backdrop", {}), true)
	quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = frame.size
	quad.mesh = qm
	quad.position = frame.pos
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	var path: String = stage.get("texture", "")
	if path != "" and ResourceLoader.exists(path):
		mat.shader = BACKDROP_SHADER
		mat.set_shader_parameter("tex", load(path))
		mat.set_shader_parameter("mirror_x", float(frame.mirror_x))
		mat.set_shader_parameter("img_top", float(frame.img_top))
		mat.set_shader_parameter("sky_top", stage.get("sky_top", Color(0.3, 0.3, 0.42)))
		using_texture = true
	else:
		mat.shader = FALLBACK_SHADER
		mat.set_shader_parameter("sky_top", stage.get("sky_top", Color(0.16, 0.22, 0.32)))
		mat.set_shader_parameter("sky_bottom", stage.get("sky_bottom", Color(0.78, 0.42, 0.26)))
		using_texture = false
	quad.material_override = mat
	add_child(quad)


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam and quad:
		quad.position.x = cam.global_position.x * 0.2
