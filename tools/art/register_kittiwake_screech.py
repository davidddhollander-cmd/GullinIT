"""Register one clip with a minimal textual diff and verify all old values."""
from pathlib import Path
import copy
import json

ROOT = Path(__file__).resolve().parents[2]
clip = dict(frames=list(range(6)), fps=7, loop=False, source_left=False,
            file='res://assets/sprites/gull-kittiwake-screech-v1.png')
for name in ['gull_art.json', 'sprites.json']:
    path = ROOT / 'data' / name
    text = path.read_text(encoding='utf-8')
    before = json.loads(text)
    expected = copy.deepcopy(before)
    expected['gull_kittiwake']['animations']['screech'] = clip
    if 'screech' not in before['gull_kittiwake']['animations']:
        start = text.index('"gull_kittiwake":')
        animations = text.index('"animations": {', start) + len('"animations": {')
        text = text[:animations] + '\n      "screech": ' + json.dumps(clip) + ',' + text[animations:]
    assert json.loads(text) == expected, f'Unexpected registry changes: {name}'
    path.write_text(text, encoding='utf-8')
    print(f'{name}: only kittiwake screech added; every existing value preserved')
