# Gullin' It pixel art audit

Sprites checked: 96 uses of 92 files  
Findings: S1 44, S2 18, S3 7, S4 8

## Sprites on screen

| Sprite | Group | Scale | Src px per screen px | Height on screen | Colours | Off-palette | Outline |
| --- | --- | --- | --- | --- | --- | --- | --- |
| crab_blue | animals | 0.25 | 4.0 | 8 | 40 | 82% | 40% |
| crab_red | animals | 0.25 | 4.0 | 7 | 47 | 70% | 43% |
| off_lead_dog | animals | 0.5 | 2.0 | 16 | 214 | 37% | 66% |
| pier_diner | diner | 0.11 | 9.09 | 39 | 628 | 82% | 100% |
| pier_diner_b | diner | 0.5 | 2.0 | 40 | 571 | 92% | 88% |
| pier_diner_b_motion | diner | 0.5 | 2.0 | 40 | 550 | 91% | 90% |
| pier_diner_b_reactions | diner | 0.5 | 2.0 | 40 | 585 | 93% | 95% |
| pier_diner_motion | diner | 0.11 | 9.09 | 37 | 486 | 82% | 76% |
| pier_diner_reactions | diner | 0.11 | 9.09 | 37 | 620 | 76% | 91% |
| food_crisps_bag | food | 0.019 | 52.63 | 7 | 31 | 71% | 44% |
| food_crisps_box | food | 0.0182 | 54.95 | 6 | 27 | 46% | 33% |
| food_crumbs | food | 0.0093 | 107.53 | 2 | 3 | 67% | 33% |
| food_fried_fish | food | 0.018 | 55.56 | 5 | 21 | 86% | 29% |
| food_half_eaten_doughnut | food | 0.5 | 2.0 | 7 | 6 | 0% | 21% |
| food_half_eaten_pizza | food | 0.5 | 2.0 | 6 | 7 | 0% | 25% |
| food_half_eaten_sandwich | food | 0.5 | 2.0 | 7 | 7 | 0% | 25% |
| food_hotdog | food | 0.0141 | 70.92 | 4 | 16 | 69% | 42% |
| food_ice_cream | food | 0.0191 | 52.36 | 7 | 19 | 55% | 54% |
| food_single_chip | food | 0.0082 | 121.95 | 2 | 2 | 0% | 0% |
| gull_great_black_backed | gull | 0.375 | 2.67 | 21 | 267 | 61% | 63% |
| gull_great_black_backed_carry | gull | 0.375 | 2.67 | 20 | 260 | 63% | 60% |
| gull_great_black_backed_carry_beak | gull | 0.375 | 2.67 | 3 | 17 | 47% | 20% |
| gull_herring | gull | 0.375 | 2.67 | 16 | 146 | 48% | 52% |
| gull_herring_carry | gull | 0.375 | 2.67 | 16 | 133 | 44% | 41% |
| gull_herring_carry_beak | gull | 0.375 | 2.67 | 3 | 13 | 46% | 9% |
| gull_kittiwake | gull | 0.375 | 2.67 | 13 | 87 | 42% | 37% |
| gull_kittiwake_carry | gull | 0.375 | 2.67 | 13 | 88 | 39% | 52% |
| gull_kittiwake_carry_beak | gull | 0.375 | 2.67 | 3 | 9 | 67% | 62% |
| gull_screech | gull | 0.375 | 2.67 | 17 | 138 | 47% | 43% |
| rival_gull_carry | gull | 0.375 | 2.67 | 20 | 264 | 33% | 57% |
| rival_gull_carry_beak | gull | 0.375 | 2.67 | 4 | 24 | 54% | 22% |
| bench_mullet | people | 0.5 | 2.0 | 40 | 685 | 80% | 81% |
| bench_sundress | people | 0.5 | 2.0 | 40 | 741 | 65% | 89% |
| bench_yellow | people | 0.5 | 2.0 | 40 | 462 | 84% | 86% |
| dog | people | 0.5 | 2.0 | 40 | 672 | 69% | 78% |
| kiosk_customer | people | 0.5 | 2.0 | 40 | 462 | 84% | 86% |
| lifeguard | people | 0.5 | 2.0 | 40 | 591 | 86% | 100% |
| market_cleaner | people | 0.5 | 2.0 | 40 | 785 | 83% | 86% |
| mum_picnic | people | 0.5 | 2.0 | 40 | 553 | 95% | 96% |
| old_man | people | 0.3 | 3.33 | 28 | 359 | 68% | 92% |
| shopper_mullet | people | 0.5 | 2.0 | 40 | 685 | 80% | 81% |
| shopper_sundress | people | 0.5 | 2.0 | 40 | 741 | 65% | 89% |
| shopper_walk_mullet_v2 | people | 0.5 | 2.0 | 40 | 685 | 80% | 81% |
| shopper_walk_sundress_v2 | people | 0.5 | 2.0 | 40 | 741 | 65% | 89% |
| sunbather_female_blue | people | 0.5 | 2.0 | 18 | 393 | 92% | 96% |
| sunbather_female_red | people | 0.5 | 2.0 | 18 | 412 | 97% | 96% |
| sunbather_male_blue | people | 0.5 | 2.0 | 18 | 390 | 84% | 98% |
| sunbather_male_red | people | 0.5 | 2.0 | 18 | 391 | 90% | 99% |
| toddler | people | 0.5 | 2.0 | 22 | 252 | 67% | 84% |
| beach_bench | props | 1 | 1.0 | 21 | 6 | 0% | 100% |
| beach_boards | props | 1 | 1.0 | 25 | 9 | 0% | 98% |
| beach_castle | props | 1 | 1.0 | 22 | 7 | 0% | 71% |
| beach_chair | props | 1 | 1.0 | 18 | 9 | 0% | 96% |
| beach_chair_blue | props | 1 | 1.0 | 18 | 9 | 0% | 95% |
| beach_hut | props | 1 | 1.0 | 52 | 13 | 0% | 100% |
| beach_lamp | props | 1 | 1.0 | 88 | 9 | 0% | 97% |
| beach_palm | props | 1 | 1.0 | 51 | 7 | 0% | 90% |
| beach_parasol | props | 1 | 1.0 | 38 | 9 | 0% | 100% |
| beach_parasol_blue | props | 1 | 1.0 | 41 | 11 | 0% | 97% |
| beach_rocks | props | 1 | 1.0 | 18 | 9 | 0% | 61% |
| beach_sign | props | 1 | 1.0 | 38 | 5 | 0% | 97% |
| bin | props | 1 | 1.0 | 17 | 6 | 0% | 98% |
| fish_chips_stand | props | 1 | 1.0 | 42 | 14 | 0% | 97% |
| hotdog_stand | props | 1 | 1.0 | 56 | 10 | 0% | 96% |
| kiosk | props | 1 | 1.0 | 56 | 14 | 0% | 100% |
| pier | props | 1 | 1.0 | 40 | 2 | 0% | 0% |
| retro-picnic-bag-coral-32bit | props | 1 | 1.0 | 16 | 8 | 0% | 48% |
| retro-picnic-bag-teal-32bit | props | 1 | 1.0 | 21 | 8 | 0% | 47% |
| retro-picnic-bag-woven-32bit | props | 1 | 1.0 | 21 | 9 | 0% | 73% |
| tower | props | 1 | 1.0 | 70 | 10 | 0% | 99% |
| umbrella | props | 1 | 1.0 | 37 | 10 | 0% | 100% |
| wheelie_bin | props | 0.8 | 1.25 | 26 | 327 | 23% | 88% |
| beach_sign_arrow | signs | 0.4 | 2.5 | 8 | 76 | 25% | 0% |
| beach_sign_arrow_left | signs | 0.4 | 2.5 | 8 | 76 | 25% | 0% |
| beach_sign_post | signs | 0.75 | 1.33 | 38 | 101 | 0% | 3% |
| stand-sign-fish-chips-runtime-v1 | signs | 0.25 | 4.0 | 13 | 356 | 58% | 87% |
| stand-sign-hot-dogs-runtime-v2 | signs | 0.25 | 4.0 | 18 | 438 | 8% | 29% |
| stand-sign-ice-cream-runtime-v2 | signs | 0.25 | 4.0 | 19 | 464 | 30% | 18% |
| loading_backdrop | ui | 0.1914 | 5.22 | 180 | 4707 | 59% | 0% |
| title_logo | ui | 0.3333 | 3.0 | 26 | 2418 | 53% | 93% |
| vendor_hotdog_base_atlas | vendors | 0.5 | 2.0 | 40 | 541 | 66% | 84% |
| vendor_hotdog_file | vendors | 0.5 | 2.0 | 40 | 541 | 66% | 84% |
| vendor_ice_cream_base_atlas | vendors | 0.5 | 2.0 | 40 | 548 | 67% | 92% |
| vendor_ice_cream_file | vendors | 0.5 | 2.0 | 40 | 548 | 67% | 92% |
| vendor_vendor_fish_chips_base_atlas | vendors | 0.5 | 2.0 | 40 | 524 | 66% | 89% |
| vendor_vendor_fish_chips_file | vendors | 0.5 | 2.0 | 40 | 524 | 66% | 89% |
| feather-down-v1 | vfx | 0.25 | 4.0 | 6 | 22 | 23% | 19% |
| feather-fluff-v1 | vfx | 0.25 | 4.0 | 6 | 25 | 60% | 36% |
| feather-gray-v1 | vfx | 0.25 | 4.0 | 6 | 14 | 29% | 25% |
| feather-tip-v1 | vfx | 0.25 | 4.0 | 5 | 17 | 53% | 57% |
| vfx-crumb-flecks-v1 | vfx | 1 | 1.0 | 6 | 3 | 0% | 50% |
| vfx-dust-puff-v1 | vfx | 1 | 1.0 | 6 | 4 | 23% | 41% |
| vfx-impact-wedge-v1 | vfx | 1 | 1.0 | 8 | 4 | 0% | 47% |
| vfx-peck-star-v1 | vfx | 1 | 1.0 | 8 | 4 | 0% | 50% |
| vfx-snatch-slash-v1 | vfx | 1 | 1.0 | 8 | 4 | 0% | 48% |
| vfx-speed-streak-v1 | vfx | 1 | 1.0 | 6 | 4 | 0% | 44% |

## Findings

| Severity | Check | Where | Detail |
| --- | --- | --- | --- |
| S1 | D1 density | `assets/sprites/beach-sign-arrow-left-v4.png [beach_sign_arrow_left]` | visual_scale 0.4 vs standard 0.5; 1.25 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (16 px tall in the file) |
| S1 | D1 density | `assets/sprites/beach-sign-arrow-v4.png [beach_sign_arrow]` | visual_scale 0.4 vs standard 0.5; 1.25 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (16 px tall in the file) |
| S1 | D1 density | `assets/sprites/beach-sign-post-v1.png [beach_sign_post]` | visual_scale 0.75 vs standard 0.5; 0.67 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (76 px tall in the file) |
| S1 | D1 density | `assets/sprites/food_bites.png [food_crisps_bag]` | visual_scale 0.019 vs standard 0.5; 26.32 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (14 px tall in the file) |
| S1 | D1 density | `assets/sprites/food_bites.png [food_crisps_box]` | visual_scale 0.0182 vs standard 0.5; 27.47 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (12 px tall in the file) |
| S1 | D1 density | `assets/sprites/food_bites.png [food_crumbs]` | visual_scale 0.0093 vs standard 0.5; 53.76 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (4 px tall in the file) |
| S1 | D1 density | `assets/sprites/food_bites.png [food_fried_fish]` | visual_scale 0.018 vs standard 0.5; 27.78 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (10 px tall in the file) |
| S1 | D1 density | `assets/sprites/food_bites.png [food_hotdog]` | visual_scale 0.0141 vs standard 0.5; 35.46 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (8 px tall in the file) |
| S1 | D1 density | `assets/sprites/food_bites.png [food_ice_cream]` | visual_scale 0.0191 vs standard 0.5; 26.18 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (14 px tall in the file) |
| S1 | D1 density | `assets/sprites/food_bites.png [food_single_chip]` | visual_scale 0.0082 vs standard 0.5; 60.98 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (4 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-great-black-backed-carry-v1-upper-beak.png [gull_great_black_backed_carry_beak]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (6 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-great-black-backed-carry-v1.png [gull_great_black_backed_carry]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (40 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-great-black-backed-diner-style.png [gull_great_black_backed]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (42 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-herring-carry-v1-upper-beak.png [gull_herring_carry_beak]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (6 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-herring-carry-v1.png [gull_herring_carry]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (32 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-herring-diner-style.png [gull_herring]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (32 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-herring-screech-v1.png [gull_screech]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (34 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-kittiwake-carry-v1-upper-beak.png [gull_kittiwake_carry_beak]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (6 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-kittiwake-carry-v1.png [gull_kittiwake_carry]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (26 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-kittiwake-diner-style.png [gull_kittiwake]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (26 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-rival-tint-base-carry-v1-upper-beak.png [rival_gull_carry_beak]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (8 px tall in the file) |
| S1 | D1 density | `assets/sprites/gull-rival-tint-base-carry-v1.png [rival_gull_carry]` | visual_scale 0.375 vs standard 0.5; 1.33 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (40 px tall in the file) |
| S1 | D1 density | `assets/sprites/loading-backdrop-v2.png [loading_backdrop]` | visual_scale 0.1914 vs standard 0.5; 2.61 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (360 px tall in the file) |
| S1 | D1 density | `assets/sprites/pier-diner-motion-v2.png [pier_diner_motion]` | visual_scale 0.11 vs standard 0.5; 4.55 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (74 px tall in the file) |
| S1 | D1 density | `assets/sprites/pier-diner-reactions-v1.png [pier_diner_reactions]` | visual_scale 0.11 vs standard 0.5; 4.55 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (74 px tall in the file) |
| S1 | D1 density | `assets/sprites/pier-diner-retro-clean.png [pier_diner]` | visual_scale 0.11 vs standard 0.5; 4.55 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (78 px tall in the file) |
| S1 | D1 density | `assets/sprites/retro-old-man-stick-32bit.png [old_man]` | visual_scale 0.3 vs standard 0.5; 1.67 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (56 px tall in the file) |
| S1 | D1 density | `assets/sprites/retro-wheelie-bin-green-32bit.png [wheelie_bin]` | visual_scale 0.8 vs standard 0.5; 0.62 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (52 px tall in the file) |
| S1 | D1 density | `assets/sprites/title-logo.png [title_logo]` | visual_scale 0.3333 vs standard 0.5; 1.50 texels per art pixel (non-integer): nearest sampling drops pixels unevenly and shimmers in motion. Re-export so it draws at 0.5 (52 px tall in the file) |
| S1 | G2 filter | `scenes/loading.tscn:16` | linear (smooth) filtering: `texture_filter = 1`; pixel art must use Nearest |
| S1 | G2 filter | `scenes/loading.tscn:36` | linear (smooth) filtering: `texture_filter = 1`; pixel art must use Nearest |
| S1 | G2 filter | `scripts/main.gd:29` | linear (smooth) filtering: `castle.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR`; pixel art must use Nearest |
| S1 | G2 filter | `scripts/menus.gd:43` | linear (smooth) filtering: `logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR`; pixel art must use Nearest |
| S1 | P2 alpha | `assets/beach-arcade-font-sprite-sheet-v2.png` | 100% of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255 |
| S1 | P2 alpha | `assets/beach-arcade-font-sprite-sheet-v3.png` | 99% of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255 |
| S1 | P2 alpha | `assets/sprites/feather-down-v1.png` | 91% of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255 |
| S1 | P2 alpha | `assets/sprites/feather-fluff-v1.png` | 91% of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255 |
| S1 | P2 alpha | `assets/sprites/feather-gray-v1.png` | 88% of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255 |
| S1 | P2 alpha | `assets/sprites/feather-tip-v1.png` | 89% of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255 |
| S1 | P2 alpha | `assets/sprites/food_bites.png` | 100% of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255 |
| S1 | P2 alpha | `assets/sprites/pier-diner-motion-v2.png` | 100% of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255 |
| S1 | P2 alpha | `assets/sprites/pier-diner-reactions-v1.png` | 100% of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255 |
| S1 | P2 alpha | `assets/sprites/pier-diner-retro-clean.png` | 100% of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255 |
| S1 | P2 alpha | `assets/sprites/title-logo.png` | 97% of opaque pixels are semi-transparent (soft edges/halo); threshold alpha to 0/255 |
| S2 | D1 density | `assets/sprites/crab-blue-v2.png [crab_blue]` | visual_scale 0.25 vs standard 0.5; 2 texels per art pixel: finer detail than the standard, dropped evenly. Re-export so it draws at 0.5 (16 px tall in the file) |
| S2 | D1 density | `assets/sprites/crab-red-v2.png [crab_red]` | visual_scale 0.25 vs standard 0.5; 2 texels per art pixel: finer detail than the standard, dropped evenly. Re-export so it draws at 0.5 (14 px tall in the file) |
| S2 | D1 density | `assets/sprites/feather-down-v1.png [feather-down-v1]` | visual_scale 0.25 vs standard 0.5; 2 texels per art pixel: finer detail than the standard, dropped evenly. Re-export so it draws at 0.5 (12 px tall in the file) |
| S2 | D1 density | `assets/sprites/feather-fluff-v1.png [feather-fluff-v1]` | visual_scale 0.25 vs standard 0.5; 2 texels per art pixel: finer detail than the standard, dropped evenly. Re-export so it draws at 0.5 (12 px tall in the file) |
| S2 | D1 density | `assets/sprites/feather-gray-v1.png [feather-gray-v1]` | visual_scale 0.25 vs standard 0.5; 2 texels per art pixel: finer detail than the standard, dropped evenly. Re-export so it draws at 0.5 (12 px tall in the file) |
| S2 | D1 density | `assets/sprites/feather-tip-v1.png [feather-tip-v1]` | visual_scale 0.25 vs standard 0.5; 2 texels per art pixel: finer detail than the standard, dropped evenly. Re-export so it draws at 0.5 (10 px tall in the file) |
| S2 | D1 density | `assets/sprites/stand-sign-fish-chips-runtime-v1.png [stand-sign-fish-chips-runtime-v1]` | visual_scale 0.25 vs standard 0.5; 2 texels per art pixel: finer detail than the standard, dropped evenly. Re-export so it draws at 0.5 (26 px tall in the file) |
| S2 | D1 density | `assets/sprites/stand-sign-hot-dogs-runtime-v2.png [stand-sign-hot-dogs-runtime-v2]` | visual_scale 0.25 vs standard 0.5; 2 texels per art pixel: finer detail than the standard, dropped evenly. Re-export so it draws at 0.5 (36 px tall in the file) |
| S2 | D1 density | `assets/sprites/stand-sign-ice-cream-runtime-v2.png [stand-sign-ice-cream-runtime-v2]` | visual_scale 0.25 vs standard 0.5; 2 texels per art pixel: finer detail than the standard, dropped evenly. Re-export so it draws at 0.5 (38 px tall in the file) |
| S2 | D2 palette | `assets/sprites/feather-fluff-v1.png [feather-fluff-v1]` | 60% of on-screen pixels are off the prop palette |
| S2 | D2 palette | `assets/sprites/feather-gray-v1.png [feather-gray-v1]` | 29% of on-screen pixels are off the prop palette |
| S2 | D2 palette | `assets/sprites/feather-tip-v1.png [feather-tip-v1]` | 53% of on-screen pixels are off the prop palette |
| S2 | D3 colours | `assets/sprites/feather-down-v1.png [feather-down-v1]` | 22 colours on screen (prop budget 16) |
| S2 | D3 colours | `assets/sprites/feather-fluff-v1.png [feather-fluff-v1]` | 25 colours on screen (prop budget 16) |
| S2 | D3 colours | `assets/sprites/feather-tip-v1.png [feather-tip-v1]` | 17 colours on screen (prop budget 16) |
| S2 | D3 colours | `assets/sprites/retro-wheelie-bin-green-32bit.png [wheelie_bin]` | 327 colours on screen (prop budget 16) |
| S2 | D5 style gap | `characters vs props` | characters average 431 colours on screen and 70% off the prop palette; props average 23 colours, 0% off. Decide whether props get a painted pass or characters get a palette-snap pass |
| S2 | G1 project | `project.godot` | window/stretch/scale_mode = (default); want integer. Scale mode not integer: at window sizes that are not a multiple of 320x180 (e.g. 1366x768) pixels get uneven widths. integer scale keeps every art pixel the same size |
| S3 | D1 density | `28 props/VFX at visual_scale 1` | each texel covers 2x2 art pixels, so props are chunkier than the 0.5-scale characters. Style decision: accept as a deliberate 'chunky world, finer cast' look, or redraw props at double resolution. Sprites: umbrella, bin, kiosk, tower, pier, hotdog_stand, fish_chips_stand, beach_parasol, beach_parasol_blue, beach_chair, beach_chair_blue, beach_bench, beach_palm, beach_sign, beach_castle, beach_rocks, beach_boards, beach_hut, beach_lamp, vfx-crumb-flecks-v1, vfx-dust-puff-v1, vfx-impact-wedge-v1, vfx-peck-star-v1, vfx-snatch-slash-v1, vfx-speed-streak-v1, retro-picnic-bag-coral-32bit, retro-picnic-bag-teal-32bit, retro-picnic-bag-woven-32bit |
| S3 | D3 colours | `assets/sprites/gull-great-black-backed-carry-v1.png [gull_great_black_backed_carry]` | 260 colours on screen vs 110 median for gull: busier than its peers |
| S3 | D3 colours | `assets/sprites/gull-great-black-backed-diner-style.png [gull_great_black_backed]` | 267 colours on screen vs 110 median for gull: busier than its peers |
| S3 | D3 colours | `assets/sprites/gull-rival-tint-base-carry-v1.png [rival_gull_carry]` | 264 colours on screen vs 110 median for gull: busier than its peers |
| S3 | D3 colours | `assets/sprites/off-lead-dog-pixel-v1.png [off_lead_dog]` | 214 colours on screen vs 47 median for animals: busier than its peers |
| S3 | D3 colours | `assets/sprites/stand-sign-ice-cream-runtime-v2.png [stand-sign-ice-cream-runtime-v2]` | 464 colours on screen vs 228 median for signs: busier than its peers |
| S3 | G1 project | `project.godot` | 2d/snap/snap_2d_vertices_to_pixel = (default); want true. Vertices not snapped to pixel: edges wobble on moving sprites |
| S4 | U1 unused | `assets/sprites/chips.png [legacy_chips]` | loaded but not drawn: 8x8 placeholder in sprites.json; no food or target uses it. Remove the entry so it cannot creep back in |
| S4 | U1 unused | `assets/sprites/cone.png [legacy_cone]` | loaded but not drawn: 8x8 placeholder in sprites.json; no food or target uses it. Remove the entry so it cannot creep back in |
| S4 | U1 unused | `assets/sprites/fish_chips.png [legacy_fish_chips]` | loaded but not drawn: 8x8 placeholder in sprites.json; no food or target uses it. Remove the entry so it cannot creep back in |
| S4 | U1 unused | `assets/sprites/hot_dog.png [legacy_hot_dog]` | loaded but not drawn: 8x8 placeholder in sprites.json; no food or target uses it. Remove the entry so it cannot creep back in |
| S4 | U1 unused | `assets/sprites/ice_cream.png [legacy_ice_cream]` | loaded but not drawn: 8x8 placeholder in sprites.json; no food or target uses it. Remove the entry so it cannot creep back in |
| S4 | U1 unused | `assets/sprites/sandwich.png [legacy_sandwich]` | loaded but not drawn: 8x8 placeholder in sprites.json; no food or target uses it. Remove the entry so it cannot creep back in |
| S4 | U1 unused | `assets/sprites/seafood.png [legacy_seafood]` | loaded but not drawn: 8x8 placeholder in sprites.json; no food or target uses it. Remove the entry so it cannot creep back in |
| S4 | U1 unused | `assets/sprites/toddler_polished.png [toddler_polished]` | loaded but not drawn: only in data/toddler_art.json, which Config never loads. Remove the entry so it cannot creep back in |
