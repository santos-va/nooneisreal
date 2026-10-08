class_name CityAlleyEvent
extends Node
## В1 «Там людині погано» without a fight (plan 2026-10-08-City-Events-Stage-1, step 2; T7 brief В1; ADR-025 п. 2, п. 6).
## A temporary passer-by asks for help and leads the hero into the southeast passage; a second one closes the passage
## mouth behind and the first shows a knife: «Жетони. Усі.» Exits, every one without a fight:
##   give  — min(tokens, cap_robbery) are taken, bought sashes stay;
##   talk  — Choko recognises a face he has met before; Skea says nothing and his smile widens; both send them off;
##           Choko with an unknown face is told not to talk his way out (the other exits remain);
##   run   — past them, over the roofs or by rope; the chase ends near people (or they lose track); caught = robbed;
##   sword — Choko only: the robbers flee or give up (ADR-025 п. 6, «Лякає»); one who gives up returns what he took
##           from this hero before.
## The hero remembers the face (CityProgress, per hero): next time «Я тебе пам'ятаю» stops the trap before it starts.
## Every number is a PLACEHOLDER for T5/T7.
signal finished(outcome: String)

const FACES: Dictionary = {"alley_a": 401173, "alley_b": 902211, "alley_c": 517733}
const BLOCKER_SEED := 733019
const MOUTH := Vector3(20.0, 0.0, 11.2)
const STAND := Vector3(20.0, 0.0, 25.5)       # the asker's spot in the south part of the passage
const BLOCK := Vector3(20.0, 0.0, 13.6)       # the second one, under the lintel of the north mouth
const ASKER_SPAWNS: Array[Vector3] = [Vector3(20.0, 0.0, 24.0), Vector3(20.0, 0.0, 29.0)]
const BLOCKER_HIDES: Array[Vector3] = [Vector3(26.5, 0.0, 9.0), Vector3(13.5, 0.0, 9.0)]
const BLOCKER_TURN := Vector3(20.0, 0.0, 10.4)
const SOUTH_EXIT := Vector3(20.0, 0.0, 31.0)
const NORTH_EXIT := Vector3(20.0, 0.0, 9.0)
const INSIDE := Vector3(20.0, 0.0, 21.0)

@export var cap_robbery: int = 5              # T5 § 3.3 «не більше 5»; plan: min(tokens, cap_robbery)
@export var approach_speed: float = 2.4       # PLACEHOLDER m/s, in a hurry
@export var lead_speed: float = 2.0
@export var block_speed: float = 4.0
@export var chase_speed: float = 5.0          # T5 § 3.3: slower than Choko 5.6 / Skea 6.2
@export var ask_seconds: float = 25.0         # PLACEHOLDER: an ignored call ends the event
@export var approach_seconds: float = 20.0
@export var lead_seconds: float = 40.0
@export var chase_seconds: float = 30.0       # PLACEHOLDER: they lose track (no soft-lock on a roof)
@export var leave_seconds: float = 10.0
@export var people_radius: float = 6.0        # PLACEHOLDER: «погоня закінчується біля людей»
@export var catch_radius: float = 1.1         # PLACEHOLDER metres, centre to centre on one level
@export var walk_away_distance: float = 9.0   # PLACEHOLDER: walking away from the call declines it
@export var surrender_chance: float = 0.5     # PLACEHOLDER: flee or give up when Choko draws
@export var react_seconds: float = 0.6        # PLACEHOLDER beat before they answer the sword

var id: String = "alley"
var director: Node
var asker: CityPasserby
var blocker: CityPasserby
var face_id: String = ""
var known_before: bool = false   # the hero had met this face before this event (Choko's «talk», «Я тебе пам'ятаю»)
var phase: String = ""
var phase_time: float = 0.0
var talk_tried: bool = false
var pending_outcome: String = ""
var robbed: int = 0
var refunded: int = 0
var reaction: String = ""
var _path: Array[Vector3] = []
var _blocker_path: Array[Vector3] = []
var _leave_speed: float = 2.2


func begin(owner: Node) -> void:
	director = owner
	var ids: Array = FACES.keys()
	ids.sort()
	face_id = String(ids[director.rng.randi_range(0, ids.size() - 1)])
	known_before = director.progress.face_known(face_id)
	asker = director.spawn_passerby(int(FACES[face_id]), _hidden(ASKER_SPAWNS))
	asker.name = "AlleyAsker"
	_path = [MOUTH]
	asker.walk_to(MOUTH, approach_speed)
	_set_phase("approach")


func _set_phase(next: String) -> void:
	phase = next
	phase_time = 0.0


func _player() -> CityFighter:
	return director.player


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _hidden(points: Array[Vector3]) -> Vector3:
	var best: Vector3 = points[0]
	var best_score: float = -INF
	for point: Vector3 in points:
		var score: float = _flat(point, _player().global_position) + (100.0 if director.out_of_view(point) else 0.0)
		if score > best_score:
			best_score = score
			best = point
	return best


func can_draw_sword() -> bool:
	var hero := _player()
	return hero.data.id == "choko" and hero.data.weapon_kind == "sword"


func robbery_amount() -> int:
	return mini(int(director.progress.summary().credits), cap_robbery)


func _physics_process(delta: float) -> void:
	if director == null or not is_instance_valid(asker):
		return
	phase_time += delta
	var hero := _player()
	if phase in ["trap", "told"]:
		_step(blocker, _blocker_path, block_speed)
	elif phase == "leave":
		_step(asker, _path, _leave_speed)
		_step(blocker, _blocker_path, _leave_speed)
	match phase:
		"approach":
			_tick_approach(hero)
		"ask":
			_tick_ask(hero)
		"lead":
			_tick_lead(hero)
		"chase":
			_tick_chase(hero)
		"react":
			if phase_time >= react_seconds:
				_answer_sword()
		"leave":
			_tick_leave()
	if phase != "ask":
		director.dialogue.prompt.visible = false


func _tick_approach(hero: CityFighter) -> void:
	if phase_time > approach_seconds or _flat(asker.global_position, hero.global_position) > 24.0:
		_leave("ignored")
		return
	if not _path.is_empty():
		if asker.walking():
			return
		_path.clear()
	var distance: float = _flat(asker.global_position, hero.global_position)
	if distance < 7.0 and asker.speech_left <= 0.0:
		asker.say("Допоможи! Там за рогом людині погано!", 4.0)
		asker.pose = "beckon"
	if distance <= 1.6:
		asker.stop()
		asker.face(hero.global_position)
		_set_phase("ask")
		return
	var away: Vector3 = (asker.global_position - hero.global_position)
	away.y = 0.0
	asker.walk_to(hero.global_position + away.normalized() * 1.5, approach_speed)


func _tick_ask(hero: CityFighter) -> void:
	asker.face(hero.global_position)
	if phase_time > ask_seconds or _flat(asker.global_position, hero.global_position) > walk_away_distance:
		director.dialogue.prompt.visible = false
		asker.say("Та ну тебе…", 2.0)
		_leave("ignored")
		return
	var prompt: Label = director.dialogue.prompt
	var free: bool = not InputRouter.ui_suppressed() and not get_tree().paused and director.npc_director.find_nearest() < 0
	prompt.visible = free and director.can_talk_to(asker)
	if not prompt.visible:
		return
	prompt.text = InputRouter.binding_label(1, "interact", _gamepad()) + " · Вислухати перехожого"
	if InputRouter.just_pressed(1, "interact"):
		prompt.visible = false
		open_ask()


func _gamepad() -> bool:
	var camera: Camera3D = director.camera
	return camera != null and camera.has_meta("harpoon_aim") and camera.get_meta("harpoon_aim").last_gamepad


func open_ask() -> void:
	var options: Array[Dictionary] = [{"id": "follow", "label": "Піти за ним"}]
	if known_before:
		options.append({"id": "remember", "label": "Я тебе пам'ятаю"})
	options.append({"id": "decline", "label": "Не зараз"})
	director.show_choices("Перехожий, захеканий:\n«Допоможи, там за рогом людині погано! Швидше!»", options, asker)


func open_trap(text: String = "") -> void:
	var amount: int = robbery_amount()
	var options: Array[Dictionary] = [{"id": "give", "label": "Віддати · %d жет." % amount}]
	if not talk_tried:
		options.append({"id": "talk", "label": "Говорити"})
	options.append({"id": "run", "label": "Тікати"})
	if can_draw_sword():
		options.append({"id": "sword", "label": "Вийняти меч"})
	if text.is_empty():
		text = "Позаду хтось став у прохід. Прохач дістає ніж:\n«Жетони. Усі.»"
	director.show_choices(text, options, asker)


func choose(action: String) -> void:
	var hero := _player()
	if phase == "ask":
		if action == "follow":
			_set_phase("lead")
			director.dialogue.close()
			asker.pose = ""
			asker.say("Сюди, сюди!", 2.0)
			_path.clear()
			if not CityEventDirector.inside_passage(asker.global_position):
				_path.append(MOUTH)
			_path.append(STAND)
			asker.walk_to(_path[0], lead_speed)
			blocker = director.spawn_passerby(BLOCKER_SEED, _hidden(BLOCKER_HIDES))
			blocker.name = "AlleyBlocker"
		elif action == "remember" and known_before:
			_tell("Ти дивишся йому просто в обличчя: «Я тебе пам'ятаю».\nПрохач відводить очі: «Обізнався, мабуть…» — і йде геть.", "remembered")
		elif action == "decline":
			_set_phase("told")
			pending_outcome = "declined"
			director.dialogue.close()
		return
	if phase != "trap":
		return
	if action == "give":
		robbed = director.progress.spend_credits(robbery_amount())
		director.progress.remember_face(face_id, robbed)
		_tell("Він забирає %d жет.: «Розумник». Обидва йдуть геть.\nКуплені перев'язі лишаються твоїми." % robbed, "gave")
	elif action == "talk" and not talk_tried:
		talk_tried = true
		if hero.data.id == "skea":
			_tell("Skea мовчить. Посмішка ширшає — ширше, ніж уміє людське обличчя.\nГрабіжники переглядаються й задкують.", "smile")
		elif known_before:
			_tell("«Ти ж той самий, що кликав мене минулого разу». Choko дивиться йому просто в очі.\nПрохач ховає ніж: «Ходімо звідси».", "recognized")
		else:
			open_trap("«Не заговорюй мені зуби. Жетони».")
	elif action == "run":
		_start_chase()
	elif action == "sword" and can_draw_sword():
		_set_phase("react")
		director.dialogue.close()
		hero.draw_sword_for_event()


func dialogue_closed() -> void:
	match phase:
		"ask":
			_set_phase("told")
			pending_outcome = "declined"
			_after_told()
		"trap":
			_start_chase()   # Esc / B in the trap means running
		"told":
			_after_told()


func _tell(text: String, outcome: String) -> void:
	pending_outcome = outcome
	_set_phase("told")
	director.dialogue.show_fact(text)


func _after_told() -> void:
	if pending_outcome == "declined":
		asker.say("Та ну тебе…", 2.0)
	_leave(pending_outcome)


func _tick_lead(hero: CityFighter) -> void:
	var distance: float = _flat(asker.global_position, hero.global_position)
	if phase_time > lead_seconds or distance > 22.0:
		_leave("lost")
		return
	# The asker waits for a hero who lags behind and goes on when he catches up.
	if not asker.walking() and not _path.is_empty() and _flat(asker.global_position, _path[0]) <= 0.05:
		_path.pop_front()
	if not _path.is_empty():
		var goal: Vector3 = _path.back()
		if distance > 7.0 and _flat(hero.global_position, goal) > _flat(asker.global_position, goal):
			asker.stop()
			asker.face(hero.global_position)
		elif not asker.walking():
			asker.walk_to(_path[0], lead_speed)
	var hero_in: bool = CityEventDirector.inside_passage(hero.global_position) and hero.on_ground()
	var deep: bool = _path.is_empty()
	var behind: bool = asker.global_position.z > hero.global_position.z
	if hero_in and ((behind and hero.global_position.z >= 17.0 and distance <= 6.0) or (deep and hero.global_position.z >= 14.5)):
		_spring_trap(hero)


func _spring_trap(hero: CityFighter) -> void:
	_set_phase("trap")
	asker.stop()
	asker.face(hero.global_position)
	asker.pose = "threat"
	asker.show_knife(true)
	asker.say("Жетони. Усі.", 3.0)
	director.progress.remember_face(face_id, 0)
	if is_instance_valid(blocker):
		_blocker_path = [BLOCKER_TURN, BLOCK]
	open_trap()


## One leg after another: a passer-by that arrived takes the next point of its path.
func _step(person: CityPasserby, path: Array[Vector3], speed: float) -> void:
	if not is_instance_valid(person) or person.walking() or path.is_empty():
		return
	if _flat(person.global_position, path[0]) <= 0.05:
		path.pop_front()
	if not path.is_empty():
		person.walk_to(path[0], speed)
	elif phase in ["trap", "told"]:
		person.face(_player().global_position)


func _start_chase() -> void:
	_set_phase("chase")
	if director.dialogue.opened:
		director.dialogue.close()
	asker.say("Стій!", 1.5)


func _tick_chase(hero: CityFighter) -> void:
	if phase_time > chase_seconds:
		_leave("lost_track")
		return
	if director.residents_near(hero.global_position, people_radius) > 0:
		for robber: CityPasserby in _robbers():
			robber.stop()
			robber.face(hero.global_position)
		asker.say("Тьху…", 2.0)
		_leave("escaped")
		return
	if phase_time < 0.4:
		return
	for robber: CityPasserby in _robbers():
		var gap: float = _flat(robber.global_position, hero.global_position)
		if gap <= catch_radius and absf(robber.global_position.y - hero.global_position.y) < 0.8:
			robbed = director.progress.spend_credits(robbery_amount())
			director.progress.remember_face(face_id, robbed)
			for each: CityPasserby in _robbers():
				each.stop()
			_tell("Тебе наздогнали й притисли до стіни. Забирають %d жет. і йдуть геть." % robbed, "caught")
			return
		robber.walk_to(hero.global_position, chase_speed)


func _answer_sword() -> void:
	var surrender: bool = director.rng.randf() < surrender_chance
	asker.show_knife(false)
	if surrender:
		reaction = "surrender"
		for robber: CityPasserby in _robbers():
			robber.stop()
			robber.pose = "surrender"
		refunded = director.progress.refund_face(face_id)
		asker.say("Добре, добре! Ми йдемо.", 2.5)
		var text := "Choko виймає меч. Прохач кидає ніж і підіймає руки: «Добре, добре! Ми йдемо»."
		if refunded > 0:
			text += "\nВін тремтячими руками повертає забране минулого разу: +%d жет." % refunded
		_tell(text, "surrendered")
	else:
		reaction = "flee"
		asker.say("Тікаймо!", 1.5)
		_leave("fled", chase_speed)


func _robbers() -> Array[CityPasserby]:
	var result: Array[CityPasserby] = []
	for robber: CityPasserby in [asker, blocker]:
		if is_instance_valid(robber):
			result.append(robber)
	return result


func _leave(outcome: String, speed: float = 2.2) -> void:
	pending_outcome = outcome
	_set_phase("leave")
	_leave_speed = speed
	director.dialogue.prompt.visible = false
	var hero := _player()
	for robber: CityPasserby in _robbers():
		if outcome != "surrendered":
			robber.pose = ""
		var path: Array[Vector3] = _exit_path(robber, hero)
		if robber == asker:
			_path = path
		else:
			_blocker_path = path
		robber.walk_to(path[0], speed)


## Out of the hero's way: inside the passage by the end on the robber's own side (never past the hero); outside it
## back through the mouth into the passage, or away down the street when the passage is behind the hero.
func _exit_path(robber: CityPasserby, hero: CityFighter) -> Array[Vector3]:
	var at: Vector3 = robber.global_position
	var path: Array[Vector3] = []
	if CityEventDirector.inside_passage(at):
		path.append(SOUTH_EXIT if at.z >= hero.global_position.z else NORTH_EXIT)
	elif director.clear_line(at, MOUTH) and _flat(MOUTH, hero.global_position) >= _flat(MOUTH, at) - 0.5:
		path.append(MOUTH)
		path.append(INSIDE)
	else:
		var away := Vector3(at.x - hero.global_position.x, 0.0, at.z - hero.global_position.z)
		away = away.normalized() if away.length() > 0.01 else Vector3.BACK
		path.append(at + away * 12.0)
	return path


func _tick_leave() -> void:
	var gone: bool = true
	for robber: CityPasserby in _robbers():
		if robber.pose == "surrender" and phase_time > 1.2:
			robber.pose = ""
		if robber.walking() and not robber.blocked:
			gone = false
	if gone or phase_time >= leave_seconds:
		_finish(pending_outcome)


func abort(reason: String) -> void:
	_finish("abort_" + reason)


func _finish(outcome: String) -> void:
	if phase == "done":
		return
	_set_phase("done")
	for robber: CityPasserby in _robbers():
		robber.queue_free()
	finished.emit(outcome)
