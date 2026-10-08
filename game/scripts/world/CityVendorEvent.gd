class_name CityVendorEvent
extends Node
## The street pedlar (plan 2026-10-08-Thirst-Substances-Icons step 2): T7's «Кухоль» stall (Л3) is not in the game, so
## alcohol and tobacco are sold by a temporary passer-by the director brings, as В2 brings the leaves (T5 Substances § 3.6:
## «пропозиція перехожого в межах того самого ліміту В2» — he and the leaves share one offer a session). A dark beer
## («Хміль») or a single cigarette («Задишка»), one token each (T7 § 4.4–4.5), «Ні, дякую» changes nothing (М2). He does
## not sell alcohol to a hungry or thirsty hero (T7 Ш6, T5 Thirst § 7: H or W ≤ 50) and never while a state lasts (М6: the
## director does not even bring him). The `drugs` key Off: he never comes, and leaves at once mid-offer. Words and prices
## are PLACEHOLDERs for T7/T5; the consequence words on the buttons are T8 п. 3's pattern.
signal finished(outcome: String)

const SEED := 731905
const OFFERS := {
	"beer": {"title": "Темне з бочки", "state": "tipsy", "price": 1, "after": "TIPSY 2:00 · ноги важчі, без кроків по стіні", "icon": "dark_beer",
		"told": "Кухоль темного з бочки — гірке, густе, шапка швидко сідає. Ноги стають важчими."},
	"cigarette": {"title": "Гільза", "state": "winded", "price": 1, "after": "WINDED 1:00 · дихання збивається, ухил відновлюється повільніше", "icon": "cigarette",
		"told": "Сірий папір, дешевий тютюн. Дим дере горло, дихання збивається."},
}
const REFUSED := "Він знизує плечима: «Як знаєш. Вода — біля колонки, задарма»."

@export var approach_speed: float = 1.3        # PLACEHOLDER m/s, as the leaves' passer-by
@export var approach_seconds: float = 25.0
@export var offer_seconds: float = 25.0        # PLACEHOLDER: an ignored offer ends the event
@export var walk_away_distance: float = 9.0
@export var leave_seconds: float = 8.0
@export var spawn_distance: float = 9.0
@export var sober_at: int = 5000               # T7 Ш6 / T5 Thirst § 7: no alcohol at H ≤ 50 or W ≤ 50

var id: String = "vendor"
var director: Node
var person: CityPasserby
var phase: String = ""
var phase_time: float = 0.0
var pending_outcome: String = ""


func begin(owner: Node) -> void:
	director = owner
	person = director.spawn_passerby(SEED, _spawn_point())
	person.name = "VendorPasserby"
	_set_phase("approach")


func _set_phase(next: String) -> void:
	phase = next
	phase_time = 0.0


func _hero() -> CityFighter:
	return director.player


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


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
				person.say("Темне з бочки, гільзи поштучно. По жетону.", 4.0)
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


## Why `offer` cannot be had now ("" when it can): tokens, then (alcohol only) hunger and thirst.
func offer_reason(offer: String) -> String:
	var spec: Dictionary = OFFERS[offer]
	var tokens: int = director.progress.credits() if director.progress != null else 0
	if tokens < int(spec.price):
		return "бракує %d жет." % (int(spec.price) - tokens)
	if spec.state == "tipsy":
		var hunger: CityHunger = director.world.get("hunger")
		if hunger != null and hunger.centi <= sober_at:
			return "спершу поїж"
		var thirst: CityThirst = director.world.get("thirst")
		if thirst != null and thirst.running and thirst.centi <= sober_at:
			return "спершу вода"
	return ""


## The button text: name, the price in the body (T8 п. 3), the price in tokens, the reason when it cannot be had.
static func offer_label(offer: String, reason: String) -> String:
	var spec: Dictionary = OFFERS[offer]
	return "%s · %s · %d жет." % [spec.title, spec.after, int(spec.price)] + ((" · " + reason) if not reason.is_empty() else "")


func open_offer(text: String = "") -> void:
	_set_phase("talk")
	var options: Array[Dictionary] = []
	for offer: String in ["beer", "cigarette"]:
		var reason: String = offer_reason(offer)
		options.append({"id": offer, "label": offer_label(offer, reason), "enabled": reason.is_empty(), "icon": String(OFFERS[offer].icon)})
	options.append({"id": "refuse", "label": "Ні, дякую"})
	options.append({"id": "leave", "label": "Піти"})
	if text.is_empty():
		text = "Перехожий тримає кошик під полою: кухоль темного з бочки й кілька гільз.\n«По жетону. Вода — біля колонки, задарма»."
	director.show_choices(text, options, person)


func choose(action: String) -> void:
	if phase != "talk":
		return
	match action:
		"beer", "cigarette":
			if not offer_reason(action).is_empty() or not director.drugs_allowed():
				return
			var substances: CitySubstances = director.world.get("substances")
			if substances == null or substances.any_state() or not director.progress.buy_food(int(OFFERS[action].price)):
				return
			substances.begin(String(OFFERS[action].state))
			person.pose = ""
			_tell(String(OFFERS[action].told), "bought_" + action)
		"refuse":
			person.pose = "shrug"
			_tell(REFUSED, "refused")
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
		target = person.global_position + Vector3(away.z, 0.0, -away.x) * 10.0
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
