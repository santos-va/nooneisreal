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
	for shop: Dictionary in CityPlaces.shops():
		var approach: Vector3 = shop.approach
		var visit: Vector3 = shop.visit
		for step: int in 18:
			_probe(approach.lerp(visit, float(step) / 17.0), String(shop.id) + " door walk " + str(step))
		var path: Array = shop.worker_path
		for index: int in range(path.size() - 1):
			for step: int in 9:
				_probe((path[index] as Vector3).lerp(path[index + 1], float(step) / 8.0), String(shop.id) + " work aisle")
		_expect(_ray(approach + Vector3.UP * 1.5, visit + Vector3.UP * 1.5).is_empty(), String(shop.id) + " doorway has no hidden solid facade")
		_expect(_ray(visit + Vector3.UP * 1.5, (shop.worker as Vector3) + Vector3.UP * 1.5).is_empty(), String(shop.id) + " counter permits face-to-face conversation")
		_expect(not _clear_body(Vector3(shop.door.x - 0.2, 0, 17.6)), String(shop.id) + " counter is solid")
		_expect(not _clear_body(Vector3(shop.door.x + 3.3, 0, 15)), String(shop.id) + " side wall is solid")
		_expect(not _ray(Vector3(shop.door.x, 1.5, 19), Vector3(shop.door.x, 1.5, 21)).is_empty(), String(shop.id) + " back wall closes room")
	var interiors: Node = district.get_node("CityInteriors")
	_expect(interiors.get_meta("visual_parts", 0) > 250, "three interiors contain real furnishings")
	_expect(interiors.get_meta("material_batches", 99) <= 19, "interior kit batches shared materials")
	var backdrop: Node3D = district.get_node("CityBackdrop")
	_expect(backdrop.get_meta("skyline_buildings", 0) == 10, "skyline has ten bounded buildings")
	_expect(backdrop.get_meta("triangle_count", 999999) <= 16000, "skyline stays within triangle budget")
	_expect(backdrop.get_child_count() <= 7, "skyline stays within seven material mesh nodes")
	_expect(backdrop.find_children("*", "CollisionObject3D", true, false).is_empty(), "skyline creates no collision or phantom anchors")
	for node: Node in backdrop.get_children():
		var outside: bool = true
		for vertex: Vector3 in (node as MeshInstance3D).mesh.get_faces():
			var point: Vector3 = (node as Node3D).global_transform * vertex
			if absf(point.x) < 32.0 and absf(point.z) < 32.0:
				outside = false
		_expect(outside, "backdrop material mesh stays outside playable square: " + node.name)
	var bridge_rails: Array[Node] = district.find_children("BridgeParapet*", "Node3D", false, false)
	_expect(bridge_rails.size() == 2, "both bridge edge rails remain present")
	for parapet: Node3D in bridge_rails:
		var collision: BoxShape3D = (parapet.get_child(1) as CollisionShape3D).shape as BoxShape3D
		_expect(collision.size == Vector3(20, 1, 0.2), "open bridge rail preserves the complete safety collider")
		var infill: MeshInstance3D = parapet.get_child(0) as MeshInstance3D
		_expect((infill.mesh as BoxMesh).size.y <= 0.25 and infill.position.y < -0.3, "bridge infill reveals footfalls")
	# Plan 2026-10-07-Aim-Free-Rope step 2 appends anchors with supports; the four street lamps keep indices 0-3 and their
	# street checks. Coverage, roofs and supports of all of them: tools/world/anchor_coverage.gd.
	var anchors: Array[Node] = get_nodes_in_group("grapple_anchor")
	_expect(anchors.size() == Layout.anchors().size() and anchors.size() > 4, "every CityLayout anchor is live, the four street lamps first")
	for node: Node in anchors:
		var anchor: Node3D = node as Node3D
		var below: Dictionary = _ray(anchor.position, anchor.position - Vector3.UP * 12)
		_expect(not below.is_empty() and anchor.position.y - float(below.position.y) >= 2.75, "idle rope at %s hangs over a floor within 12 m" % anchor.position)
		if Layout.anchors().find(anchor.position) >= 4:
			continue
		var origin: Vector3 = Vector3(signf(anchor.position.x) * 4, 1.2, signf(anchor.position.z) * 4)
		_expect(origin.distance_to(anchor.position) < 14.0, "anchor has a nearby in-range street approach")
		_expect(_ray(origin, anchor.position, 8).is_empty(), "anchor approach is unobstructed")
		_expect(absf(float(below.position.y)) < 0.01, "street lamp rope hangs over ground zero")
	print("CITY_GEOMETRY_COMPLETE checks=%d failures=%d meshes=%d" % [checks, failures, district.geometry_count])
	district.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
