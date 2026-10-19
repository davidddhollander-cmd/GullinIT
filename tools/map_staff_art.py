"""Register prepared character entries without changing unrelated registry formatting."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
path = ROOT / 'data/sprites.json'
text = path.read_text(encoding='utf-8-sig')
for name in ['lifeguard_art', 'shopper_art']:
    source = ROOT / f'data/{name}.json'
    if not source.exists():
        continue
    for key, entry in json.loads(source.read_text(encoding='utf-8-sig')).items():
        pattern = r'(?ms)^  "' + re.escape(key) + r'": \{.*?^  \}(?=,?\n)'
        replacement = '  "' + key + '": ' + json.dumps(entry, indent=2).replace('\n', '\n  ')
        text, count = re.subn(pattern, lambda match: replacement, text)
        assert count == 1, key
json.loads(text)
path.write_text(text, encoding='utf-8')
