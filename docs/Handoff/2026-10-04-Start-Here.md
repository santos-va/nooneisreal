# Session handoff — start here

Snapshot: **2026-10-04 UTC**, reconciled against GitHub and fetched `origin/main` **a401e6cfdfa794644ed5861ab32a2af52d86171c**. This is an English handoff requested explicitly by Santos. Existing Ukrainian documents remain the detailed historical record.

**PRs #164, #165, #166, #167 and #168 are merged into main.** The open-PR query returned an empty list at this snapshot. Earlier statements that #167/#168 were only on branches or waiting for CI are superseded. Merged implementation does not mean final art, target-device performance or player comfort has been accepted.

## Read in this order

1. [[state]], [[constitution]], root `AGENTS.md`, then your assigned `roles/tN-*.md`. Default coordinator is T1; do not edit another client's adapter.
2. [[Handoff/2026-10-04-Delivery-Ledger]] — what was actually delivered, where and in which merge.
3. [[Handoff/2026-10-04-Decisions-And-Validation]] — current controls, contracts, environment and evidence limits.
4. [[Handoff/2026-10-04-Remaining-Work]] — partial work, dependencies and concrete next acceptance steps.
5. Open the relevant linked Plan, Fix and Audit before editing its implementation. Historical checkboxes and old state tables are not a current task assignment.

## Product direction

Build an enjoyable, readable 3D cel-shaded/cartoon arena fighter: strong, active Choko and Skea, free movement, clear strikes and combinations, stable intelligent camera, spatial water and contact effects, comfortable controls and sound. Primary personal test machine: MacBook Air M3, approximately 8 GB RAM; exact display scaling and physical controller acceptance remain unverified.

The long-term direction includes a vertical city, five distinctive protected ambient NPCs, situational movement, more enemies and eventually online combat. These are not all implemented. The requested anatomical weight and muscular strength are a visual/gameplay goal, not a completed muscle simulator.

## How the work evolved

The environment and repository audit led to the playable/UI/water slice, then stable camera and foot support (#164). Comfort and UI input isolation followed (#165). A separate coworker workflow proposal merged as documentation (#166). Free movement and four-limb combat expanded into contact-based harpoons, finite inventory, persistent ropes and manual aim (#167). Choko's broken guard then led to drift correction, one visible active sword and an animated hand transfer (#168).

New requests expanded scope; they did not make the remaining city, NPC, anatomy, audio and workflow tracks complete. The remaining-work page preserves those obligations explicitly. This reconciliation changes documentation only and does not silently start those implementations.

## Working arrangement

One coordinator can delegate bounded role tasks; separate user-created chats are not required for every subtask. Each worker receives an exact goal, owned files, dependencies and evidence expected back. Shared files such as `Fighter.gd` have one active writer. Run Godot serially on the checkout. A new session must read the repository: private Claude chats, tool access, agent memory and external scratch artifacts do not automatically transfer.

The merged coworker plan is still a **draft integration proposal**, not proof of installed Codex hooks or runtime parity: [[Plans/2026-10-04-Codex-Coworker]], [[ADR-021-Codex-Coworker-Adapter]]. Continue its inventory before configuring an adapter. Preserve the manual boot fallback.

## Suggested first message in a new session

> Read AGENTS.md and follow its boot order, then read docs/Handoff/2026-10-04-Start-Here.md and its three handoff pages. Fetch GitHub and reconcile this dated snapshot with current main, PRs and the working tree. Preserve completed work. Report the next bounded acceptance or implementation task from Remaining-Work, delegate by repository roles where useful, and carry it through with evidence. Do not treat planned assets, historical logs or Linux renders as completed M3 acceptance.

## Scope of this reconciliation

Checked the available checkout, remote merge metadata, implementation reports, plans and audits. This cannot establish the state of private/unpushed work on other machines. External `/workspace/nooneisreal-env/` logs and captures are useful here but are not durable repository content; the next session must regenerate missing evidence. Do not fabricate historical credit balances, current provider availability or asset purchases.

## Related

- [[Handoff/2026-10-04-Delivery-Ledger]] · [[Handoff/2026-10-04-Decisions-And-Validation]] · [[Handoff/2026-10-04-Remaining-Work]]
- [[Meetings/2026-10-04-Context-Reconciliation]] · [[index]] · [[state]] · [[constitution]]
