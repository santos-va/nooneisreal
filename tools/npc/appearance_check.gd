extends SceneTree
const Appearance = preload("res://scripts/npc/NpcAppearance.gd")
func _initialize() -> void:
	var seen := {}
	for seed_value in range(100):
		var first := Appearance.describe(seed_value)
		assert(first == Appearance.describe(seed_value), "Unstable identity")
		seen[JSON.stringify(first)] = true
	var a: Node3D = Appearance.build({"appearance_seed": 42, "role": "worker"})
	var b: Node3D = Appearance.build({"appearance_seed": 42, "role": "merchant"})
	assert(a.get_meta("appearance") == b.get_meta("appearance"), "Job changed appearance")
	assert(a.get_child_count() > 12, "Missing humanoid features")
	a.set_motion(1.2, 0.8)
	a.set_motion(0, 0.8)
	assert(seen.size() == 100, "Seed collision")
	a.free()
	b.free()
	print("[npc-appearance] stable seeds, role independence, humanoid build, locomotion OK")
	quit()
