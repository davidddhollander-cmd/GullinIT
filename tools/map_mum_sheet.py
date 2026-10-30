"""Map the generated sheet into aligned engine frames; source pixels are untouched."""
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent.parent
sheet = Image.open(root / 'assets/archive/sprites/mum-polished.png')
columns = [0, 385, 680, 978, 1279]
rows = [0, 308, 616, 918, 1230]
centres = [240, 525, 820, 1118]
baselines = [300, 606, 912, 1218]
regions = []
for row in range(4):
    for col in range(4):
        cell = sheet.crop((columns[col], rows[row], columns[col+1], rows[row+1]))
        bounds = cell.getchannel('A').point(lambda a: 255 if a >= 178 else 0).getbbox()
        x, y, right, bottom = bounds
        x += columns[col]
        y += rows[row]
        width, height = right-bounds[0], bottom-bounds[1]
        regions.append({'region':[x,y,width,height], 'offset':[200-(centres[col]-x),320-(baselines[row]-y)]})

path = root / 'data/sprites.json'
data = json.loads(path.read_text(encoding='utf-8-sig'))
def animation(frames, fps=8, loop=True):
    return dict(frames=frames, fps=fps, loop=loop)
data['parent'] = dict(file='res://assets/archive/sprites/mum-polished.png', frame_w=400, frame_h=320,
    visual_scale=0.13, regions=regions, animations={
        'idle':animation([8],1), 'walk':animation([0,1,2,3]),
        'carry':animation([4,5,6,7]), 'handover':animation([8,9,10,10,11],8,False),
        'alert':animation([13],1), 'shield':animation([12],1),
        'swat':animation([14,15],8,False)})
path.write_text(json.dumps(data,indent=2)+'\n', encoding='utf-8')
print('Mapped 16 mum frames without changing source image.')
