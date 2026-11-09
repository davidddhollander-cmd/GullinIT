# 071 — Sweeper ignores Shakedown and always enters from a screen edge

Status: merged
Author: Claude
Assignee: Claude Haiku
Depends on: 070
Created: 2026-11-09

## Goal
Two playtest notes. The sweeper is the one character who is not scared of Shakedown. And he must never appear out of nowhere: he always comes in from the left or right edge of the screen.

## Context
- `scripts/shakedown.gd` `_scare()` adds the sweeper to the actors that flee. `scripts/sweeper.gd` has `flee_to`, a flee block in `tick()`, and `come_home()`, all added only for this.
- `scripts/sweeper_visits.gd` `_spawn()`: tries `camera_x±176`, but only if that is inside his sand range. The final `else` clamps x to the range ends, which can be on screen. Trace any other route to a visible pop-in, such as `sweeper.setup()` or the `ENTER` state moving him on the first frame, and check whether the view can be wider than 320 (`project.godot` stretch settings).

## Requirements
1. Remove the sweeper from `_scare()`, and delete his `flee_to`, flee block and `come_home()`. During Shakedown he behaves as he does normally: his hits bounce off and show "NOPE!". Dog and teen still flee.
2. In `_spawn()`, x is always just outside the current visible screen, on the left or right. Prefer the side nearer his sand range, and if both qualify, the side furthest from the gull as now. Remove the clamp that can place him on screen. He then runs in along the ground to his range using `ENTER`.
3. Use the real visible half-width plus a small margin rather than a magic 176, if the view can be wider than 320.

## Done when (acceptance)
- [ ] During Shakedown the sweeper does not flee; dog and teen do; Shakedown tests updated to match
- [ ] For camera positions across the whole level, including at both ends and past his sand range, a new sweeper starts outside the visible screen and reaches his range by running
- [ ] Checks added; `./tools/validate.ps1` has no new failures

## Report
<!-- Filled in by the implementer. -->

## Review notes
<!-- Filled in by the reviewer. -->

Report (Claude Haiku, branch `haiku/071-sweeper`, commit `683a74f`):

Files changed: `scripts/sweeper.gd` (removed `flee_to`, its flee block and `come_home()`; added `screen_reach()`), `scripts/shakedown.gd` (sweeper removed from `_scare()`, comments updated), `scripts/sweeper_visits.gd` (`_spawn()` rewritten, `_half_width()` and `_range_gap()` added), `data/tuning.json` (`sweeper.spawn_margin: 8`), `tests/shakedown_checks.gd`, `tests/sweeper_checks.gd`.

Pop-in cause: the old `_spawn()` put him at `camera_x±176`, which is just outside the 320-wide view only when the sprite is ignored. His sprite reaches about 66 px toward the screen from his feet (cell width 211 × 0.5 minus body anchor 79 × 0.5), so the broom and body showed on screen at spawn. The worse case was the final `else`: once the camera was past his sand range (for example camera 800), both sides failed the range test and the code clamped x to 640 with `camera_x > range[1]` choosing the right side. At camera 800 the view is 640..960, so he appeared at its left edge.

Fix: spawn at `camera_x ± (half-width + sprite reach + spawn_margin)`. The half-width comes from the viewport's visible rect divided by camera zoom (160 here, since `window/stretch/aspect` is unset, so the view stays 320 wide). Side choice: a side inside his range wins; if both are, the one furthest from the gull as before; if neither, the one nearer his sand range (by distance to the range), not the clamp. `ENTER` then runs him in to the range; the `_move` clamp still applies, but it only ever moves him off-screen.

Test results (`tests/integration.tscn`, run directly with Godot headless, same as `tools/validate.ps1` integration step): 16,970 checks, 2 failures, both known on main: "nobody teleports across the beach while running off (1 jumps)" and "data/demo.json enables the four-level demo". Main had 16,957 checks; the +13 are the new checks below.

New checks: view width is 160 half (320 total); at every camera position from 160 to 1120 in 16 px steps plus the end, the new sweeper starts outside the visible screen, past his range he comes from the nearer side, nothing jumps onto the screen while running, and he reaches his range and patrols. Shakedown: he is not scared (no `flee_to`, no `come_home`), and during the power his swats bounce and he keeps working the sand; dog and teen still flee and return.

Decisions: "qualifies" keeps the existing ±20 px tolerance on each side. The spawn margin is 8 px on top of the sprite reach, which covers the ±4 px stun shake. `validate.ps1` exits 1 because of the 2 known failures, so I ran the integration scene directly to get the check list.

Not done: no LOCK file, since the work is in a worktree and not the queue checkout. The camera lerp can move the view toward a sweeper that spawns on the gull's side faster than his run speed. This is not covered by the checks; the spec does not ask for it, but it's a possible follow-up.
