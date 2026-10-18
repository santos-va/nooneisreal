class_name CityInteriors
extends CityMarket
## Walk-in shops: collidable shell, broad clear aisles and reused batched market kit.
const Places = preload("res://scripts/world/CityPlaces.gd")
## Shops whose awning is rolled up (the Н6 «rolled» state of the market stalls, docs/Art/2026-10-08-City-Modern-Realism-
## Props.md). The grocer's spread awning (x −29.85…−23.35, y 3.76–3.94, out to z 10.905) lay under anchor 16
## (−24, 6.8, 10.6): a line chosen as clear cut on the first hanging tick (ShopAwning@(−26.74, 3.76, 11.09), docs/Fix/
## 2026-10-09-Rope-Pull-And-Jump-Arc-Fix.md). T1's choice Т1, plan 2026-10-14-Quality-Debt-Posts-Awning-Guards step 2;
## the tailor's and the workshop's stay spread. PLACEHOLDER; T6 accepts the frame.
const ROLLED_AWNINGS: Array[String] = ["grocer"]
## The rolled awning's cloth (_rolled_awning): cross stripes of cream and accent, ~0.46 m each like the rolled stall's
## 0.445 m (T6 acceptance docs/Audit/2026-10-14-T6-Acceptance.md § 1, ТЗ 2: «~14 смуг по ~0,46 м»), and its ties' width,
## П4 «≥ 0,1 м» (ТЗ 3). PLACEHOLDER; T6 accepts the frame.
const ROLLED_STRIPES: int = 14
const ROLLED_TIE: float = 0.10

func _ready() -> void:
	name = "CityInteriors"
	_materials = CityMaterials.palette()
	for key: String in _materials:
		_materials[key].set_shader_parameter("painted_fill", 0.28)
		_materials[key].set_shader_parameter("key_gain", 1.65)
	# D24: the street faces of the two end walls use the street (district) terracotta, like SouthWestRear next to them,
	# not the interior variant of plaster.
	_materials["exterior_terracotta"] = CityMaterials.palette()["terracotta"]
	for shop: Dictionary in Places.shops():
		_shop(shop)
	_street_furniture()
	_flush_batches()

func _shop(shop: Dictionary) -> void:
	var pose := Transform3D(Basis.IDENTITY, shop.door)
	var index: int = int(shop.npc_index)
	var accent: String = ["cloth_teal", "cloth_red", "copper"][index]
	var floor_material: String = "stone" if shop.id == "grocer" else "wood"
	# No single box crosses the doorway. Side/back walls join the retained upper storey.
	for side: float in [-1.0, 1.0]:
		# D16: neighbouring shops share one wall; the west neighbour builds it, so it is not built twice.
		if side < 0.0 and index > 0:
			continue
		if (side < 0.0 and index == 0) or (side > 0.0 and index == Places.shops().size() - 1):
			# D24: an end wall faces the street; its inner half is the room's plaster, its outer half the street's
			# terracotta. One collider for the whole wall, as before.
			_box(pose, Vector3(side * 3.25, 2, 4), Vector3(0.1, 4, 8), "plaster")
			_box(pose, Vector3(side * 3.35, 2, 4), Vector3(0.1, 4, 8), "exterior_terracotta")
			var wall := BoxShape3D.new()
			wall.size = Vector3(0.2, 4, 8)
			_solid("ShopWall", pose.translated_local(Vector3(side * 3.3, 2, 4)), wall)
		else:
			_box(pose, Vector3(side * 3.3, 2, 4), Vector3(0.2, 4, 8), "plaster", "ShopWall")
	_box(pose, Vector3(0, 2, 7.9), Vector3(6.6, 4, 0.2), "plaster", "ShopBack")
	_box(pose, Vector3(0, 3.6, 0), Vector3(6.6, 0.8, 0.3), accent, "ShopLintel")
	for side: float in [-1.0, 1.0]:
		# Open display bays above a low wall; centre opening remains 2.4m wide.
		# D11: the low wall ends inside the door jamb (x 1.2–1.32), so its end face no longer shares the jamb's plane.
		_box(pose, Vector3(side * 2.3, 0.47, 0), Vector3(2.0, 0.94, 0.28), accent, "ShopWindowBase")
		_box(pose, Vector3(side * 3.1, 2.1, 0), Vector3(0.18, 2.2, 0.25), "wood", "ShopJamb")
		_box(pose, Vector3(side * 1.26, 1.6, -0.02), Vector3(0.12, 3.2, 0.34), "wood", "DoorJamb")
		_box(pose, Vector3(side * 2.2, 2.15, 0), Vector3(0.06, 2.4, 0.08), "brass")
		_box(pose, Vector3(side * 2.2, 2.5, 0), Vector3(1.8, 0.06, 0.08), "brass")
	_box(pose, Vector3(0, 0.003, 4), Vector3(6.3, 0.006, 7.7), floor_material)
	if String(shop.id) in ROLLED_AWNINGS:
		_rolled_awning(pose, accent, shop.title)
	else:
		_box(pose, Vector3(0, 3.85, -0.52), Vector3(6.5, 0.18, 1.15), accent, "ShopAwning")
		# D12: the cream fascia stops at the awning's underside (y 3.76): their front faces no longer overlap in one plane.
		_box(pose, Vector3(0, 3.63, -1.04), Vector3(6.5, 0.26, 0.11), "cloth_cream")
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

## A shop awning rolled up (ROLLED_AWNINGS): one roll Ø 0.24 m (the Н6 stall roll's size) along the lintel, 1 cm off its
## face (local z −0.15) at the spread awning's height (y 3.85), in cross stripes of cream and the shop's accent like the
## rolled stall canopy (CityMarket._rolled_canopy: 8 × 0.445 m there, ROLLED_STRIPES × 6.5 / 14 m here), tied in three
## places with bands ROLLED_TIE wide (П4 ≥ 0.1 m); the cream valance with the shop's name hangs under the roll, as the front
## bar of a retracted awning. T6 acceptance docs/Audit/2026-10-14-T6-Acceptance.md § 1: one accent roll behind the valance
## merged with the lintel of its own colour and its 4 cm ties were ~6 px from 6 m. One collider for the roll (unchanged),
## none for the valance (as the spread fascia). PLACEHOLDER sizes; look and colour are T6's.
func _rolled_awning(pose: Transform3D, accent: String, title: String) -> void:
	var radius: float = 0.12
	var length: float = 6.5
	var axis: Transform3D = pose.translated_local(Vector3(0, 3.85, -0.15 - radius - 0.01)).rotated_local(Vector3.BACK, PI * 0.5)
	# The roll's axis is its local y; rotated_local(BACK, π/2) points it along the shop's −x, so the offset −(x0 + ½) puts
	# a stripe at shop x x0 + ½: stripe 0 (cream) is the west end, as in the stall.
	var stripe: float = length / float(ROLLED_STRIPES)
	for index: int in ROLLED_STRIPES:
		var x0: float = -length * 0.5 + float(index) * stripe
		_cylinder(axis, Vector3(0, -(x0 + stripe * 0.5), 0), radius, radius, stripe, "cloth_cream" if index % 2 == 0 else accent, 16)
	for x: float in [-2.2, 0.0, 2.2]:
		_cylinder(axis, Vector3(0, -x, 0), radius + 0.008, radius + 0.008, ROLLED_TIE, "wood", 16)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = length
	_solid("RolledAwning", axis, shape)
	# The valance hangs under the roll (T6 § 1, ТЗ 1): its top (y 3.73) is the roll's underside, so the whole roll shows
	# over it from the street. Its back face (z −0.28) is under the roll's lowest line (the roll's axis): at z −0.345, where
	# it stood, the 16-sided roll is 2.2 cm higher and the valance would float. It ends 3 cm inside each end of the roll,
	# so its ends never share the roll's end planes; the name stays 1.5 cm in front of it.
	_box(pose, Vector3(0, 3.60, -0.335), Vector3(6.44, 0.26, 0.11), "cloth_cream")
	_sign(pose * Vector3(0, 3.53, -0.405), title, 0.0067)

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
					# D9: the loaf lies on the board (top y + 0.045), not 3.9 cm over it.
					_loaf(pose.translated_local(Vector3(at.x, y + 0.045 + 0.14 * 0.72, at.z)), 0.72)
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
			# The fruit lies on the closed crate's lid (y 0.8), not 3.5 cm inside it.
			_primitive(fruit, display.translated_local(Vector3(-0.4 + float(i % 3) * 0.4, 0.915, -0.2 + float(i / 3) * 0.36)), "cloth_red" if side < 0 else "marker")
	# The beer barrel stands by the east display crate, out from under the herb rack (T6 docs/Audit/2026-10-15-T6-Geometry
	# -Fix-Acceptance.md § 4, choice «Б», T6's spot): 0.10 m off the crate, 0.25 m off the east wall, 0.43 m short of the
	# rack's south end. Under the rack (local z 3) a hero on the barrel had the rack board through his chest.
	_beer_barrel(pose.translated_local(Vector3(2.65, 0, 1.45)))
	_box(pose, Vector3(-0.6, 1.085, 5.55), Vector3(1.8, 0.035, 0.82), "cloth_cream")
	for index: int in 3:
		_loaf(pose.translated_local(Vector3(-1.2 + float(index) * 0.55, 1.21, 5.55)), 0.85)
	_jar(pose.translated_local(Vector3(0.5, 1.07, 5.6)), "cloth_teal", 0.7)
	# A wall herb rack gives the otherwise clear aisle a readable shop-specific silhouette. It hangs over head height
	# (its underside at 1.86 m; at 1.74 m a hero's head went through it). It is decor, so its jars have no collider:
	# solid, they were a 2.13 m perch a hero reached from the beer barrel under the rack (T6 acceptance
	# docs/Audit/2026-10-14-T6-Acceptance.md § 2.2, «бочка Шавлії»; the rack board never had one).
	_box(pose, Vector3(3.04, 1.9, 3.35), Vector3(0.3, 0.08, 2.35), "wood")
	for index: int in 4:
		var z: float = 2.5 + float(index) * 0.55
		_jar(pose.translated_local(Vector3(2.97, 1.95, z)), "terracotta", 0.55, false)
		# The sprigs stand in the jar's mouth (their foot 2 cm under its lip), not 4.5 cm over its shoulder.
		for sprig: int in 3:
			_cylinder(pose, Vector3(2.97, 2.43 + float(sprig % 2) * 0.12, z + float(sprig - 1) * 0.08), 0, 0.14, 0.46, "marker", 5)
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
	# D21: the dress form is solid where it has volume — its foot and its torso.
	var foot := CylinderShape3D.new()
	foot.radius = 0.48
	foot.height = 0.16
	_solid("DressFormFoot", pose.translated_local(Vector3(2.2, 0.08, 1)), foot)
	_solid("DressFormTorso", pose.translated_local(Vector3(2.2, 1.435, 1)), _dress_form_torso())
	# D17: the cutting table stands 0.25 m further from the counter aisle, so the service point (z 4.4) keeps a
	# hero capsule of r 0.35 clear of it (its edge was 0.30 m away).
	var cutting: Transform3D = pose.translated_local(Vector3(2.15, 0, 2.95))
	_table(cutting, Vector2(1.2, 1.8), "cloth_cream")
	# D10: the cloth lies on the top (y 1.0), not 2.2 cm over it.
	_box(cutting, Vector3(0.01, 1.0175, -0.05), Vector3(0.8, 0.035, 1.3), "cloth_teal")
	# D7: the three rolls lie on the counter top (y 1.07), not on steps of 3.5 and 7 cm over it.
	for i: int in 3:
		_box(pose, Vector3(-0.85 + float(i) * 0.52, 1.1, 5.6), Vector3(0.42, 0.06, 0.62), ["cloth_red", "cloth_teal", "cloth_cream"][i])
	# Two recognisable coats above the cutting table break the repeated stock-cylinder rhythm. The rail is held off the
	# wall by two brackets (it hung free 0.19 m from it), and both coats hang along the table, where no hero stands.
	_rod(pose * Vector3(3.01, 2.9, 1.95), pose * Vector3(3.01, 2.9, 3.95), 0.035, "brass")
	for z: float in [2.05, 3.85]:
		_rod(pose * Vector3(3.01, 2.9, z), pose * Vector3(3.2, 2.9, z), 0.02, "brass")
	for index: int in 2:
		_hanging_coat(pose.translated_local(Vector3(2.99, 0, 2.35 + float(index) * 1.2)), "cloth_red" if index == 0 else "cloth_teal")
	_sign(pose * Vector3(0, 2.7, 7.73), "КРІЙ · РЕМОНТ · ТКАНИНИ", 0.006)

## The dress form's torso collider, relative to the body at shop-local (2.2, 1.435, 1.0); the visible mesh is unchanged.
## T6 (docs/Audit/2026-10-15-T6-Geometry-Fix-Acceptance.md § 5, «манекен»): its flat top (a cylinder r 0.37 up to 1.96)
## held a hero who jumped onto it from the cutting table. Any top a capsule can stand over holds it: a contact within 45°
## of up is floor (floor_max_angle, unchanged by Fighter) — a cone up to the neck held the hero placed on its axis, a top
## slanted down from its own east edge held drops 0.27 m off that edge (probe, docs/Fix/2026-10-15-Stall-Wedge-Boundary
## -Fix.md § 3). So the top is one plane falling west at DRESS_FORM_SLOPE, and its high edge stands DRESS_FORM_WALL_GAP off
## the shop's east wall: a capsule's axis keeps 0.35 m off that wall, too far for the edge to carry it. Over the visible
## form the plane runs 1.38–2.32 m (DRESS_FORM_AXIS_TOP over the axis, 0.11 m under the neck): a walking hero (capsule
## body 0.35–1.45 m) still meets it from 0.91 m. The south side runs flat to the wall (the window base 0.49 m off it: a
## slanting side opened a 0.64–0.71 m slot there that wedged the hero), the north side narrows to 0.10 m at the wall, so
## the cutting table keeps the gap the round torso gave it (0.68 m over the axis, wider to the east). PLACEHOLDER.
const DRESS_FORM_SLOPE: float = 52.0      # degrees; 7° steeper than the floor angle
const DRESS_FORM_AXIS_TOP: float = 1.85
const DRESS_FORM_WALL_GAP: float = 0.02
## The round part's sides: with 16 the hero who stepped off the cutting table slid off a corner of the polygon to the
## form's foot (0.07 m) and lost the D exit T6 accepted; with 32 he rests where the cylinder held him (0.71 m) and both
## A and D lead to the floor, as on e7b3603 (probe, docs/Fix/2026-10-15-Stall-Wedge-Boundary-Fix.md § 3).
const DRESS_FORM_SIDES: int = 32

func _dress_form_torso() -> ConvexPolygonShape3D:
	var origin := Vector3(2.2, 1.435, 1.0)
	var wall_x: float = 3.2 - DRESS_FORM_WALL_GAP   # the shop's east wall, inner face (ShopWall at local x 3.3, 0.2 thick)
	var rise: float = tan(deg_to_rad(DRESS_FORM_SLOPE))
	var foot: Array[Vector2] = []
	for i: int in DRESS_FORM_SIDES:
		var angle: float = TAU * float(i) / float(DRESS_FORM_SIDES)
		foot.append(Vector2(origin.x + cos(angle) * 0.37, origin.z + sin(angle) * 0.37))
	foot.append(Vector2(wall_x, origin.z - 0.37))
	foot.append(Vector2(wall_x, origin.z + 0.10))
	var points := PackedVector3Array()
	for p: Vector2 in foot:
		var top: float = DRESS_FORM_AXIS_TOP + (p.x - origin.x) * rise
		points.append(Vector3(p.x, 0.91, p.y) - origin)
		points.append(Vector3(p.x, top, p.y) - origin)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	return shape

func _workshop(pose: Transform3D) -> void:
	# D17: as in the atelier, the workbench keeps the service point (z 4.4) clear of a hero capsule of r 0.35.
	var bench: Transform3D = pose.translated_local(Vector3(2.3, 0, 2.95))
	_table(bench, Vector2(1.05, 1.8), "wood")
	# Workbench vise, hanging tools, clock parts and a waiting stool. D6: the vise stands on the top (y 1.0).
	_box(bench, Vector3(0, 1.14, 0), Vector3(0.5, 0.28, 0.4), "iron")
	_rod(bench * Vector3(-0.3, 1.2, 0), bench * Vector3(0.35, 1.2, 0), 0.035, "brass")
	_box(pose, Vector3(3.16, 2.17, 3.23), Vector3(0.065, 1.25, 2.45), "wood")
	for row: int in 3:
		for column: int in 9:
			_box(pose, Vector3(3.119, 1.73 + float(row) * 0.43, 2.22 + float(column) * 0.25), Vector3(0.012, 0.035, 0.035), "ink")
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
	# D10: the clock's back (0.11 m deep at scale 0.75) is on the back wall's face (z 7.8), not 3.9 cm off it.
	_wall_clock(pose.translated_local(Vector3(2.55, 2.8, 7.8 - 0.055 * 0.75)).scaled_local(Vector3.ONE * 0.75))
	_stool(pose.translated_local(Vector3(-2.2, 0, 1.15)))
	_sign(pose * Vector3(0, 2.7, 7.73), "ГОДИННИКИ · МЕХАНІЗМИ", 0.006)

func _hanging_coat(pose: Transform3D, cloth: String) -> void:
	for side: float in [-1.0, 1.0]:
		_rod(pose * Vector3(0, 2.9, 0), pose * Vector3(0, 2.62, side * 0.29), 0.018, "brass")
		var sleeve := pose.translated_local(Vector3(-0.04, 2.31, side * 0.38)).rotated_local(Vector3.RIGHT, side * 0.55)
		_box(sleeve, Vector3.ZERO, Vector3(0.14, 0.49, 0.23), cloth)
	_box(pose, Vector3(-0.06, 2.15, 0), Vector3(0.15, 0.86, 0.56), cloth)
	_box(pose, Vector3(-0.06, 1.74, 0), Vector3(0.17, 0.13, 0.64), cloth)
	_box(pose, Vector3(-0.145, 2.17, 0), Vector3(0.01, 0.72, 0.024), "brass")   # clear of the hem's face plane
	for side: float in [-1.0, 1.0]:
		_box(pose, Vector3(-0.15, 1.99, side * 0.18), Vector3(0.014, 0.11, 0.16), "cloth_cream")

func _wall_clock(pose: Transform3D) -> void:
	var face := pose.rotated_local(Vector3.RIGHT, PI * 0.5)
	_cylinder(face, Vector3.ZERO, 0.63, 0.63, 0.11, "wood", 24)
	_cylinder(face, Vector3(0, -0.065, 0), 0.54, 0.54, 0.025, "cloth_cream", 24)
	for hour: int in 12:
		var angle: float = float(hour) * TAU / 12.0
		var mark := pose.translated_local(Vector3(sin(angle) * 0.44, cos(angle) * 0.44, -0.09)).rotated_local(Vector3.BACK, -angle)
		_box(mark, Vector3.ZERO, Vector3(0.025, 0.085, 0.02), "ink")
	_box(pose, Vector3(0, 0.16, -0.11), Vector3(0.035, 0.34, 0.025), "ink")
	_box(pose.rotated_local(Vector3.BACK, -1.05), Vector3(0, 0.12, -0.11), Vector3(0.045, 0.25, 0.025), "ink")

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
	_box(guide, Vector3(0, 1.9, 0), Vector3(0.11, 3.8, 0.11), "iron_paint", "WayfindingPost")   # 1.5 cm inside the boards' faces
	_box(guide, Vector3(0, 3.35, 0), Vector3(3.3, 0.58, 0.14), "cloth_teal")
	_sign(guide * Vector3(0, 3.35, 0.085), "‹  КРАМНИЦІ", 0.0065, 0.0)   # no arrows in the built-in font
	_box(guide, Vector3(0, 2.7, 0), Vector3(3.3, 0.5, 0.14), "wood")
	_sign(guide * Vector3(0, 2.7, 0.085), "ВЕЖА · МІСТ  ›", 0.0056, 0.0)
	# Backed wall notices add identity without placing scenery in walkable aisles.
	for shop: Dictionary in Places.shops():
		var at: Vector3 = shop.door + Vector3(0, 2.72, 7.77)
		_box(Transform3D.IDENTITY, at + Vector3(0, 0, 0.04), Vector3(3.7, 0.58, 0.06), "wood")
	# A rest corner beside the west court preserves its five-metre playable circle. The west bench stands 0.2 m
	# further west than before: its east planter, now solid (D20), keeps a 0.35 m hero clear of the route along x −22.
	for x: float in [-24.7, -14.0]:
		var pose := Transform3D(Basis.IDENTITY, Vector3(x, 0, 8))
		_box(pose, Vector3(0, 0.5, 0), Vector3(2.4, 0.14, 0.7), "wood", "StreetBench")
		_box(pose, Vector3(0, 1, 0.28), Vector3(2.4, 0.62, 0.13), "wood", "BenchBack")
		for side: float in [-1.0, 1.0]:
			_box(pose, Vector3(side * 0.92, 0.22, 0), Vector3(0.13, 0.44, 0.55), "iron_paint")
			# Uprights from the seat to the back (the back floated 0.12 m over the seat).
			_box(pose, Vector3(side * 0.92, 0.63, 0.28), Vector3(0.08, 0.14, 0.08), "iron_paint")
			_cylinder(pose, Vector3(side * 1.75, 0.3, 0), 0.4, 0.29, 0.6, "terracotta")
			for sprig: int in 3:
				_cylinder(pose, Vector3(side * 1.75 + float(sprig - 1) * 0.15, 0.85, 0), 0.0, 0.22, 0.7, "marker", 5)
			# D20: the planter is solid (its pot widens from r 0.29 to 0.4; the collider takes the rim).
			var planter := CylinderShape3D.new()
			planter.radius = 0.4
			planter.height = 0.6
			_solid("BenchPlanter", pose.translated_local(Vector3(side * 1.75, 0.3, 0)), planter)
