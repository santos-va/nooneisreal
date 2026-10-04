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
    ('district-ui', 'tools/ui/district_ui_check.gd', r'DISTRICT_UI_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('locomotion-states', 'tools/animation/locomotion_states_check.gd', r'LOCOMOTION_STATES_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('authored-combat', 'tools/animation/authored_combat_check.gd', r'AUTHORED_COMBAT_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
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
    ('free-movement', 'tools/input/free_movement_check.gd', r'FREE_MOVEMENT_COMPLETE checks=[1-9][0-9]* failures=0 mutation=', [], 0),
    ('limb-input', 'tools/input/limb_input_check.gd', r'LIMB_INPUT_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('limb-combat', 'tools/input/limb_combat_check.gd', r'LIMB_COMBAT_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('sword-state', 'tools/weapon/sword_state_check.gd', r'SWORD_STATE_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('sword-presentation', 'tools/animation/sword_presentation_check.gd', r'SWORD_PRESENTATION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('harpoon', 'tools/grapple/harpoon_check.gd', r'HARPOON_CHECK checks=[1-9][0-9]* failures=0', [], 0),
    ('harpoon-aim', 'tools/aim/harpoon_aim_check.gd', r'HARPOON_AIM_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('rope-visual', 'tools/grapple/rope_visual_check.gd', r'ROPE_VISUAL_CHECK_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('rope-recovery', 'tools/animation/rope_recovery_motion_check.gd', r'ROPE_RECOVERY_MOTION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('gait', 'tools/animation/gait_check.gd', r'GAIT_CHECK_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('comfort-ui', 'tools/ui/comfort_ui_check.gd', r'COMFORT_UI PASS \(0 failures; mutation=\)', [], 0),
    ('match-lifecycle', 'tools/match/match_lifecycle_check.gd', r'MATCH_LIFECYCLE PASS \([1-9][0-9]* checks, 0 failures; mutation=\)', [], 0),
    ('weighted-swing', 'tools/grapple/weighted_swing_check.gd', r'WEIGHTED_SWING_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('ultimate-wave', 'tools/skills/ultimate_wave_check.gd', r'ULTIMATE_WAVE_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('combat-identity', 'tools/animation/combat_identity_check.gd', r'COMBAT_IDENTITY checks=[1-9][0-9]* failures=0', [], 0),
    ('combat-presentation', 'tools/animation/combat_presentation_check.gd', r'COMBAT_PRESENTATION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('combat-control', 'tools/combat/control_check.gd', r'COMBAT_CONTROL_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('traversal', 'tools/grapple/traversal_check.gd', r'TRAVERSAL_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('dodge-stamina', 'tools/combat/dodge_stamina_check.gd', r'DODGE_STAMINA_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('music', 'tools/audio/music_check.gd', r'\[music\] failures=0', [], 0),
    ('district-life', 'tools/npc/district_life_check.gd', r'\[district-life\] [1-9][0-9]* checks / 0 failures', [], 0),
    ('district-progress', 'tools/npc/district_progress_check.gd', r'\[district-progress\] [1-9][0-9]* checks / 0 failures', [], 0),
    ('npc', 'tools/npc/npc_check.gd', r'\[npc\] [0-9]+ checks / 0 failures', [], 0),
    ('npc-runtime', 'tools/npc/npc_runtime_check.gd', r'\[npc-runtime\] [0-9]+ checks / 0 failures', [], 0),
    ('npc-appearance', 'tools/npc/appearance_check.gd', r'\[npc-appearance\] stable seeds, role independence, humanoid build, locomotion OK', [], 0),
    ('city-geometry', 'tools/world/city_geometry_check.gd', r'CITY_GEOMETRY_COMPLETE checks=[1-9][0-9]* failures=0 meshes=[1-9][0-9]*', [], 0),
    ('city-runtime', 'tools/world/city_runtime_check.gd', r'CITY_RUNTIME_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('city-onboarding', 'tools/world/city_onboarding_check.gd', r'CITY_ONBOARDING_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
]
for mutation in ('portrait', 'icon', 'input'):
    cases.append(('ui-negative-' + mutation, 'tools/ui/layout_check.gd',
                  rf'UI_LAYOUT FAIL \([1-9][0-9]* failures; mutation={mutation}\)',
                  ['--', '--break=' + mutation], 1))
for mutation in ('footer', 'focus', 'bounds'):
    cases.append(('comfort-ui-negative-' + mutation, 'tools/ui/comfort_ui_check.gd',
                  rf'COMFORT_UI FAIL \([1-9][0-9]* failures; mutation={mutation}\)',
                  ['--', '--break=' + mutation], 1))
for mutation in ('opponent_frame', 'orbit', 'facing'):
    cases.append(('free-movement-negative-' + mutation, 'tools/input/free_movement_check.gd',
                  rf'FREE_MOVEMENT_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
for mutation in ('round', 'rematch', 'score'):
    cases.append(('match-lifecycle-negative-' + mutation, 'tools/match/match_lifecycle_check.gd',
                  rf'MATCH_LIFECYCLE FAIL \([1-9][0-9]* checks, [1-9][0-9]* failures; mutation={mutation}\)',
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
    # Only named negative controls may print their scoped deliberate assertion errors.
    # Shader, resource, compiler and other runtime errors cannot hide behind a success sentinel.
    complete = re.search('^' + sentinel + '$', output, re.MULTILINE) is not None
    errors = [line.strip() for line in output.splitlines()
              if re.match(r'^\s*(?:SCRIPT ERROR|ERROR):', line)]
    assertion_prefix = None
    for scope, prefix in (('ui-negative-', 'ERROR: UI_LAYOUT: '),
                          ('comfort-ui-negative-', 'ERROR: COMFORT_UI: '),
                          ('free-movement-negative-', 'ERROR: FREE_MOVEMENT: '),
                          ('match-lifecycle-negative-', 'ERROR: MATCH_LIFECYCLE: ')):
        if name.startswith(scope):
            assertion_prefix = prefix
    unexpected = [line for line in errors
                  if expected_rc == 0 or assertion_prefix is None or not line.startswith(assertion_prefix)]
    ok = rc == expected_rc and complete and not unexpected and 'SCRIPT ERROR' not in output
    print(f'PLAYABLE {name}: {"PASS" if ok else "FAIL"} rc={rc} log={path}', flush=True)
    if not ok:
        failures += 1
        print(output[-12000:], flush=True)
print(f'PLAYABLE CHECK: {len(cases)} scenarios, {failures} failures', flush=True)
sys.exit(1 if failures else 0)
PY
