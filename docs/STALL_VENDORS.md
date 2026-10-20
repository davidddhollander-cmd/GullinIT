# Generated full-body stall vendors and counter snatches

Updated 20 October 2026. Both vendors are proper full-body characters created with the built-in image generator. Each has eight drawn poses, including idle, blink, preparation, placing food and withdrawal. The ice-cream worker has a teal uniform, brown bob and cream paper cap; the hot-dog worker has a red uniform/cap and copper ponytail. The approved diner and current cast supplied the style reference.

## Full-body artwork, upper-body display

The original complete cap-to-shoe sheets are preserved in `assets/reference/stall-vendors-v2/`. Exact generation prompts and tool provenance are in `PROMPTS.json` in that folder. Runtime atlases retain each entire figure on 128 x 128 canvases, about 80 source pixels tall, displayed at 0.5 scale: the same approximately 40-pixel adult height as the existing cast. Shoes share source baseline 116; alignment uses the shoes rather than the changing arm silhouette.

`scripts/food_stall.gd` places the full `AnimatedSprite2D` inside a local `Control` serving-window mask. The mask shows the head/upper torso and hides legs and lower apron behind the booth front. No lower-body artwork is deleted. Masking applies after mirroring too. The source figures remain usable outside the stalls later. Stall signs are raised enough to keep the generated faces/caps readable.

All code-drawn vendor faces, bodies and arms have been removed. Code draws only booth scenery and the counter shelf. The user's rule against code-generated main-character art is recorded in the project `AGENTS.md`.

The complete booth shell, masked vendor, shelf and sign share draw depth 2. Rear-lane walkers draw behind all of them; ground-lane customers remain in front. Flying gulls, exposed/loose food and effects retain foreground visibility. `tools/stall_depth_preview.tscn` reproduces both stands with crossing lanes and compares rendered serving-window pixels against a frame with rear walkers hidden.

## Counter service

The vendor prepares a snack, makes the generated placing gesture, and sets the separate food sprite onto the shelf. It stays **stationary on the counter for 0.85 seconds**, with its bottom exactly on the shelf surface. The extended counter keeps it beyond the roof footprint and reachable by an approaching dive. Gold corners mark the opportunity. The vendor withdraws while the snack remains on the counter; the buyer collects it afterward, with a short movement into the normal carried-food hand position.

A successful timed dive PECK during the counter window displays **COUNTER +50%!**. That bonus adds 50% of base food points alongside Risky/Upwind/Mugged modifiers, before the combo multiplier, and scores once when the caught food is swallowed. A 25-point ice cream earns 38 with only this bonus after rounding. Results count COUNTER events. Internally the existing `handover` snack flag/score key is retained for compatibility.

A full stomach, dive without an active peck, near-miss knockdown, ground recovery, rival interception or theft after the buyer collects does not earn the player's counter bonus. There is one real serving item; if stolen or knocked away, the buyer cannot receive a replacement when the animation finishes.

Stall-side shoppers begin by purchasing. Robbed kiosk shoppers finish their reaction and any dropped-food recovery before revisiting a compatible stand. Distant initial carriers, including Training Day's first snack, and deliberate teaching restoration are retained. Other NPC categories keep their existing supply behavior.

Families buy only missing child snacks and restore mum to two crisp bags inclusive of her held bag and any still-owned dropped bag. Cookies remain finite. Every item, including reserve stock, has its own counter window. Mum keeps an already-held snack on the side away from the counter during a reserve purchase, leaving both items visibly separate. Counter theft cancels the rest of that order and triggers retreat/retry during BUY as well as RETURN. One stand serves one order at a time, without queue UI.

## Assets and reproduction

- Full generated sources and prompts: `assets/reference/stall-vendors-v2/`.
- Runtime sheets: `assets/sprites/vendor-ice-cream-full-body-v2.png` and `vendor-hotdog-full-body-v2.png`.
- Metadata and cached frames: `data/vendor_art.json`, `scripts/vendor_art.gd`.
- Atlas import preparation: run Godot headlessly with `--script tools/prepare_stall_vendors.gd`, then reimport. This script only crops, aligns and scales the generated artwork; it never draws characters.
- Runtime service: `scripts/stall_service.gd` coordinates prepare/place/counter/collect and once-only inventory changes; `scripts/stall_portion.gd` supplies normal swept theft/knockdown targeting.
- Preview: `tools/stall_vendor_preview.tscn` saves desktop, phone, successful theft, family/reserve and complete unmasked character views as `assets/previews/stall-vendor-*-v2.png`. The older v1 images are historical placeholders.

The vendors remain independent of the crowd target cap. The serving food uses the existing player/rival targeting and score/digestion routes. All phases are manually advanced by the game's scaled simulation step, so pause, hit freeze, intros and results freeze presentation and receipt together.

## Tuning

Values are in `data/tuning.json`:

| Key | Value |
| --- | --- |
| `score.handover` | 0.5 additive counter-snatch modifier |
| `world.stall_prepare_time` | 0.25 s |
| `world.stall_extend_time` | 0.18 s placing motion |
| `world.stall_handover_time` | 0.85 s stationary counter window |
| `world.stall_retract_time` | 0.18 s collection/recovery |
| `world.stall_retry_wait` | 4 s interrupted-service retry |

Three family items take roughly 4.4 seconds plus positioning. Review that pacing before changing level time or score targets. The separate seafood broom defender is outside this two-stall art update.

## Validation

The focused service suite includes generated-source preservation, distinct character assets, full-body frame bounds and shoe anchors, hard alpha, eight distinct poses, adult scale, window clipping/mirroring, stationary counter food and exact shelf contact. It also covers real dive/peck bonus scoring, all shopper appearances, family stock/retreat, knocked food, full stomach, busy stands, pause/freeze/results and large simulation steps. Run `tests/stall_service_checks.tscn` or the full `tools/validate.ps1 -Capture` workflow. Desktop and phone captures plus the unmasked full-body review are inspected visually.

Final v2 validation: **11,938 rendered integration checks, zero failures**, including **94 focused vendor/counter checks**. The focused standalone run also passes cleanly. `test-output/capture-errors.log` and `test-output/vendor-preview-errors-v2.log` are empty. Desktop, 640 x 360 phone, family/reserve, successful snatch and full-body idle/placing comparison captures were visually inspected. Code review confirmed that code draws scenery only, generated bodies remain complete, masks are local, frame resources are cached, counter food has one owner and receipt/cancellation/bonus timing follow the simulation clock.
