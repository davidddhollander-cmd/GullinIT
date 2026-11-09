"""Task 075: pack generator artwork; never draw/repaint/recolour the gull."""
from pathlib import Path
import copy, io, json, subprocess, sys
sys.dont_write_bytecode = True
from PIL import Image, ImageDraw
from pack_black_back_enraged import beak, remove_detached

ROOT = Path(__file__).resolve().parents[2]
REF = ROOT/'assets/reference/gull-great-black-backed-enraged-v1'
SPR = ROOT/'assets/sprites'
PRE = ROOT/'assets/previews'
ID = 'gull_great_black_backed'
BODY = 'gull-great-black-backed-enraged-v1.png'
SCREECH = 'gull-great-black-backed-enraged-screech-v1.png'
CARRY = 'gull-great-black-backed-enraged-carry-v1.png'
OVERLAY = CARRY.removesuffix('.png')+'-upper-beak.png'
CLIPS = ['fly','climb','glide','dive_windup','dive','pullup','snatch','peck','landing','stunned','screech']

def read(path): return Image.open(path).convert('RGBA')
def cell(image,index,cols): return image.crop(((index%cols)*256,(index//cols)*256,(index%cols+1)*256,(index//cols+1)*256))
def generated(image,index,cols,rows):
    box=(round((index%cols)*image.width/cols),round((index//cols)*image.height/rows),round((index%cols+1)*image.width/cols),round((index//cols+1)*image.height/rows))
    return image.crop(box),box

def fit(source,normal,grounded,label):
    crop_box=source.getchannel('A').point(lambda a:255 if a>=200 else 0).getbbox()
    assert crop_box, label+' empty source'
    crop=source.crop(crop_box)
    bounds=normal.getbbox()
    target=beak(normal)
    nw,nh=bounds[2]-bounds[0],bounds[3]-bounds[1]
    width=nw+4
    preferred=nh+8
    heights=sorted(range(max(12,nh-8),min(180,nh*2+20)),key=lambda h:abs(h-preferred)) if grounded else [preferred]
    choices=[]
    for height in heights:
        sampled=crop.resize((width,height),Image.Resampling.NEAREST)
        clean,removed=remove_detached(sampled)
        trim=clean.getbbox()
        bird=clean.crop(trim)
        tip=beak(bird)
        y=bounds[3]-bird.height if grounded else target[1]-tip[1]
        error=abs(y+tip[1]-target[1])
        if error<=2:
            choices.append((error,abs(height-preferred),bird,removed,height,trim,y))
            if error<=1:
                break
    if not choices:
        raise ValueError(label+': no bill/sole alignment; regenerate this pose')
    error,_,bird,removed,height,trim,y=min(choices,key=lambda p:(p[0],p[1]))
    tip=beak(bird)
    x=target[0]-tip[0]
    assert x>=2 and y>=2 and x+bird.width<=254 and y+bird.height<=254, label+' exceeds cell'
    frame=Image.new('RGBA',(256,256))
    frame.paste(bird,(x,y))
    assert sum((a-b)**2 for a,b in zip(beak(frame),target))<=4
    assert not grounded or frame.getbbox()[3]==bounds[3]
    record=dict(label=label,source_crop=crop_box,resize=[width,height],trim=trim,destination=[x,y],normal_beak=target,enraged_beak=beak(frame),normal_bounds=bounds,bounds=frame.getbbox(),grounded=grounded,detached_pixels_removed=removed)
    return frame,record

def pack():
    metadata=json.loads((ROOT/'data/gull_art.json').read_text())[ID]
    pilot=read(REF/'approved-pilot.png')
    assert pilot.size==(1024,512)
    normal=read(SPR/'gull-great-black-backed-diner-style.png')
    body_source=read(REF/'body-full-source.png')
    body=Image.new('RGBA',(1024,1280))
    body.paste(pilot,(0,0))
    records=[]
    body_frames=[]
    for i in range(8,20):
        raw,source_box=generated(body_source,i-8,4,3)
        frame,record=fit(raw,cell(normal,i,4),i in [17,18,19],f'body/{i}')
        record['source_cell']=source_box
        body.paste(frame,((i%4)*256,(i//4)*256))
        body_frames.append(frame)
        records.append(record)
    assert body.crop((0,0,1024,512)).tobytes()==pilot.tobytes()
    screech_source=read(REF/'screech-source.png')
    normal_screech=read(SPR/'gull-great-black-backed-screech-v1.png')
    screech=Image.new('RGBA',(768,512))
    screech_frames=[]
    for i in range(6):
        raw,source_box=generated(screech_source,i,3,2)
        frame,record=fit(raw,cell(normal_screech,i,3),True,f'screech/{i}')
        record['source_cell']=source_box
        screech.paste(frame,((i%3)*256,(i//3)*256))
        screech_frames.append(frame)
        records.append(record)
    carry_walk=read(REF/'carry-walk-source.png')
    carry_flight=read(REF/'carry-flight-source.png')
    normal_carry=read(SPR/'gull-great-black-backed-carry-v1.png')
    normal_upper=read(SPR/'gull-great-black-backed-carry-v1-upper-beak.png')
    carry=Image.new('RGBA',(3328,256))
    upper=Image.new('RGBA',(3328,256))
    # Original-size source cells are grouped without repainting/resizing; the
    # two untouched generator outputs remain alongside this source atlas.
    raw_cells=[generated(carry_walk,i,4,2)[0] for i in range(8)]+[generated(carry_flight,i,3,2)[0] for i in range(5)]
    raw_size=max(max(c.size) for c in raw_cells)
    raw_atlas=Image.new('RGBA',(raw_size*4,raw_size*4))
    carry_frames=[]
    uppers=[]
    for i,raw in enumerate(raw_cells):
        raw_atlas.paste(raw,((i%4)*raw_size,(i//4)*raw_size))
        frame,record=fit(raw,cell(normal_carry,i,13),i<8,f'carry/{i}')
        # Same contact window as the normal upper mandible: crop generated
        # pixels only, keeping the snack between body and upper-beak layers.
        rect=cell(normal_upper,i,13).getbbox()
        overlay=Image.new('RGBA',(256,256))
        overlay.paste(frame.crop(rect),(rect[0],rect[1]))
        assert overlay.getbbox(), f'carry/{i} upper beak empty'
        assert any(p[3]>128 and p[0]>160 and p[1]>100 and p[2]<130 for p in overlay.get_flattened_data()), f'carry/{i} no yellow upper bill'
        carry.paste(frame,(i*256,0))
        upper.paste(overlay,(i*256,0))
        record['upper_beak_crop']=rect
        records.append(record)
        carry_frames.append(frame)
        uppers.append(overlay)
    body.save(SPR/BODY)
    screech.save(SPR/SCREECH)
    carry.save(SPR/CARRY)
    upper.save(SPR/OVERLAY)
    raw_atlas.save(REF/'carry-full-source-atlas.png')
    (REF/'full-set-packing.json').write_text(json.dumps(dict(frames=records,carry_source_cell=raw_size,pilot='approved-pilot.png'),indent=2)+'\n')
    previews(metadata,normal,body_frames,normal_screech,screech_frames,normal_carry,carry_frames,normal_upper,uppers)
    for r in records: print(r['label'],r['normal_beak'],r['enraged_beak'],r['bounds'],'removed',r['detached_pixels_removed'])

FOODS=json.loads((ROOT/'data/foods.json').read_text())
SPRITES=json.loads((ROOT/'data/sprites.json').read_text())
def food_image(food_id):
    definition=FOODS[food_id]
    sprite=SPRITES[definition['sprite']]
    region=sprite['regions'][0]['region']
    source=read(ROOT/sprite['file'][6:])
    food=source.crop((region[0],region[1],region[0]+region[2],region[1]+region[3]))
    return food.resize(tuple(definition['size']),Image.Resampling.NEAREST)

def row(label,normal,enraged,grounded,carry=None,index=0,normal_upper=None,enraged_upper=None,food='hotdog'):
    canvas=Image.new('RGBA',(600,112),(139,194,215,255))
    draw=ImageDraw.Draw(canvas)
    draw.rectangle((0,94,600,112),fill=(225,201,148,255))
    draw.text((8,4),label,fill=(22,37,47,255))
    for centre,frame,scale,overlay in [(180,normal,.375,normal_upper),(330,enraged,.375,enraged_upper),(480,enraged,.46875,enraged_upper)]:
        origin=(centre,94-12*scale) if grounded else (centre,65)
        top=(round(origin[0]-128*scale),round(origin[1]-128*scale))
        size=(round(256*scale),)*2
        canvas.alpha_composite(frame.resize(size,Image.Resampling.NEAREST),top)
        if carry:
            clip='walk' if index<8 else 'fly' if index<12 else 'glide'
            local=index if index<8 else index-8 if index<12 else 0
            anchor=carry['beak_anchors'][clip][local]
            item=food_image(food)
            at=(round(origin[0]+anchor[0]*scale/.375-item.width/2),round(origin[1]+anchor[1]*scale/.375-item.height/2))
            canvas.alpha_composite(item,at)
            canvas.alpha_composite(overlay.resize(size,Image.Resampling.NEAREST),top)
    return canvas.convert('RGB')

def poster(name,rows):
    image=Image.new('RGB',(600,28+112*len(rows)),(240,235,221))
    draw=ImageDraw.Draw(image)
    for x,label in [(140,'Normal (0.375)'),(288,'Enraged (0.375)'),(430,'Shakedown (1.25x)')]:
        draw.text((x,8),label,fill=(22,37,47))
    for i,item in enumerate(rows): image.paste(item,(0,28+i*112))
    image.save(PRE/name)

def previews(metadata,normal,body_frames,normal_screech,screech_frames,normal_carry,carry_frames,normal_upper,uppers):
    body_rows=[row(f'Body cell {i}',cell(normal,i,4),frame,i>=17) for i,frame in enumerate(body_frames,8)]
    screech_rows=[row(f'Screech {i}'+(' - held peak' if i==4 else ''),cell(normal_screech,i,3),frame,True) for i,frame in enumerate(screech_frames)]
    carry_rows=[row(f'Carry {i} - body / food / upper beak',cell(normal_carry,i,13),frame,i<8,metadata['carry'],i,cell(normal_upper,i,13),uppers[i]) for i,frame in enumerate(carry_frames)]
    poster('gull-great-black-backed-enraged-full-body-v1.png',body_rows)
    poster('gull-great-black-backed-enraged-screech-v1.png',screech_rows)
    poster('gull-great-black-backed-enraged-carry-v1.png',carry_rows)
    food_rows=[row(f'{food} / carry {i}',cell(normal_carry,i,13),carry_frames[i],i<8,metadata['carry'],i,cell(normal_upper,i,13),uppers[i],food) for food in ['single_chip','ice_cream','hotdog'] for i in [7,8,12]]
    poster('gull-great-black-backed-enraged-carry-layering-v1.png',food_rows)
    body_rows[0].save(PRE/'gull-great-black-backed-enraged-fly-v1.gif',save_all=True,append_images=body_rows[1:4],duration=100,loop=0,disposal=2)
    screech_rows[0].save(PRE/'gull-great-black-backed-enraged-screech-v1.gif',save_all=True,append_images=screech_rows[1:],duration=[140,140,150,140,500,140],loop=0,disposal=2)
    carry_rows[0].save(PRE/'gull-great-black-backed-enraged-carry-walk-v1.gif',save_all=True,append_images=carry_rows[1:8],duration=[120,130]*4,loop=0,disposal=2)

def add_members(text,key,members):
    decoder=json.JSONDecoder()
    start=text.index(json.dumps(ID))
    entry_start=text.index('{',start)
    if key:
        opening=text.index('{',text.index(json.dumps(key),entry_start))
    else:
        opening=entry_start
    value,length=decoder.raw_decode(text[opening:])
    close=opening+length-1
    new={k:v for k,v in members.items() if k not in value}
    assert all(k not in value or value[k]==v for k,v in members.items())
    if not new: return text
    indent='      ' if key else '    '
    payload=',\n'+',\n'.join(indent+json.dumps(k)+': '+json.dumps(v,separators=(',',': ')) for k,v in new.items())+'\n'+('    ' if key else '  ')
    return text[:close].rstrip()+payload+text[close:]

def register():
    base=json.loads((ROOT/'data/gull_art.json').read_text())[ID]
    carry=copy.deepcopy(base['carry'])
    carry.update(file='res://assets/sprites/'+CARRY,overlay_file='res://assets/sprites/'+OVERLAY,source='res://assets/reference/gull-great-black-backed-enraged-v1/carry-full-source-atlas.png')
    for name in ['gull_art','sprites']:
        path=ROOT/f'data/{name}.json'
        text=path.read_text()
        original=json.loads(subprocess.check_output(['git','show','HEAD:data/'+name+'.json'],cwd=ROOT))
        snapshot=REF/f'baseline-{name}-entry.json'
        if not snapshot.exists(): snapshot.write_text(json.dumps(original[ID],indent=2)+'\n')
        members={}
        current=json.loads(text)[ID]
        for clip in CLIPS:
            details=copy.deepcopy(current['animations'][clip])
            details['file']='res://assets/sprites/'+(SCREECH if clip=='screech' else BODY)
            members[clip+'_enraged']=details
        text=add_members(text,'animations',members)
        text=add_members(text,None,{'carry_enraged':carry})
        compare=json.loads(text)
        for key in members: compare[ID]['animations'].pop(key,None)
        compare[ID].pop('carry_enraged',None)
        original=copy.deepcopy(original)
        for key in members: original[ID]['animations'].pop(key,None)
        original[ID].pop('carry_enraged',None)
        assert compare==original,'Pre-existing registry values changed'
        path.write_text(text)
    print('Registered 11 clip twins and carry_enraged in both registries; existing values unchanged.')

if __name__=='__main__':
    pack()
    if '--register' in sys.argv: register()
