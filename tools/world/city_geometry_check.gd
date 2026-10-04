extends SceneTree
## Physical probes: route support, body clearance, cover and genuine openings.
const Layout = preload("res://scripts/world/CityLayout.gd")
var checks: int = 0
var failures: int = 0
var district: Node3D
var space: PhysicsDirectSpaceState3D

func _initialize() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("CITY_GEOMETRY: " + message)

func _ray(from: Vector3, to: Vector3, mask: int = 1) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, mask))

func _clear_body(feet: Vector3) -> bool:
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, feet + Vector3(0, 0.96, 0))
	query.collision_mask = 1
	return space.intersect_shape(query, 1).is_empty()

func _probe(feet: Vector3, description: String) -> void:
	var hit: Dictionary = _ray(feet + Vector3.UP * 0.45, feet - Vector3.UP * 0.45)
	_expect(not hit.is_empty(), description + " has support")
	if not hit.is_empty():
		_expect(absf(float(hit.position.y) - feet.y) < 0.06, description + " support height")
	_expect(_clear_body(feet), description + " body clearance")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/world/CityDistrict.tscn") as PackedScene
	district = packed.instantiate() as Node3D
	root.add_child(district)
	await physics_frame
	await physics_frame
	space = district.get_world_3d().direct_space_state
	var authored: Dictionary = district.get_meta("architecture_authored_triangles")
	var rendered: Dictionary = district.get_meta("architecture_rendered_triangles")
	for key: String in authored:
		_expect(authored[key] == rendered[key], "architecture mixed batch retains all " + key + " triangles")
	var market: Node = district.get_node("CityMarket")
	var market_authored: Dictionary = market.get_meta("authored_triangles")
	var market_rendered: Dictionary = market.get_meta("rendered_triangles")
	_expect(market_authored.has("cloth_teal"), "mixed cloth/ceramic batch is exercised")
	for key: String in market_authored:
		_expect(market_authored[key] == market_rendered[key], "market mixed batch retains all " + key + " triangles")
	for name: String in ["EastRamp", "WestRamp"]:
		var ramp_mesh: Mesh = (district.get_node(name).get_child(0) as MeshInstance3D).mesh
		var arrays: Array = ramp_mesh.surface_get_arrays(0)
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		_expect(normals.size() >= 6 and normals[0].y > 0.9 and normals[3].y > 0.9,
			name + " top front faces and normals point upward")
	_probe(Layout.spawn_position(), "spawn")
	var route: Array[Vector3] = Layout.route_points()
	for index: int in range(route.size() - 1):
		var count: int = maxi(1, ceili(route[index].distance_to(route[index + 1]) / 0.75))
		for step: int in range(count + 1):
			_probe(route[index].lerp(route[index + 1], float(step) / float(count)), "route %d/%d" % [index, step])
	for pocket: Dictionary in Layout.combat_pockets():
		var center: Vector3 = pocket.center
		_probe(center, pocket.id)
		for step: int in 12:
			var angle: float = TAU * float(step) / 12.0
			var point: Vector3 = center + Vector3(cos(angle), 0, sin(angle)) * float(pocket.radius)
			_probe(point, String(pocket.id) + " edge " + str(step))
	for z: float in [10.0, 12.0, 14.0, 16.0, 22.0, 28.0]:
		for x: float in [18.5, 20.0, 21.5]:
			_probe(Vector3(x, 0, z), "passage %.1f/%.1f" % [x, z])
	_expect(_ray(Vector3(20, 1.5, 8), Vector3(20, 1.5, 31)).is_empty(), "passage is open end to end")
	_expect(_ray(Vector3(0, 1.8, -15), Vector3(0, 1.8, -25)).is_empty(), "bridge has ground route below")
	_expect(not _ray(Vector3(0, 1.4, 20), Vector3(15, 1.4, 20)).is_empty(), "solid facade blocks walking")
	_expect(not _ray(Vector3(0, 1.4, 20), Vector3(15, 1.4, 20), 8).is_empty(), "solid facade blocks rope sight")
	_expect(not _ray(Vector3(0, 2, 31), Vector3(0, 2, 34)).is_empty(), "visible district boundary is solid")
	_expect(not _clear_body(Vector3(14, 0, 20)), "probe rejects an occupied volume")
	_expect(not _clear_body(Vector3(20, 4, 14)), "probe rejects low overhead lintel")
	_expect(_ray(Vector3(40, 1, 0), Vector3(40, -1, 0)).is_empty(), "probe distinguishes absent support")
	# Broad architectural ledges must support a player who reaches them by jump/grapple.
	var balcony: Dictionary = _ray(Vector3(-20, 4.1, 11.55), Vector3(-20, 3.4, 11.55))
	_expect(not balcony.is_empty() and float(balcony.position.y) > 3.7, "balcony slab has physical support")
	var mansard: Dictionary = _ray(Vector3(-20, 14, 21), Vector3(-20, 10.5, 21))
	_expect(not mansard.is_empty() and float(mansard.position.y) > 11.4, "mansard crown has physical support")
	var dome: Dictionary = _ray(Vector3(-22, 24, -25), Vector3(-22, 16.3, -25))
	_expect(not dome.is_empty() and float(dome.position.y) > 17.0, "domed tower roof has physical support")
	var anchors: Array[Node] = get_nodes_in_group("grapple_anchor")
	_expect(anchors.size() == 4, "four sparse street anchors")
	for node: Node in anchors:
		var anchor: Node3D = node as Node3D
		var origin: Vector3 = Vector3(signf(anchor.position.x) * 4, 1.2, signf(anchor.position.z) * 4)
		_expect(origin.distance_to(anchor.position) < 14.0, "anchor has a nearby in-range street approach")
		_expect(_ray(origin, anchor.position, 8).is_empty(), "anchor approach is unobstructed")
		var below: Dictionary = _ray(anchor.position, anchor.position - Vector3.UP * 8)
		_expect(not below.is_empty() and absf(float(below.position.y)) < 0.01, "idle rope hangs over ground zero")
	print("CITY_GEOMETRY_COMPLETE checks=%d failures=%d meshes=%d" % [checks, failures, district.geometry_count])
	district.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
