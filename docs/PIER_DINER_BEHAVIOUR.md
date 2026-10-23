# Pier diner: visible replacement meals

Implemented 22 October 2026 following the character-behaviour review.

## Routine

The diner keeps its existing initial fish, dining/eating poses, local strolls, umbrella defense and theft reactions. Its spawn/dining location is a fixed home; purchasing a replacement never relocates that home to a food stand.

After losing its meal, the diner finishes its warning/chase/give-up or dropped-food recovery first. Once the existing replacement cooldown expires, it walks to the nearest existing **hotdog grill**, which now also supplies cooked fish. A missing grill or service connection leaves the diner empty-handed and retries after the existing four-second stall retry delay. There is no fallback that silently regenerates fish.

The diner uses the same visible preparation and serving path as shoppers: order bubble, cook turns/works/returns, placement, **0.85 seconds stationary on the counter**, then collection. One grill serves one order at a time; a diner waits if another customer is being served. The existing generated full-body cook remains masked behind the booth. No new character artwork or map structures are introduced.

Once the single fish transfers from counter to diner, the diner carries it back to its original dining home and takes a 6–12-second dining stop before resuming normal strolls. Meal trips use `world.diner_trip_speed = 18` logical units/second, with walking playback matched to the faster cadence. Ordinary local strolling keeps its existing speed and range.

## Interruptions and ownership

- A stolen counter portion cancels receipt, releases the stand, and triggers the diner's established surprise/committed chase. The diner never receives a second copy of the stolen fish.
- Direct dive theft during the counter window retains the existing +50% base-food bonus on swallowing: an otherwise unmodified fish scores 83 points. Ordinary held-fish theft retains its existing 55-point base value.
- A full stomach rejects a catch without consuming the portion; the diner can still collect it normally.
- Knocked fish belongs to the existing loose-food/recovery flow. An outstanding dropped meal blocks replacement orders. Recovering it sends the diner home with that same fish; stealing it clears ownership and triggers the normal theft/replacement path.
- Reactions interrupt meal travel and returning resumes towards the original home. Theft of a carried replacement resets the meal trip rather than walking home empty-handed or granting another fish.
- Pause, hit freeze, intro/results and scaled gameplay time use the existing simulation clock. No independent timers or background processing are added.

## Structure

`BeachTarget.DinerMeal` tracks DINING / SEEK / RETURN and `diner_home` records the fixed anchor. `purchase_stall_type()` is shared by walking and ordering, so fish cannot be routed to the ice-cream kiosk by one path and the grill by another. `StallService` owns preparation/portion/delivery/cancellation; `BeachRoutine.dining_returned()` restores a proper dining pause without changing the anchor. Existing catch, digestion, score and generated-art presentation remain authoritative.

## Verification

- `tests/pier_diner_meal_checks.tscn`: 32 checks, zero failures. Includes visible travel, real portions, stable counter window, receipt/home return, busy/missing source, missing service, counter dive bonus, full stomach, knocked-food conservation/recovery, carried theft and interrupted return.
- Existing stall service: 132 checks, zero failures; character routines: 48 checks, zero failures; diner reaction pilot: 65 checks, zero failures.
- `tools/pier_diner_meal_preview.tscn` captures travel, preparation, counter, carrying home, dining and counter theft at desktop and phone sizes. The real return reaches its original home, and the separate actual dive-theft scenario scores 83 once. Counter/preparation desktop and carrying-home phone frames were visually inspected; render errors are empty.
- Logs: `test-output/pier-diner-meal-checks.log`, `pier-diner-stall-checks.log`, `pier-diner-routine-checks.log`, `pier-diner-reaction-checks.log` and `pier-diner-meal-render.log`.
- Final full integration: **15,988 checks, one failure**, the previously documented `level 6 rival leaves the scene of a theft` check; the existing out-of-tree UI focus error also remains. No new failures. Log: `test-output/pier-diner-meal-final-integration.log`.
