extends SceneTree
## Plan docs/Plans/2026-10-08-Thirst-Substances-Icons.md step 3 — every character the game puts on the screen exists in
## the game's font (T1 «Рішення після кроку 0», T8 06-UI-UX § «Спрага…» аудит: `→` and `✓` render as .notdef).
## Subject: for every screen string s of the game and every character c of s, the font the game draws with has a glyph
## for c — never a fallback to an operating-system font that the player's machine may not have.
## How it knows the font's coverage: the project sets no theme and ships no font (`project.godot` has no `gui/theme`;
## `find game -name '*.ttf' -o -name '*.otf' -o -name '*.woff*'` → none), so every Label, Button and Label3D draws with
## Godot's built-in default (ThemeDB.fallback_font: Open Sans SemiBold, FontFile, no fallbacks of its own). Font.has_char()
## answers from that FontFile's own character map (plus its fallbacks, of which there are none) — the system fallback
## (`allow_system_fallback`) is not consulted, which is exactly the point. The check first proves the answer can be «no»:
## `A` must be covered and U+2192 `→` and U+E000 (private use) must not; if that fails, nothing is measured (red).
## Screen strings: the string literals of every res://scripts/**/*.gd (comments skipped; `\uXXXX` escapes decoded),
## except a literal whose statement is a console call (print*, push_error, push_warning, assert) and the smoke harness
## SmokeTest.gd, which only prints to the console; every string of res://data/**/*.json; the display_name of every
## CharacterData in res://data/characters/; every `text = "…"` of res://scenes/**/*.tscn.
## --break=inject_gd|inject_json|inject_triple|font are negative controls (a `✓` literal, a `→` in data, a `◇` in a
## triple-quoted string, a font that claims every character).
## Sentinel: GLYPH_COVERAGE_COMPLETE checks=N failures=M mutation=<m> (the form playable_check.sh expects of a negative),
## after GLYPH_COVERAGE_INFO literals=L chars=C; failures print "GLYPH_COVERAGE: ...".
const SINKS: Array[String] = ["print", "prints", "printt", "printerr", "printraw", "print_rich", "print_debug", "push_error", "push_warning", "assert"]
const CONSOLE_ONLY: Array[String] = ["res://scripts/core/SmokeTest.gd"]
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var font: Font
var literals: int = 0
var seen: Dictionary = {}   # character → first place it was seen


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("GLYPH_COVERAGE: " + label)


func _covered(code: int) -> bool:
	if mutation == "font":
		return true   # the negative: a font that claims every character
	return font.has_char(code)


func _run() -> void:
	await process_frame
	font = ThemeDB.fallback_font
	var probe := Label.new()
	root.add_child(probe)
	var drawn: Font = probe.get_theme_font("font")
	probe.queue_free()
	_check(drawn == font and font is FontFile and font.fallbacks.is_empty(), "the font a Label draws with is the built-in default, with no fallbacks (%s, %s)" % [font.get_font_name(), font.get_class()])
	var measurable: bool = _covered("A".unicode_at(0)) and not _covered(0x2192) and not _covered(0xE000)
	_check(measurable, "the font's answer can be «no»: A covered, U+2192 and U+E000 not (otherwise coverage is not measured)")
	if not measurable:
		print("GLYPH_COVERAGE_INFO literals=0 chars=0")
		print("GLYPH_COVERAGE_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
		quit(1)   # not measured is not green
		return
	var files: Array[String] = []
	_walk("res://scripts", "gd", files)
	for path: String in files:
		if path in CONSOLE_ONLY:
			continue
		_scan_gd(path, FileAccess.get_file_as_string(path))
	var data: Array[String] = []
	_walk("res://data", "json", data)
	for path: String in data:
		_scan_json(path, FileAccess.get_file_as_string(path))
	var characters: Array[String] = []
	_walk("res://data/characters", "tres", characters)
	for path: String in characters:
		var resource: Resource = load(path)
		if resource != null and "display_name" in resource and resource.get_script() != null and String(resource.get_script().resource_path).ends_with("CharacterData.gd"):
			_scan_text(path + " display_name", String(resource.get("display_name")))
	var scenes: Array[String] = []
	_walk("res://scenes", "tscn", scenes)
	for path: String in scenes:
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for i: int in lines.size():
			if lines[i].begins_with("text = \""):
				_scan_text("%s:%d" % [path, i + 1], lines[i].trim_prefix("text = \"").trim_suffix("\""))
	match mutation:
		"inject_gd":
			_scan_gd("res://scripts/fixture_inject.gd", "func _x() -> void:\n\tlabel.text = \"READY ✓\"   # a ready mark\n")
		"inject_json":
			_scan_json("res://data/fixture_inject.json", "{\"lines\": [\"двір → сходи\"]}")
		"inject_triple":
			_scan_gd("res://scripts/fixture_inject.gd", "const HELP := \"\"\"first line\n\t◇ second line\"\"\"\n")
	_check(literals > 100, "the scan reached the game's strings (%d literals)" % literals)
	print("GLYPH_COVERAGE_INFO literals=%d chars=%d" % [literals, seen.size()])
	print("GLYPH_COVERAGE_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)


func _walk(dir: String, extension: String, out: Array[String]) -> void:
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == extension:
			out.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		_walk(dir.path_join(sub), extension, out)


## One screen string: every character outside ASCII must be in the font.
func _scan_text(where: String, text: String) -> void:
	literals += 1
	var missing: PackedStringArray = []
	for k: int in text.length():
		var code: int = text.unicode_at(k)
		if code < 128:
			continue
		if not seen.has(code):
			seen[code] = where
		if not _covered(code) and not missing.has(String.chr(code)):
			missing.append(String.chr(code))
	checks += 1
	if not missing.is_empty():
		failures += 1
		push_error("GLYPH_COVERAGE: %s — not in the font: %s (U+%s) «%s»" % [where, "".join(missing), ", U+".join(Array(missing).map(func(c: String) -> String: return "%04X" % c.unicode_at(0))), text.substr(0, 90)])


## String literals of a GDScript source: comments skipped, "…", '…' and triple-quoted strings, escapes kept as written
## except \uXXXX / \UXXXXXX, which are decoded (a literal must not hide a glyph behind an escape).
func _scan_gd(path: String, text: String) -> void:
	var i: int = 0
	var line: int = 1
	var n: int = text.length()
	while i < n:
		var c: String = text[i]
		if c == "\n":
			line += 1
			i += 1
			continue
		if c == "#":
			while i < n and text[i] != "\n":
				i += 1
			continue
		if c == "\"" or c == "'":
			var quote: String = c.repeat(3) if text.substr(i, 3) == c.repeat(3) else c
			var start_line: int = line
			i += quote.length()
			var body: String = ""
			while i < n and text.substr(i, quote.length()) != quote:
				if text[i] == "\\" and i + 1 < n:
					var escape: String = text[i + 1]
					if escape == "u" and i + 6 <= n and text.substr(i + 2, 4).is_valid_hex_number():
						body += String.chr(text.substr(i + 2, 4).hex_to_int())
						i += 6
						continue
					if escape == "U" and i + 8 <= n and text.substr(i + 2, 6).is_valid_hex_number():
						body += String.chr(text.substr(i + 2, 6).hex_to_int())
						i += 8
						continue
					body += text.substr(i, 2)
					i += 2
					continue
				if text[i] == "\n":
					line += 1
				body += text[i]
				i += 1
			i += quote.length()
			if not _console(text, i):
				_scan_text("%s:%d" % [path, start_line], body)
			continue
		i += 1


## True when the literal ending at `at` belongs to a console call (its statement starts with one of SINKS).
static func _console(text: String, at: int) -> bool:
	var start: int = text.rfind("\n", at - 1) + 1
	var head: String = text.substr(start, at - start).strip_edges()
	for sink: String in SINKS:
		if head.begins_with(sink + "("):
			return true
	return false


func _scan_json(path: String, text: String) -> void:
	var parser := JSON.new()
	if parser.parse(text) != OK:
		_check(false, "%s parses as JSON (%s)" % [path, parser.get_error_message()])
		return
	_scan_value(path, parser.data)


func _scan_value(where: String, value: Variant) -> void:
	if value is String:
		_scan_text(where, value)
	elif value is Array:
		for item: Variant in value:
			_scan_value(where, item)
	elif value is Dictionary:
		for key: Variant in value:
			_scan_value(where + "." + str(key), value[key])
