# 008 — Off-lead dog sprite sheet (Level 4 prep)

Status: merged
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-10-22

## Goal
The fast off-lead dog for Dog Day Afternoon exists as generated sprite art, ready for the Level 4 code task.

## Context
- Plan: `docs/superpowers/plans/2026-10-22-quests-phase1.md` → **Task 6**. Its Files, Interfaces, data values and test steps are the requirements for this task.
- Spec: `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md`
- AGENTS.md: no code-drawn character bodies/faces/limbs; GullPixel 8/16 px only; tuning in `data/`.

## Requirements
1. Do everything in the plan section named above, in its step order (tests first for code tasks).
2. Record any value or choice the plan left open in the Report.

## Out of scope
- Other plan tasks and later phases (levels 4+, shop, diving).

## Done when (acceptance)
- [x] Every step of the plan section is checked off
- [x] `./tools/validate.ps1` has no new failures (16,112 checks; existing baseline failure documented below)
- [x] Preview screenshot of every animation in the Report

## Report

Completed Task 6 / task 008 with the built-in image generator on 23 October 2026. Before generating the off-lead dog, the user explicitly requested that the dog walker and leashed dog be adapted to the current cast's pixel style. That prerequisite was implemented, rendered, validated and committed first. The off-lead sheet then used the new pixel terrier as its identity/style reference.

Plan steps:
- [x] Generate run, leap, catch/bite, idle and sniff poses for the off-lead terrier in the established pixel style.
- [x] Preserve complete generated source artwork and exact prompts; prepare runtime sprites without drawing anatomy in code.
- [x] Register the new asset in `data/dog_art.json` and the runtime sprite manifest.
- [x] Preview every animation and mirrored poses alongside the walker/leashed dog for scale.
- [x] Run validation and record results.

Files changed:
- Walker prerequisite: `assets/reference/dog-walker-pixel-v1/` (two complete generated source sheets, prompts, README), `assets/sprites/dog-owner-pixel-v1.png` plus import settings, `data/dog_owner_art.json`, existing `dog` entry in `data/sprites.json`, `docs/BEACHGOER_ART.md`, offline preparation and preview tools, and [walker pose/style comparison](../../assets/previews/dog-walker-pixel-v1.png).
- `scripts/target.gd`: dog owners now use nearest-pixel sampling and native hard alpha like the other pixel characters, with no legacy cutout shader. `tools/map_beachgoer_sheets.py` preserves the new registered owner art on rebuild. Existing integration art checks now expect crisp dog-owner rendering and the 40px adult scale.
- Off-lead asset: `assets/reference/off-lead-dog-v1/` (complete source, exact prompt, README), `assets/sprites/off-lead-dog-pixel-v1.png` plus import settings, `data/dog_art.json`, new `off_lead_dog` entry in `data/sprites.json`, offline preparation/preview tools and [every-animation preview](../../assets/previews/off-lead-dog-production-v1.png).

Decisions:
- Preserve the woman's dark ponytail, lavender tee, beige shorts and lilac trainers, and the sandy terrier's cream muzzle/chest and teal collar. Walker remains a full 40px adult. Pair uses eight 192×128 cells at 0.5 scale, baseline 116 / offset -26. Existing walk/idle/alert/bark/angry timing remains intact; food stays separate and stealable with mirrored per-frame hand anchors.
- Use the new sprite ID `off_lead_dog` so the existing paired `dog` ID remains available. Thirty generated poses, six each for run / leap / catch / idle / sniff. `bite` aliases the six catch frames for either gameplay naming convention.
- Off-lead canvas 128×96, scale 0.5, idle height 16 game pixels, baseline 84 / offset -18. One scale applies to the entire source sheet so crouching/sniffing do not enlarge the head. Collar alignment fixes the horizontal pivot; relative source paw heights retain airborne poses.
- Clip values are in the art JSON: run 12 fps looping; leap 10 fps non-looping; catch/bite 12 fps non-looping; idle 4 fps looping; sniff 6 fps looping. Future controller code owns movement, jump physics, catch/stun behavior and Level 4 spawning/quests.
- Full source artwork is untouched. Preparation only crops, cleans alpha, scales, aligns and packs generated pixels. All production sprites use lossless hard alpha without mipmaps.
- Main still listed task 006 in inbox, but it was already completed and pushed on `codex/006-customer-bite-sprites` in the preceding run. It was not regenerated. This run processed task 008 plus the user's explicit prerequisite.

Validation:
- Baseline on up-to-date main `f664661`: **16,110 checks, 1 failure** — `level 6 rival leaves the scene of a theft`.
- Walker prerequisite full run: **16,112 checks, 1 failure**, the identical baseline rival failure. Focused pixel-style checks went from four false before implementation to **4/4 passing** after it. Hard alpha, complete 80px actors, soles and gutters checked for all eight paired cells; production preview visually reviewed.
- Final `./tools/validate.ps1 -Godot <existing 4.7.2 console executable>`: **16,112 checks, 1 failure**, the same baseline rival failure. **No new failures.** The command still exits nonzero because that existing failure remains; this is not a clean green suite. Existing UI `grab_focus` diagnostics also occur on baseline.
- Off-lead rendered preview: **68 checks, 0 failures**, covering all thirty complete isolated sprites, transparent gutters, hard alpha/no mipmaps, six frames per animation group, the bite alias and screenshot output. Empty preview error log. Visually checked all animations, left-facing poses, palette and relative dog/adult scale.
- Registry comparison confirmed the off-lead step only appended `off_lead_dog`; all previous entries remain identical to the walker prerequisite. Standalone `data/dog_art.json` agrees with the runtime manifest. `git diff --check` passed.
- Local logs: `test-output/task-008-baseline-validation.log`, `dog-walker-validation.log`, `task-008-final-validation.log` and the two preview logs in the task checkout.

Nothing from the asset task or requested walker prerequisite remains unfinished. Off-lead gameplay is outside this asset-only task; the existing rival failure is unchanged.

Branch: `codex/008-off-lead-dog-sprites`, from up-to-date main; isolated checkout `.tools/queue-008` preserves the original crab/crumb work.

Walker prerequisite commit: `7084b435c0849845ea690fcdf10f3ed465ce31f7` — `Match dog walker and leashed terrier to the pixel cast`.

Last implementation commit: `7ca26ce6baf32936de731880668471a236f1919a` — `Add off-lead terrier animation assets for task 008`. This completion report follows in a separate commit; the branch tip identifies the final metadata commit.

Full sources/prompts: [walker](../../assets/reference/dog-walker-pixel-v1/README.md), [off-lead terrier](../../assets/reference/off-lead-dog-v1/README.md). Both used the built-in image tool.

## Review notes
