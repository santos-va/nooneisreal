class_name HeroFacePresentation
extends RefCounted
## Deterministic surface expression. Reads gameplay; never writes bones, hits, resources or RNG.
const Profile = preload("res://scripts/fighter/HeroFaceProfile.gd")
static var _profiles: Dictionary = {}
var profile: Resource
var material: ShaderMaterial
var elapsed: float = 0.0
var closure: Vector2 = Vector2.ZERO
var expression: String = "idle"
var blink_count: int = 0
var mouth_tension: float = 0.0
var brow_tension: float = 0.0
var _last_frame: int = -1
var _last_state: int = -1

static func get_profile(hero_id: String) -> Resource:
	if hero_id not in ["choko", "skea"]:
		return null
	if not _profiles.has(hero_id):
		_profiles[hero_id] = load("res://data/face/" + hero_id + ".tres")
	return _profiles[hero_id]

static func valid_profile(data: Resource) -> bool:
	if data == null or data.get_script() != Profile:
		return false
	if not is_finite(data.atlas_size) or data.atlas_size <= 0.0 or not is_finite(data.blink_interval) or not is_finite(data.blink_seconds) or data.blink_seconds <= 0.0 or data.blink_interval <= data.blink_seconds:
		return false
	for side: String in ["left", "right"]:
		var upper: PackedVector2Array = data.get("upper_" + side)
		var lower: PackedVector2Array = data.get("lower_" + side)
		if upper.size() != 5 or lower.size() != 5 or upper[0] != lower[0] or upper[4] != lower[4]:
			return false
		for point: Vector2 in upper + lower:
			if not point.is_finite() or point.x < 0.0 or point.y < 0.0 or point.x >= data.atlas_size or point.y >= data.atlas_size:
				return false
		if upper[0].distance_to(upper[4]) < 1.0:
			return false
		var direction: Vector2 = (upper[4] - upper[0]).normalized()
		var side_sign: float = signf(direction.cross(lower[2] - upper[2]))
		if side_sign == 0.0:
			return false
		for index: int in range(1,5):
			if direction.dot(upper[index] - upper[index-1]) <= 0.0 or direction.dot(lower[index] - lower[index-1]) <= 0.0:
				return false
		for index: int in range(1,4):
			if signf(direction.cross(lower[index] - upper[index])) != side_sign:
				return false
			if upper[index].distance_to(lower[index]) < 0.25:
				return false
	for region: Vector4 in [data.eye_left, data.eye_right]:
		if not region.is_finite() or region.z <= 0.0 or region.w <= 0.0 or region.x - region.z < 0.0 or region.y - region.w < 0.0 or region.x + region.z > data.atlas_size or region.y + region.w > data.atlas_size:
			return false
	for region: Vector4 in [data.mouth_left, data.mouth_right, data.brow_left, data.brow_right]:
		if region == Vector4.ZERO:
			continue
		if not region.is_finite() or region.z <= 0.0 or region.w <= 0.0 or region.x-region.z < 0.0 or region.y-region.w < 0.0 or region.x+region.z > data.atlas_size or region.y+region.w > data.atlas_size:
			return false
	for sample: Vector2 in [data.ink_left,data.ink_right,data.cheek_left,data.cheek_right,data.eye_skin_left,data.eye_skin_right]:
		if not sample.is_finite() or sample.x < 0.0 or sample.y < 0.0 or sample.x >= data.atlas_size or sample.y >= data.atlas_size:
			return false
	for axis: Vector2 in [data.axis_left, data.axis_right, data.mouth_axis_left, data.mouth_axis_right]:
		if not axis.is_finite() or absf(axis.length() - 1.0) > 0.01:
			return false
	return data.skin_side.is_finite() and absf(data.skin_side.x) == 1.0 and absf(data.skin_side.y) == 1.0 and is_finite(data.focus_close) and data.focus_close >= 0.0 and data.focus_close < 1.0

static func mask_vertex(hero_id: String, _rest: Vector3, uv: Vector2, head_weight: float) -> float:
	var data: Resource = get_profile(hero_id)
	if data == null or not is_finite(head_weight) or head_weight < 0.90 or not uv.is_finite():
		return 0.0
	# Bone-domain admission avoids holes introduced by UV-island/LOD boundaries.
	# Actual color edits remain bounded by the per-feature fragment envelopes.
	return 1.0

func setup(f: Fighter, rig: SkeletalRig) -> void:
	profile = get_profile(f.data.id)
	if not valid_profile(profile) or rig.hero_mesh == null:
		profile = null
		return
	material = rig.hero_mesh.material_override as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("face_atlas_size", profile.atlas_size)
	material.set_shader_parameter("face_eye_left", profile.eye_left)
	material.set_shader_parameter("face_eye_right", profile.eye_right)
	material.set_shader_parameter("face_axis_left", profile.axis_left.normalized())
	material.set_shader_parameter("face_axis_right", profile.axis_right.normalized())
	material.set_shader_parameter("face_skin_side", profile.skin_side)
	for property: String in ["upper_left","lower_left","upper_right","lower_right","eye_skin_left","eye_skin_right","ink_left","ink_right","mouth_left","mouth_right","mouth_axis_left","mouth_axis_right","cheek_left","cheek_right","brow_left","brow_right"]:
		material.set_shader_parameter("face_"+property,profile.get(property))
	reset()

func reset() -> void:
	elapsed = 0.0
	closure = Vector2.ZERO
	mouth_tension = 0.0
	brow_tension = 0.0
	expression = "idle"
	blink_count = 0
	_last_frame = -1
	_last_state = -1
	apply()

func update(f: Fighter, delta: float, serial: int) -> void:
	if profile == null or serial == _last_frame or not is_finite(delta) or delta < 0.0:
		return
	_last_frame = serial
	if f.get_tree().paused or f.frozen_frames > 0 or f.hitstop_frames > 0:
		return
	if f.state == Fighter.State.INTRO and _last_state != Fighter.State.INTRO:
		elapsed = 0.0
	_last_state = f.state
	elapsed += delta
	var previous_blinks: int = blink_count
	blink_count = int(elapsed / profile.blink_interval)
	var phase: float = fposmod(elapsed, profile.blink_interval)
	var blink: float = 0.0
	if phase < profile.blink_seconds and (blink_count > 0 or previous_blinks > 0):
		blink = sin(PI * phase / profile.blink_seconds)
	mouth_tension = 0.0
	brow_tension = 0.0
	closure = Vector2.ONE * blink
	expression = "blink" if blink > 0.01 else "idle"
	if f.state == Fighter.State.KO:
		closure = Vector2.ONE
		mouth_tension = 0.95
		brow_tension = -0.3
		expression = "ko"
	elif f.state in [Fighter.State.HITSTUN, Fighter.State.STUMBLE, Fighter.State.LAUNCHED, Fighter.State.KNOCKDOWN, Fighter.State.WALL_SPLAT]:
		closure = Vector2(0.96, 0.78)
		mouth_tension = 0.65
		brow_tension = -0.8
		expression = "hurt"
	elif f.state in [Fighter.State.ATTACK, Fighter.State.BLOCK, Fighter.State.BLOCKSTUN, Fighter.State.GRAPPLE]:
		closure = closure.max(Vector2.ONE * profile.focus_close)
		mouth_tension = 0.14
		brow_tension = 1.0
		expression = "focus"
	apply()

func apply() -> void:
	if material != null:
		material.set_shader_parameter("face_closure", closure)
		material.set_shader_parameter("face_mouth_tension", mouth_tension)
		material.set_shader_parameter("face_brow_tension", brow_tension)
