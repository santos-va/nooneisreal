class_name NpcAppearance
extends Node3D
## Versioned, seed-only identity: simulation/occupation never rerolls appearance.
const VERSION := 1
const PALETTE := ["647b70", "8b6554", "646980", "a68155", "725e79", "8f7474"]
const SKIN := ["e0b396", "b98164", "8c5c48", "633f36", "cf9879"]
const TOON = preload("res://shaders/toon.gdshader")
var _arms: Array[Node3D] = []
var _legs: Array[Node3D] = []
static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}
var _head: Node3D
var _gesture := ""
var _gesture_start := 0.0
var _clock := 0.0
var _work_prop: Node3D
var _blend_arms: Array[Vector3] = []
var _blend_head := Vector3.ZERO
var _work_resume_start := -100.0
const GESTURE_SECONDS := 1.4

static func describe(appearance_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = appearance_seed
	var identity := {"version": VERSION, "seed": appearance_seed,
		"height": rng.randf_range(0.9, 1.12), "width": rng.randf_range(0.88, 1.2),
		"outfit": rng.randi_range(0, 3), "color": rng.randi_range(0, PALETTE.size()-1),
		"skin": rng.randi_range(0, SKIN.size()-1), "hair": rng.randi_range(0, 3),
		"hair_color": rng.randi_range(0, 3), "face": rng.randi_range(0, 2)}
	# Append presentation traits after the legacy draws; never reroll saved identity.
	identity["phenotype"] = ["fox", "moth", "stone"][posmod(appearance_seed, 3)]
	identity["presentation_version"] = 2
	return identity

static func build(profile: Dictionary) -> Node3D:
	var visual := NpcAppearance.new()
	visual.name = "Appearance"
	var d := describe(int(profile.get("appearance_seed", 0)))
	visual.set_meta("appearance", d)
	visual.scale = Vector3(d.width, d.height, d.width)
	visual._assemble(d)
	return visual

static func _material(color: Color, texture_path: String = "") -> ShaderMaterial:
	var key := color.to_html() + ":" + texture_path
	if _materials.has(key): return _materials[key]
	var mat := ShaderMaterial.new()
	mat.shader = TOON
	mat.set_shader_parameter("albedo", color)
	mat.set_shader_parameter("bands", 2.0)
	mat.set_shader_parameter("rim_strength", 0.0)
	mat.set_shader_parameter("shadow_tint", Color("b07aa6"))
	if not texture_path.is_empty():
		mat.set_shader_parameter("albedo_tex", load(texture_path))
	_materials[key] = mat
	return mat

func _shape(parent: Node3D, label: String, at: Vector3, size: Vector3, material: Material, form: String = "round") -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.set_meta("head_detail", label.begins_with("Head") or label.begins_with("Nose") or label.begins_with("Eye") or label.begins_with("Brow") or label.begins_with("Ear") or label.begins_with("Mouth") or label.begins_with("Hair") or label.begins_with("LongHair") or label.begins_with("Moustache") or label.begins_with("Crown") or label.begins_with("Antenna") or label.begins_with("Muzzle"))
	if not _meshes.has(form):
		if form == "wedge":
			var wedge := PrismMesh.new()
			wedge.size = Vector3.ONE
			_meshes[form] = wedge
		elif form == "box":
			var box := BoxMesh.new()
			box.size = Vector3.ONE
			_meshes[form] = box
		else:
			var sphere := SphereMesh.new()
			sphere.radial_segments = 8
			sphere.rings = 4
			sphere.radius = 0.5
			sphere.height = 1.0
			_meshes[form] = sphere
	node.mesh = _meshes[form]
	node.position = at
	node.scale = size
	node.material_override = material
	parent.add_child(node)
	return node

func _assemble(d: Dictionary) -> void:
	var skin_color := Color(SKIN[d.skin]) if d.phenotype == "fox" else Color("bbb7b0" if d.phenotype == "moth" else "8d9d9b")
	var skin := _material(skin_color, "res://assets/characters/npc/skin_marks.svg")
	var ink := _material(Color("2b2230"))
	var cloth := _material(Color(PALETTE[d.color]), "res://assets/characters/npc/knit_stripes.svg" if d.outfit == 1 else "res://assets/characters/npc/workwear_seams.svg")
	var pants := _material(Color("464353"))
	var hair := _material(Color(["342a30", "674738", "ae8460", "aaa09e"][d.hair_color]))
	_shape(self, "Hips", Vector3(0, 0.86, 0), Vector3(0.4, 0.3, 0.28), pants)
	_shape(self, "Torso", Vector3(0, 1.17, 0), Vector3(0.48, 0.6, 0.3), cloth)
	_shape(self, "Neck", Vector3(0, 1.48, 0), Vector3(0.14, 0.18, 0.14), skin)
	_shape(self, "Head", Vector3(0, 1.68, 0), Vector3(0.32, 0.39, 0.3), skin)
	_shape(self, "Nose", Vector3(0, 1.65, -0.158), Vector3(0.065, 0.075, 0.07), skin)
	for side in [-1.0, 1.0]:
		_shape(self, "Eye", Vector3(side*0.064, 1.71, -0.141), Vector3(0.035, 0.021, 0.027), ink)
		_shape(self, "Brow", Vector3(side*0.064, 1.75, -0.134), Vector3(0.07, 0.019, 0.025), hair)
		_shape(self, "Ear", Vector3(side*0.165, 1.68, 0), Vector3(0.055, 0.09, 0.045), skin)
		_shape(self, "Shoulder", Vector3(side*0.205, 1.36, 0), Vector3(0.21, 0.24, 0.24), cloth)
		var arm := Node3D.new()
		arm.position = Vector3(side*0.26, 1.38, 0)
		add_child(arm)
		_arms.append(arm)
		_shape(arm, "Sleeve", Vector3(side*0.025, -0.16, 0), Vector3(0.17, 0.39, 0.18), cloth)
		_shape(arm, "Forearm", Vector3(side*0.025, -0.39, -0.025), Vector3(0.115, 0.25, 0.12), skin)
		_shape(arm, "Hand", Vector3(side*0.025, -0.53, -0.04), Vector3(0.13, 0.17, 0.085), skin)
		var leg := Node3D.new()
		leg.position = Vector3(side*0.115, 0.88, 0)
		add_child(leg)
		_legs.append(leg)
		_shape(leg, "Trouser", Vector3(0, -0.36, 0), Vector3(0.18, 0.74, 0.2), pants)
		_shape(leg, "Boot", Vector3(0, -0.78, -0.07), Vector3(0.22, 0.2, 0.36), ink)
	_shape(self, "Mouth", Vector3(0, 1.585, -0.135), Vector3(0.08, 0.013, 0.016), ink)
	if d.hair != 0:
		_shape(self, "HairCap", Vector3(0, 1.83, 0.015), Vector3(0.35, 0.19, 0.32), hair)
		if d.hair == 2:
			_shape(self, "HairBun", Vector3(0, 1.87, 0.17), Vector3(0.19, 0.2, 0.18), hair)
		if d.hair == 3:
			_shape(self, "LongHair", Vector3(0, 1.6, 0.095), Vector3(0.37, 0.45, 0.22), hair)
	if d.face == 1:
		_shape(self, "Moustache", Vector3(0, 1.61, -0.154), Vector3(0.13, 0.028, 0.024), hair)
	if d.outfit == 0:
		_shape(self, "CoatSkirt", Vector3(0, 0.88, 0.02), Vector3(0.54, 0.44, 0.36), cloth)
	elif d.outfit == 2:
		_shape(self, "Apron", Vector3(0, 0.98, -0.148), Vector3(0.35, 0.65, 0.055), _material(Color("c7b597"), "res://assets/characters/npc/workwear_seams.svg"))
	elif d.outfit == 3:
		var scarf := _material(Color("ba775d"))
		_shape(self, "Scarf", Vector3(0, 1.44, 0), Vector3(0.31, 0.14, 0.33), scarf)
		_shape(self, "ScarfTail", Vector3(0.11, 1.2, -0.18), Vector3(0.1, 0.43, 0.05), scarf)

	_fantasy_details(d, skin, cloth, ink)
	_head = Node3D.new()
	_head.name = "HeadPivot"
	_head.position = Vector3(0, 1.48, 0)
	add_child(_head)
	for child in get_children():
		if child is MeshInstance3D and child.get_meta("head_detail", false):
			var old_position: Vector3 = child.position
			remove_child(child)
			_head.add_child(child)
			child.position = old_position - _head.position

func _fantasy_details(d: Dictionary, skin: Material, cloth: Material, ink: Material) -> void:
	var cream := _material(Color("dbc6a0"))
	var leather := _material(Color("775541"))
	# Shared tailoring language: front placket, belt and buckle.
	_shape(self, "CoatPlacket", Vector3(0, 1.18, -0.151), Vector3(0.032, 0.46, 0.026), cream, "box")
	_shape(self, "Belt", Vector3(0, 0.91, 0), Vector3(0.43, 0.06, 0.31), leather, "box")
	_shape(self, "Buckle", Vector3(0, 0.92, -0.17), Vector3(0.065, 0.07, 0.025), cream, "box")
	if d.phenotype == "fox":
		for side in [-1.0, 1.0]:
			_shape(self, "CrownEar", Vector3(side*0.125, 1.96, 0), Vector3(0.17, 0.37, 0.12), skin, "wedge").rotation.z = -side*0.16
			_shape(self, "CrownEarInset", Vector3(side*0.125, 1.97, -0.062), Vector3(0.095, 0.22, 0.014), cream, "wedge").rotation.z = -side*0.16
		_shape(self, "Muzzle", Vector3(0, 1.63, -0.20), Vector3(0.22, 0.14, 0.17), cream)
		_shape(self, "MuzzleTip", Vector3(0, 1.67, -0.29), Vector3(0.075, 0.055, 0.055), ink)
		_shape(self, "Tail", Vector3(0.15, 0.69, 0.30), Vector3(0.20, 0.59, 0.24), skin).rotation.x = -0.65
		_shape(self, "TailTip", Vector3(0.15, 0.49, 0.47), Vector3(0.18, 0.23, 0.20), cream).rotation.x = -0.65
		_shape(self, "Satchel", Vector3(-0.25, 0.85, 0.035), Vector3(0.17, 0.27, 0.27), leather, "box")
	elif d.phenotype == "moth":
		for side in [-1.0, 1.0]:
			_shape(self, "AntennaStem", Vector3(side*0.105, 1.97, 0), Vector3(0.035, 0.26, 0.04), ink).rotation.z = -side*0.35
			_shape(self, "AntennaTip", Vector3(side*0.15, 2.08, 0), Vector3(0.10, 0.09, 0.07), cream)
			_shape(self, "FoldedWing", Vector3(side*0.23, 1.10, 0.22), Vector3(0.37, 0.90, 0.13), cloth, "wedge").rotation.z = -side*0.22
			_shape(self, "WingSpot", Vector3(side*0.25, 1.18, 0.30), Vector3(0.13, 0.21, 0.025), cream)
		_shape(self, "Ruff", Vector3(0, 1.44, 0), Vector3(0.43, 0.17, 0.37), cream)
	else:
		for side in [-1.0, 1.0]:
			_shape(self, "CrownFacet", Vector3(side*0.125, 1.76, 0.025), Vector3(0.17, 0.27, 0.27), skin, "wedge")
			_shape(self, "ShoulderPlate", Vector3(side*0.23, 1.39, 0), Vector3(0.26, 0.17, 0.29), skin, "wedge")
			_shape(_arms[0 if side < 0 else 1], "Cuff", Vector3(side*0.025, -0.39, -0.025), Vector3(0.16, 0.12, 0.16), leather, "box")
		_shape(self, "SmithApron", Vector3(0, 0.98, -0.185), Vector3(0.37, 0.62, 0.04), _material(Color("775541"), "res://assets/characters/npc/workwear_seams.svg"), "box")
		_shape(self, "ApronPocket", Vector3(.06, .94, -.212), Vector3(.18,.17,.012), _material(Color("a38165")), "box")
		_shape(self, "ApronPocketSeam", Vector3(.06, 1.02, -.22), Vector3(.18,.012,.012), cream, "box")
		for side in [-1.0, 1.0]:
			_shape(self, "CrownCheek", Vector3(side*.13,1.62,-.11), Vector3(.10,.09,.12), _material(Color("687e7d")), "wedge")

func interaction_radius() -> float:
	return 0.30 * maxf(scale.x, scale.z)

func presentation_event(kind: String) -> void:
	if kind not in ["greet", "listen", "talk", "agree", "goodbye"]: return
	_blend_arms.clear()
	for arm in _arms: _blend_arms.append(arm.rotation)
	_blend_head = _head.rotation
	_gesture = kind
	_gesture_start = _clock

func set_motion(speed: float, time: float) -> void:
	_clock = time
	var stride := sin(time * 7.0) * clampf(speed / 1.5, 0.0, 1.0)
	for i in _legs.size():
		var side := 1.0 if i == 0 else -1.0
		_legs[i].rotation = Vector3(stride * side * 0.38, 0, 0)
		_arms[i].rotation = Vector3(-stride * side * 0.3, 0, 0)
	_head.rotation = Vector3.ZERO
	if is_instance_valid(_work_prop): _work_prop.visible = _gesture.is_empty() and speed < .1
	if _gesture.is_empty(): return
	var t := maxf(0, time - _gesture_start)
	if t >= GESTURE_SECONDS:
		_gesture = ""
		_work_resume_start = time
		return
	var envelope := minf(t / 0.18, minf(1.0, (GESTURE_SECONDS-t) / 0.25))
	match _gesture:
		"greet", "goodbye":
			_arms[1].rotation = Vector3(2.1, 0, 0.55 + sin(t*15)*0.17) * envelope
		"talk":
			_arms[0].rotation = Vector3(0.85+sin(t*9)*0.16, 0, 0.25) * envelope
			_arms[1].rotation = Vector3(0.65-sin(t*9)*0.14, 0, -0.23) * envelope
		"listen": _head.rotation.z = 0.12 * envelope
		"agree": _head.rotation.x = sin(t*10) * 0.16 * envelope
	# Dialogue can interrupt at any point: begin from the displayed pose, never a reset pose.
	var blend := smoothstep(0.0, 0.18, t)
	for i in _arms.size():
		_arms[i].rotation = _blend_arms[i].lerp(_arms[i].rotation, blend)
	_head.rotation = _blend_head.lerp(_head.rotation, blend)

func set_work(kind: String, time: float) -> void:
	if not _gesture.is_empty() or _arms.size() < 2: return
	if not is_instance_valid(_work_prop):
		_work_prop = Node3D.new()
		_work_prop.name = "HeldWork"
		_work_prop.position = Vector3(0, -0.53, -0.07)
		_arms[0].add_child(_work_prop)
		var cream := _material(Color("dbc6a0"))
		var leather := _material(Color("775541"))
		if kind == "grocer":
			_shape(_work_prop, "Parcel", Vector3.ZERO, Vector3(.24,.15,.18), cream, "box")
			_shape(_work_prop, "ParcelString", Vector3(0,0,-.095), Vector3(.018,.16,.01), leather, "box")
		elif kind == "tailor":
			_shape(_work_prop, "FoldedCloth", Vector3.ZERO, Vector3(.24,.06,.20), _material(Color("ba775d")), "box")
			_shape(_work_prop, "ClothHem", Vector3(0,-.02,-.10), Vector3(.24,.02,.01), cream, "box")
		else:
			_shape(_work_prop, "ToolHandle", Vector3.ZERO, Vector3(.045,.25,.045), leather, "box")
			_shape(_work_prop, "ToolHead", Vector3(0,-.12,0), Vector3(.18,.09,.09), _material(Color("8d9d9b")), "box")
	_work_prop.show()
	var beat: float = sin(time * (3.5 if kind == "workshop" else 1.7))
	_arms[0].rotation = Vector3(0.65 + beat * (0.38 if kind == "workshop" else 0.12), 0, 0.15 + (0.1 * beat if kind == "tailor" else 0.0))
	_arms[1].rotation = Vector3(0.55 - beat * 0.15, 0, -0.15)
	var resume_weight := smoothstep(0.0, 0.18, time - _work_resume_start)
	for arm in _arms: arm.rotation *= resume_weight
