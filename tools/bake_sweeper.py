"""Bake the 192x160 sweeper master atlas to 1.1x (211x176 cells) so the engine draws it at 0.5 like the rest of the adult cast:
each baked pixel is half a logical pixel. Downsampling to the logical grid (1 px = 1 logical px) looked twice as coarse as mum.
Image processing only: box downsample, hard alpha, near-black edge pixels, a saturation/contrast lift. No pixels are painted."""
import json, re, sys
from PIL import Image, ImageEnhance
S = 1.1
CW, CH = round(192 * S), round(160 * S)   # 106 x 88
OUTLINE = (10, 10, 24)
src = Image.open('assets/sprites/sweeper-v1/sweeper-v1.png').convert('RGBA')
cols, rows = src.width // 192, src.height // 160
out = Image.new('RGBA', (cols * CW, rows * CH), (0, 0, 0, 0))
for r in range(rows):
    for c in range(cols):
        cell = src.crop((c * 192, r * 160, c * 192 + 192, r * 160 + 160))
        # premultiply so transparent pixels do not bleed grey into the edge
        pm = Image.new('RGBA', cell.size)
        a = cell.getchannel('A')
        pm.paste(Image.merge('RGB', [Image.composite(ch, Image.new('L', cell.size, 0), a) for ch in cell.convert('RGB').split()]).convert('RGBA'))
        small = pm.resize((CW, CH), Image.LANCZOS)
        alpha = a.resize((CW, CH), Image.LANCZOS)
        px, ap, res = small.load(), alpha.load(), Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
        rp = res.load()
        for y in range(CH):
            for x in range(CW):
                al = ap[x, y]
                if al >= 128:
                    k = 255.0 / al
                    rp[x, y] = (min(255, int(px[x, y][0] * k)), min(255, int(px[x, y][1] * k)), min(255, int(px[x, y][2] * k)), 255)
        rgb = ImageEnhance.Color(res.convert('RGB')).enhance(1.12)
        rgb = ImageEnhance.Contrast(rgb).enhance(1.12)
        lifted = rgb.convert('RGBA'); lifted.putalpha(res.getchannel('A'))
        lp = lifted.load()
        for y in range(CH):
            for x in range(CW):
                if lp[x, y][3] == 0:
                    continue
                edge = any(not (0 <= x + dx < CW and 0 <= y + dy < CH) or lp[x + dx, y + dy][3] == 0 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                lum = 0.3 * lp[x, y][0] + 0.59 * lp[x, y][1] + 0.11 * lp[x, y][2]
                if (edge and lum < 120) or lum < 55:
                    lp[x, y] = OUTLINE + (255,)
        out.alpha_composite(lifted, (c * CW, r * CH))
out.save('assets/sprites/sweeper-v1/sweeper-v1-game.png')
a = json.load(open('data/sweeper_art.json'))
if 'master' not in a:
    a['master'] = {k: a[k] for k in ('broom_ground_anchors_source_px', 'swat_reach_source_px', 'bin_flick_anchors_source_px', 'body_anchor_x', 'cell_w', 'cell_h')}
m = a['master']
sc = lambda pts: [[round(p[0] * S, 1), round(p[1] * S, 1)] for p in pts]
a['broom_ground_anchors_source_px'] = sc(m['broom_ground_anchors_source_px'])
a['swat_reach_source_px'] = sc(m['swat_reach_source_px'])
a['bin_flick_anchors_source_px'] = sc(m['bin_flick_anchors_source_px'])
a['body_anchor_x'] = round(m['body_anchor_x'] * S, 1)
a['cell_w'], a['cell_h'] = CW, CH
json.dump(a, open('data/sweeper_art.json', 'w'), indent=1)
s = open('data/sprites.json', encoding='utf-8').read()
i = s.index('"sweeper": {'); h, t = s[:i], s[i:]
t = t.replace('sweeper-v1/sweeper-v1.png', 'sweeper-v1/sweeper-v1-game.png', 1)
t = re.sub(r'"frame_w": [0-9.]+', f'"frame_w": {CW}', t, 1)
t = re.sub(r'"frame_h": [0-9.]+', f'"frame_h": {CH}', t, 1)
t = re.sub(r'"visual_scale": [0-9.]+', '"visual_scale": 0.5', t, 1)
open('data/sprites.json', 'w', encoding='utf-8', newline='').write(h + t)
print('baked', out.size, CW, CH)
