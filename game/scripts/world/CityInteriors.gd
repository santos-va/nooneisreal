class_name CityInteriors
extends CityMarket
## Walk-in shops: collidable shell, broad clear aisles and reused batched market kit.
const Places = preload("res://scripts/world/CityPlaces.gd")

func _ready() -> void:
	name = "CityInteriors"
	_materials = CityMaterials.palette()
	for key: String in _materials:
		_materials[key].set_shader_parameter("painted_fill", 0.28)
		_materials[key].set_shader_parameter("key_gain", 1.65)
	for shop: Dictionary in Places.shops():
		_shop(shop)
	_street_furniture()
	_flush_batches()

func _shop(shop: Dictionary) -> void:
	var pose := Transform3D(Basis.IDENTITY, shop.door)
	var accent: String = ["cloth_teal", "cloth_red", "copper"][int(shop.npc_index)]
	var floor_material: String = "stone" if shop.id == "grocer" else "wood"
	# No single box crosses the doorway. Side/back walls join the retained upper storey.
	_box(pose, Vector3(-3.3, 2, 4), Vector3(0.2, 4, 8), "plaster", "ShopWall")
	_box(pose, Vector3(3.3, 2, 4), Vector3(0.2, 4, 8), "plaster", "ShopWall")
	_box(pose, Vector3(0, 2, 7.9), Vector3(6.6, 4, 0.2), "plaster", "ShopBack")
	_box(pose, Vector3(0, 3.6, 0), Vector3(6.6, 0.8, 0.3), accent, "ShopLintel")
	for side: float in [-1.0, 1.0]:
		# Open display bays above a low wall; centre opening remains 2.4m wide.
		_box(pose, Vector3(side * 2.25, 0.47, 0), Vector3(2.1, 0.94, 0.28), accent, "ShopWindowBase")
		_box(pose, Vector3(side * 3.1, 2.1, 0), Vector3(0.18, 2.2, 0.25), "wood", "ShopJamb")
		_box(pose, Vector3(side * 1.26, 1.6, -0.02), Vector3(0.12, 3.2, 0.34), "wood", "DoorJamb")
		_box(pose, Vector3(side * 2.2, 2.15, 0), Vector3(0.06, 2.4, 0.08), "brass")
		_box(pose, Vector3(side * 2.2, 2.5, 0), Vector3(1.8, 0.06, 0.08), "brass")
	_box(pose, Vector3(0, 0.003, 4), Vector3(6.3, 0.006, 7.7), floor_material)
	_box(pose, Vector3(0, 3.85, -0.52), Vector3(6.5, 0.18, 1.15), accent, "ShopAwning")
	_box(pose, Vector3(0, 3.65, -1.04), Vector3(6.5, 0.3, 0.11), "cloth_cream")
	_sign(pose * Vector3(0, 3.56, -1.11), shop.title, 0.0067)
	# Trim, beams and a welcome mat provide scale without obstructing body clearance.
	_box(pose, Vector3(0, 0.012, 1.15), Vector3(2.1, 0.02, 1.25), accent)
	for z: float in [1.8, 5.3, 7.6]:
		_box(pose, Vector3(0, 3.83, z), Vector3(6.45, 0.26, 0.2), "wood")
	for side: float in [-1.0, 1.0]:
		_box(pose, Vector3(side * 3.16, 0.2, 4), Vector3(0.07, 0.4, 7.7), "wood")
	_counter(pose.translated_local(Vector3(-0.2, 0, 5.6)), accent)
	_shelf(pose.translated_local(Vector3(-2.82, 0, 4.2)).rotated_local(Vector3.UP, PI * 0.5), shop.id)
	_shelf(pose.translated_local(Vector3(-0.8, 0, 7.48)), shop.id)
	_lantern(pose * Vector3(0, 3.08, 3), 0.9)
	_rod(pose * Vector3(0, 3.8, 3), pose * Vector3(0, 3.36, 3), 0.025, "iron")
	var lamp := OmniLight3D.new()
	lamp.position = pose * Vector3(0, 2.9, 3.7)
	lamp.light_color = Color("f7d2a0")
	lamp.light_energy = 0.24
	lamp.omni_range = 5.2
	lamp.shadow_enabled = false
	add_child(lamp)
	match String(shop.id):
		"grocer": _grocer(pose)
		"tailor": _tailor(pose)
		"workshop": _workshop(pose)
	var marker := Marker3D.new()
	marker.name = "Shop_" + String(shop.id)
	marker.position = shop.visit
	marker.set_meta("shop_id", shop.id)
	marker.set_meta("walk_in", true)
	add_child(marker)

func _counter(pose: Transform3D, accent: String) -> void:
	_box(pose, Vector3(0, 0.48, 0), Vector3(3.6, 0.96, 0.86), accent, "ShopCounter")
	_box(pose, Vector3(0, 1.01, 0), Vector3(3.85, 0.12, 1.04), "wood")
	for x: float in [-1.65, -0.55, 0.55, 1.65]:
		_box(pose, Vector3(x, 0.47, -0.445), Vector3(0.055, 0.85, 0.045), "brass")
	_box(pose, Vector3(1.18, 1.24, 0), Vector3(0.4, 0.34, 0.36), "iron")
	_box(pose, Vector3(1.18, 1.43, -0.035), Vector3(0.28, 0.1, 0.22), "brass")

func _shelf(pose: Transform3D, kind: String) -> void:
	for x: float in [-1.15, 1.15]:
		_box(pose, Vector3(x, 1.25, 0), Vector3(0.09, 2.5, 0.55), "wood")
	for level: int in 3:
		var y: float = 0.42 + float(level) * 0.71
		_box(pose, Vector3(0, y, 0), Vector3(2.4, 0.09, 0.55), "wood")
		for item: int in 5:
			var at := Vector3(-0.92 + float(item) * 0.46, y + 0.055, 0)
			if kind == "grocer":
				if level == 0:
					_cylinder(pose, at + Vector3(0, 0.16, 0), 0.14, 0.18, 0.32, "cloth_cream")
					_cylinder(pose, at + Vector3(0, 0.33, 0), 0.1, 0.14, 0.04, "wood")
				elif level == 1:
					_jar(pose.translated_local(at), "terracotta" if item % 2 == 0 else "cloth_teal", 0.52)
				else:
					_loaf(pose.translated_local(at + Vector3(0, 0.13, 0)), 0.72)
			elif kind == "tailor":
				_cylinder(pose, at + Vector3(0, 0.21, 0), 0.16, 0.16, 0.42, ["cloth_red", "cloth_teal", "cloth_cream"][item % 3])
			else:
				_cylinder(pose, at + Vector3(0, 0.12, 0), 0.13, 0.13, 0.24, "copper" if item % 2 else "brass")
	# One broad collider prevents walking through the shelves, without tiny collision clutter.
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 2.5, 0.55)
	_solid("StockShelf", pose.translated_local(Vector3(0, 1.25, 0)), shape)

func _grocer(pose: Transform3D) -> void:
	for side: float in [-1.0, 1.0]:
		var display := pose.translated_local(Vector3(side * 2.25, 0, 0.62))
		_crate(display, Vector3(1.25, 0.8, 0.85))
		for i: int in 6:
			var fruit := SphereMesh.new()
			fruit.radius = 0.13
			fruit.height = 0.23
			fruit.radial_segments = 8
			fruit.rings = 4
			_primitive(fruit, display.translated_local(Vector3(-0.4 + float(i % 3) * 0.4, 0.88, -0.2 + float(i / 3) * 0.36)), "cloth_red" if side < 0 else "marker")
	_barrel(pose.translated_local(Vector3(2.65, 0, 3)))
	_box(pose, Vector3(-0.6, 1.085, 5.55), Vector3(1.8, 0.035, 0.82), "cloth_cream")
	for index: int in 3:
		_loaf(pose.translated_local(Vector3(-1.2 + float(index) * 0.55, 1.21, 5.55)), 0.85)
	_jar(pose.translated_local(Vector3(0.5, 1.07, 5.6)), "cloth_teal", 0.7)
	# A wall herb rack gives the otherwise clear aisle a readable shop-specific silhouette.
	_box(pose, Vector3(3.04, 1.78, 3.35), Vector3(0.3, 0.08, 2.35), "wood")
	for index: int in 4:
		var z: float = 2.5 + float(index) * 0.55
		_jar(pose.translated_local(Vector3(2.97, 1.83, z)), "terracotta", 0.55)
		for sprig: int in 3:
			_cylinder(pose, Vector3(2.97, 2.35 + float(sprig % 2) * 0.12, z + float(sprig - 1) * 0.08), 0, 0.14, 0.46, "marker", 5)
	_sign(pose * Vector3(0, 2.7, 7.73), "ХЛІБ · ТРАВИ · ПРИПАСИ", 0.006)

func _loaf(pose: Transform3D, size: float) -> void:
	var bread := CapsuleMesh.new()
	bread.radius = 0.14 * size
	bread.height = 0.5 * size
	bread.radial_segments = 8
	bread.rings = 3
	_primitive(bread, pose.rotated_local(Vector3.FORWARD, PI * 0.5), "brass")
	for index: int in 3:
		_box(pose, Vector3(float(index - 1) * 0.11 * size, 0.133 * size, 0), Vector3(0.025, 0.014, 0.19) * size, "cloth_cream")

func _tailor(pose: Transform3D) -> void:
	# Dress form and a cloth cutting table distinguish this from a food counter.
	_cylinder(pose, Vector3(2.2, 0.08, 1), 0.4, 0.48, 0.16, "iron")
	_cylinder(pose, Vector3(2.2, 0.7, 1), 0.055, 0.055, 1.25, "brass")
	_cylinder(pose, Vector3(2.2, 1.36, 1), 0.25, 0.37, 0.85, "cloth_red")
	_cylinder(pose, Vector3(2.2, 1.86, 1), 0.1, 0.25, 0.2, "cloth_red")
	_table(pose.translated_local(Vector3(2.15, 0, 3.2)), Vector2(1.2, 1.8), "cloth_cream")
	_box(pose, Vector3(2.16, 1.04, 3.15), Vector3(0.8, 0.035, 1.3), "cloth_teal")
	for i: int in 3:
		_box(pose, Vector3(-0.85 + float(i) * 0.52, 1.1 + float(i) * 0.035, 5.6), Vector3(0.42, 0.06, 0.62), ["cloth_red", "cloth_teal", "cloth_cream"][i])
	_sign(pose * Vector3(0, 2.7, 7.73), "КРІЙ · РЕМОНТ · ТКАНИНИ", 0.006)

func _workshop(pose: Transform3D) -> void:
	_table(pose.translated_local(Vector3(2.3, 0, 3.2)), Vector2(1.05, 1.8), "wood")
	# Workbench vise, hanging tools, clock parts and a waiting stool.
	_box(pose, Vector3(2.3, 1.22, 3.2), Vector3(0.5, 0.28, 0.4), "iron")
	_rod(pose * Vector3(2, 1.28, 3.2), pose * Vector3(2.65, 1.28, 3.2), 0.035, "brass")
	for i: int in 4:
		var z: float = 2.45 + float(i) * 0.52
		_box(pose, Vector3(3.08, 2.1, z), Vector3(0.07, 0.62, 0.06), "wood")
		_box(pose, Vector3(3.03, 2.39, z), Vector3(0.16, 0.14, 0.33), "iron")
	for i: int in 3:
		var wheel := TorusMesh.new()
		wheel.inner_radius = 0.13 + float(i) * 0.02
		wheel.outer_radius = wheel.inner_radius + 0.065
		wheel.rings = 12
		wheel.ring_segments = 4
		_primitive(wheel, pose.translated_local(Vector3(-1.25 + float(i) * 0.65, 1.12, 5.6)), "brass")
	_stool(pose.translated_local(Vector3(-2.2, 0, 1.15)))
	_sign(pose * Vector3(0, 2.7, 7.73), "ГОДИННИКИ · МЕХАНІЗМИ", 0.006)

func _table(pose: Transform3D, size: Vector2, material: String) -> void:
	_box(pose, Vector3(0, 0.94, 0), Vector3(size.x, 0.12, size.y), material)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			_box(pose, Vector3(x * (size.x * 0.5 - 0.12), 0.45, z * (size.y * 0.5 - 0.12)), Vector3(0.1, 0.9, 0.1), "wood")
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 1, size.y)
	_solid("WorkTable", pose.translated_local(Vector3(0, 0.5, 0)), shape)

func _stool(pose: Transform3D) -> void:
	_cylinder(pose, Vector3(0, 0.55, 0), 0.35, 0.35, 0.12, "wood")
	for i: int in 3:
		var angle: float = float(i) * TAU / 3.0
		_box(pose, Vector3(sin(angle) * 0.23, 0.26, cos(angle) * 0.23), Vector3(0.09, 0.52, 0.09), "wood")
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = 0.62
	_solid("WaitingStool", pose.translated_local(Vector3(0, 0.31, 0)), shape)

func _sign(at: Vector3, text: String, pixel_size: float, yaw: float = PI) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.rotation.y = yaw
	label.font_size = 48
	label.pixel_size = pixel_size
	label.modulate = Color("e7d7af")
	label.outline_modulate = Color("2b2230")
	label.outline_size = 6
	label.no_depth_test = false
	label.double_sided = false
	add_child(label)

func _street_furniture() -> void:
	# Wayfinding is visible from the player's south market approach; shop fronts face north.
	var guide := Transform3D(Basis.IDENTITY, Vector3(-5.7, 0, 13.7))
	_box(guide, Vector3(0, 1.9, 0), Vector3(0.13, 3.8, 0.13), "iron", "WayfindingPost")
	_box(guide, Vector3(0, 3.35, 0), Vector3(3.3, 0.58, 0.14), "cloth_teal")
	_sign(guide * Vector3(0, 3.35, 0.085), "КРАМНИЦІ  ←", 0.0065, 0.0)
	_box(guide, Vector3(0, 2.7, 0), Vector3(3.3, 0.5, 0.14), "wood")
	_sign(guide * Vector3(0, 2.7, 0.085), "ВЕЖА · МІСТ  ↑", 0.0056, 0.0)
	# Backed wall notices add identity without placing scenery in walkable aisles.
	for shop: Dictionary in Places.shops():
		var at: Vector3 = shop.door + Vector3(0, 2.72, 7.77)
		_box(Transform3D.IDENTITY, at + Vector3(0, 0, 0.04), Vector3(3.7, 0.58, 0.06), "wood")
	# A rest corner beside the west court preserves its five-metre playable circle.
	for x: float in [-24.5, -14.0]:
		var pose := Transform3D(Basis.IDENTITY, Vector3(x, 0, 8))
		_box(pose, Vector3(0, 0.5, 0), Vector3(2.4, 0.14, 0.7), "wood", "StreetBench")
		_box(pose, Vector3(0, 1, 0.28), Vector3(2.4, 0.62, 0.13), "wood", "BenchBack")
		for side: float in [-1.0, 1.0]:
			_box(pose, Vector3(side * 0.92, 0.22, 0), Vector3(0.13, 0.44, 0.55), "iron")
			_cylinder(pose, Vector3(side * 1.75, 0.3, 0), 0.4, 0.29, 0.6, "terracotta")
			for sprig: int in 3:
				_cylinder(pose, Vector3(side * 1.75 + float(sprig - 1) * 0.15, 0.85, 0), 0.0, 0.22, 0.7, "marker", 5)
