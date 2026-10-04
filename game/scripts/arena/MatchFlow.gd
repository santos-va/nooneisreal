class_name MatchFlow
extends Node
## Round / match state: intro → fight → round end → next round or match end. Best of 3 by default.

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
	GameState.last_result = {}
	# Clear match-owned objects before fighters reset; rounds never emit this signal.
	match_started.emit()
	_start_round()


func _start_round() -> void:
	round_no += 1
	time_left = float(GameState.round_seconds)
	_last_timer = int(time_left)
	phase = Phase.INTRO
	_phase_frames = 0
	p1.reset_for_round(-3.0, 1)
	p2.reset_for_round(3.0, -1)
	Engine.time_scale = 1.0
	round_started.emit(round_no)
	announce.emit("ROUND %d" % round_no, 1.1)
	timer_changed.emit(int(time_left))
	phase_changed.emit(int(phase))
	Sfx.play("round_start")


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
			if not GameState.training_mode:   # fatigue: only while a real round runs (02 § Втома (б))
				p1.tick_fatigue()
				p2.tick_fatigue()
			if GameState.training_mode:
				if p2.hp < p2.data.max_hp * 0.4 and p2.is_actionable():
					p2.heal_full()
				if p1.hp < p1.data.max_hp * 0.4 and p1.is_actionable():
					p1.heal_full()
			else:
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
				if wins[1] >= GameState.rounds_to_win or wins[2] >= GameState.rounds_to_win:
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
	GameState.last_result = {"winner": w, "rounds": round_no, "p1": p1.data.display_name, "p2": p2.data.display_name, "wins_p1": wins[1], "wins_p2": wins[2]}
	announce.emit("%s WINS" % winner_name, 4.0)
	match_over.emit(w, p1.data.display_name, p2.data.display_name)
	phase_changed.emit(int(phase))


func rematch() -> void:
	_begin_match()
