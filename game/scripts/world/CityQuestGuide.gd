class_name CityQuestGuide
extends PanelContainer
## A bearing to a quest destination, not a route or an interactable grapple target.
var title_label: Label
var bearing_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = 480
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.07, 0.94)
	style.border_color = Color("dcb275")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color("f5d5a3"))
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title_label)
	bearing_label = Label.new()
	bearing_label.add_theme_font_size_override("font_size", 26)
	bearing_label.add_theme_color_override("font_color", Color("f6ebdb"))
	bearing_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(bearing_label)
	hide()


func show_target(target: Dictionary, origin: Vector3, camera: Camera3D, canvas_size: Vector2) -> void:
	if target.is_empty() or camera == null or not target.get("position") is Vector3:
		hide()
		return
	var point: Vector3 = target.position
	if not point.is_finite() or not origin.is_finite():
		hide()
		return
	title_label.text = "QUEST · " + str(target.get("title", "Destination"))
	bearing_label.text = bearing_text(point, origin, camera.global_basis)
	# Logical canvas size follows the HUD, including scaled 720p/540p windows.
	position = Vector2((canvas_size.x - 480.0) * 0.5, 20)
	size.x = 480
	show()


static func bearing_text(point: Vector3, origin: Vector3, camera_basis: Basis) -> String:
	var delta := point - origin
	# Camera-horizontal basis keeps directions stable when looking up at rooftops.
	var forward := -camera_basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP)
	var angle := rad_to_deg(atan2(delta.dot(right), delta.dot(forward)))
	# PLACEHOLDER presentation sectors and vertical threshold; no physical movement logic.
	# The built-in font has no arrows (plan 2026-10-08-Thirst-Substances-Icons step 3): `‹ ›` point to the side the turn
	# goes, the word carries the rest.
	var bearing := "Ahead"
	if absf(angle) >= 150.0:
		bearing = "‹ Behind" if angle < 0.0 else "Behind ›"
	elif angle > 45.0:
		bearing = "Right ›"
	elif angle < -45.0:
		bearing = "‹ Left"
	elif angle > 20.0:
		bearing = "Ahead ›"
	elif angle < -20.0:
		bearing = "‹ Ahead"
	if delta.length() < 2.0:
		bearing = "Nearby"
	var height := " · Higher" if delta.y > 2.0 else (" · Lower" if delta.y < -2.0 else "")
	return "%s · %.0f m%s" % [bearing, delta.length(), height]
