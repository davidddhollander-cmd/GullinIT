# Food replacement, families and stash raids

Agreed with the user on 4 October 2026. This remains the full target specification.

Latest vendor refinement, 20 October: both stalls now use proper image-generated full-body characters, masked behind the booth so only their upper bodies appear. Vendors place food on the counter rather than directly into a person's hand. The same 0.85-second bonus window applies while the food rests on the counter, then the buyer collects it. Full-body source sheets, runtime atlases and exact prompts are preserved. Code-generated main-character art is prohibited in `AGENTS.md`. This replaces the earlier hand-to-hand vendor presentation below; ordinary mum-to-child supply handovers retain their existing behavior.

20 October update: animated vendors and visible item-by-item service now supply kiosk shoppers and families. The user explicitly requested a readable mid-handover dive-snatch window with bonus points, superseding the earlier statement that handovers have no special opportunity. Food is exposed for 0.85 seconds and a player dive snatch earns an additive +50% base-food modifier on swallowing. Family buying may take several seconds so each item can be intercepted. Theft during BUY cancels the remaining order and triggers retreat, as does theft of a newly purchased carried item during RETURN. Stall-side shoppers begin with a visible purchase and robbed kiosk shoppers revisit a stand instead of regenerating food on a timer. Initial distant carriers and training restoration are retained. Other NPC supply conversion remains separate. See `STALL_VENDORS.md` for the implemented behavior and prototype artwork status.

## Implementation status: family stand trips and stash raids complete

The family portion of steps 1 and 2 is implemented. Mums and sunbathers have visible finite supplies; automatic respawn and permanent theft departure are disabled for mums, toddlers and sunbathers; every toddler has an explicit mum ID; distant children approach her; siblings share one conserved supply; and a short visible handover transfers a normal stealable snack. Each mum has two crisp bags total (the initially held bag is one of the two) plus a separate reserve of two cookies. When backup is empty, or a seeded 22% insistence roll asks for ice cream, the mum gathers every linked child and takes them to the actual kiosk prop. Missing children receive visible food at the stand and mum tops up to two crisps inclusive of her held bag. Existing child food is preserved.

The return purchase is carried by the existing targets, so every item remains reachable through the ordinary swept food collision. A stolen newly purchased item changes the trip into a temporary within-level retreat. Mum offers whatever finite crisp or cookie backup remains and waits eight seconds before a possible retry. Purchase tags clear on a successful return; stealing pre-existing food does not falsely abort the purchase. Trip speed, gathering, purchase, retreat, retry delay and insistence chance are editable in `data/tuning.json` and use the level-seeded family RNG.

Stash raids are implemented: grounded E/controller X/touch PECK taps release random finite snacks after three pecks. Food can be caught in the air or picked up on the ground. Sunbathers react faster with existing caution, stand up, swat nearby gulls, retrieve their own dropped snacks and return to the stationary bag. Retrieved items restore stash stock; player pickups score once and remove that supply. These first-pass timings and counts are editable.

Sunbathers and their picnic bags are confined to the sandy beach section (x 24–300), and their scatter/retrieval stays before the promenade. Once awake they retrieve at 40 pixels per second. Beach bins are also finite peckable sources: four taps scatter three objects from a nine-object supply, weighted toward 2-point crumbs with wrappers and paper mixed in. Bin crumbs use the ambient scrap score path, while rubbish is visible but cannot score. All scattered edible items keep the 0.3-second pickup grace.

This status does not mark the full specification complete. Non-family stand trips, broader NPC supply conversion, expanded shielding/quicker-swat caution behavior, and fast rear shield breakthrough remain future work. Existing unrelated NPCs retain their previous timed replenishment for now. Ground scraps are unchanged.

## Main rule

Food must come from a visible source: a person's supplies, a handover or a purchase. Remove timed food reappearance for all beachgoers. Empty supplies can be replenished by visiting a food stand. People carry purchased food back, where it remains stealable.

## Families

- Each toddler belongs to a specific mum. Start with one or two toddlers per mum. They may be physically separated on the beach.
- After theft, the toddler goes to mum crying.
- Mum carries two bags of crisps shared by her children, plus a small separate cookie reserve for when the crisp bags are gone.
- A toddler usually accepts carried snacks but sometimes insists on ice cream.
- When a purchase is needed, mum takes all her toddlers to the stand and buys for those currently missing food. She replenishes her crisp supply there too.
- Purchases happen quickly, without queues. The trip, purchase, carried food and handover should be visible.
- Food can be stolen while mum carries it back or hands it over. Handover has no special vulnerability or easy-steal window.
- If newly purchased food is stolen, mum gives up on that purchase attempt, leads the toddlers away and offers backup crisps or cookies. She may return to the stand after some time away; she must not immediately repeat the purchase endlessly.
- Repeated theft makes the family more cautious. They do not permanently leave the beach because of theft. Moving away after a failed purchase is a temporary retreat within the level.
- Stronger caution means more shielding and quicker swats. Reuse the existing caution decay so it fades when the gull leaves them alone.

## Shields and fast dives

- A sufficiently fast dive can get through a shield only when approaching from behind the defender.
- The required speed should be achievable by building momentum from a reasonable height.
- Give the player a clear visual cue when the dive is fast enough. Speed alone does not remove the need for a rear approach.
- Define behind using the defender's facing direction. Tune the angle and speed threshold during playtesting.

## Stash bags and pecking

Refinement agreed 5 October: sunbathers have no exposed held snack. All food stays in a larger picnic/duffle bag beside their feet or head until the gull pecks it. The implementation places it beside the feet and removes automatic snack extraction.

- Sunbathers have visible stash bags containing chips and other snacks. Other beachgoers also use appropriate visible supplies or purchases.
- The gull must land beside a stash to raid it.
- Add a separate peck action. Each button tap performs one peck; holding the button does not repeat it automatically.
- After a few pecks, random snacks begin flying out in different directions.
- The gull can catch these snacks in the air or collect them after they land.
- Pecking increases the owner's caution. An owner who catches the gull can swat it.
- Sunbathers initially react slowly, but become quicker after repeated disturbance. Existing caution decay still applies.
- An alerted sunbather stands up and retrieves scattered snacks from the ground. This creates the collection time limit through the owner's actions.
- Updated 6 October 2026: picnic-bag refill trips are cancelled. Empty bags stay empty; owners may still recover their own scattered snacks.

## Details to tune during implementation

These are not fixed by the interview:

- Keyboard, controller and touch bindings for pecking.
- Pecks before snacks emerge, peck recovery time, snack count and scatter distance.
- Stash capacities, cookie-reserve size and snack selection probabilities.
- How often toddlers insist on ice cream.
- Purchase duration, retreat distance and delay before a family retries the stand.
- Shield-breaking speed, rear-approach angle and the exact visual cue.
- Owner reaction and ground-snack retrieval speed at different caution levels.

Choose initial values in editable settings and verify them through play. Do not add an invisible snack-disappearance timer as a substitute for the agreed owner retrieval behavior. The origin of existing ambient ground crumbs, and detailed supply behavior for each non-family target, still need implementation decisions consistent with visible food sources.

## Suggested build order

1. Add food ownership and finite supplies, including cookies, and visible stand purchases. Remove automatic held-food respawn and theft-driven permanent departures.
2. Connect mums and toddlers, including siblings, seeking mum, snack handovers, family shopping and retreat after a stolen purchase.
3. Add stash interaction, tap-to-peck controls, scattered food, airborne/ground collection and owner retrieval.
4. Connect increased caution, shielding, quicker swats and fast rear-dive breakthrough with its visual cue.
5. Test the full loop with placeholder poses before creating the additional carrying, buying, handing-over, pecking, standing and collecting artwork.

## Checks before calling it complete

- Every replacement snack has a supply or purchase source; supplies do not duplicate during transfers.
- A distant toddler finds the correct mum, and siblings share supplies correctly.
- Mum brings all siblings shopping and supplies only those missing food.
- A stolen purchase causes retreat and fallback food, followed by a delayed possible retry.
- Repeated theft increases caution without permanently removing families from the level; caution later fades.
- Only fast rear approaches break shields. Slow or frontal approaches retain the defenses.
- Pecking requires a nearby grounded gull and separate taps; it raises owner caution.
- Scattered food can be caught or picked up exactly once, by the gull or the retrieving owner.
- Sunbather retrieval creates a visible race for snacks. Depleted bags are not restocked through purchases (user scope change, 6 October 2026).
- Score, practice progress, retry and level completion still work without stale family or food actions.
