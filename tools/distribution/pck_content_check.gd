extends SceneTree
## Mount an exported PCK into an empty project so checkout files cannot mask omissions.
## Args: --pack=/absolute/file.pck --revision=<40 hex> --content-sha=<district.json sha256>

func _initialize() -> void:
	var arguments: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var pair := argument.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2:
			arguments[pair[0]] = pair[1]
	if FileAccess.file_exists("res://data/city/district.json") or FileAccess.file_exists("res://build_info.cfg"):
		_fail("Use an empty verifier project, without checkout files.")
		return
	if not ProjectSettings.load_resource_pack(arguments.get("pack", "")):
		_fail("Could not mount exported PCK.")
		return
	if not FileAccess.file_exists("res://data/city/district.json"):
		_fail("District JSON is missing from the export.")
		return
	if FileAccess.get_sha256("res://data/city/district.json") != arguments.get("content-sha", ""):
		_fail("Exported district content differs from the source snapshot.")
		return
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/city/district.json"))
	if not document is Dictionary or document.get("quests", []).size() != 6:
		_fail("Exported content does not expose all six district quests.")
		return
	var marker := ConfigFile.new()
	if marker.load("res://build_info.cfg") != OK or marker.get_value("build", "revision", "") != arguments.get("revision", "invalid"):
		_fail("Exported build marker is missing or incorrect.")
		return
	if not FileAccess.file_exists("res://data/audio/soundtracks.cfg"):
		_fail("Existing audio manifest inclusion regressed.")
		return
	print("PCK_CONTENT_COMPLETE quests=6 marker=verified audio=present")
	quit()

func _fail(message: String) -> void:
	push_error("PCK_CONTENT: " + message)
	quit(1)
