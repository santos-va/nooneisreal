class_name CityNpcDirector
extends Node3D
signal conversation_started(actor: Node3D)
signal conversation_ended
## Logical population is bounded; only nearby residents own render actors.
@export var active_radius: float = 24.0 # PLACEHOLDER streaming budget.
@export var tick_seconds: float = 6.0 # PLACEHOLDER fictional schedule clock.
const TALK_GAP: float = 0.70
const TALK_VERTICAL: float = 0.75
@export var social_radius: float = 4.2 # PLACEHOLDER nearby greeting distance.
@export var social_seconds: float = 2.6 # PLACEHOLDER speech visibility.
@export var social_cooldown: float = 18.0 # PLACEHOLDER quiet interval per resident.
var population := NpcPopulation.new()
var story: CityStory
var _story_offer_open: bool = false
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
var conversation_context := NpcConversationContext.new()
var local_conversation: NpcLocalConversation
var local_token: int = -1
var chatter: Node
var current_context: Dictionary = {}
var current_fallback: String = ""
var listen_at: float = INF

func setup(target: Node3D, district_progress: CityProgress = null, story_model: CityStory = null) -> void:
	player = target
	progress = district_progress
	story = story_model
	hero_id = progress.hero_id if progress != null else "choko"
	if not population.load_from():
		load_failed = FileAccess.file_exists(NpcPopulation.SAVE_PATH)
		# Preserve damaged saves for recovery instead of overwriting evidence.
		save_enabled = not load_failed
		population.initialize(randi_range(1, 2147483646))
	dialogue = NpcDialogue.new()
	add_child(dialogue)
	dialogue.choice_selected.connect(_choose)
	dialogue.closed.connect(_close_conversation)
	dialogue.local_enabled_changed.connect(_set_local_enabled)
	local_conversation = NpcLocalConversation.new()
	add_child(local_conversation)
	local_conversation.line_ready.connect(_local_line)
	dialogue.local_toggle.set_pressed_no_signal(local_conversation.enabled)
	# Optional presentation helper owns bounded audio voices.
	var chatter_script := load("res://scripts/npc/NpcChatter.gd") as Script
	if chatter_script != null:
		chatter = chatter_script.new()
		add_child(chatter)
		chatter.call("configure", player)
	_refresh_actors()
	if story != null:
		story.changed.connect(_sync_story_memory)
		_sync_story_memory()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	if progress != null and progress.hero_id != hero_id:
		if dialogue.opened:
			dialogue.close()
		hero_id = progress.hero_id
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
		_update_conversations()
	if dialogue.opened:
		if runtime >= listen_at:
			_present(conversation_index, "listen", player.global_position)
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

func player_radius() -> float:
	var shape: CollisionShape3D = player.get_node_or_null("BodyShape") as CollisionShape3D
	if shape != null and shape.shape is CapsuleShape3D:
		return shape.shape.radius * maxf(absf(shape.global_basis.get_scale().x), absf(shape.global_basis.get_scale().z))
	return 0.35

func surface_gap(index: int) -> float:
	if player == null or not actors.has(index):
		return INF
	var difference: Vector3 = actors[index].global_position - player.global_position
	return maxf(0.0, Vector2(difference.x, difference.z).length() - player_radius() - actors[index].interaction_radius())

func can_talk(index: int) -> bool:
	if player == null or not actors.has(index):
		return false
	var actor: CityNpcActor = actors[index]
	if absf(player.global_position.y - actor.global_position.y) > TALK_VERTICAL or surface_gap(index) > TALK_GAP + 0.00001:
		return false
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 1.5, actor.global_position + Vector3.UP * 1.5, 1)
	if player is CollisionObject3D:
		query.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func find_nearest() -> int:
	var result: int = -1
	var best: float = INF
	for index: int in actors:
		var gap: float = surface_gap(index)
		if gap < best and can_talk(index):
			best = gap
			result = index
	return result

func _refresh_actors() -> void:
	for index: int in population.people.size():
		var center: Vector3 = to_global(CityNpcActor.home_for(index))
		# Include the complete local route so walking cannot cross the streaming edge.
		var active: bool = (dialogue.opened and index == conversation_index) or center.distance_to(player.global_position) < active_radius + 4.1
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
			if chatter != null:
				chatter.call("release_actor", str(population.people[index].id))
			actors[index].queue_free()
			actors.erase(index)
		if actors.has(index):
			# Work/rest goals describe the routine, not a command to freeze the actor.
			actors[index].walking = not (dialogue.opened and index == conversation_index) and actors[index].work_kind.is_empty()

func _update_conversations() -> void:
	for index: int in actors:
		if (dialogue.opened and index == conversation_index) or runtime < float(social_ready.get(index, 1.0)):
			continue
		var actor: CityNpcActor = actors[index]
		for other: int in actors:
			if other <= index or (dialogue.opened and other == conversation_index) or runtime < float(social_ready.get(other, 1.0)):
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
			_present(index, "greet", peer.global_position)
			_present(other, "greet", actor.global_position)
			social_ready[index] = runtime + social_cooldown
			social_ready[other] = runtime + social_cooldown
			break

func open_conversation(index: int) -> bool:
	if not can_talk(index):
		return false
	if dialogue.opened:
		_close_conversation()
	conversation_index = index
	actors[index].walking = false
	actors[index].conversing = true
	_present(index, "greet", player.global_position)
	population.meet(index, hero_id)
	if progress != null:
		progress.record_event("meet", population.people[index].id)
		if index >= 3:
			progress.record_event("resident", population.people[index].id)
	_show_conversation()
	conversation_started.emit(actors[index])
	persist()
	return true

func _job(index: int) -> String:
	return ["grocer", "tailor", "workshop"][index] if index < 3 else ""

func _show_conversation(response: String = "", topic: String = "greeting") -> void:
	_story_offer_open = false
	if conversation_index < 0:
		return
	var index: int = conversation_index
	var job: String = _job(index)
	var job_title: String = {"grocer": "Крамниця · припаси й доручення", "tailor": "Кравець · кольорові перев’язі", "workshop": "Майстерня · міські маршрути"}.get(job, str(population.people[index].role))
	current_context = conversation_context.facts(population, index, hero_id, progress, topic)
	current_fallback = conversation_context.reply(current_context, index)
	var relation: String = "друзі" if int(current_context.trust) >= 6 else ("знайомі" if int(current_context.meetings) > 1 else "знайомство")
	var text: String = str(population.people[index].name) + " — " + job_title + " · " + relation + "\n\n" + current_fallback
	if not response.is_empty():
		text += "\n\n" + response
	var options: Array[Dictionary] = []
	if story != null:
		if job == "workshop":
			var action: String = "offer" if story.stage() == "available" else ("complete" if story.stage() == "return" else "hint")
			options.append({"id": "story:" + action, "label": "Сюжет: " + story.text("title")})
		elif job in ["grocer", "tailor"]:
			options.append({"id": "story:route", "label": "Про службовий двір біля вежі"})
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
	options.append({"id": "memory", "label": "Наші знайомства"})
	options.append({"id": "topic:work", "label": "Розкажи про свою роботу"})
	options.append({"id": "topic:district", "label": "Що порадиш подивитися в районі?"})
	if progress != null and progress.quest_status("roof_walk") == "completed":
		options.append({"id": "topic:route", "label": "Поділитися враженнями від маршруту на дахах"})
	if progress != null and progress.quest_status("neighbours") == "completed":
		options.append({"id": "topic:neighbours", "label": "Поговорити про спільних знайомих"})
	dialogue.show_choices(text, options)
	if response.is_empty():
		_request_local()

func _choose(action: String) -> void:
	if conversation_index < 0 or not dialogue.opened:
		return
	if action.begins_with("story:"):
		_choose_story(action.trim_prefix("story:"))
		return
	_story_offer_open = false
	local_conversation.cancel()
	local_token = -1
	current_context = {}
	var index: int = conversation_index
	_present(index, "talk", player.global_position)
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
			_present(index, "agree", player.global_position)
			population.bond_once(index, hero_id, "quest_" + argument, "Ти допоміг: " + str(q.title) + ".", 2)
			_show_conversation("Дякую за допомогу. Нагороду додано; це доручення завершене.")
	elif action == "parcel" and job == "tailor" and progress != null and progress.quest_status("parcel") == "active":
		progress.record_event("deliver", "thread_parcel")
		_present(index, "agree", player.global_position)
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
			_present(index, "agree", player.global_position)
			_show_conversation("Перев’язь змінено. Можна вийти з розмови й оглянути героя.")
	elif action == "memory":
		dialogue.show_choices(population.dialogue(index, hero_id), [{"id": "back", "label": "Назад до розмови"}])
	elif pair[0] == "topic":
		var allowed: bool = argument in ["work", "district"] or (argument == "route" and progress != null and progress.quest_status("roof_walk") == "completed") or (argument == "neighbours" and progress != null and progress.quest_status("neighbours") == "completed")
		if allowed:
			population.bond_once(index, hero_id, "topic_" + argument, "Ми поговорили: " + {"work": "про роботу", "district": "про місця району", "route": "про пройдений верхній маршрут", "neighbours": "про спільних знайомих"}.get(argument, "про район") + ".", 2 if argument in ["route", "neighbours"] else 1)
			_show_conversation("", argument)
	else:
		_show_conversation()
	persist()

func _choose_story(action: String) -> void:
	# Revalidate a stale choice against physical contact, current hero, stage and modal owner.
	if story == null or story.hero_id != hero_id or get_tree().paused or not dialogue.opened or not InputRouter.ui_owned_only_by(dialogue) or not can_talk(conversation_index):
		return
	local_conversation.cancel()
	local_token = -1
	current_context = {}
	var job: String = _job(conversation_index)
	if action == "route" and job in ["grocer", "tailor"]:
		var key: String = "before_accept"
		if story.stage() in ["investigating", "mechanism"]:
			key = "mira_route" if job == "grocer" else "taras_route"
		elif story.stage() in ["return", "completed"]:
			key = "neighbour_" + story.stage()
		_show_conversation(story.text(key))
		return
	if job != "workshop":
		return
	if action == "offer" and story.stage() == "available":
		_story_offer_open = true
		dialogue.show_choices(story.text("title") + "\n\n" + story.text("offer"), [{"id": "story:accept", "label": story.text("accept_label")}, {"id": "back", "label": "Поки відкласти"}])
	elif action == "accept" and _story_offer_open and story.accept():
		_story_offer_open = false
		_show_conversation(story.text("accepted"))
	elif action == "complete" and story.complete():
		_present(conversation_index, "agree", player.global_position)
		_show_conversation(story.text("complete"))
	elif action == "hint" and story.stage() != "available":
		dialogue.show_fact(story.journal_text())

func _sync_story_memory() -> void:
	# Story is authoritative. Repair the independent NPC document after a partial save/reload.
	if story != null and story.save_enabled and story.save_ok and story.stage() == "completed":
		if population.bond_once(2, story.hero_id, "story_clocktower_trace", story.text("memory"), 1):
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

func _present(index: int, kind: String, listener: Vector3) -> void:
	if not actors.has(index):
		return
	actors[index].presentation_event(kind, listener)
	if index == conversation_index:
		listen_at = runtime + NpcAppearance.GESTURE_SECONDS + 0.05
	if chatter != null:
		chatter.call("speak", actors[index].global_position, int(population.people[index].appearance_seed), kind, str(population.people[index].id))

func _close_conversation() -> void:
	_story_offer_open = false
	local_conversation.cancel()
	local_token = -1
	current_context = {}
	if chatter != null:
		chatter.call("stop_all")
	if actors.has(conversation_index):
		_present(conversation_index, "goodbye", player.global_position)
		actors[conversation_index].walking = actors[conversation_index].work_kind.is_empty()
		actors[conversation_index].conversing = false
	conversation_index = -1
	conversation_ended.emit()

func _set_local_enabled(value: bool) -> void:
	local_conversation.set_enabled(value)
	dialogue.flavor.text = ""
	if value and dialogue.opened and not current_context.is_empty():
		_request_local()

func _request_local() -> void:
	if not local_conversation.enabled:
		return
	dialogue.flavor.text = "Добирає слова…"
	# Synchronous cache/failure signals use the next generation too.
	local_token = local_conversation.generation + 1
	local_conversation.generate(current_context, current_fallback)

func _local_line(token: int, line: String, status: String) -> void:
	if not dialogue.opened or token != local_token or conversation_index < 0 or current_context.get("hero", "") != hero_id or (progress != null and progress.hero_id != hero_id):
		return
	dialogue.flavor.text = line if not line.is_empty() else ("" if status == "cooldown" else "Додаткові репліки зараз недоступні.")
	if not line.is_empty():
		_present(conversation_index, "talk", player.global_position)
