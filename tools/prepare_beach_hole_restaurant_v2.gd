extends SceneTree
const SRC="res://assets/reference/pier-restaurant-props-v1/beach-hole-restaurant-v2-source.png"
const OUT="res://assets/lab/pier-restaurant-props-v1/beach-hole-restaurant-v2.png"
const NAVY=Color8(24,59,78)
const P=[
Color8(24,59,78),Color8(40,102,123),Color8(64,143,168),Color8(75,136,183),
Color8(97,119,130),Color8(142,155,158),Color8(117,74,57),Color8(155,102,80),
Color8(170,112,71),Color8(185,77,78),Color8(213,154,94),Color8(198,154,104),
Color8(238,183,127),Color8(232,197,142),Color8(239,114,92),Color8(255,244,218),
Color8(232,79,24),Color8(247,137,32),Color8(229,174,51),Color8(117,137,61),
Color8(48,105,70),Color8(92,55,32),Color8(193,109,39),Color8(245,216,128)]
func _init():
 var src=Image.load_from_file(SRC)
 if src.is_empty():
  push_error("missing source")
  quit(1)
  return
 var out=Image.create(132,88,false,Image.FORMAT_RGBA8)
 out.fill(Color(0,0,0,0))
 for ty in range(86):
  for tx in range(130):
   var sx0=4+int(floor(float(tx)*1527.0/130.0))
   var sx1=4+int(ceil(float(tx+1)*1527.0/130.0))
   var sy0=238+int(floor(float(ty)*557.0/86.0))
   var sy1=238+int(ceil(float(ty+1)*557.0/86.0))
   var counts=[]
   counts.resize(P.size())
   counts.fill(0)
   var opaque=0
   var total=max(1,(sx1-sx0)*(sy1-sy0))
   for sy in range(sy0,sy1):
    for sx in range(sx0,sx1):
     var c=src.get_pixel(sx,sy)
     if c.a>=0.5:
      opaque+=1
      counts[nearest(c)]+=1
   if opaque>=max(1,int(ceil(total*0.35))):
    var best=0
    for i in range(1,counts.size()):
     if counts[i]>counts[best]:
      best=i
    out.set_pixel(1+tx,1+ty,P[best])
 for pass_index in range(2):
  out=clean(out)
 var err=out.save_png(OUT)
 if err!=OK:
  push_error("save failed "+str(err))
  quit(1)
  return
 metrics(out)
 quit()
func nearest(c):
 var bi=0
 var bd=INF
 for i in range(P.size()):
  var q=P[i]
  var d=(c.r-q.r)*(c.r-q.r)+(c.g-q.g)*(c.g-q.g)+(c.b-q.b)*(c.b-q.b)
  if d<bd:
   bd=d
   bi=i
 return bi
func clean(img):
 var result=img.duplicate()
 for y in range(1,img.get_height()-1):
  for x in range(1,img.get_width()-1):
   var c=img.get_pixel(x,y)
   if c.a==0 or c.is_equal_approx(NAVY):
    continue
   var ns=[img.get_pixel(x-1,y),img.get_pixel(x+1,y),img.get_pixel(x,y-1),img.get_pixel(x,y+1)]
   var same=0
   for n in ns:
    if n.is_equal_approx(c):
     same+=1
   if same>0:
    continue
   var replacement=Color(0,0,0,0)
   var best=0
   for candidate in ns:
    if candidate.a==0:
     continue
    var count=0
    for n in ns:
     if n.is_equal_approx(candidate):
      count+=1
    if count>best:
     best=count
     replacement=candidate
   if best>=2:
    result.set_pixel(x,y,replacement)
 return result
func metrics(img):
 var colors={}
 var opaque=0
 var isolated=0
 var minx=img.get_width()
 var miny=img.get_height()
 var maxx=-1
 var maxy=-1
 for y in range(img.get_height()):
  for x in range(img.get_width()):
   var c=img.get_pixel(x,y)
   if c.a==0:
    continue
   opaque+=1
   colors[c.to_html(false)]=true
   minx=min(minx,x)
   miny=min(miny,y)
   maxx=max(maxx,x)
   maxy=max(maxy,y)
   if c.is_equal_approx(NAVY):
    continue
   var same=false
   for o in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    var nx=x+o.x
    var ny=y+o.y
    if nx>=0 and ny>=0 and nx<img.get_width() and ny<img.get_height() and img.get_pixel(nx,ny).is_equal_approx(c):
     same=true
   if not same:
    isolated+=1
 print("Beach Hole v2 canvas=132x88 extents=%dx%d bbox=(%d,%d)-(%d,%d) colors=%d opaque=%d isolated=%d share=%.2f%%" % [maxx-minx+1,maxy-miny+1,minx,miny,maxx,maxy,colors.size(),opaque,isolated,100.0*isolated/max(1,opaque)])
