# Animated vendors inside food stalls

Assessment and implementation plan, 20 October 2026. Originally planning only; implementation was subsequently requested with the handover-snatch bonus below.

### Updated direction and implementation — 20 October 2026

**Latest accepted presentation:** use the image generator for distinct, complete full-body vendors at normal adult scale. Mask each full sprite through the stall window so its lower body stays hidden behind the counter. Never generate main-character artwork in code. The vendor places food on the counter, where it stays still for 0.85 seconds with the existing +50% dive-snatch bonus; the buyer then collects it. This supersedes the earlier code-drawn placeholder and direct hand-to-hand approach described in the historical planning notes below.

Implemented assets: `assets/reference/stall-vendors-v2/ice-cream-full-body-source.png` and `hotdog-full-body-source.png`, each with eight complete poses; full runtime atlases and `data/vendor_art.json`; exact built-in generation prompts in `assets/reference/stall-vendors-v2/PROMPTS.json`. `FoodStall` now renders generated sprites inside a clipping window, draws scenery only, and supports a fixed counter serving position. `StallService` uses prepare/place/counter/collect timing. The project art rule is persisted in `AGENTS.md`. Current implementation details and validation are in `../../STALL_VENDORS.md`.

The user requested implementation and explicitly wants a readable, bonus-bearing mid-handover dive snatch. The first playable implementation is complete with pixel-drawn vendor placeholders over the existing stall shell; final character sheets remain a later art pass. Current behavior and reproduction steps are in `../../STALL_VENDORS.md`.

- Prepare for 0.25 s, extend for 0.18 s, then hold the actual serving food beyond the counter edge for **0.85 s**, followed by 0.18 s of retraction. Gold corner glints identify the exposed item. Timings live in `data/tuning.json`.
- A dedicated serving-food target owns the single exposed item until receipt. It uses the existing swept dive/peck collision and ordinary knockdown path. The buyer receives it only if it survives the visible window. No decorative duplicate remains collectible.
- A successful **player dive snatch during OFFER earns +50% of base food points**, additive with the existing Risky/Upwind/Mugged modifiers before the combo multiplier. `score.handover` tunes this. Ground recovery, near-miss knockdowns, later theft after receipt and rival interceptions do not earn the player's handover bonus.
- Capture the flag on the caught snack; award points once on swallowing, consistent with the existing digestion system. Show HANDOVER! at interception and count handover events on results. A full stomach cannot consume the item or award the bonus.
- Stop remaining grants on family interception during BUY as well as RETURN. Preserve actual delivered food, finite stock and delayed retreat/retry.
- Every family order item now has its own exposed window, including reserve restocks. This deliberately lengthens a multi-item order (roughly 4.4 seconds for three items, plus positioning), superseding the original 1–1.5-second family target. Keep purchases free of visible queues.
- The first implementation serves children directly at a lowered outer-edge palm; test its continuity before deciding on final leaning/receiving artwork. Existing initially held snacks, teaching restoration and the separate seafood defender remain intact.

Implementation now uses `FoodStall`, `StallService` and `StallPortion`. This is an intentional refinement of the proposed scene: the independent portion makes reserve handovers stealable without temporarily replacing mum's already-held snack or adding staff to the crowd cap.

First implementation status: both stall types, all three shopper appearances, real service food, bonus scoring/results, replacement visits, family stock/retreat and runtime preview captures are connected. Final sprite sheets, dedicated receiving poses, a broader phone review and additional family-contention playtesting remain production work. The task list below retains those full production requirements rather than claiming the placeholder art is finished.

## Recommendation

Give each ice-cream kiosk and hot-dog stand a stationary vendor inside a layered stall. Show a short idle/preparation/reach/release/retract cycle, with a separate food sprite visibly moving into the buyer's hand. Reuse the existing customer, family, food and theft systems.

Start with one ice-cream stall and one adult customer. Settle the counter opening, hand contact and visual style in a small in-engine pilot before producing full character sheets. Then connect families and repeat shopper visits, and apply the same system to hot dogs. The existing seafood-vendor target is a separate later integration decision.

The difficult parts are fitting a readable person into the current stall opening and synchronizing food ownership, buyer movement and animation. The current project already supplies most surrounding systems. No navigation system, skeletal rig, shop interface, currency system or new global singleton is needed for the proposed first version.

## Assessment baseline before implementation

| Area | Evidence in the current workspace | Consequence |
| --- | --- | --- |
| Stalls | `scripts/beach.gd:setup()` builds kiosk/hot-dog props as single `AnimatedSprite2D` images. `data/sprites.json` maps both to 52 x 56 images; `scripts/stand_sign.gd` adds signage. | There is no vendor actor, opening mask, service point or purchase controller. |
| Visual opening | Inspected `retro-kiosk-32bit.png`, `retro-hotdog-stand-32bit.png` and the saved `retro-game-stands-v1.png` capture. | The serving aperture is small and contains fixtures. A normal adult behind the unchanged flat image will be hidden; one drawn in front will appear outside the stall. |
| Families | `scripts/spawner.gd:_link_families()` chooses the first kiosk's centre x. `scripts/target.gd:_tick_family_trip()` reaches that x, waits `family_purchase_pause` (currently 0.45 s), then calls `_complete_family_purchase()`. | Travel and return already work. Buying is an immediate batch food grant after a timer, without a vendor handover. |
| Family stock | `_complete_family_purchase()` supplies only missing children, preserves existing food, and restores mum to two total crisp bags including the held one. Purchase serials drive retreat after theft during the return. | Preserve those conservation and retreat rules when purchases become several visible steps. |
| Shoppers | `BeachTarget.setup()` starts shoppers carrying food. `BeachTarget.tick()` restores food on a timer for non-family types. `BeachSpawner.tick()` periodically creates already-fed shoppers at stands in levels 4–6. | An idle vendor alone would not make shoppers buy. Explicit empty-handed approach and receipt states are needed. |
| Placement | Generated stalls use `customer_offset = 48`; authored levels use different positions and sides. Level 2 has a 60-pixel offset. Family destinations currently use stall centre instead. | Existing `customer_x` positions are useful departure/patrol positions, not reliable hand-contact points. |
| Art | Adult casts use the approved diner-led finish, typically 128 x 128 source cells at 0.5 scale and approximately 40 logical pixels in height. The three shopper appearances share gameplay but have distinct sheets. | Match that finish and scale, with cropped lower bodies behind counters. New receive poses must cover all three shoppers. |
| Food anchors | `BeachgoerArt`, `MumArt` and `ToddlerArt` align separate food to animated hands. `BeachCollisions.resolve()` reads each target's `food_position()`. | Keep visible food and theft geometry together throughout receipt. |
| Crowd spacing | `BeachSpawner.reset_spacing()/apply_spacing()` adds presentation offsets and z order around simulation updates. | Uncontrolled spacing can pull a receiving hand away from the counter. Service contacts need a stable reserved position and matching food location. |
| Pause/lifecycle | `BeachGame` manually ticks simulation with its scaled step and freezes selected sprites in `set_paused()`. | New presentation must explicitly follow pause, hit freeze, slow motion, intro and results. An independently running animation could otherwise grant food while gameplay is stopped. |
| Seafood vendor | `data/targets.json` defines a food-bearing broom defender with placeholder 16 x 32 art. The generator adds this target to levels 4–6 at the fish-counter station, but does not create a seafood-stall prop. | It is not the missing employee inside the ice-cream/hot-dog stalls. Moving it into a stall would change an existing encounter. |

These findings come from the current files, including local edits, rather than assuming the last committed version is authoritative. The saved stand capture is visual reference, not a new runtime validation.

## Approaches considered

| Approach | Benefit | Limitation |
| --- | --- | --- |
| **Layered stall + reusable vendor + small service controller — recommended** | Convincing depth, explicit purchases and reusable food transfer; bounded changes around existing actors. | Requires stall-layer art, hand anchors and purchase integration. |
| Add an animated head/torso over each existing stall | Fast ambient-life prototype. | Flat image still interferes with arms; buyers still receive food invisibly unless the service work is added. Useful only for the first composition experiment. |
| Convert vendors into general walking/defending `BeachTarget` NPCs | Could support future staff leaving stalls and reacting to theft. | Inherits food respawn, departure, awareness and crowd behavior that stationary staff do not need. Larger risk and scope. |

Use simple explicit service states and sprite clips. A single manually advanced `AnimationPlayer` can synchronize the vendor sprite frame, hand/food anchor tracks and the contact event. `AnimationTree` blending is unnecessary for a stationary sprite vendor. Gameplay state remains in the service controller, separate from visual clip selection.

## Proposed presentation and asset brief

Keep each stand's current ground anchor, outer silhouette, signs and perch surface as the first constraint. Split the artwork into a rear/interior layer and a front counter/frame/awning layer. Clear fixtures from the working opening where necessary. Prototype a modestly enlarged aperture only if a torso, face and moving arm cannot read inside the current geometry; record any approved dimensions and update dependent geometry together.

Draw the vendor torso behind the counter, with the serving forearm and held food able to appear over its edge. This may require a separate serving-arm overlay rather than one undivided body sprite. Control depth locally inside the stall; do not raise the whole counter above all buyers and flying gulls. The buyer must remain visibly outside.

Vendor appearance: a seaside apron and cap, distinct ice-cream/hot-dog colour accents, clean stepped contours and compact shading matching the diner and current shoppers. Use lossless transparency, nearest sampling and no baked-in food. Start from the established adult source scale; do not force a 40-pixel full figure into a 40-pixel visible opening. Only the upper part needs to be seen.

Initial animation budget per shared vendor rig/pose set:

| Clip | Initial drawing budget | Purpose |
| --- | --- | --- |
| Idle | 2–3 | Small blink/head movement, irregular starting phase. |
| Prepare | 3–4 | Reach down/scoop or wrap; activity remains visible above the counter. |
| Present/release | 4–5 | Readable outward arm movement, shared hand-contact moment and release. |
| Retract | 2–3 | Empty hand visibly returns to the stall. |

Approximately 11–15 source drawings are a planning allowance, with held/reused frames where appropriate. Ice cream and hot dogs can share idle/reach structure; preparation and props need their own treatment. No angry/chase/broom animation is required for this first service feature.

Also needed: short empty-hand/receive poses for the original shopper, mullet shopper and sundress shopper; mum's receive pose; and a verified use or extension of her existing handover and the toddler's receiving pose. Define per-frame food/palm anchors. Reuse current food textures, sizes and carried-food clips.

Current adult service time is approximately 1.46 seconds plus positioning, including the 0.85-second exposed offer. Three family items take roughly 4.4 seconds plus positioning. This supersedes the original shorter purchase target to satisfy the requested readable dive-snatch opportunity. Avoid long cooking sequences or added purchase UI.

## Scene composition and responsibilities

```text
BeachGame
├── BeachBackdrop
│   └── FoodStall (Node2D, reusable scenes/food_stall.tscn)
│       ├── RearInterior (Sprite2D)
│       ├── VendorBody (AnimatedSprite2D)
│       ├── CounterFront (Sprite2D)
│       ├── ServingArm (Sprite2D, if the art requires it)
│       ├── PreparedFood (Sprite2D, presentation only before release)
│       ├── AnimationPlayer
│       ├── VendorPalm (Marker2D)
│       ├── BuyerContact (Marker2D)
│       └── Sign (existing sign presentation)
├── Actors
│   └── BeachTarget buyers (existing people and owned food sprites)
└── StallService (Node, local to this game instance)
```

| Owner | Responsibility |
| --- | --- |
| FoodStall | Stall layers, vendor art, local anchors and service pose playback. A vendor is created from a stall prop, not counted toward `max_targets`. |
| StallService | Registry by stable stall ID; active request, recipient/item list, service state and once-only transfer IDs. Advances on the game's simulation step. |
| BeachTarget | Its carried food, existing finite family supplies, reaction/travel states and purchase serial. No duplicate vendor inventory is introduced. |
| BeachSpawner | Actor creation, stand assignment and spacing integration. New purchases start with empty-handed buyers. Existing seeded carriers can represent earlier purchases. |
| BeachGame | Wiring, tick order, pause/restart/reload teardown and existing scoring/theft routes. |

Keep JSON as the project's data convention. Add stable stand IDs, vendor appearance/type, service-side/contact offsets and menu IDs to props or a small `data/stall_art.json`/stall definition manifest. Preserve IDs through generator placement. Keep artwork anchors in source-cell or logical coordinates with an explicit conversion, matching the existing character manifests.

Separate buyer contact from `customer_x`: the former is where hands meet; the latter can remain the post-purchase patrol/departure position. Derive contacts from local anchors, not duplicated global x constants. Families should bind to a real kiosk ID rather than a fallback x=520. Missing/incompatible stalls produce a recoverable failed request without granting food or stranding the buyer.

Proposed local communication (names are illustrative):

| Event/call | Source → consumer | Payload/purpose |
| --- | --- | --- |
| `request_service(...)` call | Shopper/family adapter → StallService | Buyer reference, stall ID, trip serial and intended item/recipient list. |
| `begin_service(...)` call | StallService → FoodStall | Request ID, food ID and contact geometry. |
| `release_reached` signal | FoodStall → StallService | Request ID and item index; controller validates and commits once. |
| `item_received` signal | StallService → buyer/family adapter | Request ID, recipient and food ID; update existing food/supply and provenance. |
| `service_finished` signal | StallService → buyer/family adapter | Resume patrol or return home only after the purchase is resolved. |
| `service_cancelled` signal | StallService → FoodStall and buyer adapter | Clear presentation/reservations on departure, reaction, theft or teardown. |

No new EventBus or saved-game schema is needed. Service requests live for one level attempt only.

## Handover and ownership rules

Data flow: empty buyer approaches the assigned contact → faces vendor and plants feet → vendor prepares → reaches over the counter → food is released into the receiving hand → vendor retracts → buyer carries it away.

1. Before OFFER, any prepared-food image is a stall presentation object, with no pickup shine, score or theft target. It is not an ordinary held snack with temporary immunity.
2. At the first exposed OFFER frame, create one `StallPortion` and remove the decorative presentation copy. The buyer does not yet own it. The service state permits one creation and one receipt for each order item.
3. During the 0.85-second offer, that portion is the single visible and collectible serving item, with its actual position authoritative for `food_position()`. Only a surviving portion becomes buyer-held food or a reserve increment at receipt. Mum's already-held snack remains a separate unchanged item. Reserve servings are held higher so the two items can be distinguished and snatched independently.
4. After exposure, use ordinary theft, knockdown and rival-gull rules immediately. The updated direction adds a readable 0.85-second offer and a player dive-snatch bonus during it. No protected carry window is added. The vendor's decorative food must never be a second collectible.
5. If the recipient already has food or has a dropped item pending, revalidate at release and skip/reconcile that item rather than overwrite it. Interrupted or stolen items must not be granted again when the clip finishes.
6. Before release, cancellation gives no food. After release, cancellation cannot undo a valid receipt or restore an item already stolen. Existing target/drop ownership remains authoritative.

Tick all handover state and presentation through `BeachGame` using its scaled step, before the existing food collision pass. Advance the animation manually once per step; pause and hit freeze advance neither animation nor purchase. Test skipped frames/large steps crossing the contact event, rather than comparing an animation time for exact equality.

Pin active buyers' presentation at the service contact and route passing actors through the existing spacing alternatives. Keep the shown food and collision position aligned after spacing. This needs explicit tests because the present game resolves collisions before applying its final crowd offsets.

## Buyers, families and simultaneous arrivals

**Ordinary shoppers:** add a small approach/receive/leave purchase lifecycle. New automatic stand customers spawn empty-handed just outside the service position, receive the stand's correct food, then move to their existing patrol area. Robbed shoppers finish their reaction/retrieval decision and return to a compatible stand after a retry delay instead of receiving food from `respawn`. Preserve dropped-food retrieval priority so a recovering snack and a purchase cannot both fill the same hand. Do not route the dog owner or pier diner through this change implicitly.

**Initial level food:** retain authored, already-carrying shoppers where the opening route depends on them, especially the first Training Day snack at x=250, far from the kiosk. Treat them as people who purchased before play began. Training's deliberate snack restoration is an explicit teaching exception; preserve it. This feature does not complete the broader conversion of every NPC away from timed replenishment.

**Families:** preserve gathering, all siblings travelling together, filling only missing hands, finite crisp/cookie supplies and retreat/retry behavior. Keep `FamilyTrip.BUY` as the high-level state but let StallService finish the purchase. Replace the batch timer grant with per-item receipt methods; reuse its stock arithmetic without calling the full old batch grant after visible transfers.

Implemented family presentation: the vendor lowers the serving hand outside the booth edge for a child, then exposes each of mum's reserve top-ups separately. Each order item has a defined recipient and once-only grant; existing child snacks are untouched, mum's held bag counts toward her two total crisps, and cookies are not silently refilled. A still-owned dropped crisp bag also counts toward the total so later recovery cannot create a third. Reserve servings remain visually separate from mum's held snack. Child and reserve handovers have been captured in-engine; finished receiving/leaning poses remain artwork follow-up.

The retreat callback now handles both `BUY` and `RETURN`. Interception of a serving item also cancels remaining grants, retains actual delivered stock and leads into the existing retreat/cooldown behavior. Ordinary held-food animation is separate from the serving portion, and a lost purchase is never repeated at the end of the service.

**No queues:** the existing agreed replenishment specification calls for quick purchases without queues. Limit each vendor to one active service, but do not build a visible waiting line. Suppress automatic arrivals while a stand is busy. Give uncommitted existing shoppers a short nearby stroll/retry; prioritize arriving families over unstarted ambient shopper requests. Bound retries and test two families at the same kiosk so neither is permanently starved. Do not teleport a second order into a busy vendor's hands.

**Seafood:** first release covers the two actual stall types. Keep the separate seafood defender's identity and broom encounter. Putting that character inside a fish stall requires a fish-stall asset, customers/menu, service position and an explicit decision about stationary broom reach and food theft; assess that as a follow-on rather than silently replacing it with a decorative employee.

## Ordered implementation plan

- [ ] **1. Build the composition pilot.** Add isolated `tools/stall_vendor_preview.tscn` and a preview script with current stall, temporary vendor upper body, one existing shopper and real separate food. Compare original/split layers, hand contact, both service sides and phone/desktop views. Preserve source art. Deliver an idle/preparation/handover strip plus a short runtime capture. This settles opening size and serving-arm layering before full sheets.
  Skills: `godot-prompter:2d-essentials`, `godot-prompter:assets-pipeline`, `godot-prompter:animation-system`; `imagegen` if new raster artwork is produced.
- [ ] **2. Add reusable stall presentation and configuration.** Create `scenes/food_stall.tscn`, `scripts/food_stall.gd`, vendor art metadata and layer assets. Update `scripts/beach.gd`, `data/sprites.json`, prop definitions in `data/levels/level_01.json`–`level_06.json`, and `scripts/level_generator.gd` as needed. Preserve generated IDs, existing signs, bins, arrival spacing and perch geometry.
  Skills: `godot-prompter:scene-organization`, `godot-prompter:resource-pattern`, `godot-prompter:assets-pipeline`, `godot-prompter:2d-essentials`.
- [ ] **3. Implement one complete adult purchase.** Add `scripts/stall_service.gd` and wire it in `scripts/game.gd`. Add a buyer purchase-state adapter in `scripts/target.gd` or a small owned component. Coordinate receiving poses/anchors through `scripts/shopper_art.gd` and `scripts/beachgoer_art.gd`; account for all shopper appearances. Add simulation-driven contact events, once-only grants, cancellation, busy handling, pause/freeze, teardown and spacing reservation. Prove this with placeholder art first.
  Skills: `godot-prompter:state-machine`, `godot-prompter:component-system`, `godot-prompter:animation-system`, `godot-prompter:gdscript-patterns`.
- [ ] **4. Connect ordinary shopper arrivals and replacement visits.** Change `scripts/spawner.gd` automatic arrivals to empty-handed purchases. Replace timed food reappearance only for participating kiosk shoppers, add compatible-stand selection and retry tuning in `data/tuning.json`, and preserve authored initial carriers and training restoration. Handle missing stands and pending drops explicitly.
  Skills: `godot-prompter:state-machine`, `godot-prompter:scene-organization`, `godot-prompter:gdscript-patterns`.
- [ ] **5. Connect family orders and interrupted purchases.** Replace the `BUY` timer/batch grant with visible receipts and short distribution. Update family destination binding, per-item accounting, purchase serials, remaining-order cancellation, mum/child anchors and theft during purchase. Test two siblings and two families sharing a stand. Preserve existing retry/retreat and finite supplies.
  Skills: `godot-prompter:state-machine`, `godot-prompter:animation-system`, `godot-prompter:component-system`, `godot-prompter:godot-testing`.
- [ ] **6. Complete production artwork and hot-dog variation.** Following the pilot, finish vendor idle/prepare/hand/retract sets, receive poses and stall layers. Use the diner-led rendering treatment and current source-cell pipeline. Save untouched generation references/prompts when used, atlas manifests and reproducible preparation/mapping tools. Add modest randomized idle phase without consuming the gameplay RNG stream.
  Skills: `godot-prompter:assets-pipeline`, `godot-prompter:animation-system`; `imagegen` for generated raster art.
- [ ] **7. Verify and document.** Add focused `tests/stall_service_checks.gd` and preview captures, integrate relevant behavior checks into `tests/integration.gd`, and update affected family/layout/staff tests to assert service contacts instead of old stall-centre timing. Run `tools/validate.ps1` and rendered `tools/validate.ps1 -Capture` after implementation; run the standalone shopper-variant checks when their manifests change. Update replenishment and visual documentation to describe precisely which buyers now use real purchases.
  Skills: `godot-prompter:godot-testing`, `godot-prompter:godot-code-review`, `godot-prompter:assets-pipeline`.

## Acceptance checks

- Each actual kiosk/hot-dog prop has one visible vendor at the correct scale; no duplicate targets or changes to crowd cap.
- Torso is behind the counter, serving hand passes over its edge, buyer stands outside, and food meets the palm without clipping or jumping. Check both sides, three shopper appearances, mum and toddlers.
- Idle, preparation, release and empty-handed retraction are visibly distinct at game size. New stall presentation does not obscure nearby gulls or signs.
- One request grants each item at most once; no food before release, no second decorative collectible, and no replacement after theft. Duplicate events, large steps, refresh and invalid recipients are covered.
- After release, visible food position matches ordinary theft/knockdown/rival targeting. Score/digestion occur through existing routes only.
- Missing child food is supplied; existing sibling food is preserved; mum totals exactly two crisps including the held one; cookies retain the existing finite behavior. A purchase stolen during BUY or RETURN cannot finish by recreating the lost order.
- Busy-stall encounters remain brief, without a queue or simultaneous handovers. Two arriving families eventually progress.
- Pausing, intro, hit freeze, slow motion, results, restart and level changes neither advance stale purchases nor leave orphaned food/arm overlays. No cross-level request or stand references survive teardown.
- Existing training snacks, family handovers, retreat/retry, dropped-food recovery, arrival clearance, generated layouts and roof perching still behave as intended.
- Review level 1/2 kiosk positions, both service sides in level 3, and generated levels 4–6. Check food availability and level pacing before changing score/time targets.

## Delivery size and remaining uncertainty

This is a medium feature spanning art, presentation and purchase behavior, rather than an idle-animation-only task. The first bounded deliverable is one layered kiosk, one vendor and one shopper completing a visible handover. The full feature adds the second stall type, all shopper appearances, family distribution and interruption handling.

The main unresolved visual decision is whether the existing opening can accommodate the desired readable vendor with a small layer edit or needs a larger aperture. Family multi-item presentation is the next risk. Resolve those through the pilot before estimating final art production. No elapsed-time estimate is asserted without that result.

The original assessment inspected scripts/configuration, existing checks, three stall reference images and recent character style documentation. Implementation adds focused service checks and runs the whole-game headless and rendered suites. Actual-runtime preparation, offer, dive interception, child receipt and reserve-restock screenshots are saved under `assets/previews/stall-vendor-*-v1.png`. See `../../STALL_VENDORS.md` for current validation and remaining artwork work.
