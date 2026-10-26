# Carried-food art v1

The untouched generated source is a 4×3 sheet in the same order as `data/foods.json`: crab, crumbs, chip, crisps box; ice cream, crisps bag, hot dog, fried fish; cookie, doughnut, sandwich, pizza. The production sheet packs the nearest-neighbour reductions into twelve 12×12 cells; each mapped region is 6–10 pixels wide with its own beak offset.

Run `tools/prepare_carried_food.gd` to rebuild `assets/sprites/carried-food-v1.png` and `data/carried_food_art.json`. Run `tools/carried_food_preview.gd` to rebuild the preview, where every card shows the real herring-gull carry pose at 1× on the left and 4× on the right.
