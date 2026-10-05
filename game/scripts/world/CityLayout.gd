class_name CityLayout
extends RefCounted
## PLACEHOLDER metres for the first functional district, not combat balance.

static func district_bounds() -> AABB:
	return AABB(Vector3(-32, -2, -32), Vector3(64, 22, 64))

static func spawn_position() -> Vector3:
	return Vector3(0, 0, 23)

static func combat_pockets() -> Array[Dictionary]:
	return [
		{"id": "central_court", "title": "Central court", "center": Vector3.ZERO, "radius": 7.0},
		{"id": "west_court", "title": "West court", "center": Vector3(-22, 0, 0), "radius": 5.0},
		{"id": "east_terrace", "title": "East terrace", "center": Vector3(20, 4, -20), "radius": 5.0},
	]

static func route_points() -> Array[Vector3]:
	return [spawn_position(), Vector3.ZERO, Vector3(18, 0, 10), Vector3(18, 0, 8),
		Vector3(18, 4, -10), Vector3(20, 4, -20), Vector3(0, 4, -20),
		Vector3(-20, 4, -20), Vector3(-29, 4, -20), Vector3(-29, 4, -14), Vector3(-29, 4, -10),
		Vector3(-29, 0, 8), Vector3(-29, 0, 10), Vector3(-22, 0, 10), Vector3(-22, 0, 6), Vector3(-22, 0, 0),
		Vector3.ZERO, spawn_position()]

static func ramps() -> Array[Dictionary]:
	return [
		{"id": "EastRamp", "x": 18.0, "width": 4.0, "start_z": 8.0, "end_z": -10.0, "height": 4.0},
		{"id": "WestRamp", "x": -29.0, "width": 3.0, "start_z": 8.0, "end_z": -10.0, "height": 4.0},
	]

static func anchors() -> Array[Vector3]:
	return [Vector3(-8, 6.5, -8), Vector3(8, 6.5, -8),
		Vector3(-8, 6.5, 8), Vector3(8, 6.5, 8)]

static func blocks() -> Array[Dictionary]:
	return [
		_box("Ground", Vector3(0, -0.5, 0), Vector3(64, 1, 64), "paving", 1),
		_box("NorthWestRoof", Vector3(-20, 2, -20), Vector3(20, 4, 20), "slate"),
		_box("NorthEastRoof", Vector3(20, 2, -20), Vector3(20, 4, 20), "terracotta"),
		_box("SouthWestBlock", Vector3(-20, 7, 21), Vector3(20, 6, 18), "terracotta"),
		_box("SouthWestRear", Vector3(-20, 2, 25), Vector3(20, 4, 10), "terracotta"),
		_box("SouthEastWestWing", Vector3(14, 4, 21), Vector3(8, 8, 18), "slate"),
		_box("SouthEastEastWing", Vector3(26, 6, 21), Vector3(8, 12, 18), "plaster"),
		_box("PassageLintel", Vector3(20, 5.5, 14), Vector3(4, 2, 4), "plaster"),
		_box("RoofBridge", Vector3(0, 3.75, -20), Vector3(20, 0.5, 4), "brass"),
		_box("ClockTower", Vector3(-24, 10, -25), Vector3(8, 12, 8), "plaster"),
		_box("WestBoundary", Vector3(-32.5, 2, 0), Vector3(1, 4, 66), "slate"),
		_box("EastBoundary", Vector3(32.5, 2, 0), Vector3(1, 4, 66), "slate"),
		_box("NorthBoundary", Vector3(0, 2, -32.5), Vector3(64, 4, 1), "slate"),
		_box("SouthBoundary", Vector3(0, 2, 32.5), Vector3(64, 4, 1), "slate"),
	]

static func _box(id: String, center: Vector3, size: Vector3, material: String, layer: int = 9) -> Dictionary:
	return {"id": id, "center": center, "size": size, "material": material, "layer": layer}
