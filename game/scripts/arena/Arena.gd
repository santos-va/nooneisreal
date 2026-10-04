extends Node3D
## Stage root: spawns both fighters from GameState, wires camera, HUD, match flow and hit FX.
## Debug keys: Tab = hitboxes, Backspace = reset round (training), Esc = pause.

const FIGHTER_SCENE := preload("res://scenes/fighter/Fighter.tscn")

@onready var fighters_root: Node3D = $Fighters
@onready var fx_root: Node3D = $FX
@onready var camera: FightCamera = $CameraRig
@onready var duel_camera: DuelCamera = $DuelRig   # free movement only (GameState.free_move)
@onready var hud: Hud = $HUD
@onready var flow: MatchFlow = $MatchFlow
@onready var backdrop: Backdrop = $Backdrop
@onready var sun: DirectionalLight3D = $Sun
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var ground: StaticBody3D = $Ground

var p1: Fighter
var p2: Fighter


func _ready() -> void:
	# Arena lifetime is a match; rounds retain this registry and its finite tokens.
	var match_ropes := MatchRopes.new()
	match_ropes.name = "MatchRopes"
	add_child(match_ropes)
	var st := GameState.stage()
	backdrop.apply(st)
	sun.rotation_degrees = Vector3(-42.0, 35.0, 0.0)
	sun.light_color = st.sun
	if world_env.environment:
		world_env.environment.ambient_light_color = st.ambient
	if GameState.free_move:
		_round_floor()
		_anchors_around()
		_drop_plane_walls()
		_apply_layout(String(st.get("layout", "")))
	_light_lamps(st.get("time_of_day", "day") == "night")
	GameState.water = null
	var water_path: String = st.get("water", "")
	if water_path != "" and ResourceLoader.exists(water_path):
		GameState.water = (load(water_path) as WaveField).duplicate()
		GameState.water.use_z = GameState.free_move   # 0.3-5: waves cross the circle arena in 3D
		GameState.water.reset(1)
		# fighters stand on the waves; the stone floor sinks below the deepest trough (it still
		# catches ragdolls) and its mesh is hidden under the water
		ground.position.y = GameState.water.min_height() - 0.1
		(ground.get_node("Mesh") as MeshInstance3D).visible = false
	p1 = _spawn(1, GameState.p1_character, -3.0, 1, false)
	p2 = _spawn(2, GameState.p2_character, 3.0, -1, GameState.p2_is_cpu)
	p1.opponent = p2
	p2.opponent = p1
	GameState.duel.behind = GameState.camera_behind()
	if GameState.free_move:
		camera.process_mode = Node.PROCESS_MODE_DISABLED
		duel_camera.setup(p1, p2)
		for b in cover_bodies:
			duel_camera.arm.add_excluded_object(b.get_rid())   # ADR-018 п. 5: cover never pulls the camera in
	else:
		camera.setup(p1, p2)
		duel_camera.queue_free()
		duel_camera = null
	for f in [p1, p2]:
		(f as Fighter).hit_landed.connect(_on_hit)
		(f as Fighter).knocked_out.connect(_on_ko)
	hud.bind(p1, p2, flow)
	var director := FxDirector.new()   # lane B: painted flipbooks; reads the fighters, writes nothing
	director.name = "FxDirector"
	add_child(director)
	director.setup(p1, p2)
	if GameState.water != null:
		var water := Water.new()
		water.name = "Water"
		add_child(water)
		water.setup(GameState.water, [p1, p2] as Array[Fighter])
		flow.round_started.connect(water.on_round_started)
	flow.setup(p1, p2)


## Free movement: the 0.2 floor is 12 m deep (z ∈ ±6) and the circle arena is ARENA_RADIUS wide,
## so the floor grows in z to cover the circle. Plane mode keeps the scene as it is.
func _round_floor() -> void:
	var depth := 2.0 * (Fighter.ARENA_RADIUS + 1.0)
	var shape := ((ground.get_node("Shape") as CollisionShape3D).shape as BoxShape3D).duplicate() as BoxShape3D
	shape.size.z = depth
	shape.size.x = maxf(shape.size.x, depth)   # launch 6: the circle (20 m) outgrew the 0.2 floor in x too
	(ground.get_node("Shape") as CollisionShape3D).shape = shape
	var mi := ground.get_node("Mesh") as MeshInstance3D
	var mesh := (mi.mesh as BoxMesh).duplicate() as BoxMesh
	mesh.size.z = depth
	mesh.size.x = maxf(mesh.size.x, depth)
	mi.mesh = mesh


## Free movement (launch 6, ADR-018 п. 5): the plane's invisible walls WallL/WallR (x = ±13.5, layer 1) stand inside
## the 20 m circle. They would stop fighters and pull the camera arm in, so in 3D they leave the world; the circle holds
## the fighters (Fighter.clamp_arena).
func _drop_plane_walls() -> void:
	for w in ["WallL", "WallR"]:
		var body := get_node_or_null(w) as StaticBody3D
		if body != null:
			body.collision_layer = 0
			body.collision_mask = 0


## Sprint A3: cover bodies on this arena (the camera arm ignores them).
var cover_bodies: Array[StaticBody3D] = []
## Lantern lights (night only).
var lamp_lights: Array[OmniLight3D] = []
const LAMP_LIGHT := Color(1.0, 0.74, 0.42)
const COVER_WOOD := Color(0.3, 0.2, 0.16)    # PLACEHOLDER stall / crate tone until band C props
const COVER_STONE := Color(0.42, 0.42, 0.48) # PLACEHOLDER fountain bowl
const LAMP_RANGE := 9.0
const LAMP_ENERGY := 1.6
const ANCHOR_RING := 8
const ANCHOR_RING_R := 14.0


## Free movement: the 0.2 anchors sit on the X line. Until a 3D anchor layout exists (PLACEHOLDER —
## level layout from T1 Дедал / T5 Арес, ADR-011), every off-centre anchor gets a twin turned 90°
## around the arena centre, so anchors stand in front of and behind the fight, not only to the sides.
func _anchors_around() -> void:
	var root := get_node("Anchors") as Node3D
	for a in root.get_children():
		var m := a as Marker3D
		if m == null or not m.is_in_group("grapple_anchor"):
			continue
		var p := m.position
		if absf(p.x) < 0.01 and absf(p.z) < 0.01:
			continue
		var twin := m.duplicate() as Marker3D
		twin.name = "%sZ" % m.name
		twin.position = Vector3(-p.z, p.y, p.x)
		root.add_child(twin)
	# launch 6: the 20 m circle (02 § Коло арени) needs an anchor within grapple_range (14 m) from every point —
	# a ring of ANCHOR_RING lamps at ANCHOR_RING_R between the axes. PLACEHOLDER layout until ADR-011's level.
	var proto := root.get_node_or_null("Anchor1") as Marker3D
	if proto == null:
		return
	for k in ANCHOR_RING:
		var ang := TAU * (float(k) + 0.5) / float(ANCHOR_RING)
		var ring := proto.duplicate() as Marker3D
		ring.name = "Ring%d" % k
		ring.position = Vector3(cos(ang) * ANCHOR_RING_R, proto.position.y, sin(ang) * ANCHOR_RING_R)
		root.add_child(ring)


func _spawn(idx: int, char_id: String, x: float, face: int, cpu: bool) -> Fighter:
	var f := FIGHTER_SCENE.instantiate() as Fighter
	f.player_index = idx
	f.data = GameState.load_character(char_id)
	f.is_cpu = cpu
	fighters_root.add_child(f)
	f.reset_for_round(x, face)
	return f


func _on_hit(attacker: Fighter, victim: Fighter, move: MoveData, blocked: bool) -> void:
	var crit := victim.last_hit_crit
	_shake(0.06 if blocked else clampf(move.damage / 420.0 + (0.15 if crit else 0.0), 0.1, 0.6))
	if not Fx.enabled:
		return
	var at := victim.global_position + Vector3(0.0, 1.15, 0.35)
	var sheet := FxDirector.hit_spark(self, at, attacker, move.damage, blocked, crit) != null
	var spark := HitSpark.new()
	fx_root.add_child(spark)
	spark.global_position = at
	spark.setup(blocked, attacker.data.accent_color, move.damage, crit, sheet)


func _on_ko(_f: Fighter) -> void:
	_shake(0.7)


func _shake(amount: float) -> void:
	if duel_camera != null:
		duel_camera.shake(amount)
	else:
		camera.shake(amount)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_hitboxes"):
		GameState.show_hitboxes = not GameState.show_hitboxes
	elif event.is_action_pressed("debug_reset") and GameState.training_mode:
		flow.reset_positions()
	elif event.is_action_pressed("ui_pause"):
		hud.toggle_pause()


## Sprint A3 (docs/GDD/04-Grapple-System.md § Якорі й укриття): an arena with a layout swaps the 0.2 anchors + ring for
## Арес's anchors, marks lanterns, and builds its cover. No layout (river) keeps what _anchors_around() made.
func _apply_layout(layout: String) -> void:
	var spec := ArenaLayout.anchors(layout)
	if spec.is_empty():
		return
	var root := get_node("Anchors") as Node3D
	var proto := (root.get_node("Anchor1") as Marker3D).duplicate() as Marker3D
	for c in root.get_children():
		root.remove_child(c)
		c.queue_free()
	for i in spec.size():
		var a: Array = spec[i]
		var m := proto.duplicate() as Marker3D
		m.name = "%s%d" % [layout.capitalize(), i]
		m.position = Vector3(a[0], a[2], a[1])
		m.set_meta("lamp", a[3])
		root.add_child(m)
	proto.free()
	for cv in ArenaLayout.cover(layout):
		var body := StaticBody3D.new()
		body.name = "Cover%d" % cover_bodies.size()
		body.collision_layer = 1 | ArenaLayout.COVER_LAYER
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var mi := MeshInstance3D.new()
		if cv[0] == "cylinder":
			var cs := CylinderShape3D.new()
			cs.radius = cv[2].x
			cs.height = cv[2].y
			shape.shape = cs
			var cm := CylinderMesh.new()
			cm.top_radius = cv[2].x
			cm.bottom_radius = cv[2].x
			cm.height = cv[2].y
			mi.mesh = cm
		else:
			var bs := BoxShape3D.new()
			bs.size = cv[2]
			shape.shape = bs
			var bm := BoxMesh.new()
			bm.size = cv[2]
			mi.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COVER_STONE if cv[0] == "cylinder" else COVER_WOOD
		mat.roughness = 1.0
		mi.material_override = mat
		body.add_child(shape)
		body.add_child(mi)   # PLACEHOLDER block until band C props
		body.position = cv[1]
		add_child(body)
		cover_bodies.append(body)


## Night: every lantern anchor (A3 layouts mark them; the 0.2 / river anchors all carry a lantern) gets a warm light.
func _light_lamps(night: bool) -> void:
	if not night:
		return
	for n in get_tree().get_nodes_in_group("grapple_anchor"):
		var m := n as Node3D
		if m == null or not bool(m.get_meta("lamp", true)):
			continue
		var l := OmniLight3D.new()
		l.name = "LampLight"
		l.light_color = LAMP_LIGHT
		l.omni_range = LAMP_RANGE
		l.light_energy = LAMP_ENERGY
		l.shadow_enabled = false
		m.add_child(l)
		lamp_lights.append(l)
