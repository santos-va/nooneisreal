class_name CityProps
extends CityMarket
## Phase 0 of docs/Plans/2026-10-09-City-Tidy-And-Modern-Props.md: the first props of the T6 catalog that need no art
## (docs/Art/2026-10-08-City-Modern-Realism-Props.md, path «Пр»). Procedural, from the city's own materials and
## batched by material like the market (К9); no new light, no letters (К5), no `ink` surface (К4).
##   № 1–3 — beer barrels, water butts under downpipes, steel tar drums;
##   № 4, Н8 — crate rows and a coal bunker that both heroes vault (0.9–1.1 m high, ≤ 0.8 m deep, the floor beyond
##            at the same level; one box collider each, so the vault sees one flat top);
##   № 15 — steam vents in the paving, puffing the painted vfx_steam_puff_v1 (CitySteamVent);
##   № 16, Н7 — a steam main on the east wall of the southeast passage: ≥ 3.2 m up, ≤ 0.25 m out of the wall, no
##            collider anywhere, so the passage keeps its 4 m, its axis and the camera keeps its arm;
##   № 22 — urns by the benches.
## Nothing stands under a rope anchor, within 8 m of the court centre, in a fight pocket or within 1 m of a resident
## lane (К6; tools/world/city_tidy_check.gd measures it). PLACEHOLDER metres; T6 accepts the look on frames.

## Obstacles to vault (Н8): centre on the floor, size (x, height, z). `run` is the axis a runner crosses it along.
const OBSTACLES: Array[Dictionary] = [
	{"id": "crates_east", "kind": "crates", "center": Vector3(30.4, 0, 0.0), "size": Vector3(1.6, 0.95, 0.7), "run": Vector3(0, 0, 1)},
	{"id": "bunker_terrace", "kind": "bunker", "center": Vector3(22.6, 0, -7.6), "size": Vector3(0.7, 1.0, 1.2), "run": Vector3(1, 0, 0)},
	{"id": "crates_west", "kind": "crates", "center": Vector3(-12.4, 0, -7.2), "size": Vector3(0.7, 0.95, 1.6), "run": Vector3(1, 0, 0)},
	{"id": "crates_south", "kind": "crates", "center": Vector3(-6.6, 0, 29.2), "size": Vector3(0.7, 0.95, 1.6), "run": Vector3(1, 0, 0)},
]
## Steam vents (№ 15): on the street edges, away from routes and pockets; `phase` staggers their puffs.
const VENTS: Array[Dictionary] = [
	{"center": Vector3(27.8, 0, -3.0), "phase": 0.0},
	{"center": Vector3(8.6, 0, -14.0), "phase": 3.4},
]
## The steam main (№ 16): the passage's east wall plane, the main's axis and its run along the wall.
const MAIN_WALL_X: float = 22.0
const MAIN_X: float = 21.88
const MAIN_Y: float = 3.6
const MAIN_Z: Vector2 = Vector2(12.4, 29.6)
var props: Array[Dictionary] = []


func _ready() -> void:
	name = "CityProps"
	_materials = CityMaterials.palette()
	_market_barrels()
	_tar_drums()
	for spec: Dictionary in OBSTACLES:
		_obstacle(spec)
	for x: float in [-27.2, -11.45]:
		_urn(Transform3D(Basis.IDENTITY, Vector3(x, 0, 8.25)))
	_steam_main()
	for spec: Dictionary in VENTS:
		_steam_vent(spec)
	_flush_batches()
	set_meta("props", props.duplicate(true))
	set_meta("obstacles", OBSTACLES.duplicate(true))


func _note(kind: String, at: Vector3, radius: float) -> void:
	props.append({"kind": kind, "position": at, "radius": radius})


## Between the stalls of the market (T6: z ≈ 21.5, |x| ≈ 9): each side has a rain butt under a downpipe from its
## facade and the stall's stock beside it; the two groups differ.
func _market_barrels() -> void:
	_water_butt(Transform3D(Basis.IDENTITY, Vector3(-9.55, 0, 22.2)))
	_note("water_butt", Vector3(-9.55, 0, 22.2), 0.36)
	_beer_barrel(Transform3D(Basis(Vector3.UP, 0.7), Vector3(-9.35, 0, 21.35)))
	_note("beer_barrel", Vector3(-9.35, 0, 21.35), 0.3)
	# West facade: the pipe stays 0.36 m off the upper facade (past its string course and plinth), steps in under
	# the plinth at y 3.9 and runs down SouthWestRear's face to just over the butt's lid.
	_downpipe([Vector3(-9.62, 9.6, 22.2), Vector3(-9.62, 3.9, 22.2), Vector3(-9.9, 3.9, 22.2), Vector3(-9.9, 0.95, 22.2)],
		[Vector4(-9.62, 8.5, 22.2, -10.02), Vector4(-9.62, 5.5, 22.2, -10.02), Vector4(-9.9, 2.2, 22.2, -10.02)])
	_water_butt(Transform3D(Basis(Vector3.UP, 1.9), Vector3(9.35, 0, 22.2)))
	_note("water_butt", Vector3(9.35, 0, 22.2), 0.36)
	_beer_barrel(Transform3D(Basis(Vector3.UP, -0.4), Vector3(9.3, 0, 21.35)))
	_note("beer_barrel", Vector3(9.3, 0, 21.35), 0.3)
	_crate(Transform3D(Basis(Vector3.UP, 0.15), Vector3(9.3, 0, 20.6)), Vector3(0.62, 0.5, 0.55))
	_note("crate", Vector3(9.3, 0, 20.6), 0.42)
	# East facade: one straight run under the cornice, clear of the string course, the sills and the plinth.
	_downpipe([Vector3(9.65, 7.6, 22.2), Vector3(9.65, 0.95, 22.2)],
		[Vector4(9.65, 6.8, 22.2, 10.02), Vector4(9.65, 5.0, 22.2, 10.02), Vector4(9.65, 2.2, 22.2, 10.02)])


## A downpipe (Ø 0.1, copper patina) along `points`, a rainwater head at the top, an open shoe at the foot; each clamp
## (x, y, z on the pipe, w = an x 2 cm inside the wall) is a flat iron strap into the wall.
func _downpipe(points: Array[Vector3], clamps: Array[Vector4]) -> void:
	for clamp: Vector4 in clamps:
		_box(Transform3D.IDENTITY, Vector3((clamp.x + clamp.w) * 0.5, clamp.y, clamp.z), Vector3(absf(clamp.w - clamp.x), 0.04, 0.12), "iron")
	for index: int in points.size() - 1:
		_rod(points[index], points[index + 1], 0.05, "copper")
	for index: int in range(1, points.size() - 1):
		_box(Transform3D.IDENTITY, points[index], Vector3(0.12, 0.12, 0.12), "copper")
	_box(Transform3D.IDENTITY, points[0] + Vector3(0, -0.05, 0), Vector3(0.18, 0.12, 0.18), "copper")
	_cylinder(Transform3D.IDENTITY, points[-1] + Vector3(0, 0.03, 0), 0.07, 0.07, 0.06, "copper")


## Three steel tar drums beside the low roof approach (east, the industrial edge), clear of its climbing face.
func _tar_drums() -> void:
	for at: Vector3 in [Vector3(14.45, 0, -4.0), Vector3(14.6, 0, -4.72), Vector3(15.18, 0, -4.3)]:
		_tar_barrel(Transform3D(Basis(Vector3.UP, at.x * 1.3), at))
		_note("tar_barrel", at, 0.3)


## One vault obstacle (Н8): a row of two crates or a coal bunker, with one box collider of the whole size.
func _obstacle(spec: Dictionary) -> void:
	var center: Vector3 = spec.center
	var size: Vector3 = spec.size
	var along_x: bool = size.x >= size.z
	var pose := Transform3D(Basis.IDENTITY if along_x else Basis(Vector3.UP, PI * 0.5), center)
	var length: float = maxf(size.x, size.z)
	var depth: float = minf(size.x, size.z)
	if String(spec.kind) == "bunker":
		_coal_bunker(pose, Vector3(length, size.y, depth))
	else:
		for side: float in [-1.0, 1.0]:
			_vault_crate(pose.translated_local(Vector3(side * length * 0.25, 0, 0)), Vector3(length * 0.5 - 0.01, size.y, depth))
	var shape := BoxShape3D.new()
	shape.size = size
	_solid("VaultObstacle_" + String(spec.id), Transform3D(Basis.IDENTITY, center + Vector3(0, size.y * 0.5, 0)), shape)
	_note(String(spec.kind), center, Vector2(size.x, size.z).length() * 0.5)


## A cargo crate whose details never rise over its lid: the lid stays one flat top to land the hands on.
func _vault_crate(pose: Transform3D, size: Vector3) -> void:
	_box(pose, Vector3(0, size.y * 0.5, 0), size, "wood")
	for side: float in [-1.0, 1.0]:
		for y: float in [0.1, size.y - 0.1]:
			_box(pose, Vector3(0, y, side * (size.z * 0.5 + 0.012)), Vector3(size.x + 0.02, 0.09, 0.024), "wood")
		for x: float in [-size.x * 0.38, size.x * 0.38]:
			_box(pose, Vector3(x, size.y * 0.5, side * (size.z * 0.5 + 0.03)), Vector3(0.085, size.y - 0.02, 0.036), "wood")
		_box(pose, Vector3(0, size.y * 0.5, side * (size.z * 0.5 + 0.004)), Vector3(size.x - 0.02, 0.016, 0.008), "iron")
	for side: float in [-1.0, 1.0]:
		_box(pose, Vector3(side * (size.x * 0.5 + 0.012), size.y * 0.5, 0), Vector3(0.024, size.y - 0.04, size.z * 0.7), "wood")


## № 5 as an obstacle: a timber coal bunker with iron corners and a flat plank lid; a coal hatch at its foot.
func _coal_bunker(pose: Transform3D, size: Vector3) -> void:
	_box(pose, Vector3(0, size.y * 0.5 - 0.02, 0), Vector3(size.x, size.y - 0.04, size.z), "wood")
	_box(pose, Vector3(0, size.y - 0.02, 0), Vector3(size.x + 0.04, 0.04, size.z + 0.04), "wood")
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			_box(pose, Vector3(x * (size.x * 0.5 + 0.005), size.y * 0.5 - 0.03, z * (size.z * 0.5 + 0.005)), Vector3(0.07, size.y - 0.1, 0.07), "iron")
	for side: float in [-1.0, 1.0]:
		_box(pose, Vector3(0, 0.22, side * (size.z * 0.5 + 0.015)), Vector3(0.5, 0.3, 0.03), "iron")


## № 22: a cast-iron litter basket with a lid, Ø 0.45 × 0.92 m, solid.
func _urn(pose: Transform3D) -> void:
	_cylinder(pose, Vector3(0, 0.05, 0), 0.15, 0.17, 0.1, "iron")
	_cylinder(pose, Vector3(0, 0.435, 0), 0.2, 0.18, 0.67, "slate")
	for y: float in [0.13, 0.76]:
		_cylinder(pose, Vector3(0, y, 0), 0.225, 0.225, 0.05, "iron")
	for index: int in 4:
		var bar: Transform3D = pose.rotated_local(Vector3.UP, float(index) * PI * 0.5 + PI * 0.25)
		_box(bar, Vector3(0, 0.445, 0.205), Vector3(0.05, 0.58, 0.03), "iron")
	_cylinder(pose, Vector3(0, 0.84, 0), 0.06, 0.235, 0.1, "iron")
	_cylinder(pose, Vector3(0, 0.905, 0), 0.03, 0.03, 0.03, "iron")
	var shape := CylinderShape3D.new()
	shape.radius = 0.225
	shape.height = 0.92
	_solid("StreetUrn", pose.translated_local(Vector3(0, 0.46, 0)), shape)
	_note("urn", pose.origin, 0.225)


## № 16 / Н7: the steam main along the passage's east wall. Every part keeps x ≥ MAIN_WALL_X − 0.25 and y ≥ 2.4, and
## nothing here is solid. Both ends go somewhere (П2): the north end into the wall, the south end up a riser into
## the wall under the roof; one drop with a drain valve stays above head height.
func _steam_main() -> void:
	var a := Vector3(MAIN_X, MAIN_Y, MAIN_Z.x)
	var b := Vector3(MAIN_X, MAIN_Y, MAIN_Z.y)
	_rod(a, b, 0.1, "copper")
	var z: float = 13.0
	while z < MAIN_Z.y:
		_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(MAIN_X, MAIN_Y, z)), Vector3.ZERO, 0.13, 0.13, 0.05, "iron")
		z += 2.0
	_rod(a, Vector3(MAIN_WALL_X + 0.02, MAIN_Y, MAIN_Z.x), 0.1, "copper")
	var riser_x: float = MAIN_WALL_X - 0.13
	_box(Transform3D.IDENTITY, Vector3(MAIN_X, MAIN_Y, MAIN_Z.y), Vector3(0.22, 0.22, 0.22), "iron")
	_rod(Vector3(riser_x, MAIN_Y + 0.1, MAIN_Z.y), Vector3(riser_x, 11.6, MAIN_Z.y), 0.08, "copper")
	_rod(Vector3(riser_x, 11.6, MAIN_Z.y), Vector3(MAIN_WALL_X + 0.02, 11.6, MAIN_Z.y), 0.08, "copper")
	# The drain drop: a tee under the main, 1 m down, a drain valve at its end (2.5 m over the floor).
	_rod(Vector3(riser_x, MAIN_Y - 0.1, 18.0), Vector3(riser_x, 2.6, 18.0), 0.06, "copper")
	_cylinder(Transform3D.IDENTITY, Vector3(riser_x, 2.62, 18.0), 0.07, 0.07, 0.08, "iron")
	for at: float in [16.0, 25.0]:
		_valve(Vector3(MAIN_X, MAIN_Y, at))


## A wheel valve on the main: a body around the pipe, a stem up and a level hand wheel that stays within the wall
## band (Ø 0.24 over the main's axis).
func _valve(at: Vector3) -> void:
	_cylinder(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), at), Vector3.ZERO, 0.12, 0.12, 0.26, "iron")
	_cylinder(Transform3D.IDENTITY, at + Vector3(0, 0.17, 0), 0.02, 0.02, 0.1, "iron")
	var wheel := TorusMesh.new()
	wheel.inner_radius = 0.095
	wheel.outer_radius = 0.12
	wheel.rings = 12
	wheel.ring_segments = 4
	_primitive(wheel, Transform3D(Basis.IDENTITY, at + Vector3(0, 0.23, 0)), "iron")
	for index: int in 2:
		_box(Transform3D(Basis(Vector3.UP, float(index) * PI * 0.5), at + Vector3(0, 0.23, 0)), Vector3.ZERO, Vector3(0.2, 0.015, 0.015), "iron")


## № 15: an iron grate flat on the paving (2 cm, nothing to trip on) with a hand wheel lying in its corner; the puff
## is a CitySteamVent child.
func _steam_vent(spec: Dictionary) -> void:
	var at: Vector3 = spec.center
	var pose := Transform3D(Basis.IDENTITY, at)
	for side: float in [-1.0, 1.0]:
		_box(pose, Vector3(side * 0.39, 0.01, 0), Vector3(0.06, 0.02, 0.84), "iron")
		_box(pose, Vector3(0, 0.01, side * 0.39), Vector3(0.72, 0.02, 0.06), "iron")
	for index: int in 5:
		_box(pose, Vector3(-0.24 + float(index) * 0.12, 0.008, 0), Vector3(0.04, 0.016, 0.72), "iron")
	var wheel := TorusMesh.new()
	wheel.inner_radius = 0.05
	wheel.outer_radius = 0.075
	wheel.rings = 10
	wheel.ring_segments = 4
	_primitive(wheel, pose.translated_local(Vector3(0.27, 0.0325, 0.27)), "brass")
	var vent := CitySteamVent.new()
	vent.name = "SteamVent%d" % VENTS.find(spec)
	vent.phase = float(spec.phase)
	vent.position = at
	add_child(vent)
	_note("steam_vent", at, 0.42)
