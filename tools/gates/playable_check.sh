#!/usr/bin/env bash
# Serial presentation regressions. A frame cap or successful process exit is not a PASS.
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export GODOT_BIN="${GODOT_BIN:-godot}"
python3 - <<'PY'
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

binary = shutil.which(os.environ['GODOT_BIN'])
if binary is None:
    print('PLAYABLE REFUSED: Godot executable unavailable', flush=True)
    sys.exit(2)
logs = Path(os.environ.get('PLAYABLE_LOG_DIR') or tempfile.mkdtemp(prefix='nir-playable-'))
logs.mkdir(parents=True, exist_ok=True)
cases = [
    ('ui', 'tools/ui/layout_check.gd', r'UI_LAYOUT PASS \(0 failures; mutation=\)', [], 0),
    ('motion', 'tools/animation/character_motion_check.gd', r'CHARACTER MOTION: [1-9][0-9]* checks, 0 failures', [], 0),
    ('idle', 'tools/animation/idle_presence_check.gd', r'IDLE PRESENCE: [1-9][0-9]* checks, 0 failures', [], 0),
    ('afterimage', 'tools/fx/afterimage_check.gd', r'afterimage: [1-9][0-9]* checks, 0 failures', [], 0),
    ('splash', 'tools/fx/water_splash_check.gd', r'SPLASH CHECK: 0 failures', [], 0),
    ('contact', 'tools/fx/water_contact_check.gd', r'WATER CONTACT CHECK: 0 failures', [], 0),
    ('camera', 'tools/camera/framing_check.gd', r'CAMERA_FRAMING: [1-9][0-9]* checks, 0 failures', [], 0),
    ('impact', 'tools/camera/impact_check.gd', r'impact-check: OK \([1-9][0-9]* checks, 0 failures\)', [], 0),
    ('foot', 'tools/animation/foot_contact_check.gd', r'FOOT CONTACT: [1-9][0-9]* checks, 0 failures', [], 0),
    ('audio', 'tools/audio/sfx_check.gd', r'sfx-check: OK \([1-9][0-9]* checks, 0 failures\)', [], 0),
    ('comfort-settings', 'tools/settings/comfort_check.gd', r'COMFORT_CHECK_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('comfort-input', 'tools/input/comfort_input_check.gd', r'COMFORT_INPUT_CHECK checks=[1-9][0-9]* failures=0', [], 0),
    ('comfort-ui', 'tools/ui/comfort_ui_check.gd', r'COMFORT_UI PASS \(0 failures; mutation=\)', [], 0),
]
for mutation in ('portrait', 'icon', 'input'):
    cases.append(('ui-negative-' + mutation, 'tools/ui/layout_check.gd',
                  rf'UI_LAYOUT FAIL \([1-9][0-9]* failures; mutation={mutation}\)',
                  ['--', '--break=' + mutation], 1))
for mutation in ('footer', 'focus', 'bounds'):
    cases.append(('comfort-ui-negative-' + mutation, 'tools/ui/comfort_ui_check.gd',
                  rf'COMFORT_UI FAIL \([1-9][0-9]* failures; mutation={mutation}\)',
                  ['--', '--break=' + mutation], 1))
failures = 0
for name, script, sentinel, args, expected_rc in cases:
    command = [binary, '--headless', '--audio-driver', 'Dummy', '--path', 'game',
               '--fixed-fps', '60', '--quit-after', '12000', '--script', str(Path(script).resolve()), *args]
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                text=True, timeout=180)
        output, rc = result.stdout, result.returncode
    except subprocess.TimeoutExpired as exc:
        raw = exc.stdout or b''
        output = raw.decode(errors='replace') if isinstance(raw, bytes) else raw
        output += '\nPLAYABLE TIMEOUT: 180 seconds\n'
        rc = 124
    path = logs / (name + '.log')
    path.write_text(output)
    # Only the UI negative controls may print their deliberate assertion errors.
    # Shader, resource, compiler and other runtime errors cannot hide behind a success sentinel.
    complete = re.search('^' + sentinel + '$', output, re.MULTILINE) is not None
    errors = [line.strip() for line in output.splitlines()
              if re.match(r'^\s*(?:SCRIPT ERROR|ERROR):', line)]
    assertion_prefix = 'ERROR: COMFORT_UI: ' if name.startswith('comfort-ui-negative-') else 'ERROR: UI_LAYOUT: '
    unexpected = [line for line in errors
                  if expected_rc == 0 or not line.startswith(assertion_prefix)]
    ok = rc == expected_rc and complete and not unexpected and 'SCRIPT ERROR' not in output
    print(f'PLAYABLE {name}: {"PASS" if ok else "FAIL"} rc={rc} log={path}', flush=True)
    if not ok:
        failures += 1
        print(output[-12000:], flush=True)
print(f'PLAYABLE CHECK: {len(cases)} scenarios, {failures} failures', flush=True)
sys.exit(1 if failures else 0)
PY
