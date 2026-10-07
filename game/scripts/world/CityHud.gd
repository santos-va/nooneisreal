class_name CityHud
extends CanvasLayer
## Exploration overlay with its own pause/input owner; no combat HUD state is reused.
signal restart_requested
signal exit_requested

var _lower_story: CityLowerStory
var _story: CityStory
var _story_world: Node
var _story_prompt: String = ""
var story_button: Button
var onboarding: CityOnboarding
var paused_ui: bool = false
var pause_panel: Control
var resume_button: Button
var skip_button: Button
var restart_button: Button
var exit_button: Button
var pause_button: Button
var objective_label: Label
var hint_label: Label
var resource_label: Label
var _status_card: PanelContainer
var _objective_title: Label
var _root: Control
var _rope_text: String = ""
var _dash_text: String = ""
var _player: Fighter
var _aim_cue: Label
var _stamina_bar: ProgressBar
var _stamina_text: String = ""
var _progress: Node
var _quest_card: PanelContainer
var _quest_title: Label
var _quest_hint: Label
var _quest_totals: Label
var _journal: Label
var quest_buttons: Dictionary = {}
var untrack_button: Button
var _journal_list: VBoxContainer
var _journal_scroll: ScrollContainer
var _quest_guide: CityQuestGuide
var _quest_director: Node
var _guide_elapsed := 0.0
var _journey: Node
var resume_location_label: Label
## Plan 2026-10-07-First-Enemy-Lethal-Fight step 0 (T8 spec): a sealed skill press is answered in the
## bottom hint line. PLACEHOLDER seconds pending T8/T6 review.
const SEALED_HINT := "SKILLS SEALED IN THE CITY · Skills, ultimate and enemy hook work in fights only"
const SEALED_HINT_SECONDS: float = 2.0
const SEALED_HINT_INTERVAL: float = 6.0
var _sealed_left: float = 0.0
var _sealed_since: float = INF
## The shared COMFORT & CONTROLS modal. CityHud stays the only pause owner; the modal only adds its
## own input token, exactly as in the duel pause.
var comfort_button: Button
var comfort: ComfortPanel


func setup(model: CityOnboarding) -> void:
	if onboarding != null and onboarding.changed.is_connected(_refresh):
		onboarding.changed.disconnect(_refresh)
	onboarding = model
	onboarding.changed.connect(_refresh)
	_refresh()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var card := PanelContainer.new()
	_status_card = card
	card.position = Vector2(18, 18)
	card.custom_minimum_size.x = 390
	card.add_theme_stylebox_override("panel", _panel_style())
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)

	_objective_title = _label("CRONSHIFT", 18)
	column.add_child(_objective_title)
	objective_label = _label("", 20)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.x = 380
	column.add_child(objective_label)
	resource_label = _label("", 18)
	resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(resource_label)
	_stamina_bar = ProgressBar.new()
	_stamina_bar.max_value = 1.0
	_stamina_bar.show_percentage = false
	_stamina_bar.custom_minimum_size.y = 5
	_stamina_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_stamina_bar)
	_aim_cue = _label("", 20)
	_aim_cue.add_theme_color_override("font_outline_color", Color("171322"))
	_aim_cue.add_theme_constant_override("outline_size", 6)
	_aim_cue.hide()
	_root.add_child(_aim_cue)
	pause_button = _button("Esc · Help", func(): set_paused(true))
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.add_theme_font_size_override("font_size", 20)
	pause_button.custom_minimum_size.y = 34
	pause_button.position = Vector2(-158, 18)
	pause_button.size = Vector2(140, 34)
	_root.add_child(pause_button)
	hint_label = _label("", 18)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_color_override("font_outline_color", Color("171322"))
	hint_label.add_theme_constant_override("outline_size", 6)
	hint_label.hide()
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_left = 24
	hint_label.offset_right = -24
	hint_label.offset_top = -58
	hint_label.offset_bottom = -14
	_root.add_child(hint_label)
	_quest_guide = CityQuestGuide.new()
	_root.add_child(_quest_guide)
	_build_quest()
	_build_pause()
	_refresh()


func _build_pause() -> void:
	pause_panel = Control.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(pause_panel)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.035, 0.055, 0.96)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 1000
	column.add_theme_constant_override("separation", 8)
	center.add_child(column)
	column.add_child(_label("CRONSHIFT  /  JOURNEY PAUSED", 36))
	column.add_child(_label(BuildInfo.label(), 18))
	resume_location_label = _label("Continue from safe district checkpoints.", 22)
	column.add_child(resume_location_label)
	var help := _label(exploration_help(), 22)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(help)
	var journal_scroll := ScrollContainer.new()
	_journal_scroll = journal_scroll
	journal_scroll.follow_focus = true
	journal_scroll.custom_minimum_size.y = 110 # was 130; the sealed-skills help line keeps the pause inside 900 px
	journal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(journal_scroll)
	_journal = _label("Meet residents to discover district tasks.", 22)
	_journal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_journal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal.focus_mode = Control.FOCUS_ALL
	_journal_list = VBoxContainer.new()
	_journal_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_list.add_theme_constant_override("separation", 6)
	journal_scroll.add_child(_journal_list)
	_journal_list.add_child(_journal)
	_journal.gui_input.connect(func(event: InputEvent):
		if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
			journal_scroll.scroll_vertical += 32 if event.is_action_pressed("ui_down") else -32
			_journal.accept_event())
	untrack_button = _button("TURN OFF QUEST GUIDE", func(): _track_quest(""))
	untrack_button.add_theme_font_size_override("font_size", 24)
	untrack_button.custom_minimum_size.y = 44
	_journal_list.add_child(untrack_button)
	untrack_button.focus_entered.connect(func(): _journal_scroll.ensure_control_visible(untrack_button))
	resume_button = _button("RESUME", func(): set_paused(false))
	comfort_button = _button("COMFORT & CONTROLS", _open_comfort)
	skip_button = _button("SKIP GUIDANCE · EXPLORE FREELY", _skip)
	restart_button = _button("RESTART WALK & GUIDANCE · KEEP PROGRESS", _restart)
	exit_button = _button("RETURN TO MAIN MENU", _exit)
	# RESUME and COMFORT & CONTROLS share the first row, so the pause still fits a 16:9 900 px canvas.
	var first_row := HBoxContainer.new()
	first_row.add_theme_constant_override("separation", 8)
	column.add_child(first_row)
	for button: Button in [resume_button, comfort_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		first_row.add_child(button)
	var buttons: Array[Control] = [skip_button, restart_button, exit_button]
	for button: Control in buttons:
		column.add_child(button)
	_rebuild_pause_focus()
	pause_panel.hide()
	comfort = ComfortPanel.new()
	_root.add_child(comfort)
	comfort.closed.connect(_on_comfort_closed)


func _open_comfort() -> void:
	if not paused_ui:
		return
	pause_panel.hide()
	comfort.show_panel(comfort_button, exploration_help())


func _on_comfort_closed() -> void:
	# Closing the modal returns to the same pause; leaving the pause closes the modal first.
	if paused_ui:
		pause_panel.show()
		comfort_button.grab_focus()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.06, 0.08, 0.9)
	style.border_color = Color("557a7c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func _build_quest() -> void:
	_quest_card = PanelContainer.new()
	_quest_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_quest_card.position = Vector2(-418, 68)
	_quest_card.custom_minimum_size.x = 400
	_quest_card.add_theme_stylebox_override("panel", _panel_style())
	_quest_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_quest_card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	_quest_card.add_child(column)
	var heading := _label("DISTRICT JOURNAL", 17)
	heading.add_theme_color_override("font_color", Color("7bc9c6"))
	column.add_child(heading)
	_quest_title = _label("", 23)
	_quest_hint = _label("", 20)
	for label: Label in [_quest_title, _quest_hint]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 378
		column.add_child(label)
	_quest_totals = _label("", 18)
	_quest_totals.add_theme_color_override("font_color", Color("b9c9ce"))
	column.add_child(_quest_totals)
	_quest_card.hide()


func bind_story(model: CityStory, world: Node) -> void:
	_story = model
	_story_world = world
	_story.changed.connect(_refresh_progress)
	story_button = _button("", _track_story)
	story_button.add_theme_font_size_override("font_size", 23)
	story_button.custom_minimum_size.y = 44
	_journal_list.add_child(story_button)
	story_button.focus_entered.connect(func(): _journal_scroll.ensure_control_visible(story_button))
	_refresh_progress()

func bind_lower_story(model: CityLowerStory) -> void:
	_lower_story = model
	_lower_story.changed.connect(_refresh_progress)
	_refresh_progress()

func _active_story() -> Node:
	if is_instance_valid(_story_world) and _story_world.has_method("active_episode"):
		return _story_world.active_episode()
	return _story if is_instance_valid(_story) and _story.stage() != "completed" else null

func _story_leads() -> bool:
	var active: Node = _active_story()
	if active == _lower_story and is_instance_valid(active):
		return is_instance_valid(_progress) and _progress.tracking_mode() == "auto"
	return is_instance_valid(active) and (active.guide_selected() or (is_instance_valid(_progress) and _progress.tracking_mode() == "auto"))

func _track_story() -> void:
	var active: Node = _active_story()
	if is_instance_valid(active):
		if active == _lower_story and is_instance_valid(_progress):
			_progress.track_automatically()
		active.select_guide(true)

func set_story_prompt(text: String) -> void:
	_story_prompt = text

func bind_progress(model: Node) -> void:
	if is_instance_valid(_progress) and _progress.changed.is_connected(_refresh_progress):
		_progress.changed.disconnect(_refresh_progress)
	_progress = model
	_progress.changed.connect(_refresh_progress)
	_refresh_progress()


func _refresh_progress() -> void:
	if not is_instance_valid(_progress) or _quest_title == null:
		return
	var summary: Dictionary = _progress.summary()
	_quest_title.text = str(summary.get("active_title", "Explore the district"))
	_quest_hint.text = str(summary.get("active_hint", "Talk to nearby residents."))
	if _story_leads():
		_quest_title.text = _active_story().text("title")
		_quest_hint.text = _active_story().current_hint()
	_quest_totals.text = "%d / %d district tasks · %d credits" % [summary.get("completed", 0), summary.get("total", 0), summary.get("credits", 0)]
	if not summary.get("save_ok", true):
		_quest_totals.text += " · Save unavailable"
	if is_instance_valid(_story) and not _story.save_ok:
		_quest_totals.text += " · Сюжет не збережено"
	if is_instance_valid(_lower_story) and not _lower_story.save_ok:
		_quest_totals.text += " · Продовження не збережено"
	_quest_card.show()
	_refresh_journal()
	_refresh_quest_guide()


func _refresh_journal() -> void:
	if _journal == null or not is_instance_valid(_progress):
		return
	var visible_ids: Array[String] = []
	var entries := PackedStringArray()
	var selected: String = str(_progress.tracked_quest_id()) if _progress.has_method("tracked_quest_id") else ""
	for entry: Dictionary in _progress.journal():
		var state: String = str(entry.get("status", "locked"))
		if state == "locked":
			continue
		var id: String = str(entry.get("id", ""))
		var caption := "%s  (%d / %d)" % [entry.get("title", ""), entry.get("progress", 0), entry.get("target", 1)]
		if state in ["active", "ready"] and not id.is_empty():
			visible_ids.append(id)
			if not quest_buttons.has(id):
				var button := _button("", _track_quest.bind(id))
				button.add_theme_font_size_override("font_size", 23)
				button.custom_minimum_size.y = 44
				button.alignment = HORIZONTAL_ALIGNMENT_LEFT
				button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				_journal_list.add_child(button)
				button.focus_entered.connect(func(): _journal_scroll.ensure_control_visible(button))
				quest_buttons[id] = button
			var button: Button = quest_buttons[id]
			button.text = ("✓ TRACKING · " if id == selected and not _story_leads() else "TRACK · ") + caption
			button.tooltip_text = str(entry.get("hint", ""))
			button.show()
		else:
			entries.append("%s · %s" % [state.to_upper(), caption])
	for id: String in quest_buttons:
		if id not in visible_ids:
			var button: Button = quest_buttons[id]
			if button.has_focus():
				resume_button.grab_focus()
			button.hide()
	if is_instance_valid(_story):
		entries.insert(0, _story.journal_text())
		var active: Node = _active_story()
		story_button.text = ("✓ СЮЖЕТ · " if _story_leads() else "ВІДСТЕЖУВАТИ СЮЖЕТ · ") + (active.text("title") if is_instance_valid(active) else "")
		if not is_instance_valid(active) and story_button.has_focus():
			resume_button.grab_focus()
		story_button.visible = is_instance_valid(active)
	if is_instance_valid(_lower_story) and not _lower_story.journal_text().is_empty():
		entries.insert(0, _lower_story.journal_text())
	_journal.text = "\n\n".join(entries) if not entries.is_empty() else "Choose an accepted task to show its destination."
	untrack_button.text = "QUEST GUIDE OFF ✓" if selected.is_empty() and not _story_leads() else "TURN OFF QUEST GUIDE"
	untrack_button.visible = _progress.has_method("track_quest")
	# Accepted tasks first, then opt-out, then non-interactive available/completed entries.
	var at := 0
	for id: String in visible_ids:
		_journal_list.move_child(quest_buttons[id], at)
		at += 1
	_journal_list.move_child(untrack_button, at)
	_journal_list.move_child(_journal, _journal_list.get_child_count() - 1)
	_rebuild_pause_focus()


func _track_quest(id: String) -> void:
	if is_instance_valid(_story) and _story.stage() != "completed":
		_story.select_guide(false)
	if is_instance_valid(_lower_story):
		_lower_story.select_guide(false)
	if is_instance_valid(_progress) and _progress.has_method("track_quest"):
		_progress.track_quest(id)


func _rebuild_pause_focus() -> void:
	if resume_button == null:
		return
	var controls: Array[Control] = [resume_button, comfort_button]
	for button: Button in [skip_button, restart_button, exit_button]:
		if not button.disabled:
			controls.append(button)
	for child: Node in _journal_list.get_children():
		if child is Button and child.visible:
			controls.append(child)
	controls.append(_journal)
	_journal.focus_neighbor_left = _journal.get_path_to(resume_button)
	_journal.focus_neighbor_right = _journal.get_path_to(resume_button)
	for i: int in controls.size():
		controls[i].focus_neighbor_top = controls[i].get_path_to(controls[posmod(i - 1, controls.size())])
		controls[i].focus_neighbor_bottom = controls[i].get_path_to(controls[(i + 1) % controls.size()])
		controls[i].focus_previous = controls[i].focus_neighbor_top
		controls[i].focus_next = controls[i].focus_neighbor_bottom
	# Tab order stays resume -> comfort -> rest; up/down treat the shared first row as one row.
	var below: Control = controls[2 % controls.size()]
	var above: Control = controls[controls.size() - 1]
	for button: Button in [resume_button, comfort_button]:
		button.focus_neighbor_top = button.get_path_to(above)
		button.focus_neighbor_bottom = button.get_path_to(below)
	below.focus_neighbor_top = below.get_path_to(resume_button)
	above.focus_neighbor_bottom = above.get_path_to(resume_button)
	resume_button.focus_neighbor_right = resume_button.get_path_to(comfort_button)
	resume_button.focus_neighbor_left = resume_button.get_path_to(comfort_button)
	comfort_button.focus_neighbor_left = comfort_button.get_path_to(resume_button)
	comfort_button.focus_neighbor_right = comfort_button.get_path_to(resume_button)


func bind_journey(model: Node) -> void:
	if is_instance_valid(_journey) and _journey.changed.is_connected(_refresh_journey):
		_journey.changed.disconnect(_refresh_journey)
	_journey = model
	_journey.changed.connect(_refresh_journey)
	_refresh_journey()


func _refresh_journey() -> void:
	if resume_location_label == null or not is_instance_valid(_journey):
		return
	resume_location_label.text = "Continue from: %s · safe checkpoint" % _journey.title()
	if not _journey.save_ok:
		resume_location_label.text = "Return point not saved · " + str(_journey.title())
	resume_location_label.add_theme_color_override("font_color", Color("f5d5a3") if not _journey.save_ok else Color("b9c9ce"))


func bind_quest_context(director: Node) -> void:
	_quest_director = director
	_refresh_quest_guide()


func _refresh_quest_guide() -> void:
	if _quest_guide == null:
		return
	_quest_guide.hide()
	if paused_ui or InputRouter.ui_suppressed() or not is_instance_valid(_player) or not is_instance_valid(_progress):
		return
	if not _progress is CityProgress:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var target: Dictionary = _story_world.story_target() if _story_leads() and is_instance_valid(_story_world) else CityQuestTargets.resolve(_progress, _quest_director, _player.global_position)
	_quest_guide.show_target(target, _player.global_position, camera, _root.size)


func exploration_help() -> String:
	var text := "Move: WASD / left stick · Look: RMB + drag / right stick\n"
	text += "Jump / hold to reel (limited): %s / A · Hook: tap %s / L3 (or Y + LT)\n" % [InputRouter.binding_label(1, "jump", false), InputRouter.binding_label(1, "grapple_parkour", false)]
	text += "Face anchor: hook / transfer · Finite hooks · Reuse rope within 0.70m of hand.\n"
	text += "Ledge: hold jump + move into edge; release, then press jump to climb.\n"
	text += "Skea wall steps: hold jump + move into wall; release to drop.\n"
	text += "Wall kick: near a wall, release jump; move away + press jump. Once per landing.\n"
	text += "Landing roll: hold %s / %s + move into a flat landing after a long drop.\n" % [InputRouter.binding_label(1, "crouch", false), InputRouter.binding_label(1, "crouch", true)]
	text += "Detach: %s / B · Dodge: %s / X · Dash skill: %s / Y + X\n" % [InputRouter.binding_label(1, "grapple_detach", false), InputRouter.binding_label(1, "dodge", false), InputRouter.binding_label(1, "dash", false)]
	text += "Strikes: %s; %s; %s; %s\n" % [InputRouter.binding_label(1, "left_hand", false), InputRouter.binding_label(1, "right_hand", false), InputRouter.binding_label(1, "left_leg", false), InputRouter.binding_label(1, "right_leg", false)]
	text += "Sword: %s / R3 · Talk for tasks: %s / Y + D-pad Down\n" % [InputRouter.binding_label(1, "weapon_swap", false), InputRouter.binding_label(1, "interact", false)]
	text += "Sealed in the city, fights only: skills %s, %s · ultimate %s · enemy hook %s" % [InputRouter.binding_label(1, "skill1", false), InputRouter.binding_label(1, "skill2", false), InputRouter.binding_label(1, "ultimate", false), InputRouter.binding_label(1, "grapple_enemy", false)]
	return text


func set_paused(value: bool) -> void:
	if paused_ui == value:
		return
	paused_ui = value
	if value and hint_label != null:
		hint_label.hide()
	if _quest_guide != null:
		_quest_guide.hide()
	if onboarding != null:
		onboarding.suspended = value
	if value:
		InputRouter.acquire_ui(self)
		get_tree().paused = true
		pause_panel.show()
		pause_button.disabled = true
		resume_button.grab_focus()
	else:
		if comfort != null and comfort.visible:
			comfort.close_panel()
		pause_panel.hide()
		pause_button.disabled = false
		get_tree().paused = false
		InputRouter.release_ui(self)
		get_viewport().gui_release_focus()


func _input(event: InputEvent) -> void:
	if event.is_echo() or (comfort != null and comfort.visible):
		return # The open modal owns Esc / B and returns to this pause itself.
	if event.is_action_pressed("ui_pause") or (paused_ui and event.is_action_pressed("ui_cancel")):
		if not paused_ui and InputRouter.ui_suppressed():
			return
		get_viewport().set_input_as_handled()
		set_paused(not paused_ui)


func _skip() -> void:
	if onboarding != null:
		onboarding.skip()
	set_paused(false)


func _restart() -> void:
	set_paused(false)
	restart_requested.emit()


func _exit() -> void:
	set_paused(false)
	exit_requested.emit()


func _refresh() -> void:
	if onboarding == null or objective_label == null:
		return
	_objective_title.text = "CRONSHIFT"
	var prompts := {
		"move": "Walk · WASD / left stick",
		"look": "Look up · RMB + drag / right stick",
		"jump": "Jump · %s / A" % InputRouter.binding_label(1, "jump", false),
		"rope": "Aim at a lamp · %s / L3 to hook" % InputRouter.binding_label(1, "grapple_parkour", false),
		"explore": "",
	}
	objective_label.text = String(prompts[onboarding.current_id()])
	objective_label.visible = not onboarding.is_complete()
	if skip_button != null:
		skip_button.disabled = onboarding.is_complete()
		_rebuild_pause_focus()


func bind_player(player: Fighter) -> void:
	_player = player
	if player.has_signal("sealed_action"):
		player.sealed_action.connect(_on_sealed_action)
	player.dodge_stamina_changed.connect(_on_stamina)
	_on_stamina(player.dodge_stamina, player.dodge_stamina_max())
	player.grapple_changed.connect(_on_rope)
	player.dash_changed.connect(_on_dash)
	_on_rope(player.grapple.charges, player.grapple.cooldown_left, player.grapple.max_charges)
	_on_dash(player.dash_charges_left, player.dash_recharge_left, player.data.dash_charges)


func _on_rope(charges: int, _cooldown: float, maximum: int) -> void:
	_rope_text = "HOOKS %d / %d" % [charges, maximum]
	if charges == 0:
		_rope_text += " · Reuse rope"
	_refresh_resources()


func _on_dash(charges: int, cooldown: float, maximum: int) -> void:
	_dash_text = "DASH %d / %d" % [charges, maximum]
	if cooldown > 0.0:
		_dash_text += " · %.1fs" % cooldown
	_refresh_resources()


func _refresh_resources() -> void:
	if resource_label != null:
		resource_label.text = _rope_text + " · " + _stamina_text + "\n" + _dash_text


func _on_stamina(value: float, maximum: float) -> void:
	_stamina_text = "STAMINA %d%%" % roundi(value / maxf(maximum, 0.001) * 100.0)
	if _stamina_bar != null:
		_stamina_bar.value = value / maxf(maximum, 0.001)
	_refresh_resources()


func _on_sealed_action(_action: String) -> void:
	if paused_ui or InputRouter.ui_suppressed() or _sealed_since < SEALED_HINT_INTERVAL:
		return
	_sealed_left = SEALED_HINT_SECONDS
	_sealed_since = 0.0
	_refresh_traversal_hint()


func _process(_delta: float) -> void:
	if not paused_ui and not InputRouter.ui_suppressed():
		_sealed_left = maxf(0.0, _sealed_left - _delta)
		_sealed_since += _delta
	_refresh_traversal_hint()
	_guide_elapsed += _delta
	if paused_ui or InputRouter.ui_suppressed():
		if _quest_guide != null:
			_quest_guide.hide()
	elif _guide_elapsed >= 0.1:
		_guide_elapsed = 0.0
		_refresh_quest_guide()
	if _aim_cue == null:
		return
	_aim_cue.hide()
	if not is_instance_valid(_player) or paused_ui or InputRouter.ui_suppressed():
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null or not camera.has_meta("harpoon_aim"):
		return
	var helper: HarpoonAim = camera.get_meta("harpoon_aim")
	var intent := helper.capture(_player, false, false)
	var point: Vector3 = intent.point
	if camera.is_position_behind(point) or (intent.target_id.is_empty() and not intent.manual):
		return
	var screen := camera.unproject_position(point)
	if not get_viewport().get_visible_rect().has_point(screen):
		return
	var kind: String = intent.get("candidate_kind", "")
	var verb := "GRAB ROPE" if kind == "rope" else ("TRANSFER" if _player.grapple.busy() else "HOOK")
	var binding: String = InputRouter.binding_label(_player.player_index, "grapple_parkour", helper.last_gamepad)
	if kind == "rope" and not intent.get("reachable", true):
		verb = "APPROACH ROPE"
		binding = ""
	_aim_cue.text = "◇ %s%s · %.2fm" % [(binding + " · ") if not binding.is_empty() else "", verb, float(intent.get("contact_distance", (_player.global_position + GrappleHook.HAND).distance_to(point)))]
	_aim_cue.position = _root.get_global_transform_with_canvas().affine_inverse() * screen + Vector2(-18, -32)
	var bounds := get_viewport().get_visible_rect().size
	var extent := _aim_cue.get_minimum_size()
	_aim_cue.position.x = clampf(_aim_cue.position.x, 12.0, maxf(12.0, bounds.x - extent.x - 12.0))
	_aim_cue.position.y = clampf(_aim_cue.position.y, 12.0, maxf(12.0, bounds.y - extent.y - 80.0))
	if _status_card.get_rect().intersects(Rect2(_aim_cue.position, extent)):
		_aim_cue.position.y = _status_card.get_rect().end.y + 8.0
	if _quest_card.visible and _quest_card.get_rect().intersects(Rect2(_aim_cue.position, extent)):
		_aim_cue.position.y = _quest_card.get_rect().end.y + 8.0
	if _quest_guide.visible and _quest_guide.get_rect().intersects(Rect2(_aim_cue.position, extent)):
		_aim_cue.position.y = _quest_guide.get_rect().end.y + 8.0
	_aim_cue.show()


func _refresh_traversal_hint() -> void:
	if hint_label == null:
		return
	hint_label.hide()
	if not is_instance_valid(_player) or paused_ui or InputRouter.ui_suppressed():
		return
	if _sealed_left > 0.0:
		hint_label.text = SEALED_HINT
		hint_label.show()
		return
	if not _story_prompt.is_empty():
		hint_label.text = _story_prompt
		hint_label.show()
		return
	var gamepad := false
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.has_meta("harpoon_aim"):
		var helper: HarpoonAim = camera.get_meta("harpoon_aim")
		gamepad = helper.last_gamepad
	var jump := InputRouter.binding_label(_player.player_index, "jump", gamepad)
	var detach := InputRouter.binding_label(_player.player_index, "grapple_detach", gamepad)
	var parkour: Dictionary = _player.get_meta("parkour_presentation", {})
	match str(parkour.get("phase", "")):
		"hang":
			var grip := "Grip %.1fs · " % maxf(0.0, float(parkour.hold_remaining)) if parkour.has("hold_remaining") else ""
			hint_label.text = "LEDGE · %sRelease, then press %s: climb / + move away: kick · %s: drop" % [grip, jump, detach]
		"mantle":
			hint_label.text = "CLIMBING"
		"wall_run":
			hint_label.text = "WALL STEPS · Hold %s + move into wall · Release to drop" % jump
		"wall_kick":
			hint_label.text = "WALL KICK · Touch down before another kick"
		"landing_roll":
			var crouch := InputRouter.binding_label(_player.player_index, "crouch", gamepad)
			hint_label.text = "LANDING ROLL · Release %s to stop rolling" % crouch
		_:
			if _player.grapple.phase != GrappleHook.Phase.HANG:
				return
			hint_label.text = ("ROPE · Hold %s to reel · Steer to swing · %s to detach" % [jump, detach]) if _player.grapple.reel_remaining() > 0.001 else ("REEL LIMIT · Steer to swing · %s to detach" % detach)
	hint_label.show()


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86))
	return label


func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 56
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(callback)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style := _panel_style()
		style.bg_color = Color("183039") if state != "pressed" else Color("285456")
		style.border_color = Color("e5b178") if state == "focus" else Color("527478")
		style.set_border_width_all(3 if state == "focus" else 1)
		button.add_theme_stylebox_override(state, style)
	return button


func _exit_tree() -> void:
	if paused_ui:
		get_tree().paused = false
	InputRouter.release_ui(self)
	if onboarding != null:
		onboarding.suspended = false
