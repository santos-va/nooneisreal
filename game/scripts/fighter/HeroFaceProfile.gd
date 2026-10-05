class_name HeroFaceProfile
extends Resource
## Calibrated regions of the original 2048px atlas. Presentation values are art placeholders.
@export var atlas_size: float = 2048.0
@export var eye_left: Vector4
@export var eye_right: Vector4
@export var axis_left: Vector2
@export var axis_right: Vector2
@export var skin_side: Vector2 = Vector2(-1, -1)
@export_range(1.0, 12.0) var blink_interval: float = 4.0
@export_range(0.08, 0.3) var blink_seconds: float = 0.16
@export_range(0.0, 0.8) var focus_close: float = 0.30
@export var ink_left: Vector2
@export var ink_right: Vector2
@export var mouth_left: Vector4
@export var mouth_right: Vector4
@export var mouth_axis_left: Vector2 = Vector2.RIGHT
@export var mouth_axis_right: Vector2 = Vector2.RIGHT
@export var cheek_left: Vector2
@export var cheek_right: Vector2
@export var brow_left: Vector4 = Vector4.ZERO
@export var brow_right: Vector4 = Vector4.ZERO
@export var eye_skin_left: Vector2
@export var eye_skin_right: Vector2

# Five original-atlas landmarks per lid, ordered from the same physical corner.
# Upper/lower are anatomical, independent of mirrored UV-island orientation.
@export var upper_left: PackedVector2Array
@export var lower_left: PackedVector2Array
@export var upper_right: PackedVector2Array
@export var lower_right: PackedVector2Array
