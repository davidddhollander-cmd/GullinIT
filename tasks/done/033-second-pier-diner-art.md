# 033 — Second pier diner look (art)

Status: merged
Author: Claude
Assignee: Codex
Depends on: none
Created: 2026-10-25

## Goal
Levels 5 and 6 each have two pier diners. There is only one diner look (woman, red cap, teal-striped T-shirt, navy shorts: `assets/sprites/pier-diner-retro-clean.png`), so the two diners are identical twins. Add a second, clearly different diner so no level repeats a person.

## Requirements
1. Generate (built-in image generator) a new full-body pier diner who reads as a different person at a glance, at in-game size: a man with a different silhouette, hair or hat and colour scheme from the existing diner. Suggestion: a younger man in a bucket hat, sunglasses, a bright vest or tank top and board shorts. Avoid red caps, teal stripes and navy shorts. He must not look like the old man, the shoppers or the sunbathers either.
2. Match the shoppers' pixel density: 128x128 frames, about 40 px art height, used at `visual_scale` 0.5 (see `kiosk_customer` in `data/sprites.json`). Use the same outline weight and palette style. Don't copy the current diner's 400x400 frames at 0.11.
3. Poses: the same 13 animations the current diner uses, so gameplay can swap looks without code changes:
   - base sheet: `idle`, `notice`, `watch`, `alert`, `brace`, `windup`, `swat`, `angry`
   - motion: `walk`, `run`, `eat`
   - reactions: `surprise`, `fist_shake`

   He holds fried fish (paper cone or tray) where the current diner does, with a food anchor that matches.
4. Keep the untouched source artwork and prompts in `assets/reference/pier-diner-b-v1/`. Put a preview image in `assets/previews/` showing both diners side by side at in-game size.
5. Register the new sprites in `data/sprites.json` under new ids (`pier_diner_b`, `pier_diner_b_motion`, `pier_diner_b_reactions`). Don't change gameplay code. Choosing which look each diner gets in a level is a follow-up Sonnet task.
6. AGENTS.md applies: generated art only. No code-drawn bodies, faces or limbs, not even as placeholders.

## Done when (acceptance)
- [x] Sprite entries exist for all 13 animations under the new ids
- [x] The preview image shows both diners together at in-game size, clearly different
- [x] Art-check tests cover the new ids (extend the diner art checks)
- [x] `tools/validate.ps1`: 0 failures

## Report

**Files changed:** `assets/reference/pier-diner-b-v1/` (four untouched built-in ImageGen source sheets, exact prompts and README), `assets/sprites/pier-diner-b-{base,motion,reactions}-v1.png` plus lossless Godot import metadata, `assets/previews/pier-diner-b-v1-comparison.png` plus import metadata, `data/sprites.json`, `tests/integration.gd`, and `tools/prepare_pier_diner_b.gd` plus UID.

**Tests:** `./tools/validate.ps1` — **13,704 checks, 0 failures**. `git diff --check` also passed.

**Decisions:** Built-in ImageGen produced a tall, lean younger man with a lime bucket hat, purple sunglasses, magenta tank, yellow/purple board shorts and white high-tops. This is immediately distinct from the red-cap/teal-stripe original, the orange-jacket shopper, sunbathers and old man. The source sheets remain untouched. The offline preparation tool only isolates/crops generated figures, hardens alpha, nearest-resizes them to about 80 source pixels high, aligns soles, packs 128×128 cells and composites the comparison preview; it never draws character anatomy. Runtime art uses `visual_scale: 0.5`, `art_height: 40`, `sprite_offset_y: -26`, lossless import and no mipmaps. Fried fish remains the existing separate gameplay sprite, with a per-frame anchor on the generated open supporting palm. The reaction sheet received one targeted built-in ImageGen cleanup pass to remove detached comic motion symbols; that exact edit prompt is preserved.

The fetched `origin/main` commit was `9cd1fde`; local `main` was occupied by the separate `GullinIt-main` worktree, so this branch was created directly from that fetched commit rather than disturbing the other worktree. The unrelated cafeteria work remains preserved in `stash@{0}`.

**Not done:** No gameplay or level data was changed. Selecting `pier_diner_b` for one diner in Levels 5 and 6 remains the explicitly planned follow-up Sonnet task.

**Branch:** `codex/033-second-pier-diner-art`

**Implementation commit:** `6f0870d` (`Add second pier diner art`). The task-report move is committed separately after this report.

## Review notes
