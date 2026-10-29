# Generation prompts

All three prompts used the existing retro pier render, stand render, and two
runtime stand sprites as visual references. Built-in image generation was used.

## Fence

Transparent runtime sprite source for a 2D Godot pixel-art seaside game: one
modular British pier safety fence with four short dark navy-painted metal posts
and two gently sagging wire ropes. Orthographic side view, long and low, aligned
to one baseline. Authentic hand-placed 32-bit-era pixel art, crisp square pixels,
deep navy outline, limited game palette. No floor, shadow, glow, antialiasing,
gradients, text, people, mesh, or scenery.

## Restaurant

Transparent runtime sprite source for a 2D Godot pixel-art seaside game: one
compact British seaside restaurant kiosk with two clearly separate serving
windows and two readable food-handover counter bays. Shallow coral-and-cream
awning, teal paneled frontage, wood trim, blank roof sign, empty interior.
Orthographic front view, crisp square pixels, deep navy outline, limited game
palette. No floor, shadow, glow, gradients, text, logos, characters, or food
baked onto the counters.

## Table and chairs

Transparent runtime prop sprite source for a 2D Godot pixel-art seaside game:
one small square wood cafe table with a readable top plane and two matching
simple slatted chairs with muted teal seats. Orthographic game view, compact
group on one baseline, crisp square pixels, deep navy outline, limited game
palette. No umbrella, people, floor, shadow, glow, antialiasing, gradients, text,
or scenery.

## Table and chairs v2

Transparent PNG sprite source for a 2D Godot pixel-art seaside game. Create exactly one isolated compact group: a small square wooden cafe table and two simple chairs, viewed in a clean orthographic three-quarter game view and standing on one baseline. No umbrella, no people, no floor, no cast shadow, no text, no scenery. The two chairs have muted teal solid seat blocks and simple solid backs, with no thin individual slats. Each chair must read as separate back, seat, and two chunky legs. The table must read as a square top plane with a thick central post or four thick legs. Use the warm wood, teal, cream and dark navy palette of a cheerful British seaside pier game. Bottom-centre origin. Design for a 60 by 34 logical-pixel runtime sprite, presented enlarged on a clean logical grid so each intended pixel is an 8 by 8 square block. Keep clear transparent padding around the complete prop and preserve the whole object.

> True low-resolution pixel art, designed on a pixel grid of about 60 by 34 pixels and shown with each pixel as a large, perfectly square block. Every pixel block is a single flat colour: no dithering, no noise, no film grain, no texture, no gradients, no anti-aliasing, no soft or blurry edges, no sub-pixel detail. Shapes are bold and simplified with straight edges. One clean, continuous outline exactly one pixel thick in a dark navy, with no broken or doubled outline pixels. Use at most 12 flat colours. Large flat colour areas with simple two-step shading: one light, one base, one shadow. Shapes and fills are at least 2 pixels wide; only the outline and occasional single highlight pixels may be 1 pixel.

## Pier wire fence v2

Transparent PNG sprite source for a 2D Godot pixel-art seaside game. Create exactly one isolated modular British pier safety fence tile, viewed as a straight orthographic side elevation and aligned to one baseline. Target runtime tile: exactly 72 by 24 logical pixels, presented enlarged on a clean logical grid so each intended pixel is an 8 by 8 square block. Four chunky dark navy-painted posts with clear flat caps and bases. Two thick, clearly readable wire ropes, 2 logical pixels thick where they carry the read, with simple stepped shallow sags rather than thin diagonal lines or dotted fragments. The left and right tile edges must be designed to repeat seamlessly when identical copies are placed side by side: matching wire heights and endpoints at both edges. No people, no floor, no cast shadow, no text, no scenery. Use the existing cheerful British seaside pier palette: dark navy, muted teal-blue, cream and restrained warm metal highlights. Keep clear transparent padding above and below while the repeating wires meet both horizontal tile edges correctly.

> True low-resolution pixel art, designed on a pixel grid of about 60 by 34 pixels and shown with each pixel as a large, perfectly square block. Every pixel block is a single flat colour: no dithering, no noise, no film grain, no texture, no gradients, no anti-aliasing, no soft or blurry edges, no sub-pixel detail. Shapes are bold and simplified with straight edges. One clean, continuous outline exactly one pixel thick in a dark navy, with no broken or doubled outline pixels. Use at most 12 flat colours. Large flat colour areas with simple two-step shading: one light, one base, one shadow. Shapes and fills are at least 2 pixels wide; only the outline and occasional single highlight pixels may be 1 pixel.
