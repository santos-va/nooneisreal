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
	var st := GameState.stage()
	backdrop.apply(st)
	sun.rotation_degrees = Vector3(-42.0, 35.0, 0.0)
	sun.light_color = st.sun
	if world_env.environment:
		world_env.environment.ambient_light_color = st.ambient
	if GameState.free_move:
		_round_floor()
	GameState.water = null
	var water_path: String = st.get("water", "")
	if water_path != "" and ResourceLoader.exists(water_path):
		GameState.water = (load(water_path) as WaveField).duplicate()
		GameState.water.reset(1)
		# fighters stand on the waves; the stone floor sinks below the deepest trough (it still
		# catches ragdolls) and its mesh is hidden under the water
		ground.position.y = GameState.water.min_height() - 0.1
		(ground.get_node("Mesh") as MeshInstance3D).visible = false
	p1 = _spawn(1, GameState.p1_character, -3.0, 1, false)
	p2 = _spawn(2, GameState.p2_character, 3.0, -1, GameState.p2_is_cpu)
	p1.opponent = p2
	p2.opponent = p1
	if GameState.free_move:
		camera.process_mode = Node.PROCESS_MODE_DISABLED
		duel_camera.setup(p1, p2)
	else:
		camera.setup(p1, p2)
		duel_camera.queue_free()
		duel_camera = null
	for f in [p1, p2]:
		(f as Fighter).hit_landed.connect(_on_hit)
		(f as Fighter).knocked_out.connect(_on_ko)
	hud.bind(p1, p2, flow)
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
	(ground.get_node("Shape") as CollisionShape3D).shape = shape
	var mi := ground.get_node("Mesh") as MeshInstance3D
	var mesh := (mi.mesh as BoxMesh).duplicate() as BoxMesh
	mesh.size.z = depth
	mi.mesh = mesh


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
	var spark := HitSpark.new()
	fx_root.add_child(spark)
	spark.global_position = victim.global_position + Vector3(0.0, 1.15, 0.35)
	spark.setup(blocked, attacker.data.accent_color, move.damage, crit)


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
