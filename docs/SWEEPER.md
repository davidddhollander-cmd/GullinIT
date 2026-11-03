# Sweeper

Beach cleaner in rust-orange dungarees (levels 2 and 5, `"sweeper": {"enabled": true}` in the level JSON). Code: `scripts/sweeper.gd` (behaviour), `scripts/sweeper_visits.gd` (schedule), tuning in `data/tuning.json` -> `sweeper`, art in `data/sweeper_art.json` + `assets/sprites/sweeper-v1/`.

## Behaviour
- **Visits:** first arrival 35 s, stays 28 s, returns after 20-30 s. Called early when MORE than `call_litter` (5, so 6+) loose items lie on the sand and 8 s have passed since he last left.
- **Gull first:** a gull that is low (<= 36 above the sand) and within 80 px (100 px if it is working a bin) gets a 0.5 s warning, a chase, a 0.6 s windup, then one swing. A hit is the ordinary adult stun (-5, snack dropped). Above 30 px, or out of 20 px swing range during windup, nothing hits. After any swing or give-up he ignores gulls for 3 s.
- **Litter:** unowned, grounded food and litter older than 1 s on the sand is brushed toward the closest bin, up to 3 items in a pile at the broom head, and dumped into it (destroyed; `refill_bin` false). Respawning crumbs, counter food, stash and owner-held items are never swept.
- **The pile is contestable:** swept food stays pickable. Taking from it makes him react (`surprise`), then chase if the gull is low.
- Player gull only; rivals are not targeted. Sand only (`range` 24-620).

## Events
`sweeper_arrived`, `sweeper_warned`, `sweeper_swatted`, `sweeper_dumped` (count), `sweeper_pile_stolen`.

Tests: `tests/sweeper_checks.gd`.
