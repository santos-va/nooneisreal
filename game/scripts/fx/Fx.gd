class_name Fx
extends RefCounted
## Shared helpers for presentation-only effects. Nothing here decides a hit.


static func root(n: Node) -> Node:
	var cs := n.get_tree().current_scene
	if cs != null and cs.has_node("FX"):
		return cs.get_node("FX")
	return cs if cs != null else n.get_parent()


static func mat(color: Color, additive: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = color
	return m


static func mesh(m: Mesh, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Anime "on twos/fours": fade in discrete steps instead of smoothly.
static func stepped(k: float, steps: int = 4) -> float:
	return ceilf(clampf(k, 0.0, 1.0) * float(steps)) / float(steps)
