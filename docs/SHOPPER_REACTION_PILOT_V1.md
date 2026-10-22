# Original shopper theft-reaction pilot v1

This pilot is intentionally scoped to the original `kiosk_customer` appearance.
Successful direct food thefts, including a serving portion intercepted from the
counter, enter a 0.32-second `surprise` beat before the existing 2.2-second,
120-pixel bounded chase. A failed chase then enters a 0.9-second planted
`give_up` presentation using `fist_shake`; the gameplay swat timers and hit path
are never armed by that clip. Both presentations use the existing escape-facing
flip and return to the existing routine.

The complete generated source and exact built-in image-generator prompt are in
`assets/reference/shopper-reaction-pilot-v1/`. The old production atlas remains
untouched; `tools/prepare_shopper_reaction_pilot.gd` maps the new complete figures
into `assets/sprites/shopper-diner-style-v2.png`.

Review assets:

- `tools/shopper_reaction_pilot_preview.tscn`
- `assets/previews/shopper-reaction-pilot-v1.png`
- `tests/shopper_reaction_pilot_checks.tscn`
