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
    # Headless has no pixels: the run must say S5 was not measured, right before its sentinel (T4 audit 2026-10-07).
    ('tight-station', 'tools/camera/tight_station_probe.gd', r'TIGHT_STATION S5=NOT MEASURED \(headless\)\nTIGHT_STATION_COMPLETE checks=[1-9][0-9]* failures=0 mode=none', ['--', '--check'], 0),
    ('conversation-camera', 'tools/camera/conversation_camera_check.gd', r'CONVERSATION_CAMERA_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('impact', 'tools/camera/impact_check.gd', r'impact-check: OK \([1-9][0-9]* checks, 0 failures\)', [], 0),
    ('foot', 'tools/animation/foot_contact_check.gd', r'FOOT CONTACT: [1-9][0-9]* checks, 0 failures', [], 0),
    ('audio', 'tools/audio/sfx_check.gd', r'sfx-check: OK \([1-9][0-9]* checks, 0 failures\)', [], 0),
    ('comfort-settings', 'tools/settings/comfort_check.gd', r'COMFORT_CHECK_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('graphics-settings', 'tools/settings/graphics_check.gd', r'GRAPHICS_CHECK_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('graphics-ui', 'tools/ui/graphics_ui_check.gd', r'GRAPHICS_UI_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('graphics-independent', 'tools/settings/graphics_independent_check.gd', r'T4_GRAPHICS_COMPLETE checks=[1-9][0-9]* failures=0 mutation=', [], 0),
    ('display-auto', 'tools/settings/display_auto_check.gd', r'DISPLAY_AUTO_COMPLETE checks=[1-9][0-9]* failures=0 mutation=', [], 0),
    # Colour test switch A / B3 (plan 2026-10-14-T6-Acceptance-Crane-Albedo-AB step 8): A by default, saved next to the
    # profile, unknown or damaged → A with the bytes kept, the COLOURS (TEST) row. Headless renders nothing: the run must
    # say the frame check of the five shaders was not measured (docs/Fix/2026-10-15-Colour-Switch-Fix.md).
    ('colour-switch', 'tools/settings/colour_switch_check.gd', r'COLOUR_SWITCH_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none red=none rs=not-measured-headless', [], 0),
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
    # Living body (plan 2026-10-07-Living-Body, step 1): R1/R7/R8/J1-J3 drawn over the authority, the duel unchanged.
    ('living-body', 'tools/animation/living_body_check.gd', r'LIVING_BODY_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('gait', 'tools/animation/gait_check.gd', r'GAIT_CHECK_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('comfort-ui', 'tools/ui/comfort_ui_check.gd', r'COMFORT_UI PASS \(0 failures; mutation=\)', [], 0),
    ('match-lifecycle', 'tools/match/match_lifecycle_check.gd', r'MATCH_LIFECYCLE PASS \([1-9][0-9]* checks, 0 failures; mutation=\)', [], 0),
    ('lethal-fight', 'tools/match/lethal_fight_check.gd', r'LETHAL_FIGHT_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('blood-content', 'tools/fx/blood_content_check.gd', r'BLOOD_CONTENT_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('weighted-swing', 'tools/grapple/weighted_swing_check.gd', r'WEIGHTED_SWING_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('ultimate-wave', 'tools/skills/ultimate_wave_check.gd', r'ULTIMATE_WAVE_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('combat-identity', 'tools/animation/combat_identity_check.gd', r'COMBAT_IDENTITY checks=[1-9][0-9]* failures=0', [], 0),
    ('combat-presentation', 'tools/animation/combat_presentation_check.gd', r'COMBAT_PRESENTATION_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('combat-control', 'tools/combat/control_check.gd', r'COMBAT_CONTROL_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('combat-intent', 'tools/combat/intent_check.gd', r'COMBAT_INTENT_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('traversal', 'tools/grapple/traversal_check.gd', r'TRAVERSAL_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    # Aim-free rope (plan 2026-10-07-Aim-Free-Rope, T8 variant Г): the selection, the refusal and the district coverage.
    ('auto-hook', 'tools/grapple/auto_hook_check.gd', r'AUTO_HOOK_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    # Rope V4 and the jump arc С2 (plan 2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum steps 1–2): the city hook pulls
    # the hero in to a swing; one arc per jump, T5 guards G1–G4.
    ('rope-pull', 'tools/grapple/rope_pull_check.gd', r'ROPE_PULL_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none red=none', [], 0),
    ('jump-arc', 'tools/animation/jump_arc_check.gd', r'JUMP_ARC_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none red=none', [], 0),
    # Animation feel, branch B (plan 2026-10-09-Animation-Feel-Landing-Rope-Stop-Wall steps 0, 4, 5): the rope, Skea's
    # wall run, the ledge and the roll of both heroes on the T6 stations. Two items stay open and pinned: the post contact
    # (geometry, back with T1) and the light landing after the mantle (LivingBodyMotion landings, branch A).
    ('anim-traversal', 'tools/animation/anim_traversal_check.gd', r'ANIM_TRAVERSAL_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none red=none open=ledge_land,rope_post', [], 0),
    # Animation feel, branch A (plan 2026-10-09-Animation-Feel-Landing-Rope-Stop-Wall steps 0–3): stops, reverse, turn,
    # landings and the wall kick on the ground and in transitions — bone ≤ 30°/tick, planted foot ≤ 50 mm, no frozen pose.
    ('anim-ground', 'tools/animation/anim_ground_check.gd', r'ANIM_GROUND_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none red=none', [], 0),
    ('anchor-coverage', 'tools/world/anchor_coverage.gd', r'ANCHOR_COVERAGE_COMPLETE checks=[1-9][0-9]* failures=0 anchors=[1-9][0-9]* t8=[0-9]+/[0-9]+ real=[0-9]+/[0-9]+ roofs=([0-9]+)/\1 supports=([0-9]+)/\2', [], 0),
    ('city-parkour', 'tools/parkour/city_parkour_check.gd', r'CITY_PARKOUR_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('city-tricks', 'tools/parkour/city_tricks_check.gd', r'CITY_TRICKS_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('tricks-independent', 'tools/parkour/tricks_independent_check.gd', r'T4_TRICKS_COMPLETE checks=[1-9][0-9]* failures=0 mutation=', [], 0),
    # Living body step 2: P1 vault, P4 side wall run, P5 ledge shimmy, P8 heavy landing (picture only).
    ('parkour-moves', 'tools/parkour/parkour_moves_check.gd', r'PARKOUR_MOVES_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
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
    # City tidy-up and the first props (plan 2026-10-09-City-Tidy-And-Modern-Props, phase 0): panes, support, z-fight,
    # duplicates, solidity, the T6 places, real-key vaults of both heroes and the steam puffs.
    ('city-tidy', 'tools/world/city_tidy_check.gd', r'CITY_TIDY_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none red=none', [], 0),
    ('city-runtime', 'tools/world/city_runtime_check.gd', r'CITY_RUNTIME_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    ('city-onboarding', 'tools/world/city_onboarding_check.gd', r'CITY_ONBOARDING_COMPLETE checks=[1-9][0-9]* failures=0', [], 0),
    # City events, stage 1 (plan 2026-10-08-City-Events-Stage-1, steps 1–5): the director, the alley, the leaves and
    # the drugs key, the haze state, tokens as money.
    ('city-event-director', 'tools/world/city_event_director_check.gd', r'CITY_EVENT_DIRECTOR_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('city-alley', 'tools/world/city_alley_check.gd', r'CITY_ALLEY_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('city-leaves', 'tools/world/city_leaves_check.gd', r'CITY_LEAVES_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('city-haze', 'tools/world/city_haze_check.gd', r'CITY_HAZE_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('city-economy', 'tools/npc/city_economy_check.gd', r'CITY_ECONOMY_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    # T8 GAP 1–4 of the event menus (06-UI-UX § «Випадки міста: COMFORT і HUD» п. 3) and the hunger scale (plan
    # 2026-10-08-Survival-Hunger step 4: T5 § 9, Santos «Повний перенос», the T8 HUD).
    ('city-event-menus', 'tools/world/city_event_menus_check.gd', r'CITY_EVENT_MENUS_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('city-hunger', 'tools/world/city_hunger_check.gd', r'CITY_HUNGER_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    # Thirst, substance states, the strength buff and item icons (plan 2026-10-08-Thirst-Substances-Icons steps 1–3).
    ('city-thirst', 'tools/world/city_thirst_check.gd', r'CITY_THIRST_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('city-substances', 'tools/world/city_substances_check.gd', r'CITY_SUBSTANCES_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('city-substances-route', 'tools/world/city_substances_check.gd', r'CITY_SUBSTANCES_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', ['--', '--part=route'], 0),
    ('glyph-coverage', 'tools/ui/glyph_coverage_check.gd', r'GLYPH_COVERAGE_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
    ('item-icons', 'tools/ui/item_icons_check.gd', r'ITEM_ICONS_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0),
]
for mutation in ('portrait', 'icon', 'input'):
    cases.append(('ui-negative-' + mutation, 'tools/ui/layout_check.gd',
                  rf'UI_LAYOUT FAIL \([1-9][0-9]* failures; mutation={mutation}\)',
                  ['--', '--break=' + mutation], 1))
for mutation in ('footer', 'focus', 'bounds'):
    cases.append(('comfort-ui-negative-' + mutation, 'tools/ui/comfort_ui_check.gd',
                  rf'COMFORT_UI FAIL \([1-9][0-9]* failures; mutation={mutation}\)',
                  ['--', '--break=' + mutation], 1))
# T8 2026-10-15 § 3 (docs/Fix/2026-10-15-Comfort-Colour-Row-Fold-Fix.md): the panel opens on MASTER, so MASTER and its
# title must be seen at open on every canvas. Content above it growing (a 2-line label at 24 px), the visible part
# shrinking, the open landing on another row, the title scrolled away and the scroll off 0 must each go red in their family.
for mutation, family in (('master_label', 'master_slider'), ('master_window', 'master_slider'),
                         ('master_focus', 'master_focus'), ('master_title', 'master_title'),
                         ('open_scrolled', 'open_top')):
    cases.append(('comfort-ui-negative-' + mutation, 'tools/ui/comfort_ui_check.gd',
                  rf'COMFORT_UI_FAMILIES failures=[1-9][0-9]* mutation={mutation} red=[a-z_,]*\b{family}\b[a-z_,]*',
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
# Lethal pocket (ADR-024): sparring turned lethal, HP that does not carry (full / none / into a retry), an enemy that
# never dies or dies at the first KO, a lethal clock, residents that stay or never return, skills sealed in the pocket
# (all three, or only skill2 and the ultimate after an open skill1) or open outside it, a city camera left off and a
# CPU that backs into the wall must each go red.
for mutation in ('sparring', 'carry', 'carry_none', 'retry_carry', 'death', 'early_death', 'clock', 'npc', 'npc_return', 'skills', 'skills_late', 'outside', 'exit', 'edge'):
    cases.append(('lethal-fight-negative-' + mutation, 'tools/match/lethal_fight_check.gd',
                  rf'LETHAL_FIGHT_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
# Blood and content (ADR-024 п. 4, п. 7): blood in a sparring, a damaged content.cfg saved over, a Reduced hit flash at
# full strength, a card that is not remembered, a step back from the card that counts as seen, blood on a block, Off
# that still bleeds, Ink that still drops, blood drawing the shared presentation RNG, a puddle from a late blow after
# the round is decided, blood that changes the fight and blood that moves a fighter's RNG must each go red.
# DRUGS (T8 Д3): a DRUGS row that never calls set_drugs_mode must go red too.
for mutation in ('sparring', 'cfg', 'flash', 'notice', 'back', 'block', 'mode', 'ink', 'rng', 'late', 'state', 'rng_state', 'drugs_row'):
    cases.append(('blood-content-negative-' + mutation, 'tools/fx/blood_content_check.gd',
                  rf'BLOOD_CONTENT_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
# DISPLAY / AUTO (plan 2026-10-07-Auto-Display-And-Quality step 4): a damaged graphics.cfg saved over, a fullscreen
# combination that toggles in a fight, a saved preset migrated to AUTO, a frame-time controller running headless and
# an upscaler requested without checking it exists must each go red.
for mutation in ('cfg', 'combat_key', 'migrate', 'headless_controller', 'upscaler'):
    cases.append(('display-auto-negative-' + mutation, 'tools/settings/display_auto_check.gd',
                  rf'DISPLAY_AUTO_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
# Aim-free rope (N10): the base selection, a press that fires into empty air, a launch without the re-check and no
# 0.25 s switch delay must each go red.
for mutation in ('base', 'empty_shot', 'no_recheck', 'lock', 'nopull'):
    cases.append(('auto-hook-negative-' + mutation, 'tools/grapple/auto_hook_check.gd',
                  rf'AUTO_HOOK_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
# Rope V4: no pull (HEAD's contract), the rope at its target in one tick (V3), a rope let out, the pull and Space summed
# in one tick must each go red in their own family. Own support (T1 after steps 1–4): the lamp post back in the hang's
# check, the next lamp's post named instead, every solid within 6 m skipped. Help: the pull left out of the pause, a
# wrong reel limit, the old «Get closer beneath an anchor for lift» back. Jump arc: the 2026-10-08 blends, no tuck,
# the light landing at ×2.5.
for mutation, family in (('nopull', 'target'), ('snap', 'step'), ('lengthen', 'lengthen'), ('sum', 'rate'),
                         ('own', 'own'), ('wrong', 'own'), ('wide', 'cover'),
                         ('help_nopull', 'help'), ('help_reel', 'help'), ('help_lift', 'help')):
    cases.append(('rope-pull-negative-' + mutation, 'tools/grapple/rope_pull_check.gd',
                  rf'ROPE_PULL_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z,]*\b{family}\b[a-z,]*',
                  ['--', '--hero=choko', '--break=' + mutation], 1))
# Plan 2026-10-14-Quality-Debt-Posts-Awning-Guards step 2 (T2-A): «chosen — not cut» — for every anchor and the positions
# it is picked from, a real E press hangs and the first hanging tick keeps the rope. Both heroes; the 12000-frame budget
# split in five parts (the route in part 1); the OPEN first-tick cuts are pinned in the fixture. Negatives: the grocer's
# spread awning back, a plate across the line on the contact tick, the projectile at a quarter of its speed.
for hero in ('choko', 'skea'):
    for part in range(1, 6):
        cases.append((f'rope-choice-{hero}-{part}', 'tools/grapple/rope_choice_check.gd',
                      rf'ROPE_CHOICE_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none part={part}/5 anchors=([0-9]+)/\1 presses=[1-9][0-9]* hangs=[1-9][0-9]* cut_first=[0-9]+ open=[0-9]+ rewinds=[0-9]+ red=none',
                      ['--', f'--hero={hero}', f'--part={part}/5'], 0))
for mutation, family in (('awning', 'cut'), ('late_wall', 'cut'), ('flight', 'cut')):
    cases.append(('rope-choice-negative-' + mutation, 'tools/grapple/rope_choice_check.gd',
                  rf'ROPE_CHOICE_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} part=1/5 anchors=[0-9]+/[0-9]+ presses=[0-9]+ hangs=[0-9]+ cut_first=[0-9]+ open=[0-9]+ rewinds=[0-9]+ red=[a-z,]*\b{family}\b[a-z,]*',
                  ['--', '--hero=choko', '--part=1/5', '--break=' + mutation], 1))
# Step 3: R3 — every anchor skips every lamp post, so the foreign post on the line holds the rope; «in the air» — a
# counter and a wall the swing on anchor 0 comes to rest against.
for mutation, family in (('all_posts', 'foreign'), ('counter', 'air'), ('wall', 'air')):
    cases.append(('rope-pull-negative-' + mutation, 'tools/grapple/rope_pull_check.gd',
                  rf'ROPE_PULL_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z,]*\b{family}\b[a-z,]*',
                  ['--', '--hero=choko', '--break=' + mutation], 1))
# Step 4: V+ — an unlisted 1.0 m crate, one at the band's bottom 0.6 m, and a listed step moved 0.3 m must each go red.
for mutation, family in (('step_new', 'vstep'), ('step_low', 'vstep'), ('step_moved', 'vstep')):
    cases.append(('city-tidy-negative-' + mutation, 'tools/world/city_tidy_check.gd',
                  rf'CITY_TIDY_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z0-9,]*\b{family}\b[a-z0-9,]*',
                  ['--', '--break=' + mutation], 1))
# Animation feel, branch B: the product of main 595490d, and each change switched back alone — no transition blend, the
# duel's 0.28 rope lean, the camera arm stopped by the anchor's own post, the old wall-run clock, a still hang and a
# lifted mantle, the authored roll — must each go red in its own family.
cases.append(('anim-traversal-negative-main', 'tools/animation/anim_traversal_check.gd',
              r'ANIM_TRAVERSAL_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation=main red='
              + ''.join(rf'(?=[a-z_,]*\b{family}\b)' for family in ('rope_turn', 'rope_lean', 'rope_arm', 'ledge_turn',
                                                                     'ledge_frozen', 'ledge_lift', 'wall_turn', 'roll_turn'))
              + r'[a-z_,]* open=ledge_land,rope_post', ['--', '--break=main'], 1))
for mutation, family in (('blend', 'ledge_turn'), ('lean', 'rope_lean'), ('camera', 'rope_arm'), ('wall', 'wall_turn'),
                         ('ledge', 'ledge_lift'), ('roll', 'roll_turn')):
    cases.append(('anim-traversal-negative-' + mutation, 'tools/animation/anim_traversal_check.gd',
                  rf'ANIM_TRAVERSAL_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z_,]*\b{family}\b[a-z_,]* open=ledge_land,rope_post',
                  ['--', '--break=' + mutation], 1))
for mutation, family in (('blend', 'G2'), ('tuck', 'G1'), ('land', 'G4depth')):
    cases.append(('jump-arc-negative-' + mutation, 'tools/animation/jump_arc_check.gd',
                  rf'JUMP_ARC_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[A-Za-z0-9,]*\b{family}\b[A-Za-z0-9,]*',
                  ['--', '--break=' + mutation], 1))
# Jump arc G1time (T4 audit 2026-10-09 proposal 3, plan 2026-10-14 step 5): T4's J10 (a 3–4 tick tuck), the tuck two
# ticks late (С1) and held until 0.06 s before the ground (С2) must each go red in G1time.
for mutation in ('j10', 'tuck_late', 'tuck_long'):
    cases.append(('jump-arc-negative-' + mutation, 'tools/animation/jump_arc_check.gd',
                  rf'JUMP_ARC_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[A-Za-z0-9,]*\bG1time\b[A-Za-z0-9,]*',
                  ['--', '--break=' + mutation], 1))
# Animation feel, branch A: the product of 595490d put back one part at a time must go red in its own family — the
# landing played to its straight end with the hold (hips), the heavy landing's sliding kneel (foot), the guard at full
# weight on the first idle tick (bone), the stance foot let go in one tick (foot), the legs chosen for the gameplay
# course with the 420°/s turn (legs), the wall-kick heading in one tick (wall). The merge of A and B, one seam at a time:
# TraversalBlend blending the kick's first tick while the node flips, the kick remembering the pose before TraversalBlend
# drew it (the early kick), TraversalBlend handing the kick over without following the drawn pose — each red in wall.
for mutation, family in (('land', 'hips'), ('kneel', 'foot'), ('guard', 'bone'), ('foot', 'foot'), ('legs', 'legs'), ('kick', 'wall'),
                         ('yield', 'wall'), ('memory', 'wall'), ('follow', 'wall')):
    cases.append(('anim-ground-negative-' + mutation, 'tools/animation/anim_ground_check.gd',
                  rf'ANIM_GROUND_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z,]*\b{family}\b[a-z,]*',
                  ['--', '--break=' + mutation], 1))
# Living body: a presented pose left on the mannequin, a stun frame, a capsule-RNG draw or invulnerability leaked into
# the fight, mirrored hit sides, a flinch clip that does not follow the hitstun, the get-up drawn by the authority alone,
# every landing drawn as light, a deferred callback that forgets the living pose and a kept pose that makes the sword
# transfer land twice must each go red.
for mutation in ('pose', 'state', 'rng', 'hurtbox', 'side', 'fill', 'getup', 'tier', 'deferred', 'transfer'):
    cases.append(('living-body-negative-' + mutation, 'tools/animation/living_body_check.gd',
                  rf'LIVING_BODY_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
# Parkour moves: a vault over a 1.5 m obstacle, a vault onto a 1 m drop, a side run at 45° to the wall and a shimmy
# whose grips leave the ledge must each go red.
for mutation in ('vault_height', 'vault_floor', 'side_angle', 'shimmy_grip'):
    cases.append(('parkour-moves-negative-' + mutation, 'tools/parkour/parkour_moves_check.gd',
                  rf'PARKOUR_MOVES_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
# City step 0: no sealed-skill hint, no throttle, no modal from the city pause, no return to the pause must go red.
for mutation in ('signal', 'interval', 'comfort', 'focus'):
    cases.append(('city-controls-negative-' + mutation, 'tools/ui/city_controls_check.gd',
                  rf'CITY_CONTROLS_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
# City events, stage 1. Director: on in a scripted run, no alley cooldown, no pocket margin, no empty-street radius, the
# seed ignored. Alley: a robbery above the cap, a face never remembered, robbers that never answer the sword, a chase
# that does not end near people. Leaves: a content source that ignores Off, a damaged content.cfg saved over, four
# leaves, twice a session, «Ні» that starts the state. Haze: no plateau, a vignette over the HUD, nothing forgotten, the
# lethal pocket open in the state, a timer that stands. Economy: food at a wrong price, a damaged save written over, a
# second refund. Each must go red.
for script, sentinel, prefix, mutations in (
        ('tools/world/city_event_director_check.gd', 'CITY_EVENT_DIRECTOR', 'city-event-director', ('headless', 'cooldown', 'pocket', 'empty', 'rng')),
        ('tools/world/city_alley_check.gd', 'CITY_ALLEY', 'city-alley', ('cap', 'memory', 'sword', 'people')),
        ('tools/world/city_leaves_check.gd', 'CITY_LEAVES', 'city-leaves', ('off', 'cfg', 'count', 'session', 'refuse', 'row')),
        ('tools/world/city_haze_check.gd', 'CITY_HAZE', 'city-haze', ('pulse', 'layer', 'forget', 'pocket', 'end')),
        ('tools/npc/city_economy_check.gd', 'CITY_ECONOMY', 'city-economy', ('price', 'save', 'refund')),
        # Event menus: no guard, the call's timer behind its open menu, a trap label from before the tokens ran out; the
        # director's old teardown order (plan 2026-10-09 step 4: the menu closed after its event left the tree).
        ('tools/world/city_event_menus_check.gd', 'CITY_EVENT_MENUS', 'city-event-menus', ('arming', 'asktimer', 'zero', 'teardown')),
        # Hunger: a wrong rate, a clock that runs in a conversation or the pocket, no floor, no token loss on the
        # collapse, an uncapped haze drop, RETRY at full hp, the crust without its condition.
        ('tools/world/city_hunger_check.gd', 'CITY_HUNGER', 'city-hunger', ('rate', 'gate', 'pocket_clock', 'floor', 'collapse', 'haze', 'retry', 'crust')),
        # Thirst: a wrong rate, a clock that runs in a conversation or the pocket, W not counted for the body, the scale
        # running with no water source; the pump's prompt over a street event's, the lever's old sign, a flat lever, the
        # ladle sunk in the column (plan 2026-10-09 step 4).
        ('tools/world/city_thirst_check.gd', 'CITY_THIRST', 'city-thirst', ('rate', 'gate', 'pocket_clock', 'ignore', 'source', 'prompt', 'lever', 'lever_flat', 'ladle')),
        # Substance states: a profile that walks, brakes or refills better; a state begun over another; a drink that keeps
        # the hangover. Plan 2026-10-09 step 3 (T4 U1–U4 and the product before the fix): a dash carried on above walking
        # pace, ground_accel × 1.5, the hang + 1 s, the dodge bar × 1.25 in a state, W that stands in «Задишка».
        ('tools/world/city_substances_check.gd', 'CITY_SUBSTANCES', 'city-substances', ('walk', 'decel', 'regen', 'stack', 'hangover', 'carry', 'accel', 'hang', 'dodges', 'water')),
        # Glyphs: a `✓` literal, a `→` in data, a `◇` in a triple-quoted string, a font that claims every character; a
        # character built at run time by `%c` (G1), String.chr (G2) or char().
        ('tools/ui/glyph_coverage_check.gd', 'GLYPH_COVERAGE', 'glyph-coverage', ('inject_gd', 'inject_json', 'inject_triple', 'font', 'inject_format', 'inject_chr', 'inject_char')),
        # Item icons: icons stretched to the button's height, text centred, no stand-in for a row without an icon.
        ('tools/ui/item_icons_check.gd', 'ITEM_ICONS', 'item-icons', ('expand', 'center', 'blank'))):
    for mutation in mutations:
        cases.append((prefix + '-negative-' + mutation, script,
                      rf'{sentinel}_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                      ['--', '--break=' + mutation], 1))
# Glyphs built at run time (T4 audit 2026-10-09 п. 4, plan 2026-10-14 step 7): G4 `char (0x2713)`, G6 bytes decoded with
# get_string_from_utf8, `String . chr (…)`, `"%E2%9C%93".uri_decode()` and a padded `%-2c` must each go red.
for mutation in ('inject_char_space', 'inject_utf8', 'inject_chr_space', 'inject_uri', 'inject_format_width'):
    cases.append(('glyph-coverage-negative-' + mutation, 'tools/ui/glyph_coverage_check.gd',
                  rf'GLYPH_COVERAGE_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
# Substance states, the state-blind route B13 (T4 audit 2026-10-09 п. 3 U5/U6, plan 2026-10-14 step 6): in a state the
# take-off × 1.08 (U5), the jump's gravity 15 % lighter, the rope pull × 1.25 (U6), the rope's target 1 m shorter, the
# vault 20 % shorter, the wall run 25 % faster must each go red.
for mutation in ('jump', 'float', 'pull', 'target', 'vault', 'wallrun'):
    cases.append(('city-substances-negative-' + mutation, 'tools/world/city_substances_check.gd',
                  rf'CITY_SUBSTANCES_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--part=route', '--break=' + mutation], 1))
# Every city-tidy negative names the family it must turn red (red=…, city_tidy_check.gd header; T4 audit 2026-10-15,
# class 18: a negative red on a neighbouring guard no longer passes).
# City tidy (phase 0): each class with the returned audit defect and another form of it — a bracket strut and the
# market wire in a pane; a barrel and a loaf floating, a crate sunk, the archive plate off its wall; the fascia and the
# door jamb in one plane; a wall and a drum built twice; a planter, the dress form and the bypass plaque without their
# colliders; the atelier table back in the service point; a prop near the court centre, under an anchor, in a resident
# lane, the steam main out of the passage wall; a 1.5 m high and a 1.2 m deep obstacle; a puff over the hero and at
# 10 frames a second, a 62 m ink seam back on the street — each must go red. After the merge (T1, plan 2026-10-09): the
# pump's spout or lever without a collider, or both on a cover-only body the hero never meets, must go red too. The
# steam vehicles (docs/Fix/2026-10-09-City-Vehicles-And-Iron-Paint-Fix.md): one floating or sunk, a hull gone, the mesh
# off its hulls, hulls on the cover layer only, a surface off the city material, a vehicle under an anchor, in a lane,
# on a run-up, a camera station behind one, and a flat-roofed one vaulted with a relaxed profile — each red.
for mutation, family in (('pane_strut', 'c1'), ('pane_wire', 'c1'), ('float_barrel', 'c2'), ('float_loaf', 'c2'),
                         ('sink_crate', 'c2'), ('float_plate', 'c2'), ('zfight_fascia', 'c3'), ('zfight_jamb', 'c3'),
                         ('dup_wall', 'c4'), ('dup_barrel', 'c4'), ('solid_planter', 'c5'), ('solid_dressform', 'c5'),
                         ('solid_sign', 'c5'), ('service', 'd17'), ('court', 'k6'), ('anchor', 'k'), ('passage', 'k7'),
                         ('lane', 'k6'), ('ink_strip', 'k4'), ('vault_high', 'v'), ('vault_deep', 'v'),
                         ('steam_hero', 's'), ('steam_flash', 's'), ('pump_spout', 'c5'), ('pump_lever', 'c5'),
                         ('pump_layer', 'c5'), ('vehicle_float', 'm3'), ('vehicle_sink', 'm3'),
                         ('vehicle_nocollider', 'm4'), ('vehicle_shift', 'm4'), ('vehicle_layer', 'm1'),
                         ('vehicle_material', 'm2'), ('vehicle_anchor', 'm5'), ('vehicle_lane', 'm6'),
                         ('vehicle_runup', 'm7'), ('vehicle_gap', 'm8'), ('vehicle_vault', 'vm')):
    cases.append(('city-tidy-negative-' + mutation, 'tools/world/city_tidy_check.gd',
                  rf'CITY_TIDY_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z0-9,]*\b{family}\b[a-z0-9,]*',
                  ['--', '--break=' + mutation], 1))
# Guard pins after the T4 audit 2026-10-14 (docs/Fix/2026-10-14-Guard-Pins-After-Audit-Fix.md). B13: T5 Substances
# § 12.3 (б) rolled back — the state's braking in a landing's settle ticks with the stick held — must go red. The OPEN
# `air` item at anchor 5, pinned to its measured air and its stall's bodies: T4's wall 0.2 m beyond the vertical (air
# stays in the slack, a foreign body), T4's wall 0.3 m on the approach side, the stall's own counter grown toward the
# vertical (only the air floor sees it) must go red in `air`; T4's box under the vertical (the OPEN gone) in `open`.
cases.append(('city-substances-negative-settle', 'tools/world/city_substances_check.gd',
              r'CITY_SUBSTANCES_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation=settle',
              ['--', '--part=route', '--break=settle'], 1))
for mutation, family in (('air5_behind', 'air'), ('air5_front', 'air'), ('air5_counter', 'air'), ('air5_box', 'open')):
    cases.append(('rope-pull-negative-' + mutation, 'tools/grapple/rope_pull_check.gd',
                  rf'ROPE_PULL_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z,]*\b{family}\b[a-z,]*',
                  ['--', '--hero=choko', '--break=' + mutation], 1))
# «Chosen — not cut», the OPEN pinned to its blocker (T4 audit 2026-10-14 proposal 7): the market's engine-named solids
# renamed — the same body at the same point under another name — must go red in `cut`.
cases.append(('rope-choice-negative-blocker_name', 'tools/grapple/rope_choice_check.gd',
              r'ROPE_CHOICE_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation=blocker_name part=1/5 anchors=[0-9]+/[0-9]+ presses=[0-9]+ hangs=[0-9]+ cut_first=[0-9]+ open=[0-9]+ rewinds=[0-9]+ red=[a-z,]*\bcut\b[a-z,]*',
              ['--', '--hero=choko', '--part=1/5', '--break=blocker_name'], 1))
# Plan 2026-10-14-T6-Acceptance-Crane-Albedo-AB step 4 (T2-A): the steam crane № 10 and the steam winch № 11 on the NE
# terrace (docs/Fix/2026-10-14-Steam-Crane-Winch-Fix.md). Each machine guard of city_tidy_check must go red on its own
# negative: hulls on the cover layer only, a surface off its city material, a brass crane surface, a machine up or down
# 5 cm, the winch's body hull gone, the crane's mesh off its hulls, the winch under anchor 24, the crane by anchor 12, the
# winch in the terrace pocket and in a resident's lane, a hull over the street, the crane between the S3 hero and the
# lens and its hook (no hull) across that line, a camera station with the facade behind, a 0.5 m slot to the terrace's
# edge, the winch's triangles doubled, its
# listed step moved, and a flat-topped winch vaulted with a relaxed profile.
for mutation, family in (('machine_layer', 'mc1'), ('machine_material', 'mc2'), ('machine_brass', 'mc2'),
                         ('machine_float', 'mc3'), ('machine_sink', 'mc3'), ('machine_nocollider', 'mc1'),
                         ('machine_shift', 'mc4'), ('machine_column', 'mc5'), ('machine_anchor', 'mc5'),
                         ('machine_pocket', 'mc6'), ('machine_lane', 'mc6'), ('machine_street_hull', 'mc7hull'),
                         ('machine_cross', 'mc7arm'), ('machine_occlude', 'mc7cross'), ('machine_gap', 'mc8'),
                         ('machine_slot', 'mc9'), ('machine_budget', 'mc10'),
                         ('machine_step', 'vstep'), ('machine_vault', 'vmc')):
    cases.append(('city-tidy-negative-' + mutation, 'tools/world/city_tidy_check.gd',
                  rf'CITY_TIDY_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z0-9,]*\b{family}\b[a-z0-9,]*',
                  ['--', '--break=' + mutation], 1))
# T6 acceptance 2026-10-14, rows 1–5 (docs/Fix/2026-10-14-T6-Acceptance-Geometry-Fix.md): V+ wedge, one form each — a
# wall put 0.55 m off a street urn, the grocer's display crate with a round top 0.52 m off the shop wall, a wall 0.66 m
# off the tailor's cutting table (the band's deep end), a pinned OPEN whose wall is gone — must each go red.
for mutation, family in (('wedge_wall', 'vwedge'), ('wedge_round', 'vwedge'), ('wedge_deep', 'vwedge'), ('wedge_open', 'vopen')):
    cases.append(('city-tidy-negative-' + mutation, 'tools/world/city_tidy_check.gd',
                  rf'CITY_TIDY_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z0-9,]*\b{family}\b[a-z0-9,]*',
                  ['--', '--break=' + mutation], 1))
# T6's A5 (docs/Audit/2026-10-14-T6-Crane-Winch-Acceptance.md § 3 п. 1; docs/Fix/2026-10-15-Albedo-B3-Fix.md § MC7): from
# the street stations S2–S4 the lens sees no machine point under the terrace's level, «seen_y ≥ 4,0 м». One form each:
# the crane's decor hanging under the level over the street (no hull), the crane standing on the street floor in view
# (every other guard holds: only this one goes red), the winch hanging in front of the terrace's wall with no floor.
# At the threshold (T4 audit 2026-10-15 proposal 2): the crane's decor with its bottom at 3.9 m, 0.1 m under the level.
for mutation, family in (('machine_seen_hook', 'mc7seen'), ('machine_seen_street', 'mc7seen'), ('machine_seen_float', 'mc7seen'),
                         ('machine_seen_low', 'mc7seen')):
    cases.append(('city-tidy-negative-' + mutation, 'tools/world/city_tidy_check.gd',
                  rf'CITY_TIDY_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z0-9,]*\b{family}\b[a-z0-9,]*',
                  ['--', '--break=' + mutation], 1))
# Colour test switch A / B3 (docs/Fix/2026-10-15-Colour-Switch-Fix.md): a fresh profile on B3, a saved key forgotten at
# load, any unknown value played as B3, a damaged file saved over, a row that never switches, a row that never saves,
# project.godot shipping B3, a shader without its branch and a row that never reaches RenderingServer must each go red
# in their own family.
for mutation in ('default', 'persist', 'unknown', 'cfg', 'row', 'row_save', 'global', 'shader', 'apply'):
    cases.append(('colour-switch-negative-' + mutation, 'tools/settings/colour_switch_check.gd',
                  rf'COLOUR_SWITCH_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z_,]*\b{mutation}\b[a-z_,]* rs=not-measured-headless',
                  ['--', '--break=' + mutation], 1))
# T4 audit 2026-10-15, class 17 (docs/Fix/2026-10-15-Stall-Wedge-Boundary-Fix.md § 5): a pinned OPEN wedge that grows —
# a wall 0.55 m along the grocer counter's west end (wider: 9 of 9 points, pinned 5) or its side shelf 0.018 m further off
# (deeper: 0.171 m under, pinned 0.147 + 0.02) — must go red.
for mutation, family in (('wedge_more', 'vgrow'), ('wedge_deeper', 'vgrow')):
    cases.append(('city-tidy-negative-' + mutation, 'tools/world/city_tidy_check.gd',
                  rf'CITY_TIDY_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z0-9,]*\b{family}\b[a-z0-9,]*',
                  ['--', '--break=' + mutation], 1))
# T4 audit 2026-10-15 YELLOW 5 (docs/Fix/2026-10-15-Tidy-Sentinel-Families-Fix.md): M0 — every kind of CityProps places
# its own GLB, an unknown kind is refused and places nothing. CityProps._place_glb broken in the fixture's probe, one form
# each: an unknown kind placed as the truck with no refusal, an unknown kind placing nothing and reporting nothing, refused
# but placed anyway, the crane placed as the winch — each must go red in m0.
for mutation, family in (('glb_standin', 'm0'), ('glb_silent', 'm0'), ('glb_both', 'm0'), ('glb_swap', 'm0')):
    cases.append(('city-tidy-negative-' + mutation, 'tools/world/city_tidy_check.gd',
                  rf'CITY_TIDY_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation} red=[a-z0-9,]*\b{family}\b[a-z0-9,]*',
                  ['--', '--break=' + mutation], 1))
# Plan 2026-10-14-T6-Acceptance-Crane-Albedo-AB, T1's decision after T6 (2026-10-15; docs/Fix/2026-10-15-Stall-Wedge-
# Boundary-Fix.md). The district's invisible edge: no running jump crosses any of the four boundaries at any height, the
# edge only meets the hero's body. Negatives: the north veil gone, every veil at 8 m, the veils on the world layer too
# (camera, rope, parkour), a veil drawn, the hero's mask without the veil.
cases.append(('city-bounds', 'tools/world/city_bounds_check.gd', r'CITY_BOUNDS_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0))
for mutation in ('gap', 'low', 'world', 'mesh', 'hero'):
    cases.append(('city-bounds-negative-' + mutation, 'tools/world/city_bounds_check.gd',
                  rf'CITY_BOUNDS_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
# The barrel on trestles (T6 RED): off its back the hero ends on the floor or its top, or S/A/D take him there. Negatives:
# the barrel back at its old place (0.62 m off SouthWestRear), a wall brought to 0.62 m off it, the barrel 0.68 m off it.
cases.append(('city-rim-exit', 'tools/world/city_rim_exit_check.gd', r'CITY_RIM_EXIT_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0))
for mutation in ('old', 'wall', 'near'):
    cases.append(('city-rim-exit-negative-' + mutation, 'tools/world/city_rim_exit_check.gd',
                  rf'CITY_RIM_EXIT_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
                  ['--', '--break=' + mutation], 1))
# The tailor's dress form (T6 YELLOW) holds no hero; the cutting table's rim keeps A and D. Negatives: the old flat
# cylinder, a top narrowed to the neck, a top falling from the form's own east edge.
cases.append(('city-perch', 'tools/world/city_perch_check.gd', r'CITY_PERCH_COMPLETE checks=[1-9][0-9]* failures=0 mutation=none', [], 0))
for mutation in ('flat', 'cone', 'edge'):
    cases.append(('city-perch-negative-' + mutation, 'tools/world/city_perch_check.gd',
                  rf'CITY_PERCH_COMPLETE checks=[1-9][0-9]* failures=[1-9][0-9]* mutation={mutation}',
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
                          ('living-body-negative-', 'ERROR: LIVING_BODY: '),
                          ('parkour-moves-negative-', 'ERROR: PARKOUR_MOVES: '),
                          ('auto-hook-negative-', 'ERROR: AUTO_HOOK: '),
                          ('rope-pull-negative-', 'ERROR: ROPE_PULL: '),
                          ('rope-choice-negative-', 'ERROR: ROPE_CHOICE: '),
                          ('jump-arc-negative-', 'ERROR: JUMP_ARC: '),
                          ('anim-traversal-negative-', 'ERROR: ANIM_TRAVERSAL: '),
                          ('anim-ground-negative-', 'ERROR: ANIM_GROUND: '),
                          ('display-auto-negative-', 'ERROR: DISPLAY_AUTO: '),
                          ('lethal-fight-negative-', 'ERROR: LETHAL_FIGHT: '),
                          ('blood-content-negative-', 'ERROR: BLOOD_CONTENT: '),
                          ('match-lifecycle-negative-', 'ERROR: MATCH_LIFECYCLE: '),
                          ('city-event-director-negative-', 'ERROR: CITY_EVENT_DIRECTOR: '),
                          ('city-alley-negative-', 'ERROR: CITY_ALLEY: '),
                          ('city-leaves-negative-', 'ERROR: CITY_LEAVES: '),
                          ('city-haze-negative-', 'ERROR: CITY_HAZE: '),
                          ('city-economy-negative-', 'ERROR: CITY_ECONOMY: '),
                          ('city-event-menus-negative-', 'ERROR: CITY_EVENT_MENUS: '),
                          ('city-hunger-negative-', 'ERROR: CITY_HUNGER: '),
                          ('city-thirst-negative-', 'ERROR: CITY_THIRST: '),
                          ('city-substances-negative-', 'ERROR: CITY_SUBSTANCES: '),
                          ('glyph-coverage-negative-', 'ERROR: GLYPH_COVERAGE: '),
                          ('item-icons-negative-', 'ERROR: ITEM_ICONS: '),
                          ('colour-switch-negative-', 'ERROR: COLOUR_SWITCH: '),
                          ('city-bounds-negative-', 'ERROR: CITY_BOUNDS: '),
                          ('city-rim-exit-negative-', 'ERROR: CITY_RIM_EXIT: '),
                          ('city-perch-negative-', 'ERROR: CITY_PERCH: '),
                          ('city-tidy-negative-', 'ERROR: CITY_TIDY: ')):
        if name.startswith(scope):
            assertion_prefix = prefix
    # One negative replays an engine fault on purpose: the director's old teardown order, whose «!is_inside_tree()»
    # reads are exactly what its case counts (plan 2026-10-09 step 4). Only that line, only in that negative.
    replayed = ('ERROR: Condition "!is_inside_tree()" is true. Returning: Transform3D()',) \
        if name == 'city-event-menus-negative-teardown' else ()
    unexpected = [line for line in errors
                  if expected_rc == 0 or assertion_prefix is None
                  or not (line.startswith(assertion_prefix) or line in replayed)]
    ok = rc == expected_rc and complete and not unexpected and 'SCRIPT ERROR' not in output
    print(f'PLAYABLE {name}: {"PASS" if ok else "FAIL"} rc={rc} log={path}', flush=True)
    if not ok:
        failures += 1
        print(output[-12000:], flush=True)
print(f'PLAYABLE CHECK: {len(cases)} scenarios, {failures} failures', flush=True)
sys.exit(1 if failures else 0)
PY
