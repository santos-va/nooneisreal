class_name Fighter
extends CharacterBody3D
## One fighter: deterministic state machine (60 Hz physics), movement, attacks, hit reception,
## status effects (freeze, armor break, bleed/poison, veil, speed), signature movement (dash or
## Skea's flash-step), skill effects, grapple and ragdoll hand-off. Visuals are derived by RigAnimator.
## Physics never decides a hit (docs/GDD/02-Combat-System.md).

signal hp_changed(hp: float, max_hp: float)
signal meter_changed(meter: float, max_meter: float)
signal state_changed(new_state: int)
signal hit_landed(attacker: Fighter, victim: Fighter, move: MoveData, blocked: bool)
signal knocked_out(fighter: Fighter)
signal grapple_changed(charges: int, cooldown_left: float, max_charges: int)
signal cooldowns_changed(cooldowns: Dictionary)
signal move_started(fighter: Fighter, move: MoveData)
signal dash_changed(charges: int, recharge_left: float, max_charges: int)
signal status_changed(text: String)

enum State { INTRO, IDLE, WALK, CROUCH, JUMP, DASH, ATTACK, BLOCK, HITSTUN, BLOCKSTUN, LAUNCHED, KNOCKDOWN, GETUP, GRAPPLE, KO, STUMBLE, WALL_SPLAT, SWAP }

## T5, Choko stance/sword plan: PLACEHOLDER physics frames, explicit commit point.
const SWORD_SWAP_FRAMES := 24
const SWORD_SWAP_CONTACT := 12
var sword_hand: String = "right"
var sword_swap_from: String = "right"
var sword_swap_to: String = "right"
var sword_swap_frame: int = 0
var attack_sword_hand: String = "right"

const GRAVITY := 24.0
const ARENA_HALF_WIDTH := 12.5
const MIN_SEPARATION := 0.95
const KNOCKDOWN_FRAMES := 40
const GETUP_FRAMES := 18
## Fatigue (docs/GDD/02-Combat-System.md § Втома, В-1, all PLACEHOLDER): the body only, never input. The effect starts at
## FATIGUE_ON and grows linearly to the caps below at fatigue 1.0. Startup, active, damage, hitstun, blockstun — unchanged.
const FATIGUE_ON := 0.3
const FATIGUE_GETUP := 0.5        # get-up × 1.5 → 27 frames
const FATIGUE_WALK := 0.1         # walk / run speed × 0.9
const FATIGUE_DASH := 0.25        # dash / Flash Step recharge × 1.25
const FATIGUE_GRAPPLE := 0.2      # grapple recharge × 1.2
const FATIGUE_RECOVERY := 2       # own attacks' recovery + 2 frames at most (rounded down)
## Seconds of fight time each own action is worth (02 § Втома (б)); hits taken add nothing.
const FATIGUE_DASH_S := 1.5
const FATIGUE_GRAPPLE_S := 2.0
const FATIGUE_SKILL_S := 1.0
## Stance from this fatigue on: the tired idle (02 § Втома (г)).
const FATIGUE_TIRED := 0.5
const MAX_METER := 100.0
const COMBO_SCALING := 0.1
const HIT_FRICTION := 30.0
# status tuning (PLACEHOLDER — T5 Арес, docs/GDD/08-Balance.md)
const FLASH_TRAVEL := 4
const FLASH_RECOVER := 7
const FLASH_IFRAMES := 7
const CRIT_MULT := 1.5
const FREEZE_DAMAGE := 0.7
const ARMOR_BREAK_FRAMES := 240
const BLEED_FRAMES := 180
const BLEED_DMG := 4.0
const POISON_FRAMES := 150
const POISON_DMG := 6.0
const DOT_EVERY := 20
const VEIL_FRAMES := 210
const CRIT_SPEED_FRAMES := 90
const SPEED_MULT := 1.3
const MARK_INTERVAL := 150
const MAX_MARKS := 2
const REWIND_HEAL_CAP := 0.15
const TIME_STOP_FRAMES := 72
## Wall splat (free movement): a ragdoll that reaches the arena edge sticks to the wall, then falls.
const WALL_SPLAT_FRAMES := 10     # `wall_splat_frames`, ДИЗАЙН (T5 Арес, docs/GDD/02 § Коло арени): no damage, once per combo
const WATER_GETUP_EXTRA := 6      # Stage-River: getting up out of the water is slower (PLACEHOLDER)
# free movement, GameState.free_move — numbers: T5 Арес, docs/GDD/02-Combat-System.md § Вільний 3D-рух
# (per-fighter ones live in CharacterData: block_arc_deg, circle_speed_mult, grapple_cone_deg)
const ARENA_RADIUS := 20.0        # `arena_radius`, ДИЗАЙН, PLACEHOLDER (Арес 2026-10-03, Р4; ≠ ARENA_HALF_WIDTH since then)
const FLASH_INPUT_LOCK := 6       # input stays in the pre-flash camera frame for the flash + 6 frames
const MIN_LINE := 0.05            # below this the direction to the opponent is undefined: keep the last
const FLASH_SIDE_DEG := 45.0      # Flash Step exit turned by a sideways stick (ДИЗАЙН, T5 Арес, docs/GDD/03 § Як у 3D)

@export var player_index: int = 1
@export var data: CharacterData
@export var is_cpu: bool = false

var state: State = State.INTRO
var facing: int = 1               # plane: ±1 along X. free_move: derived from `forward` (screen side)
## Where the fighter looks, unit vector on the ground plane. Plane mode: always (facing, 0, 0).
var forward: Vector3 = Vector3.RIGHT
var hp: float = 1000.0
var meter: float = 0.0
var opponent: Fighter
var frame_in_state: int = 0
var hitstop_frames: int = 0
var stun_frames: int = 0
var current_move: MoveData
var current_slot: String = ""
var move_frame: int = 0
var has_hit: bool = false
var combo_count: int = 0
var chain_index: int = 0
var cooldowns: Dictionary = {"skill1": 0.0, "skill2": 0.0}
var control_locked: bool = true
var invulnerable_frames: int = 0
var crouching: bool = false
var dash_dir: int = 1
var dash_frames_left: int = 0
var airborne_attack: bool = false
var stats: Dictionary = {"hits": 0, "blocks": 0, "grapples": 0, "ragdolls": 0, "crits": 0, "flashes": 0}

# status effects
var frozen_frames: int = 0
var armor_break_frames: int = 0
var dot_frames: int = 0
var dot_damage: float = 0.0
var veil_frames: int = 0
var veil_strike: bool = false
var speed_buff_frames: int = 0
var weak_marks: Dictionary = {}
var last_hit_crit: bool = false
var record_marker: RecordMarker = null
var dash_charges_left: int = 0
var dash_recharge_left: float = 0.0
## The full recharge the current dash wait started from (fatigue stretches it); the HUD fills against it.
var dash_recharge_total: float = 0.0
## 0…1 for the whole match; rounds do not reset it (02 § Втома (а)). MatchFlow adds the fight time, actions add the rest.
var fatigue: float = 0.0
## Body weight (CharacterData.ground_accel …): frames left of a jump's landing (no new action), and the visual squash
## 0…1 the rig shows (presentation only: the hurtbox and the body collider never scale).
var land_lag: int = 0
var squash: float = 0.0
const SQUASH_LAND := 1.0
const AIR_ATTACK_LAND_FRAMES := 3   # PLACEHOLDER (T5 Арес, docs/GDD/09-Tricks-And-Style.md § Вага тіла)
const SQUASH_HIT := 0.6
const SQUASH_DECAY := 0.18        # per frame
var flashing: bool = false
var _water_grounded: bool = false
var _splat_used: bool = false
# Choko's passive Printer (docs/GDD/03 § Пасивка Choko — Printer); effects can land on either fighter
var printer: Printer = null
var revealed_frames: int = 0      # «Seen»: this fighter shows through Shadow Veil (information only)
var ult_fx: GrimoireFx = null    # the running beat ultimate (armor, «SKI» flashes); null when none
var spring_frames: int = 0        # «Spring»: one extra air jump or air dash while > 0      # this combo already had its wall splat (reset when the fighter recovers)
var _limb_action: String = ""
var _normal_connected: bool = false
var _wish: Vector3 = Vector3.ZERO   # free_move: camera-relative stick in world space, this frame
var _dash_vec: Vector3 = Vector3.RIGHT
var _track_left: float = 0.0       # free_move: radians the current attack may still turn

@onready var animator: RigAnimator = $Rig
@onready var hurtbox: Area3D = $Hurtbox
@onready var hurt_shape: CollisionShape3D = $Hurtbox/Shape
@onready var hitbox_debug: MeshInstance3D = $HitboxDebug
@onready var grapple: GrappleHook = $GrappleHook

var skeletal: SkeletalRig = null   # C1 mannequin, only with GameState.skeletal_rig
var _ragdoll: Ragdoll = null
var _brain: CpuBrain = null
var _hit_query := PhysicsShapeQueryParameters3D.new()
var _hit_box := BoxShape3D.new()
var _stored_kb: Vector3 = Vector3.ZERO
var _stored_launch: bool = false
var _flash_from: Vector3 = Vector3.ZERO
var _flash_to: Vector3 = Vector3.ZERO
var _mark_timer: int = 90
var _record_slot: String = ""
var _status_text: String = ""
var _rng := RandomNumberGenerator.new()
var _weak_vis: WeakMarks


func _ready() -> void:
	if data == null:
		data = GameState.load_character("choko")
	hp = data.max_hp
	add_to_group("fighters")
	collision_layer = 2
	collision_mask = 1
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 0
	animator.setup(data)
	if GameState.skeletal_rig:
		skeletal = SkeletalRig.new()
		skeletal.name = "SkeletalRig"
		add_child(skeletal)
		skeletal.setup(self)
	grapple.setup(self)
	grapple.changed.connect(_on_grapple_changed)
	_hit_query.shape = _hit_box
	_hit_query.collision_mask = 4
	_hit_query.collide_with_areas = true
	_hit_query.collide_with_bodies = false
	_rng.seed = 7919 * player_index
	for slot in ["skill1", "skill2"]:
		var m: MoveData = data.skill1 if slot == "skill1" else data.skill2
		if m != null and m.effect == "record":
			_record_slot = slot
	dash_charges_left = data.dash_charges
	_weak_vis = WeakMarks.new()
	add_child(_weak_vis)
	_weak_vis.setup(self)
	if data.passive_id == "printer":
		printer = Printer.new()
		printer.name = "Printer"
		add_child(printer)
		printer.setup(self)
	if is_cpu:
		_brain = CpuBrain.new()
		_brain.fighter = self
		add_child(_brain)
	hitbox_debug.visible = false
	hp_changed.emit(hp, data.max_hp)
	meter_changed.emit(meter, MAX_METER)
	dash_changed.emit(dash_charges_left, 0.0, data.dash_charges)


# --- round lifecycle -------------------------------------------------------------------------
func reset_for_round(x: float, face: int) -> void:
	_break_ult()
	_clear_ragdoll()
	global_position = Vector3(x, 0.0, 0.0)
	velocity = Vector3.ZERO
	facing = face
	forward = Vector3(float(face), 0.0, 0.0)
	_wish = Vector3.ZERO
	sword_hand = "right"
	sword_swap_from = "right"
	sword_swap_to = "right"
	sword_swap_frame = 0
	attack_sword_hand = "right"
	_limb_action = ""
	_normal_connected = false
	GameState.duel.reset()
	hp = data.max_hp
	meter = 0.0
	combo_count = 0
	chain_index = 0
	hitstop_frames = 0
	stun_frames = 0
	invulnerable_frames = 0
	current_move = null
	control_locked = true
	frozen_frames = 0
	_stored_kb = Vector3.ZERO
	_stored_launch = false
	armor_break_frames = 0
	dot_frames = 0
	veil_frames = 0
	veil_strike = false
	speed_buff_frames = 0
	revealed_frames = 0
	spring_frames = 0
	if printer != null:
		printer.reset()
	weak_marks.clear()
	flashing = false
	_mark_timer = 90
	if record_marker != null and is_instance_valid(record_marker):
		record_marker.queue_free()
	record_marker = null
	dash_charges_left = data.dash_charges
	dash_recharge_left = 0.0
	dash_recharge_total = data.dash_recharge
	land_lag = 0
	squash = 0.0
	_apply_squash()
	animator.set_frozen_tint(0.0)
	animator.visible = true
	hurt_shape.disabled = false
	grapple.reset()
	_set_state(State.INTRO)
	if skeletal != null and skeletal.sword != null:
		skeletal.sword.reset_pose_state()
	hp_changed.emit(hp, data.max_hp)
	meter_changed.emit(meter, MAX_METER)
	cooldowns = {"skill1": 0.0, "skill2": 0.0}
	cooldowns_changed.emit(cooldowns)
	dash_changed.emit(dash_charges_left, 0.0, data.dash_charges)


func set_control(enabled: bool) -> void:
	control_locked = not enabled
	if enabled and state == State.INTRO:
		_set_state(State.IDLE)
	if not enabled and is_cpu:
		InputRouter.v_clear(player_index)


## Healing from an item (Printer «Patch»): never above max HP.
func heal(amount: float) -> void:
	hp = minf(data.max_hp, hp + amount)
	hp_changed.emit(hp, data.max_hp)


func heal_full() -> void:
	hp = data.max_hp
	hp_changed.emit(hp, data.max_hp)


func hurtbox_enabled() -> bool:
	return not hurt_shape.disabled and state != State.LAUNCHED and state != State.KO and invulnerable_frames <= 0


func is_actionable() -> bool:
	return state in [State.IDLE, State.WALK, State.CROUCH, State.BLOCK] and not control_locked and frozen_frames <= 0 and land_lag <= 0


func speed_mult() -> float:
	return (SPEED_MULT if speed_buff_frames > 0 else 1.0) * (1.0 - FATIGUE_WALK * fatigue_effect()) * (grapple.recovery_move_scale if grapple.recovering() else 1.0)


## 0 below FATIGUE_ON, then linear to 1 at fatigue 1.0.
func fatigue_effect() -> float:
	return clampf((fatigue - FATIGUE_ON) / (1.0 - FATIGUE_ON), 0.0, 1.0)


## `seconds` of fight time on this fighter's own clock (data.fatigue_seconds = fatigue 1.0).
func add_fatigue(seconds: float) -> void:
	fatigue = minf(1.0, fatigue + seconds / maxf(data.fatigue_seconds, 0.001))


## One frame of the round going (MatchFlow, FIGHT phase only).
func tick_fatigue() -> void:
	add_fatigue(1.0 / 60.0)


## How much fatigue slows the body: 1.0 fresh, 1 + k at fatigue 1.0.
func fatigue_mult(k: float) -> float:
	return 1.0 + k * fatigue_effect()


## The frame an own attack ends on: its data plus up to FATIGUE_RECOVERY frames of tired recovery.
func move_end_frame(m: MoveData) -> int:
	return m.total_frames() + floori(float(FATIGUE_RECOVERY) * fatigue_effect())


# --- main tick ---------------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if _free() and opponent != null:
		var a: Fighter = self if player_index == 1 else opponent
		GameState.duel.sync(a.global_position, a.opponent.global_position, InputRouter.frame())
	if state not in [State.IDLE, State.WALK, State.SWAP] or grapple.busy():
		InputRouter.buffered(player_index, "weapon_swap")
	grapple.tick_regen(delta, state == State.GRAPPLE)
	if frozen_frames > 0:
		frozen_frames -= 1
		animator.tick(delta, self, true)
		if frozen_frames == 0:
			_unfreeze()
		return
	frame_in_state += 1
	_tick_cooldowns(delta)
	_tick_status(delta)
	if hitstop_frames > 0:
		hitstop_frames -= 1
		animator.tick(delta, self, true)
		return
	if squash > 0.0:
		squash = maxf(0.0, squash - SQUASH_DECAY)
		_apply_squash()
	if invulnerable_frames > 0:
		invulnerable_frames -= 1
	if record_marker != null and _record_slot != "" and not control_locked and state != State.KO \
			and InputRouter.buffered(player_index, _record_slot):
		rewind()
	var intent := _read_intent()
	_check_swell(intent)
	match state:
		State.INTRO:
			_ground_physics(delta, 0.0)
		State.KO:
			_tick_ko()
		State.LAUNCHED:
			_tick_launched()
		State.KNOCKDOWN:
			_tick_knockdown(delta)
		State.GETUP:
			_tick_getup(delta)
		State.GRAPPLE:
			_tick_grapple(intent)
		State.SWAP:
			_tick_sword_swap(delta, intent)
		State.ATTACK:
			_tick_attack(delta)
		State.HITSTUN:
			_tick_hitstun(delta)
		State.BLOCKSTUN:
			_tick_blockstun(delta, intent)
		State.DASH:
			_tick_dash(delta)
		State.JUMP:
			_tick_air(delta, intent)
		State.STUMBLE:
			_tick_stumble(delta, intent)
		State.WALL_SPLAT:
			_tick_wall_splat(delta)
		_:
			_tick_ground(delta, intent)
	_post_move()
	_update_hitbox_debug()
	animator.tick(delta, self, false)


func _read_intent() -> Dictionary:
	var i := {"axis": 0.0, "crouch": false, "block": false, "grapple_held": false}
	_wish = Vector3.ZERO
	if control_locked:
		InputRouter.clear_recorded_view_basis(player_index)
		GameState.duel.human_to_world(Vector2.ZERO, player_index)
		return i
	i.axis = InputRouter.axis(player_index)
	if _free():
		var move := InputRouter.move(player_index)
		_wish = GameState.duel.to_world(move, player_index) if is_cpu else GameState.duel.human_to_world(move, player_index, InputRouter.view_basis(player_index))
	i.crouch = InputRouter.held(player_index, "crouch")
	i.block = InputRouter.held(player_index, "block")
	i.grapple_held = InputRouter.held(player_index, grapple.action)
	return i


func _pressed(action: String) -> bool:
	if grapple.hands_busy() and action in ["left_hand", "right_hand", "light", "skill1", "skill2", "ultimate", "weapon_swap"]:
		InputRouter.buffered(player_index, action) # Consume blocked intent, never replay after extraction.
		return false
	if control_locked:
		return false
	return InputRouter.buffered(player_index, action)


func _tick_cooldowns(delta: float) -> void:
	var changed := false
	for k in cooldowns.keys():
		if cooldowns[k] > 0.0:
			cooldowns[k] = maxf(0.0, cooldowns[k] - delta)
			changed = true
	if changed:
		cooldowns_changed.emit(cooldowns)


func _tick_status(delta: float) -> void:
	if armor_break_frames > 0:
		armor_break_frames -= 1
	if speed_buff_frames > 0:
		speed_buff_frames -= 1
	if dot_frames > 0:
		dot_frames -= 1
		if dot_frames % DOT_EVERY == 0 and hp > 1.0 and state != State.KO:
			hp = maxf(1.0, hp - dot_damage)
			hp_changed.emit(hp, data.max_hp)
	if veil_frames > 0:
		veil_frames -= 1
		if veil_frames % 7 == 0:
			Afterimage.spawn(Fx.root(self), Afterimage.snapshot(animator, skeletal), data.vfx_primary, 0.3, 0.13, true)
		if veil_frames == 0:
			end_veil()
		elif state != State.LAUNCHED and state != State.KO:
			animator.visible = revealed_frames > 0   # «Seen» shows the veiled body; information only
	if revealed_frames > 0:
		revealed_frames -= 1
	if spring_frames > 0:
		spring_frames -= 1
	if data.dash_charges > 0 and dash_charges_left < data.dash_charges and not flashing:
		dash_recharge_left -= delta
		if dash_recharge_left <= 0.0:
			dash_charges_left = data.dash_charges
			dash_recharge_left = 0.0
			Sfx.play("ui_move", -10)
		dash_changed.emit(dash_charges_left, maxf(dash_recharge_left, 0.0), data.dash_charges)
	if data.passive_id == "weak_point" and opponent != null and not control_locked:
		_mark_timer -= 1
		if _mark_timer <= 0:
			_mark_timer = MARK_INTERVAL
			if opponent.weak_marks.size() < MAX_MARKS:
				var free: Array = []
				for z in ["low", "mid", "high"]:
					if not opponent.weak_marks.has(z):
						free.append(z)
				opponent.weak_marks[free[_rng.randi() % free.size()]] = true
	_emit_status()


func _emit_status() -> void:
	var parts: PackedStringArray = []
	if frozen_frames > 0:
		parts.append("FROZEN")
	if armor_break_frames > 0:
		parts.append("ARMOR BREAK")
	if dot_frames > 0:
		parts.append("BLEED" if dot_damage <= BLEED_DMG else "POISON")
	if veil_frames > 0:
		parts.append("VEIL")
	if speed_buff_frames > 0:
		parts.append("SPEED")
	if record_marker != null:
		parts.append("RECORD %.1f" % (float(record_marker.left) / 60.0))
	var t := " · ".join(parts)
	if t != _status_text:
		_status_text = t
		status_changed.emit(t)


func _skill_ready(slot: String) -> bool:
	var m: MoveData = data.skill1 if slot == "skill1" else data.skill2
	if m == null:
		return false
	if cooldowns.get(slot, 0.0) > 0.0:
		return false
	if slot == _record_slot and record_marker != null:
		return false
	return meter >= m.meter_cost


# --- ground / air / signature movement -------------------------------------------------------
func _tick_ground(delta: float, intent: Dictionary) -> void:
	_update_facing()
	if land_lag > 0:   # the body settles after a jump: no new action, it brakes
		land_lag -= 1
		_walk_physics(delta, 0.0)
		return
	if _try_sword_swap():
		return
	crouching = intent.crouch
	if _try_grapple(intent.crouch):
		return
	if _pressed("ultimate") and meter >= MAX_METER and data.ultimate:
		_start_move(data.ultimate, "ultimate")
		return
	if _pressed("skill1") and _skill_ready("skill1"):
		_start_move(data.skill1, "skill1")
		return
	if _pressed("skill2") and _skill_ready("skill2"):
		_start_move(data.skill2, "skill2")
		return
	if _try_limb_attack(false):
		return
	if _pressed("heavy") and data.heavy:
		_start_move(data.heavy)
		return
	if _pressed("light"):
		var m: MoveData = data.crouch_light if (crouching and data.crouch_light) else data.light
		_start_move(m)
		return
	if _pressed("dash"):
		_start_dash(intent.axis)
		return
	if _pressed("jump"):
		velocity.y = data.jump_velocity
		velocity.x = intent.axis * data.walk_speed * speed_mult()
		if _free():
			velocity.x = _wish.x * data.walk_speed * speed_mult()
			velocity.z = _wish.z * data.walk_speed * speed_mult()
		_set_state(State.JUMP)
		velocity.y -= GRAVITY * delta
		move_and_slide()
		return
	if intent.block:
		_set_state_if(State.BLOCK)
		_walk_physics(delta, 0.0)
		return
	if crouching:
		_set_state_if(State.CROUCH)
		_walk_physics(delta, 0.0)
		return
	if _free():
		if _wish.length() > 0.1:
			_set_state_if(State.WALK)
			_walk_free(delta)
			return
	elif absf(intent.axis) > 0.1:
		var fwd := signf(intent.axis) == float(facing)
		var speed := (data.walk_speed if fwd else data.back_walk_speed) * speed_mult() * water_walk_mult()
		_set_state_if(State.WALK)
		_walk_physics(delta, intent.axis * speed)
		return
	_set_state_if(State.IDLE)
	_walk_physics(delta, 0.0)


## Humans travel straight in the gesture frame. CPU retains its tactical opponent-relative
## walk/back-walk and circle speed, including the existing orbit radius correction.
func _walk_free(delta: float) -> void:
	if not is_cpu:
		var travel := _wish * data.walk_speed * speed_mult() * water_walk_mult()
		_walk_physics(delta, travel.x, travel.z)
		return
	var along := _wish.dot(forward)
	var side := _wish - forward * along
	var k := speed_mult() * water_walk_mult()
	var v := forward * along * (data.walk_speed if along >= 0.0 else data.back_walk_speed) * k + side * data.walk_speed * data.circle_speed_mult * k
	var r0 := -1.0
	if opponent != null and side.length() > 0.1:
		r0 = _flat(global_position - opponent.global_position).length() - along * (data.walk_speed if along >= 0.0 else data.back_walk_speed) * k * delta
	_walk_physics(delta, v.x, v.z)
	if r0 > MIN_SEPARATION:
		var d := _flat(global_position - opponent.global_position)
		if d.length() > MIN_LINE:
			d = d.normalized() * r0
			global_position.x = opponent.global_position.x + d.x
			global_position.z = opponent.global_position.z + d.z


## The rig's squash (landing, taking a hit): wider and lower, back in SQUASH_DECAY steps. Only the pictures scale
## (RigAnimator `$Rig`, the hero SkeletalRig) — never the hurtbox or the body collider.
func _apply_squash() -> void:
	var s := clampf(squash, 0.0, 1.6)
	var k := Vector3(1.0 + 0.08 * s, 1.0 - 0.14 * s, 1.0 + 0.08 * s)
	if animator != null:
		animator.scale = k
	if skeletal != null:
		skeletal.scale = k


## Walking and standing (Santos: start/stop weight): the horizontal speed moves toward the wish at ground_accel (speeding
## up or turning) or ground_decel (braking) instead of jumping to it. Other states (attacks, dashes, stun, get-up) keep
## _ground_physics, so frame data and combos are untouched.
func _walk_physics(delta: float, vx: float, vz: float = 0.0) -> void:
	var cur := Vector2(velocity.x, velocity.z if _free() else 0.0)
	var want := Vector2(vx, vz if _free() else 0.0)
	var rate := data.ground_accel if want.length() > cur.length() - 0.001 else data.ground_decel
	var h := cur.move_toward(want, rate * delta)
	_ground_physics(delta, h.x, h.y)


func _ground_physics(delta: float, vx: float, vz: float = 0.0) -> void:
	velocity.x = vx
	if _free():
		velocity.z = vz
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if on_ground():
		velocity.y = 0.0


func _tick_air(delta: float, intent: Dictionary) -> void:
	if _try_grapple(false):
		return
	if data.dash_style == "flash" and _pressed("dash"):
		if _start_flash(intent.axis):
			return
	if _try_limb_attack(true):
		return
	if (_pressed("light") or _pressed("heavy")) and data.air_light:
		_start_move(data.air_light)
		return
	if spring_frames > 0:
		# Printer «Spring»: one extra jump or one air dash, then it is spent
		if _pressed("jump"):
			spring_frames = 0
			velocity.y = data.jump_velocity
			Sfx.play("whoosh", -6)
		elif _pressed("dash") and data.dash_style == "dash":
			spring_frames = 0
			_start_dash(intent.axis)
			return
	if _free():
		var rate := data.air_control * data.walk_speed * 3.0 * delta
		velocity.x = move_toward(velocity.x, _wish.x * data.walk_speed * speed_mult(), rate)
		velocity.z = move_toward(velocity.z, _wish.z * data.walk_speed * speed_mult(), rate)
	else:
		velocity.x = move_toward(velocity.x, intent.axis * data.walk_speed * speed_mult(), data.air_control * data.walk_speed * 3.0 * delta)
	velocity.y -= GRAVITY * delta * (data.fall_gravity_mult if velocity.y < 0.0 else 1.0)   # heavier on the way down
	move_and_slide()
	if on_ground():
		velocity.y = 0.0
		Sfx.play("land", -14)
		_update_facing()
		land_lag = data.land_frames
		squash = SQUASH_LAND
		_apply_squash()
		_set_state(State.IDLE)


func _start_dash(axis: float) -> bool:
	if data.dash_style == "flash":
		var ok := _start_flash(axis)
		if ok:
			add_fatigue(FATIGUE_DASH_S)
		return ok
	add_fatigue(FATIGUE_DASH_S)
	dash_dir = int(signf(axis)) if absf(axis) > 0.1 else facing
	if _free():
		_aim_dash()
	dash_frames_left = data.dash_frames
	if dash_dir != facing:
		invulnerable_frames = 6
	flashing = false
	Afterimage.spawn(Fx.root(self), Afterimage.snapshot(animator, skeletal), data.vfx_secondary, 0.22, 0.3, true)
	_set_state(State.DASH)
	Sfx.play("whoosh", -6)
	return true


## Skea's flash-step: a 4-frame blink that passes through the opponent, leaves stepped ghosts and
## torn ink shards. Charges: `dash_charges`; all return `dash_recharge` s after the last use.
func _start_flash(axis: float) -> bool:
	if dash_charges_left <= 0:
		Sfx.play("grapple_denied", -4)
		return false
	dash_charges_left -= 1
	dash_recharge_total = data.dash_recharge * fatigue_mult(FATIGUE_DASH)
	dash_recharge_left = dash_recharge_total
	dash_changed.emit(dash_charges_left, dash_recharge_left, data.dash_charges)
	dash_dir = int(signf(axis)) if absf(axis) > 0.1 else facing
	_flash_from = global_position
	if _free():
		_aim_flash()
		_flash_to = clamp_arena(global_position + _dash_vec * data.flash_distance)
	else:
		var tx := clampf(global_position.x + float(dash_dir) * data.flash_distance, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH)
		_flash_to = Vector3(tx, global_position.y, 0.0)
	flashing = true
	if _free():
		GameState.duel.hold(FLASH_TRAVEL + FLASH_INPUT_LOCK)   # «вперед» не перевертається під пальцем
	dash_frames_left = FLASH_TRAVEL + FLASH_RECOVER
	invulnerable_frames = maxi(invulnerable_frames, FLASH_IFRAMES)
	velocity = Vector3.ZERO
	current_move = null
	stats.flashes += 1
	var root := Fx.root(self)
	Afterimage.spawn(root, Afterimage.snapshot(animator, skeletal), data.vfx_primary, 0.4, 0.7, true)
	Afterimage.spawn(root, Afterimage.snapshot(animator, skeletal), Color(0.05, 0.03, 0.08), 0.3, 0.55, false, 1.0, Vector3(0, 0, -0.05))
	SmearShards.burst(root, _flash_from, _flash_to, [data.vfx_primary, data.vfx_secondary, data.accent_color, Color(0.04, 0.03, 0.06)], 16, 5)
	Sfx.play("flash", -2)
	_set_state(State.DASH)
	return true


## Free movement: dash/flash along the stick (or forward when neutral); dash_dir keeps its
## plane meaning (+facing = toward the opponent) for the backdash i-frames and the rig.
func _aim_dash() -> void:
	_dash_vec = _wish.normalized() if _wish.length() > 0.1 else forward
	dash_dir = facing if _dash_vec.dot(forward) >= -0.5 else -facing


## Free movement Flash Step (docs/GDD/03 § Як у 3D, T5 Арес): along the line between the fighters —
## through the opponent, or away from them when the stick points back; a sideways stick turns the
## exit point by FLASH_SIDE_DEG to that side.
func _aim_flash() -> void:
	var along := _wish.dot(forward)
	var base := forward if along >= -0.5 else -forward
	var side := _wish.dot(Vector3.UP.cross(forward))   # + = to the fighter's left
	_dash_vec = base.rotated(Vector3.UP, deg_to_rad(FLASH_SIDE_DEG) * signf(side)) if absf(side) > 0.1 else base
	dash_dir = facing if along >= -0.5 else -facing


func _tick_dash(delta: float) -> void:
	if flashing:
		_tick_flash(delta)
		return
	dash_frames_left -= 1
	velocity.x = dash_dir * data.dash_speed
	if _free():
		velocity.x = _dash_vec.x * data.dash_speed
		velocity.z = _dash_vec.z * data.dash_speed
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if dash_frames_left < data.dash_frames / 2:
		if _pressed("light") and data.light:
			_start_move(data.light)
			return
		if _pressed("heavy") and data.heavy:
			_start_move(data.heavy)
			return
	if dash_frames_left <= 0:
		_set_state(State.IDLE if on_ground() else State.JUMP)   # an air dash (Spring) ends falling


func _tick_flash(delta: float) -> void:
	var idx := (FLASH_TRAVEL + FLASH_RECOVER) - dash_frames_left
	dash_frames_left -= 1
	if idx < FLASH_TRAVEL:
		var a := float(idx + 1) / float(FLASH_TRAVEL)
		global_position = _flash_from.lerp(_flash_to, a)
		velocity = Vector3.ZERO
		Afterimage.spawn(Fx.root(self), Afterimage.snapshot(animator, skeletal), data.vfx_primary, 0.32, 0.5 - 0.08 * float(idx), true)
		if idx == FLASH_TRAVEL - 1:
			_update_facing()
			animator.flinch(Vector3(float(-dash_dir), 0.0, 0.0), 70.0, facing)
	else:
		if _pressed("light") and data.light:
			flashing = false
			_start_move(data.light)
			return
		if _pressed("heavy") and data.heavy:
			flashing = false
			_start_move(data.heavy)
			return
		if _pressed("dash") and _start_flash(InputRouter.axis(player_index) if not control_locked else 0.0):
			return
		if not on_ground():
			velocity.y -= GRAVITY * delta * 0.5
		_friction(40.0 * delta)
		move_and_slide()
	if dash_frames_left <= 0:
		flashing = false
		_set_state(State.IDLE if on_ground() else State.JUMP)


# --- attacks ------------------------------------------------------------------------------------
## New normal inputs coexist with legacy CPU light/heavy. The original move resources
## remain immutable; pose variants inherit the donor's complete combat contract.
func sword_swap_progress() -> float:
	return float(sword_swap_frame) / float(SWORD_SWAP_FRAMES) if state == State.SWAP else 0.0


func _discard_swap_blocked_inputs() -> void:
	for action: String in ["weapon_swap", "left_hand", "right_hand", "light", "heavy", "skill1", "skill2", "ultimate", "grapple", "grapple_enemy", "grapple_parkour", "jump", "block"]:
		InputRouter.buffered(player_index, action)


func _try_sword_swap() -> bool:
	if not _pressed("weapon_swap"):
		return false
	if data.id != "choko" or data.weapon_kind != "sword" or state not in [State.IDLE, State.WALK] or not on_ground() or grapple.busy():
		return false
	sword_swap_from = sword_hand
	sword_swap_to = "left" if sword_hand == "right" else "right"
	sword_swap_frame = 0
	crouching = false
	_set_state(State.SWAP)
	_discard_swap_blocked_inputs()
	return true


func _tick_sword_swap(delta: float, intent: Dictionary) -> void:
	_discard_swap_blocked_inputs()
	# Input interruptions precede this tick's handoff. At counter 11, a dodge keeps
	# the old hand; once counter 12 committed, any interruption keeps the new hand.
	if _pressed("dash"):
		_set_state(State.IDLE)
		_start_dash(intent.axis)
		return
	for action: String in ["left_leg", "right_leg"]:
		if InputRouter.pressed_within(player_index, action, InputRouter.BUFFER_FRAMES):
			_set_state(State.IDLE)
			_try_limb_attack(false, false, true)
			return
	sword_swap_frame += 1
	if sword_swap_frame == SWORD_SWAP_CONTACT:
		sword_hand = sword_swap_to
	_walk_physics(delta, 0.0)
	if sword_swap_frame >= SWORD_SWAP_FRAMES:
		_set_state(State.IDLE)


func _try_limb_attack(air: bool, chaining: bool = false, legs_only: bool = false) -> bool:
	for action: String in LimbMoves.ACTIONS:
		if legs_only and not action.ends_with("leg"):
			continue
		if not _pressed(action):
			continue
		var index := chain_index + 1 if chaining else 0
		var move := LimbMoves.resolve(data, action, index, _limb_action if chaining else "", crouching, air, sword_hand)
		if move == null:
			return false
		_start_move(move)
		chain_index = index
		_limb_action = action
		return true
	return false


func _start_move(m: MoveData, slot: String = "") -> void:
	if m == null:
		return
	if _free() and not is_cpu and opponent != null and state != State.ATTACK:
		_set_forward(opponent.global_position - global_position)
	attack_sword_hand = sword_hand
	if not m.anim.begins_with("limb_") and not m.anim.begins_with("sword_left_hand_") and not m.anim.begins_with("sword_right_hand_"):
		_limb_action = ""
	if veil_frames > 0:
		veil_strike = true
		end_veil()
		if m == data.ultimate and data.ultimate_veil != null:
			m = data.ultimate_veil   # «з диму»: the long ult (docs/GDD/03 § Ульта Skea під бас, (а))
	if m.meter_cost > 0.0:
		meter = maxf(0.0, meter - m.meter_cost)
		meter_changed.emit(meter, MAX_METER)
	if slot in ["skill1", "skill2"]:
		add_fatigue(FATIGUE_SKILL_S)
	if m.cooldown > 0.0 and slot in ["skill1", "skill2"] and m.effect != "record":
		cooldowns[slot] = m.cooldown
		cooldowns_changed.emit(cooldowns)
	if state != State.ATTACK:
		chain_index = 0
	flashing = false
	current_move = m
	current_slot = slot
	move_frame = 0
	has_hit = false
	_normal_connected = false
	_track_left = deg_to_rad(m.tracking_deg)
	airborne_attack = not on_ground()
	_set_state(State.ATTACK)
	move_started.emit(self, m)
	if m.kind == MoveData.Kind.ULTIMATE:
		Sfx.play("ultimate")


func _tick_attack(delta: float) -> void:
	var m := current_move
	if m == null:
		_set_state(State.IDLE)
		return
	if airborne_attack:
		velocity.y -= GRAVITY * delta * (data.fall_gravity_mult if velocity.y < 0.0 else 1.0)   # T5: no floating while striking
	else:
		var window := m.startup + m.active
		if _free() and move_frame < m.startup:
			_track()
		if m.forward_step > 0.0 and move_frame < window:
			velocity.x = facing * m.forward_step / (float(window) / 60.0)
			if _free():
				velocity.x = forward.x * m.forward_step / (float(window) / 60.0)
				velocity.z = forward.z * m.forward_step / (float(window) / 60.0)
		else:
			_friction(40.0 * delta)
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if airborne_attack and on_ground():
		velocity = Vector3.ZERO
		current_move = null
		land_lag = AIR_ATTACK_LAND_FRAMES   # T5 (09 § Вага тіла): an air attack lands heavier than a jump
		squash = SQUASH_LAND
		_apply_squash()
		_set_state(State.IDLE)
		return
	if move_frame == m.startup:
		if _limb_action.ends_with("leg") or m == data.heavy:
			grapple.extract_on_kick(_limb_action if _limb_action != "" else "right_leg")
		Sfx.play(m.sfx_whiff, -4)
		_strike_smear(m)
		if m.effect != "":
			_activate_effect(m)
		if m.free_after_startup:
			# «режим», not a cutscene: the effect runs the active window, the body is the player's again
			current_move = null
			_set_state(State.IDLE if on_ground() else State.JUMP)
			return

	if move_frame >= m.startup and move_frame < m.startup + m.active and not has_hit and m.damage >= 0.0 and m.anim != "throw":
		_check_hit(m)
	if has_hit and move_frame >= m.startup + m.active:
		if _try_cancel(m):
			return
	move_frame += 1
	if move_frame >= move_end_frame(m):
		current_move = null
		if airborne_attack and not on_ground():
			_set_state(State.JUMP)
		else:
			_set_state(State.IDLE)


## Free movement: during startup the attack turns toward the opponent, at most tracking_deg in
## total over the whole startup (docs/Plans/2026-10-03-Prototype-0.3-Free-Movement.md § Модель руху).
func _track() -> void:
	if opponent == null or _track_left <= 0.0:
		return
	var to := _flat(opponent.global_position - global_position)
	if to.length() < MIN_LINE:
		return
	var ang := forward.signed_angle_to(to.normalized(), Vector3.UP)
	var step := clampf(ang, -_track_left, _track_left)
	_track_left -= absf(step)
	_set_forward(forward.rotated(Vector3.UP, step))


## Ink smear along the strike on the first active frame (step 1.5): heavier moves leave more.
func _strike_smear(m: MoveData) -> void:
	if m.damage <= 0.0 or m.hitbox_size == Vector3.ZERO:
		return
	var from := global_position + _ahead(0.25, m.hitbox_offset.y)
	var to := global_position + _ahead(m.hitbox_offset.x + m.hitbox_size.x * 0.5, m.hitbox_offset.y)
	var heavy := m.damage >= 70.0
	SmearShards.burst(Fx.root(self), from, to, [data.vfx_primary, data.accent_color, Color(0.05, 0.03, 0.08)], 10 if heavy else 5, 3 if heavy else 2)


func _activate_effect(m: MoveData) -> void:
	match m.effect:
		"record":
			place_record()
		"time_stop":
			TimeStopFx.spawn(self, TIME_STOP_FRAMES)
		"sword_storm":
			SwordStormFx.spawn(self)
		"kunai_rain":
			if _free():
				# on the opponent's spot at the throw, at most 7 m away (docs/GDD/03 § Як у 3D)
				var c := global_position + forward * 3.0
				if opponent != null:
					var d := _flat(opponent.global_position - global_position)
					c = global_position + d.limit_length(7.0)
				KunaiRain.spawn_at(self, c)
				return
			var cx := global_position.x + float(facing) * 3.0
			if opponent != null:
				cx = clampf(opponent.global_position.x, global_position.x - 7.0, global_position.x + 7.0)
			KunaiRain.spawn(self, cx)
		"shadow_veil":
			begin_veil()
		"grimoire":
			ult_fx = GrimoireFx.spawn(self, m)


func _try_cancel(m: MoveData) -> bool:
	if m.cancel_tier < 3 and _pressed("ultimate") and meter >= MAX_METER and data.ultimate:
		_start_move(data.ultimate, "ultimate")
		return true
	if m.cancel_tier < 2:
		if _pressed("skill1") and _skill_ready("skill1"):
			_start_move(data.skill1, "skill1")
			return true
		if _pressed("skill2") and _skill_ready("skill2"):
			_start_move(data.skill2, "skill2")
			return true
		if data.dash_style == "flash" and dash_charges_left > 0 and _pressed("dash"):
			current_move = null
			return _start_flash(InputRouter.axis(player_index))
	if m.cancel_tier < 1 and not _limb_action.ends_with("leg") and _normal_connected and chain_index < 2 and _try_limb_attack(airborne_attack, true):
		return true
	if m.cancel_tier < 1:
		if _pressed("heavy") and data.heavy:
			_start_move(data.heavy)
			return true
		if _pressed("light") and chain_index < 2 and data.light:
			chain_index += 1
			var keep := chain_index
			_start_move(data.light)
			chain_index = keep
			return true
	return false


func _check_hit(m: MoveData) -> void:
	if opponent == null:
		return
	_hit_box.size = m.hitbox_size
	var off := m.hitbox_offset
	off.x *= float(facing)
	_hit_query.transform = Transform3D(Basis.IDENTITY, global_position + off)
	if _free():
		_hit_query.transform = Transform3D(_basis(), global_position + _basis() * m.hitbox_offset)
	var space := get_world_3d().direct_space_state
	var results := space.intersect_shape(_hit_query, 8)
	for r in results:
		var area := r.get("collider") as Area3D
		if area != null and area.get_parent() == opponent and opponent.hurtbox_enabled():
			has_hit = true
			if not on_ground():
				spring_frames = 0   # Spring never extends an air juggle: a hit in the air spends it
			var hits_before: int = stats.hits
			opponent.receive_hit(self, m)
			_normal_connected = stats.hits > hits_before
			return


# --- being hit -----------------------------------------------------------------------------
func receive_hit(attacker: Fighter, m: MoveData) -> void:
	if state == State.KO or state == State.LAUNCHED or invulnerable_frames > 0:
		return
	if ult_armored() and not m.breaks_ult_armor:
		_armored_hit(attacker, m)
		return
	_break_ult()
	last_hit_crit = false
	var crit := _check_crit(attacker, m)
	var scale := 1.0 if m.ignore_scaling else maxf(0.35, 1.0 - COMBO_SCALING * float(combo_count))
	var crit_k := CRIT_MULT if crit else 1.0
	var kb := Vector3(float(attacker.facing) * m.knockback.x, m.knockback.y, 0.0) / maxf(0.2, data.weight)
	if _free():
		kb = (attacker.forward * m.knockback.x + Vector3.UP * m.knockback.y) / maxf(0.2, data.weight)
	if frozen_frames > 0:
		# time is stopped: damage lands (70 %), knockback is stored until time resumes
		hp -= m.damage * scale * crit_k * FREEZE_DAMAGE
		combo_count += 1
		attacker.stats.hits += 1
		_stored_kb += kb * 0.6
		if m.launcher or m.knockdown:
			_stored_launch = true
		stun_frames = maxi(stun_frames, m.hitstun)
		_gain_meter(attacker, m.meter_gain_hit)
		_apply_hit_effects(m)
		animator.flash()
		Sfx.play(m.sfx_hit)
		attacker.hitstop_frames = maxi(attacker.hitstop_frames, m.hitstop)
		hp_changed.emit(hp, data.max_hp)
		hit_landed.emit(attacker, self, m, false)
		if hp <= 0.0:
			frozen_frames = 0
			animator.set_frozen_tint(0.0)
			_die(attacker, m)
		elif state != State.HITSTUN:
			_set_state(State.HITSTUN)
		return
	var blocking := (state == State.BLOCK or state == State.BLOCKSTUN) and _guards_against(attacker) and m.kind != MoveData.Kind.THROW
	if blocking:
		hp = maxf(1.0, hp - m.chip_damage * (3.0 if crit else 1.0))
		stun_frames = m.blockstun + (4 if crit else 0)
		velocity.x = float(attacker.facing) * m.knockback.x * 0.45
		if _free():
			velocity.x = attacker.forward.x * m.knockback.x * 0.45
			velocity.z = attacker.forward.z * m.knockback.x * 0.45
		velocity.y = 0.0
		meter = minf(MAX_METER, meter + m.meter_gain_block * 0.5)
		attacker.meter = minf(MAX_METER, attacker.meter + m.meter_gain_block)
		stats.blocks += 1
		_set_state(State.BLOCKSTUN)
		Sfx.play("block")
		_apply_hitstop(attacker, maxi(2, m.hitstop / 2))
		hp_changed.emit(hp, data.max_hp)
		meter_changed.emit(meter, MAX_METER)
		attacker.meter_changed.emit(attacker.meter, MAX_METER)
		hit_landed.emit(attacker, self, m, true)
		return
	var dmg := m.damage * scale * crit_k
	hp -= dmg
	combo_count += 1
	attacker.stats.hits += 1
	if crit:
		attacker.stats.crits += 1
		Sfx.play("crit", -2)
	_gain_meter(attacker, m.meter_gain_hit)
	_apply_hit_effects(m)
	animator.flash()
	Sfx.play(m.sfx_hit)
	_apply_hitstop(attacker, m.hitstop + (3 if crit else 0))
	squash = maxf(squash, SQUASH_HIT * clampf(m.damage / 60.0, 0.5, 1.6))   # the body gives under the blow (picture only)
	_apply_squash()
	hp_changed.emit(hp, data.max_hp)
	hit_landed.emit(attacker, self, m, false)
	if hp <= 0.0:
		_die(attacker, m)
		return
	if m.launcher or m.knockdown or not on_ground():
		_enter_ragdoll(kb * m.ragdoll_impulse)
		return
	stun_frames = m.hitstun
	if _free() and not _guards_against(attacker):
		stun_frames += m.backhit_hitstun_bonus   # side/back hit (docs/GDD/02 § Блок під кутом)
	velocity.x = kb.x
	velocity.y = kb.y
	if _free():
		velocity.z = kb.z
	animator.flinch(_flinch_dir(attacker), dmg, facing, _zone_for(attacker, m))
	_set_state(State.HITSTUN)


## Under a beat ultimate (MoveData.armor) Skea does not fall, flinch or lose the ult — from the move's
## first frame to the end of active. A spell already on him breaks it: DoT, armor break, «Seen», time
## stop; so does a hit with MoveData.breaks_ult_armor (Choko's crystal blast, receive_hit). Checked on every hit, so a poison landed mid-ult breaks the armor too (docs/GDD/03 § Ульта Skea
## під бас, «Непорушний»).
func ult_armored() -> bool:
	if dot_frames > 0 or armor_break_frames > 0 or revealed_frames > 0 or frozen_frames > 0:
		return false
	if state == State.ATTACK and current_move != null and current_move.armor and move_frame < current_move.startup + current_move.active:
		return true
	return ult_fx != null and is_instance_valid(ult_fx) and ult_fx.running()


## Damage lands as usual; no hitstun, no hitstop on the armored body, no knockback, no fall.
func _armored_hit(attacker: Fighter, m: MoveData) -> void:
	last_hit_crit = false
	var crit := _check_crit(attacker, m)
	var scale := 1.0 if m.ignore_scaling else maxf(0.35, 1.0 - COMBO_SCALING * float(combo_count))
	var dmg := m.damage * scale * (CRIT_MULT if crit else 1.0)
	hp -= dmg
	attacker.stats.hits += 1
	if crit:
		attacker.stats.crits += 1
		Sfx.play("crit", -2)
	_gain_meter(attacker, m.meter_gain_hit)
	_apply_hit_effects(m)
	animator.flash()
	Sfx.play(m.sfx_hit)
	attacker.hitstop_frames = maxi(attacker.hitstop_frames, m.hitstop + (3 if crit else 0))
	stats.armored = int(stats.get("armored", 0)) + 1
	hp_changed.emit(hp, data.max_hp)
	hit_landed.emit(attacker, self, m, false)
	if hp <= 0.0:
		_die(attacker, m)


## A hit got through: the running beat ultimate ends now, like any move (end event, music fade, stinger).
func _break_ult() -> void:
	if ult_fx != null and is_instance_valid(ult_fx):
		ult_fx.end_ult()
	ult_fx = null


## «SKI» signature: one flash-step stroke on the beat (no charge, no i-frames — the armor covers him).
func beat_flash(to: Vector3) -> void:
	if not (state in [State.IDLE, State.WALK, State.CROUCH, State.BLOCK, State.DASH]) or not on_ground():
		return
	_flash_from = global_position
	_flash_to = clamp_arena(Vector3(to.x, global_position.y, to.z))
	flashing = true
	dash_dir = facing
	dash_frames_left = FLASH_TRAVEL + FLASH_RECOVER
	velocity = Vector3.ZERO
	current_move = null
	Afterimage.spawn(Fx.root(self), Afterimage.snapshot(animator, skeletal), data.vfx_primary, 0.4, 0.7, true)
	Sfx.play("flash", -6)
	_set_state(State.DASH)


## Plane: the guard holds when the fighters face each other. Free movement: when the attacker is
## within ±block_arc_deg of where we look — a side or back hit is never blocked.
func _guards_against(attacker: Fighter) -> bool:
	if not _free():
		return facing == -attacker.facing
	var to := _flat(attacker.global_position - global_position)
	if to.length() < MIN_LINE:
		return true
	return rad_to_deg(forward.angle_to(to.normalized())) <= data.block_arc_deg


## Direction for RigAnimator.flinch(), which reads only dir.x against `facing`.
func _flinch_dir(attacker: Fighter) -> Vector3:
	if not _free():
		return Vector3(float(attacker.facing), 0, 0)
	return Vector3(attacker.forward.dot(forward) * float(facing), 0.0, 0.0)


func _check_crit(attacker: Fighter, m: MoveData) -> bool:
	var crit := m.force_crit
	if attacker.veil_strike:
		crit = true
		attacker.veil_strike = false
		dot_frames = BLEED_FRAMES
		dot_damage = BLEED_DMG
	if attacker.data.passive_id == "weak_point" and m.can_crit:
		var zone := _zone_for(attacker, m)
		if armor_break_frames > 0 or weak_marks.has(zone):
			crit = true
			weak_marks.erase(zone)
			attacker.speed_buff_frames = maxi(attacker.speed_buff_frames, CRIT_SPEED_FRAMES)
	last_hit_crit = crit
	return crit


func _zone_for(attacker: Fighter, m: MoveData) -> String:
	var h := attacker.global_position.y + m.hitbox_offset.y - global_position.y
	if h < 0.75:
		return "low"
	if h < 1.35:
		return "mid"
	return "high"


func _apply_hit_effects(m: MoveData) -> void:
	match m.effect:
		"armor_break":
			armor_break_frames = maxi(armor_break_frames, ARMOR_BREAK_FRAMES)
		"bleed":
			dot_frames = BLEED_FRAMES
			dot_damage = BLEED_DMG
		"poison":
			dot_frames = POISON_FRAMES
			dot_damage = POISON_DMG


func _gain_meter(attacker: Fighter, gain: float) -> void:
	attacker.meter = minf(MAX_METER, attacker.meter + gain)
	meter = minf(MAX_METER, meter + gain * 0.5)
	meter_changed.emit(meter, MAX_METER)
	attacker.meter_changed.emit(attacker.meter, MAX_METER)


## Grapple "get over here": pulled to target_x and stunned. No damage; the follow-up is the reward.
func get_pulled(target_x: float, stun: int) -> void:
	if state == State.KO or state == State.LAUNCHED or frozen_frames > 0 or ult_armored():
		return
	if state == State.GRAPPLE:
		grapple.detach()
	var dx := target_x - global_position.x
	var t := float(stun) / 60.0
	var v0 := (absf(dx) + 0.5 * HIT_FRICTION * t * t) / maxf(t, 0.05)
	velocity.x = signf(dx) * v0
	velocity.y = 2.5
	stun_frames = stun
	combo_count = 0
	animator.flinch(Vector3(signf(dx), 0, 0), 60.0, facing)
	Sfx.play("hit_light", -6)
	_set_state(State.HITSTUN)


## Free movement version of get_pulled(): pulled to a point on the ground plane (y ignored).
func get_pulled_to(target: Vector3, stun: int) -> void:
	if state == State.KO or state == State.LAUNCHED or frozen_frames > 0 or ult_armored():
		return
	if state == State.GRAPPLE:
		grapple.detach()
	var d := _flat(target - global_position)
	var t := float(stun) / 60.0
	var v0 := (d.length() + 0.5 * HIT_FRICTION * t * t) / maxf(t, 0.05)
	var dir := d.normalized() if d.length() > MIN_LINE else Vector3.ZERO
	velocity.x = dir.x * v0
	velocity.z = dir.z * v0
	velocity.y = 2.5
	stun_frames = stun
	combo_count = 0
	animator.flinch(Vector3(dir.dot(forward) * float(facing), 0, 0), 60.0, facing)
	Sfx.play("hit_light", -6)
	_set_state(State.HITSTUN)


func _apply_hitstop(other: Fighter, frames: int) -> void:
	hitstop_frames = maxi(hitstop_frames, frames)
	if other:
		other.hitstop_frames = maxi(other.hitstop_frames, frames)


func _tick_hitstun(delta: float) -> void:
	stun_frames -= 1
	_friction(HIT_FRICTION * delta)
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if on_ground():
		velocity.y = 0.0
	if stun_frames <= 0:
		combo_count = 0
		_update_facing()
		_set_state(State.IDLE if on_ground() else State.JUMP)


func _tick_blockstun(delta: float, intent: Dictionary) -> void:
	stun_frames -= 1
	_friction(HIT_FRICTION * delta)
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if stun_frames <= 0:
		_set_state(State.BLOCK if intent.block else State.IDLE)


# --- skills: freeze, record/rewind, veil ----------------------------------------------------------
func freeze(frames: int) -> bool:
	if state == State.KO or state == State.LAUNCHED or invulnerable_frames > 0:
		return false
	frozen_frames = maxi(frozen_frames, frames)
	animator.set_frozen_tint(1.0)
	if state == State.GRAPPLE:
		grapple.detach()
	_emit_status()
	return true


func _unfreeze() -> void:
	animator.set_frozen_tint(0.0)
	if _stored_launch:
		var kb := _stored_kb
		_stored_launch = false
		_stored_kb = Vector3.ZERO
		_enter_ragdoll(kb + Vector3(0.0, 3.0, 0.0))
		return
	if _stored_kb.length() > 0.05:
		velocity = _stored_kb
		_stored_kb = Vector3.ZERO
		stun_frames = maxi(stun_frames, 12)
		_set_state(State.HITSTUN)


func place_record() -> void:
	if record_marker != null and is_instance_valid(record_marker):
		record_marker.queue_free()
	record_marker = RecordMarker.spawn(self)


## Choko S1 second press (or marker timeout): snap back to the marker, recover HP up to the
## recorded value (capped at 15 % max HP), 14 i-frames. Breaks combos and ragdolls, not KO.
func rewind() -> void:
	if record_marker == null or not is_instance_valid(record_marker):
		record_marker = null
		return
	var target := record_marker.global_position
	var rec_hp := record_marker.recorded_hp
	record_marker.queue_free()
	record_marker = null
	if state == State.KO:
		return
	var root := Fx.root(self)
	var from := global_position
	for i in 5:
		var k := float(i) / 4.0
		Afterimage.spawn(root, Afterimage.snapshot(animator, skeletal), data.vfx_secondary, 0.25 + 0.06 * float(i), 0.45 * (1.0 - k * 0.6),
			true, 1.0, (target - from) * k)
	SmearShards.burst(root, from, target, [data.vfx_primary, data.vfx_secondary, Color(0.9, 0.95, 1.0)], 12, 4)
	_clear_ragdoll()
	animator.visible = true
	hurt_shape.disabled = false
	grapple.detach()
	global_position = Vector3(target.x, maxf(target.y, 0.0), target.z if _free() else 0.0)
	velocity = Vector3.ZERO
	if rec_hp > hp:
		hp = minf(rec_hp, hp + data.max_hp * REWIND_HEAL_CAP)
		hp_changed.emit(hp, data.max_hp)
	invulnerable_frames = 14
	combo_count = 0
	stun_frames = 0
	current_move = null
	var m: MoveData = data.skill1 if _record_slot == "skill1" else data.skill2
	if m != null:
		cooldowns[_record_slot] = m.cooldown
		cooldowns_changed.emit(cooldowns)
	Sfx.play("rewind")
	_update_facing()
	_set_state(State.IDLE if on_ground() or global_position.y < floor_y() + 0.05 else State.JUMP)


func begin_veil() -> void:
	veil_frames = VEIL_FRAMES
	speed_buff_frames = maxi(speed_buff_frames, VEIL_FRAMES)
	animator.visible = false
	SmokeCloud.spawn(Fx.root(self), global_position + Vector3(0, 1.0, 0), Color(0.3, 0.2, 0.4), 3.0, 2.0)
	SmearShards.burst(Fx.root(self), global_position, global_position + Vector3(0.0, 0.5, 0.0), [data.vfx_primary, data.vfx_secondary], 10, 0)
	Sfx.play("smoke")


func end_veil() -> void:
	veil_frames = 0
	if state != State.LAUNCHED and state != State.KO:
		animator.visible = true
	SmearShards.burst(Fx.root(self), global_position, global_position + _ahead(0.6), [data.vfx_primary, Color(0.05, 0.03, 0.08)], 8, 1)


# --- ragdoll / knockdown / KO ----------------------------------------------------------------
func _enter_ragdoll(impulse: Vector3) -> void:
	velocity = Vector3.ZERO
	flashing = false
	if not GameState.use_ragdoll:
		velocity.x = impulse.x * 0.5
		if _free():
			velocity.z = impulse.z * 0.5
		_set_state(State.KNOCKDOWN)
		return
	_spawn_ragdoll(impulse, true)
	_set_state(State.LAUNCHED)


func _spawn_ragdoll(impulse: Vector3, muscles: bool) -> void:
	_clear_ragdoll()
	if skeletal != null:
		# launch 7.1: the hero itself falls — the ragdoll runs on the skeleton (BoneRagdoll)
		var br := BoneRagdoll.new()
		_ragdoll = br
		get_parent().add_child(br)
		br.build_on(skeletal, animator.part_snapshot(), impulse, muscles)
	else:
		_ragdoll = Ragdoll.new()
		get_parent().add_child(_ragdoll)
		_ragdoll.build_from(animator.part_snapshot(), impulse, muscles)
	animator.visible = false
	hurt_shape.disabled = true
	stats.ragdolls += 1


func _clear_ragdoll() -> void:
	if _ragdoll != null and is_instance_valid(_ragdoll):
		_ragdoll.release()
		_ragdoll.queue_free()
	_ragdoll = null


func _tick_launched() -> void:
	if _ragdoll == null:
		_set_state(State.KNOCKDOWN)
		return
	var p := _ragdoll.pelvis_position()
	if _free() and not _splat_used and _flat(p).length() >= ARENA_RADIUS:
		_wall_splat(p)
		return
	global_position = _ground_spot(p)
	if _ragdoll.settled() or frame_in_state > 170:
		var g := global_position
		_clear_ragdoll()
		global_position = g
		velocity = Vector3.ZERO
		animator.visible = veil_frames <= 0
		hurt_shape.disabled = false
		invulnerable_frames = GETUP_FRAMES + 8
		combo_count = 0
		_update_facing()
		_set_state(State.GETUP)


## The flying ragdoll met the arena wall: end it, pin the body to the wall with its back to it,
## facing the centre. No damage. Hurtbox stays on, so the attacker gets a follow-up window.
func _wall_splat(p: Vector3) -> void:
	var n := _flat(p).normalized()
	_clear_ragdoll()
	global_position = clamp_arena(Vector3(p.x, floor_y(), p.z))
	velocity = Vector3.ZERO
	_set_forward(-n)
	animator.visible = veil_frames <= 0
	hurt_shape.disabled = false
	_splat_used = true
	stats.splats = int(stats.get("splats", 0)) + 1
	Sfx.play("hit_heavy", -4)
	_set_state(State.WALL_SPLAT)


func _tick_wall_splat(delta: float) -> void:
	_ground_physics(delta, 0.0)
	velocity.x = 0.0
	velocity.z = 0.0
	if frame_in_state >= WALL_SPLAT_FRAMES:
		_set_state(State.KNOCKDOWN)


func _tick_knockdown(delta: float) -> void:
	_friction(HIT_FRICTION * delta)
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if frame_in_state >= KNOCKDOWN_FRAMES:
		invulnerable_frames = GETUP_FRAMES + 8
		combo_count = 0
		_update_facing()
		_set_state(State.GETUP)


func _tick_getup(delta: float) -> void:
	_ground_physics(delta, 0.0)
	if frame_in_state >= getup_frames():
		_set_state(State.IDLE)


func _die(attacker: Fighter, m: MoveData) -> void:
	hp = 0.0
	hp_changed.emit(hp, data.max_hp)
	control_locked = true
	veil_frames = 0
	dot_frames = 0
	flashing = false
	if record_marker != null and is_instance_valid(record_marker):
		record_marker.queue_free()
	record_marker = null
	var dir := Vector3(float(attacker.facing) * maxf(m.knockback.x, 5.0), maxf(m.knockback.y, 4.5), 0.0) * 1.3
	if _free():
		dir = (attacker.forward * maxf(m.knockback.x, 5.0) + Vector3.UP * maxf(m.knockback.y, 4.5)) * 1.3
	if GameState.use_ragdoll:
		_spawn_ragdoll(dir, false)
	_set_state(State.KO)
	knocked_out.emit(self)
	Sfx.play("ko")


func _tick_ko() -> void:
	if _ragdoll != null:
		global_position = _ground_spot(_ragdoll.pelvis_position())


# --- grapple --------------------------------------------------------------------------------------
func _try_grapple(prefer_enemy: bool) -> bool:
	var shot_action := "grapple"
	if _pressed("grapple_enemy"):
		prefer_enemy = true
		shot_action = "grapple_enemy"
	elif _pressed("grapple_parkour"):
		prefer_enemy = false
		shot_action = "grapple_parkour"
	elif not _pressed("grapple"):
		return false
	var target := grapple.fire(prefer_enemy, shot_action)
	if target != GrappleHook.Target.NONE:
		stats.grapples += 1
		_set_state(State.GRAPPLE)
		return true
	return false


func _tick_grapple(intent: Dictionary) -> void:
	grapple.drive(get_physics_process_delta_time(), intent.grapple_held)
	if not grapple.busy() or grapple.recovering():
		_set_state(State.JUMP if not on_ground() else State.IDLE)


func _on_grapple_changed(charges: int, cooldown_left: float, max_charges: int) -> void:
	grapple_changed.emit(charges, cooldown_left, max_charges)


# --- helpers -----------------------------------------------------------------------------------
func _update_facing() -> void:
	if _free() and not is_cpu and _wish.length() > 0.1 and not InputRouter.held(player_index, "block") and not InputRouter.held(player_index, "crouch"):
		_set_forward(_wish)
		return
	if opponent == null:
		return
	if _free():
		# Guard/idle and explicit attacks prioritize the current foe.
		_set_forward(opponent.global_position - global_position)
		return
	var dx := opponent.global_position.x - global_position.x
	if absf(dx) > 0.05:
		facing = 1 if dx > 0.0 else -1
		forward = Vector3(float(facing), 0.0, 0.0)


# --- free movement helpers (GameState.free_move) ---------------------------------------------------
func _free() -> bool:
	return GameState.free_move


## This frame's camera-relative stick in world space (zero in the plane mode or without control).
func wish() -> Vector3:
	return _wish


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## Sets `forward` from any vector (y ignored); a near-zero vector keeps the old one. `facing` follows
## as the screen side: +1 when looking toward screen-right of the duel frame.
func _set_forward(v: Vector3) -> void:
	var f := _flat(v)
	if f.length() < MIN_LINE:
		return
	forward = f.normalized()
	facing = 1 if forward.dot(GameState.duel.right) >= 0.0 else -1


## Yaw that turns local +x (the rig's and MoveData's "forward") onto `forward`.
func yaw() -> float:
	return atan2(-forward.z, forward.x)


func _basis() -> Basis:
	return Basis(Vector3.UP, yaw())


## A point `dist` ahead of the fighter at height y, relative to its position.
func _ahead(dist: float, y: float = 0.0) -> Vector3:
	if _free():
		return forward * dist + Vector3.UP * y
	return Vector3(float(facing) * dist, y, 0.0)


## Ground friction on horizontal speed. Free movement slows the (x, z) vector as a whole: per-axis
## friction would stop diagonal motion √2× sooner than motion along an axis.
func _friction(amount: float) -> void:
	if not _free():
		velocity.x = move_toward(velocity.x, 0.0, amount)
		return
	var h := Vector2(velocity.x, velocity.z).move_toward(Vector2.ZERO, amount)
	velocity.x = h.x
	velocity.z = h.y


## Plane: |x| ≤ ARENA_HALF_WIDTH. Free movement: inside the circle of ARENA_RADIUS (hard edge for
## now; the soft wall's feel is T5 Арес's, #25). y is kept.
static func clamp_arena(p: Vector3) -> Vector3:
	if not GameState.free_move:
		return Vector3(clampf(p.x, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH), p.y, p.z)
	var f := Vector3(p.x, 0.0, p.z)
	if f.length() > ARENA_RADIUS:
		f = f.normalized() * ARENA_RADIUS
	return Vector3(f.x, p.y, f.z)


## Free movement soft wall (docs/GDD/02 § Коло арени): at the circle the outward radial part of the
## velocity is removed and the tangential part stays — the fighter slides along the edge.
func _soft_wall() -> void:
	var f := _flat(global_position)
	if f.length() <= ARENA_RADIUS:
		return
	var n := f.normalized()
	global_position = clamp_arena(global_position)
	var out := velocity.x * n.x + velocity.z * n.z
	if out > 0.0:
		velocity.x -= out * n.x
		velocity.z -= out * n.z


## Where the body stands while a ragdoll flies: under the pelvis, on the floor, inside the arena.
func _ground_spot(p: Vector3) -> Vector3:
	if not _free():
		return Vector3(clampf(p.x, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH), 0.0, 0.0)
	return clamp_arena(Vector3(p.x, 0.0, p.z))


# --- water (river stage) -------------------------------------------------------------------------
## Height of whatever the fighter stands on: the wave surface on water stages, else 0.
func floor_y() -> float:
	return GameState.water.height(global_position.x, global_position.z) if GameState.water != null else 0.0


## Grounded test that also works on water, where there is no collider under the feet.
func on_ground() -> bool:
	if is_on_floor():
		return true
	if GameState.water == null:
		return false
	return global_position.y <= floor_y() + 0.002 or (_water_grounded and velocity.y <= 0.0)


func water_walk_mult() -> float:
	return 0.85 + 0.15 * data.water_balance if GameState.water != null else 1.0


func getup_frames() -> int:
	return roundi(GETUP_FRAMES * fatigue_mult(FATIGUE_GETUP)) + (WATER_GETUP_EXTRA if GameState.water != null else 0)


## A swell knocks an unsteady fighter off balance: only on its first frame, only grounded
## idle/walk/crouch fighters that are not holding block, only if balance < swell strength.
func _check_swell(intent: Dictionary) -> void:
	var w := GameState.water
	if w == null or not w.swell_started_now() or control_locked:
		return
	if not state in [State.IDLE, State.WALK, State.CROUCH] or intent.block:
		return
	if data.water_balance < w.swell_strength:
		stun_frames = w.stumble_frames
		stats.stumbles = int(stats.get("stumbles", 0)) + 1
		animator.flinch(Vector3(-facing, 0.0, 0.0), 40.0, facing)
		_set_state(State.STUMBLE)


## Can't attack while stumbling, but can raise a guard (which ends the stumble).
func _tick_stumble(delta: float, intent: Dictionary) -> void:
	if intent.block:
		_set_state(State.BLOCK)
		_ground_physics(delta, 0.0)
		return
	stun_frames -= 1
	if _free():
		_ground_physics(delta, -forward.x * 0.6, -forward.z * 0.6)
	else:
		_ground_physics(delta, -facing * 0.6)
	if stun_frames <= 0:
		_set_state(State.IDLE)


func _post_move() -> void:
	if _free():
		_soft_wall()
	else:
		global_position.x = clampf(global_position.x, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH)
		global_position.z = 0.0
	if GameState.water != null:
		# stand on the waves: never below the surface, and stay glued to it while grounded
		var fy := floor_y()
		if global_position.y < fy or (_water_grounded and velocity.y <= 0.0 and global_position.y - fy < 0.25):
			global_position.y = fy
			if velocity.y < 0.0:
				velocity.y = 0.0
			_water_grounded = true
		else:
			_water_grounded = false
	elif global_position.y < 0.0:
		global_position.y = 0.0
	if opponent == null or flashing or opponent.flashing:
		return
	if state == State.LAUNCHED or state == State.KO or opponent.state == State.LAUNCHED or opponent.state == State.KO:
		return
	if _free():
		_push_radial()
		return
	var dx := global_position.x - opponent.global_position.x
	if absf(dx) < MIN_SEPARATION and on_ground() and opponent.on_ground():
		var push := (MIN_SEPARATION - absf(dx)) * 0.5
		var dir := 1.0 if dx >= 0.0 else -1.0
		if dx == 0.0:
			dir = -float(facing)
		global_position.x = clampf(global_position.x + dir * push, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH)
		opponent.global_position.x = clampf(opponent.global_position.x - dir * push, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH)


## Free movement push-box: the fighters are discs of MIN_SEPARATION on the ground plane; overlap is
## split half-half along the line between them (they are in one spot → along -forward).
func _push_radial() -> void:
	var d := _flat(global_position - opponent.global_position)
	var l := d.length()
	if l >= MIN_SEPARATION or not on_ground() or not opponent.on_ground():
		return
	var dir := d / l if l > 0.0001 else -forward
	var push := dir * (MIN_SEPARATION - l) * 0.5
	global_position = clamp_arena(global_position + push)
	opponent.global_position = clamp_arena(opponent.global_position - push)


func _update_hitbox_debug() -> void:
	var show := GameState.show_hitboxes and state == State.ATTACK and current_move != null \
		and current_move.damage >= 0.0 and move_frame >= current_move.startup and move_frame < current_move.startup + current_move.active
	hitbox_debug.visible = show
	if show:
		var off := current_move.hitbox_offset
		off.x *= float(facing)
		hitbox_debug.global_position = global_position + off
		hitbox_debug.scale = current_move.hitbox_size
		if _free():
			hitbox_debug.global_transform = Transform3D(_basis() * Basis.from_scale(current_move.hitbox_size), global_position + _basis() * current_move.hitbox_offset)


func _set_state(s: State) -> void:
	if state == State.SWAP and s != State.SWAP:
		sword_swap_frame = 0
		sword_swap_from = sword_hand
		sword_swap_to = sword_hand
	if state == State.GRAPPLE and s != State.GRAPPLE and grapple != null:
		grapple.detach()
	if state == State.ATTACK and s != State.ATTACK:
		chain_index = 0
		_limb_action = ""
		_normal_connected = false
		veil_strike = false
	state = s
	frame_in_state = 0
	if s in [State.IDLE, State.WALK, State.CROUCH, State.BLOCK, State.INTRO]:
		_splat_used = false   # back in control → the combo is over → the next combo may splat again
	state_changed.emit(int(s))


func _set_state_if(s: State) -> void:
	if state != s:
		_set_state(s)
