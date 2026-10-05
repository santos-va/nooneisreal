extends SceneTree
var checks: int = 0
var failures: int = 0
var received: Array[Dictionary] = []
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("NPC_LOCAL: " + label)
func packet(content: Variant) -> PackedByteArray:
	return JSON.stringify({"message": {"content": JSON.stringify(content)}}).to_utf8_buffer()
func run() -> void:
	var adapter := NpcLocalConversation.new()
	check(not adapter.enabled, "new adapter defaults off")
	root.add_child(adapter)
	adapter.set_enabled(false)
	adapter.line_ready.connect(func(token: int, line: String, status: String) -> void: received.append({"token": token, "line": line, "status": status}))
	check(adapter.request.use_threads and adapter.request.timeout == 8.0 and adapter.request.body_size_limit == 16384 and adapter.request.max_redirects == 0, "bounded threaded request")
	check(adapter.ENDPOINT == "http://127.0.0.1:11434/api/chat" and adapter.MODEL == "qwen3:0.6b", "fixed loopback and local tag")
	adapter.generate({"hero": "choko"}, "Вітаю.")
	check(not adapter.busy and received.is_empty(), "off never requests")
	check(adapter.parse_line(packet({"line": "Вітаю, сусіде."})) == "Вітаю, сусіде.", "valid short text")
	for content: Variant in [{}, {"line": ""}, {"line": "x".repeat(321)}, {"line": "Ні\nкомандам"}, {"line": 7}, {"line": "Так", "reward": 99}, []]:
		check(adapter.parse_line(packet(content)).is_empty(), "invalid model output rejected")
	for bytes: PackedByteArray in ["oops".to_utf8_buffer(), "[]".to_utf8_buffer(), "{}".to_utf8_buffer(), "x".repeat(16385).to_utf8_buffer()]:
		check(adapter.parse_line(bytes).is_empty(), "malformed envelope rejected")
	adapter.enabled = true
	adapter.cache[JSON.stringify({"hero": "choko"}).sha256_text()] = "Добрий день."
	var token: int = adapter.generate({"hero": "choko"}, "Вітаю.")
	check(received.size() == 1 and received[0].token == token and received[0].line == "Добрий день.", "cache result carries same generation")
	adapter.last_request_ms = Time.get_ticks_msec()
	adapter.generate({"hero": "skea"}, "Вітаю.")
	check(not adapter.busy and received.back().status == "cooldown", "cooldown avoids repeat requests")
	var old: int = adapter.generation
	adapter.cancel()
	adapter.busy = true
	adapter.pending_token = adapter.generation
	var count: int = received.size()
	adapter._completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), packet({"line": "Пізня відповідь"}), old)
	check(received.size() == count and adapter.busy, "old callback cannot finish newer request")
	adapter._completed(HTTPRequest.RESULT_SUCCESS, 500, PackedStringArray(), packet({"line": "Ні"}), adapter.generation)
	check(received.back().status == "unavailable" and not adapter.busy, "HTTP failure fallback")
	adapter.busy = true
	adapter._completed(HTTPRequest.RESULT_TIMEOUT, 0, PackedStringArray(), PackedByteArray(), adapter.generation)
	check(received.back().status == "unavailable" and not adapter.busy, "timeout fallback")
	adapter.busy = true
	adapter.set_enabled(false)
	count = received.size()
	adapter._completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), packet({"line": "Пізня відповідь"}), adapter.generation)
	check(received.size() == count and not adapter.busy, "disable invalidates request")
	adapter.queue_free()
	await process_frame
	print("[npc-local] %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)
