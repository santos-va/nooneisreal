class_name CityLethalFight
extends Node
## ADR-024: the first lethal fight, in the city's `central_court` pocket. Owns the fight's whole lifetime: the explicit
## entry at the safe point, the CPU enemy, MatchFlow with `lethal = true`, the pocket's circle on both fighters, the
## residents standing aside, the duel camera, HUD H2 and the exit — victory (the enemy dies, the pocket closes), retry
## or return to the safe point. Leaving restores the city's input, camera, residents and HUD exactly; nothing is saved
## to CityStory at this step (plan 2026-10-07-First-Enemy-Lethal-Fight, step 2).
## Fighter keeps the duel's world assumptions (spawn at (±3, 0, 0), floor y = 0, docs/GDD/03 § Мінімум CPU via T5):
## they hold only in a pocket centred on the origin on flat ground — open() refuses any other pocket.
signal opened
signal closed(outcome: String)   # "victory" | "retreat" | "abort"

const FIGHTER_SCENE := preload("res://scenes/fighter/Fighter.tscn")
## Explicit entry reach around the safe point, like the story points' hand reach. PLACEHOLDER metres.
const ENTRY_REACH := 1.6
## Residents whose lane crosses the pocket circle (radius + NPC_CLEARANCE) stand NPC_ASIDE_EXTRA beyond the edge.
## Clearance 0: exactly the lanes through the pocket (T5's audit: residents 3, 5, 11). PLACEHOLDER metres.
const NPC_CLEARANCE := 0.0
const NPC_ASIDE_EXTRA := 2.5
## How long "<ENEMY> FALLS" holds over the body before the pocket closes. PLACEHOLDER (the match-end announce is 4 s).
const AFTERMATH_SECONDS := 3.0

var world: CityWorld
var player: CityFighter
var enemy: Fighter
var flow: MatchFlow
var camera: DuelCamera
var hud: LethalHud
var fx: FxDirector
var ring: MeshInstance3D
var marker: Node3D
var active: bool = false
## This session only: a dead enemy stays dead until the city is entered again (no CityStory save yet).
var enemy_defeated: bool = false
var held_residents: Array[int] = []
var outcome: String = ""
var _aftermath_left: float = -1.0
var _prior_training: bool = false


func setup(owner_world: CityWorld) -> void:
	world = owner_world
	player = world.player
	_build_marker()


static func encounter() -> Dictionary:
	return CityLayout.lethal_encounter()


static func pocket_spec() -> Dictionary:
	return CityLayout.pocket(String(encounter().pocket))


static func safe_point() -> Vector3:
	return encounter().safe_point


## The entry is offered only to a grounded, free hero at the safe point, outside any UI, while the enemy lives.
func can_enter() -> bool:
	if active or enemy_defeated or player == null or world == null:
		return false
	if get_tree().paused or InputRouter.ui_suppressed() or player.control_locked or player.frozen_frames > 0 or not player.on_ground() or player.grapple.busy():
		return false
	if player.state not in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.CROUCH, Fighter.State.BLOCK]:
		return false
	var offset: Vector3 = player.global_position - safe_point()
	return offset.is_finite() and absf(offset.y) <= 0.75 and Vector2(offset.x, offset.z).length() <= ENTRY_REACH


func prompt_text(gamepad: bool) -> String:
	return InputRouter.binding_label(1, "interact", gamepad) + " · FACE THE " + String(_enemy_data().display_name)


func _enemy_data() -> CharacterData:
	return load(String(encounter().enemy)) as CharacterData


func open() -> bool:
	if active or enemy_defeated:
		return false
	var spec := pocket_spec()
	if spec.is_empty() or not (spec.center as Vector3).is_equal_approx(Vector3.ZERO):
		push_error("CityLethalFight: only a pocket centred on the origin keeps Fighter's spawn/floor assumptions")
		return false
	var center: Vector3 = spec.center
	var radius: float = spec.radius
	active = true
	outcome = ""
	_aftermath_left = -1.0
	_prior_training = GameState.training_mode
	GameState.training_mode = false   # a lethal fight is never training: the CPU acts, nobody is auto-healed
	# Residents first: the pocket is empty before anyone stands in it.
	held_residents = world.npc_director.hold_clear_of(center, radius, NPC_CLEARANCE, NPC_ASIDE_EXTRA)
	enemy = FIGHTER_SCENE.instantiate() as Fighter
	enemy.name = "LethalEnemy"
	enemy.data = _enemy_data()
	enemy.player_index = 2
	enemy.is_cpu = true
	world.add_child(enemy)
	for f: Fighter in [player, enemy]:
		f.arena_center = center
		f.arena_radius = radius
	player.lethal_pocket = true
	player.opponent = enemy
	enemy.opponent = player
	GameState.duel = DuelFrame.new()
	GameState.duel.behind = true
	world.hud.set_fight_mode(true)
	world.hud.set_story_prompt("")
	flow = MatchFlow.new()
	flow.name = "LethalMatchFlow"
	flow.lethal = true
	world.add_child(flow)
	hud = LethalHud.new()
	hud.name = "LethalHud"
	world.add_child(hud)
	hud.bind(player, enemy, flow)   # before setup: round 1's announce reaches the HUD
	flow.match_over.connect(_on_match_over)
	hud.retry_requested.connect(retry)
	hud.return_requested.connect(retreat)
	flow.setup(player, enemy)   # round 1 at full HP: (-3, 0, 0) hero, (3, 0, 0) enemy
	_open_camera()   # after the round-1 placement: the lens starts behind the hero, no swing from the street
	# The duel's hit feedback (Arena._on_hit / _on_ko): painted sheets, sparks, camera shake. It only watches.
	fx = FxDirector.new()
	fx.name = "LethalFx"
	world.add_child(fx)
	fx.setup(player, enemy)
	for f: Fighter in [player, enemy]:
		f.hit_landed.connect(_on_hit)
		f.knocked_out.connect(_on_ko)
	_show_ring(center, radius)
	marker.visible = false
	opened.emit()
	return true


func _on_hit(attacker: Fighter, victim: Fighter, move: MoveData, blocked: bool) -> void:
	var crit := victim.last_hit_crit
	if camera != null:
		camera.shake(0.06 if blocked else clampf(move.damage / 420.0 + (0.15 if crit else 0.0), 0.1, 0.6))
	if not Fx.enabled:
		return
	var at := victim.global_position + Vector3(0.0, 1.15, 0.35)
	var sheet := FxDirector.hit_spark(world, at, attacker, move.damage, blocked, crit) != null
	var spark := HitSpark.new()
	Fx.root(world).add_child(spark)
	spark.global_position = at
	spark.setup(blocked, attacker.data.accent_color, move.damage, crit, sheet)


func _on_ko(_f: Fighter) -> void:
	if camera != null:
		camera.shake(0.7)


func _open_camera() -> void:
	camera = DuelCamera.new()
	camera.name = "LethalCamera"
	var arm := SpringArm3D.new()
	arm.name = "SpringArm3D"
	arm.spring_length = 9.0   # Arena.tscn DuelRig values
	arm.margin = 0.2
	camera.add_child(arm)
	var lens := Camera3D.new()
	lens.name = "Camera3D"
	lens.fov = DuelCamera.FOV_DEG
	lens.near = 0.1
	lens.far = 240.0
	arm.add_child(lens)
	world.add_child(camera)
	world.camera_rig.proximity.reset()   # the city lens's body fade never carries into the fight
	world.camera_rig.process_mode = Node.PROCESS_MODE_DISABLED
	camera.setup(player, enemy)
	camera.arm.add_excluded_object(player.get_rid())
	camera.arm.add_excluded_object(enemy.get_rid())


func _physics_process(delta: float) -> void:
	if not active or _aftermath_left < 0.0:
		return
	_aftermath_left -= delta
	if _aftermath_left <= 0.0:
		close("victory")


func _on_match_over(winner: int, _p1_name: String, _p2_name: String) -> void:
	if winner == 1:
		# The decisive KO killed the enemy (`_die` + slow-mo, no reset): the body lies until the pocket closes.
		enemy_defeated = true
		_aftermath_left = AFTERMATH_SECONDS


## RETRY FIGHT: a new match against the same enemy, both at full HP (MatchFlow.rematch, GDD 02 § Поразка героя).
func retry() -> void:
	if not active or flow == null:
		return
	hud.hide_defeat()
	flow.rematch()


## RETURN TO SAFE POINT: the fight ends without a death; the hero stands at the safe point in front of the pocket.
func retreat() -> void:
	close("retreat")


## Ends the fight and gives the city back: input, camera, residents, HUD, the hero's open-city rules.
func close(reason: String) -> void:
	if not active:
		return
	active = false
	outcome = reason
	_aftermath_left = -1.0
	Engine.time_scale = 1.0
	if hud != null:
		hud.hide_defeat()
		hud.queue_free()
		hud = null
	if flow != null:
		flow.set_physics_process(false)
		flow.queue_free()
		flow = null
	if player.hit_landed.is_connected(_on_hit):
		player.hit_landed.disconnect(_on_hit)
		player.knocked_out.disconnect(_on_ko)
	if is_instance_valid(fx):
		fx.queue_free()
	fx = null
	if is_instance_valid(enemy):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED   # no tick of a half-removed fight this frame
		enemy.opponent = null
		enemy._clear_ragdoll()
		InputRouter.v_clear(enemy.player_index)
		enemy.queue_free()
	enemy = null
	player.opponent = null
	player.lethal_pocket = false
	player.arena_center = Vector3.ZERO
	player.arena_radius = Fighter.ARENA_RADIUS
	GameState.duel = DuelFrame.new()
	GameState.training_mode = _prior_training
	if is_instance_valid(camera):
		camera.queue_free()
	camera = null
	world.camera_rig.process_mode = Node.PROCESS_MODE_INHERIT
	world.camera_rig.camera.make_current()
	world.npc_director.release_hold()
	held_residents.clear()
	world.hud.set_fight_mode(false)
	if ring != null:
		ring.queue_free()
		ring = null
	marker.visible = not enemy_defeated
	if reason != "abort":
		var at: Vector3 = safe_point() if reason == "retreat" else player.global_position
		player.restart_at(Vector3(at.x, maxf(at.y, 0.0), at.z))
		world.camera_rig.reset_view()
	closed.emit(reason)


## The scene is leaving (menu, quit) mid-fight: put the globals back without touching the hero.
func _exit_tree() -> void:
	if active:
		Engine.time_scale = 1.0
		GameState.training_mode = _prior_training
		InputRouter.v_clear(2)
		if hud != null:
			hud.hide_defeat()
		active = false


## The entry: a dim ring on the street at the safe point (presentation, no collider). PLACEHOLDER look, T6 review.
func _build_marker() -> void:
	marker = Node3D.new()
	marker.name = "LethalEntry"
	add_child(marker)
	var disc := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.7
	disc.mesh = torus
	disc.scale = Vector3(1.0, 0.05, 1.0)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.material_override = _material("brass")
	marker.add_child(disc)
	marker.position = safe_point() + Vector3(0, 0.01, 0)


## The pocket's soft wall drawn on the ground while the fight runs (presentation only). PLACEHOLDER look, T6 review.
func _show_ring(center: Vector3, radius: float) -> void:
	ring = MeshInstance3D.new()
	ring.name = "PocketRing"
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.06
	torus.outer_radius = radius + 0.06
	torus.rings = 96
	ring.mesh = torus
	ring.scale = Vector3(1.0, 0.05, 1.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.material_override = _material("ink")
	ring.position = center + Vector3(0, 0.012, 0)
	add_child(ring)


func _material(key: String) -> Material:
	var palette: Variant = world.district.get("materials") if world != null and is_instance_valid(world.district) else null
	if palette is Dictionary and (palette as Dictionary).has(key):
		return palette[key]
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color("2b2230")
	return fallback
