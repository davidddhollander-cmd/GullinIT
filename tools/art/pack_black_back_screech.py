from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
REF = ROOT / 'assets/reference/gull-great-black-backed-screech-v1'
REF.mkdir(parents=True, exist_ok=True)
SOURCE = REF / 'source.png'
source = Image.open(SOURCE).convert('RGBA')
atlas = Image.new('RGBA', (768,512))
cells = []
records = []
# A common target scale preserves body scale across the generated poses.
# Crop and align only; preserve the generated RGBA pixels without repainting.
scale = 56 / 205
def connected(image):
    a = image.getchannel('A')
    pts = {(x,y) for y in range(image.height) for x in range(image.width) if a.getpixel((x,y))}
    q = [pts.pop()]
    while q:
        x,y = q.pop()
        for p in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
            if p in pts:
                pts.remove(p)
                q.append(p)
    return not pts
for i in range(6):
    cell = source.crop(((i%3)*512,(i//3)*512,(i%3+1)*512,(i//3+1)*512))
    bounds = cell.getchannel('A').point(lambda a: 255 if a >= 200 else 0).getbbox()
    bird = cell.crop(bounds)
    size = (round(bird.width*scale),round(bird.height*scale))
    # Choose a nearby sampling size that keeps feather tips connected after
    # downsampling. No pixels are painted, erased, recoloured or alpha-masked.
    candidates = sorted([(dx,dy) for dx in range(-3,4) for dy in range(-2,3)],key=lambda d:abs(d[0])+abs(d[1]))
    for dx,dy in candidates:
        sampled = bird.resize((size[0]+dx,size[1]+dy),Image.Resampling.NEAREST)
        if connected(sampled):
            bird = sampled
            break
    else:
        raise ValueError(f'No connected sampling for frame {i}')
    frame = Image.new('RGBA',(256,256))
    # Generated planted feet are at local x=275 in each source cell.
    x = round(120-(275-bounds[0])*scale)
    y = 140-bird.height
    frame.paste(bird,(x,y))
    atlas.paste(frame,((i%3)*256,(i//3)*256))
    cells.append(frame)
    records.append({'frame':i,'source_crop':list(bounds),'destination':[x,y],'bounds':list(frame.getbbox())})
atlas.save(ROOT / 'assets/sprites/gull-great-black-backed-screech-v1.png')
(REF/'packing.json').write_text(json.dumps({'scale':scale,'baseline_exclusive':140,'frames':records},indent=2)+'\n')
idle = Image.open(ROOT/'assets/sprites/gull-great-black-backed-diner-style.png').crop((0,0,256,256))
preview = Image.new('RGBA',(7*100,150),(72,95,111,255))
draw = ImageDraw.Draw(preview)
draw.text((8,8),'Great black-back: idle + six screech frames at game scale (0.375)',fill='white')
for i,frame in enumerate([idle]+cells):
    mini = frame.resize((96,96),Image.Resampling.NEAREST)
    preview.alpha_composite(mini,(i*100,30))
    draw.text((i*100+8,125),'idle' if i==0 else f'{i-1}'+(' peak' if i==5 else ''),fill='white')
preview.convert('RGB').save(ROOT/'assets/previews/gull-great-black-backed-screech-v1.png')
print(records)
