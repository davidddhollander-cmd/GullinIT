# Generated full-body stall vendors and counter snatches

Updated 21 October 2026. Both vendors are full-body characters created with ChatGPT image generation. Each now has twelve poses: the eight original approved poses plus a generated turn-away, two back-facing working poses and a turn-back pose. The ice-cream worker keeps her teal uniform, brown bob and cream paper cap; the hot-dog worker keeps her red uniform/cap and copper ponytail. New poses use the matching v2 full-body sheet as the identity/style reference.

## Full-body artwork, upper-body display

The original complete cap-to-shoe sheets are preserved in `assets/reference/stall-vendors-v2/`. Exact generation prompts and tool provenance are in `PROMPTS.json` in that folder. Runtime atlases retain each entire figure on 128 x 128 canvases, about 80 source pixels tall, displayed at 0.5 scale: the same approximately 40-pixel adult height as the existing cast. Shoes share source baseline 116; alignment uses the shoes rather than the changing arm silhouette.

The new intact turn/preparation sheets and exact generation/edit prompts are in `assets/reference/stall-vendors-v3/`. The v3 atlases preserve all eight v2 frames pixel-for-pixel and append four complete generated figures, independently aligned to the same 80-pixel height and shoe baseline. Import preparation clears transparent RGB/edge alpha; it never paints faces, bodies or limbs.

`scripts/food_stall.gd` places the full `AnimatedSprite2D` inside a local `Control` serving-window mask. The mask shows the head/upper torso and hides legs and lower apron behind the booth front. No lower-body artwork is deleted. Masking applies after mirroring too. The source figures remain usable outside the stalls later. Stall signs are raised enough to keep the generated faces/caps readable.

All code-drawn vendor faces, bodies and arms have been removed. Code draws only booth scenery and the counter shelf. The user's rule against code-generated main-character art is recorded in the project `AGENTS.md`.

The stands now use the approved v2 ChatGPT roof signs: flourished navy lettering, a cream/coral hot-dog plaque and cream/teal ice-cream plaque, each with a matching food cut-out at the upper-left corner. `scripts/stand_sign.gd` displays a 64-pixel-wide generated texture instead of drawing the former plain board/awning/text. `tools/prepare_stand_roof_signs.gd` crops the intact approval assets to 256-pixel-wide runtime textures for crisp rendering. Their bottom is y=119 on a ground-level stand, above the serving window at y=120, preserving vendor visibility. Wayfinding placement includes the full roof-sign footprint. See `assets/previews/stand-roof-signs-integrated-v2.png` and `tools/stand_roof_sign_preview.tscn`.

The complete booth shell, masked vendor, shelf and sign share draw depth 2. Rear-lane walkers draw behind all of them; ground-lane customers remain in front. Flying gulls, exposed/loose food and effects retain foreground visibility. `tools/stall_depth_preview.tscn` reproduces both stands with crossing lanes and compares rendered serving-window pixels against a frame with rear walkers hidden.

## Counter service

Buyers now show a tiny 16×9-pixel speech balloon with three moving dots when a purchase is accepted at the counter. It sits above the head, follows the buyer and lasts 0.9 seconds. Families show it above mum once for the whole order. The existing service clock controls its motion/fade; pause and hit freeze stop it, and cancellation removes it immediately. It ends before placing food and does not alter purchase or scoring rules. See `docs/godot-prompter/plans/2026-10-22-order-bubble.md` and the actual-game `assets/previews/order-bubble-cycle.gif`.

PREPARE now lasts 1.4 seconds (increased by another 0.5 seconds at the user's request on 22 October): turn away for the first 20%, alternate the two back-facing working poses until 78%, then turn back before PLACE begins. The decorative snack is hidden throughout PREPARE and appears only for the placing gesture. Pose selection uses the existing scaled service progress; no independent animation timer or food-grant event was added. Counter/receipt/cancellation logic is unchanged.

The vendor prepares a snack, makes the generated placing gesture, and sets the separate food sprite onto the shelf. It stays **stationary on the counter for 0.85 seconds**, with its bottom exactly on the shelf surface. The extended counter keeps it beyond the roof footprint and reachable by an approaching dive. Gold corners mark the opportunity. The vendor withdraws while the snack remains on the counter; the buyer collects it afterward, with a short movement into the normal carried-food hand position.

A successful timed dive PECK during the counter window displays **COUNTER +50%!**. That bonus adds 50% of base food points alongside Risky/Upwind/Mugged modifiers, before the combo multiplier, and scores once when the caught food is swallowed. A 25-point ice cream earns 38 with only this bonus after rounding. Results count COUNTER events. Internally the existing `handover` snack flag/score key is retained for compatibility.

A full stomach, dive without an active peck, near-miss knockdown, ground recovery, rival interception or theft after the buyer collects does not earn the player's counter bonus. There is one real serving item; if stolen or knocked away, the buyer cannot receive a replacement when the animation finishes.

Stall-side shoppers begin by purchasing. Robbed kiosk shoppers finish their reaction and any dropped-food recovery before revisiting a compatible stand. Distant initial carriers, including Training Day's first snack, and deliberate teaching restoration are retained. Other NPC categories keep their existing supply behavior.

Families buy only missing child snacks and restore mum to two crisp bags inclusive of her held bag and any still-owned dropped bag. Cookies remain finite. Every item, including reserve stock, has its own counter window. Mum keeps an already-held snack on the side away from the counter during a reserve purchase, leaving both items visibly separate. Counter theft cancels the rest of that order and triggers retreat/retry during BUY as well as RETURN. One stand serves one order at a time, without queue UI.

## Assets and reproduction

- Full generated sources and prompts: `assets/reference/stall-vendors-v2/` and `assets/reference/stall-vendors-v3/`.
- Runtime sheets: `assets/sprites/vendor-ice-cream-full-body-v3.png` and `vendor-hotdog-full-body-v3.png`; original v2 sheets remain intact.
- Metadata and cached frames: `data/vendor_art.json`, `scripts/vendor_art.gd`.
- Atlas import preparation: run Godot headlessly with `--script tools/prepare_stall_vendors.gd`, then reimport. This script only crops, aligns and scales the generated artwork; it never draws characters.
- Runtime service: `scripts/stall_service.gd` coordinates prepare/place/counter/collect and once-only inventory changes; `scripts/stall_portion.gd` supplies normal swept theft/knockdown targeting.
- Preview: `tools/stall_vendor_preview.tscn` saves turning, working, return, counter, phone, successful theft, family/reserve and complete unmasked turnaround views as `assets/previews/stall-vendor-*-v3.png`. Earlier previews remain available.
- Current animated actual-game preview: `assets/previews/stall-vendor-turn-cycle-1.4s.gif` (the older v3 GIF retains the original 0.9-second preparation). Reproduce its frames by running the preview with `-- --turn-cycle`; frames are saved under `test-output/vendor-turn-v3-frames/` at a 0.05-second simulation interval, then assembled into a 20-fps GIF with FFmpeg.

The vendors remain independent of the crowd target cap. The serving food uses the existing player/rival targeting and score/digestion routes. All phases are manually advanced by the game's scaled simulation step, so pause, hit freeze, intros and results freeze presentation and receipt together.

## Tuning

Values are in `data/tuning.json`:

| Key | Value |
| --- | --- |
| `score.handover` | 0.5 additive counter-snatch modifier |
| `world.stall_prepare_time` | 1.4 s readable turn/work/return |
| `world.stall_extend_time` | 0.18 s placing motion |
| `world.stall_handover_time` | 0.85 s stationary counter window |
| `world.stall_retract_time` | 0.18 s collection/recovery |
| `world.stall_retry_wait` | 4 s interrupted-service retry |

Three family items now take roughly 7.83 seconds plus positioning (previously 6.33 seconds at 0.9-second preparation). Only preparation was lengthened; the 0.85-second counter-snatch opportunity, bonus and existing time/score targets remain unchanged. The separate seafood broom defender is outside this two-stall art update.

## Validation

The focused service suite includes original/new source preservation, pixel-identical original frames, twelve distinct full-body poses, shoe anchors, hard alpha, adult scale, window clipping/mirroring, actual turn/work/return order and hidden food throughout preparation. Pause and hit-freeze are checked during preparation as well as the counter opportunity. Existing real dive/peck scoring, shopper appearances, family stock/retreat, knockdown, full stomach, busy stands, results and large-step checks remain. Run `tests/stall_service_checks.tscn` or the full `tools/validate.ps1 -Capture` workflow.

V3 validation: **15,824 headless integration checks, zero failures** (`test-output/vendor-v3-integration.log`); **122 focused vendor/service checks, zero failures**. Actual rendered desktop/phone, working/return, counter-snatch, family/reserve and full-body turnaround captures were visually reviewed. Preview and animated-cycle error logs are empty. The following v2 result is historical.

Final v2 validation: **11,938 rendered integration checks, zero failures**, including **94 focused vendor/counter checks**. The focused standalone run also passes cleanly. `test-output/capture-errors.log` and `test-output/vendor-preview-errors-v2.log` are empty. Desktop, 640 x 360 phone, family/reserve, successful snatch and full-body idle/placing comparison captures were visually inspected. Code review confirmed that code draws scenery only, generated bodies remain complete, masks are local, frame resources are cached, counter food has one owner and receipt/cancellation/bonus timing follow the simulation clock.
