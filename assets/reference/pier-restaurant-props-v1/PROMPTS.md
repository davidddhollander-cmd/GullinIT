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

## Beach Hole v2

Three built-in image-generator passes were used. The first established the 1970s tropical architecture; passes two and three enlarged the blank sign while preserving the generated building. All three untouched outputs are saved beside this file.

### Attempt 1 — generation

One isolated, full-building pixel-art sprite for a 2D Godot seaside game: a low, wide 1970s modern tropical beach restaurant. Use a low gently angled roof with a deep overhang, chunky geometric stepped forms, timber slat screens, bold burnt-orange, mustard, avocado-green, teal, cream and brown horizontal bands, and circular or hexagonal side windows. Add readable tropical character with palm or monstera motifs, bamboo/tiki wood trim, a rattan or thatch fringe, and two hanging lanterns. The front has exactly two clearly separate, completely empty service windows and two counter ledges for food pickup; no vendor, food, people or props inside. Put a huge completely blank cream sign panel on the roof fascia, intended to span at least 75% of the building width. No lettering, words, logo, glyphs, texture or decoration inside the panel. Transparent alpha cutout only; no background, floor, cast shadow, vignette or scenery. Design for a 132 x 88 logical-pixel canvas with a bottom-centre origin.

Pixel sharpness spec: crisp block shapes, no antialiasing, no blur, no grain, no dithering, no painterly brush texture, no noisy highlights, no tiny speckles, no one-pixel confetti. Use flat fills, a dark navy outline, chunky 2–5 logical-pixel features, and at most 12 opaque colours.

### Attempt 2 — sign enlargement edit

Edit the generated restaurant while preserving its full-building design, tropical 1970s character, two empty service windows, counter ledges, orange/avocado/cream palette, timber slats, lanterns, thatch fringe, geometric side windows and tropical leaf motifs. Enlarge the central blank cream sign panel into a plain uninterrupted rectangle spanning at least 78% of the full building width and at least 14% of its height. Keep it completely blank: no letters, words, logo, marks, decoration, texture, grain, shadow, border clutter or symbols inside. Preserve transparent alpha and the same pixel sharpness spec; no background, floor, cast shadow, vignette, gradient or scenery.

### Attempt 3 — selected source

Edit the shown restaurant cutout. Preserve the two empty service windows, counters, tropical 1970s orange/avocado/cream style, timber, lanterns, thatch, geometric windows and leaf motifs. Make one decisive geometry change: the blank cream sign panel must extend almost from the far-left roof edge to the far-right roof edge, spanning at least 85% of the restaurant's visible width and at least 15% of its height. The uninterrupted cream interior itself—not merely its outline—must meet that width. Keep it completely blank and flat: absolutely no letters, logo, marks, decoration, texture, grain, shadow, symbols or divisions inside. Retain both empty service windows below. Transparent alpha cutout only: no background, floor, cast shadow, vignette, gradient or scenery. Low wide 132 x 88 logical sprite design. Crisp block pixel art with hard edges, no blur, antialiasing, grain, dithering, speckles or tiny highlights; at most 12 opaque colours.
