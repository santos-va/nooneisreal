class_name CityNpcDirector
extends Node3D
## Logical population is bounded; only nearby residents own render actors.
@export var active_radius: float = 24.0 # PLACEHOLDER streaming budget.
@export var tick_seconds: float = 6.0 # PLACEHOLDER fictional schedule clock.
@export var talk_radius: float = 3.0
@export var social_radius: float = 4.2 # PLACEHOLDER nearby greeting distance.
@export var social_seconds: float = 2.6 # PLACEHOLDER speech visibility.
@export var social_cooldown: float = 18.0 # PLACEHOLDER quiet interval per resident.
var population := NpcPopulation.new()
var actors: Dictionary = {}
var actor_states: Dictionary = {}
var social_ready: Dictionary = {}
var runtime: float = 0.0
var player: Node3D
var dialogue: NpcDialogue
var elapsed: float = 0.0
var refresh_elapsed: float = 1.0
var nearest: int = -1
var save_enabled: bool = true
var load_failed: bool = false

func setup(target: Node3D) -> void:
	player = target
	if not population.load_from():
		load_failed = FileAccess.file_exists(NpcPopulation.SAVE_PATH)
		# Preserve damaged saves for recovery instead of overwriting evidence.
		save_enabled = not load_failed
		population.initialize(randi_range(1, 2147483646))
	dialogue = NpcDialogue.new()
	add_child(dialogue)
	_refresh_actors()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	elapsed += delta
	runtime += delta
	refresh_elapsed += delta
	if elapsed >= tick_seconds:
		elapsed -= tick_seconds
		population.step()
		if population.tick % 10 == 0:
			persist()
	if refresh_elapsed >= 0.5:
		refresh_elapsed = 0.0
		_refresh_actors()
		if not dialogue.opened:
			_update_conversations()
	if dialogue.opened:
		return
	nearest = find_nearest()
	dialogue.prompt.visible = nearest >= 0 and not InputRouter.ui_suppressed()
	if nearest >= 0:
		var gamepad: bool = false
		var camera: Camera3D = get_viewport().get_camera_3d()
		if camera != null and camera.has_meta("harpoon_aim"):
			gamepad = camera.get_meta("harpoon_aim").last_gamepad
		dialogue.prompt.text = InputRouter.binding_label(1, "interact", gamepad) + " · Поговорити: " + str(population.people[nearest].name)
		if InputRouter.just_pressed(1, "interact"):
			dialogue.show_fact(population.meet(nearest))
			persist()

func find_nearest() -> int:
	var result: int = -1
	var best: float = talk_radius
	for index: int in actors:
		var actor: CityNpcActor = actors[index]
		var distance: float = player.global_position.distance_to(actor.global_position)
		if distance >= best:
			continue
		var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, actor.global_position + Vector3.UP, 1)
		if player is CollisionObject3D:
			query.exclude = [player.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			continue
		best = distance
		result = index
	return result

func _refresh_actors() -> void:
	for index: int in population.people.size():
		var center: Vector3 = to_global(CityNpcActor.home_for(index))
		# Include the complete local route so walking cannot cross the streaming edge.
		var active: bool = center.distance_to(player.global_position) < active_radius + 4.1
		if active and not actors.has(index):
			var actor := CityNpcActor.new()
			add_child(actor)
			actor.setup(index, population.people[index])
			if actor_states.has(index):
				actor.restore_motion(actor_states[index])
			actors[index] = actor
		elif not active and actors.has(index):
			actor_states[index] = actors[index].motion_state()
			actors[index].queue_free()
			actors.erase(index)
		if actors.has(index):
			# Work/rest goals describe the routine, not a command to freeze the actor.
			actors[index].walking = not dialogue.opened

func _update_conversations() -> void:
	for index: int in actors:
		if runtime < float(social_ready.get(index, 1.0)):
			continue
		var actor: CityNpcActor = actors[index]
		for other: int in actors:
			if other <= index or runtime < float(social_ready.get(other, 1.0)):
				continue
			var peer: CityNpcActor = actors[other]
			if actor.global_position.distance_to(peer.global_position) > social_radius:
				continue
			var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP, peer.global_position + Vector3.UP, 1)
			if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				continue
			var lines: Array[String] = population.greet(index, other)
			actor.say(lines[0], peer.global_position, social_seconds)
			peer.say(lines[1], actor.global_position, social_seconds)
			social_ready[index] = runtime + social_cooldown
			social_ready[other] = runtime + social_cooldown
			break

func persist() -> bool:
	if not save_enabled:
		return false
	var ok: bool = population.save_to()
	if not ok:
		push_warning("City NPC save failed; current session remains in memory.")
	return ok

func _exit_tree() -> void:
	persist()
