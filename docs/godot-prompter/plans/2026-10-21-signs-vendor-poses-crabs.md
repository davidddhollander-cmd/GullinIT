# Beach signs, vendor poses and crabs

Implement in this order. Follow AGENTS.md and preserve existing workspace changes. The existing task brief is `docs/CODEX_TODO_2026-10-21.md`; this plan records implementation choices and completion criteria.

Progress: the smaller v2 signs are approved. Step 2 is implemented with ChatGPT-generated turning/working poses, rendered previews and an animated GIF. Full headless integration: 15,824 checks, zero failures; focused vendor/service: 122 checks, zero failures. Step 3 is now implemented: supplied red/blue crabs enter from sea/screen edges and can be pecked or dive-snatched for 100 base points. Crab checks pass 73/73; full integration has 15,910 checks with only the known rival escape-distance failure. See `docs/CRABS.md` and `assets/previews/crab-cycle-v1.gif`.

Latest revision: the user requested roughly half-length arrows and much smaller labels. V2 uses narrower boards and the compact native GullHud bitmap font; all six levels pass focused placement checks and have updated desktop/phone renders. The user approved `assets/previews/beach-signs-review-v2.png` by asking to proceed with step 2.

Confirmed artwork requirements: changes 1 and 2 MUST use ChatGPT image generation through the built-in `image_gen` tool. Code may crop, align, import and animate the resulting artwork; keep sign labels as crisp pixel text. Change 3 uses the user-supplied `assets/sprites/crabs-transparent.png` (file presence verified); preserve this original intact.

## 1. Generated wooden direction signs

- [x] Generate blank wooden left/right arrow boards, a post and a two-finger variant with the built-in image generator. Match `docs/RETRO_ENVIRONMENT_STYLE.md`. Preserve complete sources and prompts under `assets/reference/beach-signs-v1/`; derive game assets by cropping/alignment only. Implemented as a generated right arrow and post, a mirrored left arrow and assembled two-finger variant.
  Skills: `imagegen`, `godot-prompter:assets-pipeline`.
- [x] Replace the plain zone-board rendering in `scripts/beach.gd` with generated textures and a separate GullPixel text overlay. Keep text on integer coordinates, use nearest filtering, and size usable board interiors around the labels. Allow room for arrow tips and posts in placement bounds.
  Skills: `godot-prompter:2d-essentials`, `godot-prompter:assets-pipeline`.
- [x] Extend `sign_layouts()` and its renderer to derive destination, direction, texture variant, text position and full visual bounds. Snack arrows target real kiosk/hot-dog props; promenade/pier arrows use the current level's destination boundaries. Resolve direction after final placement. Omit unavailable destinations. Retain useful zone labels, avoid prop/flag/sign overlaps and preserve hint clearance. Keep stall frontage names in `scripts/stand_sign.gd` distinct from these wayfinding signs.
  Skills: `godot-prompter:2d-essentials`, `godot-prompter:gdscript-patterns`.
- [x] Check destination/direction and placement in authored levels 1–3 and generated levels 4–6. Update existing sign-layout checks for actual sprite bounds. Capture desktop and phone views.
  Skills: `godot-prompter:godot-testing`.

Done when wooden silhouettes and pointing directions read clearly at game size, with crisp labels and no covered hints or stalls.

## 2. Vendor turns away, prepares, returns and serves

Recommended approach: keep the existing service phases and map preparation progress to new poses. This keeps service timing authoritative in `StallService` without an independent animation clock. Explicit turn/work/return gameplay states are an alternative only if later interactions need them.

- [x] Inspect the existing full-body source artwork named in `data/vendor_art.json`, then generate reference-based turn-away, back-view working and turn-back poses for both vendors. Preserve face, uniform, hair/cap, adult proportions and complete full-body sources. Store new sources/prompts in a versioned reference folder and derived sheets separately.
  Skills: `imagegen`, `godot-prompter:assets-pipeline`.
- [x] Extend `tools/prepare_stall_vendors.gd`, metadata and `scripts/vendor_art.gd` for the new frames. Keep the 128×128 cell alignment, sole baseline 116 and current adult scale unless visual inspection establishes an alignment correction. Retain the serving-window mask: torso visible, lower body behind the stall.
  Skills: `godot-prompter:assets-pipeline`, `godot-prompter:animation-system`.
- [x] Map PREPARE to turn away → work → turn back, then use PLACE → COUNTER → RETRACT. Hide the decorative food while the vendor faces away; reveal it with the forward placement gesture. Drive all frames from the existing scaled service clock so pause/freeze stay synchronized. First fit poses within the current preparation duration; if unreadable, adjust preparation only and document the pacing change.
  Skills: `godot-prompter:animation-system`, `godot-prompter:state-machine`.
- [x] Preserve the stationary 0.85-second counter window, existing +50% dive-snatch bonus, once-only food ownership and cancellation behavior. Animation must never grant food independently. Extend service/art checks for pose order, hidden preparation food, pause/freeze and interruption; retain existing counter-snatch regressions. Review both service sides, adults, children and family reserve portions in the vendor preview; update `docs/STALL_VENDORS.md`.
  Skills: `godot-prompter:godot-testing`, `godot-prompter:animation-system`.

Done when both vendors visibly face away to prepare, return to place the snack, and the existing counter collection and bonus checks still pass.

## 3. Crabs — moving, catchable, highest-value prey

- [x] Artwork location supplied: `C:\Users\david\Documents\ChatGPT\GullinIt\assets\sprites\crabs-transparent.png`. Use this file as the source; no new crab artwork is requested.
- [x] Gameplay role confirmed: crabs are actual animated gameplay assets that emerge from the sea or enter from a side of the screen. The gull can catch them by pecking or dive-snatching. They award the highest catch score. Do not add pinching, gull damage or toddler reactions without a separate request.
- [x] Inspect the supplied sheet, identify available poses and transparency, and derive frame metadata/crops while preserving the original. Keep any working source copy under `assets/reference/crabs-v1/`. Select frames for emergence, sideways scuttling and capture where available. If required poses are missing, report the gap before generating additional artwork.
  Skills: `godot-prompter:assets-pipeline`, `godot-prompter:animation-system`.
- [x] Add a crab actor with a generated-art sprite child, a catch position/radius and a small EMERGE → SCUTTLE → CAUGHT/EXIT lifecycle. Reuse the existing catchable-target interface where it fits; keep crab movement separate from human food ownership. Give each crab one authoritative active/caught state so a peck and dive cannot collect it twice.
  Skills: `godot-prompter:scene-organization`, `godot-prompter:state-machine`, `godot-prompter:animation-system`.
- [x] Extend spawning and level configuration for both sea-entry and left/right screen-edge entry. Use the current camera bounds for screen-edge arrivals, constrained to valid world space. Animate a readable transition from water onto sand or from just off-screen into view; avoid abrupt visible spawning and avoid stall/counter routes. Keep entry frequency, speed, active count and exit lifetime configurable. Use the game's scaled clock, pause/freeze behavior, seeded spawning and level teardown conventions.
  Skills: `godot-prompter:2d-essentials`, `godot-prompter:state-machine`, `godot-prompter:gdscript-patterns`.
- [x] Wire ordinary pecks and timed dive-snatches into the existing collision/capture and digestion/scoring flow. Use swept dive contact so fast dives cannot skip a crab. Preserve stomach-capacity rules and normal score-award timing; an unsuccessful catch must not remove the crab or award points. Remove a caught crab from all target lists exactly once. Crabs do not inherit the stall-only handover bonus.
  Skills: `godot-prompter:player-controller`, `godot-prompter:component-system`, `godot-prompter:gdscript-patterns`.
- [x] Add a crab entry to food/score configuration and sprite metadata. Set its base catch points strictly above every other catchable item's base value; compare equivalent combo/bonus conditions when verifying the highest-score ranking. Pick the numeric value against the current food table during implementation. Review spawn frequency and level score pacing together, preserving existing star targets unless a demonstrated balance issue requires a documented adjustment. Document entry modes, controls and reward in `docs/CRABS.md`.
  Skills: `godot-prompter:resource-pattern`, `godot-prompter:gdscript-patterns`.
- [x] Verify sea emergence, both screen-edge entry directions, animated movement, peck capture, fast dive capture, once-only removal/reward, failed/full-stomach catches, highest base score, pause/freeze and cleanup on restart/level change. Check actual source artwork at phone and desktop size and ensure existing food, stalls and counter-snatch checks still pass.
  Skills: `godot-prompter:godot-testing`.

Done when supplied-art crabs enter naturally from both supported origins, can be pecked or dive-snatched, and are the highest-value catch under equivalent scoring conditions. Artwork location and gameplay role are resolved; no clarification gate remains.

## Verification during implementation

After each implemented change, run relevant focused checks and `tests/integration.tscn` headless, then review actual rendered captures at desktop and phone size. Record baseline failures separately from regressions; the existing brief's historical failure notes have not been revalidated in this planning pass. Preserve generated sources and avoid code-drawn character replacements, including placeholders.
