"""Compose review contact sheets and an animation from prepared atlas/render files."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT/'assets/previews'
frames = [Image.open(ROOT/f'test-output/gull-production-{i:02}.png').convert('RGB') for i in range(24)]
palette = frames[0].quantize(colors=128)
gif = [frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
gif[0].save(OUT/'gull-species-production-v1.gif',save_all=True,append_images=gif[1:],duration=100,loop=0,optimize=True)
font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',17)
labels = ['Idle','Walk 1','Walk 2','Walk 3','Walk 4','Walk 5','Walk 6','Walk 7',
          'Wings up','Downstroke','Wings down','Upstroke','Glide','Dive preparation',
          'Dive','Pull-up','Snatch','Ground peck','Landing / perch','Stunned']
for species in ['herring','kittiwake','great-black-backed']:
    atlas = Image.open(ROOT/f'assets/sprites/gull-{species}-diner-style.png')
    board = Image.new('RGB',(1000,930),'#a9d5ce')
    draw = ImageDraw.Draw(board)
    draw.rectangle((0,0,1000,39),fill='#183b4e')
    draw.text((12,7),species.upper()+' / ALL 20 SOURCE POSES',font=font,fill='#fff4da')
    for index,label in enumerate(labels):
        cell = atlas.crop((index%4*256,index//4*256,index%4*256+256,index//4*256+256))
        bird = cell.crop(cell.getbbox())
        bird = bird.resize((bird.width*2,bird.height*2),Image.Resampling.NEAREST)
        x,y = index%4*250,index//4*178+40
        board.paste(bird,(x+(250-bird.width)//2,y+135-bird.height),bird)
        draw.text((x+12,y+147),label,font=font,fill='#183b4e')
    board.save(OUT/f'gull-{species}-frames-v1.png')
print('Saved animated preview and three complete pose boards.')
