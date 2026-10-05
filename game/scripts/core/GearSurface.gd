class_name GearSurface
extends RefCounted
## Only separate garment/tool geometry. New per-owner material; callers may cache
## within their own NPC domain, never share hero camera/tint state across actors.
const SHADER = preload("res://shaders/gear_surface.gdshader")

static func make(kind: String, color: Color, accent: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("albedo", color)
	material.set_shader_parameter("accent", accent)
	material.set_shader_parameter("surface_kind", {"cloth":0, "leather":1, "metal":2}.get(kind,0))
	return material
