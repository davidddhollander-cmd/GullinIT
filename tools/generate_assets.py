"""Reproducible, original placeholder pixels, bitmap font, audio and game data.
Only Python's standard library is required. Run from any working directory.
"""
from pathlib import Path
import json, math, random, struct, wave, zlib
ROOT = Path(__file__).resolve().parents[1]
def write(path, text):
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding='utf-8')
def data(path, value): write('data/' + path + '.json', json.dumps(value, indent=2))
PALETTE = {'ink':'183b4e','white':'fff4da','grey':'8aabb3','blue':'408fa8','skin':'eeb77f','yellow':'ffc65c','red':'ef725c','brown':'9b6650','teal':'56b7ae'}
def rgb(name):
    h = PALETTE.get(name, name)
    return tuple(int(h[i:i+2],16) for i in (0,2,4)) + (255,)
class Canvas:
    def __init__(self,w,h): self.w,self.h,self.p=w,h,bytearray(w*h*4)
    def rect(self,x,y,w,h,c):
        for yy in range(max(0,int(y)),min(self.h,int(y+h))):
            for xx in range(max(0,int(x)),min(self.w,int(x+w))):
                i=(yy*self.w+xx)*4; self.p[i:i+4]=bytes(rgb(c))
    def save(self,path):
        def chunk(k,v): return struct.pack('!I',len(v))+k+v+struct.pack('!I',zlib.crc32(k+v)&0xffffffff)
        raw=b''.join(b'\0'+self.p[y*self.w*4:(y+1)*self.w*4] for y in range(self.h))
        p=ROOT/path; p.parent.mkdir(parents=True,exist_ok=True)
        p.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',self.w,self.h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
manifest={}
gull_anims={'fly':4,'glide':1,'climb':4,'dive_windup':2,'dive':1,'snatch':2,'pullup':2,'stunned':4}
entities={
 'player_gull':(24,16,gull_anims), 'rival_gull':(24,16,gull_anims),
 'sunbather':(32,16,{'idle':2,'eat':2,'angry':2}),
 'toddler':(16,20,{'walk':4,'eat':2,'cry':2}),
 'parent':(16,32,{'idle':2,'alert':1,'shield':1,'swat':3}),
 'dog':(24,16,{'idle':2,'look_up':1,'jump':3}),
 'kiosk_customer':(16,32,{'walk':4}), 'pier_diner':(16,24,{'eat':2,'swat':3}),
 'lifeguard':(16,32,{'walk':4,'whistle':2}), 'seafood_vendor':(16,32,{'idle':2,'windup':2,'swat':2})}
for key,(w,h,anims) in entities.items():
    count=sum(anims.values()); c=Canvas(w*count,h); entries={}; index=0
    for name,n in anims.items():
        entries[name]={'frames':list(range(index,index+n)),'fps':8,'loop':name not in ['dive','swat','snatch']}
        for f in range(n):
            ox=index*w
            def r(x,y,ww,hh,col): c.rect(ox+x,y,ww,hh,col)
            if 'gull' in key:
                body='white' if key=='player_gull' else 'grey'
                r(3,8,17,6,'ink'); r(5,7,13,6,body); r(15,4,6,7,'ink'); r(16,4,5,6,body)
                r(20,8,4,2,'yellow'); r(18,5,1,1,'ink'); r(1,7,5,3,body)
                wy=2+(f%3)*2 if name in ['fly','climb'] else 6
                r(8,wy,4,8,'ink'); r(9,wy,3,7,body); r(11,12,3,2,'yellow')
                if key=='rival_gull': r(15,3,6,2,'red')
            elif key=='dog':
                r(3,6,16,8,'ink'); r(4,6,14,6,'brown'); r(17,2,6,9,'brown'); r(20,4,1,1,'ink'); r(4,12,3,4,'ink'); r(14,12,3,4,'ink'); r(1,2,3,6,'brown')
            elif key=='sunbather':
                r(0,12,32,4,'red'); r(3,7,23,6,'ink'); r(4,7,20,4,'blue'); r(23,4,7,7,'skin'); r(24,5,6,2,'ink'); r(2,5,14,2,'white')
            else:
                cx=w//2; shift=(f%2) if name=='walk' else 0
                r(cx-4,1,8,8,'ink'); r(cx-3,2,6,6,'skin'); r(cx+2,4,1,1,'ink')
                shirt='red' if key in ['lifeguard','seafood_vendor'] else 'blue'
                r(cx-5,9,10,h-15,'ink'); r(cx-4,9,8,h-16,shirt)
                r(cx-4,h-7,3,6-shift,'ink'); r(cx+1,h-7,3,6+shift,'ink')
                r(cx-7,11,3,7,'skin'); r(cx+4,9 if name in ['swat','windup'] else 12,3,7,'skin')
                if key=='seafood_vendor': r(2,0,12,3,'white')
                if key=='lifeguard': r(2,0,12,3,'yellow')
            index+=1
    c.save('assets/sprites/'+key+'.png')
    manifest[key]={'file':'res://assets/sprites/'+key+'.png','frame_w':w,'frame_h':h,'animations':entries}
for key in ['chips','ice_cream','sandwich','hot_dog','cone','fish_chips','seafood']:
    c=Canvas(8,8); c.rect(0,2,8,5,'ink'); c.rect(1,2,6,4,'yellow'); c.rect(2,1,4,2,'white'); c.rect(2,5,4,1,'red')
    c.save('assets/sprites/'+key+'.png'); manifest[key]={'file':'res://assets/sprites/'+key+'.png','frame_w':8,'frame_h':8,'animations':{'idle':{'frames':[0],'fps':1,'loop':True}}}
for key,w,h in [('umbrella',32,24),('bin',12,16),('kiosk',48,40),('tower',32,48),('pier',64,40)]:
    c=Canvas(w,h)
    if key=='umbrella':
        c.rect(15,6,2,18,'brown'); c.rect(2,7,28,3,'ink'); c.rect(5,4,22,4,'red'); c.rect(10,1,12,4,'yellow'); c.rect(14,0,4,8,'white')
    elif key=='bin':
        c.rect(1,2,10,14,'ink'); c.rect(2,4,8,10,'teal'); c.rect(0,1,12,3,'brown'); c.rect(4,5,1,8,'ink'); c.rect(7,5,1,8,'ink')
    elif key=='kiosk':
        c.rect(4,5,40,35,'brown'); c.rect(7,12,34,16,'ink'); c.rect(2,4,44,7,'red'); c.rect(0,0,48,5,'white')
        for x in range(2,48,10): c.rect(x,0,5,10,'yellow')
        c.rect(2,28,44,3,'yellow'); c.rect(10,34,28,3,'skin')
    elif key=='tower':
        c.rect(4,16,3,32,'brown'); c.rect(25,16,3,32,'brown'); c.rect(0,2,32,3,'red'); c.rect(3,5,26,17,'white'); c.rect(6,7,20,10,'blue'); c.rect(0,21,32,3,'brown')
        for y in range(27,48,5): c.rect(10,y,12,2,'brown')
    else:
        c.rect(0,0,64,7,'brown'); c.rect(0,0,64,2,'skin')
        for x in [5,30,55]: c.rect(x,7,5,33,'brown')
    c.save('assets/sprites/'+key+'.png'); manifest[key]={'file':'res://assets/sprites/'+key+'.png','frame_w':w,'frame_h':h,'animations':{'idle':{'frames':[0],'fps':1,'loop':True}}}
# Preserve curated gull art when rebuilding the placeholder assets.
if (ROOT / 'data/gull_art.json').exists():
    manifest.update(json.loads((ROOT / 'data/gull_art.json').read_text(encoding='utf-8')))
if (ROOT / 'data/food_art.json').exists():
    manifest.update(json.loads((ROOT / 'data/food_art.json').read_text(encoding='utf-8')))
if (ROOT / 'data/toddler_art.json').exists():
    manifest.update(json.loads((ROOT / 'data/toddler_art.json').read_text(encoding='utf-8')))
if (ROOT / 'data/pier_diner_art.json').exists():
    manifest.update(json.loads((ROOT / 'data/pier_diner_art.json').read_text(encoding='utf-8')))
data('sprites',manifest)
data('tuning',{
 'flight':{'acceleration': 400, 'max_speed': 140, 'gravity': 75, 'stroke_lift': 36, 'stroke_duration': 0.1, 'stroke_interval': 0.3, 'descent_drag': 90, 'max_climb': 70, 'min_y': 20, 'cursor_radius': 60, 'aim_deadzone': 4, 'max_descent': 45, 'ground_speed': 28, 'feet_offset': 6, 'takeoff_speed': 45, 'coast_drag': 8, 'landing_aim_width': 36, 'landing_aim_ratio': 0.5, 'landing_alignment': 3, 'landing_side_speed': 45, 'landing_speed': 70, 'landing_touchdown_speed': 12, 'landing_slowdown': 3, 'landing_acceleration': 180},
 'dive':{"windup":0.15,"cooldown":0.4,"stun":1.5,"invulnerability":1.0,"beak_w":8,"beak_h":6,"beak_offset":10,"umbrella_angle":45,"start_speed":65,"acceleration":260,"turn_rate":5.5,"drag":15,"exit_speed":20,"aim_deadzone":8,"max_speed":340,"uphill_deceleration":420,"uphill_drag":75,"crash_vertical_speed":170,"warning_risk":0.7,"warning_time":0.65},
 'wind':{"drift":40,"gust_min":6,"gust_max":12,"warning":1,"ramp":0.5,"hold":1.5,"multiplier":1.6,"response":1.8,"lift_ref":0.6,"lift_gravity_cut":0.3,"lift_descent_cut":0.3,"dive_drag":0.2,"dive_tailwind":220,"dive_headwind_drag":0.8,"flap_tail":0.5,"flap_min":0.5,"flap_max":1.35},
 'score':{'combo_window': 3, 'tiers': [1, 1.5, 2, 2.5, 3], 'risky': 0.5, 'upwind': 0.2, 'mugged': 0.5, 'clean': 0.1, 'casual_items': 15},
 'world':{'width': 960, 'ground': 160, 'camera_lerp': 0.15, 'start_x': 40, 'start_y': 75, 'food_offset_x': 10, 'food_offset_y': -14, 'respawn_min': 6, 'respawn_max': 10, 'depart_thefts': 2, 'walk_speed': 9, 'replacement_delay': 2, 'intro_time': 2, 'shield_time': 2, 'recover_time': 3, 'suspicious': 0.4, 'alert_decay': 0.2, 'front_multiplier': 1.5, 'dog_delay': 0.5, 'dog_overhead': 40, 'dog_altitude': 130, 'whistle_radius': 120, 'whistle_trigger': 80, 'kiosk_rate': 6, 'max_targets': 18, 'scrap_spacing': 75, 'scrap_respawn': 18, 'family_crisp_bags': 2, 'family_cookie_reserve': 2, 'family_seek_speed': 22, 'toddler_cry_duration': 0.6, 'toddler_run_speed': 42, 'toddler_run_acceleration': 55, 'family_handover_distance': 14, 'family_handover_pause': 0.65, 'family_ice_cream_chance': 0.22, 'family_gather_pause': 0.35, 'family_gather_distance': 24, 'family_follow_spacing': 12, 'family_trip_speed': 20, 'family_purchase_pause': 0.45, 'family_retreat_distance': 90, 'family_retry_wait': 8, 'sunbather_stash_size': 3, 'peck_reach': 16, 'peck_cooldown': 0.18, 'peck_alert': 0.2, 'stash_pecks': 3, 'stash_burst': 2, 'stash_snacks': ['single_chip', 'cookie', 'crisps_bag'], 'stash_wake_delay': 4.0, 'stash_wake_min': 0.4, 'stash_gravity': 160, 'stash_pickup_delay': 0.3, 'stash_retrieve_speed': 40, 'stash_swat_reach': 20, 'stash_swat_cooldown': 1.4, 'beach_min_x':24, 'beach_max_x':300, 'beach_scatter_max_x':308, 'bin_stash_size':9, 'bin_pecks':4, 'bin_burst':3, 'bin_scatter':['crumbs','wrapper','half_eaten_doughnut','paper','half_eaten_sandwich','crumbs','wrapper','half_eaten_pizza','paper']},
 'rival':{'search_radius':200,'dive_range':75,'leave_time':4,'mug_window':0.5,'mug_stun':1,'cruise_y':65},
 'juice':{'audio':True,'shine':True,'shine_cycle':2.6,'shine_step':0.08,'hitstop':True,'shake':True,'particles':True,'floating_text':True,'speed_lines':True,'near_miss':True,'snatch_stop':0.06,'stun_stop':0.1,'snatch_shake':2,'stun_shake':4,'near_distance':6,'slow_time':0.25,'slow_scale':0.5,'float_time':1.3,'feathers':8}
})
types=[('sunbather','sunbather','chips',10,42,0.25,'sleep',0),('toddler','toddler','ice_cream',15,45,0.4,'cry',0),('picnic_family','parent','sandwich',20,65,0.8,'shield',20),('dog_owner','dog','hot_dog',25,65,0.7,'dog',23),('kiosk_customer','kiosk_customer','cone',15,45,0.5,'walk',0),('pier_diner','pier_diner','fish_chips',30,70,0.8,'umbrella',20),('lifeguard','lifeguard','',0,80,0.8,'whistle',0),('seafood_vendor','seafood_vendor','seafood',50,85,1,'broom',30)]
data('targets',{'sunbather': {'sprite': 'sunbather', 'awareness': 42, 'rise': 0.25, 'altitude': 115, 'twist': 'sleep', 'danger': 0, 'windup': 0.6, 'zone': 0, 'foods': []}, 'toddler': {'sprite': 'toddler', 'awareness': 45, 'rise': 0.4, 'altitude': 115, 'twist': 'cry', 'danger': 0, 'windup': 0.6, 'zone': 0, 'foods': ['ice_cream']}, 'picnic_family': {'sprite': 'parent', 'awareness': 65, 'rise': 0.8, 'altitude': 115, 'twist': 'shield', 'danger': 20, 'windup': 0.6, 'zone': 0, 'foods': ['crisps_bag', 'crisps_box']}, 'dog_owner': {'sprite': 'dog', 'awareness': 65, 'rise': 0.7, 'altitude': 115, 'twist': 'dog', 'danger': 23, 'windup': 0.6, 'zone': 1, 'foods': ['hotdog']}, 'kiosk_customer': {'sprite': 'kiosk_customer', 'awareness': 45, 'rise': 0.5, 'altitude': 115, 'twist': 'walk', 'danger': 0, 'windup': 0.6, 'zone': 1, 'foods': ['ice_cream', 'crisps_box', 'crisps_bag']}, 'pier_diner': {'sprite': 'pier_diner', 'awareness': 70, 'rise': 0.8, 'altitude': 115, 'twist': 'umbrella', 'danger': 20, 'windup': 0.6, 'zone': 2, 'foods': ['fried_fish']}, 'lifeguard': {'sprite': 'lifeguard', 'awareness': 80, 'rise': 0.8, 'altitude': 115, 'twist': 'whistle', 'danger': 0, 'windup': 0.6, 'zone': 2, 'foods': []}, 'seafood_vendor': {'sprite': 'seafood_vendor', 'awareness': 85, 'rise': 1, 'altitude': 115, 'twist': 'broom', 'danger': 30, 'windup': 0.6, 'zone': 2, 'foods': ['fried_fish']}})
data('quips',{'snatch':['SORRY NOT SORRY','BEAK SERVICE!','MINE, ACTUALLY.','FIVE-STAR LUNCH','NO RECEIPT.','FRESH TAKEAWAY!'],'rivals':['Best seagull simulator. I am a seagull. - Gary','The food is free if you are fast enough. - Chip','Five stars. Zero manners. - Bev']})
names=['Morning calm','Sea breeze','Dog day','Ice cream rush','Pier patrol','Sunset showdown']
starsets=[[150,250,350],[250,400,550],[350,550,750],[450,700,950],[550,850,1150],[700,1050,1400]]
for n in range(1,7):
    spawns=[{'type':'sunbather','x':80},{'type':'toddler','x':155},{'type':'sunbather','x':245},{'type':'toddler','x':345},{'type':'sunbather','x':445},{'type':'toddler','x':550},{'type':'sunbather','x':665},{'type':'toddler','x':765},{'type':'sunbather','x':885}]
    if n>=2:
        spawns[2]['type']='picnic_family'; spawns[4]['type']='picnic_family'
    else:
        spawns[2]['type']='picnic_family'; spawns[6]['type']='picnic_family'
    if n>=3: spawns[3]['type']='dog_owner'
    if n>=4: spawns[5]['type']='kiosk_customer'
    if n>=5:
        spawns[6]={'type':'pier_diner','x':700}; spawns[7]={'type':'lifeguard','x':790}
    if n>=6: spawns[8]['type']='seafood_vendor'
    parents=[spawn for spawn in spawns if spawn['type']=='picnic_family']
    toddlers=[spawn for spawn in spawns if spawn['type']=='toddler']
    for index,parent in enumerate(parents): parent['family_id']='family_%d'%(index+1)
    for index,toddler in enumerate(toddlers): toddler['family_id']='family_%d'%(min(index*len(parents)//len(toddlers),len(parents)-1)+1)
    rivals=[{'name':name,'speed':0.8,'accuracy_px':err} for name,err in [('Gary',16),('Chip',10),('Bev',4)]][:max(0,n-3) if n>3 else (1 if n==3 else 0)]
    sand_slots=[80,180,285]
    for index,sunbather in enumerate([spawn for spawn in spawns if spawn['type']=='sunbather']):
        sunbather['x']=sand_slots[index]
        sunbather['appearance']=['male_red','female_blue','female_red','male_blue'][(n-1+index)%4]
    data('levels/level_%02d'%n,{'id':n,'name':names[n-1],'seed':7100+n,'time_limit':75 if n<3 else (80 if n<5 else 90),'wind':{'dir':[0,1,-1,1,-1,1][n-1],'strength':[0,.3,.3,.5,.5,.65][n-1],'gusts':n>=4,'flip':n==6},'awareness_mult':1+(n-1)*.08,'stars':starsets[n-1],'rivals':rivals,'spawns':spawns,'props':[{'type':'bin','x':305},{'type':'kiosk','x':520},{'type':'tower','x':815}]+([{'type':'umbrella','x':710}] if n>=5 else [])})
# A tiny original 5x7 bitmap font, encoded as BDF for Godot's bitmap importer.
glyphs={
'A':['01110','10001','10001','11111','10001','10001','10001'],'B':['11110','10001','10001','11110','10001','10001','11110'],'C':['01111','10000','10000','10000','10000','10000','01111'],'D':['11110','10001','10001','10001','10001','10001','11110'],'E':['11111','10000','10000','11110','10000','10000','11111'],'F':['11111','10000','10000','11110','10000','10000','10000'],'G':['01111','10000','10000','10111','10001','10001','01111'],'H':['10001','10001','10001','11111','10001','10001','10001'],'I':['111','010','010','010','010','010','111'],'J':['00111','00010','00010','00010','10010','10010','01100'],'K':['10001','10010','10100','11000','10100','10010','10001'],'L':['10000','10000','10000','10000','10000','10000','11111'],'M':['10001','11011','10101','10101','10001','10001','10001'],'N':['10001','11001','11001','10101','10011','10011','10001'],'O':['01110','10001','10001','10001','10001','10001','01110'],'P':['11110','10001','10001','11110','10000','10000','10000'],'Q':['01110','10001','10001','10001','10101','10010','01101'],'R':['11110','10001','10001','11110','10100','10010','10001'],'S':['01111','10000','10000','01110','00001','00001','11110'],'T':['11111','00100','00100','00100','00100','00100','00100'],'U':['10001','10001','10001','10001','10001','10001','01110'],'V':['10001','10001','10001','10001','10001','01010','00100'],'W':['10001','10001','10001','10101','10101','11011','10001'],'X':['10001','10001','01010','00100','01010','10001','10001'],'Y':['10001','10001','01010','00100','00100','00100','00100'],'Z':['11111','00001','00010','00100','01000','10000','11111'],
'0':['01110','10001','10011','10101','11001','10001','01110'],'1':['010','110','010','010','010','010','111'],'2':['01110','10001','00001','00010','00100','01000','11111'],'3':['11110','00001','00001','01110','00001','00001','11110'],'4':['00010','00110','01010','10010','11111','00010','00010'],'5':['11111','10000','10000','11110','00001','00001','11110'],'6':['01110','10000','10000','11110','10001','10001','01110'],'7':['11111','00001','00010','00100','01000','01000','01000'],'8':['01110','10001','10001','01110','10001','10001','01110'],'9':['01110','10001','10001','01111','00001','00001','01110'],
' ':['000']*7,'.':['0','0','0','0','0','1','1'],':':['0','1','1','0','1','1','0'],"'":['1','1','0','0','0','0','0'],'!':['1','1','1','1','1','0','1'],'?':['1110','0001','0001','0010','0100','0000','0100'],'-':['000','000','000','111','000','000','000'],'+':['00000','00100','00100','11111','00100','00100','00000'],'/':['00001','00010','00010','00100','01000','01000','10000'],'>':['100','010','001','000','001','010','100'],'<':['001','010','100','000','100','010','001'],'*':['00000','10101','01110','11111','01110','10101','00000'],'[':['11','10','10','10','10','10','11'],']':['11','01','01','01','01','01','11'],'%':['11001','11010','00010','00100','01000','01011','10011'],'=':['000','000','111','000','111','000','000']}
for k in list(glyphs):
    if k.isalpha(): glyphs[k.lower()]=glyphs[k]
lines=['STARTFONT 2.1','FONT GullPixel','SIZE 8 75 75','FONTBOUNDINGBOX 5 8 0 -1','STARTPROPERTIES 2','FONT_ASCENT 7','FONT_DESCENT 1','ENDPROPERTIES','CHARS '+str(len(glyphs))]
for ch,rows in glyphs.items():
    w=len(rows[0]); lines += ['STARTCHAR char'+str(ord(ch)),'ENCODING '+str(ord(ch)),'SWIDTH 500 0','DWIDTH %d 0'%(w+1),'BBX %d 7 0 0'%w,'BITMAP']+[format(int(row,2)<<(8-w),'02X') for row in rows]+['ENDCHAR']
write('assets/fonts/gull_pixel.bdf','\n'.join(lines+['ENDFONT'])+'\n')
atlas=Canvas(128,64)
font_lines=['info face="GullPixel" size=8 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1','common lineHeight=8 base=7 scaleW=128 scaleH=64 pages=1 packed=0','page id=0 file="gull_pixel.png"','chars count='+str(len(glyphs))]
for i,(ch,rows) in enumerate(glyphs.items()):
    x=(i%16)*8; y=(i//16)*8; w=len(rows[0])
    for yy,row in enumerate(rows):
        for xx,pixel in enumerate(row):
            if pixel=='1': atlas.rect(x+xx,y+yy,1,1,'ffffff')
    font_lines.append(f'char id={ord(ch)} x={x} y={y} width={w} height=7 xoffset=0 yoffset=0 xadvance={w+1} page=0 chnl=15')
atlas.save('assets/fonts/gull_pixel.png')
write('assets/fonts/gull_pixel.fnt','\n'.join(font_lines)+'\n')
random.seed(77)
for cue,duration in [('snatch',.18),('dive',.2),('stun',.28),('gust',.5),('click',.07),('music',8)]:
    sr=22050; samples=[]
    for i in range(int(sr*duration)):
        t=i/sr; env=max(0,1-t/duration)
        freq={'snatch':700+1600*t,'dive':700-2100*t,'stun':110,'gust':1000+200*math.sin(t*20),'click':550}.get(cue,0)
        if cue=='music':
            notes=[261.63,329.63,392,329.63,293.66,349.23,440,349.23,220,261.63,329.63,261.63,196,246.94,293.66,246.94]
            freq=notes[int(t*2)%len(notes)]; env=(1-(t*2)%1)**2*.25
        value=math.sin(2*math.pi*freq*t)*env*.22
        samples.append(struct.pack('<h',int(value*32767)))
    path=ROOT/'assets/audio'/f'{cue}.wav'; path.parent.mkdir(parents=True,exist_ok=True)
    with wave.open(str(path),'wb') as f: f.setparams((1,2,sr,0,'NONE','not compressed')); f.writeframes(b''.join(samples))
from expand_beach import apply as apply_beach_layout
apply_beach_layout()
print('Generated manifest, 6 levels, pixel assets, font and original placeholder audio.')
