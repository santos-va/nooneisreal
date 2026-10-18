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
## Static (T4 audit 2026-10-08 п. 5, plan 2026-10-09 step 4): a character made at run time is never seen by the font
## check, so screen code may not make one — no `String.chr`, no global `char(` outside a console call, no `%c` directive
## in a screen literal (`git grep -nE 'String\.chr\(|[^_.a-zA-Z0-9]char\(|%c' -- game/scripts` stays empty but for
## console lines). Plan 2026-10-14 step 7 (T4 audit 2026-10-09 п. 4, proposal 5: G4 `char (0x2713)` and G6
## `PackedByteArray([0xE2, 0x9C, 0x93]).get_string_from_utf8()` got through): the calls are found as words with any
## spacing or line break before `(` / around `.`, and the decoders count too — `.get_string_from_*` (bytes → text) and
## DECODE_CALLS (`"%E2%9C%93".uri_decode()`, `"&#x2713;".xml_unescape()`, …) —, as does a padded `%-2c`. Each of these
## builds U+2713 from ASCII source on Godot 4.7; `c_unescape` does not decode `\u` there, so it is not listed.
## DECODE_ALLOWED names the one decode that is not the game's own glyph (the local model's reply).
## --break=inject_gd|inject_json|inject_triple|font are negative controls (a `✓` literal, a `→` in data, a `◇` in a
## triple-quoted string, a font that claims every character); --break=inject_format|inject_chr|inject_char are G1
## (`" %c" % 0x2713`), G2 (`String.chr(0x2192)`) and `char(0x2713)` in a screen line; --break=inject_char_space|
## inject_utf8|inject_chr_space|inject_uri|inject_format_width are G4 (`char (0x2713)`), G6 (bytes decoded with
## get_string_from_utf8), `String . chr (0x2192)`, `"%E2%9C%93".uri_decode()` and `"%-2c" % 0x2713`.
## Sentinel: GLYPH_COVERAGE_COMPLETE checks=N failures=M mutation=<m> (the form playable_check.sh expects of a negative),
## after GLYPH_COVERAGE_INFO literals=L chars=C; failures print "GLYPH_COVERAGE: ...".
const SINKS: Array[String] = ["print", "prints", "printt", "printerr", "printraw", "print_rich", "print_debug", "push_error", "push_warning", "assert"]
const CONSOLE_ONLY: Array[String] = ["res://scripts/core/SmokeTest.gd"]
## Members that decode an escape written in ASCII into a character at run time, out of the literal scan's sight (beside
## `char(`, `String.chr` and `.get_string_from_*`; T4 audits 2026-10-08 п. 5 G1/G2, 2026-10-09 п. 4 G4/G6).
const DECODE_CALLS: Array[String] = ["uri_decode", "xml_unescape", "base64_to_utf8"]
## Decodes that build no glyph of the game's own, path → exact stripped source lines. NpcLocalConversation.parse_line
## turns the local model's HTTP reply body into text for its JSON parser; the line it yields is the model's, not one the
## game writes, so no static scan can see its characters (an open finding of
## docs/Fix/2026-10-14-Audit-Guards-And-Summary-Gate-Fix.md).
const DECODE_ALLOWED: Dictionary = {
	"res://scripts/npc/NpcLocalConversation.gd": ["if json.parse(bytes.get_string_from_utf8()) != OK or not json.data is Dictionary:"],
}
var built: Array[String] = []   # screen code that builds a character at run time: path:line and what
var allowed: Array[String] = []   # the DECODE_ALLOWED decodes met in the code
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
		"inject_format":
			_scan_gd("res://scripts/fixture_inject.gd", "func _x() -> void:\n\tlabel.text = \"READY\" + (\" %c\" % 0x2713)\n")
		"inject_chr":
			_scan_gd("res://scripts/fixture_inject.gd", "func _x() -> void:\n\tlabel.text = \"двір \" + String.chr(0x2192) + \" сходи\"\n")
		"inject_char":
			_scan_gd("res://scripts/fixture_inject.gd", "func _x() -> void:\n\tlabel.text = \"READY \" + char(0x2713)\n")
		"inject_char_space":
			_scan_gd("res://scripts/fixture_inject.gd", "func _x() -> void:\n\tlabel.text = \"READY \" + char (0x2713)\n")
		"inject_utf8":
			_scan_gd("res://scripts/fixture_inject.gd", "func _x() -> void:\n\tlabel.text = \"READY \" + PackedByteArray([0xE2, 0x9C, 0x93]).get_string_from_utf8()\n")
		"inject_chr_space":
			_scan_gd("res://scripts/fixture_inject.gd", "func _x() -> void:\n\tlabel.text = \"двір \" + String . chr (0x2192) + \" сходи\"\n")
		"inject_uri":
			_scan_gd("res://scripts/fixture_inject.gd", "func _x() -> void:\n\tlabel.text = \"READY \" + \"%E2%9C%93\".uri_decode()\n")
		"inject_format_width":
			_scan_gd("res://scripts/fixture_inject.gd", "func _x() -> void:\n\tlabel.text = \"READY\" + (\"%-2c\" % 0x2713)\n")
	# Static: no screen string builds a character at run time (the font check above only sees what is written down).
	_check(built.is_empty(), "no screen code builds a character at run time (String.chr, char(), a %c format, a decode): " + ", ".join(built))
	# The allow-list stays honest: each of its lines is still in the code and seen by the scan (a stale one would hide
	# nothing, but would claim a review of a line that no longer exists).
	var listed: int = 0
	for path: String in DECODE_ALLOWED:
		listed += (DECODE_ALLOWED[path] as Array).size()
	_check(allowed.size() == listed, "every DECODE_ALLOWED line is met once in the code (%d of %d: %s)" % [allowed.size(), listed, ", ".join(allowed)])
	print("GLYPH_COVERAGE_INFO allowed_decodes=%d %s" % [allowed.size(), ", ".join(allowed)])
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
				if _format_c(body):
					built.append("%s:%d «%s» (%%c)" % [path, start_line, body.substr(0, 60)])
			continue
		# A glyph made at run time never reaches _scan_text: a global char(…), String.chr, bytes or an escape decoded into a
		# string — in code outside a console call, with any spacing (`char (`, `String . chr`, a line break between).
		if _word_char(c) and not (c >= "0" and c <= "9") and (i == 0 or not _word_char(text[i - 1])):
			var end: int = i
			while end < n and _word_char(text[end]):
				end += 1
			var what: String = _builder(text, i, end)
			if not what.is_empty() and not _console(text, i):
				if _decode_allowed(path, text, i):
					allowed.append("%s:%d %s" % [path, line, what])
				else:
					built.append("%s:%d %s" % [path, line, what])
			i = end
			continue
		i += 1


## A `%c` directive in a format string, with or without padding / precision (`%c`, `%-2c`, `%05c`, `%*c`), not escaped:
## the run of `%` right before the directive's own `%` is even (`%%c` is a literal percent and a c).
static func _format_c(body: String) -> bool:
	var directive := RegEx.create_from_string("%[-+0]*[0-9*]*(?:\\.[0-9*]+)?c")
	for found: RegExMatch in directive.search_all(body):
		var run: int = 0
		var k: int = found.get_start() - 1
		while k >= 0 and body[k] == "%":
			run += 1
			k -= 1
		if run % 2 == 0:
			return true
	return false


## What the word text[start, end) builds at run time, or "" (T4 audits 2026-10-08 п. 5 G1/G2 and 2026-10-09 п. 4 G4/G6):
## a global `char(` — not a member `x.char(` —, `String.chr` (called or passed on), a member that decodes bytes into a
## string (`.get_string_from_utf8/utf16/utf32/ascii/wchar…`) or decodes an escape written as ASCII (DECODE_CALLS).
static func _builder(text: String, start: int, end: int) -> String:
	var word: String = text.substr(start, end - start)
	var before: String = _previous_mark(text, start)
	var after: int = _skip_blank(text, end)
	var next: String = text[after] if after < text.length() else ""
	if word == "char" and before != "." and next == "(":
		return "char(…)"
	if word == "String" and next == ".":
		var at: int = _skip_blank(text, after + 1)
		if text.substr(at, 3) == "chr" and (at + 3 >= text.length() or not _word_char(text[at + 3])):
			return "String.chr"
	if before == "." and (word.begins_with("get_string_from_") or word in DECODE_CALLS):
		return "." + word + "(…)"
	return ""


## The index of the first character at or after `at` that is not a space, a tab, a line break or a line continuation.
static func _skip_blank(text: String, at: int) -> int:
	while at < text.length() and text[at] in [" ", "\t", "\n", "\r", "\\"]:
		at += 1
	return at


## The last character before `at` that is not blank ("" at the start of the text).
static func _previous_mark(text: String, at: int) -> String:
	var k: int = at - 1
	while k >= 0 and text[k] in [" ", "\t", "\n", "\r", "\\"]:
		k -= 1
	return text[k] if k >= 0 else ""


## A decode the font check may not see but that builds no glyph of the game's own (DECODE_ALLOWED: path → the exact
## stripped source line, with its reason).
static func _decode_allowed(path: String, text: String, at: int) -> bool:
	var start: int = text.rfind("\n", at - 1) + 1
	var stop: int = text.find("\n", at)
	var source: String = text.substr(start, (stop if stop >= 0 else text.length()) - start).strip_edges()
	return source in DECODE_ALLOWED.get(path, [])


## A letter, a digit or `_`.
static func _word_char(c: String) -> bool:
	return c == "_" or (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9")


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
