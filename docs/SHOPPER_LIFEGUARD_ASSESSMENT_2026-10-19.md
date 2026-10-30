# Shopper and lifeguard assessment — 19 October 2026

Implemented following user approval. Both characters are now integrated; see `SHOPPER_LIFEGUARD_PRODUCTION_V1.md` for the final source reuse, new artwork and validation. The assessment below records the previous state.

Reviewed current runtime sheets, older placeholder files, both unused lifeguard review sheets, the previous cast lineups, sprite mappings and pose-selection code. This assessment changes no production art or gameplay. `assets/archive/previews/shopper-lifeguard-assessment-v1.png` renders current actors at their actual runtime scales beside the older lifeguard artwork prepared at adult size for comparison.

## Shopper

- Active source: `assets/archive/sprites/customer-polished.png`. Dark curly hair, mustard overshirt, cream T-shirt, navy shorts, sandals. Keep this identity.
- Older source: `assets/archive/sprites/kiosk_customer.png`, a tiny geometric placeholder. It provides no usable matching character artwork. The older cast lineups reuse the painted customer rather than offering an alternate pixel design. No other named shopper source was found in the project image inventory.
- The active source has eight poses: four walk images, one idle, one suspicious and two theft/upset expressions. The walk repeats broadly similar extended-leg strides and lacks clear passing poses. Its realistic proportions, fine hair/face modelling and smooth shading differ from the diner and updated adult cast. The runtime uses linear mipmap filtering and a cutout shader.
- The mapped walk bottoms vary by about 2.3 logical pixels; two mappings extend below the nominal 500-pixel frame canvas. This should be corrected when replacing the sheet, independently of the style change.
- `BeachgoerArt` has no dedicated chase, swat windup or contact artwork. Moving chases use walking art, while warning/follow/swat windup use the angry reaction. A redraw should cover existing actions visibly rather than only replacing the idle.

Required work: create matching source art for idle/blink, a complete six-pose walk, a distinct six-pose chase, alert/warning, swat anticipation/contact/recovery and empty-hand theft reaction. Return travel can reuse walking. Keep separate snacks, frame-specific palm anchors and left/right mirroring. Match the adult setup: about 40 logical pixels tall, 80-pixel standing figure in padded 128-pixel source cells at half scale, hard alpha and nearest filtering. First check a neutral, walk and reaction sample beside the diner/mum before extending the sheet.

## Lifeguard

- Active source: `assets/archive/sprites/lifeguard.png`, six 16 × 32 placeholder frames. It is materially smaller and simpler than the approximately 40-pixel adult cast.
- Existing unused source: `assets/archive/previews/lifeguard-pixel-review-v1.png`, 12 poses including idle/blink, lookout, patrol, whistle and pointing. This is already close to the approved diner's outline, shading and expressive proportions.
- Existing unused source: `assets/archive/previews/lifeguard-motion-review-v1.png`, eight poses with clearer walking contact/passing, ready, whistle preparation, whistle/wave and pointing. Prefer this sheet for locomotion and whistle sequences; use the first sheet for complementary idle/lookout/reaction poses.
- Keep the established blond hair, red cap/vest, navy shorts, yellow whistle and red/white shoes. No new base design is necessary. The detached yellow whistle symbols should become separate effects or be excluded when isolating actors.
- Integration is missing: the whistle event currently changes awareness and shows a message, but no character code explicitly plays the registered whistle clip. Generic pose fallback continues selecting walk. A clean redraw alone would not resolve this.
- The shared adult reaction code can make the lifeguard pursue and hit the gull. Neither review sheet supplies a dedicated chase or swat cycle. If preserving that behaviour, those are the likely supplemental generation needs after fitting the existing artwork. Changing the guard to a whistle-only role would be a separate gameplay decision.

Required work: reuse and clean the existing sheets; fit to the adult height/detail scale; isolate each complete figure with transparent gutters; map idle, patrol, lookout/alert, whistle preparation, whistle and pointing/recovery; connect those states to their actual timers/events and face direction. Then assess the remaining chase/swat gaps against the existing gameplay. Whistle-only integration does not require another full generation batch.

## Recommended order

1. Fit and integrate the older lifeguard sheets; this resolves the placeholder and the missing whistle presentation with mostly existing art.
2. Produce the shopper style pilot while preserving its current identity, then generate its missing matching animation coverage.
3. Generate only lifeguard action gaps that remain necessary for the existing pursuit/hit behaviour.

Verify both beside the diner, mum and updated toddler at actual game size. Check every frame for neighbouring fragments, complete limbs, stable head/body scale, foot baseline and correct facing. For the shopper, verify food follows the visible hand and remains stealable in all relevant poses. For the guard, verify the whistle pose and event coincide and that warning/attack artwork matches actual hit timing. No new character identity decisions are necessary to begin this work.
