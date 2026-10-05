#!/usr/bin/env bash
# Actual HTTPRequest against a local protocol fixture. This is NOT model inference.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
check_profile="$(mktemp -d "${TMPDIR:-/tmp}/nir-npc-http.XXXXXX")"
server_pid=""
cleanup() {
  if [[ -n "$server_pid" ]]; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf -- "$check_profile"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
export NIR_LLM_FIXTURE_DIR="$check_profile/fixture"
export XDG_DATA_HOME="$check_profile/data"
export XDG_CONFIG_HOME="$check_profile/config"
export XDG_CACHE_HOME="$check_profile/cache"
export XDG_RUNTIME_DIR="$check_profile/runtime"
mkdir -p "$NIR_LLM_FIXTURE_DIR" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
log_dir="${NIR_LLM_LOG_DIR:-$check_profile/logs}"
mkdir -p "$log_dir"
# Never interrupt an existing Ollama or another test's listener.
python3 - <<'PY'
import socket,sys
with socket.socket() as probe:
    probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        probe.bind(('127.0.0.1',11434))
    except OSError as error:
        print(f'NPC_HTTP_UNAVAILABLE: loopback11434 is occupied or forbidden: {error}', flush=True)
        sys.exit(2)
PY
printf '%s\n' success > "$NIR_LLM_FIXTURE_DIR/mode.txt"
python3 "$repo_root/tools/npc/fixtures/fake_ollama.py" > "$log_dir/server.log" 2>&1 &
server_pid=$!
python3 - "$log_dir/server.log" "$server_pid" <<'PY'
from pathlib import Path
import os,sys,time
log=Path(sys.argv[1]); pid=int(sys.argv[2])
for attempt in range(100):
    if log.exists() and 'T4_FAKE_OLLAMA_READY' in log.read_text():
        break
    try: os.kill(pid,0)
    except ProcessLookupError: sys.exit('NPC_HTTP_UNAVAILABLE: fixture could not bind fixed loopback port')
    time.sleep(.02)
else: sys.exit('NPC_HTTP_UNAVAILABLE: fixture startup timed out')
PY
for check_name in local_http_check local_http_director_check; do
  check_rc=0
  python3 - "${GODOT_BIN:-godot}" "${NIR_GODOT_PROJECT:-$repo_root/game}" "$repo_root/tools/npc/$check_name.gd" "$log_dir/$check_name.log" <<'PY_RUN' || check_rc=$?
import os,signal,subprocess,sys
with open(sys.argv[4],'w') as output:
    try:
        process=subprocess.Popen([sys.argv[1],'--headless','--path',sys.argv[2],'--script',sys.argv[3]],stdout=output,stderr=subprocess.STDOUT,start_new_session=True)
    except OSError as error:
        sys.exit(f'NPC_HTTP_UNAVAILABLE: Godot could not start: {error}')
    def interrupted(signum, _frame):
        raise SystemExit(128+signum)
    signal.signal(signal.SIGTERM,interrupted)
    try:
        code=process.wait(timeout=45)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid,signal.SIGTERM)
        try: process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid,signal.SIGKILL)
            process.wait()
        sys.exit(124)
    finally:
        if process.poll() is None:
            os.killpg(process.pid,signal.SIGTERM)
            try: process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid,signal.SIGKILL)
                process.wait()
    sys.exit(code if code>=0 else 128-code)
PY_RUN
  cat "$log_dir/$check_name.log"
  if [[ "$check_rc" -ne 0 ]]; then
    exit "$check_rc"
  fi
done
cp "$NIR_LLM_FIXTURE_DIR/requests.jsonl" "$log_dir/requests.jsonl"
python3 - "$log_dir/local_http_check.log" "$NIR_LLM_FIXTURE_DIR/requests.jsonl" "$log_dir/local_http_director_check.log" <<'PY'
from pathlib import Path
import json,re,sys
text=Path(sys.argv[1]).read_text()
if 'T4_LLM_HTTP_COMPLETE checks=34 failures=0' not in text.splitlines():
    sys.exit('NPC_HTTP_FAIL: missing complete protocol assertions')
director=Path(sys.argv[3]).read_text()
if 'T4_LLM_DIRECTOR_COMPLETE checks=17 failures=0' not in director.splitlines():
    sys.exit('NPC_HTTP_FAIL: missing complete director authority assertions')
if re.search(r'^\s*(?:SCRIPT ERROR|SHADER ERROR|ERROR):|ObjectDB instances leaked|resources still in use',text+'\n'+director,re.M):
    sys.exit('NPC_HTTP_FAIL: strict runtime log guard')
requests=[json.loads(line) for line in Path(sys.argv[2]).read_text().splitlines()]
for request in requests:
    payload=request['body']
    if request['path']!='/api/chat' or payload['model']!='qwen3:0.6b' or payload['stream'] is not False or payload['think'] is not False:
        sys.exit('NPC_HTTP_FAIL: unexpected endpoint/model/payload')
print('NPC_HTTP_PASS protocol=34 director=17 failures=0 real_model_inference=false')
PY
