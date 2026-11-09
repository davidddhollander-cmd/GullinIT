"""Crop, resize and align generated sprites. Never paint character pixels."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
REF = ROOT / 'assets/reference/gull-great-black-backed-enraged-v1'
NAME = 'gull-great-black-backed-enraged-v1'

def beak(image):
    pixels = image.load()
    points = [(x,y) for y in range(image.height) for x in range(image.width)
              if pixels[x,y][3] >= 128 and pixels[x,y][0] > 160
              and pixels[x,y][1] > 100 and pixels[x,y][2] < 130
              and pixels[x,y][0] > pixels[x,y][1]]
    right = max(x for x,y in points)
    ys = [y for x,y in points if x == right]
    return right, round(sum(ys)/len(ys))

def remove_detached(image):
    """User-approved removal of detached specks; main bird RGBA is unchanged."""
    alpha = image.getchannel('A')
    points = {(x,y) for y in range(image.height) for x in range(image.width) if alpha.getpixel((x,y))}
    components = []
    while points:
        queue = [points.pop()]
        component = []
        while queue:
            x,y = queue.pop()
            component.append((x,y))
            for p in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
                if p in points:
                    points.remove(p)
                    queue.append(p)
        components.append(component)
    components.sort(key=len,reverse=True)
    result = image.copy()
    removed = 0
    for component in components[1:]:
        for point in component:
            result.putpixel(point,(0,0,0,0))
            removed += 1
    assert all(result.getpixel(p) == image.getpixel(p) for p in components[0])
    return result,removed

def pack():
    source = Image.open(REF/'source.png').convert('RGBA')
    normal = Image.open(ROOT/'assets/sprites/gull-great-black-backed-diner-style.png').convert('RGBA')
    sw,sh = source.width//4,source.height//2
    atlas = Image.new('RGBA',(1024,512))
    records, frames, normals = [], [], []
    for i in range(8):
        original = normal.crop(((i%4)*256,(i//4)*256,(i%4+1)*256,(i//4+1)*256))
        cell = source.crop(((i%4)*sw,(i//4)*sh,(i%4+1)*sw,(i//4+1)*sh))
        bounds = cell.getchannel('A').point(lambda a:255 if a>=200 else 0).getbbox()
        crop = cell.crop(bounds)
        target = beak(original)
        source_beak = beak(crop)
        scale = (140-target[1])/(crop.height-source_beak[1])
        # Keep the normal length plus four pixels of extra puffed body/hackles.
        size = (original.getbbox()[2]-original.getbbox()[0]+4,round(crop.height*scale))
        for dy in [0,-1,1,-2,2,-3,3]:
            bird = crop.resize((size[0],size[1]+dy),Image.Resampling.NEAREST)
            bird,removed = remove_detached(bird)
            bird = bird.crop(bird.getbbox())
            tip = beak(bird)
            y = 140-bird.height
            if abs(y+tip[1]-target[1]) <= 2:
                break
        else:
            raise ValueError(f'No bill/sole aligned sampling for frame {i}')
        x = target[0]-tip[0]
        frame = Image.new('RGBA',(256,256))
        frame.paste(bird,(x,y))
        assert frame.getbbox()[3] == 140
        assert sum((a-b)**2 for a,b in zip(beak(frame),target)) <= 4
        atlas.paste(frame,((i%4)*256,(i//4)*256))
        records.append(dict(frame=i,source_crop=bounds,resize=[size[0],size[1]+dy],detached_pixels_removed=removed,destination=[x,y],normal_beak=target,enraged_beak=beak(frame),bounds=frame.getbbox()))
        frames.append(frame)
        normals.append(original)
    atlas.save(ROOT/f'assets/sprites/{NAME}.png')
    (REF/'packing.json').write_text(json.dumps(dict(baseline_exclusive=140,frames=records),indent=2)+'\n')
    preview(frames,normals)
    print(json.dumps(records))

def panel(label, pairs, zoom=1):
    image = Image.new('RGBA',(800,180),(139,194,215,255))
    draw = ImageDraw.Draw(image)
    draw.rectangle((0,100,800,180),fill=(225,201,148,255))
    draw.text((10,8),label,fill=(22,37,47,255))
    for index,(frame,scale,text) in enumerate(pairs):
        small = frame.resize((round(256*scale),round(256*scale)),Image.Resampling.NEAREST)
        x = index*100+50-round(128*scale)
        y = 100-round(140*scale)
        image.alpha_composite(small,(x,y))
        draw.text((index*100+8,138),text,fill=(22,37,47,255))
    return image

def preview(frames,normals):
    rows = [panel('Idle at game size: normal | enraged | enraged during Shakedown (1.25x)',[(normals[0],.375,'normal'),(frames[0],.375,'enraged'),(frames[0],.46875,'1.25x')]),
            panel('Normal walk source cells 0-7',[(f,.375,str(i)) for i,f in enumerate(normals)]),
            panel('Enraged walk source cells 0-7 at Shakedown size',[(f,.46875,str(i)) for i,f in enumerate(frames)])]
    image=Image.new('RGBA',(800,540))
    for i,row in enumerate(rows): image.paste(row,(0,i*180))
    image.convert('RGB').save(ROOT/f'assets/previews/{NAME}.png')
    gif=[]
    for i in [1,2,3,4,5,6,7,0]:
        row=panel('Walk at 8 fps: normal | enraged | Shakedown 1.25x',[(normals[i],.375,'normal'),(frames[i],.375,'enraged'),(frames[i],.46875,'1.25x')])
        gif.append(row.crop((0,0,440,180)).convert('RGB'))
    # GIF timestamps use 10 ms units: alternate 120/130 for an exact 1 s cycle.
    gif[0].save(ROOT/f'assets/previews/{NAME}-walk.gif',save_all=True,append_images=gif[1:],duration=[120,130]*4,loop=0,disposal=2)

if __name__ == '__main__': pack()
