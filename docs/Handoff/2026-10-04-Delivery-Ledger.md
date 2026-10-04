# Delivery ledger — merged work and its limits

Snapshot: 2026-10-04, main `2c50938`. Merge states below were checked with GitHub; source files and linked audits were inspected. Test figures are recorded results from the implementation sessions, not new gameplay runs performed for this documentation-only reconciliation.

## Merged delivery

| PR / merge time UTC | Delivered scope | Evidence and remaining boundary |
|---|---|---|
| [#164](https://github.com/santos-va/nooneisreal/pull/164) / 12:27:15 | Responsive menu/HUD sizing; procedural toon water shading and bounded 3D splashes with drawn accents; procedural motion fallbacks and distinct living idles; hero-sized mesh afterimages; water SFX; stable duel framing, impact response and limited foot support | [[Plans/2026-10-04-Playable-Water-Slice]], [[Audit/2026-10-04-Playable-Slice]], [[Audit/2026-10-04-Camera-Foot-Contact]]. Technical acceptance was bounded; early visual findings were subsequently addressed in #167/#168. Neither Retina nor sound quality was accepted on M3. |
| [#165](https://github.com/santos-va/nooneisreal/pull/165) / 13:00:38 | Volume/shake comfort controls in menu/pause, gamepad UI navigation, neutral-before-resume input fences and help | [[Plans/2026-10-04-Comfort]], [[Audit/2026-10-04-Comfort-Audit]]. Recorded settings28/input31 checks and19 playable scenarios passed. Physical controller and listening acceptance remain. |
| [#166](https://github.com/santos-va/nooneisreal/pull/166) / 14:32:00 | Coworker session plan, role handoffs and proposed ADR-021 | [[Plans/2026-10-04-Codex-Coworker]]. Documents only; adapter/discovery/runtime parity and strict missing-Godot gate still require implementation and independent acceptance. |
| [#167](https://github.com/santos-va/nooneisreal/pull/167) / 15:34:20 | Free human movement, J/K/M/comma limb inputs, finite confirmed-hit combinations, distance-driven walk/jog/crouch; Q/E harpoons, actual contact, bounded length and full-body windup; 7/2 finite charges, persistent match ropes, miss rewind/extraction; manual camera aim and target cues | [[Plans/2026-10-04-Free-Movement-Limbs]], [[Plans/2026-10-04-Harpoon-Inventory-Ropes]], corresponding [[Audit/2026-10-04-Free-Movement-Limbs]] and [[Audit/2026-10-04-Harpoon-Inventory-Ropes]]. 30 playable scenarios passed before sword expansion. Not multi-enemy, unlimited animation generation or full terrain rope physics. |
| [#168](https://github.com/santos-va/nooneisreal/pull/168) / 15:34:26 | Choko guard/gaze correction and unkeyed spine-drift fix; one visible sword, V/R3 transfer, armed-hand sword/free-hand fist, mirrored poses, gold ultimate and recovery carry | [[Plans/2026-10-04-Choko-Stance-Sword]], [[Audit/2026-10-04-Choko-Stance-Sword]]. Final recorded32 playable scenarios,164 smoke checks,797 sword-state,228 presentation,18114 idle checks and45 native captures passed. Timings/geometry remain provisional; no fingers or blade-shaped hitbox added. |

| [#169](https://github.com/santos-va/nooneisreal/pull/169) / merge `65435de` | English handoff and historical context reconciliation | Documentation only; superseded snapshot details are updated by this cleanup. |
| [#170](https://github.com/santos-va/nooneisreal/pull/170) / 18:37:42 | Consolidated combat-control fixes, first explorable Cronshift district and style pass matching the latest separate strips | [[Plans/2026-10-04-Combat-Control]], [[Plans/2026-10-04-City-First]], [[Plans/2026-10-04-City-Style-Match]]. Recorded final suite: 43 scenarios/0 failures, smoke 164/19847 frames; gates 70 GDS/0 parse failures; native material checks 23/0 and 18 captures. Local technical acceptance does not close M3, final art or player-feel acceptance. |

#167 and #168 were originally stacked branches. GitHub now records both with base `main` and merged state; no stacked-merge action remains for these two PRs.

GitHub also reports successful CI for merged main `2c50938`: [run37213512143](https://github.com/santos-va/nooneisreal/actions/runs/37213512143). This is CI evidence; it does not supply a Mac playtest.

## Earlier foundation already present

The October 3–4 history includes models/retargeting and skeletal ragdoll (#153), 8-direction dash (#150), body inertia (#141), surface and combat sheets (#148/#152/#160), HUD portraits/icons and flipbook integrations (#159), asset licenses/reviews/scale decisions (#143–145/#154/#161), and background strip selections (#163). These merged items have different deliverable types: a licensed pack, selected image or approved layout is not proof that its meshes are integrated into the arena.

Use [[Plans/2026-10-03-Living-Combat]], [[Plans/2026-10-03-Arena-Depth-Life]], [[Plans/2026-10-03-Wave-2-Kickoff]], [[Art/Pack-Review]] and [[Meetings/2026-10-04-Apollon-F3-Strips]] for that provenance. This ledger does not retroactively grant final visual acceptance to those historical PRs.

## Important corrections to old context

- The main baseline is no longer `e0ea616` or `1440344`; both are historical checkpoints.
- Old “zero T2/T4 work” tables, capsule-only descriptions and old controls are historical snapshots, not current runtime truth.
- Afterimage hero scaling, free movement, Choko guard and sword hand transfer have concrete implementations; do not restart them from scratch.
- Water recordings were absent, but eight original procedural water WAVs were created and registered. Do not call them recorded water or Sonniss samples: [[Fix/2026-10-04-Playable-Audio]], [[Art/Procedural-Water-Audio]].
- A voice recording/naming guide already exists: [[Tech/Character-Voice-Recording]]. Character takes, runtime voice integration and listening acceptance are still pending.
- Five-NPC work remains preproduction: [[Art/2026-10-04-City-NPC-Development]]. That track did not deliver five finished NPC models. The explorable district and its procedural architecture were delivered separately in #170; do not label all city work preproduction.
- Historical credit values are dated observations. Current balance, provider availability and access from a new session require fresh checks.

## Related

- [[Handoff/2026-10-04-Start-Here]] · [[Handoff/2026-10-04-Remaining-Work]] · [[Handoff/2026-10-04-Decisions-And-Validation]] · [[state]]
