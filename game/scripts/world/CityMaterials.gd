class_name CityMaterials
extends RefCounted
## PLACEHOLDER artistic tuning from the existing Cronshift references, not sampled source pixels.
## One shared material per family; all patterns stay in world metres and use the city-only shader.
const SURFACE: Shader = preload("res://shaders/city_surface.gdshader")

static func palette() -> Dictionary:
	var result: Dictionary = {}
	result["paving"] = _material("8a8581", 1, Vector2(0.70, 0.45), 0.006, 0.16, 0.055)
	result["stone"] = _material("9d9385", 1, Vector2(0.95, 0.48), 0.011, 0.25, 0.045)
	result["brick"] = _material("9f7b73", 2, Vector2(0.62, 0.27), 0.007, 0.13, 0.045)
	result["terracotta"] = _material("a9847b", 5, Vector2.ONE, 0.010, 0.20, 0.025)
	result["plaster"] = _material("b6aa92", 5, Vector2.ONE, 0.010, 0.20, 0.025)
	result["slate"] = _material("607078", 5, Vector2.ONE, 0.010, 0.20, 0.025)
	result["roof_slate"] = _material("61717b", 3, Vector2(0.45, 0.32), 0.009, 0.30, 0.07)
	result["copper"] = _material("748075", 0)
	result["brass"] = _material("998162", 0)
	result["iron"] = _material("3b353c", 0)
	# Painted cast iron (ADR-027, T6 A/B choice B; docs/Art/2026-10-08-City-Modern-Realism-Props.md Н2–Н3): anchor
	# posts, the pump's body, bench frames, railings and the steam vehicles. `iron` stays for small fittings (hoops,
	# straps, rims), where a near-outline dark is the point.
	result["iron_paint"] = _material("577368", 0)
	result["ink"] = _material("2b2230", 0)
	result["glass"] = _material("4d6b70", 0)
	result["warm_window"] = _material("b79a60", 0)
	result["warm_window"].set_shader_parameter("glow", 0.15)
	result["wood"] = _material("756454", 4, Vector2(0.27, 1.0), 0.009, 0.38, 0.06)
	result["cloth_cream"] = _material("b9ad96", 6, Vector2.ONE, 0.008, 0.15, 0.025)
	result["cloth_red"] = _material("98685e", 6, Vector2.ONE, 0.008, 0.15, 0.025)
	result["cloth_teal"] = _material("617b79", 6, Vector2.ONE, 0.008, 0.15, 0.025)
	result["marker"] = _material("a6b79e", 0)
	return result

static func _material(color: String, kind: int, cell: Vector2 = Vector2.ONE, joint: float = 0.012, ink: float = 0.34, variance: float = 0.05) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("albedo", Color(color))
	material.set_shader_parameter("ink_color", Color("2b2230"))
	material.set_shader_parameter("shadow_tint", Color("b07aa6"))
	material.set_shader_parameter("surface_kind", kind)
	material.set_shader_parameter("cell_metres", cell)
	material.set_shader_parameter("joint_metres", joint)
	material.set_shader_parameter("ink_strength", ink)
	material.set_shader_parameter("variation", variance)
	return material
