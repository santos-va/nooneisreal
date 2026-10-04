# Session handoff — start here

**Current branch update — PR #172:** the working branch adds aimed/latched rope traversal, separate stamina dodges, revised controls, and a persistent 12-resident city slice with seeded appearance, factual dialogue and NPC saves. The merged-baseline descriptions below predate this branch; full campaign saves, authored story NPCs and a local LLM remain unfinished. Real Santos soundtrack files are still unavailable. See [[2026-10-04-Living-City-Session]] and [[2026-10-04-Living-City-Traversal]].

Snapshot: **2026-10-04 UTC**, fetched `origin/main` **2c50938702e596b6f951ceb894d899182b583858**. English handoff requested by Santos; Ukrainian Plans, Fix and Audit pages retain detailed evidence.

**PRs #164–#170 are merged.** #169 delivered the earlier context handoff; #170 delivered the consolidated combat-control, city-first and city-style implementation at **18:37:42 UTC**. At the start of cleanup, before its follow-up PR, the GitHub query returned no open PRs. PR-head `1773ac2` has successful [CI run 37224056701](https://github.com/santos-va/nooneisreal/actions/runs/37224056701). Older “local only”, “CI pending” and stacked-branch statements are dated history. Merge and CI do not establish final art, player comfort or target-device acceptance.

## Read in this order

1. [[state]], [[constitution]], root `AGENTS.md`, then assigned `roles/tN-*.md`. Default coordinator is T1; do not edit another client's adapter.
2. [[Handoff/2026-10-04-Delivery-Ledger]] — merged scope and provenance.
3. [[Handoff/2026-10-04-Decisions-And-Validation]] — current controls, contracts and verification limits.
4. [[Handoff/2026-10-04-Remaining-Work]] — unresolved acceptance and future work.
5. Relevant Plan, Fix and Audit before editing implementation. Historical checkboxes and role tables are not current assignments.

## Current game and direction

No One Is Real is a stylized 3D fighter with Choko and Skea, plus a first explorable Cronshift district. The city-first direction is to build a shared world and later locate fights within it, while preserving existing arenas. The merged district has real streets, ramps, roofs, a bridge, parkour anchors, a separate camera and optional action-based guidance. It is a bounded prototype, not a completed open world; city encounters, story, saves, NPCs and portals are not implemented by this slice.

Combat now includes continuous screen-relative movement, 5/3 dash budgets, visible Skea dash arcs, weighted Space reeling, occupied-anchor rejection, three-hit hand/leg combinations, Choko back draw/dust reform and Skea ultimate wave extension. See [[ADR-022-Combat-Control-And-Match-Resources]] and the current contract page; do not restore the superseded held-world-direction latch.

**The latest selected separate Higgsfield textures/strips govern architectural forms, palette and rendering together. Older panoramas are style drafts.** The city art pass adds modular facades, mansard roofs, market props and matte procedural materials. This is a technical and local visual-direction acceptance, not final human art approval. No new paid asset generation was required.

Primary personal test machine: MacBook Air M3, approximately 8 GB RAM. Display scaling, measured performance, listening and physical controller acceptance remain open. Anatomical weight and muscular strength are presentation/gameplay goals, not a completed muscle simulator.

## Current work boundary

Santos requested cleanup and reconciliation after the consolidated PR. This pass updates current documentation, corrects help text to match existing controls and removes confirmed redundant material; it does not start the next gameplay slice. The next product instruction is pending. Retain unresolved work in the recovery queue without treating every historical plan as an active assignment.

One coordinator can delegate bounded role tasks with exact ownership and evidence expectations. Shared code such as `Fighter.gd` has one active writer. Run Godot serially on a checkout. Private chats, agent memory and external scratch artifacts do not transfer automatically.

The merged [[Plans/2026-10-04-Codex-Coworker]] remains a **draft integration proposal**, not proof of installed Codex hooks or runtime parity. Continue its inventory before configuring adapters; preserve manual boot fallback.

## Revalidation in a new session

Fetch GitHub and reconcile this dated snapshot with current main, PRs and working tree. Preserve completed work. Select a bounded task only from the user's current instruction and the remaining-work page. Recreate missing local evidence before claiming fresh validation; Linux renders do not establish M3 acceptance.

External `/workspace/nooneisreal-env/` logs and images are not durable repository content. Committed harnesses and linked reports provide reproduction guidance. This snapshot cannot establish private/unpushed work on other machines or current provider balances/access.

## Related

- [[Handoff/2026-10-04-Delivery-Ledger]] · [[Handoff/2026-10-04-Decisions-And-Validation]] · [[Handoff/2026-10-04-Remaining-Work]]
- [[Meetings/2026-10-04-Current-State-Cleanup]] · [[index]] · [[state]] · [[constitution]]
