"""Map original user artwork and configure the longer beach without editing pixels."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
def read(path):
    return json.loads((ROOT/path).read_text(encoding='utf-8-sig'))
def save(path, data):
    (ROOT/path).write_text(json.dumps(data, indent=2)+'\n', encoding='utf-8')

def apply():
    tuning = read('data/tuning.json')
    tuning['world'].update(width=1280, promenade_start=640, pier_start=960,
                           beach_max_x=620, beach_scatter_max_x=628)
    save('data/tuning.json', tuning)
    sprites = read('data/sprites.json')
    # Exact atlas crops; the supplied transparent PNG remains unchanged.
    crops = {
        'tower': ([5,0,166,217], .32),
        'kiosk': ([187,0,163,215], .25),
        'hotdog_stand': ([187,0,163,215], .25),
        'bin': ([8,579,65,113], .16),
        'beach_parasol': ([7,216,148,158], .25),
        'beach_parasol_blue': ([156,216,133,158], .25),
        'beach_chair': ([555,274,97,97], .20),
        'beach_chair_blue': ([644,274,93,98], .20),
        'beach_bench': ([11,432,152,89], .27),
        'beach_palm': ([15,819,113,176], .35),
        'beach_sign': ([1000,390,145,220], .23),
        'beach_castle': ([8,716,100,98], .20),
        'beach_rocks': ([893,744,203,75], .20),
        'beach_boards': ([927,25,116,189], .23),
        'beach_hut': ([1416,209,120,161], .30),
        'beach_lamp': ([909,390,67,214], .27),
    }
    for name,(region,scale) in crops.items():
        sprites[name] = dict(file='res://assets/sprites/beach-props.png',
            frame_w=region[2], frame_h=region[3], visual_scale=scale,
            regions=[dict(region=region,offset=[0,0])],
            animations={'idle':dict(frames=[0],fps=1,loop=True)})
    save('data/sprites.json', sprites)
    decor = [('beach_palm',22,150),('beach_parasol',112,145),
        ('beach_chair',124,150),('beach_castle',205,169),
        ('beach_parasol_blue',350,145),('beach_chair_blue',364,150),
        ('beach_rocks',420,173),('beach_boards',465,149),
        ('beach_hut',590,151),('beach_sign',660,152),
        ('beach_bench',830,153),('beach_lamp',880,155),
        ('beach_palm',935,153),('beach_rocks',1235,172)]
    for path in sorted((ROOT/'data/levels').glob('level_*.json')):
        level = read(path.relative_to(ROOT))
        if level.get('map_version',0) < 2:
            for spawn in level['spawns']:
                if spawn['type'] in ['pier_diner','lifeguard','seafood_vendor','dog_owner']:
                    spawn['x'] += 320
                elif spawn['type'] == 'sunbather' and spawn['x'] > 100:
                    spawn['x'] = 390 if spawn['x'] < 250 else 565
                elif spawn.get('family_id') == 'family_2':
                    spawn['x'] = min(spawn['x'],610)
            level['spawns'].append(dict(type='kiosk_customer',x=750,food_id='hotdog'))
        level['map_version'] = 2
        for spawn in level['spawns']:
            if spawn['type'] == 'sunbather' and spawn['x'] == 340:
                spawn['x'] = 390
            if spawn['type'] == 'picnic_family' and spawn.get('family_id') == 'family_2':
                spawn['x'] = min(spawn['x'],590)
        level['props'] = [dict(type='bin',x=305),dict(type='bin',x=610),
            dict(type='kiosk',x=520),dict(type='hotdog_stand',x=740),dict(type='tower',x=1135)]
        if int(level['id']) >= 5:
            level['props'].append(dict(type='umbrella',x=1030))
        level['props'] += [dict(type=kind,x=x,y=y) for kind,x,y in decor]
        save(path.relative_to(ROOT),level)

if __name__ == '__main__':
    apply()
