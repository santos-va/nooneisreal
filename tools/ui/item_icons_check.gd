extends SceneTree
## Plan docs/Plans/2026-10-08-Thirst-Substances-Icons.md step 3 — item icons in the counter rows (T8 06-UI-UX § «Спрага…»
## п. 5, W12, N5) in the real CityWorld (saves off), Choko: Mira's counter and the street pedlar's offer.
## Subject: for every button of a list that has an item icon, the icon stands 32 × 32 logical px left of the text, every
## button's text starts in the same column (a row without an item icon carries a transparent stand-in, never a «?»), the
## words stay whole (full_text untouched, the wrap narrower by the icon), a disabled row still says why in words, and a
## list without icons is exactly as before.
##   I1 Mira's counter: the 5 icons where T6 has an accepted cell, the stand-in for the tea, the pastry, «Назад» and the
##      close button; expand off, icon_max_width 32, gap 10, text left, mipmapped filtering; drawn size 32 × 32;
##   I2 the wrap: every line of a row within panel − 76 − 42; full_text is the counter's own label;
##   I3 a disabled row (0 tokens): the reason in words, the icon dimmed (α ≤ 0.4);
##   I4 the pedlar's offer: beer and cigarette icons, stand-ins for «Ні, дякую», «Піти», the close button;
##   I5 Mira's conversation (no icons): no icon, the old centred text.
## --break=expand|center|blank are negative controls (icons stretched to the button, centred text, no stand-in).
## Sentinel: ITEM_ICONS_COMPLETE checks=N failures=M mutation=<m>; failures print "ITEM_ICONS: ...".
const ICON_PATH := "res://assets/ui/icons/items/icon_item_%s.png"
const COUNTER := {"eat:tea": "", "eat:loaf": "rye_loaf", "eat:crust": "rye_crust", "eat:pickled_apples": "pickled_apples", "eat:uzvar": "uzvar", "eat:eggs": "eggs", "eat:cheese_pastry": "", "back": ""}
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var world: Node
var npc: Node


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ITEM_ICONS: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _buttons(dialogue: Node) -> Array[Button]:
	var list: Array[Button] = []
	for child: Node in dialogue.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			list.append(child)
	return list


func _press(dialogue: Node, prefix: String) -> void:
	for button: Button in _buttons(dialogue):
		if str(button.get_meta("full_text", button.text)).begins_with(prefix) and not button.disabled:
			button.pressed.emit()
			await _ticks(2)
			return


## The negatives act on the product's buttons, as a careless change to NpcDialogue would.
func _break(dialogue: Node) -> void:
	for button: Button in _buttons(dialogue):
		match mutation:
			"expand":
				button.expand_icon = true
			"center":
				button.alignment = HORIZONTAL_ALIGNMENT_CENTER
			"blank":
				if String(button.get_meta("item_icon", "")).is_empty():
					button.icon = null


## The size Button draws its icon at (scene/gui/button.cpp, Godot 4.7): with expand_icon the icon fills the content
## height; then icon_max_width caps the width and the height follows the aspect.
static func icon_box(button: Button) -> Vector2:
	if button.icon == null:
		return Vector2.ZERO
	var size := Vector2(button.icon.get_width(), button.icon.get_height())
	if button.expand_icon:
		var style: StyleBox = button.get_theme_stylebox("normal")
		var content: float = button.size.y - style.get_margin(SIDE_TOP) - style.get_margin(SIDE_BOTTOM)
		size = Vector2(size.x * content / size.y, content)
	var cap: int = button.get_theme_constant("icon_max_width")
	if cap > 0 and size.x > cap:
		size = Vector2(cap, size.y * cap / size.x)
	return size


func _dressed(button: Button, slug: String, where: String) -> void:
	var icon: Texture2D = button.icon
	var real: bool = icon != null and not slug.is_empty() and icon.resource_path == ICON_PATH % slug and String(button.get_meta("item_icon", "")) == slug
	var blank: bool = icon is ImageTexture and slug.is_empty() and icon.get_width() == 32 and icon.get_height() == 32 and _transparent(icon)
	_check(real or blank, "%s «%s»: %s" % [where, button.get_meta("full_text", button.text), ("its icon " + slug) if not slug.is_empty() else "a transparent 32 px stand-in"])
	var box: Vector2 = icon_box(button)
	_check(not button.expand_icon and button.get_theme_constant("icon_max_width") == 32 and button.get_theme_constant("h_separation") == 10 and box == Vector2(32, 32), "%s «%s»: drawn %s (32 × 32), expand %s, gap %d" % [where, button.get_meta("full_text", button.text), box, button.expand_icon, button.get_theme_constant("h_separation")])
	_check(button.alignment == HORIZONTAL_ALIGNMENT_LEFT and button.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT and button.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "%s «%s»: icon and text left, mipmapped filtering" % [where, button.get_meta("full_text", button.text)])


static func _transparent(texture: Texture2D) -> bool:
	var image: Image = texture.get_image()
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				return false
	return true


func _run() -> void:
	await process_frame
	var state: Node = root.get_node("GameState")
	var content: Node = root.get_node("ContentSettings")
	var old_content: String = content.get("storage_path")
	content.call("load_settings", "user://item_icons_content_%d.cfg" % OS.get_process_id())
	content.call("set_drugs_mode", "full")
	state.p1_character = "choko"
	state.set_free_move(true)
	root.get_node("InputRouter").apply_profile("solo", false)
	world = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	npc = world.npc_director
	await _ticks(20)
	var shop: Dictionary = CityPlaces.shops()[0]
	world.player.restart_at(Vector3(shop.worker.x, 0.0, shop.service.z))
	await _ticks(30)
	world.hunger.enable_for_test(4000)
	world.progress.earn_credits(3)
	# I5 first: the conversation itself has no icons.
	_check(npc.open_conversation(0), "Mira talks")
	await _ticks(2)
	var plain: Array[Button] = _buttons(npc.dialogue)
	_check(not plain.is_empty() and plain.all(func(b: Button) -> bool: return b.icon == null and b.alignment == HORIZONTAL_ALIGNMENT_CENTER) and not npc.dialogue.icon_list, "I5 a list without item icons: no icon, centred text as before (%d buttons)" % plain.size())
	await _press(npc.dialogue, "Поїсти")
	_break(npc.dialogue)
	await _ticks(2)
	var rect: Vector2 = root.get_visible_rect().size
	var panel: float = npc.dialogue.panel_width
	var buttons: Array[Button] = _buttons(npc.dialogue)
	var font: Font = buttons[0].get_theme_font("font")
	_check(buttons.size() == COUNTER.size() + 1, "I1 the counter: 7 foods, «Назад», the close button (%d) at %s, panel %.0f" % [buttons.size(), rect, panel])
	for button: Button in buttons:
		var id: String = "close" if button.has_meta("close") else str(button.get_meta("id", ""))
		_dressed(button, String(COUNTER.get(id, "")), "I1")
		var widest: float = 0.0
		for line: String in button.text.split("\n"):
			widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x)
		_check(widest <= panel - 76.0 - 42.0 + 0.01, "I2 «%s»: every line within %.0f px (%.1f)" % [button.get_meta("full_text", button.text), panel - 118.0, widest])
	for entry: Dictionary in world.hunger.foods:
		var row: Button = null
		for button: Button in buttons:
			if str(button.get_meta("id", "")) == "eat:" + String(entry.id):
				row = button
		var label: String = npc.food_label(entry, world.hunger.food_state(String(entry.id)))
		_check(row != null and str(row.get_meta("full_text")).begins_with(label) and row.text.replace("\n", " ") == str(row.get_meta("full_text")), "I2 «%s»: the words whole — full_text is the counter's own label" % label)
	# I3: 0 tokens — the loaf disabled with its reason in words, its icon dimmed.
	npc.dialogue.close()
	await _ticks(2)
	world.progress.spend_credits(world.progress.credits())
	npc.open_conversation(0)
	await _ticks(2)
	await _press(npc.dialogue, "Поїсти")
	var loaf: Button = null
	for button: Button in _buttons(npc.dialogue):
		if str(button.get_meta("id", "")) == "eat:loaf":
			loaf = button
	_check(loaf != null and loaf.disabled and str(loaf.get_meta("full_text")).ends_with("· бракує 2 жет.") and loaf.get_theme_color("icon_disabled_color").a <= 0.41 and loaf.icon != null, "I3 the loaf with 0 tokens: disabled, «бракує 2 жет.» in words, its icon dimmed (α %.2f)" % (loaf.get_theme_color("icon_disabled_color").a if loaf != null else -1.0))
	npc.dialogue.close()
	await _ticks(2)
	# I4: the pedlar's offer.
	world.progress.earn_credits(3)
	world.player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(20)
	var events: Node = world.events
	events.enable_for_test(4242)
	events.start_chance = 0.0
	events.session_time = 1000.0
	events.last_end_time = -INF
	if events.try_start("vendor"):
		var pedlar: Node = events.active
		pedlar.person.global_position = world.player.global_position + Vector3(1.4, 0.0, 0.0)
		pedlar.person.stop()
		for tick: int in 60:
			if pedlar.phase == "offer":
				break
			await _ticks(1)
		pedlar.open_offer()
		_break(events.dialogue)
		await _ticks(2)
		var offer: Array[Button] = _buttons(events.dialogue)
		var expected := {"beer": "dark_beer", "cigarette": "cigarette", "refuse": "", "leave": ""}
		_check(offer.size() == 5, "I4 the offer: beer, cigarette, «Ні, дякую», «Піти», the close button (%d)" % offer.size())
		for button: Button in offer:
			var id: String = "close" if button.has_meta("close") else str(button.get_meta("id", ""))
			_dressed(button, String(expected.get(id, "")), "I4")
		events.abort_active("fixture")
		await _ticks(3)
	else:
		_check(false, "I4 the pedlar starts (%s)" % events.block_reason("vendor"))
	world.queue_free()
	await _ticks(3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(content.get("storage_path")))
	content.call("load_settings", old_content)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("ITEM_ICONS_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)
