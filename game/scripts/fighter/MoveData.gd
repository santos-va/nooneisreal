class_name MoveData
extends Resource
## One attack. Frame numbers are physics frames at 60 Hz (docs/GDD/02-Combat-System.md).
## Values marked PLACEHOLDER in data/characters/*.tres are not grounded yet — T5 Арес owns them.

enum Kind { NORMAL, SKILL, ULTIMATE, THROW }

@export var id: String = "light"
@export var display_name: String = "Light"
@export var kind: Kind = Kind.NORMAL
@export var anim: String = "light"            # pose family used by RigAnimator
@export var anim_chain: String = ""           # alternate pose on odd chain hits (jab → elbow)
## C1 mannequin (GameState.skeletal_rig): UAL clip name as in the GLB (e.g. "Sword_Regular_A"), "" = stance only.
## Values come from docs/GDD/02-Combat-System.md § Кліп → удар (T5 Арес, table 4a).
@export var anim_clip: String = ""
## Second in anim_clip with the contact pose; it lands on the first active frame. 0 = not measured: the clip
## spans startup + active (scripts/fighter/SkeletalRig.gd attack_clip_time()).
@export var contact_time: float = 0.0
@export var startup: int = 5
@export var active: int = 3
@export var recovery: int = 10
@export var damage: float = 40.0
@export var chip_damage: float = 0.0
@export var hitstun: int = 14
@export var blockstun: int = 8
@export var hitstop: int = 4
@export var knockback: Vector2 = Vector2(4.0, 0.0)   # x = along attacker facing, y = up (m/s)
@export var launcher: bool = false                    # throws the victim into a physics ragdoll flight
@export var knockdown: bool = false                   # ragdoll on the spot (heavy finishers)
@export var ragdoll_impulse: float = 1.0              # multiplier on knockback when a ragdoll is spawned
@export var hitbox_offset: Vector3 = Vector3(0.9, 1.1, 0.0)   # local, x = forward
@export var hitbox_size: Vector3 = Vector3(1.0, 0.8, 1.0)
@export var meter_gain_hit: float = 8.0
@export var meter_gain_block: float = 3.0
@export var meter_cost: float = 0.0
@export var cooldown: float = 0.0                     # seconds, skills only
@export var forward_step: float = 0.0                 # metres moved forward during startup+active
## Free movement (GameState.free_move): during startup the attack turns toward the opponent by at
## most this many degrees in total; locked from the first active frame. Values per move in
## data/characters/*.tres — ДИЗАЙН, T5 Арес, docs/GDD/02-Combat-System.md § Трекінг атак.
@export var tracking_deg: float = 0.0
## Free movement: extra hitstun when the hit lands outside the victim's guard arc (side/back hit).
## By move class: light 2, heavy/crouch 3, skill/ult 6 — REF VF5 via T5 Арес, docs/GDD/02 § Блок під кутом.
@export var backhit_hitstun_bonus: int = 0
## Skill effect fired at the first active frame (damage = -1 → no hitbox of its own):
##   record · time_stop · sword_storm · kunai_rain · shadow_veil · grimoire
## On-hit effect for synthetic hits: armor_break · bleed · poison
@export var effect: String = ""
@export var can_crit: bool = true                     # Skea weak-point passive may crit this
@export var ignore_scaling: bool = false              # ultimate hits skip combo scaling
@export var cancel_tier: int = 0                      # 0 light, 1 heavy, 2 skill, 3 ultimate — can cancel into higher tier on hit
@export var sfx_hit: String = "hit_light"
@export var sfx_whiff: String = "whoosh"
@export_multiline var description: String = ""


func total_frames() -> int:
	return startup + active + recovery
