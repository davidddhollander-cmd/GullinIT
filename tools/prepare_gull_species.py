"""Pack generated bird poses; retain connected actors and align feet and bills.

This is atlas preparation only: no painted pixels, palette substitutions or
invented poses. Sources and exact generation prompts remain in the reference folder.
"""
import json
import re
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'assets/reference/gull-production-v1'
CELL = 256
DISPLAY_SCALE = .375
SPECS = {'herring': (44, 1.0), 'kittiwake': (34, 1.2), 'great-black-backed': (56, 1.0)}


def components(mask):
    remaining = mask.copy()
    height, width = mask.shape
    result = []
    for y, x in zip(*np.nonzero(mask)):
        if not remaining[y, x]:
            continue
        todo = deque([(int(x), int(y))])
        remaining[y, x] = False
        points = []
        while todo:
            px, py = todo.popleft()
            points.append((px, py))
            for nx, ny in ((px-1, py), (px+1, py), (px, py-1), (px, py+1)):
                if 0 <= nx < width and 0 <= ny < height and remaining[ny, nx]:
                    remaining[ny, nx] = False
                    todo.append((nx, ny))
        result.append(np.asarray(points))
    return sorted(result, key=len, reverse=True)


def isolated(data, points):
    x0, y0 = points.min(axis=0)
    x1, y1 = points.max(axis=0) + 1
    part = np.zeros((y1-y0, x1-x0, 4), dtype=np.uint8)
    part[points[:, 1]-y0, points[:, 0]-x0] = data[points[:, 1], points[:, 0]]
    part[:, :, 3][part[:, :, 3] > 0] = 255
    return Image.fromarray(part)


def bill(image):
    a = np.asarray(image).astype(float)
    yellow = (a[:,:,0] > 145) & (a[:,:,1] > 80) & (a[:,:,2] < a[:,:,1]*.7) & (a[:,:,3] > 192)
    candidates = components(yellow)
    assert candidates, 'Missing yellow bill'
    p = max(candidates, key=lambda c: c[:,0].max())
    x0, y0 = p.min(axis=0)
    x1, y1 = p.max(axis=0)
    return (int(x1)+2, float(np.median(p[:,1])), int(x1-x0+1))


def prepare(species, height, speed):
    source = np.asarray(Image.open(SOURCE / f'{species}-source.png').convert('RGBA'))
    actors = components(source[:,:,3] >= 192)[:20]
    assert len(actors) == 20 and min(map(len, actors)) > 1000, f'{species}: incomplete source actors'
    # Group complete connected actors, not nominal cell crops that can cut wings.
    actors.sort(key=lambda p: float((p[:,1].min()+p[:,1].max())/2))
    ordered = []
    for row in range(5):
        ordered.extend(sorted(actors[row*4:row*4+4], key=lambda p: p[:,0].min()))
    poses = [isolated(source, p) for p in ordered]
    base_scale = height / poses[0].height
    atlas = Image.new('RGBA', (CELL*4, CELL*5))
    anchors = []
    bounds = []
    for index, pose in enumerate(poses):
        scale = base_scale
        pose = pose.resize((round(pose.width*scale), round(pose.height*scale)), Image.Resampling.NEAREST)
        # Nearest sampling can create isolated single-pixel diagonal fragments.
        a = np.asarray(pose)
        pose = isolated(a, components(a[:,:,3] > 0)[0])
        bx, by, _ = bill(pose)
        x = round(CELL/2+20-bx)
        grounded = index < 8 or index >= 17
        y = round(CELL/2+12)-pose.height if grounded else round((CELL/2+(0 if index in (14,16) else 4))-by)
        assert x >= 2 and y >= 2 and x+pose.width <= CELL-2 and y+pose.height <= CELL-2, (species,index,pose.size,x,y)
        atlas.paste(pose,(index%4*CELL+x,index//4*CELL+y))
        offset_y = 6-12*DISPLAY_SCALE if grounded else (0 if index in (14,16) else 2-4*DISPLAY_SCALE)
        anchors.append([10.0, round((y+by-CELL/2)*DISPLAY_SCALE+offset_y, 4)])
        bounds.append([x,y,pose.width,pose.height])
    atlas.save(ROOT / f'assets/sprites/gull-{species}-diner-style.png')
    animations = {
        'idle': ([0], 1, True), 'walk': ([1,2,3,4,5,6,7,0], 8, True),
        'fly': ([8,9,10,11], 10, True), 'climb': ([8,9,10,11], 10, True),
        'glide': ([12], 1, True), 'dive_windup': ([13], 1, False),
        'dive': ([14], 1, True), 'pullup': ([15], 1, False),
        'snatch': ([16], 1, False), 'peck': ([17], 1, False),
        'landing': ([18], 1, False), 'stunned': ([19], 1, True),
    }
    entry = {
        'file': f'res://assets/sprites/gull-{species}-diner-style.png',
        'frame_w': CELL, 'frame_h': CELL, 'visual_scale': DISPLAY_SCALE,
        'species': species, 'art_height': height*DISPLAY_SCALE, 'native_alpha': True,
        'flight_speed_mult': speed, 'ground_beak_y': anchors[0][1],
        'frame_beaks': anchors, 'frame_bounds': bounds,
        'animations': {k: {'frames':v[0], 'fps':v[1], 'loop':v[2], 'source_left':False} for k,v in animations.items()},
    }
    print(species, 'standing',height*DISPLAY_SCALE, 'beak',anchors[0], 'flight speed',speed)
    return entry


def main():
    entries = {f'gull_{key.replace("-","_")}': prepare(key,*value) for key,value in SPECS.items()}
    entries['player_gull'] = entries['gull_herring'].copy()
    entries['rival_gull'] = entries['gull_great_black_backed'].copy()
    (ROOT/'data/gull_art.json').write_text(json.dumps(entries,indent=2)+'\n',encoding='utf-8')
    path = ROOT/'data/sprites.json'
    text = path.read_text(encoding='utf-8-sig')
    for key,entry in entries.items():
        pattern = r'(?ms)^  "' + re.escape(key) + r'": \{.*?^  \}(?=,?\n)'
        replacement = '  "'+key+'": '+json.dumps(entry,indent=2).replace('\n','\n  ')
        text,count = re.subn(pattern,lambda m:replacement,text)
        if not count:
            text = text[:text.rfind('}')].rstrip()+',\n'+replacement+'\n}\n'
    json.loads(text)
    path.write_text(text,encoding='utf-8')


if __name__ == '__main__':
    main()
