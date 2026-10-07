#!/usr/bin/env bash
# Serial presentation regressions. A frame cap or successful process exit is not a PASS.
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export GODOT_BIN="${GODOT_BIN:-godot}"
python3 - <<'PY'
import os
from contextlib import contextmanager, ExitStack
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
    ('city-lower-story', 'tools/world/city_lower_story_check.gd', r'CITY_LOWER_STORY_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('city-lower-gallery', 'tools/world/city_lower_gallery_check.gd', r'CITY_LOWER_GALLERY_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('city-story', 'tools/world/city_story_check.gd', r'CITY_STORY_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('city-maintenance', 'tools/world/city_maintenance_check.gd', r'CITY_MAINTENANCE_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('weapon-craft', 'tools/animation/weapon_craft_check.gd', r'WEAPON_CRAFT_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('npc-clothing', 'tools/npc/clothing_check.gd', r'NPC_CLOTHING_COMPLETE checks=[1-9][0-9]* failures=0 max_meshes=[1-9][0-9]* max_triangles=[1-9][0-9]* max_hinges=[1-9][0-9]*', [], 0),
    ('hero-gear', 'tools/equipment/hero_gear_check.gd', r'HERO_GEAR_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('whole-body-motion', 'tools/animation/whole_body_motion_check.gd', r'WHOLE_BODY_MOTION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('ground-contact', 'tools/animation/ground_contact_check.gd', r'GROUND_CONTACT_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('physics-motion', 'tools/animation/physics_motion_check.gd', r'PHYSICS_MOTION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('city-journey', 'tools/world/city_journey_check.gd', r'CITY_JOURNEY_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('quest-tracking', 'tools/npc/quest_tracking_check.gd', r'\[quest-tracking\] [1-9][0-9]* checks / 0 failures', [], 0),
    ('quest-journal', 'tools/ui/quest_journal_check.gd', r'QUEST_JOURNAL_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('ui', 'tools/ui/layout_check.gd', r'UI_LAYOUT PASS \(0 failures; mutation=\)', [], 0),
    ('district-ui', 'tools/ui/district_ui_check.gd', r'DISTRICT_UI_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('city-controls', 'tools/ui/city_controls_check.gd', r'CITY_CONTROLS_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('locomotion-states', 'tools/animation/locomotion_states_check.gd', r'LOCOMOTION_STATES_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('authored-evasion', 'tools/animation/authored_evasion_check.gd', r'AUTHORED_EVASION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('authored-combat', 'tools/animation/authored_combat_check.gd', r'AUTHORED_COMBAT_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('motion', 'tools/animation/character_motion_check.gd', r'CHARACTER MOTION: [1-9][0-9]* checks, 0 failures', [], 0),
    ('idle', 'tools/animation/idle_presence_check.gd', r'IDLE PRESENCE: [1-9][0-9]* checks, 0 failures', [], 0),
    ('afterimage', 'tools/fx/afterimage_check.gd', r'afterimage: [1-9][0-9]* checks, 0 failures', [], 0),
    ('splash', 'tools/fx/water_splash_check.gd', r'SPLASH CHECK: 0 failures', [], 0),
    ('contact', 'tools/fx/water_contact_check.gd', r'WATER CONTACT CHECK: 0 failures', [], 0),
    ('camera', 'tools/camera/framing_check.gd', r'CAMERA_FRAMING: [1-9][0-9]* checks, 0 failures', [], 0),
    ('city-camera', 'tools/camera/city_camera_check.gd', r'CITY_CAMERA_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('tight-station', 'tools/camera/tight_station_probe.gd', r'TIGHT_STATION_COMPLETE checks=[1-9][0-9]* failures=0 mode=none', ['--', '--check'], 0),
    ('conversation-camera', 'tools/camera/conversation_camera_check.gd', r'CONVERSATION_CAMERA_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('impact', 'tools/camera/impact_check.gd', r'impact-check: OK \([1-9][0-9]* checks, 0 failures\)', [], 0),
    ('foot', 'tools/animation/foot_contact_check.gd', r'FOOT CONTACT: [1-9][0-9]* checks, 0 failures', [], 0),
    ('audio', 'tools/audio/sfx_check.gd', r'sfx-check: OK \([1-9][0-9]* checks, 0 failures\)', [], 0),
    ('comfort-settings', 'tools/settings/comfort_check.gd', r'COMFORT_CHECK_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('graphics-settings', 'tools/settings/graphics_check.gd', r'GRAPHICS_CHECK_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('graphics-ui', 'tools/ui/graphics_ui_check.gd', r'GRAPHICS_UI_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('graphics-independent', 'tools/settings/graphics_independent_check.gd', r'T4_GRAPHICS_COMPLETE checks=[1-9][0-9]* failures=0 mutation=', [], 0),
    ('comfort-input', 'tools/input/comfort_input_check.gd', r'COMFORT_INPUT_CHECK checks=[1-9][0-9]* failures=0', [], 0),
    ('free-movement', 'tools/input/free_movement_check.gd', r'FREE_MOVEMENT_COMPLETE checks=[1-9][0-9]* failures=0 mutation=', [], 0),
    ('limb-input', 'tools/input/limb_input_check.gd', r'LIMB_INPUT_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('limb-combat', 'tools/input/limb_combat_check.gd', r'LIMB_COMBAT_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('sword-state', 'tools/weapon/sword_state_check.gd', r'SWORD_STATE_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('sword-presentation', 'tools/animation/sword_presentation_check.gd', r'SWORD_PRESENTATION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('harpoon', 'tools/grapple/harpoon_check.gd', r'HARPOON_CHECK checks=[1-9][0-9]* failures=0', [], 0),
    ('rope-contact', 'tools/grapple/contact_check.gd', r'ROPE_CONTACT_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('harpoon-aim', 'tools/aim/harpoon_aim_check.gd', r'HARPOON_AIM_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('rope-visual', 'tools/grapple/rope_visual_check.gd', r'ROPE_VISUAL_CHECK_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('rope-recovery', 'tools/animation/rope_recovery_motion_check.gd', r'ROPE_RECOVERY_MOTION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('hero-face', 'tools/animation/hero_face_check.gd', r'HERO_FACE_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('city-hook-gear', 'tools/animation/city_hook_gear_check.gd', r'CITY_HOOK_GEAR_COMPLETE checks=[1-9][0-9]* failures=0 samples=276', [], 0),
    ('authored-hook', 'tools/animation/authored_hook_check.gd', r'AUTHORED_HOOK_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('parkour-motion', 'tools/animation/parkour_motion_check.gd', r'PARKOUR_MOTION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('trick-motion', 'tools/animation/trick_motion_check.gd', r'TRICK_MOTION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('gait', 'tools/animation/gait_check.gd', r'GAIT_CHECK_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('comfort-ui', 'tools/ui/comfort_ui_check.gd', r'COMFORT_UI PASS \(0 failures; mutation=\)', [], 0),
    ('match-lifecycle', 'tools/match/match_lifecycle_check.gd', r'MATCH_LIFECYCLE PASS \([1-9][0-9]* checks, 0 failures; mutation=\)', [], 0),
    ('weighted-swing', 'tools/grapple/weighted_swing_check.gd', r'WEIGHTED_SWING_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('ultimate-wave', 'tools/skills/ultimate_wave_check.gd', r'ULTIMATE_WAVE_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('combat-identity', 'tools/animation/combat_identity_check.gd', r'COMBAT_IDENTITY checks=[1-9][0-9]* failures=0', [], 0),
    ('combat-presentation', 'tools/animation/combat_presentation_check.gd', r'COMBAT_PRESENTATION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('combat-control', 'tools/combat/control_check.gd', r'COMBAT_CONTROL_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('combat-intent', 'tools/combat/intent_check.gd', r'COMBAT_INTENT_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('traversal', 'tools/grapple/traversal_check.gd', r'TRAVERSAL_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('city-parkour', 'tools/parkour/city_parkour_check.gd', r'CITY_PARKOUR_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('city-tricks', 'tools/parkour/city_tricks_check.gd', r'CITY_TRICKS_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('tricks-independent', 'tools/parkour/tricks_independent_check.gd', r'T4_TRICKS_COMPLETE checks=[1-9][0-9]* failures=0 mutation=', [], 0),
    ('dodge-stamina', 'tools/combat/dodge_stamina_check.gd', r'DODGE_STAMINA_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('music', 'tools/audio/music_check.gd', r'\[music\] failures=0', [], 0),
    ('district-life', 'tools/npc/district_life_check.gd', r'\[district-life\] [1-9][0-9]* checks / 0 failures', [], 0),
    ('district-progress', 'tools/npc/district_progress_check.gd', r'\[district-progress\] [1-9][0-9]* checks / 0 failures', [], 0),
    ('district-quest-hooks', 'tools/npc/remaining_quest_hooks_check.gd', r'T4_REMAINING_HOOKS_COMPLETE checks=[1-9][0-9]* failures=0 credits=21', [], 0),
    ('district-save-negative', 'tools/npc/save_content_negative_check.gd', r'T4_NEGATIVE_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('npc-save-negative', 'tools/npc/npc_save_negative_check.gd', r'T4_NPC_SAVE_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('npc', 'tools/npc/npc_check.gd', r'\[npc\] [0-9]+ checks / 0 failures', [], 0),
    ('npc-runtime', 'tools/npc/npc_runtime_check.gd', r'\[npc-runtime\] [0-9]+ checks / 0 failures', [], 0),
    ('npc-close', 'tools/npc/npc_close_conversation_check.gd', r'\[npc-close\] [1-9][0-9]* checks / 0 failures', [], 0),
    ('npc-local', 'tools/npc/npc_local_conversation_check.gd', r'\[npc-local\] [1-9][0-9]* checks / 0 failures', [], 0),
    ('npc-appearance', 'tools/npc/appearance_check.gd', r'\[npc-appearance\] stable seeds, role independence, humanoid build, locomotion OK', [], 0),
    ('npc-presentation', 'tools/npc/presentation_check.gd', r'NPC_PRESENTATION_COMPLETE checks=[1-9][0-9]* failures=0 max_parts=[1-9][0-9]* max_triangles=[1-9][0-9]*', [], 0),
    ('npc-chatter-mix', 'tools/npc/chatter_mix_check.gd', r'NPC_MIX_COMPLETE passed=true', [], 0),
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
cases.append(('graphics-independent-negative-apply', 'tools/settings/graphics_independent_check.gd',
              r'T4_GRAPHICS_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation=apply',
              ['--', '--break=apply'], 1))
cases.append(('tricks-independent-negative-budget', 'tools/parkour/tricks_independent_check.gd',
              r'T4_TRICKS_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation=budget',
              ['--', '--break=budget'], 1))
# Tight-support camera: pre-fix instant recovery, a drifted k=50, dither to nothing and the old ledge site must go red.
# Iteration 2: opaque hull in the dither holes, a non-exact hull back at full fill, residents unfaded at the
# lens and resident 7 on its old lane across the practice landing must go red too.
for mutation in ('damping', 'recovery50', 'floor', 'station', 'mask', 'restore', 'resident', 'lane'):
    cases.append(('tight-station-negative-' + mutation, 'tools/camera/tight_station_probe.gd',
                  rf'TIGHT_STATION_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mode={mutation}',
                  ['--', '--check', '--break=' + mutation], 1))
# City step 0: no sealed-skill hint, no throttle, no modal from the city pause, no return to the pause must go red.
for mutation in ('signal', 'interval', 'comfort', 'focus'):
    cases.append(('city-controls-negative-' + mutation, 'tools/ui/city_controls_check.gd',
                  rf'CITY_CONTROLS_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
@contextmanager
def isolated_profile():
    # Linux has an OS-supported data root override. macOS does not: use Godot's
    # custom user directory in a disposable project mirror and native data root.
    env = os.environ.copy()
    custom = sys.platform == 'darwin' or env.get('PLAYABLE_CUSTOM_USER_DIR') == '1'
    with ExitStack() as cleanup:
        if sys.platform.startswith('linux'):
            temporary = Path(cleanup.enter_context(tempfile.TemporaryDirectory(prefix='nir-playable-user-')))
            data_root = temporary / 'data'
            data_root.mkdir()
            env['XDG_DATA_HOME'] = str(data_root)
        elif sys.platform == 'darwin':
            data_root = Path.home() / 'Library' / 'Application Support'
        else:
            raise RuntimeError('save isolation currently supports Linux and macOS')
        if not custom:
            yield Path('game'), env
            return
        # Reserve an unpredictable native directory; only this owned directory is removed.
        user_dir = Path(cleanup.enter_context(tempfile.TemporaryDirectory(prefix='nir-playable-user-', dir=data_root)))
        mirror = Path(cleanup.enter_context(tempfile.TemporaryDirectory(prefix='nir-playable-project-')))
        source = Path('game').resolve()
        for child in source.iterdir():
            if child.name not in ('project.godot', 'override.cfg'):
                (mirror / child.name).symlink_to(child, target_is_directory=child.is_dir())
        shutil.copy2(source / 'project.godot', mirror / 'project.godot')
        # runtime-only project override; assets, scripts and the imported cache are reused.
        (mirror / 'override.cfg').write_text(
            '[application]\nconfig/use_custom_user_dir=true\n'
            f'config/custom_user_dir_name="{user_dir.name}"\n')
        yield mirror, env

failures = 0
for name, script, sentinel, args, expected_rc in cases:
    command = [binary, '--headless', '--audio-driver', 'Dummy', '--path', 'game',
               '--fixed-fps', '60', '--quit-after', '12000', '--script', str(Path(script).resolve()), *args]
    try:
        # Every scenario owns its saves, including real exit/re-entry within that case.
        # Never let fixture checkpoints leak into another scenario or the player's profile.
        with isolated_profile() as (project_path, child_env):
            command[command.index('--path') + 1] = str(project_path)
            result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    text=True, timeout=180, env=child_env)
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
                          ('graphics-independent-negative-', 'ERROR: T4_GRAPHICS: '),
                          ('tricks-independent-negative-', 'ERROR: T4_TRICKS: '),
                          ('tight-station-negative-', 'ERROR: TIGHT_STATION: '),
                          ('city-controls-negative-', 'ERROR: CITY_CONTROLS: '),
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
