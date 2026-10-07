class_name QualityProfile
extends Resource
## PLACEHOLDER presentation presets; no device performance claim or gameplay budget.

@export var id: String = "high"
@export var render_scale: float = 1.0
@export var msaa: int = Viewport.MSAA_4X
## Lethal-fight blood budget (docs/Art/2026-10-07-Blood-Visual-Language.md § Профілі якості, PLACEHOLDER counts).
## The defaults are High: every drop, rims on, 16 floor stains a fight. Never a gameplay budget.
@export var blood_drops: float = 1.0       # share of a splash's drops that spawn
@export var blood_size: float = 1.0        # drop size multiplier (Low: fewer but larger)
@export var blood_rim: bool = true         # ink rim on splash drops (floor stains and the puddle always keep it)
@export var blood_floor_limit: int = 16    # floor drops alive in one fight; the oldest gives way

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
			profile.blood_drops = 0.25
			profile.blood_size = 1.6
			profile.blood_rim = false
			profile.blood_floor_limit = 6
		"medium":
			profile.render_scale = 0.85
			profile.msaa = Viewport.MSAA_2X
			profile.blood_drops = 0.5
			profile.blood_floor_limit = 10
	return profile

func apply_to(viewport: Viewport) -> void:
	viewport.scaling_3d_scale = render_scale
	viewport.msaa_3d = msaa
