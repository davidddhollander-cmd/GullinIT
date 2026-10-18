# Next steps

Updated: 14 October 2026

14 October 2026 visual pilot: the pier diner now uses chunky retro pixel-art sheets with walk, run, eating, escalating awareness, windup, swat and recovery cycles. See `PIER_DINER_RETRO_PILOT.md` and the `retro-diner-*.png` captures. Review this character at game size as the proposed style benchmark before extending it to the remaining cast.

Perching is now implemented using point-down landing on stand tops, the lifeguard roof and lamp top. Rendered validation: **13,219 checks, zero failures**. Next playtest should check how easily narrow perches can be selected and whether resting above food sources improves the digestion pace. The older proposal-only status below is superseded.

Latest adjustment: quieter levels now have two toddlers (one per mum) and two sunbathers, with more family spacing. Rendered validation: **13,186 checks, zero failures**. Roof/pole landing is specified in `PERCHING_PROPOSAL.md` as a proposal for the next mechanic, not yet implemented.

Level generator completed: separated sunbather, family, promenade and pier sections; spaced food sources; repeatable variety; and arrival reservations that prevent crowding. See `LEVEL_GENERATOR.md`. Rendered validation: **16,436 checks, zero failures**, including 120 generated layouts. Immediate next step: play all six routes to assess food availability, travel time and score targets, then continue the remaining character art. Historical progress entries below describe earlier passes.

Food/reaction spec implemented: smaller portions, four-space ordered eating/digestion, grounded speed boost, points on swallowing, current-snack drops and five-point swat penalties. Toddlers run with tears; adult warnings lead to short bounded chases and return, with slower sunbathers. Rendered and final headless validation: **1,231 checks, zero failures**. Playtest the new eating pace and chase ranges before changing level timers/targets. Remaining art batch: pier diners, lifeguard and seafood vendor.

First remaining-character batch completed: polished kiosk customer and dog owner with small terrier, walking and reaction poses, and mirrored separate food. Rendered validation: **1,166 checks, zero failures**. See `BEACHGOER_ART.md`. Continue with pier diners, lifeguard and seafood vendor; dedicated stand vendors are still a separate future task.

Longer beach completed: sand doubled to 640, total map 1280, two distinct food stands and supplied scenery across all six levels. Both stands have corresponding stealable customer food. Validation: **1,113 checks, zero failures**. See `BEACH_MAP.md`. Next playtest should check travel time and scenery visibility on this longer route before adjusting timers or score targets.

Mum art pass completed: new 16-pose sheet connected to walking, carrying, handover, shielding and swatting. Food stays separate and stealable. Rendered validation: **981 checks, zero failures**. See `MUM_ART.md`. Older progress entries below record previous passes.

Reaction pass completed: sunbathers bend to retrieve, warn before swatting and settle at home; robbed toddlers cry before accelerating toward mum. Existing sheets supply these poses. Latest validation: **935 checks, zero failures**. The next art task is the mum's walking, carrying and handover poses. Older progress entries below record previous passes.

Latest art pass: female sunbathers added in red/blue alongside the male set; adults enlarged 10%, toddlers reduced 30% with matching hand-food anchors. Crisp window-resolution rendering retained. Latest rendered validation: **889 checks, zero failures**. See `SUNBATHER_ART.md` for current scales and captures; older counts below describe previous passes.

Current position: family kiosk trips are implemented on top of the finite-supply foundation. Mums gather all linked children, shop at the visible stand, carry ordinary stealable purchases home, and retreat with a delayed retry if a new purchase is stolen. The polished gull, food and toddler art remain in the game. Mums share two total crisp bags and a finite two-cookie reserve; sunbathers have a visible finite three-item stash.

Toddler rendering pass completed 6 October: game now draws at the window resolution with unchanged logical sizes, and toddlers use smooth mipmapped filtering. Before/after captures show clearer features. Latest rendered validation: **844 checks, zero failures**. Evaluate the new appearance in play before further sprite replacement.

Latest rendered validation: **838 checks, zero failures**. Sunbathers keep every snack inside a larger picnic bag, stay on sand, and retrieve scattered food faster after waking. Beach bins can be pecked for finite bursts of low-value crumbs and inert litter. Ejected food has 0.3-second pickup protection. Family trips, gentle landing, the NEXT LEVEL progress bar, and bag/bin scattering have been captured and visually inspected.

1. **Finish sunbather action poses.** The user's selected two-colour JPEG sheet is now integrated for resting, getting up and running, with stationary towels during pursuit. Dedicated swatting and picking-up poses remain to be added. See `SUNBATHER_ART.md`. Latest rendered validation: **842 checks, zero failures**.
2. **Defer remaining mechanics until after this animation pass.** Picnic-bag refilling is cancelled at the user's request; empty bags stay empty unless their owner retrieves scattered snacks. Other beachgoer replenishment and fast rear shield breakthrough remain separate future work.
3. **Finish the family characters.** Create parents with relaxed, alert, carrying, handing-over, food-protecting and swatting poses. Check toddler reactions and family shopping together.
4. **Work through the remaining beachgoers.** Create sheets for the dog and owner, kiosk customers, pier diners, lifeguard and seafood vendor. Finish with distinct rival gulls.
5. **Check each sheet before moving on.** Match the seaside colours and character sizes. Align feet, check both directions and every reaction, and inspect the art at actual game size. Save each sheet, its animation mapping and generation notes.
6. **Play all six levels.** Check food visibility, walking theft, dive control, crashes, difficulty and score targets. Try the results tally and reactions after poor, good and practice runs.
7. **Prepare playable builds.** Install the matching Godot export templates, build Windows and Web versions, and test them directly. Check controller and touch controls on real devices when available.

Immediate next task: finish sunbather towel-edge cleanup and review dedicated action poses, then work through the remaining beachgoer sheets. Mum walking, carrying and handover are now implemented. Do not implement picnic-bag refill trips.
