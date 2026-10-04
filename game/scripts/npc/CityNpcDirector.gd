class_name CityNpcDirector
extends Node3D
## Logical population is bounded; only nearby residents own render actors.
@export var active_radius: float = 24.0 # PLACEHOLDER streaming budget.
@export var tick_seconds: float = 6.0 # PLACEHOLDER fictional schedule clock.
@export var talk_radius: float = 3.0
var population := NpcPopulation.new()
var actors: Dictionary = {}
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
	refresh_elapsed += delta
	if elapsed >= tick_seconds:
		elapsed -= tick_seconds
		population.step()
		if population.tick % 10 == 0:
			persist()
	if refresh_elapsed >= 0.5:
		refresh_elapsed = 0.0
		_refresh_actors()
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
		var center := Vector3(-5.0 + (index % 4) * 3.2, 0.0, 2.0 + (index / 4) * 7.0)
		var active: bool = center.distance_to(player.global_position) < active_radius
		if active and not actors.has(index):
			var actor := CityNpcActor.new()
			add_child(actor)
			actor.setup(index, population.people[index])
			actors[index] = actor
		elif not active and actors.has(index):
			actors[index].queue_free()
			actors.erase(index)
		if actors.has(index):
			actors[index].walking = population.people[index].goal == "гуляє районом" and not dialogue.opened

func persist() -> bool:
	if not save_enabled:
		return false
	var ok: bool = population.save_to()
	if not ok:
		push_warning("City NPC save failed; current session remains in memory.")
	return ok

func _exit_tree() -> void:
	persist()
