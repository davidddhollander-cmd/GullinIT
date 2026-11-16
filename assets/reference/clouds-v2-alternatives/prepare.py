"""Prepare two generated alternatives without altering or resizing v2 art."""
from collections import deque
from pathlib import Path
import hashlib
import json
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = ROOT / 'assets/sprites/background-v2'
OLD_FILES = [OUT / 'clouds-v2.png', OUT / 'clouds-v2.json']
NAMES = ['fair-wisp-01', 'fair-wisp-02', 'fair-wisp-03', 'fair-medium-01',
         'fair-medium-02', 'fair-medium-03', 'fair-large-01', 'fair-large-02',
         'wind-streak-01', 'wind-streak-02', 'wind-streak-03', 'wind-streak-04']
VARIANTS = {
    'coastal': dict(xs=[0, 200, 420, 650, 960], ys=[30, 170, 320, 440],
                    palette=['fff4da', 'f0f0d4', 'b8dde9', '90d0e1']),
    'pearl': dict(xs=[0, 150, 300, 475, 675], ys=[15, 120, 235, 340],
                  palette=['fff4da', 'e5eddf', 'b8dde9', '90d0e1']),
}


def clean(image, palette):
    points = {(x, y) for y in range(image.height) for x in range(image.width)
              if image.getpixel((x, y))[3] >= 128}
    components = []
    while points:
        seed = points.pop()
        component, todo = {seed}, deque([seed])
        while todo:
            x, y = todo.popleft()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    at = (x + dx, y + dy)
                    if at in points:
                        points.remove(at)
                        component.add(at)
                        todo.append(at)
        components.append(component)
    result = Image.new('RGBA', image.size)
    for x, y in max(components, key=len):
        color = image.getpixel((x, y))[:3]
        nearest = min(palette, key=lambda p: sum((a-b)**2 for a,b in zip(p,color)))
        result.putpixel((x, y), (*nearest, 255))
    return result.crop(result.getbbox())


def main():
    before = [p.read_bytes() for p in OLD_FILES]
    for variant, spec in VARIANTS.items():
        source = Image.open(HERE / f'{variant}-source.png').convert('RGBA')
        palette = [tuple(bytes.fromhex(c)) for c in spec['palette']]
        cell_w, cell_h, padding = 288, 144, 8
        atlas = Image.new('RGBA', (cell_w*4, cell_h*3))
        entries = []
        masks = set()
        for i, name in enumerate(NAMES):
            row, col = divmod(i, 4)
            box = (spec['xs'][col], spec['ys'][row], spec['xs'][col+1], spec['ys'][row+1])
            selected_source = source
            source_name = f'{variant}-source.png'
            # The Pearl generation made two wind clouds too round. Use the
            # independently generated Coastal streaks with Pearl's palette.
            if variant == 'pearl' and i in (8, 9):
                coastal = VARIANTS['coastal']
                selected_source = Image.open(HERE / 'coastal-source.png').convert('RGBA')
                box = (coastal['xs'][col], coastal['ys'][row], coastal['xs'][col+1], coastal['ys'][row+1])
                source_name = 'coastal-source.png'
            # Fair clouds have no strong blue edge. Wind clouds may use one.
            sprite = clean(selected_source.crop(box), palette if row == 2 else palette[:3])
            assert sprite.width <= cell_w - padding*2
            assert sprite.height <= cell_h - padding*2
            x = col*cell_w + ((cell_w-sprite.width)//4)*2
            y = row*cell_h + ((cell_h-sprite.height)//4)*2
            atlas.paste(sprite, (x,y))
            mask_hash = hashlib.sha256(sprite.getchannel('A').tobytes()).hexdigest()
            assert mask_hash not in masks
            masks.add(mask_hash)
            entries.append(dict(id=name, set='fair' if i<8 else 'windy',
                                size='small' if i<3 else 'medium' if i<6 else 'large' if i<8 else 'streak',
                                region=[x,y,sprite.width,sprite.height], recommended_scale=.5,
                                display_size=[sprite.width/2, sprite.height/2],
                                source=source_name, source_crop=list(box)))
        filename = f'clouds-v2-alt-{variant}'
        atlas.save(OUT / f'{filename}.png')
        data = dict(version=1, alternative=variant, image=f'{filename}.png', size=list(atlas.size),
                    grid=dict(columns=4,rows=3,cell_size=[cell_w,cell_h],minimum_padding=padding),
                    region_format='[x,y,width,height], tight, top-left origin, unscaled source pixels',
                    palette=['#'+c for c in spec['palette']], alpha='binary: 0 or 255', clouds=entries)
        (OUT / f'{filename}.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
        assert set(atlas.getchannel('A').get_flattened_data()) == {0,255}
        assert {p[:3] for p in atlas.get_flattened_data() if p[3]} <= set(palette)
        assert len(masks) == 12
        print(variant, [(c['id'],c['display_size']) for c in entries])
    assert [p.read_bytes() for p in OLD_FILES] == before
    print('PASS: 24 distinct-within-set clouds; binary alpha; exact palettes; padded grid; original v2 untouched.')


if __name__ == '__main__':
    main()
