"""Crop, nearest-sample, and align generated art; never paint character pixels."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
REF = ROOT / 'assets/reference/gull-kittiwake-screech-v1'
source = Image.open(REF / 'source.png').convert('RGBA')
idle = Image.open(ROOT / 'assets/sprites/gull-kittiwake-diner-style.png').convert('RGBA').crop((0, 0, 256, 256))
baseline = idle.getbbox()[3]

def foot_center(bird):
    box = bird.getbbox()
    bottom = bird.crop((0, box[3] - 3, bird.width, box[3])).getbbox()
    return (bottom[0] + bottom[2]) / 2

target_foot = foot_center(idle)

def connected(image):
    alpha = image.getchannel('A')
    pixels = {(x,y) for y in range(image.height) for x in range(image.width) if alpha.getpixel((x,y))}
    if not pixels:
        return False
    queue = [pixels.pop()]
    while queue:
        x,y = queue.pop()
        for point in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
            if point in pixels:
                pixels.remove(point)
                queue.append(point)
    return not pixels

cw, ch = source.width // 3, source.height // 2
assert source.size == (cw * 3, ch * 2)
crops = []
for index in range(6):
    cell = source.crop(((index % 3)*cw, (index // 3)*ch, (index % 3+1)*cw, (index // 3+1)*ch))
    # Bounds detection only; generated RGBA pixels inside the crop are unchanged.
    bounds = cell.getchannel('A').point(lambda a: 255 if a >= 128 else 0).getbbox()
    assert bounds
    crops.append((cell.crop(bounds), bounds))
scale = (idle.getbbox()[2] - idle.getbbox()[0]) / crops[0][0].width
atlas = Image.new('RGBA', (768, 512))
cells, records = [], []
for index, (bird, bounds) in enumerate(crops):
    size = (round(bird.width*scale), round(bird.height*scale))
    # A nearby sampling size can keep thin generated toes/feathers connected.
    # As in task 065, this resizes only; no character pixels are repaired.
    candidates = sorted([(dx,dy) for dx in range(-4,5) for dy in range(-4,5)], key=lambda d:abs(d[0])+abs(d[1]))
    for dx,dy in candidates:
        sampled = bird.resize((size[0]+dx,size[1]+dy), Image.Resampling.NEAREST)
        if connected(sampled):
            bird = sampled
            break
    else:
        raise ValueError(f'No connected sampling for frame {index}')
    x = round(target_foot - foot_center(bird))
    y = baseline - bird.getbbox()[3]
    frame = Image.new('RGBA', (256, 256))
    frame.paste(bird, (x, y))
    assert frame.getbbox()[3] == baseline
    atlas.paste(frame, ((index % 3)*256, (index // 3)*256))
    cells.append(frame)
    records.append(dict(frame=index, source_crop=bounds, nominal_size=size, size=bird.size, sampling_adjustment=[dx,dy], destination=[x,y], bounds=frame.getbbox(), foot_center=foot_center(frame)))
atlas.save(ROOT / 'assets/sprites/gull-kittiwake-screech-v1.png')
(REF / 'packing.json').write_text(json.dumps(dict(scale=scale, baseline_exclusive=baseline, idle_foot_center=target_foot, frames=records), indent=2)+'\n')
preview = Image.new('RGBA', (840, 300), (72, 95, 111, 255))
draw = ImageDraw.Draw(preview)
draw.text((8,8), 'Kittiwake: idle + screech at game scale (0.375)', fill='white')
draw.text((8,145), 'Enlarged detail (2x atlas pixels)', fill='white')
for index, frame in enumerate([idle] + cells):
    preview.alpha_composite(frame.resize((96,96), Image.Resampling.NEAREST), (index*120,25))
    draw.text((index*120+8,125), 'idle' if index == 0 else str(index-1)+(' peak' if index == 5 else ''), fill='white')
    # Same crop in each panel makes the fixed sole and rising neck visible.
    detail = frame.crop((96,86,152,142)).resize((112,112),Image.Resampling.NEAREST)
    # Each detail is displayed at 2x source pixels, without modifying assets.
    preview.alpha_composite(detail,(index*120+4,172))
preview.convert('RGB').save(ROOT / 'assets/previews/gull-kittiwake-screech-v1.png')
print(json.dumps(records, indent=2))

