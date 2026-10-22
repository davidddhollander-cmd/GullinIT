# Pier diner theft-reaction pilot v1

The pier diner now shares the approved reaction flow used by the original
yellow-shirt shopper:

1. A successful direct food theft enters a 0.32 second empty-hand surprise.
2. The existing run animation, pursuit duration and distance bound are reused.
3. A failed chase plants both feet for a harmless 0.9 second two-beat fist
   shake facing the gull's escape direction.
4. The existing routine resumes when the reaction completes.

Warnings, failed theft attempts, loose-food pickups and swats do not enter these
new clips. Pause freezes both the state timer and manually selected reaction
frame. The new behaviour is scoped to `pier_diner`; no other cast art or state
selection is changed by this follow-up.

Generated sources and all prompts are preserved in
`assets/reference/diner-reaction-pilot-v1/`. The runtime-only aligned atlas is
`assets/sprites/pier-diner-reactions-v1.png`. Existing diner pose and motion
atlases remain unchanged.

Focused validation scene: `tests/diner_reaction_pilot_checks.tscn`.  
Review image: `assets/previews/diner-reaction-pilot-v1.png`.
