"""Register the new child sheet; keep the old painted source as an archive."""
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
path = root / 'data/sprites.json'
sprites = json.loads(path.read_text(encoding='utf-8-sig'))
sprites['toddler'] = {
    'file': 'res://assets/sprites/toddler-diner-style.png',
    'frame_w': 64, 'frame_h': 64, 'visual_scale': 0.5,
    'art_height': 22, 'sprite_offset_y': -14,
    'food_anchor': [8.5, -11],
    'food_anchors': {
        'idle': [[8.5,-11], [8.5,-11], [8.5,-11], [8.5,-11]],
        'eat': [[8.5,-11], [6.5,-12], [6.5,-12], [8.5,-11]],
        'walk': [[8.5,-11.5], [8.5,-11.5], [8.5,-11.5], [8.5,-11.5]],
    },
    'animations': {
        'idle': {'frames':[0,1,0,0], 'fps':2, 'loop':True},
        'eat': {'frames':[0,2,3,0], 'fps':4, 'loop':True},
        'walk': {'frames':[4,5,6,7], 'fps':6, 'loop':True},
        'cry': {'frames':[8,9,10,11,10,9], 'fps':6, 'loop':True},
        'cry_run': {'frames':[12,13,14,15], 'fps':10, 'loop':True},
    },
}
path.write_text(json.dumps(sprites,indent=2)+'\n',encoding='utf-8')
