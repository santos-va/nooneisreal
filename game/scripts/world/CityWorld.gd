class_name CityWorld
extends Node3D
## Bounded city traversal slice. No invisible opponent and no implicit match simulation.
const FIGHTER_SCENE := preload("res://scenes/fighter/Fighter.tscn")
const CITY_FIGHTER := preload("res://scripts/world/CityFighter.gd")
const DISTRICT_SCENE := preload("res://scenes/world/CityDistrict.tscn")

var player: CityFighter
## The script the hero's body runs: always CityFighter in the game. A fixture may hand a CityFighter subclass (a frozen
## pre-fix copy or one deliberate mutation, tools/world/city_fighter_mutants.gd) before the world enters the tree.
var fighter_script: Script = CITY_FIGHTER
var camera_rig: CityCamera
var district: Node3D
var ropes: MatchRopes
var onboarding: CityOnboarding
var hud: CityHud
var npc_director: CityNpcDirector
var lower_story: CityLowerStory
@export var lower_story_save_path: String = CityLowerStory.SAVE_PATH
@export var lower_story_save_enabled: bool = true
var story: CityStory
var story_dialogue: NpcDialogue
@export var story_save_path: String = CityStory.SAVE_PATH
@export var story_save_enabled: bool = true
var progress: CityProgress
var cosmetics: CityCosmetics
var journey: CityJourney
@export var journey_save_path: String = CityJourney.SAVE_PATH
## ADR-024: the first lethal fight in the central_court pocket (entry at its safe point).
var lethal: CityLethalFight
## Plan 2026-10-08-City-Events-Stage-1: the city events (В1 alley, В2 leaves) and the «Заплутаність» state.
var haze: CityHaze
var haze_vignette: CityHazeVignette
var events: CityEventDirector
## Plan 2026-10-08-Survival-Hunger step 4: the hunger scale (H, its bands, food, the collapse, the pocket transfer).
var hunger: CityHunger
## Plan 2026-10-08-Thirst-Substances-Icons step 1: the thirst scale on the hunger clock, and the pump that switches it on.
var thirst: CityThirst
## Step 2: «Хміль» and «Задишка» (sold by the street pedlar, CityVendorEvent); they never stack with «Заплутаність».
var substances: CitySubstances
@export var journey_save_enabled: bool = true
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
	Music.stop_music()
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
	base_player.set_script(fighter_script)
	player = base_player as CityFighter
	player.name = "Player"
	player.data = GameState.load_character(GameState.p1_character)
	player.player_index = 1
	player.is_cpu = false
	add_child(player)
	journey = CityJourney.new()
	journey.name = "DistrictJourney"
	add_child(journey)
	journey.setup(GameState.p1_character, journey_save_enabled, journey_save_path)
	player.restart_at(journey.resume_position())
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
	hud.bind_journey(journey)
	progress = CityProgress.new()
	progress.name = "DistrictProgress"
	add_child(progress)
	progress.setup(GameState.p1_character)
	hud.bind_progress(progress)
	story = CityStory.new()
	story.name = "ClocktowerStory"
	add_child(story)
	story.setup(GameState.p1_character, story_save_enabled, story_save_path)
	story.changed.connect(_apply_story_world)
	_apply_story_world()
	story_dialogue = NpcDialogue.new()
	story_dialogue.name = "StoryInspection"
	add_child(story_dialogue)
	story_dialogue.local_toggle.hide()
	lower_story = CityLowerStory.new()
	lower_story.name = "LowerMarkStory"
	add_child(lower_story)
	lower_story.setup(GameState.p1_character, story, lower_story_save_enabled, lower_story_save_path)
	lower_story.changed.connect(_apply_lower_world)
	_apply_lower_world()
	hud.bind_story(story, self)
	hud.bind_lower_story(lower_story)
	cosmetics = CityCosmetics.new()
	cosmetics.name = "CityClothStyle"
	add_child(cosmetics)
	cosmetics.setup(player, progress)
	hud.restart_requested.connect(restart_exploration)
	hud.exit_requested.connect(return_to_menu)
	npc_director = CityNpcDirector.new()
	npc_director.name = "Residents"
	add_child(npc_director)
	npc_director.setup(player, progress, story, lower_story)
	npc_director.conversation_started.connect(camera_rig.begin_conversation)
	npc_director.conversation_ended.connect(camera_rig.end_conversation)
	hud.bind_quest_context(npc_director)
	lethal = CityLethalFight.new()
	lethal.name = "LethalFight"
	add_child(lethal)
	lethal.setup(self)
	haze = CityHaze.new()
	haze.name = "Haze"
	add_child(haze)
	haze.setup(camera_rig.camera)
	haze_vignette = CityHazeVignette.new()
	haze_vignette.name = "HazeVignette"
	add_child(haze_vignette)
	haze_vignette.bind(haze)
	player.haze = haze
	npc_director.haze = haze
	hud.bind_haze(haze)
	substances = CitySubstances.new()
	substances.name = "Substances"
	add_child(substances)
	substances.haze = haze
	player.substances = substances
	events = CityEventDirector.new()
	events.name = "CityEvents"
	add_child(events)
	events.setup(self)
	events.conversation_started.connect(camera_rig.begin_conversation)
	events.conversation_ended.connect(camera_rig.end_conversation)
	hunger = CityHunger.new()
	hunger.name = "Hunger"
	add_child(hunger)
	hunger.setup(self)
	thirst = CityThirst.new()
	thirst.name = "Thirst"
	add_child(thirst)
	thirst.setup(self, hunger.running)
	hunger.thirst = thirst
	hunger.substances = substances
	thirst.substances = substances
	substances.thirst = thirst
	player.hunger = hunger
	npc_director.hunger = hunger
	hud.bind_thirst(thirst)
	hud.bind_hunger(hunger)
	hud.bind_substances(substances)
	_reset_observation()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var bounds := CityLayout.district_bounds()
	var point := player.global_position
	if not point.is_finite() or point.y < bounds.position.y - 6.0 or absf(point.x) > 36.0 or absf(point.z) > 36.0:
		recover_to_spawn()
		return
	var distance := Vector2(point.x - _last_position.x, point.z - _last_position.z).length()
	journey.observe(player, delta)
	if distance < 2.0 and player.on_ground():
		onboarding.record_event("move", distance)
	if _last_grounded and player.state == Fighter.State.JUMP and _last_state != Fighter.State.JUMP and player.velocity.y > 0.0:
		onboarding.record_event("jump")
	if player.grapple.attached and not _last_attached:
		onboarding.record_event("rope")
	if progress != null:
		for place: Dictionary in CityPlaces.landmarks():
			if player.global_position.distance_to(place.position) <= float(place.radius):
				progress.visit_landmark(place.id)
		if player.grapple.attached:
			var points: Array[Vector3] = CityLayout.anchors()
			for index: int in points.size():
				if player.grapple.anchor_point.distance_to(points[index]) < 0.6:
					progress.record_event("rope", "anchor_%d" % index)
	_update_story_interaction()
	_reset_observation()

func _apply_story_world() -> void:
	var maintenance: Node = district.get("maintenance")
	if is_instance_valid(maintenance):
		maintenance.set_story_shortcut_open(story.shortcut_open())

func _story_points() -> Dictionary:
	var maintenance: Node = district.get("maintenance")
	return maintenance.story_points() if is_instance_valid(maintenance) else {}

func _apply_lower_world() -> void:
	var gallery: Node = district.get("lower_gallery")
	if is_instance_valid(gallery):
		gallery.set_lamp_aligned(lower_story.lamp_aligned())
		gallery.set_record_delivered(lower_story.record_delivered())

func active_episode() -> Node:
	if story.stage() != "completed":
		return story
	if lower_story != null and lower_story.stage() not in ["locked", "completed"]:
		return lower_story
	return null

func _interaction_point(id: String) -> Node3D:
	if id in ["lower_lamp", "lower_plate"]:
		var gallery: Node = district.get("lower_gallery")
		return gallery.lower_points().get(id.trim_prefix("lower_")) if is_instance_valid(gallery) else null
	var key: String = {"latch": "clue_a", "counterweight_trace": "clue_b", "mechanism": "mechanism"}.get(id, "")
	return _story_points().get(key)

func _lower_target() -> Dictionary:
	if lower_story.stage() in ["available", "return"]:
		return {"id": "lower_lada", "title": lower_story.current_hint(), "position": CityPlaces.worker_positions().workshop}
	var id: String = "lower_lamp" if lower_story.stage() == "lighting" else "lower_plate"
	var point: Node3D = _interaction_point(id)
	return {"id": id, "title": lower_story.current_hint(), "position": point.global_position} if is_instance_valid(point) else {}

func story_target() -> Dictionary:
	if active_episode() == lower_story and lower_story != null:
		return _lower_target()
	if story.stage() in ["available", "return"]:
		return {"id": "story_lada", "title": story.text(story.stage()), "position": CityPlaces.worker_positions().workshop}
	var points := _story_points()
	for pair: Array in [["latch", "clue_a"], ["counterweight_trace", "clue_b"], ["mechanism", "mechanism"]]:
		if (pair[0] == "mechanism" and story.stage() == "mechanism") or (pair[0] != "mechanism" and story.stage() == "investigating" and not story.has_clue(pair[0])):
			var target: Node3D = points.get(pair[1])
			if is_instance_valid(target):
				return {"id": "story_" + pair[0], "title": story.text("prompt_" + pair[0]), "position": target.global_position}
	return {}

func can_inspect_story(id: String) -> bool:
	if story == null or player == null or story.hero_id != player.data.id or get_tree().paused or InputRouter.ui_suppressed() or player.control_locked or player.frozen_frames > 0 or player.hitstop_frames > 0 or not player.on_ground() or player.grapple.busy():
		return false
	if player.state not in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.CROUCH, Fighter.State.BLOCK]:
		return false
	if id.begins_with("lower_") and (lower_story == null or not lower_story.prerequisite_ready()):
		return false
	var point: Node3D = _interaction_point(id)
	if not is_instance_valid(point):
		return false
	var origin: Vector3 = player.global_position + Vector3.UP * 1.1
	var offset: Vector3 = point.global_position - origin
	# PLACEHOLDER hand-height inspection reach; no cross-floor or through-wall actions.
	if not offset.is_finite() or absf(offset.y) > 0.75 or Vector2(offset.x, offset.z).length() > 1.35:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, point.global_position, 1, [player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or (point.has_meta("interaction_body") and is_instance_valid(point.get_meta("interaction_body")) and hit.collider == point.get_meta("interaction_body"))

func interact_story(id: String) -> bool:
	if not can_inspect_story(id) or npc_director.find_nearest() >= 0:
		return false
	if id.begins_with("lower_"):
		return _interact_lower(id)
	var response: String
	if story.stage() == "available":
		response = story.text("before_accept")
	elif id == "mechanism":
		if story.open_shortcut():
			response = story.text("opened")
		else:
			response = story.current_hint()
	else:
		story.inspect(id)
		response = story.text(id)
		if story.stage() == "mechanism":
			response += "\n\n" + story.text(story.hero_id + "_observation") + "\n" + story.text("mechanism_hint")
	story_dialogue.show_fact(response)
	return true

func _interact_lower(id: String) -> bool:
	var response: String
	if lower_story.stage() == "available":
		response = lower_story.text("available")
	elif id == "lower_lamp":
		if not lower_story.toggle_lamp():
			return false
		response = lower_story.text("lamp_toward" if lower_story.lamp_aligned() else "lamp_away")
		if lower_story.has_copy():
			response += "\n" + lower_story.text("copy_retained")
	elif id == "lower_plate":
		var gallery: Node = district.get("lower_gallery")
		if lower_story.has_copy():
			response = lower_story.text("copied_fact")
		elif not lower_story.lamp_aligned() or not is_instance_valid(gallery) or not gallery.plate_is_lit():
			response = lower_story.text("unlit_plate")
		elif lower_story.copy_mark():
			response = lower_story.text("copied_fact") + "\n\n" + lower_story.text(lower_story.hero_id + "_observation") + "\n" + lower_story.text("boundary")
		else:
			return false
	else:
		return false
	story_dialogue.show_fact(response)
	return true

func _update_story_interaction() -> void:
	hud.set_story_prompt("")
	if lethal.active or InputRouter.ui_suppressed() or npc_director.find_nearest() >= 0:
		return
	var selected: String = ""
	var best: float = INF
	for id: String in ["latch", "counterweight_trace", "mechanism", "lower_lamp", "lower_plate"]:
		if can_inspect_story(id):
			var distance: float = player.global_position.distance_squared_to(_interaction_point(id).global_position)
			if distance < best:
				best = distance
				selected = id
	if selected.is_empty():
		if not _update_pump():
			_update_lethal_entry()
		return
	var gamepad: bool = camera_rig.aim.last_gamepad
	var action: String = story.text("prompt_" + selected)
	if selected == "mechanism" and story.stage() != "mechanism":
		action = "Оглянути механізм"
	elif selected == "lower_lamp":
		action = "Оглянути ліхтар" if lower_story.stage() == "available" else lower_story.text("prompt_lamp_away" if lower_story.lamp_aligned() else "prompt_lamp_toward")
	elif selected == "lower_plate":
		action = lower_story.text("prompt_plate") if lower_story.stage() == "copy" else "Переглянути схему"
	hud.set_story_prompt(InputRouter.binding_label(1, "interact", gamepad) + " · " + action)
	if InputRouter.just_pressed(1, "interact"):
		interact_story(selected)

## The water pump (plan 2026-10-08-Thirst-Substances-Icons step 1; T8 п. 2 «Колонка»): the existing `interact` at the
## spout, prompted on the story line; no menu, free. True when the hero is at the spout (the key is the pump's or an
## event's: either way no other prompt is offered on it).
## A street event's prompt on the same key wins: while it is shown the pump says nothing and takes no press (T4 audit
## 2026-10-08 п. 3, plan 2026-10-09 step 4). A resident's prompt already wins in _update_story_interaction.
func _update_pump() -> bool:
	if thirst == null or not thirst.can_drink(player):
		return false
	if events != null and events.dialogue != null and events.dialogue.prompt.visible:
		return true
	hud.set_story_prompt(InputRouter.binding_label(1, "interact", camera_rig.aim.last_gamepad) + " · " + PUMP_PROMPT)
	if InputRouter.just_pressed(1, "interact"):
		thirst.drink_water("pump")
		Sfx.play(PUMP_SFX, PUMP_SFX_DB)
	return true

const PUMP_PROMPT := "Drink water · free"   # T8 п. 2, PLACEHOLDER T7
const PUMP_SFX := "pump_drink"              # PLACEHOLDER name: silent until a registered file exists (Sfx.gd:6)
const PUMP_SFX_DB := -8.0

## The lethal pocket's entry is an explicit interaction at its safe point, prompted like the story points.
func _update_lethal_entry() -> void:
	if not lethal.can_enter():
		return
	if haze != null and haze.haze_active():
		# T5 розвилка 8 / T7 § 5.2: the pocket waits until the state has passed; the fight stays deterministic.
		hud.set_story_prompt(HAZY_ENTRY_TEXT)
		return
	if substances != null and substances.active():
		# T5 Substances М5, T8 п. 3: any substance state shuts the pocket; the text names the state and both ways out.
		hud.set_story_prompt(TIPSY_ENTRY_TEXT if substances.state == "tipsy" else WINDED_ENTRY_TEXT)
		return
	hud.set_story_prompt(lethal.prompt_text(camera_rig.aim.last_gamepad))
	if InputRouter.just_pressed(1, "interact"):
		lethal.request_open()

## T8 06-UI-UX § «Випадки міста: COMFORT і HUD» п. 2 (final words): the reason and both ways out; no key, no action.
const HAZY_ENTRY_TEXT := "TOO HAZY TO FIGHT · Wait it out, or eat at «Шавлія» to clear it sooner"
## T8 06-UI-UX § «Спрага…» п. 3 (PLACEHOLDER T7).
const TIPSY_ENTRY_TEXT := "TOO TIPSY TO FIGHT · Wait it out, or drink water to clear it sooner"
const WINDED_ENTRY_TEXT := "TOO WINDED TO FIGHT · Wait it out, or drink water to clear it sooner"

func _reset_observation() -> void:
	_last_position = player.global_position
	_last_grounded = player.on_ground()
	_last_attached = player.grapple.attached
	_last_state = player.state

func recover_to_spawn() -> void:
	# Fall recovery resets runtime motion, but retains the last safe place.
	if lethal != null and lethal.active:
		lethal.close("abort")
	if events != null:
		events.abort_active("recover")
	ropes.clear_match()
	player.restart_at(journey.resume_position())
	if hunger != null:
		hunger.restore_city_hp()   # a fall refills nothing: the city hp stands (T5 § 4)
	camera_rig.reset_view()
	InputRouter.acquire_ui(self)
	InputRouter.release_ui(self)
	_reset_observation()

func restart_exploration() -> void:
	get_tree().paused = false
	hud.set_paused(false)
	onboarding.restart()
	journey.restart_walk()
	if haze != null:
		haze.clear()
	if substances != null:
		substances.clear()
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
