# Pier diner A cast-standard source

These three untouched source sheets are copies of the existing generated diner A artwork. The preparation script crops each complete pose, hardens only the alpha fringe, nearest-resizes it to the cast grid, and aligns the soles. It does not draw or redesign the character.

- `pier-diner-a-base-source.png`: production `pier-diner-retro-clean.png`
- `pier-diner-a-motion-source.png`: production `pier-diner-motion-v2.png`
- `pier-diner-a-reactions-source.png`: production `pier-diner-reactions-v1.png`

Run with Godot 4.7:

```text
godot --headless --path . --script tools/prepare_pier_diner_a_cast_standard.gd
```
