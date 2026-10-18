"""Build aligned atlases from original generated sheets; do not edit image pixels."""
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parent.parent
path = ROOT/'data/sprites.json'
data = json.loads(path.read_text(encoding='utf-8-sig'))
def anim(frames, fps=7, loop=True):
    return dict(frames=frames,fps=fps,loop=loop)
for key, filename, canvas, scale, centers, baselines in [
    ('kiosk_customer','customer-polished.png',(400,500),.085,
     [200,600,998,1400,200,596,996,1380],[474]*4+[980]*4),
    ('dog','dog-owner-polished.png',(600,460),.09,
     [180,630,1072,1518,180,623,1055,1500],[430]*4+[865]*4),
]:
    image = Image.open(ROOT/'assets/sprites'/filename)
    regions = []
    for index in range(8):
        col,row=index%4,index//4
        left,top=round(col*image.width/4),round(row*image.height/2)
        right,bottom=round((col+1)*image.width/4),round((row+1)*image.height/2)
        cell=image.crop((left,top,right,bottom))
        box=cell.getchannel('A').point(lambda a:255 if a>=178 else 0).getbbox()
        x,y=left+box[0],top+box[1]
        regions.append(dict(region=[x,y,box[2]-box[0],box[3]-box[1]],
            offset=[canvas[0]/2+x-centers[index],canvas[1]+y-baselines[index]]))
    animations=dict(walk=anim([0,1,2,3]),idle=anim([4],1),alert=anim([5],1))
    if key=='dog':
        animations.update(bark=anim([5,6,6,5],6),angry=anim([7],1))
        anchors=dict(walk=[[10,-28]]*4,idle=[[9,-27]],alert=[[10,-27]],
            bark=[[10,-27],[9,-29],[9,-29],[10,-27]],angry=[[10,-28]])
    else:
        animations['angry']=anim([7,6,6],6,False)
        anchors=dict(walk=[[10,-26],[10,-26],[11,-26],[11,-26]],
            idle=[[11,-27]],alert=[[11,-27]],angry=[[11,-27]]*3)
    data[key]=dict(file='res://assets/sprites/'+filename,frame_w=canvas[0],frame_h=canvas[1],
        visual_scale=scale,regions=regions,animations=animations,food_anchors=anchors)
path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print('Mapped customer and dog-owner sheets without altering source pixels.')
