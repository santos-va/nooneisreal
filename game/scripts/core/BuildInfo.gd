class_name BuildInfo
extends RefCounted
## Exporters inject this marker into the staged project; source checkouts stay explicit.

static func revision(marker_path: String = "res://build_info.cfg") -> String:
	var marker := ConfigFile.new()
	if marker.load(marker_path) != OK:
		return ""
	var value: String = str(marker.get_value("build", "revision", ""))
	if value.length() != 40:
		return ""
	for character: String in value:
		if not character in "0123456789abcdef":
			return ""
	return value


static func label() -> String:
	var value := revision()
	var version: String = str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	return "v%s · build %s" % [version, value.left(7)] if not value.is_empty() else "v%s · development checkout" % version
