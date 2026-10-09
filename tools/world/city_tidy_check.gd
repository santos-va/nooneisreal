extends SceneTree
## Plan docs/Plans/2026-10-09-City-Tidy-And-Modern-Props.md, phase 0 (steps 0a and 0b), on the real CityWorld.
## Subject: for every visible part of the district — none enters a window pane, every prop rests on what is under it or
## hangs from the structure, no two faces of different materials flicker in one plane, nothing exists twice, and the
## hero is stopped wherever a visible part stands in his way; the new props keep the T6 places and both heroes vault the
## new obstacles with real keys.
##   C1 pane    — no prop or anchor support goes more than 2 cm (SAT over oriented boxes) into a window pane (the audit
##                compares props with structure, never structure with structure);
##   C2 support — a prop with something under it (≥ 20 % of its footprint, up to 0.3 m) rests within 2 cm of it, neither
##                floating nor sunk — unless it is fixed to a wall beside it (a structure within 2 cm rising over its
##                foot) and stands clearly off the floor (≥ 0.1 m, T6 П4), when only sinking counts; a prop with nothing
##                under it hangs, through touching parts, from the structure;
##   D17/19/24  — a hero (r 0.35, Fighter.tscn) stands free at every shop's approach, visit and service point; each solid
##                balcony side has ≥ 3 balusters inside it; the street faces of the end shop walls are street material;
##   C3 zfight  — no two faces of different materials face the same way in one plane (< 6 mm apart) over ≥ 2 cm² where
##                the patch shows (not inside a third box within 0.1 m, not under the ground);
##   C4 dup     — no two visible parts (kind, centre, extent) and no two colliders (shape, transform) are equal to 1 mm;
##   C5 solid   — a part in the hero band (floor + 0.12…1.8 m, ≥ 0.08 m wide, ≥ 0.4 l) that ≤ 13 of its 27 points have in
##                a collider can never be entered 0.1 m deep by a free hero capsule (r 0.32, h 1.8) standing on that floor
##                (within 0.3 m of it: walking, not standing on furniture);
##   K          — new props ≥ 8 m from the court centre, pockets empty, ≥ 1 m from resident lanes; the southeast passage
##                keeps its 4 m, its axis and event points and its camera, its pipes ≤ 0.25 m out of the wall and ≥ 3.2 m
##                up; every anchor keeps the floor its rope fell to on 97675c7 (anchor 5: the street, its canopy rolled)
##                and no new collider stands in its column;
##                obstacles 0.9–1.1 m high, ≤ 0.8 m deep, level floor on both sides; no `ink` surface wider than 0.2 m
##                and no long ink strip on the street; no letters in the props; groups of ≤ 5, ≤ 3 of a kind; one mesh
##                per material and no light in the props;
##   V          — Choko and Skea vault every obstacle from each side with a free run-up, by real key events (W, Space):
##                vault_seconds of the shipped profile ± 1 tick, no hang, landing beyond at the take-off level;
##   S          — each steam vent puffs (≤ 0.8 opacity), changes frame under 3 times a second, never jumps in opacity
##                by more than 0.1 a frame, stays ≤ 1.0 × 1.5 m and is gone while a hero stands at the vent.
## Literals: docs/Audit/2026-10-08-City-Tidy-Technical-Audit.md § 2 (2 cm, 0.3 m, 20 %, 6 mm, 2 cm², 0.1 m, 1 mm, r 0.32,
## 0.12–1.8 m, 13/27, 0.08 m, 0.4 l); docs/Art/2026-10-08-City-Modern-Realism-Props.md (П4 0.1 m, К4 0.2 m, К6 8 m / 1 m,
## Н7 0.25 m / 3.2 m, К8 5 / 3); the plan (obstacles 0.9–1.1 m, ≤ 0.8 m); 2026-10-07-Tight-Station-Readability-Criteria
## (≥ 3 m of camera); WCAG 2.3.1 (< 3 flashes a second). The anchor floors were measured on 97675c7 (see ANCHOR_FLOOR).
## --break=<m> is a negative control: one returned defect or another form of the same class (see MUTATIONS); sentinel
## CITY_TIDY_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_TIDY: ...".
const DT: float = 1.0 / 60.0
const GEOMETRY_BREAKS := ["pane_strut", "pane_wire", "float_barrel", "float_loaf", "sink_crate", "float_plate",
	"zfight_fascia", "zfight_jamb", "dup_wall", "dup_barrel", "solid_planter", "solid_dressform", "solid_sign", "service",
	"pump_spout", "pump_lever", "pump_layer"]
const PLACE_BREAKS := ["court", "anchor", "passage", "lane", "ink_strip"]
const VAULT_BREAKS := ["vault_high", "vault_deep"]
const STEAM_BREAKS := ["steam_hero", "steam_flash"]
const PANE_DEPTH: float = 0.02
const SUPPORT_GAP: float = 0.02
const SUPPORT_WINDOW: float = 0.3
const SUPPORT_SHARE: float = 0.2
const PLANE_GAP: float = 0.006
const PLANE_AREA: float = 0.0002
const BURIED_REACH: Array[float] = [0.0, 0.01, 0.03, 0.06, 0.1]
const SAME: float = 0.001
const HERO_R: float = 0.32
const BAND := Vector2(0.12, 1.8)
const COVERED: int = 13
const MIN_EXTENT: float = 0.08
const MIN_VOLUME: float = 0.0004
const PASS_THROUGH: float = 0.1
const COURT_CLEAR: float = 8.0
const LANE_CLEAR: float = 1.0
const PASSAGE_REACH: float = 0.25
const MAIN_HEIGHT: float = 3.2
const OBSTACLE_HEIGHT := Vector2(0.9, 1.1)
const OBSTACLE_DEPTH: float = 0.8
const INK_WIDTH: float = 0.2
const GROUP_MAX: int = 5
const SAME_KIND_MAX: int = 3
const CAMERA_SPACE: float = 3.0
const FLASH_HZ: float = 3.0
const PUFF_SIZE := Vector2(1.0, 1.5)
## The first floor under each anchor (ray down, mask 9) on 97675c7: `probe_inventory.gd` (scratchpad city-tidy/) →
## anchors.json, the same ray. Canopies of the four market stalls are under anchors 4–7 (audit D18).
## One deliberate change: anchor 5 (8.6, 6.7, 24.6) was 2.8023 (the east z 25 stall's spread canopy). T1 rolled that
## canopy up (Н6 «rolled», plan 2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum «Рішення T1 після кроків 1–4») because
## its edge cut the anchor's rope on the swing; now the rope falls to the street, 0.0. Anchors 4, 6, 7 keep their
## canopies and their 97675c7 floors; every other anchor is unchanged.
const ANCHOR_FLOOR: Array[float] = [0.0, 0.0, 0.0, 0.0, 2.8109, 0.0, 2.8109, 2.8023, 0.0, 0.0, 0.0, 3.83, 3.83, 3.83,
	0.0, 0.0, 0.0, 0.0, 0.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0]
const ANCHOR_COLUMN: float = 0.75
const HEX := {"8a8581": "paving", "9d9385": "stone", "9f7b73": "brick", "a9847b": "terracotta", "b6aa92": "plaster",
	"607078": "slate", "61717b": "roof_slate", "748075": "copper", "998162": "brass", "3b353c": "iron", "2b2230": "ink",
	"4d6b70": "glass", "b79a60": "warm_window", "756454": "wood", "b9ad96": "cloth_cream", "98685e": "cloth_red",
	"617b79": "cloth_teal", "a6b79e": "marker"}
const DISTRICT_STRUCTURE := ["Ground", "NorthWestRoof", "NorthEastRoof", "SouthWestBlock", "SouthWestRear",
	"SouthEastWestWing", "SouthEastEastWing", "PassageLintel", "RoofBridge", "ClockTower", "WestBoundary",
	"EastBoundary", "NorthBoundary", "SouthBoundary", "EastRamp", "WestRamp", "PracticeLedge", "RoofApproachLow",
	"RoofApproachHigh", "PracticeLedgeGripLip", "RoofApproachLowGripLip", "RoofApproachHighGripLip"]
const MAINTENANCE_STRUCTURE := ["SouthWall", "EastWall", "NorthWall", "WestNorthWall", "WestSouthWall", "ServiceGate",
	"GateLintel", "OuterServiceRamp", "InnerServiceRamp", "ServiceGallery", "GalleryNorthRail", "GalleryPost"]
const GALLERY_STRUCTURE := ["NorthWall", "SouthWall", "EastWall", "EntryNorth", "EntrySouth", "EntryLintel",
	"ArchiveCanopy", "ArchiveFloor"]
## The water pump (CityWaterPump.gd) used to print its C5 findings as CITY_TIDY_OPEN: it belonged to the parallel branch.
## After the merge (T1, plan 2026-10-09 «Рішення T1 після кроків 1–4») its spout and lever have colliders and C5 checks
## it like every other prop; negatives pump_spout, pump_lever, pump_layer.

var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var world: Node3D
var district: Node3D
var props_node: Node3D
var space: PhysicsDirectSpaceState3D
var parts: Array[Dictionary] = []
var grid: Dictionary = {}
var fighter_script: Script
var arch_solids: Array[Dictionary] = []


class Rec extends RefCounted:
	var parts: Array[Dictionary] = []
	var stack: PackedStringArray = PackedStringArray()
	var module: String = ""
	static func at(label: String, v: Vector3) -> String:
		return "%s@%.2f,%.2f,%.2f" % [label, v.x, v.y, v.z]
	func push(label: String) -> void:
		stack.append(label)
	func pop() -> void:
		stack.remove_at(stack.size() - 1)
	func part(kind: String, xf: Transform3D, local: AABB, material: String) -> void:
		parts.append({"module": module, "ctx": "/".join(stack), "kind": kind, "mat": material, "xf": xf, "local": local, "visible": true})


class FakeDistrict extends Node3D:
	var materials: Dictionary = {}
	var geometry_count: int = 0


class ArchRec extends CityArchitecture:
	var rec: Rec
	var solids: Array[Dictionary] = []
	func _mesh(mesh: Mesh, center: Vector3, material: String, basis: Basis = Basis.IDENTITY) -> void:
		rec.part(mesh.get_class(), Transform3D(basis, center), mesh.get_aabb(), material)
		super(mesh, center, material, basis)
	func _collider(center: Vector3, size: Vector3, basis: Basis) -> void:
		solids.append({"ctx": "/".join(rec.stack), "xf": Transform3D(basis, center), "size": size})
		super(center, size, basis)
	func _building(center: Vector3, size: Vector3, bottom: float) -> void:
		rec.push(Rec.at("building", center)); super(center, size, bottom); rec.pop()
	func _facade(origin: Vector3, width: float, height: float, yaw: float, balconies: bool) -> void:
		rec.push(Rec.at("facade", origin)); super(origin, width, height, yaw, balconies); rec.pop()
	func _window(origin: Vector3, basis: Basis, bottom: Vector3, width: float, height: float, warm: bool) -> void:
		rec.push(Rec.at("arch_window", origin + basis * bottom)); super(origin, basis, bottom, width, height, warm); rec.pop()
	func _rectangular_window(origin: Vector3, basis: Basis, bottom: Vector3, width: float, height: float, warm: bool) -> void:
		rec.push(Rec.at("rect_window", origin + basis * bottom)); super(origin, basis, bottom, width, height, warm); rec.pop()
	func _balcony(origin: Vector3, basis: Basis, bottom: Vector3, width: float) -> void:
		rec.push(Rec.at("balcony", origin + basis * bottom)); super(origin, basis, bottom, width); rec.pop()
	func _mansard(center: Vector3, size: Vector3, top: float) -> void:
		rec.push(Rec.at("mansard", center)); super(center, size, top); rec.pop()


class MarketRec extends CityMarket:
	var rec: Rec
	func _primitive(mesh: Mesh, pose: Transform3D, material: String) -> void:
		rec.part(mesh.get_class(), pose, mesh.get_aabb(), material)
		super(mesh, pose, material)
	func _quad(material: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
		rec.part("Quad", Transform3D.IDENTITY, AABB(a, Vector3.ZERO).expand(b).expand(c).expand(d), material)
		super(material, a, b, c, d)
	func _stall(pose: Transform3D, cloth: String, state: String = "full", goods_seed: int = 0) -> void:
		rec.push(Rec.at("stall", pose.origin)); super(pose, cloth, state, goods_seed); rec.pop()
	func _canopy(pose: Transform3D, color: String) -> void:
		rec.push("canopy"); super(pose, color); rec.pop()
	func _crate(pose: Transform3D, size: Vector3) -> void:
		rec.push(Rec.at("crate", pose.origin)); super(pose, size); rec.pop()
	func _beer_barrel(pose: Transform3D) -> void:
		rec.push(Rec.at("beer_barrel", pose.origin)); super(pose); rec.pop()
	func _trestle_barrel(pose: Transform3D) -> void:
		rec.push(Rec.at("trestle_barrel", pose.origin)); super(pose); rec.pop()
	func _jar(pose: Transform3D, color: String, scale_factor: float) -> void:
		rec.push(Rec.at("jar", pose.origin)); super(pose, color, scale_factor); rec.pop()
	func _wire(a: Vector3, b: Vector3, sag: float) -> void:
		rec.push(Rec.at("wire", a)); super(a, b, sag); rec.pop()
	func _lantern(center: Vector3, scale_factor: float) -> void:
		rec.push(Rec.at("lantern", center)); super(center, scale_factor); rec.pop()


class InteriorsRec extends CityInteriors:
	var rec: Rec
	func _primitive(mesh: Mesh, pose: Transform3D, material: String) -> void:
		rec.part(mesh.get_class(), pose, mesh.get_aabb(), material)
		super(mesh, pose, material)
	func _quad(material: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
		rec.part("Quad", Transform3D.IDENTITY, AABB(a, Vector3.ZERO).expand(b).expand(c).expand(d), material)
		super(material, a, b, c, d)
	func _shop(shop: Dictionary) -> void:
		rec.push("shop:" + String(shop.id)); super(shop); rec.pop()
	func _counter(pose: Transform3D, accent: String) -> void:
		rec.push(Rec.at("counter", pose.origin)); super(pose, accent); rec.pop()
	func _shelf(pose: Transform3D, kind: String) -> void:
		rec.push(Rec.at("shelf", pose.origin)); super(pose, kind); rec.pop()
	func _grocer(pose: Transform3D) -> void:
		rec.push("grocer"); super(pose); rec.pop()
	func _loaf(pose: Transform3D, size: float) -> void:
		rec.push(Rec.at("loaf", pose.origin)); super(pose, size); rec.pop()
	func _tailor(pose: Transform3D) -> void:
		rec.push("tailor"); super(pose); rec.pop()
	func _workshop(pose: Transform3D) -> void:
		rec.push("workshop"); super(pose); rec.pop()
	func _hanging_coat(pose: Transform3D, cloth: String) -> void:
		rec.push(Rec.at("coat", pose.origin)); super(pose, cloth); rec.pop()
	func _wall_clock(pose: Transform3D) -> void:
		rec.push(Rec.at("wall_clock", pose.origin)); super(pose); rec.pop()
	func _table(pose: Transform3D, size: Vector2, material: String) -> void:
		rec.push(Rec.at("table", pose.origin)); super(pose, size, material); rec.pop()
	func _stool(pose: Transform3D) -> void:
		rec.push(Rec.at("stool", pose.origin)); super(pose); rec.pop()
	func _street_furniture() -> void:
		rec.push("street_furniture"); super(); rec.pop()
	func _crate(pose: Transform3D, size: Vector3) -> void:
		rec.push(Rec.at("crate", pose.origin)); super(pose, size); rec.pop()
	func _beer_barrel(pose: Transform3D) -> void:
		rec.push(Rec.at("beer_barrel", pose.origin)); super(pose); rec.pop()
	func _jar(pose: Transform3D, color: String, scale_factor: float) -> void:
		rec.push(Rec.at("jar", pose.origin)); super(pose, color, scale_factor); rec.pop()
	func _lantern(center: Vector3, scale_factor: float) -> void:
		rec.push(Rec.at("lantern", center)); super(center, scale_factor); rec.pop()


class PropsRec extends CityProps:
	var rec: Rec
	func _primitive(mesh: Mesh, pose: Transform3D, material: String) -> void:
		rec.part(mesh.get_class(), pose, mesh.get_aabb(), material)
		super(mesh, pose, material)
	func _crate(pose: Transform3D, size: Vector3) -> void:
		rec.push(Rec.at("crate", pose.origin)); super(pose, size); rec.pop()
	func _beer_barrel(pose: Transform3D) -> void:
		rec.push(Rec.at("beer_barrel", pose.origin)); super(pose); rec.pop()
	func _water_butt(pose: Transform3D) -> void:
		rec.push(Rec.at("water_butt", pose.origin)); super(pose); rec.pop()
	func _tar_barrel(pose: Transform3D) -> void:
		rec.push(Rec.at("tar_barrel", pose.origin)); super(pose); rec.pop()
	func _downpipe(points: Array[Vector3], clamps: Array[Vector4]) -> void:
		rec.push(Rec.at("downpipe", points[0])); super(points, clamps); rec.pop()
	func _obstacle(spec: Dictionary) -> void:
		rec.push(Rec.at("obstacle", spec.center)); super(spec); rec.pop()
	func _urn(pose: Transform3D) -> void:
		rec.push(Rec.at("urn", pose.origin)); super(pose); rec.pop()
	func _steam_main() -> void:
		rec.push(Rec.at("steam_main", Vector3(MAIN_X, MAIN_Y, MAIN_Z.x))); super(); rec.pop()
	func _steam_vent(spec: Dictionary) -> void:
		rec.push(Rec.at("steam_vent", spec.center)); super(spec); rec.pop()


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_TIDY: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _phase(name: String) -> bool:
	match name:
		"geometry":
			return mutation == "none" or mutation in GEOMETRY_BREAKS
		"places":
			return mutation == "none" or mutation in PLACE_BREAKS
		"vault":
			return mutation == "none" or mutation in VAULT_BREAKS
		"steam":
			return mutation == "none" or mutation in STEAM_BREAKS
	return false


static func _v(v: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]


# --- the world ---------------------------------------------------------------------------------------------------
func _open_world(hero: String) -> void:
	root.get_node("GameState").p1_character = hero
	world = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	await _ticks(20)
	district = world.district
	props_node = district.get_node("CityProps")
	space = world.get_world_3d().direct_space_state


func _close_world() -> void:
	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	world.queue_free()
	current_scene = null
	await _ticks(3)


# --- parts -------------------------------------------------------------------------------------------------------
func _shape(p: Dictionary) -> void:
	var xf: Transform3D = p.xf
	var local: AABB = p.local
	var center: Vector3 = xf * (local.position + local.size * 0.5)
	var axes: Array[Vector3] = []
	var half := Vector3.ZERO
	var extent := Vector3.ZERO
	for k: int in 3:
		var column: Vector3 = xf.basis[k]
		var length: float = column.length()
		var unit: Vector3 = column / length if length > 0.000001 else Vector3.ZERO
		axes.append(unit)
		half[k] = length * local.size[k] * 0.5
		extent += (unit * half[k]).abs()
	p.center = center
	p.axes = axes
	p.half = half
	p.amin = center - extent
	p.amax = center + extent


func _move(selection: Array[Dictionary], offset: Vector3) -> void:
	for p: Dictionary in selection:
		p.xf = (p.xf as Transform3D).translated(offset)
		_shape(p)


func _select(module: String, needle: String, first_group_only: bool = true) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var group: String = ""
	for p: Dictionary in parts:
		if p.module != module or String(p.ctx).find(needle) < 0:
			continue
		var start: int = String(p.ctx).find(needle)
		var end: int = String(p.ctx).find("/", start)
		var owner: String = String(p.ctx).substr(0, end) if end >= 0 else String(p.ctx)
		if first_group_only:
			if group.is_empty():
				group = owner
			elif owner != group:
				continue
		result.append(p)
	return result


func _record_builders() -> void:
	var rec := Rec.new()
	var fake := FakeDistrict.new()
	fake.materials = CityMaterials.palette()
	rec.module = "CityArchitecture"
	var arch := ArchRec.new()
	arch.rec = rec
	arch._build(fake)
	arch_solids = arch.solids
	fake.free()
	for spec: Array in [["CityMarket", MarketRec.new()], ["CityInteriors", InteriorsRec.new()], ["CityProps", PropsRec.new()]]:
		rec.module = spec[0]
		var node: Node3D = spec[1]
		node.set("rec", rec)
		node._ready()
		node.free()
	var to_world: Transform3D = district.global_transform
	for entry: Dictionary in rec.parts:
		entry.xf = to_world * (entry.xf as Transform3D)
		entry.live = false
		_shape(entry)
		parts.append(entry)


func _material_key(material: Material) -> String:
	if material is ShaderMaterial:
		var hex: String = ((material as ShaderMaterial).get_shader_parameter("albedo") as Color).to_html(false)
		return String(HEX.get(hex, "#" + hex))
	if material is StandardMaterial3D:
		return "std#" + (material as StandardMaterial3D).albedo_color.to_html(false)
	return "none"


func _live_parts() -> void:
	for node: Node in district.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var path: PackedStringArray = String(district.get_path_to(mesh)).split("/")
		var top: String = path[0]
		if mesh.mesh == null or top in ["CityMarket", "CityInteriors", "CityProps", "CityBackdrop"] or top.begins_with("Architecture_"):
			continue
		var module: String = "CityDistrict"
		if top in ["CityMaintenance", "CityLowerGallery", "WaterPump"]:
			module = top
		var entry := {"module": module, "ctx": "/".join(path), "kind": mesh.mesh.get_class(), "mat": _material_key(mesh.material_override),
			"xf": mesh.global_transform, "local": mesh.mesh.get_aabb(), "visible": mesh.is_visible_in_tree(), "live": true}
		_shape(entry)
		parts.append(entry)


## role: struct | pane | anchor | prop; group: the prop instance.
func _classify() -> void:
	for p: Dictionary in parts:
		var ctx: String = p.ctx
		var elements: PackedStringArray = ctx.split("/")
		p.role = "prop"
		p.group = ""
		p.window = ""
		if p.module == "CityArchitecture":
			p.role = "struct"
			for index: int in elements.size():
				if elements[index].begins_with("arch_window@") or elements[index].begins_with("rect_window@") or elements[index].begins_with("mansard@"):
					p.window = "/".join(elements.slice(0, index + 1))
			if p.mat in ["glass", "warm_window"] and not String(p.window).is_empty():
				p.role = "pane"
			continue
		if p.live:
			var top: String = elements[0] if p.module == "CityDistrict" else (elements[1] if elements.size() > 1 else elements[0])
			if p.module == "CityDistrict":
				if top.begins_with("Anchor"):
					p.role = "anchor"
					p.group = "anchor:" + top.trim_prefix("AnchorPost").trim_prefix("AnchorArm").trim_prefix("AnchorPlate").trim_prefix("AnchorStrut").trim_prefix("AnchorCeramic").trim_prefix("AnchorBracket")
				elif top in DISTRICT_STRUCTURE or top.begins_with("NorthParapet") or top.begins_with("BridgeParapet"):
					p.role = "struct"
				else:
					p.group = "cc:CityDistrict"
			elif p.module == "CityMaintenance" and top in MAINTENANCE_STRUCTURE:
				p.role = "struct"
			elif p.module == "CityLowerGallery" and top in GALLERY_STRUCTURE:
				p.role = "struct"
			else:
				p.group = "cc:" + String(p.module)
			continue
		if p.module == "CityInteriors" and elements.size() == 1 and ctx.begins_with("shop:"):
			p.role = "struct"
			continue
		var deepest: int = -1
		for index: int in elements.size():
			if elements[index].find("@") >= 0:
				deepest = index
		if deepest >= 0:
			p.group = String(p.module) + ":" + "/".join(elements.slice(0, deepest + 1))
		else:
			p.group = "cc:" + String(p.module) + ":" + ctx
	# Parts of one cc: group that touch (≤ 1 cm) are one prop.
	var by_group: Dictionary = {}
	for index: int in parts.size():
		var p: Dictionary = parts[index]
		if p.role == "prop" and String(p.group).begins_with("cc:"):
			if not by_group.has(p.group):
				by_group[p.group] = []
			by_group[p.group].append(index)
	for key: String in by_group:
		var members: Array = by_group[key]
		var parent: Dictionary = {}
		for index: int in members:
			parent[index] = index
		for a: int in members.size():
			for b: int in range(a + 1, members.size()):
				if _aabb_gap(parts[members[a]], parts[members[b]]) <= 0.01:
					var ra: int = _find(parent, members[a])
					var rb: int = _find(parent, members[b])
					if ra != rb:
						parent[ra] = rb
		for index: int in members:
			parts[index].group = key + "#" + str(_find(parent, index))


func _find(parent: Dictionary, index: int) -> int:
	while parent[index] != index:
		parent[index] = parent[parent[index]]
		index = parent[index]
	return index


func _aabb_gap(a: Dictionary, b: Dictionary) -> float:
	var gap: Vector3 = ((a.amin as Vector3) - (b.amax as Vector3)).max((b.amin as Vector3) - (a.amax as Vector3)).max(Vector3.ZERO)
	return gap.length()


func _index_grid() -> void:
	grid.clear()
	for index: int in parts.size():
		var p: Dictionary = parts[index]
		var a: Vector3 = p.amin
		var b: Vector3 = p.amax
		for gx: int in range(floori(a.x / 2.0), floori(b.x / 2.0) + 1):
			for gz: int in range(floori(a.z / 2.0), floori(b.z / 2.0) + 1):
				var key := Vector2i(gx, gz)
				if not grid.has(key):
					grid[key] = []
				grid[key].append(index)


func _near(a: Vector3, b: Vector3, pad: float) -> Array[int]:
	var seen: Dictionary = {}
	var result: Array[int] = []
	for gx: int in range(floori((a.x - pad) / 2.0), floori((b.x + pad) / 2.0) + 1):
		for gz: int in range(floori((a.z - pad) / 2.0), floori((b.z + pad) / 2.0) + 1):
			for index: int in grid.get(Vector2i(gx, gz), []):
				if seen.has(index):
					continue
				seen[index] = true
				var q: Dictionary = parts[index]
				if ((q.amin as Vector3) - Vector3.ONE * pad).x <= b.x and (q.amax as Vector3).x + pad >= a.x \
						and (q.amin as Vector3).y - pad <= b.y and (q.amax as Vector3).y + pad >= a.y \
						and (q.amin as Vector3).z - pad <= b.z and (q.amax as Vector3).z + pad >= a.z:
					result.append(index)
	return result


func _inside_district(p: Dictionary) -> bool:
	var c: Vector3 = p.center
	return absf(c.x) < 33.5 and absf(c.z) < 33.5


func _sat(a: Dictionary, b: Dictionary) -> float:
	var axes: Array[Vector3] = []
	for k: int in 3:
		axes.append(a.axes[k])
		axes.append(b.axes[k])
	for i: int in 3:
		for j: int in 3:
			var cross: Vector3 = (a.axes[i] as Vector3).cross(b.axes[j])
			if cross.length() > 0.000001:
				axes.append(cross.normalized())
	var d: Vector3 = (b.center as Vector3) - (a.center as Vector3)
	var best: float = INF
	for axis: Vector3 in axes:
		if axis == Vector3.ZERO:
			continue
		var ra: float = 0.0
		var rb: float = 0.0
		for k: int in 3:
			ra += float(a.half[k]) * absf((a.axes[k] as Vector3).dot(axis))
			rb += float(b.half[k]) * absf((b.axes[k] as Vector3).dot(axis))
		best = minf(best, ra + rb - absf(d.dot(axis)))
		if best < 0.0:
			return best
	return best


func _label(p: Dictionary) -> String:
	var name: String = String(p.group) if not String(p.group).is_empty() else String(p.ctx)
	return "%s %s %s %s" % [p.module, name.get_slice("#", 0), p.mat, _v(p.center)]


# --- C1 ----------------------------------------------------------------------------------------------------------
func _c1_panes() -> void:
	var count: int = 0
	var bad: int = 0
	for index: int in parts.size():
		var pane: Dictionary = parts[index]
		if pane.role != "pane" or not pane.visible:
			continue
		count += 1
		for other: int in _near(pane.amin, pane.amax, 0.0):
			var q: Dictionary = parts[other]
			if other == index or not q.visible or q.kind == "Quad" or q.role in ["struct", "pane"]:
				continue
			var depth: float = _sat(pane, q)
			if depth > PANE_DEPTH:
				bad += 1
				_check(false, "C1 %s goes %.3f m into the pane %s" % [_label(q), depth, _v(pane.center)])
	_check(count > 150, "C1 the panes were found (%d)" % count)
	_check(bad == 0, "C1 no part goes more than %.2f m into a window pane (%d)" % [PANE_DEPTH, bad])
	print("CITY_TIDY_INFO C1 panes=%d intrusions=%d" % [count, bad])


# --- C2 ----------------------------------------------------------------------------------------------------------
func _c2_support() -> void:
	var groups: Dictionary = {}
	for index: int in parts.size():
		var p: Dictionary = parts[index]
		if p.role != "prop" or not p.visible or p.kind == "Quad" or not _inside_district(p):
			continue
		if not groups.has(p.group):
			groups[p.group] = []
		groups[p.group].append(index)
	var verdict: Dictionary = {}   # group → "rest" | "hang"
	var bad: int = 0
	for key: String in groups:
		var members: Array = groups[key]
		var member_set: Dictionary = {}
		var bottom: float = INF
		for index: int in members:
			member_set[index] = true
			bottom = minf(bottom, float((parts[index].amin as Vector3).y))
		var foot := Rect2()
		var started: bool = false
		for index: int in members:
			var p: Dictionary = parts[index]
			if float((p.amin as Vector3).y) < bottom + 0.05:
				var r := Rect2(Vector2(p.amin.x, p.amin.z), Vector2(p.amax.x - p.amin.x, p.amax.z - p.amin.z))
				foot = r if not started else foot.merge(r)
				started = true
		var area: float = maxf(foot.get_area(), 0.000001)
		var lo := Vector3(foot.position.x, bottom - SUPPORT_WINDOW, foot.position.y)
		var hi := Vector3(foot.end.x, bottom + SUPPORT_WINDOW, foot.end.y)
		var tops: Array[float] = []
		for other: int in _near(lo, hi, 0.0):
			var q: Dictionary = parts[other]
			if member_set.has(other) or not q.visible or q.kind == "Quad" or q.role == "pane":
				continue
			if float(q.amax.y) > bottom + SUPPORT_WINDOW or float(q.amin.y) > bottom:
				continue
			var r := Rect2(Vector2(q.amin.x, q.amin.z), Vector2(q.amax.x - q.amin.x, q.amax.z - q.amin.z))
			if foot.intersection(r).get_area() >= SUPPORT_SHARE * area:
				tops.append(float(q.amax.y))
		if tops.is_empty():
			verdict[key] = "hang"
			continue
		verdict[key] = "rest"
		var resting: bool = false
		for top: float in tops:
			resting = resting or absf(top - bottom) <= SUPPORT_GAP
		if resting:
			continue
		var top: float = tops.max()
		var gap: float = bottom - top
		if gap >= PASS_THROUGH and _mounted(members, member_set, bottom):
			continue
		bad += 1
		_check(false, "C2 %s %s %.3f m (bottom %.3f, support %.3f)" % [_label(parts[members[0]]), "floats" if gap > 0.0 else "sinks", absf(gap), bottom, top])
	# Hanging props must reach the structure or a resting prop through touching parts (≤ 2 cm).
	var grounded: Dictionary = {}
	for key: String in verdict:
		if verdict[key] == "rest":
			grounded[key] = true
	var changed: bool = true
	while changed:
		changed = false
		for key: String in verdict:
			if grounded.has(key):
				continue
			for index: int in groups[key]:
				var p: Dictionary = parts[index]
				for other: int in _near(p.amin, p.amax, SUPPORT_GAP):
					var q: Dictionary = parts[other]
					if q.group == key or not q.visible or q.kind == "Quad":
						continue
					if (q.role in ["struct", "pane", "anchor"] or grounded.has(q.group)) and _aabb_gap(p, q) <= SUPPORT_GAP:
						grounded[key] = true
						changed = true
						break
				if grounded.has(key):
					break
	for key: String in verdict:
		if not grounded.has(key):
			bad += 1
			_check(false, "C2 %s hangs in the air: nothing under it within %.1f m and nothing holds it" % [_label(parts[groups[key][0]]), SUPPORT_WINDOW])
	_check(groups.size() > 100, "C2 the props were found (%d groups)" % groups.size())
	_check(bad == 0, "C2 every prop rests within %.2f m or hangs from the structure (%d)" % [SUPPORT_GAP, bad])
	print("CITY_TIDY_INFO C2 groups=%d defects=%d" % [groups.size(), bad])


## A wall beside the prop: a structure part within 2 cm of one of its parts that rises over the prop's foot.
func _mounted(members: Array, member_set: Dictionary, bottom: float) -> bool:
	for index: int in members:
		var p: Dictionary = parts[index]
		for other: int in _near(p.amin, p.amax, SUPPORT_GAP):
			var q: Dictionary = parts[other]
			if member_set.has(other) or q.role != "struct" or not q.visible:
				continue
			if float(q.amax.y) > bottom + 0.05 and float(q.amin.y) < float(p.amax.y) and _aabb_gap(p, q) <= SUPPORT_GAP:
				return true
	return false


# --- C3 ----------------------------------------------------------------------------------------------------------
func _signature(p: Dictionary) -> String:
	var key: String = p.mat
	if key.begins_with("std#"):
		return key
	if p.module == "CityInteriors":
		return "base:" + key.trim_prefix("exterior_") if key.begins_with("exterior_") else "interiors:" + key
	return "base:" + key


func _faces(p: Dictionary) -> Array:
	var out: Array = []
	for k: int in 3:
		if p.kind != "BoxMesh" and not (p.kind == "CylinderMesh" and k == 1):
			continue
		for s: float in [-1.0, 1.0]:
			var n: Vector3 = (p.axes[k] as Vector3) * s
			var face: Vector3 = (p.center as Vector3) + n * float(p.half[k])
			out.append([n, n.dot(face), face, p.axes[(k + 1) % 3], float(p.half[(k + 1) % 3]), p.axes[(k + 2) % 3], float(p.half[(k + 2) % 3])])
	return out


func _buried(point: Vector3, normal: Vector3, skip: Array[int]) -> bool:
	if normal.y < -0.9 and point.y <= 0.01:
		return true
	for reach: float in BURIED_REACH:
		var at: Vector3 = point + normal * reach
		for index: int in _near(at, at, 0.0):
			var b: Dictionary = parts[index]
			if index in skip or b.kind != "BoxMesh" or not b.visible:
				continue
			var d: Vector3 = at - (b.center as Vector3)
			var inside: bool = true
			for k: int in 3:
				inside = inside and absf((b.axes[k] as Vector3).dot(d)) < float(b.half[k]) - 0.0001
			if inside:
				return true
	return false


func _c3_zfight() -> void:
	var bad: int = 0
	var pairs: int = 0
	for i: int in parts.size():
		var p: Dictionary = parts[i]
		if not p.visible or not (p.kind in ["BoxMesh", "CylinderMesh"]) or not _inside_district(p):
			continue
		var fp: Array = _faces(p)
		for j: int in _near(p.amin, p.amax, PLANE_GAP + 0.001):
			if j <= i:
				continue
			var q: Dictionary = parts[j]
			if not q.visible or not (q.kind in ["BoxMesh", "CylinderMesh"]) or _signature(p) == _signature(q):
				continue
			pairs += 1
			var fq: Array = _faces(q)
			for f1: Array in fp:
				for f2: Array in fq:
					var n1: Vector3 = f1[0]
					if n1.dot(f2[0]) < 0.9999:
						continue
					var gap: float = absf(float(f1[1]) - float(f2[1]))
					if gap >= PLANE_GAP - 0.0001:
						continue
					var ta: Vector3 = f1[3]
					var tb: Vector3 = f1[5]
					var sa: Vector3 = f2[3]
					var fa: float = f2[4]
					var sb: Vector3 = f2[5]
					var fb: float = f2[6]
					if maxf(absf(ta.dot(sa)), absf(ta.dot(sb))) < 0.9999:
						continue
					if absf(ta.dot(sb)) > absf(ta.dot(sa)):
						var swap_axis: Vector3 = sa
						sa = sb
						sb = swap_axis
						var swap_half: float = fa
						fa = fb
						fb = swap_half
					var c1: Vector3 = f1[2]
					var c2: Vector3 = f2[2]
					var o1: float = c2.dot(ta) - c1.dot(ta)
					var o2: float = c2.dot(tb) - c1.dot(tb)
					var ea: float = f1[4]
					var eb: float = f1[6]
					var ia: float = minf(ea, o1 + fa) - maxf(-ea, o1 - fa)
					var ib: float = minf(eb, o2 + fb) - maxf(-eb, o2 - fb)
					if ia <= 0.005 or ib <= 0.005 or ia * ib < PLANE_AREA:
						continue
					var mid1: float = (maxf(-ea, o1 - fa) + minf(ea, o1 + fa)) * 0.5
					var mid2: float = (maxf(-eb, o2 - fb) + minf(eb, o2 + fb)) * 0.5
					var point: Vector3 = c1 + ta * mid1 + tb * mid2 + n1 * (gap + 0.003)
					if _buried(point, n1, [i, j]):
						continue
					bad += 1
					_check(false, "C3 %s and %s share a plane (%.4f m apart, %.4f m², normal %s) at %s" % [_label(p), _label(q), gap, ia * ib, _v(n1), _v(point)])
	_check(bad == 0, "C3 no visible coplanar faces of different materials (%d)" % bad)
	print("CITY_TIDY_INFO C3 pairs=%d defects=%d" % [pairs, bad])


# --- C4 ----------------------------------------------------------------------------------------------------------
func _snap(v: Vector3) -> String:
	return "%d,%d,%d" % [roundi(v.x / SAME), roundi(v.y / SAME), roundi(v.z / SAME)]


func _shape_key(shape: Shape3D) -> String:
	if shape is BoxShape3D:
		return "box:" + _snap((shape as BoxShape3D).size)
	if shape is CylinderShape3D:
		return "cyl:%d,%d" % [roundi((shape as CylinderShape3D).radius / SAME), roundi((shape as CylinderShape3D).height / SAME)]
	if shape is SphereShape3D:
		return "sph:%d" % roundi((shape as SphereShape3D).radius / SAME)
	if shape is CapsuleShape3D:
		return "cap:%d,%d" % [roundi((shape as CapsuleShape3D).radius / SAME), roundi((shape as CapsuleShape3D).height / SAME)]
	if shape is ConvexPolygonShape3D:
		var points: PackedVector3Array = (shape as ConvexPolygonShape3D).points
		var box := AABB(points[0], Vector3.ZERO) if not points.is_empty() else AABB()
		for point: Vector3 in points:
			box = box.expand(point)
		return "convex:%d:%s:%s" % [points.size(), _snap(box.position), _snap(box.size)]
	if shape is ConcavePolygonShape3D:
		var faces: PackedVector3Array = (shape as ConcavePolygonShape3D).get_faces()
		var box2 := AABB(faces[0], Vector3.ZERO) if not faces.is_empty() else AABB()
		for point: Vector3 in faces:
			box2 = box2.expand(point)
		return "concave:%d:%s:%s" % [faces.size(), _snap(box2.position), _snap(box2.size)]
	return shape.get_class()


func _c4_duplicates() -> void:
	var seen: Dictionary = {}
	var bad: int = 0
	for p: Dictionary in parts:
		if not p.visible or p.kind == "Quad" or not _inside_district(p):
			continue
		var key: String = "%s|%s|%s" % [p.kind, _snap(p.center), _snap((p.amax as Vector3) - (p.amin as Vector3))]
		if seen.has(key):
			bad += 1
			_check(false, "C4 %s is drawn twice (also %s)" % [_label(p), seen[key]])
		else:
			seen[key] = _label(p)
	var bodies: Dictionary = {}
	var colliders: int = 0
	for node: Node in district.find_children("*", "CollisionShape3D", true, false):
		var shape := node as CollisionShape3D
		if shape.shape == null or shape.disabled:
			continue
		colliders += 1
		var xf: Transform3D = shape.global_transform
		var key: String = "%s|%s|%s|%s|%s" % [_shape_key(shape.shape), _snap(xf.origin), _snap(xf.basis.x), _snap(xf.basis.y), _snap(xf.basis.z)]
		if bodies.has(key):
			bad += 1
			_check(false, "C4 collider %s duplicates %s" % [district.get_path_to(shape), bodies[key]])
		else:
			bodies[key] = String(district.get_path_to(shape))
	_check(bad == 0, "C4 nothing is built twice (%d)" % bad)
	print("CITY_TIDY_INFO C4 parts=%d colliders=%d duplicates=%d" % [seen.size(), colliders, bad])


# --- C5 ----------------------------------------------------------------------------------------------------------
func _local_point(p: Dictionary, f: Vector3) -> Vector3:
	var local: AABB = p.local
	return (p.xf as Transform3D) * (local.position + local.size * f)


func _inside_collider(point: Vector3) -> bool:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	query.collision_mask = 1
	return not space.intersect_point(query, 1).is_empty()


func _capsule_free(feet: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = HERO_R
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, feet + Vector3(0, 0.96, 0))
	query.collision_mask = 1
	return space.intersect_shape(query, 1).is_empty()


func _floor_under(at: Vector3, depth: float = 2.5) -> Dictionary:
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at, at - Vector3.UP * depth, 1))
	if hit.is_empty() or Vector3(hit.normal).y < 0.7:
		return {}
	return hit


func _c5_solid() -> void:
	var examined: int = 0
	var bad: Dictionary = {}
	for p: Dictionary in parts:
		if p.role != "prop" or not p.visible or p.kind == "Quad" or not _inside_district(p):
			continue
		var floor_y: float = 4.0 if float(p.amin.y) >= 3.9 else 0.0
		if not (float(p.amin.y) < floor_y + BAND.y and float(p.amax.y) > floor_y + BAND.x):
			continue
		if maxf(float(p.amax.x - p.amin.x), float(p.amax.z - p.amin.z)) < MIN_EXTENT:
			continue
		if 8.0 * float(p.half.x) * float(p.half.y) * float(p.half.z) < MIN_VOLUME:
			continue
		var covered: int = 0
		for fx: float in [0.2, 0.5, 0.8]:
			for fy: float in [0.2, 0.5, 0.8]:
				for fz: float in [0.2, 0.5, 0.8]:
					if _inside_collider(_local_point(p, Vector3(fx, fy, fz))):
						covered += 1
		if covered > COVERED:
			continue
		examined += 1
		var reach: float = HERO_R - PASS_THROUGH
		var found: bool = false
		for fx: float in [0.05, 0.5, 0.95]:
			for fy: float in [0.05, 0.5, 0.95]:
				for fz: float in [0.05, 0.5, 0.95]:
					if found:
						break
					var point: Vector3 = _local_point(p, Vector3(fx, fy, fz))
					if point.y < floor_y + BAND.x or point.y > floor_y + BAND.y:
						continue
					for step: int in 17:
						var offset := Vector3.ZERO
						if step > 0:
							var angle: float = TAU * float((step - 1) % 8) / 8.0
							offset = Vector3(cos(angle), 0, sin(angle)) * (reach * (0.5 if step <= 8 else 1.0))
						var axis: Vector3 = Vector3(point.x, point.y, point.z) + offset
						var hit: Dictionary = _floor_under(axis)
						if hit.is_empty():
							continue
						var feet: float = float(hit.position.y)
						if absf(feet - floor_y) > SUPPORT_WINDOW or point.y < feet + 0.06 or point.y > feet + 1.86:
							continue
						if _capsule_free(Vector3(axis.x, feet, axis.z)):
							found = true
							break
		if found:
			var key: String = _label(p)
			if not bad.has(key):
				bad[key] = true
				_check(false, "C5 a hero walks %.2f m into %s: it has no collider where he meets it (%d/27 points in colliders)" % [PASS_THROUGH, key, covered])
	_check(bad.is_empty(), "C5 every visible part in the hero band stops the hero (%d)" % bad.size())
	print("CITY_TIDY_INFO C5 examined=%d defects=%d" % [examined, bad.size()])


# --- K -----------------------------------------------------------------------------------------------------------
func _props_parts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for p: Dictionary in parts:
		if p.module == "CityProps" and p.visible:
			result.append(p)
	return result


func _flat_distance(p: Dictionary, point: Vector3) -> float:
	var nearest := Vector2(clampf(point.x, p.amin.x, p.amax.x), clampf(point.z, p.amin.z, p.amax.z))
	return nearest.distance_to(Vector2(point.x, point.z))


func _k_places() -> void:
	var own: Array[Dictionary] = _props_parts()
	_check(own.size() > 100, "K the new props are there (%d parts)" % own.size())
	# К6: the court, the pockets and the lanes.
	var closest: float = INF
	for p: Dictionary in own:
		closest = minf(closest, _flat_distance(p, Vector3.ZERO))
	_check(closest >= COURT_CLEAR, "K6 nothing new within %.0f m of the court centre (closest %.2f m)" % [COURT_CLEAR, closest])
	for pocket: Dictionary in CityLayout.combat_pockets():
		var cylinder := CylinderShape3D.new()
		cylinder.radius = pocket.radius
		cylinder.height = 2.0
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = cylinder
		query.transform = Transform3D(Basis.IDENTITY, Vector3(pocket.center) + Vector3(0, 1.1, 0))
		query.collision_mask = 1
		var hits: Array[Dictionary] = space.intersect_shape(query, 8)
		_check(hits.is_empty(), "K6 the %s pocket (r %.0f) holds no collider (%d)" % [pocket.id, pocket.radius, hits.size()])
		for p: Dictionary in own:
			if _flat_distance(p, pocket.center) < float(pocket.radius) and absf(float(p.center.y) - float(pocket.center.y)) < 3.0:
				_check(false, "K6 %s stands in the %s pocket" % [_label(p), pocket.id])
	var director: Script = load("res://scripts/npc/CityNpcDirector.gd")
	var lane_bad: int = 0
	for resident: int in range(3, 12):
		var lane: Array = director.lane(resident)
		for p: Dictionary in own:
			if float(p.amin.y) > BAND.y:
				continue
			for i: int in lane.size():
				var a: Vector3 = lane[i]
				var b: Vector3 = lane[(i + 1) % lane.size()]
				var c := Vector2(p.center.x, p.center.z)
				var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(c, Vector2(a.x, a.z), Vector2(b.x, b.z))
				if _flat_distance(p, Vector3(nearest.x, 0, nearest.y)) < LANE_CLEAR:
					lane_bad += 1
					_check(false, "K6 %s is within %.0f m of resident lane %d" % [_label(p), LANE_CLEAR, resident])
					break
	_check(lane_bad == 0, "K6 the new props keep %.0f m from every resident lane (%d)" % [LANE_CLEAR, lane_bad])
	print("CITY_TIDY_INFO K6 closest_to_court=%.2f lane_breaches=%d" % [closest, lane_bad])
	await _k_passage(own)
	_k_anchors()
	_k_obstacles()
	_k_style(own)


func _k_passage(own: Array[Dictionary]) -> void:
	var inside: int = 0
	var reach: float = 0.0
	var lowest: float = INF
	var main_low: float = INF
	for p: Dictionary in own:
		if p.center.x < 18.0 or p.center.x > 22.0 or p.center.z < 12.0 or p.center.z > 30.0:
			continue
		inside += 1
		reach = maxf(reach, CityProps.MAIN_WALL_X - float(p.amin.x))
		lowest = minf(lowest, float(p.amin.y))
		if String(p.group).find("steam_main@") >= 0 and float(p.amax.z - p.amin.z) > 8.0:
			main_low = minf(main_low, float(p.amin.y))
	_check(inside > 20, "K7 the steam main is in the southeast passage (%d parts)" % inside)
	_check(reach <= PASSAGE_REACH + 0.001, "K7 the passage pipes stand ≤ %.2f m out of the wall (%.3f m)" % [PASSAGE_REACH, reach])
	_check(main_low < INF and main_low >= MAIN_HEIGHT, "K7 the main runs ≥ %.1f m up (%.2f m)" % [MAIN_HEIGHT, main_low])
	_check(lowest >= BAND.y + 0.6, "K7 nothing in the passage comes down into reach (lowest %.2f m)" % lowest)
	var box := BoxShape3D.new()
	box.size = Vector3(3.9, 4.2, 18.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = Transform3D(Basis.IDENTITY, Vector3(20, 2.2, 21))
	query.collision_mask = 1
	_check(space.intersect_shape(query, 4).is_empty(), "K7 the passage (x 18.05–21.95, z 12–30) holds no collider: 4 m wide, the camera arm free")
	var alley: Dictionary = load("res://scripts/world/CityAlleyEvent.gd").get_script_constant_map()
	for key: String in ["MOUTH", "STAND", "BLOCK", "INSIDE", "NORTH_EXIT", "SOUTH_EXIT"]:
		_check(_capsule_free(alley[key]), "K7 the alley point %s %s is free" % [key, _v(alley[key])])
	var z: float = 9.0
	var axis_free: bool = true
	while z <= 31.0:
		axis_free = axis_free and _capsule_free(Vector3(20, 0, z))
		z += 0.5
	_check(axis_free, "K7 the passage axis x = 20 is free from z 9 to 31")
	var player: Node3D = world.player
	player.restart_at(Vector3(20, 0, 21))
	player._set_forward(Vector3(0, 0, -1))
	world.camera_rig.aim.yaw_offset = 0.0
	world.camera_rig.reset_view()
	await _ticks(20)
	var arm: float = world.camera_rig.arm.get_hit_length()
	_check(arm >= CAMERA_SPACE, "K7 the camera arm in the passage keeps ≥ %.0f m (%.2f m)" % [CAMERA_SPACE, arm])
	print("CITY_TIDY_INFO K7 passage parts=%d reach=%.3f lowest=%.2f main=%.2f arm=%.2f" % [inside, reach, lowest, main_low, arm])


func _k_anchors() -> void:
	var supports: Array[Dictionary] = CityLayout.anchor_supports()
	_check(supports.size() == ANCHOR_FLOOR.size(), "K anchors: %d now, %d measured on 97675c7" % [supports.size(), ANCHOR_FLOOR.size()])
	var own_bodies: Array[Node] = props_node.find_children("*", "StaticBody3D", true, false)
	for index: int in mini(supports.size(), ANCHOR_FLOOR.size()):
		var point: Vector3 = supports[index].point
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(point - Vector3(0, 0.2, 0), point - Vector3(0, 12, 0), 9))
		var y: float = float(hit.position.y) if not hit.is_empty() else -INF
		_check(absf(y - ANCHOR_FLOOR[index]) <= 0.001, "K anchor %d: the rope still falls to y %.4f (now %.4f)" % [index, ANCHOR_FLOOR[index], y])
		for body: Node in own_bodies:
			for node: Node in body.get_children():
				var shape := node as CollisionShape3D
				if shape == null or shape.shape == null:
					continue
				var box: AABB = shape.shape.get_debug_mesh().get_aabb()
				var world_box: AABB = shape.global_transform * box
				var nearest := Vector2(clampf(point.x, world_box.position.x, world_box.end.x), clampf(point.z, world_box.position.z, world_box.end.z))
				if nearest.distance_to(Vector2(point.x, point.z)) < ANCHOR_COLUMN and world_box.position.y < point.y:
					_check(false, "K anchor %d: %s stands in its column (≤ %.2f m)" % [index, body.name, ANCHOR_COLUMN])


func _k_obstacles() -> void:
	for spec: Dictionary in props_node.get_meta("obstacles", []):
		var body: Node = props_node.get_node_or_null("VaultObstacle_" + String(spec.id))
		_check(body is StaticBody3D, "K8 obstacle %s has its collider" % spec.id)
		if not body is StaticBody3D:
			continue
		var shape: BoxShape3D = ((body as StaticBody3D).get_child(0) as CollisionShape3D).shape as BoxShape3D
		var run: Vector3 = spec.run
		var depth: float = absf(shape.size.dot(run))
		_check(shape.size.y >= OBSTACLE_HEIGHT.x and shape.size.y <= OBSTACLE_HEIGHT.y, "K8 obstacle %s is %.2f m high (%.1f–%.1f)" % [spec.id, shape.size.y, OBSTACLE_HEIGHT.x, OBSTACLE_HEIGHT.y])
		_check(depth <= OBSTACLE_DEPTH, "K8 obstacle %s is %.2f m deep (≤ %.1f)" % [spec.id, depth, OBSTACLE_DEPTH])
		var center: Vector3 = (body as StaticBody3D).global_position
		for side: float in [-1.0, 1.0]:
			var beyond: Vector3 = Vector3(center.x, 0, center.z) + run * side * (depth * 0.5 + 0.8)
			var hit: Dictionary = _floor_under(beyond + Vector3(0, 1.0, 0), 2.0)
			_check(not hit.is_empty() and absf(float(hit.position.y) - float(spec.center.y)) <= 0.05, "K8 obstacle %s: the floor %s of it is at its own level" % [spec.id, "behind" if side > 0 else "before"])


func _k_style(own: Array[Dictionary]) -> void:
	var ink_bad: int = 0
	for p: Dictionary in parts:
		if p.mat != "ink" or not p.visible:
			continue
		var sizes: Array[float] = [float(p.half.x) * 2.0, float(p.half.y) * 2.0, float(p.half.z) * 2.0]
		sizes.sort()
		var strip: bool = float(p.amax.y - p.amin.y) < 0.05 and maxf(float(p.amax.x - p.amin.x), float(p.amax.z - p.amin.z)) > 1.0
		if sizes[1] > INK_WIDTH or strip:
			ink_bad += 1
			_check(false, "K4 %s is an ink surface (%.2f m wide%s)" % [_label(p), sizes[1], ", a strip on the street" if strip else ""])
	_check(ink_bad == 0, "K4/Н1 ink is only outline: no surface wider than %.1f m, no street strip (%d)" % [INK_WIDTH, ink_bad])
	_check(props_node.find_children("*", "Label3D", true, false).is_empty(), "K5 the new props carry no letters")
	_check(props_node.find_children("*", "Light3D", true, false).is_empty(), "K9 the new props add no light")
	var meshes: Array[Node] = props_node.find_children("*", "MeshInstance3D", false, false)
	var materials: Dictionary = {}
	for p: Dictionary in own:
		materials[p.mat] = true
	_check(meshes.size() == materials.size(), "K9 the new props are one mesh per material (%d meshes, %d materials)" % [meshes.size(), materials.size()])
	# К8: groups of props (gaps ≤ 1 m) hold ≤ 5, ≤ 3 of one kind.
	var items: Array = props_node.get_meta("props", [])
	var parent: Dictionary = {}
	for i: int in items.size():
		parent[i] = i
	for i: int in items.size():
		for j: int in range(i + 1, items.size()):
			var gap: float = Vector2(items[i].position.x - items[j].position.x, items[i].position.z - items[j].position.z).length() - float(items[i].radius) - float(items[j].radius)
			if gap <= 1.0:
				var ri: int = _find(parent, i)
				var rj: int = _find(parent, j)
				if ri != rj:
					parent[ri] = rj
	var clusters: Dictionary = {}
	for i: int in items.size():
		var root_index: int = _find(parent, i)
		if not clusters.has(root_index):
			clusters[root_index] = []
		clusters[root_index].append(items[i])
	for key: int in clusters:
		var members: Array = clusters[key]
		var kinds: Dictionary = {}
		for item: Dictionary in members:
			kinds[item.kind] = int(kinds.get(item.kind, 0)) + 1
		_check(members.size() <= GROUP_MAX, "K8 a group at %s holds %d props (≤ %d)" % [_v(members[0].position), members.size(), GROUP_MAX])
		for kind: String in kinds:
			_check(int(kinds[kind]) <= SAME_KIND_MAX, "K8 a group at %s holds %d of %s (≤ %d)" % [_v(members[0].position), kinds[kind], kind, SAME_KIND_MAX])
	print("CITY_TIDY_INFO K8 props=%d groups=%d" % [items.size(), clusters.size()])


## D17, D19, D24 of the audit, each measured the way the audit measured it.
func _places_of_the_audit() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	for shop: Dictionary in CityPlaces.shops():
		for key: String in ["approach", "visit", "service"]:
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform = Transform3D(Basis.IDENTITY, Vector3(shop[key]) + Vector3(0, 0.96, 0))
			query.collision_mask = 1
			var hits: Array[Dictionary] = space.intersect_shape(query, 4)
			var names: Array[String] = []
			for hit: Dictionary in hits:
				names.append(String(hit.collider.name))
			_check(hits.is_empty(), "D17 a hero (r 0.35) stands free at the %s %s point %s (%s)" % [shop.id, key, _v(shop[key]), ", ".join(names)])
	var sides: int = 0
	var bare: int = 0
	for solid: Dictionary in arch_solids:
		var size: Vector3 = solid.size
		if String(solid.ctx).find("balcony@") < 0 or absf(size.x - 0.07) > 0.001 or absf(size.z - 0.85) > 0.001:
			continue
		sides += 1
		var inverse: Transform3D = (district.global_transform * (solid.xf as Transform3D)).affine_inverse()
		var inside: int = 0
		for p: Dictionary in parts:
			if p.module != "CityArchitecture" or p.ctx != solid.ctx or not p.visible or float(p.amax.y - p.amin.y) < 0.6:
				continue
			var local: Vector3 = inverse * (p.center as Vector3)
			if absf(local.x) <= size.x * 0.5 and absf(local.y) <= size.y * 0.5 and absf(local.z) <= size.z * 0.5:
				inside += 1
		if inside < 3:
			bare += 1
	_check(sides >= 30, "D19 the solid balcony sides were found (%d)" % sides)
	_check(bare == 0, "D19 every solid balcony side has ≥ 3 balusters inside it (%d bare)" % bare)
	for wall: Vector2 in [Vector2(-10.0, 1.0), Vector2(-30.0, -1.0)]:
		var faces: int = 0
		var wrong: Array[String] = []
		for p: Dictionary in parts:
			if not p.visible or p.kind != "BoxMesh" or float(p.amax.z) < 12.5 or float(p.amin.z) > 19.5 or float(p.amax.y) < 1.0 or float(p.amin.y) > 3.0:
				continue
			var face: float = float(p.amax.x) if wall.y > 0.0 else float(p.amin.x)
			if absf(face - wall.x) > 0.005 or float(p.amax.x - p.amin.x) > 1.0:
				continue
			faces += 1
			if not _signature(p).begins_with("base:"):
				wrong.append(_label(p))
		_check(faces > 0 and wrong.is_empty(), "D24 the street face x %.1f of the end shop wall is street material (%d faces; %s)" % [wall.x, faces, ", ".join(wrong)])


func _triangles() -> void:
	var by_module: Dictionary = {}
	var total: int = 0
	var instances: int = 0
	for node: Node in district.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var top: String = String(district.get_path_to(mesh)).get_slice("/", 0)
		var key: String = top if top in ["CityMarket", "CityInteriors", "CityBackdrop", "CityProps", "CityMaintenance", "CityLowerGallery", "WaterPump"] else ("CityArchitecture" if top.begins_with("Architecture_") else "CityDistrict")
		var count: int = int(mesh.mesh.get_faces().size() / 3)
		by_module[key] = int(by_module.get(key, 0)) + count
		total += count
		instances += 1
	print("CITY_TIDY_INFO triangles district=%d mesh_instances=%d %s" % [total, instances, JSON.stringify(by_module)])


# --- V -----------------------------------------------------------------------------------------------------------
func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _vaults(hero: String) -> void:
	var profile: Resource = load("res://data/world/city_parkour.tres")
	var want: int = roundi(float(profile.get("vault_seconds")) * 60.0)
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	for spec: Dictionary in props_node.get_meta("obstacles", []):
		var body: StaticBody3D = props_node.get_node("VaultObstacle_" + String(spec.id))
		var size: Vector3 = ((body.get_child(0) as CollisionShape3D).shape as BoxShape3D).size
		var axis: Vector3 = spec.run
		var depth: float = absf(size.dot(axis))
		var center: Vector3 = spec.center
		var tested: int = 0
		for side: float in [1.0, -1.0]:
			var run: Vector3 = axis * side
			var start: Vector3 = center - run * (depth * 0.5 + 5.0)
			var clear: bool = true
			var s: float = 0.0
			while s <= 4.3:
				var at: Vector3 = start + run * s
				var hit: Dictionary = _floor_under(at + Vector3(0, 0.5, 0), 1.0)
				clear = clear and not hit.is_empty() and absf(float(hit.position.y) - center.y) < 0.05 and _capsule_free(at)
				s += 0.5
			if not clear:
				continue
			tested += 1
			var out: Dictionary = await _vault_run(start, run, center, depth)
			var beyond: float = (Vector3(out.end) - center).dot(run)
			_check(absi(int(out.ticks) - want) <= 1, "V %s vaults %s from %s for %d ticks (want %d)" % [hero, spec.id, _v(start), out.ticks, want])
			_check(not out.hang, "V %s: no hang on %s" % [hero, spec.id])
			_check(beyond > depth * 0.5 + 0.35 and absf(float(out.landed) - center.y) < 0.05, "V %s lands beyond %s at the take-off level (%.2f m past the centre, y %.3f)" % [hero, spec.id, beyond, out.landed])
			print("CITY_TIDY_INFO V %s %s side %+.0f: %d ticks, speed %.2f, beyond %.2f, y %.3f" % [hero, spec.id, side, out.ticks, out.speed, beyond, out.landed])
		_check(tested >= 1, "V %s: %s has a free run-up from at least one side (%d)" % [hero, spec.id, tested])
	world.npc_director.process_mode = Node.PROCESS_MODE_INHERIT


func _vault_run(start: Vector3, run: Vector3, center: Vector3, depth: float) -> Dictionary:
	var player: Node3D = world.player
	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	player.restart_at(start)
	player._set_forward(run)
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = atan2(-run.x, -run.z)
	await _ticks(10)
	var out: Dictionary = {"ticks": 0, "hang": false, "end": start, "landed": INF, "speed": 0.0}
	_key(KEY_W, true)
	var jumped: bool = false
	var held: int = 0
	for tick: int in 240:
		var along: float = (player.global_position - center).dot(run)
		if not jumped and along >= -depth * 0.5 - 1.15 and player.is_on_floor():
			jumped = true
			out.speed = Vector2(player.velocity.x, player.velocity.z).length()
			_key(KEY_SPACE, true)
		await _ticks(1)
		if jumped:
			held += 1
			if held == 2:
				_key(KEY_SPACE, false)
		var phase: String = player.parkour.phase
		if phase == "vault":
			out.ticks = int(out.ticks) + 1
		out.hang = bool(out.hang) or phase in ["hang", "mantle"]
		if jumped and held > 10 and player.is_on_floor() and phase.is_empty() and player.state != fighter_script.State.JUMP:
			out.landed = player.global_position.y
			break
	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	out.end = player.global_position
	await _ticks(4)
	return out


# --- S -----------------------------------------------------------------------------------------------------------
func _steam() -> void:
	var vents: Array[Node] = []
	for child: Node in props_node.get_children():
		if child is CitySteamVent:
			vents.append(child)
	_check(vents.size() == 2, "S two steam vents (%d)" % vents.size())
	var player: Node3D = world.player
	for node: Node in vents:
		var vent: CitySteamVent = node as CitySteamVent
		vent.set_process(false)
		if mutation == "steam_hero":
			vent.hero_clear = 0.0
		if mutation == "steam_flash":
			vent.frame_seconds = 0.1
		player.restart_at(CityLayout.spawn_position())
		await _ticks(3)
		vent.clock = 0.0
		vent.step(0.0)
		var peak: float = 0.0
		var jump: float = 0.0
		var changes: int = 0
		var shown: float = 0.0
		var last_alpha: float = vent.puff_alpha()
		var last_frame: int = vent.puff_frame()
		for tick: int in roundi(vent.period / DT):
			vent.step(DT)
			var alpha: float = vent.puff_alpha()
			peak = maxf(peak, alpha)
			jump = maxf(jump, absf(alpha - last_alpha))
			if alpha > 0.01:
				shown += DT
				if vent.puff_frame() != last_frame:
					changes += 1
			last_alpha = alpha
			last_frame = vent.puff_frame()
		var rate: float = float(changes) / maxf(shown, DT)
		_check(peak >= 0.5 and peak <= 0.8 + 0.001, "S %s puffs at ≤ 0.8 opacity (peak %.2f)" % [vent.get_path(), peak])
		_check(rate < FLASH_HZ, "S %s changes frame %.2f times a second (< %.0f)" % [vent.get_path(), rate, FLASH_HZ])
		_check(jump <= 0.1, "S %s never jumps in opacity by more than 0.1 a frame (%.3f)" % [vent.get_path(), jump])
		var size: Vector2 = CitySteamVent.CELL * vent.sprite.pixel_size
		_check(size.x <= PUFF_SIZE.x and size.y <= PUFF_SIZE.y, "S %s puff is %.2f × %.2f m (≤ %.1f × %.1f)" % [vent.get_path(), size.x, size.y, PUFF_SIZE.x, PUFF_SIZE.y])
		_check(vent.sprite.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "S %s puff casts no shadow" % vent.get_path())
		player.restart_at(vent.global_position + Vector3(0.6, 0, 0))
		await _ticks(3)
		vent.clock = 0.0
		var over_hero: float = 0.0
		for tick: int in roundi(vent.period / DT):
			vent.step(DT)
			if float(tick) * DT >= 0.5:
				over_hero = maxf(over_hero, vent.puff_alpha())
		_check(over_hero <= 0.02, "S %s holds the puff while a hero stands at it (peak %.3f)" % [vent.get_path(), over_hero])
		print("CITY_TIDY_INFO S %s peak=%.2f rate=%.2f jump=%.3f over_hero=%.3f size=%.2fx%.2f" % [vent.get_path(), peak, rate, jump, over_hero, size.x, size.y])
		vent.set_process(true)


# --- mutations ---------------------------------------------------------------------------------------------------
## Breaks applied to the live scene, before anything is measured.
func _break_scene() -> void:
	match mutation:
		"pane_strut":
			# D1 returned: anchor 22's strut from 0.75 m under its arm, as before the fix.
			var spec: Dictionary = CityLayout.anchor_supports()[22]
			var mount: Vector3 = spec.mount
			var point: Vector3 = spec.point
			var low: Vector3 = mount + Vector3(0, -0.75, 0)
			var high := Vector3((mount.x + point.x) * 0.5, mount.y - 0.05, (mount.z + point.z) * 0.5)
			var strut: Node3D = district.get_node("AnchorStrut22")
			strut.transform = Transform3D(Basis.looking_at((high - low).normalized(), Vector3.UP), (low + high) * 0.5)
			(strut.get_child(0) as MeshInstance3D).mesh.size = Vector3(0.08, 0.08, low.distance_to(high))
		"float_plate":
			# D5 returned: the archive plate 6 cm off its wall.
			(district.get_node("CityLowerGallery/RoutePlate") as Node3D).position.x -= 0.06
		"solid_planter":
			for node: Node in district.get_node("CityInteriors").find_children("BenchPlanter*", "StaticBody3D", false, false):
				node.free()
				break
		"solid_dressform":
			for node: Node in district.get_node("CityInteriors").find_children("DressForm*", "StaticBody3D", false, false):
				node.free()
		"pump_spout", "pump_lever", "pump_layer":
			# The pump's spout (pipe and mouth) or its lever (bar and handle grip) without a collider, or both on a body
			# on the cover layer only, which the hero's capsule (mask 1) never meets.
			var pump_body: StaticBody3D = district.get_node("WaterPump/PumpBody")
			var names: Array[String] = []
			if mutation != "pump_lever":
				names.append_array(["SpoutPipe", "SpoutMouth"])
			if mutation != "pump_spout":
				names.append_array(["LeverBar", "HandleGrip"])
			var cover := StaticBody3D.new()
			cover.collision_layer = 8
			cover.collision_mask = 0
			if mutation == "pump_layer":
				pump_body.add_child(cover)
			for id: String in names:
				var piece: CollisionShape3D = pump_body.get_node(id)
				if mutation == "pump_layer":
					piece.reparent(cover, false)
				else:
					piece.disabled = true
			if mutation != "pump_layer":
				cover.free()
		"solid_sign":
			var plaque: Node = district.get_node("CityMaintenance/BypassSignPlaque")
			for node: Node in plaque.get_children():
				if node is CollisionShape3D:
					(node as CollisionShape3D).disabled = true
		"service":
			# D17 returned: the atelier's cutting table 0.25 m nearer the counter aisle, as before the fix.
			for node: Node in district.get_node("CityInteriors").find_children("WorkTable*", "StaticBody3D", false, false):
				var table := node as StaticBody3D
				if absf(table.global_position.x - (-17.85)) < 0.05:
					table.global_position.z += 0.25
		"dup_wall":
			var wall: StaticBody3D = district.get_node("CityInteriors").find_children("ShopWall*", "StaticBody3D", false, false)[0]
			var copy: StaticBody3D = wall.duplicate()
			district.get_node("CityInteriors").add_child(copy)
		"anchor":
			# A tar drum under anchor 2's rope.
			var drum: StaticBody3D = props_node.find_children("TarBarrel*", "StaticBody3D", false, false)[0]
			var point: Vector3 = CityLayout.anchor_supports()[2].point
			drum.global_position = Vector3(point.x, 0.45, point.z)
		"vault_high", "vault_deep":
			var body: StaticBody3D = props_node.get_node("VaultObstacle_crates_east")
			var shape := ((body.get_child(0) as CollisionShape3D).shape as BoxShape3D).duplicate() as BoxShape3D
			if mutation == "vault_high":
				shape.size.y = 1.5
				body.position.y = 0.75
			else:
				shape.size.z = 1.2
			(body.get_child(0) as CollisionShape3D).shape = shape


## Breaks applied to the measured parts (the batched builders cannot be edited after the fact).
func _break_parts() -> void:
	match mutation:
		"pane_wire":
			# D4 returned: the south market wire back at z 28, into the arched window of bay z 28.2.
			_move(_select("CityMarket", "wire@-10.00,6.20,27.00", false), Vector3(0, 0, 1.0))
		"float_barrel":
			_move(_select("CityProps", "beer_barrel@"), Vector3(0, 0.03, 0))
		"float_loaf":
			var loaves: Array[Dictionary] = []
			for p: Dictionary in parts:
				if p.module == "CityInteriors" and String(p.ctx).find("shelf@") >= 0 and String(p.ctx).find("loaf@") >= 0:
					if loaves.is_empty() or p.ctx == loaves[0].ctx:
						loaves.append(p)
			_move(loaves, Vector3(0, 0.04, 0))
		"sink_crate":
			_move(_select("CityMarket", "crate@"), Vector3(0, -0.03, 0))
		"zfight_fascia":
			# D12 returned: the fascia 0.30 m high again, its front over the awning's.
			for p: Dictionary in parts:
				if p.module == "CityInteriors" and p.ctx == "shop:grocer" and p.mat == "cloth_cream" and absf(float(p.half.y) - 0.13) < 0.001:
					p.local = AABB(Vector3(-3.25, -0.15, -0.055), Vector3(6.5, 0.3, 0.11))
					var xf: Transform3D = p.xf
					xf.origin.y = 3.65
					p.xf = xf
					_shape(p)
		"zfight_jamb":
			# D11 returned: the grocer's east display wall ends in the jamb's plane again.
			for p: Dictionary in parts:
				if p.module == "CityInteriors" and p.ctx == "shop:grocer" and absf(float(p.half.x) - 1.0) < 0.001 and absf(float(p.half.y) - 0.47) < 0.001 and float(p.center.x) > -26.6:
					p.local = AABB(Vector3(-1.05, -0.47, -0.14), Vector3(2.1, 0.94, 0.28))
					var xf: Transform3D = p.xf
					xf.origin.x -= 0.05
					p.xf = xf
					_shape(p)
		"dup_wall":
			for p: Dictionary in parts:
				if p.module == "CityInteriors" and p.ctx == "shop:tailor" and p.mat == "plaster" and absf(float(p.half.z) - 4.0) < 0.001:
					var copy: Dictionary = p.duplicate(true)
					parts.append(copy)
					break
		"dup_barrel":
			for p: Dictionary in _select("CityProps", "tar_barrel@"):
				parts.append(p.duplicate(true))
		"court":
			var urn: Array[Dictionary] = _select("CityProps", "urn@")
			_move(urn, Vector3(-5.0, 0, 5.0) - Vector3(urn[0].center.x, 0, urn[0].center.z))
		"passage":
			_move(_select("CityProps", "steam_main@", false), Vector3(-0.12, 0, 0))
		"lane":
			var crates: Array[Dictionary] = _select("CityProps", "obstacle@-12.40")
			_move(crates, Vector3(-1.4, 0, 2.2))
		"ink_strip":
			# D15 / Н1 returned: one 62 m ink seam along the street at x 5, as before the fix.
			var seam := {"module": "CityDistrict", "ctx": "StreetSeam5_0/Mesh", "kind": "BoxMesh", "mat": "ink",
				"xf": Transform3D(Basis.IDENTITY, Vector3(5, 0.004, 0)), "local": AABB(Vector3(-0.04, -0.004, -31), Vector3(0.08, 0.008, 62)),
				"visible": true, "live": true}
			_shape(seam)
			parts.append(seam)


func _run() -> void:
	await process_frame
	if mutation != "none" and not (mutation in GEOMETRY_BREAKS or mutation in PLACE_BREAKS or mutation in VAULT_BREAKS or mutation in STEAM_BREAKS):
		push_error("CITY_TIDY: unknown --break=" + mutation)
		quit(2)
		return
	fighter_script = load("res://scripts/fighter/Fighter.gd")
	var state: Node = root.get_node("GameState")
	state.set_free_move(true)
	root.get_node("InputRouter").apply_profile("solo", false)
	await _open_world("choko")
	_break_scene()
	await _ticks(2)
	if _phase("geometry") or _phase("places"):
		_record_builders()
		_live_parts()
		_break_parts()
		_classify()
		_index_grid()
		print("CITY_TIDY_INFO parts=%d" % parts.size())
	if _phase("geometry"):
		_c1_panes()
		_c2_support()
		_c3_zfight()
		_c4_duplicates()
		_c5_solid()
		_places_of_the_audit()
		_triangles()
	if _phase("places"):
		await _k_places()
	if _phase("steam"):
		await _steam()
	if _phase("vault"):
		await _vaults("choko")
		await _close_world()
		await _open_world("skea")
		_break_scene()
		await _ticks(2)
		await _vaults("skea")
	await _close_world()
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_TIDY_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)
