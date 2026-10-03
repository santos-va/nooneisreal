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

enum State { INTRO, IDLE, WALK, CROUCH, JUMP, DASH, ATTACK, BLOCK, HITSTUN, BLOCKSTUN, LAUNCHED, KNOCKDOWN, GETUP, GRAPPLE, KO, STUMBLE }

const GRAVITY := 24.0
const ARENA_HALF_WIDTH := 12.5
const MIN_SEPARATION := 0.95
const KNOCKDOWN_FRAMES := 40
const GETUP_FRAMES := 18
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
const PERFECT_BLOCK_WINDOW := 8
const PERFECT_FREEZE := 24
const REWIND_HEAL_CAP := 0.15
const TIME_STOP_FRAMES := 72
const WATER_GETUP_EXTRA := 6      # Stage-River: getting up out of the water is slower (PLACEHOLDER)

@export var player_index: int = 1
@export var data: CharacterData
@export var is_cpu: bool = false

var state: State = State.INTRO
var facing: int = 1
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
var pull_pending: bool = false
var stats: Dictionary = {"hits": 0, "blocks": 0, "grapples": 0, "ragdolls": 0, "crits": 0, "perfect": 0, "flashes": 0}

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
var flashing: bool = false
var _water_grounded: bool = false

@onready var animator: RigAnimator = $Rig
@onready var hurtbox: Area3D = $Hurtbox
@onready var hurt_shape: CollisionShape3D = $Hurtbox/Shape
@onready var hitbox_debug: MeshInstance3D = $HitboxDebug
@onready var grapple: GrappleHook = $GrappleHook

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
	_clear_ragdoll()
	global_position = Vector3(x, 0.0, 0.0)
	velocity = Vector3.ZERO
	facing = face
	hp = data.max_hp
	meter = 0.0
	combo_count = 0
	chain_index = 0
	hitstop_frames = 0
	stun_frames = 0
	invulnerable_frames = 0
	current_move = null
	pull_pending = false
	control_locked = true
	frozen_frames = 0
	_stored_kb = Vector3.ZERO
	_stored_launch = false
	armor_break_frames = 0
	dot_frames = 0
	veil_frames = 0
	veil_strike = false
	speed_buff_frames = 0
	weak_marks.clear()
	flashing = false
	_mark_timer = 90
	if record_marker != null and is_instance_valid(record_marker):
		record_marker.queue_free()
	record_marker = null
	dash_charges_left = data.dash_charges
	dash_recharge_left = 0.0
	animator.set_frozen_tint(0.0)
	animator.visible = true
	hurt_shape.disabled = false
	grapple.reset()
	_set_state(State.INTRO)
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


func heal_full() -> void:
	hp = data.max_hp
	hp_changed.emit(hp, data.max_hp)


func hurtbox_enabled() -> bool:
	return not hurt_shape.disabled and state != State.LAUNCHED and state != State.KO and invulnerable_frames <= 0


func is_actionable() -> bool:
	return state in [State.IDLE, State.WALK, State.CROUCH, State.BLOCK] and not control_locked and frozen_frames <= 0


func speed_mult() -> float:
	return SPEED_MULT if speed_buff_frames > 0 else 1.0


# --- main tick ---------------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if frozen_frames > 0:
		frozen_frames -= 1
		animator.tick(delta, self, true)
		if frozen_frames == 0:
			_unfreeze()
		return
	frame_in_state += 1
	_tick_cooldowns(delta)
	_tick_status(delta)
	grapple.tick_regen(delta, state == State.GRAPPLE)
	if hitstop_frames > 0:
		hitstop_frames -= 1
		animator.tick(delta, self, true)
		return
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
		_:
			_tick_ground(delta, intent)
	_post_move()
	_update_hitbox_debug()
	animator.tick(delta, self, false)


func _read_intent() -> Dictionary:
	var i := {"axis": 0.0, "crouch": false, "block": false, "grapple_held": false}
	if control_locked:
		return i
	i.axis = InputRouter.axis(player_index)
	i.crouch = InputRouter.held(player_index, "crouch")
	i.block = InputRouter.held(player_index, "block")
	i.grapple_held = InputRouter.held(player_index, "grapple")
	return i


func _pressed(action: String) -> bool:
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
			Afterimage.spawn(Fx.root(self), animator.part_snapshot(), data.vfx_primary, 0.3, 0.13, true)
		if veil_frames == 0:
			end_veil()
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
		_set_state(State.JUMP)
		velocity.y -= GRAVITY * delta
		move_and_slide()
		return
	if intent.block:
		_set_state_if(State.BLOCK)
		_ground_physics(delta, 0.0)
		return
	if crouching:
		_set_state_if(State.CROUCH)
		_ground_physics(delta, 0.0)
		return
	if absf(intent.axis) > 0.1:
		var forward := signf(intent.axis) == float(facing)
		var speed := (data.walk_speed if forward else data.back_walk_speed) * speed_mult() * water_walk_mult()
		_set_state_if(State.WALK)
		_ground_physics(delta, intent.axis * speed)
		return
	_set_state_if(State.IDLE)
	_ground_physics(delta, 0.0)


func _ground_physics(delta: float, vx: float) -> void:
	velocity.x = vx
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
	if (_pressed("light") or _pressed("heavy")) and data.air_light:
		_start_move(data.air_light)
		return
	velocity.x = move_toward(velocity.x, intent.axis * data.walk_speed * speed_mult(), data.air_control * data.walk_speed * 3.0 * delta)
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if on_ground():
		velocity.y = 0.0
		Sfx.play("land", -14)
		_update_facing()
		_set_state(State.IDLE)


func _start_dash(axis: float) -> bool:
	if data.dash_style == "flash":
		return _start_flash(axis)
	dash_dir = int(signf(axis)) if absf(axis) > 0.1 else facing
	dash_frames_left = data.dash_frames
	if dash_dir != facing:
		invulnerable_frames = 6
	flashing = false
	Afterimage.spawn(Fx.root(self), animator.part_snapshot(), data.vfx_secondary, 0.22, 0.3, true)
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
	dash_recharge_left = data.dash_recharge
	dash_changed.emit(dash_charges_left, dash_recharge_left, data.dash_charges)
	dash_dir = int(signf(axis)) if absf(axis) > 0.1 else facing
	_flash_from = global_position
	var tx := clampf(global_position.x + float(dash_dir) * data.flash_distance, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH)
	_flash_to = Vector3(tx, global_position.y, 0.0)
	flashing = true
	dash_frames_left = FLASH_TRAVEL + FLASH_RECOVER
	invulnerable_frames = maxi(invulnerable_frames, FLASH_IFRAMES)
	velocity = Vector3.ZERO
	current_move = null
	stats.flashes += 1
	var root := Fx.root(self)
	Afterimage.spawn(root, animator.part_snapshot(), data.vfx_primary, 0.4, 0.7, true)
	Afterimage.spawn(root, animator.part_snapshot(), Color(0.05, 0.03, 0.08), 0.3, 0.55, false, 1.0, Vector3(0, 0, -0.05))
	SmearShards.burst(root, _flash_from, _flash_to, [data.vfx_primary, data.vfx_secondary, data.accent_color, Color(0.04, 0.03, 0.06)], 16, 5)
	Sfx.play("flash", -2)
	_set_state(State.DASH)
	return true


func _tick_dash(delta: float) -> void:
	if flashing:
		_tick_flash(delta)
		return
	dash_frames_left -= 1
	velocity.x = dash_dir * data.dash_speed
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
		_set_state(State.IDLE)


func _tick_flash(delta: float) -> void:
	var idx := (FLASH_TRAVEL + FLASH_RECOVER) - dash_frames_left
	dash_frames_left -= 1
	if idx < FLASH_TRAVEL:
		var a := float(idx + 1) / float(FLASH_TRAVEL)
		global_position = _flash_from.lerp(_flash_to, a)
		velocity = Vector3.ZERO
		Afterimage.spawn(Fx.root(self), animator.part_snapshot(), data.vfx_primary, 0.32, 0.5 - 0.08 * float(idx), true)
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
		velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
		move_and_slide()
	if dash_frames_left <= 0:
		flashing = false
		_set_state(State.IDLE if on_ground() else State.JUMP)


# --- attacks ------------------------------------------------------------------------------------
func _start_move(m: MoveData, slot: String = "") -> void:
	if m == null:
		return
	if veil_frames > 0:
		veil_strike = true
		end_veil()
	if m.meter_cost > 0.0:
		meter = maxf(0.0, meter - m.meter_cost)
		meter_changed.emit(meter, MAX_METER)
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
		velocity.y -= GRAVITY * delta
	else:
		var window := m.startup + m.active
		if m.forward_step > 0.0 and move_frame < window:
			velocity.x = facing * m.forward_step / (float(window) / 60.0)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if airborne_attack and on_ground():
		velocity = Vector3.ZERO
		current_move = null
		_set_state(State.IDLE)
		return
	if move_frame == m.startup:
		Sfx.play(m.sfx_whiff, -4)
		_strike_smear(m)
		if m.effect != "":
			_activate_effect(m)
		if pull_pending:
			pull_pending = false
			if opponent:
				grapple.pull_enemy(opponent)
	if move_frame >= m.startup and move_frame < m.startup + m.active and not has_hit and m.damage >= 0.0 and m.anim != "throw":
		_check_hit(m)
	if has_hit and move_frame >= m.startup + m.active:
		if _try_cancel(m):
			return
	move_frame += 1
	if move_frame >= m.total_frames():
		current_move = null
		if airborne_attack and not on_ground():
			_set_state(State.JUMP)
		else:
			_set_state(State.IDLE)


## Ink smear along the strike on the first active frame (step 1.5): heavier moves leave more.
func _strike_smear(m: MoveData) -> void:
	if m.damage <= 0.0 or m.hitbox_size == Vector3.ZERO:
		return
	var from := global_position + Vector3(facing * 0.25, m.hitbox_offset.y, 0.0)
	var to := global_position + Vector3(facing * (m.hitbox_offset.x + m.hitbox_size.x * 0.5), m.hitbox_offset.y, 0.0)
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
			var cx := global_position.x + float(facing) * 3.0
			if opponent != null:
				cx = clampf(opponent.global_position.x, global_position.x - 7.0, global_position.x + 7.0)
			KunaiRain.spawn(self, cx)
		"shadow_veil":
			begin_veil()
		"grimoire":
			GrimoireFx.spawn(self)


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
	var space := get_world_3d().direct_space_state
	var results := space.intersect_shape(_hit_query, 8)
	for r in results:
		var area := r.get("collider") as Area3D
		if area != null and area.get_parent() == opponent and opponent.hurtbox_enabled():
			has_hit = true
			opponent.receive_hit(self, m)
			return


# --- being hit -----------------------------------------------------------------------------
func receive_hit(attacker: Fighter, m: MoveData) -> void:
	if state == State.KO or state == State.LAUNCHED or invulnerable_frames > 0:
		return
	last_hit_crit = false
	var crit := _check_crit(attacker, m)
	var scale := 1.0 if m.ignore_scaling else maxf(0.35, 1.0 - COMBO_SCALING * float(combo_count))
	var crit_k := CRIT_MULT if crit else 1.0
	var kb := Vector3(float(attacker.facing) * m.knockback.x, m.knockback.y, 0.0) / maxf(0.2, data.weight)
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
	var blocking := (state == State.BLOCK or state == State.BLOCKSTUN) and facing == -attacker.facing and m.kind != MoveData.Kind.THROW
	if blocking:
		hp = maxf(1.0, hp - m.chip_damage * (3.0 if crit else 1.0))
		stun_frames = m.blockstun + (4 if crit else 0)
		velocity.x = float(attacker.facing) * m.knockback.x * 0.45
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
		if data.passive_id == "chrono_guard" and InputRouter.pressed_within(player_index, "block", PERFECT_BLOCK_WINDOW):
			_perfect_block(attacker)
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
	hp_changed.emit(hp, data.max_hp)
	hit_landed.emit(attacker, self, m, false)
	if hp <= 0.0:
		_die(attacker, m)
		return
	if m.launcher or m.knockdown or not on_ground():
		_enter_ragdoll(kb * m.ragdoll_impulse)
		return
	stun_frames = m.hitstun
	velocity.x = kb.x
	velocity.y = kb.y
	animator.flinch(Vector3(float(attacker.facing), 0, 0), dmg, facing, _zone_for(attacker, m))
	_set_state(State.HITSTUN)


func _check_crit(attacker: Fighter, m: MoveData) -> bool:
	var crit := false
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


## Choko passive «Хроно-захист»: block pressed ≤ 8 frames before the hit freezes the attacker
## for 24 frames and refunds 1 s of skill cooldowns.
func _perfect_block(attacker: Fighter) -> void:
	if attacker.freeze(PERFECT_FREEZE):
		stats.perfect += 1
		for k in cooldowns.keys():
			cooldowns[k] = maxf(0.0, cooldowns[k] - 1.0)
		cooldowns_changed.emit(cooldowns)
		animator.flash()
		Sfx.play("time_stop", -8)


## Grapple "get over here": pulled to target_x and stunned. No damage; the follow-up is the reward.
func get_pulled(target_x: float, stun: int) -> void:
	if state == State.KO or state == State.LAUNCHED or frozen_frames > 0:
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


func _apply_hitstop(other: Fighter, frames: int) -> void:
	hitstop_frames = maxi(hitstop_frames, frames)
	if other:
		other.hitstop_frames = maxi(other.hitstop_frames, frames)


func _tick_hitstun(delta: float) -> void:
	stun_frames -= 1
	velocity.x = move_toward(velocity.x, 0.0, HIT_FRICTION * delta)
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
	velocity.x = move_toward(velocity.x, 0.0, HIT_FRICTION * delta)
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
		Afterimage.spawn(root, animator.part_snapshot(), data.vfx_secondary, 0.25 + 0.06 * float(i), 0.45 * (1.0 - k * 0.6),
			true, 1.0, (target - from) * k)
	SmearShards.burst(root, from, target, [data.vfx_primary, data.vfx_secondary, Color(0.9, 0.95, 1.0)], 12, 4)
	_clear_ragdoll()
	animator.visible = true
	hurt_shape.disabled = false
	grapple.detach()
	global_position = Vector3(target.x, maxf(target.y, 0.0), 0.0)
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
	SmearShards.burst(Fx.root(self), global_position, global_position + Vector3(float(facing) * 0.6, 0, 0), [data.vfx_primary, Color(0.05, 0.03, 0.08)], 8, 1)


# --- ragdoll / knockdown / KO ----------------------------------------------------------------
func _enter_ragdoll(impulse: Vector3) -> void:
	velocity = Vector3.ZERO
	flashing = false
	if not GameState.use_ragdoll:
		velocity.x = impulse.x * 0.5
		_set_state(State.KNOCKDOWN)
		return
	_spawn_ragdoll(impulse, true)
	_set_state(State.LAUNCHED)


func _spawn_ragdoll(impulse: Vector3, muscles: bool) -> void:
	_clear_ragdoll()
	_ragdoll = Ragdoll.new()
	get_parent().add_child(_ragdoll)
	_ragdoll.build_from(animator.part_snapshot(), impulse, muscles)
	animator.visible = false
	hurt_shape.disabled = true
	stats.ragdolls += 1


func _clear_ragdoll() -> void:
	if _ragdoll != null and is_instance_valid(_ragdoll):
		_ragdoll.queue_free()
	_ragdoll = null


func _tick_launched() -> void:
	if _ragdoll == null:
		_set_state(State.KNOCKDOWN)
		return
	var p := _ragdoll.pelvis_position()
	global_position = Vector3(clampf(p.x, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH), 0.0, 0.0)
	if _ragdoll.settled() or frame_in_state > 170:
		var gx := global_position.x
		_clear_ragdoll()
		global_position = Vector3(gx, 0.0, 0.0)
		velocity = Vector3.ZERO
		animator.visible = veil_frames <= 0
		hurt_shape.disabled = false
		invulnerable_frames = GETUP_FRAMES + 8
		combo_count = 0
		_update_facing()
		_set_state(State.GETUP)


func _tick_knockdown(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, HIT_FRICTION * delta)
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
	if GameState.use_ragdoll:
		_spawn_ragdoll(dir, false)
	_set_state(State.KO)
	knocked_out.emit(self)
	Sfx.play("ko")


func _tick_ko() -> void:
	if _ragdoll != null:
		var p := _ragdoll.pelvis_position()
		global_position = Vector3(clampf(p.x, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH), 0.0, 0.0)


# --- grapple --------------------------------------------------------------------------------------
func _try_grapple(prefer_enemy: bool) -> bool:
	if not _pressed("grapple"):
		return false
	var target := grapple.fire(prefer_enemy)
	if target == GrappleHook.Target.ANCHOR:
		stats.grapples += 1
		_set_state(State.GRAPPLE)
		return true
	if target == GrappleHook.Target.ENEMY and data.throw_move:
		stats.grapples += 1
		pull_pending = true
		_start_move(data.throw_move)
		return true
	return false


func _tick_grapple(intent: Dictionary) -> void:
	grapple.drive(get_physics_process_delta_time(), intent.grapple_held)
	if not grapple.attached:
		_set_state(State.JUMP if not on_ground() else State.IDLE)


func _on_grapple_changed(charges: int, cooldown_left: float, max_charges: int) -> void:
	grapple_changed.emit(charges, cooldown_left, max_charges)


# --- helpers -----------------------------------------------------------------------------------
func _update_facing() -> void:
	if opponent == null:
		return
	var dx := opponent.global_position.x - global_position.x
	if absf(dx) > 0.05:
		facing = 1 if dx > 0.0 else -1


# --- water (river stage) -------------------------------------------------------------------------
## Height of whatever the fighter stands on: the wave surface on water stages, else 0.
func floor_y() -> float:
	return GameState.water.height(global_position.x) if GameState.water != null else 0.0


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
	return GETUP_FRAMES + (WATER_GETUP_EXTRA if GameState.water != null else 0)


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
	_ground_physics(delta, -facing * 0.6)
	if stun_frames <= 0:
		_set_state(State.IDLE)


func _post_move() -> void:
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
	var dx := global_position.x - opponent.global_position.x
	if absf(dx) < MIN_SEPARATION and on_ground() and opponent.on_ground():
		var push := (MIN_SEPARATION - absf(dx)) * 0.5
		var dir := 1.0 if dx >= 0.0 else -1.0
		if dx == 0.0:
			dir = -float(facing)
		global_position.x = clampf(global_position.x + dir * push, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH)
		opponent.global_position.x = clampf(opponent.global_position.x - dir * push, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH)


func _update_hitbox_debug() -> void:
	var show := GameState.show_hitboxes and state == State.ATTACK and current_move != null \
		and current_move.damage >= 0.0 and move_frame >= current_move.startup and move_frame < current_move.startup + current_move.active
	hitbox_debug.visible = show
	if show:
		var off := current_move.hitbox_offset
		off.x *= float(facing)
		hitbox_debug.global_position = global_position + off
		hitbox_debug.scale = current_move.hitbox_size


func _set_state(s: State) -> void:
	if state == State.ATTACK and s != State.ATTACK:
		chain_index = 0
		veil_strike = false
	state = s
	frame_in_state = 0
	state_changed.emit(int(s))


func _set_state_if(s: State) -> void:
	if state != s:
		_set_state(s)
