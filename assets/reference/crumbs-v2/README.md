# Retro crumb varieties

Three complete transparent source artworks generated with the built-in ChatGPT image generator are preserved here: `cluster-source.png`, `scatter-source.png`, `biscuit-source.png`.

Preparation: `tools/prepare_crumbs.gd` thresholds alpha, crops and nearest-neighbour samples each into a native 5x3 pixel cell. Runtime atlas: `assets/sprites/food-crumbs-retro-v2.png`. The existing display size, pickup radius, five-point score and respawn delay remain unchanged. Beach scraps cycle through all three varieties in every level; loose bin/stash crumbs also receive stable variants. Crumbs no longer receive the shiny overlay or duplicate shadow texture pass.

Base prompt: Production sprite for a retro 16-bit pixel-art beach game: one tiny scattered cluster of edible bread crumbs, isolated on genuinely transparent background. Extremely coarse chunky pixel art, hard square pixels, jagged stair-step silhouette, NO smooth curves, NO antialiasing, NO realistic texture, NO gradients, NO gloss, NO glow, NO shadow outside sprite. Only four flat colours: pale cream #ffe4a5, golden ochre #dca24f, toasted rust #a56b3b, muted dark brown #755039. Sparse irregular cluster viewed side-on lying on sand. Design on a VERY LOW resolution 10 by 6 pixel grid, enlarged as huge clean square pixels, generous transparent margin. No text, no scene, no props. 

Variety A: three squat angular bread fragments, one large piece on left and two small detached chunks on right. Wide low triangular cluster.

Variety B: four separated uneven square crumbs in a low scattered row, medium toast fragment on the right, two tiny squares to the left, pale broken centre. Wide low cluster, not a pyramid.

Variety C: a little L-shaped broken biscuit crumb in the centre with two detached tiny angular crumbs either side. More pale cream than the other varieties, dark toasted lower pixels, asymmetrical compact low pile.
