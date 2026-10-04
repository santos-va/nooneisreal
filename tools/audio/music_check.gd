extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _run() -> void:
	var music: Node = root.get_node("Music")
	var ultimate: Node = root.get_node("UltMusic")
	music.reload_manifest("res://missing-test-soundtracks.cfg")
	music.play_menu()
	check(music.context == "menu" and not music._player.playing, "Absent menu is silent")
	music.play_battle()
	check(music.context == "battle" and not music._player.playing, "Absent battle is silent")
	check(music.target_gain_db() == music.BASE_DB, "Normal soundtrack gain")
	ultimate.active = true
	check(music.target_gain_db() == music.DUCK_DB, "Duck during ultimate")
	ultimate.paused = true
	check(music.target_gain_db() == music.DUCK_DB, "Keep duck in time stop")
	ultimate.active = false
	ultimate.paused = false
	check(music.target_gain_db() == music.BASE_DB, "Recover after ultimate")
	# Use a temporary generated stream to exercise playlist transitions without user assets.
	var fixture := AudioStreamWAV.new()
	fixture.mix_rate = 8000
	fixture.data = PackedByteArray()
	fixture.data.resize(8000)
	ResourceSaver.save(fixture, "user://music_fixture.tres")
	music._tracks = {"menu": "user://music_fixture.tres", "battle_1": "user://music_fixture.tres", "battle_2": "user://music_fixture.tres"}
	music.stop_music()
	music.play_battle()
	var first_slot: String = music.current_slot
	check(music._player.playing, "Available stream starts")
	music._on_finished()
	check(first_slot != music.current_slot, "Battle playlist alternates")
	music.play_menu()
	music._on_finished()
	check(music.current_slot == "menu", "Menu repeats")
	ultimate.play("ult_skea_bass", 0.0)
	if ultimate.audible():
		ultimate.finish("")
		check(music.target_gain_db() == music.DUCK_DB, "Duck persists over audible ultimate tail")
		for tick: int in ultimate.FADE_FRAMES:
			ultimate._physics_process(1.0 / 60.0)
		check(music.target_gain_db() == music.BASE_DB, "Recover after actual ultimate tail")
	else:
		ultimate.finish("")
	var original_gain: float = root.get_node("ComfortSettings").get_value("music")
	root.get_node("ComfortSettings").set_value("music", 0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Existing music mute routes soundtrack")
	root.get_node("ComfortSettings").set_value("music", original_gain)
	music.stop_music()
	check(music.context.is_empty() and music._player.stream == null, "Stop releases stream")
	ultimate._player.stop()
	ultimate._player.stream = null
	ultimate._cache.clear()
	fixture = null
	music = null
	ultimate = null
	for singleton: String in ["Music", "UltMusic", "Sfx"]:
		root.get_node(singleton).queue_free()
	# The audio mixer drains on wall time even when the runner accelerates physics.
	var until: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("[music] failures=%d" % failures)
	quit(failures)
