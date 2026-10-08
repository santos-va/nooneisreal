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

## ADR-024, the first lethal fight: its pocket (one of combat_pockets), the enemy and the safe point in front of the
## pocket on the street from the spawn. The safe point is also the entry: an explicit interaction there opens the
## fight; RETURN TO SAFE POINT puts the hero back on it. PLACEHOLDER metres (2.5 m outside the pocket's edge).
static func lethal_encounter() -> Dictionary:
	return {"pocket": "central_court", "enemy": "res://data/characters/lamplighter.tres", "safe_point": Vector3(0, 0, 9.5)}

static func pocket(id: String) -> Dictionary:
	for entry: Dictionary in combat_pockets():
		if entry.id == id:
			return entry
	return {}

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

## Rope anchors with their visible supports (plan 2026-10-07-Aim-Free-Rope step 2). `mount` is where the support meets
## the existing world geometry, so no anchor hangs in the air. Indices are stable: the rope quest and its saves name
## "anchor_<index>", so new anchors are only ever appended. PLACEHOLDER metres; range 14 m and the swing rules are T5's.
##   post    — a lamp post standing at `mount`, its arm over the point (the four original street lamps);
##   bracket — an iron arm fixed into a wall or a cornice at `mount` (arm height), with a strut below it;
##   hanger  — an eye-bolt hanging from a slab underside at `mount`.
static func anchor_supports() -> Array[Dictionary]:
	return [
		{"point": Vector3(-8, 6.5, -8), "mount": Vector3(-9, 0, -8), "kind": "post"},
		{"point": Vector3(8, 6.5, -8), "mount": Vector3(9, 0, -8), "kind": "post"},
		{"point": Vector3(-8, 6.5, 8), "mount": Vector3(-9, 0, 8), "kind": "post"},
		{"point": Vector3(8, 6.5, 8), "mount": Vector3(9, 0, 8), "kind": "post"},
		# Market street: brackets under the cornice of the southeast wing and the southwest block, at bay centres.
		{"point": Vector3(8.6, 6.7, 17.4), "mount": Vector3(10.05, 7.0, 17.4), "kind": "bracket"},
		{"point": Vector3(8.6, 6.7, 24.6), "mount": Vector3(10.05, 7.0, 24.6), "kind": "bracket"},
		{"point": Vector3(-8.6, 6.7, 17.4), "mount": Vector3(-10.05, 7.0, 17.4), "kind": "bracket"},
		{"point": Vector3(-8.6, 6.7, 24.6), "mount": Vector3(-10.05, 7.0, 24.6), "kind": "bracket"},
		# Southeast passage (open to the south: it ends in the strip z 30–32 along SouthBoundary, probe 2026-10-08): one
		# bracket on the plain east-wing wall, which has no facade trim.
		{"point": Vector3(20.4, 7.0, 22.0), "mount": Vector3(22.05, 7.3, 22.0), "kind": "bracket"},
		# East street: north faces of both southeast wings, between window rows.
		{"point": Vector3(28, 8.6, 10.6), "mount": Vector3(28, 8.9, 12.05), "kind": "bracket"},
		{"point": Vector3(16, 6.7, 10.6), "mount": Vector3(16, 7.0, 12.05), "kind": "bracket"},
		# Lamp posts on the terrace edges, arms over the street below: they serve the terrace and the street.
		{"point": Vector3(15, 8.0, -9.6), "mount": Vector3(15, 4.0, -11.0), "kind": "post"},
		{"point": Vector3(26, 8.0, -9.6), "mount": Vector3(26, 4.0, -11.0), "kind": "post"},
		{"point": Vector3(-18, 8.0, -9.6), "mount": Vector3(-18, 4.0, -11.0), "kind": "post"},
		{"point": Vector3(-9.6, 8.0, -24), "mount": Vector3(-11.0, 4.0, -24), "kind": "post"},
		{"point": Vector3(9.6, 8.0, -24), "mount": Vector3(11.0, 4.0, -24), "kind": "post"},
		# West street: the southwest block's north face over the shop fronts, and one street lamp by the west ramp.
		{"point": Vector3(-24, 6.8, 10.6), "mount": Vector3(-24, 7.1, 12.05), "kind": "bracket"},
		{"point": Vector3(-16, 6.8, 10.6), "mount": Vector3(-16, 7.1, 12.05), "kind": "bracket"},
		{"point": Vector3(-26, 6.5, -4), "mount": Vector3(-27, 0, -4), "kind": "post"},
		# Northwest terrace: the clock tower (east and south faces, under the cornice) and the plaster house.
		{"point": Vector3(-18.6, 10.2, -25), "mount": Vector3(-20.05, 10.5, -25), "kind": "bracket"},
		{"point": Vector3(-24, 10.2, -19.6), "mount": Vector3(-24, 10.5, -21.05), "kind": "bracket"},
		{"point": Vector3(-29.4, 10.2, -25), "mount": Vector3(-27.95, 10.5, -25), "kind": "bracket"},
		{"point": Vector3(-12, 9.3, -24.6), "mount": Vector3(-12, 9.6, -26.05), "kind": "bracket"},
		# Northeast terrace: the tall house's south face, between the first balconies and the second string course.
		{"point": Vector3(16, 9.3, -24.6), "mount": Vector3(16, 9.6, -26.05), "kind": "bracket"},
		{"point": Vector3(24, 9.3, -24.6), "mount": Vector3(24, 9.6, -26.05), "kind": "bracket"},
	]

static func anchors() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for spec: Dictionary in anchor_supports():
		points.append(spec.point)
	return points

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
