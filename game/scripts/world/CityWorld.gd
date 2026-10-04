class_name CityWorld
extends Node3D
## Bounded city traversal slice. No invisible opponent and no implicit match simulation.
const FIGHTER_SCENE := preload("res://scenes/fighter/Fighter.tscn")
const CITY_FIGHTER := preload("res://scripts/world/CityFighter.gd")
const DISTRICT_SCENE := preload("res://scenes/world/CityDistrict.tscn")

var player: CityFighter
var camera_rig: CityCamera
var district: Node3D
var ropes: MatchRopes
var onboarding: CityOnboarding
var hud: CityHud
var _prior_free_move: bool
var _prior_profile: String
var _prior_water: WaveField
var _prior_duel: DuelFrame
var _prior_time_scale: float
var _context_saved: bool = false
var _last_position := Vector3.ZERO
var _last_grounded: bool = false
var _last_attached: bool = false
var _last_state: int = Fighter.State.IDLE

func _ready() -> void:
	process_physics_priority = 20 # Observe actual fighter movement after its simulation tick.
	_prior_free_move = GameState.free_move
	_prior_profile = InputRouter.profile
	_prior_water = GameState.water
	_prior_duel = GameState.duel
	_prior_time_scale = Engine.time_scale
	_context_saved = true
	GameState.water = null
	GameState.duel = DuelFrame.new()
	GameState.set_free_move(true)
	InputRouter.apply_profile(InputRouter.PROFILE_SOLO, false)
	Engine.time_scale = 1.0
	_build_lighting()
	district = DISTRICT_SCENE.instantiate()
	add_child(district)
	ropes = MatchRopes.new()
	ropes.name = "MatchRopes"
	add_child(ropes)
	var fx := Node3D.new()
	fx.name = "FX"
	add_child(fx)
	var base_player := FIGHTER_SCENE.instantiate() as Fighter
	base_player.set_script(CITY_FIGHTER)
	player = base_player as CityFighter
	player.name = "Player"
	player.data = GameState.load_character(GameState.p1_character)
	player.player_index = 1
	player.is_cpu = false
	add_child(player)
	player.restart_at(CityLayout.spawn_position())
	camera_rig = CityCamera.new()
	camera_rig.name = "CityCamera"
	add_child(camera_rig)
	camera_rig.setup(player)
	onboarding = CityOnboarding.new()
	camera_rig.looked.connect(func(amount: float) -> void: onboarding.record_event("look", amount))
	hud = CityHud.new()
	hud.name = "CityHud"
	hud.setup(onboarding)
	add_child(hud)
	hud.bind_player(player)
	hud.restart_requested.connect(restart_exploration)
	hud.exit_requested.connect(return_to_menu)
	_reset_observation()

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var bounds := CityLayout.district_bounds()
	var point := player.global_position
	if not point.is_finite() or point.y < bounds.position.y - 6.0 or absf(point.x) > 36.0 or absf(point.z) > 36.0:
		recover_to_spawn()
		return
	var distance := Vector2(point.x - _last_position.x, point.z - _last_position.z).length()
	if distance < 2.0 and player.on_ground():
		onboarding.record_event("move", distance)
	if _last_grounded and player.state == Fighter.State.JUMP and _last_state != Fighter.State.JUMP and player.velocity.y > 0.0:
		onboarding.record_event("jump")
	if player.grapple.attached and not _last_attached:
		onboarding.record_event("rope")
	_reset_observation()

func _reset_observation() -> void:
	_last_position = player.global_position
	_last_grounded = player.on_ground()
	_last_attached = player.grapple.attached
	_last_state = player.state

func recover_to_spawn() -> void:
	# Recovery is an explicit fresh attempt, including finite rope inventory.
	ropes.clear_match()
	player.restart_at(CityLayout.spawn_position())
	camera_rig.reset_view()
	InputRouter.acquire_ui(self)
	InputRouter.release_ui(self)
	_reset_observation()

func restart_exploration() -> void:
	get_tree().paused = false
	hud.set_paused(false)
	onboarding.restart()
	recover_to_spawn()
	for node: Node in get_node("FX").get_children():
		node.queue_free()

func return_to_menu() -> void:
	get_tree().paused = false
	hud.set_paused(false)
	GameState.to_menu()

func _exit_tree() -> void:
	get_tree().paused = false
	InputRouter.release_ui(self)
	InputRouter.clear_recorded_view_basis(1)
	InputRouter.clear_view_basis(1)
	if _context_saved:
		GameState.water = _prior_water
		GameState.free_move = _prior_free_move
		GameState.duel = _prior_duel
		InputRouter.apply_profile(_prior_profile, false)
		Engine.time_scale = _prior_time_scale

func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.29, 0.35, 0.43)
	sky_material.sky_horizon_color = Color(0.72, 0.60, 0.54)
	sky_material.ground_bottom_color = Color(0.18, 0.16, 0.24)
	sky_material.ground_horizon_color = sky_material.sky_horizon_color
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.66, 0.66, 0.79)
	environment.ambient_light_energy = 0.40
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-44, -28, 0)
	sun.light_color = Color(1.0, 0.97, 0.94)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	add_child(sun)
