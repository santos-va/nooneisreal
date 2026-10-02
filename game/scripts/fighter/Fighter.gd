class_name Fighter
extends CharacterBody3D
## One fighter: deterministic state machine (60 Hz physics), movement, attacks, hit reception,
## meter, grapple hand-off and ragdoll hand-off. Visuals are derived from state by RigAnimator.
## Physics never decides a hit: hit/hurt boxes are kinematic queries on the tick (docs/GDD/02-Combat-System.md).

signal hp_changed(hp: float, max_hp: float)
signal meter_changed(meter: float, max_meter: float)
signal state_changed(new_state: int)
signal hit_landed(attacker: Fighter, victim: Fighter, move: MoveData, blocked: bool)
signal knocked_out(fighter: Fighter)
signal grapple_changed(charges: int, cooldown_left: float, max_charges: int)
signal cooldowns_changed(cooldowns: Dictionary)
signal move_started(fighter: Fighter, move: MoveData)

enum State { INTRO, IDLE, WALK, CROUCH, JUMP, DASH, ATTACK, BLOCK, HITSTUN, BLOCKSTUN, LAUNCHED, KNOCKDOWN, GETUP, GRAPPLE, KO }

const GRAVITY := 24.0
const ARENA_HALF_WIDTH := 12.5
const MIN_SEPARATION := 0.95
const KNOCKDOWN_FRAMES := 40
const GETUP_FRAMES := 18
const MAX_METER := 100.0
const COMBO_SCALING := 0.1
const HIT_FRICTION := 30.0

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
var combo_count: int = 0          # hits taken in the current combo (damage scaling)
var chain_index: int = 0          # light-string position (visual alternation)
var cooldowns: Dictionary = {"skill1": 0.0, "skill2": 0.0}
var control_locked: bool = true
var invulnerable_frames: int = 0
var crouching: bool = false
var dash_dir: int = 1
var dash_frames_left: int = 0
var airborne_attack: bool = false
var pull_pending: bool = false
var stats: Dictionary = {"hits": 0, "blocks": 0, "grapples": 0, "ragdolls": 0}

@onready var animator: RigAnimator = $Rig
@onready var hurtbox: Area3D = $Hurtbox
@onready var hurt_shape: CollisionShape3D = $Hurtbox/Shape
@onready var hitbox_debug: MeshInstance3D = $HitboxDebug
@onready var grapple: GrappleHook = $GrappleHook

var _ragdoll: Ragdoll = null
var _brain: CpuBrain = null
var _hit_query := PhysicsShapeQueryParameters3D.new()
var _hit_box := BoxShape3D.new()


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
	if is_cpu:
		_brain = CpuBrain.new()
		_brain.fighter = self
		add_child(_brain)
	hitbox_debug.visible = false
	hp_changed.emit(hp, data.max_hp)
	meter_changed.emit(meter, MAX_METER)


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
	animator.visible = true
	hurt_shape.disabled = false
	grapple.reset()
	_set_state(State.INTRO)
	hp_changed.emit(hp, data.max_hp)
	meter_changed.emit(meter, MAX_METER)
	cooldowns = {"skill1": 0.0, "skill2": 0.0}
	cooldowns_changed.emit(cooldowns)


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
	return state in [State.IDLE, State.WALK, State.CROUCH, State.BLOCK] and not control_locked


# --- main tick ---------------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	frame_in_state += 1
	_tick_cooldowns(delta)
	grapple.tick_regen(delta, state == State.GRAPPLE)
	if hitstop_frames > 0:
		hitstop_frames -= 1
		animator.tick(delta, self, true)
		return
	if invulnerable_frames > 0:
		invulnerable_frames -= 1
	var intent := _read_intent()
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


func _skill_ready(slot: String) -> bool:
	var m: MoveData = data.skill1 if slot == "skill1" else data.skill2
	if m == null:
		return false
	if cooldowns.get(slot, 0.0) > 0.0:
		return false
	return meter >= m.meter_cost


# --- ground / air / dash ---------------------------------------------------------------------
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
		velocity.x = intent.axis * data.walk_speed
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
		var speed := data.walk_speed if forward else data.back_walk_speed
		_set_state_if(State.WALK)
		_ground_physics(delta, intent.axis * speed)
		return
	_set_state_if(State.IDLE)
	_ground_physics(delta, 0.0)


func _ground_physics(delta: float, vx: float) -> void:
	velocity.x = vx
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0


func _tick_air(delta: float, intent: Dictionary) -> void:
	if _try_grapple(false):
		return
	if (_pressed("light") or _pressed("heavy")) and data.air_light:
		_start_move(data.air_light)
		return
	velocity.x = move_toward(velocity.x, intent.axis * data.walk_speed, data.air_control * data.walk_speed * 3.0 * delta)
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0
		Sfx.play("land", -14)
		_update_facing()
		_set_state(State.IDLE)


func _start_dash(axis: float) -> void:
	dash_dir = int(signf(axis)) if absf(axis) > 0.1 else facing
	dash_frames_left = data.dash_frames
	if dash_dir != facing:
		invulnerable_frames = 6   # backdash i-frames
	_set_state(State.DASH)
	Sfx.play("whoosh", -6)


func _tick_dash(delta: float) -> void:
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


# --- attacks ------------------------------------------------------------------------------------
func _start_move(m: MoveData, slot: String = "") -> void:
	if m == null:
		return
	if m.meter_cost > 0.0:
		meter = maxf(0.0, meter - m.meter_cost)
		meter_changed.emit(meter, MAX_METER)
	if m.cooldown > 0.0 and slot in ["skill1", "skill2"]:
		cooldowns[slot] = m.cooldown
		cooldowns_changed.emit(cooldowns)
	if state != State.ATTACK:
		chain_index = 0
	current_move = m
	current_slot = slot
	move_frame = 0
	has_hit = false
	airborne_attack = not is_on_floor()
	_set_state(State.ATTACK)
	move_started.emit(self, m)
	if m.kind == MoveData.Kind.ULTIMATE:
		Sfx.play("ultimate")


func _tick_attack(delta: float) -> void:
	var m := current_move
	if m == null:
		_set_state(State.IDLE)
		return
	# movement during the move
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
	if airborne_attack and is_on_floor():
		velocity = Vector3.ZERO
		current_move = null
		_set_state(State.IDLE)
		return
	# active window
	if move_frame == m.startup:
		Sfx.play(m.sfx_whiff, -4)
		if pull_pending:
			pull_pending = false
			if opponent:
				grapple.pull_enemy(opponent)
	if move_frame >= m.startup and move_frame < m.startup + m.active and not has_hit and m.damage >= 0.0 and m.anim != "throw":
		_check_hit(m)
	# cancels (only after a hit connected)
	if has_hit and move_frame >= m.startup + m.active:
		if _try_cancel(m):
			return
	move_frame += 1
	if move_frame >= m.total_frames():
		current_move = null
		if airborne_attack and not is_on_floor():
			_set_state(State.JUMP)
		else:
			_set_state(State.IDLE)


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
	var blocking := (state == State.BLOCK or state == State.BLOCKSTUN) and facing == -attacker.facing and m.kind != MoveData.Kind.THROW
	if blocking:
		hp = maxf(1.0, hp - m.chip_damage)
		stun_frames = m.blockstun
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
		return
	var scale := maxf(0.35, 1.0 - COMBO_SCALING * float(combo_count))
	var dmg := m.damage * scale
	hp -= dmg
	combo_count += 1
	attacker.stats.hits += 1
	attacker.meter = minf(MAX_METER, attacker.meter + m.meter_gain_hit)
	meter = minf(MAX_METER, meter + m.meter_gain_hit * 0.5)
	animator.flash()
	Sfx.play(m.sfx_hit)
	_apply_hitstop(attacker, m.hitstop)
	hp_changed.emit(hp, data.max_hp)
	meter_changed.emit(meter, MAX_METER)
	attacker.meter_changed.emit(attacker.meter, MAX_METER)
	hit_landed.emit(attacker, self, m, false)
	if hp <= 0.0:
		_die(attacker, m)
		return
	var kb := Vector3(float(attacker.facing) * m.knockback.x, m.knockback.y, 0.0) / maxf(0.2, data.weight)
	if m.effect == "freeze":
		stun_frames = maxi(m.hitstun, 45)
		velocity = Vector3.ZERO
		_set_state(State.HITSTUN)
		return
	if m.launcher or m.knockdown or not is_on_floor():
		_enter_ragdoll(kb * m.ragdoll_impulse)
		return
	stun_frames = m.hitstun
	velocity.x = kb.x
	velocity.y = kb.y
	animator.flinch(Vector3(float(attacker.facing), 0, 0), dmg, facing)
	_set_state(State.HITSTUN)


## Grapple "get over here": pulled to target_x and stunned. No damage; the follow-up is the reward.
func get_pulled(target_x: float, stun: int) -> void:
	if state == State.KO or state == State.LAUNCHED:
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
	if is_on_floor():
		velocity.y = 0.0
	if stun_frames <= 0:
		combo_count = 0
		_update_facing()
		_set_state(State.IDLE if is_on_floor() else State.JUMP)


func _tick_blockstun(delta: float, intent: Dictionary) -> void:
	stun_frames -= 1
	velocity.x = move_toward(velocity.x, 0.0, HIT_FRICTION * delta)
	velocity.y -= GRAVITY * delta
	move_and_slide()
	if stun_frames <= 0:
		_set_state(State.BLOCK if intent.block else State.IDLE)


# --- ragdoll / knockdown / KO ----------------------------------------------------------------
func _enter_ragdoll(impulse: Vector3) -> void:
	velocity = Vector3.ZERO
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
		animator.visible = true
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
	if frame_in_state >= GETUP_FRAMES:
		_set_state(State.IDLE)


func _die(attacker: Fighter, m: MoveData) -> void:
	hp = 0.0
	hp_changed.emit(hp, data.max_hp)
	control_locked = true
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
		_set_state(State.JUMP if not is_on_floor() else State.IDLE)


func _on_grapple_changed(charges: int, cooldown_left: float, max_charges: int) -> void:
	grapple_changed.emit(charges, cooldown_left, max_charges)


# --- helpers -----------------------------------------------------------------------------------
func _update_facing() -> void:
	if opponent == null:
		return
	var dx := opponent.global_position.x - global_position.x
	if absf(dx) > 0.05:
		facing = 1 if dx > 0.0 else -1


func _post_move() -> void:
	global_position.x = clampf(global_position.x, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH)
	global_position.z = 0.0
	if global_position.y < 0.0:
		global_position.y = 0.0
	# push-box separation (physics does not resolve fighter vs fighter)
	if opponent != null and state != State.LAUNCHED and state != State.KO and opponent.state != State.LAUNCHED and opponent.state != State.KO:
		var dx := global_position.x - opponent.global_position.x
		var both_grounded := is_on_floor() and opponent.is_on_floor()
		if absf(dx) < MIN_SEPARATION and both_grounded:
			var push := (MIN_SEPARATION - absf(dx)) * 0.5
			var dir := 1.0 if dx >= 0.0 else -1.0
			if dx == 0.0:
				dir = -float(facing)
			global_position.x = clampf(global_position.x + dir * push, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH)
			opponent.global_position.x = clampf(opponent.global_position.x - dir * push, -ARENA_HALF_WIDTH, ARENA_HALF_WIDTH)


func _update_hitbox_debug() -> void:
	var show := GameState.show_hitboxes and state == State.ATTACK and current_move != null \
		and move_frame >= current_move.startup and move_frame < current_move.startup + current_move.active
	hitbox_debug.visible = show
	if show:
		var off := current_move.hitbox_offset
		off.x *= float(facing)
		hitbox_debug.global_position = global_position + off
		hitbox_debug.scale = current_move.hitbox_size


func _set_state(s: State) -> void:
	if state == State.ATTACK and s != State.ATTACK:
		chain_index = 0
	state = s
	frame_in_state = 0
	state_changed.emit(int(s))


func _set_state_if(s: State) -> void:
	if state != s:
		_set_state(s)
