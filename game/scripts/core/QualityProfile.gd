class_name QualityProfile
extends Resource
## PLACEHOLDER presentation presets; no device performance claim or gameplay budget.

@export var id: String = "high"
@export var render_scale: float = 1.0
@export var msaa: int = Viewport.MSAA_4X

static func ids() -> Array[String]:
	return ["low", "medium", "high"]

static func make(value: Variant) -> QualityProfile:
	if not value is String or not ids().has(value):
		return null
	var profile := QualityProfile.new()
	profile.id = value
	match value:
		"low":
			profile.render_scale = 0.75
			profile.msaa = Viewport.MSAA_DISABLED
		"medium":
			profile.render_scale = 0.85
			profile.msaa = Viewport.MSAA_2X
	return profile

func apply_to(viewport: Viewport) -> void:
	viewport.scaling_3d_scale = render_scale
	viewport.msaa_3d = msaa
