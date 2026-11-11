"""Repacks sunbather sunglasses-check frames (atlas cells 88-92) at the same 1-source-pixel detail as the rest frames.
Reads assets/reference/sunbather-sunglasses-v2 sources; writes *-packed.png there and into the 4 atlases. Edit M/R paths if moved."""
import numpy as np
from PIL import Image
R='C:/Users/david/Documents/ChatGPT/GullinIt-main/assets/reference/sunbather-sunglasses-v2/'
ENV={'male':(88,34),'female':(98,36)}
def trim(im,t=128):
    a=np.array(im)[...,3]; ys,xs=np.where(a>=t); return im.crop((xs.min(),ys.min(),xs.max()+1,ys.max()+1))
def segs(im):
    col=(np.array(im)[...,3]>40).any(0); out=[];st=None
    for x,v in enumerate(col):
        if v and st is None: st=x
        if not v and st is not None: out.append((st,x));st=None
    return out
def fit(im,size,method):
    a=np.array(im).astype(np.float32); al=a[...,3:4]/255
    pm=np.concatenate([a[...,:3]*al,a[...,3:]],2)
    chans=[Image.fromarray(pm[...,i]).resize(size,method) for i in range(4)]
    o=np.stack([np.array(c) for c in chans],2)
    A=o[...,3:4]; rgb=np.where(A>0,o[...,:3]/np.maximum(A/255,1e-3),0)
    hard=(A>=128)
    out=np.concatenate([np.clip(rgb,0,255)*hard,hard*255],2).astype(np.uint8)
    return Image.fromarray(out,'RGBA')
def frames(sex,method=Image.LANCZOS,grid=1):
    s=Image.open(R+f'{sex}-red-source.png').convert('RGBA'); sg=segs(s)
    srcs=[s.crop((a,0,b,s.height)) for a,b in sg]
    srcs=[srcs[0],srcs[1],Image.open(R+f'{sex}-left-source.png').convert('RGBA'),Image.open(R+f'{sex}-right-source.png').convert('RGBA'),srcs[4]]
    W,H=ENV[sex]; out=[]
    for im in srcs:
        t=trim(im); f=fit(t,(W//grid,H//grid),method)
        if grid>1: f=f.resize((W,H),Image.NEAREST)
        out.append(f)
    return out
import shutil, colorsys
from PIL import ImageFilter
M='C:/Users/david/Documents/ChatGPT/GullinIt-main/'
OFF={'male':(20,82),'female':(15,80)}
def post(im):
    a=im.split()[3]; rgb=im.convert('RGB').filter(ImageFilter.UnsharpMask(radius=0.8,percent=150,threshold=0))
    rgb=rgb.quantize(48,method=Image.MEDIANCUT,dither=Image.NONE).convert('RGBA'); rgb.putalpha(a); return rgb
def red_cloth(r,g,b):
    r,g,b=r/255,g/255,b/255; h,s,v=colorsys.rgb_to_hsv(r,g,b)
    return r>0.35 and r>g*1.65 and b>g*0.75 and (h<0.035 or h>0.93)
def blue(im):
    a=np.array(im).copy(); H,W=a.shape[:2]
    m=np.zeros((H,W),bool)
    for y in range(H):
        for x in range(W):
            if a[y,x,3]>250 and red_cloth(*a[y,x,:3]): m[y,x]=True
    seen=np.zeros_like(m)
    for y in range(H):
        for x in range(W):
            if m[y,x] and not seen[y,x]:
                q=[(y,x)];seen[y,x]=True;i=0
                while i<len(q):
                    cy,cx=q[i];i+=1
                    for dy,dx in((0,1),(0,-1),(1,0),(-1,0)):
                        ny,nx=cy+dy,cx+dx
                        if 0<=ny<H and 0<=nx<W and m[ny,nx] and not seen[ny,nx]: seen[ny,nx]=True;q.append((ny,nx))
                if len(q)>=8:
                    for cy,cx in q:
                        r,g,b=a[cy,cx,:3]/255; h,s,v=colorsys.rgb_to_hsv(r,g,b)
                        a[cy,cx,:3]=[round(c*255) for c in colorsys.hsv_to_rgb(0.59,s*0.78,min(1,v*0.83+0.04))]
    return Image.fromarray(a,'RGBA')
for sex in ('male','female'):
    red=[post(f) for f in frames(sex,Image.LANCZOS,1)]
    strips={'red':red,'blue':[blue(f) for f in red]}
    for col,fr in strips.items():
        strip=Image.new('RGBA',(640,128),(0,0,0,0))
        for i,f in enumerate(fr): strip.paste(f,(i*128+OFF[sex][0],OFF[sex][1]))
        strip.save(R+f'{sex}-{col}-packed.png')
        p=M+f'assets/sprites/retro-sunbather-{sex}-{col}-32bit.png'
        pass
        at=Image.open(p).convert('RGBA')
        at.paste(Image.new('RGBA',(640,128),(0,0,0,0)),(0,11*128))
        at.alpha_composite(strip,(0,11*128)) if False else at.paste(strip,(0,11*128))
        at.save(p); print(sex,col,'ok')
