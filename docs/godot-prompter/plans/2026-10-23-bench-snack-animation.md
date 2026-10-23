# Bench snack visits

Requested by David on 23 October 2026: develop a plan and delegate implementation to Sol.
Assignee: Codex Sol (explicit assignment for this work).
Status: implemented and visually reviewed; no new validation failures. Existing rival escape regression remains.

## Outcome and scope

### Follow-up: block walking across bench seats

David reported that crowd spacing sent pedestrians onto the bench via the rear lane. BenchRegistry now records a walking exclusion footprint derived from the rendered bench width, height, scale and authored position, expanded for shoes. BeachSpawner rejects candidate offsets within that footprint and also projects interpolated offsets to its foreground edge, so an already-raised walker cannot slide through the bench. Empty benches are obstacles too; anchored sitting/standing visitors retain their seat position. Simulation positions still restore through reset_spacing.

Validation: 113 crowd-spacing checks and all 474 bench-snack checks pass. Full tools/validate.ps1: 16,377 checks, one unchanged pre-existing level-6 rival escape failure (escape_short=4), no new failures. The existing grab_focus diagnostic remains. Rendered both approach directions around empty/occupied benches using tools/bench_lane_preview.tscn; inspected assets/previews/bench-lanes-50.png. Regression checks include an existing rear-lane offset, interpolation, crossings from both sides, seated anchors, and scaled/repositioned bench geometry. No new character art was required.

The original yellow-shirt shopper, mullet shopper and floral-sundress shopper sometimes walk to an available bench with their existing snack, sit, take occasional bites, stand up and resume strolling. First implement and visually verify the original shopper, then adapt the other two identities. Keep the architecture reusable for pier diners, but leave diners, families, toddlers, lifeguards and vendors out of this first rollout.

Use current generated character identities and approved walking cycles. New seated anatomy must be generated with the built-in image generator; preserve complete original outputs and prompts. Do not make characters sit by squashing a standing sprite, assembling limbs, or hiding standing legs behind the bench.

## Findings and approach

Current benches use assets/sprites/retro-beach-bench-32bit.png, a 42x22 scenery sprite positioned from each prop's x/y. They have no seat reservations. BeachRoutine supplies destination walking and timed pauses. ShopperArt selects poses. AdultReaction already supports theft surprise and fist shaking for the original shopper; preserve those changes. Crowd spacing in BeachSpawner modifies actor presentation offsets and depth, so seated actors require explicit anchoring treatment. The current checkout also contains unrelated crab/crumb work and newer diner meal service.

Recommended: a small per-level bench registry plus a per-character visit state, integrated with the existing routine. This provides exclusive occupancy and clean interruption without replacing ordinary movement. A decorative sit pose without reservations would allow overlapping customers; a general-purpose furniture/navigation framework is unnecessary for this horizontal game.

## Scene and ownership

```text
Game (existing)
  BeachBackdrop (existing bench sprites, prop geometry)
  BeachSpawner (existing character collection and crowd spacing)
  BeachTarget (existing shopper)
    AnimatedSprite2D (existing, new seated clips)
    Food sprite (existing, seated per-frame hand anchors)
```

- Per-level bench registry/helper: canonical seat descriptors and reservation owner, cleared on level reset. One occupant per bench initially. Derive anchors from rendered prop geometry, including prop y and scale; no hard-coded universal ground assumption.
- Per-character visit helper/state: phase, timer, seat reference, queued interruption, next eligibility time. Keep it compact and compatible with existing RefCounted helpers.
- BeachRoutine: chooses occasional bench visits and resumes sensible strolling afterward.
- ShopperArt: selects sit_down, seated_idle, seated_eat and stand_up only while visit state owns presentation.
- Food position: remains the single visible and collectible world position; update its anchors on every animation frame and facing change.

Communication: use direct calls between these existing owners and helpers. Existing theft/drop events notify the visit controller through the character's reaction entry points; existing departure/removal paths release reservations. No new global event bus or persistent save state is needed. Document any new signals actually introduced.

## Behaviour

Normal stroll / completed purchase -> reserve nearby free bench -> approach -> align -> sit_down -> seated snack pause -> stand_up -> release seat -> stroll.

- Eligibility: supported shopper holding food, calm, no service lock, dropped-food retrieval, active reaction or departure. Keep tutorial levels 1 and 2 unchanged initially. Respect each character's routine bounds and accessible walking area.
- Starting tuning: consider visits after purchase or at a routine destination, around 30% chance; choose a valid free bench within 220 logical units. Rest 6-10 seconds with occasional bite gestures. Cooldown 20-35 seconds after departure. Seed choices per character rather than rerolling every frame. Adjust only with preview evidence.
- Reserve before approach. If none is available, continue normal routine without waiting or teleporting. Stagger arrivals. Release on cancellation, removal, reset or invalid bench; avoid leaking reservations when an actor disappears.
- Approach uses existing walk and speed. Align hips with the real seat and shoes with the plausible ground plane; preserve adult size. Lock seated visual placement against crowd offsets while allowing passers-by to use the existing spacing logic. Check correct draw order against bench backrest, seat and front supports.
- Sit/stand transitions approximately 0.4-0.6 seconds; use generated transition poses. Seated idle is relaxed, and eating is intermittent rather than continuous arm pumping.
- Snack stays a separate real gameplay object. This first feature adds eating gestures, not a new food-depletion or replenishment system. Do not duplicate snacks, replenish them on sitting, or alter scoring/ownership.
- Food remains snatchable while seated at its actual hand position. On theft, clear food immediately, interrupt eating, stand visibly and then enter the existing applicable surprise/chase/give-up path. Preserve full committed chase duration after standing; never slide or run in a seated pose. A seated surprise frame is optional; never use standing surprise artwork while still attached to the seat.
- Cancel an approach immediately for existing reactions. If already sitting or transitioning, resolve a short coherent stand-up before standing-only attacks/chases, preserving warning and windup fairness. Queue interruption once; do not restart stand-up every frame. If hit rules need a transition guard, document it and test it.
- Handle food drops, service requests, actor departure and freed focus references. After a reaction choose a normal valid destination rather than immediately reclaiming the same bench.
- All visit clocks and animation progress follow gameplay pause. No autonomous Timer/AnimatedSprite playback may continue while simulation is paused.

## Ordered implementation

1. Inspect current code and skill requirements; record baseline validation. Preserve all existing dirty work. This is a direct assignment, not an instruction to process unrelated queue tasks or pull/switch main.
   Skills: godot-prompter:state-machine, godot-prompter:ai-navigation, godot-prompter:scene-organization.
2. Generate original-shopper sit-down, seated idle/eat and stand-up artwork using current identity and bench geometry references. Aim for 4-6 transition frames and 3-4 seated eating frames; judge readable silhouettes over frame count. Preserve full sources, preparation metadata and matching hand anchors.
   Skills: imagegen, godot-prompter:animation-system, godot-prompter:assets-pipeline.
3. Add registry and visit state, animation selection, per-frame food anchors and interruption integration. Preserve current walk/run artwork and theft reactions.
   Skills: godot-prompter:state-machine, godot-prompter:ai-navigation, godot-prompter:animation-system.
4. Build a deterministic bench preview using production paths. Verify original shopper alignment, approach from both sides, sitting, eating, standing, theft and resumption at actual game size and enlarged scale.
   Skills: godot-prompter:animation-system, godot-prompter:godot-debugging.
5. Generate matching complete poses for mullet and sundress shoppers and enable the same feature through supported-animation eligibility. Preserve their revised walks and identities. If artwork cannot be completed, keep unsupported appearances safely on normal routines and report incomplete scope; never substitute another person's art.
   Skills: imagegen, godot-prompter:assets-pipeline, godot-prompter:animation-system.
6. Test and review; save a viewable GIF/video or equivalent animated preview plus representative screenshots, and update this plan with implementation status and exact validation results.
   Skills: godot-prompter:godot-testing, godot-prompter:godot-code-review.

## Acceptance

- All three shopper identities can complete a real approach/sit/snack/stand/depart sequence; no teleporting, standing-leg fakery or identity changes.
- Two shoppers cannot claim the same bench. Occupancy cleans up after cancellation, deletion, restart and theft; no bench available is a safe fallback.
- Visible hand and collectible snack agree in both orientations and all seated frames. Theft/drop and mid-transition interruption neither duplicate food nor strand state or reservations.
- Seated actors remain planted despite crowd spacing; nearby pedestrians and bench depth render coherently.
- Existing theft surprise, bounded pursuit and fist shake remain correct, with no seated attacks, shortened committed pursuit, or immediate untelegraphed hits.
- Pause freezes exact pose/timers; resumption works during approach, sitting, eating, standing and interruption.
- Tutorials, family/diner service, stationary counter portions and their bonus window remain intact.
- Focused meaningful behavioural tests and tools/validate.ps1 (or supported integration entry point) introduce no new failures. Report baseline failures separately, not as passing validation.
- Visually inspect actual rendered output. Deliver paths to previews, generated sources and the final report; do not claim quality based solely on frame pixel differences.

## Workspace handling

Initial branch: codex/pier-diner-meals. Existing modified files include data/sprites.json, data/tuning.json, scripts/beach.gd, scripts/crab.gd, scripts/scraps.gd, scripts/stash_raids.gd, docs/CRABS.md and crab/crumb previews/assets. Re-read status before edits, merge narrowly into shared metadata, and do not revert or commit others' work. Do not switch branches, pull, push or merge for this direct assignment. No queue task is being claimed.

## Implementation report — Codex Sol, 23 October 2026

Implemented the three shopper identities through production paths. No branch switch, pull, commit, push, merge or task-queue mutation was performed. Branch remains `codex/pier-diner-meals`. Earlier dirty crab/crumb changes and diner meal/theft behavior were preserved.

### Files and behavior

- `scripts/bench_registry.gd`: per-spawner level seats measured from beach-bench prop x/y and rendered scale, weak owner reservations, exclusive occupancy, release and stale/reset handling. Accessible seats obey routine x bounds, a 220-unit range and a 24-unit vertical walking tolerance.
- `scripts/bench_visit.gd`: approach, sit, rest and stand phases, deterministic per-character selection, 30% consideration at routine stops or completed purchases, 6–10-second rests, intermittent 0.8-second bites, 0.5-second transitions and 20–35-second cooldowns. A failed roll/unavailable bench also cools down before reconsideration. Walking uses the existing 9-unit speed; no approach teleport. Authored bench y=153 is reached gradually and departure rejoins the original lane gradually.
- `scripts/beach_routine.gd`, `scripts/target.gd`, `scripts/adult_reaction.gd`, `scripts/shopper_art.gd`, `scripts/spawner.gd`: narrow integration for eligibility, food drop/theft, existing proximity warning and theft reactions, anchored crowd placement, actor removal and manually clocked animation. Tutorials 1/2 and other target kinds remain ineligible. No new signals, global bus or autonomous timer was introduced.
- `data/sprites.json` and three new `assets/sprites/shopper-*-bench-v1.png` atlases: appended generated complete figures and per-frame palm anchors. All pre-existing walking/reaction pixels remain intact. Only the three shopper metadata entries were edited by preparation; existing dirty crab/crumb metadata was retained.
- `assets/reference/bench-snack-v1/`: three complete built-in image-generator outputs, exact prompts/reference roles and preparation notes. `tools/prepare_bench_snacks.gd` reproduces whole-figure crop/scale/align preparation. No new bodies, limbs or faces were drawn or assembled in code.
- `tests/bench_snacks.gd/.tscn`: focused behavioral and asset checks. Existing mullet/sundress walk regression checks now accept the appended atlas row and explicitly check that the approved walk/reaction atlas region remains pixel-identical.
- `tools/bench_snack_preview.gd/.tscn`, `tools/make_bench_preview.py`: deterministic production-path preview and GIF/contact-sheet assembly.

### Interruption and fairness decisions

Food remains the existing single visible/snatchable object at its animated hand anchor. Sitting never replenishes or consumes it. Theft hides it immediately. Seated/sitting interruptions reverse the sit progression into a coherent stand; repeated interruptions do not restart standing. Existing standing-only reaction clocks and attack processing wait until the stand completes, preserving the full committed chase duration and the warning/windup allowance. Approach reactions cancel immediately. Drops retain existing retrieval state. A freed gull focus safely resolves through the existing reaction logic after standing. Removal and registry reset release/cancel visits. Standing finishes before routine movement or departure resumes.

### Validation and visual review

- Baseline `tools/validate.ps1`: **16,078 checks, 1 failure**: `level 6 rival leaves the scene of a theft` (`escape_short=4`). Also logged the existing `grab_focus` outside-tree error.
- Final `tests/bench_snacks.tscn`: **474 checks, 0 failures**. Covers all appearances/facings, complete isolated frames, sole baselines, occupancy conflict/release, food anchors, theft and full reaction time, natural departure/cooldown, deletion, reset, partial-sit drop, proximity warning fairness, crowd anchoring, service cancellation, approach cancellation, freed focus, authored prop y, pause/resume through all visit phases and interrupted standing, tutorials and unavailable benches.
- Final `tools/validate.ps1`: **16,276 checks, 1 failure**, the same baseline rival escape check (`escape_short=4`); **no new failures**. Existing `grab_focus` outside-tree error remains. Full output: `test-output/bench-integration-verified.log`. This is not reported as a fully passing integration run.
- Godot editor import succeeds. Rendered preview completes **220 frames / 17.6 seconds**, with no preview errors. Inspected source sheets and production screenshots at actual scale and 2x, plus contact sheet stages: approach both directions, generated knee bend/sit, hip/seat contact, rest and intermittent eating, empty hand/stand after theft, standing surprise/chase, natural stand/departure and stroll resumption. Bench backrest stays behind the torso, shoes/legs remain visible in front of the seat supports, and the sundress drapes over bent legs.

### Deliverables

- `assets/previews/bench-snack-v1.gif`: all three identities, actual logical game scale; natural rest/departure left and theft/stand/chase right.
- `assets/previews/bench-snack-v1.png`: representative 2x rendered seated view.
- `assets/previews/bench-snack-contact-sheet-v1.png`: six representative stages.
- `assets/previews/bench-snack-yellow-proof-v1.png/.gif`: original shopper proof.
- `assets/previews/bench-snack-{seated,standing-after-theft,eat-and-chase,resume}-v1.png`: representative rendered screenshots.
- Generated sources and prompt set: `assets/reference/bench-snack-v1/`.

Scope is complete for the three shoppers. Diners/families/toddlers/lifeguards/vendors remain outside this first rollout, as planned. The pre-existing rival escape regression is the remaining validation limitation.

## Follow-up: bench clearance and family ground lane

User requested that walkers stop using the raised lane over benches, and that mums and toddlers remain close together without overlapping or switching depth lanes. User also authorized committing all pending project changes, superseding the initial no-commit scope above.

- Bench footprints now follow the rendered prop dimensions and authored location. Crowd candidates inside a bench footprint are excluded, and interpolated offsets are corrected before rendering. Anchored seated visitors remain on their seats.
- Mums and toddlers are placed before other walkers and use only horizontal offsets. Children follow their mum's rendered displacement when families cross. Their original simulation positions are restored before gameplay updates, preserving following, handovers and service logic.
- Existing service locks and previous rear-lane offsets do not push family members into another depth lane. Overlapping siblings and crossing families receive distinct horizontal gaps.
- Sol completed the bench implementation. The follow-up delegation hit a usage limit; the parent agent completed family spacing and final validation.
- Focused crowd-spacing validation: **251 checks, 0 failures**, including two families crossing beside a bench. Bench-snack regression: **474 checks, 0 failures**.
- Final `tools/validate.ps1`: **16,515 checks, 1 failure**, the pre-existing `level 6 rival leaves the scene of a theft` (`escape_short=4`). No new failures. The existing outside-tree `grab_focus` error is unchanged. Log: `test-output/family-lanes-integration.log`.
- Rendered `assets/previews/family-ground-lane.png` inspected: mum and two toddlers stay together on the ground line; the crowded two-family case retains distinct silhouettes. Existing generated character artwork is used unchanged.
- Reproducible family preview: `tools/family_lane_preview.tscn`. Focused suite: `tests/crowd_spacing_checks.tscn`.
