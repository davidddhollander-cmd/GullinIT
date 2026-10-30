# Tiny buyer order bubble

## Design

At the end of the approach, when StallService accepts a purchase, show one 16×9 native-pixel cream speech balloon just above the buyer's head, with a tiny tail and three animated dots. Use a mouse-ignoring Control child of the buyer so it follows world movement and spacing. A family order belongs to mum and gets one balloon for the whole order.

Use the service simulation step for its 0.9-second lifetime and dot motion. Pause and hit freeze stop it. Fade it in/out briefly, and remove it immediately if the request is cancelled or the buyer disappears. It finishes before food placement at the current 1.4-second preparation duration. It does not change preparation, food ownership, scoring or counter-snatch timing.

Scene: buyer Node2D → OrderBubble Control (rounded UI frame, tail, three dots). StallService owns the request and the bubble's lifetime; the bubble owns only its drawing and animation clock. No new global signals, input actions or gameplay states are needed.

## Work

- [x] Add the small Control renderer and clock-driven animation.
  Skills: `godot-prompter:godot-ui`, `godot-prompter:animation-system`.
- [x] Start once on accepted service, track the buying character and clean up on expiry/cancellation. Keep family multi-item orders to one bubble.
  Skills: `godot-prompter:component-system`, `godot-prompter:state-machine`.
- [x] Extend focused service checks for size/head clearance, accepted-order visibility, animated dots, pause/freeze, expiry, cancellation and family ownership. Run focused and full integration checks.
  Skills: `godot-prompter:godot-testing`.
- [x] Capture desktop and phone stills and a GIF showing approach/order, preparation and counter food. Inspect actual game rendering and update vendor documentation.
  Skills: `godot-prompter:2d-essentials`, `godot-prompter:assets-pipeline`.

## Result

Implemented in `scripts/order_bubble.gd` and `scripts/stall_service.gd`. The bubble is world-anchored UI; existing generated character art is unchanged. The 1.4-second vendor preparation, 0.85-second stationary counter window and +50% bonus remain unchanged.

Focused service suite: 132 checks, zero failures (`test-output/order-bubble-checks.log`). Full integration: 15,834 checks with one failure, `level 6 rival leaves the scene of a theft`. A separate baseline diagnostic removed only bubble creation from the script resource in memory, without modifying project source on disk: the 90-second level-6 rival simulation produced the exact same counters, scores and four short-escape observations. See `test-output/order-bubble-rival-baseline.log`. This is a pre-existing issue at the current 1.4-second preparation tuning, independent of the bubble UI.

Actual rendered desktop and phone stills were inspected: `assets/archive/previews/order-bubble-desktop.png` and `order-bubble-phone.png`. The animation is `assets/archive/previews/order-bubble-cycle.gif`. Reproduce with `tools/order_bubble_preview.tscn`; its frames go to `test-output/order-bubble-frames/`, assembled at 20 fps using FFmpeg. The render error log is empty.
