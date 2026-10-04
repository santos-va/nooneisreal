class_name CityNpcDirector
extends Node3D
## Logical population is bounded; only nearby residents own render actors.
@export var active_radius: float = 24.0 # PLACEHOLDER streaming budget.
@export var tick_seconds: float = 6.0 # PLACEHOLDER fictional schedule clock.
@export var talk_radius: float = 4.2
@export var social_radius: float = 4.2 # PLACEHOLDER nearby greeting distance.
@export var social_seconds: float = 2.6 # PLACEHOLDER speech visibility.
@export var social_cooldown: float = 18.0 # PLACEHOLDER quiet interval per resident.
var population := NpcPopulation.new()
var progress: CityProgress
var hero_id: String = "choko"
var conversation_index: int = -1
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

func setup(target: Node3D, district_progress: CityProgress = null) -> void:
	player = target
	progress = district_progress
	hero_id = progress.hero_id if progress != null else "choko"
	if not population.load_from():
		load_failed = FileAccess.file_exists(NpcPopulation.SAVE_PATH)
		# Preserve damaged saves for recovery instead of overwriting evidence.
		save_enabled = not load_failed
		population.initialize(randi_range(1, 2147483646))
	dialogue = NpcDialogue.new()
	add_child(dialogue)
	dialogue.choice_selected.connect(_choose)
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
			open_conversation(nearest)

func find_nearest() -> int:
	var result: int = -1
	var best: float = talk_radius
	for index: int in actors:
		var actor: CityNpcActor = actors[index]
		var distance: float = player.global_position.distance_to(actor.global_position)
		if distance >= best:
			continue
		var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 1.5, actor.global_position + Vector3.UP * 1.5, 1)
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
			if index < 3:
				var job: String = ["grocer", "tailor", "workshop"][index]
				actor.setup_worker(job, CityPlaces.worker_positions()[job])
			if actor_states.has(index):
				actor.restore_motion(actor_states[index])
			actors[index] = actor
		elif not active and actors.has(index):
			actor_states[index] = actors[index].motion_state()
			actors[index].queue_free()
			actors.erase(index)
		if actors.has(index):
			# Work/rest goals describe the routine, not a command to freeze the actor.
			actors[index].walking = not dialogue.opened and actors[index].work_kind.is_empty()

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

func open_conversation(index: int) -> void:
	if not actors.has(index):
		return
	conversation_index = index
	population.meet(index, hero_id)
	if progress != null:
		progress.record_event("meet", population.people[index].id)
		if index >= 3:
			progress.record_event("resident", population.people[index].id)
	_show_conversation()
	persist()

func _job(index: int) -> String:
	return ["grocer", "tailor", "workshop"][index] if index < 3 else ""

func _show_conversation(response: String = "") -> void:
	if conversation_index < 0:
		return
	var index: int = conversation_index
	var job: String = _job(index)
	var job_title: String = {"grocer": "Крамниця · припаси й доручення", "tailor": "Кравець · кольорові перев’язі", "workshop": "Майстерня · міські маршрути"}.get(job, str(population.people[index].role))
	var text: String = str(population.people[index].name) + " — " + job_title + "\n" + population.dialogue(index, hero_id)
	if not response.is_empty():
		text += "\n\n" + response
	var options: Array[Dictionary] = []
	if progress != null:
		for q: Dictionary in progress.quests:
			if q.giver != job:
				continue
			var status: String = progress.quest_status(q.id)
			if status == "available":
				options.append({"id": "offer:" + str(q.id), "label": "Доручення: " + str(q.title)})
			elif status == "ready":
				options.append({"id": "turn:" + str(q.id), "label": "Завершити: " + str(q.title) + " · +%d жет." % int(q.reward)})
			elif status == "active":
				options.append({"id": "hint:" + str(q.id), "label": "Нагадати: " + str(q.title)})
		if job == "tailor":
			if progress.quest_status("parcel") == "active":
				options.append({"id": "parcel", "label": "Передати пакунок ниток"})
			options.append({"id": "styles", "label": "Приміряти перев’язь · %d жет." % int(progress.summary().credits)})
	options.append({"id": "topic:work", "label": "Розкажи про свою роботу"})
	options.append({"id": "topic:district", "label": "Що порадиш подивитися в районі?"})
	if progress != null and progress.quest_status("roof_walk") == "completed":
		options.append({"id": "topic:route", "label": "Поділитися враженнями від маршруту на дахах"})
	if progress != null and progress.quest_status("neighbours") == "completed":
		options.append({"id": "topic:neighbours", "label": "Поговорити про спільних знайомих"})
	dialogue.show_choices(text, options)

func _choose(action: String) -> void:
	if conversation_index < 0 or not dialogue.opened:
		return
	var index: int = conversation_index
	var job: String = _job(index)
	var pair: PackedStringArray = action.split(":", true, 1)
	var argument: String = pair[1] if pair.size() > 1 else ""
	if pair[0] in ["offer", "accept", "hint", "turn"] and progress != null:
		var q: Dictionary = progress.quest(argument)
		if q.is_empty() or q.giver != job:
			return
		if pair[0] in ["offer", "hint"]:
			var options: Array[Dictionary] = [{"id": "back", "label": "Назад до розмови"}]
			if progress.quest_status(argument) == "available":
				options.push_front({"id": "accept:" + argument, "label": "Беруся за справу · нагорода %d жет." % int(q.reward)})
			dialogue.show_choices(str(q.title) + "\n\n" + str(q.description) + "\n\n" + str(q.hint), options)
			return
		if pair[0] == "accept" and progress.accept_quest(argument):
			_show_conversation("Записано в журнал. " + str(q.hint))
		elif pair[0] == "turn" and progress.complete_quest(argument):
			population.bond_once(index, hero_id, "quest_" + argument, "Ти допоміг: " + str(q.title) + ".", 2)
			_show_conversation("Дякую за допомогу. Нагороду додано; це доручення завершене.")
	elif action == "parcel" and job == "tailor" and progress != null and progress.quest_status("parcel") == "active":
		progress.record_event("deliver", "thread_parcel")
		population.bond_once(index, hero_id, "parcel", "Ти приніс пакунок ниток із крамниці.", 2)
		_show_conversation("Саме ці нитки я чекав. Повернися до крамниці — там подякують за доставку.")
	elif action == "styles" and job == "tailor" and progress != null:
		var options: Array[Dictionary] = []
		for palette: Dictionary in progress.palettes:
			var owned: bool = palette.id in progress.heroes[hero_id].owned
			options.append({"id": "palette:" + str(palette.id), "label": str(palette.title) + (" · є" if owned else " · %d жет." % int(palette.price)), "enabled": owned or int(progress.summary().credits) >= int(palette.price)})
		options.append({"id": "back", "label": "Назад до розмови"})
		dialogue.show_choices("Кольорова перев’язь · " + hero_id.capitalize() + "\n\nПерев’язь відразу з’явиться поверх твого вбрання. Вибери колір до смаку.\nЖетони: %d" % int(progress.summary().credits), options)
	elif pair[0] == "palette" and job == "tailor" and progress != null:
		if progress.set_palette(argument):
			_show_conversation("Перев’язь змінено. Можна вийти з розмови й оглянути героя.")
	elif pair[0] == "topic":
		var reply: String = ""
		if argument == "work":
			reply = {"grocer": "Тримаю припаси для сусідів. Спершу познайомся з працівниками, а тоді допоможи доставити нитки.", "tailor": "Підбираю кольори. М'ятну перев’язь можна приміряти без жетонів; інші відкриваються за зароблене у районі.", "workshop": "Перевіряю спорядження й проходи. До верхньої вулиці ведуть дві рампи; не обов'язково починати з мотузки."}.get(job, "Я працюю тут: " + str(population.people[index].role) + ". Між справами гуляю районом і вітаюся із сусідами.")
		elif argument == "district":
			reply = "На півночі є міст між дахами та годинникова вежа. Майданчик ринку — на півдні. Крамниці шукай на заході, входи позначені вивісками."
		elif argument == "route" and progress != null and progress.quest_status("roof_walk") == "completed":
			reply = "Тепер у нас є спільна тема — верхній маршрут. Добре зустріти того, хто сам його пройшов."
		elif argument == "neighbours" and progress != null and progress.quest_status("neighbours") == "completed":
			reply = "Ти вже знаєш наших сусідів. Заходь і без доручень — тепер ти тут своє обличчя."
		if not reply.is_empty():
			population.bond_once(index, hero_id, "topic_" + argument, "Ми поговорили: " + {"work": "про роботу", "district": "про місця району", "route": "про пройдений верхній маршрут", "neighbours": "про спільних знайомих"}.get(argument, "про район") + ".", 2 if argument in ["route", "neighbours"] else 1)
			_show_conversation(reply)
	else:
		_show_conversation()
	persist()

func persist() -> bool:
	if not save_enabled:
		return false
	var ok: bool = population.save_to()
	if not ok:
		push_warning("City NPC save failed; current session remains in memory.")
	return ok

func _exit_tree() -> void:
	persist()
