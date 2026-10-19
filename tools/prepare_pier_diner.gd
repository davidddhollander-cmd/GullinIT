extends SceneTree
## Separate complete figures before packing: the source artwork crosses grid lines.

func _initialize() -> void:
	for stem: String in ["pier-diner-retro", "pier-diner-motion"]:
		var source := Image.load_from_file("res://assets/sprites/%s-large-pixels.png" % stem)
		var width := source.get_width()
		var height := source.get_height()
		var data := source.get_data()
		var visited := PackedByteArray()
		visited.resize(width * height)
		var actors: Array[Dictionary] = []
		for start: int in width * height:
			if visited[start] or data[start * 4 + 3] < 128:
				continue
			var pixels := PackedInt32Array([start])
			visited[start] = 1
			var cursor := 0
			var bounds := Rect2i(start % width, start / width, 1, 1)
			while cursor < pixels.size():
				var index := pixels[cursor]
				cursor += 1
				var x := index % width
				var y := index / width
				bounds = bounds.expand(Vector2i(x, y))
				for next: int in [index - 1, index + 1, index - width, index + width]:
					if next < 0 or next >= visited.size() or absi(next % width - x) > 1:
						continue
					if not visited[next] and data[next * 4 + 3] >= 128:
						visited[next] = 1
						pixels.append(next)
			if pixels.size() > 500:
				bounds.size += Vector2i.ONE
				actors.append({"pixels": pixels, "bounds": bounds})
		actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pixels.size() > b.pixels.size())
		assert(actors.size() >= 12, "Missing complete diner figures")
		actors.resize(12)
		actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.bounds.get_center().y < b.bounds.get_center().y)
		var output := Image.create(1600, 1200, false, Image.FORMAT_RGBA8)
		for row: int in 3:
			var figures := actors.slice(row * 4, row * 4 + 4)
			figures.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.bounds.position.x < b.bounds.position.x)
			for column: int in 4:
				var actor: Dictionary = figures[column]
				var bounds: Rect2i = actor.bounds
				# Preserve the original horizontal pose origin and a shared foot baseline.
				var left := roundi(200.0 + bounds.position.x - (column + 0.5) * width / 4.0)
				left = clampi(left, 2, 398 - bounds.size.x)
				assert(bounds.size.x < 396 and bounds.size.y < 396)
				var offset := Vector2i(column * 400 + left, row * 400 + 398 - bounds.size.y)
				for index: int in actor.pixels:
					var point := Vector2i(index % width, index / width)
					output.set_pixelv(offset + point - bounds.position, source.get_pixelv(point))
				print(stem, " frame ", row * 4 + column, " bounds ", bounds, " pixels ", actor.pixels.size())
		assert(output.save_png("res://assets/sprites/%s-clean.png" % stem) == OK)
	quit()
