# Startup loading screen

The beach palette and large LOADING lettering are readable. The original gull occupied about 76 of the 320 logical screen pixels, making it compete with the heading; it was also baked into an engine splash image, which cannot animate.

`scenes/loading.tscn` is now the application entry point. It overlays the existing approved herring gull's four wingbeat poses on a bird-free backdrop. The gull has a maximum flight width of 40.5 logical pixels, about 47% smaller, and flies right with a gentle bob and bank. The title scene loads through Godot's threaded resource loader. A one-second minimum display gives the animation time to read and prevents a flash on fast launches. Longer loads keep animating until ready. A load failure displays an explanation instead of waiting forever.

The engine's initial, static splash uses the same bird-free backdrop, so it does not briefly show the old oversized gull. The original `assets/archive/sprites/boot-splash.png` and complete gull source atlases remain unchanged.

## Artwork provenance

The built-in image generator edited the original splash to create `assets/sprites/loading-backdrop-v2.png`. This file preserves the complete generated output. No character artwork was generated with code. The animation reuses `assets/sprites/gull-herring-diner-style.png`.

Exact image-edit prompt:

> Use case: precise-object-edit. Asset type: Godot pixel-art loading-screen backdrop. Edit the supplied 1280x720 image. Remove ONLY the seagull from the upper left sky (roughly x260..575, y170..275), reconstructing the flat teal sky, pale horizon and any cloud behind it. Keep the original dimensions, exact flat colors, pixel edges, cloud placements, sun, ocean, beach and the exact LOADING lettering unchanged. No bird, no added objects or text. This backdrop will have an existing animated sprite overlaid by the game.

The generated output is 1672 by 941 and is fitted to the viewport. Composition and lettering match the reference closely; the generated background has some subtle color and texture variation.

## Verification and preview

Run the project with `-- --loading-preview` to keep the loading screen visible. A normal launch continues automatically to the title menu; existing `--smoke` arguments still reach the main scene.

`tests/loading_checks.tscn` checks changing wing poses, forward movement, size, sky clearance, viewport coverage, and the actual application entry point's transition to the working title menu. Add `-- --capture` with a rendering device to save three flight poses and the completed title screen in `test-output/`.

Validated on Godot 4.7.2: 15 startup checks and 14,681 gameplay integration checks passed. Rendered loading and title captures were visually reviewed.

The focused startup runner reports an ObjectDB leak warning during engine shutdown (15 instances in the rendered run), despite passing all assertions. The full gameplay suite exits without that warning. Its cause has not been established; the loading animation and menu transition complete successfully.
