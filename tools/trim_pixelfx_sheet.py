"""Trim a pixelfx sprite sheet: python tools/trim_pixelfx_sheet.py SRC_BASE DST.png ALPHA_THRESHOLD [MAX_FRAMES]

SRC_BASE is the rendered sheet without extension (SRC_BASE.png + SRC_BASE.json from
`node tools/render.mjs <id> --sheet --no-actor` in https://github.com/patch-gg/pixelfx, commit a841596).
Drops empty tail frames (max alpha below ALPHA_THRESHOLD, e.g. 40), crops every frame to the shared used area,
repacks into a 7-column grid and prints frame count, frame size and the new pivot for data/sprites.json.
"""
import json,sys
from PIL import Image
src,dst,thr=sys.argv[1],sys.argv[2],int(sys.argv[3])
j=json.load(open(src+'.json'));m=j['meta']['pixelfx']
fw,fh=m['frameSize'];cols=m['columns'];px,py=m['pivot'];n=m['frames']
im=Image.open(src+'.png').convert('RGBA')
fr=[im.crop(((i%cols)*fw,(i//cols)*fh,(i%cols)*fw+fw,(i//cols)*fh+fh)) for i in range(n)]
alpha=[f.getchannel('A') for f in fr]
last=max(i for i,a in enumerate(alpha) if a.getextrema()[1]>=thr)
keep=fr[:min(last+1,int(sys.argv[4]) if len(sys.argv)>4 else 999)]
bb=None
for f in keep:
    b=f.getchannel('A').point(lambda v:255 if v>=8 else 0).getbbox()
    if b: bb=b if bb is None else (min(bb[0],b[0]),min(bb[1],b[1]),max(bb[2],b[2]),max(bb[3],b[3]))
w,h=bb[2]-bb[0],bb[3]-bb[1];c=min(7,len(keep));rows=-(-len(keep)//c)
out=Image.new('RGBA',(c*w,rows*h))
for i,f in enumerate(keep): out.paste(f.crop(bb),((i%c)*w,(i//c)*h))
out.save(dst)
print(dst,'frames',len(keep),'frame',w,h,'pivot',px-bb[0],py-bb[1],'cols',c)
