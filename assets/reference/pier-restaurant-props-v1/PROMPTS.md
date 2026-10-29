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

## Beach Hole v2

Three built-in image-generator passes were used. The first established the 1970s tropical architecture; passes two and three enlarged the blank sign while preserving the generated building. All three untouched outputs are saved beside this file.

### Attempt 1 — generation

One isolated, full-building pixel-art sprite for a 2D Godot seaside game: a low, wide 1970s modern tropical beach restaurant. Use a low gently angled roof with a deep overhang, chunky geometric stepped forms, timber slat screens, bold burnt-orange, mustard, avocado-green, teal, cream and brown horizontal bands, and circular or hexagonal side windows. Add readable tropical character with palm or monstera motifs, bamboo/tiki wood trim, a rattan or thatch fringe, and two hanging lanterns. The front has exactly two clearly separate, completely empty service windows and two counter ledges for food pickup; no vendor, food, people or props inside. Put a huge completely blank cream sign panel on the roof fascia, intended to span at least 75% of the building width. No lettering, words, logo, glyphs, texture or decoration inside the panel. Transparent alpha cutout only; no background, floor, cast shadow, vignette or scenery. Design for a 132 x 88 logical-pixel canvas with a bottom-centre origin.

Pixel sharpness spec: crisp block shapes, no antialiasing, no blur, no grain, no dithering, no painterly brush texture, no noisy highlights, no tiny speckles, no one-pixel confetti. Use flat fills, a dark navy outline, chunky 2–5 logical-pixel features, and at most 12 opaque colours.

### Attempt 2 — sign enlargement edit

Edit the generated restaurant while preserving its full-building design, tropical 1970s character, two empty service windows, counter ledges, orange/avocado/cream palette, timber slats, lanterns, thatch fringe, geometric side windows and tropical leaf motifs. Enlarge the central blank cream sign panel into a plain uninterrupted rectangle spanning at least 78% of the full building width and at least 14% of its height. Keep it completely blank: no letters, words, logo, marks, decoration, texture, grain, shadow, border clutter or symbols inside. Preserve transparent alpha and the same pixel sharpness spec; no background, floor, cast shadow, vignette, gradient or scenery.

### Attempt 3 — selected source

Edit the shown restaurant cutout. Preserve the two empty service windows, counters, tropical 1970s orange/avocado/cream style, timber, lanterns, thatch, geometric windows and leaf motifs. Make one decisive geometry change: the blank cream sign panel must extend almost from the far-left roof edge to the far-right roof edge, spanning at least 85% of the restaurant's visible width and at least 15% of its height. The uninterrupted cream interior itself—not merely its outline—must meet that width. Keep it completely blank and flat: absolutely no letters, logo, marks, decoration, texture, grain, shadow, symbols or divisions inside. Retain both empty service windows below. Transparent alpha cutout only: no background, floor, cast shadow, vignette, gradient or scenery. Low wide 132 x 88 logical sprite design. Crisp block pixel art with hard edges, no blur, antialiasing, grain, dithering, speckles or tiny highlights; at most 12 opaque colours.
