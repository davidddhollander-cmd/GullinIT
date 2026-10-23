# 006 — Customer bite pose sprites

Status: merged
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-10-22

## Goal
Kiosk/shopper customers have a raise-snack-to-mouth bite pose, generated with the image generator, so the mid-air bite quest is readable.

## Context
- Plan: `docs/superpowers/plans/2026-10-22-quests-phase1.md` → **Task 5, part 5a**. Its Files, Interfaces, data values and test steps are the requirements for this task.
- Spec: `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md`
- AGENTS.md: no code-drawn character bodies/faces/limbs; GullPixel 8/16 px only; tuning in `data/`.

## Requirements
1. Do everything in the plan section named above, in its step order (tests first for code tasks).
2. Record any value or choice the plan left open in the Report.

## Out of scope
- Other plan tasks and later phases (levels 4+, shop, diving).

## Done when (acceptance)
- [x] Every step of the plan section is checked off
- [x] `./tools/validate.ps1` has no new failures (16,097 checks; existing baseline failure documented below)
- [x] Generated frames match existing shopper scale and palette; preview screenshot in the Report

## Report

Implemented Task 5a only, using the built-in image generator on 23 October 2026.

Plan steps:
- [x] Generate three raise / mouth / lower frames matching the existing mullet and sundress shoppers; include the original `kiosk_customer` appearance so every current customer has the pose.
- [x] Preserve adult scale and palette, keep complete generated source strips, and leave food as the existing separate stealable sprite.
- [x] Register non-looping `bite` clips and per-frame food anchors in the art JSON and runtime registry.
- [x] Render a production-scale comparison including mirrored bite poses.

Files changed:
- `assets/reference/shopper-bite-v1/`: three untouched generated source strips, exact prompts, and a README with registration/rebuild details.
- `assets/sprites/*-bite-v1.png` and import settings: three versioned production atlases. Existing atlases remain intact.
- `data/shopper_art.json`, `data/shopper_variants_art.json`, `data/sprites.json`: `bite` frames and food anchors for all three customers. Only those three runtime registry entries changed.
- `tools/prepare_shopper_bites.gd`: offline cropping, hard-alpha cleanup, nearest-neighbor resizing, foot alignment, packing and registration. No character anatomy is drawn by code.
- `tools/shopper_bite_preview.gd`, `.tscn`, and [the preview screenshot](../../assets/previews/shopper-bite-production-v1.png): real sprites with separate food and GullPixel text at 8/16px.
- `tests/mullet_walk_checks.gd`, `tests/sundress_walk_checks.gd`: update historical filename/blank-cell expectations for the appended bite frames while keeping previous animation, canvas and non-walk pixel checks.

Decisions:
- Three frames at 5 fps, non-looping: 0.6 seconds total, matching the planned bite window. Task 007 owns gameplay scheduling and quest events.
- Include `kiosk_customer` as well as the two named variants because all three are selected by the existing customer appearance rotation.
- Use 128px source canvases, 80px actor height, baseline 116, display scale 0.5, adult height 40px and sprite offset -26, matching current art. Frames are appended at 38–40 for the original shopper and 26–28 for each variant.
- Align soles to the existing idle art and measure snack anchors on the prepared frames. Preserve complete sources and all 90 existing animation frame references/pixels.
- No gameplay files under `scripts/` changed. Offline preparation/preview helpers and necessary existing asset-check updates support the registration.

Validation:
- Baseline on up-to-date `main` (`02aa6b5`): **16,046 checks, 1 failure**, `level 6 rival leaves the scene of a theft`.
- Final `./tools/validate.ps1 -Godot <existing 4.7.2 console executable>`: **16,097 checks, 1 failure**, the identical level 6 rival failure. **No new failures.** The command still exits nonzero because that baseline failure remains; it is not a clean green run. Existing UI `grab_focus` diagnostics also appeared in the baseline.
- Focused historical walk regression checks: **84 checks, 0 failures**.
- Rendered preview: **45 registration/alignment assertions passed**, empty error log. Visually checked scale, palette, foot baseline, separate snack alignment and left-facing poses.
- Independent comparison against `main`: all **90 existing animation frame references/pixels preserved** (38 original shopper + 26 mullet + 26 sundress); only the intended three runtime registry entries changed. `git diff --check` passed.
- Local validation logs are under `test-output/task-006-*.log` in the task checkout.

Nothing from Task 5a remains unfinished. Gameplay bite timing and the mid-air quest belong to task 007; the existing rival failure is outside this asset task. Only one queue task was processed.

Branch: `codex/006-customer-bite-sprites` (from up-to-date `main`, isolated checkout `.tools/queue-006` to preserve the existing crab/crumb work).

Last implementation commit: `d607f674d63d297b119fbdfab4bb2cb4ba7f4f4d` — `Add generated customer bite pose sprites for task 006`. This completion report follows in a separate commit on the same branch; the branch tip identifies that final metadata commit.

Sources and full prompt set: [shopper-bite-v1 README](../../assets/reference/shopper-bite-v1/README.md). Generation used the built-in image tool, not a CLI/API fallback.

## Review notes
