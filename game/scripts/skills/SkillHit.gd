class_name SkillHit
extends RefCounted
## Builds the synthetic MoveData that skill effects deliver through Fighter.receive_hit,
## so AoE ticks, ultimate strikes and normals all share one hit pipeline.


static func make(id: String, damage: float, hitstun: int, knockback: Vector2, opts: Dictionary = {}) -> MoveData:
	var m := MoveData.new()
	m.id = id
	m.display_name = id
	m.kind = MoveData.Kind.SKILL
	m.damage = damage
	m.hitstun = hitstun
	m.blockstun = int(opts.get("blockstun", 8))
	m.hitstop = int(opts.get("hitstop", 3))
	m.chip_damage = float(opts.get("chip", damage * 0.12))
	m.knockback = knockback
	m.launcher = bool(opts.get("launcher", false))
	m.knockdown = bool(opts.get("knockdown", false))
	m.ragdoll_impulse = float(opts.get("ragdoll", 1.0))
	m.effect = String(opts.get("effect", ""))
	m.can_crit = bool(opts.get("can_crit", true))
	m.ignore_scaling = bool(opts.get("ignore_scaling", false))
	m.meter_gain_hit = float(opts.get("meter", 3.0))
	m.sfx_hit = String(opts.get("sfx", "hit_light"))
	m.hitbox_offset = Vector3(0.9, 1.1, 0.0)
	m.backhit_hitstun_bonus = int(opts.get("backhit", 6))   # skill/ult class (docs/GDD/02 § Блок під кутом)
	return m


## True while the fighter's skill effects must pause (owner caught in a TIME STOP).
static func paused(owner_f: Fighter) -> bool:
	return owner_f == null or not is_instance_valid(owner_f) or owner_f.frozen_frames > 0
