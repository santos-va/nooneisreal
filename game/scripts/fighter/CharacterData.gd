class_name CharacterData
extends Resource
## Everything that makes a fighter a specific character. Numbers are design data owned by
## T5 Арес; art references by T6 Аполлон. One page per character: docs/Characters/<Name>.md.

@export var id: String = "choko"
@export var display_name: String = "CHOKO"
@export_multiline var tagline: String = ""
@export var max_hp: float = 1000.0
@export var walk_speed: float = 5.5
@export var back_walk_speed: float = 4.2
@export var dash_speed: float = 13.0
@export var dash_frames: int = 12
@export var jump_velocity: float = 11.0
@export var air_control: float = 0.6
@export var weight: float = 1.0                  # scales knockback received (lighter flies further)
## 0…1, how steadily the fighter stands on water (river stage). Lower = more sway, slower walk,
## stumbles on weaker swells. PLACEHOLDER; Santos 2026-10-03: Choko and Skea both 0.85.
@export_range(0.0, 1.0) var water_balance: float = 0.85

@export_group("Placeholder rig & HUD colors")
@export var primary_color: Color = Color(0.72, 0.38, 0.2)
@export var secondary_color: Color = Color(0.32, 0.36, 0.45)
@export var accent_color: Color = Color(0.2, 0.75, 0.45)
@export var skin_color: Color = Color(0.86, 0.68, 0.55)
@export var hair_color: Color = Color(0.16, 0.1, 0.08)
@export var weapon_kind: String = "none"          # none | sword | fans | staff

@export_group("Art references")
@export var portrait_path: String = ""
@export var card_path: String = ""

@export_group("Moves")
@export var light: MoveData
@export var heavy: MoveData
@export var crouch_light: MoveData
@export var air_light: MoveData
@export var skill1: MoveData
@export var skill2: MoveData
@export var ultimate: MoveData
@export var throw_move: MoveData

@export_group("Signature movement (dash slot)")
@export var dash_style: String = "dash"           # dash | flash (Skea: short blink through the opponent)
@export var dash_charges: int = 0                 # 0 = unlimited
@export var dash_recharge: float = 4.5            # seconds after the last use until all charges return
@export var flash_distance: float = 3.6

@export_group("VFX palette")
@export var vfx_primary: Color = Color(0.2, 0.9, 0.55)
@export var vfx_secondary: Color = Color(0.55, 0.75, 1.0)

@export_group("Grapple")
@export var grapple_charges: int = 3
@export var grapple_cooldown: float = 3.0
@export var grapple_regen_all_at_once: bool = true   # true: 3 uses → 3 s → all back. false: one charge per 3 s.
@export var grapple_range: float = 14.0
## Free movement (GameState.free_move): half-angle of the aim cone (yaw only) around the stick, or
## around the fighter's forward when the stick is neutral. 30° — ДИЗАЙН, T5 Арес, docs/GDD/04-Grapple-System.md.
@export var grapple_cone_deg: float = 30.0
## Free movement (ДИЗАЙН, T5 Арес, docs/GDD/02-Combat-System.md § Вільний 3D-рух):
@export var block_arc_deg: float = 70.0       # guard holds while the attacker is within ± this of the gaze
@export var circle_speed_mult: float = 0.8    # circling speed = this × walk_speed

@export_group("Passive")
@export var passive_id: String = ""
@export_multiline var passive_description: String = ""


func moves() -> Dictionary:
	return {
		"light": light, "heavy": heavy, "crouch_light": crouch_light, "air_light": air_light,
		"skill1": skill1, "skill2": skill2, "ultimate": ultimate, "throw": throw_move,
	}
