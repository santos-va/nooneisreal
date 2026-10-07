class_name MatchFlow
extends Node
## Round / match state: intro → fight → round end → next round or match end. Best of 3 by default.
## `lethal` belongs to the fight, not to a fighter (ADR-024, docs/GDD/02-Combat-System.md § Смертельний бій):
## a sparring duel (arena, VERSUS, training) keeps `lethal = false` and every rule below it as before. A lethal
## fight is best-of-3 without a clock or training heal, and between rounds HP carries over with a partial recovery.
## Its decisive KO is the same `_die` + slow-mo; the owner (CityLethalFight) then removes the dead enemy instead of a
## rematch. Convention for a lethal fight: p1 is the hero, p2 the enemy.

signal phase_changed(phase: int)
signal match_started
signal round_started(round_no: int)
signal announce(text: String, seconds: float)
signal timer_changed(seconds_left: int)
signal round_won(player: int, wins_p1: int, wins_p2: int)
signal match_over(winner: int, p1_name: String, p2_name: String)

enum Phase { INTRO, FIGHT, ROUND_END, MATCH_END }

var phase: Phase = Phase.INTRO
var round_no: int = 0
var wins: Dictionary = {1: 0, 2: 0}
var time_left: float = 99.0
var p1: Fighter
var p2: Fighter
var _phase_frames: int = 0
var _last_timer: int = -1
## Set by the fight's owner before setup(); never by the arena.
var lethal: bool = false
## `k` of the HP carry between lethal rounds: hp_next = hp_end + k · (max_hp − hp_end), the same for both sides,
## no RNG. PLACEHOLDER 0.35 — T5 Арес, docs/GDD/02-Combat-System.md § Перенос HP між раундами — k.
const LETHAL_HP_CARRY_K := 0.35


func setup(a: Fighter, b: Fighter) -> void:
	p1 = a
	p2 = b
	p1.knocked_out.connect(_on_ko)
	p2.knocked_out.connect(_on_ko)
	_begin_match()


func _begin_match() -> void:
	p1.fatigue = 0.0
	p2.fatigue = 0.0
	wins = {1: 0, 2: 0}
	round_no = 0
	if not lethal:   # the arena's result snapshot; a city fight never writes it
		GameState.last_result = {}
	# Clear match-owned objects before fighters reset; rounds never emit this signal.
	match_started.emit()
	_start_round()


func _start_round() -> void:
	# A lethal fight carries wounds into the next round; a new match (round_no 0) starts at full HP.
	var carry := lethal and round_no > 0
	var hp_end := [p1.hp, p2.hp]
	round_no += 1
	time_left = float(GameState.round_seconds)
	_last_timer = int(time_left)
	phase = Phase.INTRO
	_phase_frames = 0
	p1.reset_for_round(-3.0, 1)
	p2.reset_for_round(3.0, -1)
	if carry:
		p1.set_round_hp(carried_hp(hp_end[0], p1.data.max_hp))
		p2.set_round_hp(carried_hp(hp_end[1], p2.data.max_hp))
	Engine.time_scale = 1.0
	round_started.emit(round_no)
	announce.emit(round_title() if lethal else "ROUND %d" % round_no, 1.1)
	if not lethal:
		timer_changed.emit(int(time_left))
	phase_changed.emit(int(phase))
	Sfx.play("round_start")


## HP a fighter starts the next lethal round with. The loser's KO counts as 0 (hp may be below 0 after the blow).
static func carried_hp(hp_end: float, max_hp: float) -> float:
	var left := clampf(hp_end, 0.0, max_hp)
	return left + LETHAL_HP_CARRY_K * (max_hp - left)


## The HUD's frame line (06-UI-UX, HUD H2 of plan step 4): a lethal round versus a sparring match.
func round_title() -> String:
	if lethal:
		return "ROUND %d — TO THE DEATH" % maxi(round_no, 1)
	return "SPARRING · FIRST TO %d" % GameState.rounds_to_win


## The decisive KO: the winner of the round that just ended has reached rounds_to_win.
func decisive() -> bool:
	return wins[1] >= GameState.rounds_to_win or wins[2] >= GameState.rounds_to_win


func reset_positions() -> void:
	if phase != Phase.FIGHT:
		return
	p1.reset_for_round(-3.0, 1)
	p2.reset_for_round(3.0, -1)
	p1.set_control(true)
	p2.set_control(true)


func _physics_process(delta: float) -> void:
	_phase_frames += 1
	match phase:
		Phase.INTRO:
			if _phase_frames == 66:
				announce.emit("FIGHT!", 0.7)
			if _phase_frames >= 84:
				phase = Phase.FIGHT
				p1.set_control(true)
				p2.set_control(true)
				phase_changed.emit(int(phase))
		Phase.FIGHT:
			var training := GameState.training_mode and not lethal   # a lethal fight is never training
			if not training:   # fatigue: only while a real round runs (02 § Втома (б))
				p1.tick_fatigue()
				p2.tick_fatigue()
			if training:
				if p2.hp < p2.data.max_hp * 0.4 and p2.is_actionable():
					p2.heal_full()
				if p1.hp < p1.data.max_hp * 0.4 and p1.is_actionable():
					p1.heal_full()
			elif not lethal:   # a lethal round has no clock and no TIME UP (02 § Смертельний бій)
				time_left -= delta
				var t := ceili(time_left)
				if t != _last_timer:
					_last_timer = t
					timer_changed.emit(maxi(t, 0))
				if time_left <= 0.0:
					_time_over()
		Phase.ROUND_END:
			if _phase_frames == 30:
				Engine.time_scale = 1.0
			if _phase_frames >= 140:
				if decisive():
					_match_end()
				else:
					_start_round()
		Phase.MATCH_END:
			pass


func _on_ko(f: Fighter) -> void:
	if phase != Phase.FIGHT:
		return
	var winner := 2 if f.player_index == 1 else 1
	_end_round(winner, "K.O.")


func _time_over() -> void:
	var winner := 1 if p1.hp >= p2.hp else 2
	_end_round(winner, "TIME UP")


func _end_round(winner: int, text: String) -> void:
	phase = Phase.ROUND_END
	_phase_frames = 0
	wins[winner] += 1
	p1.set_control(false)
	p2.set_control(false)
	Engine.time_scale = 0.4   # short cinematic slow-mo; restored after 30 frames
	announce.emit(text, 1.6)
	round_won.emit(winner, wins[1], wins[2])
	phase_changed.emit(int(phase))


func _match_end() -> void:
	phase = Phase.MATCH_END
	_phase_frames = 0
	var w := 1 if wins[1] > wins[2] else 2
	var winner_name: String = p1.data.display_name if w == 1 else p2.data.display_name
	if lethal:
		# No reset after the decisive KO: the dead enemy stays down; a fallen hero gets the defeat screen.
		announce.emit("%s FALLS" % p2.data.display_name if w == 1 else "DEFEATED", 4.0)
	else:
		GameState.last_result = {"winner": w, "rounds": round_no, "p1": p1.data.display_name, "p2": p2.data.display_name, "wins_p1": wins[1], "wins_p2": wins[2]}
		announce.emit("%s WINS" % winner_name, 4.0)
	match_over.emit(w, p1.data.display_name, p2.data.display_name)
	phase_changed.emit(int(phase))


func rematch() -> void:
	_begin_match()
