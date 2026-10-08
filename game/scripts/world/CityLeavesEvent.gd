class_name CityLeavesEvent
extends Node
## В2 «П'ять листків» (plan 2026-10-08-City-Events-Stage-1, step 3; T7 brief В2; ADR-025 п. 5): a relaxed passer-by
## with five flat leaves circling over his head offers a drag. Choices: «Ні, дякую» (he shrugs, tells a piece of city
## gossip; nothing changes), «Затягнутись» (the «Заплутаність» state, CityHaze; no bonus of any kind), «Хто ти?» (a short
## human story) and «Піти». He offers, he does not sell: tokens never change. The director starts it only while the
## `drugs` content key allows it and Off removes it at once. Every number is a PLACEHOLDER for T5/T7.
signal finished(outcome: String)

const SEED := 286411
const GOSSIP := "Кажуть, біля годинникової вежі знову бачили, як ліхтар сам гасне. Лада ходила дивитись. Нічого не знайшла. Каже, вітер."
const STORY := "Та так… Ми з другом тут колись сиділи щовечора. Він давно не приходить. Сиджу за двох."

@export var approach_speed: float = 1.3        # PLACEHOLDER m/s, unhurried
@export var approach_seconds: float = 25.0
@export var offer_seconds: float = 25.0        # PLACEHOLDER: an ignored offer ends the event
@export var walk_away_distance: float = 9.0
@export var leave_seconds: float = 8.0
@export var spawn_distance: float = 9.0        # PLACEHOLDER metres from the hero, out of view when possible

var id: String = "leaves"
var director: Node
var person: CityPasserby
var phase: String = ""
var phase_time: float = 0.0
var asked: bool = false
var pending_outcome: String = ""
var haze_started: bool = false


func begin(owner: Node) -> void:
	director = owner
	person = director.spawn_passerby(SEED, _spawn_point())
	person.name = "LeavesPasserby"
	person.show_leaves(true)
	_set_phase("approach")


func _set_phase(next: String) -> void:
	phase = next
	phase_time = 0.0


func _hero() -> CityFighter:
	return director.player


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Eight directions around the hero on his level with a clear line to him; the first out of view wins, the farthest
## clear one otherwise.
func _spawn_point() -> Vector3:
	var hero: Vector3 = _hero().global_position
	var fallback: Vector3 = hero + Vector3(0, 0, spawn_distance * 0.5)
	var fallback_ok: bool = false
	for step: int in 8:
		var angle: float = TAU * float(step) / 8.0
		var point: Vector3 = hero + Vector3(sin(angle), 0.0, cos(angle)) * spawn_distance
		if not director.clear_line(hero, point) or not _floor_near(point, hero.y):
			continue
		if director.out_of_view(point):
			return point
		if not fallback_ok:
			fallback = point
			fallback_ok = true
	return fallback


func _floor_near(point: Vector3, level: float) -> bool:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.6, point + Vector3.DOWN * 1.0, 1)
	var hit: Dictionary = director.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and absf(float(hit.position.y) - level) < 0.3


func _physics_process(delta: float) -> void:
	if director == null or not is_instance_valid(person):
		return
	phase_time += delta
	var hero := _hero()
	match phase:
		"approach":
			var distance: float = _flat(person.global_position, hero.global_position)
			if phase_time > approach_seconds or distance > 24.0:
				_leave("ignored")
			elif distance <= 1.7:
				person.stop()
				person.face(hero.global_position)
				person.pose = "offer"
				person.say("Гей. Затягнешся? Нікуди не поспішаю.", 4.0)
				_set_phase("offer")
			else:
				var away: Vector3 = person.global_position - hero.global_position
				away.y = 0.0
				person.walk_to(hero.global_position + away.normalized() * 1.6, approach_speed)
		"offer":
			_tick_offer(hero)
		"leave":
			if not person.walking() or person.blocked or phase_time >= leave_seconds:
				_finish(pending_outcome)
	if phase != "offer":
		director.dialogue.prompt.visible = false


func _tick_offer(hero: CityFighter) -> void:
	person.face(hero.global_position)
	if phase_time > offer_seconds or _flat(person.global_position, hero.global_position) > walk_away_distance:
		person.pose = "shrug"
		_leave("ignored")
		return
	var prompt: Label = director.dialogue.prompt
	prompt.visible = not InputRouter.ui_suppressed() and not get_tree().paused and director.npc_director.find_nearest() < 0 and director.can_talk_to(person)
	if not prompt.visible:
		return
	var gamepad: bool = director.camera != null and director.camera.has_meta("harpoon_aim") and director.camera.get_meta("harpoon_aim").last_gamepad
	prompt.text = InputRouter.binding_label(1, "interact", gamepad) + " · Поговорити з перехожим"
	if InputRouter.just_pressed(1, "interact"):
		prompt.visible = false
		open_offer()


func open_offer(text: String = "") -> void:
	_set_phase("talk")
	var options: Array[Dictionary] = [{"id": "refuse", "label": "Ні, дякую"}, {"id": "smoke", "label": "Затягнутись"}]
	if not asked:
		options.append({"id": "ask", "label": "Хто ти?"})
	options.append({"id": "leave", "label": "Піти"})
	if text.is_empty():
		text = "Над головою в перехожого повільно кружляють п'ять листків. Він простягає самокрутку:\n«Затягнешся? Нікуди не поспішаю»."
	director.show_choices(text, options, person)


func choose(action: String) -> void:
	if phase != "talk":
		return
	match action:
		"refuse":
			person.pose = "shrug"
			_tell("Він знизує плечима, без докору: «Як знаєш».\n«" + GOSSIP + "»", "refused")
		"smoke":
			haze_started = director.haze != null and director.haze.begin()
			person.pose = ""
			# The gossip heard in the state is half gone already (T7 В2: one can only ask again later).
			var gossip: String = director.haze.fade_line(GOSSIP, 0) if director.haze != null else GOSSIP
			_tell("Дим дере горло. Кольори пливуть, звуки відходять кудись далеко.\nВін щось розповідає: «" + gossip + "»", "smoked")
		"ask":
			asked = true
			open_offer("«" + STORY + "»")
		"leave":
			pending_outcome = "left"
			_set_phase("told")
			director.dialogue.close()


func _tell(text: String, outcome: String) -> void:
	pending_outcome = outcome
	_set_phase("told")
	director.dialogue.show_fact(text)


func dialogue_closed() -> void:
	if phase == "talk":
		pending_outcome = "left"
	if phase in ["talk", "told"]:
		_leave(pending_outcome)


func _leave(outcome: String) -> void:
	pending_outcome = outcome
	_set_phase("leave")
	director.dialogue.prompt.visible = false
	var hero := _hero()
	var away: Vector3 = person.global_position - hero.global_position
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	var target: Vector3 = person.global_position + away * 10.0
	if not director.clear_line(person.global_position, target):
		target = person.global_position + Vector3(away.z, 0.0, -away.x) * 10.0   # along the street instead
	person.walk_to(target, approach_speed)


func abort(reason: String) -> void:
	_finish("abort_" + reason)


func _finish(outcome: String) -> void:
	if phase == "done":
		return
	_set_phase("done")
	if is_instance_valid(person):
		person.queue_free()
	finished.emit(outcome)
