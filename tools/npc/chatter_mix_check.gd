extends SceneTree
const Chatter = preload("res://scripts/npc/NpcChatter.gd")
func _initialize() -> void: run.call_deferred()
func wait_for_mix(capture: AudioEffectCapture, chatter: Node) -> bool:
	# --fixed-fps accelerates simulation, while the audio mixer uses wall time.
	# Yield and briefly throttle this probe so the runner's frame cap cannot outrun it.
	var deadline := Time.get_ticks_msec() + 2500
	var required_frames := int(AudioServer.get_mix_rate() * 0.60)
	while Time.get_ticks_msec() < deadline:
		var playing := false
		for voice in chatter._voices: playing = playing or voice.playing
		if capture.get_frames_available() >= required_frames and not playing: return true
		OS.delay_msec(5)
		await process_frame
	return false

func drain_audio_commands() -> void:
	var deadline := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < deadline:
		OS.delay_msec(5)
		await process_frame

func run() -> void:
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index,"ChatterAudit")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 1
	AudioServer.add_bus_effect(index,capture)
	var listener := Node3D.new()
	root.add_child(listener)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	var chatter := Chatter.new()
	root.add_child(chatter)
	chatter.configure(listener)
	for voice in chatter._voices: voice.bus = "ChatterAudit"
	var energies := []
	var mixer_ready := true
	for distance in [2.0, 6.0, 20.0]:
		camera.position = Vector3(0,1.5,distance)
		camera.look_at(Vector3(0,1.5,0))
		chatter._process(3)
		capture.clear_buffer()
		var accepted := chatter.speak(Vector3(0,0,-1.2),0,"talk","test")
		mixer_ready = await wait_for_mix(capture, chatter) and mixer_ready
		var buffer := capture.get_buffer(capture.get_frames_available())
		var sum_square := 0.0
		var active_frames := 0
		for sample in buffer:
			if sample.length_squared() > 0.00000001:
				sum_square += sample.length_squared()
				active_frames += 1
		var rms := sqrt(sum_square/maxi(1,active_frames))
		energies.append(rms)
		print("NPC_MIX camera_distance=",distance," accepted=",accepted," listener=",chatter._spatial_listener.global_position," rms=",rms," frames=",buffer.size())
	listener.position = Vector3(12,0,0)
	chatter._process(3)
	capture.clear_buffer()
	var far := chatter.speak(Vector3.ZERO,0,"talk","far")
	mixer_ready = await wait_for_mix(capture, chatter) and mixer_ready
	var tail := capture.get_buffer(capture.get_frames_available())
	var far_energy := 0.0
	for sample in tail: far_energy += sample.length_squared()
	print("NPC_MIX far_accepted=",far," far_energy=",far_energy," mixer_ready=",mixer_ready," frames=",tail.size())
	var ok: bool = mixer_ready and energies.min() > .001 and energies.max()/energies.min() < 1.15 and not far and far_energy < .0001
	print("NPC_MIX_COMPLETE passed=",ok)
	chatter.stop_all()
	for voice in chatter._voices: voice.stream = null
	chatter.free()
	listener.free()
	camera.free()
	await drain_audio_commands()
	AudioServer.remove_bus_effect(index,0)
	capture = null
	AudioServer.remove_bus(index)
	Chatter._streams.clear()
	await drain_audio_commands()
	quit(0 if ok else 1)
