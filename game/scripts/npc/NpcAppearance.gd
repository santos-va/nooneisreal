class_name NpcAppearance
extends Node3D
## Versioned, seed-only identity: simulation/occupation never rerolls appearance.
const VERSION := 1
const PALETTE := ["647b70", "8b6554", "646980", "a68155", "725e79", "8f7474"]
const SKIN := ["e0b396", "b98164", "8c5c48", "633f36", "cf9879"]
const TOON = preload("res://shaders/toon.gdshader")
var _arms: Array[Node3D] = []
var _legs: Array[Node3D] = []

static func describe(appearance_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = appearance_seed
	return {"version": VERSION, "seed": appearance_seed,
		"height": rng.randf_range(0.9, 1.12), "width": rng.randf_range(0.88, 1.2),
		"outfit": rng.randi_range(0, 3), "color": rng.randi_range(0, PALETTE.size()-1),
		"skin": rng.randi_range(0, SKIN.size()-1), "hair": rng.randi_range(0, 3),
		"hair_color": rng.randi_range(0, 3), "face": rng.randi_range(0, 2)}

static func build(profile: Dictionary) -> Node3D:
	var visual := NpcAppearance.new()
	visual.name = "Appearance"
	var d := describe(int(profile.get("appearance_seed", 0)))
	visual.set_meta("appearance", d)
	visual.scale = Vector3(d.width, d.height, d.width)
	visual._assemble(d)
	return visual

static func _material(color: Color, texture_path: String = "") -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = TOON
	mat.set_shader_parameter("albedo", color)
	mat.set_shader_parameter("bands", 2.0)
	mat.set_shader_parameter("rim_strength", 0.0)
	mat.set_shader_parameter("shadow_tint", Color("b07aa6"))
	if not texture_path.is_empty():
		mat.set_shader_parameter("albedo_tex", load(texture_path))
	return mat

func _shape(parent: Node3D, label: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.radius = 0.5
	mesh.height = 1.0
	node.mesh = mesh
	node.position = at
	node.scale = size
	node.material_override = material
	parent.add_child(node)
	return node

func _assemble(d: Dictionary) -> void:
	var skin := _material(Color(SKIN[d.skin]), "res://assets/characters/npc/skin_marks.svg")
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

func set_motion(speed: float, time: float) -> void:
	var stride := sin(time * 7.0) * clampf(speed / 1.5, 0.0, 1.0)
	for i in _legs.size():
		var side := 1.0 if i == 0 else -1.0
		_legs[i].rotation.x = stride * side * 0.38
		_arms[i].rotation.x = -stride * side * 0.3

func set_work(kind: String, time: float) -> void:
	# Bounded hand tasks for the existing lightweight residents, separate from gait.
	if _arms.size() < 2:
		return
	var beat: float = sin(time * (3.5 if kind == "workshop" else 1.7))
	_arms[0].rotation.x = -0.65 + beat * (0.38 if kind == "workshop" else 0.12)
	_arms[1].rotation.x = -0.55 - beat * 0.15
	_arms[0].rotation.z = 0.15 + (0.1 * beat if kind == "tailor" else 0.0)
	_arms[1].rotation.z = -0.15
