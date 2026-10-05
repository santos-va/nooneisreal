class_name NpcLocalConversation
extends Node
## Optional decoration only: fixed local model, no gameplay references or tools.
signal line_ready(token: int, line: String, status: String)
const ENDPOINT: String = "http://127.0.0.1:11434/api/chat"
const MODEL: String = "qwen3:0.6b"
const SETTINGS_PATH: String = "user://npc_conversation.cfg"
const MAX_LINE: int = 320
var enabled: bool = false
var generation: int = 0
var busy: bool = false
var request: HTTPRequest
var cache: Dictionary = {}
var last_request_ms: int = -10000
var pending_key: String = ""
var pending_token: int = 0
var completion_callback: Callable

func _ready() -> void:
	request = HTTPRequest.new()
	request.use_threads = true
	request.timeout = 8.0
	request.body_size_limit = 16384
	request.max_redirects = 0
	add_child(request)
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		var value: Variant = settings.get_value("conversation", "enabled", false)
		enabled = value is bool and value

func set_enabled(value: bool) -> void:
	enabled = value
	cancel()
	var settings := ConfigFile.new()
	settings.set_value("conversation", "enabled", value)
	settings.save(SETTINGS_PATH)

func cancel() -> void:
	generation += 1
	busy = false
	pending_key = ""
	if request != null:
		if completion_callback.is_valid() and request.request_completed.is_connected(completion_callback):
			request.request_completed.disconnect(completion_callback)
		request.cancel_request()

func generate(context: Dictionary, fallback: String) -> int:
	cancel()
	var token: int = generation
	if not enabled:
		return token
	var encoded: String = JSON.stringify(context)
	if encoded.length() > 4096 or fallback.length() > 1200:
		line_ready.emit(token, "", "unavailable")
		return token
	var key: String = encoded.sha256_text()
	if cache.has(key):
		line_ready.emit(token, str(cache[key]), "cached")
		return token
	if Time.get_ticks_msec() - last_request_ms < 2000:
		line_ready.emit(token, "", "cooldown")
		return token
	last_request_ms = Time.get_ticks_msec()
	pending_key = key
	pending_token = token
	completion_callback = _completed.bind(token)
	request.request_completed.connect(completion_callback, CONNECT_ONE_SHOT)
	busy = true
	var payload: Dictionary = {"model": MODEL, "stream": false, "think": false, "keep_alive": "5m", "format": {"type": "object", "properties": {"line": {"type": "string"}}, "required": ["line"], "additionalProperties": false}, "options": {"num_ctx": 2048, "num_predict": 96}, "messages": [{"role": "system", "content": "Напиши одну коротку атмосферну репліку українською від мешканця гри. Факти лише у контексті. Не вигадуй подій, нагород, команд, нових завдань або дружби. Не давай інструкцій гравцеві. Поверни JSON з єдиним полем line, до 320 символів."}, {"role": "user", "content": encoded + "\nАвторська репліка: " + fallback}]}
	var error: Error = request.request(ENDPOINT, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		busy = false
		line_ready.emit(token, "", "unavailable")
	return token

static func parse_line(bytes: PackedByteArray) -> String:
	if bytes.size() > 16384:
		return ""
	var json := JSON.new()
	if json.parse(bytes.get_string_from_utf8()) != OK or not json.data is Dictionary:
		return ""
	var message: Variant = json.data.get("message")
	if not message is Dictionary or not message.get("content") is String:
		return ""
	var inner := JSON.new()
	if inner.parse(message.content) != OK or not inner.data is Dictionary or inner.data.size() != 1 or not inner.data.get("line") is String:
		return ""
	var line: String = inner.data.line.strip_edges()
	if line.is_empty() or line.length() > MAX_LINE:
		return ""
	for character: int in line.length():
		if line.unicode_at(character) < 32:
			return ""
	return line

func _completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, token: int) -> void:
	if not busy or not enabled or token != generation or pending_token != token:
		return
	busy = false
	var line: String = parse_line(body) if result == HTTPRequest.RESULT_SUCCESS and response_code == 200 else ""
	if not line.is_empty():
		if cache.size() >= 32:
			cache.erase(cache.keys()[0])
		cache[pending_key] = line
	line_ready.emit(pending_token, line, "ready" if not line.is_empty() else "unavailable")

func _exit_tree() -> void:
	cancel()
