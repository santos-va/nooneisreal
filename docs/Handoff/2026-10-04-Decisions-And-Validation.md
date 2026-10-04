# Decisions and validation — 2026-10-04

English handoff requested by Santos. This page separates the current gameplay contract from superseded proposals and records prior validation without claiming a new engine run. Read it with the delivery ledger and remaining-work pages maintained by T1. Repository inspected for this reconciliation: `origin/main` / HEAD `a401e6c`; working branch `codex/context-handoff`.

## Delivery status and evidence boundaries

T1's current GitHub reconciliation reports PRs #164–#168 merged. In particular, #167 merged at **2026-10-04 15:34:20 UTC**, and #168 at **15:34:26 UTC**. Their older journals saying “open”, “stacked”, or “CI pending” describe the historical handoff, not current delivery status. These merge facts are supplied by T1's GitHub check; T7 did not independently repeat the API query. This documentation pass does not rerun the gameplay suite or alter gameplay. The coordinator ran the documentation gate battery, including Godot parse checks.

The most recent recorded runtime acceptance is the Choko sword slice: 164 smoke checks / 19824 frames, 32 presentation/regression scenarios, zero failures; gates green with 59 GDScript files and zero parse failures. This is prior acceptance evidence recorded in the Fix/Audit documents, **not a fresh run of merged main**. No result here establishes M3 performance, physical-controller behavior, audio listening acceptance, or online determinism.

## Current controls and superseded proposals

The latest sections of [[GDD/05-Platforms-Input]] and the runtime `InputRouter` take precedence over historical tables lower in that document. Keys denote physical positions. “Comma” is the key next to M, **not the left-arrow key**. Left/right refer to the chosen limb, not an automatic animation alternation.

| Action | SOLO P1 | SHARED P1 | SHARED P2 | Gamepad |
|---|---|---|---|---|
| Left hand | J | F | K | LB / L1 |
| Right hand | K | G | L | RB / R1 |
| Left leg | M | Z | N | LT / L2 |
| Right leg | comma | B | J | RT / R2 |
| Guard | L | Left Shift | Right Shift | X / Square, hold |
| Skill 1 | U | Q | semicolon | Y / Triangle + LB / L1 |
| Skill 2 | I | E | apostrophe | Y / Triangle + RB / R1 |
| Enemy harpoon | Q | T | O | Y / Triangle + RT / R2 |
| Parkour harpoon | E | R | I | Y / Triangle + LT / L2 |
| Ultimate | O | V | comma | D-pad up |
| Choko sword transfer | V | H | P | R3, press right stick |

SOLO movement is WASD, jump Space, crouch X and dash Left Shift. Manual solo camera uses RMB + mouse movement or the right stick. The right-stick press for transfer is distinct from its look axes. Consult the live in-game controls panel for the active profile rather than applying SOLO labels to SHARED.

The final clarification is **SOLO Q = enemy, E = parkour, I = skill 2**. Earlier Q/I speculation, the single physical E grapple, and the intermediate “Y+LT does nothing” rule are superseded. SHARED preserves its old Q/E skills and therefore uses separate T/R harpoons for P1. The user's “Snik” clarification refers to **Skea**.

Gamepad chord routing is selected on a fresh shoulder/trigger press and held until release. Changing Y while a trigger is already held must not generate a second attack or another grapple mode. UI ownership suppresses combat/look input; held controls require neutral before new gameplay actions. These are tested contracts, not a full remapping/accessibility system.

## Movement, camera and attack variety

A held movement gesture must continue in the same world direction after crossing an opponent. Human movement is no longer projected onto an orbit around the one enemy; facing follows movement, while attack targeting remains explicit. At the start of a new SOLO P1 gesture, a recorded horizontal view-basis input packet can supply direction after manual camera movement. That basis stays latched until neutral. Fighter does not continuously read the smoothing Camera3D transform, and replay uses the recorded packet. CPU and shared framing use their own paths. See [[Fix/2026-10-04-Free-Movement-Limbs]] and [[Fix/2026-10-04-Harpoon-Aim]].

Automatic camera continuity preserves its side when fighters cross; impact is communicated through bounded, comfort-scaled lens displacement. Shared camera framing remains symmetric. Independent manual orbit/aim for two players on one screen is not delivered. Manual aim records world origin/point/direction and target identity; a visible cue is a candidate, never proof of a hit. The swept hook contact remains authoritative. Scene-path IDs used locally are not a finished online identity protocol.

Existing registered UAL Source clips supply Walk/Jog/Crouch and attacks. Gait phase follows distance and speed rather than assuming a fixed walk cadence at every velocity. Procedural poses and mirroring expand handedness and motion; this is a bounded authored/procedural set, not unlimited anatomical animation generation or real muscle simulation. A new sprint mechanic was not delivered merely because source Sprint clips exist.

Normal strings contain at most three normal attacks, with a fresh press per attack. Continuation requires a confirmed hit, not whiff/block/invulnerability. A leg ends the normal string. Hand sequences vary by side and order; crouch/air use their existing donors. Numeric combat fields remain donor values: visual variation does not secretly increase damage, hitboxes or range. “Body hook” and “uppercut” describe trajectories, not separate jaw/abdomen damage systems. The user's four-limb request explicitly authorized the exception to the older nine-action limit. Detailed combat rules belong to [[GDD/02-Combat-System]] and [[GDD/03-Skills-Framework]].

## Harpoons, stock and ropes

- Choko owns **7**, Skea **2**. This replaces the old three-charge timer regeneration. The invariant is `available + active/recovering + deployed = capacity`; ownership tokens prevent duplicate refunds.
- Enemy and parkour are explicit intents. A hit requires swept contact after windup, not immediate attraction from a preview marker. The accepted foundation includes a 30-frame windup and bounded range; design values remain subject to playtest.
- Leaving a parkour hang leaves a match-owned rope usable by either fighter, including an opponent with no available stock. Reuse does not transfer the inventory owner or issue another token.
- Round reset preserves deployed ropes and spent stock, while unfinished recoverable shots refund once. A new match clears the registry and restores capacity. This is the delivered inventory contract, not a future passive unique to Choko.
- A miss enters visible rewind. Recovery progress survives interrupts; incapacitated states pause it. Another shot cannot bypass unfinished recovery. Ground/water appearance does not resolve combat damage.
- After enemy pull, extraction occupies the hands but permits kicks. A committed kick refunds on its first active frame; ordinary extraction cannot refund early during kick startup. Interrupted startup is not successful extraction.
- The decorative segmented rope is bounded and separate from authoritative endpoint, length, hit and inventory logic. It is not a full rigid-body rope, general obstacle wrapping, or a cross-platform lockstep guarantee.

Sources: [[Fix/2026-10-04-Harpoon-Inventory]], [[Fix/2026-10-04-Rope-Presentation]], [[Audit/2026-10-04-Harpoon-Inventory-Ropes]].

## Choko stance and one active sword

Santos confirmed **one active emerald shuka**, right hand by default, and visible transfer via V/R3. The free hand punches; legs remain kicks. Armed-hand normals use sword presentation without changing their donor combat fields. The golden crystal ultimate is a temporary sword variant, not a second permanent sword. The obsolete “eight spectral blades / 256” character-card description is superseded by the crystal-ultimate contract in [[GDD/03-Skills-Framework]].

Transfer has a separate SWAP state: **24 frames, contact at 12**, explicitly PLACEHOLDER design values. Input interruption is handled before advancing the counter. Before contact, interruption preserves the old owner; after contact, the new owner remains. Feet and dash interrupt and execute; hand attacks, skills, grapples and repeated transfer requests during SWAP are discarded rather than queued. Start is restricted to grounded Choko IDLE/WALK with no busy hook. Pause, hitstop and time freeze do not advance it; round reset restores right ownership and presentation. Each attack snapshots its sword hand.

The lower asymmetric ready stance and actual-hand weapon attachment replace the raised-arm stance and hidden capsule weapon. Both transfer directions and left/right legacy/ultimate presentation were examined. The mesh is a stylized procedural implementation using existing visual references, not a newly purchased/generated weapon GLB. Sampled centerline clearance against simplified body cores does **not** guarantee all blade surfaces avoid every skinned-mesh intersection.

Sources: [[Fix/2026-10-04-Sword-Input-State]], [[Fix/2026-10-04-Choko-Sword-Presentation]], [[Fix/2026-10-04-Choko-Idle-Guard]], [[Characters/Choko]].

## Comfort, water and production decisions retained

Comfort defaults are Master/SFX/Music/shake **80/80/60/50%**, provisional rather than listener-approved. Zero mutes a bus or disables the relevant impact displacement. Settings live separately in `user://comfort.cfg`; atomic saving preserves unknown keys, and corrupt/unwritable files are not overwritten. A final Master limiter limits the sum, but does not establish pleasing sound or safe physical headphone loudness. Menu/pause controls and help are scrollable; tests isolate preferences instead of writing the user's real settings. See [[Fix/2026-10-04-Comfort-Settings]], [[Fix/2026-10-04-Comfort-Input]] and [[Fix/2026-10-04-Comfort-UI]].

The earlier slice fixed UI image sizing, added procedural toon-water presentation and bounded 3D splashes, reused drawn accents, introduced original synthesized water sounds and actual-mesh afterimages. This is not evidence that water density, the sound mix or final art polish is accepted on the target Mac. Asset rights remain tracked in the texture registry; no new paid generation was required for these motion/rope/sword changes.

Game Development Studio CLI and callable Higgsfield generation tools were unavailable in the recorded implementation environment. Blender was available locally; Ableton was not connected. Plugin mentions are not evidence of a completed provider job. [[Art/2026-10-04-City-NPC-Development]] contains five citizen concepts, gadgets, prompts and a room brief: **preproduction only**, no delivered NPC models or populated runtime district.

## Recorded validation, not rerun in this reconciliation

| Slice / source | Recorded acceptance | Interpretation |
|---|---|---|
| Comfort, [[Audit/2026-10-04-Comfort-Audit]] | settings 28/0, input 31/0, UI PASS; smoke 164/19944 frames; 19 scenarios/0 | Earlier scope; not the final total suite |
| Movement foundation, [[Audit/2026-10-04-Free-Movement-Limbs]] | smoke 164/19839; 27 scenarios/0; gait 630/0; feet 774/0 | Checkpoint before persistent-rope phase |
| Rope inventory, [[Audit/2026-10-04-Harpoon-Inventory-Ropes]] | smoke 164/19824; 30 scenarios/0; gates 57 GDS/0 | Technical GREEN with stated limits |
| Rope targeted checks | movement 54/0, aim 21/0, harpoon 55/0, limb input 177/0, limb combat 2950/0, rope geometry 24732/0, recovery 284/0 | Final rope-stage logs, not fresh counts after later changes |
| Rope native | `ACTUAL_INVENTORY_COMPLETE shots=11 failures=0` | Actual-input scenarios; Linux llvmpipe |
| Sword, [[Audit/2026-10-04-Choko-Stance-Sword]] | smoke 164/19824; 32 scenarios/0; gates 59 GDS/0 | Latest recorded complete suite |
| Sword targeted checks | state 797/0, presentation 228/0, idle 18114/0 | Technical GREEN, no open blockers in that scope |
| Sword native / clearance | 45 snapshots/0; 40 sampled cases/0 simplified-core intersections | Actual-input captures plus a limited geometric probe |

The sword runner contained 23 positive scenarios and nine deliberate negative controls. Negative rc=1 is success only for that named mutation, expected assertion and sentinel; runtime or SCRIPT ERROR is never waived generically. An rc=0 frame-cap exit without completion is not a pass. The narrow deliberately corrupt comfort-file test restores error printing immediately after asserting its expected parse rejection.

Earlier failed native captures are not accepted evidence. Final rope and sword logs retained only the known unsupported-VSync warning. Reviewers read logs and native evidence independently; Godot was run serially by the coordinator. T4's GREEN is bounded technical acceptance, not blanket visual perfection or physical-device acceptance.

## Reproducing checks and locating evidence

Use Godot **4.7**; the recorded cloud binary was `Godot_v4.7-stable_linux.x86_64` (`5b4e0cb0f`). The system `godot` previously resolved to an older version, so verify the selected executable. Run one engine at a time against this checkout; stop a running editor/game before tests. `make check-playable` already includes `make check` (import, parse and smoke).

In the retained cloud workspace:

```bash
cd /workspace/nooneisreal
source /workspace/nooneisreal-env/activate.sh
"$GODOT_BIN" --version
mkdir -p /tmp/nir-revalidation
PLAYABLE_LOG_DIR=/tmp/nir-revalidation/scenarios make check-playable > /tmp/nir-revalidation/check-playable.log 2>&1
make gates > /tmp/nir-revalidation/gates.log 2>&1
```

Check each command's exit status separately and inspect completion/error lines. The activation script sets `GODOT_BIN` and writable `XDG_CACHE_HOME`, `XDG_DATA_HOME`, `XDG_CONFIG_HOME` under `/workspace/nooneisreal-env`. It is a local environment artifact, not a portable repository dependency. On another machine, install Godot 4.7 and set the binary explicitly; for the standard macOS app location:

```bash
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT_BIN" --version
make check-playable
make gates
make run
```

If that app path differs, use the actual installed executable. `make run` imports when needed and refuses a concurrent Godot instance. A successful headless check does not replace the Mac playtest.

A focused check can be run after import, for example:

```bash
"$GODOT_BIN" --headless --path game --script ../tools/weapon/sword_state_check.gd
"$GODOT_BIN" --headless --path game --script ../tools/aim/harpoon_aim_check.gd
```

Required sentinels are `SWORD_STATE_COMPLETE` or `HARPOON_AIM_COMPLETE`, failures=0, clean runtime output and exit 0. The complete authoritative scenario list and negative-control rules live in `tools/gates/playable_check.sh`.

Recorded artifacts are under `/workspace/nooneisreal-env/{playable,contact-camera,comfort,free-limbs,rope-inventory,choko-sword}/`. In the final two directories, use `logs/check-playable-final.log`, `logs/gates-final.log` and `regression-final/`. Final native logs are `rope-inventory/logs/actual-inventory.log` and `choko-sword/logs/actual-sword-final.log`; the sword clearance probe log is `choko-sword/logs/sword-clearance2.log`.

Native captures used Xorg dummy display `:99`, `LIBGL_ALWAYS_SOFTWARE=1`, `--audio-driver Dummy`, `--rendering-method gl_compatibility`, and an 1152×648 window. Earlier comfort captures also covered 844×390 and 1024×768. These external capture helpers and images are workspace artifacts, not guaranteed to survive a fresh cloud environment. Do not claim to reproduce them from git alone: restore/rebuild the helper and display setup, then repeat actual input and inspect the resulting images. Core headless harnesses are committed under `tools/`.

## Related

- [[index]] · [[system/state]] · [[system/constitution]] · [[Meetings/2026-10-04-Context-Reconciliation]]
- [[GDD/02-Combat-System]] · [[GDD/03-Skills-Framework]] · [[GDD/04-Grapple-System]] · [[GDD/05-Platforms-Input]] · [[GDD/06-UI-UX]]
- [[Plans/2026-10-04-Free-Movement-Limbs]] · [[Plans/2026-10-04-Harpoon-Inventory-Ropes]] · [[Plans/2026-10-04-Choko-Stance-Sword]]
- [[Audit/2026-10-04-Comfort-Audit]] · [[Audit/2026-10-04-Harpoon-Inventory-Ropes]] · [[Audit/2026-10-04-Choko-Stance-Sword]]
