# Overhead windup/swat revision

Built-in ImageGen regenerated only windup (atlas frames 25-26) and swat (27-32). The untouched generated source is `overhead-windup-swat-source.png`; its exact prompt is `prompts/overhead-windup-swat.txt`.

Two targeted ImageGen edits adjust the impact reach and knee height. Frame 30 uses `overhead-knee-source.png`, frame 31 uses `overhead-impact-source.png`; the remaining six use the first source. All three full originals and exact prompts are retained. The final measured swat bristle centres are [[65,19],[25,60],[141,76],[130,135],[128,145],[133,146]].

Preparation cropped the eight generated poses, used nearest-neighbour native sampling, hardened alpha, snapped to the original 25-colour v2 palette, and registered the orange body centre at x=79 and the sole edge at y=154. No character or broom pixels were drawn or patched with code. Cells remain 211x176. Presentation sheets from the initial v2 generation are historical; the runtime atlas contains this revision.

`overhead-revision.json` records original source crops, preparation scales, atlas indexes, measured opaque-bristle centres, and pre-update file hashes. All 52 other atlas cells (50 other active frames and two empty cells) were compared pixel-for-pixel and remained unchanged. The only modified fields in sweeper_art.json are swat_reach_source_px and swat_hit_frames, which is now [3,4].

The contact preview reads windup A, windup B, swat 1, swat 2 across its first row, followed by swat 3-6 on the second row. The GIF plays the same sequence.

Validation: unchanged tests/sweeper_checks.gd passed 26 checks, 0 failures. Final audit confirms exact-palette hard-alpha pixels, all six measured anchors on opaque bristles, all 52 other atlas cells pixel-identical, and all three full ImageGen originals retained byte-for-byte. See validation/overhead-checks.log and validation/overhead-audit.json.
