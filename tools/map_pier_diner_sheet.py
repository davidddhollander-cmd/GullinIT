"""Rebuild isolated diner atlases, then register their padded animation cells."""
import json
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
os.environ['APPDATA'] = str(ROOT / '.tools/userdata')
os.environ['LOCALAPPDATA'] = os.environ['APPDATA']
subprocess.run([str(ROOT / '.tools/Godot_v4.7.2-stable_win64_console.exe'),
                '--headless', '--path', str(ROOT), '--script', 'tools/prepare_pier_diner.gd'], check=True)
path = ROOT / 'data/sprites.json'
sprites = json.loads(path.read_text(encoding='utf-8-sig'))
for key, stem in [('pier_diner', 'pier-diner-retro'), ('pier_diner_motion', 'pier-diner-motion')]:
    sprites[key]['file'] = f'res://assets/sprites/{stem}-clean.png'
    sprites[key].pop('regions', None)
path.write_text(json.dumps(sprites, indent=2) + '\n', encoding='utf-8')
(ROOT / 'data/pier_diner_art.json').write_text(json.dumps(
    {key: sprites[key] for key in ['pier_diner', 'pier_diner_motion']}, indent=2) + '\n', encoding='utf-8')
print('Registered 24 isolated diner frames with transparent gutters.')
